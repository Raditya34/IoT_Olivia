<?php
// app/Console/Commands/MqttSubscribe.php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;

class MqttSubscribe extends Command
{
    protected $signature   = 'mqtt:subscribe';
    protected $description = 'Listen data dari HiveMQ Cloud untuk 3 ESP32';

    public function handle()
    {
        $server   = env('MQTT_HOST', 'a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud');
        $port     = (int) env('MQTT_PORT', 8883);
        $clientId = env('MQTT_CLIENT_ID', 'laravel_sub') . '_' . uniqid();
        $username = env('MQTT_USERNAME', 'Olivia_IoT');
        $password = env('MQTT_PASSWORD', 'Olivia12345');
        $topic    = env('MQTT_TOPIC', 'olivia/+/telemetry');

        $this->info("Menghubungkan ke $server:$port ...");

        $mqtt = new MqttClient($server, $port, $clientId, MqttClient::MQTT_3_1_1);

        $settings = (new ConnectionSettings)
            ->setUsername($username)
            ->setPassword($password)
            ->setKeepAliveInterval(60)
            ->setConnectTimeout(15)
            ->setUseTls(true)
            ->setTlsSelfSignedAllowed(false);

        try {
            $mqtt->connect($settings, true);
            $this->info("✅ Terhubung! Menunggu data dari topic: $topic");

            $mqtt->subscribe($topic, function (string $topic, string $message) {
                $parts = explode('/', $topic);
                $deviceCode = $parts[1] ?? 'UNKNOWN';

                $this->line("[" . now() . "] $topic => $message");
                $data = json_decode($message, true);

                if (!$data) {
                    $this->error("Payload tidak valid JSON");
                    return;
                }

                try {
                    match ($deviceCode) {
                        'OLIVIA-01' => Esp1Arang::create([
                            'suhu_arang' => $data['suhu_arang'] ?? 0,
                            'volume_arang' => $data['volume_arang'] ?? 0
                        ]),
                        'OLIVIA-02' => Esp2Bleaching::create([
                            'suhu_bleaching' => $data['suhu_bleaching'] ?? 0,
                            'valve' => $data['valve'] ?? false,
                            'p1'    => $data['p1'] ?? false,
                            'p2'    => $data['p2'] ?? false,
                            'p3'    => $data['p3'] ?? false,
                            'h1'    => $data['h1'] ?? false,
                            'h2'    => $data['h2'] ?? false,
                            'h3'    => $data['h3'] ?? false,
                            'h4'    => $data['h4'] ?? false,
                            'speed' => $data['speed'] ?? 0,
                        ]),
                        'OLIVIA-03' => Esp3Validasi::create([
                            'volume_validasi'    => $data['volume_validasi']    ?? 0,
                            'turbidity' => $data['turbidity'] ?? 0,
                            'viscosity' => $data['viscosity'] ?? 0,
                            'r'         => $data['r']         ?? 0,
                            'g'         => $data['g']         ?? 0,
                            'b'         => $data['b']         ?? 0,
                        ]),
                        default => $this->warn("⚠️ Device tidak dikenal: $deviceCode"),
                    };
                    $this->info("✓ Data $deviceCode disimpan.");
                } catch (\Exception $e) {
                    $this->error("❌ Gagal simpan: " . $e->getMessage());
                }
            }, 0);

            $mqtt->loop(true);
        } catch (\Exception $e) {
            $this->error("Koneksi Error: " . $e->getMessage());
        }
    }
}

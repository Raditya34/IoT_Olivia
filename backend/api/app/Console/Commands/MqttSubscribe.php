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
    protected $description = 'Listen data dari EMQX Cloud untuk 3 ESP32';

    public function handle()
    {
        $server   = env('MQTT_HOST');
        $port     = (int) env('MQTT_PORT', 8883); // ✅ TLS port
        $clientId = env('MQTT_CLIENT_ID', 'laravel_sub') . '_' . uniqid();
        $username = env('MQTT_USERNAME');
        $password = env('MQTT_PASSWORD');
        $topic    = env('MQTT_TOPIC', 'olivia/+/telemetry');

        $this->info("Menghubungkan ke $server:$port ...");

        $mqtt = new MqttClient($server, $port, $clientId, MqttClient::MQTT_3_1_1);

        $settings = (new ConnectionSettings)
            ->setUsername($username)
            ->setPassword($password)
            ->setKeepAliveInterval(60)
            ->setConnectTimeout(15)
            ->setUseTls(true)                  // ✅ Wajib untuk emqxsl.com
            ->setTlsSelfSignedAllowed(false);  // ✅ Pakai cert resmi EMQX

        try {
            $mqtt->connect($settings, true);
            $this->info("✅ Terhubung! Menunggu data dari topic: $topic");
        } catch (\Exception $e) {
            $this->error("❌ Gagal konek: " . $e->getMessage());
            return 1;
        }

        $mqtt->subscribe($topic, function (string $topic, string $message) {
            $this->info("[" . now() . "] $topic => $message");

            $parts      = explode('/', $topic);
            $deviceCode = $parts[1] ?? 'UNKNOWN';
            $data       = json_decode($message, true);

            if (!$data) {
                $this->warn("Payload tidak valid JSON: $message");
                return;
            }

            try {
                match ($deviceCode) {
                    'OLIVIA-01' => Esp1Arang::create([
                        'suhu'   => $data['suhu']   ?? 0,
                        'volume' => $data['volume'] ?? 0,
                    ]),
                    'OLIVIA-02' => Esp2Bleaching::create([
                        'suhu'           => $data['suhu']    ?? 0,
                        'valve'          => $data['valve']   ?? false,
                        'pompa_1'        => $data['pompa_1'] ?? false,
                        'pompa_2'        => $data['pompa_2'] ?? false,
                        'pompa_3'        => $data['pompa_3'] ?? false,
                        'heater_1'       => $data['heater_1'] ?? false,
                        'heater_2'       => $data['heater_2'] ?? false,
                        'heater_3'       => $data['heater_3'] ?? false,
                        'heater_4'       => $data['heater_4'] ?? false,
                        'motor_ac_speed' => $data['speed']   ?? 0,
                    ]),
                    'OLIVIA-03' => Esp3Validasi::create([
                        'volume'     => $data['volume']     ?? 0,
                        'turbidity'  => $data['turbidity']  ?? 0,
                        'viskositas' => $data['viskositas'] ?? 0,
                        'warna'      => $data['warna']      ?? '-',
                    ]),
                    default => $this->warn("⚠️ Device tidak dikenal: $deviceCode"),
                };
                $this->info("✓ Data $deviceCode disimpan.");
            } catch (\Exception $e) {
                $this->error("❌ Gagal simpan: " . $e->getMessage());
            }
        }, 0);

        $mqtt->loop(true); // Jalan terus
    }
}

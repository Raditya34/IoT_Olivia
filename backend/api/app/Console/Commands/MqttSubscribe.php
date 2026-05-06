<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;

class MqttSubscribe extends Command
{
    // Nama command yang dijalankan di terminal: php artisan mqtt:subscribe
    protected $signature = 'mqtt:subscribe';
    protected $description = 'Mendengarkan data dari EMQX MQTT Broker untuk 3 Unit ESP32';

    public function handle()
    {
        // Mengambil setting dari .env
        $server   = env('MQTT_HOST');
        $port     = (int) env('MQTT_PORT', 1883);
        $clientId = env('MQTT_CLIENT_ID', 'laravel_subscriber') . '_' . uniqid();
        $username = env('MQTT_USERNAME');
        $password = env('MQTT_PASSWORD');

        $mqtt = new MqttClient($server, $port, $clientId, MqttClient::MQTT_3_1_1);

        $settings = (new ConnectionSettings)
            ->setUsername($username)
            ->setPassword($password)
            ->setKeepAliveInterval(60)
            ->setConnectTimeout(10);

        $this->info("Menghubungkan ke EMQX Cloud di $server:$port...");

        try {
            $mqtt->connect($settings, true);
            $this->info("✅ Berhasil Terhubung! Menunggu data telemetry...");
        } catch (\Exception $e) {
            $this->error("❌ Gagal terhubung: " . $e->getMessage());
            return;
        }

        // Subscribe ke topik wildcard: olivia/+/telemetry
        // Tanda (+) berarti akan menangkap OLIVIA-01, OLIVIA-02, dan OLIVIA-03
        $mqtt->subscribe('olivia/+/telemetry', function (string $topic, string $message) {
            $this->info("Pesan diterima di [$topic]: $message");

            // Ambil nama device (OLIVIA-01, dll) dari nama topik
            $topicParts = explode('/', $topic);
            $deviceCode = $topicParts[1] ?? 'UNKNOWN';

            $data = json_decode($message, true);
            if (!$data) {
                $this->error("Payload bukan JSON yang valid!");
                return;
            }

            try {
                // LOGIKA PEMISAHAN TABEL (MODULAR)
                switch ($deviceCode) {
                    case 'OLIVIA-01':
                        Esp1Arang::create([
                            'suhu'   => $data['suhu'] ?? 0,
                            'volume' => $data['volume'] ?? 0
                        ]);
                        $this->info("✓ Data Unit 1 (Arang) Disimpan.");
                        break;

                    case 'OLIVIA-02':
                        Esp2Bleaching::create([
                            'suhu'          => $data['suhu'] ?? 0,
                            'valve'         => $data['valve'] ?? false,
                            'pompa_1'       => $data['pompa_1'] ?? false,
                            'pompa_2'       => $data['pompa_2'] ?? false,
                            'pompa_3'       => $data['pompa_3'] ?? false,
                            'heater_1'      => $data['heater_1'] ?? false,
                            'heater_2'      => $data['heater_2'] ?? false,
                            'heater_3'      => $data['heater_3'] ?? false,
                            'heater_4'      => $data['heater_4'] ?? false,
                            'motor_ac_speed'=> $data['speed'] ?? 0,
                        ]);
                        $this->info("✓ Data Unit 2 (Bleaching) Disimpan.");
                        break;

                    case 'OLIVIA-03':
                        Esp3Validasi::create([
                            'volume'     => $data['volume'] ?? 0,
                            'turbidity'  => $data['turbidity'] ?? 0,
                            'viskositas' => $data['viskositas'] ?? 0,
                            'warna'      => $data['warna'] ?? '-',
                        ]);
                        $this->info("✓ Data Unit 3 (Validasi) Disimpan.");
                        break;

                    default:
                        $this->warn("⚠️ Perangkat tidak terdaftar: $deviceCode");
                        break;
                }
            } catch (\Exception $e) {
                $this->error("❌ Gagal simpan ke DB: " . $e->getMessage());
            }
        }, 0);

        $mqtt->loop(true);
    }
}

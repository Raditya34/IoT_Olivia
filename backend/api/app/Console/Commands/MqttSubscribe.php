<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;
use App\Models\Esp1Arang;

class MqttSubscribe extends Command
{
    protected $signature = 'mqtt:subscribe';
    protected $description = 'Mendengarkan data dari EMQX MQTT Broker';

    public function handle()
    {
        $server   = env('MQTT_HOST', 'localhost');
        $port     = (int) env('MQTT_PORT', 1883);
        $clientId = env('MQTT_CLIENT_ID', 'laravel_client') . '_' . uniqid();
        $username = env('MQTT_USERNAME');
        $password = env('MQTT_PASSWORD');

        $mqtt = new MqttClient($server, $port, $clientId, MqttClient::MQTT_3_1_1);

        $settings = (new ConnectionSettings)
            ->setUsername($username === 'null' ? null : $username)
            ->setPassword($password === 'null' ? null : $password)
            ->setKeepAliveInterval(60)
            ->setConnectTimeout(10);

        $this->info("Menghubungkan ke broker MQTT di $server:$port...");

        try {
            $mqtt->connect($settings, true);
            $this->info("Berhasil terhubung ke EMQX!");
        } catch (\Exception $e) {
            $this->error("Gagal terhubung: " . $e->getMessage());
            return;
        }

        // --- BAGIAN YANG DITAMBAHKAN MULAI DISINI ---

        $this->info("Sedang menunggu data dari ESP1, ESP2, dan ESP3...");

        // Subscribe ke semua topik di bawah 'olivia/#'
        // Tanda '#' adalah wildcard yang artinya "dengarkan semua yang dimulai dengan olivia/"
        $mqtt->subscribe('olivia/+', function (string $topic, string $message) {
            $this->info("Pesan diterima di [$topic]: $message");
            $data = json_decode($message, true);

            if (!$data) {
                $this->error("Format JSON tidak valid!");
                return;
            }

            try {
                switch ($topic) {
                    case 'olivia/esp1':
                        \App\Models\Esp1Arang::create([
                            'suhu' => $data['suhu'] ?? 0,
                            'volume' => $data['volume'] ?? 0
                        ]);
                        $this->info("✓ Data ESP1 (Arang) disimpan.");
                        break;

                    case 'olivia/esp2':
                        \App\Models\Esp2Bleaching::create([
                            'suhu' => $data['suhu'] ?? 0
                        ]);
                        $this->info("✓ Data ESP2 (Bleaching) disimpan.");
                        break;

                    case 'olivia/esp3':
                        \App\Models\Esp3Validasi::create([
                            'turbidity' => $data['turbidity'] ?? 0,
                            'viscosity' => $data['viscosity'] ?? 0,
                            'warna' => $data['warna'] ?? 0
                        ]);
                        $this->info("✓ Data ESP3 (Validasi) disimpan.");
                        break;

                    default:
                        $this->warn("Topik tidak dikenal: $topic");
                        break;
                }
            } catch (\Exception $e) {
                $this->error("Gagal simpan ke DB: " . $e->getMessage());
            }
        }, 0);

        $mqtt->loop(true);

        // --- BAGIAN YANG DITAMBAHKAN SELESAI ---
    }
}

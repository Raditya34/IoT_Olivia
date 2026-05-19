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
    protected $description = 'Listen data dari HiveMQ Cloud dan re-publish format nested ke Flutter';

    // Buffer in-memory: menyimpan data terakhir tiap device
    // agar bisa disusun menjadi payload nested yang lengkap
    private array $buffer = [
        'OLIVIA-01' => null,
        'OLIVIA-02' => null,
        'OLIVIA-03' => null,
    ];

    private ?MqttClient $mqtt = null;

    public function handle()
    {
        $server   = env('MQTT_HOST', 'a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud');
        $port     = (int) env('MQTT_PORT', 8883);
        $clientId = env('MQTT_CLIENT_ID', 'laravel_sub') . '_' . uniqid();
        $username = env('MQTT_USERNAME', 'Olivia_IoT');
        $password = env('MQTT_PASSWORD', 'Olivia12345');

        // Subscribe ke semua device dengan wildcard
        $subscribeTopik = 'olivia/+/telemetry';
        // Re-publish payload nested ke topik yang didengar Flutter
        $publishTopik   = 'olivia/purifikasi/telemetry';

        $this->info("Menghubungkan ke $server:$port ...");

        $this->mqtt = new MqttClient($server, $port, $clientId, MqttClient::MQTT_3_1_1);

        $settings = (new ConnectionSettings)
            ->setUsername($username)
            ->setPassword($password)
            ->setKeepAliveInterval(60)
            ->setConnectTimeout(15)
            ->setUseTls(true)
            ->setTlsSelfSignedAllowed(false);

        try {
            $this->mqtt->connect($settings, true);
            $this->info("Terhubung! Subscribe: $subscribeTopik → publish: $publishTopik");

            $this->mqtt->subscribe($subscribeTopik, function (string $topic, string $message) use ($publishTopik) {
                // Ekstrak kode device dari topik: olivia/OLIVIA-01/telemetry → OLIVIA-01
                $parts      = explode('/', $topic);
                $deviceCode = $parts[1] ?? 'UNKNOWN';

                $this->line("[" . now() . "] $topic => $message");
                $data = json_decode($message, true);

                if (!$data) {
                    $this->error("Payload tidak valid JSON dari $deviceCode");
                    return;
                }

                // 1. Simpan ke database sesuai device
                $this->simpanKeDatabase($deviceCode, $data);

                // 2. Update buffer in-memory
                $this->buffer[$deviceCode] = $data;

                // 3. Jika minimal OLIVIA-01 dan OLIVIA-02 sudah ada datanya,
                //    susun payload nested dan re-publish ke Flutter
                if ($this->buffer['OLIVIA-01'] !== null || $this->buffer['OLIVIA-02'] !== null) {
                    $this->republishNested($publishTopik);
                }

            }, 0);

            $this->mqtt->loop(true);

        } catch (\Exception $e) {
            $this->error("Koneksi Error: " . $e->getMessage());
        }
    }

    /**
     * Simpan raw data ke tabel database masing-masing device
     */
    private function simpanKeDatabase(string $deviceCode, array $data): void
    {
        try {
            match ($deviceCode) {
                'OLIVIA-01' => Esp1Arang::create([
                    'suhu_arang'   => $data['suhu_arang']   ?? 0,
                    'volume_arang' => $data['volume_arang'] ?? 0,
                ]),
                'OLIVIA-02' => Esp2Bleaching::create([
                    'suhu_bleaching' => $data['suhu_bleaching'] ?? 0,
                    'valve' => $data['valve'] ?? false,
                    'p1'    => $data['p1']    ?? false,
                    'p2'    => $data['p2']    ?? false,
                    'p3'    => $data['p3']    ?? false,
                    'h1'    => $data['h1']    ?? false,
                    'h2'    => $data['h2']    ?? false,
                    'h3'    => $data['h3']    ?? false,
                    'h4'    => $data['h4']    ?? false,
                    'speed' => $data['speed'] ?? 0,
                ]),
                'OLIVIA-03' => Esp3Validasi::create([
                    'volume_validasi' => $data['volume_validasi'] ?? 0,
                    'turbidity'       => $data['turbidity']       ?? 0,
                    'viscosity'       => $data['viscosity']       ?? 0,
                    'r'               => $data['r']               ?? 0,
                    'g'               => $data['g']               ?? 0,
                    'b'               => $data['b']               ?? 0,
                ]),
                default => $this->warn("Device tidak dikenal: $deviceCode"),
            };
            $this->info("DB $deviceCode disimpan.");
        } catch (\Exception $e) {
            $this->error("Gagal simpan DB $deviceCode: " . $e->getMessage());
        }
    }

    /**
     * Susun payload nested dari buffer lalu re-publish ke topik Flutter.
     * Format ini PERSIS yang diharapkan DashboardController.dart.
     */
    private function republishNested(string $publishTopik): void
    {
        $d1 = $this->buffer['OLIVIA-01'] ?? [];
        $d2 = $this->buffer['OLIVIA-02'] ?? [];
        $d3 = $this->buffer['OLIVIA-03'] ?? [];

        $payload = json_encode([
            'system_on' => true,

            'arang' => [
                'suhu_arang'   => $d1['suhu_arang']   ?? 0.0,
                'volume_arang' => $d1['volume_arang']  ?? 0.0,
            ],

            'bleaching' => [
                'suhu_bleaching' => $d2['suhu_bleaching'] ?? 0.0,
                'valve' => $d2['valve'] ?? false,
                'p1'    => $d2['p1']    ?? false,
                'p2'    => $d2['p2']    ?? false,
                'p3'    => $d2['p3']    ?? false,
                'h1'    => $d2['h1']    ?? false,
                'h2'    => $d2['h2']    ?? false,
                'h3'    => $d2['h3']    ?? false,
                'h4'    => $d2['h4']    ?? false,
                'speed' => $d2['speed'] ?? 0,
            ],

            'validasi' => [
                'volume_validasi' => $d3['volume_validasi'] ?? 0.0,
                'turbidity'       => $d3['turbidity']       ?? 0.0,
                'viscosity'       => $d3['viscosity']       ?? 0.0,
                'r'               => $d3['r']               ?? 0,
                'g'               => $d3['g']               ?? 0,
                'b'               => $d3['b']               ?? 0,
            ],
        ]);

        try {
            $this->mqtt->publish($publishTopik, $payload, 0);
            $this->line("  >> Re-published nested ke $publishTopik");
        } catch (\Exception $e) {
            $this->error("Gagal re-publish: " . $e->getMessage());
        }
    }
}

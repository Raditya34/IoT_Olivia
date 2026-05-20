<?php
// app/Console/Commands/MqttSubscribe.php
namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;
use App\Models\MasterControl;

class MqttSubscribe extends Command
{
    protected $signature   = 'mqtt:subscribe';
    protected $description = 'Listen data dari HiveMQ Cloud (mendukung 1 topik gabungan maupun modular) dan re-publish ke Flutter';

    // Buffer in-memory: fallback untuk menyusun data jika menggunakan sistem modular terpisah
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

        // Subscribe menggunakan wildcard agar menangkap semua data (termasuk olivia/OLIVIA-01/telemetry)
        $subscribeTopik = env('MQTT_SUBSCRIBE_TOPIC', 'olivia/+/telemetry');
        // Re-publish payload nested ke topik yang didengar oleh aplikasi Flutter
        $publishTopik   = env('MQTT_PUBLISH_TOPIC', 'olivia/purifikasi/telemetry');

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

                // =========================================================================
                // OPSI A: JIKA PAYLOAD ADALAH DATA GABUNGAN FULL 1 TOPIK (STRUKTUR NESTED)
                // =========================================================================
                if (isset($data['arang']) || isset($data['bleaching']) || isset($data['validasi'])) {
                    $this->info("⚡ Menerima payload GABUNGAN dari Master ($deviceCode). Memecah data ke database...");

                    // 1. Simpan ke Tabel Arang (Unit 1) jika ada di dalam json
                    if (isset($data['arang'])) {
                        try {
                            Esp1Arang::create([
                                'suhu_arang'   => $data['arang']['suhu_arang']   ?? 0.0,
                                'volume_arang' => $data['arang']['volume_arang'] ?? 0.0,
                            ]);
                            $this->info(" -> DB Arang berhasil disimpan.");
                        } catch (\Exception $e) {
                            $this->error("Gagal simpan DB Arang: " . $e->getMessage());
                        }
                    }

                    // 2. Simpan ke Tabel Bleaching (Unit 2) jika ada di dalam json
                    if (isset($data['bleaching'])) {
                        try {
                            Esp2Bleaching::create([
                                'suhu_bleaching' => $data['bleaching']['suhu_bleaching'] ?? 0.0,
                                'valve'          => (bool)($data['bleaching']['valve'] ?? false),
                                'p1'             => (bool)($data['bleaching']['p1'] ?? false),
                                'p2'             => (bool)($data['bleaching']['p2'] ?? false),
                                'p3'             => (bool)($data['bleaching']['p3'] ?? false),
                                'h1'             => (bool)($data['bleaching']['h1'] ?? false),
                                'h2'             => (bool)($data['bleaching']['h2'] ?? false),
                                'h3'             => (bool)($data['bleaching']['h3'] ?? false),
                                'h4'             => (bool)($data['bleaching']['h4'] ?? false),
                                'speed'          => $data['bleaching']['speed'] ?? 0,
                            ]);
                            $this->info(" -> DB Bleaching berhasil disimpan.");
                        } catch (\Exception $e) {
                            $this->error("Gagal simpan DB Bleaching: " . $e->getMessage());
                        }
                    }

                    // 3. Simpan ke Tabel Validasi (Unit 3) jika ada di dalam json
                    if (isset($data['validasi'])) {
                        try {
                            Esp3Validasi::create([
                                'volume_validasi' => $data['validasi']['volume_validasi'] ?? 0.0,
                                'turbidity'       => $data['validasi']['turbidity']       ?? 0.0,
                                'viscosity'       => $data['validasi']['viscosity']       ?? 0.0,
                                'r'               => $data['validasi']['r']               ?? 0,
                                'g'               => $data['validasi']['g']               ?? 0,
                                'b'               => $data['validasi']['b']               ?? 0,
                            ]);
                            $this->info(" -> DB Validasi berhasil disimpan.");
                        } catch (\Exception $e) {
                            $this->error("Gagal simpan DB Validasi: " . $e->getMessage());
                        }
                    }

                    // 4. Sinkronisasi status system_on ke tabel master_controls
                    if (isset($data['system_on'])) {
                        try {
                            MasterControl::query()->updateOrCreate(
                                [], // kriteria pencarian kosong agar selalu mengupdate baris pertama
                                ['system_on' => (bool)$data['system_on']]
                            );
                        } catch (\Exception $e) {
                            $this->error("Gagal sinkronisasi MasterControl: " . $e->getMessage());
                        }
                    }

                    // 5. LANGSUNG RE-PUBLISH data gabungan utuh ini ke Flutter (Tanpa melalui buffer)
                    // Dengan cara ini, nilai 'progress_step' & 'system_on' dari hardware ikut terkirim secara real-time!
                    try {
                        $this->mqtt->publish($publishTopik, json_encode($data), 0);
                        $this->line(" >> Re-published JSON gabungan ke Flutter via [$publishTopik]");
                    } catch (\Exception $e) {
                        $this->error("Gagal re-publish gabungan: " . $e->getMessage());
                    }

                } else {
                    // =========================================================================
                    // OPSI B: FALLBACK JALUR MODULAR LAMA (JIKA DEVICE KIRIM SECARA TERPISAH)
                    // =========================================================================

                    // 1. Simpan ke database sesuai device code masing-masing
                    $this->simpanKeDatabase($deviceCode, $data);

                    // 2. Update buffer in-memory
                    $this->buffer[$deviceCode] = $data;

                    // 3. Jika minimal OLIVIA-01 atau OLIVIA-02 mengirim data, satukan dan re-publish
                    if ($this->buffer['OLIVIA-01'] !== null || $this->buffer['OLIVIA-02'] !== null) {
                        $this->republishNested($publishTopik);
                    }
                }

            }, 0);

            $this->mqtt->loop(true);

        } catch (\Exception $e) {
            $this->error("Koneksi Error: " . $e->getMessage());
        }
    }

    /**
     * Fallback: Simpan raw data untuk sistem modular terpisah
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
                    'valve' => (bool)($data['valve'] ?? false),
                    'p1'    => (bool)($data['p1']    ?? false),
                    'p2'    => (bool)($data['p2']    ?? false),
                    'p3'    => (bool)($data['p3']    ?? false),
                    'h1'    => (bool)($data['h1']    ?? false),
                    'h2'    => (bool)($data['h2']    ?? false),
                    'h3'    => (bool)($data['h3']    ?? false),
                    'h4'    => (bool)($data['h4']    ?? false),
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
            $this->info("DB $deviceCode disimpan (Jalur Modular).");
        } catch (\Exception $e) {
            $this->error("Gagal simpan DB $deviceCode: " . $e->getMessage());
        }
    }

    /**
     * Fallback: Susun data nested dari buffer in-memory jika data masuk secara modular terpisah
     */
    private function republishNested(string $publishTopik): void
    {
        $d1 = $this->buffer['OLIVIA-01'] ?? [];
        $d2 = $this->buffer['OLIVIA-02'] ?? [];
        $d3 = $this->buffer['OLIVIA-03'] ?? [];

        // Ambil status system_on terakhir dari database jika ada
        $master = MasterControl::first();
        $isSystemOn = $master ? (bool)$master->system_on : true;

        $payload = json_encode([
            'system_on'     => $isSystemOn,
            'progress_step' => 0, // default fallback nilai progress

            'arang' => [
                'suhu_arang'   => $d1['suhu_arang']   ?? ($d1['arang']['suhu_arang'] ?? 0.0),
                'volume_arang' => $d1['volume_arang']  ?? ($d1['arang']['volume_arang'] ?? 0.0),
            ],

            'bleaching' => [
                'suhu_bleaching' => $d2['suhu_bleaching'] ?? ($d2['bleaching']['suhu_bleaching'] ?? 0.0),
                'valve' => (bool)($d2['valve'] ?? ($d2['bleaching']['valve'] ?? false)),
                'p1'    => (bool)($d2['p1']    ?? ($d2['bleaching']['p1'] ?? false)),
                'p2'    => (bool)($d2['p2']    ?? ($d2['bleaching']['p2'] ?? false)),
                'p3'    => (bool)($d2['p3']    ?? ($d2['bleaching']['p3'] ?? false)),
                'h1'    => (bool)($d2['h1']    ?? ($d2['bleaching']['h1'] ?? false)),
                'h2'    => (bool)($d2['h2']    ?? ($d2['bleaching']['h2'] ?? false)),
                'h3'    => (bool)($d2['h3']    ?? ($d2['bleaching']['h3'] ?? false)),
                'h4'    => (bool)($d2['h4']    ?? ($d2['bleaching']['h4'] ?? false)),
                'speed' => $d2['speed'] ?? ($d2['bleaching']['speed'] ?? 0),
            ],

            'validasi' => [
                'volume_validasi' => $d3['volume_validasi'] ?? ($d3['validasi']['volume_validasi'] ?? 0.0),
                'turbidity'       => $d3['turbidity']       ?? ($d3['validasi']['turbidity'] ?? 0.0),
                'viscosity'       => $d3['viscosity']       ?? ($d3['validasi']['viscosity'] ?? 0.0),
                'r'               => $d3['r']               ?? ($d3['validasi']['r'] ?? 0),
                'g'               => $d3['g']               ?? ($d3['validasi']['g'] ?? 0),
                'b'               => $d3['b']               ?? ($d3['validasi']['b'] ?? 0),
            ],
        ]);

        try {
            $this->mqtt->publish($publishTopik, $payload, 0);
            $this->line(" >> Re-published nested ke $publishTopik (Jalur Modular)");
        } catch (\Exception $e) {
            $this->error("Gagal re-publish: " . $e->getMessage());
        }
    }
}

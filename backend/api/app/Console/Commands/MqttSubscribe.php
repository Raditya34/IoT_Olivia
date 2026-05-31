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
    protected $description = 'Listen data dari HiveMQ Cloud dan re-publish ke Flutter';

    // Buffer in-memory untuk fallback jalur modular
    private array $buffer = [
        'OLIVIA-01'     => null,
        'OLIVIA-02'     => null,
        'OLIVIA-03'     => null,
        'OLIVIA-MASTER' => null, // ✅ BARU: Tambah entry untuk Master
    ];

    private ?MqttClient $mqtt = null;

    public function handle()
    {
        $server   = env('MQTT_HOST', 'a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud');
        $port     = (int) env('MQTT_PORT', 8883);
        $clientId = env('MQTT_CLIENT_ID', 'laravel_sub') . '_' . uniqid();
        $username = env('MQTT_USERNAME', 'Olivia_IoT');
        $password = env('MQTT_PASSWORD', 'Olivia12345');

        // Wildcard subscribe menangkap semua device termasuk OLIVIA-MASTER
        $subscribeTopik = env('MQTT_SUBSCRIBE_TOPIC', 'olivia/+/telemetry');
        // Re-publish ke topik yang didengar Flutter
        $publishTopik   = env('MQTT_PUBLISH_TOPIC', 'olivia/telemetry');

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
            $this->info("Terhubung! Subscribe: $subscribeTopik → Re-publish: $publishTopik");

            $this->mqtt->subscribe($subscribeTopik, function (string $topic, string $message) use ($publishTopik) {
                // Ekstrak device code dari topik: olivia/OLIVIA-MASTER/telemetry → OLIVIA-MASTER
                $parts      = explode('/', $topic);
                $deviceCode = $parts[1] ?? 'UNKNOWN';

                $this->line("[" . now() . "] [$deviceCode] $message");
                $data = json_decode($message, true);

                if (!is_array($data)) {
                    $this->error("Payload tidak valid JSON dari $deviceCode");
                    return;
                }

                // =================================================================
                // OPSI A: PAYLOAD GABUNGAN / NESTED (dari ESP32 Master V2)
                // Ditandai dengan adanya key 'arang', 'bleaching', atau 'validasi'
                // =================================================================
                if (isset($data['arang']) || isset($data['bleaching']) || isset($data['validasi'])) {
                    $this->info("⚡ Payload GABUNGAN dari [$deviceCode]. Memproses ke DB...");

                    // 1. Simpan data Arang ke DB
                    if (isset($data['arang'])) {
                        try {
                            Esp1Arang::create([
                                'suhu_arang'   => $data['arang']['suhu_arang']   ?? 0.0,
                                'volume_arang' => $data['arang']['volume_arang'] ?? 0.0,
                            ]);
                            $this->info("  → DB Arang OK");
                        } catch (\Exception $e) {
                            $this->error("  → Gagal DB Arang: " . $e->getMessage());
                        }
                    }

                    // 2. Simpan data Bleaching ke DB
                    if (isset($data['bleaching'])) {
                        try {
                            Esp2Bleaching::create([
                                'suhu_bleaching' => $data['bleaching']['suhu_bleaching'] ?? 0.0,
                                'valve'          => (bool)($data['bleaching']['valve'] ?? false),
                                'p1'             => (bool)($data['bleaching']['p1']    ?? false),
                                'p2'             => (bool)($data['bleaching']['p2']    ?? false),
                                'p3'             => (bool)($data['bleaching']['p3']    ?? false),
                                'h1'             => (bool)($data['bleaching']['h1']    ?? false),
                                'h2'             => (bool)($data['bleaching']['h2']    ?? false),
                                'h3'             => (bool)($data['bleaching']['h3']    ?? false),
                                'h4'             => (bool)($data['bleaching']['h4']    ?? false),
                                'speed'          => $data['bleaching']['speed'] ?? 0,
                            ]);
                            $this->info("  → DB Bleaching OK");
                        } catch (\Exception $e) {
                            $this->error("  → Gagal DB Bleaching: " . $e->getMessage());
                        }
                    }

                    // 3. ✅ FIX: Simpan data Validasi ke DB TERMASUK kelayakan & status_layak
                    if (isset($data['validasi'])) {
                        try {
                            Esp3Validasi::create([
                                'volume_validasi' => $data['validasi']['volume_validasi'] ?? 0.0,
                                'turbidity'       => $data['validasi']['turbidity']       ?? 0.0,
                                'viscosity'       => $data['validasi']['viscosity']       ?? 0.0,
                                'r'               => $data['validasi']['r']               ?? 0,
                                'g'               => $data['validasi']['g']               ?? 0,
                                'b'               => $data['validasi']['b']               ?? 0,
                                // ✅ Kolom ini ada di model tapi sebelumnya tidak di-insert
                                'kelayakan'       => $data['validasi']['kelayakan']        ?? 0.0,
                                'status_layak'    => $data['validasi']['status_layak']     ?? 'TIDAK LAYAK',
                            ]);
                            $this->info("  → DB Validasi OK (kelayakan=" . ($data['validasi']['kelayakan'] ?? 0) . ")");
                        } catch (\Exception $e) {
                            $this->error("  → Gagal DB Validasi: " . $e->getMessage());
                        }
                    }

                    // 4. Sinkronisasi system_on ke tabel master_controls
                    if (isset($data['system_on'])) {
                        try {
                            MasterControl::query()->updateOrCreate(
                                [],
                                ['system_on' => (bool)$data['system_on']]
                            );
                            $this->info("  → MasterControl sync: system_on=" . ($data['system_on'] ? 'true' : 'false'));
                        } catch (\Exception $e) {
                            $this->error("  → Gagal sync MasterControl: " . $e->getMessage());
                        }
                    }

                    // 5. Re-publish payload gabungan utuh ke Flutter via topic olivia/telemetry
                    //    Flutter subscribe ke 'olivia/telemetry' (tanpa device code)
                    try {
                        $this->mqtt->publish($publishTopik, $message, 0);
                        $this->line("  >> Re-published ke Flutter [$publishTopik]");
                    } catch (\Exception $e) {
                        $this->error("  >> Gagal re-publish: " . $e->getMessage());
                    }

                } else {
                    // =================================================================
                    // OPSI B: FALLBACK JALUR MODULAR (device kirim data flat terpisah)
                    // =================================================================
                    $this->info("⚙ Payload MODULAR dari [$deviceCode]. Buffering...");
                    $this->simpanKeDatabase($deviceCode, $data);
                    $this->buffer[$deviceCode] = $data;

                    // Re-publish hanya jika minimal satu device sudah punya data
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
     * Fallback: Simpan raw data flat dari device modular terpisah
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
                    'kelayakan'       => $data['kelayakan']        ?? 0.0,
                    'status_layak'    => $data['status_layak']     ?? 'TIDAK LAYAK',
                ]),
                default => $this->warn("Device tidak dikenal: $deviceCode"),
            };
            $this->info("  → DB $deviceCode OK (Jalur Modular)");
        } catch (\Exception $e) {
            $this->error("  → Gagal DB $deviceCode: " . $e->getMessage());
        }
    }

    /**
     * Fallback: Susun payload nested dari buffer in-memory untuk jalur modular
     */
    private function republishNested(string $publishTopik): void
    {
        $d1 = $this->buffer['OLIVIA-01'] ?? [];
        $d2 = $this->buffer['OLIVIA-02'] ?? [];
        $d3 = $this->buffer['OLIVIA-03'] ?? [];

        $master     = MasterControl::first();
        $isSystemOn = $master ? (bool)$master->system_on : false;

        $payload = json_encode([
            'system_on' => $isSystemOn,

            'arang' => [
                'suhu_arang'   => $d1['suhu_arang']   ?? 0.0,
                'volume_arang' => $d1['volume_arang']  ?? 0.0,
            ],

            'bleaching' => [
                'suhu_bleaching' => $d2['suhu_bleaching'] ?? 0.0,
                'valve' => (bool)($d2['valve'] ?? false),
                'p1'    => (bool)($d2['p1']    ?? false),
                'p2'    => (bool)($d2['p2']    ?? false),
                'p3'    => (bool)($d2['p3']    ?? false),
                'h1'    => (bool)($d2['h1']    ?? false),
                'h2'    => (bool)($d2['h2']    ?? false),
                'h3'    => (bool)($d2['h3']    ?? false),
                'h4'    => (bool)($d2['h4']    ?? false),
                'speed' => $d2['speed'] ?? 0,
            ],

            'validasi' => [
                'volume_validasi' => $d3['volume_validasi'] ?? 0.0,
                'turbidity'       => $d3['turbidity']       ?? 0.0,
                'viscosity'       => $d3['viscosity']       ?? 0.0,
                'r'               => $d3['r']               ?? 0,
                'g'               => $d3['g']               ?? 0,
                'b'               => $d3['b']               ?? 0,
                'kelayakan'       => $d3['kelayakan']        ?? 0.0,
                'status_layak'    => $d3['status_layak']     ?? 'TIDAK LAYAK',
            ],
        ]);

        try {
            $this->mqtt->publish($publishTopik, $payload, 0);
            $this->line("  >> Re-published nested ke $publishTopik (Jalur Modular)");
        } catch (\Exception $e) {
            $this->error("  >> Gagal re-publish: " . $e->getMessage());
        }
    }
}

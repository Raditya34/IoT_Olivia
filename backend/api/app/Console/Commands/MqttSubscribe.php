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

    private array $buffer = [
        'OLIVIA-01'     => null,
        'OLIVIA-02'     => null,
        'OLIVIA-03'     => null,
        'OLIVIA-MASTER' => null,
    ];

    private ?MqttClient $mqtt = null;

    public function handle()
    {
        $server   = env('MQTT_HOST', 'a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud');
        $port     = (int) env('MQTT_PORT', 8883);
        $clientId = env('MQTT_CLIENT_ID', 'laravel_sub') . '_' . uniqid();
        $username = env('MQTT_USERNAME', 'Olivia_IoT');
        $password = env('MQTT_PASSWORD', 'Olivia12345');

        $subscribeTopik = env('MQTT_SUBSCRIBE_TOPIC', 'olivia/+/telemetry');
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
                $parts      = explode('/', $topic);
                $deviceCode = $parts[1] ?? 'UNKNOWN';

                $this->line("[" . now() . "] [$deviceCode] Data Diterima.");
                $data = json_decode($message, true);

                if (!is_array($data)) {
                    $this->error("Payload tidak valid JSON dari $deviceCode");
                    return;
                }

                // =================================================================
                // 🌟 PERBAIKAN: TRANSLATOR FLAT KE NESTED UNTUK OLIVIA-MASTER
                // =================================================================
                if ($deviceCode === 'OLIVIA-MASTER' && !isset($data['arang'])) {
                    $this->info("🔄 Mengonversi payload FLAT dari OLIVIA-MASTER menjadi NESTED...");

                    $data = [
                        'system_on'    => $data['system_on'] ?? false,
                        'current_step' => $data['current_step'] ?? 'STANDBY',
                        'arang' => [
                            'suhu_arang'   => $data['suhu_arang'] ?? 0.0,
                            'volume_arang' => $data['volume_arang'] ?? 0.0,
                        ],
                        'bleaching' => [
                            'suhu_bleaching' => $data['suhu_bleaching'] ?? 0.0,
                            'valve' => $data['valve'] ?? false,
                            'p1'    => $data['p1'] ?? false,
                            'p2'    => $data['p2'] ?? false,
                            'p3'    => $data['p3'] ?? false,
                            'h1'    => $data['h1'] ?? false,
                            'h2'    => $data['h2'] ?? false,
                            'h3'    => $data['h3'] ?? false,
                            'h4'    => $data['h4'] ?? false,
                            'speed' => $data['speed'] ?? 0,
                        ],
                        'validasi' => [
                            'volume_validasi' => $data['volume_validasi'] ?? 0.0,
                            'turbidity'       => $data['turbidity'] ?? 0.0,
                            'viscosity'       => $data['viscosity'] ?? 0.0,
                            'r'               => $data['r'] ?? 0,
                            'g'               => $data['g'] ?? 0,
                            'b'               => $data['b'] ?? 0,
                            'kelayakan'       => $data['kelayakan'] ?? 0.0,
                            'status_layak'    => $data['status_layak'] ?? 'TIDAK LAYAK',
                        ]
                    ];

                    // Timpa pesan asli dengan format JSON yang sudah dirapikan untuk dikirim ke Flutter
                    $message = json_encode($data);
                }
                // =================================================================

                // OPSI A: PAYLOAD GABUNGAN / NESTED
                if (isset($data['arang']) || isset($data['bleaching']) || isset($data['validasi'])) {
                    $this->info("⚡ Payload GABUNGAN dari [$deviceCode]. Memproses ke DB...");

                    if (isset($data['arang'])) {
                        try {
                            Esp1Arang::create([
                                'suhu_arang'   => $data['arang']['suhu_arang']   ?? 0.0,
                                'volume_arang' => $data['arang']['volume_arang'] ?? 0.0,
                            ]);
                            $this->info("  → DB Arang OK");
                        } catch (\Exception $e) { $this->error("  → Gagal DB Arang: " . $e->getMessage()); }
                    }

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
                        } catch (\Exception $e) { $this->error("  → Gagal DB Bleaching: " . $e->getMessage()); }
                    }

                    if (isset($data['validasi'])) {
                        try {
                            Esp3Validasi::create([
                                'volume_validasi' => $data['validasi']['volume_validasi'] ?? 0.0,
                                'turbidity'       => $data['validasi']['turbidity']       ?? 0.0,
                                'viscosity'       => $data['validasi']['viscosity']       ?? 0.0,
                                'r'               => $data['validasi']['r']               ?? 0,
                                'g'               => $data['validasi']['g']               ?? 0,
                                'b'               => $data['validasi']['b']               ?? 0,
                                'kelayakan'       => $data['validasi']['kelayakan']        ?? 0.0,
                                'status_layak'    => $data['validasi']['status_layak']     ?? 'TIDAK LAYAK',
                            ]);
                            $this->info("  → DB Validasi OK");
                        } catch (\Exception $e) { $this->error("  → Gagal DB Validasi: " . $e->getMessage()); }
                    }

                    if (isset($data['system_on'])) {
                        try {
                            MasterControl::query()->updateOrCreate([], ['system_on' => (bool)$data['system_on']]);
                        } catch (\Exception $e) { $this->error("  → Gagal sync MasterControl: " . $e->getMessage()); }
                    }

                    // Re-publish ke Flutter via topic olivia/telemetry
                    try {
                        $this->mqtt->publish($publishTopik, $message, 0);
                        $this->line("  >> Re-published ke Flutter [$publishTopik] Sukses!");
                    } catch (\Exception $e) {
                        $this->error("  >> Gagal re-publish: " . $e->getMessage());
                    }

                } else {
                    // OPSI B: FALLBACK JALUR MODULAR
                    $this->info("⚙ Payload MODULAR dari [$deviceCode]. Buffering...");
                    $this->simpanKeDatabase($deviceCode, $data);
                    $this->buffer[$deviceCode] = $data;

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
    $d1 = $this->buffer['OLIVIA-01'] ?? null;
    $d2 = $this->buffer['OLIVIA-02'] ?? null;
    $d3 = $this->buffer['OLIVIA-03'] ?? null;

    $master     = MasterControl::first();
    $isSystemOn = $master ? (bool)$master->system_on : false;

    // 🚀 AMBIL DATA TERAKHIR DARI DB JIKA BUFFER HARDWARE KOSONG (SAAT OFF)
    $lastArang     = Esp1Arang::latest('id')->first();
    $lastBleaching = Esp2Bleaching::latest('id')->first();
    $lastValidasi  = Esp3Validasi::latest('id')->first();

    $payload = json_encode([
        'system_on' => $isSystemOn,

        'arang' => [
            'suhu_arang'   => $d1['suhu_arang']   ?? ($lastArang ? (float)$lastArang->suhu_arang : 0.0),
            'volume_arang' => $d1['volume_arang']  ?? ($lastArang ? (float)$lastArang->volume_arang : 0.0),
        ],

        'bleaching' => [
            'suhu_bleaching' => $d2['suhu_bleaching'] ?? ($lastBleaching ? (float)$lastBleaching->suhu_bleaching : 0.0),
            'valve'          => (bool)($d2['valve']     ?? ($lastBleaching ? $lastBleaching->valve : false)),
            'p1'             => (bool)($d2['p1']        ?? ($lastBleaching ? $lastBleaching->p1 : false)),
            'p2'             => (bool)($d2['p2']        ?? ($lastBleaching ? $lastBleaching->p2 : false)),
            'p3'             => (bool)($d2['p3']        ?? ($lastBleaching ? $lastBleaching->p3 : false)),
            'h1'             => (bool)($d2['h1']        ?? ($lastBleaching ? $lastBleaching->h1 : false)),
            'h2'             => (bool)($d2['h2']        ?? ($lastBleaching ? $lastBleaching->h2 : false)),
            'h3'             => (bool)($d2['h3']        ?? ($lastBleaching ? $lastBleaching->h3 : false)),
            'h4'             => (bool)($d2['h4']        ?? ($lastBleaching ? $lastBleaching->h4 : false)),
            'speed'          => $d2['speed']            ?? ($lastBleaching ? (int)$lastBleaching->speed : 0),
        ],

        'validasi' => [
            'volume_validasi' => $d3['volume_validasi'] ?? ($lastValidasi ? (float)$lastValidasi->volume_validasi : 0.0),
            'turbidity'       => $d3['turbidity']       ?? ($lastValidasi ? (float)$lastValidasi->turbidity : 0.0),
            'viscosity'       => $d3['viscosity']       ?? ($lastValidasi ? (float)$lastValidasi->viscosity : 0.0),
            'r'               => $d3['r']               ?? ($lastValidasi ? (int)$lastValidasi->r : 0),
            'g'               => $d3['g']               ?? ($lastValidasi ? (int)$lastValidasi->g : 0),
            'b'               => $d3['b']               ?? ($lastValidasi ? (int)$lastValidasi->b : 0),
            'kelayakan'       => $d3['kelayakan']       ?? ($lastValidasi ? (float)$lastValidasi->kelayakan : 0.0),
            'status_layak'    => $d3['status_layak']    ?? ($lastValidasi ? $lastValidasi->status_layak : 'TIDAK LAYAK'),
        ],
    ]);

    try {
        $this->mqtt->publish($publishTopik, $payload, 0);
        $this->line("  >> Re-published nested ke $publishTopik (Smart Fallback DB)");
    } catch (\Exception $e) {
        $this->error("  >> Gagal re-publish: " . $e->getMessage());
    }
}
}

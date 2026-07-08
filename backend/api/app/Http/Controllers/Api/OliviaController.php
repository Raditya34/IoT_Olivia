<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;
use App\Models\MasterControl;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;

class OliviaController extends Controller
{
    /**
     * AMBIL DATA UNTUK DASHBOARD FLUTTER (Saat baru buka aplikasi)
     * Endpoint: GET /api/dashboard
     */
    public function getDashboardData()
    {
        try {
            $esp1 = Esp1Arang::orderBy('id', 'desc')->first();
            $esp2 = Esp2Bleaching::orderBy('id', 'desc')->first();
            $esp3 = Esp3Validasi::orderBy('id', 'desc')->first();
            $master = MasterControl::first();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'system_on' => (bool) ($master->system_on ?? false),
                    'process_step' => (int) ($master->process_step ?? 0),
                    'current_step' => $master->current_step ?? 'STANDBY',

                    'arang' => [
                        'suhu_arang'   => $esp1 ? (float)$esp1->suhu_arang : 0.0,
                        'volume_arang' => $esp1 ? (float)$esp1->volume_arang : 0.0
                    ],

                    'bleaching' => [
                        'suhu_bleaching' => $esp2 ? (float)$esp2->suhu_bleaching : 0.0,
                        'valve' => (bool)($esp2->valve ?? false),
                        'p1'    => (bool)($esp2->p1 ?? false),
                        'p2'    => (bool)($esp2->p2 ?? false),
                        'p3'    => (bool)($esp2->p3 ?? false),
                        'h1'    => (bool)($esp2->h1 ?? false),
                        'h2'    => (bool)($esp2->h2 ?? false),
                        'h3'    => (bool)($esp2->h3 ?? false),
                        'h4'    => (bool)($esp2->h4 ?? false),
                        'speed' => $esp2 ? (int)$esp2->speed : 0,
                    ],

                    'validasi' => [
                        'volume_validasi' => $esp3 ? (float)$esp3->volume_validasi : 0.0,
                        'turbidity'       => $esp3 ? (float)$esp3->turbidity : 0.0,
                        'viscosity'       => $esp3 ? (float)$esp3->viscosity : 0.0,
                        'r'               => $esp3 ? (int)$esp3->r : 0,
                        'g'               => $esp3 ? (int)$esp3->g : 0,
                        'b'               => $esp3 ? (int)$esp3->b : 0,
                        'kelayakan'       => $esp3 ? (float)$esp3->kelayakan : 0.0,
                        'status_layak'    => $esp3 ? $esp3->status_layak : 'TIDAK LAYAK',
                    ]
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error("Dashboard Telemetry Error: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

     public function storeMaster(Request $request)
    {
        try {
            // Ambil payload mentah jika dikirim dalam string atau ambil langsung dari request objek
            $data = $request->all();

            if (empty($data)) {
                return response()->json(['status' => 'error', 'message' => 'Payload kosong'], 400);
            }

            // 1. Ambil data utama sistem (opsional jika ingin mencocokkan master control database)
            $systemOn = filter_var($data['system_on'] ?? false, FILTER_VALIDATE_BOOLEAN);
            $master = MasterControl::first();
            if ($master) {
                $master->update(['system_on'    => $systemOn,
                                'process_step' => (int) ($data['process_step'] ?? $master->process_step),
                                'current_step' => $data['current_step'] ?? $master->current_step,]);
            }

    // SIMPAN DATA ARANG LANGSUNG DARI FLAT PAYLOAD
        Esp1Arang::create([
            'suhu_arang'   => (float)($data['suhu_arang'] ?? 0),
            'volume_arang' => (float)($data['volume_arang'] ?? 0),
        ]);

        // SIMPAN DATA BLEACHING
        Esp2Bleaching::create([
            'suhu_bleaching' => (float)($data['suhu_bleaching'] ?? 0),
            'valve'          => (bool)($data['valve'] ?? false),
            'p1'             => (bool)($data['p1'] ?? false),
            'p2'             => (bool)($data['p2'] ?? false),
            'p3'             => (bool)($data['p3'] ?? false),
            'h1'             => (bool)($data['h1'] ?? false),
            'h2'             => (bool)($data['h2'] ?? false),
            'h3'             => (bool)($data['h3'] ?? false),
            'h4'             => (bool)($data['h4'] ?? false),
            'speed'          => (int)($data['speed'] ?? 0),
        ]);

        // SIMPAN DATA VALIDASI
        Esp3Validasi::create([
            'volume_validasi' => (float)($data['volume_validasi'] ?? 0),
            'turbidity'       => (float)($data['turbidity'] ?? 0),
            'viscosity'       => (float)($data['viscosity'] ?? 0),
            'r'               => (int)($data['r'] ?? 0),
            'g'               => (int)($data['g'] ?? 0),
            'b'               => (int)($data['b'] ?? 0),
            'kelayakan'       => (float)($data['kelayakan'] ?? 0),
            'status_layak'    => $data['status_layak'] ?? 'TIDAK LAYAK',
        ]);


                 return response()->json(['status' => 'success'], 201);
    } catch (\Exception $e) {
        return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
    }
}


    /**
     * AMBIL DATA REKAP HISTORY
     * Endpoint: GET /api/history
     */
    public function getHistory()
    {
        try {
            $arang     = Esp1Arang::orderBy('id', 'desc')->take(50)->get();
            $bleaching = Esp2Bleaching::orderBy('id', 'desc')->take(50)->get();
            $validasi  = Esp3Validasi::orderBy('id', 'desc')->take(50)->get();

            return response()->json([
                'status' => 'success',
                'data'   => [
                    'arang'     => $arang,
                    'bleaching' => $bleaching,
                    'validasi'  => $validasi,
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error("Get History Error: " . $e->getMessage());
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * SIMPAN DATA DARI ESP32 VIA HTTP POST
     */
    public function storeEsp1(Request $request) {
        try {
            $data = $request->all();
            $arangData = $data['arang'] ?? $data;
            $esp1 = Esp1Arang::create([
                'suhu_arang'   => $data['suhu_arang'] ?? 0,
                'volume_arang' => $data['volume_arang'] ?? 0
            ]);
            return response()->json(['status' => 'success', 'data' => $esp1], 201);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function storeEsp2(Request $request) {
        try {
            $data = $request->has('payload') ? json_decode($request->input('payload'), true) : $request->all();
            $res = Esp2Bleaching::create([
                'suhu_bleaching' => $data['suhu_bleaching'] ?? 0,
                'valve' => filter_var($data['valve'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'p1'    => filter_var($data['p1'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'p2'    => filter_var($data['p2'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'p3'    => filter_var($data['p3'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'h1'    => filter_var($data['h1'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'h2'    => filter_var($data['h2'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'h3'    => filter_var($data['h3'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'h4'    => filter_var($data['h4'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'speed' => $data['speed'] ?? 0,
            ]);
            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function storeEsp3(Request $request) {
        try {
            $data = $request->has('payload') ? json_decode($request->input('payload'), true) : $request->all();
            $res = Esp3Validasi::create([
                'volume_validasi' => $data['volume_validasi'] ?? 0,
                'turbidity'       => $data['turbidity'] ?? 0,
                'viscosity'       => $data['viscosity'] ?? 0,
                'r'               => $data['r'] ?? 0,
                'g'               => $data['g'] ?? 0,
                'b'               => $data['b'] ?? 0,
                'kelayakan'       => $data['kelayakan'] ?? 0.0,
                'status_layak'    => $data['status_layak'] ?? 'TIDAK LAYAK',
            ]);
            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * TOGGLE SYSTEM ON/OFF FROM FLUTTER -> DATABASE
     */
    public function updateControl(Request $request) {
        try {
            $master = MasterControl::firstOrCreate([], ['system_on' => false]);
            if ($request->has('system_on')) {
                $status = filter_var($request->system_on, FILTER_VALIDATE_BOOLEAN);

                // 1. Simpan ke Database (Aman dari 500 Error)
                $master->system_on = $status;
                $master->save();
            }
            // Setelah update, publish acknowledgement ke topic control/response
            try {
                $server   = env('MQTT_HOST', '127.0.0.1');
                $port     = (int) env('MQTT_PORT', 1883);
                $clientId = env('MQTT_CLIENT_ID', 'laravel_pub') . '_' . uniqid();
                $username = env('MQTT_USERNAME', null);
                $password = env('MQTT_PASSWORD', null);

                $mqtt = new MqttClient($server, $port, $clientId, MqttClient::MQTT_3_1_1);
                $settings = (new ConnectionSettings)
                    ->setUsername($username)
                    ->setPassword($password)
                    ->setKeepAliveInterval(60)
                    ->setConnectTimeout(10)
                    ->setUseTls(true)
                    ->setTlsSelfSignedAllowed(false);

                $mqtt->connect($settings, true);

                $payload = json_encode([
                    'system_on' => (bool) $master->system_on,
                    'timestamp' => now()->toIso8601String(),
                    'source' => 'api'
                ]);

                $responseTopic = env('MQTT_CONTROL_RESPONSE_TOPIC', 'olivia/control/response');
                $mqtt->publish($responseTopic, $payload, 0);
                $mqtt->disconnect();
            } catch (\Exception $e) {
                Log::warning('MQTT publish control response failed: ' . $e->getMessage());
            }

            return response()->json(['status' => 'success', 'data' => $master], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}

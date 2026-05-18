<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;
use App\Models\MasterControl;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class OliviaController extends Controller
{
    /**
     * AMBIL DATA UNTUK DASHBOARD FLUTTER
     * Endpoint: GET /api/dashboard
     */
    public function getDashboardData()
    {
        try {
            $esp1 = Esp1Arang::latest()->first();
            $esp2 = Esp2Bleaching::latest()->first();
            $esp3 = Esp3Validasi::latest()->first();

            return response()->json([
                'success' => true,
                'system_status' => (bool) (MasterControl::first()->system_on ?? false),

                // MAPPING DATA ESP1 KE FORMAT FLUTTER (suhu1, suhu2, tinggi, volume)
                'arang' => [
                    'suhu1' => $esp1 ? (float)$esp1->suhu : 0,
                    'suhu2' => $esp1 ? (float)$esp1->suhu : 0, // Fallback (pakai suhu yg sama)
                    'tinggi' => 0, // Fallback sementara
                    'volume' => $esp1 ? (float)$esp1->volume : 0
                ],

                // MAPPING DATA ESP2
                'bleaching' => $esp2 ?: [
                    'suhu' => 0, 'valve' => false, 'pompa_1' => false, 'pompa_2' => false,
                    'pompa_3' => false, 'heater_1' => false, 'heater_2' => false,
                    'heater_3' => false, 'heater_4' => false, 'motor_ac_speed' => 0
                ],

                // MAPPING DATA ESP3 (sesuaikan dengan format dashboard_controller flutter)
                'validasi' => $esp3 ?: [
                    'volume' => 0, 'turbidity' => 0, 'viskositas' => 0, 'warna' => '-',
                    'tegangan' => 0, 'r' => 0, 'g' => 0, 'b' => 0
                ]
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * STORE DATA DARI ESP1
     * Endpoint: POST /api/iot/esp1/store
     */
    public function storeEsp1(Request $request)
    {
        try {
            // 1. Bongkar format EMQX Webhook (Ambil string JSON di dalam "payload")
            if ($request->has('payload')) {
                $data = json_decode($request->input('payload'), true);
            } else {
                $data = $request->all(); // Fallback jika tes via Postman
            }

            // 2. Simpan ke Database
            $res = Esp1Arang::create([
                // ESP ngirim "suhu1", tapi DB kita cm punya "suhu", jadi kita jembatani
                'suhu'     => $data['suhu1'] ?? $data['suhu'] ?? 0,
                'volume'   => $data['volume'] ?? 0,
            ]);

            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            Log::error("Store ESP1 Error: " . $e->getMessage());
            return response()->json(['status' => 'error'], 400);
        }
    }

    /**
     * STORE DATA DARI ESP2
     * Endpoint: POST /api/iot/esp2/store
     */
    public function storeEsp2(Request $request)
    {
        try {
            if ($request->has('payload')) {
                $data = json_decode($request->input('payload'), true);
            } else {
                $data = $request->all();
            }

            $res = Esp2Bleaching::create([
                'suhu'           => $data['suhu'] ?? 0,
                'valve'          => filter_var($data['valve'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'pompa_1'        => filter_var($data['pompa_1'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'pompa_2'        => filter_var($data['pompa_2'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'pompa_3'        => filter_var($data['pompa_3'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_1'       => filter_var($data['heater_1'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_2'       => filter_var($data['heater_2'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_3'       => filter_var($data['heater_3'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_4'       => filter_var($data['heater_4'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'motor_ac_speed' => $data['motor_ac_speed'] ?? 0,
            ]);

            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            Log::error("Store ESP2 Error: " . $e->getMessage());
            return response()->json(['status' => 'error'], 400);
        }
    }

    /**
     * STORE DATA DARI ESP3
     * Endpoint: POST /api/iot/esp3/store
     */
    public function storeEsp3(Request $request)
    {
        try {
            if ($request->has('payload')) {
                $data = json_decode($request->input('payload'), true);
            } else {
                $data = $request->all();
            }

            $res = Esp3Validasi::create([
                'volume'     => $data['volume'] ?? 0,
                'turbidity'  => $data['turbidity'] ?? 0,
                'viskositas' => $data['viskositas'] ?? 0,
                'warna'      => $data['warna'] ?? '-',
            ]);

            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            Log::error("Store ESP3 Error: " . $e->getMessage());
            return response()->json(['status' => 'error'], 400);
        }
    }

    /**
     * TOGGLE SYSTEM ON/OFF
     * Endpoint: POST /api/control
     */
    public function updateControl(Request $request)
    {
        try {
            $master = MasterControl::first();
            if (!$master) {
                $master = MasterControl::create(['system_on' => false]);
            }

            if ($request->has('system_on')) {
                $master->system_on = filter_var($request->system_on, FILTER_VALIDATE_BOOLEAN);
                $master->save();
            }

            return response()->json(['success' => true, 'data' => $master], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 500);
        }
    }
}

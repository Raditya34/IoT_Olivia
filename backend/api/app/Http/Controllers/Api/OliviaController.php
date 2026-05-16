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
            return response()->json([
                'success' => true,
                'system_status' => (bool) (MasterControl::first()->system_on ?? false),

                'arang' => Esp1Arang::latest()->first() ?: [
                    'suhu' => 0,
                    'volume' => 0
                ],

                'bleaching' => Esp2Bleaching::latest()->first() ?: [
                    'suhu' => 0,
                    'valve' => false,
                    'pompa_1' => false,
                    'pompa_2' => false,
                    'pompa_3' => false,
                    'heater_1' => false,
                    'heater_2' => false,
                    'heater_3' => false, // Ditambahkan ke response dashboard
                    'heater_4' => false, // Ditambahkan ke response dashboard
                    'motor_ac_speed' => 0
                ],

                'validasi' => Esp3Validasi::latest()->first() ?: [
                    'volume' => 0,
                    'turbidity' => 0,
                    'viskositas' => 0,
                    'warna' => '-'
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function updateControl(Request $request)
    {
        try {
            $systemOn = $request->input('system_on', false);
            $control = MasterControl::first() ?: new MasterControl;
            $control->system_on = filter_var($systemOn, FILTER_VALIDATE_BOOLEAN);
            $control->save();

            return response()->json([
                'success' => true,
                'system_on' => (bool)$control->system_on
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }

    public function getHistory()
    {
        try {
            return response()->json([
                'arang' => Esp1Arang::latest()->take(20)->get(),
                'bleaching' => Esp2Bleaching::latest()->take(20)->get(),
                'validasi' => Esp3Validasi::latest()->take(20)->get(),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // --- METHODS UNTUK WEBHOOK STORAGE EMQX ---

    public function storeEsp1(Request $request)
    {
        try {
            $data = $request->all();
            $res = Esp1Arang::create([
                'suhu'   => $data['suhu'] ?? 0,
                'volume' => $data['volume'] ?? 0,
            ]);
            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error'], 400);
        }
    }

    public function storeEsp2(Request $request)
    {
        try {
            $data = $request->all();

            $res = Esp2Bleaching::create([
                'suhu'           => $data['suhu'] ?? 0,
                'valve'          => filter_var($data['valve'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'pompa_1'        => filter_var($data['pompa_1'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'pompa_2'        => filter_var($data['pompa_2'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'pompa_3'        => filter_var($data['pompa_3'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_1'       => filter_var($data['heater_1'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_2'       => filter_var($data['heater_2'] ?? false, FILTER_VALIDATE_BOOLEAN),
                'heater_3'       => filter_var($data['heater_3'] ?? false, FILTER_VALIDATE_BOOLEAN), // Sesuai data hardware baru
                'heater_4'       => filter_var($data['heater_4'] ?? false, FILTER_VALIDATE_BOOLEAN), // Sesuai data hardware baru
                'motor_ac_speed' => $data['motor_ac_speed'] ?? 0,
            ]);

            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            Log::error("Store ESP2 Error: " . $e->getMessage());
            return response()->json(['status' => 'error'], 400);
        }
    }

    public function storeEsp3(Request $request)
    {
        try {
            $data = $request->all();

            $res = Esp3Validasi::create([
                'volume'     => $data['volume'] ?? 0,
                'turbidity'  => $data['turbidity'] ?? 0,
                'viskositas' => $data['viskositas'] ?? 0,
                'warna'      => $data['warna'] ?? '-',
            ]);

            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error'], 400);
        }
    }
}

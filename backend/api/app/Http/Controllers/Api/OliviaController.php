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
                // Status sistem ON/OFF secara global
                'system_status' => (bool) (MasterControl::first()->system_on ?? false),

                // Data terbaru dari Unit 1
                'arang' => Esp1Arang::latest()->first() ?: [
                    'suhu' => 0,
                    'volume' => 0
                ],

                // Data terbaru dari Unit 2
                'bleaching' => Esp2Bleaching::latest()->first() ?: [
                    'suhu' => 0,
                    'valve' => false,
                    'pompa_1' => false,
                    'pompa_2' => false,
                    'pompa_3' => false,
                    'heater_1' => false,
                    'heater_2' => false,
                    'motor_ac_speed' => 0
                ],

                // Data terbaru dari Unit 3
                'validasi' => Esp3Validasi::latest()->first() ?: [
                    'volume' => 0,
                    'turbidity' => 0,
                    'viskositas' => 0,
                    'warna' => '-'
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data dashboard: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * KONTROL ON/OFF DARI FLUTTER
     * Endpoint: POST /api/control
     */
    public function updateControl(Request $request)
    {
        $request->validate(['system_on' => 'required|boolean']);

        try {
            $control = MasterControl::first() ?: new MasterControl;
            $control->system_on = $request->system_on;
            $control->save();

            return response()->json([
                'success' => true,
                'message' => 'Status sistem berhasil diubah.',
                'system_on' => (bool) $control->system_on
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * AMBIL HISTORY DARI SEMUA UNIT
     * Endpoint: GET /api/history
     */
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

    // --- METHODS UNTUK TESTING / MANUAL INSERT (OPSIONAL) ---

    public function storeEsp1(Request $request)
    {
        $validated = $request->validate(['suhu' => 'required|numeric', 'volume' => 'required|numeric']);
        return response()->json(Esp1Arang::create($validated), 201);
    }

    public function storeEsp2(Request $request)
    {
        $validated = $request->validate([
            'suhu' => 'required|numeric',
            'valve' => 'required|boolean',
            'pompa_1' => 'required|boolean',
            'pompa_2' => 'required|boolean',
            'pompa_3' => 'required|boolean',
            'heater_1' => 'required|boolean',
            'heater_2' => 'required|boolean',
            'motor_ac_speed' => 'required|integer',
        ]);
        return response()->json(Esp2Bleaching::create($validated), 201);
    }

    public function storeEsp3(Request $request)
    {
        $validated = $request->validate([
            'volume' => 'required|numeric',
            'turbidity' => 'required|numeric',
            'viskositas' => 'required|numeric',
            'warna' => 'required|string',
        ]);
        return response()->json(Esp3Validasi::create($validated), 201);
    }
}

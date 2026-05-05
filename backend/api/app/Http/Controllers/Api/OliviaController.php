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
    // --- FRONTEND METHODS (FLUTTER) ---

    public function getDashboardData()
    {
        return response()->json([
            'system_status' => MasterControl::first()->system_on ?? false,
            'arang' => Esp1Arang::latest()->first() ?? ['suhu' => 0, 'volume' => 0],
            'bleaching' => Esp2Bleaching::latest()->first() ?? [
                'suhu' => 0, 'valve' => false, 'pompa_1' => false, 'pompa_2' => false,
                'pompa_3' => false, 'heater_1' => false, 'heater_2' => false, 'motor_ac_speed' => 0
            ],
            'validasi' => Esp3Validasi::latest()->first() ?? [
                'volume' => 0, 'turbidity' => 0, 'viskositas' => 0, 'warna' => '-'
            ],
        ]);
    }

    public function updateControl(Request $request)
    {
        $request->validate(['system_on' => 'required|boolean']);
        $control = MasterControl::first() ?: new MasterControl;
        $control->system_on = $request->system_on;
        $control->save();

        return response()->json([
            'message' => $control->system_on ? 'Sistem Dinyalakan' : 'Sistem Dimatikan',
            'data' => $control
        ]);
    }

    public function getHistory()
    {
        return response()->json([
            'arang' => Esp1Arang::latest()->take(20)->get(),
            'bleaching' => Esp2Bleaching::latest()->take(20)->get(),
            'validasi' => Esp3Validasi::latest()->take(20)->get(),
        ]);
    }

    // --- IOT METHODS (ESP32 via EMQX) ---

    public function storeEsp1(Request $request)
    {
        try {
            $validated = $request->validate(['suhu' => 'required|numeric', 'volume' => 'required|numeric']);
            return response()->json(Esp1Arang::create($validated), 201);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function storeEsp2(Request $request)
    {
        try {
            $validated = $request->validate([
                'suhu' => 'required|numeric', 'valve' => 'required|boolean',
                'pompa_1' => 'required|boolean', 'pompa_2' => 'required|boolean',
                'pompa_3' => 'required|boolean', 'heater_1' => 'required|boolean',
                'heater_2' => 'required|boolean', 'motor_ac_speed' => 'required|integer',
            ]);
            return response()->json(Esp2Bleaching::create($validated), 201);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function storeEsp3(Request $request)
    {
        try {
            $validated = $request->validate([
                'volume' => 'required|numeric', 'turbidity' => 'required|numeric',
                'viskositas' => 'required|numeric', 'warna' => 'required|string',
            ]);
            return response()->json(Esp3Validasi::create($validated), 201);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}

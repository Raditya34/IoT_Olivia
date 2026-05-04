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
    public function getDashboardData()
    {
        return response()->json([
            'arang' => Esp1Arang::latest()->first() ?? ['suhu' => 0, 'volume' => 0],
            'bleaching' => Esp2Bleaching::latest()->first() ?? ['suhu' => 0],
            'validasi' => Esp3Validasi::latest()->first() ?? ['turbidity' => 0, 'viscosity' => 0, 'warna' => '-'],
            'control' => MasterControl::first() ?? [
                'system_on' => false,
                'heater' => false,
                'pompa' => false,
                'motor_ac' => false,
                'servo_pos' => 0
            ]
        ]);
    }

    public function updateControl(Request $request)
    {
        $control = MasterControl::first() ?: new MasterControl;
        $control->fill($request->only([
            'system_on', 'heater', 'pompa', 'motor_ac', 'servo_pos'
        ]));
        $control->save();

        return response()->json(['message' => 'Kontrol diperbarui', 'data' => $control]);
    }

    // Endpoint IoT dengan Error Logging
    public function storeEsp1(Request $request) {
        try {
            $data = Esp1Arang::create($request->all());
            return response()->json($data, 201);
        } catch (\Exception $e) {
            Log::error("Error ESP1: " . $e->getMessage());
            return response()->json(['error' => 'Gagal simpan data'], 500);
        }
    }

    public function storeEsp2(Request $request) {
        try {
            $data = Esp2Bleaching::create($request->all());
            return response()->json($data, 201);
        } catch (\Exception $e) {
            Log::error("Error ESP2: " . $e->getMessage());
            return response()->json(['error' => 'Gagal simpan data'], 500);
        }
    }

    public function storeEsp3(Request $request) {
        try {
            $data = Esp3Validasi::create($request->all());
            return response()->json($data, 201);
        } catch (\Exception $e) {
            Log::error("Error ESP3: " . $e->getMessage());
            return response()->json(['error' => 'Gagal simpan data'], 500);
        }
    }
}

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
     * ==========================================
     * ENDPOINT UNTUK FRONTEND (FLUTTER APP)
     * ==========================================
     */

    // 1. Ambil data terbaru untuk Dashboard & Monitor Real-time
    public function getDashboardData()
    {
        return response()->json([
            'system_status' => MasterControl::first()->system_on ?? false,
            'arang' => Esp1Arang::latest()->first() ?? [
                'suhu' => 0, 'volume' => 0
            ],
            'bleaching' => Esp2Bleaching::latest()->first() ?? [
                'suhu' => 0, 'valve' => false, 'pompa_1' => false,
                'pompa_2' => false, 'pompa_3' => false,
                'heater_1' => false, 'heater_2' => false, 'motor_ac_speed' => 0
            ],
            'validasi' => Esp3Validasi::latest()->first() ?? [
                'volume' => 0, 'turbidity' => 0, 'viskositas' => 0, 'warna' => '-'
            ],
        ]);
    }

    // 2. Tombol ON/OFF Keseluruhan Sistem dari Dashboard
    public function updateControl(Request $request)
    {
        $request->validate([
            'system_on' => 'required|boolean'
        ]);

        $control = MasterControl::first() ?: new MasterControl;
        $control->system_on = $request->system_on;
        $control->save();

        $statusMessage = $control->system_on ? 'Sistem Dinyalakan' : 'Sistem Dimatikan';

        return response()->json([
            'message' => $statusMessage,
            'data' => $control
        ]);
    }

    // 3. Ambil Data History untuk Halaman History di App
    public function getHistory()
    {
        return response()->json([
            // Mengambil 20 data terakhir untuk masing-masing proses
            'arang' => Esp1Arang::latest()->take(20)->get(),
            'bleaching' => Esp2Bleaching::latest()->take(20)->get(),
            'validasi' => Esp3Validasi::latest()->take(20)->get(),
        ]);
    }


    /**
     * ==========================================
     * ENDPOINT UNTUK IOT (EMQX / ESP32)
     * ==========================================
     */

    // ESP 1: Arang
    public function storeEsp1(Request $request)
    {
        try {
            $validated = $request->validate([
                'suhu'   => 'required|numeric',
                'volume' => 'required|numeric',
            ]);

            $data = Esp1Arang::create($validated);
            return response()->json($data, 201);

        } catch (\Exception $e) {
            Log::error("Error ESP1: " . $e->getMessage());
            return response()->json(['error' => 'Gagal simpan data ESP1'], 500);
        }
    }

    // ESP 2: Bleaching (Sensor & Status Aktuator)
    public function storeEsp2(Request $request)
    {
        try {
            $validated = $request->validate([
                'suhu'           => 'required|numeric',
                'valve'          => 'required|boolean',
                'pompa_1'        => 'required|boolean',
                'pompa_2'        => 'required|boolean',
                'pompa_3'        => 'required|boolean',
                'heater_1'       => 'required|boolean',
                'heater_2'       => 'required|boolean',
                'motor_ac_speed' => 'required|integer',
            ]);

            $data = Esp2Bleaching::create($validated);
            return response()->json($data, 201);

        } catch (\Exception $e) {
            Log::error("Error ESP2: " . $e->getMessage());
            return response()->json(['error' => 'Gagal simpan data ESP2'], 500);
        }
    }

    // ESP 3: Validasi
    public function storeEsp3(Request $request)
    {
        try {
            $validated = $request->validate([
                'volume'     => 'required|numeric',
                'turbidity'  => 'required|numeric',
                'viskositas' => 'required|numeric',
                'warna'      => 'required|string',
            ]);

            $data = Esp3Validasi::create($validated);
            return response()->json($data, 201);

        } catch (\Exception $e) {
            Log::error("Error ESP3: " . $e->getMessage());
            return response()->json(['error' => 'Gagal simpan data ESP3'], 500);
        }
    }
}

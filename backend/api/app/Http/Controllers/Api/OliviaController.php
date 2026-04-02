<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;
use App\Models\MasterControl;
use Illuminate\Http\Request;

class OliviaController extends Controller
{
    // Ambil semua data terbaru untuk Dashboard & 3 Halaman Monitor
    public function getDashboardData()
    {
        return response()->json([
            'esp1' => Esp1Arang::latest()->first(),
            'esp2' => Esp2Bleaching::latest()->first(),
            'esp3' => Esp3Validasi::latest()->first(),
            'control' => MasterControl::latest()->first(),
        ]);
    }

    // Update kontrol dari Flutter Dashboard
    public function updateControl(Request $request)
    {
        // Ambil data pertama, jika tidak ada maka buat baru
        $control = MasterControl::first() ?: new MasterControl;

        $control->fill($request->only([
            'system_on', 'heater', 'pompa', 'motor_ac', 'servo_pos'
        ]));

        $control->save();

        return response()->json(['message' => 'Kontrol diperbarui', 'data' => $control]);
    }

    // Endpoint untuk ESP mengirim data (Simpan ke DB)
    public function storeEsp1(Request $request) {
        return response()->json(Esp1Arang::create($request->all()), 201);
    }

    public function storeEsp2(Request $request) {
        return response()->json(Esp2Bleaching::create($request->all()), 201);
    }

    public function storeEsp3(Request $request) {
        return response()->json(Esp3Validasi::create($request->all()), 201);
    }
}

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
     * Endpoint: GET /api/dashboard/telemetry
     */
    public function getDashboardData()
    {
        try {
            // PERBAIKAN UTAMA: Menggunakan orderBy('id', 'desc') karena tidak ada kolom created_at
            $esp1 = Esp1Arang::orderBy('id', 'desc')->first();
            $esp2 = Esp2Bleaching::orderBy('id', 'desc')->first();
            $esp3 = Esp3Validasi::orderBy('id', 'desc')->first();
            $master = MasterControl::first();

            // Format kembalian HARUS sama dengan ekspektasi Frontend
            return response()->json([
                'status' => 'success',
                'data' => [
                    'system_on' => (bool) ($master->system_on ?? false),

                    'arang' => [
                        'suhu_arang' => $esp1 ? (float)$esp1->suhu_arang : 0.0,
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
                    ]
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error("Dashboard Telemetry Error: " . $e->getMessage());
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
            // PERBAIKAN: Menggunakan orderBy id desc untuk menghindari error created_at
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
     * STORE DATA DARI WEBHOOK / API POST ESP32 (HARDWARE 1)
     */
    public function storeEsp1(Request $request) {
        try {
            $data = $request->has('payload') ? json_decode($request->input('payload'), true) : $request->all();
            $res = Esp1Arang::create([
                'suhu_arang'   => $data['suhu_arang'] ?? 0,
                'volume_arang' => $data['volume_arang'] ?? 0
            ]);
            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * STORE DATA DARI WEBHOOK / API POST ESP32 (HARDWARE 2)
     */
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

    /**
     * STORE DATA DARI WEBHOOK / API POST ESP32 (HARDWARE 3)
     */
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
            ]);
            return response()->json(['status' => 'success', 'data' => $res], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * TOGGLE SYSTEM ON/OFF FROM FLUTTER
     */
    public function updateControl(Request $request) {
        try {
            $master = MasterControl::firstOrCreate([], ['system_on' => false]);
            if ($request->has('system_on')) {
                $master->system_on = filter_var($request->system_on, FILTER_VALIDATE_BOOLEAN);
                $master->save();
            }
            // Disamakan standard status 'success' dengan endpoint lainnya
            return response()->json(['status' => 'success', 'data' => $master], 200);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}

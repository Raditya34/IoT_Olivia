<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\Telemetry;
use Illuminate\Http\Request;

class TelemetryController extends Controller
{
    // GET /api/telemetries/latest?device=OLIVIA-01
    public function latest(Request $request)
    {
        $deviceCode = $request->query('device');
        if (!$deviceCode) {
            return response()->json(['message' => 'Query parameter "device" is required.'], 422);
        }

        // GANTI 'device_code' sesuai kolom device kamu
        $device = Device::where('device_code', $deviceCode)->first();
        if (!$device) {
            return response()->json(['message' => "Device not found: {$deviceCode}"], 404);
        }

        $telemetry = Telemetry::where('device_id', $device->id)
            ->latest('received_at')
            ->first();

        return response()->json([
            'device' => $deviceCode,
            'data' => $telemetry,
        ]);
    }

    // GET /api/telemetries?device=OLIVIA-01&limit=100
    public function index(Request $request)
    {
        $deviceCode = $request->query('device');
        $limit = (int) $request->query('limit', 50);
        $limit = max(1, min($limit, 500));

        if (!$deviceCode) {
            return response()->json(['message' => 'Query parameter "device" is required.'], 422);
        }

        // GANTI 'device_code' sesuai kolom device kamu
        $device = Device::where('device_code', $deviceCode)->first();
        if (!$device) {
            return response()->json(['message' => "Device not found: {$deviceCode}"], 404);
        }

        $rows = Telemetry::where('device_id', $device->id)
            ->latest('received_at')
            ->limit($limit)
            ->get();

        return response()->json([
            'device' => $deviceCode,
            'count' => $rows->count(),
            'data' => $rows,
        ]);
    }
}

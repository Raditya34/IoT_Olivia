<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function getLatestData(): JsonResponse
    {
        return response()->json([
            'esp1' => Esp1Arang::latest()->first(),
            'esp2' => Esp2Bleaching::latest()->first(),
            'esp3' => Esp3Validasi::latest()->first(),
        ]);
    }
}

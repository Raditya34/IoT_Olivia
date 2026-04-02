<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Device;

class DeviceController extends Controller
{
    // GET /api/devices
    public function index(Request $request)
    {
        $devices = Device::where('user_id', $request->user()->id)->get();

        return response()->json([
            'user'=> $request->user(),
            'data' => $devices
        ]);
    }
}

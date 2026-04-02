<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\TelemetryController;

Route::get('/telemetries/latest', [TelemetryController::class, 'latest']);
Route::get('/telemetries', [TelemetryController::class, 'index']);


Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // 🔥 DEVICES
    Route::get('/devices', [DeviceController::class, 'index']);

    // 🔥 TELEMETRY
    Route::get('/devices/{id}/latest', [TelemetryController::class, 'latest']);
    Route::get('/devices/{id}/telemetries', [TelemetryController::class, 'list']);
});

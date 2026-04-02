<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OliviaController;

// Auth Public
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Route Modular Baru
    Route::get('/dashboard', [OliviaController.class, 'getDashboardData']);
    Route::post('/control', [OliviaController.class, 'updateControl']);
}); // <--- PASTIKAN TANDA INI ADA UNTUK MENUTUP MIDDLEWARE

// IoT Endpoints (Tanpa Auth agar ESP32 mudah akses)
Route::post('/esp1/store', [OliviaController.class, 'storeEsp1']);
Route::post('/esp2/store', [OliviaController.class, 'storeEsp2']);
Route::post('/esp3/store', [OliviaController.class, 'storeEsp3']);

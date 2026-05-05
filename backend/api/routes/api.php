<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OliviaController;

// Public Auth
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// Protected Flutter Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/dashboard', [OliviaController::class, 'getDashboardData']);
    Route::post('/control', [OliviaController::class, 'updateControl']);
    Route::get('/history', [OliviaController::class, 'getHistory']);
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
});

// IoT Endpoints (EMQX Access)
Route::post('/esp1/store', [OliviaController::class, 'storeEsp1']);
Route::post('/esp2/store', [OliviaController::class, 'storeEsp2']);
Route::post('/esp3/store', [OliviaController::class, 'storeEsp3']);

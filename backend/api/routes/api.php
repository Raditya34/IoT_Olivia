<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OliviaController;
use App\Http\Controllers\Api\NotificationController;

// --- 1. Public Auth (Bisa diakses tanpa login) ---
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// --- 2. Protected Flutter Routes (Harus Login / Pakai Token) ---
Route::middleware('auth:sanctum')->group(function () {

    // Dashboard & Control (Sesuai dengan _api.get('/dashboard/telemetry') di Flutter)
    Route::get('/dashboard/telemetry', [OliviaController::class, 'getDashboardData']);
    Route::post('/control', [OliviaController::class, 'updateControl']);

    // Fitur Tambahan (Opsional)
    Route::get('/history', [OliviaController::class, 'getHistory']);

    // User Profile & Logout
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'getUnread']);
        Route::get('/all', [NotificationController::class, 'getAll']);
        Route::get('/count', [NotificationController::class, 'getUnreadCount']);
        Route::put('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::put('/read-all', [NotificationController::class, 'markAllAsRead']);
    });

    Route::prefix('process-history')->group(function () {
        Route::get('/', [NotificationController::class, 'getProcessHistory']);
        Route::get('/current', [NotificationController::class, 'getCurrentCycleHistory']);
    });
});

// --- 3. IoT Endpoints (Untuk testing manual atau EMQX Webhook) ---
Route::prefix('iot')->group(function () {
    Route::post('/esp1/store', [OliviaController::class, 'storeEsp1']);
    Route::post('/esp2/store', [OliviaController::class, 'storeEsp2']);
    Route::post('/esp3/store', [OliviaController::class, 'storeEsp3']);
});

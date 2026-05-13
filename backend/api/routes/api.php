<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\OliviaController;
use App\Http\Controllers\Api\NotificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// --- 1. Public Auth (Bisa diakses tanpa login) ---
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// --- 2. Protected Flutter Routes (Harus Login / Pakai Token) ---
Route::middleware('auth:sanctum')->group(function () {

    // Dashboard & Control (Menggunakan OliviaController yang baru)
    Route::get('/dashboard', [OliviaController::class, 'getDashboardData']);
    Route::post('/control', [OliviaController::class, 'updateControl']);

    // Fitur Tambahan (Opsional)
    Route::get('/history', [OliviaController::class, 'getHistory']); // Jika kamu buat fungsi history

    // User Profile & Logout
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'getUnread']); // Notifikasi unread
        Route::get('/all', [NotificationController::class, 'getAll']); // Semua notifikasi
        Route::get('/count', [NotificationController::class, 'getUnreadCount']); // Hitung unread
        Route::put('/{id}/read', [NotificationController::class, 'markAsRead']); // Mark 1 notif
        Route::put('/read-all', [NotificationController::class, 'markAllAsRead']); // Mark semua
    });

    Route::prefix('process-history')->group(function () {
        Route::get('/', [NotificationController::class, 'getProcessHistory']); // Semua history
        Route::get('/current', [NotificationController::class, 'getCurrentCycleHistory']); // Cycle sekarang
    });
});

// --- 3. IoT Endpoints (Untuk testing manual atau EMQX Webhook) ---
// Route ini tetap ada jika kamu ingin melakukan testing input data via Postman
Route::prefix('iot')->group(function () {
    Route::post('/esp1/store', [OliviaController::class, 'storeEsp1']);
    Route::post('/esp2/store', [OliviaController::class, 'storeEsp2']);
    Route::post('/esp3/store', [OliviaController::class, 'storeEsp3']);
});

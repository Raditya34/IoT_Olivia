<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\ProcessHistory;
use App\Models\ProcessTimer;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    // ===== NOTIFIKASI =====

    /**
     * Kirim notifikasi ke user
     */
    public static function send($userId, $type, $title, $message)
    {
        try {
            Notification::create([
                'user_id' => $userId,
                'type' => $type,
                'title' => $title,
                'message' => $message,
            ]);

            Log::info("Notifikasi terkirim: {$type} untuk user {$userId}");
        } catch (\Exception $e) {
            Log::error("Gagal kirim notifikasi: " . $e->getMessage());
        }
    }

    /**
     * Check & send notifikasi berdasarkan waktu
     */
    public static function checkAndSendNotifications($userId)
    {
        $timer = ProcessTimer::getActiveTimer($userId);

        if (!$timer || !$timer->system_started_at) {
            return;
        }

        $now = Carbon::now();
        $systemStarted = Carbon::parse($timer->system_started_at);
        $elapsedMinutes = $now->diffInSeconds($systemStarted) / 60;

        // Notifikasi 1: Menit 35 sistem jalan
        if ($elapsedMinutes >= 35 && !$timer->notif_arang_sent) {
            self::send($userId, 'arang', 'Arang', 'Tolong masukkan arang');
            self::recordHistory($userId, 'arang', 'started');
            $timer->update(['notif_arang_sent' => true, 'arang_started_at' => $now]);
        }

        // Notifikasi 2: 3 jam setelah arang (atau 15 menit setelah bleaching nyala)
        if ($timer->arang_started_at && !$timer->notif_bleaching_sent) {
            $arangStarted = Carbon::parse($timer->arang_started_at);
            $arangElapsed = $now->diffInSeconds($arangStarted) / 60;

            // 3 jam = 180 menit
            if ($arangElapsed >= 180) {
                self::send($userId, 'bleaching', 'Bleaching', 'Tolong masukkan bleaching');
                self::recordHistory($userId, 'arang', 'completed');
                self::recordHistory($userId, 'bleaching', 'started');
                $timer->update(['notif_bleaching_sent' => true, 'bleaching_started_at' => $now]);
            }
        }

        // Notifikasi 3: 4 jam 15 menit setelah bleaching
        if ($timer->bleaching_started_at && !$timer->notif_validasi_sent) {
            $bleachingStarted = Carbon::parse($timer->bleaching_started_at);
            $bleachingElapsed = $now->diffInSeconds($bleachingStarted) / 60;

            // 4 jam 15 menit = 255 menit
            if ($bleachingElapsed >= 255) {
                self::send($userId, 'validasi', 'Validasi', 'Cek hasil validasi');
                self::recordHistory($userId, 'bleaching', 'completed');
                self::recordHistory($userId, 'validasi', 'started');
                $timer->update(['notif_validasi_sent' => true, 'validasi_started_at' => $now]);
            }
        }

        // Notifikasi 4: 10 menit setelah validasi
        if ($timer->validasi_started_at && !$timer->notif_selesai_sent) {
            $validasiStarted = Carbon::parse($timer->validasi_started_at);
            $validasiElapsed = $now->diffInSeconds($validasiStarted) / 60;

            if ($validasiElapsed >= 10) {
                self::send($userId, 'selesai', 'Selesai', 'Selamat Proses Filtrasi Berhasil');
                self::recordHistory($userId, 'validasi', 'completed');
                self::recordHistory($userId, 'selesai', 'completed');
                $timer->update(['notif_selesai_sent' => true]);
            }
        }
    }

    // ===== HISTORY PROSES =====

    /**
     * Catat history proses
     */
    public static function recordHistory($userId, $stage, $status, $details = null)
    {
        try {
            $latestCycle = ProcessTimer::where('user_id', $userId)
                ->latest('cycle_number')
                ->first()?->cycle_number ?? 1;

            ProcessHistory::create([
                'user_id' => $userId,
                'stage' => $stage,
                'status' => $status,
                'details' => $details,
                'cycle_number' => $latestCycle,
                'started_at' => $status === 'started' ? now() : null,
                'completed_at' => $status === 'completed' ? now() : null,
            ]);

            Log::info("History tercatat: {$stage} ({$status}) untuk user {$userId} cycle {$latestCycle}");
        } catch (\Exception $e) {
            Log::error("Gagal catat history: " . $e->getMessage());
        }
    }

    /**
     * Get timeline proses untuk user
     */
    public static function getProcessTimeline($userId)
    {
        return ProcessHistory::where('user_id', $userId)
            ->orderBy('cycle_number', 'desc')
            ->orderBy('created_at', 'asc')
            ->get()
            ->groupBy('cycle_number');
    }

    /**
     * Get notifikasi unread user
     */
    public static function getUnreadNotifications($userId)
    {
        return Notification::where('user_id', $userId)
            ->where('is_read', false)
            ->latest()
            ->limit(10)
            ->get();
    }

    /**
     * Mark notifikasi sebagai read
     */
    public static function markAsRead($notificationId)
    {
        $notification = Notification::find($notificationId);
        if ($notification) {
            $notification->markAsRead();
        }
    }
}

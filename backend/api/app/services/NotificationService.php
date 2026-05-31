<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\ProcessHistory;
use App\Models\ProcessTimer;
use App\Models\Esp1Arang;
use App\Models\Esp2Bleaching;
use App\Models\Esp3Validasi;
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
     * Check & send notifikasi berdasarkan waktu + Catat Sensor ke History
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

        // Notifikasi 1: Menit 35 sistem jalan (Proses Arang Dimulai)
        if ($elapsedMinutes >= 35 && !$timer->notif_arang_sent) {
            self::send($userId, 'arang', 'Arang', 'Tolong masukkan arang');
            self::add($userId, 'arang', 'started', 'Proses arang resmi dimulai.');

            $timer->update([
                'arang_started_at' => $now,
                'notif_arang_sent' => true
            ]);
        }

        // Notifikasi 2: Menit 45 (Arang Selesai -> Masuk Bleaching)
        if ($elapsedMinutes >= 45 && !$timer->notif_bleaching_sent) {
            // Ambil data sensor arang terakhir sebelum selesai
            $lastArang = Esp1Arang::latest()->first();
            $detailsArang = $lastArang
                ? "Suhu Akhir: {$lastArang->suhu_arang}°C | Volume: {$lastArang->volume_arang}L"
                : "Data sensor tidak terekam";

            self::add($userId, 'arang', 'completed', $detailsArang);

            self::send($userId, 'bleaching', 'Bleaching', 'Proses Bleaching Dimulai');
            self::add($userId, 'bleaching', 'started', 'Sistem mengaktifkan aktuator bleaching.');

            $timer->update([
                'bleaching_started_at' => $now,
                'notif_bleaching_sent' => true
            ]);
        }

        // Notifikasi 3: Menit 55 (Bleaching Selesai -> Masuk Validasi)
        if ($elapsedMinutes >= 55 && !$timer->notif_validasi_sent) {
            // Ambil data aktuator & sensor bleaching terakhir sebelum selesai
            $lastBleach = Esp2Bleaching::latest()->first();
            $detailsBleach = $lastBleach
                ? "Suhu: {$lastBleach->suhu_bleaching}°C | Motor: {$lastBleach->speed} RPM | Heater1: " . ($lastBleach->h1 ? 'ON':'OFF') . " | P1: " . ($lastBleach->p1 ? 'ON':'OFF')
                : "Data sensor tidak terekam";

            self::add($userId, 'bleaching', 'completed', $detailsBleach);

            self::send($userId, 'validasi', 'Validasi', 'Silahkan lakukan validasi');
            self::add($userId, 'validasi', 'started', 'Menunggu hasil pembacaan sensor validasi.');

            $timer->update([
                'validasi_started_at' => $now,
                'notif_validasi_sent' => true
            ]);
        }

        // Notifikasi 4: Menit 65 (Validasi Selesai -> Seluruh Siklus Selesai)
        if ($elapsedMinutes >= 65 && !$timer->notif_selesai_sent) {
            // Ambil data sensor kualitas validasi akhir
            $lastValidasi = Esp3Validasi::latest()->first();
            $detailsValidasi = $lastValidasi
                ? "Vol: {$lastValidasi->volume_validasi}L | Turbidity: {$lastValidasi->turbidity} NTU | Viskositas: {$lastValidasi->viscosity} cPs | Warna: RGB({$lastValidasi->r},{$lastValidasi->g},{$lastValidasi->b})"
                : "Data sensor tidak terekam";

            self::add($userId, 'validasi', 'completed', $detailsValidasi);

            self::send($userId, 'selesai', 'Selesai', 'Proses produksi hari ini selesai');
            self::add($userId, 'selesai', 'completed', 'Seluruh rangkaian siklus produksi berhasil diproses.');

            $timer->update([
                'notif_selesai_sent' => true
            ]);
        }
    }

    /**
     * Catat history proses ke database
     */
    public static function add($userId, $stage, $status, $details = null)
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

<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Console\Command;

class CheckNotifications extends Command
{
    protected $signature = 'notifications:check';
    protected $description = 'Check dan kirim notifikasi ke user berdasarkan timing proses';

    public function handle()
    {
        $this->info('🔔 Mengecek notifikasi untuk semua user...');

        // Ambil semua user (atau hanya user dengan sistem yang aktif)
        $users = User::all();

        foreach ($users as $user) {
            try {
                NotificationService::checkAndSendNotifications($user->id);
            } catch (\Exception $e) {
                $this->error("Error untuk user {$user->id}: " . $e->getMessage());
            }
        }

        $this->info('✅ Pengecekan notifikasi selesai');
    }
}

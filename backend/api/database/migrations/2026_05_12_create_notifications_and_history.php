<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        // Tabel untuk notifikasi ke user
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['arang', 'bleaching', 'validasi', 'selesai']); // Tipe notifikasi
            $table->string('title'); // "Tolong masukkan arang"
            $table->text('message');
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            
            $table->index('user_id');
            $table->index('type');
            $table->index('is_read');
        });

        // Tabel untuk riwayat proses (timeline)
        Schema::create('process_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('stage', ['arang', 'bleaching', 'validasi', 'selesai']); // Stage proses
            $table->string('status'); // "started", "completed"
            $table->text('details')->nullable(); // Detail tambahan (temperature, dll)
            $table->integer('cycle_number')->default(1); // Cycle keberapa (1st, 2nd, 3rd, etc)
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
            
            $table->index('user_id');
            $table->index('stage');
            $table->index('cycle_number');
        });

        // Tabel untuk track waktu proses (untuk trigger notifikasi)
        Schema::create('process_timers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->integer('cycle_number')->default(1);
            $table->timestamp('system_started_at'); // Sistem mulai jalan
            $table->timestamp('arang_started_at')->nullable(); // Arang mulai
            $table->timestamp('bleaching_started_at')->nullable(); // Bleaching mulai
            $table->timestamp('validasi_started_at')->nullable(); // Validasi mulai
            $table->boolean('notif_arang_sent')->default(false); // Sudah kirim notif arang?
            $table->boolean('notif_bleaching_sent')->default(false); // Sudah kirim notif bleaching?
            $table->boolean('notif_validasi_sent')->default(false); // Sudah kirim notif validasi?
            $table->boolean('notif_selesai_sent')->default(false); // Sudah kirim notif selesai?
            $table->timestamps();
            
            $table->index('user_id');
            $table->index('cycle_number');
        });
    }

    public function down(): void {
        Schema::dropIfExists('process_timers');
        Schema::dropIfExists('process_history');
        Schema::dropIfExists('notifications');
    }
};

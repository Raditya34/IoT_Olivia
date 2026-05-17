<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Perbaikan Tabel ESP1 Arang
        Schema::table('esp1_arang', function (Blueprint $table) {
            $table->dropColumn('suhu'); // Hapus kolom lama
            $table->float('suhu1')->default(0)->after('id');
            $table->float('suhu2')->default(0)->after('suhu1');
            $table->float('tinggi')->default(0)->after('suhu2');
        });

        // Perbaikan Tabel ESP3 Validasi
        Schema::table('esp3_validasi', function (Blueprint $table) {
            $table->dropColumn(['turbidity', 'viskositas', 'warna']); // Hapus kolom lama

            $table->float('tinggi')->default(0)->after('id');
            $table->float('ntu')->default(0)->after('volume'); // Turbidity
            $table->float('freq')->default(0)->after('ntu');   // Viskositas
            $table->float('tegangan')->default(0)->after('freq');
            $table->integer('r')->default(0)->after('tegangan'); // Warna Red
            $table->integer('g')->default(0)->after('r');        // Warna Green
            $table->integer('b')->default(0)->after('g');        // Warna Blue
        });
    }

    public function down(): void
    {
        // Opsional: Untuk rollback
    }
};

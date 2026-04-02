<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
{
    // Tabel ESP 1 - Arang
    Schema::create('esp1_arang', function (Blueprint $table) {
        $table->id();
        $table->float('suhu');
        $table->float('volume');
        $table->timestamp('created_at')->useCurrent();
    });

    // Tabel ESP 2 - Bleaching
    Schema::create('esp2_bleaching', function (Blueprint $table) {
        $table->id();
        $table->float('suhu');
        $table->timestamp('created_at')->useCurrent();
    });

    // Tabel ESP 3 - Validasi
    Schema::create('esp3_validasi', function (Blueprint $table) {
        $table->id();
        $table->float('turbidity');
        $table->float('viscosity');
        $table->string('warna');
        $table->timestamp('created_at')->useCurrent();
    });

    // Tabel Master Control - ESP 2 Master
    Schema::create('master_controls', function (Blueprint $table) {
        $table->id();
        $table->boolean('system_on')->default(false);
        $table->boolean('heater')->default(false);
        $table->boolean('pompa')->default(false);
        $table->boolean('motor_ac')->default(false);
        $table->integer('servo_pos')->default(0);
        $table->timestamps();
    });
}
};

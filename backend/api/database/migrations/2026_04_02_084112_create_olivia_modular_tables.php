<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        // TABEL UNIT 1 - ARANG
        Schema::create('esp1_arang', function (Blueprint $table) {
            $table->id();
            $table->float('suhu_arang')->default(0.0);
            $table->float('volume_arang')->default(0.0);
            $table->timestamp('created_at')->useCurrent();
        });

        // TABEL UNIT 2 - BLEACHING
        Schema::create('esp2_bleaching', function (Blueprint $table) {
            $table->id();
            $table->float('suhu_bleaching')->default(0.0);
            $table->boolean('valve')->default(false);
            $table->boolean('p1')->default(false);
            $table->boolean('p2')->default(false);
            $table->boolean('p3')->default(false);
            $table->boolean('h1')->default(false);
            $table->boolean('h2')->default(false);
            $table->boolean('h3')->default(false);
            $table->boolean('h4')->default(false);
            $table->integer('speed')->default(0);
            $table->timestamp('created_at')->useCurrent();
        });

        // TABEL UNIT 3 - VALIDASI
        Schema::create('esp3_validasi', function (Blueprint $table) {
            $table->id();
            $table->float('volume_validasi')->default(0.0);
            $table->float('turbidity')->default(0.0);
            $table->float('viscosity')->default(0.0);
            $table->integer('r')->default(0);
            $table->integer('g')->default(0);
            $table->integer('b')->default(0);
            $table->timestamp('created_at')->useCurrent();
        });

        // TABEL MASTER CONTROL
        Schema::create('master_controls', function (Blueprint $table) {
            $table->id();
            $table->boolean('system_on')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void {
        Schema::dropIfExists('esp1_arang');
        Schema::dropIfExists('esp2_bleaching');
        Schema::dropIfExists('esp3_validasi');
        Schema::dropIfExists('master_controls');
    }
};

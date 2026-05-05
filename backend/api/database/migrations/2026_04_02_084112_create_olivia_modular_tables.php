<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('esp1_arang', function (Blueprint $table) {
            $table->id();
            $table->float('suhu');
            $table->float('volume');
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('esp2_bleaching', function (Blueprint $table) {
            $table->id();
            $table->float('suhu');
            $table->boolean('valve')->default(false);
            $table->boolean('pompa_1')->default(false);
            $table->boolean('pompa_2')->default(false);
            $table->boolean('pompa_3')->default(false);
            $table->boolean('heater_1')->default(false);
            $table->boolean('heater_2')->default(false);
            $table->integer('motor_ac_speed')->default(0);
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('esp3_validasi', function (Blueprint $table) {
            $table->id();
            $table->float('volume');
            $table->float('turbidity');
            $table->float('viskositas');
            $table->string('warna');
            $table->timestamp('created_at')->useCurrent();
        });

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

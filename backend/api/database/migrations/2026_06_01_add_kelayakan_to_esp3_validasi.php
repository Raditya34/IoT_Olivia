<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('esp3_validasi', function (Blueprint $table) {
            $table->float('kelayakan')->default(0.0)->after('b');
            $table->string('status_layak', 50)->default('TIDAK LAYAK')->after('kelayakan');
        });
    }

    public function down(): void {
        Schema::table('esp3_validasi', function (Blueprint $table) {
            $table->dropColumn(['kelayakan', 'status_layak']);
        });
    }
};

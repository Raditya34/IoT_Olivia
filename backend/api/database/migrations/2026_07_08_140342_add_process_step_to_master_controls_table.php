<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('master_controls', function (Blueprint $table) {
            $table->integer('process_step')->default(0)->after('system_on');
            $table->string('current_step', 50)->default('STANDBY')->after('process_step');
        });
    }

    public function down(): void {
        Schema::table('master_controls', function (Blueprint $table) {
            $table->dropColumn(['process_step', 'current_step']);
        });
    }
};

<?php

namespace Database\Seeders;

use App\Models\MasterControl;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder {
    public function run(): void {
        MasterControl::updateOrCreate(['id' => 1], ['system_on' => false]);
    }
}

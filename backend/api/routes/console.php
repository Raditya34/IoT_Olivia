<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

/*
|--------------------------------------------------------------------------
| Console Routes
|--------------------------------------------------------------------------
|
| This file is where you may define all of your closure based console
| commands. Each Closure is bound to a command instance allowing a
| simple approach to interacting with each command's IO methods.
|
*/

// Command bawaan Laravel
Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/**
 * CATATAN UNTUK LARAVEL 11:
 * Command berbasis Class (seperti MqttSubscribe & CheckNotifications)
 * otomatis didaftarkan oleh Laravel selama berada di folder app/Console/Commands.
 * * Jadi Anda TIDAK PERLU lagi menggunakan Artisan::starting(...) di sini.
 */

/**
 * JADWAL TUGAS (SCHEDULER)
 * Di Laravel 11, Anda bisa mengatur jadwal langsung di sini
 * atau di bootstrap/app.php
 */
Schedule::command('notifications:check')->everyMinute();

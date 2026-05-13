<?php
// routes/console.php
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use App\Console\Commands\MqttSubscribe;
use App\Console\Commands\CheckNotifications;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// ✅ Daftarkan MQTT command
Artisan::starting(function ($artisan) {
    $artisan->add(new MqttSubscribe());
    $artisan->add(new CheckNotifications());
});

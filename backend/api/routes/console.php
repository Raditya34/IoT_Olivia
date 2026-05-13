<?php
// routes/console.php
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
<<<<<<< HEAD
use App\Console\Commands\MqttSubscribe;
use App\Console\Commands\CheckNotifications;
=======
>>>>>>> ae56452e8d62796934f92f6b8795896c4f758c1d

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');
<<<<<<< HEAD

// ✅ Daftarkan MQTT command
Artisan::starting(function ($artisan) {
    $artisan->add(new MqttSubscribe());
    $artisan->add(new CheckNotifications());
});
=======
>>>>>>> ae56452e8d62796934f92f6b8795896c4f758c1d

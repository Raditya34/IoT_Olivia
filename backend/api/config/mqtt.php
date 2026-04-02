<?php

return [
    'host' => env('MQTT_HOST', '127.0.0.1'),
    'port' => (int) env('MQTT_PORT', 1883),
    'username' => env('MQTT_USERNAME', null),
    'password' => env('MQTT_PASSWORD', null),

    'client_id' => env('MQTT_CLIENT_ID', 'laravel-olivia-subscriber'),
    'topic' => env('MQTT_TOPIC', 'olivia/OLIVIA-01/telemetry'),

    // keepalive 60 detik sesuai yang terlihat di EMQX dashboard
    'keepalive' => 60,
];

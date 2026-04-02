<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpMqtt\Client\MqttClient;
use PhpMqtt\Client\ConnectionSettings;
use App\Services\Mqtt\TelemetryParser;
use App\Models\Device;
use App\Models\Telemetry;

class MqttSubscribeTelemetry extends Command
{
    protected $signature = 'mqtt:subscribe-telemetry';
    protected $description = 'Subscribe OLIVIA telemetry topics and insert into DB';

    public function handle(): int
    {
        $host = config('mqtt.host');
        $port = config('mqtt.port');
        $clientId = config('mqtt.client_id');
        $topic = config('mqtt.topic');

        $username = config('mqtt.username');
        $password = config('mqtt.password');

        $parser = new TelemetryParser();
        

        $this->info("Connecting to MQTT broker: {$host}:{$port}");
        $this->info("Subscribing topic: {$topic}");

        $connectionSettings = (new ConnectionSettings)
            ->setKeepAliveInterval(config('mqtt.keepalive'))
            ->setUsername($username ?: null)
            ->setPassword($password ?: null)
            ->setUseTls(false);

        $mqtt = new MqttClient($host, $port, $clientId);

        try {
            $mqtt->connect($connectionSettings, true); // clean session true
        } catch (\Throwable $e) {
            $this->error('MQTT connect failed: ' . $e->getMessage());
            return self::FAILURE;
        }

        $mqtt->subscribe($topic, function (string $receivedTopic, string $message) use ($parser) {
            $result = $parser->parse($receivedTopic, $message);

            $this->line("[$receivedTopic] {$message}");

            if (!$result['is_valid']) {
                $this->warn("invalid telemetry");
                return;
            }

            $this->info("device_code: {$result['device_code']}");
            $this->line("payload: " . json_encode($result['payload']));

            try {
                $device = Device::where('device_code', $result['device_code'])->first();
$col = config('olivia.device_code_column');
$device = Device::where($col, $result['device_code'])->first();
                if (!$device) {
                    $this->warn("device not found in DB: {$result['device_code']}");
                    return;
                }

                $payload = $result['payload'];

                Telemetry::create([
                    'device_id'    => $device->id,
                    //'temp'         => $payload['temp'] ?? null,
                    //'cp'           => $payload['cP'] ?? ($payload['cp'] ?? null),
                    //'ntu'          => $payload['NTU'] ?? ($payload['ntu'] ?? null),
                    //'level_volume' => $payload['level_volume'] ?? null,
                    'payload' => $payload,
                    'received_at'  => now(),
                ]);

                $this->info("saved to DB ✅");
            } catch (\Throwable $e) {
                $this->error("DB insert failed: " . $e->getMessage());
            }
        }, 0);

        $mqtt->loop(true);

        $mqtt->disconnect();
        return self::SUCCESS;
    }
}

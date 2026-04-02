<?php

namespace App\Services\Mqtt;

class TelemetryParser
{
    /**
     * Parse telemetry message dari MQTT.
     * Topic format: olivia/{DEVICE_CODE}/telemetry
     */
    public function parse(string $topic, string $message): array
    {
        $deviceCode = $this->extractDeviceCodeFromTopic($topic);

        $payload = json_decode($message, true);
        $isValidJson = json_last_error() === JSON_ERROR_NONE && is_array($payload);

        return [
            'device_code' => $deviceCode,
            'raw' => $message,
            'payload' => $isValidJson ? $payload : null,
            'is_valid' => $deviceCode !== null && $isValidJson,
        ];
    }

    private function extractDeviceCodeFromTopic(string $topic): ?string
    {
        $parts = explode('/', $topic);
        if (count($parts) >= 3 && $parts[0] === 'olivia' && $parts[2] === 'telemetry') {
            return $parts[1];
        }
        return null;
    }
}

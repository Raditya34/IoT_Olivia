<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Telemetry extends Model
{
    use HasFactory;

    protected $fillable = [
        'device_id', 'payload', 'temp', 'cp', 'ntu', 'level_volume', 'received_at'
    ];

    protected $casts = [
        'payload' => 'array',
        'received_at' => 'datetime',
    ];

    public function device()
    {
        return $this->belongsTo(Device::class);
    }
}

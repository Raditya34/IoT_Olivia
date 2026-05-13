<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProcessTimer extends Model
{
    protected $table = 'process_timers';

    protected $fillable = [
        'user_id',
        'cycle_number',
        'system_started_at',
        'arang_started_at',
        'bleaching_started_at',
        'validasi_started_at',
        'notif_arang_sent',
        'notif_bleaching_sent',
        'notif_validasi_sent',
        'notif_selesai_sent',
    ];

    protected $casts = [
        'system_started_at' => 'datetime',
        'arang_started_at' => 'datetime',
        'bleaching_started_at' => 'datetime',
        'validasi_started_at' => 'datetime',
        'notif_arang_sent' => 'boolean',
        'notif_bleaching_sent' => 'boolean',
        'notif_validasi_sent' => 'boolean',
        'notif_selesai_sent' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Get or create active timer for user
    public static function getActiveTimer($userId)
    {
        return self::where('user_id', $userId)
            ->where('notif_selesai_sent', false)
            ->latest('cycle_number')
            ->first() ?? self::create([
                'user_id' => $userId,
                'cycle_number' => (self::where('user_id', $userId)->max('cycle_number') ?? 0) + 1,
                'system_started_at' => now(),
            ]);
    }
}

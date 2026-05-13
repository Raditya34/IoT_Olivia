<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProcessHistory extends Model
{
    protected $table = 'process_history';

    protected $fillable = [
        'user_id',
        'stage',
        'status',
        'details',
        'cycle_number',
        'started_at',
        'completed_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Get all history for current cycle
    public static function getLatestCycle($userId)
    {
        $latestCycle = self::where('user_id', $userId)
            ->latest('cycle_number')
            ->first()?->cycle_number ?? 1;

        return self::where('user_id', $userId)
            ->where('cycle_number', $latestCycle)
            ->orderBy('stage')
            ->get();
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\ProcessHistory;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function getUnread(Request $request)
    {
        $user = $request->user();
        $notifications = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $notifications,
        ]);
    }

    public function getAll(Request $request)
    {
        $user = $request->user();
        $notifications = Notification::where('user_id', $user->id)
            ->latest()
            ->paginate(20);

        return response()->json([
            'status' => 'success',
            'data' => $notifications,
        ]);
    }

    public function getUnreadCount(Request $request)
    {
        $user = $request->user();
        $count = Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'unread_count' => $count,
        ]);
    }

    public function markAsRead(Request $request, $id)
    {
        $user = $request->user();
        $notification = Notification::where('user_id', $user->id)
            ->findOrFail($id);
        $notification->markAsRead();

        return response()->json(['message' => 'OK']);
    }

    public function markAllAsRead(Request $request)
    {
        $user = $request->user();
        Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now()]);

        return response()->json(['message' => 'OK']);
    }

    public function getProcessHistory(Request $request)
    {
        $user = $request->user();
        $records = ProcessHistory::where('user_id', $user->id)
            ->orderBy('cycle_number', 'desc')
            ->orderBy('stage')
            ->get();

        $grouped = [];
        foreach ($records as $record) {
            $grouped[(string) $record->cycle_number][] = $record;
        }

        return response()->json([
            'status' => 'success',
            'data' => $grouped,
        ]);
    }

    public function getCurrentCycleHistory(Request $request)
    {
        $user = $request->user();
        $records = ProcessHistory::getLatestCycle($user->id);

        return response()->json([
            'status' => 'success',
            'data' => $records,
        ]);
    }
}

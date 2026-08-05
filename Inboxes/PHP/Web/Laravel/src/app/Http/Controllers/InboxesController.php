<?php
namespace App\Http\Controllers;

use App\Models\Message;
use App\Services\CacheService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InboxesController extends Controller
{
    private $cache;

    public function __construct()
    {
        $this->cache = new CacheService();
    }

    public function index()
    {
        return view('inboxes');
    }

    public function list(): JsonResponse
    {
        $cached = $this->cache->get('messages:all');
        if ($cached !== null) {
            return response()->json($cached);
        }
        $messages = Message::orderBy('id')->get();
        $data = $messages->toArray();
        $this->cache->set('messages:all', $data);
        return response()->json($data);
    }

    public function create(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'sender' => 'required|string|max:255',
            'subject' => 'required|string|max:300',
            'body' => 'nullable|string',
        ]);
        $msg = Message::create([
            'sender' => $validated['sender'],
            'subject' => $validated['subject'],
            'body' => $validated['body'] ?? '',
        ]);
        $this->cache->delete('messages:all');
        return response()->json($msg, 201);
    }

    public function read(int $id): JsonResponse
    {
        $cached = $this->cache->get("message:$id");
        if ($cached !== null) {
            return response()->json($cached);
        }
        $msg = Message::find($id);
        if (!$msg) {
            return response()->json(['error' => 'not found'], 404);
        }
        $msg->update(['read' => true]);
        $this->cache->set("message:$id", $msg->toArray());
        $this->cache->delete('messages:all');
        return response()->json($msg);
    }

    public function delete(int $id): JsonResponse
    {
        $msg = Message::find($id);
        if (!$msg) {
            return response()->json(['error' => 'not found'], 404);
        }
        $msg->delete();
        $this->cache->delete('messages:all');
        $this->cache->delete("message:$id");
        return response()->json(['message' => 'Deleted']);
    }
}

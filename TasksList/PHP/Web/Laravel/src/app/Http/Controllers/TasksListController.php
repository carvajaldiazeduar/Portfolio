<?php
namespace App\Http\Controllers;

use App\Models\Task;
use App\Services\CacheService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TasksListController extends Controller
{
    private $cache;

    public function __construct()
    {
        $this->cache = new CacheService();
    }

    public function index()
    {
        return view('taskslist');
    }

    public function list(): JsonResponse
    {
        $cached = $this->cache->get('tasks:all');
        if ($cached !== null) {
            return response()->json($cached);
        }
        $tasks = Task::orderBy('id')->get();
        $data = $tasks->toArray();
        $this->cache->set('tasks:all', $data);
        return response()->json($data);
    }

    public function create(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);
        $task = Task::create([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? '',
        ]);
        $this->cache->delete('tasks:all');
        return response()->json($task, 201);
    }

    public function complete(int $id): JsonResponse
    {
        $task = Task::find($id);
        if (!$task) {
            return response()->json(['error' => 'Task not found'], 404);
        }
        $task->update(['completed' => true]);
        $this->cache->delete('tasks:all');
        return response()->json($task);
    }

    public function delete(int $id): JsonResponse
    {
        $task = Task::find($id);
        if (!$task) {
            return response()->json(['error' => 'Task not found'], 404);
        }
        $task->delete();
        $this->cache->delete('tasks:all');
        return response()->json(['result' => 'deleted']);
    }
}

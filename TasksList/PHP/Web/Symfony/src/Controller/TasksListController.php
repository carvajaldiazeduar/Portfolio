<?php
namespace App\Controller;

use App\ORM;
use App\Service\CacheService;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class TasksListController
{
    private $cache;

    public function __construct()
    {
        ORM::connect();
        $this->cache = new CacheService();
    }

    #[Route('/', methods: ['GET'])]
    public function index(Environment $twig): Response
    {
        return new Response($twig->render('taskslist.html.twig'));
    }

    #[Route('/api/tasks', methods: ['GET'])]
    public function list(): JsonResponse
    {
        $cached = $this->cache->get('tasks:all');
        if ($cached !== null) {
            return new JsonResponse($cached);
        }
        $tasks = ORM::table('tasks')->get();
        $this->cache->set('tasks:all', $tasks);
        return new JsonResponse($tasks);
    }

    #[Route('/api/tasks', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        if (!is_array($data) || empty($data['title'])) {
            return new JsonResponse(['error' => 'Title is required'], 400);
        }
        $task = ORM::table('tasks')->create([
            'title' => $data['title'],
            'description' => $data['description'] ?? '',
            'completed' => 0,
        ]);
        $this->cache->delete('tasks:all');
        return new JsonResponse($task, 201);
    }

    #[Route('/api/tasks/{id}/complete', methods: ['PUT'])]
    public function complete(int $id): JsonResponse
    {
        $task = ORM::table('tasks')->where('id', $id)->first();
        if (!$task) {
            return new JsonResponse(['error' => 'Not found'], 404);
        }
        ORM::table('tasks')->where('id', $id)->update(['completed' => 1]);
        $this->cache->delete('tasks:all');
        return new JsonResponse(array_merge($task, ['completed' => true]));
    }

    #[Route('/api/tasks/{id}', methods: ['DELETE'])]
    public function delete(int $id): JsonResponse
    {
        $deleted = ORM::table('tasks')->where('id', $id)->delete();
        if (!$deleted) {
            return new JsonResponse(['error' => 'Not found'], 404);
        }
        $this->cache->delete('tasks:all');
        return new JsonResponse(['message' => 'Deleted']);
    }
}

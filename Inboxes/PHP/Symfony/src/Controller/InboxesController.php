<?php
namespace App\Controller;

use App\ORM;
use App\Service\CacheService;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class InboxesController
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
        return new Response($twig->render('inboxes.html.twig'));
    }

    #[Route('/api/messages', methods: ['GET'])]
    public function list(): JsonResponse
    {
        $cached = $this->cache->get('messages:all');
        if ($cached !== null) {
            return new JsonResponse($cached);
        }
        $messages = ORM::table('messages')->get();
        $this->cache->set('messages:all', $messages);
        return new JsonResponse($messages);
    }

    #[Route('/api/messages/{id}', methods: ['GET'])]
    public function get(int $id): JsonResponse
    {
        $cached = $this->cache->get("message:$id");
        if ($cached !== null) {
            return new JsonResponse($cached);
        }
        $msg = ORM::table('messages')->where('id', $id)->first();
        if (!$msg) {
            return new JsonResponse(['error' => 'Not found'], 404);
        }
        ORM::table('messages')->where('id', $id)->update(['read' => 1]);
        $this->cache->set("message:$id", $msg);
        $this->cache->delete('messages:all');
        return new JsonResponse($msg);
    }

    #[Route('/api/messages', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        if (!is_array($data) || empty($data['subject'])) {
            return new JsonResponse(['error' => 'Subject is required'], 400);
        }
        $msg = ORM::table('messages')->create([
            'sender' => $data['sender'] ?? '',
            'subject' => $data['subject'],
            'body' => $data['body'] ?? '',
            'read' => 0,
        ]);
        $this->cache->delete('messages:all');
        return new JsonResponse($msg, 201);
    }

    #[Route('/api/messages/{id}', methods: ['DELETE'])]
    public function delete(int $id): JsonResponse
    {
        $deleted = ORM::table('messages')->where('id', $id)->delete();
        if (!$deleted) {
            return new JsonResponse(['error' => 'Not found'], 404);
        }
        $this->cache->delete('messages:all');
        $this->cache->delete("message:$id");
        return new JsonResponse(['message' => 'Deleted']);
    }
}

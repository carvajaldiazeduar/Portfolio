<?php
namespace App\Controller;

use App\ORM;
use App\Service\CacheService;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class ContactsController
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
        return new Response($twig->render('contacts.html.twig'));
    }

    #[Route('/api/contacts', methods: ['GET'])]
    public function list(): JsonResponse
    {
        $cached = $this->cache->get('contacts:all');
        if ($cached !== null) {
            return new JsonResponse($cached);
        }
        $contacts = ORM::table('contacts')->get();
        $this->cache->set('contacts:all', $contacts);
        return new JsonResponse($contacts);
    }

    #[Route('/api/contacts', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        if (!is_array($data)) {
            $data = [];
        }
        $errors = $this->validateContact($data);
        if ($errors) {
            return new JsonResponse(['errors' => $errors], 400);
        }
        $contact = ORM::table('contacts')->create([
            'name' => trim($data['name']),
            'phone' => trim($data['phone']),
            'email' => trim($data['email']),
        ]);
        $this->cache->delete('contacts:all');
        return new JsonResponse($contact, 201);
    }

    private function validateContact(array $data): array
    {
        $errors = [];
        $name = trim($data['name'] ?? '');
        $phone = trim($data['phone'] ?? '');
        $email = trim($data['email'] ?? '');
        if ($name === '') {
            $errors['name'] = 'Name is required';
        } elseif (strlen($name) < 2 || strlen($name) > 100 || !preg_match('/^[A-Za-zÀ-ÿ\' .-]+$/', $name)) {
            $errors['name'] = 'Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)';
        }
        if ($phone === '') {
            $errors['phone'] = 'Phone is required';
        } elseif (!preg_match('/^[0-9 +().-]{7,20}$/', $phone)) {
            $errors['phone'] = 'Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)';
        }
        if ($email === '') {
            $errors['email'] = 'Email is required';
        } elseif (!preg_match('/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/', $email)) {
            $errors['email'] = 'Invalid email format';
        }
        return $errors;
    }

    #[Route('/api/contacts/search', methods: ['GET'])]
    public function search(Request $request): JsonResponse
    {
        $q = strtolower($request->query->get('q', ''));
        $cached = $this->cache->get("contacts:search:$q");
        if ($cached !== null) {
            return new JsonResponse($cached);
        }
        $results = ORM::raw("SELECT * FROM contacts WHERE LOWER(name) LIKE ?", ["%$q%"]);
        $this->cache->set("contacts:search:$q", $results);
        return new JsonResponse($results);
    }

    #[Route('/api/contacts/{id}', methods: ['DELETE'])]
    public function delete(int $id): JsonResponse
    {
        $deleted = ORM::table('contacts')->where('id', $id)->delete();
        if (!$deleted) {
            return new JsonResponse(['error' => 'Not found'], 404);
        }
        $this->cache->delete('contacts:all');
        return new JsonResponse(['message' => 'Deleted']);
    }
}

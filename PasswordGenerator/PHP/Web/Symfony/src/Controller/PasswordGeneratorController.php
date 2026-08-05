<?php
namespace App\Controller;

use App\ORM;
use App\Service\CacheService;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class PasswordGeneratorController
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
        return new Response($twig->render('passwordgenerator.html.twig'));
    }

    #[Route('/api/generate', methods: ['POST'])]
    public function generate(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        if (!is_array($data) || !isset($data['length'])) {
            return new JsonResponse(['error' => 'Length is required'], 400);
        }
        $length = (int) $data['length'];
        if ($length < 4 || $length > 128) {
            return new JsonResponse(['error' => 'Length must be 4-128'], 400);
        }
        $useUpper = $data['use_upper'] ?? true;
        $useLower = $data['use_lower'] ?? true;
        $useDigits = $data['use_digits'] ?? true;
        $useSymbols = $data['use_symbols'] ?? false;
        $chars = '';
        if ($useUpper) $chars .= 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        if ($useLower) $chars .= 'abcdefghijklmnopqrstuvwxyz';
        if ($useDigits) $chars .= '0123456789';
        if ($useSymbols) $chars .= '!@#$%^&*()_+-=[]{}|;:,.<>?';
        if ($chars === '') {
            return new JsonResponse(['error' => 'Select at least one character type'], 400);
        }
        $password = '';
        $max = mb_strlen($chars) - 1;
        for ($i = 0; $i < $length; $i++) {
            $password .= $chars[random_int(0, $max)];
        }
        $entry = ORM::table('password_entries')->create([
            'password' => $password,
            'length' => $length,
        ]);
        $this->cache->delete('passwords:recent');
        return new JsonResponse(['password' => $password, 'id' => $entry['id']]);
    }

    #[Route('/api/passwords', methods: ['GET'])]
    public function history(): JsonResponse
    {
        $cached = $this->cache->get('passwords:recent');
        if ($cached !== null) {
            return new JsonResponse($cached);
        }
        $entries = ORM::raw("SELECT * FROM password_entries ORDER BY id DESC LIMIT 50");
        $this->cache->set('passwords:recent', $entries);
        return new JsonResponse($entries);
    }
}

<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class ChronometerController
{
    private static $running = false;
    private static $startedAt = 0.0;
    private static $elapsed = 0.0;
    private static $laps = [];

    #[Route('/', methods: ['GET'])]
    public function index(Environment $twig): Response
    {
        return new Response($twig->render('chronometer.html.twig'));
    }

    #[Route('/api/state', methods: ['GET'])]
    public function state(): JsonResponse
    {
        $elapsed = self::$running ? (microtime(true) - self::$startedAt + self::$elapsed) : self::$elapsed;
        return new JsonResponse(['running' => self::$running, 'elapsed' => $elapsed, 'laps' => self::$laps]);
    }

    #[Route('/api/start', methods: ['POST'])]
    public function start(): JsonResponse
    {
        if (self::$running) return new JsonResponse(['error' => 'Already running'], 400);
        self::$running = true;
        self::$startedAt = microtime(true);
        return new JsonResponse(['message' => 'Started']);
    }

    #[Route('/api/stop', methods: ['POST'])]
    public function stop(): JsonResponse
    {
        if (!self::$running) return new JsonResponse(['error' => 'Not running'], 400);
        self::$elapsed += microtime(true) - self::$startedAt;
        self::$running = false;
        return new JsonResponse(['elapsed' => self::$elapsed]);
    }

    #[Route('/api/reset', methods: ['POST'])]
    public function reset(): JsonResponse
    {
        self::$running = false; self::$startedAt = 0.0; self::$laps = []; self::$elapsed = 0.0;
        return new JsonResponse(['message' => 'Reset']);
    }

    #[Route('/api/lap', methods: ['POST'])]
    public function lap(): JsonResponse
    {
        if (!self::$running) return new JsonResponse(['error' => 'Not running'], 400);
        $lap = microtime(true) - self::$startedAt + self::$elapsed;
        self::$laps[] = $lap;
        return new JsonResponse(['lap' => $lap, 'laps' => self::$laps]);
    }
}

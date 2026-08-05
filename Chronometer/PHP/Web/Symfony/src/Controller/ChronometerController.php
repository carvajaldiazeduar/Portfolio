<?php
namespace App\Controller;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class ChronometerController
{
    private static \ = false;
    private static \ = 0.0;
    private static \ = 0.0;
    private static \ = [];

    #[Route('/', methods: ['GET'])]
    public function index(Environment \): Response
    {
        return new Response(\->render('chronometer.html.twig'));
    }

    #[Route('/api/state', methods: ['GET'])]
    public function state(): JsonResponse
    {
        \ = self::\ ? (microtime(true) - self::\ + self::\) : self::\;
        return new JsonResponse(['running' => self::\, 'elapsed' => \, 'laps' => self::\]);
    }

    #[Route('/api/start', methods: ['POST'])]
    public function start(): JsonResponse
    {
        if (self::\) return new JsonResponse(['error' => 'Already running'], 400);
        self::\ = true;
        self::\ = microtime(true);
        return new JsonResponse(['message' => 'Started']);
    }

    #[Route('/api/stop', methods: ['POST'])]
    public function stop(): JsonResponse
    {
        if (!self::\) return new JsonResponse(['error' => 'Not running'], 400);
        self::\ += microtime(true) - self::\;
        self::\ = false;
        return new JsonResponse(['elapsed' => self::\]);
    }

    #[Route('/api/reset', methods: ['POST'])]
    public function reset(): JsonResponse
    {
        self::\ = false; self::\ = 0.0; self::\ = []; self::\ = 0.0;
        return new JsonResponse(['message' => 'Reset']);
    }

    #[Route('/api/lap', methods: ['POST'])]
    public function lap(): JsonResponse
    {
        if (!self::\) return new JsonResponse(['error' => 'Not running'], 400);
        \ = microtime(true) - self::\ + self::\;
        self::\[] = \;
        return new JsonResponse(['lap' => \, 'laps' => self::\]);
    }
}

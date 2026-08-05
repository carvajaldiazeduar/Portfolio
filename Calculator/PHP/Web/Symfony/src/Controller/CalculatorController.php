<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class CalculatorController
{
    #[Route('/', methods: ['GET'])]
    public function index(Environment $twig): Response
    {
        return new Response($twig->render('calculator.html.twig'));
    }

    #[Route('/api/calculate', methods: ['POST'])]
    public function calculate(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        if (!is_array($data) || !isset($data['a'], $data['b'], $data['operator'])) {
            return new JsonResponse(['error' => 'Missing required fields: a, b, operator'], 400);
        }

        if (!is_numeric($data['a']) || !is_numeric($data['b'])) {
            return new JsonResponse(['error' => 'a and b must be numbers'], 400);
        }

        $a = (float) $data['a'];
        $b = (float) $data['b'];
        $operator = (string) $data['operator'];

        $result = match ($operator) {
            'add' => $a + $b,
            'subtract' => $a - $b,
            'multiply' => $a * $b,
            'divide' => $b == 0 ? null : $a / $b,
            default => null,
        };

        if ($result === null) {
            $error = $operator === 'divide'
                ? 'Division by zero'
                : 'Invalid operator. Use add, subtract, multiply, or divide';
            return new JsonResponse(['error' => $error], 400);
        }

        return new JsonResponse(['result' => $result]);
    }
}

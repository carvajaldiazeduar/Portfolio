<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class ConversorController
{
    private static $units = [
        'length' => ['meters'=>1.0,'kilometers'=>1000.0,'centimeters'=>0.01,'millimeters'=>0.001,'miles'=>1609.344,'yards'=>0.9144,'feet'=>0.3048,'inches'=>0.0254],
        'weight' => ['kilograms'=>1.0,'grams'=>0.001,'milligrams'=>0.000001,'pounds'=>0.453592,'ounces'=>0.0283495],
        'temperature' => [],
    ];

    #[Route('/', methods: ['GET'])]
    public function index(Environment $twig): Response
    {
        return new Response($twig->render('conversor.html.twig'));
    }

    #[Route('/api/convert', methods: ['POST'])]
    public function convert(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        if (!is_array($data) || !isset($data['value'], $data['from'], $data['to'])) {
            return new JsonResponse(['error' => 'Missing fields'], 400);
        }
        $value = (float) $data['value'];
        $from = $data['from'];
        $to = $data['to'];

        foreach (self::$units as $cat => $units) {
            if (isset($units[$from]) && isset($units[$to])) {
                $result = $value * $units[$from] / $units[$to];
                return new JsonResponse(['result' => round($result, 6), 'from' => $from, 'to' => $to, 'category' => $cat]);
            }
            if ($cat === 'temperature') {
                $result = self::convertTemperature($value, $from, $to);
                if ($result !== null) {
                    return new JsonResponse(['result' => round($result, 6), 'from' => $from, 'to' => $to, 'category' => $cat]);
                }
            }
        }
        return new JsonResponse(['error' => 'Unsupported conversion'], 400);
    }

    private static function convertTemperature(float $value, string $from, string $to): ?float
    {
        $celsius = match ($from) { 'celsius'=> $value, 'fahrenheit'=>($value-32)*5/9, 'kelvin'=>$value-273.15, default=>null };
        if ($celsius === null) return null;
        return match ($to) { 'celsius'=> $celsius, 'fahrenheit'=>$celsius*9/5+32, 'kelvin'=>$celsius+273.15, default=>null };
    }
}

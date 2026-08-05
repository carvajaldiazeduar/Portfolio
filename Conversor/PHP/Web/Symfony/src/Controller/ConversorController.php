<?php
namespace App\Controller;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;

class ConversorController
{
    private static \ = [
        'length' => ['meters'=>1.0,'kilometers'=>1000.0,'centimeters'=>0.01,'millimeters'=>0.001,'miles'=>1609.344,'yards'=>0.9144,'feet'=>0.3048,'inches'=>0.0254],
        'weight' => ['kilograms'=>1.0,'grams'=>0.001,'milligrams'=>0.000001,'pounds'=>0.453592,'ounces'=>0.0283495],
        'temperature' => [],
    ];

    #[Route('/', methods: ['GET'])]
    public function index(Environment \): Response
    {
        return new Response(\->render('conversor.html.twig'));
    }

    #[Route('/api/convert', methods: ['POST'])]
    public function convert(Request \): JsonResponse
    {
        \ = json_decode(\->getContent(), true);
        if (!is_array(\) || !isset(\['value'], \['from'], \['to'])) {
            return new JsonResponse(['error' => 'Missing fields'], 400);
        }
        \ = (float) \['value'];
        \ = \['from'];
        \ = \['to'];

        foreach (self::\ as \ => \) {
            if (isset(\[\]) && isset(\[\])) {
                \ = \ * \[\] / \[\];
                return new JsonResponse(['result' => round(\, 6), 'from' => \, 'to' => \, 'category' => \]);
            }
            if (\ === 'temperature') {
                \ = self::convertTemperature(\, \, \);
                if (\ !== null) {
                    return new JsonResponse(['result' => round(\, 6), 'from' => \, 'to' => \, 'category' => \]);
                }
            }
        }
        return new JsonResponse(['error' => 'Unsupported conversion'], 400);
    }

    private static function convertTemperature(float \, string \, string \): ?float
    {
        \ = match (\) { 'celsius'=>\, 'fahrenheit'=>(\-32)*5/9, 'kelvin'=>\-273.15, default=>null };
        if (\ === null) return null;
        return match (\) { 'celsius'=>\, 'fahrenheit'=>\*9/5+32, 'kelvin'=>\+273.15, default=>null };
    }
}

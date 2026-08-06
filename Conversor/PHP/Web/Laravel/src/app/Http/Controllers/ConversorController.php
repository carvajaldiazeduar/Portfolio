<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversorController extends Controller
{
    private static $units = [
        'length' => [
            'meters' => 1.0,
            'kilometers' => 1000.0,
            'centimeters' => 0.01,
            'millimeters' => 0.001,
            'miles' => 1609.344,
            'yards' => 0.9144,
            'feet' => 0.3048,
            'inches' => 0.0254,
        ],
        'weight' => [
            'kilograms' => 1.0,
            'grams' => 0.001,
            'milligrams' => 0.000001,
            'pounds' => 0.453592,
            'ounces' => 0.0283495,
        ],
        'temperature' => [],
    ];

    public function index()
    {
        return view('conversor');
    }

    public function convert(Request $request): JsonResponse
    {
        $data = $request->validate([
            'value' => 'required|numeric',
            'from' => 'required|string',
            'to' => 'required|string',
        ]);

        $value = (float) $data['value'];
        $from = $data['from'];
        $to = $data['to'];

        $result = null;
        $category = null;

        foreach (self::$units as $cat => $units) {
            if (isset($units[$from]) && isset($units[$to])) {
                $category = $cat;
                if ($cat === 'temperature') {
                    $result = self::convertTemperature($value, $from, $to);
                } else {
                    $result = $value * $units[$from] / $units[$to];
                }
                break;
            }
        }

        if ($result === null) {
            return response()->json(['error' => 'Unsupported conversion'], 400);
        }

        return response()->json(['result' => round($result, 6), 'from' => $from, 'to' => $to, 'category' => $category]);
    }

    private static function convertTemperature(float $value, string $from, string $to): float
    {
        $celsius = match ($from) {
            'celsius' => $value,
            'fahrenheit' => ($value - 32) * 5 / 9,
            'kelvin' => $value - 273.15,
            default => $value,
        };
        return match ($to) {
            'celsius' => $celsius,
            'fahrenheit' => $celsius * 9 / 5 + 32,
            'kelvin' => $celsius + 273.15,
            default => $celsius,
        };
    }
}

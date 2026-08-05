<?php
namespace App\Http\Controllers;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversorController extends Controller
{
    private static \ = [
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

    public function convert(Request \): JsonResponse
    {
        \ = \->validate([
            'value' => 'required|numeric',
            'from' => 'required|string',
            'to' => 'required|string',
        ]);

        \ = (float) \['value'];
        \ = \['from'];
        \ = \['to'];

        \ = null;
        \ = null;

        foreach (self::\ as \ => \) {
            if (isset(\[\]) && isset(\[\])) {
                \ = \;
                if (\ === 'temperature') {
                    \ = self::convertTemperature(\, \, \);
                } else {
                    \ = \ * \[\] / \[\];
                }
                break;
            }
        }

        if (\ === null) {
            return response()->json(['error' => 'Unsupported conversion'], 400);
        }

        return response()->json(['result' => round(\, 6), 'from' => \, 'to' => \, 'category' => \]);
    }

    private static function convertTemperature(float \, string \, string \): float
    {
        \ = match (\) {
            'celsius' => \,
            'fahrenheit' => (\ - 32) * 5 / 9,
            'kelvin' => \ - 273.15,
            default => \,
        };
        return match (\) {
            'celsius' => \,
            'fahrenheit' => \ * 9 / 5 + 32,
            'kelvin' => \ + 273.15,
            default => \,
        };
    }
}

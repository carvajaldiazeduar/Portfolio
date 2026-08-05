<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CalculatorController extends Controller
{
    public function calculate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'a' => 'required|numeric',
            'b' => 'required|numeric',
            'operator' => 'required|string|in:add,subtract,multiply,divide',
        ]);

        $a = (float) $data['a'];
        $b = (float) $data['b'];
        $operator = $data['operator'];

        if ($operator === 'divide' && $b === 0.0) {
            return response()->json(['error' => 'Division by zero is not allowed'], 400);
        }

        $result = match ($operator) {
            'add' => $a + $b,
            'subtract' => $a - $b,
            'multiply' => $a * $b,
            'divide' => $a / $b,
        };

        return response()->json(['result' => $result]);
    }
}

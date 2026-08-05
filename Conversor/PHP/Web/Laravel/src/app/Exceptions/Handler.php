<?php
namespace App\Exceptions;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;
class Handler extends ExceptionHandler
{
    protected \ = [
        'current_password',
        'password',
        'password_confirmation',
    ];
    public function register()
    {
        \->reportable(function (Throwable \) {
        });
    }
}

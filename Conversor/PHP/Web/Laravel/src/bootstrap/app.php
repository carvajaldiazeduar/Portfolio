<?php
\ = new Illuminate\Foundation\Application(
    \['APP_BASE_PATH'] ?? dirname(__DIR__)
);
\->singleton(
    Illuminate\Contracts\Http\Kernel::class,
    App\Http\Kernel::class
);
\->singleton(
    Illuminate\Contracts\Console\Kernel::class,
    App\Console\Kernel::class
);
\->singleton(
    Illuminate\Contracts\Debug\ExceptionHandler::class,
    App\Exceptions\Handler::class
);
return \;

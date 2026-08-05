<?php
use App\Kernel;
require_once dirname(__DIR__).'/vendor/autoload_runtime.php';
return function (array \) {
    return new Kernel(\['APP_ENV'], (bool) \['APP_DEBUG']);
};

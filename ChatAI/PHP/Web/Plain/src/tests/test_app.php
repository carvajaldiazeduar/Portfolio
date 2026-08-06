<?php

$_SERVER["REQUEST_METHOD"] = "GET";
$_SERVER["REQUEST_URI"] = "/health";

require_once __DIR__ . "/../index.php";

assert(function_exists('completeChat'));

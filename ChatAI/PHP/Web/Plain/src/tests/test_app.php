<?php

require_once __DIR__ . "/../index.php";

// Basic test assertions
assert(is_array(completeChat([], "gpt-4o-mini", 0.7, 1024, "", "http://stub/v1")));

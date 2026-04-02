<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_origins' => [
  'http://localhost:*',
  'http://127.0.0.1:*',
],
'allowed_headers' => ['*'],
'allowed_methods' => ['*'],
'supports_credentials' => false,
];

<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;
use Illuminate\Auth\Middleware\Authenticate;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {

        // ✅ Global: aktifkan CORS
        $middleware->append(\Illuminate\Http\Middleware\HandleCors::class);

        // ✅ EXCLUDE CSRF: Izinkan EMQX POST data tanpa token CSRF
        $middleware->validateCsrfTokens(except: [
            'api/esp1/*',
            'api/esp2/*',
            'api/esp3/*',
        ]);

        // ✅ FIX: Jangan redirect ke login jika unauthorized (khusus API)
        Authenticate::redirectUsing(function ($request) {
            return $request->expectsJson() ? null : null;
        });

        $middleware->api(append: [
            EnsureFrontendRequestsAreStateful::class,
        ]);

    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })
    ->create();

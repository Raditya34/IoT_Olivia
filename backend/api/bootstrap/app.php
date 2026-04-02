<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;
use Illuminate\Auth\Middleware\Authenticate; // ✅ TAMBAH INI

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

        // ✅ FIX: Jangan redirect ke route('login') untuk request API/JSON
        Authenticate::redirectUsing(function ($request) {
            return $request->expectsJson() ? null : null;
            // kalau kamu suatu saat punya web login, bisa ganti jadi:
            // return $request->expectsJson() ? null : route('login');
        });

        // ✅ API group middleware
        $middleware->api(append: [
            // NOTE: ini untuk SPA (cookie-based). Untuk Flutter token-based, bisa dimatikan.
            EnsureFrontendRequestsAreStateful::class,
        ]);

    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })
    ->create();

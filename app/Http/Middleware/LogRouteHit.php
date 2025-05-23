<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class LogRouteHit
{
    public function handle(Request $request, Closure $next)
    {
        Log::info('🧭   Route hit: ' . $request->method() . ' ' . $request->fullUrl());

        return $next($request);
    }
}

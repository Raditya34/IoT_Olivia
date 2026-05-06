<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; //

class User extends Authenticatable
{
    // Menggunakan trait HasApiTokens agar bisa generate token untuk mobile
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Nama field yang boleh diisi (mass assignable).
     */
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    /**
     * Field yang disembunyikan saat data dikirim ke Flutter.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Relasi ke tabel devices (jika kamu menggunakannya).
     */
    public function devices()
    {
        return $this->hasMany(\App\Models\Device::class);
    }

    /**
     * Konfigurasi casting field database.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}

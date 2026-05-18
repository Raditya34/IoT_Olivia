<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Esp2Bleaching extends Model {
    protected $table = 'esp2_bleaching';
    protected $fillable = ['suhu_bleaching', 'valve', 'p1', 'p2', 'p3', 'h1', 'h2', 'h3', 'h4', 'speed'];
    public $timestamps = false;
}

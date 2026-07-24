<?php

namespace App\Repositories\User\Interface;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

interface UserRepositoryInterface
{
    public function findByEmail(string $mail);
}

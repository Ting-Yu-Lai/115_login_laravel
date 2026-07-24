<?php

namespace App\Repositories\User;

use App\Models\mysql\User;
use App\Repositories\Eloquent\BaseRepository;
use App\Repositories\User\Interface\UserRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Exception;
use Override;
use PhpParser\Node\Expr\AssignOp\Mod;

class UserRepository extends BaseRepository implements UserRepositoryInterface
{
    /**
     * Create a new class instance.
     */
    public function __construct(protected User $user){}

    /**
     * find User Email
     * 
     * @param string $email
     * @return User|null
     */
    public function findByEmail(string $email): ?User
    {
        return $this->user->where('email', $email)->first();
    }
}

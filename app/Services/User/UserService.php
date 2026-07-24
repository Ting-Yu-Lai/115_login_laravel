<?php

namespace App\Services\User;

use Exception;
use App\Services\BaseService;
use App\Models\mysql\User;
use App\Repositories\User\Interface\UserRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;
use App\Repositories\Eloquent\BaseRepository;
use App\Repositories\User\UserRepository;

class UserService extends BaseService
{
    /**
     * Create a new class instance.
     */
    public function __construct(
        protected UserRepositoryInterface $userRepository
    ) {}

    /**
     * find User Email Service
     * 
     * @param string $email
     * @return App\Models\mysql\User|null
     */
    public function findByEmail(string $email): ?User
    {
        return $this->userRepository->findByEmail($email);
    }
}

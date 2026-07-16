<?php

namespace App\Repositories\Eloquent\Interface;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Collection;

interface EloquentRepositoryInterface
{
    public function columsQuery($query, array $params);
    public function search(array $params): LengthAwarePaginator;

    /**
     * @param string $id
     * @return Model
     */
    public function findById(string $id): Model;

    /**
     * @return Model|Collection
     */
    public function findAll(): Collection;

    /**
     * @param array $attributes
     * @return Model
     */
    public function create(array $attributes): Model;

    /**
     * @param array $attributes
     * @return bool
     */
    public function insert(array $attributes): bool;

    /**
     * @param string $id
     * @param array $attributes
     * @return Model
     */
    public function update(string $id, array $attributes): Model;

    /**
     * @param string $id
     * @return bool
     */
    public function delete(string $id): bool;
}

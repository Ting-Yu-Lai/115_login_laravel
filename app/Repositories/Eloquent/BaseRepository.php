<?php

namespace App\Repositories\Eloquent;

use App\Repositories\Eloquent\Interface\EloquentRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Collection;
use Exception;

class BaseRepository implements EloquentRepositoryInterface
{
    /**
     * Create a new class instance.
     */
    public function __construct(protected Model $model)
    {}

    public function columsQuery($query, array $params) {

        $query->select($this->model->getTable() . '.*');

        if (!empty($params['columns'])) {
            $query->select(explode(',', $params['columns']));
        }

        if (isset($params['order']) && isset($params['sort'])) {
            $query->orderBy($params['order'], $params['sort']);
        }

        return $query;
    }

    public function paginateQuery($query, $params): LengthAwarePaginator
    {
        if (isset($params['length'])) {
            return $query->paginate($params['length']);
        }

        return $query->paginate(10);
    }

    public function search(array $params): LengthAwarePaginator
    {
        $query = $this->model->newQuery();

        $query = $this->columsQuery($query, $params);

        return $this->paginateQuery($query, $params);
    }

    public function findById(string $id): Model
    {
        return $this->model->findOrFail($id);
    }

    public function findAll(): Collection
    {
        return $this->model->all();
    }

    public function create(array $attributes): Model
    {
        return $this->model->create($attributes);
    }

    public function insert(array $attributes): bool
    {
        return $this->model->insert($attributes);
    }

    public function update(string $id, array $attributes): Model
    {
        $model = $this->findById($id);

        if(!$model) {
            throw new Exception('查無資訊');
        }

        if(!$model->update($attributes)) {
            throw new Exception('更新失敗');
        }

        return $model;
    }

    public function delete(string $id): bool
    {
        $model = $this->findById($id);

        if(!$model) {
            throw new Exception('查無資訊');
        }

        if(!$model->delete()) {
            throw new Exception('刪除失敗');
        }

        return true;
    }
}

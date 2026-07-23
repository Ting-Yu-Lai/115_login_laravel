<?php

namespace App\Services;

class BaseService
{
    protected $repository;
    
    public function search(array $params) {
        return $this->repository->search($params);
    }

    public function findById(string $id) {
        return $this->repository->findById($id);
    }

    public function findAll() {
        return $this->repository->findAll();
    }

    public function create(array $attributes) {
        return $this->repository->create($attributes);
    }

    public function update(string $id, array $attributes) {
        return $this->repository->update($id, $attributes);
    }

    public function delete(string $id) {
        return $this->repository->delete($id);
    }

}

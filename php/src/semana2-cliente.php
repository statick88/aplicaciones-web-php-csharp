<?php
declare(strict_types=1);

// ============================================================
// Demo S2C1 — Clase Cliente con métodos CRUD en memoria.
// Basado en semana2.md (material proporcionado por el usuario/docente)
// ============================================================

class Cliente
{
    public function __construct(
        public int $id,
        public string $nombre,
        public string $correo,
        public bool $activo = true,
        public ?string $telefono = null,
    ) {}
}

class ClienteRepositorioMemoria
{
    /** @var array<int, Cliente> */
    private array $clientes = [];

    public function registrar(Cliente $c): void
    {
        $this->clientes[$c->id] = $c;
    }

    public function consultar(int $id): ?Cliente
    {
        return $this->clientes[$id] ?? null;
    }

    public function listar(): array
    {
        return array_values($this->clientes);
    }

    public function eliminar(int $id): bool
    {
        if (!isset($this->clientes[$id])) {
            return false;
        }
        unset($this->clientes[$id]);
        return true;
    }

    public function actualizarCorreo(int $id, string $correo): bool
    {
        $c = $this->consultar($id);
        if ($c === null) {
            return false;
        }
        $c->correo = $correo;
        return true;
    }
}

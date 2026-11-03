namespace Facturas.Models;

// S2C1 repository only: it is intentionally independent from invoice persistence.
public class ClienteRepositorioMemoria
{
    private readonly Dictionary<int, Cliente> _clientes = [];

    public void Registrar(Cliente cliente) => _clientes[cliente.Id] = cliente;
    public Cliente? Consultar(int id) => _clientes.GetValueOrDefault(id);
    public IReadOnlyList<Cliente> Listar() => _clientes.Values.ToList();

    public bool Eliminar(int id) => _clientes.Remove(id);

    public bool ActualizarCorreo(int id, string correo)
    {
        Cliente? cliente = Consultar(id);
        if (cliente is null) return false;
        cliente.Correo = correo;
        return true;
    }
}

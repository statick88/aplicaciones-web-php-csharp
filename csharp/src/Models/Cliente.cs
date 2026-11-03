namespace Facturas.Models;

// S2C1: C# declares the shape at compile time; string? represents an optional value.
public class Cliente
{
    public Cliente(int id, string nombre, string correo, bool activo = true, string? telefono = null)
    {
        Id = id;
        Nombre = nombre;
        Correo = correo;
        Activo = activo;
        Telefono = telefono;
    }

    public int Id { get; }
    public string Nombre { get; }
    public string Correo { get; set; }
    public bool Activo { get; }
    public string? Telefono { get; }
}

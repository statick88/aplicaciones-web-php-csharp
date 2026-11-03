namespace Facturas.Models;

public class Semana2Registro
{
    // Form binding may turn whitespace/empty values into null; normalize before validation.
    public string? Nombre { get; set; }
    public string? Correo { get; set; }
    // Kept as text so an invalid value can be rendered back safely after a failed POST.
    public string? Edad { get; set; }
    public string? Carrera { get; set; }
    public string[]? Intereses { get; set; }
}

public class Semana2ClienteSesion
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Correo { get; set; } = string.Empty;
    public int? Edad { get; set; }
    public string Carrera { get; set; } = string.Empty;
    public string[] Intereses { get; set; } = [];
}

public class Semana2FormularioViewModel
{
    public Semana2Registro Registro { get; set; } = new();
    public IReadOnlyList<Semana2ClienteSesion> Clientes { get; set; } = [];
    public int TotalClientes { get; set; }
    public string Consulta { get; set; } = string.Empty;
    public bool RegistroCorrecto { get; set; }
}

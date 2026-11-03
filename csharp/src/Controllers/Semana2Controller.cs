using System.Globalization;
using System.Net.Mail;
using System.Text.Json;
using Facturas.Models;
using Microsoft.AspNetCore.Mvc;

namespace Facturas.Controllers;

// Week 2 is deliberately separate from HomeController and invoice EF persistence.
[Route("Semana2")]
public class Semana2Controller : Controller
{
    private const string ClientesSessionKey = "Semana2.Clientes";
    private static readonly string[] CarrerasValidas = ["SOF", "SIS"];
    private static readonly string[] InteresesValidos = ["web", "movil", "datos"];

    [HttpGet("")]
    public IActionResult Index(string? q)
    {
        string consulta = q?.Trim() ?? string.Empty;
        bool correcto = TempData.ContainsKey("Semana2.RegistroCorrecto");
        if (correcto) TempData.Remove("Semana2.RegistroCorrecto");
        return View("Index", CrearVista(new Semana2Registro { Carrera = "SOF" }, consulta, correcto));
    }

    // Separate receiver, analogous to registro.php.
    [HttpPost("Registrar")]
    [ValidateAntiForgeryToken]
    public IActionResult Registrar([FromForm] Semana2Registro registro) => ProcesarRegistro(registro);

    // Self-processing variant: the same page displays the form and handles this POST.
    [HttpPost("")]
    [ValidateAntiForgeryToken]
    public IActionResult Index([FromForm] Semana2Registro registro) => ProcesarRegistro(registro);

    [HttpGet("Tipos")]
    public IActionResult Tipos()
    {
        int cantidad = 3;
        double precio = 12.50;
        string producto = "Teclado USB";
        bool enStock = true;
        string? descuento = null;
        double subtotal = cantidad * precio;
        double totalConDescuento = subtotal - subtotal * 0.10;
        int enteroDesdeDecimal = (int)3.99;
        double decimalDesdeTexto = double.Parse("8.5", CultureInfo.InvariantCulture);
        bool numerosIgualesTrasParse = int.Parse("1", CultureInfo.InvariantCulture) == int.Parse("01", CultureInfo.InvariantCulture);
        bool textosIgualesOrdinal = string.Equals("1", "01", StringComparison.Ordinal);
        string busquedaId = BuscarCliente(15);
        string busquedaCedula = BuscarCliente("0102");
        var datos = new Dictionary<string, string> { ["ciudad"] = "Ambato" };

        var repositorio = new ClienteRepositorioMemoria();
        repositorio.Registrar(new Cliente(1, "Ana Pérez", "ana@correo.com"));
        repositorio.Registrar(new Cliente(2, "Luis Torres", "luis@correo.com", telefono: "0987654321"));
        bool actualizoAna = repositorio.ActualizarCorreo(1, "ana.perez@correo.com");
        bool actualizoInexistente = repositorio.ActualizarCorreo(999, "nadie@correo.com");
        bool eliminoLuis = repositorio.Eliminar(2);

        ViewData["Escalares"] = $"int={cantidad}; double={precio}; string={producto}; bool={enStock}; null={descuento ?? "ausente"}; subtotal={subtotal}; total 10%={totalConDescuento}";
        ViewData["Casts"] = $"(int)3.99 = {enteroDesdeDecimal}; double.Parse(\"8.5\") = {decimalDesdeTexto}";
        ViewData["Comparacion"] = $"int.Parse(\"1\") == int.Parse(\"01\") = {numerosIgualesTrasParse}; string.Equals(\"1\", \"01\", StringComparison.Ordinal) = {textosIgualesOrdinal}; {busquedaId}; {busquedaCedula}";
        ViewData["Diccionario"] = datos["ciudad"];
        ViewData["Crud"] = repositorio.Listar();
        ViewData["ResultadosCrud"] = $"actualizar Ana={actualizoAna}; actualizar 999={actualizoInexistente}; eliminar Luis={eliminoLuis}; consultar 999={(repositorio.Consultar(999) is null ? "Cliente inexistente" : "encontrado")}; eliminar 999={repositorio.Eliminar(999)}";
        return View();
    }

    private IActionResult ProcesarRegistro(Semana2Registro registro)
    {
        NormalizarYValidar(registro);
        if (!ModelState.IsValid)
        {
            Response.StatusCode = StatusCodes.Status422UnprocessableEntity;
            return View("Index", CrearVista(registro));
        }

        string nombre = registro.Nombre ?? string.Empty;
        string correo = registro.Correo ?? string.Empty;
        string edadTexto = registro.Edad ?? string.Empty;
        string carrera = registro.Carrera ?? string.Empty;
        string[] intereses = registro.Intereses ?? [];
        int? edad = edadTexto.Length == 0 ? null : int.Parse(edadTexto, CultureInfo.InvariantCulture);
        List<Semana2ClienteSesion> clientes = ObtenerClientes();
        clientes.Add(new Semana2ClienteSesion {
            Id = clientes.Count + 1, Nombre = nombre, Correo = correo,
            Edad = edad, Carrera = carrera, Intereses = intereses,
        });
        GuardarClientes(clientes);
        TempData["Semana2.RegistroCorrecto"] = true;
        Response.Headers.Location = Url.Action(nameof(Index));
        return StatusCode(StatusCodes.Status303SeeOther);
    }

    private void NormalizarYValidar(Semana2Registro registro)
    {
        foreach (string campo in new[] { "Nombre", "Correo", "Edad", "Carrera" })
        {
            if (Request.Form[campo].Count != 1)
                ModelState.AddModelError(campo, "El campo debe ser texto.");
        }
        registro.Nombre = (registro.Nombre ?? string.Empty).Trim();
        registro.Correo = (registro.Correo ?? string.Empty).Trim();
        registro.Edad = (registro.Edad ?? string.Empty).Trim();
        registro.Carrera = (registro.Carrera ?? string.Empty).Trim();
        registro.Intereses ??= [];

        if (registro.Nombre.Length is < 1 or > 80)
            ModelState.AddModelError(nameof(registro.Nombre), "El nombre es obligatorio (máximo 80 caracteres).");
        if (!EsCorreoValido(registro.Correo))
            ModelState.AddModelError(nameof(registro.Correo), "Ingrese un correo válido.");
        if (registro.Edad.Length > 0 && (!int.TryParse(registro.Edad, CultureInfo.InvariantCulture, out int edad) || edad is < 16 or > 99))
            ModelState.AddModelError(nameof(registro.Edad), "La edad debe estar entre 16 y 99.");
        if (!CarrerasValidas.Contains(registro.Carrera, StringComparer.Ordinal))
            ModelState.AddModelError(nameof(registro.Carrera), "Carrera no válida.");
        bool formatoInteresesInvalido = Request.Form.Keys.Any(clave =>
            clave.StartsWith("Intereses", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(clave, "Intereses", StringComparison.Ordinal));
        if (formatoInteresesInvalido || registro.Intereses.Any(interes => !InteresesValidos.Contains(interes, StringComparer.Ordinal)))
            ModelState.AddModelError(nameof(registro.Intereses), "Seleccione intereses válidos.");
    }

    private Semana2FormularioViewModel CrearVista(Semana2Registro registro, string consulta = "", bool correcto = false)
    {
        List<Semana2ClienteSesion> todos = ObtenerClientes();
        IEnumerable<Semana2ClienteSesion> clientes = todos;
        if (consulta.Length > 0)
            clientes = clientes.Where(cliente => (cliente.Nombre + " " + cliente.Correo).Contains(consulta, StringComparison.OrdinalIgnoreCase));
        return new Semana2FormularioViewModel { Registro = registro, Clientes = clientes.ToList(), TotalClientes = todos.Count, Consulta = consulta, RegistroCorrecto = correcto };
    }

    private List<Semana2ClienteSesion> ObtenerClientes() =>
        JsonSerializer.Deserialize<List<Semana2ClienteSesion>>(HttpContext.Session.GetString(ClientesSessionKey) ?? "[]") ?? [];

    private void GuardarClientes(List<Semana2ClienteSesion> clientes) =>
        HttpContext.Session.SetString(ClientesSessionKey, JsonSerializer.Serialize(clientes));

    // C# has no int|string parameter union: overloads retain each input's static type.
    private static string BuscarCliente(int id) => $"BuscarPorId({id})";
    private static string BuscarCliente(string cedula) => $"BuscarPorCedula(\"{cedula}\")";

    private static bool EsCorreoValido(string correo)
    {
        try { return new MailAddress(correo).Address == correo; }
        catch (FormatException) { return false; }
    }
}

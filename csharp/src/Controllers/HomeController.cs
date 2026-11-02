using Facturas.Data;
using Facturas.Models;
using Microsoft.AspNetCore.Mvc;

namespace Facturas.Controllers;

// The "C" of MVC: receives requests, talks to the DbContext and picks the view.
public class HomeController : Controller
{
    private readonly FacturasDbContext _db;

    // Class scope: a field lives as long as the controller instance.
    private readonly string _curso = "Aplicaciones Web";

    // Compile-time constant: the value must be known at build time (PHP: const/define).
    public const string CursoConst = "Aplicaciones Web";

    // Prefer passing a parameter over reading shared static state (PHP: global).
    private static string CursoDe(string nombre) => $"Curso: {nombre}";

    public HomeController(FacturasDbContext db)
    {
        _db = db;
    }

    // GET / -> empty form (the view shows the "no es POST" card, same as the PHP exercise)
    public IActionResult Index() => View(new Factura());

    // POST -> model binding maps the form fields into Factura, then EF Core saves the row
    [HttpPost]
    public IActionResult Index(Factura factura)
    {
        if (!ModelState.IsValid)
        {
            return View(factura);
        }

        _db.Facturas.Add(factura);
        _db.SaveChanges();   // INSERT INTO Facturas ...

        factura.Enviada = true;
        return View(factura);
    }

    // GET /Home/Constantes -> S1 demo: const, nullable e interpolación en C#
    public IActionResult Constantes()
    {
        const int MAX = 10;
        string? nullable = null;
        string valor = nullable ?? "default";
        string interp = $"Max={MAX}, valor={valor}";
        return Content(interp);
    }

    // GET /Home/Variables -> S1C2 demo: declaration, typing and scope in C#
    // (PHP counterpart: public/variables.php in the php/ stack)
    public IActionResult Variables()
    {
        // Declaration: explicit types chosen by hand
        string estudiante = "Diego";
        int inscritos = 25;
        bool inscrito = true;

        // var asks the compiler to infer the type (here: double)
        var nota = 9.5;

        // Explicit conversion truncates instead of rounding: 3.99 -> 3
        int parteEntera = (int)3.99;

        // Nullable annotation: a value that may be absent (PHP counterpart: $docente = null)
        string? apellido = null;
        string nombreCompleto = apellido ?? "sin apellido"; // ?? replaces null with a default

        // Block scope: 'estado' is born and dies inside the if block
        if (inscrito)
        {
            string estado = "declarada dentro del if";
            _ = estado; // read it while it exists; outside this block it no longer does
        }

        var filas = new List<VariableDemo>
        {
            new() { Concepto = "string", Codigo = "string estudiante = \"Diego\";", Resultado = estudiante, Tipo = estudiante.GetType().Name },
            new() { Concepto = "int", Codigo = "int inscritos = 25;", Resultado = inscritos.ToString(), Tipo = inscritos.GetType().Name },
            new() { Concepto = "bool", Codigo = "bool inscrito = true;", Resultado = inscrito.ToString(), Tipo = inscrito.GetType().Name },
            new() { Concepto = "var (inferencia de tipo)", Codigo = "var nota = 9.5;", Resultado = nota.ToString(System.Globalization.CultureInfo.InvariantCulture), Tipo = nota.GetType().Name },
            new() { Concepto = "Conversión explícita (trunca)", Codigo = "int parteEntera = (int)3.99;", Resultado = parteEntera.ToString(), Tipo = typeof(int).Name },
            new() { Concepto = "Ámbito de clase (campo)", Codigo = "private readonly string _curso = \"Aplicaciones Web\";", Resultado = _curso, Tipo = _curso.GetType().Name },
            new() { Concepto = "Ámbito de bloque", Codigo = "if (inscrito) { string estado = \"...\"; }", Resultado = "'estado' no existe fuera del bloque: no compilaría", Tipo = "—" },
            new() { Concepto = "Ámbito local (método)", Codigo = "string estudiante = \"Diego\"; // dentro de Variables()", Resultado = "'estudiante' no existe fuera del método", Tipo = "—" },
            new() { Concepto = "const (valor de compilación)", Codigo = "public const string CursoConst = \"Aplicaciones Web\";", Resultado = CursoConst, Tipo = "String" },
            new() { Concepto = "nullable y ??", Codigo = "string? apellido = null; string completo = apellido ?? \"sin apellido\";", Resultado = nombreCompleto, Tipo = nombreCompleto.GetType().Name },
            new() { Concepto = "Interpolación de cadena", Codigo = "$\"Curso: {estudiante}\"", Resultado = $"Curso: {estudiante}", Tipo = "String" },
            new() { Concepto = "Parámetro vs. estado compartido", Codigo = "CursoDe(\"Aplicaciones Web\")", Resultado = CursoDe("Aplicaciones Web"), Tipo = "String" },
        };

        return View(filas);
    }
}

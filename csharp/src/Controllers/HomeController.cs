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
        _db.Facturas.Add(factura);
        _db.SaveChanges();   // INSERT INTO Facturas ...

        factura.Enviada = true;
        return View(factura);
    }

    // GET /Home/Variables -> S1C2 demo: declaration, typing and scope in C#
    // (PHP counterpart: src/variables.php in the php/ stack)
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
        };

        return View(filas);
    }
}

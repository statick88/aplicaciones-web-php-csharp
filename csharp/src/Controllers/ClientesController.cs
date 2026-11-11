using Facturas.Data;
using Facturas.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Facturas.Controllers;

// Week 3: a deliberately small MVC CRUD backed by the existing SQL Server context.
public class ClientesController : Controller
{
    private readonly FacturasDbContext _db;

    public ClientesController(FacturasDbContext db) => _db = db;

    public async Task<IActionResult> Index() => View(await _db.Clientes.AsNoTracking().OrderBy(c => c.Id).ToListAsync());

    public async Task<IActionResult> Details(int? id)
    {
        ClienteSemana3? cliente = await BuscarCliente(id);
        return cliente is null ? NotFound() : View(cliente);
    }

    public IActionResult Create() => View(new ClienteSemana3 { Activo = true });

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create([Bind("Cedula,Nombres,Apellidos,Correo,Telefono,Direccion,Ciudad,Provincia,FechaNacimiento,Activo")] ClienteSemana3 cliente)
    {
        if (!ModelState.IsValid) return View(cliente);

        _db.Clientes.Add(cliente);
        await _db.SaveChangesAsync();
        return RedirectToAction(nameof(Details), new { id = cliente.Id });
    }

    public async Task<IActionResult> Edit(int? id)
    {
        ClienteSemana3? cliente = await BuscarCliente(id);
        return cliente is null ? NotFound() : View(cliente);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit([FromRoute] int id, [Bind("Cedula,Nombres,Apellidos,Correo,Telefono,Direccion,Ciudad,Provincia,FechaNacimiento,Activo")] ClienteSemana3 cambios)
    {
        ClienteSemana3? cliente = await _db.Clientes.FindAsync(id);
        if (cliente is null) return NotFound();
        if (!ModelState.IsValid)
        {
            cambios.Id = id;
            return View(cambios);
        }

        cliente.Cedula = cambios.Cedula;
        cliente.Nombres = cambios.Nombres;
        cliente.Apellidos = cambios.Apellidos;
        cliente.Correo = cambios.Correo;
        cliente.Telefono = cambios.Telefono;
        cliente.Direccion = cambios.Direccion;
        cliente.Ciudad = cambios.Ciudad;
        cliente.Provincia = cambios.Provincia;
        cliente.FechaNacimiento = cambios.FechaNacimiento;
        cliente.Activo = cambios.Activo;
        await _db.SaveChangesAsync();
        return RedirectToAction(nameof(Details), new { id });
    }

    public async Task<IActionResult> Delete(int? id)
    {
        ClienteSemana3? cliente = await BuscarCliente(id);
        return cliente is null ? NotFound() : View(cliente);
    }

    [HttpPost, ActionName(nameof(Delete))]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed([FromRoute] int id)
    {
        ClienteSemana3? cliente = await _db.Clientes.FindAsync(id);
        if (cliente is null) return NotFound();

        _db.Clientes.Remove(cliente);
        await _db.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }

    private Task<ClienteSemana3?> BuscarCliente(int? id) =>
        id is null ? Task.FromResult<ClienteSemana3?>(null) : _db.Clientes.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id);
}

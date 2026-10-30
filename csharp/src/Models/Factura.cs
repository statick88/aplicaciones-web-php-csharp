using System.ComponentModel.DataAnnotations.Schema;

namespace Facturas.Models;

// The invoice form data (the "M" of MVC) and a row in the Facturas table.
public class Factura
{
    // PK by EF convention: int named Id -> IDENTITY column
    public int Id { get; set; }

    public string NumeroFactura { get; set; } = string.Empty;
    public string Cedula { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Telefono { get; set; } = string.Empty;
    public string Direccion { get; set; } = string.Empty;
    public string Mail { get; set; } = string.Empty;

    // True after a POST; decides which card the view renders (mirrors the PHP exercise).
    // View state only: [NotMapped] keeps it out of the table.
    [NotMapped]
    public bool Enviada { get; set; }
}

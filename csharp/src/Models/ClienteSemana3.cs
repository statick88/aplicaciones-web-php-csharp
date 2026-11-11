using System.ComponentModel.DataAnnotations;

namespace Facturas.Models;

// Week 3: persistent customer data for the MVC CRUD exercise.
public class ClienteSemana3
{
    public int Id { get; set; }

    [Required(ErrorMessage = "La cédula es obligatoria.")]
    [StringLength(10, MinimumLength = 10, ErrorMessage = "La cédula debe tener 10 caracteres.")]
    public string Cedula { get; set; } = string.Empty;

    [Required(ErrorMessage = "Los nombres son obligatorios.")]
    [StringLength(80)]
    public string Nombres { get; set; } = string.Empty;

    [Required(ErrorMessage = "Los apellidos son obligatorios.")]
    [StringLength(80)]
    public string Apellidos { get; set; } = string.Empty;

    [Required(ErrorMessage = "El correo es obligatorio.")]
    [EmailAddress(ErrorMessage = "Ingrese un correo válido.")]
    [StringLength(120)]
    public string Correo { get; set; } = string.Empty;

    [Required(ErrorMessage = "El teléfono es obligatorio.")]
    [StringLength(20)]
    public string Telefono { get; set; } = string.Empty;

    [Required(ErrorMessage = "La dirección es obligatoria.")]
    [StringLength(160)]
    public string Direccion { get; set; } = string.Empty;

    [Required(ErrorMessage = "La ciudad es obligatoria.")]
    [StringLength(80)]
    public string Ciudad { get; set; } = string.Empty;

    [Required(ErrorMessage = "La provincia es obligatoria.")]
    [StringLength(80)]
    public string Provincia { get; set; } = string.Empty;

    [Required(ErrorMessage = "La fecha de nacimiento es obligatoria.")]
    [DataType(DataType.Date)]
    public DateTime? FechaNacimiento { get; set; }

    public bool Activo { get; set; }
}

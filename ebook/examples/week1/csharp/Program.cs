using System.Globalization;

CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;

const string Curso = "PHP-CSharp";
var etiqueta = "Semana 1"; // var infiere string; no vuelve dinámico el tipo.
int exterior = 10;
int bloque;
{
    bloque = 7;
}

string nombre = "Ada";
string saludo = $"Hola {nombre}";
string concatenacion = "3" + 3;
int primeraCuenta = ContadorDeProceso.Siguiente();
int segundaCuenta = ContadorDeProceso.Siguiente();

AssertEqual("PHP-CSharp", Curso, "constante");
AssertEqual("Semana 1", etiqueta, "inferencia");
AssertEqual(7, bloque, "ámbito de bloque");
AssertEqual("33", concatenacion, "concatenación C#");
AssertEqual(1, primeraCuenta, "primer contador");
AssertEqual(2, segundaCuenta, "segundo contador");

Console.WriteLine($"CONST|curso={Curso}|etiqueta={etiqueta}");
Console.WriteLine($"SCOPE|bloque={bloque}|exterior={exterior}|static={primeraCuenta},{segundaCuenta}");
Console.WriteLine($"STRING|interpolacion={saludo}|suma={concatenacion}");

static void AssertEqual<T>(T expected, T actual, string label) where T : IEquatable<T>
{
    if (!expected.Equals(actual))
    {
        throw new InvalidOperationException($"Fallo en {label}");
    }
}

static class ContadorDeProceso
{
    private static int valor;

    public static int Siguiente() => ++valor;
}

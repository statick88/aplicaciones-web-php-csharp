# Software: tipos, dominios y mitos

**Meta.** Al terminar podrás clasificar un producto por la función técnica que
cumple y por el dominio donde se usa, sin confundir herramientas con categorías.
También podrás reemplazar afirmaciones absolutas por preguntas que guíen una acción
responsable [@blackboard-arq-s1].

## Objetivos de aprendizaje

- Distinguir tipos técnicos de software de sus dominios de aplicación.
- Explicar por qué lenguaje, intérprete, editor, framework y runtime no son sinónimos.
- Analizar los cuatro mitos de la semana mediante condiciones, consecuencias y acciones.

**Pregunta de recuperación.** ¿Puede el mismo programa ser software de aplicación y
pertenecer al dominio educativo? Justifica con dos criterios distintos.

## Dos ejes para no mezclar etiquetas

El **tipo técnico** describe el papel que el software cumple dentro de un entorno.
El **dominio de uso** describe el problema humano, organizacional o físico al que se
aplica. Un sistema puede tener varias piezas técnicas y servir a un dominio concreto;
por eso «educativo» no compite con «de aplicación» como si fueran respuestas al mismo
enunciado.

| Tipo técnico | Papel principal | Ejemplo posible |
|---|---|---|
| De sistema | Gestiona recursos o proporciona base para otros programas | sistema operativo o controlador |
| De aplicación | Ayuda directamente a realizar una tarea de usuario | portal para reservar libros |
| De desarrollo | Ayuda a crear, probar o entregar otros programas | compilador o depurador |

Los dominios dan otro contexto: una aplicación de facturación pertenece al negocio;
un aula virtual, a educación; un programa que procesa datos de un experimento, a la
ciencia; y el firmware que controla un sensor, a un sistema embebido. Esta etiqueta
no determina por sí sola el lenguaje ni la arquitectura.

## Una herramienta no cambia de categoría por su nombre

Python es un **lenguaje**: un conjunto de reglas para expresar programas. Un
**intérprete** de Python ejecuta o evalúa esos programas. Un editor ayuda a escribir
archivos; un framework aporta convenciones y componentes para construir una clase de
aplicación; un runtime ofrece el entorno de ejecución. Cumplen funciones distintas,
aunque una distribución los presente juntos.

Por ello, Python, su intérprete y un editor no son tres «tipos principales» de
software comparables. Un editor puede ser software de desarrollo; el intérprete
puede formar parte de la plataforma que ejecuta un programa; un framework no define
el dominio del producto. Preguntar «¿qué hace esta pieza para quién?» evita una
clasificación por marcas.

## Clasificación trabajada

Considera una aplicación web donde estudiantes reservan salas de estudio. La interfaz
que muestra horarios y confirma reservas es **software de aplicación**: atiende una
tarea de quienes usan la biblioteca. Su dominio es **educativo**, porque organiza un
recurso de aprendizaje, aunque también tenga reglas administrativas. El sistema
operativo del servidor que la sostiene gestiona recursos y es software de **sistema**; el
editor y las pruebas automatizadas que usa el equipo son software de **desarrollo**.

Ahora cambia el dominio sin cambiar la tecnología: el mismo lenguaje Python, el
mismo framework web y una base de datos pueden sostener reservas de equipos en un
laboratorio científico. La aplicación sigue siendo de aplicación, pero el dominio
prioritario pasa a ser **científico**. La tecnología describe una elección de
implementación; la finalidad y personas atendidas justifican el dominio.

## Cuatro mitos que ocultan condiciones

### «Agregar programadores tarde arregla el atraso»

Puede parecer razonable cuando hay tareas pendientes. Falla si quienes llegan deben
aprender contexto, coordinarse y dividir un trabajo que no era divisible: al principio
puede aumentar la comunicación y los errores. Un contraejemplo es una tarea aislada,
bien especificada y con incorporación preparada, que sí puede repartir trabajo útil.
La acción no es prohibir contratar: es revisar el cuello de botella, el tiempo de
incorporación y qué entregable puede asumir cada persona.

### «Si funciona, está terminado»

Una demostración que produce el resultado esperado aporta evidencia, pero no prueba
seguridad, mantenibilidad, operación ni comprensión de los límites. Por ejemplo, una
reserva puede funcionar hoy y carecer de control de acceso o de registro para atender
un incidente. La acción es acordar qué significa terminado para ese contexto: pruebas
pertinentes, revisión, documentación y condiciones de entrega, sin suponer una lista
idéntica para todo producto.

### «Cada cambio es fácil»

Cambiar una línea puede ser sencillo; cambiar una regla compartida, una interfaz o un
dato histórico puede afectar contratos y personas usuarias. El contraejemplo es un
texto aislado con pruebas que confirma el cambio. Antes de estimar, se rastrean
módulos, dependencias y datos; después se prueba el comportamiento afectado. El
software puede evolucionar, pero no todo cambio tiene el mismo coste ni riesgo.

### «No hace falta documentación»

El código muestra una implementación, no siempre por qué se eligió, qué alternativa
se descartó o qué supuesto operativo sigue vigente. En un equipo pequeño y una
corrección local, una explicación breve junto al cambio puede bastar; eso no elimina
la necesidad de dejar decisiones relevantes recuperables. La acción es documentar
lo que ayuda a operar, cambiar y revisar: propósito, interfaz, decisión y evidencia,
manteniéndolo cercano a quien lo usa.

## Ejercicio breve

Clasifica un programa que recoge lecturas de temperatura desde un sensor y envía una
alarma a personal de mantenimiento. Indica tipo técnico, dominio y una pregunta que
harías antes de decidir si es embebido.

::: {.callout-note collapse="true" title="Retroalimentación razonada"}
El programa que controla directamente el sensor puede ser software de sistema o
embebido según su función y entorno; el dominio podría ser industrial o científico,
según el propósito de las mediciones. Preguntaría si se ejecuta dentro de un dispositivo
con recursos y responsabilidades específicas, en vez de etiquetarlo solo porque usa
un sensor. La alarma puede ser otra aplicación conectada: clasificar sus piezas evita
forzar una sola etiqueta al conjunto.
:::

## Conclusión

Clasificar con dos ejes da una explicación verificable: primero el papel técnico,
después el dominio y la evidencia de su finalidad. Los mitos fallan porque borran
condiciones; una decisión madura las vuelve preguntas sobre personas, dependencias,
calidad y contexto. Esa conclusión permite actuar sin prometer que toda contratación,
cambio o documentación tenga el mismo resultado.

**Recuerdo rápido.** Ante «funciona, luego está terminado», ¿qué evidencia de calidad
pedirías para este producto y por qué?

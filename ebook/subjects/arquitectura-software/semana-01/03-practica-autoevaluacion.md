# Práctica integrada y autoevaluación de la Semana 1

**Propósito.** Esta propuesta de estudio integra los conceptos de la Semana 1 para
preparar una evaluación: no es una nueva tarea institucional ni un diseño de
producción. Trabajarás sobre el caso ficticio de reservas de biblioteca ya usado en
la teoría, con decisiones que puedes explicar y comprobar de forma observable.

## Ruta de trabajo

1. Lee el caso y elige una alternativa antes de abrir su retroalimentación.
2. Contrasta cada alternativa con el caso y sus restricciones.
3. Usa las comprobaciones para identificar qué concepto conviene releer.

::: {.callout-important}
## Qué se espera en esta práctica

No hay ejecución, nota ni evidencia de rendimiento que producir. Las comprobaciones
proponen una mejor alternativa bajo las premisas declaradas; no convierten una
arquitectura o un estilo en una respuesta universal.
:::

## Caso guiado: una reserva sin promesas duplicadas

Una biblioteca permite que estudiantes soliciten un ejemplar. Dos solicitudes pueden
llegar cuando queda una sola copia. El equipo quiere confirmar únicamente una reserva
activa y avisar el resultado. La pantalla actual consulta los datos y envía correos
por su cuenta.

### 1. Del enunciado a la clasificación

| Pregunta | Respuesta de trabajo | Por qué importa |
|---|---|---|
| Necesidad | No confirmar dos reservas activas para el mismo ejemplar. | Hace explícita la regla antes de elegir tecnología. |
| Tipo técnico | La interfaz de reserva es software de aplicación. | Ayuda directamente a una persona a completar una tarea. |
| Dominio | Educativo, pues organiza un recurso de aprendizaje. | El dominio describe la finalidad, no el lenguaje usado. |
| Función principal | Registrar o rechazar una solicitud según disponibilidad. | Separa el comportamiento esperado de la forma de implementarlo. |

El sistema operativo que sostiene el servidor es, sin ambigüedad, software de
sistema: administra recursos y sirve de base a programas. Esa clasificación no
convierte por sí sola a cada componente ni a todo gestor de datos en software de
sistema. También conviene separar las herramientas: un lenguaje expresa el programa,
un editor ayuda a escribirlo y el runtime proporciona condiciones de ejecución.

### 2. Decisión de diseño y arquitectura

La decisión propuesta es concentrar la regla en un módulo `Reservas`. La pantalla
pide `solicitar(ejemplar, persona)`; `Reservas` consulta una interfaz de
`Disponibilidad` que comprueba y marca la copia como una sola operación. Cuando hay
resultado final, `Notificaciones` comunica la confirmación o el rechazo.

Esta es una decisión de **diseño** porque distribuye responsabilidades. Adquiere
alcance **arquitectónico** si esa interfaz y su regla condicionan varias pantallas,
equipos o despliegues. En ambos casos el análisis la precede: identifica actores,
regla y resultado sin decidir todavía tablas, servidores o lenguaje.

::: {.table-responsive tabindex="0" role="region" aria-label="Tabla de responsabilidades e interfaces"}

| Responsabilidad | Interfaz o entrada | Resultado que entrega |
|---|---|---|
| Pantalla | datos de ejemplar y persona | muestra un resultado, sin cambiar inventario |
| `Reservas` | `solicitar(ejemplar, persona)` | confirmación o rechazo con motivo |
| `Disponibilidad` | comprobar y marcar | una sola copia marcada o no disponible |
| `Notificaciones` | resultado final | aviso preparado para la persona |

:::

La separación reduce el acoplamiento: cambiar el medio de aviso no debe exigir que
la pantalla conozca la regla de inventario. A la vez, `Reservas` mantiene cohesión si
sus tareas se relacionan con decidir una reserva, no con presentar pantallas o
administrar correos. No se recomienda reintentar ciegamente una solicitud: repetir
una operación no idempotente podría crear otra reserva. Ante un fallo se define qué
resultado quedó registrado y cómo se consulta o resuelve antes de intentar de nuevo.

### 3. Criterio de calidad y comprobación

El criterio propuesto es **consistencia** de la regla: ante dos solicitudes
controladas para el mismo ejemplar disponible, se observa una confirmación, un
rechazo y una sola reserva activa en el registro. Esto comprueba comportamiento
funcional y consistencia de datos; no demuestra que el servicio esté disponible. La
**disponibilidad** pregunta, en cambio, si el servicio puede atender solicitudes
cuando falla un componente o existe una interrupción. Son cualidades relacionadas,
pero no intercambiables.

::: {.callout-note collapse="true" title="Ejemplo parcial trabajado"}
**Registro de decisión breve.** Contexto: queda un ejemplar y pueden coincidir dos
solicitudes. Decisión: `Reservas` usa una operación de disponibilidad que comprueba y
marca de forma atómica. Alternativa descartada por ahora: dejar que cada pantalla
actualice disponibilidad; duplica una regla crítica y aumenta el riesgo de cambios
inconsistentes. Consecuencia: las pantallas dependen de una interfaz estable, pero el
equipo debe definir el resultado de una solicitud interrumpida.

El ejemplo no decide si el sistema será monolito o microservicios. Un monolito por
capas puede respetar estas fronteras; separar servicios solo sería razonable con una
necesidad y costo de operación justificados.
:::

### 4. Mito que el caso ayuda a evitar

Decir «si la demostración reserva un libro, está terminado» omite autorizaciones,
registros, casos de concurrencia y condiciones de operación. La demostración aporta
una señal, pero el criterio observable anterior agrega evidencia sobre una regla
importante. No convierte la práctica en una garantía de seguridad, disponibilidad ni
calidad total.

## Ejercicio análogo: préstamo de equipos

Una sala de innovación presta una cámara a estudiantes; hay una cámara libre y dos
solicitudes pueden coincidir. Elige el diseño que protege la regla y lee la
retroalimentación.

<!-- quiz: arq-s1-caso-regla -->

## Autoevaluación formativa

Elige una alternativa en cada caso y lee su retroalimentación. Estas preguntas son
originales para el estudio de esta semana: no se copian de Educaplay ni representan
calificación oficial.

### 1. De necesidad a decisión

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-analisis -->

### 2. Fronteras, acoplamiento y cohesión

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-fronteras -->

### 3. Vista y notación

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-vista -->

### 4. Estilo con contexto

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-estilo -->

### 5. Dos cualidades distintas

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-cualidades -->

### 6. Tipo, dominio y herramientas

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-clasificacion -->

### 7. Mito: sumar personas tarde

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-sumar-personas -->

### 8. Mito: «funciona, está terminado»

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-terminado -->

### 9. Mito: «cada cambio es fácil»

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-cambio -->

### 10. Mito: «no hace falta documentación»

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s1-documentacion -->

## Cierre

La práctica se completa al relacionar la alternativa elegida con necesidad, frontera y
observación. Si una alternativa no encaja, vuelve al concepto enlazado y revisa qué
evidencia del caso cambia la decisión.

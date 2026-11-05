# Modelos de proceso: comparación, práctica y autoevaluación

**Propósito.** Esta lectura compara cascada, incremental, evolutivo y espiral para
estudiar decisiones de proceso. Incluye un caso original de reservas de biblioteca,
una práctica análoga y diez preguntas con retroalimentación razonada. No reproduce
ni resuelve el sistema de pedidos de restaurante ni el Taller 1.2 mencionados en la
fuente oficial [@blackboard-arq-s2].

## Ruta de estudio

1. Compara cada modelo por las condiciones que aprovecha y los problemas que debe
   controlar.
2. Resuelve el caso antes de abrir la decisión trabajada.
3. Justifica un modelo con requisitos, entregas, retroalimentación y riesgos; no lo
   elijas por popularidad.
4. Contesta la autoevaluación con tus palabras y contrasta el razonamiento.

## Cuatro modelos, cuatro énfasis

Un **modelo de proceso** organiza cómo se planifican actividades, recursos, tiempos,
cambios y riesgos. Su elección depende del tamaño y complejidad del proyecto, el
presupuesto, el tiempo disponible y la estabilidad de los requisitos. Ninguna etiqueta
elimina la necesidad de diseñar, implementar, probar y mantener con evidencia.

::: {.table-responsive tabindex="0" role="region" aria-label="Comparación de modelos de proceso de software"}

| Modelo | Organización central | Es útil considerar cuando | Límite que debe controlarse |
|---|---|---|---|
| Cascada | fases secuenciales y documentadas | los requisitos son claros y estables, y el trabajo puede planificarse con pocas revisiones | los cambios son costosos y algunos errores pueden aparecer tarde |
| Incremental | entregas parciales con funciones integradas progresivamente | conviene entregar valor temprano y ampliar el sistema por partes | exige planificar fronteras e integración; el control puede volverse complejo |
| Evolutivo | versiones que cambian con retroalimentación frecuente | las necesidades deben descubrirse o ajustarse junto con las personas usuarias | tiempo, costo y alcance pueden ser difíciles de estimar si no se controla el aprendizaje |
| Espiral | ciclos de planificación, construcción y evaluación de riesgos | el proyecto es grande o complejo y existen riesgos que justifican análisis repetido | su gestión es costosa, compleja y requiere experiencia técnica |

:::

La tabla no es una puntuación. Requisitos estables favorecen una secuencia planificada,
pero no vuelven infalible a cascada. Una entrega temprana favorece incrementos, pero
cada incremento debe integrarse y probarse. La retroalimentación favorece evolución,
pero necesita límites para no convertirse en cambios sin dirección. Un riesgo alto
puede justificar ciclos de espiral, pero no toda aplicación pequeña necesita esa
carga de gestión.

## Cascada: previsibilidad cuando el cambio es limitado

En cascada, una fase se completa antes de iniciar formalmente la siguiente. Es fácil
de explicar y favorece una organización documentada. Su supuesto más exigente es que
las decisiones tempranas serán suficientemente estables. Si la biblioteca ya tiene
reglas legales fijas, formatos aprobados y una única migración definida, una secuencia
planificada puede ser defendible. Si las personas aún no saben cómo usarán la reserva,
la validación tardía aumenta el costo de corregir el enfoque.

La desventaja no significa que el modelo «nunca pruebe» o que el equipo deba ignorar
un error temprano. Significa que el flujo principal separa fases y ofrece menos
flexibilidad ante cambios; por eso la calidad de requisitos y revisiones iniciales es
crítica.

## Incremental: entregar capacidades completas por partes

El modelo incremental divide el producto en **incrementos funcionales**. Cada entrega
incorpora una parte utilizable y se integra con lo anterior. Para reservas, un primer
incremento podría consultar disponibilidad; el segundo, registrar y cancelar; el
tercero, notificar. El orden debe responder a valor y dependencias, no a cortar capas
incompletas como «primero todas las pantallas y meses después todas las reglas».

Entregar temprano permite detectar defectos y aprender, pero no garantiza flexibilidad
infinita. Una mala frontera puede duplicar reglas o dificultar la integración. La
planificación define qué capacidad queda completa, qué contrato conserva y cómo se
probará junto con los incrementos previos.

## Evolutivo: aprender con versiones y retroalimentación

El modelo evolutivo desarrolla el software de manera progresiva según necesidades de
las personas usuarias. Es adecuado cuando la interacción y el aprendizaje frecuente
son centrales. Una versión inicial de reservas podría revelar que «disponible» no
basta: estudiantes necesitan saber capacidad, equipamiento y accesibilidad de la
sala. La retroalimentación cambia el producto y puede revisar requisitos y diseño.

La flexibilidad necesita control. El equipo registra qué hipótesis valida cada versión,
qué cambio se acepta y qué evidencia permite decidir. Sin esas condiciones, el alcance
puede crecer de forma desorganizada y las estimaciones pierden utilidad.

## Espiral: ciclos guiados por riesgo

El modelo espiral combina desarrollo iterativo y análisis de riesgos. Cada ciclo hace
visible qué incertidumbre o amenaza se estudiará antes de comprometer más trabajo. En
una red grande de bibliotecas, un riesgo podría ser migrar reservas históricas sin
crear dobles ocupaciones. Un ciclo puede estudiar datos, construir una prueba limitada
y evaluar resultados antes de ampliar la migración.

Su ventaja es atender riesgos de forma explícita en proyectos complejos. Su costo es
la planificación continua, la experiencia y el esfuerzo de evaluación. Nombrar una
lista de riesgos no convierte automáticamente un proyecto en espiral: el flujo debe
usar esos riesgos para orientar los ciclos y las decisiones.

## Caso trabajado: reservas para una red de bibliotecas

La red quiere sustituir hojas separadas por un servicio de reservas. Se conocen la
regla de no duplicar horarios y la fecha del piloto. Todavía se desconoce qué filtros
necesitan estudiantes y personal. Además, migrar reservas existentes podría producir
conflictos.

### Evidencia disponible

- **Estable:** una sala no puede tener reservas activas superpuestas.
- **Necesidad temprana:** una sede debe usar el servicio en seis semanas.
- **Incertidumbre:** filtros, mensajes y flujo de modificación se aclararán con el
  piloto.
- **Riesgo:** datos históricos inconsistentes pueden bloquear o duplicar horarios.

### Comparación antes de decidir

**Cascada** daría una secuencia clara, pero exigiría cerrar pronto requisitos de uso
que aún necesitan retroalimentación. **Evolutivo** permite aprender sobre esos
requisitos, aunque por sí solo no expresa qué capacidad completa se entregará en seis
semanas. **Espiral** es útil para la migración riesgosa, pero podría ser una gestión
excesiva para toda la interfaz del piloto. **Incremental** permite ordenar capacidades
y entregar una primera utilidad, siempre que el equipo incluya puntos de
retroalimentación y trate el riesgo de datos de forma explícita.

### Decisión razonada

Para el piloto se elige un flujo **incremental**:

1. consultar salas y disponibilidad en una sede;
2. crear y cancelar una reserva sin solapamientos;
3. incorporar filtros y mensajes ajustados con la retroalimentación del piloto;
4. ampliar a otra sede solo después de evaluar la migración de sus datos.

La elección no declara que incremental sea universalmente mejor. Responde a entrega
temprana, capacidades separables y aprendizaje esperado. El riesgo de migración se
analiza antes de cada ampliación; eso es una práctica de gestión coherente con la
comparación, no una afirmación de que todo el proyecto usa simultáneamente todos los
modelos.

### Criterios observables

- El primer incremento permite consultar horarios reales de una sede.
- El segundo rechaza solapamientos y conserva una sola reserva activa.
- La retroalimentación del piloto se registra como hipótesis, evidencia y cambio.
- La ampliación se detiene si la prueba de migración produce conflictos sin resolver.

::: {.callout-note collapse="true" title="Por qué la justificación es más importante que la etiqueta"}
Otra respuesta podría elegir un enfoque evolutivo si la prioridad principal fuera
aprender la interacción antes de fijar entregas, o espiral si la migración implicara
un riesgo crítico y costoso en toda la red. Sería válida si relaciona la elección con
hechos del caso, explica límites y propone evidencia. No basta con afirmar «es más
moderno» o «es más seguro».
:::

## Práctica análoga: agenda de espacios comunitarios

Un municipio desea una agenda para reservar canchas y salones comunitarios. Las
reglas de horario y responsables están aprobadas, pero no se conoce qué vista será
más comprensible para la ciudadanía. Se necesita publicar una primera capacidad en
un mes. Hay riesgo de importar duplicados desde hojas de cálculo.

### Entregable de estudio

Escribe una página breve con:

1. hechos estables, incertidumbres y riesgos;
2. comparación de al menos dos modelos;
3. modelo elegido y razón contextual;
4. dos entregas o ciclos con resultados observables;
5. una condición que haría revisar la elección.

No implementes un sistema ni inventes métricas. La práctica evalúa razonamiento: una
respuesta alternativa es válida si conserva las reglas y explica consecuencias.

::: {.callout-tip collapse="true" title="Pista opcional"}
Separa la necesidad de publicar temprano, que favorece pensar en incrementos, de la
incertidumbre de interfaz, que requiere retroalimentación. Después pregunta si el
riesgo de datos justifica un ciclo específico antes de ampliar el servicio.
:::

::: {.callout-note collapse="true" title="Ejemplo parcial de respuesta"}
Un primer incremento podría mostrar disponibilidad y reglas aprobadas; un segundo,
permitir reservas y cancelaciones. Después de probar la vista con personas usuarias,
el equipo ajustaría lenguaje y filtros. Antes de importar otra hoja, ejecutaría una
prueba de duplicados y detendría la ampliación si aparecen conflictos. Esta respuesta
elige incremental por entrega temprana, incorpora retroalimentación y trata el riesgo
sin afirmar que una sola etiqueta resuelve todo.
:::

## Autoevaluación formativa

Responde primero sin abrir la retroalimentación. Estas diez preguntas son originales
del cuaderno: no son respuestas de una evaluación, del crucigrama, del Taller 1.2 ni
del caso oficial de restaurante.

### 1. Actividad y tarea

¿Cuál es la diferencia entre «pruebas» como actividad general y «comprobar que una
sala ocupada no acepta otra reserva» como tarea?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 1"}
Pruebas nombra un tipo amplio de trabajo orientado a obtener evidencia. La segunda
frase define una tarea concreta con condición y resultado observable. Varias tareas
pueden pertenecer a la actividad de pruebas; describirlas permite revisar avance y
resultado sin suponer que una columna llamada «Pruebas» garantiza calidad.
:::

### 2. Flujo que vuelve atrás

Una prueba revela que nadie definió cuánto dura una reserva provisional. ¿Por qué
volver a requisitos no significa necesariamente que el proceso haya fracasado?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 2"}
La prueba hizo visible una decisión faltante. Volver a requisitos permite aclarar la
regla antes de consolidar una implementación arbitraria. El fracaso sería ocultar la
incertidumbre o repetir trabajo sin aprender. Un flujo útil comunica devoluciones y
actualiza diseño, código y pruebas con la decisión acordada.
:::

### 3. Patrón sin receta

El equipo quiere reutilizar una solución que separa la disponibilidad de la pantalla.
¿Qué debe comprobar antes de llamarla una buena reutilización?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 3"}
Debe comprobar que existe un problema comparable: varias interfaces necesitan una
regla consistente y conviene protegerla detrás de un contrato. También debe revisar
consecuencias, como coordinación y manejo de errores. Reutilizar el nombre o la forma
sin compartir el problema puede añadir complejidad y no ofrece el beneficio esperado.
:::

### 4. Cascada y estabilidad

¿Qué dato del proyecto apoyaría elegir cascada y qué dato haría esa elección más
arriesgada?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 4"}
Apoya cascada que los requisitos, formatos y criterios estén claros, aprobados y sean
poco propensos al cambio. La vuelve más arriesgada que el uso real todavía deba
descubrirse o que decisiones tempranas dependan de retroalimentación tardía. La
secuencia es una ventaja solo si sus supuestos coinciden con el contexto.
:::

### 5. Incremento funcional

¿Por qué «crear todas las pantallas» no es necesariamente un buen primer incremento?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 5"}
Un incremento debe entregar una capacidad funcional integrada, no solo una capa sin
reglas ni datos. Una consulta de disponibilidad completa puede incluir interfaz,
regla, integración y prueba en un alcance pequeño. Cortar por capas puede aplazar el
valor y descubrir tarde problemas de integración.
:::

### 6. Evolución con control

¿Qué registro mínimo evitaría que un proceso evolutivo se convierta en una lista
ilimitada de cambios?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 6"}
Conviene registrar la hipótesis o necesidad, la versión donde se observará, la
evidencia recibida y la decisión de aceptar, rechazar o posponer el cambio. También
se mantiene un límite de alcance o tiempo. Así la retroalimentación orienta aprendizaje
en lugar de reemplazar toda planificación.
:::

### 7. Riesgo en espiral

Un equipo enumera riesgos al inicio, pero después ejecuta ciclos idénticos sin volver
a evaluarlos. ¿Qué elemento del modelo espiral está ausente?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 7"}
Falta usar el análisis de riesgos para orientar cada ciclo y decidir el siguiente
compromiso. Una lista decorativa no reduce incertidumbre. El equipo debería elegir
qué riesgo estudiar, obtener evidencia y adaptar planificación o solución según el
resultado.
:::

### 8. Dos proyectos, modelos distintos

Un sistema tiene requisitos legales estables; otro prueba una experiencia nueva con
usuarios. ¿Por qué sería débil recomendar el mismo modelo solo porque ambos son web?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 8"}
La tecnología de interfaz no determina estabilidad, retroalimentación, riesgo ni forma
de entrega. El primer contexto puede favorecer una secuencia más planificada; el
segundo necesita aprendizaje frecuente. Se comparan condiciones del proyecto, no la
etiqueta «web» ni una moda metodológica.
:::

### 9. Elegir con cuatro evidencias

Para una reserva de biblioteca, nombra una evidencia sobre requisitos, otra sobre
entrega, otra sobre retroalimentación y otra sobre riesgo que usarías al elegir modelo.

::: {.callout-note collapse="true" title="Retroalimentación razonada — 9"}
Podrían ser: la regla de no solapamiento está aprobada; una sede necesita consulta en
seis semanas; los filtros se definirán con el piloto; y la migración puede duplicar
horarios. En conjunto favorecen entregas incrementales, puntos de aprendizaje y una
evaluación explícita del riesgo antes de ampliar. Otras evidencias pueden justificar
otra decisión si se explica su relación.
:::

### 10. Revisar una elección

El equipo eligió incremental, pero descubre que ninguna capacidad parcial puede
operar legalmente y todos los requisitos están fijados. ¿Qué debería hacer?

::: {.callout-note collapse="true" title="Retroalimentación razonada — 10"}
Debe revisar la elección en vez de proteger la etiqueta. Si no existe valor ni uso
legal por partes y los requisitos son estables, una secuencia planificada podría ser
más coherente. También puede redefinir qué significa un incremento interno, pero no
debe fingir entregas utilizables. Un modelo es una decisión contextual que cambia
cuando cambian sus supuestos.
:::

## Alcance de la fuente y cierre

Esta Semana 2 desarrolla únicamente el contenido del documento HTML oficial verificado:
actividades generales, flujo, tareas y patrones, y los modelos cascada, incremental,
evolutivo y espiral. El plan de clase y otros archivos PDF quedaron disponibles solo
como metadatos y **no fueron leídos**; por tanto, este material no afirma cubrir todas
las clases, fuentes ni evaluaciones de la semana o del semestre.

La preparación se completa al poder justificar cómo se organiza el trabajo y por qué
un modelo encaja en condiciones concretas. Si una respuesta depende de «siempre» o
«el mejor», vuelve a requisitos, entregas, retroalimentación y riesgos: ahí debe estar
la evidencia de la elección.

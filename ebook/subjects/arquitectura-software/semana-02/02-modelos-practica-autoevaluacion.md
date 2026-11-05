# Modelos de proceso: comparación, práctica y autoevaluación

**Propósito.** Esta lectura compara cascada, incremental, evolutivo y espiral para
estudiar decisiones de proceso. Incluye un caso original de reservas de biblioteca,
una práctica análoga y diez preguntas con retroalimentación razonada. No reproduce
ni resuelve el sistema de pedidos de restaurante ni el Taller 1.2 mencionados en la
fuente oficial [@blackboard-arq-s2].

## Ruta de estudio

1. Compara cada modelo por las condiciones que aprovecha y los problemas que debe
   controlar.
2. Examina las premisas del caso antes de leer la decisión trabajada.
3. Elige el modelo que encaja con requisitos, entregas, retroalimentación y riesgos,
   no con popularidad.
4. Elige una alternativa en cada comprobación y lee su retroalimentación.

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

El municipio tiene reglas aprobadas, una primera capacidad en un mes, incertidumbre
sobre la vista y riesgo de importar duplicados. Elige el enfoque más defendible bajo
esas premisas y lee la retroalimentación.

<!-- quiz: arq-s2-practica-modelo -->

## Autoevaluación formativa

Elige una alternativa antes de leer su retroalimentación. Estas diez preguntas son
originales del cuaderno: no son respuestas de una evaluación, del crucigrama, del
Taller 1.2 ni del caso oficial de restaurante.

### 1. Actividad y tarea

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-actividad-tarea -->

### 2. Flujo que vuelve atrás

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-volver-requisitos -->

### 3. Patrón sin receta

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-patron -->

### 4. Cascada y estabilidad

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-cascada -->

### 5. Incremento funcional

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-incremento -->

### 6. Evolución con control

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-evolucion -->

### 7. Riesgo en espiral

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-espiral -->

### 8. Dos proyectos, modelos distintos

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-contexto -->

### 9. Elegir con cuatro evidencias

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-evidencias -->

### 10. Revisar una elección

Elige una alternativa y lee la retroalimentación.

<!-- quiz: arq-s2-revisar -->

## Alcance de la fuente y cierre

Esta Semana 2 desarrolla únicamente el contenido del documento HTML oficial verificado:
actividades generales, flujo, tareas y patrones, y los modelos cascada, incremental,
evolutivo y espiral. El plan de clase y otros archivos PDF quedaron disponibles solo
como metadatos y **no fueron leídos**; por tanto, este material no afirma cubrir todas
las clases, fuentes ni evaluaciones de la semana o del semestre.

La preparación se completa al relacionar el modelo con condiciones concretas. Si una
alternativa depende de «siempre» o «el mejor», vuelve a requisitos, entregas,
retroalimentación y riesgos: ahí debe estar la evidencia de la elección.

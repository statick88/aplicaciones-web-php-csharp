// Chapter-based numbering for books with appendix support
#let equation-numbering = it => {
  let pattern = if state("appendix-state", none).get() != none { "(A.1)" } else { "(1.1)" }
  numbering(pattern, counter(heading).get().first(), it)
}
#let callout-numbering = it => {
  let pattern = if state("appendix-state", none).get() != none { "A.1" } else { "1.1" }
  numbering(pattern, counter(heading).get().first(), it)
}
#let subfloat-numbering(n-super, subfloat-idx) = {
  let chapter = counter(heading).get().first()
  let pattern = if state("appendix-state", none).get() != none { "A.1a" } else { "1.1a" }
  numbering(pattern, chapter, n-super, subfloat-idx)
}
// Theorem configuration for theorion
// Chapter-based numbering (H1 = chapters)
#let theorem-inherited-levels = 1

// Appendix-aware theorem numbering
#let theorem-numbering(loc) = {
  if state("appendix-state", none).at(loc) != none { "A.1" } else { "1.1" }
}

// Theorem render function
// Note: brand-color is not available at this point in template processing
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  block(
    width: 100%,
    inset: (left: 1em),
    stroke: (left: 2pt + black),
  )[
    #if full-title != "" and full-title != auto and full-title != none {
      strong[#full-title]
      linebreak()
    }
    #body
  ]
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// syntax highlighting functions from skylighting:
/* Function definitions for syntax highlighting generated by skylighting: */
#let EndLine() = raw("\n")
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
   let blocks = []
   let lnum = start - 1
   let bgcolor = rgb("#f1f3f5")
   for ln in sourcelines {
     if number {
       lnum = lnum + 1
       blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
     }
     blocks = blocks + ln + EndLine()
   }
   block(fill: bgcolor, width: 100%, inset: 8pt, radius: 2pt, blocks)
}
#let AlertTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let AnnotationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let AttributeTok(s) = text(fill: rgb("#657422"),raw(s))
#let BaseNTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let BuiltInTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let CharTok(s) = text(fill: rgb("#20794d"),raw(s))
#let CommentTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let CommentVarTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ConstantTok(s) = text(fill: rgb("#8f5902"),raw(s))
#let ControlFlowTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let DataTypeTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DecValTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DocumentationTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ErrorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let ExtensionTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let FloatTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let FunctionTok(s) = text(fill: rgb("#4758ab"),raw(s))
#let ImportTok(s) = text(fill: rgb("#00769e"),raw(s))
#let InformationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let KeywordTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let NormalTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let OperatorTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let OtherTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let PreprocessorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let RegionMarkerTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let SpecialCharTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let SpecialStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let StringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let VariableTok(s) = text(fill: rgb("#111111"),raw(s))
#let VerbatimStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let WarningTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))



#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  // Set document metadata for PDF accessibility
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(lang: lang,
           region: region,
           size: fontsize)
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
   }

  let has-title-block = title != none or (authors != none and authors != ()) or date != none or abstract != none
  if has-title-block {
    place(
      top,
      float: true,
      scope: "parent",
      clearance: 4mm,
      block(below: 1em, width: 100%)[

        #if title != none {
          align(center, block(inset: 2em)[
            #set par(leading: heading-line-height) if heading-line-height != none
            #set text(font: heading-family) if heading-family != none
            #set text(weight: heading-weight)
            #set text(style: heading-style) if heading-style != "normal"
            #set text(fill: heading-color) if heading-color != black

            #text(size: title-size)[#title #if thanks != none {
              footnote(thanks, numbering: "*")
              counter(footnote).update(n => n - 1)
            }]
            #(if subtitle != none {
              parbreak()
              text(size: subtitle-size)[#subtitle]
            })
          ])
        }

        #if authors != none and authors != () {
          let count = authors.len()
          let ncols = calc.min(count, 3)
          grid(
            columns: (1fr,) * ncols,
            row-gutter: 1.5em,
            ..authors.map(author =>
                align(center)[
                  #author.name \
                  #author.affiliation \
                  #author.email
                ]
            )
          )
        }

        #if date != none {
          align(center)[#block(inset: 1em)[
            #date
          ]]
        }

        #if abstract != none {
          block(inset: 2em)[
          #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
          ]
        }
      ]
    )
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  doc
}

#set table(
  inset: 6pt,
  stroke: none
)
// La prosa, la portada y los títulos conservan la tipografía proporcional de Quarto.
// Solo el código usa los TTF Fira incluidos mediante `font-paths`.
#set par(justify: true)
#show raw: set text(font: "FiraCode Nerd Font")
#import "@preview/fontawesome:0.5.0": *
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)
// Logo is handled by orange-book's cover page, not as a page background
// NOTE: marginalia.setup is called in typst-show.typ AFTER book.with()
// to ensure marginalia's margins override the book format's default margins
#import "@preview/orange-book:0.7.1": book, part, chapter, appendices

#show: book.with(
  title: [Cuaderno de estudio y práctica --- Ingeniería de Software],
  subtitle: [Teoría, práctica y preparación para evaluaciones por asignatura y semana],
  author: "Diego Saavedra",
  lang: "es",
  main-color: brand-color.at("primary", default: blue),
  logo: {
    let logo-info = brand-logo.at("medium", default: none)
    if logo-info != none { image(logo-info.path, alt: logo-info.at("alt", default: none)) }
  },
  outline-depth: 3,
  supplement-chapter: "Capítulo",
)


// Reset Quarto's custom figure counters at each chapter (level-1 heading).
// Orange-book only resets kind:image and kind:table, but Quarto uses custom kinds.
// This list is generated dynamically from crossref.categories.
#show heading.where(level: 1): it => {
  counter(figure.where(kind: "quarto-float-fig")).update(0)
  counter(figure.where(kind: "quarto-float-tbl")).update(0)
  counter(figure.where(kind: "quarto-float-lst")).update(0)
  counter(figure.where(kind: "quarto-callout-Note")).update(0)
  counter(figure.where(kind: "quarto-callout-Warning")).update(0)
  counter(figure.where(kind: "quarto-callout-Caution")).update(0)
  counter(figure.where(kind: "quarto-callout-Tip")).update(0)
  counter(figure.where(kind: "quarto-callout-Important")).update(0)
  counter(math.equation).update(0)
  it
}

= Cómo usar este cuaderno
<cómo-usar-este-cuaderno>
Este cuaderno de Ingeniería de Software crece por #strong[asignatura y semana] para preparar evaluaciones mediante teoría, ejemplos resueltos, práctica y autoevaluación. Cada parte declara su cobertura actual: no sustituye la documentación oficial de la asignatura ni registra calificaciones.

== Ruta rápida
<ruta-rápida>
+ Elige la asignatura y la semana que estás cursando en la navegación.
+ Lee el concepto, predice el resultado de un ejemplo y realiza la práctica.
+ Conserva una observación concreta y contrástala con la retroalimentación.

El libro reúne seis asignaturas en un solo volumen y un solo PDF. Cada enlace abre un índice independiente con su propia cobertura y ruta de lectura:

- #link("subjects/aplicaciones-web.qmd")[Aplicaciones Web]
- #link("subjects/arquitectura-software.qmd")[Diseño y Arquitectura de Software]
- #link("subjects/gestion-empresarial-emprendimiento.qmd")[Gestión Empresarial y Emprendimiento]
- #link("subjects/inteligencia-artificial.qmd")[Inteligencia Artificial]
- #link("subjects/inteligencia-negocios.qmd")[Inteligencia de Negocios]
- #link("subjects/proyectos-informaticos.qmd")[Proyectos Informáticos]

Aplicaciones Web y Diseño y Arquitectura de Software reúnen las Semanas 1 y 2 con capítulos de estudio redactados en esta edición. Los demás índices declaran la evidencia disponible sin mezclar respuestas ni adelantar contenido por inferencia.

== Un ciclo de práctica
<un-ciclo-de-práctica>
Repita este ciclo para cada ejercicio. El objetivo no es acertar a la primera, sino hacer visible qué evidencia sostiene una respuesta.

+ #strong[Prediga.] Antes de ejecutar, escriba qué espera que ocurra y por qué.
+ #strong[Explique.] Describa qué dato entra, qué regla se aplica y qué resultado debería salir.
+ #strong[Ejecute.] Pruebe un ejemplo pequeño en el repositorio de práctica o en su entorno local.
+ #strong[Compruebe.] Compare la salida y los errores con su predicción.
+ #strong[Reflexione.] Registre qué cambió entre la hipótesis y la evidencia, y formule el siguiente experimento.

Los avisos desplegables de pista y solución ayudan a dosificar la ayuda: primero intente resolver; después contraste su razonamiento. En HTML pueden contraerse y en PDF permanecen como bloques claramente etiquetados.

== Qué fuentes tienen prioridad
<qué-fuentes-tienen-prioridad>
#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Prioridad], [Uso en este cuaderno],),
  table.hline(),
  [Documentación oficial de la asignatura], [Define los temas y la práctica de cada semana. Puede requerir inicio de sesión en Blackboard.],
  [Documentación técnica primaria], [Aclara el comportamiento de lenguajes, plataformas y herramientas.],
  [Repositorios de práctica verificados], [Ofrecen ejemplos para observar, no requisitos nuevos.],
  [Explicación editorial], [Une las fuentes con lenguaje didáctico original; no reemplaza a las anteriores.],
)
Consulte la #link("references.qmd")[política de fuentes y bibliografía] para las referencias completas y la fecha de consulta. Este texto parafrasea el material del curso; no reproduce exportaciones privadas de Blackboard.

== Autoevaluación formativa
<autoevaluación-formativa>
La autoevaluación es manual. Para cada práctica, conserve una predicción, el comando o acción realizada, la evidencia observada y una explicación breve. Revise después las #link("answers.qmd")[respuestas razonadas], corrija su explicación y decida un paso siguiente. En Arquitectura, las respuestas están junto a la práctica integrada de Semana 1. No hay LMS, puntos, cuentas ni una promesa de dominio automático.

== Alcance de esta edición
<alcance-de-esta-edición>
La cobertura publicada depende del avance real y las fuentes verificadas de cada asignatura. No se añaden temarios futuros por inferencia. En Aplicaciones Web, Docker y Dev Containers aparecen como rutas de ejecución opcionales: el aprendizaje central es PHP, C\# y la web, no una herramienta concreta.

#part[Aplicaciones Web]
Esta asignatura reúne las #strong[Semanas 1 y 2]. Combina teoría, ejemplos resueltos, práctica y autoevaluación para preparar la evaluación a partir de las fuentes oficiales y de observaciones propias; no sustituye la documentación del curso ni registra calificaciones.

#heading(level: 2, numbering: none)[Cobertura actual]
<cobertura-actual>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Semana], [Tema y propósito], [Lectura],),
  table.hline(),
  [1], [Petición, respuesta HTTP y responsabilidades web], [#link("../chapters/01-web-foundations.qmd")[Fundamentos de la web]],
  [1], [Variables, tipos, conversiones y alcance en PHP y C\#], [#link("../chapters/02-variables-types-scope.qmd")[Valores, tipos y alcance]],
  [1], [Repaso práctico con predicciones y evidencia], [#link("../chapters/03-week1-practice-review.qmd")[Práctica y repaso]],
  [1], [Rutas opcionales para ejecutar los ejemplos], [#link("../chapters/04-development-environment.qmd")[Entorno de desarrollo]],
  [2 · Clase 1], [Tipos, conversiones, variables de variables y Cliente CRUD en PHP/C\#], [#link("aplicaciones-web/semana-02/01-tipos-cliente.qmd")[Tipos y Cliente]],
  [2 · Clase 2], [Formularios GET/POST, validación y PRG en PHP/ASP.NET Core], [#link("aplicaciones-web/semana-02/02-formularios-get-post.qmd")[Formularios, GET y POST]],
  [Consulta transversal], [Métodos, datos en DevTools/PHP y estados HTTP], [#link("aplicaciones-web/consulta-http.qmd")[Tablas de consulta HTTP]],
  [Consulta transversal], [Métodos HTTP prácticos observados en DevTools], [#link("aplicaciones-web/laboratorio-http-php.qmd")[Laboratorio PHP]],
)
#heading(level: 2, numbering: none)[Navegación de la Semana 1]
<navegación-de-la-semana-1>
#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Tipo], [Recurso],),
  table.hline(),
  [Teoría], [#link("../chapters/01-web-foundations.qmd")[Fundamentos de la web] y #link("../chapters/02-variables-types-scope.qmd")[Valores, tipos y alcance]],
  [Ejemplos], [Demostraciones ejecutables en el capítulo de valores y #link("aplicaciones-web/laboratorio-http-php.qmd")[Laboratorio PHP]\; rutas opcionales en #link("../chapters/04-development-environment.qmd")[Entorno de desarrollo]],
  [Ejercicios], [#link("../chapters/03-week1-practice-review.qmd")[Práctica y repaso] con predicciones; #link("aplicaciones-web/consulta-http.qmd")[Tablas de consulta HTTP] como referencia durante la práctica],
  [Autoevaluación], [#link(<autoevaluacion-semana1>)[Autoevaluación de Semana 1] y sus #link("../answers.qmd")[respuestas razonadas]],
  [Entregas], [Sitio personal y calculadora publicados en #link("https://github.com/statick88/aplicaciones-web-semana1")[aplicaciones-web-semana1]],
)
#heading(level: 2, numbering: none)[Navegación de la Semana 2]
<navegación-de-la-semana-2>
#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Tipo], [Recurso],),
  table.hline(),
  [Teoría y ejemplos · Clase 1], [#link("aplicaciones-web/semana-02/01-tipos-cliente.qmd")[Tipos, conversiones y Cliente]],
  [Teoría y ejemplos · Clase 2], [#link("aplicaciones-web/semana-02/02-formularios-get-post.qmd")[Formularios, GET y POST]],
  [Ejercicios], [#link(<s2c1-ejercicios>)[Clase 1] y #link(<s2c2-ejercicios>)[Clase 2]],
  [Respuestas razonadas], [#link(<s2c1-respuestas>)[Clase 1] y #link(<s2c2-respuestas>)[Clase 2]],
  [Práctica local], [Demos PHP #NormalTok("semana2-tipos.php"); / #NormalTok("semana2.php"); y MVC #NormalTok("/Semana2/Tipos"); / #NormalTok("/Semana2");\; instrucciones dentro de cada clase],
)
La Semana 2 se basa en los materiales de ambas clases aportados para esta práctica; no declara una nueva entrega oficial ni una evaluación aprobada. PHP y ASP.NET Core se ejecutan localmente: este libro estático explica y enlaza el recorrido de estudio.

#heading(level: 2, numbering: none)[Alcance de las semanas actuales]
<alcance-de-las-semanas-actuales>
El recorrido cubre fundamentos de la web, valores y alcance, y la práctica guiada que los conecta. El entorno de desarrollo es opcional: ayuda a observar los ejemplos, pero no reemplaza el razonamiento sobre la petición, el programa y la respuesta. Las respuestas de Semana 1 están en #link("../answers.qmd")[Respuestas de autoevaluación]\; las de Semana 2 se encuentran al final de cada clase.

#heading(level: 2, numbering: none)[Ciclo de estudio]
<ciclo-de-estudio>
+ #strong[Lee y predice] el resultado antes de ejecutar un ejemplo.
+ #strong[Explica] la entrada, la regla y la salida con tus palabras.
+ #strong[Practica y comprueba] con una observación concreta.
+ #strong[Contrasta] tu razonamiento con la retroalimentación y registra la siguiente duda.

La cobertura se amplía solo cuando la asignatura avance y existan fuentes oficiales verificadas. Esta página delimita las Semanas 1 y 2 disponibles, sin anticipar semanas futuras.

= Clase 1: de una petición a una respuesta
<clase-1-de-una-petición-a-una-respuesta>
#strong[Meta.] Al terminar podrás explicar qué ocurre entre un navegador y una aplicación, y distinguir el lenguaje, la plataforma y las carpetas básicas de un proyecto. No necesitas montar un servidor para leer esta clase: primero sigue el recorrido y luego comprueba tus predicciones con las prácticas de la semana.

#quote(block: true)[
#strong[Ruta de estudio:] predice qué pide el navegador → sigue la respuesta → compara PHP y C\# → nombra la responsabilidad de cada carpeta → comprueba tu explicación.
]

== Una página no siempre es un archivo fijo
<una-página-no-siempre-es-un-archivo-fijo>
Una página #strong[estática] entrega esencialmente el mismo HTML a quienes solicitan la misma URL. Sus archivos pueden vivir en un servidor, pero no requieren ejecutar lógica para fabricar ese contenido. Una página #strong[dinámica] se construye al atender la petición: puede usar parámetros, datos o reglas antes de enviar la respuesta. Dinámico no significa necesariamente complejo ni que deba incluir una base de datos.

Predicción: al escribir una dirección web y pulsar Enter, ¿el navegador recibe PHP o C\#? Normalmente recibe una #strong[respuesta HTTP], cuyo cuerpo puede ser HTML, CSS, JavaScript, una imagen o datos. El código del servidor se ejecuta antes y no se entrega como parte de la página.

Los dos recorridos comparten el mismo ciclo HTTP, pero se muestran por separado para que cada figura permita seguir una sola tecnología.

#figure([
#box(image("chapters/../assets/request-response.svg", alt: "Flujo PHP con tres pasos: petición HTTP del navegador, ejecución del programa PHP en el servidor y respuesta HTML de vuelta al navegador."))
], caption: figure.caption(
position: bottom, 
[
Flujo PHP: 1. petición del navegador; 2. PHP ejecuta el programa en el servidor; 3. una respuesta con cuerpo HTML vuelve al navegador.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


#figure([
#box(image("chapters/../assets/request-response-csharp.svg", alt: "Flujo C# con tres pasos: petición HTTP del navegador, ejecución del programa C# mediante .NET en el servidor y respuesta HTML de vuelta al navegador."))
], caption: figure.caption(
position: bottom, 
[
Flujo C\#: 1. petición del navegador; 2. \.NET ejecuta el programa C\# en el servidor; 3. una respuesta con cuerpo HTML vuelve al navegador.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


== El ciclo mínimo HTTP
<el-ciclo-mínimo-http>
+ El #strong[cliente] (por ejemplo, un navegador) envía una petición: método, ruta, cabeceras y, si corresponde, datos.
+ El #strong[servidor] la recibe y el programa decide qué hacer.
+ La respuesta incluye un código de estado, cabeceras y un cuerpo.
+ El navegador interpreta el HTML recibido y solicita recursos adicionales si los encuentra.

Los estados no son mensajes decorativos. #NormalTok("200 OK"); indica que la respuesta fue atendida; #NormalTok("404 Not Found"); comunica que no se encontró el recurso solicitado; #NormalTok("500 Internal Server Error"); señala un fallo no controlado del lado servidor. Un #NormalTok("200"); no garantiza que el contenido sea útil, y un #NormalTok("404"); no prueba por sí solo que el programa esté roto: expresa el resultado de esta petición.

#block[
#callout(
body: 
[
Las herramientas de desarrollo del navegador permiten ver URL, método, estado y cuerpo de una respuesta. Es una comprobación mejor que deducir el resultado solo por lo que parece mostrar la pantalla.

]
, 
title: 
[
Observa antes de concluir
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== HTML en el cliente; programas en el servidor
<html-en-el-cliente-programas-en-el-servidor>
HTML describe la estructura que el navegador renderiza. CSS presenta esa estructura y JavaScript puede modificarla en el cliente. PHP y C\# pueden generar HTML o datos en el servidor. Esta división ayuda a diagnosticar: si el navegador muestra una etiqueta literalmente, probablemente llegó como texto; si aparece un error de PHP o \.NET, la ejecución ocurrió en el servidor.

No confundas «usar un editor» con «ejecutar una aplicación». Un #strong[editor] escribe y organiza archivos. El #strong[runtime] interpreta o ejecuta el programa. Un #strong[servidor web] recibe HTTP y puede delegar la petición al runtime. En desarrollo pueden estar en el mismo equipo; sus funciones siguen siendo distintas.

#block[
#table(
  columns: 4,
  align: (auto,auto,auto,auto,),
  table.header([Pregunta], [Editor], [Runtime], [Servidor web],),
  table.hline(),
  [¿Escribe #NormalTok("index.php"); o #NormalTok("Program.cs");?], [Sí], [No], [No],
  [¿Ejecuta el lenguaje?], [No], [Sí], [Coordina o delega],
  [¿Acepta una petición HTTP?], [No], [No necesariamente], [Sí],
)
]
== PHP y C\#: comparación inicial
<php-y-c-comparación-inicial>
PHP es un lenguaje usado con frecuencia para generar respuestas web. En el flujo tradicional, el runtime evalúa el archivo PHP que corresponde a la petición. Un acelerador como OPcache puede conservar código compilado en memoria, por lo que no es correcto afirmar que PHP «siempre recompila todo» en cada solicitud @php-manual.

C\# es el #strong[lenguaje] con el que escribimos el programa. \.NET es la #strong[plataforma] que ofrece runtime, bibliotecas y herramientas para compilar y ejecutar ese programa. Al compilar, C\# produce código intermedio (IL); el runtime aplica compilación JIT cuando necesita ejecutar código. Es una comparación de rutas de ejecución, no una escala de calidad: la elección depende del contexto y del proyecto @microsoft-csharp.

Las figuras separan las rutas para que los pasos propios de cada plataforma no se mezclen. La comparación sigue en el texto: ambas producen una respuesta, aunque su preparación y ejecución no son idénticas.

#figure([
#box(image("chapters/../assets/runtime-comparison.svg", alt: "Ruta de ejecución de PHP durante una petición HTTP: el runtime PHP ejecuta la aplicación y OPcache puede conservar código compilado."))
], caption: figure.caption(
position: bottom, 
[
Ruta de ejecución de PHP: durante la petición, el runtime ejecuta la aplicación; OPcache puede conservar código compilado.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


#figure([
#box(image("chapters/../assets/runtime-csharp.svg", alt: "Ruta de ejecución de C# con preparación previa de código fuente a IL y ejecución durante la petición mediante el runtime .NET y JIT."))
], caption: figure.caption(
position: bottom, 
[
Ruta de ejecución de C\#: el proyecto se compila a IL antes de atender peticiones; durante la petición, el runtime \.NET aplica JIT cuando hace falta y ejecuta el código.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


=== Ejemplo mental emparejado
<ejemplo-mental-emparejado>
Supón que una ruta debe saludar a Ada. En PHP el runtime evalúa una instrucción que produce #NormalTok("Hola Ada");\; en C\#, la aplicación compilada ejecuta una instrucción equivalente y produce el mismo texto. En ambos casos el resultado puede insertarse en una respuesta HTTP. Predice cuál parte ve el navegador: ve el texto final, no la variable ni el paso de compilación.

#strong[Por qué importa.] Si cambias HTML, estás cambiando lo que el cliente interpreta. Si cambias PHP o C\#, estás cambiando cómo el servidor construye la respuesta. Para confirmarlo, inspecciona la respuesta en el navegador y observa que no contiene el código de servidor.

== Una historia breve de PHP
<una-historia-breve-de-php>
La evolución importa porque explica por qué encontrarás proyectos con estilos diferentes. PHP 5 consolidó gran parte del modelo orientado a objetos; PHP 7 trajo mejoras importantes de rendimiento y tipos; PHP 8.0 incorporó cambios de lenguaje como atributos y unión de tipos. Las versiones 8.1 a 8.3 continuaron refinando el lenguaje, y PHP 8.4 y 8.5 son versiones posteriores documentadas por el proyecto. Esta clase no es un tutorial de sus novedades: al trabajar en un repositorio, verifica la versión real antes de usar una característica @php85.

La versión activa es una condición técnica, no un detalle de estilo. Una instrucción válida en una versión reciente puede no funcionar en una instalación anterior. Consulta las notas oficiales de PHP 8.5 y el manual para confirmar disponibilidad, en vez de copiar fragmentos aislados @php85@php-manual.

== Carpetas: pistas sobre responsabilidades
<carpetas-pistas-sobre-responsabilidades>
Un punto de partida frecuente separa estas carpetas:

#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Carpeta], [Responsabilidad inicial],),
  table.hline(),
  [#NormalTok("public/");], [Punto expuesto al navegador: archivos públicos y entrada web.],
  [#NormalTok("src/");], [Código de la aplicación que no debería ser una URL directa.],
  [#NormalTok("views/");], [Plantillas o fragmentos destinados a producir la presentación.],
  [#NormalTok("config/");], [Configuración de la aplicación, no secretos publicados.],
)
Esta convención no es una ley del lenguaje ni convierte automáticamente un proyecto en MVC. Es una forma de hacer visible qué archivo está expuesto y dónde buscar una responsabilidad. Nunca publiques contraseñas en #NormalTok("public/"); ni en un repositorio.

PHP ofrece #NormalTok("include"); y #NormalTok("require"); para incorporar archivos. Si falta un archivo, #NormalTok("include"); emite una advertencia y el script puede continuar; #NormalTok("require"); produce un error fatal y detiene la ejecución. Las variantes #NormalTok("include_once"); y #NormalTok("require_once"); se comportan igual, pero solo cargan cada archivo una vez, lo que evita declarar la misma función dos veces. Para configuración o código indispensable, #NormalTok("require"); evita continuar con una aplicación incompleta. Comprueba la ruta y el mensaje; no silencies el problema con operadores de supresión @php-manual.

== MVC: una introducción, no una receta completa
<mvc-una-introducción-no-una-receta-completa>
MVC propone separar responsabilidades: un #strong[modelo] representa datos y reglas, una #strong[vista] presenta información y un #strong[controlador] coordina una petición. ASP.NET Core MVC documenta este patrón para aplicaciones web @aspnet-mvc. En Semana 1 basta con reconocer el propósito de esa separación y no colocar una decisión de interfaz en un lugar arbitrario.

El ejemplo de factura PHP existente en el repositorio es monolítico y #strong[no] es una arquitectura MVC de referencia. La aplicación C\# ya usa una plantilla MVC, pero eso no convierte toda su lógica de negocio en un catálogo de patrones de dominio. No reestructures esas prácticas durante este repaso: observa, nombra responsabilidades y avanza gradualmente.

#block[
#callout(
body: 
[
Patrones de diseño, Clean Architecture y TDD requieren práctica deliberada posterior. Aquí no abrimos capítulos nuevos sobre ellos: usamos solo la idea inicial de separar responsabilidades para leer mejor una aplicación MVC.

]
, 
title: 
[
Límite de Semana 1
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
== Fuentes y trazabilidad
<fuentes-y-trazabilidad>
El temario de Clase 1 es la fuente curricular primaria @blackboard-s1c1. Para confirmar detalles técnicos consulta el #link("https://www.php.net/manual/en/")[manual oficial de PHP], las #link("https://www.php.net/releases/8.5/en.php")[notas de PHP 8.5], la #link("https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/")[referencia de C\#] y la #link("https://learn.microsoft.com/en-us/aspnet/core/mvc/overview?view=aspnetcore-10.0")[introducción oficial a ASP.NET Core MVC]. Consulta: 2026-10-30.

== Autoevaluación manual
<autoevaluación-manual>
+ ¿Qué diferencia práctica hay entre el cuerpo de una respuesta HTTP y el código PHP?
+ ¿Por qué #NormalTok("404"); y #NormalTok("500"); describen situaciones distintas?
+ ¿Qué distingue a C\# de \.NET cuando explicas cómo se ejecuta un programa?
+ ¿Cuándo prefieres #NormalTok("require"); a #NormalTok("include"); y por qué?

#block[
#callout(
body: 
[
+ El navegador recibe el cuerpo de la respuesta; PHP se ejecutó antes en el servidor.
+ #NormalTok("404"); comunica que no se encontró el recurso; #NormalTok("500"); indica un error interno al procesar la solicitud. Ambos se verifican en la respuesta, no solo en la página.
+ C\# es el lenguaje; \.NET aporta runtime y bibliotecas que ejecutan IL mediante JIT.
+ Cuando el archivo es indispensable, porque detenerse revela una aplicación incompleta en vez de continuar con un estado incierto.

]
, 
title: 
[
Retroalimentación razonada
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#strong[Siguiente paso:] en la Clase 2 predice tipos, conversiones y ámbitos antes de confirmarlos con los dos programas de demostración.

= Clase 2: valores, tipos y alcance
<clase-2-valores-tipos-y-alcance>
#strong[Meta.] Declararás valores con intención, anticiparás una conversión y explicarás qué nombre está disponible en cada parte del programa. La meta no es memorizar una lista: es predecir, ejecutar y justificar el resultado en PHP y C\#.

#quote(block: true)[
#strong[Ciclo de estudio:] identifica el valor → predice el tipo y el alcance → compara ambos lenguajes → ejecuta el ejemplo → explica cualquier diferencia.
]

== Un nombre apunta a un valor
<un-nombre-apunta-a-un-valor>
Una variable asocia un nombre con un valor que puede cambiar. El nombre debe describir el dato (#NormalTok("$total");, #NormalTok("nombreCliente");) y respetar las reglas del lenguaje. PHP distingue mayúsculas y minúsculas en los nombres de variables: #NormalTok("$total"); y #NormalTok("$Total"); no son el mismo nombre. C\# también distingue #NormalTok("total"); de #NormalTok("Total");\; por convención suele usar #NormalTok("camelCase"); para variables locales y #NormalTok("PascalCase"); para constantes y miembros.

En PHP una variable empieza con #NormalTok("$");:

#Skylighting(([#VariableTok("$nombre");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("'Ada'");#OtherTok(";");],
[#VariableTok("$activo");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("true");#OtherTok(";");],));
En C\# se declara primero el tipo o se permite que #NormalTok("var"); lo infiera:

#Skylighting(([#DataTypeTok("string");#NormalTok(" nombre ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Ada\"");#OperatorTok(";");],
[#DataTypeTok("bool");#NormalTok(" activo ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("true");#OperatorTok(";");],
[#DataTypeTok("var");#NormalTok(" edad ");#OperatorTok("=");#NormalTok(" ");#DecValTok("20");#OperatorTok(";");],));
#NormalTok("var"); #strong[no] hace dinámico a C\#. El compilador infiere un tipo estático a partir del valor inicial; #NormalTok("edad"); sigue siendo #NormalTok("int"); y no puede recibir luego una cadena. PHP trabaja habitualmente con tipado dinámico: una variable puede contener valores de tipos diferentes en momentos distintos. Esa flexibilidad no elimina la necesidad de leer conversiones y contratos con cuidado @microsoft-csharp@php-manual.

== Tipos escalares y colecciones iniciales
<tipos-escalares-y-colecciones-iniciales>
Empieza por cuatro tipos escalares frecuentes: enteros, números de punto flotante, cadenas y booleanos. PHP también tiene #NormalTok("null");, que expresa ausencia de valor. C\# usa #NormalTok("null"); para referencias anulables; con tipos de valor, #NormalTok("int?"); representa un entero que puede ser nulo. Activa y respeta las advertencias de nulabilidad: no son una garantía absoluta, pero señalan rutas que podrían fallar.

#table(
  columns: 3,
  align: (auto,auto,auto,),
  table.header([Idea], [PHP], [C\#],),
  table.hline(),
  [Entero], [#NormalTok("3");], [#NormalTok("int cantidad = 3;");],
  [Decimal], [#NormalTok("3.5");], [#NormalTok("double precio = 3.5;");],
  [Cadena], [#NormalTok("'Ada'"); o #NormalTok("\"Ada\"");], [#NormalTok("string nombre = \"Ada\";");],
  [Booleano], [#NormalTok("true");], [#NormalTok("bool activo = true;");],
  [Ausencia], [#NormalTok("null");], [#NormalTok("string? apodo = null;");],
)
Un array de PHP puede actuar como lista o como mapa de claves. En C\# conviene nombrar la colección por su intención; para comenzar, un arreglo como #NormalTok("string[] nombres = [\"Ada\", \"Lin\"];"); almacena elementos del mismo tipo. No conviertas esta introducción en una taxonomía de colecciones: primero reconoce qué datos contiene cada ejemplo.

== Comillas e interpolación
<comillas-e-interpolación>
En PHP las comillas simples preservan el texto: #NormalTok("'Hola $nombre'"); no reemplaza la variable. Las dobles permiten interpolación: #NormalTok("\"Hola {$nombre}\"");. Las llaves aclaran el límite del nombre y evitan ambigüedades al rodearlo de texto.

C\# usa comillas dobles para #NormalTok("string"); y antepone #NormalTok("$"); para interpolar:

#Skylighting(([#DataTypeTok("string");#NormalTok(" nombre ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Ada\"");#OperatorTok(";");],
[#DataTypeTok("string");#NormalTok(" saludo ");#OperatorTok("=");#NormalTok(" $");#StringTok("\"Hola {nombre}\"");#OperatorTok(";");],));
Predice el resultado de los dos fragmentos antes de ejecutarlos. En PHP, una comilla simple muestra #NormalTok("$nombre"); literalmente; en C\#, sin el prefijo #NormalTok("$");, #NormalTok("{nombre}"); también es texto ordinario. La interpolación mejora legibilidad cuando es sencilla; no sustituye validar ni codificar datos según el contexto donde se usarán.

== Constantes: lo que no debe cambiar
<constantes-lo-que-no-debe-cambiar>
Una constante comunica que un valor no cambia durante el programa. En PHP, #NormalTok("const"); se declara como parte del código y #NormalTok("define()"); crea una constante en tiempo de ejecución. Para una constante conocida y simple, prefiere #NormalTok("const"); por claridad:

#Skylighting(([#KeywordTok("const");#NormalTok(" ");#ConstantTok("CURSO");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("'PHP-CSharp'");#OtherTok(";");],
[#FunctionTok("define");#NormalTok("(");#StringTok("'ETIQUETA'");#OtherTok(",");#NormalTok(" ");#StringTok("'Semana 1'");#NormalTok(")");#OtherTok(";");],));
En C\#, #NormalTok("const"); requiere un valor de compilación. #NormalTok("readonly"); es diferente: se aplica a un #strong[campo de un tipo], no a una variable local. Un campo de instancia #NormalTok("readonly"); puede asignarse en su declaración o en el constructor de instancia; un campo #NormalTok("static readonly");, en su declaración o en el constructor estático. Por tanto, #NormalTok("readonly"); #strong[no] equivale a una constante de tiempo de compilación.

Este fragmento declara los campos dentro de una clase; no son instrucciones sueltas para pegar dentro de un método:

#Skylighting(([#KeywordTok("public");#NormalTok(" ");#KeywordTok("static");#NormalTok(" ");#KeywordTok("class");#NormalTok(" Configuracion");],
[#OperatorTok("{");],
[#NormalTok("    ");#KeywordTok("public");#NormalTok(" ");#DataTypeTok("const");#NormalTok(" ");#DataTypeTok("string");#NormalTok(" Curso ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"PHP-CSharp\"");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("public");#NormalTok(" ");#KeywordTok("static");#NormalTok(" ");#KeywordTok("readonly");#NormalTok(" System");#OperatorTok(".");#FunctionTok("DateTime");#NormalTok(" Inicio ");#OperatorTok("=");#NormalTok(" System");#OperatorTok(".");#FunctionTok("DateTime");#OperatorTok(".");#FunctionTok("UtcNow");#OperatorTok(";");],
[#OperatorTok("}");],));
El valor de #NormalTok("Inicio"); se fija al inicializar el tipo, no al compilar. Desde otro punto del programa puedes leer #NormalTok("Configuracion.Curso"); y #NormalTok("Configuracion.Inicio");. Usa #NormalTok("const"); cuando el valor pertenece literalmente al código y #NormalTok("readonly"); cuando se fija al construir el objeto o inicializar el tipo. La diferencia afecta dónde y cuándo puede asignarse el valor @microsoft-csharp.

== Conversión: predice antes de sumar
<conversión-predice-antes-de-sumar>
Una conversión implícita ocurre cuando el lenguaje puede usar un valor como otro tipo sin sintaxis adicional; una explícita declara la intención. En C\#, convertir #NormalTok("double"); a #NormalTok("int"); exige una conversión explícita porque puede perder decimales:

#Skylighting(([#DataTypeTok("double");#NormalTok(" precio ");#OperatorTok("=");#NormalTok(" ");#FloatTok("3.9");#OperatorTok(";");],
[#DataTypeTok("int");#NormalTok(" truncado ");#OperatorTok("=");#NormalTok(" ");#OperatorTok("(");#DataTypeTok("int");#OperatorTok(")");#NormalTok("precio");#OperatorTok(";");#NormalTok(" ");#CommentTok("// 3");],));
En PHP también puedes convertir explícitamente, por ejemplo #NormalTok("(int) '3'");. Antes de hacerlo, pregúntate si el texto realmente representa un número y valida la entrada externa. Convertir no es corregir datos desconocidos.

=== Ejemplo emparejado: texto y número
<ejemplo-emparejado-texto-y-número>
#strong[Predice.] ¿Qué sale al combinar la cadena numérica #NormalTok("'3'"); con el número #NormalTok("3");?

#Skylighting(([#VariableTok("$resultado");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("'3'");#NormalTok(" ");#OperatorTok("+");#NormalTok(" ");#DecValTok("3");#OtherTok(";");],
[#CommentTok("// $resultado es 6");],));
PHP convierte esta cadena numérica para la operación aritmética y obtiene #NormalTok("6");. En C\#, #NormalTok("+"); con una cadena realiza concatenación:

#Skylighting(([#DataTypeTok("string");#NormalTok(" resultado ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"3\"");#NormalTok(" ");#OperatorTok("+");#NormalTok(" ");#DecValTok("3");#OperatorTok(";");],
[#CommentTok("// resultado es \"33\"");],));
#strong[Por qué.] Los operadores se interpretan junto con los tipos de sus operandos. No copies una expresión de un lenguaje al otro suponiendo igual significado. La cadena #NormalTok("'3a'"); empieza con un número, pero no es una cadena numérica válida completa: en PHP 8, #NormalTok("'3a' + 3"); produce #NormalTok("6"); y una advertencia #NormalTok("E_WARNING");. Que se obtenga un resultado no significa que la entrada sea válida; no dependas de esta conversión. Valida y convierte de forma explícita antes de calcular @php-manual.

#strong[Comprobación de error.] Si esperabas #NormalTok("6"); en C\#, convierte el texto validado a un número antes de sumar. Si recibes texto externo en PHP, verifica su formato antes de aplicar #NormalTok("+");\; no ocultes advertencias para forzar un resultado.

== Alcance: dónde existe un nombre
<alcance-dónde-existe-un-nombre>
El alcance responde «¿en qué parte del código puedo usar este nombre?». Una variable local existe dentro de la función o método que la declara. Los parámetros son una forma explícita de entregar valores a esa función; por eso son preferibles a depender de variables globales.

Las reglas se comparan en el texto, mientras cada figura representa un solo lenguaje.

#figure([
#box(image("chapters/../assets/scope.svg", alt: "Alcance en PHP con una variable exterior y una función que recibe esa dependencia mediante un parámetro explícito."))
], caption: figure.caption(
position: bottom, 
[
Alcance en PHP: una función recibe su dependencia como parámetro explícito dentro de su ámbito local.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


#figure([
#box(image("chapters/../assets/scope-csharp.svg", alt: "Alcance en C# con una variable exterior, una variable local al bloque y un parámetro local al método."))
], caption: figure.caption(
position: bottom, 
[
Alcance en C\#: se distinguen los contextos exterior, de bloque y del parámetro local al método.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


#emph[Un nombre es visible solo dentro de su ámbito; pasar un parámetro deja la dependencia a la vista.]

PHP no crea un nuevo ámbito de variable solo por usar llaves de un #NormalTok("if"); o bloque. C\# sí delimita variables declaradas dentro de un bloque. Compara estas dos intenciones:

#Skylighting(([#VariableTok("$exterior");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#DecValTok("10");#OtherTok(";");],
[#NormalTok("{");],
[#NormalTok("    ");#VariableTok("$enBloque");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#DecValTok("7");#OtherTok(";");],
[#NormalTok("}");],
[#KeywordTok("echo");#NormalTok(" ");#VariableTok("$enBloque");#OtherTok(";");#NormalTok(" ");#CommentTok("// visible: PHP no crea ámbito de bloque");],));
#Skylighting(([#DataTypeTok("int");#NormalTok(" exterior ");#OperatorTok("=");#NormalTok(" ");#DecValTok("10");#OperatorTok(";");],
[#OperatorTok("{");],
[#NormalTok("    ");#DataTypeTok("int");#NormalTok(" enBloque ");#OperatorTok("=");#NormalTok(" ");#DecValTok("7");#OperatorTok(";");],
[#OperatorTok("}");],
[#CommentTok("// Console.WriteLine(enBloque); // error: ya salió del bloque");],));
No pruebes el error de C\# descomentándolo en la demostración ejecutable: se conserva compilable para que puedas verificar sus resultados. El contraste se explica mejor cuando primero predices y luego reconoces que el compilador evita ese acceso.

En PHP, una función no toma una variable global automáticamente. #NormalTok("global $exterior;"); la hace accesible, pero oculta una dependencia. Es más claro recibir #NormalTok("$exterior"); como parámetro. En C\#, evita el estado global mutable por la misma razón: los parámetros y retornos muestran qué necesita y qué produce una operación.

=== Variable #NormalTok("static"); en PHP
<variable-static-en-php>
Una variable local #NormalTok("static"); conserva su valor entre llamadas a la #strong[misma función durante la petición actual]. No es una memoria compartida y no debe describirse como un contador entre solicitudes HTTP. Cada petición puede iniciar un proceso o contexto distinto; para datos entre peticiones se necesita un mecanismo explícito que no forma parte de esta clase.

C\# también puede tener campos #NormalTok("static"); asociados al tipo. El ejemplo usa uno para mostrar dos llamadas consecutivas en el mismo proceso de consola, no para prometer persistencia entre reinicios ni entre usuarios web.

== Ejecuta y contrasta las demostraciones
<ejecuta-y-contrasta-las-demostraciones>
Estos programas pequeños ilustran constantes, alcance y la diferencia de #NormalTok("+");. No son una práctica web MVC ni reemplazan la práctica de HTML/CSS/PHP de Semana 1.

Desde la raíz del repositorio, ejecuta PHP:

#Skylighting(([#ExtensionTok("php");#NormalTok(" ebook/examples/week1/php/variables.php");],));
Salida esperada, sin advertencias:

#Skylighting(([#NormalTok("CONST|curso=PHP-CSharp|etiqueta=Semana 1");],
[#NormalTok("SCOPE|bloque=7|exterior=10|static=1,2");],
[#NormalTok("STRING|interpolacion=Hola Ada|suma=6");],));
Para C\# se usa el proyecto de consola \.NET 10. Desde una copia nueva del repositorio, construye primero la imagen pública definida en #NormalTok("csharp/Dockerfile");:

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml build app");],));
Este paso crea #NormalTok("csharp-app:latest"); con el nombre de proyecto predeterminado de Compose. Solo construye la imagen: no inicia la aplicación ni SQL Server. Requiere conexión para descargar la imagen base y sus herramientas. Con esa imagen ya disponible, el comando aislado es:

#Skylighting(([#ExtensionTok("docker");#NormalTok(" run ");#AttributeTok("--rm");#NormalTok(" ");#AttributeTok("--network");#NormalTok(" none ");#AttributeTok("--entrypoint");#NormalTok(" sh ");#AttributeTok("-v");#NormalTok(" ");#StringTok("\"");#VariableTok("$PWD");#StringTok("/ebook/examples/week1/csharp:/source:ro\"");#NormalTok(" csharp-app:latest ");#AttributeTok("-c");#NormalTok(" ");#StringTok("'mkdir /work && cp -a /source/. /work/ && cd /work && dotnet run --project Week1.csproj --configuration Release --no-launch-profile'");],));
Su salida esperada es deliberadamente igual salvo la concatenación:

#Skylighting(([#NormalTok("CONST|curso=PHP-CSharp|etiqueta=Semana 1");],
[#NormalTok("SCOPE|bloque=7|exterior=10|static=1,2");],
[#NormalTok("STRING|interpolacion=Hola Ada|suma=33");],));
Las aserciones internas detienen el programa si cambian estos contratos. Si una salida difiere, revisa primero comillas, tipo y ámbito; no atribuyas la diferencia a MVC ni a una petición HTTP porque estos son programas de consola.

== Fuentes y límites
<fuentes-y-límites>
El contenido curricular proviene de Clase 2 @blackboard-s1c2. Para detalles de lenguaje consulta el #link("https://www.php.net/manual/en/")[manual oficial de PHP] y la #link("https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/")[referencia oficial de C\#]. Consulta: 2026-10-30. Temas como patrones, Clean Architecture y TDD se retomarán solo cuando una semana posterior los requiera; aquí la prioridad es dominar valores y alcance observables.

== Autoevaluación manual
<autoevaluación-manual-1>
+ ¿Por qué #NormalTok("var"); no transforma una variable de C\# en dinámica?
+ Predice #NormalTok("\"Hola $nombre\""); y #NormalTok("'Hola $nombre'"); en PHP cuando #NormalTok("$nombre"); vale #NormalTok("Ada");.
+ ¿Qué resultado producen #NormalTok("'3' + 3"); en PHP y #NormalTok("\"3\" + 3"); en C\#? Explica la causa.
+ ¿Qué diferencia a #NormalTok("readonly"); de #NormalTok("const"); en C\#?
+ ¿Por qué un parámetro suele ser preferible a leer una variable global?

#block[
#callout(
body: 
[
- #strong[Pista 1:] separa «cómo se infiere el tipo» de «cuándo puede cambiar».
- #strong[Pista 2:] mira primero qué comillas habilitan sustitución en PHP.
- #strong[Pista 3:] observa si #NormalTok("+"); recibe dos números o una cadena.

#NormalTok("var"); infiere un tipo estático en la compilación. Las dobles de PHP producen #NormalTok("Hola Ada");\; las simples dejan el nombre literal. PHP suma la cadena numérica y obtiene #NormalTok("6");\; C\# concatena y obtiene #NormalTok("33");. #NormalTok("readonly"); puede asignarse al inicializar o construir, mientras que #NormalTok("const"); debe conocerse en compilación. Un parámetro declara la entrada de la operación y reduce dependencias ocultas.

]
, 
title: 
[
Pistas progresivas y retroalimentación razonada
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#strong[Siguiente paso:] usa estas predicciones al revisar la práctica de Semana 1 y anota qué resultado observaste antes de consultar una solución.

= Práctica y repaso de la Semana 1
<practica-semana1>
Esta práctica no añade una aplicación nueva: organiza lo que ya se estudió para que puedas explicar una decisión antes de escribirla. El objetivo compartido es leer una necesidad pequeña, reconocer sus entradas y resultados, y contrastar cómo PHP y C\# expresan la misma idea. PHP y C\# no son tareas distintas aquí.

== Punto de partida verificable
<punto-de-partida-verificable>
La entrega personal existente es el sitio HTML/CSS con una calculadora PHP del commit #link("https://github.com/statick88/aplicaciones-web-semana1/commit/ff3d1d757b0799bdad2b2a8f4813f3023f3f49ca")[#NormalTok("ff3d1d7");]. No la copies ni la sustituyas: úsala como evidencia previa para observar las cuatro operaciones. El repositorio de práctica actual tiene ejemplos de variables en PHP y C\# en el commit #link("https://github.com/statick88/aplicaciones-web-php-csharp/commit/406f4c02b3803f4ec444559239a8d93c724773c8")[#NormalTok("406f4c0");]. Son material de comparación, no una afirmación de que ya existe una calculadora C\# equivalente.

La consigna de la primera semana pide una página personal HTML/CSS y una calculadora PHP integrada y publicada en control de versiones @blackboard-task1. Esa es una cita breve del requisito; no se reproduce el material docente.

== Un ciclo para resolver, no para adivinar
<un-ciclo-para-resolver-no-para-adivinar>
Aplica esta secuencia en cada caso. Es útil tanto en el editor como al leer un programa ajeno.

+ #strong[Planifica.] Escribe una frase de propósito: "calcular un resultado a partir de dos números y una operación".
+ #strong[Predice.] Antes de ejecutar, anota qué valor y qué tipo esperas ver.
+ #strong[Separa.] Identifica entrada, procesamiento y salida.
+ #strong[Ejecuta.] Corre solo el ejemplo o la entrega que estás revisando.
+ #strong[Comprueba.] Contrasta el resultado observado con tu predicción.
+ #strong[Explica.] Si no coincide, describe qué dato, operador o conversión puede justificar la diferencia antes de modificar código.

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Parte], [Pregunta guía], [Ejemplo de calculadora],),
  table.hline(),
  [Entrada], [¿Qué llega al programa?], [dos cantidades y la operación elegida],
  [Procesamiento], [¿Qué regla transforma los datos?], [#NormalTok("+");, #NormalTok("-");, #NormalTok("*"); o #NormalTok("/");],
  [Salida], [¿Qué debe poder observarse?], [resultado o aviso de caso no calculable],
)
Este esquema no reemplaza el razonamiento sobre HTTP: en una página dinámica, una solicitud llega al servidor y este construye una respuesta. La página estática no necesita calcular con datos de la solicitud; la dinámica sí puede hacerlo @blackboard-task1.

== Recorrido manual de la entrega existente
<recorrido-manual-de-la-entrega-existente>
Abre la entrega personal y conserva una pequeña tabla de observación. No des por hecho que "se ve bien" equivale a que cada operación fue revisada.

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Caso declarado], [Predicción que anotas], [Qué comprobar],),
  table.hline(),
  [#NormalTok("8 + 2");], [#NormalTok("10");], [que la suma no concatene texto],
  [#NormalTok("8 - 2");], [#NormalTok("6");], [que se aplique la resta],
  [#NormalTok("8 * 2");], [#NormalTok("16");], [que se aplique la multiplicación],
  [#NormalTok("8 / 2");], [#NormalTok("4");], [que el cociente sea el esperado],
  [divisor #NormalTok("0");], [no hay división válida], [que el caso sea distinguible y explicable],
  [entrada no numérica], [no hay cálculo aritmético fiable], [qué muestra la entrega y por qué],
)
Los dos últimos casos son #strong[observaciones de la práctica declarada], no un encargo para construir ahora un marco completo de validación. Si un resultado difiere, registra entrada exacta, salida exacta y el paso de procesamiento que investigarías. Esa nota vale más que ocultar el caso con una corrección rápida.

#block[
#callout(
body: 
[
Primero formula el algoritmo en lenguaje cotidiano. Después mira cómo cada lenguaje declara sus variables y muestra el resultado. Así evitas confundir la sintaxis con el problema que se desea resolver.

]
, 
title: 
[
Consejo de comparación
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
== Misma intención, dos lecturas
<misma-intención-dos-lecturas>
En PHP una variable comienza con #NormalTok("$");\; en C\# su declaración comunica un tipo explícito o permite inferirlo con #NormalTok("var"); cuando el valor inicial lo hace claro. Ambos lenguajes permiten componer texto con valores, pero sus reglas concretas no son intercambiables. Consulta las referencias del lenguaje antes de inferir una conversión @php-manual@microsoft-csharp.

#Skylighting(([#KeywordTok("<?php");],
[#VariableTok("$nombre");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Ana\"");#OtherTok(";");],
[#VariableTok("$intentos");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#DecValTok("2");#OtherTok(";");],
[#KeywordTok("echo");#NormalTok(" ");#StringTok("\"");#VariableTok("$nombre");#StringTok(" tiene ");#VariableTok("$intentos");#StringTok(" intentos.\"");#OtherTok(";");],));
#Skylighting(([#DataTypeTok("string");#NormalTok(" nombre ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Ana\"");#OperatorTok(";");],
[#DataTypeTok("int");#NormalTok(" intentos ");#OperatorTok("=");#NormalTok(" ");#DecValTok("2");#OperatorTok(";");],
[#NormalTok("Console");#OperatorTok(".");#FunctionTok("WriteLine");#OperatorTok("(");#NormalTok("$");#StringTok("\"{nombre} tiene {intentos} intentos.\"");#OperatorTok(");");],));
Predice primero: ambos fragmentos comunican que Ana tiene 2 intentos. Luego identifica lo que cambia: #NormalTok("$"); introduce la variable en PHP, mientras que en C\# el #NormalTok("$"); pertenece a la cadena interpolada. El ejemplo ilustra variables y salida; no prueba por sí solo una aplicación web completa.

== Alcance y constantes: una decisión pequeña
<alcance-y-constantes-una-decisión-pequeña>
Una constante representa un valor que no debe reasignarse durante el programa. Una variable representa un dato que puede cambiar según el problema. El alcance indica dónde un nombre es visible. Cuando una función necesita un dato, pasarle un parámetro hace visible esa dependencia en la llamada; no es necesario usar un estado global para este ejercicio.

#Skylighting(([#KeywordTok("<?php");],
[#KeywordTok("const");#NormalTok(" ");#ConstantTok("TASA");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#FloatTok("0.19");#OtherTok(";");],
[#KeywordTok("function");#NormalTok(" precioConImpuesto(");#DataTypeTok("float");#NormalTok(" ");#VariableTok("$base");#NormalTok(")");#OtherTok(":");#NormalTok(" ");#DataTypeTok("float");#NormalTok(" {");],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" ");#VariableTok("$base");#NormalTok(" ");#OperatorTok("*");#NormalTok(" (");#DecValTok("1");#NormalTok(" ");#OperatorTok("+");#NormalTok(" ");#ConstantTok("TASA");#NormalTok(")");#OtherTok(";");],
[#NormalTok("}");],));
#Skylighting(([#DataTypeTok("const");#NormalTok(" ");#DataTypeTok("decimal");#NormalTok(" Tasa ");#OperatorTok("=");#NormalTok(" ");#FloatTok("0.19m");#OperatorTok(";");],
[#KeywordTok("static");#NormalTok(" ");#DataTypeTok("decimal");#NormalTok(" ");#FunctionTok("PrecioConImpuesto");#OperatorTok("(");#DataTypeTok("decimal");#NormalTok(" baseImponible");#OperatorTok(")");],
[#OperatorTok("{");],
[#NormalTok("    ");#KeywordTok("return");#NormalTok(" baseImponible ");#OperatorTok("*");#NormalTok(" ");#OperatorTok("(");#DecValTok("1");#NormalTok(" ");#OperatorTok("+");#NormalTok(" Tasa");#OperatorTok(");");],
[#OperatorTok("}");],));
No memorices estos fragmentos como plantilla universal. Señala en ambos la entrada (#NormalTok("$base");/#NormalTok("baseImponible");), el procesamiento (multiplicar) y la salida (el valor retornado). En PHP, #NormalTok("const"); y #NormalTok("define"); tienen reglas de uso distintas; en C\#, #NormalTok("const"); declara una constante de compilación. Revísalas en la referencia oficial antes de generalizar @php-manual@microsoft-csharp.

== Organización de prácticas web
<organización-de-prácticas-web>
MVC es el patrón de organización adoptado para las prácticas web: separa la representación, el manejo de solicitudes y los datos del dominio para que sea más fácil localizar responsabilidades @aspnet-mvc. No convierte retroactivamente todo archivo en MVC. En particular, el #NormalTok("php/public/home.php"); actual de las facturas es monolítico; este ebook no lo refactoriza y las facturas/persistencia no son requisitos oficiales comprobados de Semana 1 @practice-repo.

== Autoevaluación manual
<autoevaluacion-semana1>
Responde en una libreta antes de abrir las soluciones. Los enlaces estables llevan a respuestas razonadas, no a una calificación ni a una prueba segura.

+ ​<p1>#link(<p1-respuesta>)[P1: historia y propósito] ¿Qué problema ayuda a resolver una página dinámica frente a una estática y qué aspecto de la evolución de PHP revisarías en una fuente oficial?
+ ​<p2>#link(<p2-respuesta>)[P2: HTTP] En una calculadora web, distingue solicitud, procesamiento en servidor y respuesta con tus propias palabras.
+ ​<p3>#link(<p3-respuesta>)[P3: tipos] Predice qué intención expresa #NormalTok("\"8\" + \"2\""); en PHP y por qué debes verificarlo en vez de asumir que equivale a la suma C\# #NormalTok("8 + 2");.
+ ​<p4>#link(<p4-respuesta>)[P4: interpolación] Predice la salida de los dos ejemplos de Ana y nombra una diferencia sintáctica.
+ ​<p5>#link(<p5-respuesta>)[P5: constantes] ¿Cuándo elegirías una constante en vez de una variable? Da un ejemplo de cada una.
+ ​<p6>#link(<p6-respuesta>)[P6: alcance] Explica por qué un parámetro hace más visible la dependencia de una función que recurrir a #NormalTok("global");.
+ ​<p7>#link(<p7-respuesta>)[P7: depuración] Si #NormalTok("8 / 0"); no produce un resultado numérico útil, ¿qué tres observaciones registrarías antes de tocar el código?
+ ​<p8>#link(<p8-respuesta>)[P8: comprobación] Diseña una tabla mínima para verificar las cuatro operaciones, cero y entrada no numérica.
+ ​<p9>#link(<p9-respuesta>)[P9: MVC] ¿Qué afirma y qué no afirma decir que MVC es el patrón adoptado, dado el #NormalTok("home.php"); PHP actual?
+ ​<p10>#link(<p10-respuesta>)[P10: transferencia] Para convertir temperaturas, identifica entrada, procesamiento y salida; después escribe una predicción de prueba para PHP y otra para C\#.

== Criterios de autoevaluación
<criterios-de-autoevaluación>
#strong[Estos son criterios de autoevaluación, no rúbrica docente.] Marca cada punto solo si puedes mostrar tu predicción y una observación.

#table(
  columns: 3,
  align: (auto,right,right,),
  table.header([Evidencia personal], [Aún no], [Sí, con nota concreta],),
  table.hline(),
  [Distinguí entrada, procesamiento y salida en un caso], [☐], [☐],
  [Revisé las cuatro operaciones y el divisor cero], [☐], [☐],
  [Registré qué ocurrió con una entrada no numérica], [☐], [☐],
  [Expliqué una diferencia PHP/C\# sin inventar paridad], [☐], [☐],
  [Justifiqué una constante, un tipo y un parámetro], [☐], [☐],
)
Una pista o una respuesta te ayuda a comparar tu razonamiento; no demuestra que hayas realizado la práctica. Conserva tus notas y vuelve al ejemplo cuando una predicción falle.

== Siguiente paso
<siguiente-paso>
Lee las respuestas razonadas en #link("../answers.qmd")[Respuestas de autoevaluación] y, si deseas ejecutar los ejemplos sin cambiar el objetivo de aprendizaje, continúa con #link("04-development-environment.qmd")[Entorno de desarrollo].

= Entorno de desarrollo opcional
<entorno-desarrollo>
El objetivo sigue siendo aprender PHP y C\#, no dominar una herramienta de contenedores. Elige una de las dos rutas de esta página y aplica las mismas comprobaciones de los capítulos #strong[Fundamentos web] y #strong[Variables, tipos y alcance]. Docker Compose y Dev Containers son alternativas de ejecución, no contenidos que debas aprobar para comprender la Semana 1.

#block[
#callout(
body: 
[
En Linux se verificaron los ejemplos de lenguaje y la ruta de ejecución con Docker Compose. No se ejecutaron estas comprobaciones en Windows ni macOS, ni se probó la integración real de VS Code con Dev Containers. Los archivos bajo #NormalTok("ebook/examples/devcontainers/"); son ejemplos para #strong[copiar]\; no son configuraciones activas y no funcionan ejecutándolos desde esa carpeta.

]
, 
title: 
[
Antes de empezar
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
== Qué vas a preparar
<qué-vas-a-preparar>
Prepararás #strong[dos escenarios alternativos], cada uno con dos contenedores: uno para la aplicación y otro para su base de datos. No necesitas instalar PHP, \.NET, MariaDB ni SQL Server directamente en tu computadora para esta ruta.

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Escenario], [Servicio #NormalTok("app");], [Servicio #NormalTok("db");],),
  table.hline(),
  [PHP + MariaDB], [Apache, PHP y las extensiones #NormalTok("pdo_mysql"); y #NormalTok("mysqli");], [MariaDB],
  [\.NET + SQL Server], [Aplicación ASP.NET Core MVC con #NormalTok("dotnet watch");], [SQL Server],
)
Una #strong[imagen] contiene el entorno de ejecución; un #strong[contenedor] lo ejecuta. Un #strong[volumen] conserva los archivos de la base de datos aunque detengas el contenedor. #strong[Compose] describe los servicios y crea la red que los conecta. Los archivos #NormalTok("php/compose.yaml");, #NormalTok("csharp/compose.yaml"); y sus respectivos #NormalTok("Dockerfile"); ya existen: no debes crear otro proyecto para seguir esta práctica.

#block[
#callout(
body: 
[
Ambas aplicaciones usan #NormalTok("127.0.0.1:8080");: inicia #strong[una por vez]. Los puertos de las bases también se publican solo en loopback. La práctica \.NET utiliza #NormalTok("sa"); y #NormalTok("TrustServerCertificate=True");\; estas decisiones de desarrollo no deben copiarse como configuración de seguridad de una aplicación en producción.

]
, 
title: 
[
Entorno local, no receta de producción
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
== Elegir una ruta
<elegir-una-ruta>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Ruta], [Úsala cuando], [Idea principal],),
  table.hline(),
  [A. VS Code + terminal Compose], [quieres editar en tu host y controlar el stack desde una terminal], [VS Code es el editor; Compose crea los servicios],
  [B. Dev Containers], [ya tienes un contenedor en ejecución o quieres abrir una copia de configuración], [VS Code abre el estándar Dev Container; Docker sigue siendo tecnología separada],
)
Dev Containers es una especificación abierta con integración en VS Code; Docker no es un producto de Microsoft @devcontainers@vscode-containers. En ambos casos, la aplicación #NormalTok("app"); es la que montará el código y el navegador, si se usa, verá la dirección local indicada por Compose.

== Compatibilidad del host
<compatibilidad-del-host>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Host], [Ruta de Docker documentada], [Nota de arquitectura],),
  table.hline(),
  [Windows], [WSL2 con Docker Desktop], [Intel/AMD y Apple Silicon no aplican igual; consulta los requisitos de Desktop antes de instalar @docker-docs],
  [Linux], [Docker Engine; Docker Desktop no es requisito], [la verificación actual fue aquí],
  [macOS], [Docker Desktop es el flujo documentado; Colima es una alternativa de compatibilidad no validada aquí], [distingue Intel/AMD de Apple Silicon antes de elegir la práctica C\# con base de datos],
)
No ejecutes #NormalTok("sudo");, cambios de grupo, instalaciones globales ni cambios de seguridad del host desde esta guía. Sigue la documentación oficial de tu plataforma para preparar Docker @docker-docs. Que un host pueda ejecutar un contenedor simple no prueba que toda la práctica, y especialmente la base de datos, sea compatible.

== Límite importante de SQL Server
<límite-importante-de-sql-server>
La práctica C\# usa SQL Server como servicio #NormalTok("db");. La documentación primaria de SQL Server en contenedores Linux indica soporte para Linux x86-64 (Intel/AMD). La emulación QEMU o Rosetta no está probada ni soportada @sqlserver-containers. Por ello no se promete que el stack C\# con SQL Server funcione de manera nativa en Apple Silicon, ni se reemplaza silenciosamente por otra base de datos.

Los ejemplos de lenguaje que no dependen de la base de datos pueden ejecutarse con imágenes multi-arquitectura de PHP o del SDK \.NET cuando estén disponibles. Otra opción es un SQL Server x64 remoto, pero exige configurar explícitamente la conexión: no viene configurado por este repositorio. Esta limitación no cambia las comparaciones de variables, tipos, constantes o alcance.

== Ruta A: VS Code y terminal Compose
<ruta-a-vs-code-y-terminal-compose>
Esta ruta no requiere una ventana especial de VS Code. Ejecuta los comandos siguientes desde la #strong[raíz del repositorio], no desde #NormalTok("php/public"); ni #NormalTok("csharp/src");.

=== Preparación común
<preparación-común>
#strong[\1. Abre el proyecto.] Si todavía no tienes una copia, puedes obtenerla así:

#Skylighting(([#FunctionTok("git");#NormalTok(" clone https://github.com/statick88/aplicaciones-web-php-csharp.git");],
[#BuiltInTok("cd");#NormalTok(" aplicaciones-web-php-csharp");],));
Si ya tienes una copia, abre su carpeta: no vuelvas a clonarla. En la raíz deben estar las carpetas #NormalTok("php/");, #NormalTok("csharp/"); y #NormalTok("ebook/");.

#strong[\2. Comprueba Docker y Compose.]

#Skylighting(([#ExtensionTok("docker");#NormalTok(" ");#AttributeTok("--version");],
[#ExtensionTok("docker");#NormalTok(" compose version");],
[#ExtensionTok("docker");#NormalTok(" info");],));
Los dos primeros comandos identifican las herramientas; #NormalTok("docker info"); comprueba el acceso al motor. Si este último falla, resuelve la preparación de Docker con la documentación de tu plataforma antes de investigar PHP o \.NET. No necesitas instalar los lenguajes ni los motores de base de datos en el host. La primera construcción sí necesita acceso a los registros para descargar las imágenes.

#strong[\3. Decide qué escenario usar.] Los dos necesitan el puerto #NormalTok("8080"); del host; MariaDB publica además #NormalTok("3306"); y SQL Server #NormalTok("1433");. Si otra aplicación ocupa uno de esos puertos, identifica el conflicto antes de arrancar; no borres datos ni modifiques servicios del host automáticamente.

#block[
#callout(
body: 
[
Los Compose incluyen contraseñas de respaldo solo para desarrollo. Los archivos #NormalTok(".env"); que prepararás están ignorados por Git: no publiques sus valores ni los incluyas en capturas. Los marcadores entre #NormalTok("<"); y #NormalTok(">"); deben reemplazarse completos por contraseñas propias antes de ejecutar los comandos.

Si ya habías iniciado una base y su volumen contiene datos, #strong[cambiar #NormalTok(".env"); no equivale a cambiar la contraseña almacenada en esa base]. Verifica las credenciales existentes o realiza un cambio explícito dentro del motor; no elimines el volumen para corregir una discrepancia.

]
, 
title: 
[
Configura las contraseñas antes del primer arranque
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
=== PHP
<php>
El escenario usa #NormalTok("php/Dockerfile"); y #NormalTok("php/compose.yaml");. El primero prepara Apache, PHP 8.5.12 y las extensiones #NormalTok("pdo_mysql"); y #NormalTok("mysqli");\; Compose conecta #NormalTok("app"); con MariaDB. Puedes consultar también la #link("https://github.com/statick88/aplicaciones-web-php-csharp/blob/main/php/README.md")[guía PHP del repositorio].

#strong[\1. Crea #NormalTok("php/.env"); con tu editor.] Usa dos contraseñas distintas:

#Skylighting(([#NormalTok("MARIADB_PASSWORD='<CLAVE_PROPIA_PARA_LA_APLICACION>'");],
[#NormalTok("MARIADB_ROOT_PASSWORD='<OTRA_CLAVE_PROPIA_PARA_ROOT>'");],));
#NormalTok("MARIADB_PASSWORD"); configura tanto el usuario de la base como #NormalTok("DB_PASSWORD"); en la aplicación. La aplicación usa el usuario #NormalTok("app"); y la base #NormalTok("facturas");, no el usuario administrador #NormalTok("root");. No tienes que crear esos nombres manualmente: MariaDB los prepara mediante las variables del Compose en su inicialización.

#strong[\2. Valida la configuración y levanta el escenario.] Si habías iniciado el escenario C\#, detenlo primero como se indica en su sección de apagado.

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml config ");#AttributeTok("--quiet");],
[#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml up ");#AttributeTok("-d");#NormalTok(" ");#AttributeTok("--build");],));
#NormalTok("--env-file"); selecciona explícitamente las variables, #NormalTok("-f"); el archivo del escenario, #NormalTok("--build"); construye la imagen de la aplicación y #NormalTok("-d"); deja los servicios ejecutándose en segundo plano. El primer comando valida el modelo sin imprimir las contraseñas; no comprueba que la base acepte conexiones.

#strong[\3. Revisa el estado.]

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml ps");],));
Busca los servicios #NormalTok("app"); y #NormalTok("db");. La base puede aparecer inicialmente como #NormalTok("starting");\; #NormalTok("app"); depende de que la comprobación de salud de MariaDB termine correctamente. Si hay un problema, consulta cada servicio por separado:

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml logs ");#AttributeTok("--tail");#OperatorTok("=");#NormalTok("80 db");],
[#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml logs ");#AttributeTok("--tail");#OperatorTok("=");#NormalTok("80 app");],));
#strong[\4. Comprueba la aplicación y un guardado real.] Abre #NormalTok("http://127.0.0.1:8080");. Ver una página confirma que responde PHP/Apache, pero no prueba por sí solo que PHP pueda guardar en MariaDB.

Para comprobar el recorrido completo, abre #NormalTok("http://127.0.0.1:8080/home.php");, completa el formulario con #strong[datos ficticios] y presiona #strong[Guardar]. En este proyecto, #NormalTok("php/public/home.php"); abre la conexión mediante PDO al recibir el POST, crea la tabla #NormalTok("facturas"); con #NormalTok("CREATE TABLE IF NOT EXISTS"); y después ejecuta el #NormalTok("INSERT"); parametrizado. No hay un archivo SQL de inicio que debas importar. El resultado esperado incluye #strong["Guardada en MariaDB"] y el identificador de la fila. Si aparece #strong["No se pudo guardar en la base de datos"], revisa el error y las credenciales; no consideres exitoso el ejercicio solo porque el formulario se haya mostrado.

#strong[\5. Edita el código y detén sin borrar datos.] El proyecto PHP completo está montado en #NormalTok("/var/www/html");, pero Apache solo sirve #NormalTok("public/"); como DocumentRoot: la lógica (#NormalTok("src/");), las plantillas (#NormalTok("views/");) y la configuración (#NormalTok("config/");) quedan fuera de la URL. Para cambios de PHP normalmente basta con guardar el archivo y recargar el navegador. Reconstruye si modificas el #NormalTok("Dockerfile"); o sus extensiones.

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml stop");],));
Para volver a iniciar, reutiliza el mismo comando #NormalTok("up -d --build"); del paso 2.

=== C\# / ASP.NET Core
<c-asp.net-core>
El escenario usa #NormalTok("csharp/Dockerfile"); y #NormalTok("csharp/compose.yaml");: un contenedor con SDK \.NET 10.0.403 y #NormalTok("dotnet watch");, y otro con SQL Server 2022. Consulta también la #link("https://github.com/statick88/aplicaciones-web-php-csharp/blob/main/csharp/README.md")[guía C\# del repositorio]. Antes de empezar, respeta el límite x86-64 explicado arriba. El Compose declara #NormalTok("ACCEPT_EULA=Y");: revisa los términos de Microsoft antes de utilizar la imagen.

#strong[\1. Libera el puerto y crea #NormalTok("csharp/.env");.] Si ya preparaste PHP con los pasos anteriores y sigue encendido, detenlo:

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" php/.env ");#AttributeTok("-f");#NormalTok(" php/compose.yaml stop");],));
Si comienzas directamente por \.NET y no has preparado PHP, omite ese comando. Luego crea el archivo con tu editor:

#Skylighting(([#NormalTok("MSSQL_SA_PASSWORD='<CLAVE_PROPIA_FUERTE_PARA_SQL_SERVER>'");],));
Reemplaza el marcador por una contraseña propia; se recomienda al menos 16 caracteres combinando mayúsculas, minúsculas, números y símbolos como #NormalTok("!");, #NormalTok("_"); o #NormalTok("-");. Evita #NormalTok(";"); en este ejemplo: la contraseña se interpola directamente en la cadena de conexión. El mismo valor configura SQL Server y la variable #NormalTok("ConnectionStrings__Facturas"); de la aplicación.

#strong[\2. Valida y construye.]

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" csharp/.env ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml config ");#AttributeTok("--quiet");],
[#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" csharp/.env ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml up ");#AttributeTok("-d");#NormalTok(" ");#AttributeTok("--build");],));
No necesitas ejecutar #NormalTok("dotnet new"); ni instalar el SDK en el host: el proyecto MVC ya está en #NormalTok("csharp/src"); y el SDK está dentro de #NormalTok("app");.

#strong[\3. Espera a SQL Server y revisa los registros.]

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" csharp/.env ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml ps");],
[#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" csharp/.env ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml logs ");#AttributeTok("--tail");#OperatorTok("=");#NormalTok("100 db");],
[#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" csharp/.env ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml logs ");#AttributeTok("--tail");#OperatorTok("=");#NormalTok("100 app");],));
La comprobación de salud de #NormalTok("db"); ejecuta una consulta con #NormalTok("sqlcmd");\; #NormalTok("app"); espera a que termine correctamente. Ese estado confirma que responde el motor, no que el formulario de la aplicación ya haya guardado una factura.

#strong[\4. Comprueba las migraciones y el formulario.] Al iniciar, #NormalTok("Program.cs"); ejecuta #NormalTok("Database.Migrate()");: aplica las migraciones pendientes de EF Core en la base #NormalTok("Facturas");. Para este arranque no debes ejecutar manualmente #NormalTok("dotnet ef database update");. Si una migración falla, la aplicación puede no iniciar: revisa los registros de #NormalTok("app");, no solo los de SQL Server.

Abre #NormalTok("http://127.0.0.1:8080"); y completa el formulario con datos ficticios. El POST llega a #NormalTok("HomeController");, agrega la entidad y llama a #NormalTok("SaveChanges()");. El envío exitoso vuelve mostrando los datos; esta aplicación no tiene un mensaje específico de "conexión correcta" ni un endpoint de salud propio. No inventes esa evidencia: el recorrido que debes comprobar es formulario, POST y guardado.

#strong[\5. Edita y detén el escenario.] #NormalTok("csharp/src"); está montado en #NormalTok("/app");\; #NormalTok("dotnet watch"); detecta cambios y recompila durante el desarrollo.

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("--env-file");#NormalTok(" csharp/.env ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml stop");],));
Para retomar, usa el mismo comando #NormalTok("up -d --build"); del paso 2.

=== Direcciones y persistencia
<direcciones-y-persistencia>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Servicio], [Desde el navegador o una herramienta del host], [Desde #NormalTok("app");],),
  table.hline(),
  [Aplicación PHP o \.NET], [#NormalTok("http://127.0.0.1:8080");], [No aplica],
  [MariaDB], [#NormalTok("127.0.0.1:3306");], [#NormalTok("db:3306");],
  [SQL Server], [#NormalTok("127.0.0.1:1433");], [#NormalTok("db:1433");],
)
Dentro de #NormalTok("app");, #NormalTok("localhost"); es el propio contenedor de la aplicación. La base se encuentra por el nombre de servicio #strong[#NormalTok("db");], que resuelve la red de Compose. No hay phpMyAdmin ni un administrador web de SQL Server configurados: la página en #NormalTok("8080"); es la aplicación de práctica.

MariaDB guarda sus archivos en un volumen montado en #NormalTok("/var/lib/mysql");\; SQL Server en #NormalTok("/var/opt/mssql");. Son datos distintos del código montado desde #NormalTok("src");. #NormalTok("stop"); conserva contenedores y volúmenes. Reutiliza el mismo escenario y nombre de proyecto: cambiar de proyecto puede seleccionar otros volúmenes. #strong[No ejecutes #NormalTok("down -v"); como solución de problemas:] puede eliminar los datos.

=== Si algo falla
<si-algo-falla>
#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Síntoma], [Qué revisar primero],),
  table.hline(),
  [Docker no responde o no permite el acceso], [#NormalTok("docker info"); y la preparación del motor en tu host],
  [No encuentra #NormalTok(".env"); o #NormalTok("compose.yaml");], [La raíz del repositorio y los argumentos #NormalTok("--env-file"); y #NormalTok("-f");],
  [Puerto ocupado], [El otro escenario o un servicio local que ya usa #NormalTok("8080");, #NormalTok("3306"); o #NormalTok("1433");],
  [#NormalTok("db"); permanece iniciando o queda #NormalTok("unhealthy");], [Registros de #NormalTok("db");, recursos disponibles y, para SQL Server, contraseña y arquitectura],
  [Error de autenticación], [Coincidencia de credenciales y si el volumen ya tenía otra contraseña; no lo borres],
  [PHP muestra el formulario pero no guarda], [POST a #NormalTok("/home.php");, mensaje de error y conexión PDO],
  [\.NET no inicia o falla al enviar], [Registros de #NormalTok("app");, migraciones y conexión usada por #NormalTok("SaveChanges()");],
)
Que un contenedor figure en #NormalTok("ps"); no prueba todo el escenario. Separa siempre cuatro comprobaciones: configuración válida, servicios disponibles, respuesta HTTP y persistencia de un registro de prueba. No se promete aquí ejecución en hosts o integraciones que no se hayan verificado.

== Ruta B: Dev Containers
<ruta-b-dev-containers>
Un Dev Container abre el proyecto dentro de un contenedor para que el editor y la terminal integrada compartan ese contexto. No reemplaza Compose: esta configuración le indica a VS Code qué archivo Compose y qué servicio usar. Puedes adjuntarte a un contenedor #NormalTok("app"); ya iniciado o copiar una configuración al proyecto y después abrir la carpeta en un contenedor.

=== Copiar la configuración PHP
<copiar-la-configuración-php>
+ Desde la #strong[raíz del repositorio], crea manualmente #NormalTok("php/.devcontainer/"); si aún no existe y copia el contenido de #NormalTok("ebook/examples/devcontainers/php.json"); a #NormalTok("php/.devcontainer/devcontainer.json");.
+ Confirma que #NormalTok("dockerComposeFile"); queda como #NormalTok("../compose.yaml");, que el servicio es #NormalTok("app"); y que #NormalTok("workspaceFolder"); es #NormalTok("/var/www/html");.
+ En VS Code usa el flujo de Dev Containers para abrir la carpeta #NormalTok("php/"); o adjúntate al #NormalTok("app"); PHP que ya esté ejecutándose.
+ Ejecuta la comprobación de variables indicada en la guía PHP y registra el resultado observado. No se afirma aquí que una extensión del editor esté instalada.

=== Copiar la configuración C
<copiar-la-configuración-c>
+ Desde la #strong[raíz del repositorio], crea manualmente #NormalTok("csharp/.devcontainer/"); si aún no existe y copia el contenido de #NormalTok("ebook/examples/devcontainers/csharp.json"); a #NormalTok("csharp/.devcontainer/devcontainer.json");.
+ Confirma #NormalTok("dockerComposeFile: ../compose.yaml");, servicio #NormalTok("app"); y #NormalTok("workspaceFolder: /app");.
+ Abre #NormalTok("csharp/"); mediante el flujo Dev Containers o adjúntate al #NormalTok("app"); C\# que ya esté ejecutándose, respetando antes el límite x86-64 de SQL Server.
+ Usa la comprobación descrita en la guía C\# y explica qué verificó; no la confundas con una prueba de todas las rutas web.

Los ejemplos deliberadamente no montan el socket Docker, no usan modo #NormalTok("privileged"); y no fuerzan apagado automático: #NormalTok("shutdownAction"); es #NormalTok("none");. No agregan redes, restauraciones de paquetes ni comandos automáticos. Eso deja las decisiones de host y de ciclo de vida bajo tu control.

== Comprobación de aprendizaje, no de plataforma
<comprobación-de-aprendizaje-no-de-plataforma>
Después de cualquiera de las rutas, vuelve al objetivo de Semana 1:

+ elige un valor de entrada y predice una salida;
+ localiza entrada, procesamiento y salida en el ejemplo;
+ contrasta PHP y C\# sin exigir que tengan la misma pantalla;
+ anota si el límite fue del código, del contenedor, del puerto o de la compatibilidad de SQL Server.

Si no puedes iniciar el stack C\# en Apple Silicon, aún puedes estudiar los fragmentos y completar la comparación conceptual. No presentes esa lectura como ejecución verificada del servicio SQL Server.

== Referencias de operación
<referencias-de-operación>
- #link("https://docs.docker.com/engine/install/")[Documentación de Docker Engine] para la preparación específica del host @docker-docs.
- #link("https://containers.dev/")[Especificación Dev Container] y #link("https://code.visualstudio.com/docs/devcontainers/containers")[uso de contenedores en VS Code] para el flujo del editor @devcontainers@vscode-containers.
- #link("https://learn.microsoft.com/sql/linux/install-upgrade/quickstart-install-docker")[SQL Server en contenedores Linux] para el límite x86-64 y soporte de emulación @sqlserver-containers.

= Semana 2 · Clase 1: tipos, conversiones y Cliente
<semana2-clase1-tipos-cliente>
Esta clase conecta valores simples con decisiones observables en código: qué tipo llega, qué conversión se hace y qué ocurre al gestionar un cliente. Los ejemplos comparan PHP y C\# sin suponer que sus reglas son idénticas. Para referencias de lenguaje, consulta el manual de PHP y la referencia de C\# @php-manual@microsoft-csharp.

El alcance sigue el material de clase aportado como #NormalTok("semana2.md");, contrastado con las prácticas locales de PHP y C\#; no implica acceso nuevo a Blackboard @course-web-week2-class1.

== 1. Valores simples y ausencia de valor
<s2c1-tipos-simples>
Un escalar contiene un valor: #NormalTok("int"); (entero), #NormalTok("float");/#NormalTok("double"); (decimal), #NormalTok("string"); (texto) o #NormalTok("bool"); (verdadero/falso). #NormalTok("null"); no es un quinto escalar: representa la ausencia de valor. PHP infiere estos tipos desde el valor; C\# los declara o los infiere con #NormalTok("var"); y distingue una referencia opcional con #NormalTok("string?");.

#Skylighting(([#VariableTok("$cantidad");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#DecValTok("3");#OtherTok(";");#NormalTok("        ");#CommentTok("// int");],
[#VariableTok("$precio");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#FloatTok("12.50");#OtherTok(";");#NormalTok("      ");#CommentTok("// float");],
[#VariableTok("$producto");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Teclado USB\"");#OtherTok(";");#NormalTok(" ");#CommentTok("// string");],
[#VariableTok("$enStock");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("true");#OtherTok(";");#NormalTok("      ");#CommentTok("// bool");],
[#VariableTok("$descuento");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("null");#OtherTok(";");#NormalTok("    ");#CommentTok("// ausencia de valor");],
[#VariableTok("$subtotal");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#VariableTok("$cantidad");#NormalTok(" ");#OperatorTok("*");#NormalTok(" ");#VariableTok("$precio");#OtherTok(";");],));
#strong[Esperado:] #NormalTok("subtotal"); vale #NormalTok("37.5"); y es decimal porque interviene #NormalTok("float");. #strong[Observado en el ejemplo:] las comprobaciones #NormalTok("is_int");, #NormalTok("is_float");, #NormalTok("is_string");, #NormalTok("is_bool"); e #NormalTok("is_null"); corresponden a esos cinco valores. Para mostrar dinero se puede formatear o redondear; no se debe asumir precisión binaria exacta para operaciones como #NormalTok("0.1 + 0.2");.

En la demostración C\#, #NormalTok("int cantidad");, #NormalTok("double precio");, #NormalTok("string producto");, #NormalTok("bool enStock"); y #NormalTok("string? descuento"); expresan la misma intención. El cálculo produce #NormalTok("37.5");\; el tipo decimal de punto flotante tampoco convierte una suma en una regla de validación.

#Skylighting(([#KeywordTok("using");#NormalTok(" System");#OperatorTok(".");#FunctionTok("Globalization");#OperatorTok(";");],
[],
[#DataTypeTok("var");#NormalTok(" datos ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("new");#NormalTok(" Dictionary");#OperatorTok("<");#DataTypeTok("string");#OperatorTok(",");#NormalTok(" ");#DataTypeTok("string");#OperatorTok(">");#NormalTok(" ");#OperatorTok("{");#NormalTok(" ");#OperatorTok("[");#StringTok("\"ciudad\"");#OperatorTok("]");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Ambato\"");#NormalTok(" ");#OperatorTok("};");],
[#DataTypeTok("double");#NormalTok(" precio ");#OperatorTok("=");#NormalTok(" ");#DataTypeTok("double");#OperatorTok(".");#FunctionTok("Parse");#OperatorTok("(");#StringTok("\"8.5\"");#OperatorTok(",");#NormalTok(" CultureInfo");#OperatorTok(".");#FunctionTok("InvariantCulture");#OperatorTok(");");],
[#DataTypeTok("bool");#NormalTok(" numerosIguales ");#OperatorTok("=");#NormalTok(" ");#DataTypeTok("int");#OperatorTok(".");#FunctionTok("Parse");#OperatorTok("(");#StringTok("\"1\"");#OperatorTok(")");#NormalTok(" ");#OperatorTok("==");#NormalTok(" ");#DataTypeTok("int");#OperatorTok(".");#FunctionTok("Parse");#OperatorTok("(");#StringTok("\"01\"");#OperatorTok(");");],
[#DataTypeTok("bool");#NormalTok(" textosIguales ");#OperatorTok("=");#NormalTok(" ");#DataTypeTok("string");#OperatorTok(".");#FunctionTok("Equals");#OperatorTok("(");#StringTok("\"1\"");#OperatorTok(",");#NormalTok(" ");#StringTok("\"01\"");#OperatorTok(",");#NormalTok(" StringComparison");#OperatorTok(".");#FunctionTok("Ordinal");#OperatorTok(");");],
[],
[#NormalTok("Console");#OperatorTok(".");#FunctionTok("WriteLine");#OperatorTok("(");#NormalTok("$");#StringTok("\"{precio}; {numerosIguales}; {textosIguales}; {datos[\"");#NormalTok("ciudad");#StringTok("\"]}\"");#OperatorTok(");");],
[#NormalTok("Console");#OperatorTok(".");#FunctionTok("WriteLine");#OperatorTok("(");#NormalTok("Busqueda");#OperatorTok(".");#FunctionTok("BuscarCliente");#OperatorTok("(");#DecValTok("15");#OperatorTok("));");],
[#NormalTok("Console");#OperatorTok(".");#FunctionTok("WriteLine");#OperatorTok("(");#NormalTok("Busqueda");#OperatorTok(".");#FunctionTok("BuscarCliente");#OperatorTok("(");#StringTok("\"0102\"");#OperatorTok("));");],
[],
[#KeywordTok("static");#NormalTok(" ");#KeywordTok("class");#NormalTok(" Busqueda");],
[#OperatorTok("{");],
[#NormalTok("    ");#KeywordTok("public");#NormalTok(" ");#KeywordTok("static");#NormalTok(" ");#DataTypeTok("string");#NormalTok(" ");#FunctionTok("BuscarCliente");#OperatorTok("(");#DataTypeTok("int");#NormalTok(" id");#OperatorTok(")");#NormalTok(" ");#OperatorTok("=>");#NormalTok(" $");#StringTok("\"BuscarPorId({id})\"");#OperatorTok(";");],
[#NormalTok("    ");#KeywordTok("public");#NormalTok(" ");#KeywordTok("static");#NormalTok(" ");#DataTypeTok("string");#NormalTok(" ");#FunctionTok("BuscarCliente");#OperatorTok("(");#DataTypeTok("string");#NormalTok(" cedula");#OperatorTok(")");#NormalTok(" ");#OperatorTok("=>");#NormalTok(" $");#StringTok("\"BuscarPorCedula(");#SpecialCharTok("\\\"");#StringTok("{cedula}");#SpecialCharTok("\\\"");#StringTok(")\"");#OperatorTok(";");],
[#OperatorTok("}");],));
#strong[Esperado:] #NormalTok("precio"); es #NormalTok("8.5");, #NormalTok("numerosIguales"); es #NormalTok("true");, #NormalTok("textosIguales"); es #NormalTok("false"); y el diccionario entrega #NormalTok("Ambato"); para #NormalTok("\"ciudad\"");. Las dos sobrecargas conservan separado buscar por id de buscar por cédula.

== 2. Convertir no es validar
<s2c1-conversiones>
PHP puede convertir implícitamente cuando una operación lo requiere y permite casts explícitos. Un cast intenta interpretar un valor; no confirma que el texto completo tenga el formato permitido.

#Skylighting(([#FunctionTok("var_dump");#NormalTok("(");#StringTok("\"10\"");#NormalTok(" ");#OperatorTok("+");#NormalTok(" ");#DecValTok("5");#NormalTok(")");#OtherTok(";");#NormalTok("          ");#CommentTok("// int(15)");],
[#FunctionTok("var_dump");#NormalTok("((");#DataTypeTok("int");#NormalTok(") ");#StringTok("\"125abc\"");#NormalTok(")");#OtherTok(";");#NormalTok("    ");#CommentTok("// int(125)");],
[#FunctionTok("var_dump");#NormalTok("(");#DataTypeTok("(float)");#NormalTok(" ");#StringTok("\"8,5\"");#NormalTok(")");#OtherTok(";");#NormalTok("     ");#CommentTok("// float(8)");],
[#FunctionTok("var_dump");#NormalTok("(");#DataTypeTok("(bool)");#NormalTok(" ");#StringTok("\"0\"");#NormalTok(")");#OtherTok(";");#NormalTok("        ");#CommentTok("// bool(false)");],));
#strong[Esperado:] el cast conserva el prefijo numérico de #NormalTok("\"125abc\"");, la coma no es separador decimal para ese cast y #NormalTok("\"0\""); se vuelve #NormalTok("false");. #strong[Observado:] esos son precisamente los valores comprobados en #NormalTok("php/tests/semana2-tipos.php");. Por eso aceptar #NormalTok("125abc"); o #NormalTok("8,5"); como entrada numérica válida sería un error de validación, aunque el cast devuelva algo. En C\#, la demostración analiza #NormalTok("\"8.5\""); con #NormalTok("double.Parse"); y cultura invariante; para una entrada externa se decide y verifica el formato antes de usar el número.

También son falsos al convertir a booleano #NormalTok("0");, #NormalTok("\"\"");, #NormalTok("[]"); y #NormalTok("null");. No los uses como sustituto de una regla de negocio: una regla debe decir qué ausencia, texto o número acepta.

=== Igualdad: valor y tipo
<s2c1-igualdad>
En PHP 8, #NormalTok("0 == \"a\""); es #NormalTok("false");\; #NormalTok("\"1\" == \"01\""); es #NormalTok("true"); por comparación numérica, mientras #NormalTok("\"1\" === \"01\""); es #NormalTok("false"); porque exige tipo y valor. Prefiere #NormalTok("==="); cuando comparas datos que ya tienen tipo conocido. C\# no hace ese #emph[type juggling]: el ejemplo convierte ambos textos a entero para comparar sus números y usa #NormalTok("string.Equals(..., StringComparison.Ordinal)"); para contrastar los textos.

== 3. Contratos de tipo
<s2c1-contratos-tipo>
#NormalTok("declare(strict_types=1);"); cambia cómo PHP trata llamadas hechas desde ese archivo: una cadena como #NormalTok("\"3\""); no se acepta silenciosamente por un parámetro #NormalTok("int");. No impide que un #NormalTok("int"); se use donde el parámetro declara #NormalTok("float");.

#Skylighting(([#KeywordTok("<?php");],
[#KeywordTok("declare");#NormalTok("(strict_types");#OperatorTok("=");#DecValTok("1");#NormalTok(")");#OtherTok(";");],
[],
[#KeywordTok("function");#NormalTok(" calcularTotal(");#DataTypeTok("int");#NormalTok(" ");#VariableTok("$cantidad");#OtherTok(",");#NormalTok(" ");#DataTypeTok("float");#NormalTok(" ");#VariableTok("$precio");#OtherTok(",");],
[#NormalTok("    ");#OtherTok("?");#DataTypeTok("float");#NormalTok(" ");#VariableTok("$descuento");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("null");#NormalTok(")");#OtherTok(":");#NormalTok(" ");#DataTypeTok("float");#NormalTok(" {");],
[#NormalTok("    ");#VariableTok("$total");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#VariableTok("$cantidad");#NormalTok(" ");#OperatorTok("*");#NormalTok(" ");#VariableTok("$precio");#OtherTok(";");],
[#NormalTok("    ");#ControlFlowTok("if");#NormalTok(" (");#VariableTok("$descuento");#NormalTok(" ");#OperatorTok("!==");#NormalTok(" ");#KeywordTok("null");#NormalTok(") {");],
[#NormalTok("        ");#VariableTok("$total");#NormalTok(" ");#OperatorTok("-=");#NormalTok(" ");#VariableTok("$total");#NormalTok(" ");#OperatorTok("*");#NormalTok(" ");#VariableTok("$descuento");#OtherTok(";");],
[#NormalTok("    }");],
[#NormalTok("    ");#ControlFlowTok("return");#NormalTok(" ");#FunctionTok("round");#NormalTok("(");#VariableTok("$total");#OtherTok(",");#NormalTok(" ");#DecValTok("2");#NormalTok(")");#OtherTok(";");],
[#NormalTok("}");],));
#strong[Esperado:] #NormalTok("calcularTotal(3, 12.5)"); resulta #NormalTok("37.5"); y, con #NormalTok("0.10");, #NormalTok("33.75");. #strong[Observado:] ambas llamadas pasan en la prueba; #NormalTok("calcularTotal(\"3\", 12.5)"); lanza #NormalTok("TypeError"); desde la llamada estricta. #NormalTok("?float"); permite un #NormalTok("float"); o #NormalTok("null");. PHP además declara #NormalTok("int|string"); para una clave de búsqueda; C\# no tiene ese parámetro unión: dos sobrecargas, una para #NormalTok("int"); y otra para #NormalTok("string");, conservan la intención de cada entrada.

== 4. Nombres dinámicos bajo control
<s2c1-nombres-dinamicos>
PHP permite que una variable determine el nombre de otra. Es útil para entender el lenguaje, pero no debe construirse desde datos de usuario.

#Skylighting(([#VariableTok("$campo");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"ciudad\"");#OtherTok(";");],
[#VariableTok("$$campo");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#StringTok("\"Ambato\"");#OtherTok(";");],
[#VariableTok("$suma");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#DecValTok("0");#OtherTok(";");],
[#ControlFlowTok("for");#NormalTok(" (");#VariableTok("$i");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#DecValTok("1");#OtherTok(";");#NormalTok(" ");#VariableTok("$i");#NormalTok(" ");#OperatorTok("<=");#NormalTok(" ");#DecValTok("3");#OtherTok(";");#NormalTok(" ");#VariableTok("$i");#OperatorTok("++");#NormalTok(") {");],
[#NormalTok("    ${");#StringTok("\"nota");#VariableTok("$i");#StringTok("\"");#NormalTok("} ");#OperatorTok("=");#NormalTok(" ");#VariableTok("$i");#NormalTok(" ");#OperatorTok("*");#NormalTok(" ");#DecValTok("3");#OtherTok(";");],
[#NormalTok("    ");#VariableTok("$suma");#NormalTok(" ");#OperatorTok("+=");#NormalTok(" ${");#StringTok("\"nota");#VariableTok("$i");#StringTok("\"");#NormalTok("}");#OtherTok(";");],
[#NormalTok("}");],
[#VariableTok("$datos");#NormalTok(" ");#OperatorTok("=");#NormalTok(" [");#VariableTok("$campo");#NormalTok(" => ");#StringTok("\"Ambato\"");#NormalTok("]");#OtherTok(";");],));
#strong[Esperado:] existe #NormalTok("$ciudad"); con #NormalTok("Ambato"); y la suma de las notas es #NormalTok("18");. #strong[Observado:] el ejemplo comprueba ambos resultados. El arreglo asociativo #NormalTok("$datos['ciudad']"); logra la misma consulta de manera visible y recorrible. C\# no tiene #NormalTok("$$campo");\; usa #NormalTok("Dictionary<string, string>"); para una clave dinámica controlada, también con #NormalTok("ciudad = Ambato");.

== 5. Cliente tipado y operaciones en memoria
<s2c1-cliente-crud>
#NormalTok("Cliente"); reúne un #NormalTok("id"); entero, nombre y correo de texto, #NormalTok("activo"); booleano y teléfono opcional. El repositorio usa el id como clave de un arreglo PHP o un #NormalTok("Dictionary<int, Cliente>"); C\#. Sus operaciones son:

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Operación], [Efecto observado], [Id inexistente],),
  table.hline(),
  [registrar], [guarda por id; registrar el mismo id #strong[reemplaza] el cliente anterior], [no aplica],
  [consultar], [devuelve el cliente o #NormalTok("null");], [#NormalTok("null");],
  [listar], [devuelve los clientes guardados], [lista vacía si no había datos],
  [actualizarCorreo], [cambia el correo y devuelve #NormalTok("true");], [no cambia datos; devuelve #NormalTok("false");],
  [eliminar], [quita el cliente y devuelve #NormalTok("true");], [no cambia datos; devuelve #NormalTok("false");],
)
El siguiente es un extracto: presupone que ya se cargaron las clases #NormalTok("Cliente"); y #NormalTok("ClienteRepositorioMemoria"); de #NormalTok("php/src/semana2-cliente.php");.

#Skylighting(([#VariableTok("$repo");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#KeywordTok("new");#NormalTok(" ClienteRepositorioMemoria()");#OtherTok(";");],
[#VariableTok("$repo");#NormalTok("->registrar(");#KeywordTok("new");#NormalTok(" Cliente(");#DecValTok("1");#OtherTok(",");#NormalTok(" ");#StringTok("\"Ana Pérez\"");#OtherTok(",");#NormalTok(" ");#StringTok("\"ana@correo.com\"");#NormalTok("))");#OtherTok(";");],
[#VariableTok("$repo");#NormalTok("->actualizarCorreo(");#DecValTok("1");#OtherTok(",");#NormalTok(" ");#StringTok("\"ana.perez@correo.com\"");#NormalTok(")");#OtherTok(";");],
[#VariableTok("$noExiste");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#VariableTok("$repo");#NormalTok("->consultar(");#DecValTok("999");#NormalTok(")");#OtherTok(";");#NormalTok(" ");#CommentTok("// null");],));
#strong[Esperado:] Ana queda con el correo actualizado y #NormalTok("999"); no crea ni modifica un cliente. #strong[Observado:] las pruebas cubren consultar, listar, actualizar y eliminar, incluidos los id #NormalTok("999");\; no hay una regla de rechazo de duplicados: el registro por la misma clave reemplaza el valor según la fuente.

El repositorio de las demostraciones existe solo en memoria. En una ejecución PHP termina al acabar la solicitud; crear otro repositorio no conserva sus clientes. La acción #NormalTok("Tipos"); de C\# también crea uno nuevo por solicitud. La aplicación de formularios C\# usa una lista serializada en sesión para otro recorrido, por lo que puede reaparecer durante esa sesión; eso no convierte al repositorio de la demostración en una base de datos.

== Pasos de práctica
<s2c1-pasos-practica>
+ Predice tipo y valor de cada cast antes de ejecutarlo; separa conversión de aceptación de entrada.
+ Ejecuta desde la raíz #NormalTok("php php/tests/semana2-tipos.php"); y registra la salida.
+ Ejecuta desde la raíz #NormalTok("php php/tests/semana2-cliente.php");\; cambia solo una predicción en tus notas, no las reglas del repositorio.
+ Compara el resultado con #NormalTok("Semana2/Tipos"); en C\#: identifica qué hace el cast/parsing y qué dato queda solo en memoria.
+ Continúa con #link("02-formularios-get-post.qmd")[formularios, GET y POST] para ver cómo un texto llega por una solicitud. La navegación de la asignatura está en #link(<aplicaciones-web>)[Aplicaciones Web].

== Ejercicios y respuestas razonadas
<s2c1-ejercicios>
=== Ejercicio 1
<s2c1-ej-1>
¿Por qué #NormalTok("(int) \"125abc\""); no valida un id?

=== Ejercicio 2
<s2c1-ej-2>
Predice #NormalTok("calcularTotal(3, 12.5, 0.10)"); y explica qué ocurriría con #NormalTok("\"3\""); como primer argumento en la llamada estricta.

=== Ejercicio 3
<s2c1-ej-3>
Compara #NormalTok("\"1\" == \"01\""); con #NormalTok("\"1\" === \"01\"");. ¿Qué información exige la segunda comparación?

=== Ejercicio 4
<s2c1-ej-4>
Si se registra dos veces el id #NormalTok("2");, ¿qué ocurre? ¿Qué devuelve eliminar #NormalTok("999"); y qué datos cambia?

=== Ejercicio 5
<s2c1-ej-5>
Elige entre #NormalTok("$$campo"); y un arreglo/Dictionary para una ciudad que llega de un formulario. Justifica la elección.

=== Respuestas
<s2c1-respuestas>
=== Respuesta 1
<s2c1-r-1>
#link(<s2c1-ej-1>)[Volver al ejercicio]. El cast toma el prefijo #NormalTok("125"); y descarta que el resto haga inválido el formato; primero debe verificarse que todo el texto cumpla la regla del id.

=== Respuesta 2
<s2c1-r-2>
#link(<s2c1-ej-2>)[Volver al ejercicio]. El resultado es #NormalTok("33.75");. Con #NormalTok("\"3\"");, el modo estricto de la llamada produce #NormalTok("TypeError");\; el contrato detecta la discrepancia, pero no valida por sí solo una entrada web.

=== Respuesta 3
<s2c1-r-3>
#link(<s2c1-ej-3>)[Volver al ejercicio]. La primera es verdadera por la comparación numérica flexible; la segunda es falsa porque también exige que ambos sean el mismo texto y del mismo tipo.

=== Respuesta 4
<s2c1-r-4>
#link(<s2c1-ej-4>)[Volver al ejercicio]. El segundo registro reemplaza al valor de la clave #NormalTok("2");. Eliminar #NormalTok("999"); devuelve #NormalTok("false"); y no modifica la colección.

=== Respuesta 5
<s2c1-r-5>
#link(<s2c1-ej-5>)[Volver al ejercicio]. El arreglo o #NormalTok("Dictionary"); mantiene las claves visibles, permite recorrerlas y evita crear nombres de variables desde una entrada externa; #NormalTok("$$campo"); queda para un caso controlado y explícito.

= Semana 2 · Clase 2: formularios, GET y POST
<semana2-clase2-formularios-get-post>
Un formulario convierte una elección del navegador en una solicitud HTTP. Esta clase sigue el recorrido completo: construir la entrada, leerla con cuidado, validarla en el servidor y mostrar un resultado sin repetir un registro. Los ejemplos son prácticas locales, con datos ficticios y sin base de datos.

El alcance sigue el material de clase aportado como #NormalTok("semana2-clase2.md");, contrastado con las prácticas locales de PHP y C\#; no implica acceso nuevo a Blackboard @course-web-week2-class2.

== Formularios: contrato de entrada
<s2c2-formularios>
#NormalTok("action"); indica el destino y #NormalTok("method"); el método HTTP. Cada control que deba viajar necesita #NormalTok("name");: ese nombre será la clave recibida. #NormalTok("enctype=\"multipart/form-data\""); se usa cuando hay archivos; entonces estos llegan por #NormalTok("$_FILES"); en PHP. #NormalTok("required");, #NormalTok("type=\"email\"");, #NormalTok("min"); y #NormalTok("maxlength"); ayudan al navegador, pero una persona puede cambiar una petición antes de enviarla. Por ello son una ayuda de interfaz, no una validación del servidor.

#Skylighting(([#DataTypeTok("<");#KeywordTok("form");#OtherTok(" action");#OperatorTok("=");#StringTok("\"semana2-registro.php\"");#OtherTok(" method");#OperatorTok("=");#StringTok("\"post\"");#DataTypeTok(">");],
[#NormalTok("  ");#DataTypeTok("<");#KeywordTok("input");#OtherTok(" name");#OperatorTok("=");#StringTok("\"nombre\"");#OtherTok(" required maxlength");#OperatorTok("=");#StringTok("\"80\"");#DataTypeTok(">");],
[#NormalTok("  ");#DataTypeTok("<");#KeywordTok("input");#OtherTok(" name");#OperatorTok("=");#StringTok("\"correo\"");#OtherTok(" type");#OperatorTok("=");#StringTok("\"email\"");#OtherTok(" required");#DataTypeTok(">");],
[#NormalTok("  ");#DataTypeTok("<");#KeywordTok("input");#OtherTok(" name");#OperatorTok("=");#StringTok("\"edad\"");#OtherTok(" type");#OperatorTok("=");#StringTok("\"number\"");#OtherTok(" min");#OperatorTok("=");#StringTok("\"16\"");#OtherTok(" max");#OperatorTok("=");#StringTok("\"99\"");#DataTypeTok(">");],
[#NormalTok("  ");#DataTypeTok("<");#KeywordTok("select");#OtherTok(" name");#OperatorTok("=");#StringTok("\"carrera\"");#DataTypeTok("><");#KeywordTok("option");#OtherTok(" value");#OperatorTok("=");#StringTok("\"SOF\"");#DataTypeTok(">");#NormalTok("Software");#DataTypeTok("</");#KeywordTok("option");#DataTypeTok("><");#KeywordTok("option");#OtherTok(" value");#OperatorTok("=");#StringTok("\"SIS\"");#DataTypeTok(">");#NormalTok("Sistemas");#DataTypeTok("</");#KeywordTok("option");#DataTypeTok("></");#KeywordTok("select");#DataTypeTok(">");],
[#NormalTok("  ");#DataTypeTok("<");#KeywordTok("label");#DataTypeTok("><");#KeywordTok("input");#OtherTok(" name");#OperatorTok("=");#StringTok("\"intereses[]\"");#OtherTok(" type");#OperatorTok("=");#StringTok("\"checkbox\"");#OtherTok(" value");#OperatorTok("=");#StringTok("\"web\"");#DataTypeTok(">");#NormalTok("Web");#DataTypeTok("</");#KeywordTok("label");#DataTypeTok(">");],
[#NormalTok("  ");#DataTypeTok("<");#KeywordTok("button");#DataTypeTok(">");#NormalTok("Registrar");#DataTypeTok("</");#KeywordTok("button");#DataTypeTok(">");],
[#DataTypeTok("</");#KeywordTok("form");#DataTypeTok(">");],));
#strong[Predicción:] el navegador impedirá normalmente enviar nombre o correo vacíos, pero un POST construido fuera del formulario puede no respetar esas reglas. #strong[Comprobación en la práctica:] PHP y C\# vuelven a validar en el servidor; una entrada inválida responde #NormalTok("422"); y no crea un registro.

PHP usa #NormalTok("intereses[]"); para que las casillas se reciban como arreglo. La vista Razor usa varias casillas con el mismo #NormalTok("name=\"Intereses\"");\; el #emph[model binder] recibe los valores repetidos como #NormalTok("string[]");. En ambos casos la lista permitida es #NormalTok("web");, #NormalTok("movil"); y #NormalTok("datos");\; ninguna casilla es obligatoria.

== GET y POST expresan intenciones distintas
<s2c2-get-post>
GET pone parámetros en la URL, por ejemplo #NormalTok("?q=ana");, y sirve para consultar, buscar o filtrar. Esa URL se puede copiar, marcar o compartir cuando sus datos no son sensibles. POST transporta campos en el cuerpo de la petición y se usa para crear, modificar o eliminar. Que POST no aparezca en la barra de direcciones no significa que esté cifrado: la confidencialidad de datos reales depende de HTTPS.

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Decisión], [GET], [POST],),
  table.hline(),
  [Ubicación], [URL y cadena de consulta], [cuerpo HTTP],
  [Intención de esta práctica], [buscar], [registrar],
  [Resultado compartible], [sí, si no contiene información sensible], [no como enlace de consulta],
  [Cifrado], [necesita HTTPS], [también necesita HTTPS],
)
No uses #NormalTok("$_REQUEST"); para decidir de dónde vino un dato: combina GET, POST y cookies, por lo que oculta una decisión importante. PHP separa #NormalTok("$_GET");, #NormalTok("$_POST");, #NormalTok("$_FILES"); y #NormalTok("$_SERVER");. La aplicación C\# expresa la misma separación con una acción GET para buscar y parámetros #NormalTok("[FromForm]"); en las acciones POST.

#Skylighting(([#VariableTok("$consulta");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#VariableTok("$_GET");#NormalTok("[");#StringTok("'q'");#NormalTok("] ");#OperatorTok("??");#NormalTok(" ");#StringTok("''");#OtherTok(";");],
[#ControlFlowTok("if");#NormalTok(" (");#VariableTok("$_SERVER");#NormalTok("[");#StringTok("'REQUEST_METHOD'");#NormalTok("] ");#OperatorTok("!==");#NormalTok(" ");#StringTok("'POST'");#NormalTok(") {");],
[#NormalTok("    ");#FunctionTok("http_response_code");#NormalTok("(");#DecValTok("405");#NormalTok(")");#OtherTok(";");],
[#NormalTok("    ");#ControlFlowTok("exit");#NormalTok("(");#StringTok("'Acceso no válido'");#NormalTok(")");#OtherTok(";");],
[#NormalTok("}");],));
#strong[Predicción:] #NormalTok("semana2.php?q=ana"); solo filtra lo que ya está en la sesión. #strong[Observación prevista:] después de registrar a #NormalTok("ana@example.test");, buscar #NormalTok("ana88@example.test"); mantiene el total de clientes aunque no muestre resultados. El total responde "¿cuántos hay?"; "sin coincidencias" responde otra pregunta.

== Leer, normalizar y validar
<s2c2-validacion>
Un campo HTTP puede tener una forma inesperada: por ejemplo, #NormalTok("nombre[]"); puede llegar como arreglo en vez de texto. Por eso la práctica PHP comprueba primero que #NormalTok("nombre");, #NormalTok("correo");, #NormalTok("edad"); y #NormalTok("carrera"); sean cadenas y solo después aplica #NormalTok("trim");. En MVC, el #emph[binder] puede representar un valor vacío o espacios como #NormalTok("null");\; #NormalTok("Semana2Registro"); conserva esas propiedades como #NormalTok("string?"); y el controlador normaliza antes de comprobar las reglas.

La normalización no es validación. #NormalTok("trim"); quita espacios de borde; no confirma que el nombre sea aceptable. Las reglas del ejercicio son nombre de 1 a 80 caracteres, correo válido, edad opcional pero entre 16 y 99, carrera #NormalTok("SOF"); o #NormalTok("SIS");, e intereses de la lista.

Este fragmento se aplica #strong[después] de comprobar que esos campos son cadenas; #NormalTok("$entrada"); representa el arreglo de formulario ya recibido. Contar caracteres Unicode no equivale a contar bytes con #NormalTok("strlen");.

#Skylighting(([#VariableTok("$nombre");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#FunctionTok("trim");#NormalTok("(");#VariableTok("$entrada");#NormalTok("[");#StringTok("'nombre'");#NormalTok("] ");#OperatorTok("??");#NormalTok(" ");#StringTok("''");#NormalTok(")");#OtherTok(";");],
[#VariableTok("$longitud");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#FunctionTok("preg_match_all");#NormalTok("(");#StringTok("'/./us'");#OtherTok(",");#NormalTok(" ");#VariableTok("$nombre");#NormalTok(")");#OtherTok(";");],
[#ControlFlowTok("if");#NormalTok(" (");#VariableTok("$longitud");#NormalTok(" ");#OperatorTok("===");#NormalTok(" ");#KeywordTok("false");#NormalTok(" ");#OperatorTok("||");#NormalTok(" ");#VariableTok("$longitud");#NormalTok(" ");#OperatorTok("<");#NormalTok(" ");#DecValTok("1");#NormalTok(" ");#OperatorTok("||");#NormalTok(" ");#VariableTok("$longitud");#NormalTok(" ");#OperatorTok(">");#NormalTok(" ");#DecValTok("80");#NormalTok(") {");],
[#NormalTok("    ");#VariableTok("$errores");#NormalTok("[");#StringTok("'nombre'");#NormalTok("] ");#OperatorTok("=");#NormalTok(" ");#StringTok("'El nombre es obligatorio (máximo 80 caracteres).'");#OtherTok(";");],
[#NormalTok("}");],
[#ControlFlowTok("if");#NormalTok(" (");#FunctionTok("filter_var");#NormalTok("(");#FunctionTok("trim");#NormalTok("(");#VariableTok("$entrada");#NormalTok("[");#StringTok("'correo'");#NormalTok("] ");#OperatorTok("??");#NormalTok(" ");#StringTok("''");#NormalTok(")");#OtherTok(",");#NormalTok(" ");#ConstantTok("FILTER_VALIDATE_EMAIL");#NormalTok(") ");#OperatorTok("===");#NormalTok(" ");#KeywordTok("false");#NormalTok(") {");],
[#NormalTok("    ");#VariableTok("$errores");#NormalTok("[");#StringTok("'correo'");#NormalTok("] ");#OperatorTok("=");#NormalTok(" ");#StringTok("'Ingrese un correo válido.'");#OtherTok(";");],
[#NormalTok("}");],));
El material de clase puede mostrar #NormalTok("filter_input(INPUT_POST, ...)");. La fuente de esta práctica valida el arreglo ya recibido con #NormalTok("filter_var");, tras verificar su forma; para un correo escalar ambos aplican la misma regla de validación, pero #NormalTok("filter_var"); permite conservar y revisar la entrada normalizada. No conviertas esa equivalencia de regla en una afirmación de que las dos funciones tienen idéntico contexto o comportamiento para toda entrada @php-manual.

#Skylighting(([#NormalTok("registro");#OperatorTok(".");#FunctionTok("Nombre");#NormalTok(" ");#OperatorTok("=");#NormalTok(" ");#OperatorTok("(");#NormalTok("registro");#OperatorTok(".");#FunctionTok("Nombre");#NormalTok(" ");#OperatorTok("??");#NormalTok(" ");#DataTypeTok("string");#OperatorTok(".");#FunctionTok("Empty");#OperatorTok(").");#FunctionTok("Trim");#OperatorTok("();");],
[#KeywordTok("if");#NormalTok(" ");#OperatorTok("(");#NormalTok("registro");#OperatorTok(".");#FunctionTok("Nombre");#OperatorTok(".");#FunctionTok("Length");#NormalTok(" ");#KeywordTok("is");#NormalTok(" ");#OperatorTok("<");#NormalTok(" ");#DecValTok("1");#NormalTok(" or ");#OperatorTok(">");#NormalTok(" ");#DecValTok("80");#OperatorTok(")");],
[#NormalTok("    ModelState");#OperatorTok(".");#FunctionTok("AddModelError");#OperatorTok("(");#FunctionTok("nameof");#OperatorTok("(");#NormalTok("registro");#OperatorTok(".");#FunctionTok("Nombre");#OperatorTok("),");],
[#NormalTok("        ");#StringTok("\"El nombre es obligatorio (máximo 80 caracteres).\"");#OperatorTok(");");],
[#KeywordTok("if");#NormalTok(" ");#OperatorTok("(");#NormalTok("Request");#OperatorTok(".");#FunctionTok("Form");#OperatorTok("[");#StringTok("\"Nombre\"");#OperatorTok("].");#FunctionTok("Count");#NormalTok(" ");#OperatorTok("!=");#NormalTok(" ");#DecValTok("1");#OperatorTok(")");],
[#NormalTok("    ModelState");#OperatorTok(".");#FunctionTok("AddModelError");#OperatorTok("(");#StringTok("\"Nombre\"");#OperatorTok(",");#NormalTok(" ");#StringTok("\"El campo debe ser texto.\"");#OperatorTok(");");],));
Este fragmento resume el comportamiento real de #NormalTok("Semana2Controller");: la comprobación de forma evita tratar una colección como texto; el modelo #NormalTok("Semana2Registro"); mantiene #NormalTok("Edad"); como texto para poder devolver un valor incorrecto a la persona que debe corregirlo.

Al mostrar datos, PHP usa #NormalTok("htmlspecialchars"); con #NormalTok("ENT_QUOTES"); y Razor codifica texto de forma predeterminada. Escapar protege la salida HTML; no cambia el valor almacenado ni reemplaza la validación de entrada.

== Dos destinos POST y respuestas HTTP
<s2c2-rutas-respuestas>
La práctica ofrece dos variantes deliberadas. "Enviar a otro archivo" usa #NormalTok("POST /semana2-registro.php");, que delega en el manejador de PHP, y #NormalTok("POST /Semana2/Registrar"); en MVC. "Procesar en esta página" usa #NormalTok("POST /semana2.php"); o #NormalTok("POST /Semana2");. Ambas reutilizan la misma validación y ambas distinguen los siguientes casos:

#table(
  columns: (27.27%, 36.36%, 36.36%),
  align: (auto,right,right,),
  table.header([Caso], [PHP], [ASP.NET Core MVC],),
  table.hline(),
  [formulario inválido], [#NormalTok("422");, valores retenidos, sin escritura], [#NormalTok("422");, #NormalTok("ModelState");, sin escritura],
  [token CSRF/antiforgery inválido], [#NormalTok("403");], [#NormalTok("400");],
  [método no admitido], [#NormalTok("405");], [#NormalTok("405");],
  [registro válido], [#NormalTok("303"); a GET], [#NormalTok("303"); a GET],
)
El token CSRF de PHP se guarda por sesión y se compara antes de validar. Las acciones C\# tienen #NormalTok("[ValidateAntiForgeryToken]");. Estos mecanismos reducen envíos forjados desde otro sitio; no sustituyen HTTPS.

Tras un POST válido, el patrón Post/Redirect/Get responde #NormalTok("303"); hacia la página GET y muestra una confirmación de una sola vez. #strong[Predicción:] recargar la GET no ejecuta nuevamente el POST. #strong[Observación prevista:] el contador permanece en 1 después de registrar una vez y recargar, en lugar de pasar a 2. PRG evita el reenvío accidental; no resuelve por sí solo simultaneidad, idempotencia de operaciones ni reglas de duplicados.

Los clientes se serializan en la sesión del navegador, no en SQL ni en las facturas del experimento independiente. Otra sesión inicia sin esos registros y cerrar o expirar la sesión puede eliminarlos.

== Pasos de práctica local
<s2c2-pasos-practica>
+ Desde la raíz del repositorio, ejecuta #NormalTok("php -S 127.0.0.1:8081 -t php/public"); y abre #link("http://127.0.0.1:8081/semana2.php").
+ Registra el dato ficticio #NormalTok("ana@example.test");, carrera #NormalTok("SOF");, intereses Web y Datos; predice el #NormalTok("303"); y verifica el mensaje en la GET posterior.
+ Busca #NormalTok("ana");\; después busca #NormalTok("ana88@example.test");. Distingue total almacenado de resultados visibles y observa que no hay una escritura GET.
+ Envía edad #NormalTok("15");, carrera distinta de #NormalTok("SOF");/#NormalTok("SIS"); o un correo inválido. Comprueba #NormalTok("422");, valores retenidos y contador sin cambio.
+ Para MVC, desde la raíz construye primero la imagen y luego inicia el modo sin base de datos. Si ya hay un servidor en #NormalTok("18083");, utiliza ese servidor o detené únicamente tu instancia anterior; no borres volúmenes.

#Skylighting(([#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml build app");],
[#ExtensionTok("docker");#NormalTok(" compose ");#AttributeTok("-f");#NormalTok(" csharp/compose.yaml run ");#AttributeTok("--rm");#NormalTok(" ");#AttributeTok("--no-deps");#NormalTok(" ");#DataTypeTok("\\\\");],
[#NormalTok("  ");#ExtensionTok("-e");#NormalTok(" PracticeOnly=true ");#AttributeTok("-p");#NormalTok(" 127.0.0.1:18083:8080 ");#DataTypeTok("\\\\");],
[#NormalTok("  ");#ExtensionTok("app");#NormalTok(" dotnet run ");#AttributeTok("--no-launch-profile");],));
#block[
#set enum(numbering: "1.", start: 6)
+ Abre #link("http://127.0.0.1:18083/Semana2") y repite la comparación entre la ruta separada #NormalTok("/Semana2/Registrar"); y el POST autoprocesado #NormalTok("/Semana2");. #NormalTok("PracticeOnly=true"); es el modo aislado de esta práctica: evita la migración inicial de facturas, no convierte el ejercicio en una prueba de SQL.
]

Consulta primero #link(<semana2-clase1-tipos-cliente>)[tipos, conversiones y Cliente] y usa la navegación de #link(<aplicaciones-web>)[Aplicaciones Web] para volver al mapa de la asignatura.

== Ejercicios
<s2c2-ejercicios>
=== Ejercicio 1: contrato del formulario
<s2c2-ej-1>
¿Por qué #NormalTok("required"); no basta para aceptar un correo y qué papel cumple #NormalTok("name");?

=== Ejercicio 2: elegir método
<s2c2-ej-2>
Elige GET o POST para buscar #NormalTok("ana"); y para registrar #NormalTok("ana@example.test");. Explica por qué POST no cifra el correo.

=== Ejercicio 3: múltiples intereses
<s2c2-ej-3>
Compara #NormalTok("intereses[]"); en PHP con varias casillas #NormalTok("name=\"Intereses\""); en Razor. ¿Qué validación se conserva en ambos lados?

=== Ejercicio 4: entrada manipulada
<s2c2-ej-4>
¿Qué debe pasar si #NormalTok("nombre"); llega como arreglo o si la edad es #NormalTok("100");? Incluye estado, datos retenidos y efecto sobre el contador.

=== Ejercicio 5: PRG y alcance
<s2c2-ej-5>
¿Por qué la redirección #NormalTok("303"); ayuda al recargar, y qué problema no resuelve? ¿Dónde viven los registros de esta práctica?

== Respuestas razonadas
<s2c2-respuestas>
=== Respuesta 1
<s2c2-r-1>
#link(<s2c2-ej-1>)[Volver al ejercicio]. El navegador puede omitir o manipular sus controles, así que el servidor valida el correo. #NormalTok("name"); fija la clave con la que la solicitud entrega el valor; sin esa clave el control no participa como dato nombrado del formulario.

=== Respuesta 2
<s2c2-r-2>
#link(<s2c2-ej-2>)[Volver al ejercicio]. La búsqueda es GET porque consulta y puede ser una URL compartible; el registro es POST porque cambia la colección de la sesión. POST solo mueve el dato fuera de la URL: HTTPS protege su tránsito.

=== Respuesta 3
<s2c2-r-3>
#link(<s2c2-ej-3>)[Volver al ejercicio]. PHP agrupa con #NormalTok("[]");\; MVC agrupa por el mismo nombre repetido. Los dos resultados deben ser colecciones cuyos elementos estén entre #NormalTok("web");, #NormalTok("movil"); y #NormalTok("datos");\; el servidor no acepta una clave o valor alterado.

=== Respuesta 4
<s2c2-r-4>
#link(<s2c2-ej-4>)[Volver al ejercicio]. La forma arreglo se rechaza antes de hacer #NormalTok("trim");\; #NormalTok("100"); incumple el rango. La práctica devuelve #NormalTok("422");, conserva valores para corregir y no agrega un cliente, así que el contador no aumenta.

=== Respuesta 5
<s2c2-r-5>
#link(<s2c2-ej-5>)[Volver al ejercicio]. Tras guardar, #NormalTok("303"); lleva a GET: actualizar esa página no repite el cuerpo POST. No garantiza idempotencia ni coordina dos envíos simultáneos. Los registros viven solo en la sesión de ese navegador, no en MySQL ni en las facturas @aspnet-mvc.

= Tablas de consulta HTTP
<tablas-de-consulta-http>
Usa estas tablas al estudiar el ciclo petición/respuesta y al inspeccionar #strong[Network (Red)] del navegador. Son una referencia técnica de apoyo, no una nueva semana del temario. Las rutas de productos son ejemplos didácticos: no son servicios del repositorio.

== Métodos: qué le pides al servidor
<métodos-qué-le-pides-al-servidor>
El #strong[método] expresa la intención de la petición. La #strong[ruta] identifica el recurso; la API define sus reglas y los formatos que acepta.

#block[
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Método], [Qué significa], [Ejemplo de petición],),
  table.hline(),
  [#NormalTok("GET");], [Obtener una representación del recurso, sin solicitar su modificación.], [#NormalTok("GET /productos");],
  [#NormalTok("POST");], [Pedir que el recurso procese los datos enviados; puede crear otro recurso o ejecutar una operación definida por la API.], [#NormalTok("POST /productos");],
  [#NormalTok("PUT");], [Crear o reemplazar el estado del recurso identificado mediante la representación enviada. No equivale a cambiar solo un campo.], [#NormalTok("PUT /productos/42");],
  [#NormalTok("PATCH");], [Aplicar cambios parciales según un formato de parche y las reglas de la API.], [#NormalTok("PATCH /productos/42");],
  [#NormalTok("DELETE");], [Solicitar que se retire la asociación entre la URL y el recurso. No garantiza borrado físico inmediato de archivos o registros.], [#NormalTok("DELETE /productos/42");],
  [#NormalTok("HEAD");], [Pedir las cabeceras que corresponderían a #NormalTok("GET");, pero sin cuerpo de respuesta.], [#NormalTok("HEAD /productos/42");],
  [#NormalTok("OPTIONS");], [Consultar opciones de comunicación del destino. También se utiliza en las comprobaciones previas de CORS.], [#NormalTok("OPTIONS /productos/42");],
)
]
#strong[PUT frente a PATCH.] Para un producto con nombre y precio, #NormalTok("PUT"); envía su representación de reemplazo conforme al contrato; un parche puede cambiar solo el precio. No basta con cambiar el verbo: el servidor debe implementar la operación y validar el formato. #NormalTok("POST"); no significa exclusivamente «crear».

== Seguridad semántica e idempotencia
<seguridad-semántica-e-idempotencia>
#strong[Seguro], en HTTP, significa que el cliente no solicita cambiar el estado del recurso; no significa que haya cifrado, autenticación o permisos. #strong[Idempotente] significa que repetir la misma petición tiene el mismo efecto pretendido sobre el servidor que enviarla una vez, no que devuelva siempre el mismo cuerpo o estado.

#block[
#table(
  columns: 3,
  align: (auto,auto,auto,),
  table.header([Método], [¿Seguro según HTTP?], [¿Idempotente por su semántica?],),
  table.hline(),
  [#NormalTok("GET");, #NormalTok("HEAD");, #NormalTok("OPTIONS");], [Sí], [Sí],
  [#NormalTok("PUT");, #NormalTok("DELETE");], [No], [Sí],
  [#NormalTok("POST");, #NormalTok("PATCH");], [No], [No está garantizado],
)
]
Por ejemplo, un primer #NormalTok("DELETE"); puede responder #NormalTok("204"); y el siguiente #NormalTok("404");: el recurso sigue ausente y la operación puede seguir siendo idempotente. Un #NormalTok("PATCH"); que fija un precio puede ser idempotente, pero uno que lo incrementa no lo es. No repitas automáticamente un #NormalTok("POST"); ante una duda: podría duplicar una operación. Practica modificaciones y borrados solo en un simulador local o con datos desechables.

== Dónde van los datos y dónde verlos
<dónde-van-los-datos-y-dónde-verlos>
#block[
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Dato], [Dónde buscar en DevTools], [Interpretación en PHP],),
  table.hline(),
  [Método y URL], [#strong[Headers → General]: Request Method y Request URL.], [#NormalTok("$_SERVER['REQUEST_METHOD']"); identifica el verbo.],
  [Query, como #NormalTok("?categoria=libros");], [URL y #strong[Payload → Query String Parameters], cuando aparezca esa sección.], [#NormalTok("$_GET"); contiene los parámetros de la URL, incluso si el método es #NormalTok("POST"); u otro.],
  [Formulario enviado por #NormalTok("POST");], [#strong[Payload → Form Data].], [#NormalTok("$_POST"); para los tipos de formulario que PHP procesa, no para cualquier cuerpo.],
  [JSON enviado por #NormalTok("POST");, #NormalTok("PUT"); o #NormalTok("PATCH");], [#strong[Payload], como contenido enviado; comprueba también #NormalTok("Content-Type");.], [Leer #NormalTok("php://input");, decodificar y validar el JSON según el contrato. No esperar que aparezca en #NormalTok("$_POST");.],
  [Cabeceras de la petición], [#strong[Headers → Request Headers].], [#NormalTok("Content-Type"); describe el formato enviado; #NormalTok("Accept");, el formato de respuesta preferido.],
  [Resultado del servidor], [Estado en #strong[Headers → General]\; contenido en #strong[Response].], [El programa emite un estado, cabeceras y, cuando corresponde, un cuerpo.],
)
]
La query puede acompañar distintos métodos: #strong[no es exclusiva de GET]. En #NormalTok("fetch()"); del navegador no envíes cuerpo con #NormalTok("GET"); ni #NormalTok("HEAD");. En #NormalTok("DELETE");, no supongas que un cuerpo tiene un significado estándar: sigue el contrato de la API. Los nombres y la organización de las pestañas pueden variar entre navegadores.

== Estados: qué respondió el servidor
<estados-qué-respondió-el-servidor>
Un método no es un estado: #NormalTok("POST"); describe lo solicitado; #NormalTok("201"); describe su resultado. Ningún verbo garantiza por sí solo un código de éxito.

#block[
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Estado], [Qué significa], [Qué comprobar],),
  table.hline(),
  [#NormalTok("200 OK");], [Petición atendida con éxito.], [Leer el contenido; no deducir que es JSON solo por el código.],
  [#NormalTok("201 Created");], [Se creó uno o más recursos.], [Revisar el recurso devuelto y #NormalTok("Location");, si se proporciona.],
  [#NormalTok("204 No Content");], [Éxito sin cuerpo de respuesta.], [No intentar interpretar un JSON que no existe.],
  [#NormalTok("400 Bad Request");], [El servidor considera incorrecta la petición.], [Sintaxis, parámetros y mensaje recibido.],
  [#NormalTok("401 Unauthorized");], [Faltan credenciales de autenticación válidas.], [No confundir autenticación con permisos.],
  [#NormalTok("403 Forbidden");], [El servidor entiende la petición, pero se niega a atenderla.], [Permisos y políticas; identificarse no garantiza acceso.],
  [#NormalTok("404 Not Found");], [No se encontró el recurso o el servidor no revela su existencia.], [URL e identificador; no implica por sí solo un fallo del programa.],
  [#NormalTok("405 Method Not Allowed");], [Ese recurso no admite el método solicitado.], [Cabecera #NormalTok("Allow"); y documentación de la ruta.],
  [#NormalTok("415 Unsupported Media Type");], [No se acepta el formato del contenido enviado.], [#NormalTok("Content-Type"); y formato del cuerpo.],
  [#NormalTok("500 Internal Server Error");], [Fallo interno al procesar la petición.], [Evidencia del servidor; no atribuirlo automáticamente al navegador.],
)
]
#strong[Lectura razonada.] Si ves #NormalTok("PATCH /productos/42"); con estado #NormalTok("415");, el verbo es #NormalTok("PATCH");, no #NormalTok("415");. Compara el formato de parche esperado con el #NormalTok("Content-Type"); y el cuerpo que realmente enviaste antes de cambiar la URL o repetir la petición. Si una respuesta #NormalTok("HEAD"); no muestra cuerpo, no lo trates como un error: es lo esperado.

== Fuentes de consulta
<fuentes-de-consulta>
Referencia técnica: #link("https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods")[MDN: métodos HTTP], #link("https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status")[MDN: estados HTTP], #link("https://www.rfc-editor.org/rfc/rfc9110.html")[HTTP Semantics, RFC 9110] y #link("https://www.rfc-editor.org/rfc/rfc5789.html")[PATCH, RFC 5789]. Para entradas PHP, consulta el #link("https://www.php.net/manual/en/language.variables.external.php")[manual de variables externas]. Practica las cinco peticiones principales y su inspección real en #link("laboratorio-http-php.qmd")[Laboratorio PHP: cinco métodos en DevTools].

= Laboratorio PHP: cinco métodos en DevTools
<laboratorio-php-cinco-métodos-en-devtools>
Este laboratorio transversal permite observar peticiones reales a un servidor PHP local. Practicarás #NormalTok("GET");, #NormalTok("POST");, #NormalTok("PUT");, #NormalTok("PATCH"); y #NormalTok("DELETE"); sin base de datos ni persistencia: todos los datos son ficticios y #strong[DELETE solo simula] una eliminación.

== Ruta rápida
<ruta-rápida-1>
Necesitas PHP instalado. Desde la raíz del repositorio ejecuta:

#Skylighting(([#ExtensionTok("php");#NormalTok(" ");#AttributeTok("-S");#NormalTok(" 127.0.0.1:8088 ");#AttributeTok("-t");#NormalTok(" ebook/examples/http-methods ebook/examples/http-methods/router.php");],));
Después abre #link("http://127.0.0.1:8088/")[el laboratorio local]. La #link("../../examples/http-methods/README.md")[guía del ejemplo] conserva el mismo comando y sirve como referencia descargable del código fuente.

#block[
#callout(
body: 
[
Usa exactamente #NormalTok("127.0.0.1");, el document root aislado #NormalTok("ebook/examples/http-methods"); y #NormalTok("router.php");, que limita las rutas públicas. No omitas el router, no uses #NormalTok("0.0.0.0"); ni sirvas la raíz del repositorio: podrías exponer otros archivos. El ejemplo requiere PHP local; no funciona con #NormalTok("file://"); ni ejecutado desde GitHub Pages.

]
, 
title: 
[
Advertencia
]
, 
background_color: 
rgb("#fcefdc")
, 
icon_color: 
rgb("#EB9113")
, 
icon: 
fa-exclamation-triangle()
, 
body_background_color: 
white
)
]
== Abrir y preparar Network
<abrir-y-preparar-network>
+ Abre DevTools con #NormalTok("F12");, #NormalTok("Ctrl+Shift+I"); o el menú del navegador.
+ Selecciona #strong[Network] o #strong[Red]. Si no aparece, búscala en #NormalTok("»");.
+ Filtra por #NormalTok("api.php");. Activa #strong[Preserve log / Conservar registro] si quieres mantener las cinco filas.
+ Pulsa un botón del laboratorio y selecciona la nueva fila.
+ Revisa #strong[Headers], #strong[Payload] y #strong[Response]. Los nombres pueden variar ligeramente según la versión o el idioma del navegador.

En #strong[Headers → General] identifica siempre #strong[Request URL], #strong[Request Method] y #strong[Status Code]. Luego relaciona lo observado con la fuente que PHP leyó y con el JSON de respuesta.

== GET: parámetros en la URL
<get-parámetros-en-la-url>
Pulsa #strong[GET con query]. En la URL aparecen #NormalTok("tema=red"); y #NormalTok("nivel=basico");\; DevTools también puede mostrarlos como #strong[Query String Parameters]. PHP los recibe en #NormalTok("$_GET");.

#figure([
#box(image("subjects/aplicaciones-web/../../assets/http-lab-get.png", alt: "DevTools Network unido al laboratorio PHP real: la fila GET seleccionada muestra Request URL, Request Method GET, Status Code 200 y la dirección loopback.", width: 100%))
], caption: figure.caption(
position: bottom, 
[
DevTools Network unido al laboratorio PHP real: la fila GET seleccionada muestra Request URL, Request Method GET, Status Code 200 y la dirección loopback.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-http-lab-get>


== POST: formulario
<post-formulario>
Pulsa #strong[POST formulario] y abre #strong[Payload]. El navegador envía #NormalTok("application/x-www-form-urlencoded");\; por eso DevTools presenta #strong[Form data] y PHP llena #NormalTok("$_POST");. La query, si existiera, seguiría perteneciendo a #NormalTok("$_GET");.

#figure([
#box(image("subjects/aplicaciones-web/../../assets/http-lab-post.png", alt: "DevTools Network unido al laboratorio PHP real: Payload de POST muestra Form data con nombre Ada y curso Web.", width: 100%))
], caption: figure.caption(
position: bottom, 
[
DevTools Network unido al laboratorio PHP real: Payload de POST muestra Form data con nombre Ada y curso Web.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-http-lab-post>


== PUT: cuerpo JSON completo de ejemplo
<put-cuerpo-json-completo-de-ejemplo>
Pulsa #strong[PUT JSON]. DevTools muestra el #strong[Request payload] #NormalTok("{id: 42, nombre: \"Libro\"}");. PHP no coloca este JSON en #NormalTok("$_POST");: el endpoint lee #NormalTok("php://input"); y luego usa #NormalTok("json_decode");.

#figure([
#box(image("subjects/aplicaciones-web/../../assets/http-lab-put.png", alt: "DevTools Network unido al laboratorio PHP real: Payload de PUT muestra el JSON con id 42 y nombre Libro.", width: 100%))
], caption: figure.caption(
position: bottom, 
[
DevTools Network unido al laboratorio PHP real: Payload de PUT muestra el JSON con id 42 y nombre Libro.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-http-lab-put>


== PATCH: cambio parcial
<patch-cambio-parcial>
Pulsa #strong[PATCH JSON]. El cuerpo contiene solo el identificador y el precio de ejemplo. En #strong[Response], PHP confirma el método, la fuente #NormalTok("php://input + json_decode");, los datos recibidos y #NormalTok("saved: false");: observar una respuesta correcta no implica que se haya guardado algo.

#figure([
#box(image("subjects/aplicaciones-web/../../assets/http-lab-patch.png", alt: "DevTools Network unido al laboratorio PHP real: Response de PATCH muestra method PATCH, el origen php input más json decode, precio 19.9 y saved false.", width: 100%))
], caption: figure.caption(
position: bottom, 
[
DevTools Network unido al laboratorio PHP real: Response de PATCH muestra method PATCH, el origen php input más json decode, precio 19.9 y saved false.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-http-lab-patch>


== DELETE: simulación explícita
<delete-simulación-explícita>
Pulsa #strong[DELETE simulado]. El identificador viaja como query y PHP lo obtiene de #NormalTok("$_GET");. La respuesta dice #NormalTok("saved: false"); y #NormalTok("simulation: \"No se eliminó ningún dato.\"");\; no existe archivo, registro o contador que borrar.

#figure([
#box(image("subjects/aplicaciones-web/../../assets/http-lab-delete.png", alt: "DevTools Network unido al laboratorio PHP real: Response de DELETE muestra method DELETE, id 42, saved false y el mensaje de simulación sin eliminación.", width: 100%))
], caption: figure.caption(
position: bottom, 
[
DevTools Network unido al laboratorio PHP real: Response de DELETE muestra method DELETE, id 42, saved false y el mensaje de simulación sin eliminación.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)
<fig-http-lab-delete>


== Qué debes poder explicar
<qué-debes-poder-explicar>
#table(
  columns: (50%, 50%),
  align: (auto,auto,),
  table.header([Observación], [Lectura razonada],),
  table.hline(),
  [URL, método y estado], [Identifican el destino, la intención de la petición y el resultado HTTP.],
  [Query String Parameters], [Se originan en la URL y llegan a #NormalTok("$_GET");, no solo cuando el método es GET.],
  [Form data de POST], [PHP lo procesa en #NormalTok("$_POST"); para el tipo de formulario usado.],
  [Request payload JSON], [PHP debe leer #NormalTok("php://input");, decodificar y validar el formato.],
  [Response], [Es el cuerpo que emitió PHP; aquí refleja entradas ficticias sin guardarlas.],
)
Detén el servidor con #NormalTok("Ctrl+C"); al terminar. Para recordar significados, idempotencia y estados, vuelve a #link(<tablas-de-consulta-http>)[Tablas de consulta HTTP].

= Respuestas de autoevaluación
<respuestas-autoevaluacion>
Estas respuestas muestran una forma de razonar. Compáralas con tus notas después de contestar las preguntas de #link(<autoevaluacion-semana1>)[auto evaluación de Semana 1]. No asignan puntos, no guardan progreso y no certifican una evaluación.

Para Semana 2, las soluciones están al final de cada clase: #link(<s2c1-respuestas>)[tipos y Cliente] y #link(<s2c2-respuestas>)[formularios GET/POST].

== P1: historia y propósito
<p1-respuesta>
Una página estática entrega contenido ya preparado. Una dinámica puede construir parte de la respuesta con datos de la solicitud, por ejemplo una operación seleccionada. Para hablar de la evolución de PHP verificaría la versión y sus cambios en las notas de publicación oficiales, no en un recuerdo o tutorial sin fecha. #link(<p1>)[Volver a P1]

== P2: HTTP
<p2-respuesta>
La solicitud es lo que el navegador envía al servidor, incluidos los datos que la calculadora necesita. El procesamiento aplica una regla a esos datos. La respuesta es lo que el servidor devuelve para que el navegador lo muestre. No es necesario confundir una solicitud HTTP con el HTML que finalmente se ve. #link(<p2>)[Volver a P2]

== P3: tipos
<p3-respuesta>
En PHP, #NormalTok("\"8\" + \"2\""); produce el entero #NormalTok("10");: el operador #NormalTok("+"); suma y convierte estas dos cadenas numéricas enteras a #NormalTok("int");. En C\#, #NormalTok("8 + 2"); también produce el entero #NormalTok("10");, pero los operandos ya son #NormalTok("int");. En estos casos coincide el resultado; difieren los tipos de entrada y la conversión que realiza PHP. No lo confundas con la concatenación: en C\#, #NormalTok("\"8\" + \"2\""); produce #NormalTok("\"82\"");. Identifica los tipos antes de comparar expresiones @php-manual@microsoft-csharp. #link(<p3>)[Volver a P3]

== P4: interpolación
<p4-respuesta>
Los dos fragmentos pretenden producir "Ana tiene 2 intentos.". En PHP las variables aparecen como #NormalTok("$nombre"); y #NormalTok("$intentos"); dentro de comillas dobles. En C\#, el prefijo #NormalTok("$"); se aplica a la cadena y las expresiones van entre llaves. Una salida semejante no significa que la sintaxis sea idéntica. #link(<p4>)[Volver a P4]

== P5: constantes
<p5-respuesta>
Elegiría una constante para una regla que el programa no debe reasignar, como una tasa de ejemplo durante esa ejecución. Elegiría una variable para una entrada que cambia, como #NormalTok("base"); o #NormalTok("baseImponible");. La elección debe explicar el rol del dato; no es una decoración del código. #link(<p5>)[Volver a P5]

== P6: alcance
<p6-respuesta>
Un parámetro aparece en la firma de la función y en cada llamada, por lo que el lector puede reconocer de dónde llega el dato. #NormalTok("global"); depende de un nombre externo y oculta esa relación. Pasar parámetros no resuelve todos los diseños, pero es una opción clara para el ejemplo de Semana 1. #link(<p6>)[Volver a P6]

== P7: depuración
<p7-respuesta>
Anotaría (1) los valores y tipos que llegaron, incluido el divisor #NormalTok("0");\; (2) el operador y la rama de procesamiento que se ejecutó; y (3) el resultado o aviso exacto mostrado. Con esas observaciones puedo formular una hipótesis sin atribuir el problema automáticamente al navegador, PHP o C\#. #link(<p7>)[Volver a P7]

== P8: comprobación
<p8-respuesta>
Una tabla suficiente tiene columnas para entrada A, operación, entrada B, predicción, resultado observado y explicación. Incluye #NormalTok("8+2");, #NormalTok("8-2");, #NormalTok("8*2");, #NormalTok("8/2");, un divisor #NormalTok("0"); y una entrada no numérica. Las últimas filas documentan el comportamiento declarado: no exigen construir aquí un sistema nuevo de validación. #link(<p8>)[Volver a P8]

== P9: MVC
<p9-respuesta>
Afirma que MVC es la forma elegida para organizar las prácticas web que lo usan. No afirma que todos los archivos existentes ya estén separados en modelo, vista y controlador. El #NormalTok("php/public/home.php"); de facturas sigue siendo monolítico y este libro no lo modifica; además, las facturas son un experimento adicional y no una prueba de requisito de Semana 1. #link(<p9>)[Volver a P9]

== P10: transferencia
<p10-respuesta>
Para Celsius a Fahrenheit, la entrada es una temperatura Celsius, el procesamiento puede ser #NormalTok("C * 9 / 5 + 32");, y la salida es la temperatura convertida con su unidad. En PHP predeciría que una entrada numérica concreta, por ejemplo #NormalTok("0");, produce #NormalTok("32");\; en C\# haría la misma predicción antes de correr un fragmento con un tipo numérico apropiado. La comprobación compara la regla y el valor observado, no solo que el programa compile. #link(<p10>)[Volver a P10]

== Cómo usar una discrepancia
<cómo-usar-una-discrepancia>
Si tu respuesta no coincide, vuelve a la pregunta enlazada, localiza qué suposición hiciste sobre entrada, tipo o alcance y prueba un caso pequeño. Consultar una pista o estas soluciones puede orientar la siguiente prueba, pero no es evidencia de que la hayas realizado.

#part[Diseño y Arquitectura de Software]
Esta asignatura incorpora las #strong[Semanas 1 y 2] a partir de contenidos oficiales verificados. El recorrido desarrolla explicaciones y casos originales para justificar decisiones de arquitectura y de proceso; no sustituye la clase, no resuelve tareas institucionales ni registra calificaciones @blackboard-arq-s1@blackboard-arq-s2.

#heading(level: 2, numbering: none)[Cobertura actual]
<cobertura-actual-1>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Semana], [Tema y propósito], [Lectura],),
  table.hline(),
  [1], [Del análisis a las decisiones de diseño y arquitectura], [#link("arquitectura-software/semana-01/01-diseno-arquitectura.qmd")[Diseño y arquitectura: de la necesidad a las decisiones]],
  [1], [Tipos, dominios de uso y mitos del software], [#link("arquitectura-software/semana-01/02-dominios-mitos.qmd")[Software: tipos, dominios y mitos]],
  [1], [Caso integrado, práctica y autoevaluación formativa], [#link("arquitectura-software/semana-01/03-practica-autoevaluacion.qmd")[Práctica integrada y autoevaluación]],
  [2], [Actividades generales, flujo, tareas y patrones reutilizables], [#link("arquitectura-software/semana-02/01-procesos-flujo.qmd")[Procesos de software: actividades, flujo y trabajo reutilizable]],
  [2], [Cascada, incremental, evolutivo y espiral; práctica y autoevaluación], [#link("arquitectura-software/semana-02/02-modelos-practica-autoevaluacion.qmd")[Modelos de proceso: comparación, práctica y autoevaluación]],
)
#heading(level: 2, numbering: none)[Alcance de la cobertura actual]
<alcance-de-la-cobertura-actual>
La Semana 1 conecta necesidades, atributos de calidad, módulos y estilos; también clasifica software y analiza mitos antes de una práctica integrada. La Semana 2 explica cómo requisitos, diseño, implementación, pruebas y mantenimiento pueden organizarse en distintos flujos. Después compara cascada, incremental, evolutivo y espiral según estabilidad, entregas, retroalimentación y riesgos, con un caso original de reservas de biblioteca y diez preguntas razonadas.

La cobertura de Semana 2 procede del documento HTML oficial verificado. El plan y otros archivos PDF quedaron sin cuerpo legible, por lo que no se afirma que estén cubiertas todas las fuentes, clases o evaluaciones de la semana. Todo el material es formativo para estudiar de manera autónoma, no una tarea nueva ni una calificación.

El enlace oficial también propone un #link("https://es.educaplay.com/recursos-educativos/31153075-introduccion_al_diseno_y_arquitectura_de_software.html")[ejercicio formativo en Educaplay]. Es un recurso para contrastar ideas: este cuaderno no afirma que se haya completado ni asigna una nota.

#heading(level: 2, numbering: none)[Ruta de estudio]
<ruta-de-estudio>
+ Formula una respuesta antes de abrir la retroalimentación.
+ Relaciona una necesidad concreta con una decisión y una comprobación observable.
+ Distingue el concepto técnico de su dominio de uso antes de clasificarlo.
+ Explica qué evidencia faltaría para sostener una conclusión arquitectónica.

La cobertura se ampliará únicamente cuando haya temas oficiales verificados. Las prácticas y sus respuestas de Arquitectura viven en las lecturas de cada semana; las respuestas de Aplicaciones Web siguen en su página propia.

= Diseño y arquitectura: de la necesidad a las decisiones
<diseño-y-arquitectura-de-la-necesidad-a-las-decisiones>
#strong[Meta.] Al terminar podrás pasar de una necesidad a una decisión de diseño, explicar por qué importa y proponer cómo observar su resultado. La arquitectura no empieza al dibujar cajas: empieza al hacer explícitas decisiones que condicionan cómo el sistema responderá a cambios y cualidades relevantes @blackboard-arq-s1.

== Objetivos de aprendizaje
<objetivos-de-aprendizaje>
- Distinguir análisis, diseño y arquitectura sin reducirlos a una escala de tamaño.
- Usar abstracción, modularidad, encapsulación, acoplamiento y cohesión al razonar.
- Reconocer vistas, relaciones, estilos y atributos de calidad iniciales.

#strong[Pregunta de recuperación.] Si dos módulos cambian juntos cada vez que cambia una regla, ¿qué hipótesis harías sobre su frontera y por qué?

== De entender la necesidad a decidir una forma
<de-entender-la-necesidad-a-decidir-una-forma>
El #strong[análisis] pregunta qué problema, actores, reglas y resultados importan: por ejemplo, una biblioteca necesita reservar ejemplares sin prometer dos veces el mismo libro. El #strong[diseño] decide cómo organizar una solución a ese problema. La #strong[arquitectura] reúne las decisiones de diseño de alto impacto ---componentes, interfaces, datos, despliegue y restricciones--- y su justificación.

Hay solapamiento: una decisión puede ser arquitectónica en un contexto y local en otro. No existe un corte correcto de «muchas líneas = arquitectura». Elegir una interfaz que consumen varios equipos suele tener más alcance que renombrar una función, aunque la primera sea breve. La pregunta útil es qué opciones habilita o cierra la decisión y quién deberá convivir con ella.

== Separar para comprender y cambiar
<separar-para-comprender-y-cambiar>
Una #strong[abstracción] conserva lo esencial y oculta detalle accidental: #NormalTok("Reserva"); representa una intención, no cada tabla de la base de datos. La #strong[modularidad] agrupa responsabilidades para que puedan comprenderse y modificarse con cierta independencia. La #strong[encapsulación] protege el estado y las reglas detrás de una interfaz; no es solo declarar campos privados.

Dos medidas cualitativas orientan la conversación. El #strong[acoplamiento] es cuánto necesita saber o depender una parte de otra: se prefiere bajo cuando evita cambios en cascada. La #strong[cohesión] expresa cuán relacionadas están las tareas dentro de un módulo: se prefiere alta cuando una razón clara explica por qué viven juntas. Son objetivos de diseño, no números mágicos. La ocultación de decisiones propensas a cambiar es una razón histórica para fijarse en esas fronteras @parnas1972.

El diseño #strong[estructurado] suele descomponer por procesos y transformaciones de datos; el #strong[orientado a objetos] organiza colaboraciones entre objetos con estado y comportamiento. Ninguno anula el otro: un sistema OO también tiene flujos y datos, y uno estructurado puede tener módulos bien delimitados. Se elige la representación que hace más visible el problema.

== Vistas que responden preguntas distintas
<vistas-que-responden-preguntas-distintas>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Vista], [Pregunta que aclara], [Ejemplo en reservas],),
  table.hline(),
  [Conceptual], [¿Qué conceptos y reglas existen?], [ejemplar, persona, reserva y disponibilidad],
  [Lógica], [¿Qué componentes colaboran?], [catálogo, reservas y notificaciones],
  [Física], [¿Dónde se ejecutan y guardan?], [navegador, servicio y base de datos],
)
Un diagrama de #strong[casos de uso] sitúa a la persona usuaria y metas como «reservar»; un diagrama de #strong[clases] propone conceptos, atributos y relaciones; uno de #strong[secuencia] muestra mensajes en un escenario. Son notaciones para comunicar, no una garantía de que el diseño sea bueno. Un patrón nombra una solución recurrente con sus consecuencias; la documentación registra contexto, decisión, alternativas y razón para que no haya que adivinarla después.

#figure([
#box(image("subjects/arquitectura-software/semana-01/../../../assets/arquitectura-semana1.svg", alt: "Mapa conceptual accesible: una persona solicita una reserva; Reservas consulta la disponibilidad en Catálogo y devuelve confirmación o rechazo. Las interfaces conectan los módulos."))
], caption: figure.caption(
position: bottom, 
[
Mapa conceptual de una reserva: la persona solicita una reserva; el módulo Reservas consulta Catálogo y comunica el resultado.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


#emph[Nota.] El mapa es un esquema informal de responsabilidades e interfaces, no un diagrama UML formal.

== Caso guiado: reservar sin duplicar una promesa
<caso-guiado-reservar-sin-duplicar-una-promesa>
#strong[Necesidad de calidad.] Cuando dos personas intentan reservar el mismo ejemplar, el sistema debe evitar confirmar ambas reservas. La calidad aquí es consistencia de la operación y la confiabilidad de la información. No debe confundirse la disponibilidad de un ejemplar con la disponibilidad del servicio; no es un benchmark medido.

#strong[Decisión.] El módulo #NormalTok("Reservas"); expone #NormalTok("solicitar(ejemplar, persona)"); y delega a la interfaz #NormalTok("Disponibilidad"); una operación atómica de comprobar y marcar. El módulo #NormalTok("Notificaciones"); recibe solo el resultado final. Así la regla de no duplicación queda encapsulada, y la interfaz evita que una pantalla modifique el inventario por su cuenta.

#strong[Comprobación observable propuesta.] En una prueba controlada con dos solicitudes para el mismo ejemplar disponible, se espera una confirmación y un rechazo; el registro debe mostrar una sola reserva activa. Es un criterio hipotético para discutir la decisión, no una rúbrica docente ni una medición de rendimiento.

== Estilos y cualidades: opciones con consecuencias
<estilos-y-cualidades-opciones-con-consecuencias>
Cliente-servidor separa quien solicita de quien presta un servicio. Capas organizan, por ejemplo, presentación, reglas y persistencia. Un monolito puede mantener esos límites dentro de un único despliegue; microservicios los distribuyen entre servicios independientes. Se pueden combinar: un monolito por capas puede atender clientes, y un conjunto de servicios también puede usar capas. Microservicios no son un ascenso automático ni una cura para un diseño poco claro.

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Atributo], [Pregunta inicial], [Decisión que podría influir],),
  table.hline(),
  [Rendimiento], [¿cuánto tarda una reserva bajo una carga definida?], [consulta e índices adecuados],
  [Seguridad], [¿quién puede reservar o administrar?], [autorización en la interfaz],
  [Escalabilidad], [¿qué crece y cómo se distribuye?], [separar trabajo repetible si se justifica],
  [Disponibilidad], [¿qué ocurre si falla un componente?], [manejo explícito de fallos y degradación planificada],
  [Mantenibilidad y reutilización], [¿dónde cambia una regla?], [módulos cohesivos e interfaces estables],
)
No hay un estilo mejor sin contexto, restricciones y evidencia. Tampoco conviene partir en microservicios antes de conocer las fronteras, la operación y el coste de coordinar despliegues, fallos y datos.

== Ejercicio breve
<ejercicio-breve>
Una pantalla consulta directamente la base de datos y manda correos de confirmación. Propón una frontera de módulos y explica qué cambio quedaría más localizado.

#block[
#callout(
body: 
[
Una respuesta posible separa la pantalla, #NormalTok("Reservas"); y #NormalTok("Notificaciones");\; la pantalla pide la operación a una interfaz y no conoce la persistencia. Cambiar el proveedor de correo afectaría principalmente Notificaciones. La propuesta necesita validar qué reglas comparten realmente los casos de uso: separar por moda también puede añadir complejidad.

]
, 
title: 
[
Retroalimentación razonada
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Cierre
<cierre>
Diseñar no es dibujar por adelantado todo el sistema: es elegir representaciones y fronteras que permitan explicar una necesidad y comprobar sus consecuencias. La arquitectura hace visibles las decisiones de mayor alcance; la evolución posterior sigue siendo contextual, no una ley idéntica para todo programa @lehman1996.

#strong[Recuerdo rápido.] ¿Qué convertirías primero en una comprobación observable antes de afirmar que una decisión mejoró la calidad?

= Software: tipos, dominios y mitos
<software-tipos-dominios-y-mitos>
#strong[Meta.] Al terminar podrás clasificar un producto por la función técnica que cumple y por el dominio donde se usa, sin confundir herramientas con categorías. También podrás reemplazar afirmaciones absolutas por preguntas que guíen una acción responsable @blackboard-arq-s1.

== Objetivos de aprendizaje
<objetivos-de-aprendizaje-1>
- Distinguir tipos técnicos de software de sus dominios de aplicación.
- Explicar por qué lenguaje, intérprete, editor, framework y runtime no son sinónimos.
- Analizar los cuatro mitos de la semana mediante condiciones, consecuencias y acciones.

#strong[Pregunta de recuperación.] ¿Puede el mismo programa ser software de aplicación y pertenecer al dominio educativo? Justifica con dos criterios distintos.

== Dos ejes para no mezclar etiquetas
<dos-ejes-para-no-mezclar-etiquetas>
El #strong[tipo técnico] describe el papel que el software cumple dentro de un entorno. El #strong[dominio de uso] describe el problema humano, organizacional o físico al que se aplica. Un sistema puede tener varias piezas técnicas y servir a un dominio concreto; por eso «educativo» no compite con «de aplicación» como si fueran respuestas al mismo enunciado.

#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Tipo técnico], [Papel principal], [Ejemplo posible],),
  table.hline(),
  [De sistema], [Gestiona recursos o proporciona base para otros programas], [sistema operativo o controlador],
  [De aplicación], [Ayuda directamente a realizar una tarea de usuario], [portal para reservar libros],
  [De desarrollo], [Ayuda a crear, probar o entregar otros programas], [compilador o depurador],
)
Los dominios dan otro contexto: una aplicación de facturación pertenece al negocio; un aula virtual, a educación; un programa que procesa datos de un experimento, a la ciencia; y el firmware que controla un sensor, a un sistema embebido. Esta etiqueta no determina por sí sola el lenguaje ni la arquitectura.

== Una herramienta no cambia de categoría por su nombre
<una-herramienta-no-cambia-de-categoría-por-su-nombre>
Python es un #strong[lenguaje]: un conjunto de reglas para expresar programas. Un #strong[intérprete] de Python ejecuta o evalúa esos programas. Un editor ayuda a escribir archivos; un framework aporta convenciones y componentes para construir una clase de aplicación; un runtime ofrece el entorno de ejecución. Cumplen funciones distintas, aunque una distribución los presente juntos.

Por ello, Python, su intérprete y un editor no son tres «tipos principales» de software comparables. Un editor puede ser software de desarrollo; el intérprete puede formar parte de la plataforma que ejecuta un programa; un framework no define el dominio del producto. Preguntar «¿qué hace esta pieza para quién?» evita una clasificación por marcas.

== Clasificación trabajada
<clasificación-trabajada>
Considera una aplicación web donde estudiantes reservan salas de estudio. La interfaz que muestra horarios y confirma reservas es #strong[software de aplicación]: atiende una tarea de quienes usan la biblioteca. Su dominio es #strong[educativo], porque organiza un recurso de aprendizaje, aunque también tenga reglas administrativas. El sistema operativo del servidor que la sostiene gestiona recursos y es software de #strong[sistema]\; el editor y las pruebas automatizadas que usa el equipo son software de #strong[desarrollo].

Ahora cambia el dominio sin cambiar la tecnología: el mismo lenguaje Python, el mismo framework web y una base de datos pueden sostener reservas de equipos en un laboratorio científico. La aplicación sigue siendo de aplicación, pero el dominio prioritario pasa a ser #strong[científico]. La tecnología describe una elección de implementación; la finalidad y personas atendidas justifican el dominio.

== Cuatro mitos que ocultan condiciones
<cuatro-mitos-que-ocultan-condiciones>
=== «Agregar programadores tarde arregla el atraso»
<agregar-programadores-tarde-arregla-el-atraso>
Puede parecer razonable cuando hay tareas pendientes. Falla si quienes llegan deben aprender contexto, coordinarse y dividir un trabajo que no era divisible: al principio puede aumentar la comunicación y los errores. Un contraejemplo es una tarea aislada, bien especificada y con incorporación preparada, que sí puede repartir trabajo útil. La acción no es prohibir contratar: es revisar el cuello de botella, el tiempo de incorporación y qué entregable puede asumir cada persona.

=== «Si funciona, está terminado»
<si-funciona-está-terminado>
Una demostración que produce el resultado esperado aporta evidencia, pero no prueba seguridad, mantenibilidad, operación ni comprensión de los límites. Por ejemplo, una reserva puede funcionar hoy y carecer de control de acceso o de registro para atender un incidente. La acción es acordar qué significa terminado para ese contexto: pruebas pertinentes, revisión, documentación y condiciones de entrega, sin suponer una lista idéntica para todo producto.

=== «Cada cambio es fácil»
<cada-cambio-es-fácil>
Cambiar una línea puede ser sencillo; cambiar una regla compartida, una interfaz o un dato histórico puede afectar contratos y personas usuarias. El contraejemplo es un texto aislado con pruebas que confirma el cambio. Antes de estimar, se rastrean módulos, dependencias y datos; después se prueba el comportamiento afectado. El software puede evolucionar, pero no todo cambio tiene el mismo coste ni riesgo.

=== «No hace falta documentación»
<no-hace-falta-documentación>
El código muestra una implementación, no siempre por qué se eligió, qué alternativa se descartó o qué supuesto operativo sigue vigente. En un equipo pequeño y una corrección local, una explicación breve junto al cambio puede bastar; eso no elimina la necesidad de dejar decisiones relevantes recuperables. La acción es documentar lo que ayuda a operar, cambiar y revisar: propósito, interfaz, decisión y evidencia, manteniéndolo cercano a quien lo usa.

== Ejercicio breve
<ejercicio-breve-1>
Clasifica un programa que recoge lecturas de temperatura desde un sensor y envía una alarma a personal de mantenimiento. Indica tipo técnico, dominio y una pregunta que harías antes de decidir si es embebido.

#block[
#callout(
body: 
[
El programa que controla directamente el sensor puede ser software de sistema o embebido según su función y entorno; el dominio podría ser industrial o científico, según el propósito de las mediciones. Preguntaría si se ejecuta dentro de un dispositivo con recursos y responsabilidades específicas, en vez de etiquetarlo solo porque usa un sensor. La alarma puede ser otra aplicación conectada: clasificar sus piezas evita forzar una sola etiqueta al conjunto.

]
, 
title: 
[
Retroalimentación razonada
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Conclusión
<conclusión>
Clasificar con dos ejes da una explicación verificable: primero el papel técnico, después el dominio y la evidencia de su finalidad. Los mitos fallan porque borran condiciones; una decisión madura las vuelve preguntas sobre personas, dependencias, calidad y contexto. Esa conclusión permite actuar sin prometer que toda contratación, cambio o documentación tenga el mismo resultado.

#strong[Recuerdo rápido.] Ante «funciona, luego está terminado», ¿qué evidencia de calidad pedirías para este producto y por qué?

= Práctica integrada y autoevaluación de la Semana 1
<práctica-integrada-y-autoevaluación-de-la-semana-1>
#strong[Propósito.] Esta propuesta de estudio integra los conceptos de la Semana 1 para preparar una evaluación: no es una nueva tarea institucional ni un diseño de producción. Trabajarás sobre el caso ficticio de reservas de biblioteca ya usado en la teoría, con decisiones que puedes explicar y comprobar de forma observable.

== Ruta de trabajo
<ruta-de-trabajo>
+ Lee el caso y escribe una primera decisión antes de abrir una pista.
+ Compara tu explicación con el ejemplo parcial; no copies su forma sin revisar el contexto.
+ Resuelve el ejercicio análogo con tus propios supuestos y contrasta después la autoevaluación.

#block[
#callout(
body: 
[
No hay ejecución, nota ni evidencia de rendimiento que producir. Conserva una hoja con una necesidad, clasificaciones, una decisión justificada, un esquema de responsabilidades y un criterio observable. Diseños alternativos son válidos cuando mantienen las reglas y explican sus consecuencias.

]
, 
title: 
[
Qué se espera en esta práctica
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
== Caso guiado: una reserva sin promesas duplicadas
<caso-guiado-una-reserva-sin-promesas-duplicadas>
Una biblioteca permite que estudiantes soliciten un ejemplar. Dos solicitudes pueden llegar cuando queda una sola copia. El equipo quiere confirmar únicamente una reserva activa y avisar el resultado. La pantalla actual consulta los datos y envía correos por su cuenta.

=== 1. Del enunciado a la clasificación
<del-enunciado-a-la-clasificación>
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Pregunta], [Respuesta de trabajo], [Por qué importa],),
  table.hline(),
  [Necesidad], [No confirmar dos reservas activas para el mismo ejemplar.], [Hace explícita la regla antes de elegir tecnología.],
  [Tipo técnico], [La interfaz de reserva es software de aplicación.], [Ayuda directamente a una persona a completar una tarea.],
  [Dominio], [Educativo, pues organiza un recurso de aprendizaje.], [El dominio describe la finalidad, no el lenguaje usado.],
  [Función principal], [Registrar o rechazar una solicitud según disponibilidad.], [Separa el comportamiento esperado de la forma de implementarlo.],
)
El sistema operativo que sostiene el servidor es, sin ambigüedad, software de sistema: administra recursos y sirve de base a programas. Esa clasificación no convierte por sí sola a cada componente ni a todo gestor de datos en software de sistema. También conviene separar las herramientas: un lenguaje expresa el programa, un editor ayuda a escribirlo y el runtime proporciona condiciones de ejecución.

=== 2. Decisión de diseño y arquitectura
<decisión-de-diseño-y-arquitectura>
La decisión propuesta es concentrar la regla en un módulo #NormalTok("Reservas");. La pantalla pide #NormalTok("solicitar(ejemplar, persona)");\; #NormalTok("Reservas"); consulta una interfaz de #NormalTok("Disponibilidad"); que comprueba y marca la copia como una sola operación. Cuando hay resultado final, #NormalTok("Notificaciones"); comunica la confirmación o el rechazo.

Esta es una decisión de #strong[diseño] porque distribuye responsabilidades. Adquiere alcance #strong[arquitectónico] si esa interfaz y su regla condicionan varias pantallas, equipos o despliegues. En ambos casos el análisis la precede: identifica actores, regla y resultado sin decidir todavía tablas, servidores o lenguaje.

#block[
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Responsabilidad], [Interfaz o entrada], [Resultado que entrega],),
  table.hline(),
  [Pantalla], [datos de ejemplar y persona], [muestra un resultado, sin cambiar inventario],
  [#NormalTok("Reservas");], [#NormalTok("solicitar(ejemplar, persona)");], [confirmación o rechazo con motivo],
  [#NormalTok("Disponibilidad");], [comprobar y marcar], [una sola copia marcada o no disponible],
  [#NormalTok("Notificaciones");], [resultado final], [aviso preparado para la persona],
)
]
La separación reduce el acoplamiento: cambiar el medio de aviso no debe exigir que la pantalla conozca la regla de inventario. A la vez, #NormalTok("Reservas"); mantiene cohesión si sus tareas se relacionan con decidir una reserva, no con presentar pantallas o administrar correos. No se recomienda reintentar ciegamente una solicitud: repetir una operación no idempotente podría crear otra reserva. Ante un fallo se define qué resultado quedó registrado y cómo se consulta o resuelve antes de intentar de nuevo.

=== 3. Criterio de calidad y comprobación
<criterio-de-calidad-y-comprobación>
El criterio propuesto es #strong[consistencia] de la regla: ante dos solicitudes controladas para el mismo ejemplar disponible, se observa una confirmación, un rechazo y una sola reserva activa en el registro. Esto comprueba comportamiento funcional y consistencia de datos; no demuestra que el servicio esté disponible. La #strong[disponibilidad] pregunta, en cambio, si el servicio puede atender solicitudes cuando falla un componente o existe una interrupción. Son cualidades relacionadas, pero no intercambiables.

#block[
#callout(
body: 
[
#strong[Registro de decisión breve.] Contexto: queda un ejemplar y pueden coincidir dos solicitudes. Decisión: #NormalTok("Reservas"); usa una operación de disponibilidad que comprueba y marca de forma atómica. Alternativa descartada por ahora: dejar que cada pantalla actualice disponibilidad; duplica una regla crítica y aumenta el riesgo de cambios inconsistentes. Consecuencia: las pantallas dependen de una interfaz estable, pero el equipo debe definir el resultado de una solicitud interrumpida.

El ejemplo no decide si el sistema será monolito o microservicios. Un monolito por capas puede respetar estas fronteras; separar servicios solo sería razonable con una necesidad y costo de operación justificados.

]
, 
title: 
[
Ejemplo parcial trabajado
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 4. Mito que el caso ayuda a evitar
<mito-que-el-caso-ayuda-a-evitar>
Decir «si la demostración reserva un libro, está terminado» omite autorizaciones, registros, casos de concurrencia y condiciones de operación. La demostración aporta una señal, pero el criterio observable anterior agrega evidencia sobre una regla importante. No convierte la práctica en una garantía de seguridad, disponibilidad ni calidad total.

== Ejercicio análogo: préstamo de equipos
<ejercicio-análogo-préstamo-de-equipos>
Ahora una sala de innovación presta una cámara a estudiantes. Hay una cámara libre y dos solicitudes pueden coincidir. Propón una solución para estudiar; no implementes ni supongas que existe una plataforma institucional.

#block[
#callout(
body: 
[
Empieza por la regla que no debe romperse. Después nombra una responsabilidad que la proteja y una observación que podría refutar tu propuesta.

]
, 
title: 
[
Pista opcional
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
=== Entregables y criterios observables
<entregables-y-criterios-observables>
Entrega en tus apuntes los cinco elementos siguientes:

+ La necesidad en una oración y la clasificación por tipo técnico, dominio y función.
+ Una distinción entre lo que descubres en análisis y lo que decides en diseño o arquitectura.
+ Una tabla pequeña con al menos dos responsabilidades, una interfaz y sus resultados.
+ Un registro de decisión con contexto, alternativa considerada, consecuencia y un estilo compatible con su justificación; no existe un estilo universalmente mejor.
+ Un criterio de calidad y una comprobación observable que distinga consistencia de disponibilidad cuando corresponda.

Puedes elegir capas, cliente-servidor o un monolito con fronteras claras si explicas qué problema atiende. Un esquema cumple cuando permite reconocer quién protege la regla, qué recibe cada parte y qué observación esperas. No cumple solo por usar nombres técnicos ni por dibujar más cajas.

=== Lista de revisión sin puntaje
<lista-de-revisión-sin-puntaje>
- ☐ ¿Puedo señalar una regla del dominio sin nombrar una tecnología?
- ☐ ¿Distinguí la finalidad del producto de las herramientas para construirlo?
- ☐ ¿Mi interfaz evita que la pantalla cambie directamente el estado crítico?
- ☐ ¿Mi comprobación describe una entrada o condición y un resultado observable?
- ☐ ¿Expliqué una consecuencia o límite de mi decisión?
- ☐ ¿Sé qué concepto debo releer si no pude justificar una frontera?

Vuelve a #link(<diseño-y-arquitectura-de-la-necesidad-a-las-decisiones>)[necesidad, módulos y cualidades] para revisar análisis, interfaces, vistas y estilos; vuelve a #link(<software-tipos-dominios-y-mitos>)[tipos, dominios y mitos] para revisar clasificaciones y afirmaciones absolutas.

== Autoevaluación formativa
<autoevaluación-formativa-1>
Responde primero con tus palabras. Las preguntas son originales para el estudio de esta semana: no se copian de Educaplay ni representan calificación oficial.

=== 1. De necesidad a decisión
<de-necesidad-a-decisión>
Una coordinación pide «que las reservas sean claras». ¿Qué preguntas de análisis harías antes de decidir una interfaz, y cuándo explicarías que la decisión tiene alcance arquitectónico?

#block[
#callout(
body: 
[
Primero aclararía actores, qué significa «clara», qué regla protege una reserva y qué resultado debe ver cada persona. Eso evita convertir una frase ambigua en una tabla o API prematura. Propondría una interfaz después de identificar la regla y los límites. La llamaría arquitectónica si condiciona a varias partes, contratos o cambios futuros; si solo organiza un detalle local, sigue siendo diseño con menor alcance.

]
, 
title: 
[
Retroalimentación razonada --- 1
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 2. Fronteras, acoplamiento y cohesión
<fronteras-acoplamiento-y-cohesión>
Una pantalla valida disponibilidad, registra reservas y compone correos. Propón una frontera de módulos y explica qué cambio quedaría localizado.

#block[
#callout(
body: 
[
Una respuesta posible separa pantalla, #NormalTok("Reservas"); y #NormalTok("Notificaciones");. #NormalTok("Reservas"); concentra la regla y expone una operación; la pantalla presenta el resultado y Notificaciones compone el aviso. Cambiar el proveedor o formato del correo afecta principalmente a Notificaciones, por menor acoplamiento. La frontera es útil solo si las responsabilidades realmente cambian por razones distintas; dividir cada función sin necesidad puede reducir cohesión.

]
, 
title: 
[
Retroalimentación razonada --- 2
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 3. Vista y notación
<vista-y-notación>
Para explicar que una persona solicita una cámara y que el sistema la confirma o rechaza, ¿elegirías caso de uso, clases o secuencia? Indica también una vista que no resuelve por sí sola ese diagrama.

#block[
#callout(
body: 
[
Un caso de uso es una elección directa para mostrar actor y meta; una secuencia sirve si importa mostrar los mensajes del escenario. Un diagrama de clases ayuda a discutir conceptos y relaciones, no sustituye esa interacción. La vista conceptual aclara cámara, persona y préstamo; la lógica muestra componentes que colaboran; la física ubica ejecuciones y datos. Elegir una no elimina la pregunta de las otras.

]
, 
title: 
[
Retroalimentación razonada --- 3
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 4. Estilo con contexto
<estilo-con-contexto>
El equipo tiene una aplicación pequeña, un despliegue conocido y pocas fronteras estables. ¿Por qué «microservicios» no es automáticamente la mejor respuesta? Da una alternativa compatible.

#block[
#callout(
body: 
[
Microservicios agregan coordinación de despliegues, fallos y datos; sin una necesidad que compense esos costos pueden oscurecer el problema. Un monolito organizado por capas, atendido en cliente-servidor, puede conservar interfaces y módulos cohesivos. La elección depende de restricciones, cambios esperados y evidencia, no de una jerarquía universal de estilos.

]
, 
title: 
[
Retroalimentación razonada --- 4
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 5. Dos cualidades distintas
<dos-cualidades-distintas>
Dos solicitudes coincidentes producen una confirmación y un rechazo, pero el servicio estuvo caído una hora por un fallo externo. ¿Qué evidencia tienes y qué evidencia falta?

#block[
#callout(
body: 
[
El escenario aporta evidencia limitada de consistencia: no se prometió dos veces la misma copia. No demuestra disponibilidad, porque el servicio no atendió durante la interrupción. Para hablar de disponibilidad se definen condiciones de fallo, tiempo o nivel de servicio y cómo se observará la atención o degradación; para rendimiento se necesitaría además una carga y una medida, que esta práctica no inventa.

]
, 
title: 
[
Retroalimentación razonada --- 5
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 6. Tipo, dominio y herramientas
<tipo-dominio-y-herramientas>
Clasifica el sistema operativo de un servidor, el portal de préstamos y el editor que usa el equipo. Luego explica por qué Python y su runtime no responden a la misma pregunta que «educativo».

#block[
#callout(
body: 
[
El sistema operativo es software de sistema; el portal es software de aplicación y puede pertenecer al dominio educativo; el editor es software de desarrollo. Python es un lenguaje y el runtime aporta el entorno para ejecutar programas: describen medios técnicos diferentes. «Educativo» describe la finalidad del portal. Por eso no se comparan como etiquetas rivales ni se infiere la categoría de una base de datos solo por su nombre.

]
, 
title: 
[
Retroalimentación razonada --- 6
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 7. Mito: sumar personas tarde
<mito-sumar-personas-tarde>
Un proyecto se atrasa y alguien propone añadir cinco personas mañana. ¿Qué condición revisarías antes de aceptar o rechazar la propuesta?

#block[
#callout(
body: 
[
Revisaría el cuello de botella, el tiempo para conocer el contexto y si existen tareas independientes, bien especificadas y con incorporación preparada. Si el trabajo exige coordinación intensa, sumar personas puede aumentar comunicación y errores al inicio. No es una prohibición absoluta: una tarea aislada y preparada podría repartirse. La respuesta responsable explica esa condición en lugar de prometer que más personas siempre aceleran.

]
, 
title: 
[
Retroalimentación razonada --- 7
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 8. Mito: «funciona, está terminado»
<mito-funciona-está-terminado>
Una demostración registra un préstamo correctamente. Nombra dos clases de evidencia que aún podrían faltar antes de declarar terminado el producto.

#block[
#callout(
body: 
[
Podrían faltar evidencia de autorización ---quién puede prestar o administrar--- y de casos de falla o concurrencia, además de documentación y condiciones de entrega. Que un camino funcione confirma ese escenario, no seguridad, mantenibilidad u operación. Qué pedir depende del contexto, pero una definición explícita de terminado evita confundir una demostración con una conclusión total.

]
, 
title: 
[
Retroalimentación razonada --- 8
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 9. Mito: «cada cambio es fácil»
<mito-cada-cambio-es-fácil>
Cambiar una regla de préstamo afecta la pantalla, una interfaz compartida y registros históricos. ¿Cómo razonarías su costo sin asumir que todo cambio es difícil?

#block[
#callout(
body: 
[
Rastrearía módulos, contratos, datos existentes y personas afectadas antes de estimar, y probaría el comportamiento que depende de la regla. Es posible que un texto aislado sea fácil de cambiar; aquí las dependencias compartidas sugieren más riesgo y coordinación. La lección no es negar la evolución, sino distinguir cambios locales de cambios que atraviesan fronteras.

]
, 
title: 
[
Retroalimentación razonada --- 9
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 10. Mito: «no hace falta documentación»
<mito-no-hace-falta-documentación>
El equipo recuerda hoy por qué rechazó que cada pantalla actualizara inventario. ¿Qué documentarías para que esa razón sobreviva a un cambio de equipo?

#block[
#callout(
body: 
[
Registraría el contexto de solicitudes coincidentes, la decisión de centralizar la regla, la alternativa de actualizar desde cada pantalla, sus consecuencias y el criterio observable de una sola reserva activa. El código puede mostrar una llamada, pero no siempre por qué se eligió ni qué supuesto debe conservarse. Una nota breve y cercana a la decisión puede ser suficiente para este alcance; no exige documentación exhaustiva sin propósito.

]
, 
title: 
[
Retroalimentación razonada --- 10
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Cierre
<cierre-1>
La práctica se completa al poder defender una decisión con necesidad, frontera y observación, no al acertar una lista de letras. Si una respuesta fue débil, regresa al concepto enlazado, ajusta el supuesto y escribe qué evidencia pedirías después.

= Procesos de software: actividades, flujo y trabajo reutilizable
<procesos-de-software-actividades-flujo-y-trabajo-reutilizable>
#strong[Meta.] Al terminar podrás explicar qué organiza un proceso de software, distinguir una actividad general de una tarea concreta y representar un flujo sin asumir que todos los proyectos recorren las actividades una sola vez y en el mismo orden @blackboard-arq-s2.

== Objetivos de aprendizaje
<objetivos-de-aprendizaje-2>
- Relacionar requisitos, diseño, implementación, pruebas y mantenimiento con un resultado observable.
- Explicar cómo el flujo ayuda a organizar trabajo, avance y comunicación.
- Distinguir tareas específicas de patrones reutilizables sin convertirlos en una receta universal.

#strong[Pregunta de recuperación.] Si un equipo programa antes de aclarar quién puede reservar una sala, ¿qué información faltante podría obligarlo a rehacer el trabajo?

== Un proceso organiza el trabajo, no reemplaza el criterio
<un-proceso-organiza-el-trabajo-no-reemplaza-el-criterio>
Un #strong[proceso de software] ofrece una forma explícita de organizar actividades para construir y mejorar un producto. Permite conversar sobre qué se intenta conseguir, qué trabajo está pendiente, qué resultado pasa a la actividad siguiente y cómo se comprobará. No garantiza calidad por sí solo: un proceso ordenado también puede producir una solución equivocada si parte de requisitos mal comprendidos o si no incorpora evidencia.

La fuente oficial presenta cinco actividades generales. Sus nombres permiten ubicar el trabajo, pero no obligan a ejecutarlas siempre como una cadena rígida. El modelo de proceso y el contexto determinan si se recorren una vez, por incrementos o en ciclos con retroalimentación y análisis de riesgos.

#block[
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Actividad], [Pregunta que orienta], [Resultado de trabajo posible],),
  table.hline(),
  [Análisis de requisitos], [¿Qué necesidad, regla y restricción debe atenderse?], [requisitos aclarados y criterios observables],
  [Diseño], [¿Cómo se distribuirán responsabilidades, datos e interfaces?], [decisiones y esquema de solución],
  [Implementación], [¿Cómo se construirá el comportamiento acordado?], [software integrado en un alcance definido],
  [Pruebas], [¿Qué evidencia confirma o contradice lo esperado?], [resultados, defectos y decisiones de corrección],
  [Mantenimiento], [¿Qué debe corregirse, adaptarse o mejorarse después de usarlo?], [cambios controlados y nueva evidencia],
)
]
Estas actividades se influyen mutuamente. Una prueba puede revelar que el requisito era ambiguo; una restricción descubierta durante la implementación puede llevar a revisar el diseño; el mantenimiento puede iniciar otro ciclo de análisis. Decir que existe una secuencia lógica ayuda a coordinar, pero no demuestra que toda actividad termine para siempre antes de comenzar otra.

== Flujo: hacer visible cómo avanza el trabajo
<flujo-hacer-visible-cómo-avanza-el-trabajo>
El #strong[flujo de proceso] describe cómo se relacionan y recorren las actividades. Su utilidad es práctica: ayuda a organizar tareas, controlar el avance, coordinar la comunicación del equipo y reducir errores o retrasos evitables. Para que esa ayuda sea real, el flujo debe mostrar resultados y condiciones de paso, no solo nombres de fases.

#figure([
#box(image("subjects/arquitectura-software/semana-02/../../../assets/arquitectura-semana2.svg", alt: "Diagrama accesible. En la parte superior aparecen cinco actividades disponibles: requisitos, diseño, implementación, pruebas y mantenimiento. Debajo se muestran tres organizaciones posibles, no una receta única: secuencia planificada cuando los requisitos son estables; incrementos funcionales con entrega y aprendizaje; y ciclos con retroalimentación o análisis de riesgos."))
], caption: figure.caption(
position: bottom, 
[
Actividades comunes del proceso y tres formas contextuales de organizarlas: una secuencia planificada, entregas por incrementos y ciclos guiados por retroalimentación o riesgo.
]), 
kind: "quarto-float-fig", 
supplement: "Figura", 
)


#emph[Figura.] Las actividades pueden ser comunes, pero el recorrido depende del modelo y del contexto. Las flechas inferiores representan organizaciones alternativas; no indican que todos los proyectos deban usar simultáneamente los tres recorridos.

=== Del nombre de una fase a una condición observable
<del-nombre-de-una-fase-a-una-condición-observable>
Imagina un tablero con una columna llamada «Pruebas». Mover una tarjeta allí no prueba que el sistema funcione. Una condición más útil sería: «la reserva de una sala ocupada es rechazada y no crea un registro activo». Así el equipo sabe qué evidencia buscar y puede comunicar por qué la tarea avanza, vuelve a diseño o necesita aclarar un requisito.

Un flujo también debe reconocer esperas y devoluciones. Si la biblioteca no ha definido cuánto tiempo conserva una reserva provisional, implementar un temporizador no elimina la duda. El trabajo debe regresar a la conversación de requisitos con una pregunta concreta, registrar la decisión y después actualizar diseño, código y prueba.

== Tareas y patrones: distinto nivel de reutilización
<tareas-y-patrones-distinto-nivel-de-reutilización>
Una #strong[tarea] es una actividad específica que se ejecuta en el trabajo, como diseñar una interfaz, programar un módulo, realizar una prueba o corregir un defecto. Debe poder describirse con una entrada, una acción y un resultado. «Mejorar el sistema» es demasiado amplio; «comprobar que una reserva vencida libera la sala» permite revisar qué se hizo.

Un #strong[patrón], en el alcance verificado de esta semana, es una solución reutilizable para un problema común de diseño o desarrollo. Su valor está en reconocer una forma de resolver problemas recurrentes, favorecer la organización, reutilizar conocimiento y facilitar mantenimiento u optimización. No significa copiar una plantilla sin analizar consecuencias. Esta lectura no introduce un catálogo de patrones ni atribuye al contenido oficial un framework específico.

#block[
#table(
  columns: (33.33%, 33.33%, 33.33%),
  align: (auto,auto,auto,),
  table.header([Elemento], [Ejemplo en reservas de biblioteca], [Comprobación],),
  table.hline(),
  [Tarea de diseño], [definir la interfaz para consultar disponibilidad], [la interfaz expresa entradas, resultado y errores relevantes],
  [Tarea de implementación], [programar la regla que evita dos reservas activas], [el comportamiento se integra en el incremento acordado],
  [Tarea de prueba], [intentar reservar una sala ya ocupada], [se obtiene rechazo y no se altera la reserva existente],
  [Corrección de defecto], [impedir que una reserva vencida siga bloqueando el horario], [una prueba reproduce el fallo antes y confirma la corrección después],
  [Solución reutilizable], [separar la regla de disponibilidad de la pantalla], [se reutiliza la idea solo cuando el problema y sus consecuencias coinciden],
)
]
== Caso guiado: primer flujo para reservar salas
<caso-guiado-primer-flujo-para-reservar-salas>
Una red de bibliotecas quiere permitir que estudiantes consulten y reserven salas de estudio. Hoy cada sede lleva una hoja distinta. La primera entrega debe servir en una sede piloto; todavía no se ha decidido si las reservas podrán modificarse desde una aplicación móvil.

=== 1. Aclarar el alcance inicial
<aclarar-el-alcance-inicial>
El equipo formula una regla verificable: una sala no puede tener dos reservas activas en el mismo horario. También registra una incertidumbre: los cambios desde móvil no forman parte del primer alcance y deberán confirmarse con quienes usan el servicio. Eso evita diseñar una solución completa para un requisito aún no observado.

=== 2. Relacionar actividades y resultados
<relacionar-actividades-y-resultados>
+ #strong[Requisitos:] identificar persona, sala, horario y regla de exclusión.
+ #strong[Diseño:] separar consulta de disponibilidad y registro de reserva.
+ #strong[Implementación:] construir consulta y creación para una sede piloto.
+ #strong[Pruebas:] comprobar horario libre, horario ocupado y datos inválidos.
+ #strong[Mantenimiento:] registrar defectos y cambios aprendidos durante el piloto.

La lista describe relaciones lógicas, no una prohibición de volver atrás. Si la prueba revela que dos solicitudes simultáneas se confirman, el equipo revisa diseño e implementación. Si las personas no entienden el estado «provisional», vuelve a requisitos y lenguaje de la interfaz.

=== 3. Hacer visible el avance
<hacer-visible-el-avance>
Cada resultado tiene una condición de revisión. Un requisito avanza cuando incluye una regla y un ejemplo; el diseño, cuando muestra quién protege esa regla; la implementación, cuando integra un alcance ejecutable; la prueba, cuando registra el resultado; y el mantenimiento, cuando un cambio conserva la razón y la evidencia. El flujo mejora la comunicación porque el equipo puede explicar qué falta sin usar «casi terminado» como estado impreciso.

#block[
#callout(
body: 
[
Una respuesta razonable no necesita dibujar cinco cajas en línea. Podría organizar el piloto como un incremento y repetir análisis, diseño, implementación y pruebas para la siguiente capacidad. Lo importante es que la organización conserve la regla, muestre resultados y permita aprender. Elegir el modelo se estudia en la lectura siguiente.

]
, 
title: 
[
Retroalimentación del caso guiado
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Práctica breve: del trabajo difuso a tareas revisables
<práctica-breve-del-trabajo-difuso-a-tareas-revisables>
Para el mismo caso, el equipo escribe «hacer notificaciones» y «probar reservas». Reformula ambos elementos como tareas con entrada, acción y resultado. Después indica qué decisión debe volver a requisitos si aún no está definida.

#block[
#callout(
body: 
[
Separa el medio de notificación de la regla que decide cuándo se envía. En pruebas, especifica una condición y un resultado; no uses «probar todo».

]
, 
title: 
[
Pista opcional
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
#block[
#callout(
body: 
[
#strong[Tarea 1:] dada una reserva confirmada y un correo válido, preparar un aviso con sede, sala y horario; el resultado es un mensaje listo para enviar. #strong[Tarea 2:] dada una sala con una reserva activa en un horario, solicitar el mismo intervalo; el resultado esperado es rechazo sin un segundo registro. Debe volver a requisitos la decisión sobre qué ocurre si el envío del aviso falla: la reserva podría seguir confirmada, quedar pendiente o requerir otra política. Esa regla no se deduce del nombre de la tarea.

]
, 
title: 
[
Una solución posible
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Cierre
<cierre-2>
Un proceso aporta lenguaje para organizar trabajo y evidencia. Las actividades generales ayudan a ubicar decisiones; el flujo explica cómo avanzan, se comunican o regresan; las tareas convierten intención en trabajo revisable; y los patrones permiten reutilizar soluciones cuando el problema y sus consecuencias son comparables. La siguiente lectura usa estas bases para contrastar modelos sin declarar uno universalmente superior.

= Modelos de proceso: comparación, práctica y autoevaluación
<modelos-de-proceso-comparación-práctica-y-autoevaluación>
#strong[Propósito.] Esta lectura compara cascada, incremental, evolutivo y espiral para estudiar decisiones de proceso. Incluye un caso original de reservas de biblioteca, una práctica análoga y diez preguntas con retroalimentación razonada. No reproduce ni resuelve el sistema de pedidos de restaurante ni el Taller 1.2 mencionados en la fuente oficial @blackboard-arq-s2.

== Ruta de estudio
<ruta-de-estudio-1>
+ Compara cada modelo por las condiciones que aprovecha y los problemas que debe controlar.
+ Resuelve el caso antes de abrir la decisión trabajada.
+ Justifica un modelo con requisitos, entregas, retroalimentación y riesgos; no lo elijas por popularidad.
+ Contesta la autoevaluación con tus palabras y contrasta el razonamiento.

== Cuatro modelos, cuatro énfasis
<cuatro-modelos-cuatro-énfasis>
Un #strong[modelo de proceso] organiza cómo se planifican actividades, recursos, tiempos, cambios y riesgos. Su elección depende del tamaño y complejidad del proyecto, el presupuesto, el tiempo disponible y la estabilidad de los requisitos. Ninguna etiqueta elimina la necesidad de diseñar, implementar, probar y mantener con evidencia.

#block[
#table(
  columns: (25%, 25%, 25%, 25%),
  align: (auto,auto,auto,auto,),
  table.header([Modelo], [Organización central], [Es útil considerar cuando], [Límite que debe controlarse],),
  table.hline(),
  [Cascada], [fases secuenciales y documentadas], [los requisitos son claros y estables, y el trabajo puede planificarse con pocas revisiones], [los cambios son costosos y algunos errores pueden aparecer tarde],
  [Incremental], [entregas parciales con funciones integradas progresivamente], [conviene entregar valor temprano y ampliar el sistema por partes], [exige planificar fronteras e integración; el control puede volverse complejo],
  [Evolutivo], [versiones que cambian con retroalimentación frecuente], [las necesidades deben descubrirse o ajustarse junto con las personas usuarias], [tiempo, costo y alcance pueden ser difíciles de estimar si no se controla el aprendizaje],
  [Espiral], [ciclos de planificación, construcción y evaluación de riesgos], [el proyecto es grande o complejo y existen riesgos que justifican análisis repetido], [su gestión es costosa, compleja y requiere experiencia técnica],
)
]
La tabla no es una puntuación. Requisitos estables favorecen una secuencia planificada, pero no vuelven infalible a cascada. Una entrega temprana favorece incrementos, pero cada incremento debe integrarse y probarse. La retroalimentación favorece evolución, pero necesita límites para no convertirse en cambios sin dirección. Un riesgo alto puede justificar ciclos de espiral, pero no toda aplicación pequeña necesita esa carga de gestión.

== Cascada: previsibilidad cuando el cambio es limitado
<cascada-previsibilidad-cuando-el-cambio-es-limitado>
En cascada, una fase se completa antes de iniciar formalmente la siguiente. Es fácil de explicar y favorece una organización documentada. Su supuesto más exigente es que las decisiones tempranas serán suficientemente estables. Si la biblioteca ya tiene reglas legales fijas, formatos aprobados y una única migración definida, una secuencia planificada puede ser defendible. Si las personas aún no saben cómo usarán la reserva, la validación tardía aumenta el costo de corregir el enfoque.

La desventaja no significa que el modelo «nunca pruebe» o que el equipo deba ignorar un error temprano. Significa que el flujo principal separa fases y ofrece menos flexibilidad ante cambios; por eso la calidad de requisitos y revisiones iniciales es crítica.

== Incremental: entregar capacidades completas por partes
<incremental-entregar-capacidades-completas-por-partes>
El modelo incremental divide el producto en #strong[incrementos funcionales]. Cada entrega incorpora una parte utilizable y se integra con lo anterior. Para reservas, un primer incremento podría consultar disponibilidad; el segundo, registrar y cancelar; el tercero, notificar. El orden debe responder a valor y dependencias, no a cortar capas incompletas como «primero todas las pantallas y meses después todas las reglas».

Entregar temprano permite detectar defectos y aprender, pero no garantiza flexibilidad infinita. Una mala frontera puede duplicar reglas o dificultar la integración. La planificación define qué capacidad queda completa, qué contrato conserva y cómo se probará junto con los incrementos previos.

== Evolutivo: aprender con versiones y retroalimentación
<evolutivo-aprender-con-versiones-y-retroalimentación>
El modelo evolutivo desarrolla el software de manera progresiva según necesidades de las personas usuarias. Es adecuado cuando la interacción y el aprendizaje frecuente son centrales. Una versión inicial de reservas podría revelar que «disponible» no basta: estudiantes necesitan saber capacidad, equipamiento y accesibilidad de la sala. La retroalimentación cambia el producto y puede revisar requisitos y diseño.

La flexibilidad necesita control. El equipo registra qué hipótesis valida cada versión, qué cambio se acepta y qué evidencia permite decidir. Sin esas condiciones, el alcance puede crecer de forma desorganizada y las estimaciones pierden utilidad.

== Espiral: ciclos guiados por riesgo
<espiral-ciclos-guiados-por-riesgo>
El modelo espiral combina desarrollo iterativo y análisis de riesgos. Cada ciclo hace visible qué incertidumbre o amenaza se estudiará antes de comprometer más trabajo. En una red grande de bibliotecas, un riesgo podría ser migrar reservas históricas sin crear dobles ocupaciones. Un ciclo puede estudiar datos, construir una prueba limitada y evaluar resultados antes de ampliar la migración.

Su ventaja es atender riesgos de forma explícita en proyectos complejos. Su costo es la planificación continua, la experiencia y el esfuerzo de evaluación. Nombrar una lista de riesgos no convierte automáticamente un proyecto en espiral: el flujo debe usar esos riesgos para orientar los ciclos y las decisiones.

== Caso trabajado: reservas para una red de bibliotecas
<caso-trabajado-reservas-para-una-red-de-bibliotecas>
La red quiere sustituir hojas separadas por un servicio de reservas. Se conocen la regla de no duplicar horarios y la fecha del piloto. Todavía se desconoce qué filtros necesitan estudiantes y personal. Además, migrar reservas existentes podría producir conflictos.

=== Evidencia disponible
<evidencia-disponible>
- #strong[Estable:] una sala no puede tener reservas activas superpuestas.
- #strong[Necesidad temprana:] una sede debe usar el servicio en seis semanas.
- #strong[Incertidumbre:] filtros, mensajes y flujo de modificación se aclararán con el piloto.
- #strong[Riesgo:] datos históricos inconsistentes pueden bloquear o duplicar horarios.

=== Comparación antes de decidir
<comparación-antes-de-decidir>
#strong[Cascada] daría una secuencia clara, pero exigiría cerrar pronto requisitos de uso que aún necesitan retroalimentación. #strong[Evolutivo] permite aprender sobre esos requisitos, aunque por sí solo no expresa qué capacidad completa se entregará en seis semanas. #strong[Espiral] es útil para la migración riesgosa, pero podría ser una gestión excesiva para toda la interfaz del piloto. #strong[Incremental] permite ordenar capacidades y entregar una primera utilidad, siempre que el equipo incluya puntos de retroalimentación y trate el riesgo de datos de forma explícita.

=== Decisión razonada
<decisión-razonada>
Para el piloto se elige un flujo #strong[incremental]:

+ consultar salas y disponibilidad en una sede;
+ crear y cancelar una reserva sin solapamientos;
+ incorporar filtros y mensajes ajustados con la retroalimentación del piloto;
+ ampliar a otra sede solo después de evaluar la migración de sus datos.

La elección no declara que incremental sea universalmente mejor. Responde a entrega temprana, capacidades separables y aprendizaje esperado. El riesgo de migración se analiza antes de cada ampliación; eso es una práctica de gestión coherente con la comparación, no una afirmación de que todo el proyecto usa simultáneamente todos los modelos.

=== Criterios observables
<criterios-observables>
- El primer incremento permite consultar horarios reales de una sede.
- El segundo rechaza solapamientos y conserva una sola reserva activa.
- La retroalimentación del piloto se registra como hipótesis, evidencia y cambio.
- La ampliación se detiene si la prueba de migración produce conflictos sin resolver.

#block[
#callout(
body: 
[
Otra respuesta podría elegir un enfoque evolutivo si la prioridad principal fuera aprender la interacción antes de fijar entregas, o espiral si la migración implicara un riesgo crítico y costoso en toda la red. Sería válida si relaciona la elección con hechos del caso, explica límites y propone evidencia. No basta con afirmar «es más moderno» o «es más seguro».

]
, 
title: 
[
Por qué la justificación es más importante que la etiqueta
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Práctica análoga: agenda de espacios comunitarios
<práctica-análoga-agenda-de-espacios-comunitarios>
Un municipio desea una agenda para reservar canchas y salones comunitarios. Las reglas de horario y responsables están aprobadas, pero no se conoce qué vista será más comprensible para la ciudadanía. Se necesita publicar una primera capacidad en un mes. Hay riesgo de importar duplicados desde hojas de cálculo.

=== Entregable de estudio
<entregable-de-estudio>
Escribe una página breve con:

+ hechos estables, incertidumbres y riesgos;
+ comparación de al menos dos modelos;
+ modelo elegido y razón contextual;
+ dos entregas o ciclos con resultados observables;
+ una condición que haría revisar la elección.

No implementes un sistema ni inventes métricas. La práctica evalúa razonamiento: una respuesta alternativa es válida si conserva las reglas y explica consecuencias.

#block[
#callout(
body: 
[
Separa la necesidad de publicar temprano, que favorece pensar en incrementos, de la incertidumbre de interfaz, que requiere retroalimentación. Después pregunta si el riesgo de datos justifica un ciclo específico antes de ampliar el servicio.

]
, 
title: 
[
Pista opcional
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
, 
body_background_color: 
white
)
]
#block[
#callout(
body: 
[
Un primer incremento podría mostrar disponibilidad y reglas aprobadas; un segundo, permitir reservas y cancelaciones. Después de probar la vista con personas usuarias, el equipo ajustaría lenguaje y filtros. Antes de importar otra hoja, ejecutaría una prueba de duplicados y detendría la ampliación si aparecen conflictos. Esta respuesta elige incremental por entrega temprana, incorpora retroalimentación y trata el riesgo sin afirmar que una sola etiqueta resuelve todo.

]
, 
title: 
[
Ejemplo parcial de respuesta
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Autoevaluación formativa
<autoevaluación-formativa-2>
Responde primero sin abrir la retroalimentación. Estas diez preguntas son originales del cuaderno: no son respuestas de una evaluación, del crucigrama, del Taller 1.2 ni del caso oficial de restaurante.

=== 1. Actividad y tarea
<actividad-y-tarea>
¿Cuál es la diferencia entre «pruebas» como actividad general y «comprobar que una sala ocupada no acepta otra reserva» como tarea?

#block[
#callout(
body: 
[
Pruebas nombra un tipo amplio de trabajo orientado a obtener evidencia. La segunda frase define una tarea concreta con condición y resultado observable. Varias tareas pueden pertenecer a la actividad de pruebas; describirlas permite revisar avance y resultado sin suponer que una columna llamada «Pruebas» garantiza calidad.

]
, 
title: 
[
Retroalimentación razonada --- 1
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 2. Flujo que vuelve atrás
<flujo-que-vuelve-atrás>
Una prueba revela que nadie definió cuánto dura una reserva provisional. ¿Por qué volver a requisitos no significa necesariamente que el proceso haya fracasado?

#block[
#callout(
body: 
[
La prueba hizo visible una decisión faltante. Volver a requisitos permite aclarar la regla antes de consolidar una implementación arbitraria. El fracaso sería ocultar la incertidumbre o repetir trabajo sin aprender. Un flujo útil comunica devoluciones y actualiza diseño, código y pruebas con la decisión acordada.

]
, 
title: 
[
Retroalimentación razonada --- 2
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 3. Patrón sin receta
<patrón-sin-receta>
El equipo quiere reutilizar una solución que separa la disponibilidad de la pantalla. ¿Qué debe comprobar antes de llamarla una buena reutilización?

#block[
#callout(
body: 
[
Debe comprobar que existe un problema comparable: varias interfaces necesitan una regla consistente y conviene protegerla detrás de un contrato. También debe revisar consecuencias, como coordinación y manejo de errores. Reutilizar el nombre o la forma sin compartir el problema puede añadir complejidad y no ofrece el beneficio esperado.

]
, 
title: 
[
Retroalimentación razonada --- 3
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 4. Cascada y estabilidad
<cascada-y-estabilidad>
¿Qué dato del proyecto apoyaría elegir cascada y qué dato haría esa elección más arriesgada?

#block[
#callout(
body: 
[
Apoya cascada que los requisitos, formatos y criterios estén claros, aprobados y sean poco propensos al cambio. La vuelve más arriesgada que el uso real todavía deba descubrirse o que decisiones tempranas dependan de retroalimentación tardía. La secuencia es una ventaja solo si sus supuestos coinciden con el contexto.

]
, 
title: 
[
Retroalimentación razonada --- 4
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 5. Incremento funcional
<incremento-funcional>
¿Por qué «crear todas las pantallas» no es necesariamente un buen primer incremento?

#block[
#callout(
body: 
[
Un incremento debe entregar una capacidad funcional integrada, no solo una capa sin reglas ni datos. Una consulta de disponibilidad completa puede incluir interfaz, regla, integración y prueba en un alcance pequeño. Cortar por capas puede aplazar el valor y descubrir tarde problemas de integración.

]
, 
title: 
[
Retroalimentación razonada --- 5
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 6. Evolución con control
<evolución-con-control>
¿Qué registro mínimo evitaría que un proceso evolutivo se convierta en una lista ilimitada de cambios?

#block[
#callout(
body: 
[
Conviene registrar la hipótesis o necesidad, la versión donde se observará, la evidencia recibida y la decisión de aceptar, rechazar o posponer el cambio. También se mantiene un límite de alcance o tiempo. Así la retroalimentación orienta aprendizaje en lugar de reemplazar toda planificación.

]
, 
title: 
[
Retroalimentación razonada --- 6
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 7. Riesgo en espiral
<riesgo-en-espiral>
Un equipo enumera riesgos al inicio, pero después ejecuta ciclos idénticos sin volver a evaluarlos. ¿Qué elemento del modelo espiral está ausente?

#block[
#callout(
body: 
[
Falta usar el análisis de riesgos para orientar cada ciclo y decidir el siguiente compromiso. Una lista decorativa no reduce incertidumbre. El equipo debería elegir qué riesgo estudiar, obtener evidencia y adaptar planificación o solución según el resultado.

]
, 
title: 
[
Retroalimentación razonada --- 7
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 8. Dos proyectos, modelos distintos
<dos-proyectos-modelos-distintos>
Un sistema tiene requisitos legales estables; otro prueba una experiencia nueva con usuarios. ¿Por qué sería débil recomendar el mismo modelo solo porque ambos son web?

#block[
#callout(
body: 
[
La tecnología de interfaz no determina estabilidad, retroalimentación, riesgo ni forma de entrega. El primer contexto puede favorecer una secuencia más planificada; el segundo necesita aprendizaje frecuente. Se comparan condiciones del proyecto, no la etiqueta «web» ni una moda metodológica.

]
, 
title: 
[
Retroalimentación razonada --- 8
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 9. Elegir con cuatro evidencias
<elegir-con-cuatro-evidencias>
Para una reserva de biblioteca, nombra una evidencia sobre requisitos, otra sobre entrega, otra sobre retroalimentación y otra sobre riesgo que usarías al elegir modelo.

#block[
#callout(
body: 
[
Podrían ser: la regla de no solapamiento está aprobada; una sede necesita consulta en seis semanas; los filtros se definirán con el piloto; y la migración puede duplicar horarios. En conjunto favorecen entregas incrementales, puntos de aprendizaje y una evaluación explícita del riesgo antes de ampliar. Otras evidencias pueden justificar otra decisión si se explica su relación.

]
, 
title: 
[
Retroalimentación razonada --- 9
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
=== 10. Revisar una elección
<revisar-una-elección>
El equipo eligió incremental, pero descubre que ninguna capacidad parcial puede operar legalmente y todos los requisitos están fijados. ¿Qué debería hacer?

#block[
#callout(
body: 
[
Debe revisar la elección en vez de proteger la etiqueta. Si no existe valor ni uso legal por partes y los requisitos son estables, una secuencia planificada podría ser más coherente. También puede redefinir qué significa un incremento interno, pero no debe fingir entregas utilizables. Un modelo es una decisión contextual que cambia cuando cambian sus supuestos.

]
, 
title: 
[
Retroalimentación razonada --- 10
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Alcance de la fuente y cierre
<alcance-de-la-fuente-y-cierre>
Esta Semana 2 desarrolla únicamente el contenido del documento HTML oficial verificado: actividades generales, flujo, tareas y patrones, y los modelos cascada, incremental, evolutivo y espiral. El plan de clase y otros archivos PDF quedaron disponibles solo como metadatos y #strong[no fueron leídos]\; por tanto, este material no afirma cubrir todas las clases, fuentes ni evaluaciones de la semana o del semestre.

La preparación se completa al poder justificar cómo se organiza el trabajo y por qué un modelo encaja en condiciones concretas. Si una respuesta depende de «siempre» o «el mejor», vuelve a requisitos, entregas, retroalimentación y riesgos: ahí debe estar la evidencia de la elección.

= Gestión Empresarial y Emprendimiento
<gestión-empresarial-y-emprendimiento>
Este es el índice independiente de la asignatura dentro del libro compartido.

== Cobertura verificada
<cobertura-verificada>
La Semana 1 aparece publicada en el catálogo oficial, pero su cuerpo no fue leído ni convertido en material de estudio. Por ello, #strong[no hay capítulos de estudio verificados y redactados] para esta asignatura en la edición actual.

== Ruta de lectura
<ruta-de-lectura>
Cuando exista una fuente oficial legible y verificada, este índice enlazará sus capítulos por semana. Hasta entonces, no se infieren temas, calendario, actividades ni respuestas a partir del nombre de la asignatura.

= Inteligencia Artificial
<inteligencia-artificial>
Este es el índice independiente de la asignatura dentro del libro compartido.

== Cobertura verificada
<cobertura-verificada-1>
La Semana 1 aparece publicada en el catálogo oficial, pero su cuerpo no fue leído ni convertido en material de estudio. Por ello, #strong[no hay capítulos de estudio verificados y redactados] para esta asignatura en la edición actual.

== Ruta de lectura
<ruta-de-lectura-1>
Cuando exista una fuente oficial legible y verificada, este índice enlazará sus capítulos por semana. Hasta entonces, no se infieren teoría, prácticas, calendario ni respuestas a partir del nombre de la asignatura.

= Inteligencia de Negocios
<inteligencia-de-negocios>
Este es el índice independiente de la asignatura dentro del libro compartido.

== Cobertura verificada
<cobertura-verificada-2>
El módulo de contenidos observado no tenía material publicado. Por ello, #strong[no hay capítulos de estudio verificados y redactados] para esta asignatura en la edición actual.

== Ruta de lectura
<ruta-de-lectura-2>
Cuando exista contenido oficial legible y verificado, este índice enlazará sus capítulos por semana. No se inventan temas, actividades, calendario ni respuestas para completar una sección vacía.

= Proyectos Informáticos
<proyectos-informáticos>
Este es el índice independiente de la asignatura dentro del libro compartido.

== Cobertura verificada
<cobertura-verificada-3>
Solo se observó metadata de objetivos; no se verificó un cuerpo docente suficiente para redactar teoría o práctica. Por ello, #strong[no hay capítulos de estudio verificados y redactados] para esta asignatura en la edición actual.

== Ruta de lectura
<ruta-de-lectura-3>
Cuando exista una fuente oficial legible y verificada, este índice enlazará sus capítulos por semana. La metadata disponible no autoriza a inferir causas, métodos, actividades, calendario ni respuestas.

= Fuentes y política de uso
<fuentes-y-política-de-uso>
== Política de fuentes
<política-de-fuentes>
Los contenidos de Semana 1 de #strong[Aplicaciones Web con PHP y C\#] se organizan primero a partir de su documentación oficial @blackboard-s1c1@blackboard-s1c2@blackboard-task1, consultada el #strong[30 de octubre de 2026]. Los enlaces pueden pedir autenticación institucional. Este libro los enlaza y parafrasea de forma original; no copia ni redistribuye material privado del aula.

La Semana 1 de #strong[Arquitectura de Software] se organiza a partir de su fuente oficial de contenidos @blackboard-arq-s1, consultada el #strong[31 de octubre de 2026]. La explicación editorial desarrolla esos temas con redacción original. Como enriquecimiento técnico, Parnas fundamenta la ocultación de decisiones de cambio @parnas1972 y Lehman trata la evolución como un fenómeno contextual @lehman1996\; ninguna de las dos fuentes sustituye el currículo oficial.

Las fuentes técnicas complementarias de Aplicaciones Web se usan para verificar sintaxis, plataformas y herramientas, no para ampliar el currículo más allá de Semana 1. Cuando haya una diferencia entre una explicación editorial y una fuente primaria, prevalece la fuente primaria. Los ejemplos de los repositorios de práctica se identifican como evidencia de trabajo existente @practice-repo@assignment-repo, no como una afirmación de que todo el código siga MVC ni como requisito adicional.

Cada entrada conserva su propia fecha de consulta cuando corresponde. La bibliografía distingue las fuentes oficiales de cada asignatura del enriquecimiento técnico suplementario.

== Bibliografía
<bibliografía>
#block[
] <refs>



#bibliography(("references.bib"))


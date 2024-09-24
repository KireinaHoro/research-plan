#let rule(length) = line(start: (0pt, 1em), end: (length, 1em))

#let to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-string).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let is-glossary(it) = {
  if type(it) == label {
    let prev-heading = query(heading.where(level: 3).before(it)).last()
    to-string(prev-heading).match("Glossary") != none
  } else { false }
}

#let document(
  student-name: [Happy Student],
  student-number: [00-000-000],
  supervisor-name: [Prof. Dr. Jane Doe],
  second-advisor-name: [Prof. Dr. John Doe],
  start-date: datetime.today(),
  title: [Awesome PhD Research],
  doc
) = [
  // try to mimic the look and feel of the latex template
  #set text(
    font: "Palatino",
    size: 11pt
  )
  #set par(
    leading: 0.55em,
    justify: true
  )
  #show raw: set text(font: "Inconsolata")
  #show par: set block(spacing: 0.55em, above: 1.4em)
  #show heading: set block(above: 1.4em, below: 1em)

  // make links visible (do not highlight glossary labels)
  #show link: it => {
    if is-glossary(it.dest) {
      it
    } else {
      box(stroke: aqua, it)
    }
  }
  #show ref: it => {
    if not is-glossary(it.target) {
      let t = query(it.target).first()
      // use name of section instead of number, unless it's a work package
      let is-wp = t.has("kind") and t.kind == "work-package"
      if t.numbering == none or not is-wp {
        link(it.target, box(emph(t.body), stroke: lime))
      } else {
        box(it, stroke: lime)
      }
    } else {
      it
    }
  }


  // D-INFK doctoral administration header & footer
  #set page(
    paper: "a4",
    margin: (x: 1in, top: 0.75in + 11em, bottom: 0.75in + 1em),
    header: grid(
      columns: (6fr, 4fr),
      align: top,
      image("logo.svg", width: 60%),
      [
        #set text(size: 8pt)
        *Department of Camputer Science* \
        *Doctoral administration*

        ETH Zurich \
        CAB H 37.1 \
        Universitätstrasse 6 \
        CH-8092 Zurich

        #link("mailto:doctorate@inf.ethz.ch")[doctorate\@inf.ethz.ch] \
        #link("https://www.inf.ethz.ch")[inf.ethz.ch]
      ]
    ),
    footer: grid(
      columns: (1fr, auto, 1fr),
      align: (left, center, right),
      [Doctoral Plan],
      counter(page).display("1"),
      datetime.today().display("[month repr:long] [year]")
    ),
  )

  = Doctoral Plan

  == Basic Information

  #table(
    columns: (auto, 1fr),
    stroke: none,

    [Name Doctoral Student], student-name,
    [Student Number], student-number,
    [Name Supervisor], supervisor-name,
    [Name Second Advisor], second-advisor-name,
    [Start of Doctorate], start-date.display("[day] [month repr:long] [year]"),
  )

  Title Research Proposal

  #rect(
    width: 100%,
    height: 6em,
    title
  )

  #{
    // XXX: redefining numbering affects @ syntax
    show heading.where(level: 2): set heading(numbering: (_, lvl) => [Part #lvl #h(.5em)])
    show heading.where(level: 3): set heading(numbering: (_, _, lvl) => [#lvl. #h(.5em)])

    // show rules for work packages
    show figure.where(kind: "work-package"): it => [
      #let c = counter(figure.where(kind: "work-package"))
      #let num = locate(loc => {
        numbering(it.numbering, ..c.at(loc))
      })
      #set text(style: "italic")
      #h(-1em) WP #num: #it.body #parbreak()
    ]

    set heading(offset: 1)

    doc
  }

  #pagebreak()

  = Signatures

  #table(
    columns: (auto, 1fr),
    stroke: none,
    row-gutter: 1em,

    [Supervisor], rule(100%),
    [Second Advisor], rule(100%),
    [Doctoral Student], rule(100%),
    [Date], rule(100%),
  )
]

#let work-package(name, duration) = figure(
  [#name (#duration)],
  kind: "work-package", supplement: "WP", numbering: "1",
)

#let todo(msg) = text(red, [*TODO*: #msg])

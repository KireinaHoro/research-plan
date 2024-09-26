/// Draws a horizontal rule; useful for creating signature fields.
///
/// *Example:*
/// #example(```
/// table(
///   columns: (auto, 4cm),
///   stroke: none,
///   row-gutter: 1em,
///   [First Person], rule(100%),
///   [Second Person], rule(100%),
/// )
/// ```)
///
/// - length (length): Length of the rule to draw.
/// -> content
#let rule(length) = line(start: (0pt, 1em), end: (length, 1em))

/// Extract all text from a piece of content.
/// - content (content): input content to extract from
/// -> str
#let to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-string).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  } else {
    ""
  }
}

/// Find the name of previous heading of a given label.
/// - it (label): Position to search backwards from.
/// -> str
#let prev-heading(it) = {
  to-string(query(selector(heading).before(it)).last())
}

/// Check if a given element is inside the glossary section.
/// - it (any):            Element to check for.
/// - glossary-name (str): Name of the glossary section.
/// -> boolean
#let is-glossary(it, glossary-name: "Glossary") = {
  if type(it) == label {
    prev-heading(it).match(glossary-name) != none
  } else { false }
}

/// Create a work package header.  Can be further stylized with a show rule.
///
/// *Example:*
///
/// #example(```
/// show figure.where(kind: "work-package"): it => [
///   #let c = counter(figure.where(kind: "work-package"))
///   #let num = locate(loc => {
///     numbering(it.numbering, ..c.at(loc))
///   })
///   #set text(style: "italic")
///   WP #num: #it.body #parbreak()
/// ]
///
/// work-package([Implement a demo system], [3 months])
/// work-package([Test the system], [6 months])
/// ```, dir: ttb)
///
/// - name (content):     Name of the work package.
/// - duration (content): Duration of the work package.
/// -> content
#let work-package(name, duration) = figure(
  [#name (#duration)],
  kind: "work-package", supplement: "WP", numbering: "1",
)

/// Generate a TODO message.  You can use `fill` and `prefix` to create comment
/// functions for other authors.
///
/// *Example:*
///
/// #example(`todo[Specify exact system requirements here!]`)
/// #example(```
/// let commenter-a = todo.with(fill: blue, prefix: [Commenter A])
/// let commenter-b = todo.with(fill: orange, prefix: [Commenter B])
///
/// commenter-a[Looks a bit messy.]
/// commenter-b[I agree!]
/// ```)
///
/// - fill (color):       Color of the output text.
/// - prefix (content):   Prefix of the printed message.
/// - inline (boolean):
///     Insert TODO message inline.  If `false`, inserts paragraph breaks
///     around the message.
///
///     Example inline message:
///     #example(`[We have a paragraph here. #todo(inline: true)[Where?] This is a great paragraph.]`, dir: ttb)
/// - msg (content):      Content of the TODO message.
/// -> content
#let todo(fill: red, prefix: [TODO], inline: false, msg) = {
  if (not inline) { parbreak() }
  text(fill, [*#prefix*: #msg])
  if (not inline) { parbreak() }
}

/// Template for the doctoral plan.
/// - student-name (content):        Name of the student.
/// - student-number (content):      Legi number of the student.
/// - supervisor-name (content):     Name of the supervisor.
/// - second-advisor-name (content): Name of the second advisor.
/// - start-date (datetime):         Start date of the doctoral studies.
/// - title (content):               Title of the doctoral thesis.
/// - doc (content):                 Body of the doctoral plan.
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
    size: 11pt,
    lang: "en",
    region: "us",
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
    if query(it.target).len() != 0 {
      let t = query(it.target).first()
      // use name of section instead of number, unless it's a work package
      let is-wp = t.has("kind") and t.kind == "work-package"
      if t.numbering == none or not is-wp {
        link(it.target, emph(t.body))
      } else {
        link(it.target, it)
      }
    } else {
      // no target: must be a citation
      box(stroke: lime, it)
    }
  }


  // D-INFK doctoral administration header & footer
  #set page(
    paper: "a4",
    margin: (x: 1in, top: 0.75in + 11em, bottom: 0.75in + 1em),
    header: grid(
      columns: (6fr, 4fr),
      align: top,
      image("logos/eth.svg", width: 60%),
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
      [Doctoral Plan #student-name],
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

  #pagebreak(weak: true)

  = Signatures

  #let signature-blank = { v(1.5cm); rule(70%) }
  #let date-blank = { v(1.5cm); rule(80%) }

  #table(
    columns: (6fr, 4fr),
    stroke: none,

    signature-blank, date-blank,
    [Doctoral Student: #student-name], [Date],
    signature-blank, date-blank,
    [Supervisor: #supervisor-name], [Date],
    signature-blank, date-blank,
    [Second Advisor: #second-advisor-name], [Date],
  )
]

#let rule(length) = line(start: (0pt, 1em), end: (length, 1em))

#let conf(
  student-name: [Happy Student],
  student-number: [00-000-000],
  supervisor-name: [Prof. Dr. Jane Doe],
  second-advisor-name: [Prof. Dr. John Doe],
  start-date: datetime.today(),
  title: [Awesome PhD Research],
  doc,
) = {
  // try to mimic the look and feel of the latex template
  set text(
    font: "New Computer Modern",
    size: 11pt
  )
  set par(justify: true)

  // D-INFK doctoral administration header & footer
  set page(
    paper: "a4",
    margin: (x: 1in, top: 2.75in, bottom: 1in),
    header: [
      #grid(
        columns: (6fr, 4fr),
        align: top,
        [
          #image("logo.svg", width: 60%)
        ],
        [
          #set text(size: 8pt)
          *Department of Computer Science* \
          *Doctoral administration*
          
          ETH Zurich \
          CAB H 37.1 \
          Universitätstrasse 6 \
          CH-8092 Zurich
          
          #link("mailto:doctorate@inf.ethz.ch")[doctorate\@inf.ethz.ch] \
          #link("https://www.inf.ethz.ch")[inf.ethz.ch]
        ]
      )
    ],
    footer: context [
      #grid(
        columns: (1fr, auto, 1fr),
        align: (left, center, right),
        [Research Plan],
        [
          #counter(page).display(
            "1",
          )
        ],
        [#datetime.today().display("[month repr:long] [year]")]
      )
    ],
  )
  [
    = Research Plan

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
  ]
  
  {
    show heading.where(level: 1): set heading(numbering: n => "Part " + str(n))
    show heading.where(level: 2): set heading(numbering: (f, s) => str(s) + ". ")

    text(doc)
  }

  pagebreak()

  [= Signatures]

  {
    table(
      columns: (auto, 1fr),
      stroke: none,
      row-gutter: 1em,

      [Supervisor], rule(100%),
      [Second Advisor], rule(100%),
      [Doctoral Student], rule(100%),
      [Date], rule(100%),
    )
  }
}
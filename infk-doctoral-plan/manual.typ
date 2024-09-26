#import "@preview/tidy:0.3.0"

#import "infk-doctoral-plan.typ"

#let docs = tidy.parse-module(
  read("infk-doctoral-plan.typ"),
  name: "D-INFK Doctoral Plan Template",
  scope: (mod: infk-doctoral-plan),
  preamble: "import mod: *;"
)

#show link: underline

#set page(footer: align(center, counter(page).display("1")))

#tidy.show-module(docs)

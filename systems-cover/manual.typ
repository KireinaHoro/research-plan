#import "@preview/tidy:0.3.0"

#import "systems-cover.typ"

#let docs = tidy.parse-module(
  read("systems-cover.typ"),
  name: "Systems Group Cover Page",
  scope: (mod: systems-cover),
  preamble: "import mod: *;"
)

#show link: underline

#set page(footer: align(center, counter(page).display("1")))

#tidy.show-module(docs)

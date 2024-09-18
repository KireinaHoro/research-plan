#import "style.typ": conf
#show: doc => conf(
  student-name: [Pengcheng Xu],
  student-number: [21-951-876],
  supervisor-name: [Prof. Dr. Timothy Roscoe],
  second-advisor-name: [To Be Determined],
  // XXX: do we count from the beginning of contract, or DD enroll?
  start-date: datetime(year: 2023, month: 12, day: 1),
  title: [Co-designing HW and OS for Efficient Datacenter Communication],
  doc
)

= Research Proposal

== Abstract

== Introduction and Current State of Research in the Field

== Goals of the Thesis

== Progress to Date

== Detailed Work Plan

#[
// define work packages here.
#show heading.where(level: 3): set heading(numbering: (f, s, t) => "WP " + str(t) + " ")

=== Basic RPC NIC

=== Scheduling-aware RPC NIC

]

== Publication Plan

== Time Schedule

== References

= Teaching Responsibilities

= Other Duties

= Study Plan
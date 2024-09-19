#import "infk-doctoral-plan.typ": document, todo, work-package
#show: document.with(
  student-name: [Pengcheng Xu],
  student-number: [21-951-876],
  supervisor-name: [Prof. Dr. Timothy Roscoe],
  second-advisor-name: [To Be Determined],
  // XXX: do we count from the beginning of contract, or DD enroll?
  start-date: datetime(year: 2023, month: 12, day: 1),
  title: [Co-designing HW and OS for Efficient Datacenter Communication],
)

#import "@preview/glossarium:0.4.1": make-glossary, print-glossary, gls, glspl
#show: make-glossary

#import "glossary.typ": glossary

#let show-page-limits = true
#let lim(len) = if show-page-limits { text(blue)[(#len)] }

= Research Proposal

== Abstract #lim[max $frac(1, 2)$ page]

/*
- current dc comm has many small transactions
- design is around PCIe DMA, which is optimized for high throughput
  - optimizations disproportionately punish small transactions
- small transactions are commonplace
- overhead harms efficiency, against the goals of nowaday datacenters
- our fix: co-design hw and os with help of emerging cache-coherent interconnects
- concerns three important aspects targeting a real-world deployable system:
  - efficiency
  - deployability
  - security
- current progress: NIC building, ECI/PIO paper
  */

Datacenter communication patterns are becoming increasingly oriented towards
smaller transactions with the recent trend of micro-services and serverless
computing.  However, datacenter communication systems have been traditionally
designed around PCIe #gls("dma", long: false), an interconnect standard
designed and highly optimized for high-throughput workloads.  The design of
PCIe @dma disproportionately penalizes small transactions with various
overheads, contradicting with the trend of pursuing higher efficiency.

In this research plan, we present our vision to achieve efficient datacenter
communication through a co-design of hardware and operating system, utilizing
emerging cache-coherent interconnect standards between CPUs and custom-built
#glspl("nic", long: false).  We focus on three main aspects for building a
successful solution: efficiency, deployability, and provable security.  We
pursue high efficieny by building cache-coherent smart #glspl("nic") with
protocol offloading capabilities, aiming to eliminate all existing
communication overheads.  We ensure deployability by designing our software and
hardware with attention to requirements in production environments, such as
multi-tenancy, inspection and telemetry, and debugging.  We target provable
security by formally verifying critical software and hardware components
introduced, as well as how they interact with existing components.

#pagebreak(weak: true)

== Introduction #lim[ca 1 page]

#todo[following is copied from OSDI poster abstract.  refactor]

Virtually all workloads running in datacenters require communication with other
systems in some way; one of the most commonly used paradigms for such is @rpc.  They are the cornerstone of virtually all networked
systems, including micro-services, serverless, networked filesystems, and many
more.  Previous work on characterizing @rpc workloads
@seemakhupt_cloud-scale_2023 demonstrated that short @rpc invocations in the
ballpark of 1 microsecond make up a significant portion of all @rpc workloads.

Despite the high frequency of short @rpc workloads, traditional datacenter @rpc
architecture using PCIe @dma #glspl("nic") incur high latency and CPU overhead.  We
identify three classes of overhead in the traditional PCIe @dma @rpc
architecture: protocol overhead from marshaling and unmarshaling, session
maintenance, encryption and decryption, and more; @dma overhead from the need to
set up descriptor rings, various queues, and @dma buffers; and schedule overhead
from the need to multiplex CPU cores between normal workload and handling
events from the @nic via interrupt requests (IRQ), and to deliver packet data to
the correct user space application.  All these overheads come on top of the
actual CPU cycles spent executing the actual @rpc handler, significantly
lowering efficiency in @rpc processing.

The modern data center architecture, however, looks vastly different from the
traditional case.  Servers are dedicated to handling @rpc requests rather than
shared with other tasks and a single CPU server can come with over a hundred
cores, making obsolete mechanisms for multiplexing CPU time between multiple
tasks.

Cache-coherent interconnects allow for communication between the CPU
and @nic lower latency and higher throughput, without the need for huge batch
sizes.  Climate change and power budgets demand for higher energy efficiency in
data centers.

== Current State of Research in the Field #lim[ca 2-3 page]

#todo[mention dagger, cc-nic, etc.  steal from PIO paper related work]

== Goals of the Thesis #lim[ca 2-3 pages] <goals>

#todo[expand final goal: to achieve efficient datacenter communication; recap three points from abstract]

In our ongoing project, Enzian Fast @rpc, we propose an accelerated
communication architecture that fuses the @nic and the OS with coherently
attached FPGA, effectively freeing the CPU from all overheads in @rpc processing
to achieve high efficiency and performance.

To tackle the aforementioned protocol overhead, we offload @rpc protocol
processing operations such as compression, encryption, and arguments marshaling
to the FPGA as hardware accelerators.  We alleviate @dma overheads by
implementing the 2Fast2Forward message-passing protocol based on programmable
I/O (PIO) on top of cache-coherence protocols like CXL.  In addition, we make
use of the latency and CPU cycles advantage from the cache-coherence protocol
and deeply integrate the OS and the smart @nic, allowing the @nic to schedule @rpc
requests to be handled on a specific core.  The CPU core would load a cacheline
from the smart @nic containing all necessary information to start executing the
@rpc workload directly and eliminating schedule overhead.

We set an ambitious target for end-to-end @rpc latency of 1 microsecond.
Preliminary results on Enzian [2] show that we can send and receive Ethernet
frames from the CPU over the ECI cache coherence protocol in around 800
nanoseconds, making a promising case for our latency target.

#todo[mention aspects of the system that needs attention: basic functionality,
scheduling optimization, mem mgmt, security/formal, multi-tenancy]

== Progress to Date #lim[ca $frac(1, 2)$ page]

Mention previous work:
- FPsPIN work
- demo ECI @nic for PIO paper
- work in progress for simple @rpc offloading @nic (decode pipeline, etc.)

== Detailed Work Plan #lim[ca 1 page] <work-pkgs>

We list out the exact work packages for each critical aspect of concern, as we
have previously detailed in #link(<goals>)[Goals of the Thesis].

=== Performance guarantees

#work-package([Basic @rpc @nic], [3 months]) <basic-nic>
Work item description

#work-package([Integrated task scheduling], [3 months]) <scheduling>
Work item description

#work-package([Integrated memory management], [3 months])
Work item description

#work-package([Security through formal verification], [3 months])
Work item description

#work-package([Multi-tenancy and virtualization], [3 months])
Work item description

== Publication Plan

The basic @rpc @nic integrated with task scheduling (@basic-nic and @scheduling)
should result in one paper in a systems top conference (e.g. ASPLOS, SOSP).

== Time Schedule #lim[ca $frac(1, 2)$ page]

== References #lim[ca 1 page]

#bibliography("citations.bib",
  title: none,
  style: "ieee")

== Glossary

#{
  set text(size: 10pt)
  print-glossary(
    disable-back-references: true,
    glossary)
}

= Teaching Responsibilities

= Other Duties

= Study Plan


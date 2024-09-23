#import "infk-doctoral-plan.typ": document, todo, work-package, is-glossary
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

#import "@preview/cetz:0.2.2"
#import "glossary.typ": glossary

#let show-page-limits = true
#let lim(len) = if show-page-limits { text(blue)[(#len)] }

// replace microsecond with greek letter
#let us_rgx = regex("(\d) us\b")
#show us_rgx: it => [#it.text.match(us_rgx).captures.first() #{sym.mu}s]

= Research Proposal

== Abstract #lim[max $frac(1, 2)$ page]

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
pursue high efficieny by building a cache-coherent smart @nic[s] with protocol
offloading capabilities, aiming to eliminate all existing communication
overheads.  We ensure deployability by designing our software and hardware with
attention to requirements in production environments, such as multi-tenancy,
inspection and telemetry, and debugging.  We target provable security by
formally verifying critical software and hardware components introduced, as
well as how they interact with existing components.

#pagebreak(weak: true)

== Introduction #lim[ca 1 page]

Virtually all workloads running in datacenters require communication with other
systems in some way; one of the most commonly used paradigms for such is @rpc.
They are the cornerstone of virtually all networked systems, including
micro-services, serverless computing, networked filesystems, and many more.
Previous work on characterizing @rpc workloads~@seemakhupt_cloud-scale_2023
demonstrated that short @rpc invocations in the ballpark of 1 us make up a
significant portion of all @rpc workloads.

Despite the high frequency of short @rpc workloads, traditional datacenter @rpc
architecture using PCIe @dma @nic[s] incur high latency and CPU overhead.
We identify three classes of overhead in the traditional PCIe @dma @rpc
architecture: protocol overhead from marshaling and unmarshaling, session
maintenance, encryption and decryption, and more; @dma overhead from the need
to set up descriptor rings, various queues, and @dma buffers; and schedule
overhead from the need to multiplex CPU cores between normal workload and
handling events from the @nic via @irq, and to deliver packet data to the
correct user space application.  All these overheads come on top of the actual
CPU cycles spent executing the actual @rpc handler.  Many of these overheads
are fixed, not scaling with the size of the request and response, meaning that
they dispropotionately impact short invocations and significantly lowering
efficiency in their processing.  These overheads contradict with the ever
increasing demand for higher processing efficiency by datacenters.

We recognize that the aforementioned overheads come from the fundamental
assumptions of PCIe about the system architecture: requests are long; bus
latency is high; a server has few cores; there are many tasks other than
network processing.  The modern data center architecture, however, looks vastly
different from these traditional assumptions.  In most hyper-scalers, entire
servers are dedicated to handling @rpc requests rather than shared with other
tasks.  In addition, a single CPU server can come with over a hundred cores,
making obsolete mechanisms for multiplexing CPU time between multiple tasks.
Emerging cache-coherent interconnects allow for communication between the CPU
and @nic lower latency and higher throughput, without the need for huge batch
sizes.

Our vision to resolve this problem is to co-design the @nic and OS, taking full
advantage of cache-coherent interconnects.  We will build a cache-coherent
offloading smart @nic to free the CPU cores that run @rpc service handlers from
all overheads due to network and protocol processing.  The @nic would be
tightly integrated with various aspects of the OS, such as task scheduling and
buffer management.  Since most @rpc protocols are designed to be processed on
the CPU, we also need to explore what type of network protocols are suitable
for efficient implementation in hardware.  For a successful solution with
real-world impact, we also tackle important concerns for production
environments such as multi-tenancy, inspectability, and accounting.  As we
integrate deeply and fundamentally with the OS, security is of utmost
importance; we plan to employ various formal methods approaches to verify the
functional correctness and isolation properties of critical components and how
they interact with the rest of the system.

#pagebreak(weak: true)

== Current State of Research in the Field #lim[ca 2-3 page]

We group prior works related to this thesis by topic and cite only the most
relevant papers due to space limitation.

=== Cache Coherence Interconnects

Various industry standards for cache-coherent interconnects in datacenters have
been under development and are gradually seeing wider adoption.  Examples in
this field include OpenCAPI, Gen-Z, and CCIX; these protocols are based on
different physical layer standards and upper protocols.  They have been
superceded by and largely absorbed into CXL, which aims to the one standard
interoperable interconnect standard across vendors.  While CXL has been hyped
by many researchers, adoption has been slow due to lack of hardware
implementation.

Other notable coherent interconnects include TileLink for RISC-V systems as
well as AMBA ACE from ARM; both of which are mainly implemented in low-power
embedded systems instead of server-scale hardware.  NVLink 2.0 from NVIDIA
features cache coherence in high-performance hardware but is closed and
proprietary.  As a result from various restrictions in existing protocols,
research on cache-coherent interconnects are largely performed on experimental
systems like Intel HARP and Enzian~@cock_enzian_2022.  We plan to implement our
prototype systems on Enzian, but would also be open to adopt new CXL hardware
suitable for our purposes as they become available.

=== Communication Pattern between CPU and @nic

The communication pattern between CPU and peripheral device has been
extensively studied.  Previous works such as hXDP and kPIO+WC have shown the
high overhead of PCIe @dma for smaller transactions and attempts to mitigate
either by processing them solely on the CPU or using PCIe @pio for lower
latency.  Extra efficiency can be achieved with cache-coherent interconnects
other than PCIe.  Dagger~@lazarev_dagger_2021 builds on the UPI/CCI-P
implementation of Intel HARP an FPGA NIC for low-latency RPC, focusing mainly
on using the UPI interconnect as a @nic interface to offload @rpc protocol
processing.  Previous work in the group on @pio~@ruzhanskaia_rethinking_nodate
showed that it is possible to achieve higher efficiency with @pio using
cache-coherent interconnects.  Our work builds on the basic @nic implementation
in~@ruzhanskaia_rethinking_nodate for a full solution of offloading @rpc
processing.

Many works have since long discovered that a cache line is a better unit of
transfer for workloads where small transfers are commonplace; notable examples
are FastForward and Barrelfish UMP.  Shinjuku~@kaffes_shinjuku_2019 and
Concord~@iyer_achieving_2023 are more recent examples of employing this idea
for low-latency scheduling via one polled cache line between the CPU and @nic.
This observation coincides with findings from a recent study from
Google~@seemakhupt_cloud-scale_2023, which highlights the importance of
efficient small, #{sym.mu}s-scale transfers in datacenter @rpc due to their
high frequency.  In this thesis, we target these small transfers to improve
efficiency for a common case of datacenter communication.

=== Offload-friendly Network Protocol Design

#todo[what are the related works in this field?]

=== Integration with OS

Improving scheduling latency and efficiency of networking tasks is a topic
extensively explored by previous work.  Previous works like
Shinjuku~@kaffes_shinjuku_2019, Caladan~@fried_caladan_2020, and
DemiKernel~@zhang_demikernel_2021 improves tail latency by dedicating CPU cores
to polling @nic contexts with various kernel-bypass mechanisms to improve
efficiency.  More recently, Wave~@humphries_wave_2024 explores offloading
scheduling policies to dedicated, smart #[@nic]-like @ipu[s] while maintaining
low latency for dispatching with @pio mechanisms.   We believe that with
techniques like lazy update thanks to cache-coherent interconnects, we can
manipulate internal states of existing OS schedulers and achieve more efficient
and ergonomic integration.

Buffer management is an important topic for offloading @rpc to smart @nic[s].
Zerializer~@wolnikowski_zerializer_2021 passes memory _arenas_ containing @rpc
objects between the @nic and CPU over PCIe to achieve zero-copy serialization
and deserialization; ProtoAcc~@karandikar_hardware_2021 from Berkeley adopts a
similar approach over a tightly-coupled coprocessor interface.  We might be
able to explore further in this field with customized cache line-level
protocols on cache-coherent interconnects.

=== Deployability in Production Environments

As of today, little attention is paid to multi-tenancy support for smart
@nic[s], mainly due to most cloud providers deploying them as @ipu[s] for
offloading work from the hypervisor host.  FairNIC~@grant_smartnic_2020
discussed about performance isolation for the Cavium LiquidIO smart @nic.
#box[OSMOSIS]~@khalilov_osmosis_2024 introduces a centralized hardware
scheduler for multiplexing processing units on the smart @nic across multiple
@sriov virtual functions.  S-NIC~@zhou_smartnic_2024 focuses on security
isolation between network functions on smart @nic[s] through virtualization of
data plane and accelerators.  We believe that integration between the CPU and
smart @nic with cache-coherent interconnects would pose new challenges for
virtualization and multi-tenancy, since conventional PCIe #[@sriov]-style
virtualization technologies would not apply naively here.

Telemetry data is crucial for analyzing performance and efficiency issues for
complex distributed systems in datacenters.  Dapper~@sigelman_dapper_2010 from
Google is a distributed tracing platform for monitoring various metrics like
@rpc tail latency, network usage, etc.  Fathom~@qureshi_fathom_2023 further
integrates with Dapper, providing low-level network stack instrumentation for
all connections in Google datacenters.  The ubiquity of tracing and
instrumentation needs in production datacenters forms a stark contrast against
many research prototype systems that treat tracing as _exceptions_ rather than
_norm_: disregarding traced endpoints by excluding them from the fast path
limits the deployability of these systems.  We intend to invest in this
direction to allow our system to be deployable in production environments.

=== Security and Verification

#[@rpc]-offloading smart @nic[s] are a potential new single point of failure
introduced to datacenter systems; the critical nature warrants extensive
verification effort for their functional correctness.  Conventional hardware
verification focuses on @abv against properties specified in various logic
domains.  These properties can be either written by hand or generated from
higher-level behavioural models of the final system.  They can then be checked
in an automated fashion with simulation or formal methods.  We plan to
integrate with prior models developed in the group for cache-coherent
interconnects to derive properties and employ standard techniques to prove the
functional correctness of our custom hardware.

#todo[side-channel freedom (isolation guarantees)?  InSpectre (CCS'20)]

== Goals of the Thesis #lim[ca 2-3 pages] <goals>

#show ref: it => {
  let t = query(it.target).first()
  if not is-glossary(it.target) and t.numbering == none {
    link(it.target, t.body)
  } else {
    it
  }
}

First and foremost, we need a base prototype system to demonstrate the
feasibility of our approach to higher efficiency; we explain this in
@goals-prototype.  After attaining the prototype, we then tackle various real
world problems that affect deployability of our solutions in production
environments as we explain in @goals-deployability.  Finally, we explore how we
can prove that the resulting system is secure and reliable with formal methods
in @goals-security.

=== Base System <goals-prototype>

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

We set an ambitious target for end-to-end @rpc latency of 1 us.
Preliminary results on Enzian [2] show that we can send and receive Ethernet
frames from the CPU over the ECI cache coherence protocol in around 800
nanoseconds, making a promising case for our latency target.

=== Deployability <goals-deployability>

=== Security <goals-security>

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

=== Base System

#work-package([Basic @rpc @nic], [3 months]) <basic-nic>
Work item description

#work-package([Protocol design for HW offloading], [3 months])
Work item description

#work-package([Integrated task scheduling], [3 months]) <scheduling>
Work item description

#work-package([Integrated buffer management], [3 months])
Work item description

=== Deployability

#work-package([Multi-tenancy, Virtualization], [3 months])
Work item description

#work-package([Instrumentation, Telemetry, Robustness], [3 months])
Work item description

=== Security

#work-package([Security through formal verification], [3 months])
Work item description

== Publication Plan

The basic @rpc @nic integrated with task scheduling (@basic-nic and @scheduling)
should result in one paper in a systems top conference (e.g. ASPLOS, SOSP).

== Time Schedule #lim[ca $frac(1, 2)$ page]

#todo[draw a Gantt diagram with the @work-pkgs defined above]

#cetz.canvas({
  import cetz.draw: *

  circle((0, 0), name: "circle")

  fill(red)
  stroke(none)
  circle("circle.east", radius: 0.3)
})

== References #lim[ca 1 page]

#{
  set text(size: 10pt)
  bibliography("citations.bib",
    title: none,
    style: "ieee")
}

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


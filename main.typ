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

#let show-page-limits = false
#let lim(len) = if show-page-limits { text(blue)[(#len)] }
#let half = [\u{00bd}]

// replace microsecond with greek letter
#let us_rgx = regex("(\d) us\b")
#show us_rgx: it => [#it.text.match(us_rgx).captures.first() #{sym.mu}s]

// comment function for mothy
#let mothy(msg) = text(blue, [*Mothy*: #msg])

= Research Proposal

#mothy[example comment from mothy.  *strong text* _emph text_]

== Abstract #lim[max #half page]

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

== Introduction #lim[ca 1 page] <intro>

Virtually all workloads running in datacenters require communication with other
systems in some way; one of the most commonly used paradigms for such is @rpc.
They are the cornerstone of virtually all networked systems, including
micro-services, serverless computing, networked filesystems, and many more.
Previous work on characterizing @rpc workloads~@seemakhupt_cloud-scale_2023
demonstrated that short @rpc invocations in the ballpark of 1 us make up a
significant portion of all @rpc workloads.

Despite the high frequency of short @rpc workloads, traditional datacenter @rpc
architecture using PCIe @dma @nic[s] incur high latency and CPU overhead.  We
identify three classes of overhead in the traditional PCIe @dma @rpc
architecture: _protocol overhead_ from marshaling and unmarshaling, session
maintenance, encryption and decryption, and more; _@dma overhead_ from the need
to set up descriptor rings, various queues, and @dma buffers; and _schedule
overhead_ from the need to multiplex CPU cores between normal workload and
handling events from the @nic via @irq[s], and to deliver packet data to the
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

We group prior works related to this thesis by topic and explain our vision on
improving the status quo.  We cite only the most relevant papers due to space
limitation.

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
implementation of Intel HARP an @fpga @nic for low-latency @rpc, focusing
mainly on using the UPI interconnect as a @nic interface to offload @rpc
protocol processing.  Previous work in the group on
@pio~@ruzhanskaia_rethinking_2024 showed that it is possible to achieve higher
efficiency with @pio using cache-coherent interconnects.  Our work builds on
the basic @nic implementation in~@ruzhanskaia_rethinking_2024 for a full
solution of offloading @rpc processing.

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

/*
=== Offload-friendly Network Protocol Design <related-work-proto-design>

#todo[what are the related works in this field?]
*/

=== Integration with OS

Improving scheduling latency and efficiency of networking tasks is a topic
extensively explored by previous work.  Previous works like
Shinjuku~@kaffes_shinjuku_2019, Caladan~@fried_caladan_2020, and
DemiKernel~@zhang_demikernel_2021 improve tail latency by dedicating CPU cores
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

=== Security and Verification

#[@rpc]-offloading smart @nic[s] are a potential new single point of failure
introduced to datacenter systems; the critical nature warrants extensive
verification effort for their functional correctness.  Conventional hardware
verification focuses on @abv~@witharana_survey_2022 against properties
specified in various logic domains.  These properties can be either written by
hand or generated from higher-level behavioural models of the final system.
They can then be checked in an automated fashion with simulation or formal
methods.  We plan to integrate with prior models developed in the group for
cache-coherent interconnects to derive properties and employ standard
techniques to prove the functional correctness of our custom hardware.

_Specification synthesis_ is a method to extract behavioural specifications
from a black-box component.  Schult et.~al.~@schuh_cc-nic_2024 proposed a method to
test cache-coherence protocol hardware implementations with partial
specifications.  Their method can be extended to synthesize full specifications
for model-checking other components in a fully integrated system.  We will work
closely with the authors towards deriving specifications for all hardware
components in the system.

== Goals of the Thesis #lim[ca 2-3 pages] <goals>

First and foremost, we need a base prototype system to demonstrate the
feasibility of our approach to higher efficiency; we explain this in
@goals-prototype.  After attaining the prototype, we then have to tackle
various real world problems that would allow adoption of our solutions in
production environments; we explain how we achieve this in
@goals-deployability.  Finally, we explore how we can prove that the resulting
system is secure and reliable with formal methods in @goals-security.

=== Base System <goals-prototype>

The goal of the base prototype @rpc offloading system is to remove *all*
overheads in @rpc processing from the host CPU cores.  We use latency as a
_proxy_ of efficiency: the lower latency we are able to achieve, the higher
efficiency we will attain.  Our system fuses the @nic and the OS with a smart
@nic implemented on a coherently-attached @fpga to eliminate the three main
types of overhead in conventional @rpc processing: _protocol overhead_, _@dma
overhead_, and _schedule overhead_.

To tackle _protocol overhead_, we offload @rpc protocol processing operations
such as encryption/decryption, compression/decompression, and arguments
marshaling/unmarshaling to the @fpga as hardware accelerators.  We start with a
very simple protocol, @oncrpc based on UDP, which is easy to implement in
hardware but still have popular applications built with it, like @nfs.  We can
make use of EasyNet, the HLS TCP accelerator developed in the group, to
implement more complex @rpc protocols.  Encryption and compression are
orthogonal to the serialization format, and off-the-shelf implementations of
common cryptography and compression IP cores allow quick integration into our
prototype system.

We alleviate _@dma overheads_ by implementing the 2Fast2Forward message-passing
protocol as discussed in our @pio paper~@ruzhanskaia_rethinking_2024 on top of
ECI, the cache-coherence protocol in Enzian.  Specifically, the CPU core polls
in userspace on a pair of special control cache lines backed by @fpga memory
for receiving packets.  The @fpga blocks reload requests for these cache lines
until a packet arrives, or a specific timeout occurs.  This removes the
overhead of setting up @dma descriptors and @irq for transfers between the CPU
and the @nic.  Kernel bypass from userspace mitigates the overhead of
traversing many queues and protection boundaries.

We make use of the latency and CPU cycles advantage from the cache-coherence
protocol to deeply integrate the OS and the smart @nic and free the CPU from
any _scheduling overhead_.  This allows the smart @nic to make scheduling
decisions on where to steer the packet: by placing related context of the OS
scheduler on @fpga memory, the smart @nic receives on-demand updates whenever a
core changes state.  The smart @nic can also dispatch @rpc requests to be
handled on a specific core: the CPU core would load a cache line from the
smart @nic containing all necessary information to start executing the @rpc
workload directly, including pointers to @rpc handler code, data, unmarshaled
arguments, and protection domain information.

We set an ambitious target for end-to-end @rpc latency of *1 us*.  Preliminary
results~@ruzhanskaia_rethinking_2024 show that we can send and receive Ethernet
frames from the CPU over the ECI cache coherence protocol in around 800 ns,
thus making a promising case for our latency target.

=== Deployability <goals-deployability>

Apart from evaluating our system with synthetic benchmarks, we plan to show
deployability of the system by porting existing workloads onto it.  Dandelion
is a serverless scheduler and runtime developed in the group; the project would
benefit from an offloaded @rpc smart @nic for implementing communication
between worker nodes.  We plan to work with their team such that the
communication subsystems in Dandelion is built on our system.
DeathStarBench~@gan_open-source_2019 is the _de-facto_ standard for
benchmarking micro-service systems and would be a good candidate as well.  This
process will expose practicality issues in our design and implementation,
allowing us to further improve deployability for production systems.

The smart @nic we build needs to allow telemetry collection to help identify
possible performance bottlenecks and efficiency issues.  Implemented hardware
on @fpga[s] are not as easily instrumented as software.  We implement flexible
and customizable event counters for every part of the packet processing
pipeline, which would allow a detailed break-down of latency introduced by the
smart @nic.  We design interfaces for configurable transaction-level tracing to
allow higher-level analysis, profiling and debugging of the application.  We
plan to build tooling to allow us to analyze various sources of telemetry data
and provide the same level of insight as in production environments.  This will
involve working with our industry partners to figure out the exact requirements
real production environments have.

Effective multi-tenancy support requires _multiplexing_ of processing elements
as well as proper _performance isolation_ to avoid unwanted interference and
fairness issues between tenants on the same smart @nic.  We need to define
clear interfaces between the @rpc application and the software runtime to allow
for clean isolation.  Once we attain the prototype system as described in
@goals-prototype, we need to implement on top virtualization mechanisms to
multiplex packet processing pipelines and on-chip memory.  We also need to
figure out scheduling policies to ensure fairness among tenants.  We have to in
addition enforce performance isolation for traffic from different tenants on
the same coherent interconnect; many open questions exist here.

=== Security <goals-security>

Security problems are also deployability problems: smart @nic[s] sit at the
choke point between a server and the network, warranting high assurance in
order to be deployed large scale.  First and foremost we need to verify that
the smart @nic's _functional correctness_.  We first need to specify what is
the correct behaviour of the smart @nic and OS formally, by defining
_contracts_ for each part of the system.  Some of these contracts can be
automatically derived from protocols imposed by existing components of the
system, for example a model of the cache-coherence protocol.  We will also need
to specify some parts of the system by hand.

After acquiring specifications for each component, we then have to prove that
the implementation upholds the formal contract.  We verify hardware components
with various @abv techniques and software components with program verifiers.
We can then compose all specifications of components, abstract away
implementation details, and prove the higher-level correctness property.

== Progress to Date #lim[ca #half page]

The doctoral student has previously finished his master thesis on porting the
PsPIN smart @nic platform to Xilinx @fpga[s], which are from the same vendor as
@fpga[s] in Enzian.  FPsPIN~@schneider_fpspin_2024 combines the Corundum @fpga
@nic platform with PsPIN to create a prototype Ethernet smartNIC.  This work
helped him acquire necessary skills for @fpga development and in building
Ethernet-based smart @nic[s].

The doctoral student has partaken in building a prototype @pio @nic for the
@pio paper~@ruzhanskaia_rethinking_2024 using SpinalHDL, a hardware description
language embedded in Scala.  The basic @nic prototype passes raw Ethernet
frames between a CPU core and the @fpga attached over ECI using a variant of
the 2Fast2Forward protocol.  It serves as a proof-of-concept for
message-passing between CPU and device, as well as the foundation for the @rpc
smart @nic prototype as we discussed in @goals-prototype.

The doctoral student has finished a basic smart @nic that can offload
unmarshaling of @oncrpc requests based on the @pio @nic prototype;
implementation of the supporting system software is in progress.  Further
supplied with the @rpc encoding pipeline, this @nic will be able to demonstrate
offloading of very simple #[@oncrpc]-based applications like a calculator
service.  The rest of the prototype system builds upon this preliminary demo.

== Detailed Work Plan #lim[ca 1 page] <work-pkgs>

We list out the exact work packages for each critical aspect of concern, as we
have previously detailed in @goals.

=== Base System <work-pkgs-base-system>

#work-package([Basic @oncrpc @nic], [3 months]) <basic-nic>

Offload @oncrpc marshaling and unmarshaling in hardware; the CPU core should be
able to run the @rpc handler by loading a cache line, and to return the results
by writing to a cache line.  This includes porting a simple demo application
that builds on @oncrpc to be accelerated by the smart @nic.  We let the Linux
kernel schedule the user-space applications naively.

During development, we specify expected behaviour and verify correctness of
hardware we build with @abv paradigms.  These specifications will facilitate
later formal verification efforts in @specification.

#work-package([Integrated buffer management], [3 months]) <buffer-mgmt>

A solution for allocating memory in the decoding pipeline is needed for
variable-length fields in the @rpc message.  We exchange memory arenas between
the CPU and smart @nic to allow decoding and encoding such fields.  This will
enable more complex @oncrpc services like a @nfs server; we tackle this in
@real-systems.

/*
#work-package([Protocol design for HW offloading], [to be determined])

#todo[remove this work package? otherwise, find proper related work in
@related-work-proto-design]
*/

#work-package([Integrated task scheduling], [3 months]) <scheduling>

Integrate with the Linux scheduler to steer incoming @rpc requests to worker
cores that are not busy, replacing the naive approach in @basic-nic.  The smart
@nic should keep track of states of worker cores with help from internal
scheduler states, acquired over the cache-coherent interconnect.  We should be
able to show improvements in tail latency and efficiency in core utilization.

=== Deployability

#work-package([Implement real systems with our smart @nic], [6 months]) <real-systems>

Start implementing real workloads with the demo system implemented in
@basic-nic, while integrating @buffer-mgmt and @scheduling as they become
ready.  Candidates include a @nfs server, a communication subsystem for
Dandelion, and micro-service benchmark suites like
DeathStarBench~@gan_open-source_2019 are potential targets.  We might need to
implement other serialization protocols like ProtoBuf in @fpga or integrate
existing IP cores.

#work-package([Telemetry and instrumentation], [3 months]) <telemetry>

Basic telemetry through performance and event counters should already be
integrated as the system is built in @basic-nic.  We need to further explore
what to collect for more in-depth tracing by talking to industry partners.
Trace collection should mostly be done in hardware on the @fpga to avoid
_degrading_ traced endpoints' performance.  We then need to build tools to
analyze the collected traces and provide insight.

#work-package([Multi-tenancy and virtualization], [1 year])

Map @pio region into each VM to allow multiplexed access to smart @nic.
Implement multiple partitions on hardware scheduler from @scheduling to allow
dispatching to a specific group of cores running the tenant VM.  Hardware
scheduler in the smart @nic should be able to _wake up_ a specific VM by
contacting the hypervisor scheduler.  We reason about security and performance
isolation properties between multiple tenants as part of @specification.

=== Security

#work-package([Specify all hardware and software components], [6 months]) <specification>

We reuse specifications and models of existing components in the system, for
example the cache-coherence components in the CPU and @fpga, from previous work
in the group on conformance testing and specification synthesis.  We manually
specify new components in the system.  Many components should already be
partially specified during development and testing in @basic-nic; we bridge the
gap to allow all specifications to be composed to prove the collective
correctness property.

#work-package([Prove that implementations match specification], [6 months]) <correctness-proof>

We employ multiple paradigms to check that the implementation of each component
matches the acquired specification in @specification.  We utilize conventional
@abv methods like simulation and symbolic execution, as well as blackbox
testing methods developed in the group.

== Publication Plan

The basic smart @nic prototype described in @work-pkgs-base-system, together
with one real system implementation in @real-systems, should warrant one paper
in a systems top conference (e.g.  ASPLOS, SOSP, OSDI, etc.).  Virtualization
and multi-tenancy support is complicated enough for a separate publication in
similar venues.

Telemetry and instrumentation work from @telemetry can result in a good paper
in conferences like SIGMETRICS; coupled with network-level characterization we
might get into NSDI.

Specifying (@specification) and verifying (@correctness-proof) all system
components can lead to a paper in security conferences like S&P.  We might have
to develop new specification and verification methods, which would result in a
paper in conferences on formal methods like FM.

== Time Schedule #lim[ca #half page]

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


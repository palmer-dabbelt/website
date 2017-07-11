TITLE: Frequently Asked Questions about RISC-V Software
--------------------------------

# Frequently Asked Questions about RISC-V Software

As the maintainer of various RISC-V related software projects, I've found that
I keep answering the same questions about RISC-V -- frequently from the same
people!  As such, I think it's best to maintain a FAQ list so people don't have
to keep asking the same question over and over again via email.

This FAQ focuses on answering common questions about RISC-V software.  Each
subject contains a short list that contains every question along with a
one-sentence answer, along with a link to a longer-form answer.  If you're new
to RISC-V, it will probably save you time in the long run to read all the short
answers, as you'll probably end up needing to figure most of them out at some
point anyway.  The longer answers tend to be quite verbose as they describe not
only the answer but why we arrived at that particular solution, and as such are
meant to be more fun than useful.

If you think a question should be on this list, then feel free to either
[email](http://www.google.com/recaptcha/mailhide/d?k=01fm-8WTM-kTwRkZd8rLZxmQ==&c=Bu87McGCMC3MvPApw0RqbH1gzipCRUUpLnzplgltk-I=)
me or submit a [pull
request](https://github.com/palmer-dabbelt/website/compare) against the source
of this website.

## Short-Form Answers

### Contributing to RISC-V Projects

[How do I file a bug?](#how-do-i-file-a-bug-): Look up the
[maintainer](riscv-maintainers.html) and file it however they suggest.

[How do I submit a patch?](#how-do-i-submit-a-patch-): Look up the
[maintainer](riscv-maintainers.html) and submit it however they suggest.

### The RISC-V Toolchain (GCC, binutils, glibc, and newlib)

[What is the difference between the -mabi and -march
options?](#what-is-the-difference-between-the--mabi-and--march-options-):
-march selects the architecture (a.k.a. ISA), -mabi selects the ABI, and -mtune
selects the microarchitecture.

[Where is the 32-bit toolchain?](#where-is-the-32-bit-toolchain-): Toolchains
prefixed by riscv32 and riscv64 support all RISC-V ISAs, just pass -march=ISA
and -mabi=ABI.

## Long-Form Answers

### Contributing to RISC-V Projects

#### How do I file a bug?

Before contributing to a project, you should at least read the relevant
section's short-form FAQ entries as it's possibly the problem you're trying to
fix is one we've already encountered.  If you see your problem there, you
should read the long-form FAQ entry as it's possible we've already though of
your solution and there's a reason it's not feasible.

When you're sure what you've found is a valid bug, the RISC-V port is upstream,
and you're comfortable with whatever bug tracking system upstream uses; then
feel free to file the bug upstream.  Otherwise, check the [maintainers
list](riscv-maintainers.html) for the location we track bugs for out-of-tree
ports or a secondary bug tracker that may be easier to use.

#### How do I submit a patch?

Just like every project tracks bugs in a different manner, every project has
their own special way of managing patches.  In general, if you're familiar with
the project then we are fine accepting code contributions however upstream
handles them -- though if you're familiar with the project, you're probably
either not here or the RISC-V port isn't upstream yet so there isn't a
maintainer.

If you're looking for specific help as to how to submit a patch to the RISC-V
maintainers of an in-tree port, an out-of-tree port, or some RISC-V-specific
software, then the best place to check is the [maintainers
list](riscv-maintainers.html).  We tend to use [Git
Hub](https://github.com/riscv) to manage our ports (both in-tree and
out-of-tree), so if the maintainers list is out of date then you should check
there (and tell me the list is broken).

### Toolchain-Related Questions (GCC, binutils, glibc, and newlib)

#### What is the difference between the -mabi and -march options?

We have decided to describe a RISC-V target using three bases:

* ``-march=ISA`` selects the architecture to target.  This controls which
  instructions and registers are available for the compiler to use.  We use
  lowercase RISC-V ISA strings to describe an architecture, as they've been
  standardized by the RISC-V ISA document (the lower case is a UNIX-ism, but
  one necessary to make some of the more esoteric tools work).  The ISA
  determines the set of architectures code can run on.
* ``-mabi=ABI`` selects the ABI to target.  This controls the calling
  convention (which arguments are passed in which registers) and the layout of
  data in memory.  One argument specifies both the integer and floating-point
  ABIs on RISC-V: we use the standard naming scheme for integer ABIs (``ilp32``
  or ``lp64``), with an optional single letter appended to select the
  floating-point registers used by the ABI (``ilp32`` vs ``ilp32f`` vs
  ``ilp32d``).  In order for objects to be linked together, they must follow
  the same ABI.
* ``-mtune=CODENAME`` selects the microarchitecture to target.  This informs
  GCC about the performance of each instruction, allowing it to perform
  target-specific optimizations.  This tuning should only effect performance,
  and as RISC-V is such a simple ISA it currently doesn't do much at all.

To get a bit more specific: Version 2.2 of the RISC-V User-Level ISA concretely
defines three base ISAs that are supported by the toolchain

* RV32I: A load-store ISA with 32, 32-bit general-purpose integer registers.
* RV32E: An embedded flavor of RV32I with only 16 integer registers.
* RV64I: A 64-bit flavor of RV32I where the general-purpose integer registers
  are 64-bits wide.

In addition to these base ISAs, a handful of extensions have been specified.
The extensions that have both been specified and are supported by the toolchain
are

* M: Integer Multiplication and Division
* A: Atomic Instructions
* F: Single-Precision Floating-Point
* D: Double-Precision Floating-Point
* C: Compressed Instructions

RISC-V ISA strings are defined by appending the supported extensions to the
base ISA in the order listed above.  For example, the RISC-V ISA with 32,
32-bit integer registers and the instructions to for multiplication would be
denoted as ``RV32IM``.  Users can control the set of instructions that GCC uses
when generating assembly code by passing the lower-case ISA string to the
``-march`` GCC option: for example ``-march=rv32im``.

On RISC-V systems that don't support particular operations, emulation routines
may be used to provide the missing functionality.  For example the following C code

  double dmul(double a, double b) {
    return a * b;
  }

will compile directly to a FP multiplication instruction when compiled with the
D extension

  $ riscv64-unknown-elf-gcc test.c -march=rv64gc -mabi=lp64d -o- -S -O3
  dmul:
    fmul.d  fa0,fa0,fa1
    ret

but will compile to an emulation routine without the D extension

  $ riscv64-unknown-elf-gcc test.c -march=rv64i -mabi=lp64 -o- -S -O3
  dmul:
          add     sp,sp,-16
          sd      ra,8(sp)
          call    __muldf3
          ld      ra,8(sp)
          add     sp,sp,16
          jr      ra

In addition to controlling the instructions available to GCC during code
generating (which defines the set of implementations the generated code will
run on), users can select from various ABIs to target (which defines the
calling convention and layout of objects in memory).  Objects and libraries may
only be linked together if they follow the same ABI.

RISC-V defines two integer ABIs and three floating-point ABIs, which together
are treated as a single ABI string.  The integer ABIs follow the standard ABI
naming scheme:

* ``ilp32``: ``int``, ``long``, and pointers are all 32-bits long.  ``long
  long`` is a 64-bit type, ``char`` is 8-bit, and ``short`` is 16-bit.
* ``lp64``: ``long`` and pointers are 64-bits long, while ``int`` is a 32-bit
  type.  The other types remain the same as ilp32.

while the floating-point ABIs are a RISC-V specific addition:

* "" (the empty string): No floating-point arguments are passed in registers.
* ``f``: 32-bit and smaller floating-point arguments are passed in registers.  This
  ABI requires the F extension, as without F there are no floating-point
  registers.
* ``d``: 64-bit and smaller floating-point arguments are passed in registers.  This
  ABI requires the D extension.

Just like ISA strings, ABI strings are concatenated together and passed via the
``-mabi`` argument to GCC.

* ``-march=rv32imafdc -mabi=ilp32d``: Hardware floating-point instructions can
  be generated and floating-point arguments are passed in registers.  This is
  like the ``-mfloat-abi=hard`` option to ARM's GCC.
* ``-march=rv32imac -mabi=ilp32``: No floating-point instructions can be
  generated and no floating-point arguments are passed in registers.  This is
  like the ``-mfloat-abi=soft`` argument to ARM's GCC.
* ``-march=rv32imafdc -mabi=ilp32``: Hardware floating-point instructions can
  be generated, but no floating-point arguments will be passed in registers.
  This is like the ``-mfloat-abi=softfp`` argument to ARM's GCC, and is usually
  used when interfacing with soft-float binaries on a hard-float system.
* ``-march=rv32imac -mabi=ilp32d``: Illegal, as the ABI requires floating-point
  arguments are passed in registers but the ISA defines no floating-point
  registers to pass them in.

As a more concrete example, let's examine how the following C program is
compiled for a host of ISA/ABI pairs:

  double dmul(double a, double b) {
    return a * b;
  }

  $ riscv64-unknown-elf-gcc test.c -march=rv32imac -mabi=ilp32 -o- -S -O3
  dmul:
    add     sp,sp,-16
    sw      ra,12(sp)
    call    __muldf3
    lw      ra,12(sp)
    add     sp,sp,16
    jr      ra

  $ riscv64-unknown-elf-gcc test.c -march=rv32imafdc -mabi=ilp32 -o- -S -O3
  dmul:
    add     sp,sp,-16
    sw      a0,8(sp)
    sw      a1,12(sp)
    fld     fa5,8(sp)
    sw      a2,8(sp)
    sw      a3,12(sp)
    fld     fa4,8(sp)
    fmul.d  fa5,fa5,fa4
    fsd     fa5,8(sp)
    lw      a0,8(sp)
    lw      a1,12(sp)
    add     sp,sp,16
    jr      ra

  $ riscv64-unknown-elf-gcc test.c -march=rv32imafdc -mabi=ilp32d -o- -S -O3
  dmul:
    fmul.d  fa0,fa0,fa1
    ret

  $ riscv64-unknown-elf-gcc test.c -march=rv32imac -mabi=ilp32d -o- -S -O3
  cc1: error: requested ABI requires -march to subsume the 'D' extension

The ``-mtune`` option is the least interesting of the bunch.  RISC-V is such a
simple ISA that it doesn't suffer from the decode problems that an ISA like ARM
or ia32 does, and the extant implementations are simple enough that it doesn't
suffer from odd instruction parings like the Pentium does, so there really
isn't much to control here.  Unless you're going to contribute a new tuning
model to GCC, you probably shouldn't bother setting this option.

#### Where is the 32-bit toolchain?

The RISC-V ports of binutils and GCC support all ISA variants using a single
binary, regardless of whether the binary is called ``riscv32-unknown-elf-gcc``
or ``riscv64-unknown-elf-gcc``.  Additionally, we usually produce multilib
toolchains so multiple copies of the C libraries are installed along with the
toolchain.  You can probably build code for your architecture by running

> ``riscv{32,64}-unknown-elf-gcc -march=ISA -mabi=ABI`` ...

where ISA and ABI are the ones you're interested in.  As there are many RISC-V
ISA and ABI variants, we only build C libraries for a handful of common
targets.  If your toolchain can't find a C library for your ISA/ABI pair, then
you can

* Pick a different (but similar) ISA.  As a hint, we really like the C
  extension so if you're not using it then you probably want to.
* Petition us to add a reuse pattern for your ISA/ABI pair, which will cause
  GCC to use a different C library (which a compatible ABI) when linking your
  code -- the code you actually build will be built with the ISA you specify.
  We have a handful of these for ISA/ABI pairs we felt were similar enough to
  each other, but we're amenable to adding more.
* Petition us to add support for your ISA/ABI pair to the default set of
  multilibs.  We picked the original set guessing as to what hardware would be
  popular, but if we're wrong we're amenable to adding more popular pairs.

While we agree it's a bit odd to have both the ``riscv32-*`` and ``riscv64-*``
tuples when there's functionally little difference (just the default ISA and
ABI targets), there wasn't really a good option when specifying these.  There
are three styles of architecture tuples for ISAs that have both 32-bit and
64-bit tuples:

* ``arm-*/aarch64-*``, ``tilepro-*/tilegx-*``: These ports are entirely
  separate: for example the ``arm-*`` toolchain only supports ARMv7, and the
  ``aarch64-*`` toolchain only support ARMv8/aarch64.
* ``hppa-*/hppa64-*``, ``mips-*/mips3-*/mips64-*``, ``rs6000-* /
  powerpc-*/powerpc64-*``, ``sparc-*/sparcv8-*/sparcv9-*/sparc64-*``,
  ``sh-*/sh2-*/sh3-*/sh4-*/sh64-*``: These ports have two compiler tuples.  The
  newer tuple contains "64", and can target both their 32-bit and 64-bit ISAs.
  The older tuple contains no suffix and can only target the 32-bit ISA.  For
  the targets with multiple tuples, those other tuples just behave as aliases
  (aside from maybe a default ISA target difference).
* ``i386-*/i486-*/i586-*/i686-*/x86_64-*``: These ports avoid the ambiguity
  when referring to the 32-bit version, but otherwise act like above.

On RISC-V, we originally had our tuples called ``riscv-*`` and ``riscv32-*``.
This was confusing, as the non-suffixed version's polarity was different than
all the other architectures.  In order to avoid this confusion, we decided to
follow the naming scheme that Intel uses, and that it appears that ARM would
use if they ever bother with an aarch32 port (which I assume they won't).  If
we'd left it the other way, we'd still have the same FAQ text here, the title
would just be "where is the 64-bit toolchain?" :).

There's two things were doing that aren't standard:

* We didn't bother with an ambiguous tuple alias, as it was suggested we
  shouldn't have one.  I think if people though there was going to be a mips64
  they would have called it mips32 instead of just mips -- they did this when
  renaming the ISA, but it's very hard to rename ambiguous things in
  software-land so they'll be stuck with that forever.
* Our 32-bit toolchain can generate 64-bit ELFs.

Note that it's not feasible to have a single target, as some platforms do not
support 64-bit BFDs and therefor there needs to be some 32-bit-only tuple.

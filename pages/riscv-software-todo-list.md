TITLE: RISC-V Software TODO List
---------------------------------

# RISC-V Software TODO List

There's a lot of work left to be done WRT RISC-V software, so I though
I'd keep a TODO list around in case people were looking for projects to
start on.

## Linux Memory Map

Our memory map wasn't particularly well though out.  As a result this is
frequently a source of bugs, and they're always a headache to track
down.  This part of the port has been around for a while and has a
handful of known issues, so it's probably time to just go ahead and
think through the memory map.  [Anup's post re-ordering the memory map
for 32-bit
targets](https://lore.kernel.org/linux-riscv/20190816114915.4648-1-anup.patel@wdc.com/)
has some more information.  I also know we don't map I/O memory, which
causes trouble for PCIe.

## Linear-time linker relaxation via `R_RISCV_DELETE`

Our linker relaxations are quadratic time: they walk all the
relocations, shifting the entire binary down every time one is deleted.
This results in large binaries linking very slowly, which is a headache
for development.  It also makes the linker relaxation code very
complicated because relocations can alias as the binary shifts around,
so extra pessimism needs to be added for the PC-relative relaxations.

## Various larger code models

We currently only have 32-bit code models for RISC-V targets, which are
too small for some systems.  This manifests in both embedded systems
with sparse address maps and UNIX systems with large program images.
The simplest option may be to have a 64-bit inline addressing mode,
which can be relaxed to various 

    64-bit address:
        lui  t0, SYMBOL_64_45
        addi t0, t0, SYMBOL_44_33
      c.slli t0, t0, 32
        lui  t1, SYMBOL_32_12
      c.add  t0, t0, t1
        lw   t0, SYMBOL_11_0(t0)
    
    53-bit address:
        lui  t0, LG(x)
      c.slli t0, t0, 20
        lui  t1, HI20(x)
      c.add  t0, t0, t1
        lw   t0, LO12(t0)(x)

    43-bit address:
        lui  t0, SYMBOL_42_24
        addi t0, t0, SYMBOL_23_12
      c.slli t0, t0, 12
        lw   t0, SYMBOL_11_0(x)(t0)    

    32-bit address:
        lui  t0, HI20(x)
        lw   t0, LO12(t0)(x)
    
    12-bit addresses
        lw   t0, GPREL_LO12(gp)(x)

## Sv48 in Linux

Our Linux port only supports Sv39, and while it is mandated that all
UNIX-platform implementations support Sv39 there will be systems that
support the larger addressing modes to access more memory.  Our paging
code is quite messy and should be cleaned up as part of adding Sv48
support.  Ideally we would have support for both dynamically choosing
Sv39 vs Sv48 (ie, at runtime) but also picking the supported paging
depth at compile time.

## LLVM Sanitizers

The LLVM sanitizers (one of which is address sanitizer) are useful
development tools, and while the port isn't upstream yet there have been
various ports floating around for a while.  [A commit landed upstream in
LLVM but was reverted](https://reviews.llvm.org/D66870), which is
probably the best place to start.

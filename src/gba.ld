OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)
MEMORY {
  ROM (rx) : ORIGIN = 0x08000000, LENGTH = 32M
  RAM (rw) : ORIGIN = 0x02000000, LENGTH = 256K
}
SECTIONS {
  .text : { KEEP(*(.header)) *(.text*) *(.rodata*) . = ALIGN(4); } > ROM
  .bss (NOLOAD) : {
    . = ALIGN(4); __bss_start = .; *(.bss*) *(COMMON)
    . = ALIGN(4); __bss_end = .;
  } > RAM
  /DISCARD/ : { *(.comment) *(.note*) }
}
ASSERT(SIZEOF(.bss) < 0x3F000, "Game state exceeds EWRAM")

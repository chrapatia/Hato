CFILES 		:= $(shell find src/ -type f -name '*.c')
ASMFILES	:= $(shell find src/ -type f -name '*.s')
CC			= gcc
AS			= nasm
LD			= ld
OBJ			:= $(CFILES:.c=.c.o) $(ASMFILES:.s=.s.o)
KERNEL_HDD 	= build/disk.hdd
KERNEL_ELF 	= kernel.elf

CFLAGS :=						   \
  	-Wall						   \
	-Wextra						   \
	-Werror           			   \
	-std=gnu11                     \
	-ffreestanding                 \
	-Isrc/arch/                    \
	-Isrc/						   \

LDHARDFLAGS := 			      \
	-nostdlib                 \
	-z max-page-size=0x1000   \
	-T src/linker.ld

ASFLAGS :=					  \
		-f elf64

.PHONY: clean
.DEFAULT_GOAL = $(KERNEL_HDD)

disk: $(KERNEL_HDD)
	qemu-system-i686 -m 2G -hda $(KERNEL_HDD)

%.c.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.s.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^

$(KERNEL_ELF): $(OBJ)
	$(LD) $(LDHARDFLAGS) $(OBJ) -o $@

$(KERNEL_HDD): $(KERNEL_ELF)
	-mkdir build
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(KERNEL_HDD)
	parted -s $(KERNEL_HDD) mklabel msdos
	parted -s $(KERNEL_HDD) mkpart primary 1 100%
	echfs-utils -m -p0 $(KERNEL_HDD) quick-format 32768
	echfs-utils -m -p0 $(KERNEL_HDD) import $(KERNEL_ELF) $(KERNEL_ELF)
	echfs-utils -m -p0 $(KERNEL_HDD) import limine.cfg limine.cfg
	limine/limine-install limine/limine.bin $(KERNEL_HDD)

clean:
	-rm -f $(KERNEL_HDD) $(KERNEL_ELF) $(OBJ)

run: $(KERNEL_HDD)
	/mnt/c/"Program Files"/qemu/qemu-system-x86_64.exe build/disk.hdd
	@nc localhost 1234

# pour start le disk.hdd
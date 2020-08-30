CFILES    := $(shell find src/ -type f -name '*.c')
CC         = gcc
LD         = ld
OBJ       := $(CFILES:.c=.o)
KERNEL_HDD = build/disk.hdd
KERNEL_ELF = kernel.elf

CHARDFLAGS := $(CFLAGS) -Wall -Wextra -Werror               \
	-DBUILD_TIME='"$(BUILD_TIME)"' \
	-std=gnu11                     \
	-fno-pic                       \
	-mno-sse                       \
	-mno-sse2                      \
	-mno-mmx                       \
	-mno-80387                     \
	-mno-red-zone                  \
	-mcmodel=kernel                \
	-ffreestanding                 \
	-fno-stack-protector           \
	-fno-omit-frame-pointer        \
	-Isrc/arch/                       \
	-Isrc/							

LDHARDFLAGS := $(LDFLAGS)        \
	-nostdlib                 \
	-no-pie                   \
	-z max-page-size=0x1000   \
	-T src/linker.ld

.PHONY: clean
.DEFAULT_GOAL = $(KERNEL_HDD)

disk: $(KERNEL_HDD)
	qemu-system-x86_64 -m 2G -hda $(KERNEL_HDD)

%.o: %.c
	$(CC) $(CHARDFLAGS) -c $< -o $@

$(KERNEL_ELF): $(OBJ)
	$(LD) $(LDHARDFLAGS) $(OBJ) -o $@

$(KERNEL_HDD): $(KERNEL_ELF)
	-mkdir build
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(KERNEL_HDD)
	parted -s $(KERNEL_HDD) mklabel msdos
	parted -s $(KERNEL_HDD) mkpart primary 1 100%
	echfs-utils -m -p0 $(KERNEL_HDD) quick-format 32768
	echfs-utils -m -p0 $(KERNEL_HDD) import $(KERNEL_ELF) $(KERNEL_ELF)
	echfs-utils -m -p0 $(KERNEL_HDD) import qloader2.cfg qloader2.cfg
	qloader2/qloader2-install qloader2/qloader2.bin $(KERNEL_HDD)

clean:
	-rm -f $(KERNEL_HDD) $(KERNEL_ELF) $(OBJ)

run: $(KERNEL_HDD)
	@VBoxManage.exe -q startvm --putenv VBOX_GUI_DBG_ENABLED=true Hato
	@nc localhost 1234

CURRENTDIR	= .
SRCDIR		= $(CURRENTDIR)/src
OUTPUTDIR	= $(CURRENTDIR)/output

INCLUDEDIR	= $(CURRENTDIR)/include
COMPILER_DIR	= /home/zhai/arm-linux/arm-2011.03/lib/gcc/arm-none-eabi/4.5.2

# Linker script 
BASE_ADDR	?= 0x00000000
BOOT_LAYOUT_IN	= $(SRCDIR)/niuboot.ld.in
BOOT_LAYOUT_OUT	= $(OUTPUTDIR)/niuboot.ld


# Output ELF image
NIUBOOT_ELF	= $(OUTPUTDIR)/niuboot

# Output binary image
NIUBOOT_BIN	= $(OUTPUTDIR)/niuboot.bin

CROSS_COMPILE ?= arm-none-eabi-

AS	= $(CROSS_COMPILE)as
CC	= $(CROSS_COMPILE)gcc
LD	= $(CROSS_COMPILE)ld
CPP	= $(CROSS_COMPILE)cpp
STRIP	= $(CROSS_COMPILE)strip
OBJCOPY	= $(CROSS_COMPILE)objcopy
OBJDUMP	= $(CROSS_COMPILE)objdump

LIBGCCDIR = $(dir $(shell $(CC) -print-libgcc-file-name))
CFLAGS 	= -Wall -I$(INCLUDEDIR) -I$(COMPILER_DIR)/include -nostdinc -fno-builtin -O -g
LDFLAGS = -static -nostdlib -T $(BOOT_LAYOUT_OUT) -L$(LIBGCCDIR)  -lgcc

CFLAGS += -DSWORD


# Generic code
SRC_OBJS = entry.o serial.o main.o utils.o init.o gpmi.o dm9000x.o net.o


NIUBOOT_OBJS = $(addprefix $(SRCDIR)/, $(SRC_OBJS))
#		  $(addprefix $(BOARDDIR)/, $(BOARD_OBJS)) \
#		  $(addprefix $(HWDIR)/, $(HW_OBJS))

# Default goal
.PHONY: all
all: build



#
# Define an implicit rule for assembler files
# to run them through C preprocessor
#
%.o: %.S
	$(CC) -c $(CFLAGS) -D__ASSEMBLY__ -o $@ $<

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

#
# Make targets
#
.PHONY: build build_prep clean

build: build_prep $(NIUBOOT_BIN)

build_prep:
	mkdir -p $(OUTPUTDIR)

clean:
	@echo Cleaning...
	@echo Files:
	rm -rf $(NIUBOOT_OBJS) $(BOOT_LAYOUT_OUT)
	@echo Build output:
	rm -rf $(OUTPUTDIR)

##
## Rules to link and convert niuboot image
## 

$(NIUBOOT_BIN): $(NIUBOOT_ELF)
	$(OBJCOPY) -R -S -O binary -R .note -R .note.gnu.build-id -R .comment $< $@

$(NIUBOOT_ELF): $(NIUBOOT_OBJS) $(BOOT_LAYOUT_OUT)
	$(LD) -o $@ $(NIUBOOT_OBJS) $(LDFLAGS)
	@nm -n $@ > $@.map

$(BOOT_LAYOUT_OUT): $(BOOT_LAYOUT_IN)
	$(CPP) -P -DBASE_ADDR=$(BASE_ADDR) -o $@ $<


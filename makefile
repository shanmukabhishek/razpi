ARMGNU=aarch64-linux-gnu

CFLG=-Wall -nostdlib -nostartfiles -ffreestanding -Iinclude -mgeneral-regs-only
AFLG=-Iinclude

DIR_BUILD=bin
DIR_SRC=src

all: kernel.img

clean:
	- rm -rf $(DIR_BUILD) *.img	

$(DIR_BUILD)/%_c.o: $(DIR_SRC)/%.c
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(CFLG) -MMD -c $< -o $@

$(DIR_BUILD)/%_S.o: $(DIR_SRC)/%.S
	$(ARMGNU)-gcc $(AFLG) -MMD -c $< -o $@

C_FILES = $(wildcard $(DIR_SRC)/*.c)
ASM_FILES = $(wildcard $(DIR_SRC)/*.S)
OBJ_FILES = $(C_FILES:$(DIR_SRC)/%.c=$(DIR_BUILD)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(DIR_SRC)/%.S=$(DIR_BUILD)/%_S.o)

DEP_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

kernel.img: $(DIR_SRC)/linker.ld $(OBJ_FILES)
	$(ARMGNU)-ld -T $(DIR_SRC)/linker.ld -o $(DIR_BUILD)/kernel.elf $(OBJ_FILES)
	$(ARMGNU)-objcopy $(DIR_BUILD)/kernel.elf -O binary kernel.img

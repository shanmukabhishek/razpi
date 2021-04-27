ARMGNU=aarch64-linux-gnu

CFLG=-Wall -nostdlib -nostartfiles -ffreestanding -Iinclude -mgeneral-regs-only
AFLG=-Iinclude

DIR_BUILD=bin
DIR_SRC=src

all: kernel.img

clean:
	- rm -rf $(DIR_BUILD) *.img	

build_src:
	$(ARMGNU)-gcc $(CFLG) -MMD 
$(DIR_BUILD)/%_c.o: $(DIR_SRC)/%.c
	mkdir -p $(@D)
	$(ARMGNU)-gcc $(CFLG) -MMD $< -o $@

$(DIR_BUILD)/%_s: $(SRC_DIR)/%.s
	$(ARMGNU)-gcc $(AFLG) -MMD $< -o $@

C_FILES= $(wildcard $(DIR_SRC)/*.c)
ASM_FILES= $(wildcard $(DIR_SRC)/*.s)
OBJ_FILES= $(C_FILES:$(DIR_SRC)/%.c=$(DIR_BUILD)/%_c.o)
OBJ_FILES += $(ASM_FILES:$(DIR_SRC)/%.s:$(DIR_BUILD)/%_s.o)

DPE_FILES = $(OBJ_FILES:%.o=%.d)
-include $(DEP_FILES)

kernel.img: $(DIR_SRC)/linker.ld $(OBJ_FILES)
	$(ARMGNU)-ld -T $(DIR_SRC)/linker.ld -o $(DIR_BUILD)/kernel.elf $(OBJ_FILES)
	$(ARMGNU)-objcopy $(DIR_BUILD)/kernel.elf -O kernel.img

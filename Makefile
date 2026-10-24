PYTHON ?= python3
CROSS ?= arm-none-eabi-
AS := $(CROSS)as
LD := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
TARGET := build/gateblade

.PHONY: all clean test emulator play verify demo package
all: $(TARGET).gba

build/assets.stamp: tools/assets.py tools/maps.py assets/stages.json
	mkdir -p build
	$(PYTHON) tools/assets.py
	touch $@

$(TARGET).o: src/main.s src/constants.inc src/game.s src/render.s build/assets.stamp
	$(AS) -mcpu=arm7tdmi -g -o $@ src/main.s

$(TARGET).elf: $(TARGET).o src/gba.ld
	$(LD) -T src/gba.ld -Map=$(TARGET).map -o $@ $<

$(TARGET).gba: $(TARGET).elf tools/rom.py
	$(OBJCOPY) -O binary $< $@
	$(PYTHON) tools/rom.py $@

emulator:
	sh tools/setup_emulator.sh

test: all
	$(PYTHON) tools/test_game.py

verify: test
	$(PYTHON) tools/check_docs.py

play: all
	build/emulator/sdl/mgba $(TARGET).gba

demo: all
	sh tools/demo.sh

package: verify
	$(PYTHON) tools/package.py

clean:
	rm -f build/gateblade.o build/gateblade.elf build/gateblade.gba build/gateblade.map build/assets.stamp
	rm -rf build/assets build/test-results

PYTHON ?= python3
CROSS ?= arm-none-eabi-
AS := $(CROSS)as
LD := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
TARGET := build/gateblade

.PHONY: all clean test emulator play verify demo package learn lessons test-learn snippets
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

verify: test test-learn snippets
	$(PYTHON) tools/check_docs.py

play: all
	build/emulator/sdl/mgba $(TARGET).gba

demo: all
	sh tools/demo.sh

package: verify
	$(PYTHON) tools/package.py

clean:
	rm -f build/gateblade.o build/gateblade.elf build/gateblade.gba build/gateblade.map build/assets.stamp
	rm -rf build/assets build/test-results build/learn

# Beginner path: four ROMs from one source file, no asset generator.
STEP ?= 4
learn: build/learn/step-$(STEP).gba

lessons: build/learn/step-1.gba build/learn/step-2.gba build/learn/step-3.gba build/learn/step-4.gba

build/learn/step-%.o: learn/main.s
	mkdir -p build/learn
	$(AS) -mcpu=arm7tdmi --defsym LESSON=$* -g -o $@ $<

build/learn/step-%.elf: build/learn/step-%.o learn/gba.ld
	$(LD) -T learn/gba.ld -o $@ $<

build/learn/step-%.gba: build/learn/step-%.elf tools/rom.py
	$(OBJCOPY) -O binary $< $@
	$(PYTHON) tools/rom.py $@

# Keep ELF symbols for the tests and debugger.
.SECONDARY:
test-learn: lessons
	$(PYTHON) tools/test_learn.py
	$(PYTHON) tools/test_article.py

snippets:
	$(PYTHON) tools/article_snippets.py --check

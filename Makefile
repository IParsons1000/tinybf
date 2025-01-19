ASM ?= nasm
ASMFLAGS ?=
ASMFLAGS += -f elf64
ASMFLAGS += -F dwarf -g
LD ?= ld
LDFLAGS ?=
LDFLAGS += -m elf_x86_64
RM ?= rm

.PHONY: all clean spotless

all: brainfuck

brainfuck: brainfuck.o
	$(LD) $(LDFLAGS) -o brainfuck brainfuck.o

brainfuck.o: brainfuck.S
	$(ASM) $(ASMFLAGS) brainfuck.S

clean:
	-$(RM) -f brainfuck.o

spotless: clean
	-$(RM) -f brainfuck

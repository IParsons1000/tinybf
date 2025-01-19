GDBFLAGS := -F dwarf -g

.PHONY: all clean spotless

all: brainfuck

brainfuck: brainfuck.o
	ld -m elf_x86_64 -o brainfuck brainfuck.o

brainfuck.o: brainfuck.S
	nasm -f elf64 $(GDBFLAGS) brainfuck.S

clean:
	-rm -f brainfuck.o

spotless: clean
	-rm -f brainfuck

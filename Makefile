#
# (c)2025 Ira Parsons
# tinybf - a tiny brainf*ck interpeter for linux in x86_64 assembly
#

ASM ?= nasm
ASMFLAGS ?=
ASMFLAGS += -f elf64
ASMFLAGS += -F dwarf -g
LD ?= ld
LDFLAGS ?=
LDFLAGS += -m elf_x86_64
CP ?= cp
RM ?= rm

.PHONY: all test install clean spotless

all: tinybf

tinybf: tinybf.o
	$(LD) $(LDFLAGS) -o tinybf tinybf.o

tinybf.o: tinybf.S
	$(ASM) $(ASMFLAGS) tinybf.S

test: tinybf
	sh test/test.sh . test

install: tinybf clean
	$(CP) tinybf /bin
	$(CP) tinybf.1.gz /usr/share/man/man1

clean:
	-$(RM) tinybf.o

spotless: clean
	-$(RM) tinybf

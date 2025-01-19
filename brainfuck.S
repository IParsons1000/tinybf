; instructions <-- read in file (rax is instruction pointer)
; data array --> stack (rbp is [0], rsp is data pointer)
; input <-- stdin
; output --> stdout

global _start
_start:
    mov rax, [rsp] ; argc
    cmp rax, 2
    jl .fail

    xor rdx, rdx
    mov rsi, rdx
    mov rdi, [rsp+16] ; argv[1]
    mov rax, 2
    syscall ; open(argv[1], 0, 0)
    cmp rax, -1
    je .fail
    push rax ; fd

    mov rdx, 2
    xor rsi, rsi
    mov rdi, rax ; fd
    mov rax, 8
    syscall ; lseek(fd, 0, SEEK_END)
    cmp rax, -1
    je .fail
    push rax ; file len
    xor rdx, rdx
    mov rax, 8
    syscall ; lseek(fd, 0, SEEK_SET)
    cmp rax, -1
    je .fail

    xor r9, r9
    mov r8, -1
    mov r10, 34
    mov rdx, 7
    pop rsi ; file len
    push rsi
    xor rdi, rdi
    mov rax, 9
    syscall ; mmap(0, file_len, 7, 34, -1, 0)
    cmp rax, -1
    je .fail

    pop rdx ; file len
    mov rsi, rax
    pop rdi ; fd
    push rsi ; addr of file in mem
    xor rax, rax
    syscall ; read(fd, addr, file_len)
    cmp rax, -1
    je .fail

    pop rax ; instruction ptr
    xor rbx, rbx ; current instruction (bl)
    mov rcx, rax ; base of instructions
    mov rbp, rsp ; base of data stack
    dec rsp      ; data[0]
    mov r9, rsp ; keep track of stack size (lowest addr)
    mov BYTE [rsp], bl

.run:
    mov bl, BYTE [rax]
    cmp bl, '>'
    jne .r1
    dec rsp
    cmp rsp, r9
    jl .r0
    jmp .run.loop
.r0:
    dec r9
    xor rdx, rdx
    mov BYTE [rsp], dl
    jmp .run.loop
.r1:
    cmp bl, '<'
    jne .r2
    cmp rsp, rbp
    je .run.loop
    inc rsp
    jmp .run.loop
.r2:
    cmp bl, '+'
    jne .r3
    mov dl, BYTE [rsp]
    inc dl
    mov BYTE [rsp], dl
    jmp .run.loop
.r3:
    cmp bl, '-'
    jne .r4
    mov dl, BYTE [rsp]
    dec dl
    mov BYTE [rsp], dl
    jmp .run.loop
.r4:
    cmp bl, '.'
    jne .r5
    mov rsi, rsp
    mov rsp, r9
    dec rsp
    push rsi
    push rax
    push rbx
    push rcx
    mov rdx, 1
    mov rdi, 1
    mov rax, 1
    syscall ; write(stdout, data[i], 1)
    pop rcx
    pop rbx
    pop rax
    pop rsp
    jmp .run.loop
.r5:
    cmp bl, ','
    jne .r6
    mov rsi, rsp
    mov rsp, r9
    dec rsp
    push rsi
    push rax
    push rbx
    push rcx
    mov rdx, 1
    xor rdi, rdi
    mov rax, rdi
    syscall ; read(stdin, data[i], 1)
    pop rcx
    pop rbx
    pop rax
    pop rsp
    jmp .run.loop
.r6:
    cmp bl, '['
    jne .r7
    mov dl, BYTE [rsp]
    test dl, dl
    jne .run.loop
    mov r8, 1
.r61:
    inc rax
    mov dl, BYTE [rax]
    test dl, dl
    je .fail
    cmp dl, '['
    je .r62
    cmp dl, ']'
    je .r63
    jmp .r64
.r62:
    inc r8
    jmp .r64
.r63:
    dec r8
.r64:
    test r8, r8
    jne .r61
    jmp .run.loop
.r7:
    cmp bl, ']'
    jne .run.loop
    mov dl, BYTE [rsp]
    test dl, dl
    je .run.loop
    mov r8, 1
.r71:
    dec rax
    cmp rax, rcx ; fix to look for base
    jl .fail
    mov dl, BYTE [rax]
    cmp dl, ']'
    je .r72
    cmp dl, '['
    je .r73
    jmp .r74
.r72:
    inc r8
    jmp .r74
.r73:
    dec r8
.r74:
    test r8, r8
    jne .r71
    jmp .run.loop
.run.loop:
    inc rax
    test al, al
    jne .run
    xor rdi, rdi
    jmp .exit

.fail:
    mov rdi, 1
.exit:
    mov rax, 60
    syscall

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
    mov rbp, rsp
    dec rsp

.run:
    mov bl, BYTE [rax]
    cmp bl, '>'
    jne .r1
    dec rsp
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
    mov dl, [rsp]
    inc dl
    mov [rsp], dl
    jmp .run.loop
.r3:
    cmp bl, '-'
    jne .r4
    mov dl, [rsp]
    dec dl
    mov [rsp], dl
    jmp .run.loop
.r4:
    cmp bl, '.'
    jne .r5
    mov rsi, rsp
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
    jmp .run.loop
.r5:
    cmp bl, ','
    jne .r6
    mov rsi, rsp
    push rax
    push rbx
    push rcx
    mov rdx, 1
    mov rdi, 1
    xor rax, rax
    syscall ; read(stdin, data[i], 1)
    pop rcx
    pop rbx
    pop rax
    jmp .run.loop
.r6:
    cmp bl, '['
    jne .r7
    mov dl, [rsp]
    test dl, dl
    jne .run.loop
.r61:
    inc rax
    mov dl, BYTE [rax]
    test dl, dl
    je .fail
    cmp dl, ']'
    jne .r61
    jmp .run.loop
.r7:
    cmp bl, ']'
    jne .run.loop
    mov dl, [rsp]
    test dl, dl
    je .run.loop
.r71:
    dec rax
    cmp rax, rcx ; fix to look for base
    jl .fail
    mov dl, BYTE [rax]
    cmp dl, '['
    jne .r71
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

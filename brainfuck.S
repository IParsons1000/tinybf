; 
; (c)2025 Ira Parsons
; brainfuck - a tiny brainfuck interpreter for linux in x86_64 assembly
;

; overall architecture:
;   - instructions <-- read in from file (rax is the instruction pointer)
;   - data array --> stack (rsp is the data pointer)
;   - input <-- read byte from stdin
;   - output --> write byte to stdout

global _start
_start:
    mov rax, [rsp]     ; argc
    cmp rax, 2
    jl .fail           ; return 1 if no file is provided

    ; open provided file
    xor rdx, rdx       ;  mode (O_RDONLY)
    mov rsi, rdx       ;  flags (none)
    mov rdi, [rsp+16]  ;  argv[1]
    mov rax, 2         ;  sys_open
    syscall            ; open(argv[1], 0, 0);
    cmp rax, 0
    jl .fail           ; return EXIT_FAILURE if file can't be accessed
    push rax           ; fd of the provided file

    ; find file size
    mov rdx, 2         ;  whence (SEEK_END)
    xor rsi, rsi       ;  offset (0)
    mov rdi, rax       ;  fd supplied by open
    mov rax, 8         ;  sys_lseek
    syscall            ; lseek(fd, 0, SEEK_END)
    cmp rax, -1
    je .fail
    push rax           ; returned file len
                       ;  (preserve for the mmap syscall)

    ; reset ptr to head of file
    xor rdx, rdx       ;  whence (SEEK_SET)
                       ;  (other args preserved from previous call)
    mov rax, 8         ;  sys_lseek
    syscall            ; lseek(fd, 0, SEEK_SET)
    cmp rax, -1
    je .fail

    ; allocate space for file in memory
    xor r9, r9         ;  offset (0)
    mov r8, -1         ;  fd (-1)
    mov r10, 34        ;  flags (MAP_PRIVATE | MAP_ANONYMOUS)
    mov rdx, 7         ;  protection (PROT_READ | PROT_WRITE | PROT_EXEC)
    pop rsi            ;  file len from lseek
    push rsi           ;   (preserve for the read syscall)
    xor rdi, rdi       ;  addr (NULL)
    mov rax, 9         ;  sys_mmap
    syscall            ; mmap(0, file_len, 7, 34, -1, 0)
    cmp rax, -1
    je .fail

    ; read file into allocated space
    pop rdx            ;  file len from lseek
    mov rsi, rax       ;  address of allocated memory from mmap
    pop rdi            ;  fd from open
    push rsi           ;  *buf (addr of file in mem)
                       ;   preserve for accessing instructions)
    xor rax, rax       ;  sys_read
    syscall            ; read(fd, addr, file_len)
    cmp rax, -1
    je .fail

    ; prepare initial values for state variables
    pop rax            ; pointer to file in memory (from mmap; will be used as the
                       ;  instruction pointer)
    mov rcx, rax       ; pointer to start of file in memory
    xor rbx, rbx       ; current instruction (in the lowest byte, bl)
    mov rbp, rsp       ; pointer to the base of the data stack
    dec rsp            ; data[0] (rsp is always 1 byte lower than rbp)
    mov r9, rsp        ; keep track of stack size (stores the lowest address accessed)
    mov BYTE [rsp], bl ; initialize data[0] to zero
    mov bl, BYTE [rax] ; read byte from instruction ptr into bl

    ; main loop

.run:
    cmp bl, '>'        ; '>' - move the data ptr one cell to the right
    jne .r1
    dec rsp            ; rsp--
    cmp rsp, r9        ; if(data ptr < bottom of the stack)
    jl .r0             ;    then: .r0
    jmp .run.loop      ;    else: loop
.r0:
    dec r9             ; reset bottom of the stack
    xor rdx, rdx
    mov BYTE [rsp], dl ; intialize value at data ptr to zero
    jmp .run.loop
.r1:
    cmp bl, '<'        ; '<' - move the data ptr one cell to the left
    jne .r2
    mov r12, rbp
    sub r12, rsp
    cmp r12, 1         ; if(!data ptr)
    jle .run.loop      ;    then: loop
    inc rsp            ;    else: rsp++
    jmp .run.loop
.r2:
    cmp bl, '+'        ; '+' - increment value in cell at data ptr by one
    jne .r3
    mov dl, BYTE [rsp]
    inc dl             ; data[rsp]++
    mov BYTE [rsp], dl
    jmp .run.loop
.r3:
    cmp bl, '-'        ; '-' - decrement value in cell at data ptr by one
    jne .r4
    mov dl, BYTE [rsp]
    dec dl             ; data[rsp]--
    mov BYTE [rsp], dl
    jmp .run.loop
.r4:
    cmp bl, '.'        ; '.' - output value in cell at data ptr
    jne .r5
    mov rsi, rsp       ;  *buf (data[i])
    mov rsp, r9        ;  (jump to bottom of stack to avoid overwriting
    dec rsp            ;    any data)
    push rsi           ;  (preserve data ptr,
    push rax           ;    instruction ptr,
    push rbx           ;    current instruction,
    push rcx           ;    base of instructions in memory, and
    push r9            ;    stack size)
    mov rdx, 1         ;  count (1)
    mov rdi, 1         ;  STDOUT_FILENO (1)
    mov rax, 1         ;  sys_write
    syscall            ; write(stdout, data[i], 1)
    pop r9             ; (restore stack size,
    pop rcx            ;   base of instructions in memory,
    pop rbx            ;   current instruction,
    pop rax            ;   instruction ptr, and
    pop rsp            ;   data ptr)
    jmp .run.loop
.r5:
    cmp bl, ','        ; ',' - input value to cell at data ptr
    jne .r6
    xor rdx, rdx
    mov dl, BYTE [rsp] ; make a copy of the current data cell value
    mov rsi, rsp       ;  *buf (data[i])
    mov rsp, r9        ;  (jump to bottom of stack to avoid overwriting
    dec rsp            ;    any data)
    push rsi           ;  (preserve data ptr,
    push rax           ;    instruction ptr,
    push rbx           ;    current instruction,
    push rcx           ;    base of instructions in memory,
    push r9            ;    stack size, and
    push rdx           ;    previous value of data cell)
    mov rdx, 1         ;  count (1)
    xor rdi, rdi       ;  STDIN_FILENO (0)
    mov rax, rdi       ;  sys_read
    syscall            ; read(stdin, data[i], 1)
    pop rdx            ; (preemptively restore original value)
    test rax, rax      ; if(return <= 0) (error or eof)
    jle .r51           ;    then: no change for val at data ptr
    jmp .r52           ;    else: business as usual
.r51:
    mov BYTE [rsi], dl
.r52:                  ; (fallthrough)
    pop r9             ; (restore stack size,
    pop rcx            ;   base of instructions in memory,
    pop rbx            ;   current instruction,
    pop rax            ;   instruction ptr, and
    pop rsp            ;   data ptr)
    jmp .run.loop
.r6:
    cmp bl, '['        ; '[' - jump to instruction after matching ']', if
                       ;       value in cell at data ptr is 0
    jne .r7
    mov dl, BYTE [rsp]
    test dl, dl        ; if(data[i])
    jne .run.loop      ;    then: loop
                       ;    else:
    mov r8, 1          ;          set initial depth (r8 keeps track of the
                       ;           number of nested [] pairs, to match the
                       ;           original
                       ; (fallthrough)
.r61:
    inc rax            ; i++
    mov dl, BYTE [rax]
    test dl, dl        ; if(ins[i] == EOF)
    je .fail           ;    then: fail
    cmp dl, '['        ; else if(ins[i] == '[')
    je .r62            ;    then: depth++
    cmp dl, ']'        ; else if(ins[i] == ']')
    je .r63            ;    then: depth--
    jmp .r64
.r62:
    inc r8
    jmp .r64
.r63:
    dec r8             ; (fallthrough)
.r64:
    test r8, r8        ; while(depth)
    jne .r61           ;    loop
    jmp .run.loop
.r7:
    cmp bl, ']'        ; ']' - jump to instruction after matching '[', if
                       ;       value in cell at data ptr != 0 (searching
                       ;       backwards)
    jne .run.loop
    mov dl, BYTE [rsp]
    test dl, dl        ; if(!data[i])
    je .run.loop       ;    then: loop
                       ;    else:
    mov r8, 1          ;         set initial depth (r8 keeps track of the
                       ;          number of nested [] pairs, to match the
                       ;          original
                       ; (fallthrough)
.r71:
    dec rax            ; i--
    cmp rax, rcx       ; if(i < i_0)
    jl .fail           ;    then: fail
    mov dl, BYTE [rax]
    cmp dl, ']'        ; else if(ins[i] == ']')
    je .r72            ;    then: depth++
    cmp dl, '['        ; else if(ins[i] == '[')
    je .r73            ;    then: depth--
    jmp .r74
.r72:
    inc r8
    jmp .r74
.r73:
    dec r8             ; (fallthrough)
.r74:
    test r8, r8        ; while(depth)
    jne .r71           ;    loop
    jmp .run.loop
.run.loop:
    inc rax            ;  i++
    mov bl, BYTE [rax] ; read byte from instruction ptr into bl
    test bl, bl        ; while(ins[i] != EOF)
    jne .run           ;    loop

    xor rdi, rdi       ;  val = EXIT_SUCCESS (0)
    jmp .exit

.fail:
    mov rdi, 1         ;  val = EXIT_FAILURE (1)
.exit:                 ;  (fallthrough)
    mov rax, 60        ;  sys_exit
    syscall            ; exit(val);

; NASM x86-64 - Bilinear Interpolation 64x64 -> 128x128

section .data
    input_file  db "original_cuadrante.img", 0
    output_file db "output.img", 0
    error_msg   db "File operation failed", 10, 0
    size_error  db "Input file size incorrect", 10, 0

    IN_SIZE     equ 4096     ; 64x64
    OUT_SIZE    equ 16384    ; 128x128
    WIDTH       equ 64
    OUT_WIDTH   equ 128

section .bss
    input_buf   resb IN_SIZE
    output_buf  resb OUT_SIZE
    fd_in       resq 1
    fd_out      resq 1

section .text
global _start

_start:
    call read_input
    call interpolate_image
    call write_output
    jmp exit_success

read_input:
    ; sys_open
    mov rax, 2
    lea rdi, [input_file]
    xor rsi, rsi        ; O_RDONLY
    syscall
    mov [fd_in], rax
    cmp rax, 0
    jl error_exit

    ; sys_read
    mov rax, 0
    mov rdi, [fd_in]
    lea rsi, [input_buf]
    mov rdx, IN_SIZE
    syscall
    cmp rax, IN_SIZE
    jne size_error_exit

    ; sys_close
    mov rax, 3
    mov rdi, [fd_in]
    syscall
    ret

interpolate_image:
    ; Fase 1: Calcular píxeles horizontales y verticales
    xor r12, r12        ; y in [0, 63]
.outer_loop:
    cmp r12, WIDTH
    jge .phase2
    xor r13, r13        ; x in [0, 63]
.inner_loop:
    cmp r13, WIDTH
    jge .next_row

    ; Calcular índices de salida (2x tamaño)
    mov rax, r12
    shl rax, 1          ; y*2
    imul rax, OUT_WIDTH ; (y*2)*128
    mov rdx, r13
    shl rdx, 1          ; x*2
    add rax, rdx        ; base index = (y*2)*128 + x*2
    mov r15, rax        ; Guardar índice base

    ; Obtener píxeles originales P00, P10, P01, P11
    mov rax, r12
    imul rax, WIDTH
    add rax, r13
    movzx rbx, byte [input_buf + rax]  ; P00

    ; Manejar bordes para P10 (derecha)
    cmp r13, WIDTH-1
    je .p10_edge
    movzx rcx, byte [input_buf + rax + 1] ; P10
    jmp .get_p01
.p10_edge:
    mov rcx, rbx    ; Si estamos en el borde, replicar P00

.get_p01:
    ; Manejar bordes para P01 (abajo)
    cmp r12, WIDTH-1
    je .p01_edge
    movzx r8, byte [input_buf + rax + WIDTH] ; P01
    jmp .get_p11
.p01_edge:
    mov r8, rbx     ; Si estamos en el borde, replicar P00

.get_p11:
    ; Manejar bordes para P11 (esquina inferior derecha)
    cmp r13, WIDTH-1
    je .p11_edge
    cmp r12, WIDTH-1
    je .p11_edge
    movzx r9, byte [input_buf + rax + WIDTH + 1] ; P11
    jmp .calc_interpolation
.p11_edge:
    mov r9, r8      ; Si estamos en el borde, replicar P01

.calc_interpolation:
    ; === Fase 1: Píxeles horizontales y verticales ===
    
    ; 1. Píxel horizontal (a): (2/3)*P00 + (1/3)*P10
    mov rax, rbx
    imul rax, 2
    mov rdx, rcx
    add rax, rdx    ; 2*P00 + 1*P10
    mov rdx, 0
    mov rsi, 3
    div rsi         ; (2*P00 + 1*P10)/3
    mov r10, rax    ; Guardar resultado (a)

    ; 2. Píxel horizontal (b): (1/3)*P00 + (2/3)*P10
    mov rax, rbx
    mov rdx, rcx
    imul rdx, 2
    add rax, rdx    ; 1*P00 + 2*P10
    mov rdx, 0
    div rsi         ; (1*P00 + 2*P10)/3
    mov r11, rax    ; Guardar resultado (b)

    ; 3. Píxel vertical (c): (2/3)*P00 + (1/3)*P01
    mov rax, rbx
    imul rax, 2
    mov rdx, r8
    add rax, rdx    ; 2*P00 + 1*P01
    mov rdx, 0
    div rsi         ; (2*P00 + 1*P01)/3
    mov r14, rax    ; Guardar resultado (c)

    ; 4. Píxel vertical (g): (1/3)*P00 + (2/3)*P01
    mov rax, rbx
    mov rdx, r8
    imul rdx, 2
    add rax, rdx    ; 1*P00 + 2*P01
    mov rdx, 0
    div rsi         ; (1*P00 + 2*P01)/3
    mov rdi, rax    ; Guardar resultado (g)

    ; Escribir píxeles conocidos e interpolados en la salida
    ; Posición P00 (original)
    mov [output_buf + r15], bl

    ; Posición a (horizontal)
    mov rdx, r15
    inc rdx
    mov [output_buf + rdx], r10b

    ; Posición b (horizontal)
    mov rdx, r15
    add rdx, 2
    mov [output_buf + rdx], r11b

    ; Posición P10 (original, en x+2,y)
    mov rdx, r15
    add rdx, 3
    mov [output_buf + rdx], cl

    ; Posición c (vertical)
    mov rdx, r15
    add rdx, OUT_WIDTH
    mov [output_buf + rdx], r14b

    ; Posición g (vertical)
    mov rdx, r15
    add rdx, OUT_WIDTH
    add rdx, OUT_WIDTH
    mov [output_buf + rdx], dil

    ; Posición P01 (original, en x,y+2)
    mov rdx, r15
    add rdx, OUT_WIDTH
    add rdx, OUT_WIDTH
    add rdx, OUT_WIDTH
    mov [output_buf + rdx], r8b

    ; Continuar con el siguiente píxel
    inc r13
    jmp .inner_loop

.next_row:
    inc r12
    jmp .outer_loop

.phase2:
    ; === Fase 2: Calcular píxeles centrales (d,e,h,i) usando los interpolados ===
    ; Ahora se necesita procesar la imagen de salida para calcular los píxeles centrales
    xor r12, r12        ; y in [0,126], saltando de 2 en 2
.phase2_y_loop:
    cmp r12, OUT_WIDTH-2
    jge .done
    xor r13, r13        ; x in [0,126], saltando de 2 en 2
.phase2_x_loop:
    cmp r13, OUT_WIDTH-2
    jge .phase2_next_row

    ; Calcular índice base
    mov rax, r12
    imul rax, OUT_WIDTH
    add rax, r13
    mov r15, rax        ; Guardar índice base

    ; Obtener píxeles vecinos (ya interpolados en fase 1)
    ; Esquinas del bloque 2x2 actual
    movzx rbx, byte [output_buf + r15]          ; P00 (superior izquierdo)
    movzx rcx, byte [output_buf + r15 + 2]      ; P10 (superior derecho)
    movzx r8, byte [output_buf + r15 + OUT_WIDTH*2] ; P01 (inferior izquierdo)
    movzx r9, byte [output_buf + r15 + OUT_WIDTH*2 + 2] ; P11 (inferior derecho)

    ; Píxeles horizontales ya calculados (a,b)
    movzx r10, byte [output_buf + r15 + 1]      ; a (horizontal entre P00 y P10)
    movzx r11, byte [output_buf + r15 + OUT_WIDTH*2 + 1] ; h (horizontal entre P01 y P11)

    ; Píxeles verticales ya calculados (c,g)
    movzx r14, byte [output_buf + r15 + OUT_WIDTH] ; c (vertical entre P00 y P01)
    movzx rdi, byte [output_buf + r15 + OUT_WIDTH + 2] ; f (vertical entre P10 y P11)

    ; === Calcular píxeles centrales ===
    
    ; 1. Píxel d: (2/3)*a + (1/3)*f
    mov rax, r10
    imul rax, 2
    add rax, rdi        ; 2*a + 1*f
    mov rdx, 0
    mov rsi, 3
    div rsi             ; (2*a + 1*f)/3
    mov [output_buf + r15 + OUT_WIDTH + 1], al ; Escribir d

    ; 2. Píxel e: (1/3)*a + (2/3)*f
    mov rax, r10
    mov rdx, rdi
    imul rdx, 2
    add rax, rdx        ; 1*a + 2*f
    mov rdx, 0
    div rsi             ; (1*a + 2*f)/3
    mov [output_buf + r15 + OUT_WIDTH + 3], al ; Escribir e (en la siguiente columna)

    ; Continuar con el siguiente bloque
    add r13, 2
    jmp .phase2_x_loop

.phase2_next_row:
    add r12, 2
    jmp .phase2_y_loop

.done:
    ret

write_output:
    mov rax, 2
    lea rdi, [output_file]
    mov rsi, 577        ; O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0666o
    syscall
    mov [fd_out], rax
    cmp rax, 0
    jl error_exit

    mov rax, 1
    mov rdi, [fd_out]
    lea rsi, [output_buf]
    mov rdx, OUT_SIZE
    syscall
    cmp rax, OUT_SIZE
    jne error_exit

    mov rax, 3
    mov rdi, [fd_out]
    syscall
    ret

error_exit:
    mov rax, 1
    mov rdi, 1
    lea rsi, [error_msg]
    mov rdx, 24
    syscall
    jmp exit_failure

size_error_exit:
    mov rax, 1
    mov rdi, 1
    lea rsi, [size_error]
    mov rdx, 30
    syscall
    jmp exit_failure

exit_success:
    mov rax, 60
    xor rdi, rdi
    syscall

exit_failure:
    mov rax, 60
    mov rdi, 1
    syscall

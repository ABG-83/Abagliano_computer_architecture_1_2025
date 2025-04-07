; NASM x86-64 - Bilinear Interpolation 64x64 -> 128x128

section .data
    input_file  db "original_cuadrante.img", 0
    output_file db "output.img", 0
    error_msg   db "File operation failed", 10, 0
    size_error  db "Input file size incorrect", 10, 0

    IN_SIZE     equ 4096
    OUT_SIZE    equ 16384
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
    xor r12, r12        ; y in [0, 63]
.y_loop:
    cmp r12, WIDTH
    jge .done
    xor r13, r13        ; x in [0, 63]
.x_loop:
    cmp r13, WIDTH
    jge .next_row

    ; Get P00
    mov rax, r12
    imul rax, WIDTH
    add rax, r13
    movzx rbx, byte [input_buf + rax]  ; P00

    ; P10
    cmp r13, WIDTH-1
    je .p10_edge
    movzx rcx, byte [input_buf + rax + 1]
    jmp .p01
.p10_edge:
    mov rcx, rbx

.p01:
    cmp r12, WIDTH-1
    je .p01_edge
    movzx r8, byte [input_buf + rax + WIDTH]
    jmp .p11
.p01_edge:
    mov r8, rbx

.p11:
    cmp r13, WIDTH-1
    je .p11_edge_x
    cmp r12, WIDTH-1
    je .p11_edge_x
    movzx r9, byte [input_buf + rax + WIDTH + 1]
    jmp .interpolate
.p11_edge_x:
    mov r9, r8

.interpolate:
    ; Base output index = (2*y * 128) + 2*x
    mov rax, r12
    shl rax, 1
    imul rax, OUT_WIDTH
    mov rdx, r13
    shl rdx, 1
    add rax, rdx
    mov r10, rax        ; base output index

    ; Interpolation weights:
    ; Top-left (0,0): 9P00 + 3P10 + 3P01 + 1P11
    mov rax, rbx
    imul rax, 9
    mov rdx, rcx
    imul rdx, 3
    add rax, rdx
    mov rdx, r8
    imul rdx, 3
    add rax, rdx
    add rax, r9
    shr rax, 4
    mov [output_buf + r10], al

    ; Top-right (1,0): 3P00 + 9P10 + 1P01 + 3P11
    mov rax, rbx
    imul rax, 3
    mov rdx, rcx
    imul rdx, 9
    add rax, rdx
    mov rdx, r8
    imul rdx, 1
    add rax, rdx
    mov rdx, r9
    imul rdx, 3
    add rax, rdx
    shr rax, 4
    mov rdx, r10
    inc rdx
    mov [output_buf + rdx], al

    ; Bottom-left (0,1): 3P00 + 1P10 + 9P01 + 3P11
    mov rax, rbx
    imul rax, 3
    mov rdx, rcx
    imul rdx, 1
    add rax, rdx
    mov rdx, r8
    imul rdx, 9
    add rax, rdx
    mov rdx, r9
    imul rdx, 3
    add rax, rdx
    shr rax, 4
    mov rdx, r10
    add rdx, OUT_WIDTH
    mov [output_buf + rdx], al

    ; Bottom-right (1,1): 1P00 + 3P10 + 3P01 + 9P11
    mov rax, rbx
    imul rax, 1
    mov rdx, rcx
    imul rdx, 3
    add rax, rdx
    mov rdx, r8
    imul rdx, 3
    add rax, rdx
    mov rdx, r9
    imul rdx, 9
    add rax, rdx
    shr rax, 4
    mov rdx, r10
    add rdx, OUT_WIDTH
    inc rdx
    mov [output_buf + rdx], al

    inc r13
    jmp .x_loop

.next_row:
    inc r12
    jmp .y_loop
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


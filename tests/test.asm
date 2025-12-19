MSG_OFFSET EQU 400000  ; Message offset relative to file start

BITS 16
CPU 8086
ORG 0x5678

; Set DS to message segment
mov ax, cs
add ax, MSG_OFFSET >> 4
mov ds, ax

; Point SI to message
mov si, $$ + (MSG_OFFSET & 0xF)

.print:
    lodsb                   ; AL = next character from SI
    cmp al, 0               ; Check for null terminator
    je .done                ; Exit if null terminator
    mov ah, 0x0E            ; Teletype output function
    mov bh, 0x00            ; Page number
    mov bl, 0x07            ; Text attribute (0x07 = light gray on black)
    int 0x10                ; BIOS video interrupt
    jmp .print              ; Continue to next character
.done:
    xor ah, ah              ; Wait for keypress
    int 0x16                ; BIOS keyboard interrupt
    int 0x19                ; Continue booting

; Increase file size for test
TIMES MSG_OFFSET - ($-$$) DB 'A'

msg: DB "File successfully loaded!", 0x0D, 0x0A, 0

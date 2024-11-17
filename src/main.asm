BITS 32
GLOBAL main

EXTERN printf
EXTERN aligned_alloc
EXTERN free
EXTERN memset

EXTERN mmu_switch_page_map
EXTERN mmu_write
EXTERN mmu_read
EXTERN mmu_flags

page_alloc:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    PUSH 2048
    PUSH 2048
    CALL aligned_alloc
    ADD ESP, 8

    PUSH EAX

    PUSH 2048
    PUSH 0
    PUSH EAX
    CALL memset

    ADD ESP, 12
    POP EAX

    MOV ESP, EBP
    POP EBP
    RET

page_free:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    PUSH DWORD [EBP+8]
    CALL free
    ADD ESP, 4

    MOV ESP, EBP
    POP EBP
    RET

traverse_level:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    MOV EAX, DWORD [EBP+12] ; ENTRY
    MOV ECX, 4
    MUL ECX
    MOV EBX, EAX

    MOV EAX, DWORD [EBP+8] ; LEVEL
    ADD EAX, EBX

    MOV EBX, DWORD [EAX]
    AND EBX, 1
    CMP EBX, 1
    JE .found

    CALL page_alloc
    MOV DWORD [EBP-4], EAX

    OR EAX, DWORD [EBP+16] ; FLAGS
    PUSH EAX

    MOV EAX, DWORD [EBP+12] ; ENTRY
    MOV EBX, 4
    MUL EBX
    MOV EBX, EAX

    MOV EAX, DWORD [EBP+8]
    ADD EAX, EBX

    POP EBX
    MOV DWORD [EAX], EBX

    MOV EAX, DWORD [EBP-4]

    JMP .exit
.found:
    PUSH DWORD [EAX]
    POP EAX
    AND EAX, 0xFFFFFF00
.exit:
    MOV ESP, EBP
    POP EBP
    RET

map:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    MOV EAX, DWORD [EBP+12]
    MOV EBX, EAX
    SHR EBX, 21
    AND EBX, 0x1FF ; EBX contains Page directory

    MOV ECX, EAX
    SHR ECX, 12
    AND ECX, 0x1FF ; ECX contains Page Entry

    PUSH ECX

    PUSH DWORD [EBP+20] ; FLAGS
    PUSH EBX
    PUSH DWORD [EBP+8] ; PAGE MAP
    CALL traverse_level
    ADD ESP, 12
    MOV DWORD [EBP-4], EAX

    POP ECX
    MOV EAX, ECX
    MOV ECX, 4
    MUL ECX
    MOV ECX, EAX

    MOV EAX, DWORD [EBP-4]
    ADD EAX, ECX
    
    MOV EBX, DWORD [EBP+16]
    OR EBX, DWORD [EBP+20] ; FLAGS

    MOV DWORD [EAX], EBX ; PAGE

    MOV ESP, EBP
    POP EBP
    XOR EAX, EAX
    RET

get_phys_page:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    MOV EAX, DWORD [EBP+12]
    MOV EBX, EAX
    SHR EBX, 21
    AND EBX, 0x1FF ; PD

    MOV ECX, EAX
    SHR ECX, 12
    AND ECX, 0x1FF ; PE

    PUSH ECX

    PUSH 1 ; FLAGS
    PUSH EBX
    PUSH DWORD [EBP+8] ; PAGE MAP
    CALL traverse_level
    ADD ESP, 12
    MOV DWORD [EBP-4], EAX

    POP ECX
    MOV EAX, ECX
    MOV ECX, 4
    MUL ECX
    MOV ECX, EAX

    MOV EAX, DWORD [EBP-4]
    ADD EAX, ECX
    
    MOV EBX, DWORD [EAX]
    AND EBX, 0xFFFFFF00

    MOV EAX, EBX

    MOV ESP, EBP
    POP EBP
    RET

main:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16 ; Alinhar a stack à 16 bytes

    ; PAGE_MAP
    CALL page_alloc
    MOV DWORD [EBP-4], EAX ; ADDR PAGE_MAP

    PUSH EAX
    CALL mmu_switch_page_map
    ADD ESP, 4

    CALL page_alloc
    MOV DWORD [EBP-8], EAX

    PUSH 0b11
    PUSH EAX ; PHYS
    PUSH 0xABCDEF00 ; VIRT
    PUSH DWORD [EBP-4]
    CALL map ; MAPEAR O ENDEREÇO VIRTUAL PARA O FISICO
    ADD ESP, 16

    PUSH 0x69
    PUSH 0xABCDEF00
    PUSH DWORD [EBP-4]
    CALL mmu_write ; ESCREVER PARA O ENDEREÇO VIRTUAL
    ADD ESP, 9
    CMP EAX, 0
    JG .faulted

    PUSH 0xABCDEF00
    PUSH DWORD [EBP-4]
    CALL mmu_read ; LER O ENDEREÇO VIRTUAL
    ADD ESP, 8
    CMP DWORD [mmu_flags], 0
    JG .faulted

    PUSH BYTE AX
    PUSH DWORD [EBP-8]
    PUSH 0xABCDEF00
    PUSH read_msg
    CALL printf ; PRINTAR O VALOR
    ADD ESP, 16

    ;; PAGINA 2

    CALL page_alloc
    MOV DWORD [EBP-12], EAX

    PUSH 0b11
    PUSH EAX ; PHYS
    PUSH 0xDEADCAF0 ; VIRT
    PUSH DWORD [EBP-4]
    CALL map ; MAPEAR O ENDEREÇO VIRTUAL PARA O FISICO
    ADD ESP, 16
    
    PUSH 0x42
    PUSH 0xDEADCAF0
    PUSH DWORD [EBP-4]
    CALL mmu_write ; ESCREVER PARA O ENDEREÇO VIRTUAL
    ADD ESP, 9
    CMP EAX, 0
    JG .faulted

    PUSH 0xDEADCAF0
    PUSH DWORD [EBP-4]
    CALL mmu_read ; LER O ENDEREÇO VIRTUAL
    ADD ESP, 8
    CMP DWORD [mmu_flags], 0
    JG .faulted

    PUSH BYTE AX
    PUSH DWORD [EBP-12]
    PUSH 0xDEADCAF0
    PUSH read_msg
    CALL printf ; PRINTAR O VALOR
    ADD ESP, 16

    JMP .exit

.faulted:
    PUSH DWORD [mmu_flags]
    PUSH faulted_msg
    CALL printf
    ADD ESP, 8

.exit:
    PUSH DWORD [EBP-4]
    CALL page_free
    ADD ESP, 4

    MOV ESP, EBP
    POP EBP
    XOR EAX, EAX
    RET

read_msg: db `\n\n\n%x (virt) -> %x (phys) = %x\n\0`
faulted_msg: db `MMU faulted! Flags: %x\n\0`
GLOBAL mmu_write
EXTERN printf

GLOBAL mmu_flags
GLOBAL mmu_switch_page_map
GLOBAL mmu_read

mmu_switch_page_map:
    MOV EAX, DWORD [EBP+8]
    MOV DWORD [mmu_page_map], EAX
    RET

mmu_traverse_level_expect_flags:
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
    AND EBX, DWORD [EBP+16] ; FLAGS
    CMP EBX, DWORD [EBP+16]

    JE .true

    XOR EAX, EAX
    JE .exit
.true:
    MOV EAX, DWORD [EAX]
    AND EAX, 0xFFFFFF00
.exit:
    MOV ESP, EBP
    POP EBP
    RET

mmu_write:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    MOV EAX, DWORD [EBP+12]

    ; 2 bits unused
    ; 9 bits for Page directory
    ; 9 bits for Page entry
    ; 12 bits for Page offset
    ; 2048 byte page size

    MOV EBX, EAX
    SHR EBX, 21
    AND EBX, 0x1FF ; EBX contains Page directory

    MOV ECX, EAX
    SHR ECX, 12
    AND ECX, 0x1FF ; ECX contains Page Entry

    MOV EDX, EAX
    AND EDX, 0xFFF ; EDX contains Page offset

    PUSH EDX
    PUSH ECX

    PUSH 0b11 ; FLAGS
    PUSH EBX
    PUSH DWORD [EBP+8] ; PAGE MAP
    CALL mmu_traverse_level_expect_flags
    ADD ESP, 12

    CMP EAX, 0
    JE .fault

    MOV DWORD [EBP-4], EAX

    POP ECX
    MOV EAX, ECX
    MOV ECX, 4
    MUL ECX
    MOV ECX, EAX

    MOV EAX, DWORD [EBP-4]
    ADD EAX, ECX

    MOV EBX, DWORD [EAX]
    AND EBX, 0x000000FF
    CMP EBX, 0b11
    JNE .fault

    MOV EAX, DWORD [EAX]
    AND EAX, 0xFFFFFF00

    POP EBX
    ADD EAX, EBX ; OFFSET

    MOV ECX, DWORD [EBP+16]
    MOV [EAX], ECX

    XOR EAX, EAX
    JMP .exit
.fault:
    MOV EAX, 1
    MOV EBX, DWORD [mmu_flags]
    OR EBX, 0b1
    MOV DWORD [mmu_flags], EBX
.exit:
    MOV ESP, EBP
    POP EBP
    RET

mmu_read:
    PUSH EBP
    MOV EBP, ESP
    SUB ESP, 16

    MOV EAX, DWORD [EBP+12]

    ; 2 bits unused
    ; 9 bits for Page directory
    ; 9 bits for Page entry
    ; 12 bits for Page offset
    ; 2048 byte page size

    MOV EBX, EAX
    SHR EBX, 21
    AND EBX, 0x1FF ; EBX contains Page directory

    MOV ECX, EAX
    SHR ECX, 12
    AND ECX, 0x1FF ; ECX contains Page Entry

    MOV EDX, EAX
    AND EDX, 0xFFF ; EDX contains Page offset

    PUSH EDX
    PUSH ECX

    PUSH 0b11 ; FLAGS
    PUSH EBX
    PUSH DWORD [EBP+8] ; PAGE MAP
    CALL mmu_traverse_level_expect_flags
    ADD ESP, 12

    CMP EAX, 0
    JE .fault

    MOV DWORD [EBP-4], EAX

    POP ECX
    MOV EAX, ECX
    MOV ECX, 4
    MUL ECX
    MOV ECX, EAX

    MOV EAX, DWORD [EBP-4]
    ADD EAX, ECX

    MOV EBX, DWORD [EAX]
    AND EBX, 0x000000FF
    CMP EBX, 0b11
    JNE .fault

    MOV EAX, DWORD [EAX]
    AND EAX, 0xFFFFFF00

    POP EBX
    ADD EAX, EBX ; OFFSET

    MOV EAX, [EAX]

    JMP .exit
.fault:
    MOV EAX, 1
    MOV EBX, DWORD [mmu_flags]
    OR EBX, 0b1
    MOV DWORD [mmu_flags], EBX
.exit:
    MOV ESP, EBP
    POP EBP
    RET

SECTION .data
mmu_page_map: dd 0
mmu_flags: dd 0
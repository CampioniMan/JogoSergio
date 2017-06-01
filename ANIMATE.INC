; #########################################################################

;   include files
;   ~~~~~~~~~~~~~
    include c:\MASM32\INCLUDE\windows.inc
    include c:\MASM32\INCLUDE\masm32.inc
    include c:\MASM32\INCLUDE\gdi32.inc
    include c:\MASM32\INCLUDE\user32.inc
    include c:\MASM32\INCLUDE\kernel32.inc
    include c:\MASM32\INCLUDE\Comctl32.inc
    include c:\MASM32\INCLUDE\comdlg32.inc
    include c:\MASM32\INCLUDE\shell32.inc

;     libraries
;     ~~~~~~~~~
    includelib c:\MASM32\LIB\masm32.lib

    includelib c:\MASM32\LIB\gdi32.lib
    includelib c:\MASM32\LIB\user32.lib
    includelib c:\MASM32\LIB\kernel32.lib
    includelib c:\MASM32\LIB\Comctl32.lib
    includelib c:\MASM32\LIB\comdlg32.lib
    includelib c:\MASM32\LIB\shell32.lib

; #########################################################################

        ;=================
        ; Local prototypes
        ;=================
        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD
        FillBuffer   PROTO :DWORD,:DWORD,:BYTE
        PushButton   PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
        ThreadProc PROTO :DWORD

        ; nossas funções
        desenharFlappy  PROTO :DWORD
        voltaCanos      PROTO
        canoAndar       PROTO
        calculaPos      PROTO
        podeIrPraPos    PROTO
        subir      PROTO
        irDescendo      PROTO
        graficoDeY      PROTO

        ;wsprintfA PROTO C :DWORD, :DWORD, :VARARG
    ;wsprintf equ <wsprintfA>

    ;=============
    ; Local macros
    ;=============

    szText MACRO Name, Text:VARARG
        LOCAL lbl
        jmp lbl
            Name db Text,0
        lbl:
    ENDM

    szDWORD MACRO Name
        LOCAL lbl
        jmp lbl
            Name db DWORD,0
        lbl:
    ENDM

    m2m MACRO M1, M2
        push M2
        pop  M1
    ENDM

    return MACRO arg
        mov eax, arg
        ret
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    dividir MACRO primeiro, segundo
        mov eax, primeiro
        mov ecx, segundo
        xor edx, edx       ;coloca 0 no EDX para não haver erros
        div ecx
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ;/* Coloca em EAX o valor multiplicado */
    ;/* Altera ECX também                  */
    multiplicar MACRO primeiro, segundo
        mov ecx, primeiro
        mov eax, segundo
        mul ecx           ; estou multiplicando os dois(ecx*EAX), será guardado em EAX o valor(e em EDX se muito grande) por default
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ;/* Coloca em EAX o valor do quadrado */
    quadradoDe MACRO base
        mov eax, base   ; colocando o valor de 'base' em EAX
        mul eax         ; estou multiplicando o valor por si mesmo(EAX*EAX), será guardado em EAX o valor(e em EDX se muito grande) por default
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    .data
        CommandLine   dd 0
        hWnd          dd 0
        hWin2         dd 0
        hInstance     dd 0
        hIcon         dd 0
        hBmp          dd 0
        hFlappy       dd 0
        hFundo        dd 0
        szDisplayName db "Flappy Bird",0
        pos           POINT <0,0>
        canoC         POINT <0,0>
        canoB         POINT <0,0>
        lRect         RECT<500, 500, 0, 0>
        indiceProX    dd 1
        ExitCode      dd 0
        hThread       dd 0
        hEventStart   dd 0
        EventStop BOOL FALSE

    .const
        WM_FINISH equ WM_USER+100h
        IDM_TEST equ 1
        IDM_HELLO equ 2
        IDM_GOODBYE equ 3
        IDM_EXIT equ 4
        

; ########################### Inserted modules ############################


; #########################################################################

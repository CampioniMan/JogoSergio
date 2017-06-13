; #########################################################################

;   include files
;   ~~~~~~~~~~~~~
    ;include C:\masm32\include\masm32.inc
    include c:\MASM32\INCLUDE\windows.inc
    include c:\MASM32\INCLUDE\gdi32.inc
    include c:\MASM32\INCLUDE\user32.inc
    include c:\MASM32\INCLUDE\kernel32.inc
    include c:\MASM32\INCLUDE\Comctl32.inc
    include c:\MASM32\INCLUDE\comdlg32.inc
    include c:\MASM32\INCLUDE\shell32.inc
    include C:\MASM32\INCLUDE\Msimg32.inc
;     libraries
;     ~~~~~~~~~
    includelib c:\MASM32\LIB\gdi32.lib
    includelib c:\MASM32\LIB\user32.lib
    includelib c:\MASM32\LIB\kernel32.lib
    includelib c:\MASM32\LIB\Comctl32.lib
    includelib c:\MASM32\LIB\comdlg32.lib
    includelib c:\MASM32\LIB\shell32.lib
    includelib c:\MASM32\LIB\advapi32.lib
    includelib C:\MASM32\LIB\Msimg32.lib

; #########################################################################

        ;=================
        ; Local prototypes
        ;=================
        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD
        FillBuffer   PROTO :DWORD,:DWORD,:BYTE
        ThreadProc PROTO :DWORD

        ; nossas funções
        desenharFlappy  PROTO :DWORD
        voltaCanos      PROTO
        canoAndar       PROTO
        calculaPos      PROTO
        podeIrPraPos    PROTO
        subir           PROTO
        irDescendo      PROTO
        graficoDeY      PROTO
        recomecar       PROTO

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

    ; /* método divide registradores de 16 bits, para DWords */
    dividir MACRO primeiro, segundo
        mov eax, primeiro
        mov ecx, segundo
        xor edx, edx       ;coloca 0 no EDX para não haver erros
        idiv ecx
    ENDM

    ; /* método divide registradores de 8 bits, para DBytes */
    dividir_oito MACRO primeiro, segundo
        mov ah, primeiro
        mov al, segundo
        mov bx, 0
        @loop:
            .if ah <= al
                jmp @fim
            sub ah, al
            inc bx
        @fim:        
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Coloca em EAX o valor multiplicado */
    ; /* Altera ECX também                  */
    multiplicar MACRO primeiro, segundo
        mov ecx, primeiro
        mov eax, segundo
        imul ecx           ; estou multiplicando os dois(ecx*EAX), será guardado em EAX o valor(e em EDX se muito grande) por default
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Coloca em DX o valor multiplicado */
    ; /* Altera CX e AX também             */
    aleatorio MACRO intervalo, resultado
        mov  ah, dh
        xor  dh, dh
        mov  ch, 1
        add  ch, intervalo
        div  ch       ; here dh contains the remainder of the division - from 0 to intervalo
        mov word ptr[resultado], dx
        .while resultado > intervalo
            sub resultado, intervalo+1
        .endw
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Coloca em EAX o valor do quadrado */
    quadradoDe MACRO base
        mov eax, base   ; colocando o valor de 'base' em EAX
        imul eax         ; estou multiplicando o valor por si mesmo(EAX*EAX), será guardado em EAX o valor(e em EDX se muito grande) por default
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Coloca em EAX o valor do RGB desejado */
    RGB MACRO red,green,blue 
        xor eax,eax 
        mov ah,blue 
        shl eax,8 
        mov ah,green 
        mov al,red 
    ENDM

    RGB_b MACRO red,green,blue 
        xor ebx,ebx 
        mov bh,blue 
        shl ebx,8 
        mov bh,green 
        mov bl,red 
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Macro para escrever um texto baseando-se no contexto(hDC) e as coordenadas */
    ESCREVE_TEXTO MACRO FontName, hDC, hfont, texto, x, y
        invoke CreateFont,24,16,0,0,400,0,0,0,OEM_CHARSET,\ ;// cria a fonte
               OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
               DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT,\
               ADDR FontName
        invoke SelectObject, hDC, eax ;// coloca a fonte em hDC
        mov    hfont,eax  ;// obtemos a fonte

        RGB    200,200,50 ;// setamos em eax a cor desejada
        invoke SetTextColor,hDC,eax ;// colocamos a cor no hDC para texto
        RGB    0,160,192 ;// setamos em eax a cor desejada
        invoke SetBkColor,hDC,eax ;// colocamos a cor no hDC para background
        invoke TextOut,hDC,x,y,ADDR texto,SIZEOF texto ;// escrevemos o texto na tela
        invoke SelectObject,hDC, hfont                 ;// juntamente com a fonte escolhida
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Função que escreve um número(DByte) na tela, com um background padrão de números */
    ESCREVE_PONTUACAO MACRO FontName, hDC, hfont, number, x, y, planodefundo
        invoke CreateFont,24,16,0,0,400,0,0,0,OEM_CHARSET,\
               OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
               DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT,\
               ADDR FontName
        invoke SelectObject, hDC, eax
        mov    hfont,eax

        mov bl, number
        intToStr number
        .if planodefundo == 0
            RGB    0,255,0
            invoke SetTextColor,hDC,eax
            RGB    0,0,0
            invoke SetBkColor,hDC,eax
        .else
            RGB    200,200,50 ;// setamos em eax a cor desejada
            invoke SetTextColor,hDC,eax ;// colocamos a cor no hDC para texto
            RGB    0,160,192 ;// setamos em eax a cor desejada
            invoke SetBkColor,hDC,eax ;// colocamos a cor no hDC para background
        .endif
        invoke TextOut,hDC,x,y,ADDR number,SIZEOF number
        invoke SelectObject,hDC, hfont
        mov number, bl
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Função que escreve um número(DWord) na tela, com um background padrão de números */
    ESCREVE_PONTUACAO_D MACRO FontName, hDC, hfont, number, x, y
        invoke CreateFont,24,16,0,0,400,0,0,0,OEM_CHARSET,\
               OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
               DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT,\
               ADDR FontName
        invoke SelectObject, hDC, eax
        mov    hfont,eax

        mov bl, number
        intToStr number
        RGB    0,255,0
        invoke SetTextColor,hDC,eax
        RGB    0,0,0
        invoke SetBkColor,hDC,eax
        invoke TextOut,hDC,x,y,ADDR number,SIZEOF number
        invoke SelectObject,hDC, hfont
        mov number, bl
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* Macro para criar Threads, baseando-se no ID, no Handler e no procedimento dela */
    CRIAR_THREAD MACRO ThreadProc, ThreadID, hThread
        mov    eax, OFFSET ThreadProc
        invoke CreateEvent, NULL, FALSE, FALSE, NULL
        mov    hEventStart, eax
        mov    eax, OFFSET ThreadProc
        invoke CreateThread, NULL, NULL, ThreadProc, eax, 0, ADDR ThreadID
        invoke CloseHandle, eax
        mov    hThread,eax
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    ; /* transforma uma variável numérica(entre 0-9) e transforma em letra('0'-'9')(suponto DByte 1 bytes) */
    intToStr MACRO valor
        mov ah, valor
        add ah, '0'
        mov valor, ah
    ENDM

    ;/////////////////////////////////
    ;/////////////////////////////////
    ;/////////////////////////////////

    .data?
        ranNum DWORD ?

    .data
        CommandLine   dd 0
        hWnd          dd 0
        hWin2         dd 0
        hInstance     dd 0
        hIcon         dd 0
        hBmp          dd 0
        hFlappy       dd 0 ; Handler para bitmap do flappy com asa para baixo
        hFlappy2      dd 0 ; Handler para o bitmap do flappy com a asa para cima
        hCanoC        dd 0 ; Handler para o Bitmap representativo do cano de cima
        hCanoB        dd 0 ; Handler para o Bitmap representativo do cano de baixo
        hFundo        dd 0 ; Handler para o bitmap do fundo azul
        szDisplayName db "Flappy Bird",0

        contagemAsa   DWORD 0  ; variável que determina qual bitmap do pássaro será desenhado na tela
        posx          SDWORD 0 ; posição x do flappy no cálculo(negativa)
        posy          SDWORD 0 ; posição y do flappy no cálculo(negativa)
        posxA         SDWORD 0 ; posição x do flappy na tela(negativa)
        posyA         SDWORD 0 ; posição y do flappy na tela(negativa)
        canoCx        SDWORD 0 ; posição x do cano de cima na tela(negativa ou  positiva)
        canoCy        SDWORD 0 ; posição y do cano de cima na tela(negativa ou  positiva)
        canoBx        SDWORD 0 ; posição x do cano de baixo na tela(negativa ou  positiva)
        canoBy        SDWORD 0 ; posição y do cano de baixo na tela(negativa ou  positiva)
        DcanoCy       SDWORD 200  ; posição default das alturas dos canos
        DcanoBy       SDWORD -350

        indiceProX    dd 1 ; indice para a função utilizada no cálculo da posição do flappy
        pontos        db 0,0 ; variável que guarda os pontos feitos pelo usuário
        pontos2       db 0,0
        pontos3       db 0,0
        random        db 1,0
        somaRandom    dd 0
        randomOrdem   dd 0
        ExitCode      dd 0
        hThread       dd 0
        hEventStart   dd 0
        EventStop     BOOL FALSE
        perdeu        db 0,0
        textoPerdeu   db " ACABOU, PRESSIONE [c]",0
        textoPerdeu2  db "    PARA RECOMECAR",0
        textoPerdeu3  db "Pontos: ",0
        inicio        db 1,0
        vai           db 0,0
        velocidade    dd 4
        textoInicio   db " PRESSIONE A TECLA [b] PARA",0
        textoInicio2  db "    INICIAR SUA AVENTURA",0
        FontName      db "Consolas",0

    .const
        IDM_TEST    equ 1
        IDM_HELLO   equ 2
        IDM_GOODBYE equ 3
        IDM_EXIT    equ 4

        FLAPPY_ALTURA  DWORD 30
        FLAPPY_LARGURA DWORD 59
        FLAPPY_BITMAP equ 200
        FLAPPY2_BITMAP equ 210

        CANO_ALTURA  DWORD 450
        CANO_LARGURA DWORD 50
        FUNDO_BITMAP  equ 110
        CANOB_BITMAP  equ 120
        CANOC_BITMAP  equ 130

        WM_FINISH equ WM_USER+100h ; determina o fim da thread
        IDM_CREATE_THREAD equ 1 
        

; ########################### Inserted modules ############################


; #########################################################################

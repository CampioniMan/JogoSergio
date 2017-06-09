; #########################################################################
;
;                              GDI Animate
;
; This is a simple example of a GDI based animation technique. It uses the
; API function BitBlt to read different portions of a double bitmap and
; displays them on the client area of the window. The function is fast
; enough with a small bitmap to need a delay between each BLIT and the
; logic used is to have a double bitmap of the same image which is read
; in blocks that step across 1 pixel at a time until the width of the
; bitmap is completely read. This allows a continuous scrolling of the
; bitmap image.

; #########################################################################

.386
.model flat, stdcall  ; 32 bit memory model
option casemap :none  ; case sensitive

include animate.inc   ; local includes for this file

; #########################################################################
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Algumas constantes foram criadas para indicar as dimensões da imagem
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.data
char WPARAM 20h

.data?
ThreadID DWORD ?

.code

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

    invoke LoadBitmap,hInstance,100
    mov hBmp, eax

    ; loading bmp do sarinho
    invoke  LoadBitmap, hInstance, FLAPPY_BITMAP
    mov     hFlappy, eax

    invoke  LoadBitmap, hInstance, FLAPPY2_BITMAP
    mov     hFlappy2, eax

    invoke  LoadBitmap, hInstance, FUNDO_BITMAP
    mov     hFundo, eax

    invoke  LoadBitmap, hInstance, CANOB_BITMAP
    mov     hCanoB, eax

    invoke  LoadBitmap, hInstance, CANOC_BITMAP
    mov     hCanoC, eax

    invoke GetCommandLine
    mov CommandLine, eax

    invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
            hPrevInst :DWORD,
            CmdLine   :DWORD,
            CmdShow   :DWORD

    ;====================
    ; Put LOCALs on stack
    ;====================

    LOCAL wc   :WNDCLASSEX
    LOCAL msg  :MSG
    LOCAL Wwd  :DWORD
    LOCAL Wht  :DWORD
    LOCAL Wtx  :DWORD
    LOCAL Wty  :DWORD

    ;==================================================
    ; Fill WNDCLASSEX structure with required variables
    ;==================================================

    invoke LoadIcon,hInst,500    ; icon ID
    mov hIcon, eax

    szText szClassName, "Project_Class"

    mov wc.cbSize,         sizeof WNDCLASSEX
    mov wc.style,          CS_BYTEALIGNWINDOW or CS_BYTEALIGNCLIENT
    mov wc.lpfnWndProc,    offset WndProc
    mov wc.cbClsExtra,     NULL
    mov wc.cbWndExtra,     NULL
    m2m wc.hInstance,      hInst
    mov wc.hbrBackground,  COLOR_BTNFACE+1
    mov wc.lpszMenuName,   NULL
    mov wc.lpszClassName,  offset szClassName
    m2m wc.hIcon,          hIcon
    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,        eax
    m2m wc.hIconSm,        hIcon

    invoke RegisterClassEx, ADDR wc

    ;================================
    ; Centre window at following size
    ;================================

    mov Wwd, 506 ; 166 + 26
    mov Wht, 478 ; 68 + 82

    invoke GetSystemMetrics,SM_CXSCREEN
    invoke TopXY,Wwd,eax
    mov Wtx, eax

    invoke GetSystemMetrics,SM_CYSCREEN
    invoke TopXY,Wht,eax
    mov Wty, eax

    invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPED or WS_SYSMENU,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
    mov   hWnd,eax

    invoke LoadMenu,hInst,600  ; menu ID
    invoke SetMenu,hWnd,eax

    invoke ShowWindow,hWnd,SW_SHOWNORMAL
    invoke UpdateWindow,hWnd

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

    return msg.wParam
WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
            uMsg   :DWORD,
            wParam :DWORD,
            lParam :DWORD

    LOCAL var    :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[128]:BYTE  ; for text manipulation etc..
    mov ebx, hWin
    mov hWin2, ebx

    ;======== comandos do menu ========

    ; inicializando variáveis para começar o jogo
    ; pela 1ª vez
    .if uMsg == WM_CREATE
        call recomecar

    ; método para leitura de teclado
    .elseif uMsg == WM_CHAR
        push wParam
        pop  char
        .if char == 32 || char == 32 ; se apertou "a" ou  "A"
            call subir
        .elseif char == 99 || char == 67 ; se apertou "c" ou  "C"
            .if perdeu == 1
                call recomecar
            .endif
        .elseif char == 98 || char == 66 ; se apertou "b" ou "B"
            .if inicio == 1
                mov inicio, 0
                CRIAR_THREAD ThreadProc, ThreadID, hThread
            .endif
        .endif

    ; quando fecha a janela
    .elseif uMsg == WM_DESTROY
        mov  EventStop,TRUE
        invoke PostQuitMessage,NULL
        return 0

    ; método da Thread
    .elseif uMsg==WM_FINISH
        call calculaPos
        invoke InvalidateRect, hWnd, NULL, TRUE
    .endif

    ; Método Paint
    .if uMsg == WM_PAINT
        invoke BeginPaint, hWin, ADDR Ps
        mov hDC, eax

        invoke desenharFlappy, hDC

        invoke EndPaint, hWin, ADDR Ps
        return 0
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret
WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1
    shr wDim, 1
    mov eax, wDim
    sub sDim, eax

    return sDim
TopXY endp

; #########################################################################

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

voltaCanos proc
    mov canoCx, -506
    mov canoBx, -506
    inc randomOrdem
    mov somaRandom, 0

    aleatorio 190, random
    xor eax, eax
    mov eax, dword ptr[random]
    .if randomOrdem > 1
        multiplicar eax, 6
        mov randomOrdem, 0
        .if velocidade < 8
            inc velocidade
        .endif
    .endif
    add somaRandom, eax

    mov ebx, DcanoBy
    mov canoBy, ebx
    add canoBy, eax
    mov ebx, DcanoCy
    mov canoCy, ebx
    add canoCy, eax

    inc pontos
    .if pontos > 9
        mov pontos, 0
        inc pontos2
        .if pontos2 > 9
            mov pontos2, 0
            inc pontos3
            .if pontos3 > 9
                mov perdeu, 1
                mov pontos, 9
                mov pontos2, 9
                mov pontos3, 9
            .endif
        .endif
    .endif
    ret
voltaCanos ENDP

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

;  F    |<
canoAndar proc
    mov eax, velocidade
    add canoCx, eax
    add canoBx, eax
    ret
canoAndar endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

calculaPos proc
    .if perdeu == 0                ; se não perdeu
        call podeIrPraPos          ; verifica se pode ir pra próxima posição
        .if eax == 1               ; se não colidiu no canto
            call irDescendo        ; descer o flappy
            call canoAndar         ; andamos o cano para sensação de movimento
            mov eax, CANO_LARGURA  ; movemos a constante para o eax para utilizar no IF
            .if canoCx > eax       ; se o cano chegou no final
                call voltaCanos    ; voltamos ele com a aleatoriedade
            .endif
        .else                      ; se colidiu no canto (eax == 0)
            mov perdeu, 1          ; coloca 1 no perdeu (simbolizar)
            mov ExitCode, 1        ; coloca 1 no ExitCode (simbolizar)
        .endif
    .else                          ; perdeu (perdeu == 1)
    .endif
calculaPos endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////
;(((p.PosY <= ob.AlturaMax || p.PosY+p.Altura >= canvas.height-ob.AlturaMin) && 
;(p.PosX-p.Largura+25 <= canvas.width-ob.obPosX && p.PosX+p.Largura >= canvas.width-ob.obPosX)) || 
;(p.PosY+p.Altura >= canvas.height))
podeIrPraPos proc; USES eax edx ecx ebx
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    mov eax, posy          ; cálculo para o primeiro if
    sub eax, FLAPPY_ALTURA

    ; se caiu no chão
    .if (SDWORD ptr eax < -445)
        return 0
    .endif


    mov eax, posx           ;     ||
    sub eax, FLAPPY_LARGURA ;     -
                            ;     || canoBx >= posx + largura

    mov edx, posx           ;     ||
    add edx, CANO_LARGURA   ;      -
                            ;     || canoBx <= posx - canoLarg

    mov ebx, canoCy         ;     ||  posy <= canoCy - CANO_ALTURA
    sub ebx, CANO_ALTURA    ;     -^
                            ;     ||

    mov ecx, canoBy         ;     ||  posy >= canoBy + FLAPPY_ALTURA
    add ecx, FLAPPY_ALTURA  ;     -\/
                            ;     ||

    ; se está entre os canos no eixo X   &&  não está entre os canos no eixo Y
    .if (canoBx <= edx && canoBx >= eax) && !(posy >= ecx && posy <= ebx)
        return 0
    .endif

    ; se não está entre os canos no eixo X   &&  não está entre os canos no eixo Y
    ;.if !(canoBx <= edx && canoBx >= eax) && !(posy >= ecx && posy <= ebx)
    ;    return 1
    ;.endif

    ; se está entre os canos no eixo X   &&  está entre os canos no eixo Y
    ;.if (canoBx <= edx && canoBx >= eax) && (posy >= ecx && posy <= ebx)
    ;    return 1
    ;.endif

    return 1
podeIrPraPos endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

subir proc
    .if posy < 0 ; para não sair da tela
        mov indiceProX, 15
        mov contagemAsa, 0
    .endif
subir endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////    

irDescendo proc
    call graficoDeY       ; EAX agora tem o valor de quanto descer ou subir
    .if SDWORD ptr eax > 0
        mov contagemAsa, 0
    .else
        mov contagemAsa, 6
    .endif
    .if posy > -500
        add posy, SDWORD ptr eax    ; adicionando o valor do Y(-/+) pelo valor de EAX
    .endif
    add indiceProX, 1     ; andando com o índice para a próxima posição da função quadrática
irDescendo endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

graficoDeY proc
    LOCAL aux:SDWORD ; variável local criada

    ; -((indiceProX^2)/25) + indiceProX, fórmula para o cálculo -((x^2)/15) + x*2
    quadradoDe indiceProX
    mov aux, SDWORD ptr eax ; (indiceProX^2)
    dividir aux, 25
    mov aux, SDWORD ptr eax ; /25
    multiplicar aux, -1
    mov aux, SDWORD ptr eax ; -
    mov edx, indiceProX
    add aux, SDWORD ptr edx ; + indiceProX

    return aux
    ;// temos o resultado em EAX
graficoDeY endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

recomecar proc
    mov posx, -10
    mov posy, -100
    mov canoCx, -300
    mov canoBx, -300
    mov canoCy, 200
    mov canoBy, -350
    mov pontos, 0
    mov pontos2, 0
    mov pontos3, 0

    mov indiceProX, 30

    mov perdeu, 0
recomecar endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

; ########################################################################

desenharFlappy proc hDC:DWORD
    LOCAL hFImage:DWORD
    LOCAL memDC:DWORD
    LOCAL hfont:HFONT

    invoke CreateCompatibleDC,hDC
    mov memDC, eax

    invoke SelectObject,memDC,hFundo
    mov hFImage, eax
    invoke BitBlt,hDC,0,0,500,478,memDC,0,0,SRCCOPY

    .if perdeu == 1
        ESCREVE_TEXTO FontName, hDC, hfont, textoPerdeu, 0, 130
        ESCREVE_TEXTO FontName, hDC, hfont, textoPerdeu2, 0, 160
        ESCREVE_TEXTO FontName, hDC, hfont, textoPerdeu3, 50, 210
        ESCREVE_PONTUACAO FontName, hDC, hfont, pontos3, 170, 210
        ESCREVE_PONTUACAO FontName, hDC, hfont, pontos2, 190, 210
        ESCREVE_PONTUACAO FontName, hDC, hfont, pontos, 210, 210
    .elseif inicio == 1
        ESCREVE_TEXTO FontName, hDC, hfont, textoInicio, 0, 130
        ESCREVE_TEXTO FontName, hDC, hfont, textoInicio2, 0, 160
    .else
        .if contagemAsa > 5
            invoke SelectObject,memDC,hFlappy2
            mov hFImage, eax
            invoke BitBlt,hDC,0,0,500,478,memDC,posx,posy,SRCCOPY
        .else
            invoke SelectObject,memDC,hFlappy
            mov hFImage, eax
            invoke BitBlt,hDC,0,0,500,478,memDC,posx,posy,SRCCOPY
        .endif

        invoke SelectObject,memDC,hCanoB
        mov hFImage, eax
        invoke BitBlt,hDC,0,0,500,478,memDC,canoBx,canoBy,SRCCOPY

        invoke SelectObject,memDC,hCanoC
        mov hFImage, eax
        invoke BitBlt,hDC,0,0,500,478,memDC,canoCx,canoCy,SRCCOPY

        ESCREVE_PONTUACAO FontName, hDC, hfont, pontos3, 0, 0
        ESCREVE_PONTUACAO FontName, hDC, hfont, pontos2, 20, 0
        ESCREVE_PONTUACAO FontName, hDC, hfont, pontos, 40, 0
        ESCREVE_PONTUACAO_D FontName, hDC, hfont, random, 60, 0
    .endif


    invoke SelectObject,hDC,hFImage
    invoke DeleteDC,memDC
    return 0
desenharFlappy endp

;//////////////////////////////////////////////////////////////////////
;//////////////////             THREAD           //////////////////////
;//////////////////////////////////////////////////////////////////////

ThreadProc PROC USES ecx Param:DWORD

    invoke WaitForSingleObject,hEventStart,40 ;INFINITE
    .if perdeu == 0
        .IF eax == WAIT_TIMEOUT 
            invoke PostMessage, hWnd, WM_FINISH, NULL, NULL
        .ELSEIF eax == WAIT_OBJECT_0    
            invoke PostMessage, hWnd, WM_FINISH, NULL, NULL
        .ENDIF
    .endif
    
    jmp ThreadProc
        
    ret
ThreadProc ENDP

end start
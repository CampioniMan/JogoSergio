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
.const
FLAPPY_ALTURA DWORD 30
FLAPPY_LARGURA DWORD 59
FLAPPY_BITMAP equ 200
WM_FINISH equ WM_USER+100h ; determina o fim da thread
IDM_CREATE_THREAD equ 1 

.data 
mmm db "Very nice"
nnn db "Prog"

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

    invoke GetCommandLine
    mov CommandLine, eax

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
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

    mov Wwd, 303 ; 166 + 26
    mov Wht, 359 ; 68 + 82

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

    .WHILE TRUE
        INVOKE GetMessage, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        INVOKE TranslateMessage, ADDR msg
        INVOKE DispatchMessage, ADDR msg
    .ENDW

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

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Verificações para ver qual botão foi pressionado e seus respectivos métodos
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .IF uMsg == WM_COMMAND
        .if wParam == 500
            invoke GetDC,hWin
            mov hDC, eax
            invoke desenharFlappy, hWin, hDC

            invoke ReleaseDC,hWin,hDC
            return 0
        .elseif wParam == 550
            invoke PostQuitMessage,NULL
            return 0
        .endif
        .if lParam == 0
            .if ax == IDM_CREATE_THREAD
                mov  eax, OFFSET ThreadProc
                invoke CreateThread, NULL, NULL, ThreadProc, eax, 0, ADDR ThreadID
                invoke CloseHandle, eax
            .else
                invoke DestroyWindow, hWnd
            .endif
        .endif
    .ELSEIF uMsg==WM_FINISH
        invoke MessageBox,NULL,addr mmm, addr nnn,MB_OK
    .endif

    ;======== menu commands ========
    .if uMsg == WM_CREATE
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; Criando o segundo botão com um texto diferente e "ID" diferente
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        szText RunIt, "Jogar"
        szText RunIt2, "Sair"
        invoke PushButton, ADDR RunIt, hWin, 20, 300, 100, 25, 500
        invoke PushButton, ADDR RunIt2, hWin, 130, 300, 100, 25, 550

        mov pos.x, -10
        mov pos.y, -30
        mov canoC.x, 200
        mov canoC.y, 0
        mov canoB.x, 200
        mov canoB.y, 300

    .elseif uMsg == WM_CHAR
        push wParam
        pop  char
        .if char == 97 ; se apertou "a"
            invoke irDescendo
        .elseif char == 98 ; se apertou "b"
            mov ax, IDM_CREATE_THREAD
        .endif

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
        mov hDC, eax
        invoke  DeleteDC, hDC
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_CLOSE

    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret
WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim
TopXY endp

; #########################################################################

PushButton proc lpText:DWORD,hParent:DWORD,
    a:DWORD,b:DWORD,wd:DWORD,ht:DWORD,ID:DWORD

    szText btnClass,"BUTTON"

    invoke CreateWindowEx,0,
        ADDR btnClass,lpText,
        WS_CHILD or WS_VISIBLE,
        a,b,wd,ht,hParent,ID,
        hInstance,NULL

    ret
PushButton endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

Subir proc 
    sub indiceProX, 10
    ret
Subir endp 

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

irDescendo proc
    call graficoDeY
    sub pos.y, eax      ; subtraindo o valor do Y pelo valor de eax
    ret
irDescendo endp 

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

voltaCanos proc
    mov canoC.x, 500
    mov canoB.x, 500
    ret
voltaCanos ENDP

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

;  F    |<
canoAndar proc
    sub canoC.x, 2
    sub canoB.x, 2
    ret
canoAndar endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

calculaPos proc

calculaPos endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

podeIrPraPos proc

podeIrPraPos endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

graficoDeY proc
    LOCAL aux:DWORD

    ; -((indiceProX^2)/25) + indiceProX, fórmula para o cálculo
    invoke quadradoDe, indiceProX   ; (indiceProX^2)
    mov aux, eax
    invoke dividir, aux, 25         ; /25
    mov aux, edx
    invoke multiplicar, aux, -1     ; -
    mov aux, eax
    mov edx, indiceProX
    add aux, edx                    ; + indiceProX

    ret
    ;// temos o resultado em aux
graficoDeY endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

;/* Coloca em EDX o valor multiplicado */
;/* Altera EAX e EBX também            */
dividir proc primeiro:DWORD, segundo:DWORD
    mov eax, primeiro
    mov ebx, segundo
    xor edx, edx       ;coloca 0 no EDX para não haver erros
    div ebx
dividir endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

;/* Coloca em EAX o valor multiplicado */
;/* Altera ECX também                  */
multiplicar proc primeiro:DWORD, segundo:DWORD
    mov ecx, primeiro
    mov eax, segundo
    mul ecx           ; estou multiplicando os dois(ecx*EAX), será guardado em EAX o valor(e em EDX se muito grande) por default
multiplicar endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////

;/* Coloca em EAX o valor do quadrado */
quadradoDe proc base:DWORD
    mov eax, base   ; colocando o valor de 'base' em EAX
    mul eax         ; estou multiplicando o valor por si mesmo(EAX*EAX), será guardado em EAX o valor(e em EDX se muito grande) por default
quadradoDe endp

;/////////////////////////////////
;/////////////////////////////////
;/////////////////////////////////


; ########################################################################

desenharFlappy proc hWin:DWORD, hDC:DWORD
    LOCAL hFImage:DWORD
    LOCAL memDC:DWORD

    invoke CreateCompatibleDC,hDC
    mov memDC, eax
    
    invoke SelectObject,memDC,hFlappy
    mov hFImage, eax

    invoke BitBlt,hDC,10,10,256,128,memDC,pos.x,pos.y,SRCCOPY

    invoke SelectObject,hDC,hFImage
    invoke DeleteDC,memDC
    return 0
desenharFlappy endp

;//////////////////////////////////////////////////////////////////////
;//////////////////             THREAD           //////////////////////
;//////////////////////////////////////////////////////////////////////

ThreadProc PROC USES ecx Param:DWORD 
    mov  ecx,600000000 
    Loop1: 
        add  eax,eax 
        dec  ecx 
        jz   Get_out 
        jmp  Loop1 
    Get_out: ; não tira isso
        invoke PostMessage,hWnd,WM_FINISH,NULL,NULL 
    ret 
ThreadProc ENDP

end start
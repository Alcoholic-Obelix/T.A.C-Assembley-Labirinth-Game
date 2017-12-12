.8086
.MODEL SMalL
.STACK 2048

DADOS SEGMENT
;POSICAO INICIal DO MASE #################################################################################################################################
	posy	db	3	; a linha pode ir de [1 .. 25]
	posx	db	20	; POSx pode ir [1..80]
	posyo	db	3	
	posxo	db	20
;
;MENUS #################################################################################################################################
	menu	db	'			1. Jogar', 13, 10, 10
			db	'			2. Top 10', 13, 10, 10
			db	'			3. Configuracao do labirinto', 13, 10,	 10
			db	'			4. Sair', 13, 10, 10
			db	'			Escolher uma opcao --> ', 13, 10
			db	'$',0
	submenu db	'			1. Carregar labirinto por omissao', 13, 10, 10
			db	'			2. Editar labirinto', 13, 10, 10
			db	'			3. Criar labirint0', 13, 10, 10
			db	'			4. Menu anterior', 13, 10, 10
			db 	'			Escolher uma opcao --> ' 
			db	'$',0
; 
;MENSAGENS DE ERRO #################################################################################################################################			
	msgErrorCreate	db	'		Ocorreu um erro na criacao do ficheiro!$', 13, 10
					db	'		Press. ESC para voltar', 13, 10
	msgErrorOpen	db	'		Ocorreu um erro ao tentar abrir o ficheiro!$4', 13, 10
					db	'		Press. ESC para voltar', 13, 10
	msgErrorRead	db	'		Ocorreu um erro na leitura do ficheiro!$', 13, 10
					db	'		Press. ESC para voltar', 13, 10
	msgErrorWrite	db	'		Ocorreu um erro na escrita para ficheiro!$', 13, 10
					db	'		Press. ESC para voltar', 13, 10
	msgErrorClose	db	'		Ocorreu um erro no fecho do ficheiro!$', 13, 10
					db	'		Press. ESC para voltar', 13, 10
	;
;MAZE #################################################################################################################################
	car		db	32
	handle 	dw	?
	buffer	dw	?
	buffer1	dw	?
	auxm	db	0
;
;LER STRING DO TECLADO##################################################################################################
	fname	db 12
			db ?
			db 12 	dup(0)
	msgCriar	db	'Introduza o nome do ficheiro a criar:',13, 10
				db	'			-->$', 0
	msgAbrir	db	'Introduza o nome do ficheiro a abrir:',13, 10
				db	'			-->$', 0
	msgLer		db	'Introduza o nome do ficheiro a ler:', 13, 10
				db	'			-->$', 0
;
;CARREGAR LABIRINTO POR OMISSAO########################################################################################
	pedir_lab	db	'Introduza o nome do ficheiro a carregar:', 13, 10
				db	'			-->$', 0
	lab_jogar 	db	12
				db	?
				db	12	dup(0)
	default		db	'default.txt', 0
;
;COMEÇAR NO CARDINAL#####################################################################################################
	posyc		db	?
	posxc		db	?
	carc		db	?
	msgCardinal	db	'Nao foi encontrado caracter de inicio!$', 0
	

;JOGAR###################################################################################################################
	POSya		db	3	; Posição anterior de y
	POSxa		db	20	; Posição anterior de x
	ganhar		db	'Parabens! Venceu o labirinto!$', 0
	aux			db	?
	
DADOS ENDS 



;######################################################################################################################################
;											CODIGO
;##################################################################################################################


CODIGO	SEGMENT	para	public	'code'
	ASSUME	CS:CODIGO, DS:DADOS
	
;COMEÇO DO CURSOR ######################################################################################################################
GOTO_XY	macro	posx,posy
	mov		ah, 02h		;função que permite reposicionar o cursor
	mov		bh, 0	
	mov		dl, posx
	mov		dh, posy
	int		10h
endm
;

;OBTER UMA STRING DO TECLADO##################################################################################################
obtem_string macro str		;funcao para obter uma string do teclado

	call apaga_ecra
	goto_xy	20, 6			;vai para o sítio onde queremos apresentar o pedido
	mov ah, 09h
	lea dx, str
	int 21h					;imprime no ecra o conteudo da variavel introduzida em str
	goto_xy	29, 7			;reposiciona cursor

	mov ah, 0Ah					
	mov dx, offset fname
	int 21h					;le uma string do teclado, guarda tamanho do que foi lido em fname +1, guarda o que foi lido em fname +2

  								;Esta parte do código introduz $ no final da string guardada em fname + 2
	mov si, offset fname + 1 	;numero de carateres introduzidos
	mov cl, [si] 				;mover numero de carateres introduzidos para cl
	mov ch, 0      				;limpar ch para usar cx 
	inc cx 						
	add si, cx 					;incrementa em 1 o numero de carateres introduzidos
	mov al, '$'
	mov [si], al 				;substitui o ultimo byte criado na string por $, ficando assim e           
endm
;
;ERRO
ERRO_GERal macro str 	;funcao para imprimir mensagem de erros diferentes dependendo do tipo de erro
	mov		ah, 09h
	lea		dx, str		
	int 	21h			;imprime conteudo  da variavel introduzida em str
	ret
endm
;
;DESLOCAR CURSOR PARA POSIÇÃO INICIal################################################################################
POS_ORIG proc;

goto_xy posxo, posyo
ret

POS_ORIG endp
;	
;APAGAR ecra ######################################################################################################################
APAGA_ecra	proc
	xor		bx,bx						;zerar bx
	mov		cx,25*80					;mover para cx o numero de pixeis do ecra
		
APAGA:			
	mov		byte ptr es:[bx],' '		;poe o pixel em questao em branco
	mov		byte ptr es:[bx+1],7		;mudar o pixel para static e normal display	
	inc		bx							;
	inc 	bx							;inc 2 vezes o bx pois cada carater tem 2 bytes
	loop	apaga						;vou para o byte seguinte
	ret
APAGA_ecra	endp
;

;LER UMA TECLA ######################################################################################################################
LE_TECLA	PROC
	mov		ah, 08h
	int		21h
	mov		ah, 0
	cmp		al, 0
	jne		SAI_TECLA
	mov		ah, 08h
	int		21h
	mov		ah, 1
SAI_TECLA:	ret
LE_TECLA	endp
;

;COMEÇAR CURSOR NO SITIO DO CARDINal###################################################################################
CURSOR_CARDINal proc  					;funcao para o avatar iniciar sempre numa posiçao definida pelo utilizador pela tecla 'cardinal'
	mov posxc, 20						
	mov posyc, 3						;variaveis posc para o primeiro pixel do tabuleiro
ciclo:		
	goto_xy posxc, posyc				;reposiciono o cursor no primeiro pixel do labirinto
			
	mov 	ah, 08h						;Lê o carater que está na posição do cursor
	mov		bh, 0						
	int		10h							;Guarda em al o carater
	mov		carc, al					;guarda em carc o valor de al que é o carater lido anteriormente
			
	cmp 	carc, 35					;compara o carater lido com '#'
	je		fim			
		
	cmp		posxc, 60					;compara a posição de x com o final da linha do tabuleiro
	je		zerox						;se isto acontecer significa que já li a linha toda
			
	cmp 	posyc, 24					;compara a posy com a linha a seguir ao final do tabuleiro
	je		erro						;se isto acontecer significa que não existe nenhum '#' no tabuleiro
			
	inc		posxc						;se não se verificarem nenhuma das condiçoes anteriores verifico o pixel imediatamente a seguir na mesma linha
	jmp		ciclo		
			
zerox:									;a funcao vem para aqui quando acaba chega ao final da linha que está a comparar
	mov 	posxc, 20					;"reset" ao X, vai para o inicio
	inc		posyc						;vejo a linha seguinte
	jmp 	ciclo		
			
erro:		
	goto_xy 25, 24						;Se a  funcao chegar aqui significa que não encontrou o simbolo '#'
	mov 	ah, 09h						;o que significa que foi criado um mapa sem posição inicial
	lea 	dx, msgCardinal
	int 21h
	
fim:
	ret
	
CURSOR_CARDINal endp


;MOSTRAR MENU PRINCIPal ######################################################################################################################
MENUP proc
inicio:
	call	apaga_ecra
	goto_xy 0, 7
	mov 	AH, 09h
	lea 	DX, menu					;Escreve oq ue está na variavel menu
	int 21h		
			
	goto_xy 47, 15						;Posiciona o carater para escolha de opção
		
	call 	LE_TECLA 					
		
	cmp al, 49							;comparo tecla premida com '1'
	je menu1 							;se for igual vou para a opção Jogar
			
	cmp al, 50							;comparo tecla premida com '2'
	je menu2							;se for igual vou para a opção Top10
			
	cmp al, 51							;comparo tecla premida com '3'
	je menu3							;se for igual vou para a opção Editar Labirinto
			
	cmp al, 52							;comparo tecla premida com '4'
	je fim								;se for igual saio do jogo
	
	jmp inicio
	
menu1:
	call JOGAR
	jmp inicio
	
	
menu2:	
	jmp inicio
	
menu3:
	call SUBMENU3
	jmp inicio
	
fim:
	ret
		
MENUP endp
;

;MOSTRAR E LER SUBMENU 3 - opção Editar Labirinto ######################################################################################################################
SUBMENU3 	proc					
inicio:
	call 	apaga_ecra
	goto_xy 0,7
	mov 	AH, 09h
	lea 	DX, submenu
	int 21h
	
	goto_xy 47, 15
	
	call	LE_TECLA
	
	cmp 	al, 49							;comparo tecla premida com '1'				
	je		carregar_standard       		;se for igual vou para a opção Carregar labirinto por defeito
											
	cmp 	al, 50                  		;comparo tecla premida com '2'
	je		edit_fich               		;se for igual vou para a opção Editar Labirinto
											
	cmp 	al, 51                  		;comparo tecla premida com '3'
	je		criar_fich              		;se for igual vou para a opção Criar Labirinto
											
	cmp 	al, 52                  		;comparo tecla premida com '4'
	je		fim                     		;volto para o menu principal
	
	jmp inicio
	
		
carregar_standard:
	call LABIRINTO_OMISSAO
	jmp 	inicio

edit_fich:	
	call apaga_ecra
	call EDITAR_MAZE
	jmp inicio

criar_fich:
	call apaga_ecra
	call CRIAR_MAZE
	jmp inicio
	
fim:
	ret
SUBMENU3 endp
;

;CRIAR O LABIRINTO ######################################################################################################################
CRIAR_MAZE proc
	
	obtem_string msgCriar			;Lê do teclado e guarda na variavel fname
	call apaga_ecra		
		
	mov posx, 20		
	mov posy, 3						;reposiciona cursor no primeiro pixel do tabuleiro
		
	dec		POSy					; linha = linha -1
	dec		POSx					; POSx = POSx -1
	
ciclo:	goto_xy	POSx,POSy

IMPRIME:	
	mov		ah, 02h
	mov		dl, Car
	int		21H			
	goto_xy	POSx,POSy
	
	call 	LE_TECLA
	cmp		ah, 1
	je		cima
	cmp		al, 27				; ESCAPE
	je		SUBMENU3
	cmp		al, 13
	je		GUARDAR

ZERO:		
	cmp 	al, 48				; Tecla 0
	jne		UM
	mov		car, 32				;ESPAÇO
	jmp		ciclo					
	
UM:	cmp 		al, 49			; Tecla 1
	jne		DOIS
	mov		car, 219			;Caracter CHEIO
	jmp		ciclo		
	
DOIS:		
	cmp 	al, 50				; Tecla 2
	jne		TRES
	mov		car, 177			;CINZA 177
	jmp		ciclo			
		
TRES:		
	cmp 		al, 51			; Tecla 3
	jne		QUATRO
	mov		car, 178			;CINZA 178
	jmp		ciclo
	
QUATRO:
	cmp 	al, 52				; Tecla 4
	jne		destino
	mov		car, 176			;CINZA 176
	jmp		ciclo
		
destino:	
	cmp 	al, 53
	jne		start
	mov		car, 36	
	jmp		ciclo
	
start:
	cmp		al, 54
	jne		cima
	mov		car, 35
	jmp 	ciclo
	
cima:	
	cmp 		al,48h
	jne		baixo	
	cmp 	posy, 3				;compara a posição de y a 3 e apenas deixa decrementar a valores superiores
	jb		ciclo				;nao deixa o cursor sair dos limites do tabuleiro
	dec		posy				;cima
	jmp		ciclo	
	
baixo:		
	cmp		al,50h	
	jne		esquerda	
	cmp		posy, 20			;compara a posição de y a 20 e apenas deixa incrementar a valores inferiores
	ja		ciclo				;nao deixa o cursor sair dos limites do tabuleiro
	inc 	posy				;Baixo
	jmp		ciclo	
	
esquerda:	
	cmp		al,4Bh	
	jne		direita	
	cmp		posx, 20			;compara a posição de x a 20 e apenas deixa decrementar a valores superiores
	jb		ciclo				;nao deixa o cursor sair dos limites do tabuleiro
	dec		posx				;Esquerda
	jmp		ciclo	
	
direita:	
	cmp		al,4Dh	
	jne		ciclo 	
	cmp		posx, 57			;compara a posição de x a 57 e apenas deixa incrementar a valores inferiores
	ja		ciclo				;nao deixa o cursor sair dos limites do tabuleiro
	inc		posx				;Direita
	jmp		ciclo			
	
GUARDAR:	
		
	mov		ah, 3ch				; criar ficheiro para escrita 
	mov		cx, 00H				; ficheiro de texto
	lea		dx,	offset fname + 2	; dx contem endereco do nome do ficheiro 
	int		21h					; abre efectivamente e AX vai ficar com o Handle do ficheiro
	jnc inicio
	
	ERRO_GERal msgErrorCreate	;Se houver carry apresenta mensagem de erro e salta para o fim
	jmp fim

inicio:
	mov 	handle, ax			;guardo handle do ficheiro aberto com sucesso anteriormente
	xor 	si, si				;zerar si
		
ciclo1:	
	mov 	ax, es:[si]			;acedo aos pixeis do ecra, um a um
	
	add 	si, 2				;incremento si para depois aceder ao promximo pixel
		
	mov 	buffer, ax			;guardar em buffer o carater que está na posição do ecrã
	mov		bx, handle		
		
	mov		ah, 40h				;indica que vamos escrever   	
	lea		dx, buffer			;ax ->al Vamos escrever o que estiver no endereço DX
	mov		cx, 2				;2 vamos escrever 2 bytes duma vez só
	int		21h					; faz a escrita 	
	jc		erroaescrever	
	
	cmp 	si, 3520			;compara o numero de pixeis que já lemos com o numero de pixeis que queremos ler
	jne 	ciclo1
	je		fecha

erroacriar:
	ERRO_GERal msgErrorCreate
	jmp 	fim
	
erroaescrever:
	ERRO_GERal msgErrorWrite

fecha:
	mov		ah, 3eh			; indica que vamos fechar
	int	21h					; fecha mesmo
	jc erroafechar	; se não acontecer erro termina
	jmp fim
	
erroafechar:
	ERRO_GERal msgErrorClose
	
fim:
	ret
	
CRIAR_MAZE endp
;

;MOSTRAR MAZE NO ECRA#######################################################################################################################################
MOSTRAR_MAZE proc

	obtem_string msgAbrir				;pedir nome do ficheiro onde está guardado o labirinto
	call apaga_ecra

abrir_p_leitura:
	mov     ah, 3dh
	mov     al, 0			
	lea     dx,	offset fname + 2
	int     21h							;abre o ficheiro com o nome inserido em cima
	jc		erroaabrir

inicio:
	mov     handle, ax	
	goto_xy 0,0	
	
ciclo:
    mov     ah, 3fh
    mov     bx, handle
    mov     cx, 1					; vai ler 1 byte de cada vez
    lea     dx, car	        		; DX fica a apontar para o caracter lido
    int     21h 					; le 1 caracter do ficheiro
	jc		erroaler
	
	cmp	    ax, 0					;verifica se chegou ao fim do ficheiro
	je		fechar

	mov		ah, 02h
	mov		dl, car					
	int 	21h						;escreve no monitor o carater guardado em car
	
	jmp		ciclo					;repete o ciclo até acabar o ficheiro
	
fechar:
	mov     ah, 3eh					
	mov     bx, handle
	int     21h						;fecha o ficheiro	
	jc		erroafechar
	jmp 	fim

erroaabrir:
	ERRO_GERal msgErrorOpen
	jmp		fim
	
erroaescrever:
	ERRO_GERal msgErrorWrite
	jmp 	fechar
	
erroaler:
	ERRO_GERal msgErrorRead
	jmp 	fechar
	
erroafechar:
	ERRO_GERal msgErrorClose
	jmp 	fim	
	
fim:
	call POS_ORIG
	ret
MOSTRAR_MAZE endp
;

;EDITAR ECRÃ########################################################################################################
EDITAR_MAZE proc
	call	MOSTRAR_MAZE		;escreve o labirinto no ecrã de um determinado ficheiro inserido pelo utilizador
	
	mov posx, 20
	mov posy, 3

	dec		POSy				; linha = linha -1
	dec		POSx				; POSx = POSx -1

	
ciclo:	
	goto_xy	POSx,POSy			;posiciona o cursor


IMPRIME:	
	mov		ah, 02h
	mov		dl, Car
	int		21H			
	goto_xy	POSx,POSy
	
ler:	
	call 	LE_TECLA
	cmp		ah, 1
	je		cima
	cmp		al, 27				;escape
	je		fim
	cmp		al, 13
	je		guardar				;enter

ZERO:		
	cmp 	al, 48				;tecla 0
	jne		UM
	mov		car, 32				;ESPAÇO
	jmp		ciclo					
	
UM:	cmp 	al, 49				;tecla 1
	jne		dois
	mov		car, 219			;Caracter CHEIO
	jmp		ciclo		
	
DOIS:		
	cmp 	al, 50				;tecla 2
	jne		tres
	mov		car, 177			;CINZA 177
	jmp		ciclo			
		
TRES:		
	cmp 		al, 51			;tecla 3
	jne		QUATRO
	mov		car, 178			;CINZA 178
	jmp		ciclo
	
QUATRO:
	cmp 	al, 52				;tecla 4
	jne		destino
	mov		car, 176			;CINZA 176
	jmp		ciclo	
		
destino:	
	cmp 	al, 53				;tecla 5
	jne		start
	mov		car, 36				;carater '$'
	jmp		ciclo
	
start:
	cmp		al, 54				;tecla 6
	jne		cima
	mov		car, 35				;carater '#'
	jmp 	ciclo

cima:	
	cmp 		al,48h
	jne		baixo
	cmp 	posy, 3
	jb		ciclo
	dec		posy				;cima
	jmp		ciclo

baixo:	
	cmp		al,50h
	jne		esquerda
	cmp		posy, 20
	ja		ciclo
	inc 	posy				;Baixo
	jmp		ciclo

esquerda:
	cmp		al,4Bh
	jne		direita
	cmp		posx, 20
	jb		ciclo
	dec		posx				;Esquerda
	jmp		ciclo

direita:
	cmp		al,4Dh
	jne		ciclo 
	cmp		posx, 57
	ja		ciclo
	inc		posx				;Direita
	jmp		ciclo

GUARDAR:
	
	mov		ah, 3ch				; criar ficheiro para escrita com o nome pedido ao utiliador anteriormente
	mov		cx, 00H				; ficheiro de texto
	lea		dx,	offset fname + 2	; dx contem endereco do nome do ficheiro 
	; lea		dx, fname1
	int	21h						; abre efectivamente e ax vai ficar com o handle do ficheiro
	jnc inicio
	
	call erroacriar
	jmp fim

inicio:
	mov 	handle, ax
	xor 	si, si				;zerar si
	
ciclo1:
	mov 	ax, es:[si]

	add 	si, 2
	
	mov 	buffer, ax
	mov		bx, handle			; para escrever BX deve conter o Handle 
	mov		ah, 40h				; indica que vamos escrever 
    	
	lea		dx, buffer			;ax ->al Vamos escrever o que estiver no endereço DX
	mov		cx, 2				;2 vamos escrever multiplos bytes duma vez só
	int	21h						;faz a escrita 	
	jc	erroaescrever
	
	cmp 	si, 3520
	jne 	ciclo1
	je		fecha

erroacriar:
	ERRO_GERal msgErrorCreate
	jmp 	fim
	
erroaescrever:
	ERRO_GERal msgErrorWrite

fecha:
	mov		ah, 3eh			; indica que vamos fechar
	int	21h					; fecha mesmo
	jc erro_fechar			; se não acontecer erro termina
	jmp fim
	
erro_fechar:
	ERRO_GERal msgErrorClose
	
fim:
	ret

EDITAR_MAZE endp

;CARREGAR LABIRINTO POR OMISSÃO#######################################################################################
LABIRINTO_OMISSAO proc

	call apaga_ecra
	goto_xy	20,6
	mov ah,09h
	lea dx,	pedir_lab
	int 21h						;escrevo no ecrã um pedido para inserirem uma string
	goto_xy	29,7

	mov ah, 0Ah
	mov dx,offset lab_jogar		
	int 21h						;Ler String do teclado

  								
	mov si, offset lab_jogar + 1;Esta parte do código introduz $ no final da string guardada em fname + 2
	mov cl, [si] 				;numero de carateres introduzidos
	mov ch, 0      				;mover numero de carateres introduzidos para cl
	inc cx 						;limpar ch para usar cx 
	add si, cx 					
	mov al, '$'                 ;incrementa em 1 o numero de carateres introduzidos
	mov [si], al 				
	                            ;substitui o ultimo byte criado na string por $, ficando assim e           
	ret
abrir_p_leitura:
	mov     ah, 3dh
	mov     al, 0			
	lea     dx,	offset lab_jogar + 2
	int     21h					; Chama a rotina de abertura de ficheiro (AX fica com Handle)
	jc		erroaabrir
	mov handle, ax
	
fechar:
	mov     ah, 3eh
	mov     bx, handle
	int     21h
	jc		erroafechar
	jmp 	fim
	
erroafechar:
	ERRO_GERal msgErrorClose
	jmp 	fim	

erroaabrir:
	ERRO_GERal msgErrorWrite
	jmp		fim
	
fim:	
	ret	

LABIRINTO_OMISSAO endp

;JOGAR COM O LABIRINTO PREDEFINIDO############################################################################################
JOGAR proc

call apaga_ecra

abre_ficheiro:
	mov     ah,3dh
	mov     al,0
	lea     dx,offset lab_jogar + 2 
	int     21h						; Chama a rotina de abertura de ficheiro (AX fica com Handle)
	jnc		continua				;Se tiver um labirinto inserido pelo utilizador jogamos com esse
	mov     ah,3dh					;Se não jogamos com o noss default
	mov     al,0
	lea     dx, default 			
	int     21h						;abrir ficheiro para leitura
	mov     handle,ax
	xor	    si,si					;zerar si
	
	continua:
	mov     handle,ax
	xor	    si,si					

inicio:
	mov		posx, 20
	mov 	posy, 3
	goto_xy 0,0						;cursor no inicio do ecra
	
ciclo:
    mov     ah, 3fh
    mov     bx, handle
    mov     cx, 1					; vai ler 1 byte de cada vez
    lea     dx, car	        		; DX fica a apontar para o caracter lido
    int     21h 					; le 1 caracteres do ficheiro
	jc		erroaler
	
	cmp	    ax, 0					; verifica se chegou ao fim do ficheiro
	je		fechar

	mov		ah, 02h
	mov		dl, car
	int 	21h						;Escreve no ecrã
	jmp		ciclo
fechar:
	mov     ah, 3eh
	mov     bx, handle
	int     21h
	jc		erroafechar
	
	mov 	ah, 08h					;Guarda o Caracter que está na posição do Cursor
	mov		bh,0					;numero da página
	int		10h			
	mov		Car, al					;Guarda o Caracter que está na posição do Cursor	
	mov 	aux, 0					;zerar variavel aux com o objectivo de correr 'comeco:' apenas uma ve
	
ciclo1:	
	goto_xy	POSxa,POSya				;vai para a posição anterior do cursor
	mov		ah, 02h
	mov		dl, Car					;repoe Caracter guardado 
	int		21H		
	
	goto_xy	posx,posy				;Vai para nova posição
	mov 		ah, 08h
	mov		bh,0					;numero da página
	int		10h		
	mov		Car, al					;Guarda o Caracter que está na posição do Cursor
	
	goto_xy	78,0					;Mostra o caractr que estava na posição do AVATAR
	mov		ah, 02h					;IMPRIME caracter da posição no canto
	mov		dl, Car	
	int		21H			
	
	cmp aux, 0						;quero correr 'comeco:' apenas uma vez 
	je	comeco
	jmp cursor
	
comeco:
	call 	CURSOR_CARDINAL
	mov		aux, 1
	mov		ah, posxc
	mov		posx, ah
	mov		ah, posyc
	mov		posy, ah

cursor:
	goto_xy	POSx,POSy				;vai para posição do cursor
	
imprime:	
	mov		ah, 02h
	mov		dl, 190					;Coloca AVATAR
	int		21H	
	goto_xy	posx,posy				;Vai para posição do cursor
	
	mov		al, POSx				;Guarda a posição do cursor
	mov		POSxa, al
	mov		al, POSy				;Guarda a posição do cursor
	mov 	POSya, al

ler_seta:	
	call 	LE_TECLA
	cmp		ah, 1
	je		cima
	cmp 	al, 27					;ESCAPE
	je		fim
	jmp		ler_seta
	
		
cima:	
	cmp 	al, 48h
	jne		baixo
	cmp 	posy, 3					;compara a posição de y a 3 e apenas deixa decrementar a valores superiores
	jb		ciclo1					;nao deixa o cursor sair dos limites do tabuleiro
	dec		posy					;Cima
	goto_xy posx, posy				;manda o cursor para a nova posição
	mov 	ah, 08h
	mov		bh,0					;numero da página
	int		10h						;Le o carater da nova posição do cursor
	cmp		al, '$'					
	je 		ganhou					;se o carater for '$' vence o labirinto
	cmp 	al, ' '					;se o carater for ' ' significa que a mudança na posição efectuada anteriormente é valida
	je		ciclo1					;logo deixa ir para o ciclo onde vamos mexer o avatar
	inc		posy					;se o carater lido na nova posiçao for diferente de '$' ou de ' ' significa que a nova posição é uma parede
	jmp		ciclo1					;logo temos que "corrigir" o valor anulando assim o movimento que queriamos ter feito

baixo:	
	cmp		al,50h
	jne		esquerda
	cmp		posy, 20				;compara a posição de y a 20 e apenas deixa incrementar a valores inferiores
	ja		ciclo1					;nao deixa o cursor sair dos limites do tabuleiro	
	inc 	posy					;Baixo
	goto_xy posx, posy		
	mov 	ah, 08h		
	mov		bh,0					;numero da página
	int		10h	            		;Le o carater da nova posição do cursor
	cmp		al, '$'         		
	je 		ganhou	        		;se o carater for '$' vence o labirinto
	cmp 	al, ' '         		;se o carater for ' ' significa que a mudança na posição efectuada anteriormente é valida
	je		ciclo1          		;logo deixa ir para o ciclo onde vamos mexer o avatar
	dec		posy            		;se o carater lido na nova posiçao for diferente de '$' ou de ' ' significa que a nova posição é uma parede
	jmp		ciclo1          		;logo temos que "corrigir" o valor anulando assim o movimento que queriamos ter feito

esquerda:
	cmp		al,4Bh
	jne		direita					;compara a posição de x a 20 e apenas deixa decrementar a valores superiores
	cmp		posx, 20       			;nao deixa o cursor sair dos limites do tabuleiro
	jb		ciclo1
	dec		posx					;Esquerda
	goto_xy posx, posy
	mov 	ah, 08h
	mov		bh,0					;numero da página
	int		10h						;Le o carater da nova posição do cursor
	cmp		al, '$'     		    
	je 		ganhou      		    ;se o carater for '$' vence o labirinto
	cmp 	al, ' '     		    ;se o carater for ' ' significa que a mudança na posição efectuada anteriormente é valida
	je		ciclo1      		    ;logo deixa ir para o ciclo onde vamos mexer o avatar
	inc		posx        		    ;se o carater lido na nova posiçao for diferente de '$' ou de ' ' significa que a nova posição é uma parede
	jmp		ciclo1      		    ;logo temos que "corrigir" o valor anulando assim o movimento que queriamos ter feito

direita:
	cmp		al,4Dh
	jne		ciclo1 
	cmp		posx, 57				;compara a posição de x a 57 e apenas deixa incrementar a valores inferiores
	ja		ciclo1      			;nao deixa o cursor sair dos limites do tabuleiro
	inc		posx					;Direita
	goto_xy posx, posy
	mov 	ah, 08h
	mov		bh,0					; numero da página
	int		10h						;Le o carater da nova posição do cursor
	cmp		al, '$'                 
	je 		ganhou	                ;se o carater for '$' vence o labirinto
	cmp 	al, ' '                 ;se o carater for ' ' significa que a mudança na posição efectuada anteriormente é valida
	je		ciclo1                  ;logo deixa ir para o ciclo onde vamos mexer o avatar
	dec		posx                    ;se o carater lido na nova posiçao for diferente de '$' ou de ' ' significa que a nova posição é uma parede
	jmp		ciclo1                  ;logo temos que "corrigir" o valor anulando assim o movimento que queriamos ter feito
	
ganhou:
	call apaga_ecra
	goto_xy	20,6
	mov		ah, 09h
	lea		dx, ganhar
	int 	21h						;imprime a mensagem vitoriosa
	jmp fim

erroaabrir:
	ERRO_GERal msgErrorOpen
	jmp		fim
	
erroaescrever:
	ERRO_GERal msgErrorWrite
	jmp 	fechar
	
erroaler:
	ERRO_GERal msgErrorRead
	jmp 	fechar
	
erroafechar:
	ERRO_GERal msgErrorClose
	jmp 	fim	
	
fim:
	call LE_TECLA
	ret		
	

JOGAR endp

Main proc

	mov		ax, dados
	mov		ds, ax
	mov 	ax, 0B800h
	mov 	es, ax
	
	call 	MENUP
	
fim:
	mov ah,4ch
	int 21h

main	endp
CODIGO	ENDS
END	main
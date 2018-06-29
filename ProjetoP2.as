; Joao Carlos Morgado David - 89471
; Bernardo Cunha Matos - 89419

;---------------------------------------------------------------
; ZONA 1: Definicao de constantes

DISP_SEGM0 		EQU 	FFF0h
DISP_SEGM1 		EQU 	FFF1h
SET_LCD 		EQU 	FFF4h
OUT_LCD 		EQU 	FFF5h
SET_TEMP 		EQU 	FFF6h
START_TEMP 		EQU 	FFF7h
LEDS			EQU 	FFF8h
SET_JANELA 		EQU 	FFFCh
OUT_JANELA		EQU	FFFEh
NL			EQU	000Ah
IDENT			EQU 	0009h
SP_INICIAL		EQU	FDFFh
FIM_TEXTO		EQU 	'@'
mascaraRng   		EQU 	1000000000010110b
INT_MASK_ADDR    	EQU     FFFAh
INT_MASK         	EQU     1000010001111110b

;---------------------------------------------------------------
; ZONA 2: Definicao de interrupcoes
                	ORIG    FE01h
INT1 			WORD 	INT1F
INT2 			WORD 	INT2F
INT3 			WORD 	INT3F
INT4 			WORD 	INT4F
INT5 			WORD 	INT5F
INT6 			WORD 	INT6F
			ORIG    FE0Ah
INTA            	WORD    INTAF
	 		ORIG    FE0Fh 	
INTF 			WORD 	INTFF

;---------------------------------------------------------------
; ZONA 3: Definicao de variaveis
                       
                        ORIG    8000h
; geracao aleatoria
valI 			WORD 	0						
repeticoes  		WORD 	15

; variaveis de jogo            
escolha                 WORD    0
codigo                  WORD    1010011100b
resultado 		WORD 	0

comecou                 WORD    0                               ; indica se o jogo foi iniciado
pode_jogar 		WORD 	0                               ; indica quando o jogador pode jogar
tempo_restante 		WORD 	FFFFh
turno 			WORD 	0
high_score 		WORD 	13

cursor 			WORD 	0
carResultados 		STR 	'-ox'
high_scoreStr		STR 	'High Score:', FIM_TEXTO
comecarStr 		STR 	'Pressione IA para jogar', FIM_TEXTO
cabecalhoStr		STR 	'Turno      Jogada      Resultado', NL, FIM_TEXTO
espaco8			STR 	'        ', FIM_TEXTO
espaco9                 STR     '         ', FIM_TEXTO 
nova_linha 		STR 	NL, FIM_TEXTO
vitoriaStr 		STR 	'        xxxx', NL, 'O jogador acertou a sequencia!!!', NL, FIM_TEXTO
derrotaStr 		STR 	'Errou os 12 turnos!!! A sequencia correta era: ', FIM_TEXTO
derrota_tempoStr 	STR 	NL, 'O tempo de jogada expirou!!! A sequencia correta era: ', FIM_TEXTO
            
;----------------------------------------------------------------
; ZONA 4: Codigo
                        ORIG    0000h
                        JMP 	set_up

;----------------------------------------------------------------
; INTERRUPCOES

; comecar ou recomecar o jogo(funciona num jogo em decorrimento)
INTAF: 			PUSH    R7                              ; para repor o valor
                        MOV     R7, 1                           ; assinalamos que se deu sinal para (re)comecar
                        MOV     M[comecou], R7
                        POP     R7
			RTI

; escolhas 
INT1F:			PUSH 	1
			CALL 	fazer_escolha
			RTI

INT2F:			PUSH 	2
			CALL 	fazer_escolha
			RTI

INT3F:			PUSH 	3
			CALL 	fazer_escolha
			RTI

INT4F:			PUSH 	4
			CALL 	fazer_escolha
			RTI

INT5F:			PUSH 	5
			CALL 	fazer_escolha
			RTI

INT6F:			PUSH 	6
			CALL 	fazer_escolha
			RTI

; temporizador
INTFF:			CMP 	M[pode_jogar], R0 		; apenas corre se e a vez de jogar
			BR.Z 	fim_temp
			PUSH 	R7 				; para repor o valor			
			SHR 	M[tempo_restante], 1
			MOV 	R7, M[tempo_restante]
			MOV 	M[LEDS], R7
			CMP 	M[tempo_restante], R0

			MOV 	R7, 5 				; chamamos recursivamente o timer
			MOV 	M[SET_TEMP], R7
			MOV 	R7, 1
			MOV 	M[START_TEMP], R7
			POP 	R7
fim_temp:		RTI

;----------------------------------------------------------------
; FUNCAO: FAZER_ESCOLHA
;	Input: Numero
; 	Output: M[escolha], janela de texto
;	Descricao: Recebe um valor de 1-6 das interrupcoes dos butoes de
;	pressao, atualiza a janela de texto e o codigo escolhido de acordo
; 	com o butao pressionado.

fazer_escolha:		CMP 	M[pode_jogar], R0		; verificamos se o jogador pode fazer a jogada
			BR.Z 	fim_escolha
			PUSH 	R7 				; para repor o valor
			MOV 	R7, M[SP+3]			; o digito escolhido
			OR 	M[escolha], R7
			PUSH 	R7
			CALL 	escrever_digito 		; escrevemos o digito
			
			MOV 	R7, M[escolha]
			CMP     R7, 1000000000b                 ; ja se tinham feito 3 jogadas
			BR.NN   terminou_jogada
			
			SHL 	M[escolha], 3 			; damos shift left se nao e o ultimo digito
			POP 	R7

fim_escolha:		RETN 	1

terminou_jogada:        MOV     M[pode_jogar], R0 		; assinala-se que acabou a jogada
                        POP 	R7
                        RETN    1

;----------------------------------------------------------------
; Set up inicial
; 	Descricao: Inicializa-se o que tem de ser inicializado, tal como
; 	associa-se valores a variaveis na memorica, para confirmar o seu valor.

set_up:			MOV 	R7, SP_INICIAL			; inicializamos SP
			MOV 	SP, R7
			MOV    	R7, INT_MASK 			; e a mascara de interrupcoes
                 	MOV    	M[INT_MASK_ADDR], R7
			MOV 	R7, FFFFh			; inicializamos o ponteiro da janela de texto
			MOV 	M[SET_JANELA], R7
			MOV 	M[cursor], R0
			MOV 	R7, 13
			MOV 	M[high_score], R7
			CALL 	iniciar_lcd
			PUSH 	comecarStr
			CALL 	escrever_texto
			ENI

;----------------------------------------------------------------
; Definicao de valI do RNG 

gera_valI:		INC 	M[valI] 			; esta rotina apenas e usada uma vez, uma vez que
                        CMP     M[comecou], R0                  ; verificamos se comecou
                        BR.NZ   novo_jogo
			BR	gera_valI

idle:			CMP     M[comecou], R0                  ; esperamos que o jogador recomece
                        BR.NZ   novo_jogo
                        BR	idle 				; esperamos que se recomece o jogo

                	
novo_jogo:              ENI
                        MOV     M[comecou], R0 
                        MOV 	M[turno], R0
                        MOV 	M[DISP_SEGM0], R0
			MOV 	M[DISP_SEGM1], R0
                 	CALL 	limpa_janela
                 	CALL 	gerar_aleatorio
                 	JMP 	inicio_jogo 			; gera-se um novo valor aleatorio


;---------------------------------------------------------------
; MODULO: GERAR_ALEATORIO
; 	Descricao: Este modulo gera um numero pseudoaleatorio atraves da varias repeticoes pelo algoritmo
;	dado no enunciado. No fim divide-se por 6 para obter um resto entre 0 e 5 e soma-se 1, isto repete-se
;	para os 4 digitos da sequencia. Utiliza todos os registos de uso geral

gerar_aleatorio:	MOV 	M[codigo], R0 			; limpa-se o numero anterior 
			MOV 	R6, 4				; numero de digitos a gerar (n)
			MOV 	R7, R0				; contador de repeticoes

gerar_digito:		MOV	R4, 1b 				; preparamos para avaliar o ultimo bit
			MOV	R5, M[valI] 			; R5 fica com Ni 
			AND	R4, R5				; R4 tem o menos significativo
			BR.Z 	1  				; se N0 == 0, salta-se o XOR
			XOR	R5, mascaraRng	
			ROR	R5, 1            		
			MOV	M[valI], R5      		; Geramos Ni+1
			INC	R7               		; i++
			CMP	R7, M[repeticoes] 		; i == repeticoes?
			BR.Z 	final_geral      		; se sim, saltamos para obter o digito
			BR	gerar_digito  			; se nao, repete-se
 	
final_geral: 		MOV 	R4, 6	
			DIV 	R5, R4     			; Dividimos Ni por 6 para o resto ficar entre 0 e 5
			ADD 	R4, 1      			; R4 fica com um valor aleatorio entre 1 e 6
			PUSH	R4 				; adiciona-se o resultado a pilha
			MOV	R7, R0	        		; da-se reset a i
			DEC 	R6        			; n-- 
			JMP.NZ	gerar_digito			; se n != 0, gera-se um  novo

;-----------------------------------------------------------------
; JUNTAR OS DIGITOS
; 	Juntam-se os 4 digitos gerados no registo R1.
			
			POP	R1        			; retiramos da pilha os 4 digitos
			POP	R2        			
			POP	R3        			
			POP	R4        			
			SHL	R2,3      			; metemos cada digito a ocupar 3 bits diferentes
			SHL	R3,6	  			
			SHL	R4,9	  			
			OR 	M[codigo], R1   		; juntamos todos os digitos
			OR	M[codigo], R2     	
			OR	M[codigo], R3
			OR	M[codigo], R4

			RET
						
;----------------------------------------------------------------
; MODULO: INICIAR_LCD
;	Input: M[high_scoreStr]
;	Output: LCD
;	Descricao: Inicia o LCD com a respetiva string que lhe pertence.
;	Utiliza R5-R7

iniciar_lcd: 		MOV 	R7, 1000000000000000b 		; inicializamos o LCD
			MOV 	M[SET_LCD], R7
			MOV 	R6, high_scoreStr 		; endereco da string

loop_texto_lcd: 	MOV 	R5, M[R6]			; caracter[i]
			CMP 	R5, FIM_TEXTO
			BR.Z 	fim_escreve_lcd
			MOV 	M[OUT_LCD], R5
			INC 	R6
			INC 	R7
			MOV 	M[SET_LCD], R7
			BR 	loop_texto_lcd

fim_escreve_lcd:  	RET

;----------------------------------------------------------------
; MODULO: ATUALIZA_LCD
; 	Input: M[high_score]
; 	Output: LCD
;	Descricao: Atualiza o LCD. Apenas e utilizada quando se tem de atualizar
;	a pontuacao maxima (no fim do jogo), portanto, nao e preciso qualquer input uma vez que a pontuacao
; 	e sempre escrita no mesmo local. Utiliza R5-R7.

atualiza_lcd:		MOV 	R7, 1000000000010000b 		; metemos o cursor no inicio da segunda fila
			MOV 	M[SET_LCD], R7
			MOV 	R6, ' ' 			; limpamos o resultado previamente escrito
			MOV 	M[OUT_LCD], R6
			INC 	R7
			MOV 	M[SET_LCD], R7
			MOV 	M[OUT_LCD], R6

			MOV 	R7, 1000000000010000b 		; R7 ficara com a posicao do cursor
			MOV 	M[SET_LCD], R7
			MOV 	R6, M[high_score] 		; copiamos o highscore
			MOV 	R5, 10d	
			DIV 	R6, R5 				; fica-se com as dezenas em R6 e as unidades em R5
			PUSH 	R6	
			CALL 	escrever_digito_lcd				
			INC 	R7
menor_que_10_lcd: 	MOV 	M[SET_LCD], R7
			PUSH 	R5	
			CALL 	escrever_digito_lcd		
			RET

;----------------------------------------------------------------
; FUNCAO AUXILIAR: ESCREVER_DIGITO_LCD
; 	Input: Numero 0-9
; 	Output: LCD
; 	Descricao: Imprime um digito no LCD. Preserva os registos anteriores.
;	Utiliza R7.

escrever_digito_lcd: 	PUSH 	R7				; para repor R7
			
			MOV 	R7, M[SP+3]
			ADD 	R7, '0'  			; convertemos o digito para ASCII
			MOV 	M[OUT_LCD], R7
			
			POP 	R7
			RETN 	1


;----------------------------------------------------------------
; FUNCAO: ESCREVER_TEXTO
;	Input: Endereco da string guardada em memoria
;	Output: Janela de texto
;	Descricao: Esta funcao percorre uma string guardada na memoria, escrevendo cada caracter ate que se encontre o 
;	caracter FIM_TEXTO.
; 	Esta funcao apenas e chamada em "pausas logicas", ou seja, enquanto a logica do jogo nao esta a decorrer
; 	portanto nao e necessaria a reposicao dos registos. Utiliza R5-R7.

escrever_texto:		MOV 	R7, M[SP + 2] 			; guardamos a posicao inicial da string no registo R7
						
loop_texto:		MOV 	R5, M[cursor]			; posicao atual do cursor
			MOV 	M[SET_JANELA], R5

			MOV 	R6, M[R7]			; movemos para R6 o caracter[i] associado ao endereco
			
			CMP 	R6, FIM_TEXTO 			; caracter[i] == FIM_TEXTO?
			BR.Z 	fim_texto 			; se sim, saimos
			
			CMP 	R6, NL
			BR.Z 	new_line

			MOV 	M[OUT_JANELA], R6 		; escrevemos na caixa de texto
			INC 	M[cursor]			; proxima posicao no curso
			
proximo_car:		INC 	R7		 		; i++			
			
			BR	loop_texto 	
fim_texto: 		RETN 	1		      	    	; return e limpamos o argumentos do stack

;----------------------------------------------------------------
; MODULO AUXILIAR: NEW_LINE
; 	Descricao: Coloca o cursor na fila seguinte, na coluna 0, e volta
;	a funcao escrever texto. Neste caso e necessario preservar os valores anteriores
; 	uma vez que este modulo apenas e chamado dentro de outras funcoes, que estao a decorrer. Logo,
; 	temos de ter cuidado para nao alterar os valores das outras funcoes. Utiliza R7.

new_line: 		PUSH 	R7				; para repor R7

			MVBL 	M[cursor], R0 			; mete-se o cursor na coluna 0
			MOV 	R7, 100000000b 			; passa-se a fila seguinte, bit de menor peso do octeto mais significativo
			ADD 	M[cursor], R7
			
			POP 	R7
			BR	proximo_car

;----------------------------------------------------------------
; MODULO: LIMPA_JANELA
; 	Descricao: Preenche a janela de texto com espacos brancos.
; 	Como e chamado apenas quando se (re)inicia o jogo, nao se tem de preservar os valores
; 	dos registos. Utiliza R6-R7.

limpa_janela: 		MOV 	R7, R0 				; R7 vai indexar as posicoes da janela
			MOV 	R6, ' '

limpar_janela_loop: 	MOV 	M[SET_JANELA], R7
			MOV 	M[OUT_JANELA], R6 		; metemos um espaco vazio na posicao R7
			INC 	R7 				; passamos para a proxima posicao
			CMP 	R7, 0001100100000000b 		; fila 25 ja e supostamente inexistente
			BR.NZ 	limpar_janela_loop
			MOV 	M[cursor], R0			; damos reset ao cursor
			MOV 	M[SET_JANELA], R0
			RET	

;----------------------------------------------------------------
; FUNCAO: ESCREVER_DIGITO
; 	Input: Numero 0-9
; 	Output: Janela de texto
; 	Descricao: Imprime um digito na janela de texto. Preserva os registos anteriores.
; 	Utiliza R7.

escrever_digito: 	PUSH 	R7 				; para repor o valor
			
			MOV 	R7, M[cursor]			; retiramos da memoria a posicao atual do cursor
			MOV 	M[SET_JANELA], R7
	
			MOV 	R7, M[SP+3]
			ADD 	R7, '0'  			; convertemos o digito para ASCII
			MOV 	M[OUT_JANELA], R7
			INC 	M[cursor]			; proxima coluna da janela de texto
			
			POP 	R7
			RETN 	1
			
;----------------------------------------------------------------
; MODULO: COMPARAR
;	Input: M[codigo], M[escolha]	
;	Output: M[resultado]
;	Descricao: Este modulo compara as duas sequencias, comeca por encontrar os 'x', depois os 'o' 
;	e por fim "shifta" a sequencia ate ficar do tipo <pos_certa>*<num_certo>*<errados>*.
;	Se as sequencias forem iguais, termina-se logo.
;   	O resultado e representado em apenas 8 bits
;	2 - numero certo na posicao certa
;	1 - numero certo na posicao errada
;	0 - numero errado
; 	Nao se preservam os registos anteriores uma vez que este e um dos modulos principais. Sao usados todos
; 	os registos de uso geral.
               
comparar:               MOV     R1, M[codigo]               	; R1 fica com o codigo secreto
                        MOV     R2, M[escolha]              	; R2 com a jogada
                        CMP 	R1, R2 			    	; verifica-se o caso de vitoria
                        JMP.Z 	vitoria	
                        MOV     R3, 0                       	; R3 com o resultado
                        MOV     R4, 4                       	; conta rotacoes
	
verificar_pos_certa:    MOV     R6, 111b                    	; R6 com o ultimo digito do codigo secreto
                        MOV     R7, 111b                    	; R7 para a jogada
                        AND     R6, R1	
                        AND     R7, R2	
                        CMP     R7, R6	
                        CALL.Z  pos_certa                   	; se sao iguais, ha dois digitos na pos certa     
                        ROR     R1, 3                       	; passamos para o proximo digito
                        ROR     R2, 3	
                        DEC     R4                          	; decrementamos o contador de iteracoes
                        CMP     R4, R0 	
                        BR.NZ   verificar_pos_certa         	; loop se nao chegamos ao fim
                        	
                        	
verificar_num_certo:    ROR     R1, 4                       	; recuperamos o codigo e a escolha
                        ROR     R2, 4	
			MOV     R4, 4                       	; conta rotacoes da escolha
                        MOV     R5, 4                       	; conta rotacoes do codigo
                        	
num_certo_loop: 	MOV     R6, 111b                    	; R6 com o ultimo digito do codigo secreto
                        MOV     R7, 111b                    	; R7 para a jogada
                        AND     R6, R1	
                        AND     R7, R2	
                        	
                        CMP     R6, R7                      	; dois digitos, posicoes erradas
                        CALL.Z  num_certo	
                        ROR     R1, 3                       	; proximo digito do codigo secreto
                        DEC     R5	
                        CMP     R5, R0			    	; R5 ja rodou 4 vezes?
                        BR.NZ   num_certo_loop              	; se nao, nao se da reset ao codigo secreto
                        	
			MOV     R5, 4                       	; damos reset as posicoes do codigo e ao contador
                        ROR     R1, 4	
                        DEC     R4                          	; passamos ao proximo digito da escolha
                        ROR     R2, 3	
                        	
                        CMP 	R4,R0	
                        BR.NZ   num_certo_loop 		    	; loop se nao chegamos ao fim
                       	CALL 	loop_zeros	
	
fim_comparar:           MOV 	M[resultado], R3            	; guardamos o resultado
			RET	
                     	
	
pos_certa:              OR      R3, 2                       	; adicionamos um pos_certa ao resultado
                        BR      skip_num_certo                  ; salta-se num_certo
num_certo:              OR      R3, 1	
skip_num_certo:         AND     R1, 1111111111111000b       	; fica fora do alcance dos digitos (0)
                        OR      R2, 0000000000000111b       	; fica fora do alcance dos digitos (7)                     
                        CALL    verificar_shift 						                      
                        RET	
							
verificar_shift:	CMP 	R3, 64			    	; se R3 >= 1000000b  ocupa tantos bits como ja devia, nao se faz shift left
			BR.NN 	nao_shift	
			SHL 	R3, 2           	    	; porque cada "indicador de resultado" ocupa 2 bits
nao_shift: 		RET	
	
loop_zeros: 		CMP 	R3, 0000h 		    	; se R3 == 0, nao ha shifts para fazer
			BR.Z 	fim_comparar	
			BR 	skip_add_zero		    	; se nao, saltamos uma instrucao para nao meter um shift a mais
add_zero:		SHL	R3, 2	
skip_add_zero:		CMP 	R3, 64		    	    	; damos loop ate preencher o resto com zeros
			BR.N 	add_zero
			BR 	fim_comparar
                        
;---------------------------------------------------------------
; MODULO: ESCREVER_RESULTADO
; 	Input: M[resultado], carResultados
; 	Output: Janela de texto
; 	Descricao: Escreve o resultado na janela de texto com os caracteres em guardados em carResultados.
; 	Este modulo e apenas chamado em "pausas logicas", ou seja, enquanto a logica do jogo nao esta a decorrer
; 	portanto nao e necessaria a reposicao de qualquer registo.

escrever_resultado: 	PUSH	espaco8				; alinha-se a tabela
			CALL 	escrever_texto
				
				
			MOV 	R7, carResultados 		; o endereco dos caracteres de resultado
			MOV 	R6, 4 				; o numero de repeticoes
			MOV 	R5, M[resultado]	
				
	
analisar_resultado:	MOV 	R4, M[cursor]			; damos set ao cursor
			MOV 	M[SET_JANELA], R4

			CMP 	R6, R0 				; n == 0?
			BR.Z 	fim_escrever_resultado 	 	; se sim, terminamos 	
			MOV 	R4, 11000000b 			; para retirar os 2 primeiros bits
			AND 	R4, R5	
			SHR 	R4, 6 				; para ficar nos ultimos 2 bits
			SHL 	R5, 2 				; passamos para os proximos digitos
			ADD 	R4, R7				; ficamos assim com o caracter correto (endereco + 1 = 'o', etc.)
				
			MOV 	R4, M[R4] 			; guardamos o codigo caracter no proprio registo
			MOV 	M[OUT_JANELA], R4		; passamos para a janela de texto
			INC 	M[cursor] 			; passamos para a proxima coluna
			DEC 	R6 				; n--
			BR 	analisar_resultado 		; repetimos o processo

fim_escrever_resultado: PUSH	nova_linha
			CALL 	escrever_texto
			RET 

;----------------------------------------------------------------
; MODULO: ESCREVER_TURNO
; 	Input: M[turno]
;	Output: Janela de texto (tambem pede para escrever no display de 7 segmentos)
;	Descricao: Este modulo converte o numero de turnos para BCD (tendo em conta que este e 
; 	sempre menor que 100) e de seguida imprime o digito a digito na janela de texto.
; 	Mais uma vez esta rotina apenas e "principal" portanto nao vale a pena preservar
; 	os registos no stack. Utiliza R6-R7.
	
escrever_turno:		MOV 	R7, M[turno] 			; copiamos o numero de turno porque iria sofrer alteracoes
			MOV 	R6, 10d	
			DIV 	R7, R6 				; fica-se com as dezenas em R7 e as unidades em R6
			CMP 	R7, R0	
			BR.Z 	menor_que_10 			; se o nTurno < 10, nao damos print a 09 (por exemplo)
			MOV 	M[DISP_SEGM1], R7
			PUSH    R7
			CALL    escrever_digito
			BR      segundo_digito_turno
			

menor_que_10: 		INC     M[cursor]                       ; incrementamos o cursor manualmente para alinhar

segundo_digito_turno:   MOV 	M[DISP_SEGM0], R6
                        PUSH    R6
			CALL    escrever_digito
			PUSH    espaco9 			; identamos o texto
                        CALL    escrever_texto
			RET

;----------------------------------------------------------------
; MODULO: ATUALIZA_HIGHSCORE
; 	Input: M[turno]
; 	Output: M[high_score]
; 	Atualiza o high score caso a pontuacao do jogo seja menor que o high_score previo.
; 	O highscore e inicializado a 13 uma vez que e impossivel ganhar no 13º turno.
; 	Utiliza apenas R7 e e chamado no fim da rotina principal.

atualiza_highscore:	MOV 	R7, M[turno]			; pontuacao atual
			CMP 	R7, M[high_score]
			BR.NN 	fim_atualiza_highscore
			MOV 	M[high_score], R7
			CALL 	atualiza_lcd 			; se pontuacao < high score, atualizamos o LCD
fim_atualiza_highscore: RET

;----------------------------------------------------------------
; MODULO: ESCREVER_CERTA
; 	Input: M[codigo]
;	Output: Janela de Texto
;	Descricao: Escreve a sequencia correta na janela de texto. Utiliza os registos R5-R7. Nao e necessario
;	preservar os registos anteriores uma vez que este modulo decorre no fim do jogo, e portanto nao ha
;	maneira de "estragar" outras rotinas.

escrever_certa: 	MOV 	R7, M[codigo]
			MOV 	R6, 4				; para retirar o primeiro digito
			
loop_escrever_certa: 	CMP 	R6, R0 				; se ja rodou 4 vezes
			BR.Z 	fim_escrever_certa
			MOV 	R5, 111000000000b 		; contador
			AND 	R5, R7
			SHR 	R5, 9 				; para ocupar os bits menos significativos
			SHL 	R7, 3				; passamos ao proximo digito
			PUSH 	R5
			CALL 	escrever_digito
			DEC 	R6 				; reduzimos o contador
			BR 	loop_escrever_certa

fim_escrever_certa: 	PUSH 	nova_linha
			CALL 	escrever_texto
			RET 
      
;----------------------------------------------------------------
; ROTINA PRINCIPAL
; 	Descricao: Aqui decorre a sequencia logica principal do programa. Espera pelo input do jogador, calcula a
; 	jogada atual e se se perdeu por tempo ou por demasiadas tentativas falhadas.

inicio_jogo:		PUSH 	cabecalhoStr 			; escrevemos o cabecalho da tabela
			CALL	escrever_texto	
	
	
proxima_jogada: 	INC 	M[turno] 			; incrementamos o contador de jogadas
			MOV 	R7, M[turno]	
			CMP 	R7, 13				; verificamos se o jogador ja perdeu os 12 turnos
			JMP.Z 	derrota	
			CALL 	escrever_turno 			; escrevemos o numero da jogada
			MOV 	M[escolha], R0 			; limpa-se a jogada anterior

			MOV 	R7, FFFFh 			
			MOV 	M[LEDS], R7			; reacendemos as LEDS 
			MOV 	M[tempo_restante], R7	
			MOV 	R7, 5 				; (re)comecamos o temporizador
			MOV 	M[SET_TEMP], R7	
			MOV 	R7, 1				; comecamos o temporizador
			MOV 	M[START_TEMP], R7

			MOV 	R7, 1	
			MOV 	M[pode_jogar], R7 		; assinala que o jogador pode fazer a jogada
	
	
verificar_input:	CMP 	M[tempo_restante], R0 		; se o tempo esgotou
			JMP.Z 	derrota_tempo
			
			CMP     M[comecou], R0                  ; verificamos se e jogador pediu para reiniciar
                        JMP.NZ  novo_jogo
                        
                        CMP 	M[pode_jogar], R0		; se ja se escreveu os 4 digitos
			BR.Z	jogada 				; se sim, processamos a jogada
			
			BR	verificar_input 		; voltamos a verificar input
	
				
jogada:			MOV 	M[pode_jogar], R0 		; proibe-se ao jogador fazer jogadas
			CALL 	comparar  			; comparamos as sequencias 
			CALL	escrever_resultado 		; e escrevemos o resultado na janela de texto
			JMP 	proxima_jogada 			; passamos para a proxima jogada
	
derrota:		PUSH 	derrotaStr 			; escrevemos o texto de derrota
			CALL 	escrever_texto
			CALL 	escrever_certa	
			BR 	fim	

derrota_tempo: 		MOV 	M[pode_jogar], R0 		; uma vez que nao se completou a jogada
			PUSH 	derrota_tempoStr	
			CALL 	escrever_texto
			CALL 	escrever_certa	
			BR 	fim 				; acabou o jogo
	
vitoria:		PUSH 	vitoriaStr			; damos print ao resultado aqui para evitar complicaoes na logica do programa
			CALL 	escrever_texto			; escrevemos o texto de vitoria
			CALL 	atualiza_highscore
	
fim:			PUSH 	comecarStr 			; texto de restart
			CALL 	escrever_texto
			JMP 	idle 				; salta-se para o ciclo de espera de recomeco
			BR 	fim
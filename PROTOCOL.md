# PROTOCOLO

Seja "Novo cliente" um computador que acabou de entrar na rede,
"Host" o computador selecionado pelo leilão para ser o controlador de tudo,
e "Cliente" uma máquina que já está na rede há um tempo


### RCVE
Recebe o número primo a ser computado, e a seção a se calcular
Host:
	>> RCVE
	<< ANS RCVE <primo> <pte. inicial> <pte. final>

### LOAD
Checa o load da máquina: Quantos números ela precisa computar
Host:
	>> LOAD
	<< ANS LOAD <quantos números>

### CONN
Cita todos os computadores conectados na rede.
Cliente:
  >> CONN
Host:
  << ANS CONN <Lista de IPs>

Cliente:
  >> CONN
Outro cliente:
  << ANS CONN HOST <IP do HOST>

### SPLIT
Manda o cliente dividir seu trabalho e devolver a fração desejada pelo host.
  >> SPLIT 0.3 # Me dê 30% dos números que você tá trabalhando
  << ANS SPLIT <pte. inicial> <pte. final>

### END
Mostra final de cálculo para a máquina Host.
Cliente:
	>> END FALSE
	<< ANS END OK
Cliente:
	>> END PROOF <Número>
	<< ANS END OK

### TRN
Transfere liderança para outro computador. Todos os dados são transferidos
Host:
  >> TRN START
  << ANS TRN OK

#### CALC
Dentro do Transfer, fala o que já foi calculado

### PING
Executa um ping à outra máquina, pra saber se ela está viva.
Qualquer um:
  >> PING
  << ANS PING <URI do líder>

### CAP
Checa a capacidade computacional do computador no momento. Realiza um micro stress-test e o mais rápido vira o líder.

### ANS
Responde algum protocolo anterior.

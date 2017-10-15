# PROTOCOLO

Seja "Novo cliente" um computador que acabou de entrar na rede,
"Host" o computador selecionado pelo leilão para ser o controlador de tudo,
e "Cliente" uma máquina que já está na rede há um tempo

### HELLO
Indica nova conexão para o outro computador
Novo cliente:
  >> HELLO
  << ANS HELLO HI_THERE

### RCVE
Recebe o número primo a ser computado, e a seção a se calcular
Host:
	>> RCVE
	<< ANS RCVE <primo> <pte. inicial> <pte. final>

### LOAD
Checa o load da máquina: Quantos números ela precisa computar
Host:
	>> LOAD
	<< ANS LOAD <Quantos números>

### SOLVE
Host indica a cliente qual a solução
Host:
  >> SOLVE PRIME
  << ANS SOLVE CLOSE

Host:
  >> SOLVE <Divisor>
  << ANS SOLVE CLOSE

### WAIT
Host indica a cliente que não há mais LOAD para pegar, apenas esperar
Host:
  >> WAIT
  << ANS WAIT OK

### CLOSE
Pede para fechar a conexão com o servidor

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

### LDR
Indica para os outros computadores que o cliente é o novo lider.

Novo líder:
  >> LDR
  << ANS LDR OK

### TRN
Transfere liderança para outro computador. Todos os dados são transferidos
Host:
  >> TRN START
  << ANS TRN OK

#### NEXT
Dentro do transfer, avisa o próximo dado e se foi calculado ou não
Host:
  >> NEXT 10000000 TRUE

#### FINISH
Dentro do transfer, avisa o fim dos dados
Host:
  >> FINISH

### PING
Executa um ping à outra máquina, pra saber se ela está viva.
Qualquer um:
  >> PING
  << ANS PING <URI do líder>

### ANS
Responde algum protocolo anterior.

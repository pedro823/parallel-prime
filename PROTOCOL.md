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

### ANS
Responde algum protocolo anterior.

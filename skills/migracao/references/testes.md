# Estratégia de testes numa migração

O teste, aqui, tem um propósito diferente do usual. Ele não verifica se o código faz o que a spec pede — verifica se **o sistema novo faz o que o antigo fazia**. São coisas diferentes, e confundi-las é o que faz uma migração "passar nos testes" e quebrar em produção.

## Teste de caracterização

É o instrumento central. Registra:

> o que o sistema atual **realmente** faz

e não:

> o que gostaríamos que ele fizesse

A distinção é a razão de ele existir. O sistema antigo tem comportamentos que ninguém especificou e que alguém já usa: arredondamento particular, tolerância a entrada malformada, ordenação acidental, campo que vem vazio em vez de nulo. Se você escrever o teste a partir do comportamento *desejado*, ele passa nos dois sistemas e não detecta nada.

Como construir:

1. Escolha os fluxos críticos identificados no inventário.
2. Execute contra o sistema atual com entradas reais — incluindo as feias, sobretudo as feias.
3. **Grave a saída como esperada, sem julgá-la.** Se a saída parece errada, registre como está e anote a estranheza como decisão a tomar (`PRESERVAR` ou `ALTERAR`). Não corrija dentro do teste.
4. Rode contra o sistema novo. Divergência é ou defeito, ou mudança intencional que você aprovou — nunca "provavelmente tanto faz".

O teste de caracterização é descartável por natureza. Ele existe para atravessar a migração; depois do corte, o que sobrevive são os testes escritos a partir da spec do sistema novo. Não invista em elegância nele — invista em cobertura dos casos estranhos.

## As outras camadas, e o que cada uma cobre aqui

| Camada | O que ela pega numa migração |
|---|---|
| **Contrato** | quebra de compatibilidade com consumidor externo — o risco que você não controla |
| **Integração** | credencial, endereço, formato de payload no ambiente novo |
| **End-to-end** | o passo manual e o fluxo que atravessa componentes de gerações diferentes |
| **Performance** | a regressão que só aparece com volume real; o alvo raramente é mais rápido por acidente |
| **Unitário** | regra de negócio complexa isolada — cálculo, elegibilidade, precificação |

**Priorize contrato acima de unitário.** O consumidor externo é o que você não pode consertar com um deploy, e é onde a quebra custa mais caro.

## Comparação automatizada

Quando a estratégia inclui parallel run, o comparador é o artefato mais valioso do projeto — vale mais que qualquer suíte de testes, porque roda sobre tráfego real com toda a diversidade que ninguém consegue inventar.

Ao construí-lo, defina antes:

- **O que comparar** — a saída visível ao consumidor, não a estrutura interna.
- **O que normalizar antes de comparar** — timestamp de processamento, ID gerado, ordem de lista não ordenada. Sem normalização, tudo divergirá e você desligará o comparador.
- **Qual divergência é aceitável** — tolerância numérica explícita, com o motivo.
- **Como a divergência é registrada** — precisa incluir a entrada que a produziu, ou não é investigável.

Divergência que ninguém investiga é pior que comparador nenhum: cria a sensação de que há verificação onde não há.

## Dados de teste

Comportamento estranho vive nos dados de produção, não nos que você inventaria. Prefira uma cópia mascarada de produção a um seed sintético, principalmente para caracterização.

Mascaramento é obrigatório para dado pessoal, e precisa **preservar a forma** que o sistema testa: se você mascarar CPF gerando dígito verificador inválido, o sistema novo rejeita entradas que o antigo aceitava e você depura o mascaramento em vez da migração.

## O que precisa estar pronto em cada gate

- Antes de fixar a **estratégia**: você sabe se os testes atuais cobrem o comportamento crítico. Se não cobrem, a estratégia tem que compensar (parallel run) ou a primeira fase é construir caracterização.
- Antes de **cada corte de fase**: caracterização daquele escopo passando nos dois sistemas, contrato dos consumidores externos verificado, e a métrica da Fase 0 medida no novo.

---
name: migracao
description: Planejamento de migração de sistemas, arquiteturas, bancos e plataformas legadas — entender o sistema atual antes de propor o alvo, escolher a estratégia que reduz risco, tratar dados como migração separada, dividir em fases verificáveis com rollback concreto. Use quando a mudança altera fronteiras de comportamento, forma dos dados ou quem consome o sistema: reescrever ou substituir um sistema, trocar de linguagem, banco, cloud, plataforma ou modelo de arquitetura, aposentar um legado, planejar convivência entre sistema novo e antigo, ou levantar o que um sistema antigo faz antes de reconstruí-lo — inclusive quando o usuário descrever isso sem usar a palavra migração ("legado", "monolito para microsserviços", "on-premise para cloud", "portar para", "refazer em", "sair do X e ir pro Y"). NÃO use para atualização de versão de framework, runtime ou dependência — nem quando é troca de major com deprecations a resolver, desde que exista caminho de upgrade documentado —, troca de biblioteca atrás de uma única interface, ou reorganização de código sem mudança de dados nem de consumidores — nesses casos leia o changelog, faça a mudança e rode os testes.
model: opus
effort: high
---

# Planejamento de migração

O objetivo desta skill não é produzir documentos. É **reduzir incerteza**. Todo artefato que não diminui a chance de alguém descobrir um problema durante o corte é cerimônia — corte o artefato.

A regra que governa tudo aqui: **migração não é reescrever o sistema atual na tecnologia nova.** É transportar comportamento, dados e confiança de um lugar para outro sem quebrar quem depende disso. A tecnologia nova é o meio, não o objetivo.

Conduza como quem vai operar o sistema durante o corte, às duas da manhã, com o antigo já desligado.

## Precedência sobre o `sdd`

Um pedido de migração também casa com a skill `sdd`, e a ordem importa: **esta skill vem primeiro, e o `sdd` entra depois, uma vez por fase.** Se o `sdd` conduzir uma migração desde o início, a spec vai descrever o sistema alvo e nunca registrar o que não pode quebrar no atual — perdendo inventário, teste de caracterização e rollback justamente onde eles decidem o resultado.

## Quando não usar

Isto vale a pena quando a mudança altera **fronteiras de comportamento, forma dos dados, ou quem consome o sistema**. Quando não altera nenhuma das três, não é migração no sentido que exige planejamento — é trabalho de manutenção, e um plano de seis documentos para ele treina o usuário a ignorar o processo.

Não use para:

- Subir versão dentro de um major compatível (Django 4.2 → 5.0, Node 20 → 22). Leia o changelog do projeto, atualize, rode os testes.
- Trocar biblioteca atrás de uma única interface (`requests` → `httpx`, `moment` → `date-fns`).
- Upgrade de framework com caminho documentado pelo próprio framework e sem mudança de modelo de dados.
- Renomear, reorganizar pastas, extrair módulo dentro do mesmo processo.

**Se você consegue descrever a mudança inteira como "trocar A por B e rodar os testes", apenas faça, e diga que dispensou o fluxo.**

Nesse caso a resposta correta é **zero documento** — nem o documento único da escala intermediária descrita abaixo. Produzir um `migracao.md` como meio-termo para um upgrade de dependência é a forma mais comum de esta skill atrapalhar: parece diligência, entrega cerimônia.

### Escala intermediária

Entre "não é migração" e "programa de migração" existe um caso muito comum: **um componente só muda de lugar ou de tecnologia**, com fronteira já conhecida e consumidores identificados. Um endpoint que sai de um serviço para outro, uma tabela que muda de forma, um job que sai do cron para uma fila.

Nesse caso produza **um documento único** — `specs/<numero>-<slug>/migracao.md` — cobrindo inventário do componente, o antes/depois, dados, riscos, rollback e as fases. Não fatie em cinco arquivos o que cabe em três páginas.

O conjunto completo de artefatos se justifica quando a migração atravessa **múltiplos componentes ou domínios**, envolve **dados históricos com volume**, tem **consumidores externos** que você não controla, ou precisa de **convivência** entre antigo e novo por mais de um deploy.

## O fluxo

```
Fase 0  Diagnóstico   → por que migramos, e qual o resultado mensurável
Fase 1  Inventário    → o que existe hoje, de fato          ── GATE
Fase 2  Alvo          → arquitetura destino e o mapa atual→alvo
Fase 3  Estratégia    → como migrar, dados, testes, rollback ── GATE
Fase 4  Fases         → incrementos verificáveis, em ordem
Fase 5  Execução      → cada fase entra no fluxo `sdd`
Fase 6  Desativação   → aposentar o legado
```

A separação existe porque **cada fase decide uma classe de coisa, e misturá-las faz decisão prematura se disfarçar de fato levantado**. O erro clássico é escrever no inventário "o serviço de pedidos vai virar uma Lambda" — isso é alvo, não inventário. O inventário diz: *"o serviço de pedidos grava direto na tabela PEDIDO e é chamado por dois consumidores, um deles fora do nosso controle"*.

### Os dois gates

Ao fim do **inventário** e da **estratégia**, mostre o resultado e espere confirmação. São os dois pontos onde o usuário tem informação que você não tem: ele sabe quais integrações existem que não estão no código, e sabe qual risco a empresa aceita correr.

Passados os gates, fases e execução correm até o fim. Interrompa apenas em bloqueio real.

## Fase 0 — Por que estamos migrando

Não aceite "migrar para X" como objetivo. **"Migrar para X" é uma solução; o objetivo é o que dói hoje.** Sem isso você não tem critério nenhum para decidir o que preservar, o que melhorar e o que jogar fora — e sem critério, migração vira reescrita com data indefinida.

Descubra o motivo real — plataforma sem suporte, vulnerabilidade, **custo de infraestrutura ou de licença**, performance, escalabilidade, escassez de gente que saiba manter, compliance, necessidade de recurso que a plataforma atual não permite — e transforme em resultado mensurável:

```
Objetivo:  melhorar performance
Meta:      p95 das requisições de consulta abaixo de 300 ms
```

Se o usuário não sabe dizer o motivo mensurável, **isso é a primeira lacuna do plano** e vale registrar como `DECISÃO PENDENTE`. Sem meta, ninguém consegue afirmar no fim que a migração deu certo.

## Fase 1 — Inventário do sistema atual

Construa um modelo do que existe **antes** de propor qualquer coisa. Este é o trabalho mais valioso da skill e o mais tentador de pular, porque não produz nada visível.

O que investigar e como registrar está em `references/inventario.md`. O essencial:

**Nunca invente regra de negócio.** Quando não souber, escreva `DESCONHECIDO` e registre uma ação para descobrir. Um inventário com dez `DESCONHECIDO` honestos é infinitamente mais útil que um completo e adivinhado — porque os dez viram tarefas de investigação, e os adivinhados viram bugs no corte.

**Separe fato, inferência e hipótese**, marcando cada afirmação:

```
FATO:        a aplicação grava pedidos direto na tabela PEDIDO
INFERÊNCIA:  o banco é usado como integração entre módulos
HIPÓTESE:    outros sistemas leem essa tabela diretamente
```

A razão de marcar é que hipótese não confirmada tem o hábito de virar requisito ao ser copiada para o documento seguinte. Depois de copiada duas vezes, ninguém lembra que era um chute.

**Classifique cada comportamento e componente** com `PRESERVAR` / `MELHORAR` / `ALTERAR` / `SUBSTITUIR` / `REMOVER` / `DESCONHECIDO`, cada um com justificativa. Não presuma que tudo que existe deve ser mantido — nem que comportamento ruim pode simplesmente desaparecer. Alguém depende dele.

## Fase 2 — Arquitetura alvo e o mapa

Documente a arquitetura alvo com o mesmo rigor do inventário, e então produza o mapa componente a componente: **atual → destino → estratégia → dependências → risco**. É o mapa que revela o que ninguém tinha notado: um componente sem destino, ou três componentes convergindo para um só.

### A pergunta que economiza mais retrabalho

Para cada mudança que aparecer no alvo e não existir no atual:

> **Essa mudança é necessária para a migração?**

Migração é o momento em que todo mundo quer aproveitar para corrigir o que incomoda: trocar o banco, refazer a UI, revisar aquela regra estranha. **Cada variável que muda ao mesmo tempo multiplica a dificuldade de descobrir a origem do problema quando algo divergir** — e algo vai divergir. Se a mudança não é necessária para a migração, separe como evolução posterior e registre a decisão.

Isso vale especialmente para regra de negócio. Migrar e corrigir a regra ao mesmo tempo destrói sua única ferramenta de validação: comparar antigo e novo.

## Fase 3 — Estratégia

Três estratégias independentes, e o erro mais caro é tratá-las como uma:

1. **Estratégia de migração da aplicação** — big bang, incremental, strangler fig, dual/parallel run, branch by abstraction, por domínio. Critérios de escolha e quando cada uma se aplica: `references/estrategias.md`. Escolha uma e **explique por que ela é adequada a este caso** — a justificativa é o que permite reavaliar depois sem refazer a análise.

2. **Estratégia de dados** — extração, transformação, carga, validação, reconciliação. Está em `references/dados.md`. Trate como migração própria, com plano e rollback próprios: a aplicação você redeploya, o dado corrompido você não. E defina desde já **como provar que os dados chegaram certos** — contagem não é prova.

   Confirme que as três são **de fato** independentes antes de planejá-las em separado. Quando a regra de negócio vive dentro do banco — procedure, trigger, view com regra —, migrar o dado é também reescrever aplicação, e fases separadas para as duas descobrem isso no meio da execução. Ver `references/inventario.md`.

3. **Estratégia de testes** — o instrumento central é o **teste de caracterização**: registrar *o que o sistema atual realmente faz*, não o que gostaríamos que fizesse. É ele que permite comparar antigo e novo. Detalhe em `references/testes.md`.

Nesta fase também entram **riscos, rollback e observabilidade** — `references/riscos-rollback.md`. Dois pontos que não são negociáveis:

- **Rollback precisa de mecanismo concreto.** "Faremos rollback se necessário" não é plano. Cada fase responde: o que pode dar errado, como detectamos, até quando podemos voltar, como voltamos, e **o que acontece com os dados escritos no novo sistema** — essa última é a que costuma faltar e a que impede o rollback na prática.
- **Defina os sinais** que determinam `CONTINUAR`, `PAUSAR` e `ROLLBACK`, com limiar numérico. Definidos durante o incidente, viram opinião.

## Fase 4 — Fases da migração

"Fase 1, Fase 2, Fase 3" não é plano. Cada fase precisa produzir um **incremento verificável** e trazer objetivo, escopo, pré-requisitos, validação, riscos, rollback e critérios de saída. Template em `references/templates.md`.

Uma fase que não pode ser validada isoladamente e não pode voltar atrás isoladamente está grande demais — divida.

## Fase 5 — Execução: handoff para o `sdd`

Esta skill planeja a migração; ela **não implementa**. Cada fase que envolve escrever código entra no fluxo da skill `sdd` como uma feature própria: o plano de migração é o pai, e cada fase gera sua `specs/<numero>-<slug>/` com `spec.md`, `plan.md`, `tasks.md`.

A divisão de responsabilidade importa porque os artefatos vivem no mesmo lugar: **esta skill é dona dos arquivos `migracao.md`, `inventario.md`, `alvo.md`, `estrategia.md` e `fases.md`; a `sdd` é dona de `spec.md`, `plan.md` e `tasks.md`.** Ao abrir a spec de uma fase, referencie o `fases.md` de origem — sem esse link, seis meses depois ninguém sabe que aquelas cinco specs eram uma migração.

Ao fim de cada fase implementada, a `sdd` já cobre code-review, security-review, CHANGELOG e atualização de `docs/`. Não duplique isso aqui.

## Fase 6 — Desativação do legado

A migração não termina quando o novo funciona; termina quando o **antigo pode ser desligado com segurança**. Sistema legado que continua ligado "por garantia" continua recebendo escrita por algum caminho que ninguém mapeou, e aí você tem dois sistemas divergindo em silêncio.

Definition of Done em `references/riscos-rollback.md`.

## Vocabulário de incerteza

Informação que falta é resultado, não falha. Não a esconda para o documento parecer completo — marque inline, no ponto exato onde a dúvida afeta a decisão:

| Marca | Quando usar |
|---|---|
| `BLOQUEIO` | a falta desta informação impede decidir; não dá para seguir |
| `DECISÃO PENDENTE` | há alternativas e a escolha é humana, não sua |
| `RISCO` | há incerteza, mas o planejamento continua |
| `HIPÓTESE` | suposição em uso temporário, precisa confirmação |
| `DESCONHECIDO` | comportamento do sistema atual que não foi possível determinar |

Cada `BLOQUEIO` e cada `DESCONHECIDO` gera uma **ação com responsável** para resolvê-lo. Lacuna registrada sem ação é lacuna esquecida.

## Revisão adversarial antes de fechar

Antes de entregar o plano, ataque-o. Estas são as perguntas que mais frequentemente revelam o que faltou:

- Existe consumidor externo que não está no inventário? Alguém lendo o banco direto?
- Existe integração que só existe em produção — cron, planilha, script de alguém?
- Existe dado que não conseguimos migrar? O que fazemos com ele?
- Conseguimos **detectar** divergência entre antigo e novo, ou só descobriríamos por reclamação?
- A janela de rollback é real, ou expira no primeiro registro escrito no sistema novo?
- Alguma fase depende de decisão que ainda não foi tomada?
- Alguma fase é grande demais para validar isoladamente?
- Estamos aproveitando a migração para mudar coisa que não deveria mudar agora?
- O plano depende do conhecimento de uma única pessoa sobre o legado?

O que essa revisão encontrar entra no plano como risco ou ação — não como parágrafo tranquilizador.

## Estrutura de arquivos

```
specs/
  <numero>-<slug>/
    migracao.md      # escala intermediária: tudo num documento
    ── ou, na escala completa: ──
    inventario.md    # sistema atual, com FATO/INFERÊNCIA/HIPÓTESE e classificação
    alvo.md          # arquitetura destino + mapa atual→alvo
    estrategia.md    # aplicação, dados, testes, riscos, rollback, observabilidade
    fases.md         # fases com validação, rollback e critérios de saída
```

Cada fase implementada abre seu próprio `specs/<numero>-<slug>/` pelo fluxo `sdd`, apontando de volta para `fases.md`.

## Sinais de que o plano está ruim

- O inventário não tem nenhum `DESCONHECIDO` num sistema que ninguém do time escreveu — então foi adivinhado.
- A estratégia de dados é um parágrafo dentro da estratégia da aplicação.
- Rollback descrito como intenção, não como mecanismo.
- Alguma fase entrega "a migração do módulo X" sem dizer como se verifica que ficou equivalente.
- O alvo contém melhorias que ninguém pediu e que não são necessárias para migrar.
- Nenhuma meta numérica — então não haverá como declarar que terminou.
- Poderia ter sido escrito sem olhar o sistema atual.

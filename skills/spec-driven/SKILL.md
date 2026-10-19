---
name: spec-driven
description: Spec-Driven Development — a especificação é o artefato durável e o código é a saída dela. Fluxo em fases (mapear → specify → plan → tasks → implement → review) com artefatos markdown versionados, documentação viva do repositório em docs/ e CHANGELOG.md, e fechamento obrigatório com code-review + security-review. Use sempre que chegar um pedido de desenvolvimento, correção, criação ou alteração de funcionalidade que não seja trivial; quando o usuário pedir para especificar uma feature, escrever ou alterar uma spec, planejar antes de codar, quebrar escopo em tarefas; quando relatar um bug ou comportamento errado em algo já entregue; quando mencionar SDD, spec-driven ou "seguir a spec"; quando existir um documento de proposta/escopo ou uma análise de mercado (analise-mercado) do qual derivar especificações executáveis; e quando um pedido de mudança exigir alterar uma spec já existente antes de tocar no código. Aceita argumento de fase (`/spec-driven <pedido>`, `/spec-driven fix <sintoma>`, `/spec-driven review [feature]`).
model: opus
effort: high
---

# Spec-Driven Development

A premissa do SDD é que **a especificação é o artefato durável e o código é a saída dela**. Não o contrário. Quando o código é a fonte da verdade, a intenção original vira arqueologia: você lê um `if` e não sabe se aquilo é regra de negócio, correção de bug ou acidente.

Conduza isto como um engenheiro de software responsável pelo sistema depois de pronto — não como alguém preenchendo formulários. O valor está nas decisões registradas com a justificativa junto, não na existência dos arquivos.

## Precedência: o SDD do repositório vence

Esta skill é global e serve de **padrão para qualquer repositório**. Quando o repositório já tem o próprio SDD, ele prevalece e esta skill vira só referência de método:

- skills de projeto como `sdd`, `sdd-*`, `/specify`, `/plan`, `/tasks`, `/implement` em `.claude/skills/` ou `.claude/commands/`;
- `specs/constitution.md` ou `docs/specs/constitution.md`;
- uma seção de SDD/fluxo de especificação no `CLAUDE.md` do repositório.

Nesses casos siga o fluxo local — numeração, templates, quem escreve a spec, regras de commit e push — e use daqui apenas o que ele não cobre. A razão: o fluxo local carrega decisões do time (contratos, gates, ordem de deploy) que uma skill genérica não conhece, e dois fluxos rodando ao mesmo tempo produzem artefatos em dois formatos. O que **não** se negocia em nenhum caso é o fechamento da Fase 5: code-review e security-review sobre o diff.

## Roteamento pelo argumento

| Invocação | Caminho |
|---|---|
| `/spec-driven <pedido>` | fluxo completo, da Fase 0 à 5 |
| `/spec-driven fix <sintoma>` ou relato de bug/comportamento errado | correção dentro do SDD — leia `references/correcao.md` |
| `/spec-driven review [feature]` | só a Fase 5 sobre o diff atual — leia `references/review.md` |
| ideia ainda não validada ("vale a pena construir X?") | skill `analise-mercado` primeiro; o relatório dela vira o documento de origem da Fase 1 |

## Esta skill é o método, não a ferramenta

Aqui o fluxo é conduzido à mão, com markdown versionado — sem depender de ferramenta nenhuma. Se o pedido for sobre a **ferramenta GitHub Spec Kit** (a CLI `specify`, `specify init`, comandos `/speckit.*`, a pasta `.specify/`), use a skill `spec-kit`. O desempate mais barato: se existe `.specify/` na raiz, o repositório usa a ferramenta.

## Quando o pedido é uma migração

Se o pedido é migrar, modernizar ou substituir um sistema existente — trocar de framework, banco, plataforma, arquitetura, ou aposentar um legado —, **use a skill `migracao` primeiro**. Ela levanta o sistema atual, escolhe a estratégia de corte, trata os dados como migração própria e define rollback; depois disso, **cada fase da migração volta para cá** como uma feature própria com sua `spec.md`/`plan.md`/`tasks.md`.

O motivo da precedência: uma spec escrita direto sobre uma migração descreve o sistema alvo e não registra o que não pode quebrar no atual — e é justamente esse levantamento que impede a migração de virar reescrita.

## Quando não usar

Isso só vale a pena quando há ambiguidade real a resolver. Correção de typo, ajuste de CSS, renomear variável, endpoint que copia outro endpoint — nada disso precisa de spec. Escrever uma spec de três seções para um trabalho de dez minutos é cerimônia, e cerimônia treina o usuário a ignorar o processo.

**Se a implementação é óbvia para quem lê o pedido, apenas implemente e diga que dispensou o fluxo.** Não gere spec, não mapeie o repositório, não escreva no CHANGELOG.

Duas exceções a essa dispensa:
- **Invocação explícita** (`/spec-driven ...`) — o usuário pediu o fluxo; rode-o, em versão enxuta se o escopo for pequeno (uma spec curta, uma tarefa).
- **Correção de algo que uma spec descreve** — se existe spec cobrindo o comportamento, o conserto passa por ela, por menor que seja (`references/correcao.md`). Corrigir o código sem tocar a spec faz a spec mentir.

E mesmo quando o fluxo é dispensado, **código escrito sai revisado**: rode code-review e security-review sobre o que mudou antes de entregar.

O sinal de que SDD serve: você conseguiria implementar de duas maneiras defensáveis e diferentes, e a escolha errada custa retrabalho.

## O fluxo

```
Fase 0  Mapear      → entender o repositório e documentá-lo
Fase 1  Specify     → o quê e por quê          ── GATE: confirmar com o usuário
Fase 2  Plan        → como, em arquitetura     ── GATE: confirmar com o usuário
Fase 3  Tasks       → em que ordem
Fase 4  Implement   → o código, todas as tarefas de uma vez
Fase 5  Review      → code-review + security-review + CHANGELOG
```

A separação entre as fases existe por um motivo específico: **cada fase decide uma classe de coisa, e misturá-las faz decisões prematuras se disfarçarem de requisito.**

| Fase | Responde | Proibido nesta fase |
|---|---|---|
| **Specify** | O quê e por quê | Nomes de tabela, framework, endpoint, biblioteca |
| **Plan** | Como, em termos de arquitetura | Ordem de execução, estimativas |
| **Tasks** | Em que ordem, em que unidades | Escrever o código |
| **Implement** | O código | Redefinir escopo silenciosamente |

O erro clássico é escrever na spec "criar tabela `documento_versao` com coluna `hash_sha256`". Isso é plano, não spec. A spec diz: *"cada envio preserva o anterior e permite provar que o arquivo guardado é o que o cliente enviou"*. A diferença importa porque a spec sobrevive a uma troca de banco de dados; a DDL não.

### Os dois gates

Ao fim de **specify** e de **plan**, mostre o resultado e espere confirmação. É justamente aí que o custo de corrigir o rumo é baixo — depois de implementado, a mesma correção custa o retrabalho inteiro.

Passados os dois gates, **tasks, implement e review correm até o fim sem parar.** Interrompa apenas em bloqueio real: uma pendência cuja resposta muda o que se constrói, uma credencial que falta, uma decisão que é do usuário e não sua. Dúvida que você consegue resolver escolhendo o padrão defensável não é bloqueio — decida, registre a decisão e siga.

Se o usuário pedir explicitamente o fluxo inteiro de uma vez, os gates caem; destaque no fim as decisões que você tomou sozinho.

**Implementar em sessão limpa.** Aprovado o plano, o contexto que produziu spec e plano já não é necessário: tudo o que importa está nos arquivos. Antes de o usuário rodar `/clear`, execute a skill `checkpoint-contexto`, que prova que nenhuma decisão ou esclarecimento ficou só na conversa. Depois do `/clear`, a implementação recomeça lendo `spec.md`, `plan.md` e `tasks.md`.

## Fase 0 — Mapear o repositório

Antes de especificar, você precisa saber o que já existe. Uma spec escrita às cegas contradiz convenções do projeto e propõe reconstruir o que já está lá.

**Esta fase só roda quando o mapeamento não existe ou não está válido.** Comece sempre pela validação, que é barata: leia `docs/indice.md` e `CLAUDE.md`.

- **Índice existe e confere** — não mapeie nada. Leia os documentos que o pedido toca e vá para specify. Este é o caso normal e deve ser o mais rápido.
- **Índice não existe** — mapeamento completo, produzindo `docs/` e `CLAUDE.md`.
- **Índice existe mas está defasado** — re-mapeie **apenas as áreas divergentes**, não o repositório inteiro, e diga ao usuário o que estava desatualizado.

A validação é uma verificação de sanidade sobre o índice, não uma auditoria: os documentos listados existem? o estado registrado é anterior às últimas entradas do CHANGELOG? a stack descrita ainda bate com os manifestos? Se nada saltar aos olhos, considere válido e siga. Re-varrer um repositório já mapeado por excesso de zelo consome justamente o contexto que deveria ir para o problema do usuário.

Os critérios de validação, o que investigar quando o mapeamento for necessário, quais documentos gerar e como mantê-los: leia `references/mapeamento.md`.

A regra que mais importa e que se perde fácil: **gere documento apenas para componente que existe no repositório.** Um repo sem CSS não recebe `design-system.md`. A taxonomia em `mapeamento.md` é um catálogo de candidatos, não um checklist a cumprir — doze arquivos vazios de conteúdo real são pior que três densos.

## Fase 1 — Specify

Produz `specs/<numero>-<slug>/spec.md`. Escreva para quem entende o negócio e não lê código. O template está em `references/templates.md`.

Conteúdo:
- **Problema** — o que dói hoje, concretamente. Se você não consegue descrever a dor sem citar a solução, ainda não entendeu o problema.
- **Usuários e o que cada um pode fazer** — por perfil, quando houver perfis.
- **Comportamento esperado** — em cenários, não em campos. "Quando o cliente envia um arquivo num item já preenchido, o anterior continua acessível e o novo vira a versão corrente."
- **Requisitos e critérios de aceitação** — requisitos numerados `RF-01…`, cada critério `CA-01 (RF-01)` ligado ao requisito que prova, no formato *dado / quando / então*. Cada CA respondível com sim ou não olhando o sistema pronto. Os IDs são o que permite rastrear requisito → tarefa → teste, e usar os CA como régua na revisão.
- **Fora do escopo** — explícito. É a seção que mais evita retrabalho.
- **Pendências** — perguntas cuja resposta muda o que se constrói.

Sobre as pendências: **marque-as com `[PENDENTE: pergunta]` inline, no ponto exato onde a dúvida afeta o comportamento.** Não as esconda numa lista no rodapé. E não invente a resposta para deixar o documento bonito — uma spec com três pendências honestas é infinitamente mais útil que uma spec completa e adivinhada. Quando a pendência bloqueia tudo, pergunte antes de seguir; quando bloqueia só uma parte, especifique o resto e siga.

Se existir um documento de origem (proposta comercial, ata, documento de escopo), **extraia dele em vez de reescrever por cima**: ele contém as decisões já negociadas com o cliente, e contradizê-las silenciosamente cria um conflito que só aparece na homologação. Onde o documento for omisso, marque como pendência.

## Fase 2 — Plan

Produz `plan.md` no mesmo diretório. Aqui entram stack, modelo de dados, contratos de API e as decisões de arquitetura com **a justificativa junto** — o motivo é o que permite reavaliar a decisão depois sem refazer a análise inteira.

Inclua sempre uma seção de **invariantes**: as afirmações que devem valer em qualquer estado do sistema, independentemente do caminho de código. São elas que viram os testes mais valiosos e os pontos de revisão mais duros. Exemplo: "nenhum caminho de código faz UPDATE ou DELETE na tabela de auditoria".

Inclua uma seção de **reuso**: o que já existe no repositório e será aproveitado, com caminho de arquivo. O maior risco de um fluxo spec-driven é reescrever o que já está lá — a spec descreve a capacidade em abstrato e a implementação nasce do zero sem que ninguém tenha procurado. Seção vazia significa "procurei e não achei", então diga onde procurou.

Inclua também **riscos**: o que pode dar errado nesta mudança especificamente — regressão provável, dado que pode vazar, caminho que pode quebrar sob concorrência. É o que a fase de review vai procurar depois.

Se o repositório tem `CLAUDE.md` ou `docs/` com convenções e invariantes, o plano **herda** deles em vez de repeti-los — cite e siga. Se o plano precisar contrariar uma convenção existente, diga isso explicitamente e justifique; convenção quebrada em silêncio é defeito.

## Fase 3 — Tasks

Produz `tasks.md`: lista ordenada, cada item pequeno o bastante para ser verificável isoladamente, com dependências explícitas e o critério de aceitação da spec que ele satisfaz. Marque o que pode correr em paralelo.

A ordem certa é a que **mantém o sistema funcionando entre as tarefas**, não a que agrupa arquivos parecidos.

Cada tarefa leva:
- **Verificar** — um comando real ou uma observação concreta (`pytest tests/x.py -k caso` → verde). Nunca "rodar os testes" ou "conferir se funciona". Tarefa sem verificação possível está grande demais ou não deveria existir sozinha.
- **Escreve dados?** — `sim` quando a verificação grava em banco compartilhado, chama integração externa, envia notificação ou toca ambiente real. Essas param no gate da Fase 4.

Feche com a tabela **RF → tarefas**. Todo RF precisa aparecer em pelo menos uma tarefa; se algum ficar órfão, **avise em vez de inventar uma tarefa para tapar** — RF órfão quase sempre é algo que a spec pediu e o plano não resolveu, e isso volta uma fase.

## Fase 4 — Implement

Execute as tarefas na ordem, atualizando o estado em `tasks.md` conforme avança. Vá até o fim sem pedir confirmação intermediária — o usuário já aprovou a spec e o plano, e parar a cada tarefa desperdiça a aprovação que ele deu.

Três regras de execução:
- **Marque `[x]` só depois de verificar** — nunca ao começar. Tarefa marcada cuja verificação não rodou some do radar e é pior que tarefa pendente.
- **Gate de escrita de dados** — antes de qualquer verificação com `Escreve dados?: sim`, pare e diga ao usuário qual tarefa, qual comando e o que será alterado. Só siga com confirmação. É interrupção de segurança, não de fluxo.
- **Falha isolada não aborta o lote** — se uma tarefa trava por motivo local a ela, marque `[!]` com a razão e siga para as que não dependem dela. Relate todas as bloqueadas no fim.

Quando a implementação revelar que a spec estava errada — e vai revelar, é o resultado mais valioso do processo —, **pare e atualize a spec antes de continuar codando**. Uma spec que diverge do código entregue é pior que nenhuma spec, porque a próxima pessoa vai confiar nela. Registre o que mudou e por quê, e conte ao usuário no fim.

## Fase 5 — Review e registro

Terminada a implementação, feche o ciclo **na mesma execução** — não termine sugerindo que o usuário rode o review depois. O portão só funciona se acontecer sempre.

1. **Invoque a skill `code-review`** sobre o diff da feature.
2. **Invoque a skill `security-review`** sobre o mesmo diff — **sempre**, mesmo quando a mudança parece inócua. A triagem de segurança é larga e barata justamente para não depender do palpite de que "isto é só um ajuste de tela".

Passe para as duas o **escopo explícito**: a feature, a base do diff e a lista de arquivos criados ou alterados. Sem isso elas revisam o repositório inteiro e devolvem dívidas antigas que não ajudam a decidir se *esta* mudança pode subir. Onde não há git, a lista que você manteve é a única fonte.

Trate os achados como trabalho seu — triagem (corrigir agora / tarefa nova / encaminhar para correção de outra spec / descartar), reverificação de cada correção e checagem de premissa duplicada nos documentos estão em `references/review.md`. Leia antes de triar.

3. **Atualize `CHANGELOG.md`** na raiz. Ele é o histórico do sistema — e onde não há git, é o *único* histórico. O formato está em `references/templates.md`.

4. **Atualize os documentos em `docs/`** que a mudança tornou desatualizados. Documentação que envelhece em silêncio é pior que ausente, porque induz ao erro.

## Alterar uma spec existente

Este é o caminho central do SDD e o mais fácil de pular sob pressão: **quando o pedido muda algo que já foi especificado, a mudança começa na spec, não no código.**

1. Localize a spec correspondente em `specs/`. Se o pedido atravessa várias, trate todas.
2. Altere a spec: ajuste o comportamento, os critérios de aceitação, o fora do escopo. Registre no rodapé o que mudou e por quê — a spec anterior explicava uma decisão, e apagar a razão dela apaga o aprendizado.
3. Re-derive **apenas o que foi afetado** em `plan.md` e `tasks.md`. Reescrever o plano inteiro por causa de um critério novo descarta decisões que continuam válidas.
4. Passe o gate de confirmação da spec alterada, depois implemente e siga para o review.

Se não existir spec para o que o pedido muda, e a mudança for grande o bastante para merecer uma, escreva a spec do estado atual junto com a alteração — assim o próximo pedido já encontra terreno documentado.

Quando a mudança é **correção de defeito** (algo entregue se comporta errado), o caminho tem um passo antes: achar a causa raiz sem editar código, e só então decidir qual spec passa a descrever o comportamento correto. O roteiro completo está em `references/correcao.md`.

## Estrutura de arquivos

```
CLAUDE.md              # convenções, stack e invariantes — carrega em toda sessão
CHANGELOG.md           # histórico de todas as alterações
docs/                  # documentação viva por componente (ver references/mapeamento.md)
specs/
  <numero>-<slug>/
    spec.md            # o quê e por quê
    plan.md            # como, com invariantes e riscos
    tasks.md           # em que ordem, com estado
```

Um diretório por feature ou módulo, numerado para preservar a ordem cronológica das decisões.

## Sinais de que a spec está ruim

- Cita tecnologia — é plano disfarçado.
- Critérios de aceitação que não dá para responder com sim ou não.
- Nenhuma pendência marcada num domínio que você não conhece a fundo — significa que você adivinhou.
- Seção "fora do escopo" vazia.
- Descreve telas em vez de comportamento. Layout é design, não especificação.
- Poderia ter sido escrita sem ler o repositório — então provavelmente foi, e vai contradizer o que já existe.

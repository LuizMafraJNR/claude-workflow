# CLAUDE.md global — distribuição de modelos

Vale para toda sessão nesta máquina. **O CLAUDE.md do projeto prevalece** sobre este arquivo
quando os dois falam do mesmo assunto (skills obrigatórias, revisores, TDD, regra de push).

## Papéis

| Papel | Modelo · effort | Faz | Não faz |
|---|---|---|---|
| Sessão principal | Sonnet · high (medium no laço de implementação) | planeja, decide, integra, revisa e verifica o resultado | trabalho braçal que um subagente faz |
| Advisor | Opus (`advisor`) | revisa a sessão inteira e aconselha | nunca escreve código |
| `worker` | Sonnet · medium · `maxTurns: 80` | implementa **uma tarefa** de `tasks.md`: edita e roda testes | decide escopo ou arquitetura; feature inteira |
| `explorer` | Haiku · medium | lê código, localiza símbolo, mapeia estrutura (read-only) | edita qualquer coisa |
| `researcher` | Haiku · medium | consulta docs, specs e web | edita qualquer coisa |

Lema: **pense em high, execute em medium, mantenha o Opus de plantão.** Ideação, spec, plano,
revisão e depuração ficam em `high` (é onde a qualidade se decide); o laço de implementação
sob uma spec e um plano prontos roda em `medium`, com o TDD como rede de segurança.

## Quando chamar o advisor (Opus)

- **antes de um plano** — antes de escrever código ou de se comprometer com uma interpretação;
- **erro que se repete** — a mesma falha duas vezes, ou a abordagem não converge;
- **antes de declarar pronto** — com a entrega já durável (arquivo salvo, commit feito).

Fora disso, fica quieto: tarefa rotineira e reativa não consome Opus.

O advisor recebe a conversa **inteira** a cada chamada, então o custo dele é o tamanho do
contexto. Por isso: chame **cedo** (contexto ainda pequeno); no fim, **uma vez por feature**,
não por tarefa; e, se a sessão já passa de ~300 mil tokens, compacte antes de chamá-lo.

## Orçamento de contexto e custo

Cada chamada do modelo relê o contexto inteiro. Numa sessão de 400 mil tokens, 100 chamadas
leem 40 milhões de tokens. O custo cresce com o **tamanho do contexto × número de chamadas**,
e é aí que o limite semanal vai embora. Economizar é cortar desperdício, **nunca** etapa de
verificação.

**Cortar** (não afeta a qualidade):

- **Uma feature por sessão.** Terminou (commit + push), `/clear`. A memória durável é a spec,
  `tasks.md`, o diário e as notas do projeto — não a conversa. `/compact` no fim de uma
  tarefa, nunca no meio; o `autoCompactWindow` do `settings.json` é só o freio de segurança.
- **Delegar para manter a sessão principal pequena.** Subagente começa com ~20 mil tokens e
  devolve só a conclusão. A leitura pesada (varrer código, logs de teste, docs) vai para ele.
- **Worker com escopo fechado:** uma tarefa de `tasks.md`, contrato no prompt, `maxTurns`.
  O custo está nos workers longos (numa medição de uma semana, 1 em cada 5 passou de 100 chamadas): se uma tarefa não
  cabe em ~60 chamadas, divida a tarefa, não despache de novo.
- **Saída longa filtrada:** log de teste e build entram no contexto só como falhas + resumo.
- **Opus na sessão principal** (`/model opus`) só no **início** da sessão e só para: desenho
  de arquitetura, incidente em produção, defeito de concorrência ou transação, migração de
  banco de alto risco. Trocar no meio quebra o cache de prompt. Rotina é Sonnet.

**Nunca cortar** (é onde mora a qualidade): spec e plano antes do código, TDD, verificação
rodada de verdade, `code-review` + `security-review` ao fim de mudança de código, advisor
antes do plano e antes de declarar pronto, e os revisores que o projeto exigir.

## Como cada subagente funciona (memória e disparo)

- **Contexto isolado.** O subagente não vê a conversa. Ele começa com: o corpo do seu `.md`
  como system prompt, o CLAUDE.md (global + projeto), o snapshot do git e **o prompt de
  delegação** — que é a única entrada de tarefa dele. Skills só se listadas em `skills:`.
  Se o prompt não disser, ele não sabe: arquivos, escopo, regra e verificação vão escritos.
- **Só a conclusão volta.** A mensagem final do subagente é o que entra na sessão principal;
  o que ele leu e tentou fica fora. É isso que poupa contexto.
- **Sem memória entre invocações.** Cada chamada é uma instância nova. Para continuar a
  mesma, use `SendMessage` (retoma com o histórico completo, e o contexto antigo volta a
  custar). O campo `memory:` do frontmatter dá um diretório persistente, mas não usamos.
- **Disparo:** o Claude escolhe pelo campo `description` do agente ou pelo nome citado no
  prompt; em segundo plano ou em paralelo (várias chamadas na mesma mensagem).
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` (no `settings.json`) impede subagente de criar
  subagente.

## Quando delegar

- Busca ampla no código (muitos arquivos, convenções, "onde está X") → `explorer`.
  Use `explorer` no lugar do `Explore` built-in, para a busca rodar em Haiku.
- Documentação, spec externa, API de terceiro → `researcher`.
- Edição mecânica ou **uma tarefa** de implementação já especificada → `worker`, com
  contrato explícito no prompt: arquivos, o que mudar, como verificar. Nunca a feature
  inteira num worker só.
- Fato pontual cujo arquivo já é conhecido → faça direto; delegar custa mais que ler.
  Mudança de poucas linhas em arquivo que a sessão principal já leu também é direto.
- Tarefas independentes → dispare os subagentes **na mesma mensagem**, em paralelo.

## Regras de paralelismo e retorno

- Dois `worker` em paralelo **só em arquivos disjuntos**, ou com `isolation: "worktree"`.
  Caso contrário um sobrescreve o outro.
- O resultado de subagente volta para a sessão principal, que **revisa e verifica** (diff,
  testes) antes de seguir. Relatório de subagente não é prova de que funcionou.
- Subagente não re-delega; quem orquestra é sempre a sessão principal.

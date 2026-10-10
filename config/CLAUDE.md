# CLAUDE.md global — distribuição de modelos

Vale para toda sessão nesta máquina. **O CLAUDE.md do projeto prevalece** sobre este arquivo
quando os dois falam do mesmo assunto (skills obrigatórias, revisores, TDD, regra de push).

## Papéis

| Papel | Modelo · effort | Faz | Não faz |
|---|---|---|---|
| Sessão principal | Sonnet · high | planeja, decide, integra, revisa e verifica o resultado | trabalho braçal que um subagente faz |
| Advisor | Opus (`advisor`) | revisa a sessão inteira e aconselha | nunca escreve código |
| `worker` | Sonnet · medium | edita código e roda testes numa fatia bem delimitada | decide escopo ou arquitetura |
| `explorer` | Haiku · medium | lê código, localiza símbolo, mapeia estrutura (read-only) | edita qualquer coisa |
| `researcher` | Haiku · medium | consulta docs, specs e web | edita qualquer coisa |

Lema: **planeje em high, delegue em medium, mantenha o Opus de plantão.**

## Quando chamar o advisor (Opus)

- **antes de um plano** — antes de escrever código ou de se comprometer com uma interpretação;
- **erro que se repete** — a mesma falha duas vezes, ou a abordagem não converge;
- **antes de declarar pronto** — com a entrega já durável (arquivo salvo, commit feito).

Fora disso, fica quieto: tarefa rotineira e reativa não consome Opus.

## Quando delegar

- Busca ampla no código (muitos arquivos, convenções, "onde está X") → `explorer`.
  Use `explorer` no lugar do `Explore` built-in, para a busca rodar em Haiku.
- Documentação, spec externa, API de terceiro → `researcher`.
- Edição mecânica ou fatia de implementação já especificada → `worker`, com contrato
  explícito no prompt: arquivos, o que mudar, como verificar.
- Fato pontual cujo arquivo já é conhecido → faça direto; delegar custa mais que ler.
- Tarefas independentes → dispare os subagentes **na mesma mensagem**, em paralelo.

## Regras de paralelismo e retorno

- Dois `worker` em paralelo **só em arquivos disjuntos**, ou com `isolation: "worktree"`.
  Caso contrário um sobrescreve o outro.
- O resultado de subagente volta para a sessão principal, que **revisa e verifica** (diff,
  testes) antes de seguir. Relatório de subagente não é prova de que funcionou.
- Subagente não re-delega; quem orquestra é sempre a sessão principal.

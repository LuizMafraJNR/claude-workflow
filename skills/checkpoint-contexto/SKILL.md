---
name: checkpoint-contexto
description: Checkpoint antes de limpar o contexto (/clear, /compact) ou encerrar uma sessão. Confere se toda decisão, esclarecimento do usuário, descoberta, pendência e próximo passo da conversa já está registrado em arquivo (spec, plano, tarefas, diário), escreve o que faltar e entrega um relatório de validação. Use quando o usuário disser que vai limpar, compactar ou zerar o contexto, "passar para a implementação em sessão limpa", "encerrar a sessão", "salvar o estado", ou quando um plano for aprovado e a implementação começar numa sessão nova — mesmo que não diga a palavra checkpoint.
effort: medium
---

# Checkpoint de contexto

A conversa é descartável; os arquivos não. Limpar o contexto só é seguro quando os arquivos
contam a história inteira. Esta skill existe para provar isso **antes** do `/clear`, não
depois que a decisão sumiu.

**O teste que decide tudo:** *se eu esquecesse esta conversa agora, os arquivos ainda
contariam a história toda?* Só "sim, com evidência" libera a limpeza.

Você não executa `/clear` nem `/compact`: são comandos do usuário. Seu trabalho é validar,
completar os arquivos e dizer se pode limpar.

## 1. Descubra onde cada coisa mora

Leia o `CLAUDE.md` do projeto e procure o processo de especificação que ele manda seguir
(constituição, skills `sdd*`, pasta `docs/specs/`). Isso decide os destinos:

| O que saiu da conversa | Projeto com spec-driven genérico | Projeto cuja spec/plano é escrita por outro agente ou pessoa |
|---|---|---|
| Decisão de design e a razão | `plan.md` (decisões e alternativas descartadas) | `observacao` da tarefa e diário; nota do `vault/` se virou padrão |
| Esclarecimento ou preferência do usuário que muda comportamento | `spec.md`, como requisito ou critério de aceite | `observacao` da tarefa, sinalizado para o dono da spec |
| Descoberta (spec errada, risco, trabalho novo) | atualizar a spec **antes** de seguir; tarefa nova em `tasks.md` | tarefa nova em `tasks.md` |
| Pendência ou pergunta em aberto | `tasks.md` (`[!]` ou tarefa nova) | idem |
| Estado e próximo passo | `tasks.md` + `CHANGELOG.md` | diário de implementação |

Sem nenhum processo no repositório, grave tudo em `docs/handoff-<slug>.md`.

Regra do dono da spec: se o projeto diz que a spec e o plano pertencem a outro agente,
**não reescreva** `spec.md` nem `plan.md`; registre na `observacao` da tarefa e no diário.

## 2. Levante da conversa o que precisa sobreviver

Releia a conversa visível (não confie na memória do que já está nos arquivos) e liste, por
categoria:

- **Decisões:** o que foi decidido, o porquê, e as alternativas rejeitadas com o motivo.
- **Esclarecimentos do usuário:** qualquer coisa que ele disse e que muda o comportamento ou
  o escopo.
- **Premissas assumidas** sem confirmação.
- **Descobertas:** spec divergente do código, risco novo, tarefa que faltava.
- **Pendências e perguntas abertas.**
- **Estado:** branch, o que foi verificado e com qual comando, o que está sem commit.
- **Próximo passo exato.**

Tentativa que não deu certo e não deixou consequência não precisa sobreviver. Se deixou uma
lição ("não use X porque Y"), precisa.

## 3. Confira cada item contra os arquivos

Para cada item, **abra o arquivo** (busca dirigida, sem varrer o repositório) e marque:

- **registrado**, com `arquivo:linha`;
- **faltando**;
- **descartável**, com a razão em uma linha.

## 4. Complete o que faltou

Escreva só o que está faltando, no destino da tabela, no estilo do arquivo. Não reescreva o
que já está bom, não amplie o escopo da spec e não invente requisito: um esclarecimento do
usuário entra com as palavras dele, em forma de critério verificável.

## 5. Relatório de validação

Entregue neste formato, curto:

```
Item | Tipo | Onde está | Status
...

Arquivos alterados neste checkpoint: ...
Trabalho sem commit: ... (o /clear não apaga arquivos, mas apaga o porquê)
Próximo passo: <comando exato, ex.: /implement <slug>>
Teste "se eu esquecesse esta conversa": sim | não — <evidência ou o que falta>
```

Feche com uma de duas frases: **"Pode limpar."** ou **"Não limpe ainda: falta ..."**.

## Observações

- Se a conversa já foi compactada antes, avise que o checkpoint cobre só o histórico que
  restou visível, e peça ao usuário para conferir se algo importante ficou de fora.
- Se o usuário quer `/compact` em vez de `/clear`, devolva também a linha pronta:
  `/compact guarde: <decisões, arquivos tocados, pendências>`.
- O checkpoint tem que ser barato: leia só os arquivos da feature, não o repositório.

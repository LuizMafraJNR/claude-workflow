# Fase 5 — Review em detalhe

Portão de qualidade final. Roda automaticamente ao fim da Fase 4 e também sozinho (`/spec-driven review`), por exemplo depois de aplicar correções.

## Pré-condição

Leia `spec.md`, `plan.md` e `tasks.md`. Os **critérios de aceitação são a régua**: achado que quebra um CA tem prioridade diferente de achado de qualidade geral.

Se há tarefas `[ ]` pendentes, diga quais. Revisar parcial é legítimo, mas o usuário precisa saber que o diff está incompleto.

## 1. Delimitar o diff

```bash
git status --short
git diff --stat
git diff            # e, se a feature já tem commits: git diff <base>...HEAD
```

Review acontece **sobre o diff**, não sobre o repositório. Problemas pré-existentes que a feature não introduziu não ajudam a decidir se ela pode subir.

## 2. Rodar as duas revisões

Invoque `code-review` e depois `security-review` (ferramenta Skill), cada uma com o escopo fixado no argumento:

```
Revisar o diff da feature 004-exportacao-csv (git diff contra main).
Arquivos: src/export/service.py, src/export/api.py, tests/test_export.py
```

As duas rodam **sempre**. Se a invocação encadeada for recusada pelo harness, não desista do portão: leia o `SKILL.md` de cada uma e siga-o você mesmo. Se nem isso for possível, feche dizendo **em destaque** que a revisão ficou pendente e a feature não está revisada.

Além do que as skills cobrem, olhe o que a spec e o plano declararam: as **invariantes** do `plan.md` valem em todo caminho de código do diff? Os **riscos** listados foram mitigados?

## 3. Triar os achados

| Achado | Destino |
|---|---|
| Quebra um CA da spec, ou é vulnerabilidade real | **Corrigir agora**, nesta execução |
| Válido, mas fora do escopo da feature | **Tarefa nova** no `tasks.md`, marcada pós-review |
| Defeito real em capacidade de **outra** spec | **Encaminhar para correção** (`/spec-driven fix <sintoma>`) — não é tarefa desta feature |
| Não procede | **Descartar**, com uma linha de justificativa |

Corrigir na hora o que está fora do escopo parece diligente e não é: infla o diff recém-revisado com código que ninguém revisou e mistura a feature com um refactor que ninguém pediu.

A terceira linha é a distinção sutil: enxertar um defeito alheio como tarefa desta feature cria uma tarefa sem RF que a justifique — e a spec dona daquele comportamento continua descrevendo o mundo errado.

## 4. Premissa duplicada nos documentos

Quando a implementação descobre que uma premissa do plano era falsa, o reflexo é acrescentar uma seção de correção — deixando **as duas versões vivas** no mesmo documento, e o plano orientando o oposto do código em algum ponto.

```bash
grep -niE "correç(ão|ao) de premissa|premissa|revisad|na verdade|ao contrário" specs/<feature>/{spec,plan}.md
```

Achou dois blocos sobre o mesmo assunto? Confirme qual descreve o repositório **hoje** — medindo, nunca pela data do texto — e apague ou marque o obsoleto. É achado de documento e vale mesmo com o código certo, porque o plano é o que a próxima pessoa lê.

## 5. Reverificar

Toda correção aplicada roda sua verificação de novo. Correção não verificada não conta — e é traiçoeira aqui, porque vem logo depois de um review que deu a impressão de que tudo foi checado.

## 6. Fechar

- Achados corrigidos, com o que mudou e a verificação que provou
- Achados que viraram tarefa nova (e onde) ou encaminhados para correção
- Achados descartados, com a justificativa de uma linha
- `CHANGELOG.md` e `docs/` atualizados, se houve efeito externo
- Commit: siga a regra do repositório (`CLAUDE.md`). Sem regra declarada, **proponha a mensagem e aguarde aprovação** — commit e push são ações visíveis para outras pessoas.

Se as revisões não encontraram nada, diga isso de forma direta. Relatório vazio é resultado válido e mais útil que observações menores inventadas para preenchê-lo.

# claude-workflow

Um workflow de desenvolvimento para o [Claude Code](https://code.claude.com), em português:
especificação antes do código, revisão de código e de segurança obrigatórias no fim, e o
trabalho distribuído entre modelos para gastar menos sem perder qualidade.

> Planeje em high. Delegue em medium. Mantenha o Opus de plantão.

## O que vem no pacote

### Skills

| Skill | O que faz |
|---|---|
| `spec-driven` | SDD completo: mapear o repositório → spec → plano → tarefas → implementação → review. Também cobre correção de bug (`fix`) e review avulso (`review`). Termina **sempre** em code-review + security-review. |
| `analise-mercado` | Valida uma ideia antes de construir: concorrentes, preços, tendências, lacunas, demanda e riscos, com fonte em cada fato. Fecha com veredito e uma semente de spec para o `spec-driven`. |
| `code-review` | Revisão de qualidade: correção lógica, design, legibilidade, performance e testes. Poucos achados, ordenados pelo custo de ignorá-los. |
| `security-review` | Revisão adversarial: autenticação, autorização/IDOR, injeção, segredos, dados sensíveis, SSRF, upload. |
| `migracao` | Planejamento de migração de sistemas legados: inventário do atual, estratégia de corte, dados, rollback. Cada fase volta para o `spec-driven`. |

### Agentes

| Agente | Modelo · effort | Papel |
|---|---|---|
| `worker` | Sonnet · medium | edita código e roda testes numa fatia já especificada |
| `explorer` | Haiku · medium | busca read-only no código |
| `researcher` | Haiku · medium | pesquisa documentação e web |

### Configuração global (`config/`)

- `CLAUDE.md` — a política de distribuição de modelos: quando delegar, para quem, quando chamar o advisor.
- `settings.example.json` — sessão principal em Sonnet/high e advisor em Opus.

## Instalação

**1. Skills e agentes** — dentro do Claude Code:

```
/plugin marketplace add <usuario>/claude-workflow
/plugin install claude-workflow@claude-workflow
```

**2. CLAUDE.md global e modelos** — o plugin não instala isso, então rode o script do repositório:

```powershell
# Windows
git clone https://github.com/<usuario>/claude-workflow
powershell -ExecutionPolicy Bypass -File claude-workflow\scripts\install.ps1
```

```bash
# macOS / Linux (precisa de jq para o settings.json)
git clone https://github.com/<usuario>/claude-workflow
bash claude-workflow/scripts/install.sh
```

O script nunca sobrescreve um `CLAUDE.md` existente e faz backup do `settings.json` antes de
alterar só as chaves de modelo.

**3. Confira** numa sessão nova: `/model`, `/effort` e `/agents`.

## Como usar

```
/claude-workflow:analise-mercado  vale a pena um app de agendamento para barbearias no interior?
/claude-workflow:spec-driven      exportar relatório de vendas em CSV
/claude-workflow:spec-driven fix  o filtro de mês mostra fevereiro no dia 31/01 à noite
/claude-workflow:spec-driven review
```

As skills também disparam sozinhas quando o pedido combina com a descrição delas.

**Se o seu repositório já tem um SDD próprio** (skills `sdd*`, `specs/constitution.md` ou uma
seção no `CLAUDE.md` do projeto), o fluxo local vale e o `spec-driven` vira só referência — o
que não muda é o fechamento com os dois reviews.

## Requisitos e custo

- Claude Code com acesso a Sonnet, Haiku e Opus (o advisor exige a API da Anthropic ou um
  plano que o inclua).
- A `analise-mercado` faz buscas reais na web em paralelo: cada análise consome tokens.
- O advisor recebe a sessão inteira a cada chamada — por isso a política o chama só antes de
  um plano, em erro repetido e antes de concluir.

## Licença

MIT — veja [LICENSE](LICENSE).

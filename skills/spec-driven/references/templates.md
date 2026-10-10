# Templates dos artefatos

Estes são pontos de partida, não formulários. Corte seção que não tem conteúdo real para aquele escopo — seção preenchida com "N/A" só ensina o leitor a pular. Acrescente seção que o escopo pedir.

---

## spec.md

```markdown
# <Título da feature>

Status: rascunho | aprovada | implementada
Criada em: <data>

## Problema

<O que dói hoje, concretamente, sem citar a solução. Quem sofre, com que frequência,
qual o custo de continuar assim.>

## Usuários e alcance

| Perfil | O que pode fazer | O que não pode |
|---|---|---|

## Comportamento esperado

<Cenários em prosa, não listas de campos. Cada cenário: a situação, a ação, o resultado
observável. Inclua os caminhos de exceção — o que acontece quando dá errado é metade
da especificação e a metade que costuma faltar.>

## Requisitos funcionais

- **RF-01** — <capacidade observável, uma frase, sem tecnologia>

## Critérios de aceitação

- **CA-01** (RF-01) — Dado <estado>, quando <ação>, então <resultado observável>.
  <Respondível com sim ou não olhando o sistema pronto.>

## Fora do escopo

- <O que explicitamente não será feito, e por quê quando não for óbvio.>

## Pendências

<Só o que sobrou depois de marcar [PENDENTE: pergunta] inline no ponto onde a dúvida
afeta o comportamento. Se não há pendência nenhuma num domínio que você não domina,
provavelmente você adivinhou em algum lugar.>

## Histórico de alterações desta spec

| Data | RF/CA | O que mudou e por quê | Origem |
|---|---|---|---|
| <data> | — | Spec criada | <pedido \| análise de mercado \| correção de legado> |
```

---

## plan.md

```markdown
# Plano — <Título da feature>

Referência: [spec.md](spec.md)

## Abordagem

<Como resolver, em termos de arquitetura. Uma decisão sem a razão junto é uma decisão
que ninguém vai conseguir reavaliar depois sem refazer a análise inteira.>

## Decisões

| Decisão | Alternativas consideradas | Por que esta |
|---|---|---|

## Reuso

| O que já existe | Onde (caminho) | Como entra na feature |
|---|---|---|

<Vazio = "procurei e não achei nada reaproveitável" — diga onde procurou.>

## Mapeamento RF → implementação

| RF | Onde | Como |
|---|---|---|

## Modelo de dados

<Entidades, relações, migrações. Só o que muda.>

## Contratos

<Endpoints, eventos, interfaces afetadas. Entrada, saída, erros.>

## Invariantes

<Afirmações que devem valer em qualquer estado do sistema, independentemente do caminho
de código. Viram os testes mais valiosos e os pontos mais duros da revisão.>

- <ex.: nenhum caminho de código faz UPDATE ou DELETE na tabela de auditoria>

## Riscos

| Risco | Como se manifesta | Mitigação |
|---|---|---|

## Convenções herdadas

<O que este plano segue de CLAUDE.md e docs/, por referência. Se contraria alguma,
diga qual e por quê — convenção quebrada em silêncio é defeito.>

## Estratégia de teste

<O que precisa de teste automatizado e o que se verifica de outro jeito. Ligue aos
critérios de aceitação.>
```

---

## tasks.md

```markdown
# Tarefas — <Título da feature>

Referência: [spec.md](spec.md) · [plan.md](plan.md)

Legenda: [ ] pendente · [~] em andamento · [x] concluída · [!] bloqueada

- [ ] **T1** — <ação imperativa, verificável isoladamente>
  - RF: RF-01
  - Depende de: —
  - Arquivos: `<caminho>`
  - Verificar: `<comando real>` → <resultado esperado>
  - Escreve dados?: não

- [ ] **T2** — <...>
  - RF: RF-02
  - Depende de: T1
  - Arquivos: `<caminho>`
  - Verificar: `<comando real>` → <resultado esperado>
  - Escreve dados?: sim — <o que grava e onde; para no gate da Fase 4>

Paralelizáveis: T3, T4 (não se tocam)

## Rastreabilidade RF → tarefas

| RF | Tarefas |
|---|---|
| RF-01 | T1 |

<RF sem tarefa: avise o usuário, não invente tarefa para tapar.>

## Bloqueios

<Registre aqui o que travou de fato, com o que é preciso para destravar. Só bloqueio
real: dúvida que você consegue resolver escolhendo o padrão defensável não entra —
decida, registre no plano e siga.>
```

A ordem certa é a que mantém o sistema funcionando entre as tarefas, não a que agrupa arquivos parecidos.

---

## CHANGELOG.md

Segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/), o padrão de mercado. Onde não há git, este arquivo é o único histórico do sistema — escreva pensando em quem vai lê-lo daqui a um ano sem contexto nenhum.

```markdown
# Changelog

Todas as alterações relevantes deste projeto são registradas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [Não publicado]

### Adicionado
- Versionamento de documentos: cada envio preserva o anterior. ([spec](specs/003-versionamento/spec.md))

### Alterado
### Corrigido
### Removido
### Segurança

## [0.2.0] — 2026-08-12
```

Categorias: **Adicionado**, **Alterado**, **Descontinuado**, **Removido**, **Corrigido**, **Segurança**. Omita as vazias.

Cada entrada descreve o efeito para quem usa o sistema, não o arquivo que você mexeu. "Corrigido cálculo de prazo que ignorava feriados" serve; "ajustado `utils.py`" não diz nada. Aponte para a spec quando houver.

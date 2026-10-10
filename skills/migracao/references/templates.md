# Templates dos artefatos de migração

Pontos de partida, não formulários. **Corte seção sem conteúdo real** — seção preenchida com "N/A" só ensina o leitor a pular, e num plano de migração o leitor que pula é o que executa o corte.

---

## migracao.md — escala intermediária (um componente)

Use quando a migração é de um componente só, com fronteira conhecida. Substitui os quatro documentos abaixo.

```markdown
# Migração — <componente> de <origem> para <destino>

Status: rascunho | aprovada | em execução | concluída
Criada em: <data>

## Por que

<O que dói hoje. E a meta mensurável — sem ela não haverá como declarar que terminou.>

## O que existe hoje

<Responsabilidade, quem chama, de que depende, comportamentos implícitos.
Marque FATO / INFERÊNCIA / HIPÓTESE / DESCONHECIDO.>

| Comportamento | Classificação | Justificativa |
|---|---|---|

## O que passa a existir

<Destino, e explicitamente o que NÃO muda nesta migração.>

## Dados

<Mapeamento, qualidade do que existe, como se prova que chegou certo.
Se não há dado a mover, diga isso — é informação, não omissão.>

## Consumidores

| Quem | Como consome | Precisa mudar? | Controlamos? |
|---|---|---|---|

## Riscos

| Risco | Evidência | Mitigação | Contingência |
|---|---|---|---|

## Como validamos

<Caracterização, contrato, comparação. Ligado aos comportamentos PRESERVAR acima.>

## Rollback

<Mecanismo em passos. O que acontece com o que foi escrito no novo.>

## Fases

<Mesmo formato de fases.md, mais enxuto.>

## Pendências

<BLOQUEIO / DECISÃO PENDENTE, cada um com a ação para resolvê-lo.>
```

---

## inventario.md

```markdown
# Inventário — <sistema>

Criado em: <data>

## Escopo do levantamento

<O que foi examinado e o que não foi — e por quê. Delimitar o que ficou de fora
é o que impede o leitor de confiar num inventário parcial como se fosse completo.>

## Componentes

### <componente>

- **Responsabilidade:**
- **Consumidores:** <internos / externos; marque os que não controlamos>
- **Depende de:**
- **Acoplamentos:**
- **Criticidade:** <o que acontece com o negócio se ficar 1h fora>
- **Classificação:** PRESERVAR | MELHORAR | ALTERAR | SUBSTITUIR | REMOVER | DESCONHECIDO
- **Justificativa:**

## Fluxos críticos

<Fim a fim, atravessando componentes. Inclua os passos manuais — são os que
não aparecem em nenhum diagrama e sustentam o fluxo sem que ninguém saiba.>

## Regras de negócio identificadas

| Regra | Onde vive | Evidência | FATO/INFERÊNCIA/HIPÓTESE |
|---|---|---|---|

## Comportamentos implícitos

| Comportamento | Como descobrimos | Alguém depende? | PRESERVAR/ALTERAR |
|---|---|---|---|

## Integrações

| Integração | Direção | Protocolo | Controlamos? | Documentada? |
|---|---|---|---|---|

## Dívida técnica e workarounds

| O que | O que contornava | A migração resolve? | Decisão |
|---|---|---|---|

## Desconhecidos

| O que não sabemos | Impacto na migração | Como descobrir | Responsável |
|---|---|---|---|
```

---

## alvo.md

```markdown
# Arquitetura alvo — <sistema>

Referência: [inventario.md](inventario.md)

## Arquitetura alvo

<Componentes, responsabilidades, comunicação, persistência, integrações,
infraestrutura e — sobretudo — os limites arquiteturais: o que não pode
conhecer o quê.>

## Mapa atual → alvo

| Componente atual | Destino | Estratégia | Dependências | Risco |
|---|---|---|---|---|

<Componente sem destino é lacuna, não simplificação. Vários componentes
convergindo para um só merece atenção: é onde a regra de negócio se perde.>

## Decisões de arquitetura

| Decisão | Alternativas | Por que esta |
|---|---|---|

## Mudanças que NÃO fazem parte desta migração

| Mudança proposta | Por que fica de fora | Quando revisitar |
|---|---|---|

<Esta é a seção que mais reduz risco no documento inteiro. Cada variável que muda
ao mesmo tempo multiplica a dificuldade de achar a origem de uma divergência.>
```

---

## estrategia.md

```markdown
# Estratégia de migração — <sistema>

Referência: [inventario.md](inventario.md) · [alvo.md](alvo.md)

## Estratégia da aplicação

**Escolhida:** <big bang | incremental | strangler fig | dual/parallel run |
branch by abstraction | por domínio>

**Por que:** <ligada às restrições concretas deste caso, não à preferência>

| Alternativa descartada | Por que não |
|---|---|

## Convivência

<Durante quanto tempo antigo e novo coexistem, como o tráfego é roteado,
quem é a fonte da verdade por entidade, e qual o custo de manter os dois.>

## Estratégia de dados

<Mapeamento, qualidade medida, pipeline, e como se prova que chegou certo.
Ver references/dados.md.>

## Estratégia de testes

<Caracterização dos comportamentos PRESERVAR, contrato dos consumidores externos,
comparação automatizada se houver parallel run. Ver references/testes.md.>

## Riscos

| Risco | Prob. | Impacto | Evidência | Mitigação | Contingência |
|---|---|---|---|---|---|

## Observabilidade

<O que observar, linha de base medida no sistema antigo, e os limiares de
CONTINUAR / PAUSAR / ROLLBACK.>

## Rollback

<Mecanismo geral, janela, autoridade para acionar, e como será ensaiado.>

## Pendências

<BLOQUEIO / DECISÃO PENDENTE, cada um com ação e responsável.>
```

---

## fases.md

```markdown
# Fases da migração — <sistema>

Referência: [estrategia.md](estrategia.md)

Legenda: [ ] pendente · [~] em execução · [x] concluída · [!] bloqueada

## Sequência

<Por que esta ordem. A ordem certa é a que mantém o sistema funcionando entre
as fases e ensaia o processo em algo pequeno antes do crítico — não a que agrupa
componentes parecidos.>

---

## [ ] Fase 1 — <nome>

**Objetivo:** <o incremento verificável que esta fase entrega>

**Escopo:** <componentes, dados e fluxos incluídos>

**Fora do escopo:**

**Pré-requisitos:** <o que precisa estar pronto antes; inclui decisões pendentes>

**Depende de:** <fases anteriores, ou —>

**Implementação:** <em linhas gerais; o detalhe vira spec própria pelo fluxo sdd>
→ spec: `specs/<numero>-<slug>/`

**Validação:** <como se comprova que ficou equivalente — caracterização, contrato,
comparação, métrica>

**Riscos desta fase:**

**Rollback desta fase:** <mecanismo em passos; o que acontece com os dados>

**Critérios de saída:**
1. <verificável, respondível com sim ou não>
2.

---

## [ ] Fase N — Desativação do legado

<Sempre a última, sempre explícita. Congelamento somente-leitura antes do
desligamento, confirmação de que ninguém escreve nem lê, arquivamento, data e dono.
Ver references/riscos-rollback.md.>
```

---

## Template de task

Tasks derivam da arquitetura e da estratégia, nunca antes delas. Cada fase gera suas tasks pelo fluxo `sdd` (`tasks.md`), mas numa migração cada task carrega dois campos a mais que uma task comum — **comportamento a preservar** e **como se comprova a equivalência**:

```markdown
- [ ] **T1** — Migrar <componente> para <destino>
  - **Objetivo:** <o resultado, não a atividade>
  - **Contexto:** <o que existe hoje; link para o inventário>
  - **Escopo:** / **Fora do escopo:**
  - **Componentes e arquivos:**
  - **Depende de:**
  - **Preserva:** <comportamentos A, B, C — do inventário>
  - **Substitui:** <dependência Y por Z>
  - **Compatibilidade:** <integração W permanece intacta>
  - **Critérios de aceite:**
    - Dado <situação>, quando <ação>, então <resultado equivalente ao legado>
  - **Validação:** <qual teste de caracterização, qual comparação>
  - **Riscos:**
```

Evite task vaga como "migrar módulo X" — ela não diz o que não pode quebrar, e é justamente isso que a próxima pessoa precisa saber.

Critério de aceite precisa ser verificável. "Sistema funcionando corretamente" não é critério; "dado um pedido válido, o resultado é equivalente ao observado no legado, com tolerância de arredondamento de R$ 0,01" é.

---
name: code-review
description: Revisão de código focada em qualidade, manutenibilidade e sustentabilidade — correção lógica, design/SOLID, legibilidade, performance e cobertura de testes. Use sempre que o usuário pedir para revisar código, revisar um diff, revisar um PR/MR, "dar uma olhada" em mudanças, verificar se um código está bom antes de commitar, ou pedir opinião sobre a qualidade de uma implementação — mesmo que não use a palavra "review". Também use antes de propor um commit de mudança substancial.
model: opus
effort: medium
---

# Code Review

Revisar código não é caçar erros. É responder a uma pergunta mais dura: **alguém vai conseguir manter isso em seis meses, sem te perguntar nada?** Bugs são o sintoma mais visível de código que falha nesse teste, mas não o único.

Isso importa para o formato do seu retorno. Um review que lista trinta observações irrelevantes ao lado de um bug real esconde o bug. Um review que só diz "está bom" desperdiça a leitura. O alvo é: **poucos achados, cada um justificado, ordenados por quanto custam se ignorados.**

## O que NÃO revisar

Formatação — espaçamento, quebra de linha, ponto e vírgula, ordem de imports, aspas simples vs. duplas — é trabalho de linter (ESLint, Prettier, Black, Ruff, SonarQube) no CI. Apontar isso num review humano gasta a atenção do autor no que menos importa e treina ele a ignorar seus comentários. Se o projeto não tem linter configurado, o achado correto é "falta linter no CI", uma vez, não trinta observações de estilo.

Preferência pessoal sem consequência também não entra. "Eu escreveria com early return" só é achado se o aninhamento atual realmente dificulta a leitura ou esconde um caminho não tratado.

## Escopo: leia o diff, não o repositório

O custo de um review é dominado pelo volume de código lido. Um review disciplinado lê o diff e os arquivos que ele toca; um review indisciplinado varre o projeto e produz o mesmo resultado por dez vezes o preço.

Determine o alvo nesta ordem:

1. O usuário apontou arquivo, pasta, PR ou colou código → é esse o alvo.
2. Usuário citou número de PR → `gh pr diff <n>`.
3. Caso geral → o diff da branch atual:

```bash
git diff --stat $(git merge-base HEAD origin/homolog 2>/dev/null || git merge-base HEAD origin/main)..HEAD
```

Se não houver diff commitado, tente `git diff HEAD` (working tree) e `git diff --cached`. Se nada disso render mudança, diga isso e pergunte o alvo — não invente um.

Comece pelo `--stat` para dimensionar. Depois leia o diff completo dos arquivos relevantes. Abra o arquivo inteiro (Read) apenas quando o diff não bastar para julgar — tipicamente quando precisa ver a assinatura de uma função chamada, o resto de uma classe que você está avaliando, ou se um teste já existe. Buscar no repo (Grep) é justificado para responder perguntas específicas: "essa função é chamada em outro lugar?", "já existe um utilitário que faz isso?". Não é justificado para "entender o projeto".

## Padrões locais do repositório

Um review que ignora as convenções do projeto produz achados que o autor vai (corretamente) rejeitar. Antes de julgar design, leia o `CLAUDE.md` aplicável — o da raiz do repo e o do subprojeto tocado pelo diff, se houver. Muitos projetos documentam ali padrões obrigatórios com histórico de violação; **quebrar um deles é achado bloqueante**, não sugestão, porque o projeto já decidiu a questão e o custo do desvio já foi pago antes.

Se existirem comandos de review específicos do projeto (`.claude/commands/*review*.md`), leia-os: eles costumam trazer checklists de padrões locais (framework, tema, camadas) que complementam as categorias abaixo. Se não houver `CLAUDE.md` nem convenção documentada, siga só as categorias — a skill funciona em repo sem documentação.

## As cinco categorias

Percorra todas, mas relate só o que tem consequência. A ordem é deliberada: um problema de correção derruba a feature hoje; um problema de legibilidade cobra juros ao longo de anos.

### 1. Correção e lógica

- **Funcionalidade**: o código faz o que a tarefa pedia? Compare com o que o próprio diff diz que faz (mensagem de commit, nome da branch, descrição do PR, nome da função). Divergência entre intenção declarada e comportamento real é o achado mais valioso que existe.
- **Casos de borda**: nulo, vazio, lista de um elemento, zero, negativo, valor máximo, string com caractere especial. Fronteira de tempo (meia-noite, virada de mês, fuso, horário de verão) e concorrência (duas requisições simultâneas no mesmo registro) são as que mais escapam.
- **Erro e falha externa**: chamada de rede sem timeout, sem retry, ou com `except` que engole a exceção. Um `try/except: pass` transforma falha em corrupção silenciosa de dados — sempre achado.
- **Regras de negócio**: a lógica corresponde à regra real do produto? Aqui é onde o `CLAUDE.md` e os testes existentes são sua melhor fonte. Se você não consegue verificar a regra, diga isso explicitamente em vez de assumir que está certa.

### 2. Design e arquitetura

- **Aderência ao padrão do projeto**: a camada certa faz o trabalho certo? Business logic dentro de view/controller, query de banco dentro de template, chamada HTTP dentro de model — são desvios que se acumulam e travam refactor.
- **Responsabilidade única**: uma função que valida, transforma, persiste e notifica é quatro funções. O sinal prático não é contagem de linhas — é se você consegue nomear a função sem usar "e".
- **Extensibilidade**: adicionar o próximo caso exige editar um `if/elif` gigante em três arquivos diferentes? Isso é dívida com juros conhecidos.
- **Duplicação**: código repetido é achado quando as cópias vão precisar mudar juntas. Duas linhas parecidas que evoluem por motivos independentes é coincidência, não duplicação — abstrair isso cedo cria acoplamento pior que a repetição.

### 3. Legibilidade e manutenibilidade

- **Nomes**: o nome diz o que a coisa é ou faz? `data`, `temp`, `flag`, `handle()`, `process()` obrigam o leitor a reconstruir o significado do corpo. Pior: nome que mente — `get_user()` que também cria o usuário.
- **Complexidade**: aninhamento profundo e função longa são achado quando escondem um caminho não tratado ou impedem entender o fluxo de uma leitura. Aponte a simplificação concreta (early return, extrair predicado nomeado, tabela de despacho) — "simplifique isso" não é revisão.
- **Comentários**: bom comentário explica **por que**, não o quê. `# incrementa i` é ruído; `# a API rejeita lote > 500, daí o chunk` é conhecimento que não está no código e se perderia. Comentário desatualizado que contradiz o código é pior que nenhum — é achado.

### 4. Segurança e performance

Esta skill faz a varredura de superfície. Para diff com superfície de ataque real — autenticação, autorização, entrada de terceiro, query construída dinamicamente, upload, criptografia — recomende ao usuário rodar `/security-review`, que aprofunda com modelo mais forte. Não tente substituí-la.

Na varredura, procure:

- **Injeção**: query montada por concatenação/f-string com valor de entrada (SQL, NoSQL, comando shell, LDAP). Parametrização é a resposta, sempre.
- **Autorização a nível de objeto (IDOR)**: o endpoint checa que o usuário autenticado pode acessar *aquele* registro, ou só que ele está logado? É a falha mais comum e mais explorável em API CRUD.
- **Dados sensíveis**: token, senha, PII ou payload inteiro em log; segredo em URL; stack trace devolvido ao cliente.
- **Segredo comitado**: chave de API, senha, token, certificado, string de conexão em código ou arquivo de config versionado. Achado bloqueante — e o segredo precisa ser rotacionado, não só removido, porque já está no histórico do git.
- **Eficiência**: query dentro de loop (N+1) é o caso dominante. Depois: `SELECT` sem limite em tabela que cresce, carregar coleção inteira em memória para contar/filtrar, índice ausente em coluna de filtro, recomputar o mesmo valor em cada iteração. Só relate se o volume real de dados torna isso relevante — micro-otimização em código que roda uma vez por dia é ruído.

### 5. Testes

- **Presença**: mudança de comportamento sem teste é achado. Bugfix sem teste de regressão é achado mais forte — o bug volta.
- **Qualidade**: o teste verifica comportamento observável ou só executa a linha para subir cobertura? Sinais de teste vazio: nenhuma assertion, assertion sobre o próprio mock, `assert result is not None` como única verificação, teste que passa se você inverter a condição na implementação.
- **Cobertura do que importa**: os testes cobrem caso de sucesso, entrada inválida e caminho de erro — ou só o caminho felizmente feliz?

## Verificar antes de relatar

Um achado errado custa mais que um achado ausente: queima a confiança do autor em todo o resto do review. Antes de listar qualquer coisa, submeta cada achado a este teste:

1. **Eu li o código suficiente para afirmar isso?** Se o argumento depende de como uma função chamada se comporta, abra a função. "Provavelmente não valida" não é achado.
2. **Consigo descrever o cenário concreto de falha?** Entrada específica → comportamento errado específico. Se não consegue, é palpite — descarte ou rebaixe a pergunta ("essa função lida com lista vazia? não consegui confirmar").
3. **Já está tratado em outro lugar?** Validação no serializer, guarda no middleware, constraint no banco, checagem no chamador. Este é o motivo mais frequente de falso positivo.
4. **Tem consequência real?** Se a resposta honesta for "é questão de gosto", não entra.

## Relatar os achados

Use a ferramenta **ReportFindings**, uma única chamada, achados ordenados do mais severo para o menos. Não imprima também a lista como texto — duplica e polui.

Para cada achado:

- `file` — caminho relativo ao repo
- `line` — a linha exata onde ancora
- `short_summary` — a afirmação, ≤60 chars, sem justificativa ("query N+1 no loop de funcionários")
- `summary` — uma frase declarando o defeito
- `failure_scenario` — **entrada/estado concreto → resultado errado concreto**. É o campo que separa review útil de review genérico. "Se `cpf` vier com máscara `123.456.789-01`, o filtro não acha o funcionário e a batida cria um duplicado" é útil; "pode dar problema com CPF inválido" não é.
- `category` — kebab-case: `correctness`, `edge-case`, `business-rule`, `design`, `duplication`, `readability`, `complexity`, `security`, `performance`, `test-coverage`, `project-convention`
- `verdict` — `CONFIRMED` quando você leu o código que prova o defeito; `PLAUSIBLE` quando o raciocínio é sólido mas você não conseguiu verificar tudo. Ser honesto aqui é o que torna o review confiável.

Depois da chamada, escreva **duas ou três frases** no chat: se o diff está aprovável, o que é bloqueante, e — se o diff tem superfície de segurança — a sugestão de rodar `/security-review`.

Se nada sobreviveu à verificação, chame ReportFindings com array vazio e diga claramente que o diff está limpo, mencionando o que você verificou. Um review sem achados é resultado legítimo e frequente; inventar observação para parecer produtivo é o pior desfecho possível desta skill.

## Comentar no PR

**Sempre que o código revisado tiver um PR aberto, publique o review como comentário nele.** O `ReportFindings` renderiza na interface local e desaparece com a sessão; o PR é onde a revisão fica junto do código, visível para quem for aprovar e para quem abrir o histórico em seis meses. Um review que só existiu no seu terminal não revisou nada para o time.

Descubra o PR sem perguntar ao usuário:

```bash
gh pr view --json number,url,title 2>/dev/null              # PR da branch atual
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number,url,state
```

Se o usuário já citou um número de PR, é esse. Publique com:

```bash
gh pr comment <n> --body-file <arquivo.md>
```

Escreva o corpo num arquivo (no diretório de scratchpad, não no repo) em vez de passar `--body` inline: o texto tem markdown, acentuação e quebras de linha, e o shell mutila isso.

**Formato do comentário** — os mesmos achados do `ReportFindings`, em markdown legível:

- Um título curto (`## Code review`) e uma linha dizendo o veredito geral: aprovável, aprovável com ressalvas, ou bloqueado.
- Um bloco por achado, do mais severo ao menos, com: arquivo e linha como referência clicável (`` `caminho/arquivo.py:123` ``), o defeito em uma frase, o cenário concreto de falha, e a correção sugerida quando ela é curta.
- Marque o veredito de cada achado (`CONFIRMED` / `PLAUSIBLE`) — é o que diz ao autor onde ele precisa conferir seu raciocínio.
- Se você descartou falsos positivos durante a verificação, vale uma seção curta "Verificado e descartado" com uma linha cada. Isso poupa o próximo revisor de reabrir a mesma questão e mostra o que foi coberto.
- Fechando: o que é bloqueante para o merge e, se houver superfície de segurança, a sugestão de `/security-review`.

**Quando não comentar:**

- Não há PR (branch local, código colado, working tree sujo) → só o `ReportFindings` e o resumo no chat. Não crie PR para poder comentar.
- O review encontrou zero achados → comente ainda assim, curto: dizer "revisado, sem achados, verifiquei X, Y e Z" tem valor para quem aprova, e evita que o PR pareça não revisado.
- O usuário pediu explicitamente para não comentar.

Comentar no PR **não** é a mesma coisa que aprovar ou solicitar mudanças: use `gh pr comment`, nunca `gh pr review --approve` ou `--request-changes`. Aprovar é decisão do usuário, não sua.

Se o mesmo PR já tem um comentário de review seu de uma rodada anterior, publique um novo em vez de editar o antigo — a sequência de rodadas é informação útil. Deixe claro no título que é uma nova rodada (`## Code review — 2ª rodada`).

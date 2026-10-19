---
name: security-review
description: Revisão de segurança adversarial de mudanças de código — autenticação, autorização/IDOR, injeção, segredos expostos, exposição de dados sensíveis, SSRF, upload e criptografia. Use sempre que o usuário pedir revisão de segurança, auditoria de vulnerabilidades, "isso está seguro?", verificação antes de subir para produção, ou quando o diff toca autenticação, permissões, queries, entrada de terceiros, upload de arquivo ou manejo de segredos — mesmo que o pedido seja um review genérico.
model: opus
effort: medium
---

# Security Review

Um review de segurança tem uma assimetria brutal: **falso negativo é catastrófico e invisível.** Se você deixa passar um IDOR, ninguém percebe — até alguém percebe. Já um falso positivo custa cinco minutos do autor. Isso deveria enviesar você para relatar mais, mas não para relatar *lixo*: um relatório com dez achados especulativos treina o time a ignorar o relatório inteiro, e aí você reintroduziu o falso negativo por outra porta.

O equilíbrio correto: **seja agressivo ao procurar, rigoroso ao afirmar.** Persiga toda hipótese; relate só o que sustenta um cenário de exploração descritível.

Pense como atacante, não como autor. O autor pergunta "isso funciona?". Você pergunta "**o que acontece se eu mentir nesse campo?**".

## Escopo: profundidade onde há superfície

Ler o repositório inteiro é caro e desnecessário; ler só o diff é raso e perde vulnerabilidade encadeada. A regra é: **triagem larga e barata, aprofundamento seletivo.**

Determine o alvo:

1. Alvo explícito do usuário (arquivo, pasta, PR, código colado) → é esse.
2. Número de PR → `gh pr diff <n>`.
3. Caso geral → diff da branch:

```bash
git diff --stat $(git merge-base HEAD origin/homolog 2>/dev/null || git merge-base HEAD origin/main)..HEAD
```

Sem diff commitado, tente `git diff HEAD` e `git diff --cached`. Sem nada, pergunte o alvo.

**Triagem.** Leia o diff completo uma vez e classifique cada arquivo:

- **Superfície sensível** — toca autenticação, autorização/permissões, query de banco, entrada de terceiro (request, webhook, arquivo, mensagem de fila), upload/download, criptografia, chamada HTTP de saída, serialização/deserialização, geração de token, ou qualquer arquivo de configuração/env.
- **Não sensível** — template, CSS, texto, teste, documentação, refactor puramente interno.

Aprofunde só nos sensíveis. Nos não sensíveis, uma passada de olho para segredo comitado e nada mais.

**Aprofundamento.** Para cada arquivo sensível, siga a cadeia de confiança, porque é aí que vive a vulnerabilidade real. Isso significa sair do diff deliberadamente:

- De onde vem cada valor? Rastreie até a fonte. Valor que vem do cliente é hostil, sempre — mesmo que o frontend "só mande valores válidos".
- Quem autoriza? Abra a permission class / middleware / decorator e leia o que ele **de fato** checa. Nome tranquilizador (`IsOwnerOrAdmin`) não é prova.
- O que a função chamada garante? Se seu achado depende de "isso provavelmente não valida", abra e confirme.

Duas ou três saltos de Grep/Read por hipótese é o custo justo de um achado confirmado. Varrer o projeto sem hipótese não é.

## Contexto do projeto

Leia o `CLAUDE.md` da raiz e do subprojeto tocado. Em sistema com integração machine-to-machine, contrato de auth documentado e regras cross-service, o documento costuma conter exatamente as invariantes de segurança que o diff pode estar quebrando — e frases como "identificado só pelo documento enviado pelo cliente" ou "sem o header de usuário, qualquer chamador pode consultar qualquer registro" são declarações de superfície de ataque assumida. Verificar se o diff respeita ou amplia essa superfície é dos achados mais valiosos que você pode produzir.

## O que procurar

### Autorização — comece aqui

É a categoria com mais vulnerabilidades reais e menos cobertura por ferramenta automática, porque a falha é semântica: o código funciona, só permite quem não devia.

- **IDOR / autorização a nível de objeto**: o endpoint valida que o usuário autenticado pode acessar **aquele** registro, ou só que ele está autenticado? Todo ID que vem do cliente (path param, query, body) é a pergunta. `Pedido.objects.get(pk=request.data['id'])` sem filtro por dono é a forma canônica da falha.
- **Escalada de privilégio**: usuário comum alcança rota/ação de admin? Campo sensível (`is_admin`, `role`, `valor`, `desconto`, `saldo`) aceito de payload de usuário e persistido sem filtro (mass assignment)? Endpoint que aceita "para qual usuário" sem checar alçada?
- **Ausência de checagem**: rota nova sem permission class; `AllowAny` sem justificativa; decorator de permissão colocado na função errada ou depois de um `return` cedo; permissão checada no frontend e não no backend.
- **Vazamento cross-tenant / cross-setor**: filtro de escopo (empresa, setor, cliente) aplicado em uma query e esquecido em outra do mesmo fluxo — export, relatório e listagem agregada são onde escapa.

Método: para cada endpoint tocado, responda explicitamente **"quem pode chamar isso, e sobre os dados de quem?"**. Se não conseguir responder lendo o código, é achado.

### Injeção

- SQL/NoSQL montado com concatenação, f-string, `%`, `.format()` ou template, com qualquer valor de origem externa. Parametrização (`?`, `%s`, bind) é a única resposta aceitável — escapar manualmente não é.
- ORM com escape hatch: `raw()`, `extra()`, `RawSQL`, `cursor.execute` com string construída.
- Comando de sistema: `os.system`, `subprocess` com `shell=True`, backtick — com valor externo em qualquer posição.
- Injeção de template (SSTI), de expressão, de LDAP, de header (CRLF em resposta), de log (quebra de linha em entrada logada).
- Deserialização insegura: `pickle`, `yaml.load` sem `SafeLoader`, `eval`, `exec` sobre dado externo.

### Segredos

- Chave de API, senha, token, private key, string de conexão, secret de assinatura em código, teste, fixture, migration, comentário ou config versionado.
- Segredo em URL (fica em log de proxy, histórico, referer) ou em query string de redirect.
- Valor default de fallback perigoso: `SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret')` em código que roda em produção.
- Achado de segredo é **sempre bloqueante**, e a remediação inclui **rotacionar** — remover do código não basta, o valor já está no histórico do git e em qualquer clone.

### Exposição de dados

- PII, credencial, token ou payload/request inteiro em log — especialmente em nível INFO/DEBUG.
- Stack trace, mensagem de exceção interna, query SQL ou caminho de arquivo devolvidos ao cliente.
- Serializer/response que devolve campo além do necessário — hash de senha, token interno, dado de outro usuário, campo administrativo.
- Endpoint de erro que diferencia "usuário não existe" de "senha errada" (enumeração de conta); resposta cujo tempo diferencia os dois casos.

### Autenticação e sessão

- Validação de token: assinatura verificada? `exp` checado? algoritmo fixado (rejeita `alg: none` e confusão RS256/HS256)? `iss`/`aud` validados quando o mesmo par de chaves serve mais de um emissor?
- Comparação de segredo/HMAC com `==` em vez de comparação de tempo constante (`hmac.compare_digest`, `crypto.timingSafeEqual`).
- Hash de senha com algoritmo rápido (MD5, SHA1, SHA256 puro) em vez de bcrypt/argon2/scrypt.
- Fluxo de reset/convite com token previsível, sem expiração, ou reutilizável.
- Ausência de rate limit em login, reset de senha, envio de OTP, ou endpoint caro.

### Requisições de saída e recursos

- **SSRF**: URL de destino influenciada por entrada do usuário — webhook configurável, importação por URL, proxy, geração de preview. Metadata de cloud (`169.254.169.254`) é o alvo clássico.
- **Path traversal**: nome de arquivo de upload/download composto com entrada do cliente (`../`, caminho absoluto, byte nulo).
- **Upload**: tipo validado só por extensão ou por `Content-Type` do cliente; sem limite de tamanho; salvo em diretório servido diretamente; nome preservado sem sanitização.
- **Redirect aberto**: destino de redirect vindo de parâmetro sem allowlist.
- **CSRF**: mudança de estado por GET, ou endpoint mutante com proteção CSRF desabilitada sem ser API stateless com token em header.
- **Exaustão de recurso**: entrada que controla tamanho de loop, alocação, paginação sem teto, regex sobre entrada longa com backtracking catastrófico (ReDoS), zip bomb.

### Criptografia

- Algoritmo obsoleto (DES, RC4, ECB), IV/nonce fixo ou reutilizado, `random` em vez de CSPRNG para token/senha/ID.
- Verificação de certificado TLS desabilitada (`verify=False`, `rejectUnauthorized: false`, `InsecureSkipVerify`).

## Verificar antes de relatar

Cada achado passa por isto — e aqui o rigor é maior que num review comum, porque um relatório de segurança move prioridade de time:

1. **Descreva o ataque em passos concretos.** Quem é o atacante (anônimo? usuário comum autenticado? outro tenant?), o que ele envia, o que ele obtém. Se não consegue escrever esses três, você tem suspeita, não achado.
2. **Confirme que a defesa não existe.** Abra a permission class, o middleware, o validador, a constraint. Este é o filtro que mais elimina falso positivo: a maioria das "vulnerabilidades" está tratada uma camada acima.
3. **Verifique se é alcançável.** Código morto, rota não registrada, branch atrás de flag desligada, função só chamada por management command interno — mudam a severidade materialmente. Diga se a alcançabilidade é condicional.
4. **Confirme que o diff introduz ou amplia.** Vulnerabilidade preexistente e intocada pelo diff pode ser mencionada, mas marcada como tal — misturar as duas coisas distorce a avaliação do PR.

Quando o raciocínio é sólido mas você não pôde confirmar (código fora do repo, comportamento de lib, config de runtime), relate com `verdict: PLAUSIBLE` e diga o que falta verificar. Isso é muito melhor que silenciar: em segurança, "não consegui confirmar se esse endpoint checa dono" é informação acionável.

## Relatar

Uma única chamada a **ReportFindings**, ordenada por severidade real (impacto × alcançabilidade), não por categoria. Não repita a lista como texto.

Para cada achado:

- `file`, `line` — onde ancora
- `short_summary` — a afirmação, ≤60 chars ("IDOR: cancelamento aceita pedido de outro cliente")
- `summary` — uma frase com a vulnerabilidade
- `failure_scenario` — **o ataque em passos**: quem, o que envia, o que obtém. Ex.: "Cliente comum autenticado envia `POST /api/v1/pedidos/<id>/cancelar/` com o `id` do pedido de outra pessoa; a view não valida que o pedido pertence ao solicitante, então ele cancela a compra de outro cliente."
- `category` — `broken-access-control`, `idor`, `privilege-escalation`, `injection`, `hardcoded-secret`, `sensitive-data-exposure`, `broken-auth`, `ssrf`, `path-traversal`, `insecure-upload`, `csrf`, `open-redirect`, `resource-exhaustion`, `weak-crypto`, `insecure-deserialization`
- `verdict` — `CONFIRMED` se você leu o código que prova ausência de defesa; `PLAUSIBLE` caso contrário

Depois, no chat, **três a cinco frases**: veredito sobre subir para produção, o que é bloqueante, e — importante — **o que você verificou e considerou seguro**. Essa última parte é o que dá ao leitor a medida da cobertura do review; sem ela, ele não sabe se ausência de achado significa "está limpo" ou "não olhei".

Nada encontrado é resultado válido e comum: ReportFindings com array vazio, e um resumo explícito das superfícies que você examinou e por que cada uma se sustenta. Nunca fabrique achado para justificar o review — em segurança, ruído é o mecanismo pelo qual vulnerabilidades reais passam desapercebidas.

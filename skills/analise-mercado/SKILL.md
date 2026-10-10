---
name: analise-mercado
description: Ideação e análise de mercado para decidir SE e O QUÊ construir — enquadra a ideia, pesquisa concorrentes e preços, tendências em crescimento, lacunas (o que está em falta, o que os usuários reclamam), sinais de demanda e riscos, e fecha com veredito (seguir, pivotar ou descartar) e uma semente de spec pronta para o SDD. Use sempre que o usuário trouxer uma ideia de produto, negócio, funcionalidade ou SaaS para validar; pedir pesquisa de mercado, análise de concorrência, benchmark de produtos, comparação com o mercado, "o que está crescendo", "o que falta no mercado", oportunidade, nicho, tendência, "vale a pena construir X?", "existe algo parecido?" — mesmo que não use a palavra mercado. Não use para comparar bibliotecas ou frameworks técnicos (isso é pesquisa técnica pontual), nem para escrever a spec em si (isso é a skill spec-driven, que recebe o relatório desta).
effort: high
---

# Análise de mercado e ideação

O objetivo não é produzir um relatório bonito — é **evitar construir a coisa errada**. A pergunta que esta skill responde é: *existe uma dor real, que as alternativas atuais resolvem mal, para gente que pagaria (em dinheiro ou adoção) por algo melhor?* Cada seção do relatório existe para sustentar ou derrubar essa afirmação.

Isso define o tom: um "não vale a pena" bem fundamentado é um resultado excelente. Ele economiza meses. O fracasso desta skill é o relatório otimista que confirma a ideia porque o usuário estava animado com ela.

## Regras de evidência

Pesquisa de mercado feita por modelo tem um modo de falha conhecido: números plausíveis sem fonte, concorrentes inventados, tendências afirmadas por intuição. Por isso:

- **Toda afirmação factual leva fonte** — URL e data de acesso. Sem fonte, não é fato.
- **Número de mercado é estimativa** — diga de onde veio e o ano. TAM de relatório de consultoria é marketing da consultoria; trate como ordem de grandeza, nunca como dado.
- **Separe fato de inferência, visivelmente** — marque o que é leitura sua (`**Inferência:**`). O leitor precisa saber onde a evidência acaba.
- **"Não encontrado" é resposta válida** — escreva isso em vez de preencher a lacuna. Ausência de concorrente às vezes é ausência de mercado.
- **Prefira sinal recente** — mercado muda rápido; fonte com mais de dois anos vale como contexto, não como estado atual. Marque o ano.
- **Fonte primária primeiro** — site e página de preço do próprio produto, documentação, dados públicos, reviews de usuário real (G2, Capterra, App Store, Reclame Aqui, Reddit, fóruns do nicho). Artigo de blog que agrega outros blogs é a última opção.

## Fluxo

### 1. Enquadrar a ideia (antes de pesquisar)

Escreva em poucas linhas, e confirme com o usuário se algo for ambíguo:
- **Problema** — a dor, sem citar a solução.
- **Quem tem o problema** — perfil concreto (segmento, porte, região). "Empresas" não é perfil.
- **Alternativa atual** — o que essa pessoa faz hoje (planilha, concorrente, processo manual, nada).
- **Região e idioma do mercado** — muda concorrentes, preço e regulação. Se o usuário não disse, pergunte; no Brasil o mercado costuma ser outro.
- **Restrições do usuário** — orçamento, time, prazo, se é produto próprio ou para cliente.

Pergunte só o que muda a pesquisa. Se o enquadramento for claro, siga.

### 2. Pesquisar em paralelo

Divida a pesquisa por dimensão e dispare um subagente `researcher` por dimensão, **na mesma mensagem**, para rodarem em paralelo e não encherem o contexto principal com páginas lidas. Sem esse agente disponível, use `general-purpose` ou pesquise você mesmo, uma dimensão por vez.

Dimensões (corte as que não fazem sentido para a ideia):

| Dimensão | Pergunta que responde |
|---|---|
| Concorrentes diretos | quem resolve exatamente isso, por quanto, para quem |
| Substitutos e indiretos | o que as pessoas usam no lugar (planilha, ferramenta genérica, serviço) |
| Lacunas e reclamações | o que os usuários dos concorrentes reclamam em reviews e fóruns |
| Tendências | o que está crescendo ou encolhendo no espaço, com sinal datado |
| Demanda | sinais de que alguém procura isso (buscas, comunidades, vagas, financiamento recente) |
| Regulação e riscos | lei, certificação, dependência de plataforma, barreira de entrada |

No prompt de cada subagente, passe o enquadramento do passo 1, a pergunta da dimensão e as regras de evidência acima, e peça o retorno **em tópicos curtos com URL e data por item** — não um texto corrido.

### 3. Sintetizar

O trabalho de verdade é cruzar as dimensões, não justapô-las:
- Uma reclamação recorrente em vários concorrentes é uma **lacuna**; em um só é um defeito daquele produto.
- Tendência em crescimento sem lacuna é mercado disputado; lacuna sem demanda é nicho que ninguém procura.
- Concorrente bem financiado e recente é sinal de mercado *e* de briga.

Se a síntese revelar um buraco que muda o veredito (ex.: não sabe se existe concorrente local), faça **uma** rodada extra focada. Mais que isso vira pesquisa infinita.

### 4. Escrever o relatório

Use a estrutura de `references/relatorio.md`. Salve em:
- dentro de um repositório: `docs/ideias/<slug>/analise.md`;
- fora de um repositório: `./analise-<slug>.md` no diretório atual.

Mostre ao usuário o veredito e os três achados que mais pesaram, com o caminho do arquivo — não cole o relatório inteiro no chat.

### 5. Entregar para o SDD

Se o veredito for **seguir** ou **pivotar**, o relatório termina com a **semente de spec**: problema, usuários, comportamento central, fora do escopo e pendências `[PENDENTE: ...]`. Ela é o *documento de origem* que a skill `spec-driven` lê na Fase 1 — a spec é extraída dela em vez de reescrita do zero.

Ofereça seguir para `/spec-driven` com o relatório como origem. Não comece a especificar sem o OK: decidir construir é do usuário.

Code-review e security-review não se aplicam a este relatório — não há código. Eles acontecem obrigatoriamente na Fase 5 do SDD, quando a ideia virar implementação.

## Sinais de que a análise está ruim

- Nenhuma lacuna vem de reclamação real de usuário — foi imaginada.
- Todo concorrente é "caro, complexo e ultrapassado" — viés de quem quer construir.
- Tamanho de mercado em número exato sem fonte.
- Veredito "seguir" sem nenhum risco relevante listado.
- Não dá para dizer, lendo o relatório, quem pagaria e por quê.

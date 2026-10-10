# Inventário do sistema atual

O propósito deste levantamento é responder a uma pergunta só: **o que quebra se eu desligar isto?** Tudo aqui serve a ela.

## O que investigar

Varra o que estiver disponível, na ordem de maior retorno:

| Fonte | O que ela revela que as outras não revelam |
|---|---|
| Banco de dados | quem escreve, quem lê, o que é integração disfarçada de tabela |
| Código-fonte | regras de negócio implementadas, workarounds, comportamento implícito |
| Configuração e variáveis de ambiente | integrações externas, feature flags, comportamento que varia por ambiente |
| Jobs, crons, filas | processamento assíncrono — o que roda sem ninguém olhar |
| Logs de produção | o que realmente é usado, e o que só existe no código |
| Autenticação e autorização | quem pode o quê; costuma ser a parte menos documentada |
| Pipelines e infraestrutura | como isso sobe, e o que impede de subir em outro lugar |
| Relatórios e exportações | consumidores silenciosos; quebram tarde e reclamam alto |
| Processos manuais | o passo que uma pessoa faz na mão e que ninguém documentou |

O item mais perigoso da lista é o último. Migração falha com frequência não por causa do código, mas porque uma pessoa executava um passo manual que sustentava o fluxo, e ninguém sabia.

## Quando o código não é a fonte da verdade

Duas situações são comuns em legado antigo e quebram o levantamento se você não as reconhecer cedo:

**A lógica de negócio vive no banco.** Stored procedure, trigger, view com regra, constraint que implementa política, job de banco. A aplicação só chama. Isso muda três coisas de uma vez: o inventário precisa varrer o dicionário do banco, não só o código; a classificação `PRESERVAR`/`ALTERAR` incide sobre objetos de banco; e — o ponto que mais escapa — **as estratégias de aplicação e de dados deixam de ser independentes.** Migrar o banco passa a ser também reescrever aplicação, e um plano que trata as duas em fases separadas vai descobrir isso no meio da execução. Verifique isso *antes* de fixar a estratégia, porque a resposta muda a escolha.

**O fonte não existe, está incompleto, ou não corresponde ao binário em produção.** Frequente em sistemas de uma década ou mais. Não trate como impedimento nem finja que o fonte disponível é autoritativo — declare qual é o caso e mude o instrumento de levantamento:

- **Observação de comportamento** passa a ser a fonte primária: entradas e saídas reais, log de produção, tráfego de rede, estado do banco antes e depois de uma operação.
- **O banco vira o inventário mais confiável que você tem** — o schema, as constraints e os dados registram décadas de regra efetivamente aplicada. Valor que existe nos dados revela regra que o código aceitou algum dia.
- **O conhecimento das pessoas** que operam o sistema passa a ser evidência de primeira classe, e precisa ser registrado como `INFERÊNCIA` até confirmado por observação — memória de operador é boa em intenção e ruim em detalhe.
- **O teste de caracterização é construído por fora**, pela interface que existir, mesmo que seja uma pessoa operando uma tela. Se a operação só acontece por interação manual, isso limita quantos casos você consegue registrar, e essa limitação é um `RISCO` a declarar, não um detalhe de execução.

Nesse cenário o inventário legitimamente terá muitos `DESCONHECIDO`. Isso não é falha — mas um inventário que é *só* `DESCONHECIDO` não sustenta decisão nenhuma. Quando chegar nesse ponto, **a primeira fase da migração é investigação**, com escopo e critério de saída próprios, e não a migração de nada.

## O que registrar

Para cada componente ou módulo:

- **Responsabilidade** — em uma frase, o que ele faz.
- **Quem o chama** — internos e externos. Externo que você não controla é a restrição mais dura do plano inteiro.
- **De que ele depende** — serviços, bibliotecas, tabelas, arquivos, credenciais.
- **Acoplamentos** — onde ele conhece detalhe interno de outro. Determina se é possível migrar isolado.
- **Criticidade** — o que acontece com o negócio se ficar fora por uma hora.
- **Classificação** — `PRESERVAR` / `MELHORAR` / `ALTERAR` / `SUBSTITUIR` / `REMOVER` / `DESCONHECIDO`, com justificativa.

## Fato, inferência, hipótese

Marque cada afirmação. Não é formalidade: hipótese não marcada vira requisito ao ser copiada para o documento seguinte, e depois de duas cópias ninguém lembra que era chute.

```
FATO         comprovado por código, banco, log, documentação ou informação do usuário
INFERÊNCIA   deduzido de evidência — plausível, não verificado
HIPÓTESE     suposição em uso temporário; precisa confirmação antes de virar decisão
DESCONHECIDO não foi possível determinar; gera ação para descobrir
```

Toda `HIPÓTESE` que sustenta uma decisão de arquitetura precisa ser confirmada antes do gate da estratégia. Se não puder ser confirmada, ela vira `RISCO` explícito — com o plano de contingência caso se prove falsa.

## Comportamentos implícitos

São a maior fonte de surpresa no corte, porque não estão em nenhum requisito. Procure ativamente por:

- **Ordenação não declarada** — resultado que sempre veio ordenado por acidente do índice, e alguém passou a depender disso.
- **Tolerância a entrada inválida** — o sistema antigo aceitava e normalizava algo que o novo vai rejeitar. Existe dado gravado assim.
- **Timing e fuso** — o que "hoje" significa, em qual fuso, em que ponto do código.
- **Arredondamento e precisão** — dinheiro e hora. Divergência de centavo é onde a validação de paridade quebra primeiro.
- **Idempotência** — o que acontece quando a mesma operação chega duas vezes. Se o antigo tolerava por acidente, alguém já depende disso.
- **Efeito colateral de leitura** — endpoint de GET que escreve. Existe mais do que se imagina, e some no redesenho.
- **Comportamento sob erro** — o que o sistema faz quando a integração externa está fora. Retry, fila, silêncio.

Para cada um encontrado, decida explicitamente se é `PRESERVAR` ou `ALTERAR` — nunca deixe cair no esquecimento. Comportamento implícito não classificado é comportamento que vai mudar sem ninguém decidir.

## Dívida técnica e workarounds

Registre, mas **não os trate automaticamente como coisa a corrigir na migração**. Cada workaround existe porque resolveu algo — às vezes algo que ainda não foi resolvido de outra forma. Remover um workaround sem entender o que ele contornava é a forma mais rápida de reintroduzir um bug antigo com cara de bug novo.

Classifique: o que a migração naturalmente elimina (porque a plataforma nova já resolve), o que precisa ser transportado como está, e o que é candidato a evolução posterior.

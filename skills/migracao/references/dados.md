# Estratégia de dados

Dados são uma migração independente, com plano e rollback próprios. A razão é assimétrica e simples: **aplicação errada você redeploya; dado corrompido você não recupera** — a não ser que tenha planejado antes como recuperar.

## O que analisar

**Modelo atual e modelo alvo**, e entre eles o mapeamento entidade a entidade, campo a campo: tipo, nulidade, constraint, índice, chave, relacionamento, cardinalidade.

Os pontos que costumam morder:

- **Identidade.** O ID do sistema novo é o mesmo do antigo? Se muda, algo externo referencia o antigo — link, planilha, integração, log. Preserve o ID original em coluna de correlação; é barato agora e insubstituível depois.
- **Precisão e escala.** Dinheiro em float, hora em minutos inteiros, timestamp sem fuso. Diferença de arredondamento aparece na reconciliação e custa dias para rastrear.
- **Fuso horário.** Data gravada em fuso local, em UTC, ou em nenhum dos dois de forma consistente ao longo do histórico. Verifique por período — sistemas antigos frequentemente mudaram de convenção no meio da vida.
- **Enum e domínio.** Valor que existe nos dados mas não na lista de valores válidos do código. Existe sempre.
- **Encoding.** Latin-1 legado sob UTF-8 novo. Aparece nos nomes com acento e só em parte das linhas.
- **Soft delete.** Registro marcado como removido: migra ou não? Se não migrar, o histórico e o relatório do ano passado mudam.

## Qualidade dos dados existentes

Antes de mapear, **meça** — não presuma:

- Registros que violam a constraint que o modelo novo vai exigir (nulo em campo obrigatório, FK órfã, duplicata em campo que virará único).
- Registros órfãos e duplicados.
- Volumetria por entidade e taxa de crescimento — decide se a carga cabe numa janela ou precisa ser incremental.
- Distribuição temporal — quanto do volume é histórico frio que talvez não precise migrar para o sistema quente.

Cada violação encontrada exige decisão explícita **antes** da carga: corrigir na origem, transformar na carga, ou rejeitar e tratar à parte. `DECISÃO PENDENTE` é resposta legítima aqui — adivinhar não é, porque a escolha muda o número que o negócio vê depois.

Dado que não pode ser migrado precisa de destino declarado: arquivo morto consultável, tabela de quarentena, ou descarte documentado com aprovação de quem responde pelo dado.

## O pipeline

```
Extração  →  Transformação  →  Carga  →  Validação  →  Reconciliação
```

Faça com que ele seja **repetível e idempotente**. Você vai rodá-lo muitas vezes: em cópia, em homologação, em ensaio, e no dia. Pipeline que só funciona uma vez porque suja o destino não pode ser ensaiado — e pipeline não ensaiado é o maior risco da migração.

Preserve os dados de origem intocados durante todo o processo. Extração é leitura.

## Como provar que os dados chegaram certos

Contagem de linhas não é prova. Ela passa com todos os valores errados.

Construa a validação em camadas, da mais barata para a mais forte:

1. **Contagem** por entidade, e por período. Detecta perda em bloco.
2. **Soma de controle** sobre os campos que o negócio confere: total financeiro, total de horas, total por status, por mês. É a camada que pega erro de conversão e de arredondamento.
3. **Integridade referencial** no destino: nenhuma FK órfã criada pela carga.
4. **Amostragem dirigida** — não aleatória. Escolha os casos extremos que você identificou no inventário: o registro mais antigo, o com acento, o com valor negativo, o soft-deleted, o duplicado, o de fuso ambíguo. É onde o defeito vive.
5. **Reconciliação de saída** — a prova mais forte. Gere o mesmo relatório nos dois sistemas, sobre o mesmo período, e compare. Se o número que o negócio usa bate nos dois lados, o dado chegou. Se não bate, você tem um número concreto para investigar em vez de uma suspeita.

Defina de antemão **qual divergência é aceitável** e por quê — centavo de arredondamento, ordenação, timestamp de criação. Sem isso, toda divergência vira discussão no dia do corte.

## Escrita durante a convivência

Se antigo e novo coexistem e ambos escrevem, você precisa decidir explicitamente, por entidade:

- **Quem é a fonte da verdade** durante a convivência. Um dos dois é; nunca os dois.
- **Como o outro lado se atualiza** — replicação, evento, carga incremental, ou nada (leitura só do dono).
- **O que acontece com conflito** — o mesmo registro alterado nos dois lados. Se você não decidir, o último que escreve ganha, e isso será silencioso.

Escrita dupla sem dono definido é a forma mais confiável de produzir dois sistemas divergindo sem que ninguém perceba.

## Rollback de dados

A pergunta que decide se o rollback existe: **o que acontece com o que foi escrito no sistema novo depois do corte?**

- Se o antigo continua sendo a fonte da verdade, o rollback é desligar o novo. Barato.
- Se o novo passou a receber escrita própria, o rollback exige trazer essas escritas de volta — e isso precisa ser construído **antes** do corte, não improvisado durante.
- Se não for viável trazer de volta, diga: a janela de rollback expira na primeira escrita, e a partir daí a única saída é corrigir para frente. É uma decisão legítima, mas precisa ser tomada consciente, não descoberta.

Registre também o ponto de restauração: backup verificado, com restauração **testada**, e o tempo que a restauração leva de fato. Backup nunca restaurado é hipótese, não plano.

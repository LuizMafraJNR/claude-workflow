# Correção dentro do SDD

Porta de entrada de toda correção: bug, comportamento divergente, regra que mudou em algo já entregue.

## Ideia central

Corrigir o código sem tocar a spec faz a spec mentir — e spec que mente é pior que spec nenhuma: quem lê depois acredita nela, planeja em cima dela e só descobre a divergência quando o sistema real a contradiz, normalmente em produção.

Então o trabalho aqui **não é consertar primeiro**. É decidir *qual documento passa a descrever o comportamento correto*, e deixar o conserto para a Fase 4, que sabe verificar.

A entrada é o **sintoma em linguagem natural**. Localizar o defeito é trabalho seu, não do usuário. Se ele der uma pista (arquivo, feature), aproveite para pular a busca — mas nunca cobre isso dele.

## Passo 1 — Causa raiz, sem editar código

Leia o código a partir dos termos do sintoma, chegue ao arquivo e à função. **Não edite código-fonte nesta etapa.** Um bug entendido pela metade vira requisito errado, e requisito errado parece revisado: passa pelo review, entra na spec e vira a descrição oficial de algo que ninguém validou.

Separe sintoma de causa. "Duplica o registro" é sintoma; "o retry reenvia sem chave de idempotência" é causa. A spec falará da causa em termos de comportamento observável.

Leia o `CLAUDE.md` do repositório e `docs/armadilhas.md` se existir — muitos bugs são reincidência de um padrão já conhecido.

## Passo 2 — Localizar a spec dona

Procure em `specs/` a spec cujos RF/CA descrevem a capacidade errada. A pergunta é: **que documento deveria ter previsto isso?**

| Situação | Destino |
|---|---|
| Existe spec cujos RF/CA cobrem a capacidade | Emendar — acrescentar RF/CA |
| Existe spec, mas o comportamento correto **contradiz** um RF/CA dela | Corrigir aquele RF/CA **no lugar** — nunca acrescentar um contraditório |
| Nenhuma spec cobre (código legado) | Spec nova mínima |

O segundo caso é o que mais dá errado quando fica implícito: acrescentar um RF-08 que diz o oposto do RF-03 deixa a spec inconsistente, e o próximo leitor não sabe qual vale.

## Passo 2b — Gate: confirmar o diagnóstico

Antes de escrever qualquer arquivo, apresente curto:
- a **causa raiz** (arquivo/função e o mecanismo em uma ou duas frases);
- a **spec dona** escolhida, ou a decisão de criar uma nova;
- quais **RF/CA** serão acrescentados ou corrigidos.

Espere confirmação. Você inferiu a causa lendo código; o usuário sabe como o sistema se comporta em produção e o que já foi tentado. Se ele corrigir o diagnóstico, volte ao passo 1. A partir do OK, a passada é contínua até o review.

## Passo 3 — Escrever

**Emenda**: atualize o status e a data, acrescente RF/CA na numeração contínua (ou corrija in loco), e registre no histórico:

```markdown
| <data> | RF-03, CA-05 | <o que mudou e por quê>. Origem: bug em produção \| ajuste solicitado \| achado de review |
```

O campo **Origem** distingue "o sistema fazia o errado" de "mudamos de ideia sobre o certo" — consequências diferentes para quem mexer ali depois.

O CA novo deve ser o que **prova que o bug não volta**: descreva o estado que produzia o defeito e o resultado correto.

**Spec nova mínima**: slug descrevendo o comportamento **correto**, não o defeito (`fuso-mes-relatorio`, não `fix-bug-data`) — a spec continua existindo depois que o bug for esquecido. Só as seções que a correção precisa: problema, RF/CA, fora do escopo, histórico. É assim que a cobertura do SDD cresce sozinha sobre o legado.

**Plano**: se a correção invalida uma decisão do `plan.md`, ajuste-o; senão ele segue descrevendo uma abordagem que o código já não usa. Para correção local sem escolha de abordagem, o `plan.md` é dispensável — diga isso explicitamente no fechamento, para a ausência se ler como decisão.

## Passo 4 — Tarefas e implementação

Enxerte as tarefas no `tasks.md` (marcadas *(correção)*, apontando o RF que satisfazem) e siga direto para a Fase 4 e a Fase 5, sem nova parada.

A verificação precisa **provar a correção**, não só que o código roda: um teste que passaria igualmente antes do fix não verifica nada. O natural é um teste que falha hoje e passa depois.

## Sem escapatória para o trivial

Se existe spec cobrindo o comportamento, não há "bug pequeno demais para mexer na spec". Correção pequena gera registro pequeno — um CA, uma tarefa, uma linha de histórico. O caro é a spec que já não descreve o sistema, e ela nunca fica errada de uma vez: fica errada um "só desta vez" por vez.

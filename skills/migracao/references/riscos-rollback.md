# Riscos, rollback, observabilidade e Definition of Done

## Riscos

Registre cada risco com estes campos. O que costuma faltar é **evidência** e **contingência** — sem evidência o risco é opinião e ninguém o prioriza; sem contingência a mitigação é otimismo.

| Campo | Por que importa |
|---|---|
| Risco | o que pode acontecer, concretamente |
| Probabilidade | alta / média / baixa |
| Impacto | o que se perde se acontecer |
| Severidade | probabilidade × impacto, para ordenar |
| Evidência | o que faz você acreditar que é real — log, medição, incidente passado |
| Mitigação | o que reduz a probabilidade, feito **antes** |
| Contingência | o que se faz **se acontecer mesmo assim** |

Cubra ao menos: técnico, dados, integrações, segurança, performance, operacional, infraestrutura, equipe, prazo, dependência externa e **conhecimento do legado** — este último é o mais subestimado, porque não aparece em nenhum diagrama e some com a pessoa.

Priorize os que causam **perda de dados, corrupção, indisponibilidade, divergência de regra, falha financeira, ou impossibilidade de rollback**. Esses cinco compram atenção antes de qualquer outro; os demais podem ser aceitos com registro.

Risco aceito é decisão legítima — mas precisa estar escrito como aceito, e por quem.

## Rollback

Cada fase relevante responde cinco perguntas. A quarta e a quinta são as que faltam nos planos ruins:

1. **O que pode dar errado nesta fase, especificamente?**
2. **Como detectamos** — qual sinal, em quanto tempo. Detecção que depende de reclamação de usuário não conta como detecção.
3. **Até quando podemos voltar** — a janela. Ela tem um fim concreto, e frequentemente é a primeira escrita no sistema novo.
4. **Como voltamos** — o mecanismo, em passos executáveis por alguém que não escreveu o sistema. "Reverter o deploy" só é suficiente se o dado não mudou.
5. **O que acontece com os dados** escritos no novo desde o corte. Ver `dados.md`.

"Faremos rollback se necessário" não é plano. Exija mecanismo.

**Ensaie o rollback antes de precisar dele.** Rollback nunca executado é hipótese. O ensaio revela o que o documento não revela: a credencial que ninguém tem, o passo que leva quarenta minutos, a dependência que já foi desligada.

Registre quem tem **autoridade** para acionar o rollback e como essa pessoa é acionada. Decisão sem dono, às três da manhã, atrasa o suficiente para a janela fechar.

## Observabilidade

Defina antes do corte o que será observado, e onde isso é visível:

- Erros e taxa de erro, comparada à linha de base do sistema antigo — sem linha de base medida antes, você não sabe se 2% é regressão ou normal.
- Latência (p50/p95/p99) e throughput.
- Falhas de integração, por integração.
- **Divergência entre sistemas**, quando há parallel run — a métrica mais informativa que existe durante a convivência.
- Filas e jobs: profundidade, idade da mensagem mais antiga, taxa de falha.
- Volume processado, comparado ao esperado. Queda silenciosa de volume é o sintoma de dado que parou de chegar — e não gera erro nenhum.

Meça a **linha de base no sistema antigo antes de começar**. Sem ela, toda leitura no novo é um número sem referência.

### Sinais de decisão

Defina com limiar numérico, antes do corte:

| Sinal | Critério |
|---|---|
| `CONTINUAR` | métricas dentro da linha de base, divergência abaixo do tolerado |
| `PAUSAR` | métrica degradada mas estável — para de avançar, investiga, não volta ainda |
| `ROLLBACK` | limiar de erro, perda de dado, ou divergência em regra crítica |

O estado `PAUSAR` é o que evita rollback desnecessário: a maior parte dos sustos é problema de configuração, e voltar tudo por causa disso custa a janela.

Limiar definido durante o incidente é opinião. Definido antes, é decisão.

## Definition of Done da migração

A migração termina quando o legado pode ser **desligado**, não quando o novo funciona. Percorra:

- [ ] Funcionalidades críticas migradas e validadas por quem usa
- [ ] Dados migrados e **reconciliados** — relatório do negócio batendo nos dois lados
- [ ] Integrações validadas, inclusive as dos consumidores que você não controla
- [ ] Testes de caracterização passando; suíte do sistema novo estabelecida
- [ ] Meta mensurável da Fase 0 medida e atingida
- [ ] Segurança validada — autenticação, autorização e dado sensível no novo modelo
- [ ] Observabilidade em produção, com alarme e dono
- [ ] Rollback **exercitado**, não apenas documentado
- [ ] Documentação atualizada e `docs/` refletindo o sistema novo
- [ ] Operação treinada — quem atende o incidente sabe o novo caminho
- [ ] Nenhuma dependência viva do legado, ou cada uma justificada com prazo
- [ ] Legado desligado, ou com data de desligamento acordada e dono

## Desativação do legado

Sistema legado ligado "por garantia" continua recebendo escrita por algum caminho que ninguém mapeou. Antes de desligar:

1. **Confirme que ninguém escreve** — instrumentando o legado, não presumindo. Log de escrita por período suficiente para pegar o job mensal.
2. **Confirme que ninguém lê** — inclusive relatório, planilha e script pessoal. Leitura é mais difícil de detectar que escrita e some do inventário com facilidade.
3. **Congele em modo somente leitura** por um período antes de desligar de fato. É o passo que revela o consumidor esquecido, com custo baixo — ele reclama em vez de perder dado.
4. **Arquive o dado histórico** de forma consultável, se houver obrigação legal ou de auditoria.
5. **Desligue** e mantenha a possibilidade de restaurar por um período declarado.

Registre a data de desligamento e o responsável. Migração sem data de desligamento do legado não terminou — ficou permanente, e agora há dois sistemas para manter.

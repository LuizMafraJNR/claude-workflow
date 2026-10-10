# Estratégias de migração da aplicação

Nenhuma é certa em abstrato. A escolha é uma troca entre risco e custo de convivência, e depende do estado dos testes e dos dados mais do que da tecnologia.

## As opções

### Big bang
Substitui tudo de uma vez, num corte.

Serve quando: o sistema é pequeno, a convivência é caríssima ou impossível (formato de dado incompatível), há janela de indisponibilidade aceitável, e existe backup íntegro para voltar.

Custo real: o rollback é a única mitigação, então ele precisa ser exercitado de verdade. Big bang sem ensaio de rollback é aposta.

### Migração incremental
Partes migram progressivamente; antigo e novo coexistem.

Serve quando: há fronteiras razoavelmente limpas entre módulos, e não pode haver parada.

Custo real: a convivência precisa ser construída e mantida — roteamento, sessão compartilhada, dado consistente entre os dois lados. Esse custo é frequentemente subestimado, e é permanente até a última fase.

### Strangler fig
Uma camada na frente intercepta as chamadas e as roteia progressivamente do antigo para o novo, até o antigo ficar sem tráfego.

Serve quando: há um ponto de entrada único ou poucos (HTTP, mensageria), e você quer poder voltar rota por rota.

Custo real: exige que o ponto de interceptação exista ou possa ser criado sem alterar os consumidores. Se cada consumidor precisa mudar de endereço, não é strangler fig — é migração incremental com trabalho no cliente.

### Dual run
Os dois sistemas rodam; o antigo continua sendo a fonte da verdade, e o novo processa em paralelo sem efeito visível.

Serve quando: você precisa ganhar confiança antes de cortar, e a divergência é difícil de prever por raciocínio.

Custo real: escrita duplicada e reconciliação. Cuidado com efeito colateral externo — o sistema novo não pode enviar e-mail, cobrar, ou chamar terceiro enquanto está em observação.

### Parallel run com comparação
Variante do dual run onde a saída dos dois é comparada automaticamente e a divergência é registrada.

É a estratégia mais forte que existe para validar equivalência de regra de negócio, e a única que dá evidência em vez de opinião. Exige investimento em comparador e em decidir o que é divergência aceitável (arredondamento, ordenação, timestamp).

### Branch by abstraction
Introduz uma abstração no código atual, com duas implementações atrás dela, e alterna por configuração.

Serve quando: a troca é de dependência ou de subsistema dentro do mesmo processo — banco, provedor de storage, motor de cálculo.

Custo real: a abstração tem que caber nas duas implementações honestamente. Abstração modelada sobre a implementação antiga vaza detalhes dela e trava o alvo.

### Migração por domínio
Migra bounded contexts inteiros, um por vez.

Serve quando: o sistema tem domínios com pouca conversa entre si, e há dono de negócio por domínio para validar.

Custo real: o dado compartilhado entre domínios precisa de decisão explícita — quem passa a ser dono, e como o outro lado lê.

## Como escolher

Percorra na ordem; a primeira restrição que morder decide mais que as preferências:

1. **Pode haver indisponibilidade?** Não → elimina big bang.
2. **O rollback precisa existir depois do corte?** Sim → favorece strangler fig e branch by abstraction, onde voltar é mudar configuração.
3. **A regra de negócio é complexa e mal documentada?** Sim → parallel run é o que dá evidência de equivalência; sem ele você vai descobrir divergência por reclamação.
4. **Existe consumidor externo que você não controla?** Sim → o contrato dele é intocável nesta migração; favorece strangler fig, que preserva o endereço. **Mas verifique a que ele está acoplado antes de concluir isso** — ver abaixo.
5. **Os testes atuais cobrem o comportamento crítico?** Não → construa testes de caracterização antes, ou aceite parallel run como substituto.
6. **O dado pode ser convertido incrementalmente?** Não → a convivência é limitada pelo dado, não pelo código; reveja a estratégia de dados antes de fixar esta.
7. **Há gente suficiente para manter dois sistemas?** Não → migração incremental longa é armadilha; prefira fatiar em menos fases e mais curtas.

## Consumidor acoplado ao schema, não a um contrato

O critério 4 acima pressupõe que o consumidor externo fala com o sistema por um endereço — HTTP, mensageria, arquivo. Verifique isso, porque **quando o consumidor lê o banco diretamente, a maior parte das opções acima deixa de se aplicar**, e essa é a restrição mais dura que uma migração pode ter.

Planilha que puxa do banco, BI apontado nas tabelas, relatório com SQL próprio, integração de terceiro com usuário de leitura: nesses casos o contrato **é o schema**. Não há ponto de interceptação a criar, então strangler fig não tem onde morar; não há payload a comparar, então teste de contrato não se aplica na forma usual.

As saídas reais, em ordem de preferência:

1. **Preservar o schema antigo como uma camada de compatibilidade** — view, tabela materializada ou réplica com a forma antiga, alimentada pelo sistema novo. Compra tempo e desacopla o cronograma do consumidor do seu.
2. **Migrar o consumidor primeiro**, para uma interface de leitura de verdade, antes de tocar no sistema. Vira fase própria e frequentemente é a fase 1 — e boa fase 1, porque é reversível e ensaia a convivência.
3. **Congelar o schema antigo** em modo somente leitura com o dado do momento do corte, quando o consumo é histórico. Só serve se ele não precisa de dado novo.

Se nenhuma for viável, isso é `BLOQUEIO`, não detalhe: significa que existe um consumidor cuja quebra você não pode evitar nem detectar, e a decisão de aceitar isso é do negócio.

Um consumidor acoplado a schema que **escreve** no banco é caso mais grave ainda — trate-o como parte do sistema a migrar, não como consumidor.

Registre a escolha com a justificativa e com **as alternativas descartadas e o motivo**. Quando a migração travar no meio — e é comum — é essa lista que permite trocar de estratégia sem refazer a análise.

## Convivência tem custo físico, não só lógico

As estratégias acima descrevem a convivência em termos de roteamento e propriedade do dado. Quando os dois sistemas ficam em **ambientes diferentes** — data center da empresa e cloud, duas regiões, duas contas —, a convivência ganha restrições que nenhuma delas menciona e que decidem prazo:

- **Latência entre os dois lados**, quando uma operação atravessa a fronteira. Chamada que era local passa a ser remota; o que era imperceptível vira tempo de resposta.
- **Banda de saída** do ambiente antigo. A janela da carga inicial e da replicação contínua pode ser limitada pelo link, não pelo I/O do banco — e essa é a medição que costuma faltar.
- **Conectividade e sua confiabilidade** — VPN, link dedicado, quem opera, o que acontece quando cai. Convivência sobre conexão instável precisa de fila e reprocessamento, o que é trabalho a planejar.
- **Cliente instalado** na máquina do usuário — desktop, aplicativo, dispositivo. Ele não redeploya com o servidor: cada mudança de contrato exige atualizar a base instalada, e sempre haverá versão antiga em uso. Se ele fala direto com o banco, some isto ao problema de acoplamento a schema acima.
- **Quem opera o ambiente novo.** Se a equipe nunca operou a plataforma alvo, isso é risco de operação, não de tecnologia — e aparece no primeiro incidente, não no corte.

Meça essas restrições antes de fixar o número de fases: convivência longa sobre fronteira física custa mais do que sobre fronteira lógica, e frequentemente empurra a decisão para menos fases e mais curtas.

## Combinações comuns e legítimas

- Strangler fig na borda HTTP + branch by abstraction para o banco por trás.
- Parallel run durante as primeiras fases da incremental, desligado depois que a confiança se estabelece.
- Big bang em um domínio pequeno e não crítico, como ensaio real do processo, antes das fases grandes.

Ensaiar em algo pequeno e reversível vale mais que qualquer revisão de plano.

# Mapeamento do repositório

Objetivo: construir e manter um mapa mental do sistema, de modo que cada spec futura nasça sabendo o que já existe, quais convenções seguir e onde estão as armadilhas. Documentação aqui não é entrega burocrática — é o que evita que a próxima spec proponha reconstruir algo que já está pronto ou contradiga uma decisão tomada meses atrás.

## Validação: decidir se o mapeamento é necessário

O mapeamento completo roda uma vez por repositório. Toda invocação começa validando o que já existe — uma verificação rápida, não uma auditoria.

Leia `docs/indice.md` e `CLAUDE.md`, e confira:

1. O índice existe e tem a linha de estado do mapeamento?
2. Os documentos que ele lista existem de fato?
3. O estado registrado é razoavelmente recente — não é muito anterior às últimas entradas do `CHANGELOG.md`?
4. A stack descrita ainda bate com os manifestos do projeto (`package.json`, `pyproject.toml`, `pom.xml`, `go.mod`, `*.csproj`)?

Isso são quatro leituras. Não abra o código para validar; se as quatro respostas forem sim, o mapeamento é válido.

**Válido** — não mapeie. Leia apenas os documentos que o pedido atual toca e siga para specify. Este é o caso normal.

**Ausente** — não existe `docs/indice.md`, ou existe sem cobertura real. Faça o mapeamento completo descrito abaixo.

**Defasado** — alguma resposta foi não. Re-mapeie **apenas as áreas divergentes**: se só a stack mudou, atualize `arquitetura.md` e o `CLAUDE.md`, não o conjunto inteiro. Registre no índice o novo estado e conte ao usuário o que estava desatualizado.

Não re-varra um repositório já mapeado. O custo se paga uma vez; repetido a cada invocação, ele consome o contexto que deveria ir para o problema real.

## O que investigar no mapeamento completo

Investigue com propósito, buscando responder perguntas — não leia arquivos por leitura.

- **Stack e execução** — linguagens, frameworks, gerenciador de pacotes. Como se instala, roda, testa e faz build. Leia os manifestos (`package.json`, `pyproject.toml`, `pom.xml`, `go.mod`, `*.csproj`) e os arquivos de CI, que costumam ser a documentação mais honesta de como o projeto realmente roda.
- **Estrutura** — quais são os módulos de topo e qual a responsabilidade de cada um. O objetivo é saber onde uma mudança nova deve morar.
- **Convenções reais** — nomenclatura, organização de testes, tratamento de erro, camadas. Extraia do código que existe, não do que seria ideal; a convenção é o que o repositório pratica.
- **Regras de negócio e invariantes** — o que o sistema garante independentemente do caminho de código. Costumam estar em validações, constraints de banco, middlewares e testes.
- **Autenticação e autorização** — como identidade e permissão são resolvidas, e onde isso é aplicado.
- **Pontos de risco** — o que já quebrou (procure no CHANGELOG, em comentários de correção, em testes de regressão), o que é frágil, o que é fácil de usar errado.

## Documentos a gerar

Gere um documento **apenas para componente que existe no repositório.** Repo sem CSS não recebe `design-system.md`; API sem autenticação não recebe `autenticacao.md`. Esta lista é um catálogo de candidatos, não um checklist — três documentos densos valem mais que doze superficiais, e documento vazio ensina o leitor a não confiar em `docs/`.

Candidatos, conforme o sistema tiver:

| Arquivo | Conteúdo |
|---|---|
| `docs/indice.md` | Mapa de tudo, com a linha de estado do mapeamento. Sempre presente. |
| `docs/arquitetura.md` | Módulos, responsabilidades, como se comunicam, fluxo de uma requisição típica |
| `docs/regras-negocio.md` | Regras do domínio, ciclos de vida, invariantes, com a razão de cada uma |
| `docs/padroes-codigo.md` | Convenções praticadas, com exemplos curtos tirados do próprio repositório |
| `docs/autenticacao.md` | Identidade, sessão, perfis, onde a permissão é aplicada |
| `docs/api.md` | Endpoints ou contratos, com exemplos reais de requisição e resposta |
| `docs/dados.md` | Modelo de dados, relações, migrações, políticas de acesso a linha |
| `docs/design-system.md` | Tokens, cores, tipografia, componentes, regras de uso |
| `docs/infra.md` | Ambientes, deploy, variáveis, serviços externos |
| `docs/armadilhas.md` | Erros comuns e evitáveis, com o sintoma e a forma correta |

`docs/armadilhas.md` é o que mais se paga com o tempo e o que ninguém escreve. Cada entrada: o erro, por que é atraente, o que acontece quando se comete, o jeito certo.

O `CLAUDE.md` recebe o essencial que precisa estar em toda sessão — stack, comandos, convenções críticas, invariantes duras — e **aponta** para os documentos de `docs/` em vez de duplicá-los. Duplicação entre os dois garante divergência.

## Formato do índice

```markdown
# Índice da documentação

Estado do mapeamento: <data> — <referência do estado, ex.: commit, versão ou "CHANGELOG até 0.4.0">
Cobertura: <o que foi mapeado e o que ficou de fora, com o motivo>

| Documento | Cobre | Atualizado em |
|---|---|---|
| [arquitetura.md](arquitetura.md) | módulos e fluxo de requisição | <data> |
```

A linha de estado é o que permite detectar defasagem depois sem reler tudo.

## Manutenção

Documentação viva significa que a fase de review atualiza o que a mudança tornou falso. Ao alterar comportamento coberto por um documento, atualize o documento na mesma entrega e ajuste a data no índice. Documento que envelhece em silêncio é pior que ausente: o leitor confia nele e erra com confiança.

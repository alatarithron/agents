# Diretrizes de desenvolvimento

> Material de referência para humanos e revisões de código. Este arquivo **não** é carregado automaticamente por agentes. As regras normativas para agentes estão em [`../AGENTS.md`](../AGENTS.md) e no `AGENTS.md` de cada projeto.

Estas práticas são independentes de linguagem, com atenção especial a Elixir, JavaScript, TypeScript, PHP, Python, Rust e Ruby.

## Princípios

- Escrever código para pessoas, usando nomes que expressem intenção.
- Manter funções e módulos coesos, com responsabilidades claras.
- Preferir a implementação mais simples que atenda corretamente ao requisito.
- Evitar abstrações prematuras; generalizar somente depois de observar padrões reais.
- Reduzir duplicação de regras de negócio sem sacrificar clareza por poucas linhas repetidas.
- Separar regras de domínio de banco de dados, HTTP, arquivos, filas, frameworks e serviços externos.
- Tornar dependências e efeitos colaterais explícitos.
- Preferir imutabilidade e composição quando forem adequadas.
- Evitar estado global e dependências invisíveis.
- Comentar decisões e motivos não evidentes, não repetir o código.

## Dados, tipos e erros

- Modelar conceitos do domínio com tipos e estruturas significativas.
- Usar o sistema de tipos efetivamente; evitar `any`, casts forçados e supressões sem justificativa.
- Validar dados externos em tempo de execução mesmo quando houver tipagem estática.
- Normalizar entradas nas fronteiras e manter invariantes no domínio.
- Tratar erros esperados de forma explícita e específica.
- Não usar exceções como fluxo normal nem retornar sucesso parcial como sucesso completo.
- Definir contratos claros para funções, módulos, APIs e integrações.

## Concorrência e desempenho

- Não otimizar antes de identificar um gargalo real.
- Medir antes e depois de uma otimização relevante.
- Considerar limites de memória, CPU, disco, conexões, filas, uploads e lotes.
- Evitar consultas N+1 e carregamento sem paginação de coleções potencialmente grandes.
- Não manter transações abertas durante chamadas externas.
- Definir limites de concorrência; não disparar trabalho ilimitado.
- Considerar cancelamento, timeout, backpressure, isolamento e condições de corrida.
- Tornar operações críticas idempotentes quando puderem ser repetidas.

## Banco de dados

- Usar queries parametrizadas e constraints para proteger invariantes.
- Usar transações quando várias alterações precisarem ser atômicas.
- Criar índices com base em consultas reais.
- Considerar locks, volume de dados e tempo de execução de migrations.
- Preferir migrations reversíveis e compatíveis com implantação gradual.
- Separar alteração de schema, preenchimento de dados e remoção destrutiva quando necessário.
- Não apagar dados automaticamente para corrigir inconsistências.

## APIs e integrações

- Definir e preservar contratos claros.
- Validar requisições e respostas externas.
- Tratar timeouts, indisponibilidade, respostas inválidas e rate limits.
- Usar retries somente quando a operação for segura ou idempotente, com backoff apropriado.
- Padronizar erros e não expor detalhes internos.
- Usar paginação e limites explícitos.
- Versionar mudanças incompatíveis.
- Usar chaves de idempotência em operações críticas quando aplicável.

## Testes e automação

- Testar comportamento público, regras de negócio, casos de borda, falhas e regressões.
- Evitar testes acoplados a detalhes internos e mocks excessivos.
- Combinar testes unitários, integração, contrato e poucos fluxos ponta a ponta conforme o risco.
- Não remover, desabilitar ou enfraquecer testes para esconder problemas.
- Automatizar formatter, lint, tipos, testes, build e verificações de segurança no CI quando possível.
- Aplicar a regra especial de aprovação do usuário antes de criar testes para novas funcionalidades.

## Git e controle de versão

- Usar Conventional Commits no formato `<type>(<scope>): <description>`.
- Escrever mensagens de commit em inglês, de forma objetiva e no imperativo.
- Fazer commits pequenos, coerentes e focados em uma mudança lógica.
- Não misturar sem necessidade funcionalidade, correção, refatoração, formatação e atualização de dependências.
- Conferir o diff antes de fazer commit.
- Não usar `git add .` cegamente.
- Não versionar segredos, logs, builds, caches ou configurações locais desnecessárias.
- Versionar lockfiles de aplicações conforme a convenção do ecossistema.
- Não reescrever histórico compartilhado sem autorização específica.

## Convenções por ecossistema

### Elixir

- Usar pattern matching e retornos `{:ok, value}` / `{:error, reason}` de forma idiomática.
- Usar `with` quando tornar uma sequência de operações falíveis mais clara.
- Criar processos para concorrência ou estado, não apenas para organizar código.
- Supervisionar processos de longa duração.
- Evitar `String.to_atom/1` com entrada não confiável.
- Preferir `mix format`, ExUnit, Credo, Dialyzer e Sobelow quando aplicáveis.

### JavaScript e TypeScript

- Preferir TypeScript estrito em projetos de médio e grande porte.
- Usar `unknown` e narrowing em fronteiras desconhecidas, não `any`.
- Diferenciar conscientemente `undefined`, `null`, vazio e ausência.
- Evitar coerção implícita e misturas desnecessárias de callbacks, Promises e `async/await`.
- Validar dados externos em runtime.
- Limitar concorrência assíncrona em grandes coleções.
- Usar as ferramentas já escolhidas pelo projeto, como ESLint, Prettier, Biome, Vitest, Jest ou Playwright.

### PHP

- Usar `declare(strict_types=1)` quando compatível com o projeto.
- Declarar tipos de parâmetros, propriedades e retornos.
- Preferir objetos de dados a arrays associativos genéricos para contratos importantes.
- Usar Composer, namespaces e autoloading PSR.
- Preferir classes `final` quando não forem projetadas para herança.
- Usar exceções específicas e análise estática com PHPStan ou Psalm quando aplicável.

### Python

- Escrever Python idiomático, preferindo funções e módulos simples antes de hierarquias complexas.
- Usar context managers, dataclasses, type hints e `pathlib` quando apropriados.
- Evitar argumentos mutáveis como valor padrão.
- Capturar exceções específicas.
- Usar `Decimal` ou inteiros na menor unidade para dinheiro.
- Preferir a configuração existente do projeto para Ruff, Black, mypy, Pyright e pytest.

### Rust

- Modelar estados inválidos como impossíveis usando tipos e enums.
- Usar `Result`, `Option` e o operador `?` conscientemente.
- Evitar `unwrap()` e `expect()` em produção sem uma invariante demonstrada.
- Não usar `clone()` apenas para contornar o modelo de ownership.
- Minimizar e isolar `unsafe`, documentando suas invariantes.
- Usar `cargo fmt`, `cargo clippy`, `cargo test`, `cargo audit` e `cargo deny` quando aplicáveis.

### Ruby

- Escrever Ruby idiomático sem sacrificar clareza por concisão.
- Usar `?` para consultas e `!` de forma consistente.
- Evitar callbacks que escondam fluxos importantes.
- Não concentrar toda a regra de negócio em modelos Active Record.
- Preferir keyword arguments em chamadas com vários parâmetros.
- Usar RuboCop, RSpec ou Minitest, Brakeman e Bundler Audit conforme o projeto.

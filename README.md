# Agents :: Diretrizes padrão para IAs e agentes

Minha base pessoal para trabalhar com assistentes de IA e agentes de código.

Aqui eu concentro três coisas:
- minhas preferências canônicas de trabalho
- templates para adotar esse padrão em outros repositórios
- material de referência para manter tudo consistente

Não é um repositório pensado como produto ou framework para comunidade.
É mais um espaço pessoal, público por transparência, que eu uso para organizar como quero que agentes trabalhem comigo e dentro dos meus projetos.

## O que tem aqui

```text
agents/
├── AGENTS.md
├── wire.sh
├── adopt.sh
├── check.sh
├── test-check.sh
├── test-scripts.sh
├── template-diff.sh
├── templates/
│   ├── README.md
│   ├── AGENTS.project.md
│   ├── PROJECT_MEMORY.md
│   ├── BOOTSTRAP.md
│   ├── DECISION.md
│   └── skills/
└── reference/
    ├── DEVELOPMENT-GUIDELINES.md
    ├── SECURITY-AND-PRIVACY.md
    └── PROJECT-MEMORY-POLICY.md
```

## Como eu uso

### 1. Fiação global

```bash
./wire.sh
```

Esse script conecta o `AGENTS.md` canônico deste repositório aos arquivos globais lidos por ferramentas como Claude Code, Codex CLI, Gemini CLI e Hermes.

A ideia é simples: manter um único ponto de verdade para minhas preferências pessoais.

### 2. Adoção por projeto

```bash
./adopt.sh <caminho-do-projeto>
```

Esse script prepara um repositório para seguir a mesma estrutura, criando:
- `AGENTS.md` na raiz
- `CLAUDE.md` apontando para ele
- `.agents/PROJECT_MEMORY.md`
- `.agents/decisions/`
- `.agents/BOOTSTRAP.md`, roteiro de primeira sessão
- `.agents/TEMPLATE_ORIGIN`, registro da origem dos arquivos instalados
- `.agents/skills/`, procedimentos de simplificação, investigação de bugs e revisão pré-commit

Sem sobrescrever arquivos, diretórios ou symlinks existentes. Adoção instala a estrutura; não declara o projeto pronto. Na primeira sessão, peça ao agente para seguir `.agents/BOOTSTRAP.md`: investigar o projeto, preencher somente fatos verificados, remover exemplos e executar as validações aplicáveis. Depois, o bootstrap não precisa ser carregado rotineiramente.

Regras ficam em `AGENTS.md`; fatos e comandos, em `.agents/PROJECT_MEMORY.md`; motivos de decisões, em `.agents/decisions/`. Projetos sem decisões ainda podem manter esse diretório vazio.

Os scripts usam Bash e utilitários GNU em Linux. Git permite verificar exclusões efetivas e recuperar revisões dos templates; ShellCheck é usado no desenvolvimento e no CI.

### 3. Verificação

```bash
./check.sh <caminho-do-projeto>
```

Confere um projeto adotado contra a política: estrutura no lugar, placeholders do template já preenchidos, entradas de memória dentro do limite de forma, decisões cruzadas com a memória (sem órfãs nem links quebrados), baseline de teste com data, e nenhuma string com cara de credencial nos arquivos de instrução.

Somente leitura — reporta, nunca edita. Sai com 1 em erro, 0 em aviso. Os limites de tamanho podem ser ajustados: `MEM_WARN=400 MEM_FAIL=1200 ./check.sh <projeto>`.

```bash
./test-check.sh
./test-scripts.sh
shellcheck ./*.sh
```

Cada caso monta um projeto de mentira, quebra exatamente uma coisa e exige que o `check.sh` reporte — mais um caso que não quebra nada e exige silêncio. Um check que para de ler continua imprimindo `ok`, e isso é indistinguível de um check que funciona.


### 4. Comparação dos templates

```bash
./template-diff.sh <caminho-do-projeto>
```

Comparação somente leitura, sem sincronização automática. O registro de origem distingue arquivos instalados pelo kit de arquivos preexistentes. Revise diferenças antes de incorporar uma regra: customizações locais não são defeitos e têm precedência. Projetos antigos sem registro não recebem uma origem inventada.

`.agents/TEMPLATE_ORIGIN` é texto separado por TAB: cabeçalho `template-origin-v1`, linha `revision<TAB><HEAD ou unknown>` e linhas `file<TAB><destino relativo><TAB><template relativo><TAB><blob ID ou unknown>`. O blob identifica os bytes copiados, inclusive mudanças ainda não commitadas; a revisão identifica o HEAD do kit, não garante que o template estava limpo.

O manifesto existente nunca é atualizado na readoção. Arquivos acrescentados depois podem ficar sem baseline; isso é reportado, não preenchido por suposição. Se o blob estiver disponível no Git local do kit, a comparação separa mudanças locais de mudanças do template. Caso contrário, mostra apenas template atual versus arquivo adotado. Não faz fetch nem escreve objetos Git. Diferenças são informativas e retornam 0; erros operacionais retornam não zero.

### Skills por projeto

O diretório canônico é `.agents/skills/`, não `.skills/` na raiz. O Codex documenta descoberta nesse caminho; outros agentes podem ler os arquivos explicitamente pelo ponteiro no `AGENTS.md`. Não presumimos descoberta nativa universal nem instalamos nada nos diretórios globais das ferramentas.

O conjunto inicial é enxuto:
- `code-simplifier`: uma passagem delimitada sobre o código da tarefa, preservando comportamento, antes da validação final.
- `debugging`: reprodução e evidência antes da correção.
- `pre-commit-review`: revisão e validação antes de um commit autorizado.

Essas skills são implementações próprias deste kit. O [repositório sugerido](https://github.com/lyen1688/code-simplifier), revisado na revisão `b6c8c2a027236e33f76573c280a9418ee1445889`, serviu como referência de objetivo, não como conteúdo copiado: não declara licença e seu procedimento inclui preferências específicas de JavaScript/React e simplificação proativa.

Cada skill declara gatilho, procedimento, limites e verificação. Leia somente a que se aplica. Skills extras devem responder a uma necessidade real e ter origem, licença e permissões revisadas; adoção não baixa código remoto nem executa instaladores.

Referências de descoberta: [Codex](https://developers.openai.com/codex/skills/) e [Claude Code](https://code.claude.com/docs/en/skills). A leitura explícita é o fallback portátil; esta alteração não é um teste de integração dos CLIs.

### Validação contínua

O workflow `.github/workflows/validate.yml` executa sintaxe Bash, ShellCheck, as duas suítes e a verificação deste repositório. Os testes de instalação usam projetos temporários e HOME isolado; não conectam suas ferramentas reais.

`check.sh` valida estrutura e heurísticas, não a veracidade da memória, segurança completa ou correção da aplicação. Um resultado verde não substitui testes do projeto nem sua aprovação manual.

## Prioridade das instruções

Quando houver conflito:
1. pedido explícito e atual do usuário
2. regras específicas do projeto
3. preferências pessoais deste repositório
4. convenções da ferramenta

## Idioma

Cada camada tem um idioma fixo:

- **Português**: este `README.md` e `reference/`. São material meu e para leitura humana.
- **Inglês**: `AGENTS.md` e `templates/`. São artefatos que vivem dentro de repositórios de código, junto com commits, identificadores e documentação técnica.

A regra que os agentes seguem é a mesma: falam comigo em português, escrevem código e artefatos técnicos em inglês.

## Escopo

Este repositório não é memória de projeto.
Ele não deve guardar credenciais, tokens, segredos, fatos temporários ou contexto específico de um único repositório.

## Futuro

Com o tempo, quero evoluir este espaço com calma:
- melhorar os templates
- refinar as regras com base no uso real
- manter decisões e memória de projeto mais organizadas
- reduzir atrito entre ferramentas diferentes

Um tijolo por vez.

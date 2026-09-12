# Política de memória por projeto

> Referência completa da política. O resumo operacional que os agentes seguem está na seção "Project memory" de [`../AGENTS.md`](../AGENTS.md) e no `AGENTS.md` de cada projeto.

## Objetivo

A memória de um projeto deve acompanhar o código entre computadores, clones, branches e agentes. Por isso, ela deve existir dentro do repositório e ser versionada junto com ele.

Memória de projeto é documentação técnica durável. Não é histórico de conversa, log de execução nem lista temporária de tarefas.

## Localização padrão

```text
<project>/
├── AGENTS.md
└── .agents/
    ├── PROJECT_MEMORY.md
    ├── skills/
    │   └── <name>/SKILL.md
    └── decisions/
        └── NNN-short-title.md
```

- `AGENTS.md`: regras operacionais que o agente deve aplicar imediatamente.
- `.agents/PROJECT_MEMORY.md`: fatos estáveis e contexto reutilizável do projeto.
- `.agents/decisions/`: decisões arquiteturais ou operacionais que precisam de contexto, alternativas e consequências.
- `.agents/skills/`: procedimentos reutilizáveis, carregados conforme a tarefa; não fatos nem estado temporário.
- `.agents/BOOTSTRAP.md`: roteiro de adoção, fora da leitura recorrente. `.agents/TEMPLATE_ORIGIN`: proveniência inerte dos arquivos instalados, nunca comandos a executar.

A memória não deve existir apenas em bancos globais da ferramenta, diretórios pessoais, sessões de chat ou serviços externos. Esses mecanismos podem servir como cache ou conveniência, mas o repositório é a fonte de verdade para contexto específico do projeto.

## O que registrar

Registrar fatos estáveis que reduzam a necessidade de redescoberta:

- objetivo e limites do projeto;
- arquitetura e responsabilidades dos componentes;
- termos importantes do domínio;
- decisões arquiteturais vigentes e seus motivos;
- convenções que não estejam evidentes nas ferramentas do projeto;
- comandos reais de instalação, execução, teste, lint e build;
- dependências externas relevantes e seus contratos;
- requisitos de compatibilidade e ambiente;
- invariantes de dados e regras de negócio importantes;
- procedimentos de desenvolvimento ou validação já confirmados;
- armadilhas recorrentes e limitações conhecidas;
- localização da documentação canônica.

Escrever fatos de forma declarativa, objetiva e verificável. Sempre que possível, apontar para arquivos, documentação ou decisões versionadas.

## Forma da entrada

Uma entrada de memória é **um fato com um ponteiro**, não um parágrafo. O limite operacional é por unidade, não por arquivo:

- Cada item de lista ou célula de tabela cabe em cerca de 300 caracteres.
- O que não couber tem outro lugar: o porquê vai para `decisions/`, o detalhe de implementação vai para o doc comment do módulo, e a memória fica com a frase que aponta para lá.
- Não escrever prosa corrida dentro de célula de tabela. Uma célula que cresceu por acréscimo é um sinal de que o assunto virou uma decisão.

O motivo é operacional, não estético: uma entrada curta é editável, e uma linha de milhares de caracteres não é. Quando atualizar custa reescrever um bloco enorme, a memória para de ser atualizada e passa a acumular — que é exatamente o que a política proíbe. `check.sh` mede esse limite.

### O modo como isso quebra, com nome e número

⚠️ **A entrada de estado atual é a que cresce por acréscimo.** O padrão é sempre o mesmo: um item chamado `Current state:` / `Estado atual:` que ninguém reescreve, só acrescenta, a cada feature entregue. Cada acréscimo é pequeno e razoável; a soma não é.

Um projeto real deste ecossistema chegou a **uma única linha de 77.609 caracteres** — 59 % de um `PROJECT_MEMORY.md` de 132 KB, com 62 carimbos de data dentro. Era um changelog em prosa, e o Git e os 40 registros de decisão já guardavam a mesma cronologia.

Três coisas que essa falha ensina:

- **Data dentro de uma entrada é sinal de changelog.** Se a frase precisa dizer _quando_, o lugar dela é `decisions/`, não a memória.
- **O limite de FAIL é rede de segurança, não alvo.** O alvo é ~300 caracteres por entrada. Um projeto que aceita 1.200 está dizendo que quatro vezes o limite é tolerável, e foi assim que uma entrada passou dos setenta mil sem que nada reclamasse.
- **Antes de apagar, confirme que o fato tem outra casa.** Quase sempre a memória é a _terceira_ cópia — depois do comentário do módulo e do registro de decisão — e é a única que envelhece. Confirmar isso em uma amostra é o que torna a limpeza segura em vez de corajosa.

## O que não registrar

Não registrar:

- senhas, tokens, cookies, chaves ou outras credenciais;
- dados pessoais ou conteúdo real de produção;
- conteúdo de `.env` ou configurações locais sensíveis;
- estado momentâneo de uma tarefa;
- “próximos passos” de uma sessão;
- resultados isolados de testes, builds ou CI — ver a ressalva sobre baselines abaixo;
- números de PR, commits ou branches usados apenas em uma tarefa passageira;
- transcrições de conversas;
- hipóteses não verificadas apresentadas como fatos;
- informações que já estão claras e canônicas em outro arquivo, sem necessidade de índice ou contexto adicional;
- inventário de funcionalidades: a lista do que a interface ou a API faz hoje, tela por tela, opção por opção. Isso se lê no código, muda a cada semana e envelhece mais rápido que qualquer outra coisa na memória. Registrar o que **não** se lê no código: a fronteira, o invariante, o motivo.

Use issues, pull requests, planos de trabalho ou o sistema de tarefas para informações temporárias.

### Baseline não é resultado de execução

Um **resultado** responde "passou agora?" e é descartável: a saída de uma execução, o link de um run de CI, a captura de um build. Não entra na memória.

Um **baseline** responde "o que se espera encontrar?" e é durável, porque é falseável: se a contagem esperada era 181 e hoje dá 174, alguma coisa se perdeu, e a memória é o que permite perceber isso. Registrar um baseline exige o que o torna honesto — **data e ambiente junto do número**:

```text
Verificado em 2026-08-24, Rust 1.98.0: `cargo test --workspace` (181 testes verdes);
`cargo fmt --all --check` reporta diferenças hoje — não reformatar fora da tarefa.
```

Pela mesma razão, o inventário do que **ainda não foi exercitado** é memória legítima: não é lista de tarefas, é risco conhecido, e desaparece sozinho quando o fluxo for exercitado. Escrever como risco ("nunca rodado na aplicação: X, Y"), nunca como plano ("falta fazer X").

Um baseline sem data é um resultado disfarçado. Se não der para dizer quando e onde foi verificado, não registrar.

### Relatórios e auditorias datados

Relatórios de pentest, auditoria, benchmark ou análise não são memória nem decisão: são observações com prazo de validade, verdadeiras na data em que foram feitas e frequentemente falsas depois.

- Eles vivem fora de `.agents/`, no diretório que a ferramenta usar, versionados quando o relatório for o que alguém vai ler depois.
- A memória os referencia dizendo **de quando são** e **o que já mudou desde então**.
- Quando um achado for corrigido, registrar a correção junto da referência, em vez de deixar o relatório contradizer o código em silêncio.

Sem isso, quem abrir o relatório meses depois reabre um achado que já foi resolvido.

## Atualização

- Atualizar a memória no mesmo conjunto de alterações que tornar uma informação anterior incorreta.
- Remover ou substituir conteúdo obsoleto; não acumular notas contraditórias.
- Registrar decisões importantes no momento em que forem confirmadas.
- Preservar o histórico por meio do Git, em vez de manter seções como “antigo” ou “alterado em”.
- Revisar a memória durante mudanças arquiteturais, de ambiente, ferramentas ou fluxo de validação.
- Manter o arquivo principal curto e navegável; mover explicações longas para `decisions/`.

## O portão

⚠️ **`check.sh` rodado à mão é um check que ninguém lembra.** A política pode estar escrita, o script pode estar certo, e as duas coisas juntas não impedem nada se a falha só aparece quando alguém resolve olhar. No caso acima o script vinha diagnosticando a linha de 77.609 caracteres corretamente havia quarenta commits — bastava que alguém o executasse.

- O `adopt.sh` instala `.github/workflows/agent-policy.yml`, que roda o check a cada push e a cada PR.
- O kit entra **fixado num commit**, nunca num branch: o script é a definição do portão, e uma definição que se move por push de outro repositório deixa este vermelho sem nada no histórico daqui que explique.
- Os limites (`MEM_WARN`, `MEM_FAIL`) ficam **no workflow do projeto**, não nos defaults do kit — é ali que cada projeto declara o quão apertada mantém a própria memória, e afrouxar vira um diff com autor e data.

## Responsabilidade dos agentes

Ao iniciar trabalho em um projeto, o agente deve:

1. Ler `AGENTS.md`.
2. Ler `.agents/PROJECT_MEMORY.md`, se existir.
3. Consultar decisões relacionadas à tarefa.
4. Verificar no código e nas ferramentas se a memória continua correta.
5. Tratar o repositório como fonte de verdade quando houver conflito com memória externa.

Ao descobrir contexto durável, o agente pode propor ou realizar uma atualização da memória dentro do escopo autorizado. Alterar código não autoriza commit ou push.

O agente não deve salvar memória específica do projeto apenas em memória global. Se uma ferramenta mantiver memória própria, ela deve conter no máximo preferências pessoais gerais e um lembrete de que a fonte canônica do projeto está no repositório.

## Versionamento

- `AGENTS.md`, `.agents/PROJECT_MEMORY.md`, `.agents/decisions/` e skills adotadas devem ser rastreados pelo Git. Versionar também `.agents/TEMPLATE_ORIGIN` quando presente; ele permite revisar a origem dos templates sem sincronização automática.
- Eles não devem ser adicionados ao `.gitignore`.
- Alterações de memória devem ser revisadas como qualquer outra alteração técnica.
- Commits que incluam memória devem seguir a mesma política do projeto.
- Nenhum commit ou push deve ser executado sem ordem explícita do usuário.

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
    └── decisions/
        └── NNN-short-title.md
```

- `AGENTS.md`: regras operacionais que o agente deve aplicar imediatamente.
- `.agents/PROJECT_MEMORY.md`: fatos estáveis e contexto reutilizável do projeto.
- `.agents/decisions/`: decisões arquiteturais ou operacionais que precisam de contexto, alternativas e consequências.

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

## O que não registrar

Não registrar:

- senhas, tokens, cookies, chaves ou outras credenciais;
- dados pessoais ou conteúdo real de produção;
- conteúdo de `.env` ou configurações locais sensíveis;
- estado momentâneo de uma tarefa;
- “próximos passos” de uma sessão;
- resultados isolados de testes, builds ou CI;
- números de PR, commits ou branches usados apenas em uma tarefa passageira;
- transcrições de conversas;
- hipóteses não verificadas apresentadas como fatos;
- informações que já estão claras e canônicas em outro arquivo, sem necessidade de índice ou contexto adicional.

Use issues, pull requests, planos de trabalho ou o sistema de tarefas para informações temporárias.

## Atualização

- Atualizar a memória no mesmo conjunto de alterações que tornar uma informação anterior incorreta.
- Remover ou substituir conteúdo obsoleto; não acumular notas contraditórias.
- Registrar decisões importantes no momento em que forem confirmadas.
- Preservar o histórico por meio do Git, em vez de manter seções como “antigo” ou “alterado em”.
- Revisar a memória durante mudanças arquiteturais, de ambiente, ferramentas ou fluxo de validação.
- Manter o arquivo principal curto e navegável; mover explicações longas para `decisions/`.

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

- `AGENTS.md`, `.agents/PROJECT_MEMORY.md` e `.agents/decisions/` devem ser rastreados pelo Git.
- Eles não devem ser adicionados ao `.gitignore`.
- Alterações de memória devem ser revisadas como qualquer outra alteração técnica.
- Commits que incluam memória devem seguir a mesma política do projeto.
- Nenhum commit ou push deve ser executado sem ordem explícita do usuário.

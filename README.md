# Diretrizes padrão para IAs e agentes

Fonte canônica das minhas preferências pessoais para assistentes de IA e agentes de código, dos templates de adoção por projeto e do material de referência.

Nenhuma ferramenta lê este diretório automaticamente. O que as ferramentas leem são os pontos de fiação descritos abaixo — arquivos globais por ferramenta e o `AGENTS.md` na raiz de cada repositório. Este repositório existe para ser a **única fonte** por trás desses pontos.

## Estrutura

```text
agents/
├── AGENTS.md                    # Preferências pessoais canônicas (autossuficiente)
├── wire.sh                      # Cria os symlinks globais por ferramenta
├── adopt.sh                     # Adota a estrutura em um projeto
├── templates/
│   ├── AGENTS.project.md        # Template de AGENTS.md para a raiz de um projeto
│   ├── PROJECT_MEMORY.md        # Template de memória de projeto
│   └── DECISION.md              # Template de registro de decisão (ADR)
└── reference/                   # Material para humanos e revisões; não é carregado por agentes
    ├── DEVELOPMENT-GUIDELINES.md
    ├── SECURITY-AND-PRIVACY.md
    └── PROJECT-MEMORY-POLICY.md
```

Cada arquivo consumido por agentes é deliberadamente autossuficiente. A redundância entre `AGENTS.md` (global) e `templates/AGENTS.project.md` (por projeto) é intencional: um agente que leia apenas um dos dois ainda se comporta corretamente. Ao alterar uma regra que exista nos dois, altere os dois — eles vivem neste mesmo repositório justamente para serem editados juntos.

## Fiação global por ferramenta

Execute uma vez (e novamente após instalar uma ferramenta nova):

```bash
./wire.sh
```

O script cria symlinks do arquivo canônico para os locais globais que cada ferramenta lê:

| Ferramenta | Arquivo global lido | Fiação |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | symlink → `AGENTS.md` daqui |
| OpenAI Codex CLI | `~/.codex/AGENTS.md` | symlink → `AGENTS.md` daqui |
| Gemini CLI | `~/.gemini/GEMINI.md` | symlink (criado se `~/.gemini` existir) |
| Hermes | `~/.hermes/SOUL.md` (persona) | ponteiro anexado ao final do `SOUL.md`; o `AGENTS.md` de cada projeto é descoberto nativamente |
| Outras | varia | aponte o arquivo global/system prompt da ferramenta para `AGENTS.md` daqui |

Com isso, as preferências pessoais valem em **qualquer** diretório, mesmo em projetos ainda não adotados. Editar o arquivo canônico atualiza todas as ferramentas de uma vez; os symlinks também fazem edições feitas pela ferramenta (ex.: `/memory` no Claude Code) caírem aqui, versionáveis.

Ferramentas sem configuração global, mas que seguem o padrão [AGENTS.md](https://agents.md) (Cursor, Zed, Jules, entre outras), são cobertas pelo `AGENTS.md` na raiz de cada projeto adotado.

## Adoção em um projeto

```bash
./adopt.sh <caminho-do-projeto>
```

O script cria, sem sobrescrever nada existente:

```text
project/
├── AGENTS.md                # copiado de templates/AGENTS.project.md
├── CLAUDE.md                # symlink relativo → AGENTS.md
└── .agents/
    ├── PROJECT_MEMORY.md    # copiado de templates/PROJECT_MEMORY.md
    └── decisions/
```

Depois de rodar o script:

1. Preencha a seção "Repository-specific information" do `AGENTS.md` com fatos reais e remova os placeholders.
2. Preencha `.agents/PROJECT_MEMORY.md` apenas com fatos verificados.
3. Confirme que `.agents/` não está no `.gitignore`.
4. Versione `AGENTS.md`, `CLAUDE.md` e `.agents/` com o restante do projeto.

`AGENTS.md` fica na raiz porque é o padrão reconhecido por múltiplos agentes. A memória fica em `.agents/` dentro do repositório para acompanhar clones, branches e máquinas.

## Prioridade das instruções

Quando houver conflito:

1. Pedido explícito e atual do usuário.
2. Regras específicas do projeto (`AGENTS.md` e memória do repositório).
3. Preferências pessoais (`AGENTS.md` deste repositório).
4. Convenções padrão da ferramenta ou do agente.

Uma regra mais específica e recente substitui uma regra geral anterior.

## Escopo

Este repositório guarda preferências pessoais, templates e referência. Ele não substitui a memória de cada projeto e não deve armazenar fatos específicos de um repositório, credenciais, tokens, dados pessoais ou informações temporárias.

# agents

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
├── templates/
│   ├── AGENTS.project.md
│   ├── PROJECT_MEMORY.md
│   └── DECISION.md
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

Sem sobrescrever o que já existe.

## Prioridade das instruções

Quando houver conflito:
1. pedido explícito e atual do usuário
2. regras específicas do projeto
3. preferências pessoais deste repositório
4. convenções da ferramenta

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

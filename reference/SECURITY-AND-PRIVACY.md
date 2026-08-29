# Segurança e privacidade no desenvolvimento

> Material de referência para humanos e checklist de revisão de segurança. Este arquivo **não** é carregado automaticamente por agentes. As regras normativas para agentes estão em [`../AGENTS.md`](../AGENTS.md) e no `AGENTS.md` de cada projeto.

Segurança protege sistemas e informações contra acesso, alteração, destruição, indisponibilidade e abuso. Privacidade limita a coleta e o uso de dados pessoais à finalidade necessária. Um sistema pode ser seguro e ainda violar a privacidade.

## Princípios

- Aplicar segurança e privacidade desde requisitos, design e implementação até deploy e operação.
- Negar acesso por padrão e conceder somente o mínimo necessário.
- Diferenciar autenticação de autorização e verificar ambas no servidor.
- Tratar entradas, identidades, redes, dependências e configurações como não confiáveis.
- Coletar e manter somente os dados necessários para uma finalidade definida.
- Considerar abuso da regra de negócio, não apenas ataques técnicos.
- Usar controles em profundidade; não depender de uma única camada.

## Entradas, saídas e execução

- Validar tipo, formato, tamanho, intervalo, valores permitidos e relações entre campos.
- Validar dados assim que entram no sistema.
- Usar queries parametrizadas.
- Passar argumentos de processos separadamente e evitar shell quando não for necessário.
- Evitar `eval`, `exec`, desserialização insegura e carregamento dinâmico controlado por entrada externa.
- Fazer escaping conforme o contexto de saída: HTML, atributo, URL, SQL, shell, CSV ou XML.
- Sanitizar HTML de usuário somente com biblioteca consolidada e política restritiva.
- Proteger caminhos contra traversal e não confiar em nomes de arquivos enviados pelo usuário.

## Autenticação, autorização e sessões

- Validar autorização por recurso e operação em cada requisição.
- Não confiar em IDs, roles ou permissões fornecidos pelo cliente.
- Evitar enumeração de contas e vazamento entre usuários ou tenants.
- Armazenar senhas apenas com mecanismo consolidado e apropriado, preferencialmente Argon2id em sistemas novos.
- Usar tokens curtos, revogáveis e de uso único quando necessário.
- Não colocar tokens em URLs nem logs.
- Proteger cookies com `HttpOnly`, `Secure` e `SameSite` apropriado.
- Rotacionar sessões após autenticação e revogá-las em eventos críticos.
- Exigir reautenticação ou MFA para operações de alto risco quando aplicável.

## Segredos e criptografia

- Nunca colocar senhas, tokens, chaves, certificados privados ou strings de conexão no código, commits, imagens, logs, exemplos ou prompts externos.
- Usar variáveis de ambiente ou gerenciador de segredos com acesso mínimo, rotação, revogação e auditoria.
- Se um segredo for versionado, considerá-lo comprometido: revogar, substituir, investigar e remover do histórico quando necessário.
- Não implementar criptografia própria.
- Usar bibliotecas e algoritmos consolidados, modos autenticados e fontes aleatórias criptograficamente seguras.
- Separar chaves dos dados protegidos.
- Usar TLS e não desativar validação de certificados para contornar erros.

## Erros, logs e observabilidade

- Não expor stack traces, SQL, caminhos, versões, tokens ou detalhes de infraestrutura ao usuário.
- Retornar erros estáveis e úteis, com códigos apropriados.
- Registrar contexto técnico suficiente sem incluir dados sensíveis.
- Nunca registrar senhas, tokens, cookies, chaves, cartões completos ou payloads sensíveis.
- Mascarar ou pseudonimizar identificadores quando necessário.
- Proteger logs contra acesso, alteração e exclusão indevidos.
- Definir retenção de logs de acordo com a finalidade.

## Uploads, APIs e SSRF

- Limitar tamanho e tipos permitidos de uploads.
- Validar o conteúdo, gerar nomes de armazenamento e impedir execução.
- Armazenar uploads fora da raiz pública quando aplicável.
- Proteger downloads com autorização.
- Limitar tamanho de requests, paginação, filtros, concorrência e tentativas.
- Aplicar rate limits, quotas, timeouts e idempotência em operações sensíveis.
- Validar assinaturas, timestamps e replay de webhooks.
- Não buscar URLs arbitrárias fornecidas por usuários.
- Restringir protocolos e hosts, bloquear redes privadas, limitar redirecionamentos e aplicar política de egress contra SSRF.

## Dependências, CI e infraestrutura

- Versionar lockfiles e remover dependências não utilizadas.
- Avaliar manutenção, licença, origem e vulnerabilidades antes de adicionar uma dependência.
- Tratar scripts de instalação como código executável.
- Fixar versões de actions e imagens quando apropriado.
- Aplicar permissões mínimas ao CI e proteger secrets de código vindo de forks.
- Usar branch protection, revisão, CI obrigatório, secret scanning e análise de dependências quando disponíveis.
- Separar desenvolvimento, homologação e produção com credenciais, dados e permissões distintas.
- Não copiar dados reais de produção para ambientes inferiores sem anonimização e controle adequados.

## Privacidade e LGPD

- Documentar finalidade, categorias de dados, titulares, base legal, compartilhamentos, retenção, controles e responsável.
- Não presumir que consentimento é sempre a base legal adequada.
- Implementar ciclo de vida para coleta, uso, retenção, exclusão ou anonimização.
- Diferenciar pseudonimização de anonimização; dados pseudonimizados continuam protegidos.
- Permitir acesso, correção, exportação, exclusão e gestão de preferências quando aplicável.
- Verificar a identidade antes de exportar ou excluir dados.
- Não enviar dados pessoais automaticamente para analytics, telemetria ou outros terceiros.
- Informar quando uma solução compartilhar dados com serviços externos.
- Validar juridicamente interpretações de LGPD quando a decisão depender do caso concreto.

## Verificação

Antes de publicar, verificar pelo menos:

1. Entradas e respostas externas são validadas?
2. Todas as operações possuem autorização adequada?
3. Queries e comandos estão protegidos contra injeção?
4. Senhas, tokens, cookies e segredos estão protegidos?
5. Logs e erros evitam dados sensíveis?
6. Uploads, URLs externas e webhooks têm controles de abuso?
7. Dependências e pipeline usam versões e privilégios adequados?
8. A coleta de dados é necessária, transparente e possui retenção definida?
9. Existem testes ou verificações negativas proporcionais ao risco?
10. Credenciais podem ser revogadas e dados podem ser restaurados ou excluídos com segurança?

Nenhum scanner substitui revisão e análise contextual.

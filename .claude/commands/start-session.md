---
description: Bootstrap da sessao. Com item "a confirmar" na stack (ou o argumento stack) entrevista o sponsor e grava em .memory/project_stack.md; depois, git sync + contexto enxuto + briefing ativo do arquiteto.
allowed-tools: Bash(git status:*), Bash(git fetch:*), Bash(git pull:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git merge-base:*), Bash(gh pr list:*), Read, Glob, Grep, AskUserQuestion, Write, Edit
---

Bootstrap da Crew build (IMAN Terra, fork do QGIS). Rode as fases em ordem.

**Phase 0 - STACK (so com o argumento `stack`)**

Os itens `a confirmar` da stack desta Crew (build local, instalador, testes, gate) sao MEDIDOS pela fatia de
fundacao e gravados por ela, nao perguntados na abertura. Sem o argumento `stack`, pule para a Phase 1.

Com o argumento `stack`: mostre o `project_stack.md` atual, pergunte por `AskUserQuestion` (pergunta aberta) o que
muda, mostre o diff e peca confirmacao antes de sobrescrever. Diga ao sponsor, em uma linha, o que falta fora desta
Crew: registrar o gate no harness do arquiteto (kind `qgis-build` no `crew_gate.sh`) e copiar
`.claude/settings.local.json.example` para `.claude/settings.local.json` se ainda nao houver.

A Phase 0 escreve SO o `project_stack.md`. Nao instala dependencia, nao compila, nao commita.

**Phase 1 - INSPECT** (sempre, so leitura)
- `git status --porcelain`; `git rev-parse --abbrev-ref --symbolic-full-name @{u}` (tolerar falha);
  `git fetch origin --prune` (nunca `--all`: o remoto `upstream` e o QGIS inteiro); `git status -sb`.
  Anuncie o estado em uma linha.

**Phase 2 - PULL** (so com arvore limpa, atras, nao a frente, com upstream)
- `git pull --ff-only`. Senao, pule e diga o motivo (sujo / divergente / sem upstream).
- Branch de fatia ja mergeada em `origin/develop` (`git merge-base --is-ancestor HEAD origin/develop`): diga que o
  checkout esta parado numa fatia entregue e que a proxima nasce de `origin/develop`.

**Phase 3 - CONTEXTO ENXUTO** (sempre)
- O `CLAUDE.md` ja esta carregado e importa o `project_stack.md`. Leia `.memory/MEMORY.md`, todos os
  `.memory/feedback_*.md` e o `.memory/reference_build_environment.md` (a bancada de build desta maquina).
- **Nao** leia documento grande inteiro (`iman/docs/**`, a forense do arquiteto). Sob demanda: `Grep` pelo ID da
  fatia do briefing ativo e leia so o trecho encontrado.

**Phase 3b - BRIEFING ATIVO** (sempre, so leitura)
- `Glob` em `../iman-product-architect/.memory/briefings/*_qgis-build_*.md`; escolha o de data mais alta no NOME
  (`YYYY-MM-DD`) e, no empate, o `NNN` mais alto. Nao pelo mtime.
- Leia-o inteiro e extraia: base (branch + SHA), o que fazer, testes, STOP, fora de escopo, como entregar.
- Compare HEAD com a base: bate -> `pronto`; avancou N -> `ja aplicou N commits, conferir com o briefing`; outra
  branch -> `divergente`; sujo -> listar.
- **Confira o briefing contra o CODIGO antes de confiar no status** do cabecalho: procure os artefatos que ele
  prescreve; existindo, classifique `ja aterrado`.
- `gh pr list --author @me --state open`: PR aberto para a branch -> `fase de smoke/review, nao de aplicacao`.

**Phase 4 - RESUMO**
- Uma linha por fase. Comece pelo sinal mais relevante (briefing novo, drift, PR aberto). Feche com uma linha de prontidao.

**Invariantes:** idempotente, le antes, transparente, tolerante a falha. Fora da Phase 0: sem edits, sem commits,
sem PR, sem mutacao de memoria. Nunca escrever no repo do arquiteto nem na distro congelada. Nada de travessao no
que escrever (D-IMAN-034).

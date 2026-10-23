# Patchset do IMAN Terra sobre o QGIS

Todo arquivo do QGIS que este fork altera, a partir da tag `final-3_44_13`, fica listado aqui com o motivo e a
decisao (D-ID). O que e do IMAN e novo vive em `iman/` e nao entra nesta lista; `.claude/`, `.memory/` e
`CLAUDE.md` sao o harness da Crew e tambem nao entram.

Conferencia (tem de listar exatamente os arquivos da tabela):

```
git diff --stat final-3_44_13..HEAD -- . ':!iman' ':!.claude' ':!.memory' ':!CLAUDE.md'
```

A conferencia automatica e `iman/build/Test-Patchset.ps1`, que falha se um arquivo alterado nao estiver na tabela.

## Arquivos alterados

| Arquivo | Motivo | D-ID | Fatia |
|---|---|---|---|

Nenhum arquivo do QGIS alterado ate aqui. A fatia `qgis-build #043` (fundacao) compila o 3.44.13 sem mudanca.

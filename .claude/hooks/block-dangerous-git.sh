#!/bin/bash
  # PreToolUse(Bash) guardrail — bloqueia operacoes git destrutivas/de-forca.
  # Lista ESTREITA: so o que NINGUEM deveria fazer. NAO bloqueia commit/push normais.
  INPUT=$(cat)
  if command -v jq >/dev/null 2>&1; then
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
    [ -z "$COMMAND" ] && COMMAND="$INPUT"
  else
    COMMAND="$INPUT"
  fi
  DANGEROUS_PATTERNS=(
    "git push[^|;&]*--force"
    "git push[^|;&]*-f([[:space:]]|\"|$)"
    "git reset[^|;&]*--hard"
    "git clean[^|;&]*-[a-zA-Z]*f"
    "git branch[^|;&]*-D"
    "git checkout([^|;&]*--)?[[:space:]]+\\.([[:space:]]|\"|$)"
    "git restore[^|;&]+\\.([[:space:]]|\"|$)"
  )
  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if printf '%s' "$COMMAND" | grep -qE "$pattern"; then
      echo "BLOQUEADO: comando casa com padrao git destrutivo/de-forca proibido ('$pattern'). Use
  alternativa nao-destrutiva ou peca ao sponsor." >&2
      exit 2
    fi
  done
  exit 0

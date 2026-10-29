# Memory Index - IMAN Terra (Crew build)

Uma linha por arquivo da raiz de `.memory/`. O `/start-session` le este indice, os `feedback_*.md` e o
`reference_build_environment.md`; os demais sao lidos sob demanda.

- [Stack do projeto](project_stack.md) - fork do QGIS 3.44.13, build local e de release, convencoes de `iman/`; carregada pelo CLAUDE.md (@import).
- [feedback_branding_license_guardrails.md](feedback_branding_license_guardrails.md) - BL-1 a BL-7 na versao do fork: creditos, nao oficial, perfil isolado, fonte unica, patchset minimo, GPL, VM limpa.
- [reference_build_environment.md](reference_build_environment.md) - bancada desta maquina: VS 2022 Build Tools 17.14 (MSVC 14.44), ferramentas e raiz de trabalho em `D:\iman-terra-build`, tempos e disco medidos na fatia 043 (2026-10-23); nome interno QGIS3 compartilhado, .res do icone e captura de janela (fatia 044); nome interno proprio, Inno 7.1.0, tar do Git Bash, WinToast e a 0.3.0 removida (fatia 047); Debugging Tools instaladas, sobras `.antes-047-patch` e disco (patch de 2026-10-29).

> Decisoes de produto vivem no arquiteto: `../iman-product-architect/.memory/reference_decisions.md` (D-IMAN-040). Briefings: `../iman-product-architect/.memory/briefings/`.

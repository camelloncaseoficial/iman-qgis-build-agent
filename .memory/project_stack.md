---
name: Stack do projeto
description: Stack da Crew build do IMAN Terra (fork do QGIS compilado com a marca). Carregada pelo CLAUDE.md (@import). Itens "a confirmar" sao perguntados pelo proximo /start-session ou medidos pela fatia de fundacao.
type: project
captured_at: 2026-10-22
updated_at: 2026-10-25 (fatia 044: marca no fonte, checagens de marca no smoke, guarda por rodada)
---

| Item | Escolha | Fonte |
|---|---|---|
| Base | fork publico do `qgis/QGIS`, ramo `develop` nascido da tag `final-3_44_13` (Qt5) | D-IMAN-040 |
| Repo | `camelloncaseoficial/iman-qgis-build-agent` (publico; cumpre a GPL pelo proprio repo) | D-IMAN-040 |
| Build local | Windows; VS 2022 Build Tools 17.14 (MSVC 14.44, SDK 10.0.26100), CMake 3.29.0, ninja 1.10.2, winflexbison 2.5.25; 156 pacotes OSGeo4W fixados nas versoes do 3.44.13 oficial (`iman/build/osgeo4w.lock.tsv`, com sha256); CMake manual com as flags da receita `qgis-ltr` (jef-n/OSGeo4W@b17db55); entrada `iman/build/Invoke-ImanBuild.ps1`; saida fora do repo em `D:\iman-terra-build` | medido na fatia 043 |
| Build de release | GitHub Actions do fork, reproduzivel, ligado pelo sponsor numa fatia propria | D-IMAN-040 |
| Linguagem | C++/Qt5 e CMake (core), Python (PyQGIS), PowerShell (scripts de build e testes) | D-IMAN-040 |
| Instalador | a confirmar na fundacao (Inno Setup 7, como a distro e o D-IMAN-030, ou o empacotamento do proprio QGIS) | a confirmar |
| Testes | `iman/build/Invoke-Smoke.ps1`: versao e revisao (BL-6), provedores do Processamento, plugins, `native:buffer` num fixture, janela + `.qgz`, guarda do QGIS oficial (BL-3); `Test-Patchset.ps1` (BL-5). Desde a 044: checagens `marca:*` no smoke (titulo, traducao, idioma, splash, icones, enderecos, noticias e versao, PDF), cada uma cai contra o oficial (`-Target Official`, veredito de controle); referencia de provedores, algoritmos e plugins em `smoke/expected/`; `Test-GuardRounds.ps1` (guarda); `Invoke-BrandCaptures.ps1` (capturas do laudo, fora do gate) | medido nas fatias 043 e 044 |
| Smoke | VM Windows limpa (BL-7) | D-IMAN-025 |
| Gate | proposto: `pwsh -NoProfile -File iman/build/Invoke-Gate.ps1` (patchset + build incremental offline + smoke); registro e do arquiteto | proposto na fatia 043 |
| Branching | develop-based (base de PR = `develop`) | D-IMAN-012 |
| Distribuicao | GitHub Releases deste repo | D-IMAN-040 |
| Arquiteto | `../iman-product-architect` (briefings em `.memory/briefings/`) | D-IMAN-040 |

- Prefixo dos briefings desta Crew: `qgis-build` (`<YYYY-MM-DD>_qgis-build_<NNN>_<slug>.md`, convencao IMAN).
- Gate: **o gate oficial e registrado pelo arquiteto no harness dele (`crew_gate.sh`, kind `qgis-build`), nao por
  esta Crew** - quem e verificado nao define o proprio oraculo. Push e PR da branch da fatia NAO esperam o gate:
  rode o comando depois do PR aberto e cole o resultado no `/deliver`.

## Convencoes de diretorio

- Arvore do QGIS: intocada, salvo os arquivos listados em `iman/PATCHES.md`.
- `iman/brand/` - fonte unica de marca (nome, versao, cores, textos, endereços) e os assets (icones, splash, logo).
- `iman/build/` - scripts de build versionados (dependencias fixadas, passos, saida).
- `iman/installer/` - instalador do produto.
- `iman/notices/` - `LICENSE`, `THIRD_PARTY_NOTICES.md`, `SOURCE_CODE.md`.
- `iman/docs/` - arquitetura do fork, contrato da marca, laudos de verificacao (`iman/docs/verify/`).
- `iman/PATCHES.md` - todo arquivo do QGIS alterado, com motivo e D-ID.
- Saida de build e dependencias baixadas: fora do git (`.git/info/exclude` ou pasta fora do repo).

---
name: reference_build_environment
description: Bancada de build desta maquina, medida pelo arquiteto em 2026-10-22, antes da fatia de fundacao.
type: reference
---

Medido em 2026-10-22, na criacao da Crew:

- Windows 11 Pro, 24 processadores logicos, 32 GB de RAM.
- Disco livre: C: 272 GB, D: 166 GB.
- **Sem Visual Studio** (sem `vswhere`), **sem `cmake`, `ninja` nem `cl` no PATH**, sem `C:\OSGeo4W`.
- Com `git`. Com o QGIS 3.44.13 oficial em `C:\Program Files\QGIS 3.44.13` (o do sponsor: so leitura, nunca
  alterar) e o IMAN Terra 0.3.0 da distro em `%LOCALAPPDATA%\Programs\IMAN Terra` (congelado).
- Clone deste repo: parcial (`--filter=blob:none`), `core.longpaths=true`, `core.autocrlf=false`; remoto
  `upstream` = `qgis/QGIS` (nunca `git fetch --all`: baixa o QGIS inteiro).

A fatia de fundacao atualiza este arquivo com o que instalar, as versoes e o tempo de build medido.

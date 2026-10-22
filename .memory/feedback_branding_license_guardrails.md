---
name: feedback_branding_license_guardrails
description: Invariantes de marca e licenca do fork do QGIS (BL-1 a BL-7, versao do build); vale para toda fatia.
type: feedback
---

O IMAN Terra e um QGIS compilado por nos e redistribuido. Isso muda o papel de "usuario" para "redistribuidor de
binario modificado", e cada invariante abaixo existe por isso.

**Why:** sponsor, D-IMAN-025 (BL-1 a BL-7) e D-IMAN-040 (o fork substitui a camada de marca sem fork).
**How to apply:**

- **BL-1 CREDITO AO QGIS** - "powered by QGIS" visivel no produto; o "Sobre" do QGIS fica com os creditos, os
  contribuidores e a licenca dele. Nunca remover nem esconder credito.
- **BL-2 NAO OFICIAL** - o produto nunca se apresenta como QGIS oficial nem endossado. A marca QGIS (nome e logo)
  nao vira a identidade do produto: onde o QGIS nomeia o aplicativo em uso, vira IMAN Terra; onde nomeia o projeto
  QGIS, a comunidade, os creditos ou a licenca, fica. Aviso de independencia no pacote.
- **BL-3 PERFIL ISOLADO** - o produto nao le nem escreve a configuracao, o perfil, o registro ou a instalacao de um
  QGIS do usuario. Instalar o IMAN Terra numa maquina com QGIS oficial nao muda nada do QGIS oficial.
- **BL-4 MARCA EM FONTE UNICA** - nome, versao e todo texto de marca vem de `iman/brand/`; o rename e trocar um
  lugar, nao caçar strings.
- **BL-5 PATCHSET MINIMO** - (substitui o antigo "sem fork primeiro") todo arquivo do QGIS alterado fica em
  `iman/PATCHES.md`; mudanca de comportamento do QGIS so com briefing; a migracao para a proxima versao do QGIS e
  reaplicar o patchset, nao reescrever.
- **BL-6 GPL** - todo binario distribuido sai de um commit publico deste repo, identificado no pacote; `LICENSE`,
  `THIRD_PARTY_NOTICES.md` e `SOURCE_CODE.md` no instalador; dependencias transitivas (Qt LGPL, GDAL e as demais)
  nomeadas.
- **BL-7 VM LIMPA** - a entrega e provada instalando numa maquina Windows limpa; smoke que nao rodou na VM e lacuna
  declarada.

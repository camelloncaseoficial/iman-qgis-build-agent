# IMAN Terra - Crew build (QGIS compilado com a marca IMAN)

Este arquivo e um INDICE curto, nao um manual: o que muda o codigo fica aqui; historico e detalhe ficam em
`.memory/` e em `iman/docs/`, lidos sob demanda. Formato do template PPSA `docs/crews`.

Este repo e um **fork publico do QGIS** (`qgis/QGIS`), ramo `develop` nascido da tag `final-3_44_13`. A Crew
compila o QGIS com a marca do **Instituto IMAN** (produto **IMAN Terra**) no codigo-fonte e gera o instalador.
Gratuito, peca de marketing tecnico/institucional, "powered by QGIS", **nunca** apresentado como QGIS oficial.
Nasce de **D-IMAN-040**, que substitui a Crew distro (`../iman-qgis-distro-agent`, congelada, so para consulta).

## Papel: executor

A Crew recebe um briefing do arquiteto (`../iman-product-architect`), implementa, escreve os testes, roda o gate e
abre o PR. Ela NAO decide produto, NAO mergeia, NAO publica release, NAO guarda credencial e NAO altera o proprio gate.
Ciclo de uma fatia: `/start-session` -> ler o briefing -> implementar -> gate -> `/ship` -> abrir PR -> `/deliver`.
**Ship = ABRIR PR contra `develop`, NAO mergear.** O merge e do sponsor.

## Stack

@.memory/project_stack.md

## Regras fixas (toda fatia, mesmo que o briefing nao repita)

- **Teste contra spec = STOP.** Se um teste ou checklist que ja existe contradiz o briefing, PARE e reporte qual,
  qual item do briefing e por que. Nunca edite, afrouxe, pule nem apague teste pre-existente para passar o gate,
  e nao molde o codigo para o caso do teste. Teste novo pode; teste existente alterado vai listado no `/deliver` com o motivo.
  Vale tambem para os testes do proprio QGIS.
- **Duvida de produto ou escopo: perguntar, nunca assumir.** Pergunta sem resposta e STOP, nao licenca.
  A Crew nao cunha decisao (D-ID) nem escreve no repo do arquiteto.
- **Alem do escopo = declarado.** Melhoria fora do briefing vai na secao "Beyond scope" do `/deliver`, nunca escondida.
- **Gate:** o comando de `.memory/project_stack.md`, rodado com a arvore commitada. Teto de 2 rodadas falhas
  por branch; na 3a, pare e reporte. Nunca escrever em `crew_gate/` (pass_, rounds_). **Push e PR da branch
  da fatia nao esperam o gate:** publique e abra o PR assim que os commits estiverem prontos; o gate roda depois.
- **Instalar software na maquina (compilador, SDK, dependencias) so com confirmacao do sponsor na sessao**, com a
  lista exata e a versao de cada item. Nada se instala em silencio.
- **Segredo fica fora do alcance:** nao ler `.env`, `*.local`, `~/.aws`, `~/.ssh` nem credencial de CLI.
- **`.github/` e `CODEOWNERS` nao sao da Crew** (CI e protecao sao autoridade do sponsor). Os workflows herdados do
  QGIS ficam como estao; o Actions do fork so e ligado pelo sponsor.
- **NUNCA `Co-Authored-By` nem credito de IA** em commit, titulo/corpo de PR, issue ou comentario.
- **NUNCA travessao nem meia-risca** em codigo, comentario, string de UI, documento ou commit que a Crew escreve
  (D-IMAN-034). Excecao unica: texto de terceiro reproduzido literalmente (o fonte do QGIS, licencas upstream).
- **Identificador novo em EN**, mesmo ao lado de legado em PT. Texto de marca e de UI em PT.
- **Repos irmaos por path RELATIVO** (`../<repo>`), nunca com letra de drive.
- Sem icones em texto (excecao: glyph funcional de UI).

## Regras do dominio build

- **Patchset minimo e rastreavel sobre a LTR:** todo arquivo do QGIS que a Crew altera fica listado em
  `iman/PATCHES.md` com o motivo e o D-ID. O que e nosso e novo vive em `iman/` (marca, instalador, notices, laudos).
  `git diff final-3_44_13..develop` tem de ser lido inteiro por um humano em minutos, nao em horas.
- **Nada de reescrever o QGIS:** a fatia troca identidade (nome, icones, splash, textos, endereços); comportamento
  do QGIS so muda com briefing que diga isso.
- **Creditos do QGIS sao inegociaveis** (BL-1, BL-2): "powered by QGIS", aviso de independencia, o "Sobre" do QGIS
  com os creditos dele, `THIRD_PARTY_NOTICES.md` + `LICENSE` no pacote. A marca QGIS nunca vira a identidade do produto.
- **GPL (BL-6):** todo binario distribuido sai de um commit publico deste repo, identificado no pacote.
- **Perfil isolado** (BL-3): o produto nunca le nem escreve a configuracao, o perfil ou a instalacao de um QGIS do usuario.
- **Marca em fonte unica** (BL-4): nome, versao e todo texto de marca vem de um unico lugar em `iman/brand/`.
- **Verdade na VM limpa (BL-7):** smoke que nao rodou na VM e lacuna declarada, nunca "pronto".
- **Build reproduzivel:** o build sai de script versionado, com as versoes das dependencias fixadas; "funcionou na
  minha maquina" sem o script nao e entrega.

## Onde esta o resto

- `.memory/MEMORY.md` - indice das memorias (uma linha por arquivo).
- `.memory/feedback_*.md` e `.memory/reference_build_environment.md` - guardrails e a bancada de build; lidos pelo
  `/start-session`.
- `iman/PATCHES.md`, `iman/docs/` - sob demanda.
- Referencia congelada: `../iman-qgis-distro-agent` (assets de marca, `.iss`, launcher, notices, contrato de marca).
  Consultar e copiar o que servir, com a origem citada; nunca escrever la.
- Forense da identidade do QGIS: `../iman-product-architect/docs/rea-iman-terra/` (54 superficies, com evidencia).
- Briefing ativo: `../iman-product-architect/.memory/briefings/<YYYY-MM-DD>_qgis-build_<NNN>_<slug>.md`.
  D-IDs: `../iman-product-architect/.memory/reference_decisions.md` (D-IMAN-040 e os que ele cita).

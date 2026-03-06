# Memoria do Projeto - Nuke Assalt

## Regra operacional persistente

- Este projeto sera executado em etapas sequenciais.
- Nenhuma etapa sera considerada finalizada sem:
  - `dotnet test` verde;
  - validacao manual no Roblox Studio;
  - confirmacao explicita do usuario.
- Eu nao devo avancar automaticamente para a etapa seguinte.

## Plano mestre

- Documento fonte: `docs/IMPLEMENTATION_PLAN.md`

## Proxima etapa prevista

- `Etapa 3 - Mapa greybox Silo-7 e metadados espaciais`

## Etapas aceitas

- `Etapa 0 - Fundacao tecnica e harness de validacao` validada manualmente no Roblox Studio em 2026-03-06 e aceita pelo usuario.
- `Etapa 1 - Contratos centrais, configuracao data-driven e rede` aceita pelo usuario para commit e avancar em 2026-03-06.
- `Etapa 2 - Loop base de match e round` validada manualmente no Roblox Studio e aceita pelo usuario em 2026-03-06.

## Observacoes importantes

- O projeto usa `JSON + Luau bridge` como fonte de verdade para configuracoes estaticas.
- O repositorio e a source of truth entre VSCode, Roblox Studio e Git.
- O fluxo operacional atual e `Studio-first`.
- O jogo deve permanecer server-authoritative em compra, dano, objetivo, round, inventario e placement.

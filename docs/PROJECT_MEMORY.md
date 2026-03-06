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

- `Etapa 0 - Fundacao tecnica e harness de validacao`

## Observacoes importantes

- O projeto usa `JSON + Luau bridge` como fonte de verdade para configuracoes estaticas.
- O repositorio e a source of truth entre VSCode, Roblox Studio e Git.
- O fluxo operacional atual e `Studio-first`.
- O jogo deve permanecer server-authoritative em compra, dano, objetivo, round, inventario e placement.

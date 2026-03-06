# Studio Map Authoring

## Objetivo

Permitir que um mapa montado manualmente no Roblox Studio seja usado pelo runtime do jogo sem depender do `map.json` gerado.

Quando existir um root de mapa manual no `Workspace`, o servidor usa esse root.
Se nao existir, o fallback continua sendo o mapa gerado a partir de `data/config/map.json`.

## Prioridade de carregamento

1. mapa manual no Studio
2. mapa gerado por config

## Como ativar um mapa manual

Crie um `Model` no `Workspace` e adicione este atributo no root:

- `NukeAssaltManualMap = true`

Atributos opcionais no root:

- `MapId = "meu-mapa-teste"`
- `MapName = "Meu Mapa Teste"`
- `Theme = "Prototype"`

## Estrutura esperada

```text
Workspace
└─ MeuMapaTeste (Model) [NukeAssaltManualMap=true]
   ├─ Spawns
   │  ├─ Attacker Spawn (SpawnLocation) [Team="Attackers"]
   │  ├─ Defender Spawn (SpawnLocation) [Team="Defenders"]
   │  └─ Lobby Spawn (SpawnLocation) [Team="Spectators"]
   ├─ Bombsites
   │  ├─ Reactor Chamber (Folder/Model) [BombsiteId="A"]
   │  │  └─ A Default Plant (Part) [PlantZoneId="a-default", BombsiteId="A"]
   │  └─ Control Hub (Folder/Model) [BombsiteId="B"]
   │     └─ B Default Plant (Part) [PlantZoneId="b-default", BombsiteId="B"]
   ├─ Callouts
   │  ├─ A Main Marker (Part) [CalloutId="a_main"]
   │  └─ Mid Pipe Marker (Part) [CalloutId="mid_pipe"]
   ├─ Routes
   │  └─ Route A Main Marker (Part) [RouteId="route-a-main", FromCalloutId="attacker_spawn", ToCalloutId="a_main", SiteId="A"]
   ├─ AnchorPoints
   │  └─ Camera Mid Pipe (Part) [AnchorPointId="anchor-camera-mid-pipe", AnchorType="Camera", SiteId="Mid", CalloutId="mid_pipe"]
   └─ Geometry
      └─ qualquer geometria do mapa
```

## Regras minimas obrigatorias

- O root precisa ter `NukeAssaltManualMap = true`.
- O root precisa ter `Spawns`.
- O root precisa ter `Bombsites`.
- Os `SpawnLocation`s precisam cobrir:
  - `Attackers`
  - `Defenders`
  - `Spectators`
- Cada bombsite precisa ter `BombsiteId`.
- Cada plant zone precisa ter `PlantZoneId`.
- O mapa manual precisa ter pelo menos `2` bombsites.
- Cada bombsite precisa ter pelo menos `1` plant zone.

## O que o runtime le manualmente hoje

- spawns por time
- bombsites
- plant zones
- callouts
- routes
- anchor points
- nome, id e tema do mapa

## O que o runtime publica para debug

Em `ReplicatedStorage > NukeAssaltRuntime`:

- `MapSource`
- `ActiveMapRootName`
- `ActiveMapId`
- `ActiveMapName`
- `ActiveMapTheme`
- `MapCalloutCount`
- `MapRouteCount`
- `MapBombsiteCount`
- `MapAnchorPointCount`
- `MapGeometryCount`

## Fluxo recomendado no Studio

1. Rode o projeto e deixe o fallback gerar o mapa.
2. Recrie esse layout manualmente no `Workspace` ou monte um mapa novo do zero.
3. Adicione `NukeAssaltManualMap = true` no root do seu mapa.
4. Configure `Spawns`, `Bombsites`, `Callouts`, `Routes` e `AnchorPoints`.
5. Rode `Play`.
6. Confirme no `F9` ou nos atributos de `NukeAssaltRuntime` que `MapSource = StudioManual`.

## Observacao importante sobre Rojo

Esse modo permite authoring manual no Studio para testes e iteracao local.
Como o `Workspace` atual nao esta mapeado como source principal do repo, suas mudancas manuais no Studio vivem no place local salvo no Studio, nao em arquivos `luau/json` do repositorio.

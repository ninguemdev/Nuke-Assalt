# Plano de Implementacao - Nuke Assalt

## Estado atual do repositorio

- O projeto esta em estado inicial, com estrutura minima de `Rojo` e scripts "hello world" em `src/client`, `src/server` e `src/shared`.
- Ainda nao existe harness de validacao em `.NET`, nem suite de testes, nem estrutura modular para gameplay.
- Por isso, a `Etapa 0` e obrigatoria: sem ela nao existe como cumprir a exigencia de encerrar cada etapa com `dotnet test`.

## Protocolo operacional deste projeto

- A implementacao sera feita em uma etapa por vez.
- Cada etapa so termina quando quatro condicoes forem atendidas:
  - a implementacao da etapa estiver concluida;
  - os testes da etapa passarem com `dotnet test`;
  - a validacao manual no Roblox Studio for executada;
  - o usuario confirmar explicitamente que a etapa esta aceita.
- Eu so sigo para a etapa seguinte quando o usuario disser algo como `proxima etapa`, `pode seguir`, `avancar`, ou equivalente.
- Se houver divergencia entre o plano e a realidade encontrada durante a execucao, eu ajusto o plano antes de seguir.

## Estrategia obrigatoria de testes com dotnet

Como o runtime principal do jogo sera `Luau`, o `dotnet test` nao substitui a validacao no Roblox Studio. O papel do `.NET` neste projeto sera validar regras deterministicas, contratos, configuracoes e maquinas de estado que nao dependem do motor do Roblox.

### Harness proposto

- Solucao: `tools/NukeAssalt.Validation.sln`
- Projeto principal de testes: `tools/NukeAssalt.Specs`
- Responsabilidades do harness:
  - validar tabelas e catalogos de conteudo;
  - validar regras de economia;
  - validar maquinas de estado de match, round e objetivo;
  - validar restricoes de inventario, loja e lados;
  - validar metadados do mapa;
  - validar contratos de eventos e telemetria;
  - impedir regressao de balanceamento obvia.

### Comando padrao de aceite

```powershell
dotnet test .\tools\NukeAssalt.Validation.sln
```

### Regra de aceite por etapa

- Sem `dotnet test` verde, a etapa nao fecha.
- Sem checklist manual no Studio, a etapa nao fecha.
- Sem sua confirmacao, a etapa nao fecha.

## Arquitetura alvo recomendada

### Estrutura Luau

- `src/shared/Config`
- `src/shared/Types`
- `src/shared/Net`
- `src/shared/Enums`
- `src/shared/Util`
- `src/server/Services`
- `src/server/Systems`
- `src/server/Controllers`
- `src/client/Controllers`
- `src/client/UI`
- `src/client/HUD`
- `src/client/Effects`

### Estrutura de suporte

- `docs/`
- `tools/NukeAssalt.Specs/`
- `tools/NukeAssalt.Specs/Fixtures/`
- `tools/NukeAssalt.Specs/Validators/`

## Roadmap completo de implementacao

## Etapa 0 - Fundacao tecnica e harness de validacao

### Objetivo

Criar a base operacional do projeto para que todas as etapas seguintes sejam implementadas com seguranca, validacao repetivel e estrutura modular.

### Entregaveis

- Estrutura de pastas compartilhada entre cliente, servidor e dados.
- Loader de modulos e convencoes de naming.
- Solucao `.NET` para testes.
- Primeiros validadores de configuracao.
- Documento de arquitetura curta e fluxo de trabalho local.

### O que sera implementado

- Bootstrap dos diretorios modulares em `src/`.
- Contratos base de servicos e enums comuns.
- Harness `dotnet` com projeto de testes.
- Configuracoes iniciais de match, round, economia e catalogo como fonte de verdade.
- Comando padrao de validacao local.
- Geracao dos modulos Luau a partir de `data/config/*.json`.

### Testes obrigatorios com dotnet

- A solucao compila.
- O projeto de testes executa.
- Validadores detectam configuracoes invalidas.
- Tempos base fazem sentido:
  - buy phase menor que o round;
  - post-plant positivo;
  - swap de lados configurado;
  - limite de rounds coerente com `first to 9`.

### Comandos locais da etapa

```powershell
$env:DOTNET_CLI_HOME="$PWD\\.dotnet"
$env:NUGET_PACKAGES="$PWD\\.nuget\\packages"
dotnet run --project .\tools\NukeAssalt.Tools\NukeAssalt.Tools.csproj -- generate-config
dotnet test .\tools\NukeAssalt.Validation.sln
```

### O que fazer manualmente no Roblox Studio

- Instalar e habilitar o plugin do Rojo.
- Abrir o place derivado do `rojo build`.
- Rodar `rojo serve` e conectar o Studio ao projeto.
- Verificar se a arvore sincroniza corretamente em `ReplicatedStorage`, `ServerScriptService` e `StarterPlayerScripts`.
- Salvar um place base local de trabalho para as proximas etapas.
- Tratar o repositorio como source of truth; o place do Studio nao e a origem primaria do codigo.

### Criterio de aceite

- `dotnet test` verde.
- Rojo sincronizando corretamente.
- Estrutura de codigo pronta para receber gameplay.

## Etapa 1 - Contratos centrais, configuracao data-driven e rede

### Objetivo

Definir a linguagem tecnica do jogo: configuracoes, tipos, eventos de rede e interfaces dos servicos.

### Entregaveis

- Catalogos iniciais de armas, utilitarios, equipamentos e timers.
- Enums de lados, fases do round, estados do objetivo e tipos de item.
- Contratos de `RemoteEvent` e `RemoteFunction`.
- Interfaces de `MatchService`, `RoundService`, `EconomyService`, `ShopService`, `InventoryService`, `WeaponService`, `ObjectiveService`, `UtilityService`, `EquipmentService`, `StatsService`.

### O que sera implementado

- Modelos de dados compartilhados entre cliente e servidor.
- Validador central de configuracao carregada no startup.
- Registro unico de remotes.
- Estrutura para flags de feature e tuning rapido.

### Testes obrigatorios com dotnet

- Nenhum item com custo negativo.
- Nenhum item exclusivo do lado errado.
- Limites de utilitario e slot consistentes.
- Tempos e recompensas economicas dentro de faixas validas.
- Contratos de evento com nomes unicos.

### O que fazer manualmente no Roblox Studio

- Conferir a criacao de objetos sincronizados para remotes e containers compartilhados.
- Validar se o place abre sem erros no output.
- Verificar se os atributos/configs expostos para debug estao legiveis durante execucao.

### Criterio de aceite

- Toda configuracao critica do jogo existe fora da logica central.
- Cliente e servidor compartilham os mesmos contratos.

## Etapa 2 - Loop base de match e round

### Objetivo

Provar o esqueleto competitivo: times, round sem respawn, transicoes e vitoria por eliminacao ou tempo.

### Entregaveis

- `MatchService` e `RoundService` funcionais.
- Estados: lobby tecnico, buy phase, live round, post-round, troca de lados, fim da partida.
- Entrada e balanceamento de jogadores nos lados.
- Respawn desativado durante o round.
- Reset completo entre rounds.

### O que sera implementado

- Maquina de estado do match.
- Timers autoritativos no servidor.
- Spawn por lado.
- Eliminacao total e timeout como resolucao inicial de round.
- Preparacao para `first to 9` e troca apos 8 rounds.

### Testes obrigatorios com dotnet

- Transicoes validas entre estados.
- Um round nao inicia antes de terminar o anterior.
- Timeout da rodada beneficia o lado correto antes do plant.
- Swap de lados ocorre exatamente no round alvo.
- Vitoria da partida acontece no threshold correto.

### O que fazer manualmente no Roblox Studio

- Criar ou ajustar `Teams`, `SpawnLocation` e pontos de spawn iniciais.
- Validar que jogadores mortos nao retornam no mesmo round.
- Testar reset de personagens e posicionamento entre rounds.
- Testar o fluxo de varios rounds com `Start Server` e pelo menos 2 clientes locais.

### Criterio de aceite

- E possivel jogar rounds completos de forma repetida sem travar o estado global da partida.

## Etapa 3 - Mapa greybox Silo-7 e metadados espaciais

### Objetivo

Criar o mapa 1 em versao jogavel de greybox com bombsites, rotas e pontos validos para objetivo e equipamentos.

### Entregaveis

- Greybox funcional de `Silo-7`.
- `A Site`, `Mid / Service`, `B Site`, conectores e rotacoes.
- Callouts nomeados.
- Zonas de plant.
- Anchor points de barricada, camera e mina.

### O que sera implementado

- Hierarquia do mapa no `Workspace`.
- Metadados por tags, atributos ou colecoes.
- Estrutura para validar bombsites, rotas e pontos de deploy.
- Layout sem clutter visual desnecessario.

### Testes obrigatorios com dotnet

- Cada site possui ao menos duas entradas funcionais de atacante no metadata.
- Nenhum anchor point invalido cai dentro de plant zone proibida.
- Todos os callouts sao unicos.
- Spawns, sites e rotas possuem referencias completas no metadata.

### O que fazer manualmente no Roblox Studio

- Construir a greybox com partes simples.
- Ajustar colisao, cobertura, alturas e bloqueios.
- Marcar sites, zonas e anchor points com nomes/atributos padronizados.
- Testar leitura visual de rotas, line of sight e tempos de rotacao.

### Criterio de aceite

- O mapa suporta rounds reais e deixa claro onde A, Mid e B funcionam.

## Etapa 4 - FPS core: camera, movimento, dano e morte

### Objetivo

Estabelecer o feeling base de shooter e o pipeline autoritativo de hit, dano, morte e observacao.

### Entregaveis

- Camera em primeira pessoa.
- Movimento com correr, agachar, pular e penalidade de precisao em movimento.
- Pipeline de dano autoritativo no servidor.
- Hit zones.
- Morte, eliminacao e transicao para espectador basico.

### O que sera implementado

- Controller de camera e input.
- `DamageService` base.
- Integracao com `Humanoid` e regras de letalidade.
- Penalidade de tiro correndo e pulando.
- Feedback minimo de acerto e morte.

### Testes obrigatorios com dotnet

- Multiplicadores de hit zone consistentes.
- Regras de precisao em movimento dentro das faixas definidas.
- Dano nao gera vida negativa ou estados invalidos.
- Headshot, torso e membros respeitam a hierarquia de dano prevista.

### O que fazer manualmente no Roblox Studio

- Ajustar `CameraMode`, sensibilidade e offset.
- Testar movimento em varias geometrias do greybox.
- Validar se correr atirando fica visivelmente pior do que parar para atirar.
- Verificar transicao para espectador apos morte.

### Criterio de aceite

- O jogo ja transmite um FPS tatico basico e jogavel.

## Etapa 5 - Arsenal beta e sistema de armadura

### Objetivo

Implementar o conjunto inicial de armas com papeis distintos e adicionar armadura.

### Entregaveis

- `P1`, `P2`, `SMG-9`, `Rifle-A`, `Rifle-B`, `SR-1`.
- Municao, recarga, cadencia, recoil, spread e reserva.
- Recompensa por kill por classe de arma.
- `Armor`.

### O que sera implementado

- `WeaponService` com suporte a catalogo.
- Comportamento especifico por arma.
- Integracao com dano e economia.
- Regras de precisao com stance e movimento.

### Testes obrigatorios com dotnet

- Catalogo de armas completo e sem ids duplicados.
- Cadencia, pente e reserva acima de zero quando aplicavel.
- Recompensa por kill correta por classe.
- Armadura reduz dano nas categorias previstas.
- Breakpoints de dano nao violam a intencao de balanceamento.

### O que fazer manualmente no Roblox Studio

- Configurar modelos de arma, `Tool` ou representacao equivalente.
- Ligar animacoes placeholder de equip, fire e reload.
- Inserir sons placeholder.
- Testar o papel tatico de cada arma em curta, media e longa distancia.

### Criterio de aceite

- As armas ja criam diferenca real de escolha entre eco, anti-eco e full buy.

## Etapa 6 - Economia, loja e inventario por round

### Objetivo

Fazer a economia gerar decisao real antes do round e garantir que cada jogador respeite slots e restricoes por lado.

### Entregaveis

- `EconomyService`, `ShopService` e `InventoryService`.
- Dinheiro inicial, vitoria, derrota escalonada, plant bonus, defuse bonus e reward por kill.
- Regras de loadout por round.
- Regras de slot.
- Restricoes de buy phase.

### O que sera implementado

- Fluxo de compra autoritativo no servidor.
- Persistencia apenas dentro da partida.
- Validacao de custo, lado e ocupacao de slot.
- Compra de armor, kit, armas, utilitarios e equipamento especial.

### Testes obrigatorios com dotnet

- Loss streak escala corretamente.
- Compra falha com dinheiro insuficiente.
- Compra falha fora da buy phase.
- Jogador nao ultrapassa 3 utilitarios.
- Jogador nao equipa 2 equipamentos especiais.
- Defensor e atacante respeitam exclusivos.

### O que fazer manualmente no Roblox Studio

- Testar compras com varios valores de saldo.
- Verificar se o inventario reseta corretamente por round.
- Simular pistol round, eco, semi-buy, force e full buy.
- Conferir se armas dropadas e recuperadas mantem consistencia.

### Criterio de aceite

- A economia do round influencia as decisoes de compra de forma visivel.

## Etapa 7 - Objetivo central: maleta, plant e defuse

### Objetivo

Implementar o loop principal de plant/defuse com maleta nuclear portatil.

### Entregaveis

- `ObjectiveService`.
- Atribuicao da maleta a um atacante no inicio do round.
- Drop, pickup e fallback seguro da maleta.
- Plant em zonas validas.
- Defuse com e sem kit.
- Pos-plant com explosao.

### O que sera implementado

- Estados do objetivo.
- Interacoes de plant e defuse com cancelamento.
- Vitoria por explosao, defuse e timeout antes do plant.
- Feed minimo de estado do objetivo.

### Testes obrigatorios com dotnet

- Apenas atacante pode plantar.
- Apenas defensor pode desarmar.
- Kit altera o tempo de defuse corretamente.
- Maleta cai e pode ser recuperada.
- Fallback entra em acao se a maleta ficar inacessivel.
- Round e resolvido corretamente em todos os ramos de plant/defuse.

### O que fazer manualmente no Roblox Studio

- Criar modelo visual da maleta.
- Marcar bombsites e superficies validas para plant.
- Testar interrupcao de plant por morte, movimento ou cancelamento.
- Testar retake com e sem kit.
- Validar clareza audiovisual do estado de bomba armada.

### Criterio de aceite

- O loop plant/defuse ja funciona fim a fim e sustenta rounds completos.

## Etapa 8 - Utilitarios ofensivos e defensivos

### Objetivo

Adicionar o conjunto principal de utilitarios que define o espacamento tatico do round.

### Entregaveis

- `Smoke`
- `Flashbang`
- `HE`
- `Incendiaria / Molotov`

### O que sera implementado

- Inventario e consumo.
- Throw ou deploy padronizado.
- Efeitos de area e duracao.
- Friendly effect conforme regra do GDD.
- Integracao com dano, visibilidade e objective play.

### Testes obrigatorios com dotnet

- Limites de compra por tipo.
- Maximo total de 3 utilitarios.
- Duracoes e raios dentro das faixas previstas.
- Flash afeta aliados e usuario quando apropriado.
- Incendiaria respeita regra de dano em aliado definida para a beta.

### O que fazer manualmente no Roblox Studio

- Criar ou importar VFX placeholder.
- Ajustar emissao de particulas e performance.
- Validar leitura de smoke e incendio a distancia.
- Testar execucoes de entrada, retake e corte de visao.

### Criterio de aceite

- O utilitario muda o desfecho de entradas e retakes de forma clara.

## Etapa 9 - Equipamentos especiais do defensor

### Objetivo

Adicionar os diferenciais do projeto sem quebrar o equilibrio competitivo.

### Entregaveis

- `Defuse Kit`
- `Camera fixa`
- `Barricada de metal`
- `Mina terrestre`

### O que sera implementado

- Slot exclusivo de equipamento especial.
- Placement validation no servidor.
- Destrutibilidade e counterplay.
- Armamento, vida e custos iniciais.
- Feed de uso e destruicao quando necessario.

### Testes obrigatorios com dotnet

- Jogador nao equipa mais de 1 equipamento especial.
- Equipamentos exclusivos nao podem ser comprados por atacantes.
- Camera so valida spots permitidos.
- Barricada nao pode nascer em plant zone proibida.
- Mina nao ultrapassa o teto de letalidade pretendido.
- Defuse kit aplica tempo correto.

### O que fazer manualmente no Roblox Studio

- Posicionar anchor points reais no mapa.
- Configurar superficies validas de camera.
- Modelar placeholder de barricada e mina.
- Testar destruicao por arma e granada.
- Validar que camera, barricada e mina possuem leitura visual/sonora suficiente.

### Criterio de aceite

- Os equipamentos criam profundidade defensiva, mas continuam com contra-jogo claro.

## Etapa 10 - HUD, loja final, spectate e audio tatico

### Objetivo

Tornar o estado do round legivel para o jogador e aproximar o prototipo de um produto jogavel.

### Entregaveis

- HUD completa.
- Buy UI em abas.
- Kill feed.
- Indicadores de vivos por time.
- Status de armor, dinheiro, arma, utilitarios e equipamento.
- Spectate funcional.
- `AudioEventService`.

### O que sera implementado

- UI de round.
- UI de plant/defuse.
- UI da maleta.
- Navegacao de spectate em aliados vivos.
- Event routing de audio tatico.

### Testes obrigatorios com dotnet

- Contratos de dados de HUD sem campos obrigatorios faltando.
- Eventos de kill feed e objective feed respeitam schema.
- Buy UI reflete corretamente custo e ocupacao de slot.
- Spectate nunca expande informacao do time inimigo.

### O que fazer manualmente no Roblox Studio

- Montar telas e anchors da HUD.
- Ajustar feedbacks sonoros prioritarios.
- Testar legibilidade em resolucoes diferentes.
- Validar se o jogador entende rapidamente o estado do round.

### Criterio de aceite

- Um playtester novo consegue ler o round sem depender de explicacao constante.

## Etapa 11 - Match completo, estatisticas e tela de resultado

### Objetivo

Fechar o ciclo completo da partida competitiva do inicio ao fim.

### Entregaveis

- `first to 9`
- Troca de lados apos 8 rounds
- Tela de resultado
- `StatsService`
- KDA, plants, defuses, dano e economia basica
- Historico basico da partida

### O que sera implementado

- Encerramento de match.
- Agregacao de estatisticas por jogador.
- Exibicao do vencedor final.
- Preparacao de dados para telemetria e futuro profile.

### Testes obrigatorios com dotnet

- Vitoria final ocorre no round correto.
- Swap de lados nao corrompe score nem inventario.
- Estatisticas agregam corretamente por round e match.
- Resultados de match respeitam todos os caminhos de encerramento.

### O que fazer manualmente no Roblox Studio

- Testar partidas completas com varios rounds.
- Validar troca real de spawns e lados.
- Conferir se scoreboard e tela final batem com a partida.
- Fazer smoke test com varios clientes locais.

### Criterio de aceite

- A partida beta e jogavel do primeiro round ate a tela final.

## Etapa 12 - Telemetria, anti-exploit e hardening

### Objetivo

Blindar a beta contra erros previsiveis, exploracoes obvias e falta de observabilidade.

### Entregaveis

- Eventos de telemetria principais.
- Validacoes de servidor revisadas.
- Rate limiting e guard rails de remotes.
- Auditoria de placement, compra, dano, municao e cadencia.
- Cleanup de objetos temporarios.

### O que sera implementado

- Telemetria de win rate por lado, plant rate, defuse rate e picks.
- Protecoes basicas contra spam de remotes.
- Revisao de autoridade de servidor em todas as mecanicas criticas.
- Ferramentas de debug para playtest fechado.

### Testes obrigatorios com dotnet

- Schemas de telemetria validos.
- Eventos criticos exigem payload coerente.
- Validadores de compra, placement e objective recusam entradas invalidas.
- Suites de regressao das etapas anteriores continuam verdes.

### O que fazer manualmente no Roblox Studio

- Testar spam de input e repeticao indevida de remotes.
- Testar cleanup de smokes, incendios, minas e barricadas.
- Rodar soak test local com varios rounds seguidos.
- Medir gargalos de performance mais obvios.

### Criterio de aceite

- O projeto aguenta playtests repetidos sem falhas graves ou exploits triviais.

## Etapa 13 - Beta fechada, balanceamento e polish

### Objetivo

Transformar o vertical slice em beta fechada estavel e balanceavel.

### Entregaveis

- Ajustes finos de preco, dano, timers e anchor points.
- Pass de UX.
- Pass de audio e VFX.
- Correcoes de bugs recorrentes.
- Checklist de release interna.

### O que sera implementado

- Tuning orientado por telemetria.
- Revisao do mapa com base em exec, retake e stall.
- Revisao de camera, barricada e mina.
- Melhorias de onboarding minimo para playtest.

### Testes obrigatorios com dotnet

- Suites de regressao completas.
- Validacao de catalogos apos tuning.
- Check de consistencia de economia e tempos apos rebalance.

### O que fazer manualmente no Roblox Studio

- Conduzir playtests fechados.
- Coletar feedback qualitativo.
- Ajustar pontos do mapa e tempos de round conforme resultados.
- Verificar estabilidade apos cada rodada de tuning.

### Criterio de aceite

- O jogo sustenta sessoes repetidas de teste com feedback de balanceamento util.

## Etapa 14 - Beta publica e preparo de patching

### Objetivo

Levar a beta a um estado de publicacao controlada e pronta para iteracoes curtas.

### Entregaveis

- Onboarding minimo.
- Checklist de publicacao.
- Estrutura de rollout e hotfix.
- Estatisticas basicas de sessao.
- Procedimento de patch rapido.

### O que sera implementado

- Fluxo de primeira sessao.
- Revisao final de UX para entrada do jogador.
- Rotina de release, monitoramento e correcoes curtas.

### Testes obrigatorios com dotnet

- Manifesto de conteudo coerente.
- Regressao completa antes de release.
- Schemas de evento e analytics sem quebra.

### O que fazer manualmente no Roblox Studio

- Testar publicacao do lugar e configuracoes do experience.
- Validar imagens, descricao, acessos e permissoes.
- Rodar checklist final de smoke test com clientes locais.

### Criterio de aceite

- A beta pode ser publicada e corrigida com cadencia previsivel.

## Ordem de execucao recomendada

1. Etapa 0
2. Etapa 1
3. Etapa 2
4. Etapa 3
5. Etapa 4
6. Etapa 5
7. Etapa 6
8. Etapa 7
9. Etapa 8
10. Etapa 9
11. Etapa 10
12. Etapa 11
13. Etapa 12
14. Etapa 13
15. Etapa 14

## Definicao de pronto por etapa

Uma etapa sera considerada encerrada apenas quando existir:

- implementacao concluida;
- `dotnet test` verde;
- checklist manual do Studio validado;
- sua confirmacao explicita para avancar.

## Proxima etapa proposta

`Etapa 0 - Fundacao tecnica e harness de validacao`

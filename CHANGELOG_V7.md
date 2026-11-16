# EcoLabirinto V7 — alterações em relação à V6

## Correções de maior impacto

1. **Render:** vegetação e solo são desenhados separadamente dos objetos animados, ao criar o mapa. Não redesenhar centenas de árvores a cada deslocamento de inimigo.
2. **Controles:** `player_velocity` com aceleração/fricção em timestep fixo; micro-buffer de E.
3. **Cura:** BFS por tiles conectados + distâncias de perigo. Reavalia a oferta em vida crítica, para evitar bloqueios.
4. **Interface:** cores do guia oficial, tipografia sem serifa legível, HUD mais compacto e coleção em linhas horizontais.
5. **Chefe:** 3 fases, telegraph circular, intervalos de ataque mais longos, HP reduzido, checkpoint na fase final.

## Polimento adicional

- Iluminação local suave durante a noite (personagem e chefe).
- Partículas atmosféricas leves, desligadas em animações reduzidas.
- Hit flash branco discreto, screen shake curto e hit-stop de 55 ms com timer `ignore_time_scale`.
- Seis SFX originais e opção de desativá-los.
- Placar registra identificador `generator_version`.
- Novos testes `qa_v7.gd`, `qa_seeds_v7.gd` e check estático ampliado.

## Não incluído ainda

- Reescrita completa para `TileMapLayer`; a camada estática foi implementada sem trocar a estrutura de grid existente.
- Benchmark de FPS/latência e teste compilado em Godot (executável indisponível neste ambiente).
- Editor interno para adicionar memes (já existe pasta separada para PNGs).
- Sprite sheet de animação para todos os personagens; mantém pixel art existente com feedback pontual.

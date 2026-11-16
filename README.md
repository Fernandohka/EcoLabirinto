# EcoLabirinto — Guardiões da Floresta V7

**Jogo 2D top-down para Godot 4.7.2.** Continuação jogável da V6, com foco em game feel, desempenho, UX e Lobo de Fogo. Não é jogo de tabuleiro: movimento livre em labirintos gerados por seed.

## Abrir

1. Descompacte o ZIP inteiro.
2. No Godot 4.7.2, importe **`Eco/project.godot`**.
3. Espere a primeira importação de `.png` e `.wav`.
4. Execute com **F5**.

**Testes de console (Godot no PATH):**

```bash
godot --headless --path Eco --editor --quit
godot --headless --path Eco --script res://Adventure/smoke_test.gd
godot --headless --path Eco --script res://Adventure/qa_visual.gd
godot --headless --path Eco --script res://Adventure/qa_v7.gd
godot --headless --path Eco --script res://Adventure/qa_seeds_v7.gd
python Eco/check_project.py
```

Se o comando for `godot4`, substitua `godot` por `godot4`.

## Novidades V7

| Área | Mudança |
|---|---|
| Game feel | Movimento com aceleração e desaceleração em `_physics_process` (60 ticks físicos/s por padrão), com diagonais normalizadas. Buffer de E de 140 ms. |
| Desempenho | `terrain_layer.gd` desenha mapa/árvores apenas quando o mundo muda de seed/fase. `world.gd` redesenha apenas objetos dinâmicos a 30 FPS. |
| Visual | `theme_palette.gd` centraliza paleta terrosa brasileira. UI em sans-serif legível, cartões compactos sem scroll no HUD. |
| Coleção | Bestiário usa **uma coluna de cards horizontais**; evita nomes empilhados letra por letra. Scroll permanece apenas nos menus. |
| Atmosfera | `ambient_fx.gd` desenha folhas/vaga-lumes discretos, luz radial noturna do jogador e luz do Lobo na fase final. |
| Feedback | Flash de dano, micro-impacto com timer independente da escala e treme-treme configurável pela opção de animações reduzidas. |
| Curas | Flor da Vida emerge apenas em casa conectada por BFS, longe de fogo, inimigos e chefe. Verifica novamente periodicamente quando a vida está crítica. |
| Chefe | Vida 75/90/105 para Fácil/Médio/Difícil. Três fases legíveis. Aviso circular no solo e 1,8–2,8 s de reação. Incêndios limitados. A fase final é um checkpoint de reinício. |
| Áudio | Seis efeitos simples originais: resgatar, coletar, água, cura, dano e Lobo. Podem ser desligados em Configurações. |
| Seeds e placar | Preservados. Novo campo `generator_version` em recordes para identificar a versão do jogo. |

## Controles

- **WASD / setas**: mover. **Shift**: correr (consome energia).
- **E**: resgatar, coletar, apagar ou interagir.
- **Espaço**: poder exclusivo do guardião, com recarga.
- **TAB**: caderno de missões e detalhes. **ESC**: pausa.
- **Campanha:** 4 tentativas para os cinco capítulos. Derrota ou reinício manual consome tentativa. O início da fase do Lobo funciona como checkpoint; a campanha não volta aos quatro biomas anteriores após uma derrota no chefe.

## Teste rápido da luta

Entre no jogo e escolha **Contra o Relógio → Fácil → Fase 5 (Lobo de Fogo)**. Apague focos de incêndio, resgate animais e recolha lixo para enfraquecer o chefe. O círculo ocre marca o local do próximo fogo. Quando ele for atordoado, haverá uma janela de respiro.

## Arquitetura

- `Adventure/main.gd`: estado da partida, input, física, câmera, SFX, poderes e objetivos.
- `Adventure/world.gd`: procedimentos de seed, IA, ameaças e objetos dinâmicos.
- `Adventure/terrain_layer.gd`: **camada de cenário estático**; cada fase chama `rebuild()` uma única vez.
- `Adventure/theme_palette.gd`: paleta e variações dos biomas.
- `Adventure/interface.gd`: menus, bestiário, HUD, alertas e efeitos de tela.
- `Adventure/player_visual.gd`: desenho do guardião e hit flash.
- `Adventure/ambient_fx.gd`: folhas e vaga-lumes em camada leve.
- `Assets/Audio/`: seis sons originais WAV (não são músicas comerciais).
- `Assets/Animals/Memes/`: pasta para PNGs de animais extras; não afetam missões obrigatórias.

**Fontes:** a interface utiliza fontes sans-serif comuns do sistema em vez de distribuir arquivos de fontes de terceiros. Para títulos pixelizados, escolha no Godot uma fonte licenciada que a equipe tenha direito de usar.

## Checklist de teste da banca

- [ ] F5 abre menu sem erro GDScript, `Parse error`, recursos faltando ou erros de áudio.
- [ ] Janela cheia: texto e imagens organizados; HUD sem rolagem; textos do bestiário horizontais.
- [ ] Player fica na área jogável e não atravessa paredes ao correr na diagonal.
- [ ] Com 30 HP ou menos, o jogo oferece cura próxima e **alcançável**.
- [ ] TAB abre detalhes e ESC pausa; nenhuma sobreposição impede movimentação.
- [ ] Campanha perde uma das quatro tentativas e reinicia fase correspondente.
- [ ] Lobo: aviso visível antes do fogo; três estágios; vidas 75/90/105 nos três modos.
- [ ] Mudar `Animações reduzidas` tira treme-treme e micro-impacto.
- [ ] `Sons: desligados` silencia SFX.
- [ ] A mesma seed reproduz o mapa, inimigos e itens iniciais de um mesmo bioma/dificuldade.
- [ ] Testar FPS com o painel **Depurador → Monitores** (não existe benchmark real deste ambiente).

## Limitações conhecidas / transparência

- **Não foi possível abrir o executável do Godot neste ambiente.** Os scripts foram revisados e verificados por um teste estático de estrutura, mas ainda precisam passar pelo compilador real e pela jogabilidade no Godot 4.7.2 da equipe. Os scripts `qa_*.gd` são entregues para essa validação.
- O terreno está otimizado em uma camada estática própria, **não foi convertido para TileMapLayer**. Isso elimina a recalcificação do cenário no redraw dinâmico, mas a migração a TileMapLayer pode continuar sendo avaliada se benchmarks mostrarem gargalos.
- Sons e partículas são leves e provisórios. Ainda é recomendável realizar testes de mistura sonora, hitboxes, acessibilidade e balanceamento com jogadores antes da banca.
- Não há mecânica de pulo/coyote time porque EcoLabirinto é aventura top-down, não plataforma.

As pastas originais do protótipo (`Map/`, `Player/` etc.) permanecem. O arquivo `README_V6.md` documenta mudanças anteriores.

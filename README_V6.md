# EcoLabirinto V6 — Banca / UX / Boss

Projeto editável no **Godot 4.7.2**. Esta versão mantém a V5 como base e altera a interface e o balanceamento sem criar um jogo de tabuleiro.

## Instalação
1. Descompacte o arquivo `.zip`.
2. Abra o Godot 4.7.2 e importe `Eco/project.godot`.
3. Pressione **F5**.
4. Se abrir uma cópia antiga, feche o editor e importe o `project.godot` **da pasta V6**; não copie só os scripts para a V5.

## O que mudou
- **HUD sem scroll:** barra fixa e mais estreita, nomes e números horizontais, status/missões/poder/tempo/seed/mapa em blocos compactos. As informações adicionais aparecem com **TAB** e o jogo pausa para leitura.
- **Câmera:** foco reposicionado para centralizar o guardião na área jogável, à esquerda do HUD, com zoom mais confortável.
- **Menus:** bestiário em uma coluna horizontal, cards curtos, sem nomes quebrados verticalmente.
- **Tipografia:** títulos usam fonte do sistema em estilo serifa/rústico, com alternativa nativa do Godot para manter compatibilidade. Não é necessária fonte externa.
- **Transições:** avisos de DIA, NOITE, fase e ondas duram aproximadamente 3 segundos, com fundo translúcido. Os efeitos de dano são mais suaves.
- **Cura de emergência:** ao chegar a 38 HP ou menos, pode surgir **Flor da Vida** num piso alcançável próximo ao jogador. Ela pode ser pega com **E** ou encostando nela. Recupera HP e 2 pontos da saúde da floresta. Há um limite por fase; no Fácil, uma última chance automática evita uma derrota inesperada uma vez por fase.
- **Quatro tentativas na Campanha inteira:** não se renovam entre biomas. Morrer gasta uma tentativa; recomeçar manualmente uma fase também gasta uma tentativa. O tutorial não consome tentativas. Ao acabarem as quatro, a campanha termina e é preciso iniciar outra partida. Sprint e Sobrevivência não têm esta regra.
- **Lobo de Fogo:** HP ajustado (90/100/110), velocidade/dano reduzidos, ataques anunciados (sinal visual e texto) e no máximo 3/4/5 focos de fogo ativos, conforme Fácil/Médio/Difícil. Apagar incêndios atordoa e causa dano ao chefe; limpar lixo e salvar animais também reduz sua vida. Não precisa apagar infinitas ondas de fogo para vencer.
- **Cronômetro:** não se devolve tempo ao recomeçar uma fase — mantém a integridade dos recordes da campanha.

## Controles
- WASD / setas: mover
- SHIFT: correr
- **E**: interagir
- ESPAÇO: poder especial
- **TAB**: caderno de missão detalhado (pausa enquanto lê)
- **ESC**: pausa

## Para a banca
- Os recordes e bestiário continuam salvos no computador via `user://`.
- Seeds continuam determinando o estado **inicial** do mapa e dos objetivos para uma fase e dificuldade. A reação dos inimigos muda conforme as ações do jogador.
- A nova arte `Assets/UI/Icons/heal.png` foi criada para a Flor da Vida.
- O modo Fácil é recomendado para demonstração do chefe final; é possível testar diretamente a Fase 5 no modo Contra o Relógio.

## Testes locais no editor
Abrir **F5**, conferir que os nomes estão na horizontal, HUD inteiro sem scroll, TAB funciona, após dano nasce a Flor da Vida, quatro mortes encerram a campanha e o boss anuncia os ataques.

Se tiver o executável do Godot no terminal:
```
godot --headless --path Eco --script res://Adventure/smoke_test.gd
godot --headless --path Eco --script res://Adventure/qa_v6.gd
```

**Validação:** o projeto foi conferido estaticamente, inclusive referências e arquivos de arte. Não foi possível executar o Godot neste ambiente. Estas rotinas precisam ser executadas no computador com Godot antes da banca.

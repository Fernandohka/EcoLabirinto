# EcoLabirinto V7.1 — correção do menu e tipografia

## Corrigido
- Removido corte global de texto com reticências dos `Label` em `Adventure/interface.gd`, introduzido na V7.
- Reservada altura mínima aos títulos, subtítulos e notas, evitando o colapso dos rótulos em `ScrollContainer`.
- Vitrine lateral: altura mínima e título/subtítulo em uma linha.
- Removida a dependência de `SystemFont` com nomes de fontes Linux possivelmente ausentes no Windows. Os títulos agora usam a mesma fonte de fallback confiável dos botões.
- Menu principal com painel de altura limitada e centrado verticalmente.
- Seleção dos quatro personagens com cartões que se adaptam à largura disponível.
- Campo de seed com largura adaptável; menus mantêm rolagem vertical somente quando necessária.
- Corte com reticências permanece somente nos indicadores curtos da HUD.

## Como validar no Godot 4.7.2
Abra `Eco/project.godot`, pressione F5 e confira no Menu Principal: título `ECO LABIRINTO`, selo `ODS 15`, descrição, botões e chamada lateral. Teste também Bestiário, Personagens, Modos e Placar.

Para executar verificações pelo terminal a partir da pasta onde está `Eco/`:
```bash
godot --headless --path Eco --editor --quit
godot --headless --path Eco --script res://Adventure/qa_menu_v7_1.gd
godot --headless --path Eco --script res://Adventure/qa_v7.gd
```

**Estado dos testes:** verificações estáticas executadas aqui, sem erros; compilação e execução do Godot 4.7.2 não executadas porque o binário não está disponível neste ambiente.

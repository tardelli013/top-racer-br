# Top Racer BR — Top Gear Brasil (protótipo)

Protótipo jogável de corrida arcade pseudo-3D (estilo OutRun / Top Gear de 16 bits), feito em **Godot 4.3+** com GDScript. Direção de arte inspirada em `exemplo_visual.png`.

- 1 carro: Fiat Uno Mille branco de firma, com bagageiro e escada de alumínio no teto
- 1 pista de circuito fechado (litoral urbano estilizado), 3 voltas, 6 adversários com IA
- Largada com contagem, HUD (velocidade, posição, volta, tempo, minimapa), pausa, reinício e tela de resultado
- Toda a arte é gerada por código (sem assets externos, sem problemas de licença)

## Como executar

1. Instale o [Godot 4.3 ou superior](https://godotengine.org/download) (testado com 4.7.2).
2. Abra a pasta do projeto no Godot (`project.godot`) e pressione F5, ou rode:

```
godot --path .
```

### Controles

| Tecla | Ação |
| --- | --- |
| `W` / Seta para cima | Acelerar |
| `S` / Seta para baixo | Frear / ré |
| `A` `D` / Setas | Virar |
| `Esc` | Pausar / retomar |
| `R` | Reiniciar corrida |
| `Enter` | Iniciar (menu) / correr novamente |

## Estrutura

- `scripts/track.gd`: pista definida em dados (lista de trechos), cenário lateral e minimapa
- `scripts/road_renderer.gd`: renderização pseudo-3D por segmentos em 320×180 (nearest), parallax e sprites
- `scripts/sprite_factory.gd`: sprites pixel art procedurais (Uno, adversários, palmeiras, placas, prédios)
- `scripts/race.gd`: física arcade, IA, colisões, checkpoints/voltas, posição e estados
- `scripts/hud.gd`: HUD, menu e resultado (1280×720)
- `scripts/main.gd`: monta a cena
- `tests/sim.gd`: simulação automatizada (autopiloto dá as 3 voltas)

## Testes

```
godot --headless --fixed-fps 60 --path . res://tests/sim.tscn
```

Imprime o progresso e termina com `FINISHED pos=... time=...` ao completar as 3 voltas.

## Exportação Web

1. No Godot: *Projeto > Exportar > Adicionar... > Web* e instale os templates de exportação.
2. Exporte para `build/index.html`.
3. Publicação no GitHub Pages: envie o conteúdo de `build/` para a branch `gh-pages` (ou use uma action de deploy).

Limitações: o áudio na Web exige interação do usuário (o jogo não usa áudio ainda) e, se habilitar threads, o servidor precisa enviar os cabeçalhos COOP/COEP (GitHub Pages não envia; use export sem threads). Nenhum deploy foi feito nem testado.

## Limitações conhecidas

- Sem áudio e sem fonte pixel (usa a fonte padrão do Godot no HUD).
- Pista sem colinas; sem chuva, noite, nitro, combustível, campeonato ou seleção de carros (a arquitetura permite adicionar).
- Export Web não testado.

## Licença

Este projeto está sob a licença [MIT](LICENSE).

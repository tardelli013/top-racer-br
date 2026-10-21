# Prompt para Claude Code / Codex — Protótipo Pseudo-3D "Top Gear Brasil"

## Papel

Atue como desenvolvedor sênior de jogos com experiência em Godot 4, GDScript, corridas arcade pseudo-3D (estilo OutRun / Top Gear / Lou's Pseudo-3D), pixel art procedural e exportação Web. Implemente no repositório aberto um protótipo jogável, não apenas plano, mockup ou cena estática.

## Referência visual (obrigatória)

Abra e estude `exemplo_visual.png` na raiz do repositório antes de começar. Ela é a referência de **direção de arte**; não precisa ser copiada pixel a pixel. Extraia dela:
- **Estilo:** pixel art 16 bits, cores saturadas, contornos escuros, pouca paleta por elemento, sem filtragem suave.
- **Perspectiva:** pista em pseudo-3D (estrada em faixas horizontais que se estreitam até o horizonte), carros e objetos como sprites que escalam com a distância.
- **Cenário:** céu em degradê com nuvens, horizonte com morros (um estilo "Pão de Açúcar"), mar/litoral, prédios distantes, palmeiras e placas laterais.
- **Pista:** faixas alternando tons de asfalto, linha central tracejada, zebras vermelhas e brancas nas curvas, setas/placas de curva.
- **HUD:** velocímetro com número grande em km/h e barra segmentada, posição grande (ex.: `3º`) em um canto, volta atual/total, tempo e minimapa simples do traçado.
- **Menu:** logo "TOP GEAR BRASIL" estilizado (pode ser em texto com contorno/degradê), fundo de pôr do sol com palmeiras, opção "Iniciar corrida" e controles.

Se o PNG não estiver acessível, siga a descrição acima e avise.

## Abordagem técnica decidida (a mais barata e fiel)

Use **Godot 4.x estável + GDScript, em 2D, com renderização pseudo-3D por segmentos**. Motivos: é a técnica original desse tipo de jogo, é leve para Web, não exige modelagem 3D, física nem câmera 3D, e fica naturalmente próxima da imagem.

Não use 3D real (Node3D, malhas, VehicleBody). Só mude de abordagem se justificar por escrito que a pseudo-3D é inviável.

Detalhes:
- **Resolução interna baixa e fixa de 320×180 (16:9)** em um `SubViewport` (ou `stretch mode viewport`), ampliada com filtro **nearest** e escala inteira quando possível, com barras pretas se necessário. HUD legível em 1280×720.
- A pista é uma lista de **segmentos** (z, curvatura, altura/colinas leves, cor). A cada frame, projete os segmentos visíveis (distância de visão ~150–300 segmentos) e desenhe polígonos com `draw_polygon`/`draw_rect`, do mais distante ao mais próximo. Se o desempenho cair, desenhe em uma `Image`/textura por scanline.
- Curvas: acumule a curvatura por segmento e desloque x (efeito OutRun). Colinas: opcionais e suaves; priorize curvas.
- Fundo em **parallax** (céu, morros, cidade/mar) que se desloca horizontalmente conforme a curva.
- Objetos laterais (palmeiras, placas, postes, prédios) e carros adversários são **sprites** posicionados por segmento, escalados pela projeção e cortados pela linha do horizonte.
- Zebras vermelhas/brancas nas bordas dos segmentos de curva; setas de curva como sprites laterais.

## Arte e assets

- Gere a arte **proceduralmente ou com sprites pixel art originais** feitos no próprio projeto (via código, `Image`, ou PNGs pequenos criados por script). Não copie assets da imagem de referência nem de jogos comerciais, e não baixe nada sem licença clara (registre origem e licença).
- **Carro do jogador: Fiat Uno Mille branco de firma**, visto de trás, em pixel art (~48×32 px ou equivalente): hatch quadrado, vidro traseiro escuro, lanternas vermelhas, para-choque escuro, pneus visíveis, **bagageiro e escada de alumínio no teto** claramente visíveis. Inclua variações simples: virando esquerda/direita (deslocamento/inclinação dos sprites) e pequena vibração em alta velocidade.
- Adversários: 5 a 7 carros de cores diferentes, silhueta de hatch/sedã genérica (não precisam ser modelos reais).
- Paleta consistente, máximo de ~32 cores para a cena, mais um acento de arcade na interface.
- Fonte: pixel/bitmap (crie por código ou use fonte livre com licença registrada).

## Escopo desta primeira versão

Construa somente:
- **1 carro jogável** (Uno) e **1 pista de circuito fechado**, **3 voltas**, **6 adversários** controlados por IA.
- Cenário: **litoral urbano brasileiro estilizado** (mar, morro, prédios, palmeiras) conforme a referência. Chuva, noite, nitro, combustível, campeonato, seleção de carros e créditos ficam **fora do escopo**, mas a arquitetura deve permitir adicioná-los.
- Largada com contagem regressiva, voltas, linha de chegada e tela de resultado.
- HUD em português e menu inicial simples.

Não implemente ROM/emulador, multiplayer, tuning, economia ou qualquer coisa fora do escopo. Não pare após o plano: implemente, teste e corrija.

## Jogabilidade

- Modelo arcade: aceleração, frenagem, ré, velocidade máxima (~240 km/h exibidos), desaceleração natural.
- Curvas empurram o carro para fora (força centrífuga proporcional à velocidade × curvatura); o jogador compensa com a direção.
- Sair do asfalto reduz fortemente a velocidade e faz o carro balançar; ao ficar parado fora da pista, deve ser possível voltar.
- Colisão com adversários (perda de velocidade e leve empurrão) e com objetos laterais sólidos (placas/postes, se houver).
- IA: cada adversário segue uma linha com offset lateral próprio, velocidade-alvo diferente por carro, desacelera nas curvas, e pode ser ultrapassado. Leve "rubber banding" opcional e discreto para manter a corrida disputada. Não podem ficar parados nem aleatórios.
- Circuito fechado com checkpoints e contagem correta de voltas; posição calculada por volta + progresso.
- Pausa e reinício.

Controles: `W`/↑ acelera, `S`/↓ freia/ré, `A`/`D` ou ←/→ viram, `Esc` pausa, `R` reinicia. Mostre-os no menu.

## Interface e áudio

- Todo texto em português brasileiro.
- HUD no estilo da referência: velocidade grande com barra segmentada, posição (`3º`), volta (`1/3`), cronômetro, minimapa do traçado com pontos dos carros.
- Menu: título "TOP GEAR BRASIL" (provisório), "Iniciar corrida", controles.
- Resultado: posição final, tempo total, melhor volta e "Correr novamente".
- Áudio: opcional. Se quiser, gere beeps/motor simples por `AudioStreamGenerator` (som próprio); não baixe músicas protegidas. Sem áudio é aceitável.

## Tecnologia e arquitetura

- Godot 4.3+ (registre a versão usada em `project.godot` e no README), GDScript tipado quando possível, sem plugins.
- Estrutura sugerida: `scenes/` (menu, corrida, HUD, resultado), `scripts/` (`track.gd` geração/projeção de segmentos, `road_renderer.gd`, `player_car.gd`, `ai_car.gd`, `race_manager.gd`, `hud.gd`, `parallax_bg.gd`, `sprite_factory.gd`), `assets/`, `docs/`.
- Defina a pista em dados (lista de trechos: comprimento, curvatura, colina), para facilitar novas pistas.
- Evite um script gigante; separe lógica de corrida, renderização e UI.
- Meta de desempenho: 60 FPS no desktop e ≥30 FPS no export Web em notebook comum; build Web idealmente < 40 MB.
- Prepare exportação Web (preset em `export_presets.cfg` se possível) e documente os passos para GitHub Pages e as limitações (threads/headers, áudio exigindo interação do usuário), sem afirmar que fez deploy se não fez.

## Processo obrigatório de trabalho

1. Audite o repositório (hoje contém basicamente README, LICENSE, a imagem e este prompt). Preserve o que existe.
2. Apresente um plano curto e siga por **marcos**, deixando cada um executável:
   - **M1:** pista pseudo-3D com curvas, zebras, parallax e carro do Uno dirigindo.
   - **M2:** adversários com IA, colisões, checkpoints e voltas.
   - **M3:** HUD, menu, contagem, pausa/reinício, resultado.
   - **M4:** polimento visual segundo a referência, Web e documentação.
3. Se o Godot estiver instalado, valide com `godot --headless --quit` (ou `--check-only` por script) e corrija erros. Se um screenshot puder ser gerado, compare com `exemplo_visual.png` e ajuste cores/proporções.
4. Teste o fluxo: abrir, iniciar, acelerar, virar, sair da pista, colidir, completar 3 voltas, ver resultado, reiniciar.
5. Seja transparente sobre o que não pôde executar; forneça comandos exatos para testar localmente. Nunca afirme ter testado o que não rodou.
6. Sem pseudocódigo, funções vazias, botões sem ação ou TODOs em funcionalidades essenciais.
7. Ao final, resuma arquivos, comandos, testes, limitações e próximos passos.

## Critérios de aceite

- O projeto abre sem erros de scripts/recursos conhecidos.
- Visual claramente na linha da referência: pixel art, pista pseudo-3D com faixas, zebras, céu/morros/mar em parallax, sprites laterais e HUD arcade.
- O Uno branco com bagageiro e escada é reconhecível.
- Corrida completa de 3 voltas com 6 adversários que seguem a pista e podem ser ultrapassados.
- Curvas, saída da pista, colisões, voltas, chegada, pausa e reinício funcionam.
- Menu, HUD e resultado em português e legíveis em 16:9 sem distorção.
- README com instruções de execução, versão do Godot, créditos/licenças de assets e passos de exportação Web (sem alegar deploy não feito).

## Prioridades se houver limitações

1. Corrida jogável e estável.
2. Pista pseudo-3D com curvas e sensação de velocidade.
3. Carro do jogador reconhecível.
4. Adversários e voltas.
5. HUD/menu.
6. Fidelidade visual à referência (parallax, palmeiras, prédios, polimento).
7. Exportação Web e documentação.

Não amplie o escopo. Faça escolhas simples, consistentes e testáveis: o objetivo é uma base pequena e sólida, com visual promissor, sobre a qual possam ser adicionados os outros carros brasileiros, novas pistas, nitro, combustível e campeonato.

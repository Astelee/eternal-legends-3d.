# Arqueiro (piloto) — estado e pendências

## O que está implementado (código)
- `SpriteCache`: cache único de texturas.
- `CharacterDefs`: dados do personagem (animações com status, soquetes por quadro, ordem de camadas por direção, visuais de equipamento).
- `LayeredCharacter`: personagem em camadas, pivô nos pés, Sprite2D nearest, âncoras por soquete.
- `Player`: usa `LayeredCharacter` quando a classe tem dados (hoje só o arqueiro); o resto continua igual.
- Mochila: retrato composto com o mesmo `Game.equipped` do mundo.

## Aprovado
- Altura lógica 40 px (48 px só para comparação). Quadro frontal parado: `source/front_idle_r1f2.png` → `base/front_idle.png`.

## PENDENTE (não existe, não foi inventado)
| Item | Situação |
|---|---|
| Walk / Run (4 dir.) | Sem ciclo. Quadros 7–12 proibidos como caminhada. Hoje: pose parada, sem balanço. |
| Direção cima (costas) | Nenhum quadro. |
| Lateral | Candidatos 3, 4, 6 (3/4) aguardam aprovação. Quadro 3 tem artefato no rosto. |
| Attack / Skill | Sem quadros limpos (linhas 3–5 do atlas misturam corpo e efeito). O disparo funciona por código; o corpo não anima. |
| Hit / Death | Sem quadros. Hit = só tinta vermelha; morte = só tinta cinza (sem tombar). |
| Arco na mão | Camada pronta, **desligada** (`enabled:false`): o quadro frontal não segura o arco. |
| Camadas de equipamento | Corpo único. Capacete, peitoral, luvas, botas e cabelo precisam ser desenhados por camada, alinhados a cada quadro. |
| Âncoras (`sockets`) | Estimadas (`validated:false`). |

## Para o artista (por animação/direção)
Mesmo tamanho de quadro, pés no mesmo ponto, fundo transparente, ~40 px de altura, 4 quadros no mínimo por ciclo de walk, 6 por run, 4–5 por attack.
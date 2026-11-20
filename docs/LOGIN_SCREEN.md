# Tela de login — Eternal Legends

Cena principal: `scenes/login/login_screen.tscn` (definida como `main_scene`).
Depois de entrar, abre a seleção permanente de classe (`ClassSelect`) se a conta ainda não tiver classe; só então carrega `scenes/main/main.tscn`.

## Estrutura
- `scripts/login/login_screen.gd` — layout, animações, navegação entre janelas.
- `scripts/login/windows/` — `LoginForm`, `RegisterWindow`, `RecoveryWindow`, `LegalWindow`, `NewsHistoryWindow`, `NewsDetailWindow`.
- `scripts/login/news/` — `NewsPanel`, `NewsCard`.
- `scripts/login/ui/` — `PixelPanel`, `PixelButton`, `PixelField`, `PixelCheck`, `FormMessage`, `ModalWindow`.
- `scripts/login/services/` — `AuthService` (HTTP), `ProfileService` (classe da conta), `NewsRepository`, `NewsCategories`.
- `scripts/class_select/` — `ClassSelect` (tela "Escolha seu destino") e `ClassCard`.
- `scripts/login/core/` — tema, validações, sessão, preferências, movimento.
- `tools/gen_login_assets.py` — gera todos os PNGs em `assets/ui/login/` (exceto `login_bg.png`, que é o seu cenário original, sem alterações).

## Backend (Firebase)
Login, cadastro e recuperação de senha usam o Firebase Authentication por REST; perfil e classe ficam no Firestore.
Nada é simulado: sem `firebase/api_key` e `firebase/project_id` (project.godot) as telas mostram erro.
Passo a passo, regras de segurança e como virar GM: `docs/FIREBASE.md`. Regras: `firebase/firestore.rules`.

Login é só por e-mail. O token fica só em memória (`Session`); só o identificador do "Lembrar-me" é salvo em `user://login.cfg`.

## Atualizações
Hoje vêm de `data/news.json` (todas marcadas `is_demo: true`, exibidas com selo EXEMPLO).
Para o painel administrativo: defina `eternal_legends/news/url` (ou `EL_NEWS_URL`) para uma API que devolva `{"items": [...]}` no mesmo formato. Categorias em `news_categories.gd`.

## Termos e Política
Preencha `data/legal/terms_of_service.json` e `privacy_policy.json` (`sections: [{heading, body}]`). Vazios, mostram aviso de texto pendente.

## Fonte e movimento
- Fonte pixelada opcional: coloque um .ttf livre em `assets/fonts/pixel.ttf`.
- Redução de movimento: lida do navegador na exportação Web; nas demais plataformas, use o botão "Animações" no rodapé (o Godot não expõe a configuração do sistema).
- Atalho `[DEBUG] entrar sem servidor`: só em build de debug; remova com `ALLOW_DEBUG_SKIP := false`. Ele pula login e seleção de classe e usa o cache local; nunca publique com ele ligado.

## Classe permanente da conta
A classe pertence à CONTA e é protegida pelas regras do Firestore (`players/<uid>.class_id`): só o dono grava,
só uma vez, e não existe regra para trocar. `user://profile.cfg` guarda apenas cache visual que o login sobrescreve.
Detalhes em `docs/FIREBASE.md`.
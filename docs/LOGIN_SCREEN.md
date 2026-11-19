# Tela de login — Eternal Legends

Cena principal: `scenes/login/login_screen.tscn` (definida como `main_scene`).
Depois de entrar, carrega `scenes/main/main.tscn`. A escolha de classe continua dentro do jogo.

## Estrutura
- `scripts/login/login_screen.gd` — layout, animações, navegação entre janelas.
- `scripts/login/windows/` — `LoginForm`, `RegisterWindow`, `RecoveryWindow`, `LegalWindow`, `NewsHistoryWindow`, `NewsDetailWindow`.
- `scripts/login/news/` — `NewsPanel`, `NewsCard`.
- `scripts/login/ui/` — `PixelPanel`, `PixelButton`, `PixelField`, `PixelCheck`, `FormMessage`, `ModalWindow`.
- `scripts/login/services/` — `AuthService` (HTTP), `NewsRepository`, `NewsCategories`.
- `scripts/login/core/` — tema, validações, sessão, preferências, movimento.
- `tools/gen_login_assets.py` — gera todos os PNGs em `assets/ui/login/` (exceto `login_bg.png`, que é o seu cenário original, sem alterações).

## Backend de autenticação
Nada é simulado: sem servidor configurado o login/cadastro/recuperação mostram erro.
Configure `eternal_legends/auth/base_url` (project.godot) ou a variável `EL_AUTH_URL`.

Endpoints (JSON, POST):
- `/auth/login` `{identifier, password, remember}` → 200 `{token, username?}`
- `/auth/register` `{username, email, password, accepted_terms, accepted_privacy}` → 2xx (com `token` entra direto; sem `token`, volta ao login)
- `/auth/password-reset` `{email}` → 2xx (responda sempre igual, exista ou não o e-mail)

Erros: 400/422 `{message?, errors: {campo: mensagem}}` (campos: identifier, password, username, email), 401, 409, 429, 5xx.
O token fica só em memória (`Session`); só o identificador do "Lembrar-me" é salvo em `user://login.cfg`.

## Atualizações
Hoje vêm de `data/news.json` (todas marcadas `is_demo: true`, exibidas com selo EXEMPLO).
Para o painel administrativo: defina `eternal_legends/news/url` (ou `EL_NEWS_URL`) para uma API que devolva `{"items": [...]}` no mesmo formato. Categorias em `news_categories.gd`.

## Termos e Política
Preencha `data/legal/terms_of_service.json` e `privacy_policy.json` (`sections: [{heading, body}]`). Vazios, mostram aviso de texto pendente.

## Fonte e movimento
- Fonte pixelada opcional: coloque um .ttf livre em `assets/fonts/pixel.ttf`.
- Redução de movimento: lida do navegador na exportação Web; nas demais plataformas, use o botão "Animações" no rodapé (o Godot não expõe a configuração do sistema).
- Atalho `[DEBUG] entrar sem servidor`: só em build de debug; remova com `ALLOW_DEBUG_SKIP := false`.
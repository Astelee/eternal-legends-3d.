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
- Atalho `[DEBUG] entrar sem servidor`: só em build de debug; remova com `ALLOW_DEBUG_SKIP := false`. Ele pula login e seleção de classe e usa o cache local; nunca publique com ele ligado.

## Classe permanente da conta (backend obrigatório)
A classe pertence à CONTA e é protegida pelo SERVIDOR. O cliente só consulta e pede a gravação;
`user://profile.cfg` guarda apenas um cache visual que o login sobrescreve. Sem estes dois endpoints
a proteção não existe: o app mostra erro e não deixa entrar no mundo.

Ids válidos: `warrior`, `archer`, `mage`. Autenticação: cabeçalho `Authorization: Bearer <token>`.
A conta é sempre a do token; o corpo nunca informa de qual conta é.

- `GET /profile/class` → 200 `{"class_id": null}` (ainda não escolheu) ou `{"class_id": "warrior"}`.
- `POST /profile/class` `{"class_id": "warrior"}`
  - 200/201 `{"class_id": "warrior"}` — gravou agora (primeira vez).
  - 409 `{"class_id": "archer"}` — a conta já tinha classe; devolve a oficial e NÃO altera nada.
  - 400/422 — id fora da lista. 401 — token inválido/expirado.

Regra de gravação (única, atômica, no banco). Exemplo SQL:

```sql
ALTER TABLE accounts ADD COLUMN class_id TEXT NULL
  CHECK (class_id IN ('warrior', 'archer', 'mage'));

-- 1 linha afetada = gravou. 0 linhas = já existia: responda 409 com o valor atual.
UPDATE accounts SET class_id = :class_id
 WHERE id = :account_id_do_token AND class_id IS NULL;
```

O `WHERE class_id IS NULL` garante que duas solicitações simultâneas gravem só uma. Não ofereça
nenhuma rota de PUT/PATCH/DELETE para `class_id`; trocar classe só por intervenção administrativa direta.
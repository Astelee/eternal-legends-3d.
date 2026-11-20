# Firebase — contas, classe permanente e GM (Eternal Legends)

Tudo é feito pelo navegador do celular. O jogo fala com o Firebase por REST; não há servidor próprio
nem arquivo `google-services.json`.

## 1. Criar o projeto (uma vez)
1. Abra https://console.firebase.google.com e crie um projeto.
2. **Build > Authentication > Começar > Método de login > E-mail/senha > Ativar > Salvar**.
3. **Build > Firestore Database > Criar banco de dados** (modo produção, escolha a região).
4. Aba **Regras** do Firestore: apague tudo, cole o conteúdo de `firebase/firestore.rules` e toque em **Publicar**.
5. Engrenagem > **Configurações do projeto > Geral**: copie o **ID do projeto** e a **Chave de API da Web**.
6. No GitHub, edite `project.godot` e preencha na seção `[eternal_legends]`:
   ```
   firebase/api_key="COLE_A_CHAVE_AQUI"
   firebase/project_id="COLE_O_ID_AQUI"
   ```
   A chave Web não é segredo; quem protege os dados são as regras do passo 4.

## 2. Como o jogo usa o Firebase
- Cadastro: e-mail + senha no Firebase Authentication; o nome de usuário vira o nome de exibição. Senha: mínimo 6 caracteres.
- Login: **só por e-mail** (o Firebase não entra por nome de usuário).
- Perfil: documento `players/<uid>` no Firestore, criado no primeiro login, com `class_id` vazio.
- Classe: o jogo grava `class_id` uma vez. As regras negam qualquer segunda gravação, de qualquer aparelho,
  e negam alterar a conta de outra pessoa. Duas gravações ao mesmo tempo: só a primeira passa.
- Recuperar senha: o Firebase envia o e-mail de redefinição.

## 3. Virar GM
1. Crie sua conta pelo jogo (cadastro com seu e-mail).
2. Console > **Authentication > Usuários**: copie o **UID** da sua conta.
3. Console > **Firestore Database > Iniciar coleção**: ID da coleção `gms`, ID do documento = seu UID,
   campo `enabled` (boolean) = `true` > Salvar.
4. Entre no jogo: o crachá mostra **[GM]**.

Só o console consegue criar documentos em `gms`; o app não. Hoje o GM aparece no crachá e pode ler o perfil de
qualquer jogador (regras). Poderes de GM no jogo (comandos, teleporte etc.) ainda não existem e, quando existirem,
precisam ser validados pelas regras do Firestore, nunca só pelo cliente.

## 4. Limites conhecidos
- O token de sessão dura cerca de 1 hora. Depois disso o jogo pede para entrar de novo (renovação automática ainda não implementada).
- O nome de usuário não é único (dois jogadores podem usar o mesmo nome).
- Confirmação de e-mail não é exigida.
# Flutter Auth Screens + Supabase Auth Integration

**Data:** 2026-03-22
**Fase:** 1 — Identity and Foundation
**Requisitos:** AUTH-01, AUTH-04 (AUTH-02/03 diferidos para fase futura)

## Decisoes

- Email/password + forgot-password. Sem social login (Google/Apple diferidos).
- Auth via Supabase SDK direto (permitido por mobile.md) em vez de via backend Fastify, pois o SDK gerencia JWT refresh, session persistence e auth state changes nativamente. Os endpoints em auth.routes.ts existem para uso futuro (mobile-to-backend auth proxy nao e necessario).
- Flutter → Backend Fastify para CRUD e logica de negocio.
- TDD obrigatorio — testes primeiro, implementacao depois.
- Riverpod para state management, GoRouter para navegacao.
- AUTH-04 (session persistence) satisfeito por: `Supabase.initialize()` restaura sessao automaticamente + GoRouter redirect verifica `currentSession` no boot. Nao ha SplashScreen dedicado — GoRouter resolve a rota inicial baseado no estado da sessao.

## Estrutura de Arquivos

```
lib/
├── core/
│   ├── theme/                          (existente — sem alteracao)
│   ├── router/
│   │   └── app_router.dart             GoRouter com auth redirect
│   └── supabase/
│       └── supabase_config.dart        init Supabase + leitura de env
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart    wrapper sobre Supabase Auth SDK
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_text_field.dart input reutilizavel com estado de erro
│   │   └── providers/
│   │       └── auth_provider.dart      Riverpod — sessao + acoes de auth
│   └── agenda/                         (existente — sem alteracao)
└── main.dart                           atualizado: Supabase init + ProviderScope + GoRouter
```

## Fluxo de Dados

```
Screen → Provider (Riverpod) → AuthRepository → Supabase Auth SDK
```

## Telas

### LoginScreen — `/login`

- Logo Oriz centralizado no topo
- Campo email (validacao: formato email)
- Campo senha (validacao: min 8 chars)
- Botao primario "Entrar" (1 por tela)
- Ghost link "Criar conta" → `/signup`
- Ghost link "Esqueci senha" → `/forgot-password`
- Estados: formulario (default), loading (spinner no botao, campos desabilitados), erro (inline nos campos + toast)
- Rate limit visual: apos 3 tentativas falhas consecutivas, desabilitar formulario por 30s com mensagem "Muitas tentativas. Aguarde antes de tentar novamente."
- Sucesso: redirect para `/agenda`

### SignupScreen — `/signup`

- Top bar: seta voltar + titulo "Criar conta"
- Campo nome completo (validacao: min 1 char)
- Campo email (validacao: formato email)
- Campo senha (validacao: min 8 chars)
- Botao primario "Criar conta"
- Ghost link "Ja tem conta? Entrar" → `/login`
- Erros inline: 409 email ja existe, 400 senha fraca
- Sucesso: redirect para `/agenda`

### ForgotPasswordScreen — `/forgot-password`

- Top bar: seta voltar + titulo "Recuperar senha"
- Texto descritivo: "Informe seu email e enviaremos instrucoes para redefinir."
- Campo email
- Botao primario "Enviar instrucoes"
- Sucesso: mensagem generica "Se o email existir, enviaremos instrucoes." (nunca revelar se email existe)

## AuthRepository

Wrapper fino sobre `supabase_flutter` — sem logica de negocio:

| Metodo | SDK Call |
|--------|----------|
| `signUp(email, password, fullName)` | `supabase.auth.signUp(data: {full_name})` |
| `signIn(email, password)` | `supabase.auth.signInWithPassword()` |
| `signOut()` | `supabase.auth.signOut()` |
| `resetPassword(email)` | `supabase.auth.resetPasswordForEmail()` |
| `authStateChanges` | `supabase.auth.onAuthStateChange` stream |
| `currentSession` | `supabase.auth.currentSession` |

## Router (GoRouter)

- Rotas publicas: `/login`, `/signup`, `/forgot-password`
- Rotas protegidas: `/agenda` (e todas as futuras)
- Redirect logic:
  - Sem sessao → qualquer rota protegida redireciona para `/login`
  - Com sessao → rotas de auth redirecionam para `/agenda`
- Estado da sessao via `onAuthStateChange` stream → Riverpod provider → GoRouter `refreshListenable`
- Rota inicial `/`: GoRouter resolve para `/agenda` (com sessao) ou `/login` (sem sessao) — sem SplashScreen dedicado
- Migracao de `MaterialApp` para `MaterialApp.router`. Bottom nav via GoRouter `ShellRoute` wrapping rotas protegidas

## Provider (Riverpod)

```dart
// Estado
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { final Session session; }
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState { final String message; }
class AuthActionSuccess extends AuthState { final String message; }
```

- `AuthActionSuccess` para acoes sem autenticacao (ex: resetPassword sucesso → mostra mensagem → volta para `AuthUnauthenticated`)
- Provider escuta `authStateChanges` do repositorio
- Metodos: `signIn()`, `signUp()`, `signOut()`, `resetPassword()`
- Cada metodo transiciona: current → loading → success/error
- `resetPassword`: loading → `AuthActionSuccess` → (apos exibir mensagem) `AuthUnauthenticated`
- Login: contador de falhas consecutivas. Apos 3 falhas, emite `AuthError` com flag `rateLimited = true`

## Design System (tokens existentes)

- Botao primario: bg `AppColors.primary`, text white, h48, radius `AppRadius.md`
- Input: bg `AppColors.neutral100`, border `AppColors.neutral200`, focus border `AppColors.primary`, h48, radius `AppRadius.md`
- Label: `AppTypography.caption`, cor `AppColors.neutral600`
- Erro inline: border `AppColors.error`, texto `AppColors.error` em `AppTypography.caption`
- Espacamento entre campos: `AppSpacing.md` (16px)
- Padding horizontal da tela: `AppSpacing.lg` (24px)
- Toast de erro: persiste ate fechar manualmente
- Haptic: `lightImpact` no tap de botao, `mediumImpact` no sucesso
- Spinner inline no botao: cor `AppColors.accent` (gold), 20px
- Campos de senha: icone de olho para toggle de visibilidade
- Keyboard: `TextInputType.emailAddress` para email, `TextInputAction.next` para encadear campos, auto-dismiss no submit
- Form dentro de `SingleChildScrollView` para evitar overflow com teclado aberto

## Estrategia de Testes (TDD)

### Unit Tests

**auth_repository_test.dart**
- Mock do Supabase Auth client (`GoTrueClient`)
- `signUp` chama `supabase.auth.signUp` com parametros corretos
- `signIn` chama `supabase.auth.signInWithPassword` com parametros corretos
- `resetPassword` chama `supabase.auth.resetPasswordForEmail`
- `signOut` chama `supabase.auth.signOut`
- Erros do SDK (`AuthException`) propagam corretamente

**auth_provider_test.dart**
- Mock do AuthRepository
- Estado inicial: `AuthInitial`
- `signIn` sucesso: `AuthLoading` → `AuthAuthenticated`
- `signIn` erro: `AuthLoading` → `AuthError`
- `signUp` sucesso: `AuthLoading` → `AuthAuthenticated`
- `signOut`: `AuthAuthenticated` → `AuthUnauthenticated`
- `authStateChanges` stream atualiza estado

### Widget Tests

**login_screen_test.dart**
- Renderiza campos email e senha
- Renderiza botao "Entrar" e links de navegacao
- Validacao: email vazio mostra erro inline
- Validacao: senha < 8 chars mostra erro inline
- Botao desabilitado durante loading
- Spinner visivel durante loading
- Mensagem de erro exibida apos falha
- Tap em "Criar conta" navega para `/signup`
- Tap em "Esqueci senha" navega para `/forgot-password`

**signup_screen_test.dart**
- Renderiza campos nome, email, senha
- Validacao: nome vazio mostra erro
- Validacao: email invalido mostra erro
- Validacao: senha < 8 chars mostra erro
- Loading state: spinner + campos desabilitados
- Erro 409: mostra "Email ja cadastrado"
- Tap em "Ja tem conta?" navega para `/login`

**forgot_password_screen_test.dart**
- Renderiza campo email e botao
- Validacao: email vazio mostra erro
- Loading state durante envio
- Sucesso: mostra mensagem generica
- Nunca revela se email existe

### Router Tests

**app_router_test.dart**
- Sem sessao: rota `/agenda` redireciona para `/login`
- Com sessao: rota `/login` redireciona para `/agenda`
- Rotas publicas acessiveis sem sessao

## Dependencias a Adicionar

```yaml
dependencies:
  supabase_flutter: ^2.x
  flutter_riverpod: ^2.x
  go_router: ^14.x

dev_dependencies:
  mocktail: ^1.x
```

## Fora de Escopo

- Social login (Google/Apple) — fase futura
- Magic link — descartado
- SplashScreen animado — AUTH-04 satisfeito por Supabase session restore + GoRouter redirect
- Onboarding wizard — proximo passo apos auth
- Coleta de telefone no signup — coletado no onboarding ou perfil, nao no cadastro
- i18n — diferido

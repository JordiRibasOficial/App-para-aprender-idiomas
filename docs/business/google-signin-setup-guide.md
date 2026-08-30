# Guía de configuración — Google Sign-In

> Guía de ejecución directa por tu parte — necesitas una cuenta de Google Cloud
> (gratuita) y acceso al proyecto de Supabase. No hay ninguna API por la que
> yo pueda crear estas credenciales por ti; una vez las tengas, el código para
> usarlas ya está preparado y solo falta pegar los valores reales en los
> sitios marcados como `[PENDIENTE]`.

## Por qué 3 credenciales, no 1

El flujo nativo que usa la app (`google_sign_in` en el dispositivo +
`Supabase Auth.signInWithIdToken`, no un navegador/redirect) necesita **tres**
Client IDs de OAuth, uno por plataforma, aunque los tres pertenezcan al mismo
proyecto de Google Cloud:

| Client ID | Para qué sirve | Dónde se usa |
|---|---|---|
| **Web** | Es el `serverClientId` que el SDK nativo de Android/iOS necesita para obtener un ID token que **Supabase** (el servidor, no el dispositivo) pueda verificar. Se pega igual en Android e iOS. | `GoogleSignIn(serverClientId: ...)` en el código Flutter, y en Supabase Dashboard → Authentication → Providers → Google. |
| **Android** | Identifica la app Android ante Google — requiere el nombre del paquete (`com.webapps.app_para_aprender_idiomas` o el que use el build de release) y el **SHA-1** del certificado de firma. | Se registra en Google Cloud Console; no se pega en ningún archivo del repo — Google lo asocia automáticamente al paquete+SHA-1. |
| **iOS** | Identifica la app iOS ante Google — requiere el Bundle ID. | Su "reversed client ID" (formato `com.googleusercontent.apps.XXXX`) se pega literalmente en `ios/Runner/Info.plist` como `CFBundleURLSchemes`. |

## Pasos

1. **Google Cloud Console** → [console.cloud.google.com](https://console.cloud.google.com) → crea un proyecto nuevo (o reutiliza uno existente si ya tienes uno para AdMob/Sentry — son productos distintos, pero pueden vivir en el mismo proyecto de Google Cloud).
2. **APIs & Services → OAuth consent screen**: configúralo como "External", con el nombre de la app, tu email de contacto y el logo si lo tienes. Sin esto no puedes crear credenciales OAuth.
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**, tres veces:
   - **Tipo "Web application"**: sin necesidad de configurar redirect URIs para este flujo nativo. Este es el que necesito de vuelta.
   - **Tipo "Android"**: pide el nombre del paquete y el SHA-1. Para el SHA-1 del build de **debug** (para probar mientras desarrollamos): `cd src/mobile/android && ./gradlew signingReport` y copia el `SHA1` bajo la variante `debug`. Para el de **release** (el que de verdad sube a Play Store) necesitarás el SHA-1 del keystore de firma real — dímelo cuando lo tengas y te digo dónde consultarlo según cómo esté configurada la firma.
   - **Tipo "iOS"**: pide el Bundle ID (`ios/Runner.xcodeproj` → o dímelo y lo confirmo yo desde el repo).
4. **Pásame solo el Client ID de tipo "Web"** (no hace falta que me des el Android/iOS — esos no se pegan en ningún archivo, Google los reconoce automáticamente por el paquete/Bundle ID + SHA-1 que registraste). **No hace falta ningún "client secret"** para este flujo — el flujo nativo con `google_sign_in` no lo usa; ignóralo si Google te lo muestra.
5. **Supabase Dashboard → Authentication → Providers → Google**: actívalo y pega ahí también el Client ID de tipo "Web" (mismo valor que en el paso 4) — Supabase lo usa para verificar el ID token que el móvil le manda. **Client secret**: tampoco hace falta para este flujo; puedes dejarlo vacío.

## Qué haré yo en cuanto tenga el Client ID "Web"

- Añadir el paquete `google_sign_in` y wire-uear `AccountRepository.signInWithGoogle()`.
- Crear `GoogleSignInConfig` (mismo patrón que `SupabaseConfig`/`SentryConfig`) con ese Client ID — es un identificador público, seguro de subir al repo, igual que el DSN de Sentry.
- Activar el botón "Continuar con Google" en `AuthChoiceScreen` (hoy deshabilitado, marcado "Próximamente").
- Añadir el `CFBundleURLSchemes` a `ios/Runner/Info.plist` con el reversed client ID de iOS (ese sí que necesito el valor exacto — te lo pediré cuando llegue el momento, junto con el Bundle ID exacto del proyecto).
- Actualizar `privacy-policy-draft.md`/`terms-of-service-draft.md` (y sus espejos en gh-pages) con la nueva finalidad: qué datos comparte Google con nosotros al iniciar sesión (nombre, email, foto de perfil — según los scopes por defecto de `google_sign_in`, sin pedir ningún permiso adicional).
- Actualizar `play-console-setup-guide.md`'s Data Safety con la nueva fila.

## Lo que NO puedo hacer por ti

Registrar el SHA-1 de release en Google Cloud Console requiere que primero
tengas (o generes) el keystore de firma real de Play Store — si todavía no lo
tienes, dímelo y vemos juntos cómo generarlo de forma segura (nunca debe
subirse a este repo ni compartirse en el chat).

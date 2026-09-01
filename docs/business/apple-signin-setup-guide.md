# Guía de configuración — Sign in with Apple

> Guía de ejecución directa por tu parte — necesitas una cuenta del **Apple
> Developer Program** (de pago, ver más abajo) y acceso al proyecto de
> Supabase. No hay ninguna API por la que yo pueda crear estas credenciales
> por ti. A diferencia de Google, aquí no necesito que me pases ningún valor
> de vuelta — todo lo que reúnas en este documento se pega directamente en el
> Dashboard de Supabase, nunca en el código del repo. Solo necesito que me
> confirmes cuándo está hecho.

## Coste: a diferencia de Google, esto no es gratis

El Apple Developer Program cuesta **99 USD/año**. Si todavía no estás
inscrito, es el primer paso y el único con coste — sin él no puedes crear
ninguna de las credenciales de abajo. Suponemos que ya lo estás, porque
también lo necesitas para publicar la app en la App Store y para las
credenciales de verificación de compras (ver más abajo, no confundir con
esas).

## No confundir con las credenciales de verificación de compras

Este repo ya usa credenciales de Apple para un fin totalmente distinto:
`APPLE_KEY_ID` / `APPLE_ISSUER_ID` / `APPLE_PRIVATE_KEY` / `APPLE_BUNDLE_ID`
(ver `src/backend/README.md` sección "Store credentials setup") sirven para
que `verify-purchase` consulte la App Store Server API y confirme que una
suscripción es genuina — nada que ver con que un usuario inicie sesión.
Ambos conjuntos de credenciales viven en la misma cuenta de Apple Developer
y comparten el mismo Team ID, pero son claves y servicios de Apple
distintos — no reutilices una clave `.p8` de verificación de compras para
Sign in with Apple, ni al revés.

## Por qué varias piezas, no 1

El flujo nativo en iOS (paquete `sign_in_with_apple` en el dispositivo +
`Supabase Auth.signInWithIdToken`, sin navegador/redirect) no necesita que
yo pegue ningún Client ID en el código Dart — a diferencia de Google, la
identidad de la app ante Apple la da la propia firma/entitlement de Xcode,
no un valor que se escriba en Dart. Lo que sí hace falta es dar de alta la
capacidad en varios sitios de Apple Developer y, sobre todo, en **Supabase**
(que es quien de verdad verifica el token del usuario contra Apple):

| Pieza | Para qué sirve | Dónde se usa |
|---|---|---|
| **App ID con la capacidad "Sign In with Apple"** | Identifica la app (`com.worldwebapps.app.aprenderidioma`) ante Apple y le da permiso para ofrecer este inicio de sesión. | Se activa en Apple Developer; no se pega en ningún archivo — es la app en sí. |
| **Services ID** | Actúa como el "Client ID" del flujo — Apple lo trata como una app "web" ligada a tu App ID real. Necesario aunque el flujo en el móvil sea nativo, porque Supabase lo usa como uno de los "Client IDs" válidos al verificar el token. | Se pega en Supabase Dashboard → Authentication → Providers → Apple, campo "Client IDs" (junto con el Bundle ID, ver más abajo). |
| **Key (.p8) + Key ID + Team ID** | Le permiten a Supabase generar el secreto JWT que Apple exige para el intercambio de tokens server-side. | Se pegan **directamente en Supabase Dashboard**, nunca en este repo ni en el chat conmigo — son la parte más sensible de todo esto. |
| **Bundle ID** (`com.worldwebapps.app.aprenderidioma`) | El segundo valor del campo "Client IDs" de Supabase — porque el token nativo que genera el móvil está dirigido al Bundle ID de la app, no al Services ID. | Mismo campo "Client IDs" de Supabase, junto al Services ID. Ya lo tengo confirmado desde el repo (`ios/Runner.xcodeproj`), no hace falta que me lo des. |

## Pasos

1. **Apple Developer → Certificates, Identifiers & Profiles → Identifiers**:
   busca el App ID `com.worldwebapps.app.aprenderidioma` (ya existe, es el
   de la app) y activa la casilla de capacidad **"Sign In with Apple"**.
   Guarda.
2. **Identifiers → + → Services IDs**: crea uno nuevo (por ejemplo
   `com.worldwebapps.app.aprenderidioma.signin` — el identificador exacto no
   importa, solo que sea único y lo reconozcas). Al crearlo, activa "Sign In
   with Apple" y pulsa **Configure**:
   - **Primary App ID**: selecciona el App ID del paso 1.
   - **Domains and Subdomains**: `nfkhnrwyekqbjxwxmctu.supabase.co`
   - **Return URLs**: `https://nfkhnrwyekqbjxwxmctu.supabase.co/auth/v1/callback`
   Guarda — este identificador del Services ID es el que luego va en
   Supabase como uno de los "Client IDs".
3. **Certificates, Identifiers & Profiles → Keys → +**: activa "Sign In
   with Apple", pulsa **Configure** y selecciona el mismo App ID del paso 1.
   Al generar la key, Apple te deja **descargar el archivo `.p8` una única
   vez** — guárdalo en un sitio seguro (gestor de contraseñas, no en este
   repo ni en ningún chat) porque no se puede volver a descargar. Anota
   también el **Key ID** que Apple te muestra junto a la key.
4. **Team ID**: está arriba a la derecha de cualquier página de tu cuenta
   de Apple Developer, o en Membership details.
5. **Supabase Dashboard → Authentication → Providers → Apple**: actívalo y
   rellena:
   - **Client IDs**: el Services ID del paso 2 y el Bundle ID
     `com.worldwebapps.app.aprenderidioma`, separados por coma.
   - **Team ID**, **Key ID** y el contenido del archivo **.p8** del paso 3.
   Supabase genera el secreto JWT automáticamente a partir de esos tres
   valores — no hay que generarlo tú a mano.

Con eso, todo lo que Apple/Supabase necesitan está configurado. **No hace
falta que me pases ningún valor de vuelta** — el Services ID, el Bundle ID,
el Team ID, el Key ID y la key en sí solo viven en Apple Developer y en el
Dashboard de Supabase.

## Qué haré yo en cuanto me confirmes que está hecho

- Añadir el paquete `sign_in_with_apple` y wire-uear
  `AccountRepository.signInWithApple()` usando el flujo nativo
  (`SignInWithAppleButton` → `Supabase Auth.signInWithIdToken`).
- Añadir la capacidad/entitlement "Sign In with Apple" al target `Runner`
  en Xcode (`ios/Runner/Runner.entitlements`).
- Activar el botón "Continuar con Apple" en `AuthChoiceScreen` (hoy
  deshabilitado, marcado "Próximamente").
- Actualizar `privacy-policy-draft.md`/`terms-of-service-draft.md` (y sus
  espejos en gh-pages) con la nueva finalidad: qué datos comparte Apple con
  nosotros al iniciar sesión (nombre y email — Apple permite al usuario
  ocultar su email real y usar un alias de reenvío privado, "Hide My
  Email"; nuestro backend solo ve el que Apple decida entregar).
- Actualizar `play-console-setup-guide.md`/`store-listing.md`'s Data Safety
  con la nueva fila.

## Solo iOS por ahora

Apple exige ofrecer Sign in with Apple **en iOS** (App Store Review
Guideline 4.8) cuando la app ya ofrece otros inicios de sesión de terceros
— pero no lo exige en Android, donde Apple ni siquiera tiene SDK nativo (se
haría vía un flujo de redirect web, con un mecanismo distinto). Por eso
esta guía y la implementación planeada cubren solo iOS. Si en el futuro
quieres ofrecerlo también en Android, es un trabajo aparte que documentaré
cuando le toque — no bloquea nada de lo de aquí.

# Guía de configuración — Facebook Login

> Guía de ejecución directa por tu parte — necesitas una cuenta de Meta for
> Developers (gratuita) y acceso al proyecto de Supabase. No hay ninguna API
> por la que yo pueda crear estas credenciales por ti; una vez las tengas,
> el código para usarlas ya está preparado y solo falta pegar los valores
> reales en los sitios marcados como `[PENDIENTE]`.

## Aviso: el proceso de Meta cambia con frecuencia

A diferencia de Google y Apple, la consola de Meta for Developers reorganiza
su flujo de creación de apps y sus requisitos de revisión con cierta
frecuencia — los nombres exactos de menús de los pasos de abajo pueden
haberse movido cuando llegues a hacerlo. La lógica de fondo (App ID, App
Secret, Client Token, plataformas registradas, modo Live) se mantiene
estable aunque cambien las pantallas.

Meta también puede pedirte **verificación de identidad** para gestionar la
app (documento oficial, según tu cuenta) y, para que usuarios que no sean
administradores/desarrolladores/testers de la app puedan iniciar sesión de
verdad, la app tiene que estar en modo **Live**, no en modo desarrollo — ver
el paso 7.

## Por qué varias piezas, no 1

| Pieza | Para qué sirve | Dónde se usa | ¿Es secreta? |
|---|---|---|---|
| **App ID** | Identifica la app ante Facebook. | Código Flutter (`FacebookAppID` en `Info.plist`/`AndroidManifest.xml`) y Supabase Dashboard. | No — es público, como el Client ID de Google. |
| **Client Token** | El SDK nativo de Facebook lo necesita en el dispositivo para autenticarse ante la API de Facebook. | Código Flutter (`FacebookClientToken` en `Info.plist`/`AndroidManifest.xml`). | No — pensado para ir embebido en la app. |
| **App Secret** | Lo usa Supabase (el servidor, no el dispositivo) para completar el intercambio de tokens con Facebook. | Se pega **directamente en Supabase Dashboard**, nunca en este repo ni en el chat conmigo. | **Sí** — nunca lo compartas fuera de Supabase. |
| **Key Hashes (Android)** / **Bundle ID (iOS)** | Identifican cada plataforma de la app ante Facebook — equivalente al SHA-1 que le diste a Google, pero codificado distinto. | Se registran en Meta for Developers; no se pegan en ningún archivo del repo. | No, pero solo Facebook los necesita. |

## Pasos

1. **[developers.facebook.com](https://developers.facebook.com) → My Apps
   → Create App**: elige el caso de uso relacionado con autenticación /
   inicio de sesión de usuarios (el texto exacto de esta opción cambia
   según la versión de la consola). Dale un nombre y complétalo.
2. **Add Product → Facebook Login**: añádelo a la app. No hace falta el
   producto "Facebook Login for Business" para esto, solo el estándar.
3. **App Settings → Basic**: aquí están el **App ID** y el **App Secret**.
   Guarda el App Secret en un gestor de contraseñas — es la pieza sensible.
4. **App Settings → Advanced → Security**: ahí está el **Client Token**
   (en algunas versiones de la consola vive dentro de "Settings → Advanced"
   directamente).
5. **Facebook Login → Settings**: en **Valid OAuth Redirect URIs** añade:
   ```
   https://nfkhnrwyekqbjxwxmctu.supabase.co/auth/v1/callback
   ```
6. **Registra las plataformas** (Settings → Basic → Add Platform):
   - **iOS**: Bundle ID `com.worldwebapps.app.aprenderidioma`.
   - **Android**: Package Name `com.worldwebapps.app.aprenderidioma`, Class
     Name `.MainActivity` (el estándar en un proyecto Flutter), y el
     **Key Hash** — se genera así, una vez por keystore (debug y luego
     release):
     ```
     keytool -exportcert -alias <alias-del-keystore> -keystore <ruta-al-keystore> | openssl sha1 -binary | openssl base64
     ```
     Para el keystore de **debug** (para probar mientras desarrollamos), el
     alias suele ser `androiddebugkey` y la ruta `~/.android/debug.keystore`
     (contraseña `android`). Para el de **release** (el que de verdad sube a
     Play Store) necesitarás el keystore de firma real — dímelo cuando lo
     tengas y vemos juntos cómo generar el hash sin compartir el keystore.
7. **Modo Live**: mientras la app esté en modo "Development", solo pueden
   iniciar sesión los usuarios que hayas añadido como admin/developer/tester
   en **Roles**. Para que cualquier usuario real pueda usar "Continuar con
   Facebook", cambia el interruptor de la app a **Live** en la parte
   superior del dashboard — Meta puede pedirte completar un "App Review"/
   "Data Use Checkup" antes de dejarte, según los permisos que uses; para
   permisos básicos (perfil público y email) esto suele resolverse sin
   revisión manual, pero confírmalo en el momento porque la política de
   Meta cambia. `[PENDIENTE: confirmar en el momento de activar Live si
   Meta pide algo adicional para este caso concreto.]`
8. **Pásame el App ID y el Client Token** del paso 3/4 — nada más. **No me
   pases el App Secret** — ese se queda solo en Supabase Dashboard.
9. **Supabase Dashboard → Authentication → Providers → Facebook**:
   actívalo y pega ahí el **App ID** (Client ID) y el **App Secret**
   (Client Secret) del paso 3.

## Qué haré yo en cuanto tenga el App ID y el Client Token

- Añadir el paquete `flutter_facebook_auth` y wire-uear
  `AccountRepository.signInWithFacebook()`.
- Crear `FacebookSignInConfig` (mismo patrón que `GoogleSignInConfig`/
  `SupabaseConfig`) con el App ID y el Client Token — ambos son
  identificadores públicos, seguros de subir al repo.
- Añadir las claves `FacebookAppID`, `FacebookClientToken` y
  `FacebookDisplayName` a `ios/Runner/Info.plist`, y el meta-data
  equivalente en `android/app/src/main/AndroidManifest.xml`.
- Activar el botón "Continuar con Facebook" en `AuthChoiceScreen` (hoy
  deshabilitado, marcado "Próximamente").
- Decidir en ese momento el flujo exacto de integración nativa (Facebook
  ofrece dos: Login clásico con access token, o Limited Login con un ID
  token compatible con OIDC en iOS) según cuál encaje mejor con
  `Supabase Auth` — un detalle técnico que no necesitas resolver tú.
- Actualizar `privacy-policy-draft.md`/`terms-of-service-draft.md` (y sus
  espejos en gh-pages) con la nueva finalidad: qué datos comparte Facebook
  con nosotros al iniciar sesión (nombre, email y foto de perfil, según los
  permisos por defecto `public_profile`/`email`, sin pedir ningún permiso
  adicional).
- Actualizar `play-console-setup-guide.md`/`store-listing.md`'s Data Safety
  con la nueva fila.

## Lo que NO puedo hacer por ti

Generar el Key Hash de release requiere el keystore de firma real de Play
Store, y completar el modo Live/App Review es una acción dentro de la
propia consola de Meta ligada a tu cuenta — ninguna de las dos las puedo
hacer yo.

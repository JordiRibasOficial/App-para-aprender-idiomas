# Política de Privacidad (borrador) — App para Aprender Idiomas

> **BORRADOR. No publicar sin revisión de un abogado/asesor en protección de datos real.** Este documento intenta ser coherente con el RGPD (por tener usuarios en la UE) y con los requisitos de Apple App Store / Google Play, pero no ha sido redactado ni revisado por un profesional del derecho. Nombre y email ya rellenados según lo indicado por el usuario — sigue pendiente confirmar la forma legal real con un asesor (ver `business-registration-checklist.md`), especialmente si "Webapps" acaba siendo un nombre comercial sobre una figura legal distinta (autónomo/SL).

**Última actualización: 19 de agosto de 2026**

## 1. Quiénes somos

App para Aprender Idiomas es una aplicación móvil de aprendizaje de idiomas. Webapps es responsable del tratamiento de los datos descritos en esta política. Contacto: world.webapps@gmail.com.

## 2. Qué datos recogemos

La aplicación tiene un backend propio (Supabase), pero con un alcance deliberadamente reducido: solo verifica compras de suscripción contra Google Play / Apple, y sirve el contenido de los cursos de pago a quien tiene una suscripción activa. No gestiona cuentas de usuario ni recoge email. Los datos que se recogen son:

- **Progreso de aprendizaje** (lecciones completadas, puntuación, racha): almacenado localmente en el dispositivo (SQLite), no se envía a ningún servidor nuestro.
- **Email (opcional)**: si el usuario elige "Continuar con email" en el registro inicial, se guarda localmente en el dispositivo, cifrado (Keychain en iOS, almacenamiento cifrado en Android). **No se usa para crear una cuenta real ni se envía a ningún servidor en esta versión** — se pedirá de nuevo, de forma más completa y con backend real, cuando exista un sistema de cuentas (ver hoja de ruta del producto).
- **Identidad anónima de sesión**: para verificar una compra o descargar un curso de pago, la app crea automáticamente una identidad anónima en nuestro backend (Supabase) — un identificador técnico sin nombre, email ni ningún dato personal asociado, que solo sirve para vincular esas dos operaciones a un mismo dispositivo. Esta identidad se guarda cifrada en el dispositivo (Keychain/almacenamiento cifrado), igual que el email opcional.
- **Datos de verificación de compra**: cuando el usuario compra o restaura una suscripción, la app envía el token de compra a nuestro backend, que lo verifica directamente contra la API oficial de Google Play / Apple App Store y guarda el resultado (plataforma, producto, estado, fecha de expiración) asociado a la identidad anónima anterior — nunca a un nombre o email. No tenemos acceso a datos de tarjetas ni de pago en ningún momento; eso lo gestionan Google/Apple directamente. También se registra la marca de tiempo de cada intento de verificación (sin más datos), únicamente para limitar el abuso de este mecanismo.
- **Qué curso de pago se está descargando**: al abrir un idioma de pago (portugués, francés o japonés), la app pide su contenido a nuestro backend, que comprueba que la identidad anónima tiene una suscripción activa antes de responder. Esto revela a nuestro backend qué idioma está estudiando un usuario Premium en el momento de la descarga — no se guarda un historial de esto más allá de los logs técnicos habituales del servidor (ver "Retención de logs" más abajo). El progreso dentro de ese curso sigue siendo 100% local.
- **Publicidad (solo usuarios sin suscripción Premium activa)**: la versión gratuita muestra anuncios de Google AdMob. AdMob puede recoger un identificador de publicidad del dispositivo y datos técnicos para mostrar y medir anuncios — sujeto a la política de privacidad de Google. Los anuncios se desactivan automáticamente en cuanto el usuario tiene una suscripción Premium activa. Antes de mostrar anuncios a usuarios en la UE/Reino Unido, se solicita su consentimiento mediante el formulario oficial de Google (UMP), conforme al RGPD.

### Retención de logs

Los logs técnicos del backend (Supabase) — incluidas las peticiones a los endpoints de verificación de compra y descarga de contenido — se conservan según la política de retención por defecto de Supabase para nuestro plan. `[PENDIENTE: confirmar el periodo exacto con Supabase y reflejarlo aquí antes de publicar.]`

## 3. Qué NO hacemos

- No vendemos datos personales a terceros.
- No compartimos el progreso de aprendizaje con nadie — vive solo en el dispositivo del usuario.
- No mostramos anuncios a usuarios con una suscripción Premium activa.

## 4. Base legal del tratamiento (RGPD)

- Progreso local: no sale del dispositivo, por lo que no constituye un tratamiento por nuestra parte en el sentido del RGPD más allá de facilitar el almacenamiento local.
- Email opcional: consentimiento explícito del usuario al elegir proporcionar su email.
- Identidad anónima de sesión y datos de verificación de compra: ejecución del contrato de suscripción (necesario para prestar el servicio de pago) — sin esa identidad no podemos confirmar que una compra es genuina ni entregar el contenido de pago correspondiente.
- Publicidad: consentimiento del usuario (recogido vía el formulario UMP de Google para usuarios en la UE/Reino Unido) o interés legítimo donde el RGPD lo permita, según la región.

## 5. Servicios de terceros

- **Google Play Billing / Apple StoreKit**: procesan los pagos de la suscripción. Sujetos a las políticas de privacidad de Google y Apple respectivamente.
- **Supabase** (nuestro proveedor de backend, alojado en la UE): actúa como encargado del tratamiento para la identidad anónima de sesión y los datos de verificación de compra descritos en la sección 2. Sujeto a la [política de privacidad de Supabase](https://supabase.com/privacy).
- **Google AdMob**: muestra anuncios a usuarios sin suscripción Premium activa. Sujeto a la [política de privacidad de Google](https://policies.google.com/privacy). Google actúa como encargado/responsable del tratamiento según corresponda a su propio rol — ver su documentación para publishers de AdMob.
- `[PENDIENTE: si en el futuro se añade analítica (p. ej. Firebase Analytics, un SDK de crash reporting como Sentry) o un backend de cuentas real, esta sección debe actualizarse antes de publicar esa versión — no anticipar aquí servicios que todavía no existen.]`

## 6. Derechos del usuario

Bajo el RGPD, el usuario tiene derecho a acceder, rectificar, suprimir, limitar el tratamiento y portar sus datos. Dado que el progreso vive localmente, el usuario ya tiene control total: desinstalar la app elimina todos los datos locales, incluidos el email opcional y la identidad anónima de sesión. Para solicitar la eliminación de los datos de verificación de compra guardados en nuestro backend (sección 2), puede escribirse a world.webapps@gmail.com indicando la plataforma (Android/iOS) y, si se conoce, la fecha aproximada de la suscripción.

En caso de una brecha de seguridad que afecte a tus datos personales y suponga un riesgo para tus derechos, lo notificaremos a la Agencia Española de Protección de Datos en el plazo legal y, cuando el riesgo sea alto, también a ti directamente. Procedimiento interno en `docs/business/data-breach-response-plan.md` (documento interno, no público).

## 7. Menores de edad

La aplicación no está dirigida específicamente a menores de 13 años (o la edad mínima aplicable según la jurisdicción). `[PENDIENTE: definir política de edad mínima real con el asesor legal, especialmente si se plantea un público infantil en el futuro — cambiaría sustancialmente los requisitos, p. ej. COPPA en EE.UU.]`

## 8. Cambios en esta política

Cualquier cambio material se notificará dentro de la aplicación antes de que entre en vigor.

## 9. Contacto

world.webapps@gmail.com

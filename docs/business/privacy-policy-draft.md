# Política de Privacidad (borrador) — App para Aprender Idiomas

> **BORRADOR. No publicar sin revisión de un abogado/asesor en protección de datos real.** Este documento intenta ser coherente con el RGPD (por tener usuarios en la UE) y con los requisitos de Apple App Store / Google Play, pero no ha sido redactado ni revisado por un profesional del derecho. Nombre y email ya rellenados según lo indicado por el usuario — sigue pendiente confirmar la forma legal real con un asesor (ver `business-registration-checklist.md`), especialmente si "Webapps" acaba siendo un nombre comercial sobre una figura legal distinta (autónomo/SL).

**Última actualización: 6 de agosto de 2026**

## 1. Quiénes somos

App para Aprender Idiomas es una aplicación móvil de aprendizaje de idiomas. Webapps es responsable del tratamiento de los datos descritos en esta política. Contacto: world.webapps@gmail.com.

## 2. Qué datos recogemos

A fecha de esta versión, la aplicación **no tiene backend propio** — el progreso de aprendizaje se almacena únicamente en el dispositivo del usuario. Los datos que se recogen son:

- **Progreso de aprendizaje** (lecciones completadas, puntuación, racha): almacenado localmente en el dispositivo (SQLite), no se envía a ningún servidor nuestro.
- **Email (opcional)**: si el usuario elige "Continuar con email" en el registro inicial, se guarda localmente en el dispositivo. **No se usa para crear una cuenta real ni se envía a ningún servidor en esta versión** — se pedirá de nuevo, de forma más completa y con backend real, cuando exista un sistema de cuentas (ver hoja de ruta del producto).
- **Datos de compra de suscripción**: gestionados directamente por Google Play / Apple App Store, no por nosotros. No tenemos acceso a datos de tarjetas ni de pago — solo recibimos confirmación de que existe una suscripción activa, a través de la API oficial de cada tienda.
- **Publicidad (solo usuarios sin suscripción Premium activa)**: la versión gratuita muestra anuncios de Google AdMob. AdMob puede recoger un identificador de publicidad del dispositivo y datos técnicos para mostrar y medir anuncios — sujeto a la política de privacidad de Google. Los anuncios se desactivan automáticamente en cuanto el usuario tiene una suscripción Premium activa. Antes de mostrar anuncios a usuarios en la UE/Reino Unido, se solicita su consentimiento mediante el formulario oficial de Google (UMP), conforme al RGPD.

## 3. Qué NO hacemos

- No vendemos datos personales a terceros.
- No compartimos el progreso de aprendizaje con nadie — vive solo en el dispositivo del usuario.
- No mostramos anuncios a usuarios con una suscripción Premium activa.

## 4. Base legal del tratamiento (RGPD)

- Progreso local: no sale del dispositivo, por lo que no constituye un tratamiento por nuestra parte en el sentido del RGPD más allá de facilitar el almacenamiento local.
- Email opcional: consentimiento explícito del usuario al elegir proporcionar su email.
- Datos de suscripción: ejecución del contrato de suscripción (necesario para prestar el servicio de pago).
- Publicidad: consentimiento del usuario (recogido vía el formulario UMP de Google para usuarios en la UE/Reino Unido) o interés legítimo donde el RGPD lo permita, según la región.

## 5. Servicios de terceros

- **Google Play Billing / Apple StoreKit**: procesan los pagos de la suscripción. Sujetos a las políticas de privacidad de Google y Apple respectivamente.
- **Google AdMob**: muestra anuncios a usuarios sin suscripción Premium activa. Sujeto a la [política de privacidad de Google](https://policies.google.com/privacy). Google actúa como encargado/responsable del tratamiento según corresponda a su propio rol — ver su documentación para publishers de AdMob.
- `[PENDIENTE: si en el futuro se añade analítica (p. ej. Firebase Analytics) o un backend de cuentas real, esta sección debe actualizarse antes de publicar esa versión — no anticipar aquí servicios que todavía no existen.]`

## 6. Derechos del usuario

Bajo el RGPD, el usuario tiene derecho a acceder, rectificar, suprimir, limitar el tratamiento y portar sus datos. Dado que el progreso vive localmente, el usuario ya tiene control total: desinstalar la app elimina todos los datos locales. Para el email opcional (si se proporcionó), puede solicitarse su eliminación escribiendo a world.webapps@gmail.com.

## 7. Menores de edad

La aplicación no está dirigida específicamente a menores de 13 años (o la edad mínima aplicable según la jurisdicción). `[PENDIENTE: definir política de edad mínima real con el asesor legal, especialmente si se plantea un público infantil en el futuro — cambiaría sustancialmente los requisitos, p. ej. COPPA en EE.UU.]`

## 8. Cambios en esta política

Cualquier cambio material se notificará dentro de la aplicación antes de que entre en vigor.

## 9. Contacto

world.webapps@gmail.com

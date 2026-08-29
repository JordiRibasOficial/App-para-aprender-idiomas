# Política de Privacidad (borrador) — App para Aprender Idiomas

> **BORRADOR. No publicar sin revisión de un abogado/asesor en protección de datos real.** Este documento intenta ser coherente con el RGPD (por tener usuarios en la UE) y con los requisitos de Apple App Store / Google Play, pero no ha sido redactado ni revisado por un profesional del derecho. Nombre y email ya rellenados según lo indicado por el usuario — sigue pendiente confirmar la forma legal real con un asesor (ver `business-registration-checklist.md`), especialmente si "Webapps" acaba siendo un nombre comercial sobre una figura legal distinta (autónomo/SL).

**Última actualización: 19 de agosto de 2026**

## 1. Quiénes somos

App para Aprender Idiomas es una aplicación móvil de aprendizaje de idiomas. Webapps es responsable del tratamiento de los datos descritos en esta política. Contacto: world.webapps@gmail.com.

## 2. Qué datos recogemos

La aplicación tiene un backend propio (Supabase), pero con un alcance deliberadamente reducido: solo verifica compras de suscripción contra Google Play / Apple, y sirve el contenido de los cursos de pago a quien tiene una suscripción activa. No gestiona cuentas de usuario. Los datos que se recogen son:

- **Progreso de aprendizaje** (lecciones completadas, puntuación, racha): almacenado localmente en el dispositivo (SQLite), no se envía a ningún servidor nuestro.
- **Email (opcional)**: si el usuario elige "Continuar con email" en el registro inicial, se guarda localmente en el dispositivo, cifrado (Keychain en iOS, almacenamiento cifrado en Android), y **no se usa para crear una cuenta real** — se pedirá de nuevo, de forma más completa y con backend real, cuando exista un sistema de cuentas (ver hoja de ruta del producto). **Si el usuario lo dio y completa una compra**, se envía una única vez a nuestro backend, junto con esa compra, para poder enviarle el correo de confirmación que exige el art. 98.7 TRLGDCU (ver `terms-of-service-draft.md` sección 4) — nuestro backend lo usa solo para ese envío puntual, a través de Resend (nuestro proveedor de email transaccional), y **no lo guarda** en ninguna tabla ni base de datos propia.
- **Identidad anónima de sesión**: para verificar una compra o descargar un curso de pago, la app crea automáticamente una identidad anónima en nuestro backend (Supabase) — un identificador técnico sin nombre, email ni ningún dato personal asociado, que solo sirve para vincular esas dos operaciones a un mismo dispositivo. Esta identidad se guarda cifrada en el dispositivo (Keychain/almacenamiento cifrado), igual que el email opcional.
- **Datos de verificación de compra**: cuando el usuario compra o restaura una suscripción, la app envía el token de compra a nuestro backend, que lo verifica directamente contra la API oficial de Google Play / Apple App Store y guarda el resultado (plataforma, producto, estado, fecha de expiración) asociado a la identidad anónima anterior — nunca a un nombre o email. No tenemos acceso a datos de tarjetas ni de pago en ningún momento; eso lo gestionan Google/Apple directamente. También se registra la marca de tiempo de cada intento de verificación (sin más datos), únicamente para limitar el abuso de este mecanismo.
- **Qué curso de pago se está descargando**: al abrir un idioma de pago (portugués, francés o japonés), la app pide su contenido a nuestro backend, que comprueba que la identidad anónima tiene una suscripción activa antes de responder. Esto revela a nuestro backend qué idioma está estudiando un usuario Premium en el momento de la descarga — no se guarda un historial de esto más allá de los logs técnicos habituales del servidor (ver "Retención de logs" más abajo). El progreso dentro de ese curso sigue siendo 100% local.
- **Publicidad (solo usuarios sin suscripción Premium activa)**: la versión gratuita muestra anuncios de Google AdMob. AdMob puede recoger un identificador de publicidad del dispositivo y datos técnicos para mostrar y medir anuncios — sujeto a la política de privacidad de Google. Los anuncios se desactivan automáticamente en cuanto el usuario tiene una suscripción Premium activa. Antes de mostrar anuncios a usuarios en la UE/Reino Unido, se solicita su consentimiento mediante el formulario oficial de Google (UMP), conforme al RGPD.

### Retención de logs

Los logs técnicos del backend (Supabase) — incluidas las peticiones a los endpoints de verificación de compra y descarga de contenido — se conservan según la política de retención por defecto de Supabase para nuestro plan. `[PENDIENTE: confirmar el periodo exacto con Supabase y reflejarlo aquí antes de publicar.]`

Aparte de esos logs de la plataforma, las tablas propias que usamos solo para limitar el abuso de estos endpoints (marca de tiempo de cada intento de verificación de compra, descarga de contenido, exportación o eliminación de datos) se purgan a los 7 días — ver `src/backend/README.md` sección "Data retention".

## 3. Qué NO hacemos

- No vendemos datos personales a terceros.
- No compartimos el progreso de aprendizaje con nadie — vive solo en el dispositivo del usuario.
- No mostramos anuncios a usuarios con una suscripción Premium activa.

## 4. Base legal del tratamiento (RGPD)

- Progreso local: no sale del dispositivo, por lo que no constituye un tratamiento por nuestra parte en el sentido del RGPD más allá de facilitar el almacenamiento local.
- Email opcional guardado localmente: consentimiento explícito del usuario al elegir proporcionarlo.
- Email transmitido puntualmente para el correo de confirmación de compra: cumplimiento de una obligación legal (art. 6.1.c RGPD) — el art. 98.7 TRLGDCU exige facilitar esa confirmación; no es una base adicional de consentimiento, es la misma compra la que la activa.
- Identidad anónima de sesión y datos de verificación de compra: ejecución del contrato de suscripción (necesario para prestar el servicio de pago) — sin esa identidad no podemos confirmar que una compra es genuina ni entregar el contenido de pago correspondiente.
- Publicidad: consentimiento del usuario (recogido vía el formulario UMP de Google para usuarios en la UE/Reino Unido) o interés legítimo donde el RGPD lo permita, según la región.
- Datos de diagnóstico/fallos (Sentry): interés legítimo (art. 6.1.f RGPD) — mantener la app funcionando de forma segura y detectar errores en producción.

## 5. Servicios de terceros

- **Google Play Billing / Apple StoreKit**: procesan los pagos de la suscripción. Sujetos a las políticas de privacidad de Google y Apple respectivamente.
- **Supabase** (nuestro proveedor de backend, alojado en la UE): actúa como encargado del tratamiento para la identidad anónima de sesión y los datos de verificación de compra descritos en la sección 2. Sujeto a la [política de privacidad de Supabase](https://supabase.com/privacy). Su Acuerdo de Encargado del Tratamiento (DPA) queda incorporado automáticamente al aceptar sus Términos de Servicio — verificado, no requiere firma ni acción separada nuestra (detalle en `docs/business/records-of-processing-activities.md`).
- **Google AdMob**: muestra anuncios a usuarios sin suscripción Premium activa. Sujeto a la [política de privacidad de Google](https://policies.google.com/privacy). Google actúa como encargado/responsable del tratamiento según corresponda a su propio rol — ver su documentación para publishers de AdMob.
- **Sentry** (monitorización de errores, región UE): recibe automáticamente detalles técnicos de fallos de la app (excepción, traza, contexto del dispositivo/SO) solo en la versión de producción — nunca en desarrollo. No recibe el email ni ningún otro dato personal introducido por el usuario. Sujeto a la [política de privacidad de Sentry](https://sentry.io/privacy/). Ver `docs/business/crash-reporting-review.md`.
- **Resend** (envío del correo de confirmación de compra): recibe la dirección de email del usuario únicamente cuando completa una compra y solo para enviar ese correo puntual — no lo retiene para ningún otro fin por nuestra parte. Sujeto a la [política de privacidad de Resend](https://resend.com/legal/privacy-policy). Ver `src/backend/README.md` sección "Purchase confirmation email setup".

## 6. Derechos del usuario

Bajo el RGPD, el usuario tiene derecho a acceder, rectificar, suprimir, limitar el tratamiento y portar sus datos. Dado que el progreso vive localmente, el usuario ya tiene control total: desinstalar la app elimina todos los datos locales, incluidos el email opcional y la identidad anónima de sesión. Para acceder a los datos guardados en nuestro backend (sección 2), exportarlos o **eliminarlos permanentemente**, puede usar la opción "Mis datos" dentro de la propia App — el botón "Eliminar mis datos" borra de inmediato, sin necesidad de escribir a nadie, la suscripción y los intentos de verificación de compra asociados a su identidad anónima; es irreversible. También puede solicitarlo por email a world.webapps@gmail.com indicando la plataforma (Android/iOS) y, si se conoce, la fecha aproximada de la suscripción.

En caso de una brecha de seguridad que afecte a tus datos personales y suponga un riesgo para tus derechos, lo notificaremos a la Agencia Española de Protección de Datos en el plazo legal y, cuando el riesgo sea alto, también a ti directamente. Procedimiento interno en `docs/business/data-breach-response-plan.md` (documento interno, no público).

## 7. Menores de edad

La App no está dirigida a menores de 16 años. Este umbral es deliberadamente más alto que el mínimo legal de cualquier jurisdicción relevante (14 años en España según la LOPDGDD, 13 años según el RGPD del Reino Unido o la COPPA en EE. UU.), para no tener que aplicar un umbral distinto según el país. Durante el registro se pide al usuario que confirme, mediante una casilla específica, que cumple esta edad — una autodeclaración, no una verificación documental. No recopilamos intencionadamente datos de menores de 16 años; si tenemos constancia de que un usuario no cumple este mínimo, eliminaremos su cuenta y los datos asociados. `[PENDIENTE: confirmar con el asesor legal si esta autodeclaración es suficiente o si conviene reforzarla en el futuro — ver también terms-of-service-draft.md sección 10.]`

## 8. Cambios en esta política

Cualquier cambio material se notificará dentro de la aplicación antes de que entre en vigor.

## 9. Contacto

world.webapps@gmail.com — mismo punto de contacto único (para autoridades públicas y para usuarios, conforme a los arts. 11/12 del Reglamento de Servicios Digitales) descrito en la sección 15 de los [Términos de servicio](https://jordiribasoficial.github.io/App-para-aprender-idiomas/terms.html).

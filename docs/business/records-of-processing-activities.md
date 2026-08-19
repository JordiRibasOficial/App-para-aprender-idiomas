# Registro de Actividades de Tratamiento (RGPD art. 30)

> **Documento interno obligatorio, no se publica.** El RGPD exige a todo responsable del tratamiento mantener este registro internamente (art. 30.1), independientemente del tamaño de la empresa salvo excepciones muy concretas que no aplican aquí (tratamiento no ocasional de datos). Es distinto de la política de privacidad: esta es la versión interna y exhaustiva: qué se trata, para qué, con qué base legal, durante cuánto tiempo y con qué medidas — construido a partir de lo ya documentado en `privacy-policy-draft.md`, `play-console-setup-guide.md` y `src/backend/README.md`, no a partir de suposiciones nuevas. `[PENDIENTE: revisar con un asesor en protección de datos antes de tratarlo como definitivo — en particular la calificación de responsable/encargado de cada tercero.]`

**Responsable del tratamiento:** Webapps — `world.webapps@gmail.com`. `[PENDIENTE: forma legal real, ver business-registration-checklist.md.]`
**Delegado de Protección de Datos (DPO):** no designado — no es obligatorio dado el volumen y naturaleza del tratamiento actual (sin categorías especiales de datos, sin tratamiento a gran escala). Reevaluar si el volumen de usuarios crece sustancialmente.
**Última actualización:** 19 de agosto de 2026.

---

## 1. Verificación de compra de suscripción

- **Finalidad:** confirmar que una compra/restauración de suscripción es legítima y activar el acceso Premium correspondiente.
- **Base legal:** ejecución de un contrato (art. 6.1.b RGPD) — es necesario para prestar el servicio de suscripción que el usuario contrata.
- **Categorías de interesados:** usuarios de la App con una suscripción Premium activa o intentada.
- **Categorías de datos:** identidad anónima de sesión (UUID sin nombre/email), plataforma (Android/iOS), producto adquirido, estado de la suscripción, fecha de expiración, token de compra (verificado, no almacenado en claro tras la verificación — ver `src/backend/README.md`).
- **Destinatarios / encargados del tratamiento:** Supabase (alojamiento y base de datos — encargado, DPA incorporado automáticamente en sus Términos de Servicio, ver sección "Encargados" más abajo); Google Play Billing / Apple App Store (verificación de la compra en sí — actúan como responsables independientes de esa parte, no como encargados nuestros).
- **Transferencias internacionales:** Supabase aloja este proyecto en AWS, región `[PENDIENTE: confirmar región AWS concreta del proyecto — Project Settings → General en el Dashboard]`; si la región está fuera del EEE, aplican las Cláusulas Contractuales Tipo (SCC) de Supabase.
- **Plazo de conservación:** mientras la suscripción esté activa o pueda ser objeto de disputa/reembolso; sin fecha de purga automática definida hoy. `[PENDIENTE: definir plazo de purga para suscripciones expiradas hace mucho tiempo.]`
- **Medidas de seguridad:** RLS en Supabase (cada fila solo accesible por su propio dueño vía el backend), cifrado en reposo AES-256 (verificado, ver `src/backend/README.md`), TLS en tránsito, rate limiting sobre el endpoint de verificación.

## 2. Identidad anónima de sesión

- **Finalidad:** vincular las operaciones de un mismo dispositivo (compra, descarga de contenido Premium) sin necesidad de una cuenta real.
- **Base legal:** ejecución de un contrato (art. 6.1.b) e interés legítimo en prevenir abuso del servicio (art. 6.1.f) para el componente de rate limiting.
- **Categorías de interesados:** usuarios de la App.
- **Categorías de datos:** identificador anónimo (UUID de sesión Supabase Auth, sin PII).
- **Destinatarios / encargados:** Supabase.
- **Transferencias internacionales:** igual que actividad 1.
- **Plazo de conservación:** vinculado al ciclo de vida de la actividad 1; se elimina si el usuario solicita el borrado de sus datos de verificación de compra (ver `privacy-policy-draft.md` sección 6).
- **Medidas de seguridad:** igual que actividad 1.

## 3. Entrega de contenido de pago (idioma de estudio)

- **Finalidad:** servir el contenido del curso correspondiente (portugués/francés/japonés) únicamente a usuarios con Premium activo.
- **Base legal:** ejecución de un contrato (art. 6.1.b).
- **Categorías de interesados:** usuarios Premium.
- **Categorías de datos:** identidad anónima de sesión + idioma solicitado en cada petición (no se almacena un historial, solo se procesa en el momento — ver `get-course-content` en `src/backend/README.md`).
- **Destinatarios / encargados:** Supabase.
- **Transferencias internacionales:** igual que actividad 1.
- **Plazo de conservación:** no se persiste — solo se procesa en el momento de la petición (aparece en logs de la función durante el periodo de retención de logs, ver `privacy-policy-draft.md` sección 2 "Retención de logs").
- **Medidas de seguridad:** igual que actividad 1; validación de la suscripción activa antes de servir el contenido.

## 4. Publicidad (usuarios sin Premium activo)

- **Finalidad:** monetización de la versión gratuita mediante anuncios.
- **Base legal:** consentimiento (art. 6.1.a) para usuarios en la UE/Reino Unido, recabado vía el formulario UMP de Google antes de cualquier anuncio; en el resto de regiones, interés legítimo salvo que la normativa local exija consentimiento explícito. Para el identificador de publicidad en iOS (IDFA), consentimiento adicional específico vía el prompt de App Tracking Transparency (ver `AttTrackingManager`).
- **Categorías de interesados:** usuarios de la versión gratuita.
- **Categorías de datos:** identificador de publicidad del dispositivo (AAID en Android, IDFA en iOS solo si se acepta ATT), datos de interacción con el anuncio.
- **Destinatarios / responsables:** Google (AdMob) — actúa como **responsable independiente**, no como encargado nuestro, para el tratamiento de datos publicitarios (es su propia base legal, sus propios fines de medición/personalización). `[PENDIENTE: confirmar esta calificación con el asesor — depende de los términos contractuales reales de AdMob vigentes.]`
- **Transferencias internacionales:** gestionadas por Google bajo su propio marco de cumplimiento (SCC/certificaciones); fuera del control directo de Webapps.
- **Plazo de conservación:** gestionado por Google, no por nosotros.
- **Medidas de seguridad:** las propias de Google; de nuestro lado, los anuncios se desactivan automáticamente en cuanto hay Premium activo (`PremiumGatedBannerAd`).

## 5. Progreso de aprendizaje y ajustes (procesamiento local)

- **Finalidad:** guardar el progreso del usuario (lecciones completadas, racha, puntuación) y sus preferencias (tema, idioma seleccionado) entre sesiones de la App.
- **Base legal:** ejecución de un contrato (art. 6.1.b) — es la funcionalidad central de la App.
- **Categorías de interesados:** todos los usuarios.
- **Categorías de datos:** progreso de lecciones, racha, puntuación, tema de UI, email opcional (si el usuario lo introduce en el onboarding).
- **Destinatarios / encargados:** ninguno — estos datos **nunca salen del dispositivo** (SQLite/`shared_preferences`/`flutter_secure_storage` locales). No hay tratamiento por parte de Webapps más allá de que el código de la App, que nosotros escribimos, se ejecuta en el dispositivo del usuario.
- **Transferencias internacionales:** ninguna.
- **Plazo de conservación:** hasta que el usuario desinstale la App o borre los datos de la aplicación.
- **Medidas de seguridad:** email cifrado vía `flutter_secure_storage` (Keychain/EncryptedSharedPreferences); el resto sin cifrado adicional al ya provisto por el sandboxing del sistema operativo.

---

## Encargados del tratamiento — resumen

| Encargado | Rol | DPA | Notas |
|---|---|---|---|
| Supabase | Alojamiento, base de datos, Edge Functions | **Sí, en vigor** — verificado: su DPA "supplements and forms part of the Supabase Terms of Service" y queda incorporado automáticamente al aceptar dichos Términos (cláusula 7(b): "The Parties agree to comply with the Data Processing Addendum, which is incorporated into this Agreement"). No requiere firma ni acción separada en el Dashboard — ya está en vigor desde que existe la cuenta. | `[PENDIENTE: guardar copia/enlace fechado del DPA vigente en el momento de esta verificación, por si su contenido cambia más adelante — https://supabase.com/legal/dpa]` |
| Google (AdMob) | Publicidad | No aplica como encargado — actúa como responsable independiente (ver actividad 4). | — |
| Google Play / Apple | Procesamiento de pagos, distribución | No aplica como encargado — actúan como responsables independientes de esa parte. | — |

## Próxima revisión

Revisar y actualizar este registro cada vez que se añada una nueva actividad de tratamiento (p. ej. si se implementa subida de contenido por usuarios — ver sección 7 de `terms-of-service-draft.md`) o cambie un encargado existente.

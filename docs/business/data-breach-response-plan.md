# Plan de respuesta a brechas de seguridad (RGPD art. 33-34)

> **Documento interno de procedimiento, no se publica en la App ni en la web.** Define qué hacer si se detecta una brecha de seguridad que afecte a datos personales — hoy: identidad anónima de sesión, resultado de verificación de compra, idioma de estudio (Premium). Ver `docs/business/privacy-policy-draft.md` sección 2 para qué datos existen realmente. `[PENDIENTE: revisar con un asesor en protección de datos antes de necesitarlo de verdad — este documento no sustituye asesoramiento legal en el momento de una brecha real.]`

## Qué cuenta como "brecha de seguridad" (art. 4.12 RGPD)

Cualquier incidente que produzca, de forma accidental o ilícita, la destrucción, pérdida, alteración, comunicación o acceso no autorizados a datos personales. Incluye, por ejemplo:

- Acceso no autorizado a la base de datos de Supabase (`subscriptions`, `verify_purchase_attempts`).
- Filtración de credenciales/claves de servicio (`SUPABASE_SERVICE_ROLE_KEY`, claves de Google Play/Apple).
- Un despliegue erróneo que exponga datos de un usuario a otro (fallo de RLS).
- Pérdida de un backup sin cifrar, o acceso indebido a uno.

**No** cuenta como brecha en el sentido del RGPD: un fallo que solo afecte a disponibilidad sin exposición de datos (p. ej. el backend caído), aunque sí conviene documentarlo igualmente por motivos operativos.

## Fuentes de detección

Todas ya existen o se han cubierto en rondas anteriores de este checklist — este documento no añade herramientas nuevas, solo el procedimiento de qué hacer cuando alguna de ellas dispara:

- Logs de `console.error` de las Edge Functions (`src/backend/README.md` § Monitoring & alerts).
- Alertas basadas en logs del Dashboard de Supabase (5xx, picos de 401/403/429).
- Notificación directa de Supabase (son el "encargado del tratamiento" — están obligados por RGPD art. 28 a notificarte a ti sin dilación indebida si detectan una brecha en su infraestructura).
- Reporte externo (investigador de seguridad vía `.github/SECURITY.md`, usuario, Google Play/Apple).

## Procedimiento

### 1. Contención inmediata (primeras horas)

- Si es una clave/credencial filtrada: rotarla inmediatamente (Supabase service role key, claves de API de las tiendas).
- Si es un fallo de RLS o de código: desplegar el fix o, si no es posible al momento, deshabilitar temporalmente la función/tabla afectada.
- Preservar evidencia (logs, timestamps) antes de que roten o se borren — necesaria para evaluar el alcance.

### 2. Evaluación (siguientes horas, en paralelo a la contención)

Responder, con la evidencia disponible:

- ¿Qué datos concretos se han visto afectados? (usar la tabla de `docs/business/privacy-policy-draft.md` sección 2 como referencia de qué existe).
- ¿Cuántos usuarios, aproximadamente?
- ¿Es probable que suponga un riesgo para los derechos y libertades de los afectados? (dado que no se maneja email/nombre en el backend salvo que el usuario lo haya guardado localmente, y las identidades son anónimas, el riesgo real para la mayoría de brechas plausibles aquí es bajo-medio — pero **la evaluación real hay que hacerla caso por caso**, no asumir esto de antemano).

### 3. Notificación a la AEPD (RGPD art. 33) — plazo de 72 horas

**Si hay riesgo para los derechos y libertades de las personas** (el umbral es bajo — la ausencia de riesgo es la excepción, no la norma), hay que notificar a la Agencia Española de Protección de Datos **en un plazo máximo de 72 horas** desde que se tuvo conocimiento de la brecha:

- Formulario de notificación de brechas de la AEPD: `https://sedeagpd.gob.es` (sede electrónica, trámite "Notificación de violaciones de seguridad de los datos").
- Si no se puede completar en 72h, se notifica igualmente con la información disponible y se completa después por fases (permitido por el propio art. 33.4).
- Contenido mínimo: naturaleza de la brecha, categorías y número aproximado de afectados, categorías y número aproximado de registros afectados, contacto del responsable (`world.webapps@gmail.com`), consecuencias probables, medidas adoptadas o propuestas.

**Excepción:** no es necesario notificar a la AEPD si es improbable que la brecha suponga un riesgo para los derechos y libertades de las personas — pero esa decisión, y su justificación, debe quedar documentada igualmente (ver registro interno más abajo).

### 4. Notificación a los usuarios afectados (RGPD art. 34)

Solo obligatoria cuando la brecha suponga un **riesgo alto** (umbral más exigente que el de la AEPD). Si aplica:

- Comunicación directa "sin dilación indebida", en lenguaje claro y sencillo.
- Contenido: naturaleza de la brecha, contacto (`world.webapps@gmail.com`), consecuencias probables, medidas adoptadas y recomendadas para el usuario.
- Dado que hoy no se gestionan cuentas con email real (identidad anónima salvo el email opcional guardado solo localmente en el dispositivo del propio usuario — ver `privacy-policy-draft.md` sección 2), el canal de notificación directa es limitado: `[PENDIENTE: definir canal real de notificación a usuarios si no hay forma de contactarlos directamente — posible aviso dentro de la propia App en el próximo arranque, o nota pública si no hay otro medio, conforme permite el art. 34.3.c cuando la comunicación individual exigiría un esfuerzo desproporcionado.]`

### 5. Registro interno (obligatorio siempre, se notifique o no)

El art. 33.5 exige documentar **toda** brecha, se notifique o no a la AEPD: hechos, efectos y medidas adoptadas. Mantener un registro simple (fecha, qué pasó, alcance, si se notificó y a quién, medidas tomadas) — `[PENDIENTE: decidir dónde vive este registro; no debe ser público ni estar en este repo si contiene detalles de una brecha real].`

## Contactos relevantes

- Responsable del tratamiento: Webapps — `world.webapps@gmail.com`.
- Encargado del tratamiento (backend): Supabase — notificación de brechas de su lado vía su propio canal de soporte/seguridad.
- AEPD: `https://sedeagpd.gob.es`.

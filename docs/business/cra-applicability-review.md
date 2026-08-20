# Aplicabilidad del Reglamento de Ciber-Resiliencia de la UE (CRA)

> **Hallazgo de investigación, con una fecha real que conviene tener en el radar antes de publicar.** Verificado contra fuentes públicas sobre el Reglamento (UE) 2024/2847.

## Qué es y si aplica a esta app

El CRA regula "productos con elementos digitales" cuyo uso previsto o razonablemente previsible incluya una conexión de datos, directa o indirecta, a un dispositivo o red. Esto **incluye explícitamente apps móviles de consumo** — no es un reglamento solo para hardware/IoT. Esta app se conecta a un backend propio (Supabase), a AdMob y a las APIs de verificación de Google/Apple, así que encajaría dentro del alcance si se publica en el mercado de la UE.

## Calendario — esto es lo que importa de verdad ahora

- **Entrada en vigor:** diciembre de 2024.
- **Obligación de notificación de vulnerabilidades activamente explotadas e incidentes graves** (a ENISA/CSIRT, en 24h desde que se tiene conocimiento): exigible **desde el 11 de septiembre de 2026**. Hoy es 19 de agosto de 2026 — **quedan menos de un mes**.
- **Obligaciones principales** (evaluación de conformidad, marcado CE, documentación técnica completa): exigibles desde el **11 de diciembre de 2027**.

## El matiz que sí importa: "colocar en el mercado"

El CRA aplica a fabricantes que **colocan** el producto en el mercado de la UE. Esta app **todavía no está publicada** (ver checklists de Play Console/App Store Connect, ambas con pasos pendientes) — mientras no se publique, la obligación de notificación de septiembre de 2026 no se activa todavía en la práctica. Pero **si se publica antes de esa fecha, o poco después**, hay que tener ya el proceso listo, no improvisarlo el mismo día que aparezca una vulnerabilidad real.

## Exenciones

- **Software de código abierto no comercial:** no aplica aquí — esta app es un producto comercial.
- **Pequeñas empresas/autónomos:** el CRA reduce la carga administrativa para desarrolladores individuales/pequeñas empresas en algunas obligaciones de documentación, pero **no exime de la obligación de notificar vulnerabilidades explotadas activamente** — esa obligación no tiene un umbral de tamaño como el de la CCPA. `[PENDIENTE: confirmar con el asesor legal el alcance exacto de la reducción de carga aplicable a un desarrollador individual.]`

## Qué ya tenemos listo, y qué falta

**Ya cubierto por trabajo de rondas anteriores** de este checklist:

- Canal de reporte de vulnerabilidades (`.github/SECURITY.md` + `security.txt`) — la vía de entrada ya existe.
- Plan de respuesta a incidentes/brechas (`docs/business/data-breach-response-plan.md`) — el proceso interno de "qué hacer cuando pasa algo" ya existe, aunque está redactado en clave RGPD (datos personales), no en clave CRA (vulnerabilidad de seguridad del producto, haya habido o no exposición de datos personales).

**Falta:**

- Registrarse y saber notificar a **ENISA/el CSIRT nacional** específicamente (RGPD notifica a la AEPD; CRA notifica a un organismo distinto) dentro de las 24h desde que se detecta una vulnerabilidad activamente explotada o un incidente grave — el plan actual de brechas no menciona este canal.
- `[PENDIENTE: ampliar data-breach-response-plan.md (o crear un documento hermano) con el procedimiento de notificación CRA a ENISA/CSIRT, antes de publicar la app — idealmente antes de septiembre de 2026 si la publicación es inminente, aunque la obligación real solo se activa al colocar el producto en el mercado.]`

## Recomendación

No es urgente escribir el procedimiento de notificación a ENISA hoy mismo si la publicación todavía no es inminente (semanas/meses vista) — pero si tienes fecha de publicación fijada para antes o poco después de septiembre de 2026, este es el momento de ampliarlo. Dímelo cuando tengas fecha de lanzamiento y lo añado al plan de respuesta a incidentes.

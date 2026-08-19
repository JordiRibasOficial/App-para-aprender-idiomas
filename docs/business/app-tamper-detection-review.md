# Detección de manipulación/re-firma de la app

> **Hallazgo + recomendación, no implementado todavía — ver el motivo abajo antes de construir nada.**

## Por qué esto ya no es tan grave como parece

Antes de la ronda de "cierra el hueco real" (contenido Premium movido al backend, verificación de compra server-side), una APK re-firmada era un vector real: un atacante podía parchear el check local de `isPremium` y desbloquear contenido Premium gratis, o falsificar el estado de suscripción. **Ese hueco ya está cerrado** — hoy:

- El contenido Premium no existe en el cliente hasta que el backend confirma una suscripción activa (`get-course-content`).
- El estado de "Premium" se verifica contra la API real de Google/Apple, nunca se confía en lo que diga el cliente (`verify-purchase`).

Una APK re-firmada hoy **no puede** robar contenido de pago ni falsificar una suscripción — el servidor no confía en el cliente para nada de eso. Lo que sí sigue siendo posible con una APK modificada: quitar los anuncios (pérdida de ingresos, no de seguridad), o redistribuir una copia con otro nombre/marca (riesgo de reputación/marca, no de seguridad de datos).

## Por qué un chequeo de firma solo-cliente no sirve de mucho

Un chequeo típico (leer el certificado de firma de la app en tiempo de ejecución y compararlo con un hash esperado, hardcodeado en el propio APK) tiene una debilidad estructural: **el mismo atacante que re-firma la APK puede simplemente borrar o parchear ese chequeo antes de re-firmarla.** No hay nada que lo impida — el código del chequeo vive en el mismo binario que el atacante ya está modificando. Esto no es una opinión, es la razón documentada por la que Google sustituyó SafetyNet (que funcionaba así) por **Play Integrity API**, que sí es robusto porque la verificación ocurre fuera del binario: Google Play Services genera un token firmado criptográficamente que tu propio backend verifica contra los servidores de Google, no contra nada que viva en el APK.

Implementar el chequeo débil habría sido peor que no implementar nada: da una falsa sensación de seguridad sin cerrar el hueco real.

## La solución real: Play Integrity API

Requiere, en este orden:

1. **Activar Play Integrity API** en Play Console (Play Console → App integrity) — acción tuya, no la puedo hacer yo.
2. **Cliente**: pedir un token de integridad a Google Play Services antes de una operación sensible (p. ej. antes de restaurar/verificar una compra) — en Flutter, vía el plugin oficial `play_integrity` o invocando el SDK nativo de Play Integrity por canal de plataforma.
3. **Backend**: un nuevo endpoint (mismo patrón que `verify-purchase`/`export-user-data`) que reciba ese token y lo verifique contra la API de Google (`playintegrity.googleapis.com`), usando credenciales de una cuenta de servicio de Google Cloud — **otra credencial que solo tú puedes generar** (Google Cloud Console → cuenta de servicio con el rol "Play Integrity API").
4. Decidir qué hacer con una respuesta "no íntegra" (dispositivo rooteado sin Play Protect, app re-firmada, emulador no certificado): lo razonable aquí, dado que el hueco económico ya está cerrado, sería **registrar la señal para detectar patrones de abuso** (p. ej. muchos intentos desde apps no íntegras contra `verify-purchase`), no bloquear el uso — Play Integrity da falsos positivos en dispositivos legítimos pero antiguos/rooteados por el propio usuario para fines lícitos.

## Recomendación

Dado que el hueco económico real ya está cerrado por la arquitectura actual, esto pasa de "cierre un hueco crítico" a "señal adicional de abuso, de valor secundario". Es una pieza de trabajo más grande que las anteriores de esta sesión (requiere que actives Play Integrity API en Play Console y generes una cuenta de servicio de Google Cloud antes de que yo pueda escribir y probar el código real) — no la construyo sin que confirmes que quieres invertir en ello ahora. `[PENDIENTE: decisión de producto — ¿lo priorizamos con la infraestructura real de Google, o queda documentado para más adelante?]`

No aplica nada equivalente en iOS: App Store ya impide instalar binarios re-firmados fuera de TestFlight/App Store salvo jailbreak, que es un vector totalmente distinto (ya cubierto por el gating server-side del contenido Premium, no por esto).

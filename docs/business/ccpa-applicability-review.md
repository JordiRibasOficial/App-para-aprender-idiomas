# Aplicabilidad de la CCPA/CPRA (California)

> **Hallazgo de investigación, no requiere cambios de código hoy.** Verificado contra la página oficial del Attorney General de California (`oag.ca.gov/privacy/ccpa`).

## Umbrales de aplicabilidad

La CCPA (enmendada por la CPRA) solo aplica a un negocio si cumple **al menos uno** de estos tres umbrales:

1. Ingresos brutos anuales superiores a 25 millones USD.
2. Compra, venta o "comparte" ("shares") información personal de **100.000 o más residentes/hogares de California** al año.
3. Obtiene el 50% o más de sus ingresos anuales de la venta de información personal de residentes de California.

**Estado actual: no aplica.** La app aún no se ha publicado, no tiene usuarios ni ingresos — ninguno de los tres umbrales se cumple hoy.

## El matiz real que sí conviene vigilar

La CPRA define "compartir" ("sharing") como: *"sharing for cross-context behavioral advertising, which is the targeting of advertising to a consumer based on the consumer's personal information obtained from the consumer's online activity across numerous websites."*

Esto describe casi exactamente lo que hace **Google AdMob** con anuncios personalizados (usa el identificador de publicidad del dispositivo — AAID/IDFA — para segmentar anuncios según actividad entre apps). Es decir: si la app llega a tener actividad de anuncios personalizados con **100.000 dispositivos/usuarios de California**, probablemente se cruzaría el umbral 2 — que depende del **volumen de usuarios**, no de ingresos. Una app gratuita financiada con anuncios podría llegar ahí sin apenas ingresos propios, solo con tráfico.

## Qué implicaría cruzar el umbral (para cuando llegue el momento, no ahora)

- Enlace "Do Not Sell or Share My Personal Information" visible y accesible.
- Honrar la señal Global Privacy Control (GPC) del navegador/dispositivo cuando esté disponible.
- Sección específica de CCPA en la política de privacidad (categorías de información personal "compartida", derechos de los residentes de California, plazo de respuesta a solicitudes).
- Posible integración con el modo de "Restricted Data Processing" de Google/AdMob para usuarios de California que ejerzan su derecho de exclusión, en vez de bloquear anuncios por completo como con el consentimiento UMP/GDPR.

## Recomendación

No construir nada de esto ahora — sería trabajo especulativo para un umbral de usuarios que hoy no existe (la app ni siquiera está publicada). **Revisar este documento cuando haya datos reales de uso por región** (Play Console / App Store Connect Analytics, una vez publicada) y cruzar el umbral de 100.000 dispositivos activos de California específicamente, no el total global. `[PENDIENTE: no es una acción con fecha — es un disparador a vigilar.]`

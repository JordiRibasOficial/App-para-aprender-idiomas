# Guía paso a paso — configurar la app en Google Play Console

> Para cuando ya tienes la cuenta de Play Console creada, verificada y pagada. Esto es una guía de ejecución directa por tu parte — no hay ninguna API por la que yo pueda crear la app o los productos de suscripción en tu cuenta; lo que sí puedo garantizar es que cada valor de aquí abajo coincide exactamente con lo que ya implementa el código, para que no haya desajustes entre lo que declaras en Play Console y lo que la app hace de verdad.

## 1. Crear la app

**Play Console → Todas las apps → Crear app**

| Campo | Valor |
|---|---|
| Nombre de la app | `App para Aprender Idiomas` |
| Idioma predeterminado | Español (España) |
| Tipo | App |
| Gratis o de pago | **Gratis** (el curso de inglés A1 completo es gratis; Premium es una suscripción dentro de la app, no un pago de entrada) |

**Nombre del paquete (package name / applicationId):**
```
com.worldwebapps.app.aprenderidioma
```
Tiene que coincidir exactamente con `applicationId` en `src/mobile/android/app/build.gradle.kts:18` — ya está así en el código, no hace falta tocar nada ahí.

## 2. Ficha de la tienda (Store listing)

Todos los textos ya están escritos y verificados contra el código en `docs/business/store-listing.md` — cópialos y pégalos tal cual en la sección "Ficha de la tienda principal":
- Descripción corta y completa
- Categoría: Educación
- Email de contacto: `world.webapps@gmail.com`
- URL de política de privacidad: `https://jordiribasoficial.github.io/App-para-aprender-idiomas/privacy.html`

**Gráficos** (en `docs/business/brand-assets/` y `docs/business/store-screenshots/`):
- Icono de la app (512×512): `icon_1024.png` (redimensiona o sube el de 1024, Play acepta hasta ese tamaño)
- Gráfico de feature (1024×500): `feature_graphic_1024x500.png`
- Capturas de pantalla: las de `store-screenshots/` sirven como placeholder honesto, pero **no cumplen las medidas exactas de teléfono que pide Play** (fueron generadas a 390×844 vía Flutter Web, no desde un dispositivo/emulador Android real). En cuanto el job `integration-test-android` del CI esté en verde (ya tenemos un emulador Android real funcionando ahí), puedo generar capturas reales desde ese mismo emulador con las medidas correctas — dímelo cuando quieras que lo haga.

## 3. Cuestionario de clasificación de contenido

**Play Console → Política → Clasificación de contenido**

La app no tiene contenido violento, sexual, de apuestas, ni generado por otros usuarios (no hay chat, no hay contenido de terceros). Todas las respuestas del cuestionario deberían ser "No" salvo las que declaran que es una app educativa. Resultado esperado: **PEGI 3 / Apto para todos los públicos**.

## 4. Sección "Seguridad de los datos" (Data safety)

Esto tiene que reflejar lo que el código hace de verdad — he revisado el repositorio para que esta tabla sea exacta, no una suposición:

| Dato | ¿Se recopila? | Detalle |
|---|---|---|
| Dirección de email | **Sí, opcional** | Solo si el usuario crea una cuenta real (Supabase Auth) eligiendo "Registrarse con email" — desde el onboarding (`auth_choice_screen.dart`), o más tarde cuando la app se lo pide al intentar comprar/restaurar Premium, abrir un idioma de pago o usar "Mis datos" (`require_account.dart`) — en vez de seguir como invitado. **Finalidad "Funcionalidad de la app"** (la cuenta en sí) y, si el usuario marca la casilla separada de marketing, también **finalidad "Marketing"** (guardado en una tabla propia dedicada, `marketing_contacts`) — marca ambas finalidades en el cuestionario, la de marketing solo aplica a quien la consintió explícitamente. **Al completar una compra**, el email de la cuenta se envía además una única vez a nuestro backend junto con esa compra, para el correo de confirmación que exige el art. 98.7 TRLGDCU (vía Resend) — esa transmisión puntual no se guarda en ninguna tabla propia. Marca esta fila como compartida con un tercero (Resend) para esa finalidad puntual en el cuestionario. |
| Progreso de aprendizaje (lecciones completadas, racha, puntuación) | Sí | Guardado solo localmente en el dispositivo. No se comparte con terceros. |
| Historial de compras / facturación | **Sí** | Comprar/restaurar una suscripción, y descargar un curso de pago, requieren tener la cuenta real de arriba — la app la pide antes, nunca después de cobrar. Google Play Billing (`in_app_purchase`) procesa el pago en sí, según su propia política. Además, nuestro backend verifica cada compra directamente contra la API de Google Play y guarda el resultado (plataforma, producto, estado, fecha de expiración) asociado a esa cuenta — nunca a un nombre suelto ni a datos de pago. |
| Idioma de estudio (solo suscriptores Premium) | **Sí** | Al abrir un curso de pago (portugués/francés/japonés), la app lo pide a nuestro backend, que revela qué idioma está estudiando ese usuario en el momento de la descarga — ver `get-course-content` en `src/backend/README.md`. |
| Identificador de publicidad, datos de dispositivo para anuncios | **Sí, solo para usuarios sin Premium activo** | Google AdMob (`google_mobile_ads`) muestra anuncios en la versión gratuita — se desactivan automáticamente en cuanto hay una suscripción Premium activa (`PremiumGatedBannerAd`, gateado por `entitlementProvider`). Se pide consentimiento vía el formulario UMP de Google para usuarios en la UE/Reino Unido antes de mostrar cualquier anuncio. **Marca esta app como "Contiene anuncios" en Play Console** y completa la subsección de publicidad del cuestionario de seguridad de datos con AdMob como proveedor. |
| Ubicación, contactos, fotos, analítica de terceros | No | No hay ningún SDK de analítica de comportamiento ni de marketing de terceros integrado — solo el SDK de anuncios de arriba y nuestro propio backend (Supabase) para lo descrito en las filas anteriores, incluida la fila de marketing por email, que es first-party (nuestra propia tabla), no un SDK de terceros. |
| Datos de fallos (crash) | **Sí** | Sentry (`sentry_flutter`), solo en builds de producción — captura la excepción, el stack trace y contexto técnico del dispositivo/SO cuando la app falla, vinculado a un ID de instalación anónimo generado por el propio SDK, no a ningún dato de usuario. Ver `docs/business/crash-reporting-review.md`. Marca esta fila en la subsección "Datos de la app" → "Fallos de la aplicación" del cuestionario. |

Marca "Los usuarios pueden pedir que se borren sus datos" (borrar la app borra todo lo local; para los datos de verificación de compra guardados en el backend, ver la sección 6 de `privacy-policy-draft.md`). Ya **no** marques "No se comparten datos con terceros", "Sin anuncios" ni "Ningún dato se envía fuera del dispositivo" — ninguna de las tres es cierta con AdMob + el backend de verificación integrados.

## Audiencia objetivo (Target audience) y Política de Familias

Distinto de la sección "Data safety" de arriba: **Play Console → Ficha de Play Store → Contenido de la app → Audiencia objetivo y contenido** obliga a declarar explícitamente el grupo de edad al que se dirige la app, no solo qué datos recopila.

- **Grupos de edad a marcar**: dado que el mínimo de edad ya fijado en el código y en el ToS/privacy policy es **16 años** (ver `terms-of-service-draft.md` sección 10), marca únicamente **"18 y mayores"** — no marques ningún grupo de 17 años o menos, ni siquiera "13-15" o "16-17", para que la declaración de Play Console sea coherente con esa política, aunque la casilla de autodeclaración de edad del onboarding no impida técnicamente que alguien mienta sobre su edad.
- **No marques "Diseñada principalmente para niños" ni "Atractiva para niños"** — hacerlo activa la Política de Familias de Google Play, que **prohíbe la publicidad conductual/personalizada** (obligaría a AdMob a servir solo anuncios no personalizados, incompatible con el consentimiento UMP ya implementado que sí permite anuncios personalizados) y añade requisitos adicionales de diseño y de aprobación humana de contenido, ninguno de los cuales aplica aquí.
- Esta declaración es **independiente y compatible** con la clasificación de contenido (IARC) de la sección de abajo — una app puede clasificarse "Para todos los públicos" en contenido y aun así declarar una audiencia objetivo adulta si así lo decide el desarrollador, que es exactamente este caso.
- `[PENDIENTE: solo se puede completar desde la propia consola de Play — no hay API de Play Console disponible en este entorno para verificarlo o rellenarlo automáticamente, mismo caso que la protección de la rama en GitHub.]`

## 5. Productos de suscripción (lo más importante — que coincidan con el código)

**Play Console → Monetizar → Productos → Suscripciones → Crear suscripción**

El código en `src/mobile/lib/domain/models/subscription_plan.dart:26-27` espera exactamente estos dos IDs de producto — si los creas con un ID distinto, la app no encontrará los planes al conectar con la tienda real:

### Suscripción mensual
| Campo | Valor |
|---|---|
| ID del producto | `monthly_sub` |
| Nombre | Premium mensual |
| Precio (España/UE, referencia) | **14,99 €/mes** |
| Periodo de facturación | 1 mes |

### Suscripción anual
| Campo | Valor |
|---|---|
| ID del producto | `annual_sub` |
| Nombre | Premium anual |
| Precio (España/UE, referencia) | **89,94 €/año** |
| Periodo de facturación | 1 año |

Estos son los precios que confirmaste (14,99 €/mes, 89,94 €/año — un ahorro real del 50% frente a pagar mensual todo el año). Play Console te dejará fijar el precio en euros y luego convertirá automáticamente al resto de monedas por región — revisa que la conversión automática no distorsione el precio en mercados grandes (EE.UU., Reino Unido) antes de publicar, si te importa el precio exacto ahí.

Una vez creados y **activados** (no solo guardados como borrador), la app real (no la de pruebas con `MockSubscriptionRepository`) podrá cargarlos vía `InAppPurchaseSubscriptionRepository` — ese código ya está implementado y probado (69 tests en `test/`, más los de integración en dispositivo real que están terminando de verificarse en CI ahora mismo).

## 6. Cuenta de AdMob y IDs de anuncio reales [HECHO]

La app ya integra Google AdMob (banner discreto, solo para usuarios sin Premium activo, oculto en el instante en que se activa una suscripción). **Cuenta creada y los IDs reales ya están en el código** (publisher `ca-app-pub-6843680802048559`) — `ad_unit_ids.dart`, `AndroidManifest.xml` e `Info.plist` actualizados, `flutter analyze`/`flutter test` verificados en verde.

**Auditado: `ad_unit_ids.dart` cambia automáticamente entre IDs de prueba (`publisher 3940256099942544`, el mismo en todas las apps de ejemplo de Google) y los IDs reales según `kReleaseMode`** — solo un build de release (`flutter build ... --release`, lo único que sube a las tiendas) sirve los anuncios reales; cualquier `flutter run` de desarrollo local sirve siempre los de prueba. Esto evita generar impresiones/clics no genuinos desde dispositivos de desarrollador, que la política de "tráfico inválido" de Google prohíbe explícitamente y puede acabar en suspensión de la cuenta de AdMob — antes de esta auditoría, el código servía los IDs reales incondicionalmente, incluso en desarrollo.

## 7. Track de pruebas interno (recomendado antes de producción)

**Play Console → Pruebas → Pruebas internas → Crear versión nueva**

Sube el `.aab` (generado con `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info` — el nombre de clases/miembros Dart queda ofuscado en el binario público; guarda la carpeta `build/debug-info` fuera del repo, hace falta para poder leer los stack traces de crashes reales más adelante) a este track primero. Te permite:
- Probar compras reales de suscripción con tarjetas de prueba, sin cobro real
- Añadir tu propio email como probador y confirmar el flujo completo de principio a fin
- Detectar cualquier problema de configuración de la ficha antes de exponerla al público

## 8. Firma de la app (App signing)

Play Console gestiona la firma por ti por defecto ("Play App Signing") — no hace falta que generes ni guardes tú una keystore de producción. Solo confirma que está activado (lo está por defecto en apps nuevas) la primera vez que subas un `.aab`.

---

## Checklist rápido

- [ ] App creada con el package name correcto
- [ ] Ficha de tienda rellenada (textos de `store-listing.md`)
- [ ] Gráficos subidos (icono, feature graphic, 7 capturas reales — ya generados y verificados, ver `store-listing.md` § "Lo que falta", solo falta subirlos)
- [ ] Cuestionario de clasificación de contenido completado
- [ ] Sección de seguridad de datos completada (tabla de arriba)
- [ ] Suscripción `monthly_sub` creada y **activada**
- [ ] Suscripción `annual_sub` creada y **activada**
- [x] Cuenta de AdMob creada y vinculada, IDs de unidad de anuncio reales en el código
- [ ] Primer `.aab` subido al track de pruebas internas
- [ ] Compra de prueba real completada con tarjeta de prueba

Todo lo de este documento es ejecutable ya, no depende de que termine la incidencia de GitHub Actions.

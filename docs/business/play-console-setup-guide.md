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
| Dirección de email | **Sí, opcional** | Solo si el usuario elige "continuar con email" en el onboarding (`auth_choice_screen.dart`) en vez de "continuar como invitado". Se guarda **únicamente en el dispositivo** (`SharedPreferences`, vía `SharedPreferencesOnboardingRepository`) — la app no tiene backend propio, nunca se envía a ningún servidor nuestro. |
| Progreso de aprendizaje (lecciones completadas, racha, puntuación) | Sí | Guardado solo localmente en el dispositivo, mismo mecanismo que arriba. No se comparte con terceros. |
| Historial de compras / facturación | No lo recopila la app directamente | Las suscripciones se gestionan vía Google Play Billing (`in_app_purchase`) — es Google quien procesa y almacena esos datos según su propia política, la app solo consulta el estado de la suscripción. |
| Identificador de publicidad, datos de dispositivo para anuncios | **Sí, solo para usuarios sin Premium activo** | Google AdMob (`google_mobile_ads`) muestra anuncios en la versión gratuita — se desactivan automáticamente en cuanto hay una suscripción Premium activa (`PremiumGatedBannerAd`, gateado por `entitlementProvider`). Se pide consentimiento vía el formulario UMP de Google para usuarios en la UE/Reino Unido antes de mostrar cualquier anuncio. **Marca esta app como "Contiene anuncios" en Play Console** y completa la subsección de publicidad del cuestionario de seguridad de datos con AdMob como proveedor. |
| Ubicación, contactos, fotos, analítica de terceros | No | No hay ningún SDK de analítica integrado en el código — solo el SDK de anuncios de arriba. |

Marca "Los usuarios pueden pedir que se borren sus datos" (borrar la app borra todo lo almacenado localmente). Ya **no** marques "No se comparten datos con terceros" ni "Sin anuncios" — con AdMob integrado, ninguna de las dos es cierta.

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

## 6. Cuenta de AdMob y IDs de anuncio reales

La app ya integra Google AdMob (banner discreto, solo para usuarios sin Premium activo, oculto en el instante en que se activa una suscripción). Ahora mismo usa **los IDs de prueba oficiales de Google** (`ca-app-pub-3940256099942544/...`) — siempre devuelven anuncios de prueba, nunca generan ingresos reales. Para monetizar de verdad:

1. Crea una cuenta en [admob.google.com](https://admob.google.com) (gratis, vinculada a tu cuenta de Google — puede ser la misma que usas para Play Console).
2. Vincula tu app de Play Console desde AdMob (o crea la entrada de la app manualmente en AdMob con el mismo package name `com.worldwebapps.app.aprenderidioma`).
3. Crea una unidad de anuncio de tipo **banner** para Android y otra para iOS.
4. Pásame los dos ID de unidad de anuncio reales y el App ID de AdMob de cada plataforma — actualizo `src/mobile/lib/data/ads/ad_unit_ids.dart` (el ID de la unidad de anuncio) y `AndroidManifest.xml`/`Info.plist` (el App ID) en un momento.

**No subas un build a producción con los IDs de prueba activos** — Google lo prohíbe explícitamente (política de "fraudulent clicks"/spam) y puede suspender la cuenta de AdMob. Los de prueba son solo para desarrollo y para el track de pruebas internas del punto 7.

## 7. Track de pruebas interno (recomendado antes de producción)

**Play Console → Pruebas → Pruebas internas → Crear versión nueva**

Sube el `.aab` (lo genera `flutter build appbundle --release`, ya verificado que compila limpio en CI) a este track primero. Te permite:
- Probar compras reales de suscripción con tarjetas de prueba, sin cobro real
- Añadir tu propio email como probador y confirmar el flujo completo de principio a fin
- Detectar cualquier problema de configuración de la ficha antes de exponerla al público

## 8. Firma de la app (App signing)

Play Console gestiona la firma por ti por defecto ("Play App Signing") — no hace falta que generes ni guardes tú una keystore de producción. Solo confirma que está activado (lo está por defecto en apps nuevas) la primera vez que subas un `.aab`.

---

## Checklist rápido

- [ ] App creada con el package name correcto
- [ ] Ficha de tienda rellenada (textos de `store-listing.md`)
- [ ] Gráficos subidos (icono, feature graphic, capturas — placeholder válido por ahora)
- [ ] Cuestionario de clasificación de contenido completado
- [ ] Sección de seguridad de datos completada (tabla de arriba)
- [ ] Suscripción `monthly_sub` creada y **activada**
- [ ] Suscripción `annual_sub` creada y **activada**
- [ ] Cuenta de AdMob creada y vinculada (o IDs de unidad de anuncio reales enviados para actualizar el código)
- [ ] Primer `.aab` subido al track de pruebas internas
- [ ] Compra de prueba real completada con tarjeta de prueba

Todo lo de este documento es ejecutable ya, no depende de que termine la incidencia de GitHub Actions.

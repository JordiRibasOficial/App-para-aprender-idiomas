# Ficha de tienda (borrador) — App para Aprender Idiomas

> **Borrador de textos, listo para copiar y pegar en Play Console / App Store Connect en cuanto tengas las cuentas.** Los assets gráficos (icono final, gráfico de feature, capturas de pantalla) siguen pendientes — ver la sección "Lo que falta" al final. Nada de este documento se ha subido a ninguna tienda todavía.

## Nombre de la app

**"App para Aprender Idiomas"** (25 caracteres — cabe en el límite de 30 de ambas tiendas).

**Nota de ASO (App Store Optimization), a decidir:** este nombre no incluye "inglés", que es probablemente el término de búsqueda más directo para el MVP (solo hay curso de inglés completo por ahora). Una alternativa más orientada a búsqueda sería algo como *"Aprende Inglés - Idiomas"* (24 caracteres), que mete la palabra clave principal en el título — el campo con más peso en el algoritmo de búsqueda de ambas tiendas. Lo dejo como decisión tuya, no cambio el nombre del proyecto unilateralmente; mientras tanto, la keyword "inglés" ya está bien representada en subtítulo/descripción corta más abajo.

---

## Google Play Console

**Descripción corta** (máx. 80 caracteres):
```
Aprende inglés de verdad: lecciones cortas, contenido real, sin relleno.
```
(72 caracteres)

**Descripción completa** (máx. 4000 caracteres):
```
Aprende inglés con lecciones de 5 minutos que encajan en tu día — no otra app que empiezas y abandonas.

CURSO DE INGLÉS A1 COMPLETO, GRATIS DESDE EL PRIMER DÍA
5 unidades, 20 lecciones, 120 ejercicios reales: saludos y presentaciones, números y la hora, familia y personas, comida y bebida, rutina diaria. No es una demo — es un curso A1 entero, sin ninguna lección bloqueada tras un muro de pago.

TRES TIPOS DE EJERCICIO, CADA UNO ENSEÑA ALGO DISTINTO
- Opción múltiple para reconocer vocabulario y gramática
- Rellenar el hueco para practicar la forma exacta de una palabra
- Emparejar para conectar conceptos en español e inglés

TU PROGRESO, GUARDADO EN TU DISPOSITIVO
Rachas diarias, puntuación acumulada y lecciones completadas — todo guardado localmente, sin necesidad de crear una cuenta para empezar.

PREMIUM: PORTUGUÉS, FRANCÉS Y JAPONÉS
La suscripción Premium (mensual o anual, con descuento en el plan anual) desbloquea los cursos A1 completos de portugués, francés y japonés — misma calidad y estructura que el inglés, ya disponibles, no "próximamente". El curso de inglés A1 no está detrás de un muro — lo premium es una ampliación real de idiomas, no un rescate de lo básico.

Sin gamificación vacía. Sin relleno. Contenido real, revisado, que se puede completar de verdad.
```

**Categoría:** Educación

**Etiquetas sugeridas:** aprender inglés, idiomas, educación, vocabulario, gramática

**Clasificación de contenido:** Apto para todos los públicos (sin contenido objetable — habrá que completar el cuestionario real de Play Console, esto es solo la expectativa).

**Email de contacto de la ficha:** world.webapps@gmail.com

**URL de política de privacidad (obligatoria):** `https://jordiribasoficial.github.io/App-para-aprender-idiomas/privacy.html` — publicada y en vivo.

---

## Apple App Store Connect

**Subtítulo** (máx. 30 caracteres):
```
Inglés en lecciones de 5 min
```
(28 caracteres)

**Texto promocional** (máx. 170 caracteres — se puede cambiar sin pasar revisión, útil para anuncios puntuales):
```
Curso de inglés A1 completo, gratis desde el primer día. 5 unidades, 120 ejercicios reales. Sin relleno, sin muro de pago en lo básico.
```

**Descripción** (máx. 4000 caracteres): igual que la de Google Play de arriba — Apple no impone un formato distinto, se puede reutilizar tal cual.

**Palabras clave** (máx. 100 caracteres, separadas por comas, sin espacios para aprovechar el límite):
```
ingles,aprender ingles,curso ingles,idiomas,vocabulario,gramatica,a1 ingles,ingles gratis
```
(89 caracteres)

**Categoría primaria:** Educación
**Categoría secundaria:** Referencia (opcional)

**Clasificación de edad:** 4+ (sin contenido objetable — a completar en el cuestionario real de App Store Connect).

**URL de soporte (obligatoria):** `https://jordiribasoficial.github.io/App-para-aprender-idiomas/` — misma página, sirve como landing de soporte/legal.
**URL de política de privacidad (obligatoria):** `https://jordiribasoficial.github.io/App-para-aprender-idiomas/privacy.html` — publicada y en vivo.

---

## Lo que falta (fuera del alcance de este documento)

- ~~Icono final~~ **[HECHO — primera pasada, ver nota]** — marca de globo (mismo motivo que `Icons.language` en la app) en color de marca `#3D5AFE`, generada programáticamente (`tools/branding/generate_assets.py`) y aplicada a Android (icono clásico + adaptativo) e iOS con `flutter_launcher_icons`. Verificado: `flutter analyze`/`flutter test` limpios y `flutter build appbundle --release` compila con los iconos nuevos. Master en `docs/business/brand-assets/icon_1024.png`. **Limitación real: no es un logo diseñado por un profesional** — es una marca simple y consistente con el icono ya usado dentro de la app, válida para publicar, pero conviene sustituirla si en algún momento se invierte en identidad de marca real.
- ~~Gráfico de feature de Play Store~~ **[HECHO — primera pasada, misma nota]** — 1024×500 con el mismo emblema + nombre de la app + idiomas soportados, en `docs/business/brand-assets/feature_graphic_1024x500.png`.
- ~~Capturas de pantalla~~ **[HECHO — 7/7 reales]** — 7 capturas en `docs/business/store-screenshots/`, todas del emulador Android real (perfil Pixel 6, 1080×2337, CI vía `flutter drive`): `01-welcome`, `02-idioma` (con el gate de Premium visible en portugués/francés/japonés), `03-nivel`, `04-lecciones`, `05-ejercicio`, `06-ejercicio2`, `07-premium`. Costó 13 ejecuciones del workflow `.github/workflows/store-screenshots.yml` (`workflow_dispatch`, `integration_test/screenshot_*.dart` vía `flutter drive`) encontrando y arreglando bugs reales por el camino: script mal formado, falta `convertFlutterSurfaceToImage()` en Android, `pageBack()` sin destino con rutas por `go()`, el singleton `appRouter` reteniendo estado entre tests, `SharedPreferences` real persistiendo entre tests, `takeScreenshot()` devolviendo bytes obsoletos entre testWidgets del mismo proceso (arreglado moviendo 05-07 a su propio proceso `flutter drive` cada uno) y, por último, esos mismos 05-07 volviendo con bytes idénticos a una captura de un proceso *anterior y distinto* aun con la aserción de navegación en verde — el compositor de Android no había terminado de pintar el frame nuevo en el instante exacto de `takeScreenshot()`. Arreglado con una pausa real de 1s (no `pumpAndSettle()`, que solo espera animaciones del lado Flutter) justo antes de cada captura. Verificado por checksum: las 7 capturas tienen SHA-256 distintos entre sí.
- ~~Alojar la política de privacidad y los términos~~ **[HECHO]** — página estática en vivo en la rama `gh-pages` (`index.html`, `privacy.html`, `terms.html`), GitHub Pages activado, verificado con `curl` (HTTP 200 en las 3 URLs, contenido correcto).
- ~~Nombre legal/razón social y email de contacto~~ **[HECHO]** — Webapps / world.webapps@gmail.com, ya rellenados en las páginas publicadas y en los borradores de `privacy-policy-draft.md`/`terms-of-service-draft.md`. Sigue pendiente de un asesor real confirmar si "Webapps" corresponde a una figura legal constituida (autónomo/SL) o es solo un nombre comercial — ver `business-registration-checklist.md`.

Todo lo de texto de este documento está listo para copiar y pegar en cuanto tengas las cuentas aprobadas.

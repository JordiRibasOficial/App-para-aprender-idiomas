# Screenshots reales vía Flutter Web + Playwright

Este contenedor no tiene emulador gráfico Android/iOS, así que no se pueden generar
capturas de pantalla reales de la forma habitual. Este directorio contiene una
alternativa: compilar la app con el target Flutter Web y capturarla con un
navegador Chromium real (Playwright).

Esto **no** convierte el proyecto en una app web — `src/mobile/web/` es solo un
scaffold auxiliar para poder generar capturas de pantalla reales de la UI. El
target de lanzamiento sigue siendo únicamente Android + iOS.

## Uso

```bash
cd src/mobile
~/flutter/bin/flutter build web --release
./../../tools/web-screenshots/patch-local-canvaskit.sh build/web/flutter_bootstrap.js
python3 -m http.server 8765 -d build/web &
cd ../../tools/web-screenshots
npm install
node shoot.js
```

Las capturas se guardan en `tools/web-screenshots/screenshots/`.

## Por qué hacen falta dos parches

1. **CanvasKit local**: por defecto Flutter Web carga `canvaskit.wasm`/`.js` desde
   `gstatic.com`. Si esa red no es accesible (como en este sandbox), la app se
   queda en blanco. `patch-local-canvaskit.sh` fuerza el uso de la copia local que
   `flutter build web` ya deja en `build/web/canvaskit/`.
2. **Fuente local**: Flutter Web también intenta descargar Roboto desde
   `fonts.gstatic.com`. Si falla, CanvasKit no tiene bytes de fuente y el texto no
   se dibuja (aunque el resto de la UI sí). `shoot.js` intercepta esa petición vía
   Playwright y sirve una fuente local (`Liberation Sans`) en su lugar — solo
   afecta a la captura, no a la app real.
3. **Semántica para clicks**: CanvasKit dibuja todo en un `<canvas>`, así que
   Playwright no puede hacer `getByText(...)` hasta que el árbol de accesibilidad
   de Flutter se activa (clic en el `flt-semantics-placeholder` oculto, lo mismo
   que dispararía un lector de pantalla).

## Nota sobre in_app_purchase en web

El paquete `in_app_purchase` no tiene implementación para Flutter Web. Por eso
`subscriptionRepositoryProvider` usa `MockSubscriptionRepository` cuando
`kIsWeb` es verdadero — así la pantalla de Premium se puede capturar sin que la
app real (Android/iOS) pierda su integración real con las tiendas.

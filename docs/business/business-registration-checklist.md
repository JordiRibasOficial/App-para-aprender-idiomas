# Checklist informativo — alta de actividad y fiscalidad (borrador)

> **Puramente informativo. No es asesoría fiscal ni legal, y no se ha ejecutado ningún trámite real.** Cada punto está marcado como pendiente de un asesor/gestoría real, tal y como confirmaste que harías antes de publicar. Este documento existe para que sepas qué preguntas llevar a esa reunión, no para sustituirla.

## 1. Forma legal de la actividad

- [ ] **Pendiente de asesor**: decidir entre autónomo (persona física) o sociedad (SL) para operar la app. Factores a llevar a la reunión: ingresos esperados (ver `financial-projection.md`), otros negocios/actividades que ya gestionas (mencionaste tener varios proyectos — puede afectar a si conviene una sociedad holding o una SL específica), y responsabilidad patrimonial deseada.
- [ ] **Pendiente de asesor**: si ya tienes una estructura societaria de otro proyecto, preguntar si esta app puede operar bajo la misma o si conviene una entidad separada.

## 2. Alta de actividad (España, si operas desde aquí)

- [ ] **Pendiente de asesor**: alta en el Censo de Empresarios (modelo 036/037) con el epígrafe de IAE correspondiente a desarrollo/venta de software o servicios digitales.
- [ ] **Pendiente de asesor**: si autónomo, alta en el RETA (Régimen Especial de Trabajadores Autónomos) — confirmar si ya estás dado de alta por otro proyecto y cómo se combina con esta actividad.

## 3. IVA e IVA digital (ventas dentro de la UE)

- [ ] **Pendiente de asesor**: las suscripciones se venden **a través de Google Play y Apple App Store**, no directamente. En la mayoría de los casos, Apple y Google actúan como "reseller of record" (venden ellos la suscripción al usuario final y nos pagan a nosotros como desarrolladores) — esto normalmente simplifica mucho la gestión del IVA digital, porque son las tiendas quienes declaran el IVA de la venta al consumidor final, no nosotros directamente. **Confirmar con el asesor si este es el caso para nuestro tipo de producto/región y qué obligaciones de IVA quedan de nuestro lado** (típicamente, el IVA sobre la comisión/pago que recibimos de la tienda, no sobre el precio de venta al usuario).
- [ ] **Pendiente de asesor**: si en el futuro se vende algo directamente al usuario sin pasar por la tienda (p. ej. una web de pago aparte), preguntar por el régimen de ventanilla única (OSS - One Stop Shop) para IVA digital en la UE — no aplica mientras todo pase por las tiendas.

## 4. Facturación con Apple y Google

- [ ] **Pendiente de asesor**: entender el ciclo de pagos de Google Play Console y App Store Connect (mensual, con retenciones/umbrales mínimos) y cómo se registran esos ingresos contablemente.
- [ ] **Pendiente de asesor**: confirmar si las tiendas emiten factura/liquidación automáticamente o si hace falta generar algún documento propio para la contabilidad.

## 5. Protección de datos (RGPD)

- [ ] **Pendiente de asesor legal**: revisar y aprobar `privacy-policy-draft.md` antes de publicarla como definitiva.
- [x] **Actualizado — ya no aplica tal como estaba escrito**: esta nota asumía que no había backend; ahora sí lo hay (Supabase, verificación de compra, identidad anónima — ver `privacy-policy-draft.md` sección 2). Además, el "registro ante la AEPD" que citaba es del régimen antiguo (LOPD 1999) — el RGPD lo sustituyó por el **registro interno de actividades de tratamiento** (art. 30), que no se presenta ante la AEPD, se mantiene internamente. Ya existe: `docs/business/records-of-processing-activities.md`. `[PENDIENTE: el asesor legal debe revisar igualmente ese registro y confirmar que no aplica ninguna obligación adicional de notificación previa para este caso concreto.]`

## 6. Cuentas de plataforma (acción directa del usuario, no de un asesor)

- [ ] Crear cuenta de Google Play Console (25 USD, pago único) — la creas y pagas tú, con mi guía técnica cuando llegue el Paso 13.
- [ ] Crear cuenta de Apple Developer Program (99 USD/año) — igual, la creas y pagas tú.
- [ ] Al crear ambas cuentas, decidir si se registran a tu nombre personal o a nombre de la entidad legal que resulte de los puntos 1-2 — mejor decidirlo con el asesor ANTES de crear las cuentas, porque cambiar el titular después suele ser más complicado que hacerlo bien la primera vez.

## Resumen para la reunión con el asesor real

Lleva a la reunión: este checklist, `financial-projection.md` (para hablar de volumen esperado), y la lista de tus otros proyectos/negocios activos (para decidir si esta app encaja en una estructura ya existente o necesita una nueva).

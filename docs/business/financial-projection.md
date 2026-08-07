# Proyección financiera estimada — App para Aprender Idiomas

> **ESTIMACIÓN, no una proyección financiera profesional.** Construida con supuestos declarados explícitamente, muchos de ellos sin validar con datos reales. No usar para decisiones de inversión, préstamos, o declaraciones fiscales sin que un asesor financiero/fiscal real la revise y, muy probablemente, la rehaga con supuestos propios.

## Supuestos declarados

| Supuesto | Valor usado | Fuente / confianza |
|---|---|---|
| Precio mensual | €14.99 | Confirmado por el usuario antes del Paso 13 |
| Precio anual | €89.94 (ahorro 50% exacto) | Confirmado por el usuario antes del Paso 13 |
| Comisión de tienda (Apple/Google) | 15% (tier de desarrollador pequeño, <$1M/año) | Política pública de ambas tiendas para el primer millón de USD de ingresos anuales — **verificar vigencia real al momento de publicar** |
| Tasa de conversión free→paid | 3% (hipótesis conservadora para apps de idiomas freemium) | Sin datos propios todavía — cifra de referencia de industria, no medida |
| Churn mensual de suscripción | 8% (hipótesis) | Sin datos propios — cifra de referencia de industria |
| Coste de adquisición (CAC) | €0 en el escenario base (solo canales orgánicos, ver `launch-strategy.md`) | Caso base explícito del Paso 14 |

## Costes conocidos (no estimados — reales o contractuales)

- Google Play Console: 25 USD, pago único.
- Apple Developer Program: 99 USD/año.
- **Total cuentas de plataforma: ~124 USD el primer año**, a cargo del usuario (pendiente de creación, Paso 13).
- Desarrollo de la app hasta este punto: sin coste de terceros facturado (trabajo propio/asistido).

## Escenarios a 12 meses (solo canales orgánicos, sin CAC)

Todos los escenarios asumen una base de instalaciones mensuales que crece linealmente por el efecto acumulado del contenido orgánico (TikTok/Reels/ASO) descrito en `launch-strategy.md` — **no un modelo de crecimiento validado**, una hipótesis simple para tener un orden de magnitud.

| Escenario | Instalaciones acumuladas (mes 12) | Usuarios de pago (3% conversión) | Ingreso bruto mensual (mes 12, mezcla mensual/anual estimada 70/30) | Ingreso neto tras comisión de tienda (85%) |
|---|---|---|---|---|
| Conservador | 5.000 | 150 | ~€1.900 | ~€1.615 |
| Base | 15.000 | 450 | ~€5.700 | ~€4.845 |
| Optimista | 40.000 | 1.200 | ~€15.300 | ~€13.005 |

**Estos números son ilustrativos, no un objetivo ni una promesa.** El propio caso base de `launch-strategy.md` no tiene todavía datos reales de conversión ni de crecimiento orgánico — la primera revisión seria de esta tabla debería hacerse con datos reales de las primeras 4-8 semanas después del lanzamiento (Paso 13), no antes.

## Punto de equilibrio de las cuentas de plataforma

Con el escenario conservador (~€1.615 netos/mes desde el mes 12), los ~124 USD de coste de las cuentas de tienda se recuperan mucho antes del mes 12 en cualquier escenario — este no es el riesgo financiero real del proyecto. El riesgo real es la validación de la tasa de conversión y el crecimiento orgánico, ninguno de los dos medido todavía.

## Qué falta para que esto sea una proyección financiera de verdad

- Medir conversión free→paid y churn reales tras el lanzamiento — sustituir los supuestos de la tabla de arriba.
- Decidir la forma legal de la actividad (autónomo vs. sociedad) con un asesor real — afecta directamente a impuestos y por tanto al ingreso neto real, no solo al neto de comisión de tienda que se muestra aquí.
- Revisar con un asesor fiscal el tratamiento del IVA digital (ver `business-registration-checklist.md`).

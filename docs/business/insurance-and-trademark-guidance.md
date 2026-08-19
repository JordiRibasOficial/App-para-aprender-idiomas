# Seguro de responsabilidad civil y protección de marca/dominio

> **Guía, no una acción completada.** Ni contratar un seguro ni registrar una marca o un dominio son cosas que yo pueda hacer por ti — requieren pago y una decisión de negocio tuya. Esto documenta qué mirar exactamente y por qué, con los hechos verificables que sí puedo confirmar desde el código/repositorio.

## Seguro de responsabilidad civil / ciberseguro

Tipos de póliza relevantes para este tipo de producto (nombres orientativos, varían por asegurador):

- **Responsabilidad civil profesional / Errors & Omissions (E&O)**: cubre reclamaciones por errores en el servicio — por ejemplo, si un fallo real de la app causa un perjuicio económico a un usuario (cobro duplicado, pérdida de acceso a Premium ya pagado).
- **Ciberseguro (cyber liability)**: cubre específicamente incidentes de seguridad — coste de responder a una brecha de datos (el procedimiento de `data-breach-response-plan.md` cuesta tiempo y, si hay que contratar ayuda forense o legal externa, dinero), multas regulatorias si aplican, y reclamaciones de terceros derivadas de la brecha.
- **Responsabilidad civil general**: menos relevante para software puro, pero algunas pólizas combinadas la incluyen igualmente.

Por qué podría importar en este proyecto concreto, con hechos ya verificados en rondas anteriores del checklist:

- Hay un backend real con datos de usuarios (identidad anónima + verificación de compra) — ver `records-of-processing-activities.md`. Una brecha ahí ya no es solo teórica.
- Si en algún momento se activa la función de subida de contenido (sección 7 de `terms-of-service-draft.md`), el riesgo de reclamaciones de terceros por contenido infractor aumenta, aunque el DMCA/LSSI ya mitigue parte de ese riesgo.

Qué hacer: pedir cotización a un corredor que trabaje con autónomos/pequeñas empresas tecnológicas en España, una vez esté resuelta la forma legal (`business-registration-checklist.md` sección 1) — la mayoría de aseguradoras cotizan de forma distinta a un autónomo que a una SL. `[PENDIENTE: decisión de negocio, no técnica — no hay una acción de código aquí.]`

## Protección de marca y dominio

**Estado actual verificado:**

- **Dominio**: la web vive en `jordiribasoficial.github.io/App-para-aprender-idiomas/` — un subdominio de `github.io`, **no hay ningún dominio propio registrado** (confirmé que no existe archivo `CNAME` en la rama `gh-pages`, que es lo que activaría un dominio personalizado en GitHub Pages).
- **Nombre/marca**: "App para Aprender Idiomas" y el emblema de globo — no hay evidencia en el repositorio de que se haya solicitado registro de marca en ningún organismo (OEPM, EUIPO, USPTO); no puedo confirmarlo con certeza porque esos registros no son visibles desde el código, pero no hay ningún documento en `docs/business/` que mencione una solicitud ya hecha.

**Qué hacer, en dos frentes independientes:**

1. **Dominio**: registrar un dominio propio (p. ej. `.com` o `.es`) es barato (~10-15 €/año) y sencillo de conectar a GitHub Pages con un `CNAME`. Vale la pena hacerlo pronto — nombres de dominio razonables para una marca concreta se agotan con el tiempo, y cambiar de dominio después de publicar en las tiendas (donde la URL ya queda registrada como política de privacidad/soporte) es más complicado que registrar el bueno desde el principio.
2. **Marca registrada**: más caro y con más fricción (cientos de euros, requiere clasificación de productos/servicios, gestión con un agente o directamente en el organismo). Dado que el nombre actual ("App para Aprender Idiomas") es bastante descriptivo/genérico, es posible que **ni siquiera sea registrable como marca** en su forma actual — las marcas puramente descriptivas suelen rechazarse. Esto es una razón adicional (más allá del SEO, ya mencionado en `launch-strategy.md`) para considerar un nombre distintivo si se invierte en esto. `[PENDIENTE: consultar con un agente de propiedad industrial antes de gastar en un registro que podría ser rechazado por descriptividad.]`

Prioridad sugerida si el presupuesto es limitado: el dominio primero (barato, sin fricción, protege la URL ya usada en las tiendas); la marca registrada solo si el negocio crece lo suficiente para justificar el coste y el riesgo de rechazo por descriptividad.

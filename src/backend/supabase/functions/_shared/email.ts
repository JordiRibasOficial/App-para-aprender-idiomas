// Shared by every Edge Function in this project — not deployed on its own
// (Supabase's CLI skips directories prefixed with `_`).

const RESEND_API_URL = "https://api.resend.com/emails";
// Deno's fetch has no default timeout — see google_play.ts/apple.ts for
// why this matters for an outbound call inside a request handler.
const FETCH_TIMEOUT_MS = 10_000;

export type ConfirmedPlatform = "android" | "ios";
export type ConfirmedProductId = "monthly_sub" | "annual_sub";

export interface PurchaseConfirmationEmailInput {
  to: string;
  productId: ConfirmedProductId;
  platform: ConfirmedPlatform;
}

const PRODUCT_LABELS: Record<ConfirmedProductId, string> = {
  monthly_sub: "Suscripción Premium mensual",
  annual_sub: "Suscripción Premium anual",
};

const STORE_LABELS: Record<ConfirmedPlatform, string> = {
  android: "Google Play",
  ios: "App Store",
};

/**
 * The full content TRLGDCU art. 97.1 requires (referenced by art. 98.7 —
 * see docs/business/terms-of-service-draft.md §4), split from what the
 * store's own receipt already covers. Google Play / Apple's receipt
 * already confirms the transaction itself (product, price paid, date) —
 * this email deliberately does not repeat those figures (this backend
 * never reliably knows the exact price charged: it varies by the buyer's
 * store region/currency and isn't part of the subscription-status API
 * response verify-purchase calls). Instead it covers everything the
 * store's receipt does *not*: business identity/contact, content
 * characteristics, the withdrawal-right notice and its waiver, the
 * complaints procedure, and the ODR platform — and points back to the
 * store receipt for the price/date specifics, so the two together satisfy
 * the full art. 97.1 list.
 */
function buildEmailHtml(input: PurchaseConfirmationEmailInput): string {
  const product = PRODUCT_LABELS[input.productId];
  const store = STORE_LABELS[input.platform];
  return `
<!DOCTYPE html>
<html lang="es">
<body style="font-family: sans-serif; max-width: 640px; margin: 0 auto; color: #1a1a1a;">
  <h1 style="font-size: 20px;">Confirmación de tu suscripción — App para Aprender Idiomas</h1>

  <p>Gracias por suscribirte. Este correo confirma tu contrato conforme a los
  arts. 97.1 y 98.7 del Texto Refundido de la Ley General para la Defensa de
  los Consumidores y Usuarios (TRLGDCU).</p>

  <h2 style="font-size: 16px;">1. Identidad y contacto del prestador del servicio</h2>
  <p>Webapps ("nosotros") — <em>identidad jurídica completa (autónomo/sociedad,
  NIF/CIF, domicilio) pendiente de registro formal</em>.<br>
  Email de contacto: world.webapps@gmail.com</p>

  <h2 style="font-size: 16px;">2. Características del contenido digital contratado</h2>
  <p>${product}, adquirida a través de ${store}. Da acceso a todo el
  contenido de la App (todos los idiomas y cursos disponibles) mientras la
  suscripción permanezca activa.</p>

  <h2 style="font-size: 16px;">3. Precio y fecha</h2>
  <p>El precio exacto pagado, la moneda y la fecha de la transacción constan
  en el recibo que ${store} te ha enviado por separado — ese recibo, junto
  con este correo, forma la confirmación completa que exige el art. 98.7.</p>

  <h2 style="font-size: 16px;">4. Derecho de desistimiento</h2>
  <p>Como consumidor en la Unión Europea, normalmente dispondrías de 14 días
  para desistir de este contrato sin justificar el motivo. Al confirmar la
  compra, diste tu consentimiento expreso a que el acceso al contenido
  digital comenzara de inmediato y reconociste expresamente la pérdida de
  ese derecho (art. 103.m TRLGDCU), mediante una casilla específica en la
  pantalla de suscripción.</p>

  <h2 style="font-size: 16px;">5. Reclamaciones y resolución de conflictos</h2>
  <p>Para cualquier reclamación, escribe primero a world.webapps@gmail.com
  — intentamos resolver cualquier disputa de forma amistosa antes de
  cualquier otro paso. Si prefieres una vía de resolución de litigios en
  línea, puedes acudir a la
  <a href="https://ec.europa.eu/consumers/odr/">plataforma ODR de la Comisión Europea</a>
  (Reglamento (UE) n.º 524/2013). Ninguna de las dos vías sustituye tu
  derecho a acudir directamente a los tribunales.</p>

  <p style="color: #666; font-size: 12px; margin-top: 32px;">Este correo se
  ha generado automáticamente tras tu compra y no requiere respuesta salvo
  que tengas una consulta.</p>
</body>
</html>`.trim();
}

/**
 * Sends the TRLGDCU durable-medium purchase confirmation via Resend's REST
 * API — see docs/business/terms-of-service-draft.md §4 for the legal
 * requirement, docs/business/crash-reporting-review.md-style vendor
 * comparison in src/backend/README.md for why Resend. A plain `fetch` call
 * is deliberate: Deno's own SMTP libraries add connection-management
 * complexity an Edge Function invocation doesn't need, and Resend (like
 * every modern transactional-email provider) exposes the same
 * functionality over a simple HTTP API.
 *
 * Callers must not let a failure here fail the whole verify-purchase
 * request — the entitlement grant is the priority; email delivery is
 * best-effort and errors are the caller's to log, not propagate. See
 * handler.ts's call site.
 */
export async function sendPurchaseConfirmationEmail(
  input: PurchaseConfirmationEmailInput,
): Promise<void> {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  const fromAddress = Deno.env.get("RESEND_FROM_EMAIL");
  if (!apiKey || !fromAddress) {
    throw new Error(
      "RESEND_API_KEY/RESEND_FROM_EMAIL not configured — see src/backend/README.md",
    );
  }

  const response = await fetch(RESEND_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: fromAddress,
      to: input.to,
      subject: "Confirmación de tu suscripción — App para Aprender Idiomas",
      html: buildEmailHtml(input),
    }),
    signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
  });
  if (!response.ok) {
    throw new Error(`Resend send failed: ${response.status} ${await response.text()}`);
  }
}

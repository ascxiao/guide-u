import nodemailer from "nodemailer"

type ReportKind = "incident" | "lost_found"

interface StatusEmailInput {
  to: string
  reportKind: ReportKind
  reportTitle: string
  newStatus: string
}

interface IncidentCreatedEmailInput {
  to: string
  title: string
  description: string
  location: string
  reporterStudentId: string
  reporterEmail: string
  imageCount: number
}

interface LostFoundCreatedEmailInput {
  to: string
  itemName: string
  reportType: string
  description: string
  location: string
  reporterStudentId: string
  reporterEmail: string
  imageCount: number
}

function getTransport() {
  const host = process.env.SMTP_HOST
  const port = Number.parseInt(process.env.SMTP_PORT ?? "0", 10)
  const user = process.env.SMTP_USER
  const pass = process.env.SMTP_PASS

  if (!host || !port || !user || !pass) return null

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  })
}

function prettifyStatus(status: string) {
  return status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())
}

function reportLabel(kind: ReportKind) {
  return kind === "incident" ? "Incident Report" : "Lost & Found Report"
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/'/g, "&#39;")
}

function fmt(value: string | null | undefined, fallback = "Not provided") {
  const safe = (value ?? "").trim()
  return safe.length ? escapeHtml(safe) : fallback
}

function buildShell(title: string, intro: string, content: string) {
  return `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${escapeHtml(title)}</title>
  </head>
  <body style="margin:0;padding:0;background:#f6f8f6;font-family:Segoe UI,Arial,sans-serif;color:#111827;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background:#f6f8f6;padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="max-width:760px;background:#ffffff;border:1px solid #e5e7eb;border-radius:14px;overflow:hidden;">
            <tr>
              <td style="background:#006633;height:6px;font-size:0;line-height:0;">&nbsp;</td>
            </tr>
            <tr>
              <td style="padding:28px 28px 10px 28px;">
                <p style="margin:0;color:#006633;font-size:12px;letter-spacing:0.1em;text-transform:uppercase;font-weight:700;">GuideU Notification</p>
                <h1 style="margin:10px 0 8px 0;font-size:24px;line-height:1.3;color:#111827;">${escapeHtml(title)}</h1>
                <p style="margin:0;font-size:14px;line-height:1.7;color:#374151;">${escapeHtml(intro)}</p>
              </td>
            </tr>
            <tr>
              <td style="padding:10px 28px 28px 28px;">
                ${content}
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
`
}

export async function sendStatusChangeEmail({
  to,
  reportKind,
  reportTitle,
  newStatus,
}: StatusEmailInput) {
  const transport = getTransport()
  const from = process.env.SMTP_FROM

  if (!transport || !from) {
    return { sent: false as const, reason: "SMTP is not configured" }
  }

  const label = reportLabel(reportKind)
  const readableStatus = prettifyStatus(newStatus)

  await transport.sendMail({
    from,
    to,
    subject: `${label} status updated: ${readableStatus}`,
    text: [
      `Your ${label.toLowerCase()} has been updated.`,
      `Title: ${reportTitle || "Untitled"}`,
      `New status: ${readableStatus}`,
    ].join("\n"),
    html: `
      <p>Your ${label.toLowerCase()} has been updated.</p>
      <p><strong>Title:</strong> ${reportTitle || "Untitled"}</p>
      <p><strong>New status:</strong> ${readableStatus}</p>
    `,
  })

  return { sent: true as const }
}

export async function sendIncidentCreatedEmail({
  to,
  title,
  description,
  location,
  reporterStudentId,
  reporterEmail,
  imageCount,
}: IncidentCreatedEmailInput) {
  const transport = getTransport()
  const from = process.env.SMTP_FROM

  if (!transport || !from) {
    return { sent: false as const, reason: "SMTP is not configured" }
  }

  const plainTitle = (title ?? "").trim() || "Untitled"
  const safeTitle = fmt(title, "Untitled")
  const safeDescription = fmt(description)
  const safeLocation = fmt(location)
  const safeStudentId = fmt(reporterStudentId)
  const safeReporterEmail = fmt(reporterEmail)

  const html = buildShell(
    "New Incident Report Submitted",
    "A new incident report was created and is now available for review.",
    `
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="border:1px solid #e5e7eb;border-radius:10px;overflow:hidden;">
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Title</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeTitle}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Description</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeDescription}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Location</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeLocation}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Reporter Student ID</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeStudentId}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Reporter Email</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeReporterEmail}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Attached Images</td>
          <td style="padding:12px 14px;font-size:14px;color:#111827;">${imageCount} ${imageCount === 1 ? "file" : "files"}</td>
        </tr>
      </table>
      <p style="margin:18px 0 0 0;font-size:12px;line-height:1.6;color:#6b7280;">
        This is an automated email from GuideU. Please do not reply directly to this message.
      </p>
    `,
  )

  await transport.sendMail({
    from,
    to,
    subject: `New Incident Report: ${plainTitle}`,
    text: [
      "A new incident report was submitted.",
      `Title: ${title || "Untitled"}`,
      `Description: ${description || "Not provided"}`,
      `Location: ${location || "Not provided"}`,
      `Reporter Student ID: ${reporterStudentId || "Not provided"}`,
      `Reporter Email: ${reporterEmail || "Not provided"}`,
      `Attached Images: ${imageCount}`,
    ].join("\n"),
    html,
  })

  return { sent: true as const }
}

export async function sendLostFoundCreatedEmail({
  to,
  itemName,
  reportType,
  description,
  location,
  reporterStudentId,
  reporterEmail,
  imageCount,
}: LostFoundCreatedEmailInput) {
  const transport = getTransport()
  const from = process.env.SMTP_FROM

  if (!transport || !from) {
    return { sent: false as const, reason: "SMTP is not configured" }
  }

  const plainItem = (itemName ?? "").trim() || "Unnamed"
  const safeItem = fmt(itemName, "Unnamed")
  const safeType = fmt(reportType, "Not provided")
  const safeDescription = fmt(description)
  const safeLocation = fmt(location)
  const safeStudentId = fmt(reporterStudentId)
  const safeReporterEmail = fmt(reporterEmail)

  const html = buildShell(
    "New Lost & Found Report Submitted",
    "A new lost and found report was created and is now available for review.",
    `
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="border:1px solid #e5e7eb;border-radius:10px;overflow:hidden;">
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Item</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeItem}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Report Type</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeType}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Description</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeDescription}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Location</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeLocation}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Reporter Student ID</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeStudentId}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;border-bottom:1px solid #e5e7eb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Reporter Email</td>
          <td style="padding:12px 14px;border-bottom:1px solid #e5e7eb;font-size:14px;color:#111827;">${safeReporterEmail}</td>
        </tr>
        <tr>
          <td style="padding:12px 14px;background:#f9fafb;width:180px;font-size:12px;font-weight:600;color:#4b5563;">Attached Images</td>
          <td style="padding:12px 14px;font-size:14px;color:#111827;">${imageCount} ${imageCount === 1 ? "file" : "files"}</td>
        </tr>
      </table>
      <p style="margin:18px 0 0 0;font-size:12px;line-height:1.6;color:#6b7280;">
        This is an automated email from GuideU. Please do not reply directly to this message.
      </p>
    `,
  )

  await transport.sendMail({
    from,
    to,
    subject: `New Lost & Found Report: ${plainItem}`,
    text: [
      "A new lost and found report was submitted.",
      `Item: ${itemName || "Unnamed"}`,
      `Type: ${reportType || "Not provided"}`,
      `Description: ${description || "Not provided"}`,
      `Location: ${location || "Not provided"}`,
      `Reporter Student ID: ${reporterStudentId || "Not provided"}`,
      `Reporter Email: ${reporterEmail || "Not provided"}`,
      `Attached Images: ${imageCount}`,
    ].join("\n"),
    html,
  })

  return { sent: true as const }
}
import nodemailer from "nodemailer"

type ReportKind = "incident" | "lost_found"

interface StatusEmailInput {
  to: string
  reportKind: ReportKind
  reportTitle: string
  newStatus: string
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
Report Observer Setup

Goal
- Send emails for report lifecycle events without any mobile-side email code.
- Database changes become the source of truth.

What is already implemented in web app
- Observer endpoint: /api/report-observer
  - File: web/src/app/api/report-observer/route.ts
  - Handles:
    - INSERT on incident_reports: sends incident created email
    - INSERT on lost_found_reports: sends lost and found created email
    - UPDATE on both tables when status changes: sends status update email to reporter
- Inline action email mode switch:
  - REPORT_EMAIL_MODE=observer disables duplicate inline sends from admin actions.

Environment variables
- REPORT_OBSERVER_SECRET=your-random-secret
- REPORT_EMAIL_MODE=observer
- REPORT_CREATED_NOTIFICATION_EMAIL=usls.projectdigitalization@gmail.com (optional)
- SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM

Supabase Database Webhooks (recommended)
Create 4 webhooks in Supabase Dashboard, all pointing to:
- URL: https://your-web-domain/api/report-observer
- Method: POST
- Headers:
  - x-report-observer-secret: same value as REPORT_OBSERVER_SECRET

Webhook list
1) Table: incident_reports, Event: INSERT
2) Table: incident_reports, Event: UPDATE
3) Table: lost_found_reports, Event: INSERT
4) Table: lost_found_reports, Event: UPDATE

Notes
- Keep your RLS patch applied (mobile_reports_rls_patch.sql) so inserts/selects from mobile remain allowed.
- Once REPORT_EMAIL_MODE is observer, web admin actions will no longer send direct status/create emails, preventing duplicates.
- If your web host requires public routing for API endpoints, ensure /api/report-observer is reachable from Supabase.

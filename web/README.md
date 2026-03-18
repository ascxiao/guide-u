# Next.js template

This is a Next.js template with shadcn/ui.

## Adding components

To add components to your app, run the following command:

```bash
npx shadcn@latest add button
```

This will place the ui components in the `components` directory.

## Using components

To use the components in your app, import them as follows:

```tsx
import { Button } from "@/components/ui/button";
```

## Environment setup

For report status notification emails, configure SMTP credentials in your local environment file:

```bash
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-smtp-username
SMTP_PASS=your-smtp-password
SMTP_FROM="GuideU Admin <no-reply@yourdomain.com>"
```

Email notifications are sent when incident or lost-and-found report status is changed from the admin panel.

If your database was created before this change, run the following SQL once:

```sql
alter table incident_reports add column if not exists reporter_email text;
alter table lost_found_reports add column if not exists reporter_email text;
alter table incident_reports add column if not exists reporter_student_id text;
alter table lost_found_reports add column if not exists reporter_student_id text;
```

# Legacy Firebase Functions

This folder is kept only as a legacy reference.

Current project status:

- the active push-notification path uses `supabase/functions/send-notification/`
- unread counters are updated by the Flutter app
- mention notifications are also triggered by the Flutter app through the Supabase Edge Function
- these Firebase Cloud Functions are not required for the current Spark-plan setup

Why this folder still exists:

- it documents an earlier server-side approach
- it can be useful later if the project moves to the Firebase Blaze plan

Important note:

- do not rely on `functions/index.js` as the main production backend unless the project is upgraded and those functions are intentionally redeployed

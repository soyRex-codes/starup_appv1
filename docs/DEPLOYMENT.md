# Terai web: source, build, and deployment

The local checkout and GitHub repository contain the editable source. Cloudflare Pages serves the compiled `build/web` files and currently uses direct uploads, not a Git integration.

## Current targets

- Website: https://terai.us
- GitHub: https://github.com/soyRex-codes/starup_appv1
- Cloudflare Pages project: `terai` (`terai-6nc.pages.dev`)
- Supabase: `qddhubtyvqoqlbshxfkr` (existing accounts and database retained)
- Auth sender: `Terai <no-reply@auth.terai.us>`
- Supabase Auth SMTP: `smtp.resend.com`, port `465`, username `resend`. The sending key belongs only in the dashboard, never in the app or repository.
- Signup and recovery email templates use `{{ .Token }}`; clients verify `OtpType.signup` and `OtpType.recovery` respectively.

## Local setup and checks

Use Flutter 3.41.4 (Dart 3.11.1), the SDK used to build the verified release. Keep the `foundervers` Dart package name for existing imports.

Copy `.env.example` to `.env.web` and set public client configuration. Never add provider or service-role secrets to this file. Then run:

```sh
flutter pub get
flutter test
flutter build web --release --dart-define-from-file=.env.web
```

The GitHub validation workflow runs the full Flutter test suite and compiles a web build with a placeholder public key. That CI build is a compilation check and must not be deployed as a configured production artifact.

## GitHub workflow

Use a feature branch and an explicit pull request, wait for checks, then merge when authorized. Fast-forward the local `main` after merging. Do not push directly to `main` or force-push. Dashboard email configuration is separate from Git commits.

## Website publication

Upload the contents of `build/web` (with `index.html` at the root) to a Pages preview, inspect it, and publish the approved same build to production. Preserve the previous production deployment for rollback. Publishing static files does not run SQL migrations or deploy Supabase functions.

On November 6, 2026, production deployment `e14012e8-5181-48a8-a651-174f42baab56` was verified at `terai.us`. Its `main.dart.js` SHA-256 is `1a0fbcf8f1e1721ee973324733f440ef723af83714de5a8cb3d7c4327f98c2a4`. The preview deployment is `e248e2a3-80af-476f-b720-7858daa135c0`.

Signup, confirmation email delivery, OTP verification, and login were verified interactively. Password recovery still requires an end-to-end user test. Existing sessions and feed access remained available after publication.

## Historical files

The older README sections and legacy scripts describe the former mobile/payment product. They are reference material, not current deployment instructions. Removed platform, payment, and legacy branding files remain recoverable in Git history. Do not execute old migration or deployment scripts as part of source synchronization.

# Repository workflow

- The current product is Terai, a Flutter web app hosted on Cloudflare Pages.
- Preserve existing accounts and data in Supabase project `qddhubtyvqoqlbshxfkr`.
- Work on a descriptive feature branch. Never push source changes directly to `main`.
- Review the entire diff, run applicable tests and a release web build, and scan changed files for secrets before committing.
- Write explicit commit messages and PR descriptions: problem, final behavior, scope, validation, and material limitations. Identify pre-existing changes included in a snapshot.
- Open a GitHub pull request for source changes. Merge only when authorized by the user and all applicable checks pass. Then fast-forward local `main` to the merged remote commit and verify it is clean.
- Do not reset the worktree, force-push, overwrite unrelated edits, rewrite history, or delete branches without authorization.
- Keep `.env*` files (except `.env.example`), credentials, generated builds, and Supabase CLI caches out of commits. Firebase web identifiers and Supabase anon/publishable keys are public client configuration; service-role and provider sending keys are secrets.
- Source synchronization does not authorize database migrations, Edge Function deployment, credential rotation, or changes to live data. Do not deploy these automatically.
- Report what was committed, the PR link, check results, merge status, and whether local and remote `main` match.

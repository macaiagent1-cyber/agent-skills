---
name: vercel-deployment-and-react
description: Consolidated skill replacing 7 redundant skills.
---

# Consolidated Skill: vercel-deployment-and-react



## --- Original Skill: deploy-pipeline ---

# Deploy Pipeline (Stripe / Supabase / Vercel)

Coordinate staged releases across Stripe, Supabase, and Vercel from the shell using the [Composio CLI](https://docs.composio.dev/docs/cli). One script kicks off the whole "ship it" sequence: product/price updates, DB migrations, frontend deploy, smoke checks, changelog post.

## When to Use

- Full-stack product launch that touches billing, database, and frontend together.
- Promoting a preview Vercel build to production with a Stripe price flip and a Supabase migration.
- Weekly release trains where the same sequence repeats and you want it reliable.

## Prereqs

```bash
curl -fsSL https://composio.dev/install | bash
composio login
composio link stripe
composio link supabase
composio link vercel
composio link slack        # for release announcements
```

## Discover Tools

```bash
composio search "create price" --toolkits stripe
composio search "apply migration" --toolkits supabase
composio search "create deployment" --toolkits vercel
composio tools list stripe
composio tools list supabase
composio tools list vercel
```

Common slugs (verify with `--get-schema`):

**Stripe**
- `STRIPE_CREATE_PRODUCT`
- `STRIPE_CREATE_PRICE`
- `STRIPE_UPDATE_PRODUCT`
- `STRIPE_LIST_PRICES`

**Supabase**
- `SUPABASE_LIST_PROJECTS`
- `SUPABASE_RUN_SQL_QUERY`
- `SUPABASE_LIST_MIGRATIONS`
- `SUPABASE_APPLY_MIGRATION`

**Vercel**
- `VERCEL_CREATE_A_NEW_DEPLOYMENT`
- `VERCEL_GET_A_DEPLOYMENT_BY_ID_OR_URL`
- `VERCEL_LIST_DEPLOYMENTS`
- `VERCEL_PROMOTE_DEPLOYMENT`

## The Pipeline

The order matters: **Stripe → Supabase → Vercel → Verify → Announce.** Billing changes before DB, DB before frontend.

### 1. Stripe: Create or Update the Price

```bash
composio execute STRIPE_CREATE_PRICE -d '{
  "product":"prod_abc123",
  "unit_amount":2900,
  "currency":"usd",
  "recurring":{"interval":"month"},
  "lookup_key":"team-plan-v2"
}'
```

### 2. Supabase: Apply Migrations

```bash
composio execute SUPABASE_APPLY_MIGRATION -d '{
  "project_id":"abcxyz",
  "name":"add_team_tier_column",
  "query":"alter table teams add column tier text default '\''free'\'';"
}'
```

Sanity-check the schema after:

```bash
composio execute SUPABASE_RUN_SQL_QUERY -d '{
  "project_id":"abcxyz",
  "query":"select column_name from information_schema.columns where table_name='\''teams'\'' and column_name='\''tier'\'';"
}'
```

### 3. Vercel: Deploy + Promote

```bash
# Trigger a production deployment from a git ref
composio execute VERCEL_CREATE_A_NEW_DEPLOYMENT -d '{
  "name":"web",
  "target":"production",
  "gitSource":{"type":"github","ref":"main","repoId":123456}
}'
```

Poll until ready:

```bash
composio execute VERCEL_GET_A_DEPLOYMENT_BY_ID_OR_URL -d '{"idOrUrl":"dpl_xxx"}' \
  | jq '.readyState'
```

### 4. Verify

```bash
curl -fsS https://app.acme.com/api/health
composio execute SUPABASE_RUN_SQL_QUERY -d '{
  "project_id":"abcxyz","query":"select count(*) from teams where tier is null;"
}'
```

### 5. Announce

```bash
composio execute SLACK_SEND_MESSAGE -d '{
  "channel":"releases",
  "text":"✅ Team Plan v2 shipped. Stripe price `team-plan-v2` live, Supabase migration applied, Vercel production promoted."
}'
```

## Pipeline as a Workflow File

`scripts/ship.ts`, run with `composio run --file scripts/ship.ts -- --ref main`:

```ts
const ref = process.argv[process.argv.indexOf("--ref") + 1] ?? "main";

// 1. Stripe
const price = await execute("STRIPE_CREATE_PRICE", {
  product: "prod_abc123", unit_amount: 2900, currency: "usd",
  recurring: { interval: "month" }, lookup_key: "team-plan-v2"
});

// 2. Supabase
await execute("SUPABASE_APPLY_MIGRATION", {
  project_id: "abcxyz",
  name: "add_team_tier_column",
  query: "alter table teams add column tier text default 'free';"
});

// 3. Vercel
const dep = await execute("VERCEL_CREATE_A_NEW_DEPLOYMENT", {
  name: "web", target: "production",
  gitSource: { type: "github", ref, repoId: 123456 }
});

// 4. Wait for ready
let state = "QUEUED";
while (state !== "READY" && state !== "ERROR") {
  await new Promise(r => setTimeout(r, 4000));
  const d = await execute("VERCEL_GET_A_DEPLOYMENT_BY_ID_OR_URL", { idOrUrl: dep.id });
  state = d.readyState;
}

if (state !== "READY") throw new Error("Vercel deploy failed");

// 5. Announce
await execute("SLACK_SEND_MESSAGE", {
  channel: "releases",
  text: `✅ Shipped ${ref}. Stripe price ${price.id}, Vercel ${dep.url}.`
});
```

## Rollback Plan

If verification fails, undo in **reverse order**:

1. Vercel: `VERCEL_PROMOTE_DEPLOYMENT` to the previous deployment ID.
2. Supabase: apply the down migration (always write the paired `down.sql` before shipping).
3. Stripe: `STRIPE_UPDATE_PRODUCT` to hide the new price (`active:false`); do **not** delete — Stripe objects are immutable in practice and affect historical invoices.
4. Slack: announce the rollback.

## Troubleshooting

- **Stripe price visible but checkout still shows old one** → cache on your app side; confirm `lookup_key` is what checkout fetches.
- **Supabase migration hangs** → another connection holds a lock; run `select pid, state, query from pg_stat_activity where state <> 'idle';`.
- **Vercel deploy stuck in `QUEUED`** → check build logs via `VERCEL_GET_A_DEPLOYMENT_BY_ID_OR_URL` with `?logs=1`.
- **Ordering bug** (frontend reads a column before migration applies) → always serialize the pipeline; never `--parallel` across Stripe/Supabase/Vercel.

Full CLI reference: [docs.composio.dev/docs/cli](https://docs.composio.dev/docs/cli)


## --- Original Skill: deploy-to-vercel ---

# Deploy to Vercel

Deploy any project to Vercel. **Always deploy as preview** (not production) unless the user explicitly asks for production.

The goal is to get the user into the best long-term setup: their project linked to Vercel with git-push deploys. Every method below tries to move the user closer to that state.

## Step 1: Gather Project State

Run all four checks before deciding which method to use:

```bash
# 1. Check for a git remote
git remote get-url origin 2>/dev/null

# 2. Check if locally linked to a Vercel project (either file means linked)
cat .vercel/project.json 2>/dev/null || cat .vercel/repo.json 2>/dev/null

# 3. Check if the Vercel CLI is installed and authenticated
vercel whoami 2>/dev/null

# 4. List available teams (if authenticated)
vercel teams list --format json 2>/dev/null
```

### Team selection

If the user belongs to multiple teams, present all available team slugs as a bulleted list and ask which one to deploy to. Once the user picks a team, proceed immediately to the next step — do not ask for additional confirmation.

Pass the team slug via `--scope` on all subsequent CLI commands (`vercel deploy`, `vercel link`, `vercel inspect`, etc.):

```bash
vercel deploy [path] -y --no-wait --scope <team-slug>
```

If the project is already linked (`.vercel/project.json` or `.vercel/repo.json` exists), the `orgId` in those files determines the team — no need to ask again. If there is only one team (or just a personal account), skip the prompt and use it directly.

**About the `.vercel/` directory:** A linked project has either:
- `.vercel/project.json` — created by `vercel link` (single project linking). Contains `projectId` and `orgId`.
- `.vercel/repo.json` — created by `vercel link --repo` (repo-based linking). Contains `orgId`, `remoteName`, and a `projects` array mapping directories to Vercel project IDs.

Either file means the project is linked. Check for both.

**Do NOT** use `vercel project inspect`, `vercel ls`, or `vercel link` to detect state in an unlinked directory — without a `.vercel/` config, they will interactively prompt (or with `--yes`, silently link as a side-effect). Only `vercel whoami` is safe to run anywhere.

## Step 2: Choose a Deploy Method

### Linked (`.vercel/` exists) + has git remote → Git Push

This is the ideal state. The project is linked and has git integration.

1. **Ask the user before pushing.** Never push without explicit approval:
   ```
   This project is connected to Vercel via git. I can commit and push to
   trigger a deployment. Want me to proceed?
   ```

2. **Commit and push:**
   ```bash
   git add .
   git commit -m "deploy: <description of changes>"
   git push
   ```
   Vercel automatically builds from the push. Non-production branches get preview deployments; the production branch (usually `main`) gets a production deployment.

3. **Retrieve the preview URL.** If the CLI is authenticated:
   ```bash
   sleep 5
   vercel ls --format json
   ```
   The JSON output has a `deployments` array. Find the latest entry — its `url` field is the preview URL.

   If the CLI is not authenticated, tell the user to check the Vercel dashboard or the commit status checks on their git provider for the preview URL.

---

### Linked (`.vercel/` exists) + no git remote → `vercel deploy`

The project is linked but there's no git repo. Deploy directly with the CLI.

```bash
vercel deploy [path] -y --no-wait
```

Use `--no-wait` so the CLI returns immediately with the deployment URL instead of blocking until the build finishes (builds can take a while). Then check on the deployment status with:

```bash
vercel inspect <deployment-url>
```

For production deploys (only if user explicitly asks):
```bash
vercel deploy [path] --prod -y --no-wait
```

---

### Not linked + CLI is authenticated → Link first, then deploy

The CLI is working but the project isn't linked yet. This is the opportunity to get the user into the best state.

1. **Ask the user which team to deploy to.** Present the team slugs from Step 1 as a bulleted list. If there's only one team (or just a personal account), skip this step.

2. **Once a team is selected, proceed directly to linking.** Tell the user what will happen but do not ask for separate confirmation:
   ```
   Linking this project to <team name> on Vercel. This will create a Vercel
   project to deploy to and enable automatic deployments on future git pushes.
   ```

3. **If a git remote exists**, use repo-based linking with the selected team scope:
   ```bash
   vercel link --repo --scope <team-slug>
   ```
   This reads the git remote URL and matches it to existing Vercel projects that deploy from that repo. It creates `.vercel/repo.json`. This is much more reliable than `vercel link` (without `--repo`), which tries to match by directory name and often fails when the local folder and Vercel project are named differently.

   **If there is no git remote**, fall back to standard linking:
   ```bash
   vercel link --scope <team-slug>
   ```
   This prompts the user to select or create a project. It creates `.vercel/project.json`.

4. **Then deploy using the best available method:**
   - If a git remote exists → commit and push (see git push method above)
   - If no git remote → `vercel deploy [path] -y --no-wait --scope <team-slug>`, then `vercel inspect <url>` to check status

---

### Not linked + CLI not authenticated → Install, auth, link, deploy

The Vercel CLI isn't set up at all.

1. **Install the CLI (if not already installed):**
   ```bash
   npm install -g vercel
   ```

2. **Authenticate:**
   ```bash
   vercel login
   ```
   The user completes auth in their browser. If running in a non-interactive environment where login is not possible, skip to the **no-auth fallback** below.

3. **Ask which team to deploy to** — present team slugs from `vercel teams list --format json` as a bulleted list. If only one team / personal account, skip. Once selected, proceed immediately.

4. **Link the project** with the selected team scope (use `--repo` if a git remote exists, plain `vercel link` otherwise):
   ```bash
   vercel link --repo --scope <team-slug>   # if git remote exists
   vercel link --scope <team-slug>          # if no git remote
   ```

5. **Deploy** using the best available method (git push if remote exists, otherwise `vercel deploy -y --no-wait --scope <team-slug>`, then `vercel inspect <url>` to check status).

---

### No-Auth Fallback — claude.ai sandbox

**When to use:** Last resort when the CLI can't be installed or authenticated in the claude.ai sandbox. This requires no authentication — it returns a **Preview URL** (live site) and a **Claim URL** (transfer to your Vercel account).

```bash
bash /mnt/skills/user/deploy-to-vercel/resources/deploy.sh [path]
```

**Arguments:**
- `path` - Directory to deploy, or a `.tgz` file (defaults to current directory)

**Examples:**
```bash
# Deploy current directory
bash /mnt/skills/user/deploy-to-vercel/resources/deploy.sh

# Deploy specific project
bash /mnt/skills/user/deploy-to-vercel/resources/deploy.sh /path/to/project

# Deploy existing tarball
bash /mnt/skills/user/deploy-to-vercel/resources/deploy.sh /path/to/project.tgz
```

The script auto-detects the framework from `package.json`, packages the project (excluding `node_modules`, `.git`, `.env`), uploads it, and waits for the build to complete.

**Tell the user:** "Your deployment is ready at [previewUrl]. Claim it at [claimUrl] to manage your deployment."

---

### No-Auth Fallback — Codex sandbox

**When to use:** In the Codex sandbox where the CLI may not be authenticated. Codex runs in a sandboxed environment by default — try the CLI first, and fall back to the deploy script if auth fails.

1. **Check whether the Vercel CLI is installed** (no escalation needed for this check):
   ```bash
   command -v vercel
   ```

2. **If `vercel` is installed**, try deploying with the CLI:
   ```bash
   vercel deploy [path] -y --no-wait
   ```

3. **If `vercel` is not installed, or the CLI fails with "No existing credentials found"**, use the fallback script:
   ```bash
   skill_dir="<path-to-skill>"

   # Deploy current directory
   bash "$skill_dir/resources/deploy-codex.sh"

   # Deploy specific project
   bash "$skill_dir/resources/deploy-codex.sh" /path/to/project

   # Deploy existing tarball
   bash "$skill_dir/resources/deploy-codex.sh" /path/to/project.tgz
   ```

The script handles framework detection, packaging, and deployment. It waits for the build to complete and returns JSON with `previewUrl` and `claimUrl`.

**Tell the user:** "Your deployment is ready at [previewUrl]. Claim it at [claimUrl] to manage your deployment."

**Escalated network access:** Only escalate the actual deploy command if sandboxing blocks the network call (`sandbox_permissions=require_escalated`). Do **not** escalate the `command -v vercel` check.

---

## Agent-Specific Notes

### Claude Code / terminal-based agents

You have full shell access. Do NOT use the `/mnt/skills/` path. Follow the decision flow above using the CLI directly.

For the no-auth fallback, run the deploy script from the skill's installed location:
```bash
bash ~/.claude/skills/deploy-to-vercel/resources/deploy.sh [path]
```
The path may vary depending on where the user installed the skill.

### Sandboxed environments (claude.ai)

You likely cannot run `vercel login` or `git push`. Go directly to the **no-auth fallback — claude.ai sandbox**.

### Codex

Codex runs in a sandbox. Check if the CLI is available first, then fall back to the deploy script. Go to the **no-auth fallback — Codex sandbox**.

---

## Output

Always show the user the deployment URL.

- **Git push:** Use `vercel ls --format json` to find the preview URL. If the CLI isn't authenticated, tell the user to check the Vercel dashboard or commit status checks.
- **CLI deploy:** Show the URL returned by `vercel deploy --no-wait`. Use `vercel inspect <url>` to check build status and report it to the user.
- **No-auth fallback:** Show both the preview URL and the claim URL:
  ```
  Deployment successful!

  Preview URL: https://my-app-abc123.vercel.app
  Claim URL:   https://vercel.com/claim-deployment?code=...

  View your site at the Preview URL.
  To transfer this deployment to your Vercel account, visit the Claim URL.
  ```

**Do not** curl or fetch the deployed URL to verify it works. Just return the link.

---

## Troubleshooting

### Network Egress Error (claude.ai)

If deployment fails due to network restrictions on claude.ai, tell the user:

```
Deployment failed due to network restrictions. To fix this:

1. Go to https://claude.ai/settings/capabilities
2. Add *.vercel.com to the allowed domains
3. Try deploying again
```

### Escalated Network Access (Codex / sandboxed environments)

If deployment fails due to network issues (timeouts, DNS errors, connection resets) in a sandboxed environment, rerun with escalated permissions (`sandbox_permissions=require_escalated`). Do not escalate the initial CLI availability check — only escalate the actual deploy command.

Example guidance to the user:
```
The deploy needs escalated network access to deploy to Vercel. I can rerun
the command with escalated permissions — want me to proceed?
```

### CLI Auth Failure

If `vercel login` or `vercel deploy` fails with authentication errors, fall back to the no-auth deploy script (claude.ai or Codex variant, depending on the environment).


## --- Original Skill: vercel-cli-with-tokens ---

# Vercel CLI with Tokens

Deploy and manage projects on Vercel using the CLI with token-based authentication, without relying on `vercel login`.

## Step 1: Locate the Vercel Token

Before running any Vercel CLI commands, identify where the token is coming from. Work through these scenarios in order:

### A) `VERCEL_TOKEN` is already set in the environment

```bash
printenv VERCEL_TOKEN
```

If this returns a value, you're ready. Skip to Step 2.

### B) Token is in a `.env` file under `VERCEL_TOKEN`

```bash
grep '^VERCEL_TOKEN=' .env 2>/dev/null
```

If found, export it:

```bash
export VERCEL_TOKEN=$(grep '^VERCEL_TOKEN=' .env | cut -d= -f2-)
```

### C) Token is in a `.env` file under a different name

Look for any variable that looks like a Vercel token (Vercel tokens typically start with `vca_`):

```bash
grep -i 'vercel' .env 2>/dev/null
```

Inspect the output to identify which variable holds the token, then export it as `VERCEL_TOKEN`:

```bash
export VERCEL_TOKEN=$(grep '^<VARIABLE_NAME>=' .env | cut -d= -f2-)
```

### D) No token found — ask the user

If none of the above yield a token, ask the user to provide one. They can create a Vercel access token at vercel.com/account/tokens.

---

**Important:** Once `VERCEL_TOKEN` is exported as an environment variable, the Vercel CLI reads it natively — **do not pass it as a `--token` flag**. Putting secrets in command-line arguments exposes them in shell history and process listings.

```bash
# Bad — token visible in shell history and process listings
vercel deploy --token "vca_abc123"

# Good — CLI reads VERCEL_TOKEN from the environment
export VERCEL_TOKEN="vca_abc123"
vercel deploy
```

## Step 2: Locate the Project and Team

Similarly, check for the project ID and team scope. These let the CLI target the right project without needing `vercel link`.

```bash
# Check environment
printenv VERCEL_PROJECT_ID
printenv VERCEL_ORG_ID

# Or check .env
grep -i 'vercel' .env 2>/dev/null
```

**If you have a project URL** (e.g. `https://vercel.com/my-team/my-project`), extract the team slug:

```bash
# e.g. "my-team" from "https://vercel.com/my-team/my-project"
echo "$PROJECT_URL" | sed 's|https://vercel.com/||' | cut -d/ -f1
```

**If you have both `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` in your environment**, export them — the CLI will use these automatically and skip any `.vercel/` directory:

```bash
export VERCEL_ORG_ID="<org-id>"
export VERCEL_PROJECT_ID="<project-id>"
```

Note: `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` must be set together — setting only one causes an error.

## CLI Setup

Ensure the Vercel CLI is installed and up to date:

```bash
npm install -g vercel
vercel --version
```

## Deploying a Project

Always deploy as **preview** unless the user explicitly requests production. Choose a method based on what you have available.

### Quick Deploy (have project ID — no linking needed)

When `VERCEL_TOKEN` and `VERCEL_PROJECT_ID` are set in the environment, deploy directly:

```bash
vercel deploy -y --no-wait
```

With a team scope (either via `VERCEL_ORG_ID` or `--scope`):

```bash
vercel deploy --scope <team-slug> -y --no-wait
```

Production (only when explicitly requested):

```bash
vercel deploy --prod --scope <team-slug> -y --no-wait
```

Check status:

```bash
vercel inspect <deployment-url>
```

### Full Deploy Flow (no project ID — need to link)

Use this when you have a token and team but no pre-existing project ID.

#### Check project state first

```bash
# Does the project have a git remote?
git remote get-url origin 2>/dev/null

# Is it already linked to a Vercel project?
cat .vercel/project.json 2>/dev/null || cat .vercel/repo.json 2>/dev/null
```

#### Link the project

**With git remote (preferred):**

```bash
vercel link --repo --scope <team-slug> -y
```

Reads the git remote and connects to the matching Vercel project. Creates `.vercel/repo.json`. More reliable than plain `vercel link`, which matches by directory name.

**Without git remote:**

```bash
vercel link --scope <team-slug> -y
```

Creates `.vercel/project.json`.

**Link to a specific project by name:**

```bash
vercel link --project <project-name> --scope <team-slug> -y
```

If the project is already linked, check `orgId` in `.vercel/project.json` or `.vercel/repo.json` to verify it matches the intended team.

#### Deploy after linking

**A) Git Push Deploy — has git remote (preferred)**

Git pushes trigger automatic Vercel deployments.

1. **Ask the user before pushing.** Never push without explicit approval.
2. Commit and push:
   ```bash
   git add .
   git commit -m "deploy: <description of changes>"
   git push
   ```
3. Vercel builds automatically. Non-production branches get preview deployments.
4. Retrieve the deployment URL:
   ```bash
   sleep 5
   vercel ls --format json --scope <team-slug>
   ```
   Find the latest entry in the `deployments` array.

**B) CLI Deploy — no git remote**

```bash
vercel deploy --scope <team-slug> -y --no-wait
```

Check status:

```bash
vercel inspect <deployment-url>
```

### Deploying from a Remote Repository (code not cloned locally)

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd <repo-name>
   ```
2. Link to Vercel:
   ```bash
   vercel link --repo --scope <team-slug> -y
   ```
3. Deploy via git push (if you have push access) or CLI deploy.

### About `.vercel/` Directory

A linked project has either:
- `.vercel/project.json` — from `vercel link`. Contains `projectId` and `orgId`.
- `.vercel/repo.json` — from `vercel link --repo`. Contains `orgId`, `remoteName`, and a `projects` map.

Not needed when `VERCEL_ORG_ID` + `VERCEL_PROJECT_ID` are both set in the environment.

**Do NOT** run `vercel project inspect` or `vercel link` in an unlinked directory to detect state — they will interactively prompt or silently link as a side-effect. `vercel ls` is safe (in an unlinked directory it defaults to showing all deployments for the scope). `vercel whoami` is safe anywhere.

## Managing Environment Variables

```bash
# Set for all environments
echo "value" | vercel env add VAR_NAME --scope <team-slug>

# Set for a specific environment (production, preview, development)
echo "value" | vercel env add VAR_NAME production --scope <team-slug>

# List environment variables
vercel env ls --scope <team-slug>

# Pull env vars to local .env.local file
vercel env pull --scope <team-slug>

# Remove a variable
vercel env rm VAR_NAME --scope <team-slug> -y
```

## Inspecting Deployments

```bash
# List recent deployments
vercel ls --format json --scope <team-slug>

# Inspect a specific deployment
vercel inspect <deployment-url>

# View build logs (requires Vercel CLI v35+)
vercel inspect <deployment-url> --logs

# View runtime request logs (follows live by default; add --no-follow for a one-shot snapshot)
vercel logs <deployment-url>
```

## Managing Domains

```bash
# List domains
vercel domains ls --scope <team-slug>

# Add a domain to the project — linked or env-linked directory (1 arg)
vercel domains add <domain> --scope <team-slug>

# Add a domain — unlinked directory (requires <project> positional)
vercel domains add <domain> <project> --scope <team-slug>
```

## Stripe Projects Plan Changes

If this project is managed by Stripe Projects. **Ask the user before running any paid or destructive plan change** — upgrades bill a real card, downgrades remove seats.

First run `stripe projects status --json` to confirm the Vercel resource's local name. The examples below assume the default (`vercel-plan`); substitute the actual name if it was renamed at `stripe projects add` time.

- **Upgrade to Pro:** `stripe projects add vercel/pro` (or `stripe projects upgrade vercel-plan pro`)
- **Downgrade to Hobby:** `stripe projects downgrade vercel-plan hobby`

### What Pro gives you

- $20/month platform fee, includes $20/month of usage credit.
- Turbo build machines (30 vCPUs, 60 GB memory) by default for new projects — significantly faster builds than Hobby.
- 1 deploying seat + unlimited free Viewer seats (read-only collaborators, preview comments).
- Higher included allocations (1 TB Fast Data Transfer, 10M Edge Requests per month).
- Paid add-ons available: SAML SSO, HIPAA BAA, Flags Explorer, Observability Plus, Speed Insights, Web Analytics Plus.

Full details: https://vercel.com/docs/plans/pro-plan

## Working Agreement

- **Never pass `VERCEL_TOKEN` as a `--token` flag.** Export it as an environment variable and let the CLI read it natively.
- **Check the environment for tokens before asking the user.** Look in the current env and `.env` files first.
- **Default to preview deployments.** Only deploy to production when explicitly asked.
- **Ask before pushing to git.** Never push commits without the user's approval.
- **Do not modify `.vercel/` files directly.** The CLI manages this directory. Reading them (e.g. to verify `orgId`) is fine.
- **Do not curl/fetch deployed URLs to verify.** Just return the link to the user.
- **Use `--format json`** when structured output will help with follow-up steps.
- **Use `-y`** on commands that prompt for confirmation to avoid interactive blocking.

## Troubleshooting

### Token not found

Check the environment and any `.env` files present:

```bash
printenv | grep -i vercel
grep -i vercel .env 2>/dev/null
```

### Authentication error

If the CLI fails with `Authentication required`:
- The token may be expired or invalid.
- Verify: `vercel whoami` (uses `VERCEL_TOKEN` from environment).
- Ask the user for a fresh token.

### Wrong team

Verify the scope is correct:

```bash
vercel whoami --scope <team-slug>
```

### Build failure

Check the build logs:

```bash
vercel inspect <deployment-url> --logs
```

Common causes:
- Missing dependencies — ensure `package.json` is complete and committed.
- Missing environment variables — add with `vercel env add`.
- Framework misconfiguration — check `vercel.json`. Vercel auto-detects frameworks (Next.js, Remix, Vite, etc.) from `package.json`; override with `vercel.json` if detection is wrong.

### CLI not installed

```bash
npm install -g vercel
```


## --- Original Skill: vercel-composition-patterns ---

# React Composition Patterns

Composition patterns for building flexible, maintainable React components. Avoid
boolean prop proliferation by using compound components, lifting state, and
composing internals. These patterns make codebases easier for both humans and AI
agents to work with as they scale.

## When to Apply

Reference these guidelines when:

- Refactoring components with many boolean props
- Building reusable component libraries
- Designing flexible component APIs
- Reviewing component architecture
- Working with compound components or context providers

## Rule Categories by Priority

| Priority | Category                | Impact | Prefix          |
| -------- | ----------------------- | ------ | --------------- |
| 1        | Component Architecture  | HIGH   | `architecture-` |
| 2        | State Management        | MEDIUM | `state-`        |
| 3        | Implementation Patterns | MEDIUM | `patterns-`     |
| 4        | React 19 APIs           | MEDIUM | `react19-`      |

## Quick Reference

### 1. Component Architecture (HIGH)

- `architecture-avoid-boolean-props` - Don't add boolean props to customize
  behavior; use composition
- `architecture-compound-components` - Structure complex components with shared
  context

### 2. State Management (MEDIUM)

- `state-decouple-implementation` - Provider is the only place that knows how
  state is managed
- `state-context-interface` - Define generic interface with state, actions, meta
  for dependency injection
- `state-lift-state` - Move state into provider components for sibling access

### 3. Implementation Patterns (MEDIUM)

- `patterns-explicit-variants` - Create explicit variant components instead of
  boolean modes
- `patterns-children-over-render-props` - Use children for composition instead
  of renderX props

### 4. React 19 APIs (MEDIUM)

> **⚠️ React 19+ only.** Skip this section if using React 18 or earlier.

- `react19-no-forwardref` - Don't use `forwardRef`; use `use()` instead of `useContext()`

## How to Use

Read individual rule files for detailed explanations and code examples:

```
rules/architecture-avoid-boolean-props.md
rules/state-context-interface.md
```

Each rule file contains:

- Brief explanation of why it matters
- Incorrect code example with explanation
- Correct code example with explanation
- Additional context and references

## Full Compiled Document

For the complete guide with all rules expanded: `AGENTS.md`


## --- Original Skill: vercel-optimize ---

# Vercel Optimize

Run an observability-first Vercel optimization audit. Do not inspect source files until `signals.json` exists and a deterministic gate points to a route, file, or project setting.

Core doctrine: read [references/doctrine.md](references/doctrine.md) if any rule is unclear.

- Metrics first. Recommendations start from Vercel production signals, not repo-wide grep.
- Deterministic gates. `scripts/gate-investigations.mjs` decides what deserves investigation.
- Candidate-bound scope. Read only files named by a candidate or a route-local import chain.
- Version-aware citations. Use only `references/docs-library.json`; invalid or version-mismatched citations are stripped.
- Customer copy. Read [references/voice.md](references/voice.md) before writing report text or chat output.

## Prerequisites

- Vercel CLI v53+ with `vercel metrics`, `vercel usage`, `vercel contract`, and `vercel api`.
- Authenticated CLI session: `vercel login`.
- Linked app directory: `vercel link`. `VERCEL_PROJECT_ID` can help resolve project config, but `vercel metrics` still requires directory linkage. The link or environment must include the intended project org/team/user scope so the collector can resolve a CLI-safe `--scope` and keep `vercel metrics`, `vercel usage`, and `vercel contract` on the same account.
- Node.js 20+.
- Observability Plus for route-level metric-backed recommendations.

Never put auth tokens in shell commands. Do not type `VERCEL_TOKEN=...`, `--token ...`, or `Authorization: Bearer ...` into commands that may be echoed in chat.

## Framework Support

The preflight reads `package.json` and sets expectations before metric fan-out.

| Framework | Status | Notes |
|---|---|---|
| Next.js App Router | supported | strongest route mapping, scanners, playbooks, citations |
| Next.js Pages Router | supported | scoped to Pages Router idioms when detected |
| SvelteKit | supported | route mapping for `src/routes` files and SvelteKit scanner |
| Nuxt | supported | route mapping plus generic/platform checks; fewer framework-specific recs |
| Astro | limited | route mapping plus generic checks; fewer framework-specific recs |
| Hono / Remix / unknown | blocked by default | continue only if the user accepts a limited platform/code-only audit |

If unsupported, stop and ask before scanning or gating:

```text
This project uses <framework>. Vercel Optimize supports metric-backed code recommendations for Next.js, SvelteKit, and Nuxt. Astro support is limited. For <framework>, I can still run a limited platform/scanner audit, but route-level Vercel metrics may not map back to source files.

Do you want me to continue with the limited audit, or stop here?
```

If the user continues, rerun collection with `--continue-unsupported-framework`.

## Run Directory

Use a fresh run directory for every audit. Do not reuse briefs, sub-agent outputs, or reports across runs.

```bash
RUN_DIR="$(mktemp -d -t vercel-optimize-XXXXXX)"
```

## Pipeline

### 1. Collect, scan, and merge signals

Run from the linked app directory or pass `--cwd` where a script supports it. Keep stdout JSON separate from stderr logs. Do not combine streams.

```bash
node scripts/collect-signals.mjs [projectId] > "$RUN_DIR/vercel-signals.json" 2> "$RUN_DIR/collect.stderr"
node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$RUN_DIR/vercel-signals.json"

node scripts/scan-codebase.mjs <repo-root> > "$RUN_DIR/codebase.json"
node scripts/merge-signals.mjs "$RUN_DIR/vercel-signals.json" "$RUN_DIR/codebase.json" --out "$RUN_DIR/signals.json"
```

Collection details, schemas, metric IDs, and degradation behavior live in [references/data-collection.md](references/data-collection.md). The metric registry is [lib/queries.mjs](lib/queries.mjs); keep all queries on the shared 14-day window.

`collect-signals.mjs` resolves the linked project owner to `commandScope.cliScope` and verifies that the resolved account can read the resolved project before it checks Observability Plus. Downstream scripts reuse that scope for every Vercel CLI command that accepts `--scope`. Do not run `vercel usage`, `vercel metrics`, or `vercel contract` manually without the same scope; unscoped usage can report the user's personal organization while route metrics come from the team project.

If project or scope resolution is ambiguous, stop and ask the user which Vercel project and team/personal scope they want audited. Do not infer the intended scope from the current `vercel whoami` team, and do not proceed with metrics, usage, or contract collection until the link, an exact project match in `.vercel/repo.json`, or `VERCEL_PROJECT_ID` + `VERCEL_ORG_ID` identifies the intended account.

Use this prompt for `PROJECT_SCOPE_UNRESOLVED`, `SCOPE_UNRESOLVED`, or `PROJECT_SCOPE_MISMATCH`:

```text
I can't safely identify the Vercel project and account for this audit yet.

Please confirm the Vercel project name or ID and the team slug/name, or tell me it's under your personal account. Once confirmed, I'll relink or rerun collection against that exact scope before checking metrics.
```

### 1.1 Stop on blockers

Check blockers before gating:

```bash
jq '{frameworkSupportBlocker, observabilityPlus, observabilityPlusUsable, observabilityPlusBlocker, observabilityPlusBlockerDetail}' "$RUN_DIR/signals.json"
```

Required actions:

- `frameworkSupportBlocker === "unsupported_framework"`: use the unsupported-framework prompt above.
- `PROJECT_SCOPE_UNRESOLVED`, `SCOPE_UNRESOLVED`, or `PROJECT_SCOPE_MISMATCH`: stop and ask which Vercel project and team/personal scope the user wants audited. For team projects, rerun after `vercel link --yes --project <project-name-or-id> --team <team-slug>`; for personal projects, rerun after linking under the intended user account or after setting both `VERCEL_PROJECT_ID` and `VERCEL_ORG_ID`.
- `observabilityPlusBlocker === null`: continue.
- `no_traffic`: tell the user route metrics are sparse; continue only if they accept limited output.
- `payment_required` or `no_oplus_probe`: render [references/observability-plus.md](references/observability-plus.md) verbatim and ask.
- `project_disabled`: tell the user to enable Observability Plus for the project or accept a limited audit.
- `daily_quota_exceeded`: stop and tell the user the Observability query quota is exhausted; retry after the next UTC midnight reset, or ask whether to continue with a limited code-only audit.
- `not_linked`: link the app directory, then rerun Step 1. If app path and project are known:

```bash
vercel link --yes --project <project-name-or-id> --cwd <app-dir>
# add --team <team-id-or-slug> when known
```

- `forbidden` or `project_not_found`: fix auth/team scope. Do not pitch Observability Plus.
- `all_failed_other`: show the raw error code and ask whether to continue in limited code-only mode.

Do not silently fall back to code-only mode. If the user accepts a limited audit, rerun collection with:

```bash
node scripts/collect-signals.mjs [projectId] --continue-without-observability > "$RUN_DIR/vercel-signals.json" 2> "$RUN_DIR/collect.stderr"
```

Then scan and merge again.

### 2. Gate candidates

```bash
node scripts/gate-investigations.mjs "$RUN_DIR/signals.json" > "$RUN_DIR/gate.json"
```

Output shape:

- `toLaunch`: code-scope candidates to investigate.
- `platform`: project/account-scope recommendations.
- `gated`: skipped, covered, or disqualified candidates that must still appear in the report.
- `budget`: candidate budget and selection mode.

Default budget is 6 code-scope candidates with a diversity guardrail. To expand:

```bash
node scripts/gate-investigations.mjs "$RUN_DIR/signals.json" --max-candidates 12 > "$RUN_DIR/gate.json"
node scripts/gate-investigations.mjs "$RUN_DIR/signals.json" --max-candidates all > "$RUN_DIR/gate.json"
```

Generated candidate docs: [references/candidates.md](references/candidates.md).

### 2.1 Ask about audit scope when needed

Before deep-dive, run:

```bash
node scripts/budget-summary.mjs "$RUN_DIR/gate.json" --format json > "$RUN_DIR/budget-summary.json"
```

If `shouldAsk` is false, continue.

If `shouldAsk` is true:

1. Print `exactChatMessage.body` exactly as returned. Do not summarize, truncate, reorder, or rewrite it.
2. Then ask `questionText` using `questionPayload` when the host supports structured questions.
3. If the user chooses a different number, rerun the gate with `--max-candidates <choice>`.

Never put the long preview inside the question field. The preview and the question are separate surfaces.

### 2.2 Deep-dive and reconcile

```bash
node scripts/deep-dive.mjs "$RUN_DIR/signals.json" "$RUN_DIR/gate.json" --cwd <project-dir> > "$RUN_DIR/investigation-evidence.json"

node scripts/reconcile-candidates.mjs "$RUN_DIR/investigation-evidence.json" \
  --gate "$RUN_DIR/gate.json" \
  --out "$RUN_DIR/reconciled-investigation.json"
```

`--cwd` must be the linked project directory so `deep-dive.mjs` can verify the same project link and reuse `signals.json.commandScope.cliScope` for any follow-up `vercel metrics` calls.

Reconciliation deterministically converts disproven candidates into observations before any source investigation:

- `metric_mismatch`
- `error_storm`
- `deployment_regression`
- `scanner_only_no_metric`

### 2.3 Generate briefs and investigate

List the work:

```bash
node scripts/prepare-investigation-brief.mjs "$RUN_DIR/signals.json" "$RUN_DIR/reconciled-investigation.json" --list > "$RUN_DIR/briefs-manifest.json"
```

Generate one brief for every entry in `briefs-manifest.json.briefs`. The `group` can be `toLaunch` or `platform`; do not generate only `toLaunch` briefs.

```bash
mkdir -p "$RUN_DIR/briefs" "$RUN_DIR/sub-agent-outputs"
node scripts/prepare-investigation-brief.mjs "$RUN_DIR/signals.json" "$RUN_DIR/reconciled-investigation.json" \
  --group <brief.group> --index <brief.index> --out "$RUN_DIR/briefs/<brief.group>-<brief.index>.md"
```

Use `briefs-manifest.json.briefs[].label` for visible worker names, for example `Low cache-hit route on /docs/llm-digest/[...slug]`, not `toLaunch-7`.

Fan-out rule:

- 1-2 briefs: investigate inline.
- 3+ briefs: spawn one sub-agent per brief when the host supports it.
- Hosts without sub-agents: run inline serially.

Sub-agent contract:

- The brief is the whole prompt.
- Read only files listed in the brief, plus route-local imports when needed.
- Emit one JSON recommendation or one JSON no-change finding using [references/recommendations.md](references/recommendations.md).
- Do not cite URLs outside the provided citation subset.
- Do not recommend framework features unavailable in the detected version.

If a sub-agent reaches for repo-wide grep, the candidate is malformed; drop or abstain rather than widening scope.

### 2.4 Collect outputs

Save each raw investigation result in `$RUN_DIR/sub-agent-outputs/`, then collect:

```bash
node scripts/collect-sub-agent-outputs.mjs \
  --manifest "$RUN_DIR/briefs-manifest.json" \
  --out "$RUN_DIR/recommendations.json" \
  "$RUN_DIR/sub-agent-outputs/"
```

The collector extracts JSON, prepends pre-resolved records, enforces manifest order, and fails on missing, duplicate, unknown, or mismatched `candidateRef` values.

### 3. Verify recommendations

```bash
node scripts/verify-and-regen.mjs "$RUN_DIR/recommendations.json" \
  --signals "$RUN_DIR/signals.json" \
  --repo-root <project-dir> \
  --out "$RUN_DIR/verify.json"
```

This script extracts claims, verifies files/citations/version fit, grades quality, applies sanitizers, emits `verifiedRecommendations`, `withheldRecommendations`, `renderableRecommendations`, and creates `regenPlan` for failed or unsafe recommendations.

Recommendation schema, writing rules, sanitizer order, and grading rules: [references/recommendations.md](references/recommendations.md). Verification rules: [references/verification.md](references/verification.md).

For each `regenPlan` entry, rerun the same brief with a `Previous attempt failed these checks` section listing `topFailures`. Keep the regenerated output only if verification improves without gutting citations.

### 4. Render report and final message

```bash
node scripts/render-report.mjs "$RUN_DIR/verify.json" "$RUN_DIR/gate.json" "$RUN_DIR/signals.json" \
  --project <name> \
  --out "$RUN_DIR/report.md" \
  --message-out "$RUN_DIR/final-message.json"
```

Use `--debug-out "$RUN_DIR/debug.json"` only when developing the skill. Customer Markdown and chat output must not expose `passRate`, `quality`, sanitizer trails, raw sub-agent names, or other implementation fields.

After rendering, print `final-message.json.body` verbatim and stop. Do not add highlights, debug notes, raw counts, sub-agent summaries, or extra explanation. Render-time dedupe, platform caps, and hard-safety drops can change the customer-visible count, so never summarize from raw `verify.json`.

Report structure and impact framing: [references/scoring.md](references/scoring.md).

## Recommendation Rules

Every recommendation must:

- Trace to a launched candidate, platform candidate, pre-resolved observation, or verified traffic-independent scanner finding.
- Include observed metric evidence from `signals.json` or `evidence.deepDive`.
- Cite verified files with line numbers when code is involved.
- Include at least one allowed citation that applies to the detected framework/version.
- Use precise observed performance numbers.
- Use cost magnitude phrases only; never customer-facing `$N` savings.
- Do not recommend duration reductions for Vercel Workflow runtime endpoints (`/.well-known/workflow/v1/*`). These are generated orchestration routes for durable step/flow execution and should be hard-gated before investigation.
- Workflow recommendations must name the boundary being changed. Valid examples: enqueue durable work and return a run ID instead of awaiting completion, fix stream replay/closure/locks, or reduce verified excess Workflow Steps/Storage. Do not infer cost savings from Workflow endpoint wall-clock duration.
- For streaming, SSE, resumable chat, or other intentionally long-lived routes, do not frame wall-clock function duration as a problem by itself. Require evidence of avoidable pre-first-byte work, high active CPU, duplicate invocations, or post-response work that can move out of the user-visible path.
- Name a specific cache policy when recommending caching.
- Keep unsafe responses dynamic unless evidence proves they are safe to cache: auth-sensitive paths, errors, fallback responses, missing content, invalid requests, geolocation/device-varying output, and unversioned dynamic URLs.

Never recommend "verify X is on" for facts already present in `signals.project`, including Fluid compute status, memory tier, regions, in-function concurrency, and timeout.

## Scanner Rules

Scanner findings are supplementary. Drop findings annotated `COLD-PATH` or `NO-ROUTE-MAPPING` unless the scanner declares `metadata.trafficIndependent === true`.

Traffic-independent examples: middleware matcher, source maps, React Compiler config, build settings. Route-local cache or data-fetch patterns need route-level traffic evidence.

Scanner docs: [references/scanner-patterns.md](references/scanner-patterns.md).

## Final Customer Terms

Use:

- `recommendations ready`
- `observations from investigation`
- `investigated, no change recommended`
- `not investigated in this run`

Avoid:

- `sub-agent`
- `abstention`
- `passRate`
- `quality score`
- `gate`
- `LLM`

## Failure Copy

Use these messages without adding sales copy or process detail.

**No traffic in the last 14 days:**

> This project has no meaningful traffic in the last 14 days, so route-level metrics are sparse. I can still check traffic-independent scanner findings and project settings, but I cannot rank route fixes until traffic accumulates.

**Route-level metrics unavailable:**

> Use the verbatim choice template in [references/observability-plus.md](references/observability-plus.md). Do not silently fall back to code-only mode; present the two-path choice: enable Observability Plus and rerun the metric-backed audit, or accept a limited code-only run.

**Project is not linked:**

> This worktree is not linked to a Vercel project. Run `vercel link --yes --project <project-name-or-id> --cwd <app-dir>` and rerun the audit. If the team is known, add `--team <team-id-or-slug>`.

**Most route-to-file mappings failed:**

> The route inventory matched fewer than half of the routes we saw in observability. This is common in monorepos with custom routing. I've surfaced what I can match; the rest appear in the "Not investigated in this run" section.


## --- Original Skill: vercel-react-best-practices ---

# Vercel React Best Practices

Comprehensive performance optimization guide for React and Next.js applications, maintained by Vercel. Contains 70 rules across 8 categories, prioritized by impact to guide automated refactoring and code generation.

## When to Apply

Reference these guidelines when:
- Writing new React components or Next.js pages
- Implementing data fetching (client or server-side)
- Reviewing code for performance issues
- Refactoring existing React/Next.js code
- Optimizing bundle size or load times

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Eliminating Waterfalls | CRITICAL | `async-` |
| 2 | Bundle Size Optimization | CRITICAL | `bundle-` |
| 3 | Server-Side Performance | HIGH | `server-` |
| 4 | Client-Side Data Fetching | MEDIUM-HIGH | `client-` |
| 5 | Re-render Optimization | MEDIUM | `rerender-` |
| 6 | Rendering Performance | MEDIUM | `rendering-` |
| 7 | JavaScript Performance | LOW-MEDIUM | `js-` |
| 8 | Advanced Patterns | LOW | `advanced-` |

## Quick Reference

### 1. Eliminating Waterfalls (CRITICAL)

- `async-cheap-condition-before-await` - Check cheap sync conditions before awaiting flags or remote values
- `async-defer-await` - Move await into branches where actually used
- `async-parallel` - Use Promise.all() for independent operations
- `async-dependencies` - Use better-all for partial dependencies
- `async-api-routes` - Start promises early, await late in API routes
- `async-suspense-boundaries` - Use Suspense to stream content

### 2. Bundle Size Optimization (CRITICAL)

- `bundle-barrel-imports` - Import directly, avoid barrel files
- `bundle-analyzable-paths` - Prefer statically analyzable import and file-system paths to avoid broad bundles and traces
- `bundle-dynamic-imports` - Use next/dynamic for heavy components
- `bundle-defer-third-party` - Load analytics/logging after hydration
- `bundle-conditional` - Load modules only when feature is activated
- `bundle-preload` - Preload on hover/focus for perceived speed

### 3. Server-Side Performance (HIGH)

- `server-auth-actions` - Authenticate server actions like API routes
- `server-cache-react` - Use React.cache() for per-request deduplication
- `server-cache-lru` - Use LRU cache for cross-request caching
- `server-dedup-props` - Avoid duplicate serialization in RSC props
- `server-hoist-static-io` - Hoist static I/O (fonts, logos) to module level
- `server-no-shared-module-state` - Avoid module-level mutable request state in RSC/SSR
- `server-serialization` - Minimize data passed to client components
- `server-parallel-fetching` - Restructure components to parallelize fetches
- `server-parallel-nested-fetching` - Chain nested fetches per item in Promise.all
- `server-after-nonblocking` - Use after() for non-blocking operations

### 4. Client-Side Data Fetching (MEDIUM-HIGH)

- `client-swr-dedup` - Use SWR for automatic request deduplication
- `client-event-listeners` - Deduplicate global event listeners
- `client-passive-event-listeners` - Use passive listeners for scroll
- `client-localstorage-schema` - Version and minimize localStorage data

### 5. Re-render Optimization (MEDIUM)

- `rerender-defer-reads` - Don't subscribe to state only used in callbacks
- `rerender-memo` - Extract expensive work into memoized components
- `rerender-memo-with-default-value` - Hoist default non-primitive props
- `rerender-dependencies` - Use primitive dependencies in effects
- `rerender-derived-state` - Subscribe to derived booleans, not raw values
- `rerender-derived-state-no-effect` - Derive state during render, not effects
- `rerender-functional-setstate` - Use functional setState for stable callbacks
- `rerender-lazy-state-init` - Pass function to useState for expensive values
- `rerender-simple-expression-in-memo` - Avoid memo for simple primitives
- `rerender-split-combined-hooks` - Split hooks with independent dependencies
- `rerender-move-effect-to-event` - Put interaction logic in event handlers
- `rerender-transitions` - Use startTransition for non-urgent updates
- `rerender-use-deferred-value` - Defer expensive renders to keep input responsive
- `rerender-use-ref-transient-values` - Use refs for transient frequent values
- `rerender-no-inline-components` - Don't define components inside components

### 6. Rendering Performance (MEDIUM)

- `rendering-animate-svg-wrapper` - Animate div wrapper, not SVG element
- `rendering-content-visibility` - Use content-visibility for long lists
- `rendering-hoist-jsx` - Extract static JSX outside components
- `rendering-svg-precision` - Reduce SVG coordinate precision
- `rendering-hydration-no-flicker` - Use inline script for client-only data
- `rendering-hydration-suppress-warning` - Suppress expected mismatches
- `rendering-activity` - Use Activity component for show/hide
- `rendering-conditional-render` - Use ternary, not && for conditionals
- `rendering-usetransition-loading` - Prefer useTransition for loading state
- `rendering-resource-hints` - Use React DOM resource hints for preloading
- `rendering-script-defer-async` - Use defer or async on script tags

### 7. JavaScript Performance (LOW-MEDIUM)

- `js-batch-dom-css` - Group CSS changes via classes or cssText
- `js-index-maps` - Build Map for repeated lookups
- `js-cache-property-access` - Cache object properties in loops
- `js-cache-function-results` - Cache function results in module-level Map
- `js-cache-storage` - Cache localStorage/sessionStorage reads
- `js-combine-iterations` - Combine multiple filter/map into one loop
- `js-length-check-first` - Check array length before expensive comparison
- `js-early-exit` - Return early from functions
- `js-hoist-regexp` - Hoist RegExp creation outside loops
- `js-min-max-loop` - Use loop for min/max instead of sort
- `js-set-map-lookups` - Use Set/Map for O(1) lookups
- `js-tosorted-immutable` - Use toSorted() for immutability
- `js-flatmap-filter` - Use flatMap to map and filter in one pass
- `js-request-idle-callback` - Defer non-critical work to browser idle time

### 8. Advanced Patterns (LOW)

- `advanced-effect-event-deps` - Don't put `useEffectEvent` results in effect deps
- `advanced-event-handler-refs` - Store event handlers in refs
- `advanced-init-once` - Initialize app once per app load
- `advanced-use-latest` - useLatest for stable callback refs

## How to Use

Read individual rule files for detailed explanations and code examples:

```
rules/async-parallel.md
rules/bundle-barrel-imports.md
```

Each rule file contains:
- Brief explanation of why it matters
- Incorrect code example with explanation
- Correct code example with explanation
- Additional context and references

## Full Compiled Document

For the complete guide with all rules expanded: `AGENTS.md`


## --- Original Skill: vercel-react-view-transitions ---

# React View Transitions

Animate between UI states using the browser's native `document.startViewTransition`. Declare *what* with `<ViewTransition>`, trigger *when* with `startTransition` / `useDeferredValue` / `Suspense`, control *how* with CSS classes. Unsupported browsers skip animations gracefully.

## When to Animate

Every `<ViewTransition>` should communicate a spatial relationship or continuity. If you can't articulate what it communicates, don't add it.

Implement **all** applicable patterns from this list, in this order:

| Priority | Pattern | What it communicates |
|----------|---------|---------------------|
| 1 | **Shared element** (`name`) | "Same thing — going deeper" |
| 2 | **Suspense reveal** | "Data loaded" |
| 3 | **List identity** (per-item `key`) | "Same items, new arrangement" |
| 4 | **State change** (`enter`/`exit`) | "Something appeared/disappeared" |
| 5 | **Route change** (layout-level) | "Going to a new place" |

This is an implementation order, not a "pick one" list. Implement every pattern that fits the app. Only skip a pattern if the app has no use case for it.

### Choosing Animation Style

| Context | Animation | Why |
|---------|-----------|-----|
| Hierarchical navigation (list → detail) | Type-keyed `nav-forward` / `nav-back` | Communicates spatial depth |
| Lateral navigation (tab-to-tab) | Bare `<ViewTransition>` (fade) or `default="none"` | No depth to communicate |
| Suspense reveal | `enter`/`exit` string props | Content arriving |
| Revalidation / background refresh | `default="none"` | Silent — no animation needed |

Reserve directional slides for hierarchical navigation (list → detail) and ordered sequences (prev/next photo, carousel, paginated results). For ordered sequences, the direction communicates position: "next" slides from right, "previous" from left. Lateral/unordered navigation (tab-to-tab) should not use directional slides — it falsely implies spatial depth.

---

## Availability

- **Next.js:** Do **not** install `react@canary` — the App Router already bundles React canary internally. `ViewTransition` works out of the box. `npm ls react` may show a stable-looking version; this is expected.
- **Without Next.js:** Install `react@canary react-dom@canary` (`ViewTransition` is not in stable React).
- Browser support: Chromium 111+, Firefox 144+, Safari 18.2+. Graceful degradation on unsupported browsers.

---

## Implementation Workflow

When adding view transitions to an existing app, **follow `references/implementation.md` step by step.** Start with the audit — do not skip it. Copy the CSS recipes from `references/css-recipes.md` into the global stylesheet — do not write your own animation CSS.

---

## Core Concepts

### The `<ViewTransition>` Component

```jsx
import { ViewTransition } from 'react';

<ViewTransition>
  <Component />
</ViewTransition>
```

React auto-assigns a unique `view-transition-name` and calls `document.startViewTransition` behind the scenes. Never call `startViewTransition` yourself.

### Animation Triggers

| Trigger | When it fires |
|---------|--------------|
| **enter** | `<ViewTransition>` first inserted during a Transition |
| **exit** | `<ViewTransition>` first removed during a Transition |
| **update** | DOM mutations inside a `<ViewTransition>`. With nested VTs, mutation applies to the innermost one |
| **share** | Named VT unmounts and another with same `name` mounts in the same Transition |

Only `startTransition`, `useDeferredValue`, or `Suspense` activate VTs. Regular `setState` does not animate.

### Critical Placement Rule

`<ViewTransition>` only activates enter/exit if it appears **before any DOM nodes**:

```jsx
// Works
<ViewTransition enter="auto" exit="auto">
  <div>Content</div>
</ViewTransition>

// Broken — div wraps the VT, suppressing enter/exit
<div>
  <ViewTransition enter="auto" exit="auto">
    <div>Content</div>
  </ViewTransition>
</div>
```

---

## Styling with View Transition Classes

### Props

Values: `"auto"` (browser cross-fade), `"none"` (disabled), `"class-name"` (custom CSS), or `{ [type]: value }` for type-specific animations.

```jsx
<ViewTransition default="none" enter="slide-in" exit="slide-out" share="morph" />
```

If `default` is `"none"`, all triggers are off unless explicitly listed.

### CSS Pseudo-Elements

- `::view-transition-old(.class)` — outgoing snapshot
- `::view-transition-new(.class)` — incoming snapshot
- `::view-transition-group(.class)` — container
- `::view-transition-image-pair(.class)` — old + new pair

See `references/css-recipes.md` for ready-to-use animation recipes.

---

## Transition Types

Tag transitions with `addTransitionType` so VTs can pick different animations based on context. Call it multiple times to stack types — different VTs in the tree react to different types:

```jsx
startTransition(() => {
  addTransitionType('nav-forward');
  addTransitionType('select-item');
  router.push('/detail/1');
});
```

Pass an object to map types to CSS classes. Works on `enter`, `exit`, **and** `share`:

```jsx
<ViewTransition
  enter={{ 'nav-forward': 'slide-from-right', 'nav-back': 'slide-from-left', default: 'none' }}
  exit={{ 'nav-forward': 'slide-to-left', 'nav-back': 'slide-to-right', default: 'none' }}
  share={{ 'nav-forward': 'morph-forward', 'nav-back': 'morph-back', default: 'morph' }}
  default="none"
>
  <Page />
</ViewTransition>
```

`enter` and `exit` don't have to be symmetric. For example, fade in but slide out directionally:

```jsx
<ViewTransition
  enter={{ 'nav-forward': 'fade-in', 'nav-back': 'fade-in', default: 'none' }}
  exit={{ 'nav-forward': 'nav-forward', 'nav-back': 'nav-back', default: 'none' }}
  default="none"
>
```

**TypeScript:** `ViewTransitionClassPerType` requires a `default` key in the object.

For apps with multiple pages, extract the type-keyed VT into a reusable wrapper:

```jsx
export function DirectionalTransition({ children }: { children: React.ReactNode }) {
  return (
    <ViewTransition
      enter={{ 'nav-forward': 'nav-forward', 'nav-back': 'nav-back', default: 'none' }}
      exit={{ 'nav-forward': 'nav-forward', 'nav-back': 'nav-back', default: 'none' }}
      default="none"
    >
      {children}
    </ViewTransition>
  );
}
```

### `router.back()` and Browser Back Button

`router.back()` and the browser's back/forward buttons do **not** trigger view transitions (`popstate` is synchronous, incompatible with `startViewTransition`). Use `router.push()` with an explicit URL instead.

### Types and Suspense

Types are available during navigation but **not** during subsequent Suspense reveals (separate transitions, no type). Use type maps for page-level enter/exit; use simple string props for Suspense reveals.

---

## Shared Element Transitions

Same `name` on two VTs — one unmounting, one mounting — creates a shared element morph:

```jsx
<ViewTransition name="hero-image">
  <img src="/thumb.jpg" onClick={() => startTransition(() => onSelect())} />
</ViewTransition>

// On the other view — same name
<ViewTransition name="hero-image">
  <img src="/full.jpg" />
</ViewTransition>
```

- Only one VT with a given `name` can be mounted at a time — use unique names (`photo-${id}`). Watch for reusable components: if a component with a named VT is rendered in both a modal/popover *and* a page, both mount simultaneously and break the morph. Either make the name conditional (via a prop) or move the named VT out of the shared component into the specific consumer.
- `share` takes precedence over `enter`/`exit`. Think through each navigation path: when no matching pair forms (e.g., the target page doesn't have the same name), `enter`/`exit` fires instead. Consider whether the element needs a fallback animation for those paths.
- Never use a fade-out exit on pages with shared morphs — use a directional slide instead.

---

## Common Patterns

### Enter/Exit

```jsx
{show && (
  <ViewTransition enter="fade-in" exit="fade-out"><Panel /></ViewTransition>
)}
```

### List Reorder

```jsx
{items.map(item => (
  <ViewTransition key={item.id}><ItemCard item={item} /></ViewTransition>
))}
```

Trigger inside `startTransition`. Avoid wrapper `<div>`s between list and VT.

### Composing Shared Elements with List Identity

Shared elements and list identity are independent concerns — don't confuse one for the other. When a list item contains a shared element (e.g., an image that morphs into a detail view), use two nested `<ViewTransition>` boundaries:

```jsx
{items.map(item => (
  <ViewTransition key={item.id}>                                      {/* list identity */}
    <Link href={`/items/${item.id}`}>
      <ViewTransition name={`item-image-${item.id}`} share="morph">   {/* shared element */}
        <Image src={item.image} />
      </ViewTransition>
      <p>{item.name}</p>
    </Link>
  </ViewTransition>
))}
```

The outer VT handles list reorder/enter animations. The inner VT handles the cross-route shared element morph. Missing either layer means that animation silently doesn't happen.

### Force Re-Enter with `key`

```jsx
<ViewTransition key={searchParams.toString()} enter="slide-up" default="none">
  <ResultsGrid />
</ViewTransition>
```

**Caution:** If wrapping `<Suspense>`, changing `key` remounts the boundary and refetches.

### Suspense Fallback to Content

Simple cross-fade:
```jsx
<ViewTransition>
  <Suspense fallback={<Skeleton />}><Content /></Suspense>
</ViewTransition>
```

Directional reveal:
```jsx
<Suspense fallback={<ViewTransition exit="slide-down"><Skeleton /></ViewTransition>}>
  <ViewTransition enter="slide-up" default="none"><Content /></ViewTransition>
</Suspense>
```

For more patterns, see `references/patterns.md`.

---

## How Multiple VTs Interact

Every VT matching the trigger fires simultaneously in a single `document.startViewTransition`. VTs in **different** transitions (navigation vs later Suspense resolve) don't compete.

### Use `default="none"` Liberally

Without it, every VT fires the browser cross-fade on **every** transition — Suspense resolves, `useDeferredValue` updates, background revalidations. Always use `default="none"` and explicitly enable only desired triggers.

### Two Patterns Coexist

**Pattern A — Directional slides:** Type-keyed VT on each page, fires during navigation.
**Pattern B — Suspense reveals:** Simple string props, fires when data loads (no type).

They coexist because they fire at different moments. `default="none"` on both prevents cross-interference. Always pair `enter` with `exit`. Place directional VTs in page components, not layouts.

### Nested VT Limitation

When a parent VT exits, nested VTs inside it do **not** fire their own enter/exit — only the outermost VT animates. Per-item staggered animations during page navigation are not possible today. See [react#36135](https://github.com/facebook/react/pull/36135) for an experimental opt-in fix.

---

## Next.js Integration

For Next.js setup (`experimental.viewTransition` flag, `transitionTypes` prop on `next/link`, App Router patterns, Server Components), see `references/nextjs.md`.

---

## Accessibility

Always add the reduced motion CSS from `references/css-recipes.md` to your global stylesheet.

---

## Reference Files

- **`references/implementation.md`** — Step-by-step implementation workflow.
- **`references/patterns.md`** — Patterns, animation timing, events API, troubleshooting.
- **`references/css-recipes.md`** — Ready-to-use CSS animation recipes.
- **`references/nextjs.md`** — Next.js App Router patterns and Server Component details.

## Full Compiled Document

For the complete guide with all reference files expanded: `AGENTS.md`

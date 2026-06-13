---
name: watermelon-ui
description: Watermelon UI (ui.watermelon.sh) is a React + Tailwind component collection whose public docs are a JS-rendered SPA — server-fetched HTML returned no readable component catalogue during skill authoring. Trigger on "watermelon-ui", "watermelon", or "ui.watermelon.sh" when shopping component libraries for a Shopify Hydrogen drop-shipping store. Treat as low-priority until docs are inspected via Chrome MCP or a real browser. Do NOT invent component names or recommend imports without verification. Keywords: drop-shipping, Shopify, Hydrogen, product page, PDP, hero, CTA, conversion, store, ecommerce, watermelon, candidate library.
---

# Watermelon UI

## What this is
Watermelon UI is a React component library hosted at ui.watermelon.sh. Likely Tailwind-based, likely targeting Next.js / Remix + TypeScript, possibly a shadcn-style copy/paste registry — but unverified. The public landing page rendered entirely client-side at fetch time, returning a bare HTML shell with no component sidebar, install instructions, license terms, or pricing visible without a real browser. This skill is therefore a routing placeholder: it tells you what to verify before recommending anything for a drop-shipping store.

## When to trigger
- User explicitly mentions "watermelon-ui", "watermelon", or "ui.watermelon.sh".
- User is shopping component libraries for a Shopify Hydrogen store and asks to compare watermelon against cult-ui / skiper-ui / shadcn.
- User asks "is watermelon-ui any good for my Shopify store?" — answer: unknown until docs are inspected.

## Components / patterns that fit drop-shipping
**Unknown.** The site's HTML at fetch time exposed no component list. Before recommending any Watermelon UI component for a Hydrogen PDP, PLP, cart drawer, or hero, do one of:
1. Open https://ui.watermelon.sh in a real browser (or via Chrome MCP) and read the component sidebar.
2. Find the GitHub source (search "watermelon-ui" or "ui.watermelon.sh") and enumerate the components directory.
3. Ask the user which specific Watermelon UI component they have in mind.

If verification reveals it's a shadcn fork or registry, install pattern is `npx shadcn add <url>` and it can probably play a similar role to cult-ui — but that needs evidence, not inference.

## Multi-niche store builder fit
Cannot evaluate without seeing the catalogue. Multi-niche reuse depends on: (1) MIT or permissive license, (2) shadcn-style copy/paste (so each niche store owns its source), (3) theming via CSS variables so brand tokens swap cleanly. All three are unconfirmed.

## Install (Shopify Hydrogen)
**Unverified.** Install instructions were not exposed in server-fetched HTML. Most likely patterns:
- shadcn-style registry: `npx shadcn add https://ui.watermelon.sh/r/<component>.json`
- npm package: `npm i @watermelon/ui` or similar
- Direct copy/paste from docs site

Stack assumption (until verified): Next.js / Remix + React + TypeScript + Tailwind, matching a Hydrogen project. Confirm peer deps by reading the live install page.

## Conversion-focused patterns
Unknown until catalogue is inspected. If Watermelon ships hero, product-card, or cart-drawer patterns, evaluate them against the same conversion criteria used for cult-ui and skiper-ui: scroll-stop hero, hover-rich product cards, sticky CTAs, mobile-first cart pill, exit-intent capture.

## Gotchas
- **Docs are JS-rendered** — server-side HTML fetches return nothing useful. A real browser or Chrome MCP is required.
- **Unknown maintenance status** — confirm last commit, issue response time, and dep freshness before adopting in a production drop-shipping store.
- **Unknown license terms** — verify MIT vs. premium tier before pulling into a store you'll sell to a client.
- **Unknown accessibility posture** — small/niche libraries often skip ARIA and reduced-motion. Drop-shipping stores need solid mobile a11y for paid-ads landing pages.
- **Unknown Oxygen / SSR compatibility** — Hydrogen renders on Shopify's edge runtime; some libraries assume Node-only.
- **Default to cult-ui + shadcn** for the same use cases unless the user has a specific reason to prefer Watermelon's look after inspecting it.
- **Do NOT invent component names** — never write `import { WatermelonHero } from "..."` without verifying the import on the live site.

## Reference
- Docs: https://ui.watermelon.sh (JS-rendered; not directly scrapeable)
- Suggested verification: open in a real browser via Chrome MCP, screenshot the sidebar, then update this skill with the actual component inventory.
- Related: shadcn/ui base, cult-ui, skiper-ui, Shopify Hydrogen docs

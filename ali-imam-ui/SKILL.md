---
name: ali-imam-ui
description: Ali Imam's component collection at aliimam.in/docs/components and animata.design is an indie React + Tailwind animated-component reference focused on micro-interactions. Docs were not directly fetchable during skill authoring — verify in a real browser before recommending specifics. Trigger on "ali imam", "aliimam", "ali-imam-ui", "animata", or when building a Shopify Hydrogen drop-shipping store that needs product-card hover micro-interactions, scroll-triggered reveals, sparkline-style trust badges, animated counters for social proof, or status-pulse indicators on order tracking. Keywords: drop-shipping, Shopify, Hydrogen, product page, hero, CTA, testimonial, conversion, store, ecommerce, micro-interaction, hover card.
---

# Ali Imam UI (aliimam.in / animata.design)

## What this is
A personal / indie React component documentation site by designer-developer Ali Imam, with the related animata.design property hosting a broader catalogue of copy/paste React + Tailwind animated components. Strong motion-design / micro-interaction focus — the kind of polish that drop-shipping landing pages use to feel "premium" without going full SaaS-hero excess. URLs were not retrievable through the fetch tool during skill authoring; verify the live catalogue in a real browser before recommending specifics.

## When to trigger
- Building a Hydrogen PDP and want hover-rich product card micro-interactions.
- Adding scroll-triggered reveals on a long landing page (problem → solution → product → testimonials → CTA).
- Designing animated social-proof counters ("3,427 happy customers", "Sold in 47 countries").
- Adding sparkline-style trust badges (rating mini-bars, review distributions).
- Status-pulse indicators on the order confirmation / tracking page.
- User explicitly says "ali imam", "aliimam", or "animata".

## Components / patterns that fit drop-shipping
**Inferred from positioning — confirm against the live site:**
- **Number flip / odometer counters** → social-proof stats above the fold ("12,489 orders shipped").
- **Status pulse / breathing dot** → order tracking page ("Preparing → Shipped → Out for delivery").
- **Hover-card with content reveal** → product card preview (price, rating, variant swatches) on PLP.
- **Sparkline mini-chart** → review distribution badges (5-star count visualized).
- **Scroll-triggered reveals** → long-form landing page sections (problem / solution / how-it-works).
- **Animated section headings** → collection page titles, brand-story page chapter breaks.
- **Marquee / ticker** → "As seen in" press logos, recent-purchase notification rail.

If the live catalogue does not include these, fall back to cult-ui or hand-roll with Framer Motion.

## Multi-niche store builder fit
Likely single-file copy/paste components — you own the source per store. Theming depends on the catalogue's use of Tailwind tokens vs. hardcoded colors. For multi-niche reuse, lift each component into a shared `packages/store-ui/` workspace and override Tailwind theme tokens per niche (`theme.supplements.css`, `theme.apparel.css`, `theme.pets.css`).

## Install (Shopify Hydrogen)
**Unverified.** Likely patterns:
- Copy/paste source from code blocks on the docs site.
- shadcn registry CLI: `npx shadcn add <url>` if registry JSON is exposed.
- Possible separate package via animata.design.

Stack assumption: Next.js / Remix + React + TypeScript + Tailwind + Framer Motion. Confirm peer deps (`clsx`, `tailwind-merge`, `lucide-react`) per component.

```bash
npm create @shopify/hydrogen@latest
cd <store>
npx shadcn@latest init
# Then copy/paste individual Ali Imam / animata components into app/components/
```

## Conversion-focused patterns
- **Social proof tickers** above the fold: animated counters anchor trust on first paint.
- **Hover product cards** on PLP: reveal variant swatches and quick-add without click-through.
- **Scroll-reveal storytelling** on landing pages: each scroll milestone reveals a new conversion lever (problem, demo, testimonial, CTA).
- **Trust-badge sparklines**: rating distribution as a tiny visual instead of text — reads faster on mobile.
- **Marquee press strip**: "Featured in" logos drifting horizontally — cheap perceived authority.

## Gotchas
- **Docs not auto-fetchable** — verify the URL and component list manually in a real browser (Chrome MCP) before recommending any specific component.
- **Personal-portfolio site** — maintenance and breakage risk is higher than for shadcn or Radix. Pin versions and own the source per store.
- **Unknown license terms** — confirm MIT vs. paid before pulling into a client store you'll sell.
- **Likely incomplete a11y defaults** — audit ARIA, keyboard nav, reduced-motion per component. Drop-shipping traffic is heavily mobile and increasingly a11y-scrutinized.
- **Mobile performance** — animated counters and scroll-reveal listeners can hurt LCP / CLS. Lazy-load below the fold; pause animations off-screen.
- **Oxygen / SSR** — verify each component under Hydrogen's edge runtime; some scroll-reveal libs assume `window` exists.

## Reference
- Docs: https://aliimam.in/docs/components (verify in browser; not auto-fetchable)
- Related: https://animata.design
- Portfolio: https://aliimam.in
- Related libraries: shadcn/ui base, cult-ui, Framer Motion, Shopify Hydrogen

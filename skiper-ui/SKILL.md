---
name: skiper-ui
description: Skiper UI is a premium-leaning shadcn-CLI registry of motion-rich React components by Gxuri (Next.js/Remix + Tailwind + motion.dev). ~103 components, mostly behind a $129 one-time license. Trigger on "skiper", "skiper-ui", or when building a Shopify Hydrogen drop-shipping store and the brief calls for high-impact hero motion, image-reveal product showcases, drag-scroll product galleries, dynamic-island cart notifications, or scroll-stop conversion polish. Keywords: drop-shipping, Shopify, Hydrogen, product page, PDP, hero, CTA, testimonial, conversion, store, ecommerce, image reveal, dynamic island, drag scroll, skiperN. UI-only — does not cover Storefront API, checkout flow, or Shopify backend.
---

# Skiper UI

## What this is
Skiper UI is a premium-leaning shadcn registry of motion-heavy "wow-factor" components built for consumer marketing and ecommerce surfaces. Roughly 24 free / 54+ premium components, $129 one-time license. Distributed as copy/paste source via `npx shadcn add @skiper-ui/skiperN`. Built on motion.dev (Framer Motion), Tailwind, and shadcn primitives. The aesthetic is exactly what drop-shipping pages need: bold, scroll-stopping, conversion-driving motion.

## When to trigger
- Building a Shopify Hydrogen product page (PDP) hero that has to stop the scroll on a paid-ads landing page.
- Designing an image-reveal opener for a new niche store (supplements, apparel, electronics, pet).
- Adding a dynamic-island-style "added to cart" notification.
- Building a drag-scroll product gallery for the PDP or a "shop the look" collection module.
- User explicitly says "skiper", "skiper-ui", or links to a skiperN slug.

## Components / patterns that fit drop-shipping
- **Image Reveal (skiper components)** → PDP hero or above-the-fold collection banner. Big product photo with cinematic reveal.
- **Drag-Scroll Gallery (skiper5)** → PDP image gallery, "shop the look", recently-viewed rail.
- **Dynamic Island (skiper2)** → cart-add confirmation pill ("Added: 1x Hoodie · View cart"), free-shipping-threshold meter, stock-low warning.
- **Number-tick / counter** → "127 sold this week", "Only 8 left", live social-proof counters.
- **Image Cursor Trail (skiper18)** → premium-brand landing hero where vibe sells. Use sparingly.
- **Vercel-style Tooltip (skiper43)** → variant swatch hover, size-guide affordance.
- **Devouring-details Sign-in (skiper56)** → email capture / account create on order confirmation.

## Multi-niche store builder fit
Skiper components are single-file copy/paste — you own each one. Parametrize colors and copy via Tailwind theme tokens and shadcn CSS vars so the same Image Reveal hero works for a supplement store (forest green / cream) and a streetwear store (black / acid yellow). Lift the component once into your store-builder library, then swap brand tokens per niche.

## Install (Shopify Hydrogen)
```bash
# Baseline Hydrogen project
npm create @shopify/hydrogen@latest
cd <store>
npx shadcn@latest init
# Add skiper components (premium login required)
npx shadcn add @skiper-ui/skiper2    # dynamic island
npx shadcn add @skiper-ui/skiper5    # drag-scroll gallery
npx shadcn add @skiper-ui/skiper18   # image cursor trail
```
Peer deps: `motion`, `clsx`, `tailwind-merge`. Premium components require a Skiper account during install.

## Conversion-focused patterns
- **PDP hero scroll-stop**: image-reveal + animated price strikethrough on first paint.
- **Cart confirmation**: dynamic island pill instead of a full cart-drawer slam — keeps the user shopping.
- **Social proof tickers**: animated counters for "sold today", "live viewers", "low stock".
- **Hover-rich variant swatches**: tooltip-driven color/size selection that feels responsive.
- **Exit-intent reveal**: devouring-details modal for "10% off if you stay" email capture.

## Gotchas
- **$129 paywall** — the genuinely useful components (dynamic island, image cursor trail, devouring-details) are mostly premium. Budget accordingly per store launch.
- **Bundle weight** — motion.dev + multiple skiper components on a Hydrogen PDP will hurt LCP on mobile. Lazy-load below-the-fold and code-split aggressively.
- **Mobile performance** — drop-shipping traffic is 70%+ mobile. Audit each skiper component on a real low-end device, not desktop devtools.
- **Oxygen runtime** — components must be client components or properly hydrated. Verify SSR compatibility per component.
- **Accessibility** — motion-first components rarely ship reduced-motion or full ARIA. Respect `prefers-reduced-motion`.
- **License** — per-developer one-time. Don't republish source across client stores you don't own.

## Reference
- Docs: https://skiper-ui.com
- Components: https://skiper-ui.com/components
- Pricing: https://skiper-ui.com/pricing
- Related: shadcn/ui base, Shopify Hydrogen docs, motion.dev

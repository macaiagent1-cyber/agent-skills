---
name: cult-ui
description: Cult UI is an MIT-licensed motion-rich shadcn/ui extension by nolly-studio (~3.8k stars) for Next.js/Remix + Tailwind + Framer Motion. Components include Texture Card, Expandable Card, Family Button, Dock, Dynamic Island, Gradient Heading, Tilt Card. Trigger on "cult", "cult-ui", "texture card", "expandable card", "family button", "tilt card", "dynamic island", or when building a Shopify Hydrogen drop-shipping store and need premium product cards, hover-3D PDP heroes, floating action stacks, mini-cart pills, or collection-page hero titles. Keywords: drop-shipping, Shopify, Hydrogen, product page, PDP, hero, CTA, testimonial, conversion, store, ecommerce, cart drawer.
---

# Cult UI

## What this is
Cult UI is a motion-rich open-source component registry that extends shadcn/ui. MIT-licensed, ~3.8k stars, authored by Jordan Gilliam at nolly-studio. Components install via `npx shadcn add` against cult-ui.com's registry JSON — you own the source. Built on shadcn theme variables, Tailwind, Radix, and Framer Motion. Pairs naturally with Shopify Hydrogen because both lean React + Tailwind + composable primitives.

## When to trigger
- Building a Hydrogen product card grid that needs premium texture / hover-3D depth.
- Designing a floating "add to cart / wishlist / share" action stack on PDP.
- Adding a persistent mini-cart pill that shows item count without slamming a full drawer.
- Building collection-page (PLP) hero titles with gradient flair.
- Expanding product detail accordions (description, ingredients, shipping, FAQ).

## Components / patterns that fit drop-shipping
- **Texture Card** → premium product card on PLP. Subtle grain reads "premium" not "Aliexpress".
- **Tilt Card** → PDP hero product image with hover-3D depth. Works on desktop; degrade gracefully on mobile.
- **Expandable Card** → PDP accordion blocks (description, ingredients, shipping, returns, FAQ).
- **Family Button** → floating PDP action stack (Add to Cart / Wishlist / Share / Quick View).
- **Dock** → persistent mobile bottom nav (Shop / Collections / Cart / Account) — Shopify mobile-first.
- **Dynamic Island** → mini cart pill ("3 items · $87 · View"), free-shipping progress bar, "added to cart" confirmation.
- **Gradient Heading** → collection page / landing hero titles. One per page, used as the brand moment.
- **Tweet Textarea pattern** → product review submission form with character feedback.

## Multi-niche store builder fit
Cult UI components are copy/paste shadcn registry entries — you own each file. Theme via shadcn CSS variables (`--background`, `--primary`, `--accent`) so the same Texture Card works for a pet-supplies niche (warm browns) or a tech-gadgets niche (cool slate). Build one shared `packages/store-ui/` workspace with cult-ui components installed once, then per-store `theme.css` files override tokens.

## Install (Shopify Hydrogen)
```bash
npm create @shopify/hydrogen@latest
cd <store>
npx shadcn@latest init
# Add cult-ui components
npx shadcn@latest add "https://www.cult-ui.com/r/texture-card.json"
npx shadcn@latest add "https://www.cult-ui.com/r/expandable-card.json"
npx shadcn@latest add "https://www.cult-ui.com/r/family-button.json"
npx shadcn@latest add "https://www.cult-ui.com/r/dock.json"
npx shadcn@latest add "https://www.cult-ui.com/r/dynamic-island.json"
npx shadcn@latest add "https://www.cult-ui.com/r/tilt-card.json"
```
Peer deps: `framer-motion`, `clsx`, `tailwind-merge`, `lucide-react`, plus Radix primitives shadcn pulls in.

## Conversion-focused patterns
- **PDP**: Tilt Card hero + Family Button floating actions + Expandable Card description = premium feel, fewer clicks to cart.
- **PLP**: Texture Card grid with Gradient Heading at top.
- **Mini cart**: Dynamic Island pill that sticks during browse — visible cart progress drives AOV.
- **Mobile nav**: Dock as bottom-fixed primary nav. Thumb-zone optimized.
- **Trust strip**: Expandable Cards for shipping / returns / guarantee — one tap reveals detail without leaving page.

## Gotchas
- **Cult Pro is separate and paid** — keep license boundaries clean; don't mix Pro marketing blocks into stores you sell to clients.
- **Framer Motion bundle weight** — 4-5 animated components on a single PDP will hurt mobile LCP. Code-split and lazy-load below-the-fold.
- **Tilt Card on mobile** — disable or downgrade the 3D effect on touch devices; gyroscope-driven tilt feels janky.
- **Oxygen / Edge runtime** — verify each component renders correctly under Hydrogen's SSR; some Framer Motion patterns need `'use client'`.
- **Accessibility** — respect `prefers-reduced-motion`; ensure Expandable Cards have proper aria-expanded.
- **Docs sidebar is JS-rendered** — when verifying slugs, use a real browser or GitHub source.

## Reference
- Docs: https://www.cult-ui.com/docs
- GitHub: https://github.com/nolly-studio/cult-ui
- Pro: https://pro.cult-ui.com
- Related: shadcn/ui base, Shopify Hydrogen, Framer Motion

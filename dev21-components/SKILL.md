---
name: dev21-components
description: 21st.dev is a community marketplace of React + Tailwind components ("npm for design engineers") with Magic Chat, 1Code, and an MCP server for prompt-to-UI generation. Goldmine for drop-shipping Shopify Hydrogen stores — Heros, Testimonials, Pricing, CTAs, Buttons, AI Chat, and Shaders map directly to conversion surfaces. Trigger when building a product page, collection page, hero, testimonial carousel, pricing block, sticky CTA, ATC button variants, or product Q&A widget. Keywords: 21st.dev, magic chat, 1code, shadcn marketplace, hero, testimonial, pricing, CTA, product page, conversion, drop-shipping, Shopify, Hydrogen, ecommerce, store. Does NOT cover: Shopify Storefront API queries, cart/checkout state (use Hydrogen primitives), or a unified design system — marketplace components vary in quality and need vetting per niche.
---

# 21st.dev Community Components

## What this is
A community-driven marketplace of React + Tailwind components, plus three AI-flavored entry points: Magic Chat (prompt-to-UI), 1Code (one-shot generation), and an MCP server for agent-driven lookup. Stack assumes React + TS + Tailwind, shadcn/ui-compatible — drops cleanly into Shopify Hydrogen (Remix-based) or a Next.js Storefront API fallback. Quality varies per author; treat it as a parts bin, not a system.

## When to trigger
- Building a new niche store and need a hero, testimonial row, pricing/promo block, or sticky CTA fast.
- Need ATC button variations, trust-badge rows, or animated text reveals for PDPs.
- Adding product Q&A / chat support widgets (AI Chat category).
- Want a shader/gradient backdrop for a hero without writing WebGL.
- Prompt-to-component workflow — describe a section, generate a starting point, refine.

## What this gives a drop-shipping store
- **Heros** → above-the-fold hero with headline, value prop, primary CTA. Drop into `routes/_index.tsx`.
- **Testimonials** → carousels, grid walls, video-style cards. PDP and landing page social proof.
- **Pricing** → comparison tables, tiered cards, bundle pricers. Promo pages, bundle PDPs.
- **CTAs** → sticky bottom bars, exit-intent banners, scroll-triggered reveals. Cart conversion.
- **Buttons** → "Add to Cart", "Buy Now", quantity steppers, payment-method buttons.
- **AI Chat** → product Q&A / support widget on PDP and collection pages.
- **Shaders** → animated hero backdrops (use sparingly; mobile cost).
- **Text** → kinetic typography, number tickers (revenue counters, stock left).

## Multi-niche store builder fit
Most 21st.dev components accept className overrides and shadcn token vars (`--primary`, `--background`, `--foreground`, `--accent`). Define a `brand.tokens.css` per niche (supplements, apparel, electronics, pet) and the same hero/testimonial/CTA component re-skins automatically. Magic Chat is ideal for the store-builder pattern: feed it the brand brief plus a section description and it returns niche-flavored variants you parametrize with tokens.

## Install (Shopify Hydrogen)
```bash
# Hydrogen scaffold assumed: npm create @shopify/hydrogen@latest
npx shadcn@latest init                    # base tokens + utils
# Then copy components from 21st.dev pages OR use the MCP:
npx -y @21st-dev/magic                    # Magic Chat / MCP
# Components typically need:
npm install motion lucide-react clsx tailwind-merge
```
Register the 21st MCP in your Claude config so you can query mid-session: "find me a 3-tier pricing card with a 'most popular' highlight."

## Conversion-focused patterns
- **Sticky ATC bar** (mobile PDP) — slide-up after hero scrolls off; persistent price + CTA. Mobile conversion lift is real.
- **Scarcity ticker** (Text category) — "Only 3 left at this price" with animated digit. Pair with real inventory from Storefront API; never fake it.
- **Testimonial wall** above the fold-2 — 6–9 cards, autoscroll, pause on hover.
- **Bundle pricing** (Pricing) — show single / 2-pack / 3-pack with crossed-out original.
- **Exit-intent CTA** — discount-code reveal on mouse-leave (desktop) or scroll-up-fast (mobile).
- **Trust row** under ATC — "Free shipping over $X • 30-day returns • 4.8★ from 12k reviews."

## Gotchas
- Heterogeneous quality — vet each component for layout shift (CLS), bundle size, and Lighthouse impact before adopting on the PDP.
- Many components ship `framer-motion` + `lucide-react` deps; check tree-shaking.
- Shopify Oxygen runs on workers — avoid components that touch `window` at import time; defer to `useEffect` or `<ClientOnly>`.
- Accessibility uneven — audit ARIA, focus rings, reduced-motion before launch.
- Shaders + heavy hero video kill mobile LCP. Test on a throttled 4G device.
- Licensing varies per component author — confirm per use.

## Reference
- Marketplace: https://21st.dev/community/components
- MCP: https://21st.dev/mcp
- Related libs: `framer-motion` (motion runtime), `emil-kowalski` (Vaul/Sonner/cmdk polish), `impeccable-style` (anti-slop audit), shadcn/ui (base primitives)

---
name: styleui
description: StyleUI (styleui.dev) is a handmade Next.js + Tailwind full-page TEMPLATE collection by Ras Mic and the Fabrika team — not a component library. Free catalogue is small (Notio, Axis); a paid Pro tier exists. Trigger on "styleui", "style ui", "template", "landing page", "notio", "axis", "ras mic", "fabrika" when building non-product pages for a Shopify Hydrogen drop-shipping store — brand-story, about-us, contact, FAQ, lookbook, manifesto. NOT a fit for product or collection pages (Hydrogen has its own conventions). Keywords: drop-shipping, Shopify, Hydrogen, landing page, brand page, about, FAQ, conversion, store, ecommerce, template.
---

# StyleUI

## What this is
StyleUI is a hand-crafted Next.js + Tailwind **template** collection (not a component library) by Ras Mic and the Fabrika team. The free side at github.com/heyfabrika/styleui exposes two named templates (Notio, Axis); a paid StyleUI Pro tier hosts more. Each template is a full-page, opinionated Next.js project you fork and rebrand — hero, features, pricing, footer all baked in. Useful as a design reference and starting point for the non-commerce pages of a drop-shipping store.

## When to trigger
- Building a brand-story / about-us page for a niche store where the brand voice matters (premium supplements, artisan pet food, boutique apparel).
- Designing an FAQ, contact, or manifesto page where Hydrogen's product-centric routing is less opinionated.
- Spinning up a coming-soon / pre-launch landing page before a Shopify backend is wired up.
- Lifting design references (hero composition, type stack, section rhythm) into custom Hydrogen routes.
- User explicitly says "styleui", "notio", "axis", or asks about full-page templates.

## Components / patterns that fit drop-shipping
StyleUI is template-level, not component-level. Map templates to **non-product** surfaces only:
- **Notio** → "About the Brand" page, brand-manifesto page, founder-story page. Clean documentation-flavored layout.
- **Axis** → marketing-style landing page for a new product drop, pre-launch waitlist page, lookbook.
- **Hero + features sections** → liftable into Hydrogen's home route as design inspiration.
- **Pricing section** → reusable as a "bundles / subscription tiers" page if the niche supports subscriptions (supplements, pet food refills).

**Do NOT use StyleUI for PDP, PLP, cart drawer, or checkout** — Hydrogen has strong conventions there and templates will fight them.

## Multi-niche store builder fit
Templates are opinionated full pages, so multi-niche reuse means forking once per niche and rebranding heavily (colors, type, copy, imagery). Better pattern: lift the **structural ideas** (section rhythm, type hierarchy, white-space discipline) into your shared `packages/store-ui/` workspace as Hydrogen route components, rather than copying the templates wholesale per store.

## Install (Shopify Hydrogen)
StyleUI is template-by-clone, not CLI install. Two integration paths:

**Path A — standalone marketing site adjacent to Hydrogen:**
```bash
git clone https://github.com/heyfabrika/styleui.git
cd styleui/templates/notio
npm install && npm run dev
# Rebrand, deploy to Vercel, link from your Shopify storefront
```

**Path B — lift sections into Hydrogen routes:**
```bash
npm create @shopify/hydrogen@latest
cd <store>
# Copy individual sections from a StyleUI template into app/routes/about.tsx, app/routes/faq.tsx
```
Stack: Next.js + React + TypeScript + Tailwind. Hydrogen uses Remix — Next.js patterns (App Router, server components) need translation when porting.

## Conversion-focused patterns
- **Brand-story page**: Notio-style typographic layout builds trust for premium niches — reduces "is this a scam dropship?" friction.
- **Pre-launch waitlist**: Axis-style hero with email capture before the Shopify store is live.
- **Manifesto / mission page**: cheap perceived authority for niches where values sell (sustainable apparel, ethical pet products).
- **FAQ page**: structured Q&A reduces support tickets and answers objections that block checkout.

## Gotchas
- **Templates, not components** — don't reach for StyleUI when you need a single button, card, or modal. Use cult-ui or shadcn.
- **Next.js → Remix translation** — Hydrogen runs on Remix. App-Router patterns (Next.js `app/`, server actions) need rewriting for Remix loaders/actions.
- **Wrong tool for product/collection pages** — Hydrogen has its own product-page conventions; templates will fight them.
- **Small free catalogue** — only Notio and Axis visible without Pro. If neither fits the niche's voice, look elsewhere (Vercel templates, Tailwind UI).
- **Pro is paid** — verify license before publishing a derived template for a client store.
- **Customization burden** — templates ship opinionated copy, images, and section structure. Stripping them down for a niche brand can take longer than building fresh from shadcn primitives.
- **No commerce primitives** — templates assume static content. No cart, no variant selector, no Shopify Storefront API integration; add on top.
- **Dark-mode parity** — verify per template before assuming the about-us page will look right on mobile in-app browsers.

## Reference
- Site: https://styleui.dev (canonical https://www.styleui.dev)
- GitHub: https://github.com/heyfabrika/styleui
- Templates:
  - Notio — https://www.styleui.dev/template/notio
  - Axis — https://www.styleui.dev/template/axis
- Author: Ras Mic (https://x.com/rasmic), Fabrika (https://x.com/heyfabrika)
- Related: shadcn/ui base, Shopify Hydrogen docs, Remix, Tailwind UI

---
name: frontend-design-system
description: Consolidated skill replacing 13 redundant skills.
---

# Consolidated Skill: frontend-design-system



## --- Original Skill: ali-imam-ui ---

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


## --- Original Skill: cult-ui ---

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


## --- Original Skill: dev21-components ---

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


## --- Original Skill: huashu-design ---

# huashu-design (AI Fund anchor)

## What this is
Upstream alchaincyf/huashu-design is a Chinese-language Claude Code skill that ships a 20-style design vocabulary, a Junior-Designer workflow, a 5-step brand-asset protocol (extract real colors from official sources, never the model's memory), a 5-axis critique (philosophical consistency / visual hierarchy / execution detail / function / innovation), and a Stage+Sprite animation engine that exports MP4/GIF.

Two honesty markers up front:
1. **Language barrier** — the upstream SKILL.md and most reference files are in Chinese. Claude can translate on the fly, but expect Chinese strings in generated comments and references. Tell it the output audience language explicitly.
2. **AI Fund has no design surface today.** No frontend, no deck, no marketing site. The Phase 6+ Mac mini dashboard is on the roadmap, not in the repo. So the portable part of huashu-design here is the *protocol discipline*: brand-asset rigor, batched clarifying questions, 5-axis review — applied to AI Fund's text-and-future-pixel deliverables.

## When to trigger in AI Fund
- Client asks for an **investor / partner deck** explaining the fund.
- Client asks for a **mockup** of the future Phase 6+ dashboard.
- Drafting a **public AI portfolio launch** asset for X.com (image + copy) per `AI_PORTFOLIO_STANDARD.md`.
- Producing a **trade-card visual** (chart + card layout) that goes beyond the plain-text generator.
- Running a **design critique** on anything visual the fund eventually produces.
- Defining a **brand-spec.md** if/when AI Fund gets a visual identity (colors, type, voice).

## Setup in AI Fund
Installation is optional — most of the value is the protocol, which Claude can follow without the upstream files. If you want the upstream toolchain:

```bash
# Optional. Requires Node 18+ and ffmpeg.
npx skills add alchaincyf/huashu-design
```

This drops a Playwright-renderer toolchain, html2pptx exporter, and starter components (iPhone bezel, browser chrome, deck stage). The renderer overlaps with the project's existing Playwright install — do not install a separate Playwright stack. If invoking the upstream Python renderer, point it at `/Users/kdawg/ai-fund/.venv/bin/python`.

## Usage patterns (AI-Fund-specific)

1. **Brand Asset Protocol → AI Fund brand-spec.** Today there is no `brand-spec.md`. When asked to produce one, follow the upstream rule: do NOT invent colors. Sources of truth:
   - Existing `wealthsimple_*.png` screenshots (broker context).
   - `tqqq_*.png` (chart aesthetic the client is already using).
   - The plain-text trade-card format in `AI_PORTFOLIO_STANDARD.md` (the *real* current brand).
   Output: `/Users/kdawg/ai-fund/brand-spec.md` with CSS variables, type pairing, voice notes. All future visual work uses `var(--brand-*)`. Never paint over the public AI portfolio standard's voice.

2. **Investor / partner deck.** When generating, use the Junior-Designer workflow: batch clarifying questions first (audience, length, tone, must-include data), grey-block first pass, iterate on actual data, then visual polish. Deck content must match the fund's real state — Phase 0, $11,654 CAD inception, advisor-assist mode, paper-validation window. Forbidden: implying live execution, implying multi-leg options access, implying any non-Wealthsimple-supported trade type.

3. **5-axis critique on output.** Apply when the client asks "is this any good?" on a visual:
   - Philosophical consistency: does it match `AI_PORTFOLIO_STANDARD.md` voice?
   - Visual hierarchy: does the eye land on the trade decision first, not the decoration?
   - Execution detail: real numbers? Real dates? No lorem ipsum?
   - Function: can the audience act on it?
   - Innovation: does it look like every other AI-fund Twitter thread, or like this fund?

4. **Dashboard mockups (Phase 6+).** When the Mac mini dashboard is ready to design, run huashu's iPhone/macOS-frame components to mock the daily-brief view and the trade-queue view *before* writing React. Deliver as static HTML in `/Users/kdawg/ai-fund/research/mockups/` for client review.

5. **Pair with taste-skill.** huashu produces deliverables (decks, mockups, MP4); taste-skill enforces the text/voice discipline inside those deliverables. Use them together — huashu's slide says *what* and taste-skill enforces *how it reads*.

## Integration with the 5-agent system
- **Claude** is the only agent that produces client-visible design work. Gemini may research brand examples for inspiration; Codex may compute the numbers that go on slides. The synthesis voice is Claude's.
- No voting-weight implication — this is downstream of trading decisions, not a decision input.
- Public AI portfolio publishing eventually involves Grok (since publishing is on X.com), but huashu's role is the artifact, not the channel.

## Risk gate / compliance
- Decks and public assets must NEVER claim execution that didn't happen. If the deck shows a "TQQQ +X%" tile, that number is paper-only (Phase 0) and labeled as such.
- VUN / XEQT positions visible in any portfolio screenshot in a deck — disclose they are permanent TFSA holds, not active trades.
- Single-leg options constraint: the deck cannot show a "covered strangle" or "iron condor" example as part of the fund's strategy. Only single-leg long calls, long puts, covered calls.
- FX cost (1.5% on USD): if a deck mentions cost basis, the FX leg has to be in the math.
- Forward-looking claims need disclaimer language per `AI_PORTFOLIO_STANDARD.md`.

## Gotchas
- **Language barrier.** Tell Claude the audience language up front, otherwise comments in generated HTML may come out in Chinese.
- **Naming confusion.** 画术 (huà shù, "drawing technique") sounds identical to 话术 (huà shù, "scripted persuasion / sales talk"). This skill is the *former*. It is not for writing sales copy in Chinese; don't try to make it draft Wealthsimple persuasion scripts.
- **Personal-use license on upstream.** Commercial use needs the author's permission. Check before publishing.
- **Heavy local toolchain** (ffmpeg, Playwright browsers, Node 18+). Most AI Fund work doesn't need it — the protocol discipline is most of the value.
- **Don't use huashu to design the trade-card text layout.** That schema is set by `AI_PORTFOLIO_STANDARD.md` and is non-negotiable. huashu sits above the schema (deck, brand, mockup), not inside it.
- **Quality cap.** Author flags that blank-canvas brand design caps ~60-65/100 quality without a designer in the loop. For high-stakes investor decks, treat huashu output as a strong draft, not the final.

## Reference
- Upstream: https://github.com/alchaincyf/huashu-design
- Site: https://www.huasheng.ai/
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/AI_PORTFOLIO_STANDARD.md` (governs all client-visible output)
  - `/Users/kdawg/ai-fund/PROTOCOL.md` (decision-flow + output format)
  - `/Users/kdawg/ai-fund/MANDATE.md` (fund mandate — what's in scope for decks)
  - `/Users/kdawg/ai-fund/research/mockups/` (suggested layout for future visual work)
  - `/Users/kdawg/ai-fund/wealthsimple_*.png`, `/Users/kdawg/ai-fund/tqqq_*.png` (visual reference material)


## --- Original Skill: skiper-ui ---

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


## --- Original Skill: styleui ---

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


## --- Original Skill: watermelon-ui ---

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


## --- Original Skill: taste-skill ---

# taste-skill (AI Fund anchor)

## What this is
Upstream Leonxlnx/taste-skill is a frontend-design taste filter for AI coding agents. It says: no purple gradients, no emoji-as-icon, no Inter-for-everything, prefer real spacing scales, prefer editorial CSS Grid layouts. The AI Fund has no frontend yet — the Phase 6+ Mac mini dashboard is roadmap, not code. So we honor the lineage (taste-as-anti-slop discipline) and re-anchor it to what AI Fund actually ships **today**: text. Trade cards. Daily briefs. The eventual X.com / public-AI-portfolio voice. The skill teaches Claude to write output that does not sound like default LLM output.

## When to trigger in AI Fund
- Generating a trade card via `tools/trade_card_generator.py` (the plain-text AI FUND TRADE CARD format in `AI_PORTFOLIO_STANDARD.md`).
- Writing the daily brief that lands in `reports/autonomous_daily_brief_YYYY-MM-DD.md`.
- Drafting any copy meant for the public AI portfolio (eventual X.com publishing).
- Rewriting client-facing output that came out vague, hedged, or engagement-baited.
- Phase 6+ — when the dashboard exists, the upstream taste-skill applies directly to its React code; keep this skill for the text layer.

## Setup in AI Fund
No install needed for the text discipline. If/when the dashboard is built:

```bash
# Future, only when Phase 6+ frontend exists:
cd /Users/kdawg/ai-fund/dashboard   # does not exist yet
npx skills add https://github.com/Leonxlnx/taste-skill
```

For now this skill lives entirely as Claude-side writing rules, enforced when generating `reports/*.md` and trade cards.

## Usage patterns (AI-Fund-specific)

1. **Trade card voice rules** (enforced when `trade_card_generator.py` output is reviewed):
   - Signal section: name the trigger in <= 12 words. No "interesting setup," no "potential opportunity."
   - Thesis: 3 sentences max. Concrete numbers (price, ratio, date). Skip adjectives.
   - Counter-thesis: must be sharp. "Earnings miss" is not enough; say *what miss* would kill it.
   - Trade plan: entry, target, stop, size, platform, order type — all numeric. No "around X" or "in the range of."
   - Portfolio fit: name the exposure %, the correlation, the cash impact.
   - Status: one of the 6 enums (`Watching / Recommended / Executed / Passed / Closed / Expired`). Never invent a 7th.

2. **Daily brief discipline.** The brief is information density per line, not narrative arc. Each section is data-first; commentary is bounded to one sentence per section. Forbidden:
   - "It's worth noting that..."
   - "The market appears to be..."
   - "Investors should consider..."
   - Bullet points that are entire paragraphs.
   - Closing motivational summary. The brief ends when the data ends.

3. **Anti-slop checklist** (apply before any client-facing output ships):
   - No emoji.
   - No em-dash-for-drama ("The trade — and this is the key — needs..."). Em-dashes are for parentheticals only.
   - No "Let me explain" / "Here's the thing" framing.
   - No three-bullet "key takeaways" tail when one sentence would do.
   - No "potentially," "could possibly," "might be worth" hedging when the agent has actual conviction. If conviction is low, *say* it's low and name the gap.
   - No "the AI agrees" / "the model is confident" anthropomorphic phrasing. The committee voted X; the score was Y; that's the language.

4. **Public AI portfolio voice (`AI_PORTFOLIO_STANDARD.md`).** When eventually publishing trades to X.com under the public-AI-portfolio brand:
   - Trade announcement = the trade card, untouched. No "exciting trade idea" preamble.
   - Honest losses are published with the same format as wins. Same enums.
   - Source attribution per agent: "Codex flagged options flow; Gemini cross-checked filings; Claude approved at 0.62 conviction." Not "the AI saw."

5. **Recovery from slop.** If a draft comes back vague: cut every sentence that doesn't carry a number, a name, or a decision. Whatever's left is the actual content.

## Integration with the 5-agent system
- **Claude** is the only voice the client sees. Gemini / Grok / Codex / DeepSeek+Gemma write internal artifacts in `data/agent_runs.csv` — those are raw and don't need taste discipline. The synthesis pass Claude does is where this skill applies.
- **Grok**, in particular, tends toward engagement-baited phrasing because of its source diet (X.com). When Claude synthesizes a brief that includes a Grok-driven signal, strip the social-media affect and reduce to: source, signal, conviction.
- No voting-weight implication. This skill is downstream of the vote, upstream of client output.

## Risk gate / compliance
- The voice rules NEVER soften the pinned hard rules. A trade card that recommends selling VUN or XEQT is wrong content; no amount of voice polish fixes that.
- "Confidence" language must match conviction score honestly. If the committee scored 0.51, the card says "low conviction" — not "compelling setup."
- Forward-looking statements need disclaimers per `AI_PORTFOLIO_STANDARD.md`. Voice discipline does not include dropping the disclaimer for flow.
- Compliance text (paper-mode, Phase 0, advisor-assist) appears verbatim where the standard requires it. Don't paraphrase it for tone.

## Gotchas
- This is text discipline, not a design system. When the Phase 6+ dashboard ships, switch to the upstream skill for the React side.
- Anti-slop ≠ terse-to-the-point-of-unclear. The goal is signal density, not minimalism for its own sake.
- Claude has trained biases toward the very phrasings this skill bans ("It's worth noting," "potentially," three-bullet endings). Expect to scrub on review, not just on first draft.
- The trade-card schema in `AI_PORTFOLIO_STANDARD.md` is the contract. Voice rules cannot reorder the 6 sections or rename them.
- Upstream Leonxlnx has multiple variants (minimalist, soft, brutalist). Map to AI Fund as: trade cards = brutalist (raw, no decoration); daily brief = minimalist (spacious, dense); public X posts = minimalist with verbatim trade-card body.

## Reference
- Upstream: https://github.com/Leonxlnx/taste-skill
- Site: https://tasteskill.dev
- AI Fund touchpoints:
  - `/Users/kdawg/ai-fund/AI_PORTFOLIO_STANDARD.md` (the 6-section card schema, public voice)
  - `/Users/kdawg/ai-fund/tools/trade_card_generator.py`
  - `/Users/kdawg/ai-fund/reports/autonomous_daily_brief_*.md`
  - `/Users/kdawg/ai-fund/PROTOCOL.md` (output format)
  - `/Users/kdawg/ai-fund/TRADE_LOG.md`


## --- Original Skill: impeccable-style ---

# Impeccable Style

## What this is
A design-discipline skill condensed from Paul Bakaus' Impeccable (impeccable.style — skill + 23 slash-commands + Chrome extension + CLI detector with 29 deterministic anti-pattern rules). The condensed worldview: what good design looks like, and what AI-generated / template-y UI gets wrong. For drop-shipping, the highest-leverage skill in the kit — most stores look generic, and looking generic kills trust, which kills conversion.

## When to trigger
- Pre-launch audit of any page: home, PDP, PLP, cart, checkout, order confirmation.
- Hero design review — does it look like every AI-generated SaaS hero?
- Copy review — does this PDP description read like ChatGPT wrote it?
- Picking palette + font pair for a new niche store.
- Before paying for traffic: every $ of ad spend lands on a page that signals "this is a real brand."

## What this gives a drop-shipping store

**The two registers — drop-shipping is brand register**
- **Brand register**: storefront, hero, PDP, marketing pages. Editorial, emotional, opinionated. The store has a *customer*, so design *for* that customer.
- **Product register**: admin tools, customer dashboards. Restrained, function-first. (Not the main surface here.)

**The 29 anti-patterns mapped to drop-shipping tells**

*Visual (these are the "yep, that's a drop-shipping store" tells):*
1. Inter + purple gradient + three feature cards → generic AI tell #1.
2. Hero stock image with overlaid headline + "Shop Now" / "Get Started" button.
3. Three identical USP icons (truck, shield, gift) in a row, no styling differentiation.
4. Pill buttons everywhere (`border-radius: 9999px`) regardless of context.
5. Nested cards on cards on cards. Single elevation per row.
6. Stock testimonials with placeholder avatars (or worse, AI-generated faces).
7. Trust-badge row of payment logos squeezed into the footer with no hierarchy.
8. Hero h1 in italic serif (Fraunces/Newsreader) as the whole brand — wrong if you're selling protein powder.
9. Uppercase letter-spaced eyebrow chip above h1 — banished outside specific editorial contexts.
10. Low-contrast button text on opaque button bg.
11. Carousel as the only above-the-fold content (avg engagement: 1 slide).
12. "Limited time" timer that resets on page refresh (also illegal in some jurisdictions).
13. Tilted product mockups under the hero copy. The Apple-lite tell.
14. Identical pricing-tier cards differentiated only by checkmark count.
15. Gradient text headlines that fail accessibility contrast checks.

*Prose / copy (the new monoculture in PDP descriptions):*
16. Em-dash sandwiches in every paragraph.
17. "Delve, leverage, unlock, navigate, robust, compelling, seamless."
18. Tricolons in every paragraph (X, Y, and Z).
19. "It's not just [product] — it's a lifestyle / movement / experience."
20. Closing motivational summary nobody reads.
21. AI-generated "5-star review" prose all reading identically.
22. "In today's fast-paced world…"
23. Bullet points that all start with the same verb (Discover, Experience, Enjoy).
24. CTA copy: "Get Started" / "Learn More" / "Discover More" on an ecommerce store.

*Conversion-killing visual tells:*
25. Sticky banner pop-up the second the page loads (kills first-impression trust).
26. Footer email-capture with no incentive ("Subscribe to our newsletter").
27. Reviews section that loads below 12s LCP.
28. ATC button below the fold on mobile PDP.
29. Same-niche stock photography (the "amazon supplement powder on white" photo every supplement brand uses).

## Multi-niche store builder fit
- Per-niche **DESIGN.md** committed alongside the store config. Tokens: color palette, type system, motion timing, copy register, CTA verbs.
- Reflex-reject during niche kickoff: name your first three palette/font instincts, reject them, pick the fourth.
- Cross-niche through-line: the audit checklist. Same 29 rules apply to supplements, apparel, electronics, pet — the *answers* differ; the *questions* don't.

## Install (Shopify Hydrogen)
This is a discipline, not a runtime library — no install required for the vocabulary. Optional CLI for CI checks:
```bash
npx impeccable detect app/
# Add to package.json scripts and gate pre-launch
```
Pairs with: `dev21-components` (vet picks against the 29), `emil-kowalski` (restraint principle), `ui-ux-pro-max` (palette/font picks pre-audit), `framer-motion` (motion choices the audit grades).

## Conversion-focused patterns

**The 23-command vocabulary** — use these verbs in prompts to direct the work:
`typeset` `colorize` `layout` `animate` `polish` `audit` `critique` `harden` `craft` `shape` `bolder` `quieter` `distill` `extract` (plus 9 more). Be specific: *"quieter the PDP description"*, *"audit this hero against the 29"*, *"extract tokens from the apparel niche brief."*

**Pre-launch audit checklist (every page)**
1. Open the URL in incognito on a throttled 4G phone.
2. Could this be any drop-shipping store? If yes, fail.
3. Hero: does the headline say something only this brand could say?
4. PDP: would a real customer write this description? Run `quieter` + `distill`.
5. Testimonials: real names, real photos, real specifics. Else cut the section entirely.
6. CTA verbs: "Add to bag" / "Shop the collection" — not "Get Started."
7. Run `npx impeccable detect` and resolve everything.

**Reflex-reject in prose**
Before keeping a sentence: name your first three instincts, reject them, write the fourth. Most AI-generated PDP copy is instinct #1.

## Gotchas
- Don't apply this to the admin/order-management surfaces — that's product register.
- Reflex-reject paralysis is real — use at strategy gates and pre-launch, not on every micro-decision.
- The vocabulary works only if used deliberately. "Audit this" needs a dimension.
- Don't ship without the audit. Ad spend lights money on fire if the LP fails the 29.
- License: impeccable.style content is Paul Bakaus' work; plugin terms at the source URL.

## Reference
- Site: https://impeccable.style
- Anti-patterns: https://impeccable.style/slop
- Docs: https://impeccable.style/docs
- GitHub: https://github.com/pbakaus/impeccable
- Related libs: `dev21-components`, `emil-kowalski`, `ui-ux-pro-max`, `framer-motion`


## --- Original Skill: ui-ux-pro-max ---

# UI UX Pro Max

## What this is
A reference catalog skill (`ui-ux-pro-max-skill.nextlevelbuilder.io`): searchable database of UI styles, color palettes, font pairings, and UX patterns. Lookup index — "give me a curated option" — not a code generator or a critique engine. For a multi-niche drop-shipping store builder, this is where brand parametrization starts: each niche gets a palette + font pair + UX pattern set, and the same Hydrogen component tree re-skins.

## When to trigger
- Spinning up a new niche store — need a palette and font pair before scaffolding.
- Building the `brand.tokens.css` for a niche (supplements vs apparel vs electronics vs pet).
- Picking UX patterns: empty cart, sold-out PDP, order confirmation, email-capture incentive.
- Choosing UI style direction: editorial, terminal, brutalist, minimal, playful.
- Locking the type system — display + body + numeric for prices.

## What this gives a drop-shipping store

**Five reference categories — the high-leverage ones**
1. **UI styles** — editorial, minimal, brutalist, playful, terminal. Pick per niche.
2. **Color palettes** — paired sets ready for Tailwind tokens. Include accessible contrast pairs.
3. **Font pairings** — display + body + numeric. Critical for price legibility on PDPs.
4. **UX patterns** — empty states, error recovery, address autocomplete, variant pickers, social-proof placements.
5. **(Charts)** — less relevant on the customer-facing side; useful only for the admin/back-office dashboard.

## Multi-niche store builder fit

**Per-niche brand recipes (starting points, not gospel)**

| Niche | UI style | Palette direction | Font pairing direction |
|-------|----------|-------------------|------------------------|
| **Supplements** | Clean medical / minimal | Off-white + deep navy + one accent (mint / amber). Avoid neon. | Modern sans (Söhne / Inter Tight / General Sans) + JetBrains Mono for dose/serving numerics. |
| **Apparel** | Editorial / fashion | Cream / charcoal / accent. Avoid pure white. High contrast. | Display serif (Editorial New / Fraunces) + neutral sans (Inter / Geist) + tabular for prices. |
| **Electronics** | Minimal / techy | Near-black + cool neutral + electric accent (cyan / lime). | Sans (Geist / Inter Tight) + IBM Plex Mono accents for specs / SKUs / prices. |
| **Pet** | Playful / friendly | Warm cream + saturated brand color (coral / sage / mustard) + soft neutral. | Rounded sans (DM Sans / Nunito) + slight personality display (Fraunces soft / Cooper) + sans numerics. |

**Token layer**
```css
/* brand.tokens.css — switch root data attr to swap niches */
[data-niche="supplements"] {
  --bg: #fafaf9; --fg: #0b1830; --accent: #5eead4;
  --font-display: "General Sans", system-ui; --font-num: "JetBrains Mono", monospace;
}
[data-niche="apparel"] {
  --bg: #faf7f2; --fg: #111; --accent: #8b6f47;
  --font-display: "Fraunces", Georgia; --font-num: "Inter Tight", system-ui;
}
```
Every Hero, PDP, Testimonial component reads from `var(--accent)`, `var(--font-display)`, etc. One component tree, four (or N) niches.

**UX patterns that move conversion**
- **Empty cart** — copy + product recommendations, not just "Your cart is empty."
- **Sold-out PDP** — "Notify me" email capture + suggested alternatives, never a dead end.
- **Variant unavailable** — gray-out with reason ("Out of stock") rather than removing the option.
- **Address autocomplete** at checkout — reduces drop-off ~10%.
- **Order confirmation** — order number + tracking promise + cross-sell + share incentive.
- **Email capture** — incentive (10% off / free shipping) before "subscribe" ask.

## Install (Shopify Hydrogen)
Install the upstream skill from `https://ui-ux-pro-max-skill.nextlevelbuilder.io` for the live searchable database. Until then, phrase requests as catalog queries:
- "From ui-ux-pro-max: three palettes for a pet supplements brand, warm + trustworthy."
- "From ui-ux-pro-max: font pairing for premium men's apparel, editorial register."
- "From ui-ux-pro-max: empty-state pattern for a sold-out PDP."

Fallback: known-good Tailwind palette generators (uicolors.app, realtimecolors.com), font pairing lookups (fontpair.co, type-scale.com).

## Conversion-focused patterns

**Niche palette + font lock — one query at niche kickoff**
Run a single catalog query before scaffolding. Lock the answer in `brand.tokens.css`. Don't revisit unless conversion data says so.

**Type pairing rules for ecommerce**
- Numerics in tabular-mono — prices, quantities, ratings. Avoids layout shift when values change.
- Display font does *one* job (h1, hero). Body sans does everything else.
- Max two type families. Three is a tell.

**Palette rules for ecommerce**
- One brand accent, one success-green, one error-red. Done.
- High contrast on CTAs — minimum 4.5:1 against bg, ideally 7:1.
- Dark-mode optional — most drop-shipping converts on light. Don't burn time on dark unless data says so.

## Gotchas
- Landing page is a thin pitch — the installed skill is where the database lives.
- Not a code generator — hands you references; you implement in Hydrogen.
- Always cross-check catalog picks against `impeccable-style` (does this pick read as generic AI?).
- Niche templates are *starting points*. The customer + price point shift the right answer.
- Don't pick blindly. Three options, decide, move on.
- License/access: confirm at the source URL.

## Reference
- Site: https://ui-ux-pro-max-skill.nextlevelbuilder.io
- Related libs: `impeccable-style` (audit), `emil-kowalski` (polish + Vaul/Sonner/cmdk), `framer-motion` (motion tokens per niche), `dev21-components` (prebuilt sections to re-skin)


## --- Original Skill: frontend-design ---

This skill guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Apply creative forms like gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

## --- Original Skill: emil-kowalski ---

# Emil Kowalski Polish

## What this is
A design + libraries skill modeled on Emil Kowalski (Design Engineer at Linear, ex-Vercel). Three production-grade React libraries — **Sonner** (toasts), **Vaul** (drawers), **cmdk** (command palette) — plus the animations.dev course and a restraint principle: every animation, every micro-interaction must earn its place. For drop-shipping, this is the difference between a store that feels polished and one that feels templated.

## When to trigger
- PDP: "Added to cart" feedback, sold-out notify-me toast, variant-out-of-stock warning.
- Mobile cart drawer (slide-up sheet, not a full page).
- Size guide, shipping info, filter sheet on mobile — all Vaul.
- Desktop global product search — cmdk palette (`⌘K`).
- Order confirmation: success toast that stacks if multiple events fire.
- Any micro-interaction that currently feels harsh (no transition, jump-cut, sloppy easing).

## What this gives a drop-shipping store
- **Sonner** → swipeable toasts for ATC success, "Saved to wishlist", coupon-applied, "Item back in stock." Mobile-friendly (swipe-to-dismiss), stackable, accessible.
- **Vaul** → mobile cart drawer, size guide, filter/sort sheet, variant picker on small screens, address-add sheet at checkout. Native-feeling drag-to-dismiss with snap points.
- **cmdk** → desktop power-user search: products, collections, recent orders, support topics. Reduces clicks on large catalogs.
- **Restraint principle** → audit gate: every animation, toast, drawer answers "does this help convert or is it noise?" If noise, cut it.

## Multi-niche store builder fit
All three libraries are unstyled-ish and theme via CSS vars. Define toast/drawer tokens per niche in `brand.tokens.css`:
```css
[data-niche="supplements"] { --toast-bg: #fff; --toast-border: #e5e7eb; }
[data-niche="apparel"]     { --toast-bg: #111; --toast-border: #2a2a2a; }
[data-niche="pet"]         { --toast-bg: #fef3c7; --toast-border: #f59e0b; }
```
Same Sonner/Vaul/cmdk components, different brand-feel per store. Easings stay consistent across niches — restraint is the through-line.

## Install (Shopify Hydrogen)
```bash
npm install sonner vaul cmdk
```
Pairs with: `framer-motion` (other motion), `dev21-components` (prebuilt sections), `impeccable-style` (audit pass).

## Conversion-focused patterns

**Signature easings (drop into every animation)**
- `[0.22, 1, 0.36, 1]` — soft landing (easeOutQuint). Number reveals, toasts.
- `[0.32, 0.72, 0, 1]` — Vaul-default. Drawer/sheet opens.
- Springs: `{ stiffness: 400, damping: 28 }` snappy hover; `{ stiffness: 350, damping: 32 }` modal/drawer.
- Durations: 120–180ms hovers, 220–300ms opens, 500–700ms number flips.

**Sonner — Added to cart toast**
```tsx
import { Toaster, toast } from "sonner";
// In root layout:
<Toaster position="bottom-right" richColors closeButton />
// On ATC success:
toast.success("Added to cart", {
  description: `${product.title} • ${variant.title}`,
  action: { label: "View cart", onClick: () => openCart() },
});
```

**Vaul — Mobile cart drawer**
```tsx
import { Drawer } from "vaul";
<Drawer.Root open={cartOpen} onOpenChange={setCartOpen} snapPoints={[0.5, 0.95]}>
  <Drawer.Portal>
    <Drawer.Overlay className="fixed inset-0 bg-black/40" />
    <Drawer.Content className="fixed bottom-0 inset-x-0 rounded-t-2xl bg-white">
      <div className="mx-auto my-3 h-1.5 w-12 rounded-full bg-zinc-300" />
      <CartLines />
      <CartFooterCTA />
    </Drawer.Content>
  </Drawer.Portal>
</Drawer.Root>
```

**Vaul — Size guide sheet**
Snap points `[0.4, 0.9]` so user can peek then expand. Drag handle visible.

**cmdk — Product search palette (desktop)**
```tsx
import { Command } from "cmdk";
<Command.Dialog open={open} onOpenChange={setOpen}>
  <Command.Input placeholder="Search products, collections…" />
  <Command.List>
    <Command.Empty>No results.</Command.Empty>
    <Command.Group heading="Products">
      {products.map(p => (
        <Command.Item key={p.id} onSelect={() => navigate(p.url)}>
          {p.title} <span className="ml-auto text-xs">${p.price}</span>
        </Command.Item>
      ))}
    </Command.Group>
  </Command.List>
</Command.Dialog>
```

**Restraint audit (apply before launch)**
1. Does the toast tell the user something they couldn't see? (Else cut.)
2. Does the drawer need full-screen, or is a sheet enough?
3. Is this animation guiding attention or stealing it?
4. Honor `prefers-reduced-motion` everywhere.

## Gotchas
- All three are unstyled-ish — budget Tailwind work to match each niche's brand.
- Vaul drag-dismiss on desktop is trackpad-only — always provide a close button.
- Sonner stacking: cap at 3 visible; ATC + coupon + back-in-stock can collide on PDPs.
- cmdk works best on desktop — on mobile, route search to a full page or Vaul sheet.
- Shopify Oxygen / worker compat: all three are client-only — wrap in `<ClientOnly>` or dynamic import where needed.
- Don't toast every event. ATC: yes. Page view: no. Threshold: completions and state changes only.
- License: MIT across Sonner, Vaul, cmdk.

## Reference
- Site: https://emilkowal.ski
- Sonner: https://sonner.emilkowal.ski
- Vaul: https://vaul.emilkowal.ski
- cmdk: https://cmdk.paco.me
- Course: https://animations.dev
- Related libs: `framer-motion` (runtime), `dev21-components` (sections), `impeccable-style` (anti-slop)


## --- Original Skill: framer-motion ---

# Framer Motion (now: Motion)

## What this is
MIT-licensed React animation library by the Framer team. Install: `npm install motion`, import from `motion/react`. Hybrid engine — JS-orchestrated, GPU-accelerated where possible. Works inside Shopify Hydrogen (Remix) and Next.js, runs fine on Shopify Oxygen workers since it's a client component.

## When to trigger
- PDP: image gallery transitions, variant swap fade, ATC button success burst, price flip on variant change.
- Hero: scroll-triggered headline reveal, parallax product mockup, number tickers for social proof (reviews, customers, units sold).
- Collection: staggered product card entrance, hover lift, quick-shop modal.
- Cart: drawer slide (or pair with Vaul), line-item add/remove with AnimatePresence, success toast.
- Global: sticky header that condenses on scroll, scroll progress bar, exit-intent modal.

## What this gives a drop-shipping store
- **Hero fade-in + parallax** — headline lands after image settles, scrolls slow.
- **ATC burst** — button scales + emerald flash + Sonner toast on success.
- **Product gallery** — crossfade between images on variant change.
- **Testimonial carousel** — auto-advance with pause-on-hover, swipeable on mobile.
- **Sticky condensing header** — full height at top, 56px on scroll.
- **Cart line-item animations** — slide-in on add, slide-out + height collapse on remove.
- **Number tickers** — "12,847 happy customers" counts up on viewport entry.

## Multi-niche store builder fit
Define motion tokens per niche brand:
```ts
// brand.motion.ts
export const motionTokens = {
  supplements: { ease: [0.22, 1, 0.36, 1], duration: 0.4 }, // clean, medical
  apparel:     { ease: [0.65, 0, 0.35, 1], duration: 0.6 }, // editorial slower
  electronics: { ease: [0.4, 0, 0.2, 1],   duration: 0.3 }, // crisp, snappy
  pet:         { type: "spring", stiffness: 280, damping: 18 }, // playful bounce
};
```
Every component reads from the active niche's tokens — same Hero component, four different feels.

## Install (Shopify Hydrogen)
```bash
npm install motion
# import from "motion/react"  (legacy `framer-motion` aliases still work)
```
Pairs with: Sonner (toasts), Vaul (drawers), cmdk (palette) — see `emil-kowalski`.

## Conversion-focused patterns

**Add-to-cart success burst (PDP)**
```tsx
const [added, setAdded] = useState(false);
<motion.button
  whileTap={{ scale: 0.97 }}
  animate={added ? { backgroundColor: "#10b981" } : {}}
  transition={{ type: "spring", stiffness: 400, damping: 22 }}
  onClick={async () => { await addToCart(); setAdded(true); toast.success("Added to cart"); }}
>
  {added ? "Added" : "Add to Cart"}
</motion.button>
```

**Hero scroll fade-in**
```tsx
<motion.h1
  initial={{ opacity: 0, y: 24 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-100px" }}
  transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
>
  The supplement that actually works.
</motion.h1>
```

**Sticky condensing header**
```tsx
const { scrollY } = useScroll();
const height = useTransform(scrollY, [0, 120], [80, 56]);
const bg = useTransform(scrollY, [0, 120], ["rgba(255,255,255,0)", "rgba(255,255,255,0.95)"]);
<motion.header style={{ height, backgroundColor: bg }} className="fixed top-0 inset-x-0 backdrop-blur z-50" />
```

**Product card hover (Collection)**
```tsx
<motion.div
  whileHover={{ y: -4 }}
  transition={{ type: "spring", stiffness: 400, damping: 28 }}
  className="rounded-xl bg-white overflow-hidden"
>
  <motion.img whileHover={{ scale: 1.04 }} transition={{ duration: 0.4 }} src={img} />
</motion.div>
```

**Number ticker on viewport entry**
```tsx
function Ticker({ to }: { to: number }) {
  const mv = useMotionValue(0);
  const rounded = useTransform(mv, v => Math.round(v).toLocaleString());
  return (
    <motion.span
      onViewportEnter={() => animate(mv, to, { duration: 1.4, ease: [0.22, 1, 0.36, 1] })}
    >{rounded}</motion.span>
  );
}
```

**Staggered product grid entry**
```tsx
const grid = { show: { transition: { staggerChildren: 0.05 } } };
const card = { hidden: { opacity: 0, y: 12 }, show: { opacity: 1, y: 0 } };
<motion.div variants={grid} initial="hidden" whileInView="show" viewport={{ once: true }} />
```

## Gotchas
- Package renamed: `motion`, import from `motion/react`. Legacy `framer-motion` still works.
- Mobile LCP — defer non-critical animations until after first paint; lazy-load below-the-fold sections.
- `AnimatePresence` children need stable `key`. #1 bug.
- Honor `useReducedMotion()` — affects 10%+ of users; legally required in some regions.
- `layout` animations re-measure every frame; expensive on large collection grids. Use `layout="position"`.
- Shopify Oxygen runs on workers — wrap motion components in client boundaries; don't import at module top in loaders.
- Bundle: ~50kb gz; tree-shakeable. Use `LazyMotion` + `domAnimation` features import to drop ~30kb.
- License: MIT.

## Reference
- Docs: https://motion.dev/docs/react
- GitHub: https://github.com/framer/motion
- Related libs: `emil-kowalski` (Sonner/Vaul/cmdk), `dev21-components` (prebuilt sections), Hydrogen's `<CartForm>` for cart-state integration

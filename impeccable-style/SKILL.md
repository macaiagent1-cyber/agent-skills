---
name: impeccable-style
description: Anti-AI-slop design discipline (Paul Bakaus' Impeccable — 29 anti-pattern detectors, "reflex-reject" practice, vocabulary of 23 design commands). Critical for drop-shipping Shopify Hydrogen stores because most drop-shipping sites scream "AI-generated Shopify template" — purple gradients, Inter everywhere, three nested cards, "Get Started" CTAs, em-dash-laden copy. Trigger before launch on every page, every hero, every PDP, every collection. Keywords: anti-slop, anti-pattern, audit, critique, design review, AI tells, generic Shopify look, drop-shipping, Shopify, Hydrogen, product page, hero, CTA, conversion, ecommerce, store, polish, brand register. Does NOT cover: runtime animation (`framer-motion`), component libraries (`dev21-components`, `emil-kowalski`), or chart/palette references (`ui-ux-pro-max`) — this is a critique and vocabulary layer.
---

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

---
name: ui-ux-pro-max
description: Reference catalog skill — a searchable database of UI styles, color palettes, font pairings, and UX patterns. The brand-parametrization layer for a multi-niche drop-shipping Shopify Hydrogen store builder. Trigger when starting a new niche (supplements, apparel, electronics, pet) and need to pick palette + type system + UX patterns that fit the customer, not the model's average default. Keywords: palette, font pairing, design tokens, brand, niche, UX pattern, empty state, drop-shipping, Shopify, Hydrogen, product page, hero, CTA, testimonial, conversion, ecommerce, store, multi-niche. Does NOT cover: code generation, animation (use `framer-motion`), critique (use `impeccable-style`), or runtime components — it's a lookup layer feeding the other skills.
---

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

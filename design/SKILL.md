---
name: design
description: >
  Use for all visual design tasks: creating original art/posters/visuals (canvas), applying
  Anthropic brand colors and typography (brand), or generating visual themes/palettes (theme).
  Triggers when: "create a poster", "design something", "make art", "apply brand colors",
  "brand guidelines", "Anthropic style", "create a theme", "color palette", "visual identity",
  "make it look like Anthropic", or any request for visual design output. Creates .png, .pdf,
  and styled artifacts.
---

# Design

Three visual design modes: original art creation, brand application, and theme generation.

## Mode Selection

```
Creating original art, poster, or visual piece?  → CANVAS mode
Applying Anthropic brand to existing work?        → BRAND mode
Generating a theme/color palette/visual system?   → THEME mode
```

---

## CANVAS MODE
*Create original visual art — museum/magazine quality, not amateur*

Output: `.png` and/or `.pdf` files + `.md` design philosophy file.

### Step 1: Design Philosophy

Create a visual philosophy (not a layout or template) — an aesthetic movement to be expressed visually.

**Name the movement** (1-2 words): e.g., "Brutalist Joy", "Chromatic Silence", "Metabolist Dreams"

**Write 4-6 paragraphs covering:**
- Space and form
- Color and material
- Scale and rhythm
- Composition and balance
- Visual hierarchy

**Critical guidelines:**
- Each design aspect mentioned once — no redundancy
- Emphasize craftsmanship repeatedly: "meticulously crafted", "painstaking attention", "master-level execution"
- Leave creative space for interpretation while staying specific about aesthetic direction

**Philosophy examples:**
- "Concrete Poetry" — Massive color blocks, sculptural typography, Brutalist spatial divisions, Polish poster energy
- "Chromatic Language" — Color as primary information system, geometric precision, Josef Albers meets data viz
- "Analog Meditation" — Paper grain, ink bleeds, vast negative space, Japanese photobook aesthetic
- "Geometric Silence" — Grid-based precision, dramatic negative space, Swiss formalism meets Brutalist honesty

Output philosophy as `.md` file.

### Step 2: Deduce the Subtle Reference

Before creating the canvas, identify the conceptual thread from the request. This is the soul woven invisibly into the work — a sophisticated reference someone familiar with the subject will feel intuitively, while others simply experience a masterful composition.

Think like a jazz musician quoting another song — only those who know will catch it, but everyone appreciates the music.

### Step 3: Create the Canvas

Use the philosophy to craft the piece with expert craftsmanship.

**Technical requirements:**
- Use repeating patterns and perfect shapes
- Sparse, clinical typography — text is minimal and visual-first
- Nothing falls off page, nothing overlaps — check margins carefully
- Use different fonts; search `./canvas-fonts` directory for options
- Typography as art: if work is abstract, bring font onto the canvas as visual element

**Quality bar:** Must look like it took countless hours. Someone at the absolute top of their field labored over every detail. If you can show it to people as proof of expertise, the quality is right.

**For non-art content (movie, game, book):** Remain sophisticated. Never cartoony or amateur.

### Step 4: Refine

User has already said: "It isn't perfect enough. It must be pristine, a masterpiece of craftsmanship."

Refine what exists — don't add more graphics. Make existing composition more cohesive. Before calling a new function or drawing a new shape, ask: "How can I make what's already here more of a piece of art?"

Output: single `.pdf` or `.png` + design philosophy `.md`

---

## BRAND MODE
*Apply Anthropic's official brand colors and typography*

### Colors

**Main:**
- Dark: `#141413` — Primary text, dark backgrounds
- Light: `#faf9f5` — Light backgrounds, text on dark
- Mid Gray: `#b0aea5` — Secondary elements
- Light Gray: `#e8e6dc` — Subtle backgrounds

**Accent:**
- Orange: `#d97757` — Primary accent
- Blue: `#6a9bcc` — Secondary accent
- Green: `#788c5d` — Tertiary accent

### Typography
- **Headings (24pt+):** Poppins (Arial fallback)
- **Body text:** Lora (Georgia fallback)

### Application Rules
- Headings ≥ 24pt → Poppins
- Body text → Lora
- Non-text shapes → cycle through orange, blue, green accents
- Smart color selection based on background (dark text on light, light text on dark)
- Falls back to Arial/Georgia automatically if custom fonts unavailable

---

## THEME MODE
*Generate visual themes, color palettes, and design systems*

**Use when:** Creating a cohesive visual identity for a product, app, or brand from scratch.

### Process

**1. Understand the context:**
- What is this for? (app, website, marketing, product)
- What feeling/tone should it evoke? (professional, playful, minimal, bold)
- Any existing colors or constraints to respect?
- Who is the audience?

**2. Generate the palette:**
- Primary color (dominant brand color)
- Secondary color (supporting, used less)
- Accent color (CTAs, highlights)
- Neutral scale (backgrounds, text, borders — usually 3-5 shades)
- Semantic colors (success: green, error: red, warning: amber, info: blue)

**3. Typography pairing:**
- Heading font (personality, weight)
- Body font (readability, comfort)
- Mono font (code, technical — if needed)

**4. Design tokens:**
```
--color-primary: #...
--color-secondary: #...
--color-accent: #...
--color-background: #...
--color-text: #...
--font-heading: 'FontName', fallback
--font-body: 'FontName', fallback
--spacing-unit: 8px
--border-radius: 4px / 8px / 16px
```

**5. Deliver as:**
- CSS/design tokens file
- Color swatches with hex values and usage guidance
- Sample component showing the theme applied (button, card, heading)

**Quality check:** Does the palette work in both light and dark contexts? Is there enough contrast for accessibility (4.5:1 for body text)?

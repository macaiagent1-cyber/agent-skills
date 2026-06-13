---
name: framer-motion
description: Runtime React animation library (now published as `motion`, formerly `framer-motion`). The motion layer for drop-shipping Shopify Hydrogen stores — hero scroll fade-ins, product image transitions, add-to-cart burst feedback, variant switcher animations, sticky-on-scroll headers, testimonial carousels, price reveal tickers. Trigger when animating any PDP, collection, hero, cart, or CTA surface. Keywords: animate, motion, AnimatePresence, spring, stagger, scroll, hero, product page, add to cart, cart drawer, testimonial carousel, drop-shipping, Shopify, Hydrogen, conversion, ecommerce, store. Does NOT cover: CSS-only transitions, complex drawer gestures (use Vaul from `emil-kowalski`), Storefront API state, or page transitions (use Remix's view transitions).
---

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

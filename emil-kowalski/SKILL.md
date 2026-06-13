---
name: emil-kowalski
description: Polish layer for drop-shipping Shopify Hydrogen stores — Emil Kowalski's libraries (Sonner toasts, Vaul drawers, cmdk command palette) and his restraint principle / signature easings. Trigger when implementing "Added to cart" toasts, mobile cart drawers, size-guide / filter / variant sheets, desktop product search palettes, or any micro-interaction that needs to feel crafted rather than slapped together. Keywords: Sonner, Vaul, cmdk, toast, drawer, command palette, cart drawer, mobile sheet, product search, drop-shipping, Shopify, Hydrogen, product page, conversion, ecommerce, store, restraint, polish, easings. Does NOT cover: runtime animation primitives (use `framer-motion`), hero theatrics, or product-grid layout — these are focused interaction primitives.
---

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

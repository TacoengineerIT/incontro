# Design System Strategy: The Midnight Salon

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Digital Aperitivo."** 

Italian university life is defined by the transition from the rigors of the *aula* (classroom) to the warmth of the *piazza* at dusk. This system moves away from the cold, clinical "SaaS" look and instead embraces a high-end editorial feel that mimics a dimly lit, premium lounge. We achieve this through **Organic Layering**—breaking the rigid 12-column grid in favor of intentional asymmetry, overlapping elements, and extreme radius values that feel tactile and "human." 

Instead of a flat app, we are building a series of floating, frosted planes that feel as though they are suspended in a deep, nocturnal space.

---

## 2. Colors & Surface Philosophy
We are moving beyond "Dark Mode" into "Deep Mode." The palette utilizes a rich `#131313` base, accented by electric violets and Mediterranean teals.

### The Palette
- **Primary (Accent):** `primary` (#c4c0ff) — Use for high-intent actions and "Aha!" moments.
- **Secondary:** `secondary` (#5cdbc0) — Use for social validation (likes, matches, active states).
- **Surface Strategy:** 
    - `surface-container-lowest` (#0e0e0e): For the "void" or deep background.
    - `surface-container-high` (#2a2a2a): For interactive cards and floating headers.

### The "No-Line" Rule
**Strict Prohibition:** Do not use 1px solid borders to separate content. 
Structure must be defined by **Tonal Shifts**. To separate a "Story" bar from the "Feed," place the Story bar on `surface-container-low` against a `surface` background. The eye should perceive the edge through color variance, not a drawn line.

### The "Glass & Gradient" Rule
To elevate the "Tinder-style" cards, apply a subtle linear gradient: `primary` (#c4c0ff) to `primary-container` (#8781ff) at a 135° angle. For floating navigation or overlays, use **Glassmorphism**: `surface-variant` at 60% opacity with a 20px `backdrop-blur`.

---

## 3. Typography: Editorial Sophistication
While the request specified Poppins, we are elevating the hierarchy using **Plus Jakarta Sans** for high-impact displays and **Be Vietnam Pro** for legible body text, creating a custom editorial feel that feels "University-Premium."

- **Display (The Statement):** `display-lg` (3.5rem). Use for welcome screens or major milestones. Tight letter-spacing (-0.02em).
- **Headline (The Story):** `headline-md` (1.75rem). Use for user names on cards. 
- **Body (The Connection):** `body-md` (0.875rem). Optimized for long-form bios or chat threads. Increased line-height (1.6) to ensure readability under low-light conditions.

---

## 4. Elevation & Depth: Tonal Layering
We do not use "Shadows" in the traditional sense; we use **Ambient Glows**.

- **The Layering Principle:** Depth is achieved by stacking. A `surface-container-highest` card sits on a `surface-container-low` background. This creates a "soft lift."
- **Ambient Shadows:** For the Tinder-style cards, use an extra-diffused shadow:
    - Offset: 0px 20px | Blur: 40px | Color: `primary` at 8% opacity. This mimics the glow of a neon sign in a dark Italian alley.
- **The "Ghost Border" Fallback:** If a container requires more definition (e.g., an input field), use the `outline-variant` token at **15% opacity**. It should be felt, not seen.

---

## 5. Components & Interaction

### Cards (The "Incontro" Swipe)
- **Radius:** Must use `xl` (3rem / 48px) for the outer container and `lg` (2rem / 32px) for internal elements (images/buttons).
- **Styling:** Forbid dividers. Separate the user's name from their bio using a `spacing-4` vertical gap.
- **Shadow:** Use the Ambient Glow (as defined above) to make the card feel like it's hovering over the feed.

### The Stories Bar (Instagram-Inspired)
- **Container:** `surface-container-low`.
- **Active State:** Instead of a simple ring, use a `primary` to `secondary` gradient stroke (2px) with a 4px "air gap" (padding) between the stroke and the user's avatar.

### Buttons (Tactile Luxury)
- **Primary:** `primary-container` background with `on-primary-container` text. Radius: `full` (9999px).
- **Secondary (Glass):** `surface-bright` at 20% opacity with a `backdrop-blur` of 12px. This creates a sophisticated, non-intrusive secondary action.

### Input Fields
- **Base:** `surface-container-highest`. 
- **State:** When focused, the "Ghost Border" increases to 40% opacity of the `primary` color. No sharp edges—radius must be `md` (1.5rem) minimum.

---

## 6. Do's and Don'ts

### Do
- **Embrace Asymmetry:** Let cards bleed off the edge of the screen slightly to suggest more content (horizontal scrolling).
- **Use "Italian" White Space:** Be generous with the spacing scale. Use `spacing-8` (2.75rem) between major sections to let the UI breathe.
- **Micro-animations:** Every "Match" or "Incontro" should trigger a soft `primary` glow expansion from the center of the screen.

### Don't
- **No Pure Black:** Never use `#000000`. Use `surface-container-lowest` (#0e0e0e) to maintain the "warm" dark-mode feel.
- **No Dividers:** If you feel the need to add a line, add `spacing-6` of empty space instead.
- **No Default Shadows:** Avoid the "black drop shadow" preset. It muddies the deep grey surfaces. Always tint your shadows with the `primary` hue.
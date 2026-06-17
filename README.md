## What is this?

Lucid is a from-scratch browser and web protocol built with one core belief: the web should work for users, not against them.

The modern web is a surveillance machine. Every page you visit runs arbitrary JavaScript, phones home to dozens of tracking endpoints, fingerprints your device, and sells that data to brokers you've never heard of. The browser is supposed to be your window to the internet — instead it's become a one-way mirror.

Lucid is an attempt to fix that at the protocol level, not the policy level.

---

## The Problem With Fixing The Existing Web

Every privacy tool built on top of the existing web is fighting a losing battle. Ad blockers get circumvented. CSP headers get misconfigured. HTTPS was opt-in for a decade. The reason these solutions are fragile is that they're policies layered on top of a foundation that was never designed with privacy in mind.

You cannot fix a foundation with paint.

Lucid doesn't try to fix HTML, CSS, and JavaScript. It replaces them entirely with a stack designed from first principles where privacy and security are structural properties, not features you toggle on.

---

## How It Works

### The Stack

Lucid has three layers that replace the entire web frontend stack:

**DSL** — replaces HTML and CSS. Describes structure, layout, and style. Contains no executable logic. Every capability a page has must be declared here upfront, like an Android permissions manifest. If it isn't declared, it physically cannot happen.

**Code-Behind** — replaces JavaScript. Runs in a WASM sandbox. Can only call the capabilities declared in the DSL. Cannot touch the filesystem, clipboard, network, or anything else that wasn't explicitly granted by the user.

**Runtime Engine** — the browser itself. Owns layout, rendering, clipping, and input dispatch. WASM never touches rendering directly. The engine is deterministic and simple by design.

### The Permission System

Stolen directly from Android's permission model and made stricter.

When you visit a page, it declares what it needs:

```
capabilities FileManager {
    Files {
        open()
        save()
        delete()
    }
}
```

The user sees this. The user can deny any or all of it. If the user denies file access, the page doesn't get a CORS error or a permission denied exception — the WASM import table simply doesn't contain those functions. There is nothing to exploit.

Pages that try to function without granted permissions can refuse to render. That's the maximum retaliation available to them.

### No Cross-Site Anything

Sites get their own sandboxed local storage. There is no shared identifier, no cross-site cookie, no cohort tracking. A network of sites sharing user identifiers gets nothing useful because every identifier is scoped to the site that issued it.

### Identity Without Tracking

Account creation uses RSA-based site-scoped identifiers. The site gets a cryptographic proof that you are the same user who was here before. It does not get your name, your email, your IP history, or anything that correlates across sites unless you explicitly provide it through the user-controlled profile system.

The profile system inverts the current model:

**Today:** site extracts what it can → decides what to share with brokers

**Lucid:** user owns their data → user decides what to forward → site receives only what was approved

### Mandatory Encryption

There is no HTTP equivalent. All transport is encrypted binary from the first byte. Unencrypted communication is not a degraded mode, it is not a mode at all.

### The RPC System

Server-to-client data uses a typed binary RPC system with mandatory versioning. Every schema has a version number. Schema mismatches are loud immediate failures, not silent runtime corruption. The browser understands primitive types including dates, so there is no per-site date format chaos.

---

## Why WASM

WASM gives us a sandboxed execution environment with a well-defined import/export surface. The capabilities a page declared in the DSL map directly to the WASM import table the runtime generates. A page that declared no network capability gets a WASM module with no network imports. This is not a policy check at runtime. It is a structural impossibility at compile time.

Crypto miners, session replay scripts, keyloggers, and supply chain attacks through npm-style dependencies all become significantly harder or outright impossible depending on what permissions a user has granted.

---

## Current Status

Early prototyping stage. The rendering pipeline is being built in C3 using raylib. Current progress:

- Rich text parsing with bold, italic, bold-italic, and emoji support including ZWJ sequences and Fitzpatrick skin tone modifiers
- Scene graph with measure, layout, clip, and render passes
- UDim2-style layout system inspired by Roblox GUIs — deterministic, one-way, no constraint solving
- Dirty flag system for efficient pass invalidation

The DSL compiler, WASM runtime integration, and network protocol are next.

---

## What This Is Not

- This is not a Brave-style privacy layer on top of Chromium
- This is not a tor browser
- This is not trying to be backwards compatible with the existing web
- This is not trying to convince existing websites to change anything

Existing websites stay on the existing web. Lucid is a parallel ecosystem for people who want to build and browse without handing their users to data brokers.

---

## Who Is This For

**Users** who are tired of being the product.

**Developers** who want to build experiences without being forced to integrate seventeen surveillance SDKs to monetize.

**Anyone** who thinks the web made a wrong turn somewhere around 2010 and wants to see what it looks like if you start over with what we know now.

---

## Get Involved

The project is in early prototyping. If any of this resonates — whether you want to contribute code, think through protocol design, stress test the security model, or just watch the thing get built — you're welcome here.

Questions, challenges, and devil's advocate arguments are especially welcome. The best time to find holes in a security model is before anyone depends on it.

---

## Licenses

- **Lucid Browser**:
Lucid Browser by Cody Tilkins
Licensed under AGPL-3.0
https://www.gnu.org/licenses/agpl-3.0.txt

Source: https://github.com/tilkinsc/project-lucid

- **Inter Font**:
Inter font by Rasmus Andersson
Licensed under SIL Open Font License 1.1
https://openfontlicense.org/open-font-license-official-text/

Source: https://github.com/rsms/inter

- **Emoji Assets**:
Emoji graphics by Twemoji (Twitter/X contributors)
Licensed under CC BY 4.0
https://creativecommons.org/licenses/by/4.0/

Source: https://github.com/twitter/twemoji

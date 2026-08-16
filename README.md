# Parse-Gtag-Ordered-dataLayer-Array-to-Find-Object-by-Index

A custom [Google Tag Manager (GTM)](https://tagmanager.google.com/) **variable** template (`.tpl`) that reads a value out of a `dataLayer` entry pushed by the `gtag()` function's internal **array-based ("command queue") format** — a fundamentally different shape than the plain object format (`{event: 'purchase', ...}`) most GTM Data Layer Variables expect. This template exists specifically to make that array-based data accessible to GTM without needing a Custom JavaScript variable per payload field.

## Why this is needed: two different dataLayer shapes

When code calls GTM's native `dataLayer.push({...})` directly, the pushed value is a flat object, e.g.:

```javascript
dataLayer.push({ event: 'purchase', ecommerce: { transaction_id: 'T123', value: 99.99 } });
```

GTM's built-in **Data Layer Variable** type reads this shape natively via a dot-notation key path (e.g., `ecommerce.value`).

But when code instead calls the **`gtag()`** function — the wrapper function used by Google Ads, GA4's `gtag.js` snippet, and various other Google tagging implementations — like this:

```javascript
gtag('event', 'purchase', { transaction_id: 'T123', value: 99.99 });
```

`gtag()` doesn't push a flat object. Internally, it converts its own arguments into an **array-like `arguments` object** and pushes *that* onto `dataLayer` — so the resulting entry in `window.dataLayer` looks structurally more like:

```javascript
["event", "purchase", { transaction_id: "T123", value: 99.99 }]
```

— accessible only by **numeric index** (`[0]`, `[1]`, `[2]`, ...), not by a `event`/`ecommerce` key path. This is sometimes referred to as "command queue" syntax, mirroring how `gtag()`/`ga()` have historically queued commands. A standard GTM Data Layer Variable can't read into this shape at all — this template's entire purpose is to search `dataLayer` for the right array-shaped entry and pull out whichever indexed element you need (almost always index `2`, the payload/parameters object).

## How it works

The template's sandboxed JavaScript (`___SANDBOXED_JS_FOR_WEB_TEMPLATE___`) does the following:

1. Takes a full, read-only snapshot of `window.dataLayer` via `copyFromWindow('dataLayer')`.
2. Reads four configured field values (see below).
3. **Guards execution behind the current triggering event.** Only proceeds if `dataLayerCurrentEvent` (intended to be wired to GTM's built-in `{{Event}}` variable) equals `eventValue` — i.e., this variable only actually searches the data layer when it's being evaluated in the context of the specific event it's looking for (e.g., only when the tag/trigger currently firing is itself the `'purchase'` event). This is the template's own stated mechanism for avoiding unnecessary console errors on unrelated tag fires.
4. **Searches `dataLayer` backward (most recent first)** for the last entry where `dataLayer[i][0] === eventName` and `dataLayer[i][1] === eventValue` — e.g., the most recent array entry whose first two elements are `"event"` and `"purchase"`.
5. Returns `returnResult[eventIndex]` — by default, index `2`, which for a typical `gtag('event', 'purchase', {...})` call is the parameters/payload object itself.

## Template fields

| Field | Display name | Default | Purpose |
|---|---|---|---|
| `eventName` | *eventName (index 0 - likely 'event')* | `event` | The expected value at array index 0 — almost always the literal string `'event'`, matching `gtag()`'s first argument. |
| `eventValue` | *eventValue (index 1 - value of trigger var i.e. {{Event}}=)* | `purchase` | The expected value at array index 1 — the specific `gtag()` event name you're looking for (e.g., `'purchase'`, `'add_to_cart'`). |
| `eventIndex` | *eventIndex (returned JSON object)* | `2` | Which array index to return once a match is found — index `2` is the payload/parameters object in the typical three-argument `gtag('event', name, {...})` call, but any single-digit index (`0`–`9`) is accepted. |
| `dataLayerCurrentEvent` | *dataLayerCurrentEvent (trigger var i.e. '{{Event}}')* | `{{Event}}` | A GTM variable reference (via the macro-insertion picker) — normally left at its default, wiring in GTM's own `{{Event}}` built-in variable so the search only runs when the currently-firing event matches `eventValue`. |

## ⚠️ Two considerations worth knowing before implementing

### 1. A potential crash if no matching entry is found
The code's post-loop check is:

```javascript
if (returnResult[1] === eventValue) {
  return returnResult[indexInt];
} else {
  return undefined;
}
```

If the search loop **never finds a match** (i.e., `dataLayerCurrentEvent` equals `eventValue`, meaning the guard passed, but no `dataLayer` entry actually has `[eventName, eventValue, ...]` at that point — for example, due to a timing issue, a differently-shaped push, or a mismatch between the triggering event and the actual command-queue array), `returnResult` remains `undefined`. The very next line, `returnResult[1]`, then throws a runtime error (`Cannot read properties of undefined`) rather than returning `undefined` gracefully. This directly undercuts the template's own documented purpose — *"to avoid unnecessary errors in the browser console"* — since the one case most likely to occur when something's misconfigured (no match found) is exactly the case that isn't handled safely. **If you use this template, consider adding a defensive check** (e.g., `if (returnResult) { ... } else { return undefined; }`) before accessing `returnResult[1]`.

### 2. An unused import / possibly unnecessary permission
The code requires `copyFromDataLayer` (`const copyFromDataLayer = require('copyFromDataLayer');`) — GTM's sandboxed API specifically designed for structured, path-based data-layer reads — but **never actually calls it anywhere** in the logic. The template instead reads the entire `dataLayer` array via `copyFromWindow('dataLayer')` and manually loops through it itself. Correspondingly, the bundled `read_data_layer` permission (with `allowedKeys: "any"`) is requested but, as the code is actually written, isn't exercised. This isn't harmful, but it's worth knowing: the unused import is dead code, and if you're auditing this template's permissions, the `read_data_layer` grant isn't actually load-bearing for the current implementation — the real data access happens through the `access_globals` permission covering `dataLayer` (read-only).

## Requested permissions

GTM template permissions are declared explicitly in `___WEB_PERMISSIONS___`:

- **`logging`** — allowed to write to the console, across **all** environments (broader than several of this author's other templates, which typically restrict logging to `debug` only) — though note the code itself never actually calls `logToConsole` despite requiring it, so no console output is currently produced by this template either way.
- **`access_globals`** — read-only access (`read: true`, `write: false`, `execute: false`) to exactly one global: `dataLayer`.
- **`read_data_layer`** — `allowedKeys: "any"` — requested, but (per the note above) not actually exercised by the current implementation.

## Getting started

### Import into Google Tag Manager

1. In your GTM container, go to **Templates** → **Variable Templates** → **New**.
2. Click the **⋮** (more actions) menu → **Import**.
3. Select the `Parse Gtag Ordered dataLayer Array to Find Object by Index.tpl` file from this repository.
4. Save the template.

### Create a variable from the template

1. Go to **Variables** → **User-Defined Variables** → **New**.
2. Choose **Parse Gtag Ordered dataLayer Array to Find Object by Index** as the variable type.
3. Set **eventName** to `event` (almost always correct, unless your `gtag()` calls use a different first argument).
4. Set **eventValue** to the specific `gtag()` event you want to find (e.g., `purchase`).
5. Set **eventIndex** to the array position you want returned — `2` for the payload/parameters object in the standard three-argument form.
6. Leave **dataLayerCurrentEvent** at its default `{{Event}}` reference, so the search only runs on the matching trigger.
7. Save the variable, then reference it (e.g., `{{Parse purchase payload}}`) anywhere you'd use any other GTM variable — most commonly as the source for a GA4 event tag's parameter mapping, or as an input to further Custom JavaScript logic.

### Verify it's working

- Use GTM's **Preview/Debug** mode, trigger the relevant `gtag()` event on your test page, and confirm the variable resolves to the expected object (or field) rather than `undefined` or a thrown error.
- If you see a runtime error in the console referencing this variable, it's most likely the crash scenario described above — check that your page's `gtag()` call actually produces a `dataLayer` entry shaped exactly as `[eventName, eventValue, ...]` at the point this variable is evaluated.

## Notes

- This is a **variable template** (`type: "MACRO"`), not a tag template — it's used as an input to other tags/variables, not something you trigger directly.
- The `___TESTS___` section currently contains no automated test scenarios (`scenarios: []`).
- This template was created on 3/10/2026.
- This is an unofficial, community-built template and is not published or endorsed by Google. Always review sandboxed template code and requested permissions — and be aware of the crash scenario noted above — before relying on this in a production GTM container.

## License

No license file is currently included in this repository. Check with the repository owner before reusing this template in a commercial or redistributed context.

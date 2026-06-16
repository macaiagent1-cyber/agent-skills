---
name: mcp-and-agent-development-kit
description: Consolidated skill replacing 11 redundant skills.
---

# Consolidated Skill: mcp-and-agent-development-kit



## --- Original Skill: build-mcp-app ---

# Build an MCP App (Interactive UI Widgets)

An MCP app is a standard MCP server that **also serves UI resources** — interactive components rendered inline in the chat surface. Build once, runs in Claude *and* ChatGPT and any other host that implements the apps surface.

The UI layer is **additive**. Under the hood it's still tools, resources, and the same wire protocol. If you haven't built a plain MCP server before, the `build-mcp-server` skill covers the base layer. This skill adds widgets on top.

> **Testing in Claude:** Add the server as a custom connector in claude.ai (via a Cloudflare tunnel for local dev) — this exercises the real iframe sandbox and `hostContext`. See https://claude.com/docs/connectors/building/testing.

## Claude host specifics

| `_meta.ui.*` key | Where | Effect |
|---|---|---|
| `resourceUri` | tool | Which `ui://` resource the host renders for this tool's results. |
| `visibility: ["app"]` | tool | Hide a widget-only helper tool (e.g. geometry/image fetcher called via `callServerTool`) from Claude's tool list. |
| `prefersBorder: false` | resource | Drop the host's outer card border (mobile). |
| `csp.{connectDomains, resourceDomains, baseUriDomains}` | resource | Declare external origins; default is block-all. `frameDomains` is currently restricted in Claude. |

- `hostContext.safeAreaInsets: {top, right, bottom, left}` (px) — honor these for notches and the composer overlay.
- Directory submission requires OAuth or **authless** (`none`) — static bearer is private-deploy only and blocks listing — plus tool `annotations` and 3–5 PNG screenshots; see `references/directory-checklist.md`.

---

## When a widget beats plain text

Don't add UI for its own sake — most tools are fine returning text or JSON. Add a widget when one of these is true:

| Signal | Widget type |
|---|---|
| Tool needs structured input Claude can't reliably infer | Form |
| User must pick from a list Claude can't rank (files, contacts, records) | Picker / table |
| Destructive or billable action needs explicit confirmation | Confirm dialog |
| Output is spatial or visual (charts, maps, diffs, previews) | Display widget |
| Long-running job the user wants to watch | Progress / live status |

If none apply, skip the widget. Text is faster to build and faster for the user.

---

## Widgets vs Elicitation — route correctly

Before building a widget, check if **elicitation** covers it. Elicitation is spec-native, zero UI code, works in any compliant host.

| Need | Elicitation | Widget |
|---|---|---|
| Confirm yes/no | ✅ | overkill |
| Pick from short enum | ✅ | overkill |
| Fill a flat form (name, email, date) | ✅ | overkill |
| Pick from a large/searchable list | ❌ (no scroll/search) | ✅ |
| Visual preview before choosing | ❌ | ✅ |
| Chart / map / diff view | ❌ | ✅ |
| Live-updating progress | ❌ | ✅ |

If elicitation covers it, use it. See `../build-mcp-server/references/elicitation.md`.

---

## Architecture: two deployment shapes

### Remote MCP app (most common)

Hosted streamable-HTTP server. Widget templates are served as **resources**; tool results reference them. The host fetches the resource, renders it in an iframe sandbox, and brokers messages between the widget and Claude.

```
┌──────────┐  tools/call   ┌────────────┐
│  Claude  │─────────────> │ MCP server │
│   host   │<── result ────│  (remote)  │
│          │  + widget ref │            │
│          │               │            │
│          │ resources/read│            │
│          │─────────────> │  widget    │
│ ┌──────┐ │<── template ──│  HTML/JS   │
│ │iframe│ │               └────────────┘
│ │widget│ │
│ └──────┘ │
└──────────┘
```

### MCPB-packaged MCP app (local + UI)

Same widget mechanism, but the server runs locally inside an MCPB bundle. Use this when the widget needs to drive a **local** application — e.g., a file picker that browses the actual local disk, a dialog that controls a desktop app.

For MCPB packaging mechanics, defer to the **`build-mcpb`** skill. Everything below applies to both shapes.

---

## How widgets attach to tools

A widget-enabled tool has **two separate registrations**:

1. **The tool** declares a UI resource via `_meta.ui.resourceUri`. Its handler returns plain text/JSON — NOT the HTML.
2. **The resource** is registered separately and serves the HTML.

When Claude calls the tool, the host sees `_meta.ui.resourceUri`, fetches that resource, renders it in an iframe, and pipes the tool's return value into the iframe via the `ontoolresult` event.

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerAppTool, registerAppResource, RESOURCE_MIME_TYPE }
  from "@modelcontextprotocol/ext-apps/server";
import { z } from "zod";

const server = new McpServer({ name: "contacts", version: "1.0.0" });

// 1. The tool — returns DATA, declares which UI to show
registerAppTool(server, "pick_contact", {
  description: "Open an interactive contact picker",
  annotations: { title: "Pick Contact", readOnlyHint: true },
  inputSchema: { filter: z.string().optional() },
  _meta: { ui: { resourceUri: "ui://widgets/contact-picker.html" } },
}, async ({ filter }) => {
  const contacts = await db.contacts.search(filter);
  // Plain JSON — the widget receives this via ontoolresult
  return { content: [{ type: "text", text: JSON.stringify(contacts) }] };
});

// 2. The resource — serves the HTML
registerAppResource(
  server,
  "Contact Picker",
  "ui://widgets/contact-picker.html",
  {},
  async () => ({
    contents: [{
      uri: "ui://widgets/contact-picker.html",
      mimeType: RESOURCE_MIME_TYPE,
      text: pickerHtml,  // your HTML string
    }],
  }),
);
```

The URI scheme `ui://` is convention. The mime type MUST be `RESOURCE_MIME_TYPE` (`"text/html;profile=mcp-app"`) — this is how the host knows to render it as an interactive iframe, not just display the source.

---

## Widget runtime — the `App` class

Inside the iframe, your script talks to the host via the `App` class from `@modelcontextprotocol/ext-apps`. This is a **persistent bidirectional connection** — the widget stays alive as long as the conversation is active, receiving new tool results and sending user actions.

```html
<script type="module">
  /* ext-apps bundle inlined at build time → globalThis.ExtApps */
  /*__EXT_APPS_BUNDLE__*/
  const { App } = globalThis.ExtApps;

  const app = new App({ name: "ContactPicker", version: "1.0.0" }, {});

  // Set handlers BEFORE connecting
  app.ontoolresult = ({ content }) => {
    const contacts = JSON.parse(content[0].text);
    render(contacts);
  };

  await app.connect();

  // Later, when the user clicks something:
  function onPick(contact) {
    app.sendMessage({
      role: "user",
      content: [{ type: "text", text: `Selected contact: ${contact.id}` }],
    });
  }
</script>
```

The `/*__EXT_APPS_BUNDLE__*/` placeholder gets replaced by the server at startup with the contents of `@modelcontextprotocol/ext-apps/app-with-deps` — see `references/iframe-sandbox.md` for why this is necessary and the rewrite snippet. **Do not** `import { App } from "https://esm.sh/..."`; the iframe's CSP blocks the transitive dependency fetches and the widget renders blank.

| Method | Direction | Use for |
|---|---|---|
| `app.ontoolresult = fn` | Host → widget | Receive the tool's return value |
| `app.ontoolinput = fn` | Host → widget | Receive the tool's input args (what Claude passed) |
| `app.sendMessage({...})` | Widget → host | Inject a message into the conversation |
| `app.updateModelContext({...})` | Widget → host | Update context silently (no visible message) |
| `app.callServerTool({name, arguments})` | Widget → server | Call another tool on your server |
| `app.openLink({url})` | Widget → host | Open a URL in a new tab (sandbox blocks `window.open`) |
| `app.getHostContext()` / `app.onhostcontextchanged` | Host → widget | Theme, host CSS vars, `containerDimensions`, `displayMode`, `deviceCapabilities` |
| `app.requestDisplayMode({mode})` | Widget → host | Ask for `inline` / `pip` / `fullscreen` |
| `app.downloadFile({name, mimeType, content})` | Widget → host | Host-mediated download (base64 content) |
| `new App(info, caps, {autoResize: true})` | — | Iframe height tracks rendered content |

`sendMessage` is the typical "user picked something, tell Claude" path. `updateModelContext` is for state that Claude should know about but shouldn't clutter the chat. `openLink` is **required** for any outbound navigation — `window.open` and `<a target="_blank">` are blocked by the sandbox attribute.

**What widgets cannot do:**
- Access the host page's DOM, cookies, or storage
- Make network calls to arbitrary origins (CSP-restricted — route through `callServerTool`)
- Open popups or navigate directly — use `app.openLink({url})`
- Load remote images reliably — inline as `data:` URLs server-side

Keep widgets **small and single-purpose**. A picker picks. A chart displays. Don't build a whole sub-app inside the iframe — split it into multiple tools with focused widgets.

---

## Scaffold: minimal picker widget

**Install:**

```bash
npm install @modelcontextprotocol/sdk @modelcontextprotocol/ext-apps zod express
```

**Server (`src/server.ts`):**

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { registerAppTool, registerAppResource, RESOURCE_MIME_TYPE }
  from "@modelcontextprotocol/ext-apps/server";
import express from "express";
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { z } from "zod";

const require = createRequire(import.meta.url);
const server = new McpServer({ name: "contact-picker", version: "1.0.0" });

// Inline the ext-apps browser bundle into the widget HTML.
// The iframe CSP blocks CDN script fetches — bundling is mandatory.
const bundle = readFileSync(
  require.resolve("@modelcontextprotocol/ext-apps/app-with-deps"), "utf8",
).replace(/export\{([^}]+)\};?\s*$/, (_, body) =>
  "globalThis.ExtApps={" +
  body.split(",").map((p) => {
    const [local, exported] = p.split(" as ").map((s) => s.trim());
    return `${exported ?? local}:${local}`;
  }).join(",") + "};",
);
const pickerHtml = readFileSync("./widgets/picker.html", "utf8")
  .replace("/*__EXT_APPS_BUNDLE__*/", () => bundle);

registerAppTool(server, "pick_contact", {
  description: "Open an interactive contact picker. User selects one contact.",
  annotations: { title: "Pick Contact", readOnlyHint: true },
  inputSchema: { filter: z.string().optional().describe("Name/email prefix filter") },
  _meta: { ui: { resourceUri: "ui://widgets/picker.html" } },
}, async ({ filter }) => {
  const contacts = await db.contacts.search(filter ?? "");
  return { content: [{ type: "text", text: JSON.stringify(contacts) }] };
});

registerAppResource(server, "Contact Picker", "ui://widgets/picker.html", {},
  async () => ({
    contents: [{ uri: "ui://widgets/picker.html", mimeType: RESOURCE_MIME_TYPE, text: pickerHtml }],
  }),
);

const app = express();
app.use(express.json());
app.post("/mcp", async (req, res) => {
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
  res.on("close", () => transport.close());
  await server.connect(transport);
  await transport.handleRequest(req, res, req.body);
});
app.listen(process.env.PORT ?? 3000);
```

For local-only widget apps (driving a desktop app, reading local files), swap the transport to `StdioServerTransport` and package via the `build-mcpb` skill.

**Widget (`widgets/picker.html`):**

```html
<!doctype html>
<meta charset="utf-8" />
<style>
  body { font: 14px system-ui; margin: 0; }
  ul { list-style: none; padding: 0; margin: 0; max-height: 300px; overflow-y: auto; }
  li { padding: 10px 14px; cursor: pointer; border-bottom: 1px solid #eee; }
  li:hover { background: #f5f5f5; }
  .sub { color: #666; font-size: 12px; }
</style>
<ul id="list"></ul>
<script type="module">
/*__EXT_APPS_BUNDLE__*/
const { App } = globalThis.ExtApps;
(async () => {
  const app = new App({ name: "ContactPicker", version: "1.0.0" }, {});
  const ul = document.getElementById("list");

  app.ontoolresult = ({ content }) => {
    const contacts = JSON.parse(content[0].text);
    ul.innerHTML = "";
    for (const c of contacts) {
      const li = document.createElement("li");
      li.innerHTML = `<div>${c.name}</div><div class="sub">${c.email}</div>`;
      li.addEventListener("click", () => {
        app.sendMessage({
          role: "user",
          content: [{ type: "text", text: `Selected contact: ${c.id} (${c.name})` }],
        });
      });
      ul.append(li);
    }
  };

  await app.connect();
})();
</script>
```

See `references/widget-templates.md` for more widget shapes.

---

## Design notes that save you a rewrite

**One widget per tool.** Resist the urge to build one mega-widget that does everything. One tool → one focused widget → one clear result shape. Claude reasons about these far better.

**Tool description must mention the widget.** Claude only sees the tool description when deciding what to call. "Opens an interactive picker" in the description is what makes Claude reach for it instead of guessing an ID.

**Widgets are optional at runtime.** Hosts that don't support the apps surface simply ignore `_meta.ui` and render the tool's text content normally. Since your tool handler already returns meaningful text/JSON (the widget's data), degradation is automatic — Claude sees the data directly instead of via the widget.

**Don't block on widget results for read-only tools.** A widget that just *displays* data (chart, preview) shouldn't require a user action to complete. Return the display widget *and* a text summary in the same result so Claude can continue reasoning without waiting.

**Layout-fork by item count, not by tool count.** If one use case is "show one result in detail" and another is "show many results side-by-side", don't make two tools — make one tool that accepts `items[]`, and let the widget pick a layout: `items.length === 1` → detail view, `> 1` → carousel. Keeps the server schema simple and lets Claude decide count naturally.

**Put Claude's reasoning in the payload.** A short `note` field on each item (why Claude picked it) rendered as a callout on the card gives users the reasoning inline with the choice. Mention this field in the tool description so Claude populates it.

**Normalize image shapes server-side.** If your data source returns images with wildly varying aspect ratios, rewrite to a predictable variant (e.g. square-bounded) *before* fetching for the data-URL inline. Then give the widget's image container a fixed `aspect-ratio` + `object-fit: contain` so everything sits centered.

**Follow host theme.** `app.getHostContext()?.theme` (after `connect()`) plus `app.onhostcontextchanged` for live updates. Toggle a `.dark` class on `<html>`, keep colors in CSS custom props with a `:root.dark {}` override block, set `color-scheme`. Disable `mix-blend-mode: multiply` in dark — it makes images vanish.

---

## Testing

**Claude Desktop** — current builds still require the `command`/`args` config shape (no native `"type": "http"`). Wrap with `mcp-remote` and force `http-only` transport so the SSE probe doesn't swallow widget-capability negotiation:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://localhost:3000/mcp",
               "--allow-http", "--transport", "http-only"]
    }
  }
}
```

Desktop caches UI resources aggressively. After editing widget HTML, **fully quit** (⌘Q / Alt+F4, not window-close) and relaunch to force a cold resource re-fetch.

**Headless JSON-RPC loop** — fast iteration without clicking through Desktop:

```bash
# test.jsonl — one JSON-RPC message per line
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"t","version":"0"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":2,"method":"tools/list"}
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"your_tool","arguments":{...}}}

(cat test.jsonl; sleep 10) | npx mcp-remote http://localhost:3000/mcp --allow-http
```

The `sleep` keeps stdin open long enough to collect all responses. Parse the jsonl output with `jq` or a Python one-liner.

**Widget dev loop** — avoid the ⌘Q-relaunch cycle entirely by serving the inlined widget HTML at a plain GET route with a fake `ExtApps` shim that fires `ontoolresult` from a query param:

```ts
app.get("/widget-preview", (_req, res) => {
  const shim = `globalThis.ExtApps={applyHostStyleVariables:()=>{},App:class{
    constructor(){this.h={}} ontoolresult;onhostcontextchanged;
    async connect(){const p=new URLSearchParams(location.search).get("payload");
      if(p)this.ontoolresult?.({content:[{type:"text",text:p}]});}
    getHostContext(){return{theme:"light"}}
    sendMessage(m){console.log("sendMessage",m)} updateModelContext(){}
    callServerTool(){return Promise.resolve({content:[]})} openLink(){} downloadFile(){}
  }};`;
  res.type("html").send(widgetHtml.replace("/*__EXT_APPS_BUNDLE__*/", shim));
});
```

Open `http://localhost:3000/widget-preview?payload={"rows":[...]}` in a normal browser tab and iterate with ordinary devtools.

**Host fallback** — use a host without the apps surface (or MCP Inspector) and confirm the tool's text content degrades gracefully.

**CSP debugging** — open the iframe's own devtools console. CSP violations are the #1 reason widgets silently fail (blank rectangle, no error in the main console). See `references/iframe-sandbox.md`.

---

## Reference files

- `references/iframe-sandbox.md` — CSP/sandbox constraints, the bundle-inlining pattern, image handling, host theming
- `references/widget-templates.md` — reusable HTML scaffolds for picker / confirm / progress / display
- `references/apps-sdk-messages.md` — the `App` class API: widget ↔ host ↔ server messaging, lifecycle & supersession
- `references/payload-budgeting.md` — host tool-result size caps, prune-then-truncate, heavy assets via `callServerTool`
- `references/abuse-protection.md` — Anthropic egress CIDRs, tiered rate limiting, `trust proxy`, response caching
- `references/directory-checklist.md` — pre-flight for connector-directory submission


## --- Original Skill: build-mcp-server ---

# Build an MCP Server

You are guiding a developer through designing and building an MCP server that works seamlessly with Claude. MCP servers come in many forms — picking the wrong shape early causes painful rewrites later. Your first job is **discovery, not code**.

**Load Claude-specific context first.** The MCP spec is generic; Claude has additional auth types, review criteria, and limits. Before answering questions or scaffolding, fetch `https://claude.com/docs/llms-full.txt` (the full export of the Claude connector docs) so your guidance reflects Claude's actual constraints.

Do not start scaffolding until you have answers to the questions in Phase 1. If the user's opening message already answers them, acknowledge that and skip straight to the recommendation.

---

## Phase 1 — Interrogate the use case

Ask these questions conversationally (batch them into one message, don't interrogate one-at-a-time). Adapt wording to what the user has already told you.

### 1. What does it connect to?

| If it connects to… | Likely direction |
|---|---|
| A cloud API (SaaS, REST, GraphQL) | Remote HTTP server |
| A local process, filesystem, or desktop app | MCPB or local stdio |
| Hardware, OS-level APIs, or user-specific state | MCPB |
| Nothing external — pure logic / computation | Either — default to remote |

### 2. Who will use it?

- **Just me / my team, on our machines** → Local stdio is acceptable (easiest to prototype)
- **Anyone who installs it** → Remote HTTP (strongly preferred) or MCPB (if it *must* be local)
- **Users of Claude desktop who want UI widgets** → MCP app (remote or MCPB)

### 3. How many distinct actions does it expose?

This determines the tool-design pattern — see Phase 3.

- **Under ~15 actions** → one tool per action
- **Dozens to hundreds of actions** (e.g. wrapping a large API surface) → search + execute pattern

### 4. Does a tool need mid-call user input or rich display?

- **Simple structured input** (pick from list, enter a value, confirm) → **Elicitation** — spec-native, zero UI code. *Host support is rolling out* (Claude Code ≥2.1.76) — always pair with a capability check and fallback. See `references/elicitation.md`.
- **Rich/visual UI** (charts, custom pickers with search, live dashboards) → **MCP app widgets** — iframe-based, needs `@modelcontextprotocol/ext-apps`. See `build-mcp-app` skill.
- **Neither** → plain tool returning text/JSON.

### 5. What auth does the upstream service use?

- None / API key → straightforward
- OAuth 2.0 → you'll need a remote server with CIMD (preferred) or DCR support; see `references/auth.md`

---

## Phase 2 — Recommend a deployment model

Based on the answers, recommend **one** path. Be opinionated. The ranked options:

### ⭐ Remote streamable-HTTP MCP server (default recommendation)

A hosted service speaking MCP over streamable HTTP. This is the **recommended path** for anything wrapping a cloud API.

**Why it wins:**
- Zero install friction — users add a URL, done
- One deployment serves all users; you control upgrades
- OAuth flows work properly (the server can handle redirects, DCR, token storage)
- Works across Claude desktop, Claude Code, Claude.ai, and third-party MCP hosts

**Choose this unless** the server *must* touch the user's local machine.

→ **Fastest deploy:** Cloudflare Workers — `references/deploy-cloudflare-workers.md` (zero to live URL in two commands)
→ **Portable Node/Python:** `references/remote-http-scaffold.md` (Express or FastMCP, runs on any host)

### Elicitation (structured input, no UI build)

If a tool just needs the user to confirm, pick an option, or fill a short form, **elicitation** does it with zero UI code. The server sends a flat JSON schema; the host renders a native form. Spec-native, no extra packages.

**Caveat:** Host support is new (Claude Code shipped it in v2.1.76; Desktop unconfirmed). The SDK throws if the client doesn't advertise the capability. Always check `clientCapabilities.elicitation` first and have a fallback — see `references/elicitation.md` for the canonical pattern. This is the right spec-correct approach; host coverage will catch up.

Escalate to `build-mcp-app` widgets when you need: nested/complex data, scrollable/searchable lists, visual previews, live updates.

### MCP app (remote HTTP + interactive UI)

Same as above, plus **UI resources** — interactive widgets rendered in chat. Rich pickers with search, charts, live dashboards, visual previews. Built once, renders in Claude *and* ChatGPT.

**Choose this when** elicitation's flat-form constraints don't fit — you need custom layout, large searchable lists, visual content, or live updates.

Usually remote, but can be shipped as MCPB if the UI needs to drive a local app.

→ Hand off to the **`build-mcp-app`** skill.

### MCPB (bundled local server)

A local MCP server **packaged with its runtime** so users don't need Node/Python installed. The sanctioned way to ship local servers.

**Choose this when** the server *must* run on the user's machine — it reads local files, drives a desktop app, talks to localhost services, or needs OS-level access.

→ Hand off to the **`build-mcpb`** skill.

### Local stdio (npx / uvx) — *not recommended for distribution*

A script launched via `npx` / `uvx` on the user's machine. Fine for **personal tools and prototypes**. Painful to distribute: users need the right runtime, you can't push updates, and the only distribution channel is Claude Code plugins.

Recommend this only as a stepping stone. If the user insists, scaffold it but note the MCPB upgrade path.

---

## Phase 3 — Pick a tool-design pattern

Every MCP server exposes tools. How you carve them matters more than most people expect — tool schemas land directly in Claude's context window.

### Pattern A: One tool per action (small surface)

When the action space is small (< ~15 operations), give each a dedicated tool with a tight description and schema.

```
create_issue    — Create a new issue. Params: title, body, labels[]
update_issue    — Update an existing issue. Params: id, title?, body?, state?
search_issues   — Search issues by query string. Params: query, limit?
add_comment     — Add a comment to an issue. Params: issue_id, body
```

**Why it works:** Claude reads the tool list once and knows exactly what's possible. No discovery round-trips. Each tool's schema validates inputs precisely.

**Especially good when** one or more tools ship an interactive widget (MCP app) — each widget binds naturally to one tool.

### Pattern B: Search + execute (large surface)

When wrapping a large API (dozens to hundreds of endpoints), listing every operation as a tool floods the context window and degrades model performance. Instead, expose **two** tools:

```
search_actions  — Given a natural-language intent, return matching actions
                  with their IDs, descriptions, and parameter schemas.
execute_action  — Run an action by ID with a params object.
```

The server holds the full catalog internally. Claude searches, picks, executes. Context stays lean.

**Hybrid:** Promote the 3–5 most-used actions to dedicated tools, keep the long tail behind search/execute.

→ See `references/tool-design.md` for schema examples and description-writing guidance.

---

## Phase 4 — Pick a framework

Recommend one of these two. Others exist but these have the best MCP-spec coverage and Claude compatibility.

| Framework | Language | Use when |
|---|---|---|
| **Official TypeScript SDK** (`@modelcontextprotocol/sdk`) | TS/JS | Default choice. Best spec coverage, first to get new features. |
| **FastMCP 3.x** (`fastmcp` on PyPI) | Python | User prefers Python, or wrapping a Python library. Decorator-based, very low boilerplate. This is jlowin's package — not the frozen FastMCP 1.0 bundled in the official `mcp` SDK. |

If the user already has a language/stack in mind, go with it — both produce identical wire protocol.

---

## Phase 5 — Scaffold and hand off

Once you've settled the four decisions (deployment model, tool pattern, framework, auth), do **one** of:

1. **Remote HTTP, no UI** → Scaffold inline using `references/remote-http-scaffold.md` (portable) or `references/deploy-cloudflare-workers.md` (fastest deploy). This skill can finish the job.
2. **MCP app (UI widgets)** → Summarize the decisions so far, then load the **`build-mcp-app`** skill.
3. **MCPB (bundled local)** → Summarize the decisions so far, then load the **`build-mcpb`** skill.
4. **Local stdio prototype** → Scaffold inline (simplest case), flag the MCPB upgrade path.

When handing off, restate the design brief in one paragraph so the next skill doesn't re-ask.

---

## Beyond tools — the other primitives

Tools are one of three server primitives. Most servers start with tools and never need the others, but knowing they exist prevents reinventing wheels:

| Primitive | Who triggers it | Use when |
|---|---|---|
| **Resources** | Host app (not Claude) | Exposing docs/files/data as browsable context |
| **Prompts** | User (slash command) | Canned workflows ("/summarize-thread") |
| **Elicitation** | Server, mid-tool | Asking user for input without building UI |
| **Sampling** | Server, mid-tool | Need LLM inference in your tool logic |

→ `references/resources-and-prompts.md`, `references/elicitation.md`, `references/server-capabilities.md`

---

## Phase 6 — Test in Claude and publish

Once the server runs:

1. **Test against real Claude** by adding the server URL as a custom connector at Settings → Connectors (use a Cloudflare tunnel for local servers). Claude identifies itself with `clientInfo.name: "claude-ai"` on initialize. → https://claude.com/docs/connectors/building/testing
2. **Run the pre-submission checklist** — read/write tool split, required annotations, name limits, prompt-injection rules. → https://claude.com/docs/connectors/building/review-criteria
3. **Submit to the Anthropic Directory.** → https://claude.com/docs/connectors/building/submission
4. **Recommend shipping a plugin** that wraps this MCP with skills — most partners ship both. → https://claude.com/docs/connectors/building/what-to-build

---

## Quick reference: decision matrix

| Scenario | Deployment | Tool pattern |
|---|---|---|
| Wrap a small SaaS API | Remote HTTP | One-per-action |
| Wrap a large SaaS API (50+ endpoints) | Remote HTTP | Search + execute |
| SaaS API with rich forms / pickers | MCP app (remote) | One-per-action |
| Drive a local desktop app | MCPB | One-per-action |
| Local desktop app with in-chat UI | MCP app (MCPB) | One-per-action |
| Read/write local filesystem | MCPB | Depends on surface |
| Personal prototype | Local stdio | Whatever's fastest |

---

## Reference files

- `references/remote-http-scaffold.md` — minimal remote server in TS SDK and FastMCP
- `references/deploy-cloudflare-workers.md` — fastest deploy path (Workers-native scaffold)
- `references/tool-design.md` — writing tool descriptions and schemas Claude understands well
- `references/auth.md` — OAuth, CIMD, DCR, token storage patterns
- `references/resources-and-prompts.md` — the two non-tool primitives
- `references/elicitation.md` — spec-native user input mid-tool (capability check + fallback)
- `references/server-capabilities.md` — instructions, sampling, roots, logging, progress, cancellation
- `references/versions.md` — version-sensitive claims ledger (check when updating)


## --- Original Skill: build-mcpb ---

# Build an MCPB (Bundled Local MCP Server)

MCPB is a local MCP server **packaged with its runtime**. The user installs one file; it runs without needing Node, Python, or any toolchain on their machine. It's the sanctioned way to distribute local MCP servers.

> MCPB is the **secondary** distribution path. Anthropic recommends remote MCP servers for directory listing — see https://claude.com/docs/connectors/building/what-to-build.

**Use MCPB when the server must run on the user's machine** — reading local files, driving a desktop app, talking to localhost services, OS-level APIs. If your server only hits cloud APIs, you almost certainly want a remote HTTP server instead (see `build-mcp-server`). Don't pay the MCPB packaging tax for something that could be a URL.

---

## What an MCPB bundle contains

```
my-server.mcpb              (zip archive)
├── manifest.json           ← identity, entry point, config schema, compatibility
├── server/                 ← your MCP server code
│   ├── index.js
│   └── node_modules/       ← bundled dependencies (or vendored)
└── icon.png
```

The host reads `manifest.json`, launches `server.mcp_config.command` as a **stdio** MCP server, and pipes messages. From your code's perspective it's identical to a local stdio server — the only difference is packaging.

---

## Manifest

```json
{
  "$schema": "https://raw.githubusercontent.com/anthropics/mcpb/main/schemas/mcpb-manifest-v0.4.schema.json",
  "manifest_version": "0.4",
  "name": "local-files",
  "version": "0.1.0",
  "description": "Read, search, and watch files on the local filesystem.",
  "author": { "name": "Your Name" },
  "server": {
    "type": "node",
    "entry_point": "server/index.js",
    "mcp_config": {
      "command": "node",
      "args": ["${__dirname}/server/index.js"],
      "env": {
        "ROOT_DIR": "${user_config.rootDir}"
      }
    }
  },
  "user_config": {
    "rootDir": {
      "type": "directory",
      "title": "Root directory",
      "description": "Directory to expose. Defaults to ~/Documents.",
      "default": "${HOME}/Documents",
      "required": true
    }
  },
  "compatibility": {
    "claude_desktop": ">=1.0.0",
    "platforms": ["darwin", "win32", "linux"]
  }
}
```

**`server.type`** — `node`, `python`, or `binary`. Informational; the actual launch comes from `mcp_config`.

**`server.mcp_config`** — the literal command/args/env to spawn. Use `${__dirname}` for bundle-relative paths and `${user_config.<key>}` to substitute install-time config. **There's no auto-prefix** — the env var names your server reads are exactly what you put in `env`.

**`user_config`** — install-time settings surfaced in the host's UI. `type: "directory"` renders a native folder picker. `sensitive: true` stores in OS keychain. See `references/manifest-schema.md` for all fields.

---

## Server code: same as local stdio

The server itself is a standard stdio MCP server. Nothing MCPB-specific in the tool logic.

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { readFile, readdir } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

// ROOT_DIR comes from what you put in manifest's server.mcp_config.env — no auto-prefix
const ROOT = (process.env.ROOT_DIR ?? join(homedir(), "Documents"));

const server = new McpServer({ name: "local-files", version: "0.1.0" });

server.registerTool(
  "list_files",
  {
    description: "List files in a directory under the configured root.",
    inputSchema: { path: z.string().default(".") },
    annotations: { readOnlyHint: true },
  },
  async ({ path }) => {
    const entries = await readdir(join(ROOT, path), { withFileTypes: true });
    const list = entries.map(e => ({ name: e.name, dir: e.isDirectory() }));
    return { content: [{ type: "text", text: JSON.stringify(list, null, 2) }] };
  },
);

server.registerTool(
  "read_file",
  {
    description: "Read a file's contents. Path is relative to the configured root.",
    inputSchema: { path: z.string() },
    annotations: { readOnlyHint: true },
  },
  async ({ path }) => {
    const text = await readFile(join(ROOT, path), "utf8");
    return { content: [{ type: "text", text }] };
  },
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

**Sandboxing is entirely your job.** There is no manifest-level sandbox — the process runs with full user privileges. Validate paths, refuse to escape `ROOT`, allowlist spawns. See `references/local-security.md`.

Before hardcoding `ROOT` from a config env var, check if the host supports `roots/list` — the spec-native way to get user-approved directories. See `references/local-security.md` for the pattern.

---

## Build pipeline

### Node

```bash
npm install
npx esbuild src/index.ts --bundle --platform=node --outfile=server/index.js
# or: copy node_modules wholesale if native deps resist bundling
npx @anthropic-ai/mcpb pack
```

`mcpb pack` zips the directory and validates `manifest.json` against the schema.

### Python

```bash
pip install -t server/vendor -r requirements.txt
npx @anthropic-ai/mcpb pack
```

Vendor dependencies into a subdirectory and prepend it to `sys.path` in your entry script. Native extensions (numpy, etc.) must be built for each target platform — avoid native deps if you can.

---

## MCPB has no sandbox — security is on you

Unlike mobile app stores, MCPB does NOT enforce permissions. The manifest has no `permissions` block — the server runs with full user privileges. `references/local-security.md` is mandatory reading, not optional. Every path must be validated, every spawn must be allowlisted, because nothing stops you at the platform level.

If you came here expecting filesystem/network scoping from the manifest: it doesn't exist. Build it yourself in tool handlers.

If your server's only job is hitting a cloud API, stop — that's a remote server wearing an MCPB costume. The user gains nothing from running it locally, and you're taking on local-security burden for no reason.

---

## MCPB + UI widgets

MCPB servers can serve UI resources exactly like remote MCP apps — the widget mechanism is transport-agnostic. A local file picker that browses the actual disk, a dialog that controls a native app, etc.

Widget authoring is covered in the **`build-mcp-app`** skill; it works the same here. The only difference is where the server runs.

---

## Testing

```bash
# Interactive manifest creation (first time)
npx @anthropic-ai/mcpb init

# Run the server directly over stdio, poke it with the inspector
npx @modelcontextprotocol/inspector node server/index.js

# Validate manifest against schema, then pack
npx @anthropic-ai/mcpb validate
npx @anthropic-ai/mcpb pack

# Sign for distribution
npx @anthropic-ai/mcpb sign dist/local-files.mcpb

# Install: drag the .mcpb file onto Claude Desktop
```

Test on a machine **without** your dev toolchain before shipping. "Works on my machine" failures in MCPB almost always trace to a dependency that wasn't actually bundled.

---

## Reference files

- `references/manifest-schema.md` — full `manifest.json` field reference
- `references/local-security.md` — path traversal, sandboxing, least privilege


## --- Original Skill: mcp-integration ---

# MCP Integration for Claude Code Plugins

## Overview

Model Context Protocol (MCP) enables Claude Code plugins to integrate with external services and APIs by providing structured tool access. Use MCP integration to expose external service capabilities as tools within Claude Code.

**Key capabilities:**
- Connect to external services (databases, APIs, file systems)
- Provide 10+ related tools from a single service
- Handle OAuth and complex authentication flows
- Bundle MCP servers with plugins for automatic setup

## MCP Server Configuration Methods

Plugins can bundle MCP servers in two ways:

### Method 1: Dedicated .mcp.json (Recommended)

Create `.mcp.json` at plugin root:

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "DB_URL": "${DB_URL}"
    }
  }
}
```

**Benefits:**
- Clear separation of concerns
- Easier to maintain
- Better for multiple servers

### Method 2: Inline in plugin.json

Add `mcpServers` field to plugin.json:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

**Benefits:**
- Single configuration file
- Good for simple single-server plugins

## MCP Server Types

### stdio (Local Process)

Execute local MCP servers as child processes. Best for local tools and custom servers.

**Configuration:**
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"],
    "env": {
      "LOG_LEVEL": "debug"
    }
  }
}
```

**Use cases:**
- File system access
- Local database connections
- Custom MCP servers
- NPM-packaged MCP servers

**Process management:**
- Claude Code spawns and manages the process
- Communicates via stdin/stdout
- Terminates when Claude Code exits

### SSE (Server-Sent Events)

Connect to hosted MCP servers with OAuth support. Best for cloud services.

**Configuration:**
```json
{
  "asana": {
    "type": "sse",
    "url": "https://mcp.asana.com/sse"
  }
}
```

**Use cases:**
- Official hosted MCP servers (Asana, GitHub, etc.)
- Cloud services with MCP endpoints
- OAuth-based authentication
- No local installation needed

**Authentication:**
- OAuth flows handled automatically
- User prompted on first use
- Tokens managed by Claude Code

### HTTP (REST API)

Connect to RESTful MCP servers with token authentication.

**Configuration:**
```json
{
  "api-service": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}",
      "X-Custom-Header": "value"
    }
  }
}
```

**Use cases:**
- REST API-based MCP servers
- Token-based authentication
- Custom API backends
- Stateless interactions

### WebSocket (Real-time)

Connect to WebSocket MCP servers for real-time bidirectional communication.

**Configuration:**
```json
{
  "realtime-service": {
    "type": "ws",
    "url": "wss://mcp.example.com/ws",
    "headers": {
      "Authorization": "Bearer ${TOKEN}"
    }
  }
}
```

**Use cases:**
- Real-time data streaming
- Persistent connections
- Push notifications from server
- Low-latency requirements

## Environment Variable Expansion

All MCP configurations support environment variable substitution:

**${CLAUDE_PLUGIN_ROOT}** - Plugin directory (always use for portability):
```json
{
  "command": "${CLAUDE_PLUGIN_ROOT}/servers/my-server"
}
```

**User environment variables** - From user's shell:
```json
{
  "env": {
    "API_KEY": "${MY_API_KEY}",
    "DATABASE_URL": "${DB_URL}"
  }
}
```

**Best practice:** Document all required environment variables in plugin README.

## MCP Tool Naming

When MCP servers provide tools, they're automatically prefixed:

**Format:** `mcp__plugin_<plugin-name>_<server-name>__<tool-name>`

**Example:**
- Plugin: `asana`
- Server: `asana`
- Tool: `create_task`
- **Full name:** `mcp__plugin_asana_asana__asana_create_task`

### Using MCP Tools in Commands

Pre-allow specific MCP tools in command frontmatter:

```markdown
---
allowed-tools: [
  "mcp__plugin_asana_asana__asana_create_task",
  "mcp__plugin_asana_asana__asana_search_tasks"
]
---
```

**Wildcard (use sparingly):**
```markdown
---
allowed-tools: ["mcp__plugin_asana_asana__*"]
---
```

**Best practice:** Pre-allow specific tools, not wildcards, for security.

## Lifecycle Management

**Automatic startup:**
- MCP servers start when plugin enables
- Connection established before first tool use
- Restart required for configuration changes

**Lifecycle:**
1. Plugin loads
2. MCP configuration parsed
3. Server process started (stdio) or connection established (SSE/HTTP/WS)
4. Tools discovered and registered
5. Tools available as `mcp__plugin_...__...`

**Viewing servers:**
Use `/mcp` command to see all servers including plugin-provided ones.

## Authentication Patterns

### OAuth (SSE/HTTP)

OAuth handled automatically by Claude Code:

```json
{
  "type": "sse",
  "url": "https://mcp.example.com/sse"
}
```

User authenticates in browser on first use. No additional configuration needed.

### Token-Based (Headers)

Static or environment variable tokens:

```json
{
  "type": "http",
  "url": "https://api.example.com",
  "headers": {
    "Authorization": "Bearer ${API_TOKEN}"
  }
}
```

Document required environment variables in README.

### Environment Variables (stdio)

Pass configuration to MCP server:

```json
{
  "command": "python",
  "args": ["-m", "my_mcp_server"],
  "env": {
    "DATABASE_URL": "${DB_URL}",
    "API_KEY": "${API_KEY}",
    "LOG_LEVEL": "info"
  }
}
```

## Integration Patterns

### Pattern 1: Simple Tool Wrapper

Commands use MCP tools with user interaction:

```markdown
# Command: create-item.md
---
allowed-tools: ["mcp__plugin_name_server__create_item"]
---

Steps:
1. Gather item details from user
2. Use mcp__plugin_name_server__create_item
3. Confirm creation
```

**Use for:** Adding validation or preprocessing before MCP calls.

### Pattern 2: Autonomous Agent

Agents use MCP tools autonomously:

```markdown
# Agent: data-analyzer.md

Analysis Process:
1. Query data via mcp__plugin_db_server__query
2. Process and analyze results
3. Generate insights report
```

**Use for:** Multi-step MCP workflows without user interaction.

### Pattern 3: Multi-Server Plugin

Integrate multiple MCP servers:

```json
{
  "github": {
    "type": "sse",
    "url": "https://mcp.github.com/sse"
  },
  "jira": {
    "type": "sse",
    "url": "https://mcp.jira.com/sse"
  }
}
```

**Use for:** Workflows spanning multiple services.

## Security Best Practices

### Use HTTPS/WSS

Always use secure connections:

```json
✅ "url": "https://mcp.example.com/sse"
❌ "url": "http://mcp.example.com/sse"
```

### Token Management

**DO:**
- ✅ Use environment variables for tokens
- ✅ Document required env vars in README
- ✅ Let OAuth flow handle authentication

**DON'T:**
- ❌ Hardcode tokens in configuration
- ❌ Commit tokens to git
- ❌ Share tokens in documentation

### Permission Scoping

Pre-allow only necessary MCP tools:

```markdown
✅ allowed-tools: [
  "mcp__plugin_api_server__read_data",
  "mcp__plugin_api_server__create_item"
]

❌ allowed-tools: ["mcp__plugin_api_server__*"]
```

## Error Handling

### Connection Failures

Handle MCP server unavailability:
- Provide fallback behavior in commands
- Inform user of connection issues
- Check server URL and configuration

### Tool Call Errors

Handle failed MCP operations:
- Validate inputs before calling MCP tools
- Provide clear error messages
- Check rate limiting and quotas

### Configuration Errors

Validate MCP configuration:
- Test server connectivity during development
- Validate JSON syntax
- Check required environment variables

## Performance Considerations

### Lazy Loading

MCP servers connect on-demand:
- Not all servers connect at startup
- First tool use triggers connection
- Connection pooling managed automatically

### Batching

Batch similar requests when possible:

```
# Good: Single query with filters
tasks = search_tasks(project="X", assignee="me", limit=50)

# Avoid: Many individual queries
for id in task_ids:
    task = get_task(id)
```

## Testing MCP Integration

### Local Testing

1. Configure MCP server in `.mcp.json`
2. Install plugin locally (`.claude-plugin/`)
3. Run `/mcp` to verify server appears
4. Test tool calls in commands
5. Check `claude --debug` logs for connection issues

### Validation Checklist

- [ ] MCP configuration is valid JSON
- [ ] Server URL is correct and accessible
- [ ] Required environment variables documented
- [ ] Tools appear in `/mcp` output
- [ ] Authentication works (OAuth or tokens)
- [ ] Tool calls succeed from commands
- [ ] Error cases handled gracefully

## Debugging

### Enable Debug Logging

```bash
claude --debug
```

Look for:
- MCP server connection attempts
- Tool discovery logs
- Authentication flows
- Tool call errors

### Common Issues

**Server not connecting:**
- Check URL is correct
- Verify server is running (stdio)
- Check network connectivity
- Review authentication configuration

**Tools not available:**
- Verify server connected successfully
- Check tool names match exactly
- Run `/mcp` to see available tools
- Restart Claude Code after config changes

**Authentication failing:**
- Clear cached auth tokens
- Re-authenticate
- Check token scopes and permissions
- Verify environment variables set

## Quick Reference

### MCP Server Types

| Type | Transport | Best For | Auth |
|------|-----------|----------|------|
| stdio | Process | Local tools, custom servers | Env vars |
| SSE | HTTP | Hosted services, cloud APIs | OAuth |
| HTTP | REST | API backends, token auth | Tokens |
| ws | WebSocket | Real-time, streaming | Tokens |

### Configuration Checklist

- [ ] Server type specified (stdio/SSE/HTTP/ws)
- [ ] Type-specific fields complete (command or url)
- [ ] Authentication configured
- [ ] Environment variables documented
- [ ] HTTPS/WSS used (not HTTP/WS)
- [ ] ${CLAUDE_PLUGIN_ROOT} used for paths

### Best Practices

**DO:**
- ✅ Use ${CLAUDE_PLUGIN_ROOT} for portable paths
- ✅ Document required environment variables
- ✅ Use secure connections (HTTPS/WSS)
- ✅ Pre-allow specific MCP tools in commands
- ✅ Test MCP integration before publishing
- ✅ Handle connection and tool errors gracefully

**DON'T:**
- ❌ Hardcode absolute paths
- ❌ Commit credentials to git
- ❌ Use HTTP instead of HTTPS
- ❌ Pre-allow all tools with wildcards
- ❌ Skip error handling
- ❌ Forget to document setup

## Additional Resources

### Reference Files

For detailed information, consult:

- **`references/server-types.md`** - Deep dive on each server type
- **`references/authentication.md`** - Authentication patterns and OAuth
- **`references/tool-usage.md`** - Using MCP tools in commands and agents

### Example Configurations

Working examples in `examples/`:

- **`stdio-server.json`** - Local stdio MCP server
- **`sse-server.json`** - Hosted SSE server with OAuth
- **`http-server.json`** - REST API with token auth

### External Resources

- **Official MCP Docs**: https://modelcontextprotocol.io/
- **Claude Code MCP Docs**: https://docs.claude.com/en/docs/claude-code/mcp
- **MCP SDK**: @modelcontextprotocol/sdk
- **Testing**: Use `claude --debug` and `/mcp` command

## Implementation Workflow

To add MCP integration to a plugin:

1. Choose MCP server type (stdio, SSE, HTTP, ws)
2. Create `.mcp.json` at plugin root with configuration
3. Use ${CLAUDE_PLUGIN_ROOT} for all file references
4. Document required environment variables in README
5. Test locally with `/mcp` command
6. Pre-allow MCP tools in relevant commands
7. Handle authentication (OAuth or tokens)
8. Test error cases (connection failures, auth errors)
9. Document MCP integration in plugin README

Focus on stdio for custom/local servers, SSE for hosted services with OAuth.


## --- Original Skill: agent-development ---

# Agent Development for Claude Code Plugins

## Overview

Agents are autonomous subprocesses that handle complex, multi-step tasks independently. Understanding agent structure, triggering conditions, and system prompt design enables creating powerful autonomous capabilities.

**Key concepts:**
- Agents are FOR autonomous work, commands are FOR user-initiated actions
- Markdown file format with YAML frontmatter
- Triggering via description field with examples
- System prompt defines agent behavior
- Model and color customization

## Agent File Structure

### Complete Format

```markdown
---
name: agent-identifier
description: Use this agent when [triggering conditions]. Typical triggers include [scenario 1 in prose], [scenario 2 in prose], and [scenario 3 in prose]. See "When to invoke" in the agent body for worked scenarios.
model: inherit
color: blue
tools: ["Read", "Write", "Grep"]
---

You are [agent role description]...

## When to invoke

[Two to four representative scenarios written as prose, e.g.:]
- **[Scenario name].** [What the situation looks like and what the agent should do.]
- **[Scenario name].** [Same.]

**Your Core Responsibilities:**
1. [Responsibility 1]
2. [Responsibility 2]

**Analysis Process:**
[Step-by-step workflow]

**Output Format:**
[What to return]
```

## Frontmatter Fields

### name (required)

Agent identifier used for namespacing and invocation.

**Format:** lowercase, numbers, hyphens only
**Length:** 3-50 characters
**Pattern:** Must start and end with alphanumeric

**Good examples:**
- `code-reviewer`
- `test-generator`
- `api-docs-writer`
- `security-analyzer`

**Bad examples:**
- `helper` (too generic)
- `-agent-` (starts/ends with hyphen)
- `my_agent` (underscores not allowed)
- `ag` (too short, < 3 chars)

### description (required)

Defines when Claude should trigger this agent. **This is the most critical field** — it is loaded into context whenever the agent is registered, so the harness can decide when to dispatch.

**Must include:**
1. Triggering conditions ("Use this agent when...")
2. A short prose summary of the typical trigger scenarios
3. A pointer to a "When to invoke" section in the agent body for the detailed worked scenarios

**Format:**
```
Use this agent when [conditions]. Typical triggers include [scenario 1 in prose], [scenario 2 in prose], and [scenario 3 in prose]. See "When to invoke" in the agent body for worked scenarios.
```

**Best practices:**
- Name 2-4 trigger scenarios in the prose summary
- Cover both proactive (assistant invokes itself) and reactive (user requests) triggering
- Cover different phrasings of the same intent
- Be specific about when NOT to use the agent
- Put detailed scenarios in the body under "When to invoke" as a bullet list of prose descriptions

### model (required)

Which model the agent should use.

**Options:**
- `inherit` - Use same model as parent (recommended)
- `sonnet` - Claude Sonnet (balanced)
- `opus` - Claude Opus (most capable, expensive)
- `haiku` - Claude Haiku (fast, cheap)

**Recommendation:** Use `inherit` unless agent needs specific model capabilities.

### color (required)

Visual identifier for agent in UI.

**Options:** `blue`, `cyan`, `green`, `yellow`, `magenta`, `red`

**Guidelines:**
- Choose distinct colors for different agents in same plugin
- Use consistent colors for similar agent types
- Blue/cyan: Analysis, review
- Green: Success-oriented tasks
- Yellow: Caution, validation
- Red: Critical, security
- Magenta: Creative, generation

### tools (optional)

Restrict agent to specific tools.

**Format:** Array of tool names

```yaml
tools: ["Read", "Write", "Grep", "Bash"]
```

**Default:** If omitted, agent has access to all tools

**Best practice:** Limit tools to minimum needed (principle of least privilege)

**Common tool sets:**
- Read-only analysis: `["Read", "Grep", "Glob"]`
- Code generation: `["Read", "Write", "Grep"]`
- Testing: `["Read", "Bash", "Grep"]`
- Full access: Omit field or use `["*"]`

## System Prompt Design

The markdown body becomes the agent's system prompt. Write in second person, addressing the agent directly.

### Structure

**Standard template:**
```markdown
You are [role] specializing in [domain].

**Your Core Responsibilities:**
1. [Primary responsibility]
2. [Secondary responsibility]
3. [Additional responsibilities...]

**Analysis Process:**
1. [Step one]
2. [Step two]
3. [Step three]
[...]

**Quality Standards:**
- [Standard 1]
- [Standard 2]

**Output Format:**
Provide results in this format:
- [What to include]
- [How to structure]

**Edge Cases:**
Handle these situations:
- [Edge case 1]: [How to handle]
- [Edge case 2]: [How to handle]
```

### Best Practices

✅ **DO:**
- Write in second person ("You are...", "You will...")
- Be specific about responsibilities
- Provide step-by-step process
- Define output format
- Include quality standards
- Address edge cases
- Keep under 10,000 characters

❌ **DON'T:**
- Write in first person ("I am...", "I will...")
- Be vague or generic
- Omit process steps
- Leave output format undefined
- Skip quality guidance
- Ignore error cases

## Creating Agents

### Method 1: AI-Assisted Generation

Use this prompt pattern (extracted from Claude Code):

```
Create an agent configuration based on this request: "[YOUR DESCRIPTION]"

Requirements:
1. Extract core intent and responsibilities
2. Design expert persona for the domain
3. Create comprehensive system prompt with:
   - Clear behavioral boundaries
   - Specific methodologies
   - Edge case handling
   - Output format
   - A "When to invoke" section listing 2-4 trigger scenarios as prose bullets
4. Create identifier (lowercase, hyphens, 3-50 chars)
5. Write description with triggering conditions and a short prose summary of trigger scenarios

Return JSON with:
{
  "identifier": "agent-name",
  "whenToUse": "Use this agent when... Typical triggers include [...]. See \"When to invoke\" in the agent body.",
  "systemPrompt": "You are..."
}
```

Then convert to agent file format with frontmatter.

See `examples/agent-creation-prompt.md` for complete template.

### Method 2: Manual Creation

1. Choose agent identifier (3-50 chars, lowercase, hyphens)
2. Write description with examples
3. Select model (usually `inherit`)
4. Choose color for visual identification
5. Define tools (if restricting access)
6. Write system prompt with structure above
7. Save as `agents/agent-name.md`

## Validation Rules

### Identifier Validation

```
✅ Valid: code-reviewer, test-gen, api-analyzer-v2
❌ Invalid: ag (too short), -start (starts with hyphen), my_agent (underscore)
```

**Rules:**
- 3-50 characters
- Lowercase letters, numbers, hyphens only
- Must start and end with alphanumeric
- No underscores, spaces, or special characters

### Description Validation

**Length:** 10-5,000 characters
**Must include:** Triggering conditions and examples
**Best:** 200-1,000 characters with 2-4 examples

### System Prompt Validation

**Length:** 20-10,000 characters
**Best:** 500-3,000 characters
**Structure:** Clear responsibilities, process, output format

## Agent Organization

### Plugin Agents Directory

```
plugin-name/
└── agents/
    ├── analyzer.md
    ├── reviewer.md
    └── generator.md
```

All `.md` files in `agents/` are auto-discovered.

### Namespacing

Agents are namespaced automatically:
- Single plugin: `agent-name`
- With subdirectories: `plugin:subdir:agent-name`

## Testing Agents

### Test Triggering

Create test scenarios to verify agent triggers correctly:

1. Write agent with specific triggering examples
2. Use similar phrasing to examples in test
3. Check Claude loads the agent
4. Verify agent provides expected functionality

### Test System Prompt

Ensure system prompt is complete:

1. Give agent typical task
2. Check it follows process steps
3. Verify output format is correct
4. Test edge cases mentioned in prompt
5. Confirm quality standards are met

## Quick Reference

### Minimal Agent

```markdown
---
name: simple-agent
description: Use this agent when [condition]. Typical triggers include [trigger 1] and [trigger 2]. See "When to invoke" in the agent body.
model: inherit
color: blue
---

You are an agent that [does X].

## When to invoke

- **[Scenario A].** [Description.]
- **[Scenario B].** [Description.]

Process:
1. [Step 1]
2. [Step 2]

Output: [What to provide]
```

### Frontmatter Fields Summary

| Field | Required | Format | Example |
|-------|----------|--------|---------|
| name | Yes | lowercase-hyphens | code-reviewer |
| description | Yes | Prose triggers | Use when... Typical triggers include... |
| model | Yes | inherit/sonnet/opus/haiku | inherit |
| color | Yes | Color name | blue |
| tools | No | Array of tool names | ["Read", "Grep"] |

### Best Practices

**DO:**
- ✅ Name 2-4 trigger scenarios in the description (as prose)
- ✅ Put detailed worked scenarios in a "When to invoke" body section, as prose bullets
- ✅ Write specific triggering conditions
- ✅ Use `inherit` for model unless specific need
- ✅ Choose appropriate tools (least privilege)
- ✅ Write clear, structured system prompts
- ✅ Test agent triggering thoroughly

**DON'T:**
- ❌ Use generic descriptions without trigger scenarios
- ❌ Omit triggering conditions
- ❌ Give all agents same color
- ❌ Grant unnecessary tool access
- ❌ Write vague system prompts
- ❌ Skip testing

## Additional Resources

### Reference Files

For detailed guidance, consult:

- **`references/system-prompt-design.md`** - Complete system prompt patterns
- **`references/triggering-examples.md`** - Example formats and best practices
- **`references/agent-creation-system-prompt.md`** - The exact prompt from Claude Code

### Example Files

Working examples in `examples/`:

- **`agent-creation-prompt.md`** - AI-assisted agent generation template
- **`complete-agent-examples.md`** - Full agent examples for different use cases

### Utility Scripts

Development tools in `scripts/`:

- **`validate-agent.sh`** - Validate agent file structure
- **`test-agent-trigger.sh`** - Test if agent triggers correctly

## Implementation Workflow

To create an agent for a plugin:

1. Define agent purpose and triggering conditions
2. Choose creation method (AI-assisted or manual)
3. Create `agents/agent-name.md` file
4. Write frontmatter with all required fields
5. Write system prompt following best practices
6. Name 2-4 trigger scenarios in description (prose) and detail them in a "When to invoke" body section
7. Validate with `scripts/validate-agent.sh`
8. Test triggering with real scenarios
9. Document agent in plugin README

Focus on clear triggering conditions and comprehensive system prompts for autonomous operation.


## --- Original Skill: agent-orchestration ---

# Agent Orchestration

Single entry point for all agent coordination. Reads the task and routes to the right mode.

## Dynamic Skill Discovery

**At session start, read the skills index to know what's available:**
- Linda: `~/.openclaw/workspace/skills/INDEX.md`
- Codex: `~/.codex/skills/` (list directory)
- Gemini CLI: `~/.gemini/skills/` (list directory)

This index is always current — new skills appear here automatically when added. Never assume the skill list is fixed; always check the index before routing.

---

## Mode Selection

```
Task requires coordinating 3+ skill domains?  → ORCHESTRATE mode
Task has truly independent parallel parts?    → PARALLEL DISPATCH mode
Task has a written implementation plan?       → SUBAGENT DEV mode
Task is large/repetitive coding work?         → CODEX mode
Task benefits from Google/web grounding?      → GEMINI mode
Starting any session?                         → SKILL AWARENESS mode
```

---

## SKILL AWARENESS MODE
*Governs every session — how to find and use skills*

**The Rule:** Before responding, check if a skill covers this task. Invoke it if the task matches trigger keywords in the description OR if the task's primary output type is what the skill produces.

**When in doubt:** a skill is worth invoking if skipping it would likely produce a worse result. A simple task with a matching skill still benefits from the skill.

**Priority order:**
1. Process skills first (planning, debugging) — determine HOW to approach
2. Implementation skills second — guide execution

**Red flags** (you're rationalizing — stop):
- "This is too simple" → Simple tasks have skills too
- "I need context first" → Skill check comes BEFORE clarifying questions
- "Let me explore first" → Skills tell you HOW to explore

**Skip only for:** pure conversational acknowledgments (ok, thanks, yes/no, got it)

**User instructions always override skills.** CLAUDE.md/AGENTS.md > superpowers skills > defaults.

---

## ORCHESTRATE MODE
*Multi-domain tasks requiring visible planning before execution*

### Phase 1: Plan
Identify connectors (data fetch) and skills (transform/produce), order connectors first.

```
[EXECUTION PLAN]
1. [Connector X]  — fetch [data]
2. [Skill A]      — process with [purpose]
3. [Skill B]      — format as [deliverable]
Skipped: [Skill C] — [reason]

Depth option: Run [Skill D] for [additional value]. Include it?
```

Wait for confirmation before executing.

### Phase 2: Execute
- Read each skill's SKILL.md only when about to execute it
- Forward only relevant output to next step (no blind pass-through)
- On connector failure: ask retry/skip/manual

### Phase 3: Synthesize
Chain results, merge overlapping content, flag conflicts.

```
[ORCHESTRATION SUMMARY]
- [Step 1]: executed — [result]
- [Step 2]: failed — [reason], impact: low/medium/high

[UNIFIED RESULT]
[The actual deliverable]
```

**Conflict hierarchy:** Legal/Compliance > Security > Operations > Design/UX

**Token awareness:** At ~80% budget → pause and ask "Continue or synthesize now?"

---

## PARALLEL DISPATCH MODE
*2+ independent tasks that can run without shared state*

**Use when:** Multiple failures with different root causes, no shared state between investigations.

**Don't use when:** Failures are related, need full system context, agents would edit same files, or tasks share config/logging/error context (they're not truly independent).

### The Pattern
1. **Identify independent domains** — group problems by what's broken
2. **Craft focused agent tasks** — each gets: specific scope, clear goal, constraints, expected output
3. **Dispatch concurrently** — one agent per domain
4. **Integrate results** — verify no conflicts, run full test suite

**Good agent prompt:**
```
Fix the failing tests in [file]:
1. [test name] — [what it expects]

These are [type] issues. Your task:
1. Read the test file
2. Identify root cause
3. Fix — do NOT [constraint]
Return: Summary of root cause and changes made.
```

---

## SUBAGENT DEV MODE
*Executing an implementation plan task-by-task*

**Pre-check:** Task tool available? → Subagent mode (preferred). No Task tool? → Inline mode.

Announce: "Using agent-orchestration in [subagent|inline] mode."

**REQUIRED first:** Set up isolated workspace with dev-workflow skill (WORKTREE mode).

### Subagent Mode (per task)
1. Dispatch implementer with full task text + context
2. After implementation: dispatch spec reviewer
3. If spec passes: dispatch code quality reviewer
4. Fix issues → mark complete → commit

Model selection: mechanical 1-2 file tasks → cheap; multi-file → standard; architecture → most capable.

**After all tasks:** Use dev-workflow skill (FINISH BRANCH mode).

### Inline Mode (no subagents)
1. Implement following TDD
2. Self-review against spec, then for quality
3. Fix before marking complete, commit
4. Every 3 tasks: pause, run full suite, report progress

**Stop and ask when:** Blocker, repeated test failure (3+), unclear instruction, plan has critical gaps.

---

## GEMINI MODE
*Tasks that benefit from Google search grounding, large context, or a second model opinion — delegate to Gemini CLI*

**Delegate when:** Research requiring live web/Google grounding, large-context analysis (100k+ tokens), multi-source synthesis, scaffolding across 3+ files, or user says "use gemini" / "run gemini" / "ask gemini".

**Handle in-house when:** Task requires Claude-specific tools (computer use, MCP servers, skills), quick single-file fixes, or code review.

Full details: read `gemini-dispatcher` skill. Summary:
1. **Detect binary:** `which gemini` or check `~/.local/bin/gemini`, `/opt/homebrew/bin/gemini`.
2. **Pick model:** `gemini-2.5-pro` (complex/large), `gemini-2.5-flash` (fast/boilerplate).
3. **Approval mode:** `--approval-mode auto_edit` (default), `--yolo` (low-risk fast tasks), `--approval-mode plan` (read-only).
4. **Run:** `gemini --model $M $APPROVAL --prompt "$P"`
5. **Resume:** `gemini --resume latest` to continue previous session.
6. **Critical review:** Read output → verify vs spec → dispute wrong choices → escalate after 2 failed corrections.
7. **Wrap-up:** Report model, mode, what was done.

---

## CODEX MODE
*Large/multi-file coding — delegate to OpenAI Codex CLI*

**Delegate when:** Refactoring 3+ files, scaffolding project/feature, boilerplate for 3+ entities, writing test suites for existing code, estimated 10+ sequential tool calls.

**Handle in-house when:** Questions, code review, 1-2 file changes, quick bug fix.

### Steps
1. **Detect binary:** Check `~/.local/bin/codex`, `~/bin/codex`, `/usr/local/bin/codex`, `/opt/homebrew/bin/codex`. Not found → fall back to Claude.
2. **Validate flags:** Run `codex --help`, verify `--model`, `--reasoning`, `--sandbox`, `--prompt`.
3. **Ask user:** Model + reasoning effort (default: `xhigh`).
4. **Write prompt:**
   ```
   You are working on [PROJECT]. Your task: [EXACT TASK]
   Constraints: [list]. Success criteria: [what done looks like]
   ```
5. **Run:** `codex --model $M --reasoning $E --sandbox $S --no-git-check --quiet --yes --prompt "$P"`
6. **Critical review:** Read diff → verify vs spec → dispute wrong choices → escalate after 2 failed corrections. ("Escalate" = stop Codex, explain the issue to the user, and ask how to proceed inline.)
7. **Wrap-up:** Report model, effort, what was done in 2-3 sentences.

**Sandbox:** read-only / workspace-write / full (full requires explicit user confirmation)

---

## SKILL PIPELINE MAP
*How skills connect — use this to avoid sequencing errors*

**Standard development pipeline:**
```
planning (BRAINSTORM) → writing (PLAN mode) → dev-workflow (WORKTREE SETUP)
  → agent-orchestration (SUBAGENT DEV) or dev-workflow (EXECUTE PLAN)
  → code-review (REQUEST) [after each task or batch]
  → planning (VERIFY) or dev-workflow (FINISH BRANCH)
```

**Key handoffs:**
- `planning` always comes before any implementation — it writes the spec
- `writing` (PLAN mode) always comes before `dev-workflow` or `agent-orchestration` — it writes the plan
- `dev-workflow` (WORKTREE SETUP) always comes before executing any plan
- `code-review` (REQUEST) runs after tasks complete, before marking done
- `planning` (VERIFY) or `dev-workflow` (FINISH BRANCH) is the final gate before shipping

**Skill ownership boundaries:**
- **Creating a new skill:** `builder` (SKILL CREATOR mode)
- **Editing an existing skill:** `writing` (SKILL CONTENT mode)
- **Plan writing:** `writing` (PLAN mode) — not planning skill, not dev-workflow
- **Verification before done:** `planning` (VERIFY mode)
- **Branch shipping:** `dev-workflow` (FINISH BRANCH mode)
- **Heavy coding delegation:** `codex-dispatcher` (full decision matrix + flag validation)
- **Web/research/large-context delegation:** `gemini-dispatcher` (model selection + approval modes)

**Dispatcher routing:**
```
Heavy multi-file coding / boilerplate / test suites  → codex-dispatcher
Web grounding / large context / second opinion        → gemini-dispatcher
Everything else                                       → handle in-house or subagent
```

**When subagents aren't available:**
Fall back to inline execution via `dev-workflow` (EXECUTE PLAN mode). Quality cost is ~10% lower; takes longer. Tell the user if this fallback applies.

**Skill list is dynamic:** New skills auto-appear in the index. Re-read INDEX.md if you're unsure whether a skill exists for a task.


## --- Original Skill: agents-sdk ---

# Cloudflare Agents SDK

Your knowledge of the Agents SDK may be outdated. **Prefer retrieval over pre-training** for any Agents SDK task.

## Retrieval Sources

Cloudflare docs: https://developers.cloudflare.com/agents/

| Topic | Docs URL | Use for |
|-------|----------|---------|
| Getting started | [Quick start](https://developers.cloudflare.com/agents/getting-started/quick-start/) | First agent, project setup |
| Adding to existing project | [Add to existing project](https://developers.cloudflare.com/agents/getting-started/add-to-existing-project/) | Install into existing Workers app |
| Configuration | [Configuration](https://developers.cloudflare.com/agents/api-reference/configuration/) | `wrangler.jsonc`, bindings, assets, deployment |
| Agent class | [Agents API](https://developers.cloudflare.com/agents/api-reference/agents-api/) | Agent lifecycle, patterns, pitfalls |
| State | [Store and sync state](https://developers.cloudflare.com/agents/api-reference/store-and-sync-state/) | `setState`, `validateStateChange`, persistence |
| Routing | [Routing](https://developers.cloudflare.com/agents/api-reference/routing/) | URL patterns, `routeAgentRequest` |
| Callable methods | [Callable methods](https://developers.cloudflare.com/agents/api-reference/callable-methods/) | `@callable`, RPC, streaming, timeouts |
| Scheduling | [Schedule tasks](https://developers.cloudflare.com/agents/api-reference/schedule-tasks/) | `schedule()`, `scheduleEvery()`, cron |
| Workflows | [Run workflows](https://developers.cloudflare.com/agents/api-reference/run-workflows/) | `AgentWorkflow`, durable multi-step tasks |
| HTTP/WebSockets | [WebSockets](https://developers.cloudflare.com/agents/api-reference/websockets/) | Lifecycle hooks, hibernation |
| Chat agents | [Chat agents](https://developers.cloudflare.com/agents/api-reference/chat-agents/) | `AIChatAgent`, streaming, tools, persistence |
| Client SDK | [Client SDK](https://developers.cloudflare.com/agents/api-reference/client-sdk/) | `useAgent`, `useAgentChat`, React hooks |
| Client tools | [Client tools](https://developers.cloudflare.com/agents/api-reference/client-tools/) | Client-side tools, `autoContinueAfterToolResult` |
| Server-driven messages | [Trigger patterns](https://developers.cloudflare.com/agents/api-reference/trigger-patterns/) | `saveMessages`, `waitUntilStable`, server-initiated turns |
| Resumable streaming | [Resumable streaming](https://developers.cloudflare.com/agents/api-reference/resumable-streaming/) | Stream recovery on disconnect |
| Email | [Email](https://developers.cloudflare.com/agents/api-reference/email/) | Email routing, secure reply resolver |
| MCP client | [MCP client](https://developers.cloudflare.com/agents/api-reference/mcp-client-api/) | Connecting to MCP servers |
| MCP server | [MCP server](https://developers.cloudflare.com/agents/api-reference/mcp-agent-api/) | Building MCP servers with `McpAgent` |
| MCP transports | [MCP transports](https://developers.cloudflare.com/agents/api-reference/mcp-transports/) | Streamable HTTP, SSE, RPC transport options |
| Securing MCP servers | [Securing MCP](https://developers.cloudflare.com/agents/api-reference/securing-mcp-servers/) | OAuth, proxy MCP, hardening |
| Human-in-the-loop | [Human-in-the-loop](https://developers.cloudflare.com/agents/concepts/human-in-the-loop/) | Approval flows, `needsApproval`, workflows |
| Durable execution | [Durable execution](https://developers.cloudflare.com/agents/api-reference/durable-execution/) | `runFiber()`, `stash()`, surviving DO eviction |
| Queue | [Queue](https://developers.cloudflare.com/agents/api-reference/queue-tasks/) | Built-in FIFO queue, `queue()` |
| Retries | [Retries](https://developers.cloudflare.com/agents/api-reference/retries/) | `this.retry()`, backoff/jitter |
| Observability | [Observability](https://developers.cloudflare.com/agents/api-reference/observability/) | Diagnostics-channel events |
| Push notifications | [Push notifications](https://developers.cloudflare.com/agents/api-reference/push-notifications/) | Web Push + VAPID from agents |
| Webhooks | [Webhooks](https://developers.cloudflare.com/agents/api-reference/webhooks/) | Receiving external webhooks |
| Cross-domain auth | [Cross-domain auth](https://developers.cloudflare.com/agents/api-reference/cross-domain-authentication/) | WebSocket auth, tokens, CORS |
| Readonly connections | [Readonly](https://developers.cloudflare.com/agents/api-reference/readonly-connections/) | `shouldConnectionBeReadonly` |
| Voice | [Voice](https://developers.cloudflare.com/agents/api-reference/voice/) | Experimental STT/TTS, `withVoice` |
| Browse the web | [Browser tools](https://developers.cloudflare.com/agents/api-reference/browse-the-web/) | Experimental CDP browser automation |
| Think | [Think](https://developers.cloudflare.com/agents/api-reference/think/) | Experimental higher-level chat agent class |
| Migrations | [AI SDK v5](https://developers.cloudflare.com/agents/guides/migration-to-ai-sdk-v5/), [AI SDK v6](https://developers.cloudflare.com/agents/guides/migration-to-ai-sdk-v6/) | Upgrading `@cloudflare/ai-chat` |

## Capabilities

The Agents SDK provides:

- **Persistent state** — SQLite-backed, auto-synced to clients via `setState`
- **Callable RPC** — `@callable()` methods invoked over WebSocket
- **Scheduling** — One-time, recurring (`scheduleEvery`), and cron tasks
- **Workflows** — Durable multi-step background processing via `AgentWorkflow`
- **Durable execution** — `runFiber()` / `stash()` for work that survives DO eviction
- **Queue** — Built-in FIFO queue with retries via `queue()`
- **Retries** — `this.retry()` with exponential backoff and jitter
- **MCP integration** — Connect to MCP servers or build your own with `McpAgent`
- **Email handling** — Receive and reply to emails with secure routing
- **Streaming chat** — `AIChatAgent` with resumable streams, message persistence, tools
- **Server-driven messages** — `saveMessages`, `waitUntilStable` for proactive agent turns
- **React hooks** — `useAgent`, `useAgentChat` for client apps
- **Observability** — `diagnostics_channel` events for state, RPC, schedule, lifecycle
- **Push notifications** — Web Push + VAPID delivery from agents
- **Webhooks** — Receive and verify external webhooks
- **Voice** (experimental) — STT/TTS via `@cloudflare/voice`
- **Browser tools** (experimental) — CDP-powered browsing via `agents/browser`
- **Think** (experimental) — Higher-level chat agent via `@cloudflare/think`

## FIRST: Verify Installation

```bash
npm ls agents  # Should show agents package
```

If not installed:
```bash
npm install agents
```

For chat agents:
```bash
npm install agents @cloudflare/ai-chat ai @ai-sdk/react
```

## Wrangler Configuration

```jsonc
{
  "compatibility_flags": ["nodejs_compat"],
  "durable_objects": {
    "bindings": [{ "name": "MyAgent", "class_name": "MyAgent" }]
  },
  "migrations": [{ "tag": "v1", "new_sqlite_classes": ["MyAgent"] }]
}
```

**Gotchas:**
- Do NOT enable `experimentalDecorators` in tsconfig (breaks `@callable`)
- Never edit old migrations — always add new tags
- Each agent class needs its own DO binding + migration entry
- Add `"ai": { "binding": "AI" }` for Workers AI

## Agent Class

```typescript
import { Agent, routeAgentRequest, callable } from "agents";

type State = { count: number };

export class Counter extends Agent<Env, State> {
  initialState = { count: 0 };

  validateStateChange(nextState: State, source: Connection | "server") {
    if (nextState.count < 0) throw new Error("Count cannot be negative");
  }

  onStateUpdate(state: State, source: Connection | "server") {
    console.log("State updated:", state);
  }

  @callable()
  increment() {
    this.setState({ count: this.state.count + 1 });
    return this.state.count;
  }
}

export default {
  fetch: (req, env) => routeAgentRequest(req, env) ?? new Response("Not found", { status: 404 })
};
```

## Routing

Requests route to `/agents/{agent-name}/{instance-name}`:

| Class | URL |
|-------|-----|
| `Counter` | `/agents/counter/user-123` |
| `ChatRoom` | `/agents/chat-room/lobby` |

Client: `useAgent({ agent: "Counter", name: "user-123" })`

Custom routing: use `getAgentByName(env.MyAgent, "instance-id")` then `agent.fetch(request)`.

## Core APIs

| Task | API |
|------|-----|
| Read state | `this.state.count` |
| Write state | `this.setState({ count: 1 })` |
| SQL query | `` this.sql`SELECT * FROM users WHERE id = ${id}` `` |
| Schedule (delay) | `await this.schedule(60, "task", payload)` |
| Schedule (cron) | `await this.schedule("0 * * * *", "task", payload)` |
| Schedule (interval) | `await this.scheduleEvery(30, "poll")` |
| RPC method | `@callable() myMethod() { ... }` |
| Streaming RPC | `@callable({ streaming: true }) stream(res) { ... }` |
| Start workflow | `await this.runWorkflow("ProcessingWorkflow", params)` |
| Durable fiber | `await this.runFiber("name", async (ctx) => { ... })` |
| Enqueue work | `this.queue("handler", payload)` |
| Retry with backoff | `await this.retry(fn, { maxAttempts: 5 })` |
| Broadcast to clients | `this.broadcast(message)` |
| Get connections | `this.getConnections(tag?)` |

## React Client

```tsx
import { useAgent } from "agents/react";

function App() {
  const [state, setLocalState] = useState({ count: 0 });

  const agent = useAgent({
    agent: "Counter",
    name: "my-instance",
    onStateUpdate: (newState) => setLocalState(newState),
    onIdentity: (name, agentType) => console.log(`Connected to ${name}`)
  });

  return (
    <button onClick={() => agent.setState({ count: state.count + 1 })}>
      Count: {state.count}
    </button>
  );
}
```

## References

### Core
- **[references/state-scheduling.md](references/state-scheduling.md)** — State persistence, scheduling, SQL
- **[references/callable.md](references/callable.md)** — RPC methods, streaming, timeouts
- **[references/routing.md](references/routing.md)** — URL patterns, custom routing, `getAgentByName`
- **[references/configuration.md](references/configuration.md)** — Wrangler config, bindings, Vite setup

### Chat & Streaming
- **[references/streaming-chat.md](references/streaming-chat.md)** — AIChatAgent, resumable streams, tools
- **[references/client-sdk.md](references/client-sdk.md)** — `useAgent`, `useAgentChat`, `AgentClient`
- **[references/server-driven-messages.md](references/server-driven-messages.md)** — Trigger patterns, `saveMessages`
- **[references/human-in-the-loop.md](references/human-in-the-loop.md)** — Approval flows, `needsApproval`

### Background Processing
- **[references/workflows.md](references/workflows.md)** — Durable Workflows integration
- **[references/durable-execution.md](references/durable-execution.md)** — `runFiber`, `stash`, surviving eviction
- **[references/queue-retries.md](references/queue-retries.md)** — Built-in queue, retry with backoff

### Integrations
- **[references/mcp.md](references/mcp.md)** — MCP client and server, transports, securing
- **[references/email.md](references/email.md)** — Email routing and handling
- **[references/webhooks-push.md](references/webhooks-push.md)** — Webhooks, push notifications
- **[references/observability.md](references/observability.md)** — Diagnostics-channel events

### Experimental
- **[references/think.md](references/think.md)** — `@cloudflare/think` higher-level chat agent
- **[references/voice.md](references/voice.md)** — `@cloudflare/voice` STT/TTS
- **[references/codemode.md](references/codemode.md)** — Code Mode for tool orchestration
- **[references/browse-the-web.md](references/browse-the-web.md)** — CDP browser tools


## --- Original Skill: skill-creator ---

# Skill Creator

A skill for creating new skills and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run claude-with-access-to-the-skill on them
- Help the user evaluate the results both qualitatively and quantitatively
  - While the runs happen in the background, draft some quantitative evals if there aren't any (if there are some, you can either use as is or modify if you feel something needs to change about them). Then explain them to the user (or if they already existed, explain the ones that already exist)
  - Use the `eval-viewer/generate_review.py` script to show the user the results for them to look at, and also let them look at the quantitative metrics
- Rewrite the skill based on feedback from the user's evaluation of the results (and also if there are any glaring flaws that become apparent from the quantitative benchmarks)
- Repeat until you're satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages. So for instance, maybe they're like "I want to make a skill for X". You can help narrow down what they mean, write a draft, write the test cases, figure out how they want to evaluate, run all the prompts, and repeat.

On the other hand, maybe they already have a draft of the skill. In this case you can go straight to the eval/iterate part of the loop.

Of course, you should always be flexible and if the user is like "I don't need to run a bunch of evaluations, just vibe with me", you can do that instead.

Then after the skill is done (but again, the order is flexible), you can also run the skill description improver, which we have a whole separate script for, to optimize the triggering of the skill.

Cool? Cool.

## Communicating with the user

The skill creator is liable to be used by people across a wide range of familiarity with coding jargon. If you haven't heard (and how could you, it's only very recently that it started), there's a trend now where the power of Claude is inspiring plumbers to open up their terminals, parents and grandparents to google "how to install npm". On the other hand, the bulk of users are probably fairly computer-literate.

So please pay attention to context cues to understand how to phrase your communication! In the default case, just to give you some idea:

- "evaluation" and "benchmark" are borderline, but OK
- for "JSON" and "assertion" you want to see serious cues from the user that they know what those things are before using them without explaining them

It's OK to briefly explain terms if you're in doubt, and feel free to clarify terms with a short definition if you're unsure if the user will get it.

---

## Creating a skill

### Capture Intent

Start by understanding the user's intent. The current conversation might already contain a workflow the user wants to capture (e.g., they say "turn this into a skill"). If so, extract answers from the conversation history first — the tools used, the sequence of steps, corrections the user made, input/output formats observed. The user may need to fill the gaps, and should confirm before proceeding to the next step.

1. What should this skill enable Claude to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflow steps) benefit from test cases. Skills with subjective outputs (writing style, art) often don't need them. Suggest the appropriate default based on the skill type, but let the user decide.

### Interview and Research

Proactively ask questions about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until you've got this part ironed out.

Check available MCPs - if useful for research (searching docs, finding similar skills, looking up best practices), research in parallel via subagents if available, otherwise inline. Come prepared with context to reduce burden on the user.

### Write the SKILL.md

Based on the user interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. This is the primary triggering mechanism - include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Note: currently Claude has a tendency to "undertrigger" skills -- to not use them when they'd be useful. To combat this, please make the skill descriptions a little bit "pushy". So for instance, instead of "How to build a simple fast dashboard to display internal Anthropic data.", you might write "How to build a simple fast dashboard to display internal Anthropic data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a 'dashboard.'"
- **compatibility**: Required tools, dependencies (optional, rarely needed)
- **the rest of the skill :)**

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can execute without loading)

These word counts are approximate and you can feel free to go longer if needed.

**Key patterns:**
- Keep SKILL.md under 500 lines; if you're approaching this limit, add an additional layer of hierarchy along with clear pointers about where the model using the skill should go next to follow up.
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

**Domain organization**: When a skill supports multiple domains/frameworks, organize by variant:
```
cloud-deploy/
├── SKILL.md (workflow + selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
Claude reads only the relevant reference file.

#### Principle of Lack of Surprise

This goes without saying, but skills must not contain malware, exploit code, or any content that could compromise system security. A skill's contents should not surprise the user in their intent if described. Don't go along with requests to create misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activities. Things like a "roleplay as an XYZ" are OK though.

#### Writing Patterns

Prefer using the imperative form in instructions.

**Defining output formats** - You can do it like this:
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern** - It's useful to include examples. You can format them like this (but if "Input" and "Output" are in the examples you might want to deviate a little):
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs. Use theory of mind and try to make the skill general and not super-narrow to specific examples. Start by writing a draft and then look at it with fresh eyes and improve it.

### Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts — the kind of thing a real user would actually say. Share them with the user: [you don't have to use this exact language] "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json`. Don't write assertions yet — just the prompts. You'll draft assertions in the next step while the runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema (including the `assertions` field, which you'll add later).

## Running and evaluating test cases

This section is one continuous sequence — don't stop partway through. Do NOT use `/skill-test` or any other testing skill.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory (`eval-0/`, `eval-1/`, etc.). Don't create all of this upfront — just create directories as you go.

### Step 1: Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents in the same turn — one with the skill, one without. This is important: don't spawn the with-skill runs first and then come back for baselines later. Launch everything at once so it all finishes around the same time.

**With-skill run:**

```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about — e.g., "the .docx file", "the final CSV">
```

**Baseline run** (same prompt, but the baseline depends on context):
- **Creating a new skill**: no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- **Improving an existing skill**: the old version. Before editing, snapshot the skill (`cp -r <skill-path> <workspace>/skill-snapshot/`), then point the baseline subagent at the snapshot. Save to `old_skill/outputs/`.

Write an `eval_metadata.json` for each test case (assertions can be empty for now). Give each eval a descriptive name based on what it's testing — not just "eval-0". Use this name for the directory too. If this iteration uses new or modified eval prompts, create these files for each new eval directory — don't assume they carry over from previous iterations.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs are in progress, draft assertions

Don't just wait for the runs to finish — you can use this time productively. Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them and explain what they check.

Good assertions are objectively verifiable and have descriptive names — they should read clearly in the benchmark viewer so someone glancing at the results immediately understands what each one checks. Subjective skills (writing style, design quality) are better evaluated qualitatively — don't force assertions onto things that need human judgment.

Update the `eval_metadata.json` files and `evals/evals.json` with the assertions once drafted. Also explain to the user what they'll see in the viewer — both the qualitative outputs and the quantitative benchmark.

### Step 3: As runs complete, capture timing data

When each subagent task completes, you receive a notification containing `total_tokens` and `duration_ms`. Save this data immediately to `timing.json` in the run directory:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

This is the only opportunity to capture this data — it comes through the task notification and isn't persisted elsewhere. Process each notification as it arrives rather than trying to batch them.

### Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run** — spawn a grader subagent (or grade inline) that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json` in each run directory. The grading.json expectations array must use the fields `text`, `passed`, and `evidence` (not `name`/`met`/`details` or other variants) — the viewer depends on these exact field names. For assertions that can be checked programmatically, write and run a script rather than eyeballing it — scripts are faster, more reliable, and can be reused across iterations.

2. **Aggregate into benchmark** — run the aggregation script from the skill-creator directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens for each configuration, with mean ± stddev and the delta. If generating benchmark.json manually, see `references/schemas.md` for the exact schema the viewer expects.
Put each with_skill version before its baseline counterpart.

3. **Do an analyst pass** — read the benchmark data and surface patterns the aggregate stats might hide. See `agents/analyzer.md` (the "Analyzing Benchmark Results" section) for what to look for — things like assertions that always pass regardless of skill (non-discriminating), high-variance evals (possibly flaky), and time/token tradeoffs.

4. **Launch the viewer** with both qualitative outputs and quantitative data:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   **Cowork / headless environments:** If `webbrowser.open()` is not available or the environment has no display, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Feedback will be downloaded as a `feedback.json` file when the user clicks "Submit All Reviews". After download, copy `feedback.json` into the workspace directory for the next iteration to pick up.

Note: please use generate_review.py to create the viewer; there's no need to write custom HTML.

5. **Tell the user** something like: "I've opened the results in your browser. There are two tabs — 'Outputs' lets you click through each test case and leave feedback, 'Benchmark' shows the quantitative comparison. When you're done, come back here and let me know."

### What the user sees in the viewer

The "Outputs" tab shows one test case at a time:
- **Prompt**: the task that was given
- **Output**: the files the skill produced, rendered inline where possible
- **Previous Output** (iteration 2+): collapsed section showing last iteration's output
- **Formal Grades** (if grading was run): collapsed section showing assertion pass/fail
- **Feedback**: a textbox that auto-saves as they type
- **Previous Feedback** (iteration 2+): their comments from last time, shown below the textbox

The "Benchmark" tab shows the stats summary: pass rates, timing, and token usage for each configuration, with per-eval breakdowns and analyst observations.

Navigation is via prev/next buttons or arrow keys. When done, they click "Submit All Reviews" which saves all feedback to `feedback.json`.

### Step 5: Read the feedback

When the user tells you they're done, read `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."},
    {"run_id": "eval-2-with_skill", "feedback": "perfect, love this", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the user thought it was fine. Focus your improvements on the test cases where the user had specific complaints.

Kill the viewer server when you're done with it:

```bash
kill $VIEWER_PID 2>/dev/null
```

---

## Improving the skill

This is the heart of the loop. You've run the test cases, the user has reviewed the results, and now you need to make the skill better based on their feedback.

### How to think about improvements

1. **Generalize from the feedback.** The big picture thing that's happening here is that we're trying to create skills that can be used a million times (maybe literally, maybe even more who knows) across many different prompts. Here you and the user are iterating on only a few examples over and over again because it helps move faster. The user knows these examples in and out and it's quick for them to assess new outputs. But if the skill you and the user are codeveloping works only for those examples, it's useless. Rather than put in fiddly overfitty changes, or oppressively constrictive MUSTs, if there's some stubborn issue, you might try branching out and using different metaphors, or recommending different patterns of working. It's relatively cheap to try and maybe you'll land on something great.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight. Make sure to read the transcripts, not just the final outputs — if it looks like the skill is making the model waste a bunch of time doing things that are unproductive, you can try getting rid of the parts of the skill that are making it do that and seeing what happens.

3. **Explain the why.** Try hard to explain the **why** behind everything you're asking the model to do. Today's LLMs are *smart*. They have good theory of mind and when given a good harness can go beyond rote instructions and really make things happen. Even if the feedback from the user is terse or frustrated, try to actually understand the task and why the user is writing what they wrote, and what they actually wrote, and then transmit this understanding into the instructions. If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag — if possible, reframe and explain the reasoning so that the model understands why the thing you're asking for is important. That's a more humane, powerful, and effective approach.

4. **Look for repeated work across test cases.** Read the transcripts from the test runs and notice if the subagents all independently wrote similar helper scripts or took the same multi-step approach to something. If all 3 test cases resulted in the subagent writing a `create_docx.py` or a `build_chart.py`, that's a strong signal the skill should bundle that script. Write it once, put it in `scripts/`, and tell the skill to use it. This saves every future invocation from reinventing the wheel.

This task is pretty important (we are trying to create billions a year in economic value here!) and your thinking time is not the blocker; take your time and really mull things over. I'd suggest writing a draft revision and then looking at it anew and making improvements. Really do your best to get into the head of the user and understand what they want and need.

### The iteration loop

After improving the skill:

1. Apply your improvements to the skill
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baseline runs. If you're creating a new skill, the baseline is always `without_skill` (no skill) — that stays the same across iterations. If you're improving an existing skill, use your judgment on what makes sense as the baseline: the original version the user came in with, or the previous iteration.
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for the user to review and tell you they're done
5. Read the new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- The feedback is all empty (everything looks good)
- You're not making meaningful progress

---

## Advanced: Blind comparison

For situations where you want a more rigorous comparison between two versions of a skill (e.g., the user asks "is the new version actually better?"), there's a blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md` for the details. The basic idea is: give two outputs to an independent agent without telling it which is which, and let it judge quality. Then analyze why the winner won.

This is optional, requires subagents, and most users won't need it. The human review loop is usually sufficient.

---

## Description Optimization

The description field in SKILL.md frontmatter is the primary mechanism that determines whether Claude invokes a skill. After creating or improving a skill, offer to optimize the description for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

The queries must be realistic and something a Claude Code or Claude.ai user would actually type. Not abstract requests, but requests that are concrete and specific and have a good amount of detail. For instance, file paths, personal context about the user's job or situation, column names and values, company names, URLs. A little bit of backstory. Some might be in lowercase or contain abbreviations or typos or casual speech. Use a mix of different lengths, and focus on edge cases rather than making them clear-cut (the user will get a chance to sign off on them).

Bad: `"Format this data"`, `"Extract text from PDF"`, `"Create a chart"`

Good: `"ok so my boss just sent me this xlsx file (its in my downloads, called something like 'Q4 sales final FINAL v2.xlsx') and she wants me to add a column that shows the profit margin as a percentage. The revenue is in column C and costs are in column D i think"`

For the **should-trigger** queries (8-10), think about coverage. You want different phrasings of the same intent — some formal, some casual. Include cases where the user doesn't explicitly name the skill or file type but clearly needs it. Throw in some uncommon use cases and cases where this skill competes with another but should win.

For the **should-not-trigger** queries (8-10), the most valuable ones are the near-misses — queries that share keywords or concepts with the skill but actually need something different. Think adjacent domains, ambiguous phrasing where a naive keyword match would trigger but shouldn't, and cases where the query touches on something the skill does but in a context where another tool is more appropriate.

The key thing to avoid: don't make should-not-trigger queries obviously irrelevant. "Write a fibonacci function" as a negative test for a PDF skill is too easy — it doesn't test anything. The negative cases should be genuinely tricky.

### Step 2: Review with user

Present the eval set to the user for review using the HTML template:

1. Read the template from `assets/eval_review.html`
2. Replace the placeholders:
   - `__EVAL_DATA_PLACEHOLDER__` → the JSON array of eval items (no quotes around it — it's a JS variable assignment)
   - `__SKILL_NAME_PLACEHOLDER__` → the skill's name
   - `__SKILL_DESCRIPTION_PLACEHOLDER__` → the skill's current description
3. Write to a temp file (e.g., `/tmp/eval_review_<skill-name>.html`) and open it: `open /tmp/eval_review_<skill-name>.html`
4. The user can edit queries, toggle should-trigger, add/remove entries, then click "Export Eval Set"
5. The file downloads to `~/Downloads/eval_set.json` — check the Downloads folder for the most recent version in case there are multiple (e.g., `eval_set (1).json`)

This step matters — bad eval queries lead to bad descriptions.

### Step 3: Run the optimization loop

Tell the user: "This will take some time — I'll run the optimization loop in the background and check on it periodically."

Save the eval set to the workspace, then run in the background:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt (the one powering the current session) so the triggering test matches what the user actually experiences.

While it runs, periodically tail the output to give the user updates on which iteration it's on and what the scores look like.

This handles the full optimization loop automatically. It splits the eval set into 60% train and 40% held-out test, evaluates the current description (running each query 3 times to get a reliable trigger rate), then calls Claude to propose improvements based on what failed. It re-evaluates each new description on both train and test, iterating up to 5 times. When it's done, it opens an HTML report in the browser showing the results per iteration and returns JSON with `best_description` — selected by test score rather than train score to avoid overfitting.

### How skill triggering works

Understanding the triggering mechanism helps design better eval queries. Skills appear in Claude's `available_skills` list with their name + description, and Claude decides whether to consult a skill based on that description. The important thing to know is that Claude only consults skills for tasks it can't easily handle on its own — simple, one-step queries like "read this PDF" may not trigger a skill even if the description matches perfectly, because Claude can handle them directly with basic tools. Complex, multi-step, or specialized queries reliably trigger skills when the description matches.

This means your eval queries should be substantive enough that Claude would actually benefit from consulting a skill. Simple queries like "read file X" are poor test cases — they won't trigger skills regardless of description quality.

### Step 4: Apply the result

Take `best_description` from the JSON output and update the skill's SKILL.md frontmatter. Show the user before/after and report the scores.

---

### Package and Present (only if `present_files` tool is available)

Check whether you have access to the `present_files` tool. If you don't, skip this step. If you do, package the skill and present the .skill file to the user:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

After packaging, direct the user to the resulting `.skill` file path so they can install it.

---

## Claude.ai-specific instructions

In Claude.ai, the core workflow is the same (draft → test → review → improve → repeat), but because Claude.ai doesn't have subagents, some mechanics change. Here's what to adapt:

**Running test cases**: No subagents means no parallel execution. For each test case, read the skill's SKILL.md, then follow its instructions to accomplish the test prompt yourself. Do them one at a time. This is less rigorous than independent subagents (you wrote the skill and you're also running it, so you have full context), but it's a useful sanity check — and the human review step compensates. Skip the baseline runs — just use the skill to complete the task as requested.

**Reviewing results**: If you can't open a browser (e.g., Claude.ai's VM has no display, or you're on a remote server), skip the browser reviewer entirely. Instead, present results directly in the conversation. For each test case, show the prompt and the output. If the output is a file the user needs to see (like a .docx or .xlsx), save it to the filesystem and tell them where it is so they can download and inspect it. Ask for feedback inline: "How does this look? Anything you'd change?"

**Benchmarking**: Skip the quantitative benchmarking — it relies on baseline comparisons which aren't meaningful without subagents. Focus on qualitative feedback from the user.

**The iteration loop**: Same as before — improve the skill, rerun the test cases, ask for feedback — just without the browser reviewer in the middle. You can still organize results into iteration directories on the filesystem if you have one.

**Description optimization**: This section requires the `claude` CLI tool (specifically `claude -p`) which is only available in Claude Code. Skip it if you're on Claude.ai.

**Blind comparison**: Requires subagents. Skip it.

**Packaging**: The `package_skill.py` script works anywhere with Python and a filesystem. On Claude.ai, you can run it and the user can download the resulting `.skill` file.

**Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. In this case:
- **Preserve the original name.** Note the skill's directory name and `name` frontmatter field -- use them unchanged. E.g., if the installed skill is `research-helper`, output `research-helper.skill` (not `research-helper-v2`).
- **Copy to a writeable location before editing.** The installed skill path may be read-only. Copy to `/tmp/skill-name/`, edit there, and package from the copy.
- **If packaging manually, stage in `/tmp/` first**, then copy to the output directory -- direct writes may fail due to permissions.

---

## Cowork-Specific Instructions

If you're in Cowork, the main things to know are:

- You have subagents, so the main workflow (spawn test cases in parallel, run baselines, grade, etc.) all works. (However, if you run into severe problems with timeouts, it's OK to run the test prompts in series rather than parallel.)
- You don't have a browser or display, so when generating the eval viewer, use `--static <output_path>` to write a standalone HTML file instead of starting a server. Then proffer a link that the user can click to open the HTML in their browser.
- For whatever reason, the Cowork setup seems to disincline Claude from generating the eval viewer after running the tests, so just to reiterate: whether you're in Cowork or in Claude Code, after running tests, you should always generate the eval viewer for the human to look at examples before revising the skill yourself and trying to make corrections, using `generate_review.py` (not writing your own boutique html code). Sorry in advance but I'm gonna go all caps here: GENERATE THE EVAL VIEWER *BEFORE* evaluating inputs yourself. You want to get them in front of the human ASAP!
- Feedback works differently: since there's no running server, the viewer's "Submit All Reviews" button will download `feedback.json` as a file. You can then read it from there (you may have to request access first).
- Packaging works — `package_skill.py` just needs Python and a filesystem.
- Description optimization (`run_loop.py` / `run_eval.py`) should work in Cowork just fine since it uses `claude -p` via subprocess, not a browser, but please save it until you've fully finished making the skill and the user agrees it's in good shape.
- **Updating an existing skill**: The user might be asking you to update an existing skill, not create a new one. Follow the update guidance in the claude.ai section above.

---

## Reference files

The agents/ directory contains instructions for specialized subagents. Read them when you need to spawn the relevant subagent.

- `agents/grader.md` — How to evaluate assertions against outputs
- `agents/comparator.md` — How to do blind A/B comparison between two outputs
- `agents/analyzer.md` — How to analyze why one version beat another

The references/ directory has additional documentation:
- `references/schemas.md` — JSON structures for evals.json, grading.json, etc.

---

Repeating one more time the core loop here for emphasis:

- Figure out what the skill is about
- Draft or edit the skill
- Run claude-with-access-to-the-skill on test prompts
- With the user, evaluate the outputs:
  - Create benchmark.json and run `eval-viewer/generate_review.py` to help the user review them
  - Run quantitative evals
- Repeat until you and the user are satisfied
- Package the final skill and return it to the user.

Please add steps to your TodoList, if you have such a thing, to make sure you don't forget. If you're in Cowork, please specifically put "Create evals JSON and run `eval-viewer/generate_review.py` so human can review test cases" in your TodoList to make sure it happens.

Good luck!


## --- Original Skill: skill-development ---

# Skill Development for Claude Code Plugins

This skill provides guidance for creating effective skills for Claude Code plugins.

## About Skills

Skills are modular, self-contained packages that extend Claude's capabilities by providing
specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific
domains or tasks—they transform Claude from a general-purpose agent into a specialized agent
equipped with procedural knowledge that no model can fully possess.

### What Skills Provide

1. Specialized workflows - Multi-step procedures for specific domains
2. Tool integrations - Instructions for working with specific file formats or APIs
3. Domain expertise - Company-specific knowledge, schemas, business logic
4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

### Anatomy of a Skill

Every skill consists of a required SKILL.md file and optional bundled resources:

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation intended to be loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts, etc.)
```

#### SKILL.md (required)

**Metadata Quality:** The `name` and `description` in YAML frontmatter determine when Claude will use the skill. Be specific about what the skill does and when to use it. Use the third-person (e.g. "This skill should be used when..." instead of "Use this skill when...").

#### Bundled Resources (optional)

##### Scripts (`scripts/`)

Executable code (Python/Bash/etc.) for tasks that require deterministic reliability or are repeatedly rewritten.

- **When to include**: When the same code is being rewritten repeatedly or deterministic reliability is needed
- **Example**: `scripts/rotate_pdf.py` for PDF rotation tasks
- **Benefits**: Token efficient, deterministic, may be executed without loading into context
- **Note**: Scripts may still need to be read by Claude for patching or environment-specific adjustments

##### References (`references/`)

Documentation and reference material intended to be loaded as needed into context to inform Claude's process and thinking.

- **When to include**: For documentation that Claude should reference while working
- **Examples**: `references/finance.md` for financial schemas, `references/mnda.md` for company NDA template, `references/policies.md` for company policies, `references/api_docs.md` for API specifications
- **Use cases**: Database schemas, API documentation, domain knowledge, company policies, detailed workflow guides
- **Benefits**: Keeps SKILL.md lean, loaded only when Claude determines it's needed
- **Best practice**: If files are large (>10k words), include grep search patterns in SKILL.md
- **Avoid duplication**: Information should live in either SKILL.md or references files, not both. Prefer references files for detailed information unless it's truly core to the skill—this keeps SKILL.md lean while making information discoverable without hogging the context window. Keep only essential procedural instructions and workflow guidance in SKILL.md; move detailed reference material, schemas, and examples to references files.

##### Assets (`assets/`)

Files not intended to be loaded into context, but rather used within the output Claude produces.

- **When to include**: When the skill needs files that will be used in the final output
- **Examples**: `assets/logo.png` for brand assets, `assets/slides.pptx` for PowerPoint templates, `assets/frontend-template/` for HTML/React boilerplate, `assets/font.ttf` for typography
- **Use cases**: Templates, images, icons, boilerplate code, fonts, sample documents that get copied or modified
- **Benefits**: Separates output resources from documentation, enables Claude to use files without loading them into context

### Progressive Disclosure Design Principle

Skills use a three-level loading system to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by Claude (Unlimited*)

*Unlimited because scripts can be executed without reading into context window.

## Skill Creation Process

To create a skill, follow the "Skill Creation Process" in order, skipping steps only if there is a clear reason why they are not applicable.

### Step 1: Understanding the Skill with Concrete Examples

Skip this step only when the skill's usage patterns are already clearly understood. It remains valuable even when working with an existing skill.

To create an effective skill, clearly understand concrete examples of how the skill will be used. This understanding can come from either direct user examples or generated examples that are validated with user feedback.

For example, when building an image-editor skill, relevant questions include:

- "What functionality should the image-editor skill support? Editing, rotating, anything else?"
- "Can you give some examples of how this skill would be used?"
- "I can imagine users asking for things like 'Remove the red-eye from this image' or 'Rotate this image'. Are there other ways you imagine this skill being used?"
- "What would a user say that should trigger this skill?"

To avoid overwhelming users, avoid asking too many questions in a single message. Start with the most important questions and follow up as needed for better effectiveness.

Conclude this step when there is a clear sense of the functionality the skill should support.

### Step 2: Planning the Reusable Skill Contents

To turn concrete examples into an effective skill, analyze each example by:

1. Considering how to execute on the example from scratch
2. Identifying what scripts, references, and assets would be helpful when executing these workflows repeatedly

Example: When building a `pdf-editor` skill to handle queries like "Help me rotate this PDF," the analysis shows:

1. Rotating a PDF requires re-writing the same code each time
2. A `scripts/rotate_pdf.py` script would be helpful to store in the skill

Example: When designing a `frontend-webapp-builder` skill for queries like "Build me a todo app" or "Build me a dashboard to track my steps," the analysis shows:

1. Writing a frontend webapp requires the same boilerplate HTML/React each time
2. An `assets/hello-world/` template containing the boilerplate HTML/React project files would be helpful to store in the skill

Example: When building a `big-query` skill to handle queries like "How many users have logged in today?" the analysis shows:

1. Querying BigQuery requires re-discovering the table schemas and relationships each time
2. A `references/schema.md` file documenting the table schemas would be helpful to store in the skill

**For Claude Code plugins:** When building a hooks skill, the analysis shows:
1. Developers repeatedly need to validate hooks.json and test hook scripts
2. `scripts/validate-hook-schema.sh` and `scripts/test-hook.sh` utilities would be helpful
3. `references/patterns.md` for detailed hook patterns to avoid bloating SKILL.md

To establish the skill's contents, analyze each concrete example to create a list of the reusable resources to include: scripts, references, and assets.

### Step 3: Create Skill Structure

For Claude Code plugins, create the skill directory structure:

```bash
mkdir -p plugin-name/skills/skill-name/{references,examples,scripts}
touch plugin-name/skills/skill-name/SKILL.md
```

**Note:** Unlike the generic skill-creator which uses `init_skill.py`, plugin skills are created directly in the plugin's `skills/` directory with a simpler manual structure.

### Step 4: Edit the Skill

When editing the (newly-created or existing) skill, remember that the skill is being created for another instance of Claude to use. Focus on including information that would be beneficial and non-obvious to Claude. Consider what procedural knowledge, domain-specific details, or reusable assets would help another Claude instance execute these tasks more effectively.

#### Start with Reusable Skill Contents

To begin implementation, start with the reusable resources identified above: `scripts/`, `references/`, and `assets/` files. Note that this step may require user input. For example, when implementing a `brand-guidelines` skill, the user may need to provide brand assets or templates to store in `assets/`, or documentation to store in `references/`.

Also, delete any example files and directories not needed for the skill. Create only the directories you actually need (references/, examples/, scripts/).

#### Update SKILL.md

**Writing Style:** Write the entire skill using **imperative/infinitive form** (verb-first instructions), not second person. Use objective, instructional language (e.g., "To accomplish X, do Y" rather than "You should do X" or "If you need to do X"). This maintains consistency and clarity for AI consumption.

**Description (Frontmatter):** Use third-person format with specific trigger phrases:

```yaml
---
name: Skill Name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2", "specific phrase 3". Include exact phrases users would say that should trigger this skill. Be concrete and specific.
version: 0.1.0
---
```

**Good description examples:**
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", "implement prompt-based hooks", or mentions hook events (PreToolUse, PostToolUse, Stop).
```

**Bad description examples:**
```yaml
description: Use this skill when working with hooks.  # Wrong person, vague
description: Load when user needs hook help.  # Not third person
description: Provides hook guidance.  # No trigger phrases
```

To complete SKILL.md body, answer the following questions:

1. What is the purpose of the skill, in a few sentences?
2. When should the skill be used? (Include this in frontmatter description with specific triggers)
3. In practice, how should Claude use the skill? All reusable skill contents developed above should be referenced so that Claude knows how to use them.

**Keep SKILL.md lean:** Target 1,500-2,000 words for the body. Move detailed content to references/:
- Detailed patterns → `references/patterns.md`
- Advanced techniques → `references/advanced.md`
- Migration guides → `references/migration.md`
- API references → `references/api-reference.md`

**Reference resources in SKILL.md:**
```markdown
## Additional Resources

### Reference Files

For detailed patterns and techniques, consult:
- **`references/patterns.md`** - Common patterns
- **`references/advanced.md`** - Advanced use cases

### Example Files

Working examples in `examples/`:
- **`example-script.sh`** - Working example
```

### Step 5: Validate and Test

**For plugin skills, validation is different from generic skills:**

1. **Check structure**: Skill directory in `plugin-name/skills/skill-name/`
2. **Validate SKILL.md**: Has frontmatter with name and description
3. **Check trigger phrases**: Description includes specific user queries
4. **Verify writing style**: Body uses imperative/infinitive form, not second person
5. **Test progressive disclosure**: SKILL.md is lean (~1,500-2,000 words), detailed content in references/
6. **Check references**: All referenced files exist
7. **Validate examples**: Examples are complete and correct
8. **Test scripts**: Scripts are executable and work correctly

**Use the skill-reviewer agent:**
```
Ask: "Review my skill and check if it follows best practices"
```

The skill-reviewer agent will check description quality, content organization, and progressive disclosure.

### Step 6: Iterate

After testing the skill, users may request improvements. Often this happens right after using the skill, with fresh context of how the skill performed.

**Iteration workflow:**
1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Identify how SKILL.md or bundled resources should be updated
4. Implement changes and test again

**Common improvements:**
- Strengthen trigger phrases in description
- Move long sections from SKILL.md to references/
- Add missing examples or scripts
- Clarify ambiguous instructions
- Add edge case handling

## Plugin-Specific Considerations

### Skill Location in Plugins

Plugin skills live in the plugin's `skills/` directory:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
├── agents/
└── skills/
    └── my-skill/
        ├── SKILL.md
        ├── references/
        ├── examples/
        └── scripts/
```

### Auto-Discovery

Claude Code automatically discovers skills:
- Scans `skills/` directory
- Finds subdirectories containing `SKILL.md`
- Loads skill metadata (name + description) always
- Loads SKILL.md body when skill triggers
- Loads references/examples when needed

### No Packaging Needed

Plugin skills are distributed as part of the plugin, not as separate ZIP files. Users get skills when they install the plugin.

### Testing in Plugins

Test skills by installing plugin locally:

```bash
# Test with --plugin-dir
cc --plugin-dir /path/to/plugin

# Ask questions that should trigger the skill
# Verify skill loads correctly
```

## Examples from Plugin-Dev

Study the skills in this plugin as examples of best practices:

**hook-development skill:**
- Excellent trigger phrases: "create a hook", "add a PreToolUse hook", etc.
- Lean SKILL.md (1,651 words)
- 3 references/ files for detailed content
- 3 examples/ of working hooks
- 3 scripts/ utilities

**agent-development skill:**
- Strong triggers: "create an agent", "agent frontmatter", etc.
- Focused SKILL.md (1,438 words)
- References include the AI generation prompt from Claude Code
- Complete agent examples

**plugin-settings skill:**
- Specific triggers: "plugin settings", ".local.md files", "YAML frontmatter"
- References show real implementations (multi-agent-swarm, ralph-loop)
- Working parsing scripts

Each demonstrates progressive disclosure and strong triggering.

## Progressive Disclosure in Practice

### What Goes in SKILL.md

**Include (always loaded when skill triggers):**
- Core concepts and overview
- Essential procedures and workflows
- Quick reference tables
- Pointers to references/examples/scripts
- Most common use cases

**Keep under 3,000 words, ideally 1,500-2,000 words**

### What Goes in references/

**Move to references/ (loaded as needed):**
- Detailed patterns and advanced techniques
- Comprehensive API documentation
- Migration guides
- Edge cases and troubleshooting
- Extensive examples and walkthroughs

**Each reference file can be large (2,000-5,000+ words)**

### What Goes in examples/

**Working code examples:**
- Complete, runnable scripts
- Configuration files
- Template files
- Real-world usage examples

**Users can copy and adapt these directly**

### What Goes in scripts/

**Utility scripts:**
- Validation tools
- Testing helpers
- Parsing utilities
- Automation scripts

**Should be executable and documented**

## Writing Style Requirements

### Imperative/Infinitive Form

Write using verb-first instructions, not second person:

**Correct (imperative):**
```
To create a hook, define the event type.
Configure the MCP server with authentication.
Validate settings before use.
```

**Incorrect (second person):**
```
You should create a hook by defining the event type.
You need to configure the MCP server.
You must validate settings before use.
```

### Third-Person in Description

The frontmatter description must use third person:

**Correct:**
```yaml
description: This skill should be used when the user asks to "create X", "configure Y"...
```

**Incorrect:**
```yaml
description: Use this skill when you want to create X...
description: Load this skill when user asks...
```

### Objective, Instructional Language

Focus on what to do, not who should do it:

**Correct:**
```
Parse the frontmatter using sed.
Extract fields with grep.
Validate values before use.
```

**Incorrect:**
```
You can parse the frontmatter...
Claude should extract fields...
The user might validate values...
```

## Validation Checklist

Before finalizing a skill:

**Structure:**
- [ ] SKILL.md file exists with valid YAML frontmatter
- [ ] Frontmatter has `name` and `description` fields
- [ ] Markdown body is present and substantial
- [ ] Referenced files actually exist

**Description Quality:**
- [ ] Uses third person ("This skill should be used when...")
- [ ] Includes specific trigger phrases users would say
- [ ] Lists concrete scenarios ("create X", "configure Y")
- [ ] Not vague or generic

**Content Quality:**
- [ ] SKILL.md body uses imperative/infinitive form
- [ ] Body is focused and lean (1,500-2,000 words ideal, <5k max)
- [ ] Detailed content moved to references/
- [ ] Examples are complete and working
- [ ] Scripts are executable and documented

**Progressive Disclosure:**
- [ ] Core concepts in SKILL.md
- [ ] Detailed docs in references/
- [ ] Working code in examples/
- [ ] Utilities in scripts/
- [ ] SKILL.md references these resources

**Testing:**
- [ ] Skill triggers on expected user queries
- [ ] Content is helpful for intended tasks
- [ ] No duplicated information across files
- [ ] References load when needed

## Common Mistakes to Avoid

### Mistake 1: Weak Trigger Description

❌ **Bad:**
```yaml
description: Provides guidance for working with hooks.
```

**Why bad:** Vague, no specific trigger phrases, not third person

✅ **Good:**
```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events. Provides comprehensive hooks API guidance.
```

**Why good:** Third person, specific phrases, concrete scenarios

### Mistake 2: Too Much in SKILL.md

❌ **Bad:**
```
skill-name/
└── SKILL.md  (8,000 words - everything in one file)
```

**Why bad:** Bloats context when skill loads, detailed content always loaded

✅ **Good:**
```
skill-name/
├── SKILL.md  (1,800 words - core essentials)
└── references/
    ├── patterns.md (2,500 words)
    └── advanced.md (3,700 words)
```

**Why good:** Progressive disclosure, detailed content loaded only when needed

### Mistake 3: Second Person Writing

❌ **Bad:**
```markdown
You should start by reading the configuration file.
You need to validate the input.
You can use the grep tool to search.
```

**Why bad:** Second person, not imperative form

✅ **Good:**
```markdown
Start by reading the configuration file.
Validate the input before processing.
Use the grep tool to search for patterns.
```

**Why good:** Imperative form, direct instructions

### Mistake 4: Missing Resource References

❌ **Bad:**
```markdown
# SKILL.md

[Core content]

[No mention of references/ or examples/]
```

**Why bad:** Claude doesn't know references exist

✅ **Good:**
```markdown
# SKILL.md

[Core content]

## Additional Resources

### Reference Files
- **`references/patterns.md`** - Detailed patterns
- **`references/advanced.md`** - Advanced techniques

### Examples
- **`examples/script.sh`** - Working example
```

**Why good:** Claude knows where to find additional information

## Quick Reference

### Minimal Skill

```
skill-name/
└── SKILL.md
```

Good for: Simple knowledge, no complex resources needed

### Standard Skill (Recommended)

```
skill-name/
├── SKILL.md
├── references/
│   └── detailed-guide.md
└── examples/
    └── working-example.sh
```

Good for: Most plugin skills with detailed documentation

### Complete Skill

```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   └── advanced.md
├── examples/
│   ├── example1.sh
│   └── example2.json
└── scripts/
    └── validate.sh
```

Good for: Complex domains with validation utilities

## Best Practices Summary

✅ **DO:**
- Use third-person in description ("This skill should be used when...")
- Include specific trigger phrases ("create X", "configure Y")
- Keep SKILL.md lean (1,500-2,000 words)
- Use progressive disclosure (move details to references/)
- Write in imperative/infinitive form
- Reference supporting files clearly
- Provide working examples
- Create utility scripts for common operations
- Study plugin-dev's skills as templates

❌ **DON'T:**
- Use second person anywhere
- Have vague trigger conditions
- Put everything in SKILL.md (>3,000 words without references/)
- Write in second person ("You should...")
- Leave resources unreferenced
- Include broken or incomplete examples
- Skip validation

## Additional Resources

### Study These Skills

Plugin-dev's skills demonstrate best practices:
- `../hook-development/` - Progressive disclosure, utilities
- `../agent-development/` - AI-assisted creation, references
- `../mcp-integration/` - Comprehensive references
- `../plugin-settings/` - Real-world examples
- `../command-development/` - Clear critical concepts
- `../plugin-structure/` - Good organization

### Reference Files

For complete skill-creator methodology:
- **`references/skill-creator-original.md`** - Full original skill-creator content

## Implementation Workflow

To create a skill for your plugin:

1. **Understand use cases**: Identify concrete examples of skill usage
2. **Plan resources**: Determine what scripts/references/examples needed
3. **Create structure**: `mkdir -p skills/skill-name/{references,examples,scripts}`
4. **Write SKILL.md**:
   - Frontmatter with third-person description and trigger phrases
   - Lean body (1,500-2,000 words) in imperative form
   - Reference supporting files
5. **Add resources**: Create references/, examples/, scripts/ as needed
6. **Validate**: Check description, writing style, organization
7. **Test**: Verify skill loads on expected triggers
8. **Iterate**: Improve based on usage

Focus on strong trigger descriptions, progressive disclosure, and imperative writing style for effective skills that load when needed and provide targeted guidance.


## --- Original Skill: skill-installer ---

# Skill Installer

Helps install skills. By default these are from https://github.com/openai/skills/tree/main/skills/.curated, but users can also provide other locations.

Use the helper scripts based on the task:
- List curated skills when the user asks what is available, or if the user uses this skill without specifying what to do.
- Install from the curated list when the user provides a skill name.
- Install from another repo when the user provides a GitHub repo/path (including private repos).

Install skills with the helper scripts.

## Communication

When listing curated skills, output approximately as follows, depending on the context of the user's request:
"""
Skills from {repo}:
1. skill-1
2. skill-2 (already installed)
3. ...
Which ones would you like installed?
"""

After installing a skill, tell the user: "Restart Codex to pick up new skills."

## Scripts

All of these scripts use network, so when running in the sandbox, request escalation when running them.

- `scripts/list-curated-skills.py` (prints curated list with installed annotations)
- `scripts/list-curated-skills.py --format json`
- `scripts/install-skill-from-github.py --repo <owner>/<repo> --path <path/to/skill> [<path/to/skill> ...]`
- `scripts/install-skill-from-github.py --url https://github.com/<owner>/<repo>/tree/<ref>/<path>`

## Behavior and Options

- Defaults to direct download for public GitHub repos.
- If download fails with auth/permission errors, falls back to git sparse checkout.
- Aborts if the destination skill directory already exists.
- Installs into `$CODEX_HOME/skills/<skill-name>` (defaults to `~/.codex/skills`).
- Multiple `--path` values install multiple skills in one run, each named from the path basename unless `--name` is supplied.
- Options: `--ref <ref>` (default `main`), `--dest <path>`, `--method auto|download|git`.

## Notes

- Curated listing is fetched from `https://github.com/openai/skills/tree/main/skills/.curated` via the GitHub API. If it is unavailable, explain the error and exit.
- Private GitHub repos can be accessed via existing git credentials or optional `GITHUB_TOKEN`/`GH_TOKEN` for download.
- Git fallback tries HTTPS first, then SSH.
- The skills at https://github.com/openai/skills/tree/main/skills/.system are preinstalled, so no need to help users install those. If they ask, just explain this. If they insist, you can download and overwrite.
- Installed annotations come from `$CODEX_HOME/skills`.


## --- Original Skill: skill-share ---

## When to use this skill

Use this skill when you need to:
- **Create new Claude skills** with proper structure and metadata
- **Generate skill packages** ready for distribution
- **Automatically share created skills** on Slack channels for team visibility
- **Validate skill structure** before sharing
- **Package and distribute** skills to your team

Also use this skill when:
- **User says he wants to create/share his skill** 

This skill is ideal for:
- Creating skills as part of team workflows
- Building internal tools that need skill creation + team notification
- Automating the skill development pipeline
- Collaborative skill creation with team notifications

## Key Features

### 1. Skill Creation
- Creates properly structured skill directories with SKILL.md
- Generates standardized scripts/, references/, and assets/ directories
- Auto-generates YAML frontmatter with required metadata
- Enforces naming conventions (hyphen-case)

### 2. Skill Validation
- Validates SKILL.md format and required fields
- Checks naming conventions
- Ensures metadata completeness before packaging

### 3. Skill Packaging
- Creates distributable zip files
- Includes all skill assets and documentation
- Runs validation automatically before packaging

### 4. Slack Integration via Rube
- Automatically sends created skill information to designated Slack channels
- Shares skill metadata (name, description, link)
- Posts skill summary for team discovery
- Provides direct links to skill files

## How It Works

1. **Initialization**: Provide skill name and description
2. **Creation**: Skill directory is created with proper structure
3. **Validation**: Skill metadata is validated for correctness
4. **Packaging**: Skill is packaged into a distributable format
5. **Slack Notification**: Skill details are posted to your team's Slack channel

## Example Usage

```
When you ask Claude to create a skill called "pdf-analyzer":
1. Creates /skill-pdf-analyzer/ with SKILL.md template
2. Generates structured directories (scripts/, references/, assets/)
3. Validates the skill structure
4. Packages the skill as a zip file
5. Posts to Slack: "New Skill Created: pdf-analyzer - Advanced PDF analysis and extraction capabilities"
```

## Integration with Rube

This skill leverages Rube for:
- **SLACK_SEND_MESSAGE**: Posts skill information to team channels
- **SLACK_POST_MESSAGE_WITH_BLOCKS**: Shares rich formatted skill metadata
- **SLACK_FIND_CHANNELS**: Discovers target channels for skill announcements

## Requirements

- Slack workspace connection via Rube
- Write access to skill creation directory
- Python 3.7+ for skill creation scripts
- Target Slack channel for skill notifications

---
name: ecc-harness-methodology
description: |
  Master agent harness performance optimization: token efficiency, hook-driven automation, agentic architecture, and test-driven development. Use this skill whenever you're building or optimizing AI agent workflows, designing Claude Code / Claude Code / Codex / Cursor agent configurations, implementing automated hooks to guard code quality, architecting multi-agent systems, or building production-grade TDD pipelines for AI-assisted development. Triggers especially for token budgeting, command sequencing, agent lifecycle management, pre-commit/push automation, or code review workflows in agentic contexts.
---

# ECC Harness Methodology: Agent Performance Optimization

This skill distills **Everything Claude Code's** core methodology for building production-grade agentic systems: how to optimize token spend, orchestrate automated hooks, design resilient agent harnesses, and embed TDD into agent workflows.

## Core Conceptual Model

**The Agent Harness** = { Token Budget } + { Hook Pipeline } + { Agent State Machine } + { Test Coverage }

An agent harness is a closed-loop system where:
- **Tokens** are your most constrained resource (cost, latency, context windows)
- **Hooks** are decision gates that intercept agent actions (pre/post execution, safety checks, state capture)
- **Agents** are task-specific policies that route work (specialized models, role-based instructions)
- **Tests** are your only proof the harness works end-to-end under real conditions

---

## 1. Token Optimization (Priority 1)

### The Token Budget Framework

Tokens are CPU time for LLMs. Your harness must budget them explicitly:

```
Total Budget = Development Tokens + Runtime Tokens + Safety Buffer
```

**Development Phase:**
- Prompt engineering iterations (pay once, reuse forever)
- Test case generation (amortized across runs)
- Eval/benchmark data collection (one-time cost)
- Documentation (reference cost, not per-request)

**Runtime Phase:**
- Agent initialization (system prompt)
- Input tokenization (user query)
- Reasoning loop (generation)
- Tool output ingestion (observation processing)

**Safety Buffer:** Reserve 15–25% for retries, error recovery, and unexpected context growth.

### Token Reduction Tactics (in order of impact)

#### 1. **Compress System Prompts**
Distill agent instructions into essential decision trees. Remove:
- Redundant examples (keep 1–2 exemplars, not 5–10)
- Verbose caveats (use constraints instead: "You may NOT...")
- Explanatory prose (replace with bullet points)
- Repeated context (reference external docs instead)

**Example:**
```
❌ LONG: "When you encounter a Python file, consider whether it needs testing. 
Often, Python files benefit from unit tests. You should write tests..."

✅ SHORT: "Mandate tests for: new functions, mutation-prone logic, external 
integrations. Use pytest. No tests = BLOCKER."
```

#### 2. **Cache Repeated Context**
If your agent processes the same file multiple times, tokenize once:
- Load large files once at harness start
- Pass file refs, not full content
- Use model-specific cache APIs (if available)

#### 3. **Prune Tool Outputs**
Don't return entire tool responses. Extract signal:
```
❌ Full output: bash command returns 50 lines of logs
✅ Filtered: "✓ Tests passed (23/23). 1 deprecation warning in module X."
```

#### 4. **Use Structured Outputs**
Force models to respond in compact JSON:
```
❌ Verbose: "Based on my analysis, the risk is moderate to high..."
✅ Compact: { "risk_level": "HIGH", "signal": "uncaught exception" }
```

#### 5. **Segment Long Workflows**
Break multi-step tasks into separate agent invocations:
```
Agent 1 (Lightweight): Analyze code → Output structured verdict
[Save to disk]
Agent 2 (Heavyweight): Fix code → Output patch
```

### Monitoring Token Spend

Track in real-time:
```json
{
  "prompt_tokens": 450,
  "completion_tokens": 120,
  "cache_read_tokens": 50,
  "total_cost": "$0.0023",
  "tokens_per_second": 18.5
}
```

Set alerts: if runtime tokens exceed dev tokens by 5x, your prompts are over-prompting.

---

## 2. Hook-Driven Automation (Priority 2)

### The Hook Lifecycle

Hooks are **deterministic, synchronous checkpoints** in the agent workflow:

```
Input → [pre:input] → Agent Logic → [post:output] → [pre:effect] → Write/Execute → [post:effect]
```

Each hook is a chance to:
- **Validate** (reject unsafe outputs)
- **Transform** (normalize format)
- **Observe** (log, audit, metrics)
- **Decide** (interrupt or proceed)

### Hook Categories

#### **Input Hooks** (pre:input)
Normalize, sanitize, validate user requests before agent sees them.

```javascript
// pre:input:sanitize-paths
// Reject absolute paths, escape shell metacharacters, normalize to relative
if (containsAbsolutePath(input)) {
  throw new Error("Absolute paths blocked. Use relative paths.");
}
input = escapeShellMeta(input);
```

**Use for:** Rate limiting, API key validation, request schema enforcement.

#### **Logic Hooks** (mid:inference)
Intercept agent mid-thought (requires API-level support).

```javascript
// mid:inference:token-check
// Halt if tokens exceed budget
if (usedTokens > budget * 0.95) {
  throw new Error("Token budget exceeded. Halting.");
}
```

#### **Output Hooks** (post:output)
Validate, sanitize, transform agent outputs before returning.

```javascript
// post:output:security-strip
// Remove credential patterns from model response
output = output
  .replace(/api[_-]?key[=:]\s*\S+/gi, "api_key=***")
  .replace(/password[=:]\s*\S+/gi, "password=***");
```

**Use for:** Secret redaction, format enforcement, schema validation.

#### **Effect Hooks** (pre:effect, post:effect)
Guard actual state changes (writes, API calls, deployments).

```javascript
// pre:effect:file-write-guard
// Require human approval for changes to production config
if (isProductionFile(filepath)) {
  const approved = await promptHumanApproval(filepath, diff);
  if (!approved) throw new Error("Write rejected by human.");
}

// post:effect:verify-write
// Confirm file was written correctly
const written = fs.readFileSync(filepath, 'utf8');
if (written !== expectedContent) {
  throw new Error("Write verification failed.");
}
```

**Use for:** Safety gates, audit trails, rollback logic.

### Hook Implementation Patterns

**Pattern 1: Synchronous Gate**
```javascript
function hookPreInput(event) {
  if (event.tokens > BUDGET) {
    return { action: "REJECT", reason: "Token budget exceeded" };
  }
  return { action: "PROCEED" };
}
```

**Pattern 2: Transform**
```javascript
function hookPostOutput(output) {
  return sanitize(output)
    .pipe(normalize)
    .pipe(redactSecrets);
}
```

**Pattern 3: Log & Decide**
```javascript
function hookPostEffect(event) {
  log({
    timestamp: Date.now(),
    effect: event.type,
    input_hash: hash(event.input),
    output_hash: hash(event.output),
    duration_ms: event.duration
  });
  
  if (event.duration > TIMEOUT) {
    alert("Slow execution detected");
  }
  return { action: "PROCEED" };
}
```

### Hook Configuration (hooks.json structure)

```json
{
  "hooks": {
    "pre:input": [
      {
        "name": "sanitize-paths",
        "description": "Reject absolute paths",
        "command": "node scripts/sanitize-paths.js",
        "timeout_ms": 100,
        "on_error": "REJECT"
      }
    ],
    "post:output": [
      {
        "name": "security-strip",
        "description": "Redact secrets from output",
        "command": "node scripts/redact-secrets.js",
        "timeout_ms": 50,
        "on_error": "WARN"
      }
    ],
    "pre:effect": [
      {
        "name": "prod-approval-gate",
        "description": "Require approval for prod writes",
        "command": "node scripts/prod-gate.js",
        "timeout_ms": 30000,
        "on_error": "REJECT"
      }
    ]
  }
}
```

### Debugging Hooks

When a hook fires:
1. Check **timeout_ms** — is the hook exceeding its budget?
2. Check **on_error** — does WARN vs REJECT match intent?
3. Check **command path** — does the script exist and have execute perms?
4. Run hook standalone: `node scripts/sanitize-paths.js < test-input.json`

Set `ECC_HOOK_DEBUG=1` to log every hook invocation.

---

## 3. Agent Harness Optimization (Priority 3)

### The Agent State Machine

Every agent operates in a state:

```
INIT → READY → INFERRING → OBSERVING → DECIDING → ACTING → [COMPLETE | ERROR | RETRY]
```

**Your harness manages transitions.**

### State Diagram with Hooks

```
INIT
  ├─[pre:init]─> validate harness config
  └─[post:init]─> log initialization
  
READY
  ├─[pre:input]─> sanitize request
  └─[post:input]─> tokenize & cache
  
INFERRING (model call)
  ├─[mid:inference]─> monitor tokens
  └─[post:output]─> validate response format
  
OBSERVING (tool execution)
  ├─[pre:effect]─> approval gate
  └─[post:effect]─> verify state change
  
DECIDING
  ├─[logic:retry?]─> check error recovery
  └─[logic:complete?]─> check success criteria
  
ACTING
  └─[on:finish]─> cleanup, metrics, audit log
```

### Agent Specialization (Role-Based Routing)

Instead of one mega-agent, specialize:

```
User Request
  ├─ Analyzer Agent (lightweight, quick classification)
  │   └─ Returns: { category, complexity, risks }
  │
  ├─ (If simple) Direct Agent (fast path)
  │   └─ Returns: direct result
  │
  └─ (If complex) Expert Agent (heavyweight, full reasoning)
      └─ Returns: detailed solution + audit trail
```

**Benefits:**
- Lighter agents = lower token spend
- Parallelizable = faster execution
- Testable in isolation = higher reliability

### Harness Resource Management

```javascript
class AgentHarness {
  constructor(config) {
    this.tokenBudget = config.tokenBudget || 10000;
    this.timeout = config.timeout || 30000;
    this.maxRetries = config.maxRetries || 3;
    this.hooks = new HookPipeline(config.hooks);
  }

  async invoke(request) {
    const startTokens = this.tokenCount();
    const deadline = Date.now() + this.timeout;

    try {
      // Run through hook pipeline
      const sanitized = await this.hooks.run('pre:input', request);
      
      // Invoke agent with token budget
      const response = await this.agent.call(sanitized, {
        maxTokens: this.tokenBudget - (this.tokenCount() - startTokens),
        deadline
      });

      // Validate and transform
      const validated = await this.hooks.run('post:output', response);
      
      // Execute effects under guard
      await this.hooks.run('pre:effect', validated);
      const result = await this.applyEffects(validated);
      await this.hooks.run('post:effect', result);

      return result;
    } catch (error) {
      if (this.retries < this.maxRetries) {
        this.retries++;
        return this.invoke(request); // Retry
      }
      throw error;
    }
  }
}
```

### Monitoring & Observability

Track these metrics per invocation:

```json
{
  "invocation_id": "agent-20250328-001",
  "timestamp": "2025-03-28T14:32:15Z",
  "request_tokens": 450,
  "response_tokens": 320,
  "cache_hit_rate": 0.65,
  "hook_timings": {
    "pre:input": 12,
    "post:output": 8,
    "pre:effect": 45,
    "post:effect": 6
  },
  "state_transitions": ["INIT", "READY", "INFERRING", "OBSERVING", "ACTING", "COMPLETE"],
  "error_recovery": 0,
  "total_duration_ms": 2341,
  "success": true
}
```

---

## 4. TDD for Agent Workflows (Priority 4)

### Test Levels (Pyramid)

```
                  E2E Tests (end-to-end harness)
                 /                              \
              Integration Tests (agent + hooks)
             /                                    \
          Unit Tests (isolated components: hooks, parsers)
         /_______________________________________________\
```

### Unit Tests: Hook Testing

```javascript
// test/hooks/pre-input-sanitize.spec.js
const { sanitizeInput } = require('../../scripts/sanitize-paths.js');

describe('sanitize-input: path rejection', () => {
  test('rejects absolute paths', () => {
    const input = { path: '/etc/passwd', action: 'read' };
    expect(() => sanitizeInput(input)).toThrow('Absolute paths blocked');
  });

  test('normalizes relative paths', () => {
    const input = { path: '../../../file.txt', action: 'read' };
    const result = sanitizeInput(input);
    expect(result.path).toBe('file.txt');
  });

  test('escapes shell metacharacters', () => {
    const input = { path: 'file;rm -rf /', action: 'read' };
    const result = sanitizeInput(input);
    expect(result.path).not.toContain(';');
  });
});
```

### Integration Tests: Agent + Hooks

```javascript
// test/integration/agent-with-guards.spec.js
const { AgentHarness } = require('../../src/harness.js');
const mockAgent = require('./mocks/agent.js');

describe('Agent Harness + Hook Pipeline', () => {
  let harness;

  beforeEach(() => {
    harness = new AgentHarness({
      tokenBudget: 1000,
      hooks: hooksConfig
    });
  });

  test('rejects request when token budget exceeded', async () => {
    const largRequest = { size: 'huge', tokens: 1200 };
    await expect(harness.invoke(largRequest))
      .rejects.toThrow('Token budget exceeded');
  });

  test('redacts secrets from agent output', async () => {
    const response = await harness.invoke({
      action: 'generate_config',
      include_secrets: true
    });
    expect(response).not.toMatch(/api.?key.*\S+/);
    expect(response).toContain('api_key=***');
  });

  test('blocks prod writes without approval', async () => {
    const prodWrite = {
      target: '/prod/config.json',
      data: { debug: false }
    };
    // Should fail unless human approves
    await expect(harness.invoke(prodWrite))
      .rejects.toThrow('Approval required');
  });
});
```

### E2E Tests: Full Workflow

```javascript
// test/e2e/code-review-workflow.spec.js
describe('TDD Code Review Workflow (E2E)', () => {
  test('review + fix + validate cycle', async () => {
    const originalCode = `
      function add(a, b) {
        return a + b
      }
    `;

    // Step 1: Request review
    const review = await harness.invoke({
      action: 'review_code',
      code: originalCode,
      rules: ['no-missing-semicolons', 'require-tests']
    });

    expect(review.issues).toHaveLength(2);
    expect(review.issues[0].rule).toBe('no-missing-semicolons');
    expect(review.issues[1].rule).toBe('require-tests');

    // Step 2: Request fix
    const fixed = await harness.invoke({
      action: 'fix_code',
      code: originalCode,
      issues: review.issues
    });

    expect(fixed.code).toContain(';');
    expect(fixed.code).toContain('test');

    // Step 3: Re-review (should pass)
    const recheck = await harness.invoke({
      action: 'review_code',
      code: fixed.code,
      rules: review.issues.map(i => i.rule)
    });

    expect(recheck.issues).toHaveLength(0);
    expect(recheck.passed).toBe(true);
  });
});
```

### Test-Driven Development Loop for Agents

1. **Write a test that fails** (red)
   ```javascript
   test('agent must include test code in output', async () => {
     const result = await agent.call("write a function");
     expect(result).toMatch(/test|spec|describe/);
   });
   ```

2. **Make the test pass** (green)
   - Add instruction to agent: "Always include unit tests"
   - Regenerate and verify

3. **Refactor** (refactor)
   - Move test to integration suite
   - Extract hook logic to separate module
   - Optimize token spend

### Quality Gates

Run before every commit:

```bash
# Run all tests
npm test

# Check coverage
npm run coverage -- --threshold 80

# Lint hooks
npm run lint:hooks

# Verify harness config
npm run verify:config

# Token audit
npm run audit:tokens
```

If any gate fails, **block commit** (pre-commit hook).

---

## Quick Start Checklist

### Week 1: Foundation
- [ ] Define token budget (total, per-agent, per-request)
- [ ] Write 5–10 unit tests for input validation
- [ ] Implement pre:input + post:output hooks
- [ ] Set up metrics collection (Prometheus, CloudWatch, or logs)

### Week 2: Hardening
- [ ] Add pre:effect approval gate for production changes
- [ ] Write integration tests (agent + hooks together)
- [ ] Profile token spend across real requests
- [ ] Document hook configuration (what triggers what)

### Week 3: Observability
- [ ] Build dashboard for token spend / hook timings
- [ ] Write E2E test for your main workflow
- [ ] Set up alerts (high token spend, hook timeouts, errors)
- [ ] Review logs and retro on failure modes

### Month 2+: Optimization
- [ ] Compress prompts (target: 20% token reduction)
- [ ] Add caching layer for repeated context
- [ ] Specialize agents (create lightweight + heavyweight variants)
- [ ] Tune hook timeouts based on prod data

---

## Anti-Patterns (What NOT to Do)

❌ **No token budget.** You'll leak dollars and hit limits at the worst time.  
✅ **Plan token spend per request.** Know your budget before you act.

❌ **Hooks that throw exceptions.** Use `on_error: WARN` for non-critical checks.  
✅ **Hooks that fail gracefully.** Log, alert, but let the workflow continue unless blocking.

❌ **One mega-agent.** Will always hit token limits and be impossible to debug.  
✅ **Specialized agents by role.** Each agent owns one decision or task.

❌ **No tests, just hope.** Agent behavior is hard to predict. You'll ship bugs.  
✅ **Tests at every level (unit, integration, E2E).** Catch regressions early.

❌ **Hooks that run forever.** A hook that times out breaks the whole pipeline.  
✅ **Hooks with strict timeout budgets.** If a hook needs 5s, timeout is 6s max.

---

## References & Further Reading

- **Token Optimization:** Prompt caching, structured outputs, input/output compression
- **Hook Systems:** Pre/post middleware, event-driven architecture, gate patterns
- **Agent Patterns:** Agentic loops, tool use, chain-of-thought
- **Testing AI:** Deterministic benchmarks, fuzzing, adversarial inputs, eval frameworks

---

## Support & Debugging

**Hooks aren't firing?**
```bash
ECC_HOOK_DEBUG=1 npm run harness
```

**Token spend too high?**
```bash
npm run audit:tokens -- --profile detailed
```

**Agent keeps failing?**
```bash
npm run e2e -- --log-level debug --record-trace
```

**Hooks timing out?**
```bash
npm run hooks:profile -- --timeout-ms 5000
```

---

**This is a living guide.** Your specific harness will be unique. Start with these principles, measure what matters (tokens, latency, errors), and iterate.

What's your next step?

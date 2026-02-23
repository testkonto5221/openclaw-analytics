# openclaw-analytics

Analytics and report scripts for the [OpenClaw](https://github.com/lsoraas/openclaw) personal AI assistant platform. Each script offloads a specific analytical task to Claude Code CLI and delivers an HTML report by email.

Reports are saved locally, indexed in a RAG knowledge base, and cached for 7–14 days to avoid redundant API calls.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| [Claude Code CLI](https://claude.ai/code) (`claude`) | Must be logged in with an active plan |
| [himalaya](https://github.com/soywod/himalaya) | Email CLI — configure with your Gmail/SMTP account before running |
| Python 3 + `yfinance` | Only needed for `fetch-stocks` and `send-stock-report` |
| OpenClaw workspace | The directory where reports, templates, and memory files live |
| `rag` CLI | Optional — for indexing reports into local vector search |

---

## Installation

```bash
git clone https://github.com/lsoraas/openclaw-analytics
cd openclaw-analytics
chmod +x install.sh
./install.sh
```

The installer will ask for:
- **OpenClaw workspace path** (default: `~/.openclaw/workspace`)
- **Default recipient email** for all reports

It then substitutes all paths, symlinks scripts to `~/.local/bin/`, copies the HTML template, and checks for dependencies.

### Manual configuration after install

**hmail sender address** — edit `~/.local/bin/hmail`, change the `FROM=` line to your configured himalaya account:
```bash
FROM="your-sender@gmail.com"
```

**Default recipient** — each script has `MOTTAKER="..."` near the top. Change globally with `install.sh` or per-script.

---

## Scripts

### Core utilities

| Script | Purpose |
|--------|---------|
| `claude-kjor` | Wrapper around `claude --print` with automatic rate-limit retry (up to 8 attempts, 65 min wait). Used internally by all report scripts. |
| `hmail` | Thin wrapper around `himalaya message send` for plain-text and HTML email. |
| `list-rapporter` | List all saved reports with date, type, and subject. Supports `--tech`, `--finans`, `--rag` flags. |

---

### Financial analytics

#### `dybdeanalyse "Equinor"`
Deep single-company analysis. Analogous to a sell-side equity research note.

Sections: business overview · financial history (3yr) · valuation · competitive moat · management · risk map · growth catalysts · 3 scenarios (bull/base/bear) · investor profile fit · buy/hold/sell recommendation.

```bash
dybdeanalyse "Aker BP"
dybdeanalyse "Mowi" --to "annen@epost.no"
dybdeanalyse "Equinor" --budget 2.00
dybdeanalyse "Capgemini" --model claude-opus-4-6
```

**Model:** Sonnet · **Default budget:** $1.50 · **Cache:** 7 days

---

#### `send-investor-rapport "DNB, Equinor, Aker BP"`
Comparative multi-company investor report for 2–4 companies.

Sections: what they do · valuation table · revenue & growth · debt & financial strength · risk map · opportunity map · investor profile fit · scorecard · buy if / avoid if · one-line verdict per company.

```bash
send-investor-rapport "DNB, Equinor, Aker BP"
send-investor-rapport "Capgemini, TCS" --to "annen@epost.no" --budget 1.00
```

**Model:** Haiku · **Default budget:** $0.80 · **Cache:** 7 days

---

#### `sammenlign-rapporter "olje-gass" "fornybar"`
Cross-sector comparison of two previously saved reports (uses report slug or filename).

```bash
sammenlign-rapporter "olje-gass" "sjomat"
sammenlign-rapporter "2026-02-22_olje-gass" "2026-01-15_finans"
sammenlign-rapporter "olje-gass" "fornybar" --budget 1.00
```

**Model:** Haiku · **Default budget:** $0.80 · **Cache:** 7 days

---

#### `fetch-stocks AKRBP.OL CAP.PA`
Fetch live stock prices, key ratios, analyst consensus, and 3-year performance via Yahoo Finance. No AI call — pure data.

```bash
fetch-stocks AKRBP.OL EQNR.OL DNB.OL
fetch-stocks NVDA --full          # + analyst targets, dividend history, key ratios
fetch-stocks --watchlist          # predefined watchlist (edit script to configure)
```

---

#### `send-stock-report --tickers "DNB.OL EQNR.OL NVDA" --to "you@example.com"`
Formatted HTML stock report with live data, sent by email.

```bash
send-stock-report --tickers "AKRBP.OL EQNR.OL" --to "you@example.com"
send-stock-report --tickers "NVDA MSFT" --to "you@example.com" --subject "My watchlist"
```

---

### Tech analytics

#### `tech-trend-analyse "Rust"`
Deep technology trend analysis. The tech equivalent of `dybdeanalyse`.

Sections: what it is · adoption curve (GitHub stars, Stack Overflow, TIOBE) · job market demand · ecosystem & toolchain · competitors comparison · strengths & weaknesses · 3 scenarios (mainstream/niche/fading) · who should learn it · resources · verdict (LEARN NOW / WATCH / SKIP).

```bash
tech-trend-analyse "Rust"
tech-trend-analyse "WebAssembly" --to "annen@epost.no"
tech-trend-analyse "htmx" --budget 2.00
tech-trend-analyse "Kubernetes" --model claude-opus-4-6
```

**Model:** Sonnet · **Default budget:** $1.50 · **Cache:** 14 days

---

#### `sektor-radar "AI infra"`
Tech sector pulse report. What's hot, what's rising, what's fading — in a given domain.

Domains to try: `AI infra` · `developer tools` · `cybersecurity` · `edge computing` · `observability` · `WebAssembly` · `data engineering`

Sections: sector overview · top 5 projects/companies with momentum signal · new OSS projects (< 12 months) · key events last quarter · hype vs. substance table · where top engineers are moving · risk factors · ThoughtWorks-style radar (ADOPT/TRY/ASSESS/HOLD) · 3 concrete actions.

```bash
sektor-radar "AI infra"
sektor-radar "developer tools" --to "annen@epost.no"
sektor-radar "cybersecurity" --budget 1.00
```

**Model:** Haiku · **Default budget:** $0.80 · **Cache:** 7 days

---

#### `oss-prosjekt-helse "shadcn/ui"`
Open source project health check. Answers: is this safe to build on?

Sections: project overview · contributor health (bus factor, spread) · commit & release activity · issue & PR health · dependency risk · funding & governance · fork ecosystem · health scorecard (6 dimensions, 1–5 score) · recommendation (HEALTHY / WATCHFUL / AT RISK).

```bash
oss-prosjekt-helse "shadcn/ui"
oss-prosjekt-helse "tauri-apps/tauri"
oss-prosjekt-helse "htmx" --to "annen@epost.no"
```

**Model:** Haiku · **Default budget:** $0.40 · **Cache:** 14 days

---

#### `ai-modell-sammenligning "GPT-4o, Claude Sonnet, Gemini 2.5 Flash"`
Side-by-side comparison of 2–4 AI models. The tech equivalent of `send-investor-rapport`.

Sections: model card (context window, cutoff, license, API availability) · benchmarks (MMLU, HumanEval, MATH, GPQA) · pricing per 1M tokens · strengths by use case (code, long docs, multilingual, tool use, structured output, multimodal) · practical API experience (latency, rate limits, SDKs) · weaknesses · who each model fits · winner per scenario.

```bash
ai-modell-sammenligning "GPT-4o, Claude Sonnet, Gemini 2.5 Flash"
ai-modell-sammenligning "Llama 3.3, Mistral Large, Qwen 2.5"
ai-modell-sammenligning "o3, Claude Opus, Gemini 2.0 Ultra" --budget 0.80
```

**Model:** Haiku · **Default budget:** $0.50 · **Cache:** 7 days

---

## How it works

```
you / OpenClaw assistant
        │
        ▼
   report script          ← bash script in ~/.local/bin/
        │
        ├─ archive check  ← skip if report < N days old
        │
        ▼
   claude-kjor            ← wrapper with rate-limit retry
        │
        ▼
   claude --print         ← Claude Code CLI in non-interactive mode
        │  (searches web, generates HTML, saves file, sends email)
        │
        ├─► HTML file      → workspace/rapporter/YYYY-MM-DD_type_slug.html
        ├─► email          → via hmail → himalaya → Gmail/SMTP
        └─► RAG index      → rag add <file> <source-name>
```

All reports are written in Norwegian (technical terms kept in English), targeting a non-specialist reader. Claude is instructed never to fabricate numbers — it searches for real data.

---

## File naming convention

Reports are saved as:
```
YYYY-MM-DD_<type>_<slug>.html
```

| Prefix | Script |
|--------|--------|
| `dybde_` | `dybdeanalyse` |
| `sammenligning_` | `sammenlign-rapporter` |
| `tech_` | `tech-trend-analyse` |
| `radar_` | `sektor-radar` |
| `oss_` | `oss-prosjekt-helse` |
| `aimod_` | `ai-modell-sammenligning` |
| (no prefix) | `send-investor-rapport` |

---

## OpenClaw integration

If you run OpenClaw (Lilleklo), the assistant can trigger any of these scripts directly via its exec tool:

```
# In a Telegram message to Lilleklo:
"Kan du lage en tech-trend-analyse av Rust og sende til meg?"

# Lilleklo will call:
tech-trend-analyse "Rust" --to "lsoraas@gmail.com"
```

To add these scripts to the assistant's awareness, add to `workspace/TOOLS.md`:

```markdown
## Analytics Scripts

| Script | Purpose |
|--------|---------|
| `tech-trend-analyse "X"` | Deep tech trend analysis (~$1.50, Sonnet) |
| `sektor-radar "X"` | Tech sector pulse report (~$0.80) |
| `oss-prosjekt-helse "X"` | OSS project health check (~$0.40) |
| `ai-modell-sammenligning "X, Y"` | AI model comparison (~$0.50) |
| `dybdeanalyse "X"` | Deep company analysis (~$1.50, Sonnet) |
| `send-investor-rapport "X, Y"` | Multi-company investor report (~$0.80) |
| `sammenlign-rapporter "X" "Y"` | Compare two saved reports (~$0.80) |
| `list-rapporter` | Show all saved reports |
```

---

## Cost reference

| Script | Model | Typical cost |
|--------|-------|-------------|
| `dybdeanalyse` | Sonnet | $0.50–1.50 |
| `tech-trend-analyse` | Sonnet | $0.50–1.50 |
| `send-investor-rapport` | Haiku | $0.20–0.80 |
| `sammenlign-rapporter` | Haiku | $0.20–0.80 |
| `sektor-radar` | Haiku | $0.20–0.80 |
| `ai-modell-sammenligning` | Haiku | $0.20–0.50 |
| `oss-prosjekt-helse` | Haiku | $0.10–0.40 |
| `send-stock-report` | Haiku | $0.10–0.30 |

All scripts accept `--budget N` to cap spend.

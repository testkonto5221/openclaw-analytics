# openclaw-analytics

Analytics and report scripts for the [OpenClaw](https://github.com/lsoraas/openclaw) personal AI assistant platform. All report types are driven by a single generic runner (`rapport`) with per-type config files.

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

**Default recipient** — set in each `.conf` file or override per-run with `--to`.

---

## The `rapport` runner

All reports are generated via one generic runner:

```bash
rapport <type> <input> [--to email] [--budget N] [--model M]
rapport --list                          # show available report types
```

The runner:
1. Loads `rapporter/<type>.conf` (prompt, model, budget, cache duration)
2. Checks archive cache — sends existing report from disk if it's fresh enough
3. Expands the prompt with `${INPUT}`, `${DATO}`, `${MALSTI}`, `${UTFIL}`
4. Calls `claude-kjor` (with automatic rate-limit retry)
5. Fallback: saves HTML from stdout if Claude didn't write the file itself
6. Sends report via email (`hmail`)
7. Indexes in RAG knowledge base

### Available report types

| Type | Name | Model | Budget | Cache | Description |
|------|------|-------|--------|-------|-------------|
| `fin-investor` | Investorrapport | Haiku | $0.80 | 7d | Comparative multi-company investor report |
| `fin-dybde` | Dybdeanalyse | Sonnet | $2.00 | 7d | Deep single-company analysis (3yr history, DCF, scenarios) |
| `fin-sammenlign` | Rapportsammenligning | Haiku | $0.80 | 7d | Compare two stored reports (dual input) |
| `tech-puls` | Tech-puls | Sonnet | $1.00 | 7d | Fresh digest with videos, news, papers, tools |
| `tech-trend` | Tech-trendanalyse | Sonnet | $1.50 | 14d | Deep technology trend analysis (adoption, jobs, scenarios) |
| `tech-radar` | Sektorradar | Haiku | $0.80 | 7d | Tech sector pulse (ADOPT/TRY/ASSESS/HOLD) |
| `tech-oss` | OSS-helsesjekk | Haiku | $0.40 | 14d | Open source project health check |
| `tech-ai` | AI-modellsammenligning | Haiku | $0.50 | 7d | Compare 2-4 AI models (benchmarks, pricing, use cases) |

### Examples

```bash
rapport fin-investor "DNB, Equinor, Aker BP" --to you@example.com
rapport fin-dybde "Orkla"
rapport fin-dybde "Equinor" --model claude-opus-4-6
rapport fin-sammenlign "olje-gass" "sjømat"
rapport tech-puls "AI agents" --budget 1.50
rapport tech-trend "Rust"
rapport tech-radar "cybersecurity"
rapport tech-oss "shadcn/ui"
rapport tech-ai "GPT-4o, Claude Sonnet, Gemini 2.5 Flash"
```

### Backward compatibility

The old command names still work via thin wrappers:

| Old command | New equivalent |
|-------------|---------------|
| `fin-investor-rapport "X"` | `rapport fin-investor "X"` |
| `fin-dybdeanalyse "X"` | `rapport fin-dybde "X"` |
| `fin-sammenlign-rapporter "A" "B"` | `rapport fin-sammenlign "A" "B"` |
| `tech-puls "X"` | `rapport tech-puls "X"` |
| `tech-trend-analyse "X"` | `rapport tech-trend "X"` |
| `tech-sektor-radar "X"` | `rapport tech-radar "X"` |
| `tech-oss-helse "X"` | `rapport tech-oss "X"` |
| `tech-ai-sammenligning "X"` | `rapport tech-ai "X"` |

---

## Config files (`rapporter/*.conf`)

Each report type is defined by a config file with these fields:

```bash
NAME="Investorrapport"           # Display name
FILENAME_PREFIX=""               # Prefix in output filename (e.g. "dybde_")
RAG_PREFIX="rapport"             # Prefix for RAG index key
TEMPLATE="investorsammenligning.html"  # HTML template to use
MODEL="claude-haiku-4-5-20251001"      # Default Claude model
BUDGET="0.80"                    # Default budget cap (USD)
CACHE_DAYS=7                     # Days before regenerating
INPUT_LABEL="Selskaper"          # Help text for input argument
SUBJECT_PREFIX="Investoranalyse" # Email subject prefix
TITTEL_PREFIX="Investoranalyse"  # claude-kjor --tittel prefix

PROMPT='Your prompt here with ${INPUT}, ${DATO}, ${MALSTI}, ${UTFIL} placeholders'
```

For the dual-input comparison type (`fin-sammenlign`), add:
```bash
INPUT_MODE="dual"
```
This enables `${INPUT_FILE_1}` and `${INPUT_FILE_2}` in the prompt.

---

## Core utilities

| Script | Purpose |
|--------|---------|
| `rapport` | Generic report runner — loads `.conf` files and handles all boilerplate |
| `claude-kjor` | Wrapper around `claude --print` with automatic rate-limit retry (up to 8 attempts, 65 min wait) |
| `hmail` | Thin wrapper around `himalaya message send` for plain-text and HTML email |
| `list-rapporter` | List all saved reports with date, type, and subject. Supports `--tech`, `--finans`, `--rag` flags |

---

## Stock tools (non-report)

#### `fetch-stocks AKRBP.OL CAP.PA`
Fetch live stock prices, key ratios, analyst consensus, and 3-year performance via Yahoo Finance. No AI call — pure data.

```bash
fetch-stocks AKRBP.OL EQNR.OL DNB.OL
fetch-stocks NVDA --full          # + analyst targets, dividend history, key ratios
fetch-stocks --watchlist          # predefined watchlist (edit script to configure)
```

#### `send-stock-report --tickers "DNB.OL EQNR.OL NVDA" --to "you@example.com"`
Formatted HTML stock report with live data, sent by email.

---

## How it works

```
you / OpenClaw assistant
        │
        ▼
   rapport <type> <input>    ← generic runner in ~/.local/bin/
        │
        ├─ load .conf        ← rapporter/<type>.conf
        ├─ archive check     ← skip if report < N days old
        │
        ▼
   claude-kjor               ← wrapper with rate-limit retry
        │
        ▼
   claude --print            ← Claude Code CLI in non-interactive mode
        │  (searches web, generates HTML, saves file)
        │
        ├─► HTML file         → workspace/rapporter/YYYY-MM-DD_type_slug.html
        ├─► email             → via hmail → himalaya → Gmail/SMTP
        └─► RAG index         → rag add <file> <source-name>
```

All reports are written in Norwegian (technical terms kept in English), targeting a non-specialist reader. Claude is instructed never to fabricate numbers — it searches for real data.

---

## File naming convention

Reports are saved as:
```
YYYY-MM-DD_<prefix><slug>.html
```

| Prefix | Report type |
|--------|-------------|
| `investor_` | `fin-investor` |
| `dybde_` | `fin-dybde` |
| `sammenligning_` | `fin-sammenlign` |
| `puls_` | `tech-puls` |
| `tech_` | `tech-trend` |
| `radar_` | `tech-radar` |
| `oss_` | `tech-oss` |
| `aimod_` | `tech-ai` |

---

## OpenClaw integration

If you run OpenClaw (Lilleklo), the assistant can trigger any report directly via its exec tool:

```
# In a Telegram message to Lilleklo:
"Kan du lage en tech-trend-analyse av Rust og sende til meg?"

# Lilleklo will call:
rapport tech-trend "Rust" --to "lsoraas@gmail.com"
```

---

## Cost reference

| Report type | Model | Typical cost |
|-------------|-------|-------------|
| `fin-dybde` | Sonnet | $0.50–2.00 |
| `tech-trend` | Sonnet | $0.50–1.50 |
| `tech-puls` | Sonnet | $0.50–1.00 |
| `fin-investor` | Haiku | $0.20–0.80 |
| `fin-sammenlign` | Haiku | $0.20–0.80 |
| `tech-radar` | Haiku | $0.20–0.80 |
| `tech-ai` | Haiku | $0.20–0.50 |
| `tech-oss` | Haiku | $0.10–0.40 |
| `send-stock-report` | Haiku | $0.10–0.30 |

All report types accept `--budget N` to cap spend and `--model M` to override the default model.

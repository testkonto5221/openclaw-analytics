# TOOLS.md

## Rapportsystemet (`rapport`)

Alle rapporter genereres via én generisk runner: `rapport <type> <input> [flagg]`.
Config-filer (prompt + parametere) ligger i `workspace/rapporter/*.conf`.
HTML-maler ligger i `workspace/templates/`. Se `templates/TEMPLATES.md` for maldetaljer.

### Bruk

```bash
rapport <type> <input> [--to email] [--budget N] [--model M]
rapport --list                          # vis alle tilgjengelige rapporttyper
```

### Tilgjengelige rapporttyper

| Type | Navn | Modell | Budsjett | Cache | Beskrivelse |
|------|------|--------|----------|-------|-------------|
| `fin-investor` | Investorrapport | Haiku | $0.80 | 7d | Sammenlignende investoranalyse av flere selskaper (prefix: `investor_`) |
| `fin-dybde` | Dybdeanalyse | Sonnet | $2.00 | 7d | Ekstra dyp analyse av ett enkelt selskap (3-års historikk, DCF, scenarier) |
| `fin-sammenlign` | Rapportsammenligning | Haiku | $0.80 | 7d | Sammenlign to lagrede rapporter (dual input) |
| `tech-puls` | Tech-puls | Sonnet | $1.00 | 7d | Fersk oppdatering med videoer, nyheter og lenker |
| `tech-trend` | Tech-trendanalyse | Sonnet | $1.50 | 14d | Dybdeanalyse av én teknologi (adopsjon, jobbmarked, scenarier) |
| `tech-radar` | Sektorradar | Haiku | $0.80 | 7d | Pulsrapport for et teknologidomene (ADOPT/TRY/ASSESS/HOLD) |
| `tech-oss` | OSS-helsesjekk | Haiku | $0.40 | 14d | Helsesjekk av open source-prosjekt (bus factor, aktivitet, governance) |
| `tech-ai` | AI-modellsammenligning | Haiku | $0.50 | 7d | Sammenlign 2-4 AI-modeller (benchmarks, prising, brukstilfeller) |

### Eksempler

```bash
rapport fin-investor "DNB, Equinor" --to lsoraas@gmail.com
rapport fin-dybde "Orkla"
rapport fin-sammenlign "olje-gass" "sjømat"
rapport tech-puls "Rust" --budget 1.50
rapport tech-trend "htmx" --model claude-opus-4-6
rapport tech-radar "AI infra"
rapport tech-oss "shadcn/ui"
rapport tech-ai "GPT-4o, Claude Sonnet, Gemini 2.5 Flash"
```

### Hva runneren gjør

1. Laster `rapporter/<type>.conf` (prompt, modell, budsjett, cache-varighet)
2. Sjekker arkiv-cache — sender eksisterende rapport fra disk hvis den er fersk nok
3. Ekspanderer prompten med `${INPUT}`, `${DATO}`, `${MALSTI}`, `${UTFIL}`
4. Kaller `claude-kjor` (med retry ved rate-limit)
5. Fallback: lagrer HTML fra stdout hvis Claude ikke skrev filen selv
6. Sender rapport via e-post (`hmail`)
7. Indekserer i RAG-kunnskapsbasen

### Bakoverkompatibilitet

De gamle kommandonavnene fungerer fortsatt via wrappers:

| Gammel kommando | Ny kommando |
|----------------|-------------|
| `fin-dybdeanalyse "X"` | `rapport fin-dybde "X"` |
| `fin-investor-rapport "X"` | `rapport fin-investor "X"` |
| `fin-sammenlign-rapporter "A" "B"` | `rapport fin-sammenlign "A" "B"` |
| `tech-puls "X"` | `rapport tech-puls "X"` |
| `tech-trend-analyse "X"` | `rapport tech-trend "X"` |
| `tech-sektor-radar "X"` | `rapport tech-radar "X"` |
| `tech-oss-helse "X"` | `rapport tech-oss "X"` |
| `tech-ai-sammenligning "X"` | `rapport tech-ai "X"` |

### Oversikt over lagrede rapporter

Bruk `list-rapporter` for å se alle lagrede rapporter med dato og sektor.
RAG-status kan sjekkes med `rag list`.

### Diskuter rapportinnhold

Alle rapporter legges automatisk i RAG ved generering. Du kan stille spørsmål om innholdet direkte. Rapporter eldre enn 6 måneder slettes automatisk fra disk og RAG via heartbeat.

### Send en lagret rapport på nytt

```bash
hmail --to "mottaker@epost.no" --subject "Rapport" --file workspace/rapporter/FILNAVN.html
```

### Manuell rapport (be meg direkte)

```
Lag en sammenlignende investoranalyse av [SELSKAP1] og [SELSKAP2]
basert på malen i /home/lars/.openclaw/workspace/templates/investorsammenligning.html.
Send til lsoraas@gmail.com.
```

Alle rapporter lagres til `workspace/rapporter/` og legges automatisk i RAG.

## Knowledge Base (RAG)

See `RAG.md` for full docs. Quick reference:

Jeg kan legge til filer eller URL-er i kunnskapsbasen for senere søk og spørsmål. Du kan også spørre meg direkte om innholdet i kunnskapsbasen. Jeg kan fjerne dokumenter og liste opp alle kilder jeg har lagret. Jeg vil alltid sjekke kunnskapsbasen før jeg svarer på spørsmål som kan være dekket der.

### Fjerne filer/rapporter — bruk ALLTID `rag-remove`

```bash
rag-remove <source_name> [file_path]
```

Fjerner fra både RAG og filsystemet (via trash) i én operasjon. Hvis `file_path` utelates, søker den automatisk i `workspace/rapporter/`. **Fjern aldri manuelt med `rag remove` + `trash` hver for seg.**

## Opplastede filer (media/inbound)

Filer lastet opp av brukeren havner i `/home/lars/.openclaw/media/inbound/` med UUID-navn. Originalnavnet bevares **ikke** i filnavnet — det må registreres.

```bash
media-register <uuid-filnavn> <originalt-navn> [mime-type]   # registrer + RAG-indekser
media-remove <originalt-navn|uuid-filnavn>                    # fjern fra alt
media-list                                                     # vis registrerte filer
```

- Registrer **alltid** opplastede filer umiddelbart med `media-register`
- RAG-kompatible filer (.txt, .md, .html, .htm, .pdf) indekseres automatisk
- Bruk `media-remove` for fjerning — fjerner fra manifest, RAG og filsystem
- Manifest: `media/inbound/manifest.json`

## GitHub

`gh` CLI er autentisert som `testkonto5221`. Git er konfigurert med credential helper, så `git push/pull` fungerer uten ekstra autentisering.

Jeg kan utføre ulike GitHub-operasjoner, som å liste opp repositories, klone repositories, opprette og administrere pull requests og issues, og gjøre rå API-kall.

Min Git-identitet for commits er `Lilleklo <testaccount5221@gmail.com>`. Hvis du vil bruke din personlige GitHub-konto, må du oppgi en PAT (Personal Access Token).

## Stock Report (automated — use this for stock emails)

**Single command — does everything:** fetches live data, news, formats HTML, sends email.

Jeg kan sende en automatisert aksjerapport som henter live data og nyheter, formaterer det til HTML og sender en e-post. Rapporten inkluderer gjeldende pris, kursutvikling over ulike perioder, utbytter, analytikervurderinger og selskapsnyheter. Jeg kan sende dette for en eller flere tickers (f.eks. `AKRBP.OL`, `EQNR.OL`, `DNB.OL`, `NVDA`) til en e-postadresse du oppgir.

## Stock Prices (raw data only)

Jeg kan hente rå data om aksjepriser. **Jeg vil aldri oppgi priser fra mitt minne; jeg vil alltid hente ferske data når du spør.** Du kan spørre om spesifikke tickers eller be om data for en overvåkningsliste.

## Newsfeeds

Jeg kan hente nyheter fra forskjellige kilder, som NRK, Politiet Vest, og ulike teknologinyhetskilder. Du kan be meg om nyheter fra spesifikke kilder eller kombinasjoner av dem. **Jeg vil aldri fabrikkere lenker; jeg vil alltid hente ferske nyheter når du spør.**

## Email

Jeg kan sende e-postmeldinger, enten korte meldinger, eller jeg kan sende eksisterende HTML-rapporter som vedlegg. Sistnevnte er den foretrukne metoden for å sende rapporter. Standard avsender er `testkonto5221@gmail.com`, og din e-postadresse er `lsoraas@gmail.com`, som jeg alltid vil bruke når jeg sender noe til deg.

Jeg kan også lese e-post fra ulike mapper som `INBOX`, `[Gmail]/Sendt e-post` m.fl.

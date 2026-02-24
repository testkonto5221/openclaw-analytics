# Rapportmaler

Disse malene er utgangspunkt for nye rapporter. Filene ligger her:
`/home/lars/.openclaw/workspace/templates/`

---

## investorsammenligning.html

**Hva:** Sammenlignende investoranalyse for 2–4 selskaper. Laget for småinvestorer uten finansbakgrunn.

**Sist brukt:** Februar 2026 — Vår Energi, Capgemini, Knowit

**Innhold i malen:**
1. Hva gjør selskapene (enkelt forklart)
2. Kurs og verdsettelse (P/E, EV/EBITDA, direkteavkastning)
3. Inntekter og vekst
4. Gjeld og finansiell styrke
5. Risikokart (tabellformat, med trafikklysstatus)
6. Mulighetskartet
7. Investorprofil (utbytte/vekst/verdi/defensiv)
8. Scorecard (⭐-vurdering)
9. Kjøp hvis / unngå hvis
10. Én setnings-konklusjon per selskap

---

### Slik lager du en ny rapport

#### Metode 1: Automatisk via shell-script (anbefalt)

```bash
fin-investor-rapport "DNB, Equinor, Aker BP"
fin-investor-rapport "Capgemini, TCS" --to "annen@epost.no"
```

Scriptet (`/home/lars/.local/bin/fin-investor-rapport`) kaller Claude Code CLI (`claude`) som:
1. Søker etter oppdatert finansdata for hvert selskap
2. Leser og fyller inn HTML-malen
3. Sender ferdig rapport på epost

Kostnad: ~USD 0.30–0.80 per rapport (Haiku-modellen). Budsjettgrense kan settes med `--budget`.

**Lilleklo kan trigge dette direkte** ved å kjøre kommandoen via exec-tool:
```
fin-investor-rapport "DNB, Equinor" --to "lsoraas@gmail.com"
```

---

#### Metode 2: Be Lilleklo/Claude direkte

```
Lag en sammenlignende investoranalyse av DNB, Equinor og Aker BP
basert på malen i investorsammenligning.html. Send til lsoraas@gmail.com.
```

**Hva som skjer:**
1. Søke etter oppdatert finansdata for selskapene
2. Fylle inn malen med nye tall og tekst
3. Sende HTML-rapport på mail

---

### Tilpasninger du kan be om

- **Færre seksjoner:** "Dropp risikokartet, bare ta med verdsettelse og scorecard"
- **Annen målgruppe:** "Skriv for en mer erfaren investor med faglig språk"
- **Annen valuta:** Fungerer automatisk — tabellene har kolonner per selskap
- **Én enkelt aksje:** Bruk malen som utgangspunkt og be om dybderapport på ett selskap
- **Legg til seksjon:** "Legg til en seksjon om ESG og bærekraft"

---

### Tickers å huske

| Selskap | Ticker | Børs |
|---------|--------|------|
| Vår Energi | VAR.OL | Oslo |
| Aker BP | AKRBP.OL | Oslo |
| Equinor | EQNR.OL | Oslo |
| DNB | DNB.OL | Oslo |
| Orkla | ORK.OL | Oslo |
| Capgemini | CAP.PA | Paris |
| TCS | TCS.NS | Mumbai |
| Knowit | KNOW | Stockholm |
| NVIDIA | NVDA | NASDAQ |

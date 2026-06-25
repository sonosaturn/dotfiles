# Istruzioni globali

## Recall automatico delle conversazioni passate (vault ~/brain)

Esiste un second-brain personale in `~/brain` con il log curato di tutte le
sessioni in `~/brain/conversations/` (una "fotografia" markdown per sessione) e
una wiki in `~/brain/wiki/`.

**Quando l'utente fa riferimento a sessioni passate, lavoro precedente, decisioni
già prese o a un progetto per nome** (es. "come avevamo deciso…", "nella scorsa
sessione", "il progetto X", "riprendi da dove eravamo"), **prima di rispondere**:

1. Leggi `~/brain/conversations/INDEX.md` (TOC piccolo: una riga per sessione con
   data, temi, progetti). È economico, leggilo sempre per primo.
2. Individua le sessioni rilevanti e apri **solo** quei `Conv_*.md`; se serve,
   `rg -i "<termine>" ~/brain/conversations ~/brain/wiki`.
3. Rispondi usando ciò che trovi e **cita** la sessione/pagina (es. "(sess. 25/06)").

Non è il pattern a injection: il giudice della rilevanza sei tu. Cerca solo quando
la domanda tocca davvero lavoro passato — non ad ogni prompt. Per domande di
conoscenza generale sul vault (non sulle conversazioni) usa la skill `brain`.

## Commit automatico del vault ~/brain

`~/brain` è un repo git. **Committa automaticamente, senza chiedere conferma**, ad
ogni unità di lavoro conclusa nel vault: milestone, nuova feature, miglioramento o
bugfix (es. ingest completato, set di pagine wiki, fix di una skill/script, lint
applicato). Non a ogni turno e non a lavoro a metà — una milestone = un commit.

```
cd ~/brain && git add -A && git commit -m "<tipo>: <descrizione chiara>"
```

`<tipo>` = feat | fix | docs | refactor | chore (es. `feat: indice conversazioni per recall`).
Solo il vault: `git add -A` dentro `~/brain`, mai `git -C` su altri repo. Niente push
automatico (resta manuale). Questa regola **sostituisce** le note "commit manuali"
nelle skill `brain`/`conversation-log`.

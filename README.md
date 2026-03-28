<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.41.5-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/FastAPI-Production-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
<img src="https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
<img src="https://img.shields.io/badge/Railway-Deployed-0B0D0E?style=for-the-badge&logo=railway&logoColor=white"/>
<img src="https://img.shields.io/badge/Versione-0.3.0-6C63FF?style=for-the-badge"/>

### *Non studiare da solo. Trova il tuo match.*

</div>

---

## Il Perché di Tutto

Questo progetto non nasce da un hackathon, non nasce da un corso universitario, non nasce da una brief aziendale.

**Nasce da una valigia.**

Da quella sensazione di arrivare in una città nuova, aprire la porta di un appartamento che non conosci, sederti in un'aula piena di gente e sentirti comunque solo. Da quei pomeriggi passati a studiare da soli in biblioteca perché non sai da dove cominciare per rompere il ghiaccio. Da quella voglia enorme di fare, di crescere, di connettersi — bloccata da muri invisibili che nessuno ti ha insegnato ad abbattere.

In Italia, **oltre 600.000 studenti** ogni anno lasciano casa per seguire i propri sogni universitari. La maggior parte di loro affronta questa sfida da sola. Non perché non vogliano conoscere persone — ma perché nessuno ha ancora costruito lo strumento giusto per facilitarlo.

**Incontro è quello strumento.**

---

## La Visione

Viviamo in un momento storico unico: per la prima volta nella storia, le tecnologie più avanzate del pianeta sono accessibili a chiunque abbia una connessione internet e la voglia di usarle.

L'intelligenza artificiale non è più solo uno strumento per le grandi aziende tech. È uno **strumento di livellamento sociale**. Può dare a uno studente fuorisede, da solo nel suo appartamento, la stessa capacità di costruire prodotti digitali di un team da dieci persone con anni di esperienza.

Questa è la mia missione personale: **dimostrare che l'AI, usata consapevolmente, spezza le divaricazioni sociali**. Mette tutti allo stesso livello. Dà le stesse possibilità. Non sostituisce l'ingegno umano — lo amplifica. Non elimina la fatica — la direziona meglio.

Ma alla fine, strumenti o no, **sta sempre all'individuo cacciare fuori i denti**.

Stare in silenzio o alzarsi e fare. Aspettare che qualcuno ti parli o essere il primo a sorridere. Lamentarsi della solitudine o costruire la soluzione.

Io ho scelto di costruire.

---

## Cos'è Incontro

Incontro è una **piattaforma mobile social per studenti fuorisede** che combina:

- Il **matching intelligente** di Tinder — ma per trovare compagni di studio, non appuntamenti
- La **mappa interattiva** dei posti dove studiare nella tua città e in tutta Italia
- Il **social graph** di Instagram — storie, follower, @username, profili
- La **chat** per comunicare con i tuoi match
- Il **badge live** per sapere chi sta studiando proprio in questo momento

Non è un'app di dating travestita. Non è un forum universitario. È qualcosa di nuovo: uno spazio digitale pensato specificamente per abbattere i muri sociali che impediscono agli studenti fuorisede di connettersi tra loro.

---

## Funzionalità Implementate

### 🔐 Identità e Sicurezza
Ogni utente si registra con la propria **email istituzionale** (.edu o .it) — questo garantisce che la community sia composta esclusivamente da studenti universitari verificati. Nessun profilo falso, nessun intruso.

Il sistema di autenticazione usa **JWT con PBKDF2-HMAC-SHA256** a 200.000 iterazioni — lo stesso standard usato dalle applicazioni bancarie. La privacy degli utenti non è un'opzione, è un requisito di design.

Ogni utente sceglie il proprio **@username univoco**, esattamente come su Instagram. Questo crea un'identità digitale riconoscibile e ricercabile all'interno della community.

### 🃏 Swipe Feed e Matching
Il cuore dell'esperienza è un **feed stile Tinder** dove scorrere i profili degli altri studenti. Ma a differenza di Tinder, il matching non è casuale — è guidato da un **algoritmo di compatibilità** che considera le materie di studio in comune e lo stile di apprendimento preferito (silenzioso in biblioteca o con musica in un bar).

Solo quando il like è reciproco si crea un match. Solo allora si sblocca la chat. Questo meccanismo protegge gli utenti e garantisce che ogni connessione sia genuinamente bidirezionale.

### 🗺️ Mappa Interattiva Nazionale
Una delle feature più distintive: una **mappa interattiva di tutta Italia** che mostra in tempo reale i posti dove studiare — bar, caffè, biblioteche — con marker colorati e filtri per categoria.

Ogni posto è cliccabile: un bottom sheet mostra nome, indirizzo, distanza, e permette di aprire le indicazioni direttamente su **Google Maps o Apple Maps** con un tap. La mappa si aggiorna automaticamente mentre l'utente esplora, caricando nuovi posti nell'area visibile. Supporta la ricerca per città e la geolocalizzazione GPS in tempo reale.

La mappa usa **OpenStreetMap e Nominatim** — tecnologie open source, gratuite, indipendenti da Google. Una scelta deliberata: i dati degli studenti non vengono ceduti a piattaforme pubblicitarie.

### 🟢 Badge "Studia Ora"
Ogni utente può avviare una **sessione di studio live** specificando dove si trova. Questo attiva un badge verde pulsante sul suo profilo, visibile a tutti gli altri utenti del feed. In questo modo è possibile vedere, in tempo reale, chi sta studiando in questo momento e dove — aprendo la possibilità di raggiungerlo fisicamente.

Questo è il ponte tra il digitale e il fisico. Il vero obiettivo di Incontro non è che le persone chattino — è che si incontrino davvero.

### 📖 Stories e Social Graph
Gli utenti possono pubblicare **storie con scadenza 24 ore**, esattamente come Instagram. Le storie appaiono in una barra orizzontale nella parte superiore del feed, mostrando chi tra i propri seguiti è attivo.

Il sistema di **follower e seguiti** permette di costruire una rete sociale all'interno della piattaforma. Si può cercare qualsiasi utente per @username dalla schermata chat e scegliere di seguirlo indipendentemente dal matching.

### 💬 Chat Persistente
Ogni match sblocca una conversazione privata. I messaggi sono **salvati nel database cloud** e persistono nel tempo — non spariscono al riavvio dell'app. Il sistema effettua un polling automatico per i nuovi messaggi, con **notifiche push** immediate per match e messaggi ricevuti.

### 📸 Foto Profilo
Ogni utente può impostare una **foto profilo** selezionata dalla galleria del dispositivo. L'immagine viene compressa automaticamente e salvata nel database. Appare nelle card dello swipe feed, nelle stories, nelle chat e in tutti i punti di contatto della piattaforma.

---

## Architettura Tecnica

```
📱 App Flutter (Android · iOS · Windows)
         │
         │ HTTPS / REST API
         ▼
☁️  Railway — Backend FastAPI Python 3.11
  incontrobackend-production.up.railway.app
         │
         │ PostgreSQL / psycopg2
         ▼
🗄️  Supabase — Database Cloud
  5 tabelle: users · swipes · matches · messages · stories
```

| Layer | Tecnologia | Motivazione |
|-------|-----------|-------------|
| Mobile | Flutter 3.41 + Dart 3.11 | Un codebase, tutte le piattaforme |
| Backend | FastAPI + Python 3.11 | Async, tipizzato, auto-documentato |
| Database | PostgreSQL su Supabase | Gratuito, scalabile, SQL standard |
| Deploy | Railway | CI/CD automatico da GitHub |
| Auth | JWT + PBKDF2-SHA256 | Standard bancario |
| Mappe | OpenStreetMap + Nominatim | Open source, privacy-first |
| Design | Google Stitch AI | Mockup → codice in ore |

---

## Come è Stato Costruito: L'Approccio AI-First

Questo progetto è stato realizzato da **una singola persona** in circa **48 ore** di sviluppo effettivo, grazie a un ecosistema di strumenti AI usati in modo strategico e consapevole.

È importante essere trasparenti su questo: **l'AI non ha avuto l'idea**. Non ha capito il problema. Non ha vissuto la solitudine del fuorisede. Non ha deciso l'architettura, le feature prioritarie, la visione sociale del prodotto. Non ha scritto questo README.

Quello che l'AI ha fatto è **amplificare la capacità esecutiva** di chi sapeva già dove voleva arrivare.

### Gli Strumenti Usati

**Claude Code (Anthropic)** — agente AI che lavora autonomamente nel terminale, legge e scrive file, esegue comandi, corregge i propri errori. Usato per sessioni di sviluppo autonome — anche notturne — in cui l'agente implementava feature complete partendo da istruzioni dettagliate. Risultati: 15+ feature implementate in sessioni da 30-40 minuti, migrazione completa a PostgreSQL, build e verifica automatica dell'APK.

**Claude (claude.ai)** — usato per pianificazione architetturale, scrittura dei prompt strategici per Claude Code, debugging di problemi complessi, documentazione.

**Google Stitch AI** — generazione UI da descrizioni testuali. Ogni schermata dell'app è stata prima prototipata su Stitch, poi fornita come immagine di riferimento a Claude Code per la reimplementazione in Flutter. Flusso: idea → descrizione → mockup → PNG → Flutter widget. Ore invece di giorni.

### Il Messaggio Vero

Chiunque può usare questi strumenti. Sono pubblici, accessibili, spesso gratuiti.

La differenza non sta negli strumenti — sta nel **sapere cosa costruire e perché**. Sta nell'avere un problema reale da risolvere. Sta nella capacità di imparare velocemente, fallire, correggere, riprovare.

L'AI livella il campo di gioco tecnico. Il resto — la visione, la determinazione, il coraggio di costruire qualcosa dal nulla — quello è ancora, e sempre sarà, **una questione umana**.

---

## Roadmap

### v0.4.0 — Real-time *(Q2 2026)*
- [ ] WebSocket per chat in tempo reale
- [ ] Indicatore di digitazione e presenza online

### v0.5.0 — Verifica e Fiducia *(Q3 2026)*
- [ ] Video selfie per badge identità verificata
- [ ] Integrazione sistemi universitari (ESSE3, Infostud)

### v1.0.0 — Lancio Pubblico *(Q4 2026)*
- [ ] App Store + Google Play
- [ ] AI moderation contenuti
- [ ] Gruppi di studio (3-6 persone)
- [ ] Calendario sessioni condiviso
- [ ] Dashboard per università

---

## Autore

**Marco** — Studente, fuorisede, builder.

Sono cresciuto con la convinzione che le opportunità non si aspettano — si costruiscono. Che i muri sociali si abbattono un passo alla volta. Che la tecnologia, usata bene, non è un privilegio di pochi ma uno strumento di libertà per tutti.

Incontro è la sintesi di tutto questo: un'idea nata dall'esperienza vissuta, costruita con gli strumenti più avanzati disponibili oggi, con l'obiettivo di rendere un po' meno sola la vita di chi, come me, ha scelto di andare lontano per crescere.

> *"Cacciare fuori i denti" non è un'espressione elegante. Ma è la più onesta che conosco per descrivere quello che serve davvero: la grinta di alzarsi, di fare il primo passo, di non aspettare che qualcuno risolva i tuoi problemi al posto tuo. L'AI mi ha dato strumenti più potenti. La grinta l'ho sempre dovuta trovare da solo.*

---

<div align="center">

Se questo progetto ti ha colpito, lascia una ⭐

Se sei uno studente fuorisede e vuoi contribuire, apri una Pull Request.

Se sei un'azienda che crede in questa visione, scrivimi.

**Fatto con ❤️, determinazione, e qualche agente AI sveglio di notte.**

*Per tutti gli studenti fuorisede d'Italia che meritano di non sentirsi soli.*

</div>

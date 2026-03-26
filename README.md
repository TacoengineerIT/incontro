<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.41.5-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/FastAPI-0.1.0-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-In%20sviluppo-FF6B6B?style=for-the-badge"/>

<br/><br/>

```
  ___                      _
 |_ _|_ __   ___ ___  _ __| |_ _ __ ___
  | || '_ \ / __/ _ \| '_ \ __| '__/ _ \
  | || | | | (_| (_) | | | | |_| | | (_) |
 |___|_| |_|\___\___/|_| |_|\__|_|  \___/
```

### *Non studiare da solo. Trova il tuo match.*

**Incontro** è una piattaforma mobile di matching per studenti fuorisede —  
pensata per chi si ritrova in una città nuova, con voglia di studiare, ma senza nessuno con cui farlo.

[📱 Demo](#demo) · [🚀 Quick Start](#quick-start) · [🗺️ Roadmap](#roadmap) · [💡 Contribuisci](#contribuisci)

</div>

---

## 🎯 Il Problema

Ogni anno in Italia **oltre 600.000 studenti** lasciano la propria città per frequentare l'università.  
Si ritrovano in appartamenti nuovi, in aule affollate di sconosciuti, con la pressione degli esami e **nessuno con cui studiare**.

> *"Mangiare il mondo da soli è difficile. Farlo insieme è un'altra storia."*

La solitudine accademica non è solo un disagio emotivo — è un **ostacolo concreto alla carriera universitaria**. Gli studenti che studiano in gruppo ottengono risultati migliori, abbandonano meno e vivono l'università con più soddisfazione.

**Incontro risolve questo problema.**

---

## 💡 La Soluzione

Un'app di **matching intelligente per studenti**, che funziona come Tinder — ma per trovare compagni di studio, non appuntamenti.

L'algoritmo abbina gli studenti in base a:
- 📚 **Materie in comune** — stai studiando Analisi? Ti matchamo con chi studia Analisi
- 🎧 **Stile di studio** — silenzioso in biblioteca o con musica in un bar?
- 📍 **Prossimità geografica** — i migliori posti studio vicini a te, in tempo reale
- ✅ **Email istituzionale verificata** — solo studenti veri, niente profili falsi

---

## 🏗️ Architettura

```
incontro/
├── 📱 Frontend (Flutter)
│   ├── Swipe Feed          → Card stile Tinder con profili studenti
│   ├── Map Screen          → Posti studio vicini via OpenStreetMap/Nominatim
│   ├── Chat Screen         → Lista match e conversazioni
│   └── Profile Screen      → Gestione profilo e preferenze
│
└── ⚙️  Backend (FastAPI + Python)
    ├── Auth System         → JWT, email istituzionale (.edu / .it)
    ├── Matching Engine     → Score compatibilità multi-criterio
    ├── Swipe & Match API   → Like/dislike con rilevamento match reciproci
    └── Maps Integration    → Nominatim (OpenStreetMap) per luoghi vicini
```

### Stack Tecnologico

| Layer | Tecnologia | Motivazione |
|-------|-----------|-------------|
| Mobile | Flutter 3.41 | Cross-platform, performance native, UI fluida |
| Backend | FastAPI (Python) | Async nativo, validazione automatica, docs OpenAPI |
| Auth | JWT + PBKDF2 | Sicuro, stateless, standard industriale |
| Maps | Nominatim (OSM) | Gratuito, open-source, no dipendenze da Google |
| Swipe | flutter_card_swiper | Animazioni fluide, gesture naturali |

---

## 📱 Funzionalità Attuali (v0.1.0)

### ✅ Implementate

- **Autenticazione sicura** — Registrazione e login con email istituzionale (.edu / .it)
- **Setup profilo** — Materie di studio e stile (silenzioso / rumoroso)
- **Swipe Feed** — Card studenti con algoritmo di compatibilità
- **Match System** — Like reciproco → match confermato
- **Mappa posti studio** — Bar e biblioteche vicine tramite Nominatim API
- **Bottom Navigation** — Navigazione fluida tra le 4 sezioni principali
- **Design dark mode** — UI moderna, tema viola/teal, font Poppins

---

## 🚀 Roadmap

### v0.2.0 — Chat Real-Time *(Q2 2026)*
- [ ] WebSocket per messaggistica in tempo reale
- [ ] Notifiche push per nuovi match e messaggi
- [ ] Stato online/offline degli studenti
- [ ] Condivisione materiale di studio in chat

### v0.3.0 — Geolocalizzazione Avanzata *(Q3 2026)*
- [ ] GPS in tempo reale per distanza precisa
- [ ] Mappa interattiva con flutter_map (OpenStreetMap)
- [ ] "Studia ora" — badge live se uno studente è attivo in un posto vicino
- [ ] Sessioni di studio di gruppo geolocalizzate

### v0.4.0 — Verifica Identità *(Q3 2026)*
- [ ] Video selfie per badge identità verificata
- [ ] Integrazione con sistemi universitari (ESSE3, Infostud)
- [ ] Verifica iscrizione corso di laurea
- [ ] Badge materie certificate (superamento esame verificato)

### v1.0.0 — Lancio Pubblico *(Q4 2026)*
- [ ] AI Moderation — filtro contenuti inappropriati
- [ ] Sistema di rating post-sessione di studio
- [ ] Gruppi di studio (3-6 persone)
- [ ] Calendario sessioni condiviso
- [ ] Integrazione Google Calendar / iCal
- [ ] App Store + Google Play

---

## 💫 Visione a Lungo Termine

### 🎓 Incontro Campus Network
Una rete nazionale di studenti connessi per università, con:
- **Leaderboard** degli studenti più attivi per facoltà
- **Sessioni pubbliche** — "Alle 15 sono in biblioteca Nazionale, chi viene?"
- **Biblioteca condivisa** — scambio appunti e materiali tra studenti compatibili

### 🤖 AI Study Companion
- Suggerimenti personalizzati di partner basati su storico di studio
- Predizione delle sessioni più produttive (orario, luogo, partner)
- Analisi dei progressi con i diversi compagni di studio

### 🏢 Incontro for Universities
- Dashboard per università per monitorare engagement studentesco
- Integrazione con sistemi di prenotazione aule
- API per associazioni studentesche e biblioteche

---

## ⚡ Quick Start

### Prerequisiti
- Flutter 3.41+
- Python 3.11+
- Android Studio / Xcode (per mobile) oppure Windows 10+ (desktop)

### Backend

```bash
cd incontro
pip install fastapi uvicorn pyjwt "pydantic[email]"
uvicorn main:app --reload
# → http://localhost:8000
# → Docs: http://localhost:8000/docs
```

### Frontend

```bash
cd study_match
flutter pub get
flutter run -d windows   # oppure -d chrome, -d android
```

---

## 🔐 Sicurezza

- Password hashate con **PBKDF2-HMAC-SHA256** (200.000 iterazioni)
- Token **JWT** con scadenza 24h, issuer verificato
- Validazione **email istituzionale** obbligatoria (regex .edu / .it)
- Nessun dato sensibile esposto nelle risposte API
- Rate limiting e gestione errori generica (no leak interni)

---

## 📊 API Reference

La documentazione completa è disponibile automaticamente su:
```
http://localhost:8000/docs
```

Endpoint principali:

| Method | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/auth/register` | Registrazione con email istituzionale |
| POST | `/auth/login` | Login → JWT token |
| GET | `/auth/me` | Profilo utente corrente |
| PUT | `/me/profile` | Aggiorna materie e stile |
| POST | `/matches/recommendations` | Lista studenti compatibili |
| POST | `/swipe` | Like o dislike su uno studente |
| GET | `/matches/me` | Lista match confermati |
| POST | `/maps/nearby` | Posti studio vicini |

---

## 🤝 Contribuisci

Il progetto è in fase early-stage e ogni contributo è benvenuto.

```bash
git clone https://github.com/TacoengineerIT/incontro.git
cd incontro
# Crea un branch per la tua feature
git checkout -b feature/nome-feature
# Committa le modifiche
git commit -m "feat: descrizione"
# Apri una Pull Request
```

Aree dove serve aiuto:
- 🎨 UI/UX design migliorato per mobile
- 🧪 Test unitari e di integrazione
- 🌍 Localizzazione (EN, ES, FR)
- 📱 Build e test su iOS fisico

---

## 👤 Autore

**Marco** — Studente, fuorisede, builder.

> *Questo progetto nasce da un'esperienza personale: arrivare in una nuova città con tanta voglia di studiare e nessuno con cui farlo. Incontro è la risposta che avrei voluto avere.*

---

## 📄 Licenza

MIT License — libero di usare, modificare e distribuire con attribuzione.

---

<div align="center">

**Se ti piace il progetto, lascia una ⭐ — significa molto.**

*Fatto con ❤️ per tutti gli studenti fuorisede d'Italia.*

</div>
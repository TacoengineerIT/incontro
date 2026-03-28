# INCONTRO — Feature Sociali v0.3.0

## CONTESTO
App Flutter "Incontro" per studenti fuorisede.
Backend: C:\Users\mabat\incontro\main.py (porta 8000)
Frontend: C:\Users\mabat\study_match\lib\
REGOLA: USA SEMPRE withValues(alpha: x) — MAI withOpacity(x)
REGOLA: MAI const davanti a widget con colori dinamici
REGOLA: Ogni file completo, niente TODO

═══════════════════════════════════════════════════════
STEP 1 — DIPENDENZE (pubspec.yaml)
═══════════════════════════════════════════════════════

Aggiungi:
  image_picker: ^1.1.0
  cached_network_image: ^3.4.1
  image_cropper: ^8.0.0

Poi esegui flutter pub get.

═══════════════════════════════════════════════════════
STEP 2 — BACKEND: USERNAME + FOTO + SOCIAL
(C:\Users\mabat\incontro\main.py)
═══════════════════════════════════════════════════════

### 2A — Aggiorna UserInDB
Aggiungi campi:
  username: Optional[str] = None
  avatar_base64: Optional[str] = None
  followers: List[str] = Field(default_factory=list)
  following: List[str] = Field(default_factory=list)
  stories: List[Dict] = Field(default_factory=list)

### 2B — Aggiorna UserPublic
Aggiungi:
  username: Optional[str]
  avatar_base64: Optional[str]
  followers_count: int
  following_count: int
  has_active_story: bool

Nel costruttore di UserPublic calcola:
  followers_count = len(user.followers)
  following_count = len(user.following)
  has_active_story = any story posted < 24h ago

### 2C — Aggiorna /auth/register
Dopo la creazione dell'utente, genera username automatico:
  base = email.split('@')[0].lower()
  Rimuovi caratteri non alfanumerici da base.
  Se base è già in uso: aggiungi numeri casuali finché è unico.
  Salva su user.username

### 2D — Storage globale usernames
Aggiungi dizionario:
  USERNAMES: Dict[str, str] = {}  # username -> user_id

Aggiorna _seed_bot_profiles() per assegnare username ai bot:
  marco@unina.it → username="marco_unina"
  sofia@unibo.it → username="sofia_unibo"
  luca@polimi.it → username="luca_polimi"
  giulia@uniroma1.it → username="giulia_uniroma"
  alessio@unina.it → username="alessio_unina"
  chiara@unibo.it → username="chiara_unibo"
  davide@polimi.it → username="davide_polimi"
  martina@uniroma1.it → username="martina_uniroma"
  andrea@unina.it → username="andrea_unina"
  valentina@unibo.it → username="valentina_unibo"

### 2E — Endpoint username
PUT /me/username
  Body: { "username": str }
  Auth richiesta.
  Valida: solo lettere, numeri, underscore, 3-20 caratteri.
  Controlla unicità in USERNAMES.
  Se già in uso: 409 Conflict.
  Aggiorna USERNAMES e user.username.
  Ritorna UserPublic aggiornato.

GET /users/search
  Params: q: str (query @username)
  Auth richiesta.
  Rimuovi @ iniziale se presente.
  Cerca USERNAMES dove username inizia con q (case insensitive).
  Ritorna lista UserPublic (max 20 risultati).

GET /users/{username}
  Auth richiesta.
  Cerca utente per username in USERNAMES.
  Ritorna UserPublic.

### 2F — Endpoint foto profilo
PUT /me/avatar
  Body: { "avatar_base64": str }
  Auth richiesta.
  Valida che sia una stringa base64 valida.
  Salva su user.avatar_base64.
  Ritorna { "saved": true }

### 2G — Endpoint follower/seguiti
POST /users/{username}/follow
  Auth richiesta.
  Trova target per username.
  Se già seguito: 409.
  Aggiungi target.id a user.following.
  Aggiungi user.id a target.followers.
  Ritorna { "following": true, "followers_count": int }

DELETE /users/{username}/follow
  Auth richiesta.
  Rimuovi follow reciproco.
  Ritorna { "following": false, "followers_count": int }

GET /users/{username}/followers
  Auth richiesta.
  Ritorna lista UserPublic dei followers.

GET /users/{username}/following
  Auth richiesta.
  Ritorna lista UserPublic dei following.

### 2H — Endpoint stories
POST /me/story
  Body: { "image_base64": str, "caption": Optional[str] }
  Auth richiesta.
  Crea story: { "id": uuid, "image_base64": str, 
    "caption": str, "created_at": time.time() }
  Aggiungi a user.stories.
  Stories scadono dopo 24h (filtra nel getter).
  Ritorna story creata.

GET /stories/feed
  Auth richiesta.
  Ritorna stories degli utenti che l'utente segue
  (solo quelle < 24h).
  Formato: [{ "user": UserPublic, "stories": [story] }]

### 2I — Aggiorna /matches/recommendations
Includi nel risultato:
  "username": str
  "avatar_base64": Optional[str]
  "followers_count": int
  "has_active_story": bool

═══════════════════════════════════════════════════════
STEP 3 — MODELLI FLUTTER AGGIORNATI
═══════════════════════════════════════════════════════

### lib/models/student.dart
Aggiungi:
  final String? username;
  final String? avatarBase64;
  final int followersCount;
  final bool hasActiveStory;

fromJson aggiornato con tutti i campi.

getter displayName:
  if username != null: return "@$username"
  return email.split('@').first

### lib/models/story.dart — CREA
class Story {
  final String id;
  final String imageBase64;
  final String? caption;
  final double createdAt;
  final String userId;
  
  factory Story.fromJson(Map<String, dynamic> json)
  
  bool get isExpired =>
    DateTime.now().millisecondsSinceEpoch / 1000 - createdAt > 86400;
}

### lib/models/user_profile.dart — CREA
class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? avatarBase64;
  final List<String> studySubjects;
  final String? learningStyle;
  final int followersCount;
  final int followingCount;
  final bool hasActiveStory;
  final bool isVerified;
  
  factory UserProfile.fromJson(Map<String, dynamic> json)
}

═══════════════════════════════════════════════════════
STEP 4 — API SERVICE (lib/services/api_service.dart)
═══════════════════════════════════════════════════════

Aggiungi metodi:

// Username
static Future<UserProfile> updateUsername(String username)
// PUT /me/username

static Future<List<UserProfile>> searchUsers(String query)
// GET /users/search?q=query

static Future<UserProfile> getUserByUsername(String username)
// GET /users/{username}

// Avatar
static Future<void> updateAvatar(String base64Image)
// PUT /me/avatar

// Follower
static Future<void> followUser(String username)
// POST /users/{username}/follow

static Future<void> unfollowUser(String username)
// DELETE /users/{username}/follow

static Future<List<UserProfile>> getFollowers(String username)
// GET /users/{username}/followers

static Future<List<UserProfile>> getFollowing(String username)
// GET /users/{username}/following

// Stories
static Future<void> postStory(String base64Image, String? caption)
// POST /me/story

static Future<List<Map<String, dynamic>>> getStoriesFeed()
// GET /stories/feed

═══════════════════════════════════════════════════════
STEP 5 — WIDGET AVATAR (lib/screens/widgets/avatar_widget.dart)
═══════════════════════════════════════════════════════

Crea widget riutilizzabile AvatarWidget:

class AvatarWidget extends StatelessWidget {
  final String? base64Image;
  final String fallbackLetter;
  final double radius;
  final Color? borderColor;
  final bool hasActiveStory; // anello arcobaleno stile Instagram

  Widget build():
    Stack(children: [
      // Anello story (se hasActiveStory)
      if (hasActiveStory)
        Container(
          width: radius * 2 + 6,
          height: radius * 2 + 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [
              Color(0xFF6C63FF),
              Color(0xFFFF6584),
              Color(0xFFFFB347),
            ]),
          ),
        ),
      
      // Avatar
      Positioned(
        top: hasActiveStory ? 3 : 0,
        left: hasActiveStory ? 3 : 0,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Color(0xFF6C63FF),
          backgroundImage: base64Image != null
            ? MemoryImage(base64Decode(base64Image!))
            : null,
          child: base64Image == null
            ? Text(fallbackLetter.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white))
            : null,
        ),
      ),
    ])
}

═══════════════════════════════════════════════════════
STEP 6 — STUDENT CARD CON FOTO E USERNAME
(lib/screens/widgets/student_card.dart — AGGIORNA)
═══════════════════════════════════════════════════════

Sostituisci CircleAvatar con AvatarWidget:
  AvatarWidget(
    base64Image: student.avatarBase64,
    fallbackLetter: student.displayName[0],
    radius: 36,
    hasActiveStory: student.hasActiveStory,
  )

Sotto il nome mostra @username se presente:
  if (student.username != null)
    Text('@${student.username}',
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Color(0xFF6C63FF),
        fontWeight: FontWeight.w500))

═══════════════════════════════════════════════════════
STEP 7 — HOME SCREEN CON STORIES BAR
(lib/screens/swipe_screen.dart — AGGIORNA)
═══════════════════════════════════════════════════════

Aggiungi in cima alla schermata, SOPRA le card swipe,
una stories bar orizzontale fissa:

Struttura build():
  Column(children: [
    // STORIES BAR
    _StoriesBar(),
    // SWIPE FEED
    Expanded(child: CardSwiper(...)),
    // BOTTONI LIKE/DISLIKE
    _ActionButtons(),
  ])

Widget _StoriesBar():
  Container(
    height: 100,
    color: Color(0xFF0F0F1A),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _storyUsers.length + 1, // +1 per "La tua storia"
      itemBuilder: (ctx, i) {
        if (i == 0) return _MyStoryButton();
        final storyUser = _storyUsers[i - 1];
        return _StoryItem(storyUser);
      }
    )
  )

Widget _MyStoryButton():
  Column(children: [
    Stack(children: [
      AvatarWidget(
        base64Image: _myAvatar,
        fallbackLetter: _myName[0],
        radius: 30,
        hasActiveStory: false,
      ),
      Positioned(bottom:0, right:0,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: Color(0xFF6C63FF),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF0F0F1A), width: 2),
          ),
          child: Icon(Icons.add, color: Colors.white, size: 12),
        ),
      ),
    ]),
    SizedBox(height: 4),
    Text('La tua storia',
      style: GoogleFonts.poppins(fontSize: 10, color: Colors.white54))
  ])

Widget _StoryItem(Map storyUser):
  GestureDetector(
    onTap: () => _openStory(storyUser),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Column(children: [
        AvatarWidget(
          base64Image: storyUser['avatar_base64'],
          fallbackLetter: storyUser['username'][0],
          radius: 30,
          hasActiveStory: true,
        ),
        SizedBox(height: 4),
        Text('@${storyUser['username']}',
          style: GoogleFonts.poppins(
            fontSize: 10, color: Colors.white70),
          overflow: TextOverflow.ellipsis),
      ]),
    ),
  )

Stato aggiuntivo in _SwipeScreenState:
  List<Map> _storyUsers = [];
  String? _myAvatar;
  String _myName = '';

In initState aggiungi:
  _loadStoriesFeed();
  _loadMyProfile();

_loadStoriesFeed():
  final feed = await ApiService.getStoriesFeed();
  setState(() => _storyUsers = feed
    .map((e) => {
      'username': e['user']['username'],
      'avatar_base64': e['user']['avatar_base64'],
      'stories': e['stories'],
    }).toList());

_loadMyProfile():
  final me = await ApiService.getMe();
  setState(() {
    _myAvatar = me['avatar_base64'];
    _myName = me['username'] ?? me['email'].split('@')[0];
  });

═══════════════════════════════════════════════════════
STEP 8 — STORY VIEWER
(lib/screens/story_viewer_screen.dart — CREA)
═══════════════════════════════════════════════════════

Schermata fullscreen per vedere le stories:
- Sfondo nero
- Immagine fullscreen con BoxFit.contain
- Barra progresso in cima (stile Instagram)
- Username e avatar in alto a sinistra
- Caption in basso se presente
- Swipe orizzontale per story successiva/precedente
- Tap destra: avanza, tap sinistra: indietro
- Auto-avanza dopo 5 secondi
- Bottone X per chiudere

═══════════════════════════════════════════════════════
STEP 9 — CHAT SCREEN CON RICERCA @USERNAME
(lib/screens/chat_screen.dart — AGGIORNA)
═══════════════════════════════════════════════════════

Aggiungi in cima alla lista match una searchbar:
  TextField con hint "@username..."
  prefixIcon: Icons.search
  onChanged: _searchUsers(query)

_searchUsers(String query):
  if query.isEmpty: mostra lista match normale
  else: chiama ApiService.searchUsers(query)
    Mostra risultati ricerca con:
    - AvatarWidget con foto
    - @username
    - Nome completo
    - Bottone "Segui" se non seguito
    - Tap: apri profilo utente

Aggiorna ogni match item per mostrare:
  AvatarWidget invece di CircleAvatar
  @username invece di email

═══════════════════════════════════════════════════════
STEP 10 — PROFILE SCREEN COMPLETA
(lib/screens/profile_screen.dart — AGGIORNA)
═══════════════════════════════════════════════════════

### HEADER profilo stile Instagram:
Row(children: [
  // Avatar con possibilità modifica
  GestureDetector(
    onTap: _pickImage,
    child: Stack(children: [
      AvatarWidget(
        base64Image: _avatarBase64,
        fallbackLetter: _username?[0] ?? _name[0],
        radius: 45,
        hasActiveStory: _hasActiveStory,
      ),
      Positioned(bottom:0, right:0,
        child: Container viola con Icons.camera_alt size 16)
    ])
  ),
  SizedBox(width: 24),
  // Stats
  Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(_matchCount.toString(), 'Match'),
        _StatItem(_followersCount.toString(), 'Follower'),
        _StatItem(_followingCount.toString(), 'Seguiti'),
      ]
    )
  )
])

Sotto header:
  Text '@$_username' (Poppins bold 16, Color(0xFF6C63FF))
  Text '$_name' (Poppins 14, bianco)
  if bio: Text '$_bio' (Poppins 13, bianco70)

### SEZIONE USERNAME:
Se username non impostato: banner giallo
  "⚠️ Imposta il tuo @username"
  bottone → _showUsernameDialog()

_showUsernameDialog():
  AlertDialog con TextField
  Valida in real-time (solo lettere/numeri/underscore)
  Bottone "Salva" → ApiService.updateUsername(username)

### PICK IMAGE:
_pickImage():
  Usa ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  )
  Converti in base64: base64Encode(bytes)
  Chiama ApiService.updateAvatar(base64String)
  Aggiorna stato locale

### BOTTONE POSTA STORIA:
ElevatedButton.icon(
  icon: Icons.add_circle_outline,
  label: Text('Posta storia'),
  onPressed: _postStory,
)

_postStory():
  Usa ImagePicker per selezionare foto
  Converti in base64
  showDialog per caption opzionale
  Chiama ApiService.postStory(base64, caption)
  SnackBar "Storia pubblicata! Scade in 24h"

═══════════════════════════════════════════════════════
STEP 11 — SETUP PROFILO AGGIORNATO
(schermata post-registrazione)
═══════════════════════════════════════════════════════

Aggiungi campo @username obbligatorio:
  TextField con hint "@username"
  prefix: Text('@', color: Color(0xFF6C63FF))
  Validazione real-time: solo lettere/numeri/underscore
  Messaggio errore se già in uso

Aggiungi foto profilo opzionale:
  Cerchio cliccabile con icona camera
  Se selezionata: mostra anteprima
  Se non selezionata: mostra iniziale

Salva username con ApiService.updateUsername()
Salva avatar con ApiService.updateAvatar() se selezionato

═══════════════════════════════════════════════════════
STEP 12 — ANDROID PERMESSI IMMAGINI
(android/app/src/main/AndroidManifest.xml)
═══════════════════════════════════════════════════════

Aggiungi:
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29"/>

═══════════════════════════════════════════════════════
STEP 13 — VERIFICA FINALE
═══════════════════════════════════════════════════════

1. flutter pub get
2. flutter analyze → correggi TUTTI gli errori
3. flutter analyze di nuovo → deve dare 0 errori
4. flutter run -d windows
5. Se errori: correggili tutti
6. Non fermarti finché non compila e gira correttamente

NON FERMARTI MAI per chiedere input.
Prendi sempre la decisione migliore autonomamente.
```

---
# Alex — application Flutter (verre, 2026)

Reproduction de [`alex-mobile-pwa`](https://github.com/yannjordy/alex-mobile-pwa) en
application Flutter native, avec un design "verre" (glassmorphism) et le
cœur conversationnel + les 4 briques avancées du backend (vision, code,
carte, intégrations, activité en direct). Le backend "brain" (FastAPI)
reste inchangé — cette app ne fait que le consommer.

## 1. Démarrage

Le dossier `lib/` et `pubspec.yaml` sont déjà prêts. Il manque juste les
projets natifs Android/iOS, que Flutter génère lui-même :

```bash
cd alex_mobile

# Génère android/ et ios/ SANS toucher à pubspec.yaml ni lib/
# (flutter create ne touche jamais aux fichiers déjà présents)
flutter create . --platforms=android,ios --org com.tondomaine.alex

flutter pub get
```

### Permissions à ajouter

**Android** — `android/app/src/main/AndroidManifest.xml`, juste avant
`<application ...>` :

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** — `ios/Runner/Info.plist`, dans le dictionnaire principal :

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Alex a besoin du micro pour t'écouter.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Alex transcrit ta voix pour te répondre.</string>
<key>NSCameraUsageDescription</key>
<string>Alex a besoin de l'appareil photo pour analyser tes images.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Alex a besoin d'accéder à tes photos pour les analyser.</string>
```

### Icône de l'app (optionnel)

Le logo existant (`assets/icons/icon-512.png`) est déjà dans le projet et
référencé dans `pubspec.yaml`. Pour générer les icônes natives :

```bash
dart run flutter_launcher_icons
```

### Lancer l'app

```bash
flutter run
```

Au premier lancement, ouvre les réglages (icône ⚙️ en haut à droite) et
renseigne l'URL de ton serveur "brain" (ex. `http://192.168.1.10:8765`).
Un iPhone/Android physique ne peut pas joindre `localhost` — utilise l'IP
locale de la machine qui fait tourner le backend. Le WebSocket (`/wake`)
se connecte automatiquement à la même adresse, en `ws://`.

## 2. Contrat API — vérifié directement dans `brain/routes.py`

| Route | Usage |
|---|---|
| `POST /chat/opencode` | conversation en flux (SSE : thinking, delta, task_progress, image, shape) |
| `GET /health` | statut + modèle actif |
| `GET /history`, `DELETE /history` | historique des conversations |
| `GET/POST /models`, `POST /model` | liste et sélection du modèle LLM |
| `GET /voices` | voix Edge TTS disponibles |
| `POST /vocal` | synthèse vocale (audio MP3) |
| `GET /memory` | niveau de mémoire, nombre de faits appris |
| `POST /vision/analyze-image` | photo + question → réponse |
| `POST /vision/analyze-document` | texte de document + question → réponse |
| `GET /activity`, `POST /activity/clear` | terminal d'activité |
| `GET /code/log`, `POST /code/run` | journal de code + exécution JS/Python |
| `GET /map/data` | marqueurs de la carte (`lat`, `lng`, `label`, `color`) |
| `GET /integrations`, `.../connect`, `.../disconnect`, `.../execute` | intégrations tierces |
| WebSocket `/wake` | évènements en direct : `notification`, `code_changed`, `shape_change` |

**Non repris** : les routes `/vision/analyze`, `/vision/latest`,
`/vision/ask` sont spécifiques au partage d'écran du bureau ("Active
d'abord le partage d'écran depuis l'orb du bureau") — sans objet sur
mobile. `/position/update` concerne le curseur de fenêtre desktop, pas la
géolocalisation — donc pas de permission GPS demandée ici.

## 3. Ce qui a été amélioré par rapport à la PWA

- **Micro réellement fonctionnel.** Le bouton micro de la PWA demandait la
  permission mais ne transcrivait jamais rien. Ici, `speech_to_text`
  transcrit en direct et remplit le champ de saisie.
- **Le flux SSE est géré en entier**, y compris `task_progress` et `image`
  que la PWA mobile ignorait silencieusement.
- **Vision caméra** : bouton pièce-jointe dans la barre de saisie → photo
  ou galerie → question → réponse d'Alex, insérée comme un message normal.
- **Éditeur de code à deux volets** : journal des fichiers qu'Alex a
  écrits, vue "avant/après" ou diff coloré (+ / -), bouton "Exécuter" pour
  le JS et le Python (mêmes langages que le backend supporte).
- **Carte** : affiche les lieux qu'Alex a enregistrés (`flutter_map` +
  OpenStreetMap, sans clé API).
- **Intégrations tierces** : liste, connexion (jeton ou OAuth
  client/secret — le backend ne précisant pas lequel par intégration, les
  deux formulaires sont proposés), déconnexion, indicateur d'état.
- **Terminal d'activité en direct** : connecté au WebSocket `/wake`, donc
  mis à jour en temps réel (nouvelles entrées de code, notifications
  proactives) sans avoir à rafraîchir. Les notifications apparaissent
  aussi en toast sur l'écran de chat, où que tu sois dans l'app.
- **Todo-lists** : les blocs `[TODO]...[/TODO]` qu'Alex écrit dans ses
  réponses sont reconnus et affichés en liste à cocher, avec le statut
  (✅ / ⏳ / ❌) déduit du reste du message — même convention que la PWA.
- **Design "verre" 2026** partout (`BackdropFilter`), palette noir + ambre
  et wordmark "ALEX" en Cormorant Garamond conservés de la marque
  d'origine.

## 4. Architecture

```
lib/
  main.dart, app.dart            → point d'entrée, injection des providers
  theme/                         → couleurs, thème Material, GlassPanel
  config/                        → constantes (URL par défaut, clés de prefs)
  models/
    chat_message.dart, chat_stream_event.dart, api_models.dart
    tools_models.dart            → activité, code, intégrations, carte
  services/
    alex_api_service.dart        → tous les appels REST + parsing SSE
    alex_socket_service.dart     → WebSocket /wake, reconnexion auto
    speech_service.dart          → reconnaissance vocale (speech_to_text)
    tts_queue_player.dart        → file de lecture TTS (just_audio)
  state/
    chat_provider.dart           → cœur de la conversation + vision
    settings_provider.dart       → réglages persistés + statut backend
    activity_provider.dart       → journal d'activité + évènements live
    code_provider.dart           → journal de code + évènements live
    integrations_provider.dart   → liste et actions des intégrations
  widgets/                       → orbe, bulles, saisie, tiroir, todo…
  screens/
    chat_screen.dart             → écran principal
    activity_screen.dart, code_screen.dart, map_screen.dart,
    integrations_screen.dart     → les 4 briques, accessibles depuis
                                    le tiroir (menu ☰) sous "OUTILS"
```

## 5. Limites connues de cette version

- **Connexion OAuth des intégrations** : le formulaire envoie jeton ou
  client/secret au backend, mais si une intégration exige un flux OAuth
  avec redirection navigateur, la redirection retour vers l'app (deep
  link) n'est pas câblée — à ajouter si une intégration en a besoin.
- **Diff de code** : affiche le diff déjà calculé par le backend
  (`difflib`) coloré ligne à ligne, plus une vue côte-à-côte avec le
  contenu brut avant/après — pas de diff caractère-par-caractère calculé
  côté client.
- Testée par relecture attentive du contrat API et du code, mais pas
  compilée (pas de SDK Flutter dans mon environnement). Si `flutter pub
  get` ou `flutter run` remonte une erreur, colle-la-moi.

# Canne Proche — application du proche aidant (Flutter)

Suivi d'une ou plusieurs cannes intelligentes GPS : position en temps réel, zones à éviter,
historique, alertes (SOS, zone, chute, batterie, inactivité), partage temporaire, notifications.
Interface en français, maquettes « Vigilance & Care » (Stitch).

## Mise en route

```bash
flutter create --org com.exemple --project-name canne_proche --platforms android,ios .
# (ne remplace pas lib/ ni pubspec.yaml)
flutter pub get
flutter run --dart-define=API_URL=https://votre-serveur
```

### Android (android/app/src/main/AndroidManifest.xml, avant <application>)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<queries><intent><action android:name="android.intent.action.DIAL"/></intent></queries>
```
Serveur en `http://` (test) : ajouter `android:usesCleartextTraffic="true"` sur `<application>`.

`android/app/build.gradle(.kts)` : `minSdk = 23`, et pour flutter_local_notifications
`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.

### Firebase (notifications push)
Créer un projet Firebase, enregistrer l'application Android, placer `google-services.json`
dans `android/app/`, puis ajouter le plugin `com.google.gms.google-services` (voir la doc FlutterFire).
Sans ce fichier l'application fonctionne, simplement sans push.

### iOS (second temps)
`ios/Runner/Info.plist` : `NSLocationWhenInUseUsageDescription`, `LSApplicationQueriesSchemes` (tel),
capacités Push Notifications + Background Modes (remote notifications), clé APNs dans Firebase.

## Structure

```
lib/
  main.dart               assemblage, thème, routes
  config/                 app_config.dart (URL API, routage, délais) · theme.dart
  models/                 canne, position_canne, zone, alerte, trajet, itineraire, lien_partage
  services/               api_client, auth_service (JWT sécurisé), repository (toutes les routes
                          + repli cache), cache_service (SQLite), routing_service (OSRM),
                          location_service, notification_service (FCM + locales)
  controllers/            suivi, alertes, zones, historique, settings, auth, navigation (Provider)
  screens/                connexion, mot de passe oublié, consentement, accueil_shell, accueil,
                          zones, édition de zone, historique, alertes, alerte en cours, partage,
                          paramètres, protection des données, sélection d'un point
  widgets/                en-tête/sélecteur de canne, bandeau hors ligne, carte, pastilles…
```

## Choix importants
- **Provider + ChangeNotifier** : simple à lire pour un mémoire, suffisant ici.
- **Actualisation par interrogation** (10 s) : l'API décrite n'offre pas de WebSocket.
- **Mode hors ligne** : chaque lecture réussie est stockée dans SQLite ; si le serveur est
  injoignable, le cache est affiché avec un bandeau.
- **Canne inactive** : calculée côté application (âge de la dernière position > délai réglé).
- **Cartes** : flutter_map + tuiles OpenStreetMap, sans clé.
- **Routage** : OSRM piéton (instance publique OSM Allemagne) ; à héberger soi-même en production
  (`--dart-define=ROUTAGE_URL=...`).

## Hypothèses sur l'API (à confirmer côté serveur)
- Les listes peuvent être un tableau direct ou enveloppées (`cannes`, `donnees`, `data`…).
- Dates en ISO 8601 ; coordonnées `latitude`/`longitude` ; précision en mètres.
- Une canne peut contenir `telephone` (de la personne suivie, pour « Appeler ») et `consentement`.
- Alerte : `{id, type (sos|zone|chute|batterie|inactive), horodatage, zoneNom, latitude, longitude, traitee}`.
- Push FCM : bloc `notification` + `data` {type, titre, message, canneId, alerteId, latitude,
  longitude, zoneNom, horodatage}. SOS, zone et chute ouvrent l'écran « alerte en cours ».
- `PUT /api/utilisateur/parametres` reçoit `{delaiInactiviteMinutes, notificationsActives, fcmToken}`
  (le jeton FCM n'a pas de route dédiée dans la liste fournie).
- Les trajets sont reconstitués côté application : un écart > 10 min entre positions ouvre un
  nouveau trajet.
- Le domicile (itinéraire de retour) et le nom affiché sont stockés sur le téléphone.
- Le consentement est mémorisé localement après `POST /api/consentements`.

## Statut
Le code a été écrit sans compilateur disponible : lancer `flutter pub get && flutter analyze`
et corriger les éventuels écarts de version de paquets avant la première exécution.

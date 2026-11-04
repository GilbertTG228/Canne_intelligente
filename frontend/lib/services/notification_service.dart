import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../controllers/settings_controller.dart';

/// Réception en arrière-plan (application fermée ou en veille).
/// Doit être une fonction de premier niveau.
///
/// Si le message contient un bloc `notification`, Android l'affiche tout seul.
/// Un message « data » seul est affiché ici avec flutter_local_notifications.
/// Hypothèse : data = {type, titre, message, canneId, alerteId, latitude,
/// longitude, zoneNom, horodatage}.
@pragma('vm:entry-point')
Future<void> gestionnaireMessageArrierePlan(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ));
  final data = message.data;
  await plugin.show(
    message.hashCode,
    (data['titre'] ?? 'Alerte canne') as String,
    (data['message'] ?? 'Une alerte nécessite votre attention.') as String,
    NotificationService.details(son: true, vibration: true),
    payload: jsonEncode(data),
  );
}

/// Notifications : FCM (réception) + flutter_local_notifications (affichage).
class NotificationService {
  NotificationService(this._reglages);

  final SettingsController _reglages;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _localPret = false;
  bool _firebasePret = false;
  int _compteur = 0;

  /// Appelé quand le proche touche une notification (ou ouvre l'appli par elle).
  void Function(Map<String, dynamic> data)? surOuverture;

  /// Appelé quand un message arrive alors que l'application est ouverte.
  void Function(Map<String, dynamic> data)? surMessageAuPremierPlan;

  /// Appelé avec le jeton FCM (initial puis à chaque renouvellement) pour
  /// l'enregistrer côté serveur.
  void Function(String jeton)? surJeton;

  /// À appeler dans main() avant runApp. Sans configuration Firebase
  /// (google-services.json absent), l'application fonctionne quand même,
  /// simplement sans notifications push.
  static Future<bool> initialiserFirebase() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(gestionnaireMessageArrierePlan);
      return true;
    } catch (_) {
      return false;
    }
  }

  static NotificationDetails details({required bool son, required bool vibration}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        canalId(son: son, vibration: vibration),
        'Alertes de la canne',
        channelDescription: 'SOS, entrées en zone, chutes, batterie faible, canne inactive',
        importance: Importance.max,
        priority: Priority.high,
        playSound: son,
        enableVibration: vibration,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(presentSound: son, presentAlert: true, presentBadge: true),
    );
  }

  /// Sur Android, le son et la vibration se règlent par canal : un canal par
  /// combinaison, choisi selon les paramètres de l'utilisateur.
  static String canalId({required bool son, required bool vibration}) =>
      'alertes_${son ? 's' : 'x'}${vibration ? 'v' : 'x'}';

  /// À appeler une fois l'utilisateur connecté.
  Future<void> demarrer() async {
    await _initialiserLocal();
    _firebasePret = await initialiserFirebaseSiNecessaire();
    if (!_firebasePret) return;

    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);
    await fcm.setForegroundNotificationPresentationOptions(
        alert: false, badge: true, sound: false);

    final jeton = await fcm.getToken();
    if (jeton != null) surJeton?.call(jeton);
    fcm.onTokenRefresh.listen((j) => surJeton?.call(j));

    FirebaseMessaging.onMessage.listen((message) {
      final data = Map<String, dynamic>.from(message.data);
      final titre = message.notification?.title ?? data['titre']?.toString();
      final corps = message.notification?.body ?? data['message']?.toString();
      if (_reglages.notificationsActives) {
        afficher(titre ?? 'Alerte canne', corps ?? '', data);
      }
      surMessageAuPremierPlan?.call(data);
    });
    FirebaseMessaging.onMessageOpenedApp
        .listen((m) => surOuverture?.call(Map<String, dynamic>.from(m.data)));

    final initial = await fcm.getInitialMessage();
    if (initial != null) surOuverture?.call(Map<String, dynamic>.from(initial.data));
  }

  bool get _firebaseInitialisee => Firebase.apps.isNotEmpty;

  Future<bool> initialiserFirebaseSiNecessaire() async {
    if (_firebaseInitialisee) return true;
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initialiserLocal() async {
    if (_localPret) return;
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (reponse) {
        final payload = reponse.payload;
        if (payload == null || payload.isEmpty) {
          surOuverture?.call(<String, dynamic>{});
          return;
        }
        try {
          surOuverture?.call(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {
          surOuverture?.call(<String, dynamic>{});
        }
      },
    );
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    for (final son in [true, false]) {
      for (final vib in [true, false]) {
        await android?.createNotificationChannel(AndroidNotificationChannel(
          canalId(son: son, vibration: vib),
          'Alertes de la canne${son ? '' : ' (sans son)'}${vib ? '' : ' (sans vibration)'}',
          importance: Importance.max,
          playSound: son,
          enableVibration: vib,
        ));
      }
    }
    _localPret = true;
  }

  /// Affiche une notification locale en respectant les réglages son/vibration.
  Future<void> afficher(String titre, String corps, [Map<String, dynamic>? data]) async {
    await _initialiserLocal();
    await _local.show(
      ++_compteur,
      titre,
      corps,
      details(son: _reglages.sons, vibration: _reglages.vibrations),
      payload: data == null ? null : jsonEncode(data),
    );
  }
}

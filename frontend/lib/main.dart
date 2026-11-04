import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'controllers/alertes_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/historique_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/suivi_controller.dart';
import 'controllers/zones_controller.dart';
import 'screens/accueil_shell.dart';
import 'screens/connexion_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/repository.dart';
import 'services/routing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  // Sans google-services.json, l'application démarre quand même (sans push).
  await NotificationService.initialiserFirebase();

  final reglages = await SettingsController.charger();
  final cache = CacheService();

  // ApiClient a besoin du jeton (AuthService) et AuthService a besoin
  // d'ApiClient : on rompt le cycle avec une variable « late ».
  late final AuthService authService;
  final api = ApiClient(lireJeton: () => authService.lireJeton());
  authService = AuthService(api);

  final repository = Repository(api, cache);
  final notifications = NotificationService(reglages);

  final auth = AuthController(authService, cache, reglages);
  final suivi = SuiviController(repository, reglages, notifications);
  final alertes = AlertesController(repository);
  final zones = ZonesController(repository);
  final historique = HistoriqueController(repository);
  final navigation = NavigationController();

  // 401 du serveur -> retour à l'écran de connexion.
  api.surNonAutorise = () => auth.sessionExpiree();
  // À chaque déconnexion, on oublie les données de la session.
  auth.surDeconnexion = () {
    suivi.reinitialiser();
    alertes.reinitialiser();
    zones.reinitialiser();
    historique.reinitialiser();
    navigation.reinitialiser();
  };

  await auth.initialiser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: reglages),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: suivi),
        ChangeNotifierProvider.value(value: alertes),
        ChangeNotifierProvider.value(value: zones),
        ChangeNotifierProvider.value(value: historique),
        ChangeNotifierProvider.value(value: navigation),
        Provider.value(value: authService),
        Provider.value(value: repository),
        Provider.value(value: notifications),
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => RoutingService()),
      ],
      child: const CanneProcheApp(),
    ),
  );
}

class CanneProcheApp extends StatefulWidget {
  const CanneProcheApp({super.key});

  @override
  State<CanneProcheApp> createState() => _CanneProcheAppState();
}

class _CanneProcheAppState extends State<CanneProcheApp> {
  final _navigateur = GlobalKey<NavigatorState>();
  late final AuthController _auth;
  bool _etaitConnecte = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthController>();
    _etaitConnecte = _auth.connecte;
    _auth.addListener(_surAuth);
  }

  @override
  void dispose() {
    _auth.removeListener(_surAuth);
    super.dispose();
  }

  /// À la déconnexion, on ferme les écrans empilés (paramètres, alerte…)
  /// pour que l'écran de connexion soit bien celui qui s'affiche.
  void _surAuth() {
    if (_etaitConnecte && !_auth.connecte) {
      _navigateur.currentState?.popUntil((route) => route.isFirst);
    }
    _etaitConnecte = _auth.connecte;
  }

  @override
  Widget build(BuildContext context) {
    final reglages = context.watch<SettingsController>();
    final connecte = context.select<AuthController, bool>((a) => a.connecte);

    return MaterialApp(
      title: 'Canne Proche',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigateur,
      theme: AppTheme.claire(),
      darkTheme: AppTheme.sombre(),
      themeMode: reglages.themeMode,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: connecte
          ? AccueilShell(key: const ValueKey('shell'), navigatorKey: _navigateur)
          : const ConnexionScreen(),
    );
  }
}

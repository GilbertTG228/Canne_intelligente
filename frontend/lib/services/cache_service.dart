import 'dart:convert';

import 'package:path/path.dart' as chemin;
import 'package:sqflite/sqflite.dart';

class EntreeCache {
  const EntreeCache(this.json, this.maj);
  final dynamic json;
  final DateTime maj;
}

/// Cache local (SQLite) des dernières réponses de l'API : permet de consulter
/// les données déjà reçues sans réseau. Une table clé -> JSON suffit ici.
class CacheService {
  Database? _base;

  Future<Database> _ouvrir() async {
    final existante = _base;
    if (existante != null) return existante;
    final base = await openDatabase(
      chemin.join(await getDatabasesPath(), 'canne_proche_cache.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE cache (cle TEXT PRIMARY KEY, valeur TEXT NOT NULL, maj INTEGER NOT NULL)',
      ),
    );
    _base = base;
    return base;
  }

  Future<void> ecrire(String cle, dynamic json) async {
    try {
      final base = await _ouvrir();
      await base.insert(
        'cache',
        {
          'cle': cle,
          'valeur': jsonEncode(json),
          'maj': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Le cache est un confort : une erreur de stockage ne doit rien bloquer.
    }
  }

  Future<EntreeCache?> lire(String cle) async {
    try {
      final base = await _ouvrir();
      final lignes = await base.query('cache', where: 'cle = ?', whereArgs: [cle], limit: 1);
      if (lignes.isEmpty) return null;
      return EntreeCache(
        jsonDecode(lignes.first['valeur'] as String),
        DateTime.fromMillisecondsSinceEpoch(lignes.first['maj'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> vider() async {
    try {
      final base = await _ouvrir();
      await base.delete('cache');
    } catch (_) {}
  }
}

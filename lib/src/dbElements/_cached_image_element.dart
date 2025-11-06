import "dart:async";

import "package:path/path.dart" show join;
import "package:sqflite/sqflite.dart";

/// Represents a cached image entry stored in the database.
class CachedImageElement {
  /// Unique identifier of the cached image. May be null for new entries.
  final int? id;

  /// Original URL of the image.
  final String url;

  /// Local file path where the image is stored.
  final String path;

  /// Number of times this cached image has been accessed.
  final int usageCount;

  /// Timestamp of the last time this image was accessed.
  final DateTime lastUsage;

  /// Creates a [CachedImageElement].
  const CachedImageElement({this.id, required this.url, required this.path, required this.usageCount, required this.lastUsage});

  /// Converts this object into a map suitable for storing in a database.
  ///
  /// If [includeId] is true, includes the `id` field in the map.
  Map<String, Object?> toMap({bool includeId = true}) {
    final Map<String, Object?> map = {      
      "url": url,
      "path": path,
      "usageCount": usageCount,
      "lastUsage": lastUsage.millisecondsSinceEpoch
    };

    if(includeId) {
      map["id"] = id;
    }

    return map;
  }

  /// Creates a [CachedImageElement] from a database map.
  factory CachedImageElement.fromMap(Map<String, Object?> map) {
    return CachedImageElement(
      id: map["id"] as int,
      url: map["url"] as String,
      path: map["path"] as String,
      usageCount: map["usageCount"] as int,
      lastUsage: DateTime.fromMillisecondsSinceEpoch(map["lastUsage"] as int)
    );
  }
}

/// Provides database operations for cached image elements.
class CachedImageElementProvider {
  static const String _table = "cachedImageElements";
  static Database? _db;

  /// Initializes the database if needed, creating the table on first run.
  static Future<Database> _initDatabase() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), "cachedImageDB.db"),
      // When the database is first created, create a table to store DownloadedSongCacheElements.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          "CREATE TABLE $_table(id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT, path TEXT, audioFilter TEXT, usageCount INTEGER, lastUsage INTEGER)",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    return _db!;
  }

  /// Returns the initialized database instance.
  static Future<Database> get database async {
    return await _initDatabase();
  }

  /// Inserts a new [CachedImageElement] into the database.
  ///
  /// Throws an error if a conflicting entry exists.
  static Future<void> insert(CachedImageElement cachedImageElement) async {
    Database db = await database;
    await db.insert(
      _table,
      cachedImageElement.toMap(includeId: false),
      conflictAlgorithm: ConflictAlgorithm.abort
    );
  }

  /// Returns all cached image elements.
  ///
  /// If [orderByUsageAsc] is true, results are ordered by `lastUsage` and `usageCount` ascending.
  static Future<List<CachedImageElement>> list({bool orderByUsageAsc = false}) async {
    List<CachedImageElement> list = List.empty(growable: true);
    Database db = await database;
    List<Map<String, Object?>> maps = await db.query(_table, orderBy: orderByUsageAsc ? "lastUsage, usageCount" : null);
    for (Map<String, Object?> map in maps) {
      list.add(CachedImageElement.fromMap(map));
    }
    return list;
  }

  /// Returns a cached image element for the given [url], or `null` if not found.
  static Future<CachedImageElement?> get(String url) async {
    Database db = await database;
    
    List<Map<String, Object?>> maps = await db.query(
      _table,
      columns: ["id", "url", "path", "usageCount", "lastUsage"],
      where: "url = ?",
      whereArgs: [url],
      limit: 1
    );
    if(maps.isNotEmpty) {
      Map<String, Object?> map = maps.first;
      return CachedImageElement.fromMap(map);
    }
    return null;
  }

  /// Removes a cached image element with the specified [id].
  static Future<void> remove(int id) async {
    Database db = await database;
    await db.delete(
      _table,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  /// Updates the last usage timestamp of the cached image element with [id].
  ///
  /// If [incrementUsageCount] is true, also increments the usage count by 1.
  static Future<void> updateLastUsage(int id, DateTime lastUsage, {bool incrementUsageCount = false}) async {
    Database db = await database;
    if (incrementUsageCount) {
      await db.rawUpdate(
        '''
        UPDATE $_table
        SET lastUsage = ?, usageCount = usageCount + 1
        WHERE id = ?
        ''',
        [lastUsage.millisecondsSinceEpoch, id],
      );
    } else {
      await db.update(
        _table,
        {"lastUsage": lastUsage.millisecondsSinceEpoch},
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }
}
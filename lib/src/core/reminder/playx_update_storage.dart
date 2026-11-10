/// Where [PlayxUpdateReminder] remembers snoozed and skipped versions.
///
/// The package ships only an in-memory implementation so it does not force a
/// storage dependency on your app. To keep the choice across app launches,
/// implement this with the storage you already use, for example
/// `shared_preferences`:
///
/// ```dart
/// class PrefsUpdateStorage implements PlayxUpdateStorage {
///   PrefsUpdateStorage(this._prefs);
///   final SharedPreferences _prefs;
///
///   @override
///   Future<String?> read(String key) async => _prefs.getString(key);
///
///   @override
///   Future<void> write(String key, String value) =>
///       _prefs.setString(key, value);
///
///   @override
///   Future<void> remove(String key) => _prefs.remove(key);
/// }
/// ```
abstract interface class PlayxUpdateStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

/// A [PlayxUpdateStorage] that keeps values in memory, so they are lost when
/// the app process ends.
class PlayxInMemoryUpdateStorage implements PlayxUpdateStorage {
  /// The storage used when none is provided, shared for the whole process.
  static final PlayxInMemoryUpdateStorage shared = PlayxInMemoryUpdateStorage();

  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}

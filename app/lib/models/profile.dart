import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/storage.dart';

/// The player's identity for online features. No password — the email is just
/// how your results are keyed and how friends find you. Persisted locally.
class Profile extends ChangeNotifier {
  static const _key = 'profile_v1';

  String name;
  String email;
  List<String> friends; // friends' emails (for friend competition)

  Profile({this.name = '', this.email = '', List<String>? friends})
      : friends = friends ?? <String>[];

  bool get hasIdentity => email.isNotEmpty;

  factory Profile.load() {
    final raw = Storage.getString(_key);
    if (raw == null) return Profile();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return Profile(
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        friends: [for (final e in (m['friends'] as List? ?? [])) e as String],
      );
    } catch (_) {
      return Profile();
    }
  }

  void _save() {
    Storage.setString(
      _key,
      jsonEncode({'name': name, 'email': email, 'friends': friends}),
    );
    notifyListeners();
  }

  void setIdentity({required String name, required String email}) {
    this.name = name.trim();
    this.email = email.trim().toLowerCase();
    _save();
  }

  void addFriend(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || friends.contains(e) || e == this.email) return;
    friends.add(e);
    _save();
  }

  void removeFriend(String email) {
    friends.remove(email.trim().toLowerCase());
    _save();
  }

  static bool isValidEmail(String e) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(e.trim());
  }
}

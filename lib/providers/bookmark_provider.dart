import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/internship_model.dart';

class BookmarkProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_internships_v1';

  final List<InternshipModel> _savedInternships = [];
  final Set<int> _savedIds = {};
  bool _isLoaded = false;

  BookmarkProvider() {
    _loadBookmarks();
  }

  List<InternshipModel> get savedInternships => List.unmodifiable(_savedInternships);
  Set<int> get savedIds => Set.unmodifiable(_savedIds);
  int get count => _savedInternships.length;
  bool get isEmpty => _savedInternships.isEmpty;
  bool get isLoaded => _isLoaded;

  bool isBookmarked(int internshipId) {
    return _savedIds.contains(internshipId);
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey);
      if (listJson != null && listJson.isNotEmpty) {
        _savedInternships.clear();
        _savedIds.clear();

        for (final itemStr in listJson) {
          try {
            final Map<String, dynamic> data = jsonDecode(itemStr);
            final internship = InternshipModel.fromJson(data);
            _savedInternships.add(internship);
            _savedIds.add(internship.id);
          } catch (e) {
            debugPrint('Error parsing saved internship item: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved bookmarks: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _savedInternships.map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList(_storageKey, listJson);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<bool> toggleBookmark(InternshipModel internship) async {
    final isAlreadySaved = _savedIds.contains(internship.id);

    if (isAlreadySaved) {
      _savedIds.remove(internship.id);
      _savedInternships.removeWhere((i) => i.id == internship.id);
      notifyListeners();
      await _saveBookmarks();
      return false; // Now un-bookmarked
    } else {
      _savedIds.add(internship.id);
      _savedInternships.insert(0, internship);
      notifyListeners();
      await _saveBookmarks();
      return true; // Now bookmarked
    }
  }

  Future<void> removeBookmark(int internshipId) async {
    if (_savedIds.contains(internshipId)) {
      _savedIds.remove(internshipId);
      _savedInternships.removeWhere((i) => i.id == internshipId);
      notifyListeners();
      await _saveBookmarks();
    }
  }

  Future<void> clearAll() async {
    _savedIds.clear();
    _savedInternships.clear();
    notifyListeners();
    await _saveBookmarks();
  }
}

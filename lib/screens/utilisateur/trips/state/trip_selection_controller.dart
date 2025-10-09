import 'package:flutter/foundation.dart';

/// Local-only selection controller for Trips export mode.
/// Holds the export mode flag and the set of selected trip ids.
class TripSelectionController extends ChangeNotifier {
  bool _exportMode = false;
  final Set<String> _selectedIds = <String>{};

  bool get exportMode => _exportMode;
  Set<String> get selectedIds => _selectedIds;
  int get count => _selectedIds.length;

  void toggleExportMode([bool? on]) {
    final bool next = on ?? !_exportMode;
    if (_exportMode == next) return;
    _exportMode = next;
    if (!_exportMode) {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void toggle(String tripId) {
    if (_selectedIds.contains(tripId)) {
      _selectedIds.remove(tripId);
    } else {
      _selectedIds.add(tripId);
    }
    notifyListeners();
  }

  bool isSelected(String tripId) => _selectedIds.contains(tripId);

  void clear() {
    if (_selectedIds.isEmpty && !_exportMode) return;
    _selectedIds.clear();
    _exportMode = false;
    notifyListeners();
  }
}



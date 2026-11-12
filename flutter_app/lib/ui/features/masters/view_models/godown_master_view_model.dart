import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/godown.dart';

class GodownMasterViewModel extends ChangeNotifier {
  GodownMasterViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Godown> _godowns = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  int? _editingId;
  String _name = '';

  List<Godown> get godowns => _godowns;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int? get editingId => _editingId;
  String get name => _name;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _godowns = await _masterRepo.fetchGodowns();
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void editGodown(Godown godown) {
    _editingId = godown.id;
    _name = godown.name;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm() {
    _editingId = null;
    _name = '';
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> saveGodown() async {
    if (_name.trim().isEmpty) {
      _errorMessage = 'Godown name is required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final saved = await _masterRepo.saveGodown(
        Godown(id: _editingId ?? 0, name: _name.trim()),
      );
      clearForm();
      _godowns = await _masterRepo.fetchGodowns();
      _successMessage = 'Godown "${saved.name}" saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _godowns = const [];
    clearForm();
  }
}

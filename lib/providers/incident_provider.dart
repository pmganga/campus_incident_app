import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';
import '../utils/constants.dart';

enum WriteOutcome {
  done,

  queuedOffline,
  failed,
}

/// How the reports list is ordered.
enum ReportSort {
  newest('Newest first'),
  oldest('Oldest first'),
  recentlyUpdated('Recently updated');

  const ReportSort(this.label);

  final String label;
}

/// The result of any write (submit, status update, withdraw).
class WriteResult {
  final WriteOutcome outcome;
  final String? errorMessage;

  const WriteResult(this.outcome, [this.errorMessage]);

  bool get isFailure => outcome == WriteOutcome.failed;
}

/// App-wide incident state. Kept in sync with the signed-in user by
/// ChangeNotifierProxyProvider in main.dart.
///
/// Holds one live list of reports: a student's own reports, or every report
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._incidentService, {this.photoRetryDelay = const Duration(seconds: 1)});

  /// How long to wait for the server before treating a write as queued offline.
  static const writeTimeout = Duration(seconds: 15);

  final IncidentService _incidentService;

  /// Wait before the first photo retry; doubled for each further retry.
  final Duration photoRetryDelay;

  /// Download attempts per photo before showing the category icon instead.
  static const photoAttempts = 4;

  AppUser? _currentUser;
  StreamSubscription<List<Incident>>? _subscription;
  List<Incident> _reports = const [];
  bool _isLoading = false;
  String? _loadError;
  bool _isSubmitting = false;

  // Filters used by the reports list screens.
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  String _searchQuery = '';
  ReportSort _sort = ReportSort.newest;

  /// Downloaded photos, kept for the session so scrolling a list does not
  /// download the same photo again.
  final Map<String, Future<Uint8List?>> _photoCache = {};

  /// Students: their own reports. Staff: every report. Newest first.
  List<Incident> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isSubmitting => _isSubmitting;
  bool get isStaffView => _currentUser?.isStaff ?? false;

  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;
  ReportSort get sort => _sort;
  bool get hasActiveFilters =>
      _statusFilter != null || _categoryFilter != null || _searchQuery.isNotEmpty;

  List<Incident> get recentIncidents => _reports.take(3).toList();

  /// Reports waiting for staff to pick them up, oldest first (first come, first served).
  List<Incident> get awaitingReview =>
      _reports.where((i) => i.status == IncidentStatus.submitted).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  int countByStatus(IncidentStatus status) =>
      _reports.where((incident) => incident.status == status).length;

  /// The reports after applying the status, category and search filters,
  /// in the chosen order.
  List<Incident> get filteredIncidents {
    final results = _reports.where(_matchesFilters).toList();
    switch (_sort) {
      case ReportSort.newest:
        break; // the stream is already newest first
      case ReportSort.oldest:
        results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ReportSort.recentlyUpdated:
        results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return results;
  }

  /// Reports the student created in the last 24 hours.
  int get reportsInLast24Hours {
    final since = DateTime.now().subtract(const Duration(hours: 24));
    return _reports
        .where((i) => i.reporterId == _currentUser?.uid && i.createdAt.isAfter(since))
        .length;
  }

  /// Misuse protection: students may submit at most
  /// [AppConstants.dailyReportLimit] reports in any 24 hours.
  bool get hasReachedDailyLimit =>
      !isStaffView && reportsInLast24Hours >= AppConstants.dailyReportLimit;

  /// When the student may report again after reaching the daily limit: 24
  /// hours after the oldest report that still counts towards it.
  DateTime? get nextReportAllowedAt {
    if (!hasReachedDailyLimit) return null;
    final since = DateTime.now().subtract(const Duration(hours: 24));
    final recent = _reports
        .where((i) => i.reporterId == _currentUser?.uid && i.createdAt.isAfter(since))
        .map((i) => i.createdAt)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    // Once the oldest of the newest [dailyReportLimit] reports is 24 h old,
    // the count drops below the limit.
    return recent[AppConstants.dailyReportLimit - 1].add(const Duration(hours: 24));
  }

  /// An open report by this student with the same category and place, used to
  /// warn about duplicates before submitting.
  Incident? findSimilarOpenReport(IncidentCategory category, String location) {
    for (final incident in _reports) {
      if (incident.reporterId == _currentUser?.uid &&
          incident.status.isOpen &&
          incident.category == category &&
          incident.location == location) {
        return incident;
      }
    }
    return null;
  }

  /// The photo for [incident], downloaded once and then cached.
  Future<Uint8List?> photoFor(Incident incident) {
    if (!incident.hasPhoto) return Future.value(null);
    return _photoCache.putIfAbsent(incident.id, () {
      final future = _fetchPhotoWithRetry(incident.id);
      // Forget failures so the next attempt tries again.
      future.catchError((Object _) {
        _photoCache.remove(incident.id);
        return null;
      });
      return future;
    });
  }

  /// Right after a report is submitted, the photo may not have reached the
  /// server yet, and Firestore refuses to read a document that is not there.
  /// Retrying a few times (1 s, 2 s, 4 s) lets the new thumbnail appear.
  Future<Uint8List?> _fetchPhotoWithRetry(String incidentId) async {
    var delay = photoRetryDelay;
    for (var attempt = 1; ; attempt++) {
      try {
        return await _incidentService.fetchPhoto(incidentId);
      } catch (_) {
        if (attempt == photoAttempts) rethrow;
      }
      await Future<void>.delayed(delay);
      delay *= 2;
    }
  }

  Incident? incidentById(String id) {
    for (final incident in _reports) {
      if (incident.id == id) return incident;
    }
    return null;
  }

  /// A student may withdraw their own report until staff start working on it.
  bool canWithdraw(Incident incident) =>
      incident.reporterId == _currentUser?.uid && incident.status == IncidentStatus.submitted;

  bool _matchesFilters(Incident incident) {
    if (_statusFilter != null && incident.status != _statusFilter) return false;
    if (_categoryFilter != null && incident.category != _categoryFilter) return false;
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return incident.title.toLowerCase().contains(query) ||
        incident.description.toLowerCase().contains(query) ||
        incident.fullLocation.toLowerCase().contains(query) ||
        incident.category.label.toLowerCase().contains(query) ||
        (isStaffView && !incident.isAnonymous && incident.reporterName.toLowerCase().contains(query));
  }

  void setStatusFilter(IncidentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSort(ReportSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Called whenever AuthProvider changes (sign-in, sign-out, role change).
  /// Runs during a build, so it must not call notifyListeners() directly.
  void updateUser(AppUser? user) {
    if (user?.uid == _currentUser?.uid && user?.role == _currentUser?.role) return;
    _currentUser = user;

    _subscription?.cancel();
    _subscription = null;
    _reports = const [];
    _loadError = null;
    _statusFilter = null;
    _categoryFilter = null;
    _searchQuery = '';
    _sort = ReportSort.newest;
    _photoCache.clear();

    if (user == null) {
      _isLoading = false;
      return;
    }
    _isLoading = true;
    final stream = user.isStaff
        ? _incidentService.watchAllIncidents()
        : _incidentService.watchIncidentsByReporter(user.uid);
    _subscription = stream.listen(
      (incidents) {
        _reports = incidents;
        _isLoading = false;
        _loadError = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _loadError = error is FirebaseException && error.code == 'permission-denied'
            ? 'You do not have permission to view these reports.'
            : 'Could not load reports. Check your connection.';
        notifyListeners();
      },
    );
  }

  Future<WriteResult> submitIncident({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? locationDetail,
    Uint8List? photo,
    bool isAnonymous = false,
  }) async {
    final reporter = _currentUser;
    if (reporter == null) {
      return const WriteResult(WriteOutcome.failed, 'You need to be signed in to submit a report.');
    }
    if (hasReachedDailyLimit) {
      return const WriteResult(WriteOutcome.failed,
          'You have reached the limit of ${AppConstants.dailyReportLimit} reports in 24 hours. '
          'Please try again later.');
    }

    _isSubmitting = true;
    notifyListeners();
    try {
      return await _write(
        'submit the report',
        () => _incidentService.createIncident(
          reporter: reporter,
          title: title,
          description: description,
          category: category,
          location: location,
          locationDetail: locationDetail,
          photo: photo,
          isAnonymous: isAnonymous,
        ),
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Staff only. A note is required when rejecting, so the student knows why.
  Future<WriteResult> updateStatus(Incident incident, IncidentStatus status, {String? note}) {
    final staff = _currentUser;
    if (staff == null || !staff.isStaff) {
      return Future.value(
          const WriteResult(WriteOutcome.failed, 'Only staff can change a report\'s status.'));
    }
    if (status == incident.status) {
      return Future.value(const WriteResult(WriteOutcome.failed, 'Choose a different status.'));
    }
    if (status == IncidentStatus.rejected && (note == null || note.trim().isEmpty)) {
      return Future.value(
          const WriteResult(WriteOutcome.failed, 'Please give a reason for rejecting.'));
    }
    return _write(
      'update the status',
      () => _incidentService.updateStatus(
        incidentId: incident.id,
        status: status,
        changedBy: staff,
        note: note,
      ),
    );
  }

  /// Student only, and only while the report is still "submitted".
  Future<WriteResult> withdrawIncident(Incident incident) {
    if (!canWithdraw(incident)) {
      return Future.value(const WriteResult(WriteOutcome.failed,
          'Only reports that have not been picked up yet can be withdrawn.'));
    }
    return _write('withdraw the report', () => _incidentService.deleteIncident(incident));
  }

  /// Runs a Firestore write with a timeout and turns errors into friendly messages.
  Future<WriteResult> _write(String action, Future<void> Function() write) async {
    try {
    
      await write().timeout(writeTimeout);
      return const WriteResult(WriteOutcome.done);
    } on TimeoutException {
      return const WriteResult(WriteOutcome.queuedOffline);
    } on FirebaseException catch (e) {
      final message = e.code == 'permission-denied'
          ? 'You do not have permission to $action.'
          : 'Could not $action (${e.code}). Please try again.';
      return WriteResult(WriteOutcome.failed, message);
    } catch (_) {
      return WriteResult(WriteOutcome.failed, 'Could not $action. Please try again.');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

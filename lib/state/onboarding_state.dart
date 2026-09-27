import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_books.dart';
import '../data/models.dart';
import '../data/sheet_link.dart';
import 'app_state.dart';
import 'deal_state.dart';
import 'library_state.dart';

enum OnbStatus { empty, checking, ok, access, columns, format, offline, unknown }

@immutable
class OnboardingState {
  const OnboardingState({
    this.url = '',
    this.status = OnbStatus.empty,
    this.candidate,
    this.missing = const <String>[],
    this.found = const <String>[],
    this.isDemo = false,
  });

  final String url;
  final OnbStatus status;

  /// The list we loaded but have not committed yet.
  final LibraryData? candidate;
  final List<String> missing;
  final List<String> found;
  final bool isDemo;

  bool get isError =>
      status == OnbStatus.access ||
      status == OnbStatus.columns ||
      status == OnbStatus.format ||
      status == OnbStatus.unknown;

  OnboardingState copyWith({
    String? url,
    OnbStatus? status,
    LibraryData? candidate,
    bool clearCandidate = false,
    List<String>? missing,
    List<String>? found,
    bool? isDemo,
  }) =>
      OnboardingState(
        url: url ?? this.url,
        status: status ?? this.status,
        candidate: clearCandidate ? null : (candidate ?? this.candidate),
        missing: missing ?? this.missing,
        found: found ?? this.found,
        isDemo: isDemo ?? this.isDemo,
      );
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  int _generation = 0;

  @override
  OnboardingState build() => const OnboardingState();

  /// Pre-fills the field, e.g. when arriving from "Сменить таблицу".
  void prefill(String url) =>
      state = OnboardingState(url: url, status: OnbStatus.empty);

  void setUrl(String url) => state = state.copyWith(
        url: url,
        status: OnbStatus.empty,
        clearCandidate: true,
        isDemo: false,
      );

  /// Shows the "нет интернета" state on a cold start with no cache.
  void showOffline() => state = state.copyWith(status: OnbStatus.offline);

  Future<void> connect([String? override]) async {
    final url = (override ?? state.url).trim();
    final link = parseSheetLink(url);
    if (link == null) {
      state = state.copyWith(
          url: url, status: OnbStatus.format, clearCandidate: true, isDemo: false);
      return;
    }
    _generation++;
    final gen = _generation;
    state = state.copyWith(
        url: url, status: OnbStatus.checking, clearCandidate: true, isDemo: false);
    try {
      final data =
          await ref.read(sheetLoaderProvider).load(link, originalUrl: url);
      if (gen != _generation) return;
      state = state.copyWith(status: OnbStatus.ok, candidate: data);
    } on SheetException catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(
        status: switch (e.kind) {
          SheetFailure.access => OnbStatus.access,
          SheetFailure.columns => OnbStatus.columns,
          SheetFailure.format => OnbStatus.format,
          SheetFailure.network => OnbStatus.offline,
          SheetFailure.unknown => OnbStatus.unknown,
        },
        missing: e.missing,
        found: e.found,
        clearCandidate: true,
      );
    } catch (_) {
      if (gen != _generation) return;
      state = state.copyWith(status: OnbStatus.unknown, clearCandidate: true);
    }
  }

  void useSample() {
    _generation++;
    final language = ref.read(settingsProvider).language;
    state = state.copyWith(
      status: OnbStatus.ok,
      candidate: demoLibrary(language),
      url: '',
      isDemo: true,
    );
  }

  /// Reloads the candidate from another tab of the same spreadsheet.
  Future<void> selectTab(String gid) async {
    final candidate = state.candidate;
    if (candidate == null || candidate.gid == gid || state.isDemo) return;
    _generation++;
    final gen = _generation;
    state = state.copyWith(status: OnbStatus.checking);
    try {
      final data = await ref.read(sheetLoaderProvider).load(
            SheetLink(id: candidate.sheetId, gid: gid),
            originalUrl: candidate.sheetUrl,
          );
      if (gen != _generation) return;
      state = state.copyWith(status: OnbStatus.ok, candidate: data);
    } on SheetException catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(
        status: e.kind == SheetFailure.columns ? OnbStatus.columns : OnbStatus.access,
        missing: e.missing,
        found: e.found,
      );
    }
  }

  /// Commits the loaded list and moves to the table.
  void start() {
    final data = state.candidate;
    if (data == null) return;
    ref.read(libraryProvider.notifier).adopt(data, cache: !state.isDemo);
    ref
        .read(settingsProvider.notifier)
        .setSheetUrl(state.isDemo ? null : data.sheetUrl);
    ref.read(dealProvider.notifier).deal(data.unread);
    ref.read(routeProvider.notifier).go(AppRoute.deal);
    state = const OnboardingState();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

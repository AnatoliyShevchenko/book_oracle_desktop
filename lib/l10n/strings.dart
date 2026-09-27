import 'package:flutter/widgets.dart';

/// Every user-visible string lives here. [StringsRu] is the reference
/// implementation; [StringsEn] mirrors it.
abstract class Strings {
  const Strings();

  static const Strings ru = StringsRu();
  static const Strings en = StringsEn();

  static Strings of(String code) => code == 'en' ? en : ru;

  String get localeCode;
  Locale get locale => Locale(localeCode);
  String get languageName;

  // --- chrome -------------------------------------------------------------
  String get appName => 'Book Oracle';
  String get minimize;
  String get maximize;
  String get restore;
  String get close;
  String get offlineChip;

  // --- splash -------------------------------------------------------------
  String get splashLoading;
  String get splashCached;
  String get splashFirstRun;

  // --- onboarding ---------------------------------------------------------
  String get onbLead;
  String get onbEyebrow;
  String get onbTitle;
  String get onbIntro;
  String get onbColumnsTitle;
  String get onbColTitle;
  String get onbColAuthor;
  String get onbColRead;
  String get onbOr;
  String get onbSampleHeaderTitle;
  String get onbSampleHeaderAuthor;
  String get onbSampleHeaderRead;
  String get onbSampleRow1Title;
  String get onbSampleRow1Author;
  String get onbSampleRow2Title;
  String get onbSampleRow2Author;
  String get onbSampleRow2Read;
  String get onbColumnsNote;
  String get onbUrlLabel;
  String get onbUrlPlaceholder;
  String get onbConnect;
  String get onbAccessHelp;
  String get onbAccessHelpLink;
  String get onbChecking;
  String get onbSheetLabel;
  String get onbTrySample;
  String get onbStart;
  String get onbRetry;

  // --- errors -------------------------------------------------------------
  String get errFormatTitle;
  String get errFormatBody;
  String get errAccessTitle;
  String get errAccessBody;
  String get errOfflineTitle;
  String get errOfflineBody;
  String get errUnknownTitle;
  String get errUnknownBody;

  /// Localised name of a canonical column id (`title` / `author` / `read`).
  String columnLabel(String id);
  String errColumnsTitle(List<String> missing);
  String errColumnsBody(List<String> found);

  // --- deal ---------------------------------------------------------------
  String get dealHint;
  String get keySpace;
  String get keyR;
  String get keyF11;
  String get keySpaceHint;
  String get keyRHint;
  String get keyF11Hint;
  String get panelEyebrowList;
  String get defaultListName;
  String get sourceSheet;
  String get refresh;
  String get refreshing;
  String get panelLeft;
  String get panelOutOf;
  String get panelEyebrowChoice;
  String get panelEliminated;

  /// The band across a turned-over card.
  String get cardOutBand;
  String get panelLogEmpty;
  String get pickRandom;
  String get reshuffle;
  String get settings;
  String get backToTable;
  String get newSpread;
  String get revealEyebrow;
  String get revealTitle;
  String get tooFewTitle;
  String get openSheet;
  String cardClosed(int index);
  String cardEliminated(String title);
  String cardWinner(String title);
  String sheetTotalLine(int total, int read);
  String spreadCapped(int shown, int total);

  // --- network ------------------------------------------------------------
  String get netOfflineTitle;
  String netOfflineBody(String savedAt);
  String get netRecheck;
  String get netChecking;
  String get netRestoredTitle;

  /// Banner title for a plain refresh that changed something.
  String get listUpdatedTitle;
  String get netRestoredNoChange;

  /// [redealt] — whether the table already picked the new list up.
  String listChanged(int added, int removed, {required bool redealt});
  String get netHide;

  // --- settings -----------------------------------------------------------
  String get settingsTitle;
  String get secDeck;
  String get secDeckSub;
  String get secBackground;
  String get secList;
  String get secBehaviour;
  String get secLanguage;
  String get bgDim;
  String get bgPickFile;
  String get bgFileHint;
  String get bgNoFile;
  String get bgSeasonal;
  String get bgSeasonalSub;
  String get setUrlLabel;
  String get setChangeSheet;
  String get swRefreshOnStart;
  String get swUseCacheOffline;
  String get swAnimations;
  String get swSounds;
  String get swFullscreenReveal;
  String get swRememberWindow;
  String get preview;
  String get previewDeck;
  String get previewBackground;
  String get previewFonts;
  String get sampleFace1;
  String get sampleFace2;
  String sheetSummary({
    required String? sheetName,
    required int total,
    required int deck,
    required int read,
    required List<String> columns,
    required String updated,
  });
  String get bgSubGlow;
  String get bgSubAutumn;
  String get bgSubWinter;
  String get bgSubSpring;
  String get bgSubSummer;
  String get bgSubPlain;
  String get bgSubCustom;

  // --- counts / dates -----------------------------------------------------
  String books(int n);
  String inDeck(int n);
  String readCount(int n);
  String andMore(int n);
  String get today;
  String get yesterday;
  String relativeDateTime(DateTime when, {DateTime? now});
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Picks the right Russian form: 1 книга / 2 книги / 5 книг.
String _plural(int n, String one, String few, String many) {
  final mod100 = n.abs() % 100;
  final mod10 = n.abs() % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

class StringsRu extends Strings {
  const StringsRu();

  @override
  String get localeCode => 'ru';
  @override
  String get languageName => 'Русский';

  @override
  String get minimize => 'Свернуть';
  @override
  String get maximize => 'Развернуть';
  @override
  String get restore => 'Восстановить';
  @override
  String get close => 'Закрыть';
  @override
  String get offlineChip => 'Офлайн';

  @override
  String get splashLoading => 'Загружаем список книг…';
  @override
  String get splashCached => 'Нет сети — открываем сохранённый список';
  @override
  String get splashFirstRun => 'Первый запуск — подключим таблицу';

  @override
  String get onbLead =>
      'Колода из вашего списка. Открывайте карты по одной — они выбывают, пока не останется одна.';
  @override
  String get onbEyebrow => 'Первый запуск';
  @override
  String get onbTitle => 'Подключите список';
  @override
  String get onbIntro =>
      'Книги берутся из Google Таблицы: одна строка — одна карта. Сколько строк, столько и карт — стол подстроится.';
  @override
  String get onbColumnsTitle => 'В первой строке обязательно три столбца:';
  @override
  String get onbColTitle => 'название';
  @override
  String get onbColAuthor => 'автор';
  @override
  String get onbColRead => 'прочитано';
  @override
  String get onbOr => 'или';
  @override
  String get onbSampleHeaderTitle => 'название';
  @override
  String get onbSampleHeaderAuthor => 'автор';
  @override
  String get onbSampleHeaderRead => 'прочитано';
  @override
  String get onbSampleRow1Title => 'Мастер и Маргарита';
  @override
  String get onbSampleRow1Author => 'Михаил Булгаков';
  @override
  String get onbSampleRow2Title => 'Цирцея';
  @override
  String get onbSampleRow2Author => 'Мадлен Миллер';
  @override
  String get onbSampleRow2Read => 'да';
  @override
  String get onbColumnsNote =>
      'Порядок столбцов любой, лишние игнорируются. В колоду попадают книги с пустой ячейкой «прочитано» — любая пометка (да, ✓, дата, что угодно) убирает книгу из расклада.';
  @override
  String get onbUrlLabel => 'Ссылка на таблицу';
  @override
  String get onbUrlPlaceholder => 'https://docs.google.com/spreadsheets/d/…';
  @override
  String get onbConnect => 'Подключить';
  @override
  String get onbAccessHelp =>
      'В таблице: «Настройки доступа» → «Все, у кого есть ссылка» → «Читатель».';
  @override
  String get onbAccessHelpLink => 'Как открыть доступ';
  @override
  String get onbChecking => 'Проверяем таблицу и читаем строки…';
  @override
  String get onbSheetLabel => 'Лист';
  @override
  String get onbTrySample => 'Попробовать на примере';
  @override
  String get onbStart => 'Начать расклад';
  @override
  String get onbRetry => 'Повторить';

  @override
  String get errFormatTitle => 'Это не ссылка на Google Таблицу';
  @override
  String get errFormatBody =>
      'Скопируйте адрес из браузера — он начинается с docs.google.com/spreadsheets/.';
  @override
  String get errAccessTitle => 'Нет доступа к таблице';
  @override
  String get errAccessBody =>
      'Откройте доступ «Все, у кого есть ссылка» с правом чтения и нажмите «Подключить» ещё раз.';
  @override
  String get errOfflineTitle => 'Нет интернета';
  @override
  String get errOfflineBody =>
      'Подключитесь к сети, чтобы загрузить таблицу.';
  @override
  String get errUnknownTitle => 'Не удалось прочитать таблицу';
  @override
  String get errUnknownBody =>
      'Проверьте ссылку и попробуйте ещё раз.';

  static const Map<String, String> _columns = <String, String>{
    'title': 'название',
    'author': 'автор',
    'read': 'прочитано',
  };

  @override
  String columnLabel(String id) => _columns[id] ?? id;

  @override
  String errColumnsTitle(List<String> missing) {
    final parts = missing.map((m) => '«${columnLabel(m)}» ($m)').join(', ');
    return missing.length == 1
        ? 'Не найден столбец $parts'
        : 'Не найдены столбцы $parts';
  }

  @override
  String errColumnsBody(List<String> found) {
    final head = found.isEmpty
        ? 'Ни одного из нужных столбцов нет.'
        : 'Нашли: ${found.map(columnLabel).join(', ')}.';
    return '$head Добавьте недостающие столбцы в первую строку — можно пустые — и нажмите «Подключить» ещё раз.';
  }

  @override
  String get dealHint =>
      'Кликните по карте — она выбывает. Последняя оставшаяся — выбор.';
  @override
  String get keySpace => 'Пробел';
  @override
  String get keyR => 'R';
  @override
  String get keyF11 => 'F11';
  @override
  String get keySpaceHint => 'случайная';
  @override
  String get keyRHint => 'перетасовать';
  @override
  String get keyF11Hint => 'весь экран';
  @override
  String get panelEyebrowList => 'Список';
  @override
  String get defaultListName => 'Что почитать';
  @override
  String get sourceSheet => 'Google Таблица';
  @override
  String get refresh => 'Обновить';
  @override
  String get refreshing => 'Обновляем…';
  @override
  String get panelLeft => 'Осталось';
  @override
  String get panelOutOf => 'из';
  @override
  String get panelEyebrowChoice => 'Выбор';
  @override
  String get panelEliminated => 'Выбыли';
  @override
  String get cardOutBand => 'Выбыла';
  @override
  String get panelLogEmpty =>
      'Пока никто. Откройте любую карту или нажмите «Случайная».';
  @override
  String get pickRandom => 'Случайная';
  @override
  String get reshuffle => 'Перетасовать';
  @override
  String get settings => 'Настройки';
  @override
  String get backToTable => 'К раскладу';
  @override
  String get newSpread => 'Новый расклад';
  @override
  String get revealEyebrow => 'Оракул ответил';
  @override
  String get revealTitle => 'Выбор сделан';
  @override
  String get tooFewTitle => 'В таблице меньше двух непрочитанных книг';
  @override
  String get openSheet => 'Открыть таблицу';

  @override
  String cardClosed(int index) => 'Карта $index, закрыта';
  @override
  String cardEliminated(String title) => '$title — выбыла';
  @override
  String cardWinner(String title) => '$title — выбор';

  @override
  String sheetTotalLine(int total, int read) =>
      'В таблице $total · прочитанные ($read) в колоду не попали';

  @override
  String spreadCapped(int shown, int total) => 'В раскладе $shown из $total';

  @override
  String get netOfflineTitle => 'Нет интернета';
  @override
  String netOfflineBody(String savedAt) =>
      'Показываем сохранённый список от $savedAt. Расклад работает как обычно.';
  @override
  String get netRecheck => 'Проверить снова';
  @override
  String get netChecking => 'Проверяем…';
  @override
  String get netRestoredTitle => 'Связь восстановлена';
  @override
  String get listUpdatedTitle => 'Список обновлён';
  @override
  String get netRestoredNoChange =>
      'Список обновлён из таблицы. Изменений нет — текущий расклад сохранён.';
  @override
  String listChanged(int added, int removed, {required bool redealt}) {
    final parts = <String>[];
    if (added > 0) parts.add('+$added');
    if (removed > 0) parts.add('−$removed');
    final what = 'Список изменился: ${parts.join(', ')}.';
    return redealt
        ? '$what Карты на столе обновлены.'
        : '$what Новый список будет в следующем раскладе.';
  }

  @override
  String get netHide => 'Скрыть';

  @override
  String get settingsTitle => 'Настройки';
  @override
  String get secDeck => 'Колода';
  @override
  String get secDeckSub => 'Рубашка карт, цвета и шрифты всего приложения.';
  @override
  String get secBackground => 'Фон стола';
  @override
  String get secList => 'Список';
  @override
  String get secBehaviour => 'Расклад и окно';
  @override
  String get secLanguage => 'Язык';
  @override
  String get bgDim => 'Затемнение фона';
  @override
  String get bgPickFile => 'Выбрать файл…';
  @override
  String get bgFileHint => 'PNG или JPG, от 1920 px по ширине';
  @override
  String get bgNoFile => 'Файл не выбран';
  @override
  String get bgSeasonal => 'Менять фон по сезону';
  @override
  String get bgSeasonalSub =>
      'Осень, зима, весна и лето включаются сами по текущей дате.';
  @override
  String get setUrlLabel => 'Ссылка на Google Таблицу';
  @override
  String get setChangeSheet => 'Сменить таблицу';
  @override
  String get swRefreshOnStart => 'Обновлять список при запуске';
  @override
  String get swUseCacheOffline => 'Без интернета — брать сохранённую копию';
  @override
  String get swAnimations => 'Анимации и частицы';
  @override
  String get swSounds => 'Звуки карт';
  @override
  String get swFullscreenReveal => 'Показывать выбор на весь экран';
  @override
  String get swRememberWindow => 'Запоминать размер и положение окна';
  @override
  String get preview => 'Предпросмотр';
  @override
  String get previewDeck => 'Колода';
  @override
  String get previewBackground => 'Фон';
  @override
  String get previewFonts => 'Шрифты';
  @override
  String get sampleFace1 => 'Цирцея';
  @override
  String get sampleFace2 => 'Вий';

  @override
  String sheetSummary({
    required String? sheetName,
    required int total,
    required int deck,
    required int read,
    required List<String> columns,
    required String updated,
  }) {
    final head = sheetName == null ? '' : 'Лист «$sheetName» · ';
    return '$head${books(total)}: $deck в колоде, $read прочитано · '
        'столбцы ${columns.join(', ')} · обновлено $updated';
  }

  @override
  String get bgSubGlow => 'Мягкий свет и частицы';
  @override
  String get bgSubAutumn => 'Свечи и физалис';
  @override
  String get bgSubWinter => 'Ель, шишки, свеча';
  @override
  String get bgSubSpring => 'Цветущая ветка';
  @override
  String get bgSubSummer => 'Арбуз и базилик';
  @override
  String get bgSubPlain => 'Цвет колоды';
  @override
  String get bgSubCustom => 'Файл с компьютера';

  @override
  String books(int n) => '$n ${_plural(n, 'книга', 'книги', 'книг')}';
  @override
  String inDeck(int n) => '$n в колоду';
  @override
  String readCount(int n) => '$n прочитано';
  @override
  String andMore(int n) => 'и ещё $n';
  @override
  String get today => 'сегодня';
  @override
  String get yesterday => 'вчера';

  static const List<String> _months = <String>[
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  @override
  String relativeDateTime(DateTime when, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final time = '${when.hour}:${_two(when.minute)}';
    final day = DateTime(when.year, when.month, when.day);
    final nDay = DateTime(n.year, n.month, n.day);
    final diff = nDay.difference(day).inDays;
    if (diff == 0) return '$today, $time';
    if (diff == 1) return '$yesterday, $time';
    final month = _months[when.month - 1];
    final year = when.year == n.year ? '' : ' ${when.year}';
    return '${when.day} $month$year, $time';
  }
}

class StringsEn extends Strings {
  const StringsEn();

  @override
  String get localeCode => 'en';
  @override
  String get languageName => 'English';

  @override
  String get minimize => 'Minimise';
  @override
  String get maximize => 'Maximise';
  @override
  String get restore => 'Restore';
  @override
  String get close => 'Close';
  @override
  String get offlineChip => 'Offline';

  @override
  String get splashLoading => 'Loading your book list…';
  @override
  String get splashCached => 'No connection — opening the saved list';
  @override
  String get splashFirstRun => 'First run — let’s connect a sheet';

  @override
  String get onbLead =>
      'A deck made from your list. Turn the cards one by one — each one turned is out, until a single card is left.';
  @override
  String get onbEyebrow => 'First run';
  @override
  String get onbTitle => 'Connect your list';
  @override
  String get onbIntro =>
      'Books come from a Google Sheet: one row, one card. However many rows there are, the table adapts.';
  @override
  String get onbColumnsTitle => 'The first row needs these three columns:';
  @override
  String get onbColTitle => 'title';
  @override
  String get onbColAuthor => 'author';
  @override
  String get onbColRead => 'read';
  @override
  String get onbOr => 'or';
  @override
  String get onbSampleHeaderTitle => 'title';
  @override
  String get onbSampleHeaderAuthor => 'author';
  @override
  String get onbSampleHeaderRead => 'read';
  @override
  String get onbSampleRow1Title => 'The Master and Margarita';
  @override
  String get onbSampleRow1Author => 'Mikhail Bulgakov';
  @override
  String get onbSampleRow2Title => 'Circe';
  @override
  String get onbSampleRow2Author => 'Madeline Miller';
  @override
  String get onbSampleRow2Read => 'yes';
  @override
  String get onbColumnsNote =>
      'Column order is up to you and extra columns are ignored. A book joins the deck while its read cell is empty — any mark at all (yes, ✓, a date, anything) keeps it out.';
  @override
  String get onbUrlLabel => 'Sheet link';
  @override
  String get onbUrlPlaceholder => 'https://docs.google.com/spreadsheets/d/…';
  @override
  String get onbConnect => 'Connect';
  @override
  String get onbAccessHelp =>
      'In the sheet: Share → Anyone with the link → Viewer.';
  @override
  String get onbAccessHelpLink => 'How to share a sheet';
  @override
  String get onbChecking => 'Checking the sheet and reading rows…';
  @override
  String get onbSheetLabel => 'Tab';
  @override
  String get onbTrySample => 'Try the sample list';
  @override
  String get onbStart => 'Start the spread';
  @override
  String get onbRetry => 'Try again';

  @override
  String get errFormatTitle => 'That is not a Google Sheets link';
  @override
  String get errFormatBody =>
      'Copy the address from your browser — it starts with docs.google.com/spreadsheets/.';
  @override
  String get errAccessTitle => 'No access to the sheet';
  @override
  String get errAccessBody =>
      'Share it with “Anyone with the link” as a viewer, then press Connect again.';
  @override
  String get errOfflineTitle => 'No internet';
  @override
  String get errOfflineBody => 'Connect to a network to load the sheet.';
  @override
  String get errUnknownTitle => 'Could not read the sheet';
  @override
  String get errUnknownBody => 'Check the link and try again.';

  @override
  String columnLabel(String id) => id;

  @override
  String errColumnsTitle(List<String> missing) {
    final parts = missing.map((m) => '“$m”').join(', ');
    return missing.length == 1
        ? 'Missing the $parts column'
        : 'Missing the $parts columns';
  }

  @override
  String errColumnsBody(List<String> found) {
    final head = found.isEmpty
        ? 'None of the required columns are there.'
        : 'Found: ${found.join(', ')}.';
    return '$head Add the missing columns to the first row — they may be empty — and press Connect again.';
  }

  @override
  String get dealHint =>
      'Click a card and it is out. The last one standing is the choice.';
  @override
  String get keySpace => 'Space';
  @override
  String get keyR => 'R';
  @override
  String get keyF11 => 'F11';
  @override
  String get keySpaceHint => 'random';
  @override
  String get keyRHint => 'reshuffle';
  @override
  String get keyF11Hint => 'full screen';
  @override
  String get panelEyebrowList => 'List';
  @override
  String get defaultListName => 'What to read';
  @override
  String get sourceSheet => 'Google Sheet';
  @override
  String get refresh => 'Refresh';
  @override
  String get refreshing => 'Refreshing…';
  @override
  String get panelLeft => 'Left';
  @override
  String get panelOutOf => 'of';
  @override
  String get panelEyebrowChoice => 'Choice';
  @override
  String get panelEliminated => 'Out';
  @override
  String get cardOutBand => 'Out';
  @override
  String get panelLogEmpty => 'Nobody yet. Turn any card or press Random.';
  @override
  String get pickRandom => 'Random';
  @override
  String get reshuffle => 'Reshuffle';
  @override
  String get settings => 'Settings';
  @override
  String get backToTable => 'Back to the table';
  @override
  String get newSpread => 'New spread';
  @override
  String get revealEyebrow => 'The oracle has spoken';
  @override
  String get revealTitle => 'The choice is made';
  @override
  String get tooFewTitle => 'The sheet has fewer than two unread books';
  @override
  String get openSheet => 'Open the sheet';

  @override
  String cardClosed(int index) => 'Card $index, face down';
  @override
  String cardEliminated(String title) => '$title — out';
  @override
  String cardWinner(String title) => '$title — the choice';

  @override
  String sheetTotalLine(int total, int read) =>
      '$total in the sheet · $read read, kept out of the deck';

  @override
  String spreadCapped(int shown, int total) => '$shown of $total in this spread';

  @override
  String get netOfflineTitle => 'No internet';
  @override
  String netOfflineBody(String savedAt) =>
      'Showing the list saved on $savedAt. The spread works as usual.';
  @override
  String get netRecheck => 'Check again';
  @override
  String get netChecking => 'Checking…';
  @override
  String get netRestoredTitle => 'Back online';
  @override
  String get listUpdatedTitle => 'List updated';
  @override
  String get netRestoredNoChange =>
      'The list was refreshed from the sheet. Nothing changed — your spread is intact.';
  @override
  String listChanged(int added, int removed, {required bool redealt}) {
    final parts = <String>[];
    if (added > 0) parts.add('+$added');
    if (removed > 0) parts.add('−$removed');
    final what = 'The list changed: ${parts.join(', ')}.';
    return redealt
        ? '$what The table has been re-dealt.'
        : '$what The new list starts with the next spread.';
  }

  @override
  String get netHide => 'Hide';

  @override
  String get settingsTitle => 'Settings';
  @override
  String get secDeck => 'Deck';
  @override
  String get secDeckSub => 'Card backs, colours and fonts across the app.';
  @override
  String get secBackground => 'Table background';
  @override
  String get secList => 'List';
  @override
  String get secBehaviour => 'Spread and window';
  @override
  String get secLanguage => 'Language';
  @override
  String get bgDim => 'Background dimming';
  @override
  String get bgPickFile => 'Choose a file…';
  @override
  String get bgFileHint => 'PNG or JPG, at least 1920 px wide';
  @override
  String get bgNoFile => 'No file chosen';
  @override
  String get bgSeasonal => 'Follow the season';
  @override
  String get bgSeasonalSub =>
      'Autumn, winter, spring and summer switch themselves by the date.';
  @override
  String get setUrlLabel => 'Google Sheets link';
  @override
  String get setChangeSheet => 'Change sheet';
  @override
  String get swRefreshOnStart => 'Refresh the list at start-up';
  @override
  String get swUseCacheOffline => 'Offline — use the saved copy';
  @override
  String get swAnimations => 'Animations and particles';
  @override
  String get swSounds => 'Card sounds';
  @override
  String get swFullscreenReveal => 'Show the choice full screen';
  @override
  String get swRememberWindow => 'Remember window size and position';
  @override
  String get preview => 'Preview';
  @override
  String get previewDeck => 'Deck';
  @override
  String get previewBackground => 'Background';
  @override
  String get previewFonts => 'Fonts';
  @override
  String get sampleFace1 => 'Circe';
  @override
  String get sampleFace2 => 'Viy';

  @override
  String sheetSummary({
    required String? sheetName,
    required int total,
    required int deck,
    required int read,
    required List<String> columns,
    required String updated,
  }) {
    final head = sheetName == null ? '' : 'Tab “$sheetName” · ';
    return '$head${books(total)}: $deck in the deck, $read read · '
        'columns ${columns.join(', ')} · updated $updated';
  }

  @override
  String get bgSubGlow => 'Soft light and motes';
  @override
  String get bgSubAutumn => 'Candles and physalis';
  @override
  String get bgSubWinter => 'Spruce, cones, a candle';
  @override
  String get bgSubSpring => 'A blossoming branch';
  @override
  String get bgSubSummer => 'Watermelon and basil';
  @override
  String get bgSubPlain => 'The deck colour';
  @override
  String get bgSubCustom => 'A file from your computer';

  @override
  String books(int n) => '$n ${n == 1 ? 'book' : 'books'}';
  @override
  String inDeck(int n) => '$n in the deck';
  @override
  String readCount(int n) => '$n read';
  @override
  String andMore(int n) => '$n more';
  @override
  String get today => 'today';
  @override
  String get yesterday => 'yesterday';

  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  String relativeDateTime(DateTime when, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final hour12 = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final time = '$hour12:${_two(when.minute)} ${when.hour < 12 ? 'am' : 'pm'}';
    final day = DateTime(when.year, when.month, when.day);
    final nDay = DateTime(n.year, n.month, n.day);
    final diff = nDay.difference(day).inDays;
    if (diff == 0) return '$today, $time';
    if (diff == 1) return '$yesterday, $time';
    final month = _months[when.month - 1];
    final year = when.year == n.year ? '' : ' ${when.year}';
    return '$month ${when.day}$year, $time';
  }
}

/// Localised deck / background display names, so the UI is not stuck with the
/// Russian labels baked into design_tokens.json.
String deckName(Strings s, String id, String fallback) {
  if (s.localeCode == 'ru') return fallback;
  return const <String, String>{
        'graphite': 'Graphite',
        'coven': 'Coven',
        'library': 'Library',
        'paper': 'Paper',
        'garden': 'Garden',
      }[id] ??
      fallback;
}

String backgroundName(Strings s, String id, String fallback) {
  if (s.localeCode == 'ru') return fallback;
  return const <String, String>{
        'glow': 'Glow',
        'autumn': 'Autumn',
        'winter': 'Winter',
        'spring': 'Spring',
        'summer': 'Summer',
        'plain': 'Plain',
        'custom': 'Your own image',
      }[id] ??
      fallback;
}

String backgroundSubtitle(Strings s, String id) => switch (id) {
      'glow' => s.bgSubGlow,
      'autumn' => s.bgSubAutumn,
      'winter' => s.bgSubWinter,
      'spring' => s.bgSubSpring,
      'summer' => s.bgSubSummer,
      'plain' => s.bgSubPlain,
      _ => s.bgSubCustom,
    };

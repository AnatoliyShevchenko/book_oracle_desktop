# Разработка

Техническая часть. Про само приложение — в [README](../README.md), полное ТЗ —
в [SPEC.md](SPEC.md), источник правды для темы — в
[`assets/design_tokens.json`](../assets/design_tokens.json).

## Сборка

Проект закреплён за Flutter 3.47.5 через [FVM](https://fvm.app) (`.fvmrc`).

```bash
fvm install                       # один раз
fvm flutter pub get
fvm flutter run -d windows        # отладка
fvm flutter build windows --release
```

Готовый бинарник: `build/windows/x64/runner/Release/book_oracle.exe`.
Переносить нужно всю папку `Release` целиком — рядом с exe лежат движок,
плагины и папка `data` с ассетами.

Нужны Visual Studio с рабочей нагрузкой «Разработка классических приложений на
C++» и Windows 10 SDK.

## Инсталлятор

```powershell
powershell -ExecutionPolicy Bypass -File tool\build_installer.ps1
```

Скрипт соберёт релиз, найдёт runtime Visual C++ и запустит компилятор
[Inno Setup](https://jrsoftware.org/isinfo.php)
(`winget install JRSoftware.InnoSetup`). Результат —
`dist/BookOracleSetup-<версия>.exe`, около 15 МБ. Флаг `-SkipBuild` упакует
уже собранный релиз.

Что делает установщик:

- ставит **в профиль пользователя** (`%LOCALAPPDATA%\Programs\Book Oracle`),
  поэтому UAC не спрашивает; машинную установку можно выбрать на первом шаге;
- кладёт рядом с exe `msvcp140.dll` и `vcruntime140*.dll`. Без них приложение
  не стартует там, где не установлен Visual C++ Redistributable, а Flutter их
  рядом с exe не кладёт. Microsoft такое размещение разрешает; плата за него в
  том, что эти копии не обновляются через Windows Update;
- создаёт ярлык в меню «Пуск» и, по желанию, на рабочем столе;
- регистрируется в «Приложениях и возможностях» со своим деинсталлятором;
- при удалении **спрашивает**, стирать ли настройки и сохранённую копию списка
  из `%APPDATA%\com.bookoracle`; по умолчанию не трогает.

Версия берётся из `pubspec.yaml`. `AppId` в `installer/book_oracle.iss` менять
нельзя — по нему Windows опознаёт обновление поверх прошлой версии.

## Проверки

```bash
fvm flutter analyze          # должно быть чисто
fvm flutter test
```

Тесты покрывают:

| Файл | О чём |
|---|---|
| `sheet_link_test` | разбор ссылки: `/edit`, `#gid=`, `?gid=`, `/htmlview`, мусор, `pubhtml` |
| `sheet_parser_test` | заголовки ru/en, любой порядок, лишние столбцы, пометки «прочитано», пустые строки |
| `layout_test` | ступени адаптива и сетка: контрольные размеры из ТЗ, полный прямоугольник, все n от 2 до 60 на пяти разрешениях |
| `auto_color_test` | разбор токенов, FNV-1a, детерминированность цвета карты |
| `network_state_test` | офлайн → «Проверить снова» → «Связь восстановлена», дельта списка, поведение стола при обновлении |
| `settings_repo_test` | чтение настроек, в том числе битых и с неверными типами |
| `svg_path_test` | парсер SVG-путей и все иконки приложения |
| `sound_test` | синтез звуков, WAV-заголовок, гейт по флагу |
| `widget_test` | расклад из 5 карт → 4 клика → показ выбора |

## Структура

```
lib/
  main.dart                 window_manager, сплэш-окно, runApp
  app.dart                  тема из колоды, роутинг, запуск, память окна
  core/tokens.dart          design_tokens.json → DeckTheme, шрифты
  core/layout.dart          ступени адаптива и алгоритм сетки (чистые функции)
  core/hash.dart            FNV-1a для стабильного цвета карты
  core/card_colors.dart     title → пара «фон / текст»
  core/sound.dart           звуки карт (выключены, см. ниже)
  l10n/strings.dart         все строки, ru + en
  data/                     ссылка, загрузка, разбор, кэш, настройки
  state/                    Riverpod: settings, library, deal, onboarding
  ui/window/                своя рамка окна
  ui/splash|onboarding|deal|settings
  ui/widgets/               кнопки, поля, плашки, иконки, парсер SVG-путей
installer/book_oracle.iss   скрипт Inno Setup
tool/generate_app_icon.dart генератор .ico
tool/generate_sounds.dart   синтезатор звуков
tool/build_installer.ps1    сборка инсталлятора
```

## Данные

Приложение читает CSV-экспорт таблицы:
`https://docs.google.com/spreadsheets/d/<ID>/export?format=csv&gid=<GID>`,
таймаут 8 секунд. Редирект на `accounts.google.com`, ответ не 200 или HTML
вместо CSV — это «нет доступа». Название документа и список листов
подхватываются best-effort из `/htmlview`.

Последняя успешная загрузка сохраняется в
`%APPDATA%\com.bookoracle\book_oracle\cache.json`, настройки — там же в
`shared_preferences.json`. Удалите оба файла, чтобы начать с чистого листа.

## Шрифты

Unbounded, Onest, Cormorant Garamond, Manrope, Old Standard TT, Prata и
Yeseva One вшиты в `assets/fonts/` (все под OFL, лицензии лежат рядом).
Первые четыре — вариативные: вес задаётся осью `wght` через `FontVariation`,
см. `fontStyle()` в `lib/core/tokens.dart`. Поэтому в `pubspec.yaml` каждый из
них объявлен одним файлом без `weight:` — иначе Flutter рисовал бы
синтетический жирный вместо настоящего начертания.

## Иконка приложения

`windows/runner/resources/app_icon.ico` генерируется из того же векторного
логотипа, что рисуется в интерфейсе:

```bash
fvm flutter test tool/generate_app_icon.dart
```

Семь размеров от 16 до 256 px, толщина обводки подобрана под каждый.

## Звуки карт

Выключены на уровне сборки: флаг `kCardSoundsEnabled` в `lib/core/sound.dart`.
Реализация на месте и привязана к событиям (переворот, раздача, перетасовка,
показ выбора); файлы `assets/sounds/*.wav` синтезируются скриптом
`tool/generate_sounds.dart` — шум через биквад-фильтры плюс синусовые
обертоны, сид фиксирован, так что файлы воспроизводимы побайтно.

Поставьте флаг в `true`, чтобы вернуть и воспроизведение, и строку
«Звуки карт» в настройках. Синтезированные звуки звучат слишком «цифрово» —
если включать всерьёз, их стоит заменить нормальными сэмплами под OFL/CC0.

## Заметки по реализации

Несколько мест, где очевидное решение оказалось неверным:

- **Экраны обёрнуты в `Material`.** Без него каждый `Text` наследует
  фолбэк-стиль Flutter, в котором стоит двойное подчёркивание.
- **Память окна висит на `didChangeMetrics`, а не только на `WindowListener`.**
  `window_manager` шлёт `resized`/`moved` лишь по `WM_EXITSIZEMOVE`, то есть
  когда пользователь отпустил рамку. Снап по Win+стрелка так не ловится.
- **`SettingsRepo.read()` читает значения по типу и глушит любые ошибки.**
  Одно поле неверного типа в `shared_preferences.json` иначе роняет старт, и
  пользователь видит пустое окно без объяснений.
- **Каждый вызов `AudioPlayer` ожидается.** Конструктор создаёт нативный плеер
  в фоне; брошенный Future превращает отсутствие плагина в необработанное
  исключение зоны мимо `try/catch`.
- **Иконки — это разобранные SVG-пути из макетов**, а не подбор похожих
  материаловских. Мини-парсер лежит в `ui/widgets/svg_path.dart`.

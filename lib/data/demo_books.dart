import 'models.dart';

/// The built-in list behind "Попробовать на примере" / "Try the sample list".
LibraryData demoLibrary(String language) {
  final rows = language == 'en' ? _en : _ru;
  return LibraryData(
    sheetUrl: '',
    sheetId: '',
    gid: '0',
    documentName: language == 'en' ? 'What to read' : 'Что почитать',
    columns: const <String>['title', 'author', 'read'],
    loadedAt: DateTime.now(),
    books: rows
        .map((r) => Book(title: r.$1, author: r.$2, read: r.$3))
        .toList(growable: false),
  );
}

const List<(String, String, bool)> _ru = <(String, String, bool)>[
  ('Мастер и Маргарита', 'Михаил Булгаков', false),
  ('Цирцея', 'Мадлен Миллер', true),
  ('Джонатан Стрендж и мистер Норрелл', 'Сюзанна Кларк', false),
  ('Практическая магия', 'Элис Хоффман', false),
  ('Сто лет одиночества', 'Габриэль Гарсиа Маркес', false),
  ('Ребекка', 'Дафна дю Морье', false),
  ('Франкенштейн', 'Мэри Шелли', true),
  ('Дракула', 'Брэм Стокер', false),
  ('Тайная история', 'Донна Тартт', false),
  ('Ночной цирк', 'Эрин Моргенштерн', false),
  ('Имя розы', 'Умберто Эко', false),
  ('Вий', 'Николай Гоголь', false),
  ('Пикник на обочине', 'Аркадий и Борис Стругацкие', true),
  ('Мы живём в замке', 'Ширли Джексон', false),
  ('Коралина', 'Нил Гейман', false),
  ('Портрет Дориана Грея', 'Оскар Уайльд', false),
  ('Грозовой перевал', 'Эмили Бронте', false),
  ('Ведьмы', 'Роальд Даль', true),
  ('Призрак дома на холме', 'Ширли Джексон', false),
  ('Американские боги', 'Нил Гейман', false),
  ('Дом, в котором…', 'Мариам Петросян', false),
  ('Ночь в одиноком октябре', 'Роджер Желязны', false),
  ('Ведьмы Иствика', 'Джон Апдайк', true),
  ('Мексиканская готика', 'Сильвия Морено-Гарсия', false),
  ('Солярис', 'Станислав Лем', false),
  ('Трудно быть богом', 'Аркадий и Борис Стругацкие', false),
  ('Облачный атлас', 'Дэвид Митчелл', true),
  ('Тень ветра', 'Карлос Руис Сафон', false),
  ('Книжный вор', 'Маркус Зусак', false),
  ('Цветы для Элджернона', 'Дэниел Киз', false),
];

const List<(String, String, bool)> _en = <(String, String, bool)>[
  ('The Master and Margarita', 'Mikhail Bulgakov', false),
  ('Circe', 'Madeline Miller', true),
  ('Jonathan Strange & Mr Norrell', 'Susanna Clarke', false),
  ('Practical Magic', 'Alice Hoffman', false),
  ('One Hundred Years of Solitude', 'Gabriel García Márquez', false),
  ('Rebecca', 'Daphne du Maurier', false),
  ('Frankenstein', 'Mary Shelley', true),
  ('Dracula', 'Bram Stoker', false),
  ('The Secret History', 'Donna Tartt', false),
  ('The Night Circus', 'Erin Morgenstern', false),
  ('The Name of the Rose', 'Umberto Eco', false),
  ('Viy', 'Nikolai Gogol', false),
  ('Roadside Picnic', 'Arkady and Boris Strugatsky', true),
  ('We Have Always Lived in the Castle', 'Shirley Jackson', false),
  ('Coraline', 'Neil Gaiman', false),
  ('The Picture of Dorian Gray', 'Oscar Wilde', false),
  ('Wuthering Heights', 'Emily Brontë', false),
  ('The Witches', 'Roald Dahl', true),
  ('The Haunting of Hill House', 'Shirley Jackson', false),
  ('American Gods', 'Neil Gaiman', false),
  ('The Gray House', 'Mariam Petrosyan', false),
  ('A Night in the Lonesome October', 'Roger Zelazny', false),
  ('The Witches of Eastwick', 'John Updike', true),
  ('Mexican Gothic', 'Silvia Moreno-Garcia', false),
  ('Solaris', 'Stanisław Lem', false),
  ('Hard to Be a God', 'Arkady and Boris Strugatsky', false),
  ('Cloud Atlas', 'David Mitchell', true),
  ('The Shadow of the Wind', 'Carlos Ruiz Zafón', false),
  ('The Book Thief', 'Markus Zusak', false),
  ('Flowers for Algernon', 'Daniel Keyes', false),
];

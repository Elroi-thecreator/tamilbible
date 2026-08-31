import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TamilBibleApp());
}

enum AppThemeMode { light, sepia, dark }

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  AppThemeMode _currentTheme = AppThemeMode.light;
  AppThemeMode get currentTheme => _currentTheme;

  void setTheme(AppThemeMode mode) {
    _currentTheme = mode;
    notifyListeners();
  }
}

class TamilBibleApp extends StatelessWidget {
  const TamilBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        ThemeData theme;
        switch (ThemeController.instance.currentTheme) {
          case AppThemeMode.sepia:
            theme = ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF4ECD8),
              cardColor: const Color(0xFFEADBC8),
              colorSchemeSeed: const Color(0xFF8D6E63),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFFEADBC8),
                foregroundColor: Color(0xFF3E2723),
              ),
              textTheme: GoogleFonts.muktaMalarTextTheme(ThemeData.light().textTheme).apply(
                bodyColor: const Color(0xFF3E2723),
                displayColor: const Color(0xFF3E2723),
              ),
            );
            break;
          case AppThemeMode.dark:
            theme = ThemeData.dark(useMaterial3: true).copyWith(
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF90CAF9),
                brightness: Brightness.dark,
              ),
              textTheme: GoogleFonts.muktaMalarTextTheme(ThemeData.dark().textTheme),
            );
            break;
          case AppThemeMode.light:
          default:
            theme = ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFFAFAFA),
              colorSchemeSeed: const Color(0xFF4A148C),
              textTheme: GoogleFonts.muktaMalarTextTheme(ThemeData.light().textTheme),
            );
            break;
        }

        return MaterialApp(
          title: 'பரிசுத்த வேதாகமம்',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookModel> _allBooks = [];
  Map<int, int> _chapterCounts = {};
  bool _loading = true;
  int? _lastBookId;
  int? _lastChapter;
  String? _lastBookName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBookId = prefs.getInt('last_book_id');
      _lastChapter = prefs.getInt('last_chapter');
      _lastBookName = prefs.getString('last_book_name');
    });
  }

  Future<void> _loadData() async {
    final books = await DatabaseHelper.getBooks();
    final Map<int, int> counts = {};
    for (var b in books) {
      final chapters = await DatabaseHelper.getChapters(b.id);
      counts[b.id] = chapters.length;
    }

    setState(() {
      _allBooks = books;
      _chapterCounts = counts;
      _loading = false;
    });
  }

  void _openThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('வண்ண தீம் (Theme)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Light (வெள்ளை)'),
              onTap: () {
                ThemeController.instance.setTheme(AppThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF8D6E63)),
              title: const Text('Sepia (வாசிப்பு முறை)'),
              onTap: () {
                ThemeController.instance.setTheme(AppThemeMode.sepia);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round_outlined),
              title: const Text('Dark (இரவு முறை)'),
              onTap: () {
                ThemeController.instance.setTheme(AppThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final otBooks = _allBooks.where((b) => b.testament == 'OT').toList();
    final ntBooks = _allBooks.where((b) => b.testament == 'NT').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('பரிசுத்த வேதாகமம்', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: _openThemeSelector,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'பழைய ஏற்பாடு (OT)'),
            Tab(text: 'புதிய ஏற்பாடு (NT)'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_lastBookId != null && _lastChapter != null && _lastBookName != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('கடைசியாக வாசித்தது', style: TextStyle(fontSize: 12)),
                subtitle: Text('$_lastBookName $_lastChapter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  final targetBook = _allBooks.firstWhere((b) => b.id == _lastBookId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(
                        book: targetBook,
                        initialChapter: _lastChapter!,
                        totalChapters: _chapterCounts[targetBook.id] ?? 1,
                      ),
                    ),
                  ).then((_) => _loadLastRead());
                },
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookList(otBooks),
                _buildBookList(ntBooks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(List<BookModel> books) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        final totalChapters = _chapterCounts[book.id] ?? 1;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text('${book.id}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
          title: Text(book.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalChapters அதி.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  book: book,
                  initialChapter: 1,
                  totalChapters: totalChapters,
                ),
              ),
            ).then((_) => _loadLastRead());
          },
        );
      },
    );
  }
}

class ReaderScreen extends StatefulWidget {
  final BookModel book;
  final int initialChapter;
  final int totalChapters;

  const ReaderScreen({
    super.key,
    required this.book,
    required this.initialChapter,
    required this.totalChapters,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  late int _currentChapter;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _pageController = PageController(initialPage: widget.initialChapter - 1);
    _saveLastRead(_currentChapter);
  }

  Future<void> _saveLastRead(int ch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_book_id', widget.book.id);
    await prefs.setInt('last_chapter', ch);
    await prefs.setString('last_book_name', widget.book.name);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showChapterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.book.name} - அதிகாரங்கள்', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: widget.totalChapters,
                  itemBuilder: (context, index) {
                    final chNum = index + 1;
                    final isSelected = chNum == _currentChapter;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pageController.jumpToPage(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$chNum',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showChapterBottomSheet,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.book.name} $_currentChapter', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(14.0, 32.0)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(14.0, 32.0)),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.totalChapters,
        onPageChanged: (pageIndex) {
          final ch = pageIndex + 1;
          setState(() => _currentChapter = ch);
          _saveLastRead(ch);
        },
        itemBuilder: (context, pageIndex) {
          final chapter = pageIndex + 1;
          return ChapterView(
            book: widget.book,
            chapter: chapter,
            fontSize: _fontSize,
          );
        },
      ),
    );
  }
}

class ChapterView extends StatefulWidget {
  final BookModel book;
  final int chapter;
  final double fontSize;

  const ChapterView({
    super.key,
    required this.book,
    required this.chapter,
    required this.fontSize,
  });

  @override
  State<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<ChapterView> {
  Map<int, String> _highlights = {};

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  String _getKey(int verse) => 'hl_${widget.book.id}_${widget.chapter}_$verse';

  Future<void> _loadHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final verses = await DatabaseHelper.getVerses(widget.book.id, widget.chapter);
    final Map<int, String> map = {};
    for (var v in verses) {
      final val = prefs.getString(_getKey(v.number));
      if (val != null) map[v.number] = val;
    }
    if (mounted) setState(() => _highlights = map);
  }

  Future<void> _setHighlight(int verse, String? colorHex) async {
    final prefs = await SharedPreferences.getInstance();
    if (colorHex == null) {
      await prefs.remove(_getKey(verse));
      setState(() => _highlights.remove(verse));
    } else {
      await prefs.setString(_getKey(verse), colorHex);
      setState(() => _highlights[verse] = colorHex);
    }
  }

  void _showVerseActions(VerseModel verse) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final reference = '${widget.book.name} ${widget.chapter}:${verse.number}';
        final fullText = '$reference\n"${verse.text}"';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reference, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(verse.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'நகலெடு (Copy)',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('வசனம் நகலெடுக்கப்பட்டது')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'பகிர் (Share)',
                      onPressed: () {
                        Share.share(fullText);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('ஹைலைட் வண்ணம் (Highlight):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _colorCircle(verse.number, '0xFFFFF59D', Colors.yellow.shade200),
                    _colorCircle(verse.number, '0xFFA5D6A7', Colors.green.shade200),
                    _colorCircle(verse.number, '0xFFF48FB1', Colors.pink.shade200),
                    _colorCircle(verse.number, '0xFF90CAF9', Colors.blue.shade200),
                    IconButton(
                      icon: const Icon(Icons.format_color_reset, color: Colors.grey),
                      onPressed: () {
                        _setHighlight(verse.number, null);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorCircle(int verseNumber, String hex, Color color) {
    return GestureDetector(
      onTap: () {
        _setHighlight(verseNumber, hex);
        Navigator.pop(context);
      },
      child: CircleAvatar(backgroundColor: color, radius: 16),
    );
  }

  Color? _getHighlightColor(int verseNumber) {
    final hex = _highlights[verseNumber];
    if (hex == null) return null;
    return Color(int.parse(hex));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VerseModel>>(
      future: DatabaseHelper.getVerses(widget.book.id, widget.chapter),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final verses = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final v = verses[index];
            final hlColor = _getHighlightColor(v.number);

            return InkWell(
              onTap: () => _showVerseActions(v),
              onLongPress: () => _showVerseActions(v),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2.0),
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: hlColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      height: 1.65,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: [
                      TextSpan(
                        text: '${v.number} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: widget.fontSize * 0.85,
                        ),
                      ),
                      TextSpan(text: v.text),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  void _doSearch(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _searching = true);
    final res = await DatabaseHelper.searchTamil(text.trim());
    setState(() {
      _results = res;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'தேடுங்கள் (எ.கா: வெளிச்சம்)...',
            border: InputBorder.none,
          ),
          onSubmitted: _doSearch,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _doSearch(_ctrl.text)),
        ],
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  title: Text(
                    '${item['name_ta']} ${item['chapter']}:${item['verse']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item['text_ta']),
                  onTap: () async {
                    final books = await DatabaseHelper.getBooks();
                    final book = books.firstWhere((b) => b.id == item['book_id']);
                    final chapters = await DatabaseHelper.getChapters(book.id);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            book: book,
                            initialChapter: item['chapter'],
                            totalChapters: chapters.length,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
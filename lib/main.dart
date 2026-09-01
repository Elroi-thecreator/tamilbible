import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'db_helper.dart';
import 'reading_plans.dart';
import 'tts_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TamilBibleApp());
}

enum AppThemeMode { light, sepia, dark }
enum TamilFontOption { muktaMalar, catamaran, notoSerifTamil }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  AppThemeMode themeMode = AppThemeMode.light;
  TamilFontOption fontOption = TamilFontOption.muktaMalar;

  void setTheme(AppThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setFont(TamilFontOption option) {
    fontOption = option;
    notifyListeners();
  }

  TextTheme getTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    switch (fontOption) {
      case TamilFontOption.catamaran:
        return GoogleFonts.catamaranTextTheme(base);
      case TamilFontOption.notoSerifTamil:
        return GoogleFonts.notoSerifTamilTextTheme(base);
      case TamilFontOption.muktaMalar:
      default:
        return GoogleFonts.muktaMalarTextTheme(base);
    }
  }
}

class TamilBibleApp extends StatelessWidget {
  const TamilBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        ThemeData theme;
        switch (AppSettings.instance.themeMode) {
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
              textTheme: AppSettings.instance.getTextTheme(Brightness.light).apply(
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
              textTheme: AppSettings.instance.getTextTheme(Brightness.dark),
            );
            break;
          case AppThemeMode.light:
          default:
            theme = ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFFAFAFA),
              colorSchemeSeed: const Color(0xFF0288D1),
              textTheme: AppSettings.instance.getTextTheme(Brightness.light),
            );
            break;
        }

        return MaterialApp(
          title: 'திருவிவிலியம்',
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

  final List<Map<String, dynamic>> _dailyVerses = const [
    {"ref": "சங்கீதம் 23:1", "text": "கர்த்தர் என் மேய்ப்பராயிருக்கிறார்; நான் தாழ்ச்சியடையேன்."},
    {"ref": "யோவான் 3:16", "text": "தேவன், உலகத்திலுள்ள எவரும் அழியாமல் நித்தியஜீவனை அடையும்படிக்கு, தம்முடைய ஒரேபேறான குமாரனைத் தந்தருளி, இவ்வளவாய் உலகத்தில் அன்புகூர்ந்தார்."},
    {"ref": "பிலிப்பியர் 4:13", "text": "என்னைப் பெலப்படுத்துகிற கிறிஸ்துவினாலே எல்லாவற்றையுஞ்செய்ய எனக்குப் பெலனுண்டு."},
    {"ref": "நீதிமொழிகள் 3:5", "text": "உன் சுயபுத்தியின்மேல் சாயாமல், உன் முழு இருதயத்தோடும் கர்த்தரில் நம்பிக்கையாயிரு."},
    {"ref": "ஏசாயா 41:10", "text": "நீ பயப்படாதே, நான் உன்னுடனே இருக்கிறேன்; திகையாதே, நான் உன் தேவன்; நான் உன்னைப் பலப்படுத்தி உனக்குச் சகாயம்பண்ணுவேன்."},
    {"ref": "மத்தேயு 6:33", "text": "முதலாவது தேவனுடைய ராஜ்யத்தையும் அவருடைய நீதியையும் தேடுங்கள்; அப்பொழுது இவைகளெல்லாம் உங்களுக்குக்கூடக் கொடுக்கப்படும்."},
    {"ref": "எரேமியா 29:11", "text": "நீங்கள் எதிர்பார்க்கும் முடிவை உங்களுக்குக் கொடுக்கும்படிக்கு நான் உங்களைக்குறித்து நினைத்திருக்கிற நினைவுகளை அறிவேன் என்று கர்த்தர் சொல்லுகிறார்."}
  ];

  Map<String, dynamic> get _todayVerse {
    final dayIndex = DateTime.now().day % _dailyVerses.length;
    return _dailyVerses[dayIndex];
  }

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

  void _openAppearanceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('வண்ண தீம் (Theme)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _themeButton('வெள்ளை', AppThemeMode.light, Icons.wb_sunny_outlined),
                  _themeButton('Sepia', AppThemeMode.sepia, Icons.menu_book_outlined),
                  _themeButton('இருள்', AppThemeMode.dark, Icons.nightlight_round_outlined),
                ],
              ),
              const Divider(height: 24),
              const Text('எழுத்து வடிவம் (Tamil Font)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Mukta Malar (முத்து மலர்)'),
                trailing: AppSettings.instance.fontOption == TamilFontOption.muktaMalar ? const Icon(Icons.check) : null,
                onTap: () {
                  AppSettings.instance.setFont(TamilFontOption.muktaMalar);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Catamaran (கட்டமரன்)'),
                trailing: AppSettings.instance.fontOption == TamilFontOption.catamaran ? const Icon(Icons.check) : null,
                onTap: () {
                  AppSettings.instance.setFont(TamilFontOption.catamaran);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Noto Serif Tamil (செரிப்)'),
                trailing: AppSettings.instance.fontOption == TamilFontOption.notoSerifTamil ? const Icon(Icons.check) : null,
                onTap: () {
                  AppSettings.instance.setFont(TamilFontOption.notoSerifTamil);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeButton(String label, AppThemeMode mode, IconData icon) {
    final isSelected = AppSettings.instance.themeMode == mode;
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        AppSettings.instance.setTheme(mode);
        Navigator.pop(context);
      },
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
        title: Row(
          children: [
            // Clipped circular logo without borders
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('திருவிவிலியம்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'வாசிப்பு திட்டங்கள்',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlansListScreen(allBooks: _allBooks, chapterCounts: _chapterCounts)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'குறித்த வசனங்கள்',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HighlightsScreen(allBooks: _allBooks, chapterCounts: _chapterCounts)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: _openAppearanceDialog,
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surfaceVariant,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🌟 இன்றைய வசனம்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.share, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Share.share('${_todayVerse["ref"]}\n"${_todayVerse["text"]}"\n- பரிசுத்த வேதாகமம்');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('"${_todayVerse["text"]}"', style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_todayVerse["ref"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          if (_lastBookId != null && _lastChapter != null && _lastBookName != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 20),
                title: Text('கடைசியாக வாசித்தது: $_lastBookName $_lastChapter', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReaderScreen(book: book, initialChapter: 1, totalChapters: totalChapters),
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
  bool _audioBarVisible = false;

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
    TtsEngine.instance.stop();
    _pageController.dispose();
    super.dispose();
  }

  void _showChapterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
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
                        border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400),
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
      ),
    );
  }

  Future<void> _startReadingFullChapter() async {
    final verses = await DatabaseHelper.getVerses(widget.book.id, _currentChapter);
    final texts = verses.map((v) => v.text.trim()).toList();
    await TtsEngine.instance.startChapter(texts);
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
            icon: Icon(_audioBarVisible ? Icons.volume_up : Icons.volume_up_outlined),
            tooltip: 'குரல் வாசிப்பு (TTS Audio)',
            onPressed: () {
              setState(() => _audioBarVisible = !_audioBarVisible);
            },
          ),
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
      body: Column(
        children: [
          if (_audioBarVisible)
            AnimatedBuilder(
              animation: TtsEngine.instance,
              builder: (context, _) {
                final isPlaying = TtsEngine.instance.state == TtsState.playing;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    children: [
                      IconButton.filled(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          if (isPlaying) {
                            TtsEngine.instance.pause();
                          } else if (TtsEngine.instance.state == TtsState.paused) {
                            TtsEngine.instance.resume();
                          } else {
                            _startReadingFullChapter();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () => TtsEngine.instance.stop(),
                      ),
                      const Spacer(),
                      const Text('வேகம்: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      DropdownButton<double>(
                        value: TtsEngine.instance.speechRate,
                        isDense: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 0.35, child: Text('0.75x')),
                          DropdownMenuItem(value: 0.45, child: Text('1.0x')),
                          DropdownMenuItem(value: 0.55, child: Text('1.25x')),
                          DropdownMenuItem(value: 0.65, child: Text('1.5x')),
                        ],
                        onChanged: (val) {
                          if (val != null) TtsEngine.instance.setRate(val);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.totalChapters,
              onPageChanged: (pageIndex) {
                final ch = pageIndex + 1;
                setState(() => _currentChapter = ch);
                _saveLastRead(ch);
                TtsEngine.instance.stop();
              },
              itemBuilder: (context, pageIndex) {
                final chapter = pageIndex + 1;
                return ChapterView(book: widget.book, chapter: chapter, fontSize: _fontSize);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChapterView extends StatefulWidget {
  final BookModel book;
  final int chapter;
  final double fontSize;

  const ChapterView({super.key, required this.book, required this.chapter, required this.fontSize});

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'இந்த வசனத்தை வாசி',
                      onPressed: () {
                        TtsEngine.instance.startChapter([verse.text]);
                        Navigator.pop(ctx);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'நகலெடு',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('வசனம் நகலெடுக்கப்பட்டது')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'பகிர்',
                      onPressed: () {
                        Share.share(fullText);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('ஹைலைட் வண்ணம்:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                decoration: BoxDecoration(color: hlColor, borderRadius: BorderRadius.circular(6)),
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
          decoration: const InputDecoration(hintText: 'தேடுங்கள் (எ.கா: வெளிச்சம்)...', border: InputBorder.none),
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
                  title: Text('${item['name_ta']} ${item['chapter']}:${item['verse']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['text_ta']),
                  onTap: () async {
                    final books = await DatabaseHelper.getBooks();
                    final book = books.firstWhere((b) => b.id == item['book_id']);
                    final chapters = await DatabaseHelper.getChapters(book.id);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(book: book, initialChapter: item['chapter'], totalChapters: chapters.length),
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

class HighlightsScreen extends StatefulWidget {
  final List<BookModel> allBooks;
  final Map<int, int> chapterCounts;
  const HighlightsScreen({super.key, required this.allBooks, required this.chapterCounts});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  List<Map<String, dynamic>> _savedVerses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllHighlights();
  }

  Future<void> _loadAllHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('hl_'));
    final List<Map<String, dynamic>> list = [];

    for (var k in keys) {
      final parts = k.split('_');
      if (parts.length == 4) {
        final bookId = int.parse(parts[1]);
        final ch = int.parse(parts[2]);
        final verseNum = int.parse(parts[3]);
        final colorHex = prefs.getString(k);
        final book = widget.allBooks.firstWhere((b) => b.id == bookId, orElse: () => widget.allBooks.first);
        final verseText = await DatabaseHelper.getSingleVerseText(bookId, ch, verseNum);

        if (verseText != null) {
          list.add({
            "book": book,
            "book_id": bookId,
            "chapter": ch,
            "verse": verseNum,
            "text": verseText,
            "colorHex": colorHex,
          });
        }
      }
    }

    setState(() {
      _savedVerses = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('முக்கிய வசனங்கள் (Highlights)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedVerses.isEmpty
              ? const Center(child: Text('ஹைலைட் செய்யப்பட்ட வசனங்கள் இல்லை.'))
              : ListView.separated(
                  itemCount: _savedVerses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _savedVerses[index];
                    final book = item["book"] as BookModel;
                    final Color? bg = item["colorHex"] != null ? Color(int.parse(item["colorHex"])) : null;

                    return ListTile(
                      tileColor: bg?.withOpacity(0.35),
                      title: Text('${book.name} ${item["chapter"]}:${item["verse"]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item["text"]),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(
                              book: book,
                              initialChapter: item["chapter"],
                              totalChapters: widget.chapterCounts[book.id] ?? 1,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class PlansListScreen extends StatelessWidget {
  final List<BookModel> allBooks;
  final Map<int, int> chapterCounts;
  const PlansListScreen({super.key, required this.allBooks, required this.chapterCounts});

  @override
  Widget build(BuildContext context) {
    final plans = ReadingPlansData.getAllPlans();

    return Scaffold(
      appBar: AppBar(title: const Text('வாசிப்பு திட்டங்கள் (Plans)')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text('${plan.totalDays} நாட்கள்', style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.description,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('திட்டத்தைத் தொடங்கு'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlanDetailScreen(
                              plan: plan,
                              allBooks: allBooks,
                              chapterCounts: chapterCounts,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlanDetailScreen extends StatefulWidget {
  final ReadingPlan plan;
  final List<BookModel> allBooks;
  final Map<int, int> chapterCounts;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    required this.allBooks,
    required this.chapterCounts,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  Set<int> _completedDays = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  String _getProgressKey(int day) => '${widget.plan.id}_day_$day';

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final set = <int>{};
    for (int d = 1; d <= widget.plan.totalDays; d++) {
      if (prefs.getBool(_getProgressKey(d)) ?? false) {
        set.add(d);
      }
    }
    setState(() {
      _completedDays = set;
      _loading = false;
    });
  }

  Future<void> _toggleDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    final isDone = _completedDays.contains(day);
    if (isDone) {
      await prefs.setBool(_getProgressKey(day), false);
      setState(() => _completedDays.remove(day));
    } else {
      await prefs.setBool(_getProgressKey(day), true);
      setState(() => _completedDays.add(day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.plan.totalDays == 0 ? 0.0 : (_completedDays.length / widget.plan.totalDays);

    return Scaffold(
      appBar: AppBar(title: Text(widget.plan.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('முன்னேற்றம்: ${_completedDays.length} / ${widget.plan.totalDays} நாட்கள்',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${(percent * 100).toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: percent, minHeight: 8),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.plan.days.length,
                    itemBuilder: (context, index) {
                      final day = widget.plan.days[index];
                      final isDone = _completedDays.contains(day.dayNumber);

                      return CheckboxListTile(
                        value: isDone,
                        onChanged: (_) => _toggleDay(day.dayNumber),
                        title: Text('நாள் ${day.dayNumber}: ${day.summary}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            )),
                        subtitle: Wrap(
                          spacing: 6,
                          children: day.portions.map((p) {
                            return ActionChip(
                              avatar: const Icon(Icons.menu_book, size: 14),
                              label: Text('${p.bookName} ${p.chapter}', style: const TextStyle(fontSize: 12)),
                              onPressed: () {
                                final targetBook = widget.allBooks.firstWhere(
                                  (b) => b.id == p.bookId,
                                  orElse: () => widget.allBooks.first,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(
                                      book: targetBook,
                                      initialChapter: p.chapter,
                                      totalChapters: widget.chapterCounts[targetBook.id] ?? 1,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
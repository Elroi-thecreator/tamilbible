import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'db_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TamilBibleApp());
}

class TamilBibleApp extends StatelessWidget {
  const TamilBibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'பரிசுத்த வேதாகமம்',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5E35B1),
        textTheme: GoogleFonts.muktaMalarTextTheme(Theme.of(context).textTheme),
      ),
      home: const HomeScreen(),
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final otBooks = _allBooks.where((b) => b.testament == 'OT').toList();
    final ntBooks = _allBooks.where((b) => b.testament == 'NT').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('பரிசுத்த வேதாகமம்', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookList(otBooks),
          _buildBookList(ntBooks),
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
            child: Text(
              '${book.id}', 
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
          title: Text(
            book.name, 
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          // Chapter count displayed at the end of the row
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
            // Directly navigate to Chapter 1
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReaderScreen(
                  book: book, 
                  initialChapter: 1,
                  totalChapters: totalChapters,
                ),
              ),
            );
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
              Text(
                '${widget.book.name} - அதிகாரத்தைத் தேர்ந்தெடுக்கவும்',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
        // Interactive title to jump chapters directly from header
        title: InkWell(
          onTap: _showChapterBottomSheet,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.book.name} $_currentChapter',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(14.0, 32.0)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(14.0, 32.0)),
          ),
        ],
      ),
      // Swipe left/right between chapters
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.totalChapters,
        onPageChanged: (pageIndex) {
          setState(() {
            _currentChapter = pageIndex + 1;
          });
        },
        itemBuilder: (context, pageIndex) {
          final chapter = pageIndex + 1;
          return ChapterView(
            bookId: widget.book.id,
            chapter: chapter,
            fontSize: _fontSize,
          );
        },
      ),
    );
  }
}

class ChapterView extends StatelessWidget {
  final int bookId;
  final int chapter;
  final double fontSize;

  const ChapterView({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VerseModel>>(
      future: DatabaseHelper.getVerses(bookId, chapter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('வசனங்கள் கிடைக்கவில்லை'));
        }

        final verses = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: verses.length,
          itemBuilder: (context, index) {
            final v = verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: fontSize,
                    height: 1.65,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  children: [
                    TextSpan(
                      text: '${v.number} ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: fontSize * 0.85,
                      ),
                    ),
                    TextSpan(text: v.text),
                  ],
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
                );
              },
            ),
    );
  }
}
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final books = await DatabaseHelper.getBooks();
    setState(() {
      _allBooks = books;
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
        return ListTile(
          leading: CircleAvatar(
            child: Text('${book.id}', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(book.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChapterScreen(book: book)),
            );
          },
        );
      },
    );
  }
}

class ChapterScreen extends StatelessWidget {
  final BookModel book;
  const ChapterScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${book.name} - அதிகாரங்கள்')),
      body: FutureBuilder<List<int>>(
        future: DatabaseHelper.getChapters(book.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final chapters = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final ch = chapters[index];
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReaderScreen(book: book, initialChapter: ch)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('$ch', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  final BookModel book;
  final int initialChapter;
  const ReaderScreen({super.key, required this.book, required this.initialChapter});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int _currentChapter;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book.name} $_currentChapter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(14.0, 30.0)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(14.0, 30.0)),
          ),
        ],
      ),
      body: FutureBuilder<List<VerseModel>>(
        future: DatabaseHelper.getVerses(widget.book.id, _currentChapter),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                      fontSize: _fontSize,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: [
                      TextSpan(
                        text: '${v.number} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: _fontSize * 0.85,
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
      ),
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
                  title: Text('${item['name_ta']} ${item['chapter']}:${item['verse']}', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['text_ta']),
                );
              },
            ),
    );
  }
}
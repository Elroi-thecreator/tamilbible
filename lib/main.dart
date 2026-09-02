import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'db_helper.dart';
import 'reading_plans.dart';
import 'topical_data.dart';
import 'tts_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.loadPreferences();
  runApp(const TamilBibleApp());
}

enum AppThemeMode { light, sepia, dark }
enum TamilFontOption { muktaMalar, catamaran, notoSerifTamil }
enum BibleLanguageMode { tamil, english, combined }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  AppThemeMode themeMode = AppThemeMode.light;
  TamilFontOption fontOption = TamilFontOption.muktaMalar;
  BibleLanguageMode languageMode = BibleLanguageMode.combined;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final langIndex = prefs.getInt('bible_language_mode') ?? BibleLanguageMode.combined.index;
    languageMode = BibleLanguageMode.values[langIndex];
  }

  void setTheme(AppThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setFont(TamilFontOption option) {
    fontOption = option;
    notifyListeners();
  }

  Future<void> setLanguageMode(BibleLanguageMode mode) async {
    languageMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bible_language_mode', mode.index);
  }

  void cycleLanguageMode() {
    final nextIndex = (languageMode.index + 1) % BibleLanguageMode.values.length;
    setLanguageMode(BibleLanguageMode.values[nextIndex]);
  }

  String get languageBadgeLabel {
    switch (languageMode) {
      case BibleLanguageMode.tamil:
        return 'தமிழ்';
      case BibleLanguageMode.english:
        return 'ENG';
      case BibleLanguageMode.combined:
        return 'இணை';
    }
  }

  String get languageFullTitle {
    switch (languageMode) {
      case BibleLanguageMode.tamil:
        return 'தமிழ் மட்டும்';
      case BibleLanguageMode.english:
        return 'English (KJV)';
      case BibleLanguageMode.combined:
        return 'தமிழ் + English';
    }
  }

  String getBookDisplayName(BookModel book) {
    switch (languageMode) {
      case BibleLanguageMode.english:
        return book.nameEn;
      case BibleLanguageMode.combined:
        return '${book.name} (${book.nameEn})';
      case BibleLanguageMode.tamil:
      default:
        return book.name;
    }
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
  bool _isVerseExpanded = true;
  int _streakCount = 1;
  int? _lastBookId;
  int? _lastChapter;

  final List<Map<String, dynamic>> _dailyVerses = const [
    {"ref": "சங்கீதம் 23:1", "text": "கர்த்தர் என் மேய்ப்பராயிருக்கிறார்; நான் தாழ்ச்சியடையேன்."},
    {"ref": "யோவான் 3:16", "text": "தேவன், உலகத்திலுள்ள எவரும் அழியாமல் நித்தியஜீவனை அடையும்படிக்கு, தம்முடைய ஒரேபேறான குமாரனைத் தந்தருளி, இவ்வளவாய் உலகத்தில் அன்புகூர்ந்தார்."},
    {"ref": "பிலிப்பியர் 4:13", "text": "என்னைப் பெலப்படுத்துகிற கிறிஸ்துவினாலே எல்லாவற்றையுஞ்செய்ய எனக்குப் பெலனுண்டு."},
    {"ref": "நீதிமொழிகள் 3:5-6", "text": "உன் சுயபுத்தியின்மேல் சாயாமல், உன் முழு இருதயத்தோடும் கர்த்தரில் நம்பிக்கையாயிரு; உன் வழிகளிலெல்லாம் அவரை நினைத்துக்கொள்; அப்பொழுது அவர் உன் பாதைகளைச் செவ்வைப்படுத்துவார்."},
    {"ref": "ஏசாயா 41:10", "text": "நீ பயப்படாதே, நான் உன்னுடனே இருக்கிறேன்; திகையாதே, நான் உன் தேவன்; நான் உன்னைப் பலப்படுத்தி உனக்குச் சகாயம்பண்ணுவேன்; என் நீதியின் வலதுகரத்தினால் உன்னைத் தாங்குவேன்."},
    {"ref": "மத்தேயு 6:33", "text": "முதலாவது தேவனுடைய ராஜ்யத்தையும் அவருடைய நீதியையும் தேடுங்கள்; அப்பொழுது இவைகளெல்லாம் உங்களுக்குக்கூடக் கொடுக்கப்படும்."},
    {"ref": "எரேமியா 29:11", "text": "நீங்கள் எதிர்பார்த்திருக்கும் முடிவை உங்களுக்குக் கொடுக்கும்படிக்கு நான் உங்களைக்குறித்து நினைத்திருக்கிற நினைவுகளை அறிவேன் என்று கர்த்தர் சொல்லுகிறார்; அவைகள் தீமைக்கல்ல, சமாதானத்துக்கேதுவான நினைவுகளே."},
    {"ref": "யோசுவா 1:9", "text": "நான் உனக்குக் கட்டளையிடவில்லையா? பலங்கொண்டு திடமனதாயிரு; திகையாதே, கலங்காதே, நீ போகும் இடமெல்லாம் உன் தேவனாகிய கர்த்தர் உன்னோடே இருக்கிறார்."},
    {"ref": "சங்கீதம் 46:1", "text": "தேவன் நமக்கு அடைக்கலமும் பெலனும், ஆபத்துக்காலத்தில் அநுகூலமான துணையுமானவர்."},
    {"ref": "ரோமர் 8:28", "text": "அன்றியும், அவருடைய தீர்மானத்தின்படி அழைக்கப்பட்டவர்களாய் தேவனிடத்தில் அன்புகூருகிறவர்களுக்குச் சகலமும் நன்மைக்கு ஏதுவாக நடக்கிறது என்று அறிந்திருக்கிறோம்."},
    {"ref": "சங்கீதம் 119:105", "text": "உம்முடைய வசனம் என் கால்களுக்குத் தீபமும், என் பாதைக்கு வெளிச்சமுமாயிருக்கிறது."},
    {"ref": "மத்தேயு 11:28", "text": "வருத்தப்பட்டுப் பாரஞ்சுமக்கிறவர்களே! நீங்கள் எல்லாரும் என்னிடத்தில் வாருங்கள்; நான் உங்களுக்கு இளைப்பாறுதல் தருவேன்."},
    {"ref": "சங்கீதம் 91:1-2", "text": "உன்னதமானவரின் மறைவிலிருக்கிறவன் சர்வவல்லவருடைய நிழலில் தங்குவான். நான் கர்த்தரை நோக்கி: நீர் என் அடைக்கலம், என் கோட்டை, என் தேவன், நான் நம்பியிருக்கிறவர் என்று சொல்லுவேன்."},
    {"ref": "நீதிமொழிகள் 18:10", "text": "கர்த்தரின் நாமம் பலத்த துருகம்; நீதிமான் அதற்குள் ஓடிச் சுகமாயிருப்பான்."},
    {"ref": "ஏசாயா 40:31", "text": "கர்த்தருக்குக் காத்திருக்கிறவர்களோ புதுப்பெலன் அடைந்து, கழுகுகளைப்போலச் செட்டைகளை அடித்து எழும்புவார்கள்; அவர்கள் ஓடினாலும் இளைப்படையார்கள், நடந்தாலும் சோர்ந்துபோகார்கள்."},
    {"ref": "2 தீமோத்தேயு 1:7", "text": "தேவன் நமக்கு பயமுள்ள ஆவியைக்கொடாமல், பலமும் அன்பும் தெளிந்த புத்தியுமுள்ள ஆவியையே கொடுத்திருக்கிறார்."},
    {"ref": "எபிரெயர் 11:1", "text": "விசுவாசமானது நம்பப்படுகிறவைகளின் உறுதியும், காணப்படாதவைகளின் நிச்சயமுமாயிருக்கிறது."},
    {"ref": "சங்கீதம் 121:1-2", "text": "எனக்கு ஒத்தாசை வரும் பர்வதங்களுக்கு நேராக என் கண்களை ஏறெடுக்கிறேன். வானத்தையும் பூமியையும் உண்டாக்கின கர்த்தரிடத்திலிருந்து எனக்கு ஒத்தாசை வரும்."},
    {"ref": "1 பேதுரு 5:7", "text": "அவர் உங்களை விசாரிக்கிறவரானபடியால், உங்கள் கவலைகளையெல்லாம் அவர்மேல் வைத்துவிடுங்கள்."},
    {"ref": "பிலிப்பியர் 4:6-7", "text": "நீங்கள் ஒன்றுக்குங் கவலைப்படாமல், எல்லாவற்றையுங்குறித்து உங்கள் விண்ணப்பங்களை ஸ்தோத்திரத்தோடே கூடிய ஜெபத்தினாலும் வேண்டுதலினாலும் தேவனுக்குத் தெரியப்படுத்துங்கள்."},
    {"ref": "சங்கீதம் 37:4", "text": "கர்த்தரிடத்தில் மனமகிழ்ச்சியாயிரு; அவர் உன் இருதயத்தின் வேண்டுதல்களை உனக்கு அருள்செய்வார்."},
    {"ref": "யோவான் 14:27", "text": "சமாதானத்தை உங்களுக்கு வைத்துப்போகிறேன், என்னுடைய சமாதானத்தையே உங்களுக்குக் கொடுக்கிறேன்; உலகம் கொடுக்கிறபிரகாரம் நான் உங்களுக்குக் கொடுக்கிறதில்லை. உங்கள் இருதயம் கலங்காமலும் பயப்படாமலும் இருப்பதாக."},
    {"ref": "கலாத்தியர் 5:22-23", "text": "ஆவியின் கனியோ, அன்பு, சந்தோஷம், சமாதானம், நீடியபொறுமை, தயவு, நற்குணம், விசுவாசம், சாந்தம், இச்சையடக்கம்; இப்படிப்பட்டவைகளுக்கு விரோதமான பிரமாணம் ஒன்றுமில்லை."},
    {"ref": "சங்கீதம் 34:8", "text": "கர்த்தர் நல்லவர் என்பதை ருசித்துப்பாருங்கள்; அவர்மேல் நம்பிக்கையாயிருக்கிற மனுஷன் பாக்கியவான்."},
    {"ref": "நீதிமொழிகள் 4:23", "text": "எல்லாக் காவலோடும் உன் இருதயத்தைக் காத்துக்கொள், அதினிடத்தினின்று ஜீவஊற்று புறப்படும்."},
    {"ref": "சங்கீதம் 103:1-2", "text": "என் ஆத்துமாவே, கர்த்தரை ஸ்தோத்திரி; என் முழு உள்ளமே, அவருடைய பரிசுத்த நாமத்தை ஸ்தோத்திரி. என் ஆத்துமாவே, கர்த்தரை ஸ்தோத்திரி; அவர் செய்த சகல உபகாரங்களையும் மறவாதே."},
    {"ref": "யோவான் 8:12", "text": "மறுபடியும் இயேசு ஜனங்களை நோக்கி: நான் உலகத்திற்கு வெளிச்சமாயிருக்கிறேன், என்னைப் பின்பற்றுகிறவன் இருளிலே நடவாமல் ஜீவவெளிச்சத்தை அடைந்திருப்பான் என்றார்."},
    {"ref": "எபேசியர் 2:8", "text": "கிருபையினாலே விசுவாசத்தைக்கொண்டு இரட்சிக்கப்பட்டீர்கள்; இது உங்களால் உண்டானதல்ல, இது தேவனுடைய ஈவு."},
    {"ref": "சங்கீதம் 16:11", "text": "ஜீவபாதையை எனக்குத் தெரியப்படுத்துவீர்; உம்முடைய சமுகத்தில் பரிபூரண ஆனந்தமும், உம்முடைய வலதுபாரிசத்தில் நித்திய பேரின்பமும் உண்டு."},
    {"ref": "ரோமர் 12:2", "text": "நீங்கள் இந்தப் பிரபஞ்சத்திற்கு ஒத்த வேஷந்தரியாமல், தேவனுடைய நன்மையும் பிரியமும் பரிபூரணமுமான சித்தம் இன்னதென்று பகுத்தறியத்தக்கதாக, உங்கள் மனம் புதிதாகிறதினாலே மறுரூபமாகுங்கள்."},
    {"ref": "வெளிப்படுத்தின விசேஷம் 21:4", "text": "அவர்களுடைய கண்ணீர் யாவையும் தேவன் துடைப்பார்; இனி மரணமுமில்லை, துக்கமுமில்லை, அலறுதலுமில்லை, வருத்தமுமில்லை; முந்தினவைகள் ஒழிந்துபோயின என்று விளம்பினது."}
  ];

  Map<String, dynamic> get _todayVerse {
    final dayOfMonth = DateTime.now().day;
    final index = (dayOfMonth - 1) % _dailyVerses.length;
    return _dailyVerses[index];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadState();
    _updateStreak();
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('last_active_date');
    int currentStreak = prefs.getInt('active_streak') ?? 1;

    if (lastDate != null && lastDate != today) {
      final last = DateTime.tryParse(lastDate);
      if (last != null) {
        final diff = DateTime.now().difference(last).inDays;
        if (diff == 1) {
          currentStreak += 1;
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }
    }
    await prefs.setString('last_active_date', today);
    await prefs.setInt('active_streak', currentStreak);
    if (mounted) setState(() => _streakCount = currentStreak);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVerseExpanded = prefs.getBool('verse_banner_expanded') ?? true;
      _lastBookId = prefs.getInt('last_book_id');
      _lastChapter = prefs.getInt('last_chapter');
    });
  }

  Future<void> _toggleVerseBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final newState = !_isVerseExpanded;
    await prefs.setBool('verse_banner_expanded', newState);
    setState(() => _isVerseExpanded = newState);
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

  void _showLanguageSelectorSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Text('மொழி தேர்வு (Language Mode)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              RadioListTile<BibleLanguageMode>(
                title: const Text('தமிழ் மட்டும் (Tamil Only)'),
                subtitle: const Text('திருவிவிலியம் பழைய மற்றும் புதிய ஏற்பாடு'),
                value: BibleLanguageMode.tamil,
                groupValue: AppSettings.instance.languageMode,
                onChanged: (val) {
                  if (val != null) AppSettings.instance.setLanguageMode(val);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<BibleLanguageMode>(
                title: const Text('English Only (KJV)'),
                subtitle: const Text('Authorized King James Version'),
                value: BibleLanguageMode.english,
                groupValue: AppSettings.instance.languageMode,
                onChanged: (val) {
                  if (val != null) AppSettings.instance.setLanguageMode(val);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<BibleLanguageMode>(
                title: const Text('தமிழ் + KJV English (இணைந்தது)'),
                subtitle: const Text('ஒப்புநோக்கு வாசிப்பு (Bilingual Parallel)'),
                value: BibleLanguageMode.combined,
                groupValue: AppSettings.instance.languageMode,
                onChanged: (val) {
                  if (val != null) AppSettings.instance.setLanguageMode(val);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
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

    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final langMode = AppSettings.instance.languageMode;

        final otTabTitle = langMode == BibleLanguageMode.english
            ? 'Old Testament (OT)'
            : (langMode == BibleLanguageMode.combined
                ? 'பழைய ஏற்பாடு (OT)'
                : 'பழைய ஏற்பாடு');

        final ntTabTitle = langMode == BibleLanguageMode.english
            ? 'New Testament (NT)'
            : (langMode == BibleLanguageMode.combined
                ? 'புதிய ஏற்பாடு (NT)'
                : 'புதிய ஏற்பாடு');

        BookModel? lastBook;
        if (_lastBookId != null) {
          lastBook = _allBooks.firstWhere((b) => b.id == _lastBookId, orElse: () => _allBooks.first);
        }

        return Scaffold(
          appBar: AppBar(
            title: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'வாழ்க்கை வழிகாட்டி (Topics)',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TopicalGuideScreen(allBooks: _allBooks, chapterCounts: _chapterCounts)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_outlined),
                tooltip: 'குறிப்புகள் (Notes)',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotesListScreen(allBooks: _allBooks, chapterCounts: _chapterCounts)),
                ),
              ),
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
              tabs: [
                Tab(text: otTabTitle),
                Tab(text: ntTabTitle),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'home_lang_fab',
            elevation: 3,
            icon: const Icon(Icons.translate, size: 18),
            label: Text(
              AppSettings.instance.languageBadgeLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            tooltip: 'மொழி மாற்று (${AppSettings.instance.languageFullTitle})',
            onPressed: _showLanguageSelectorSheet,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                      Theme.of(context).colorScheme.surfaceVariant,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          langMode == BibleLanguageMode.english ? 'Verse of the Day' : 'இன்றைய வசனம்',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            langMode == BibleLanguageMode.english ? '🔥 $_streakCount Days' : '🔥 $_streakCount நாள்',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'பகிர்',
                          onPressed: () {
                            Share.share('${_todayVerse["ref"]}\n"${_todayVerse["text"]}"\n- பரிசுத்த வேதாகமம்');
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_isVerseExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: _isVerseExpanded ? 'சுருக்கு' : 'விரிவாக்கு',
                          onPressed: _toggleVerseBanner,
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _isVerseExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      firstChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            '"${_todayVerse["text"]}"',
                            style: const TextStyle(fontSize: 14.5, height: 1.45, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _todayVerse["ref"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${_todayVerse["ref"]} - ${_todayVerse["text"]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (lastBook != null && _lastChapter != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(
                      langMode == BibleLanguageMode.english
                          ? 'Last read: ${AppSettings.instance.getBookDisplayName(lastBook)} $_lastChapter'
                          : 'கடைசியாக வாசித்தது: ${AppSettings.instance.getBookDisplayName(lastBook)} $_lastChapter',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(
                            book: lastBook!,
                            initialChapter: _lastChapter!,
                            totalChapters: _chapterCounts[lastBook.id] ?? 1,
                          ),
                        ),
                      ).then((_) => _loadState());
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
      },
    );
  }

  Widget _buildBookList(List<BookModel> books) {
    final langMode = AppSettings.instance.languageMode;
    final suffix = langMode == BibleLanguageMode.english ? 'Ch.' : 'அதி.';

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 76),
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        final totalChapters = _chapterCounts[book.id] ?? 1;
        final displayName = AppSettings.instance.getBookDisplayName(book);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text('${book.id}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
          title: Text(displayName, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalChapters $suffix',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReaderScreen(book: book, initialChapter: 1, totalChapters: totalChapters),
              ),
            ).then((_) => _loadState());
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
  final int? targetVerse;

  const ReaderScreen({
    super.key,
    required this.book,
    required this.initialChapter,
    required this.totalChapters,
    this.targetVerse,
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
  }

  @override
  void dispose() {
    TtsEngine.instance.stop();
    _pageController.dispose();
    super.dispose();
  }

  void _showChapterBottomSheet() {
    final bookTitle = AppSettings.instance.getBookDisplayName(widget.book);
    final headerTitle = AppSettings.instance.languageMode == BibleLanguageMode.english
        ? '$bookTitle - Chapters'
        : '$bookTitle - அதிகாரங்கள்';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headerTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _showLanguageSelectorDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Text('மொழி தேர்வு (Language Mode)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              RadioListTile<BibleLanguageMode>(
                title: const Text('தமிழ் மட்டும் (Tamil Only)'),
                value: BibleLanguageMode.tamil,
                groupValue: AppSettings.instance.languageMode,
                onChanged: (val) {
                  if (val != null) AppSettings.instance.setLanguageMode(val);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<BibleLanguageMode>(
                title: const Text('English Only (KJV)'),
                value: BibleLanguageMode.english,
                groupValue: AppSettings.instance.languageMode,
                onChanged: (val) {
                  if (val != null) AppSettings.instance.setLanguageMode(val);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<BibleLanguageMode>(
                title: const Text('தமிழ் + KJV English (இணைந்தது)'),
                value: BibleLanguageMode.combined,
                groupValue: AppSettings.instance.languageMode,
                onChanged: (val) {
                  if (val != null) AppSettings.instance.setLanguageMode(val);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startReadingFullChapter() async {
    final verses = await DatabaseHelper.getVerses(widget.book.id, _currentChapter);
    final isEnglishOnly = AppSettings.instance.languageMode == BibleLanguageMode.english;
    final texts = verses
        .map((v) => (isEnglishOnly && v.textEn != null && v.textEn!.isNotEmpty) ? v.textEn!.trim() : v.text.trim())
        .toList();
    await TtsEngine.instance.startChapter(texts);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final bookTitle = AppSettings.instance.getBookDisplayName(widget.book);

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
                    Text('$bookTitle $_currentChapter', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            actions: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => AppSettings.instance.cycleLanguageMode(),
                onLongPress: _showLanguageSelectorDialog,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        AppSettings.instance.languageBadgeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          const Text('Speed: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    return ChapterView(
                      book: widget.book,
                      chapter: chapter,
                      fontSize: _fontSize,
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
  String _getNoteKey(int verse) => 'note_${widget.book.id}_${widget.chapter}_$verse';

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

  void _showAddNoteDialog(VerseModel verse) async {
    final prefs = await SharedPreferences.getInstance();
    final noteKey = _getNoteKey(verse.number);
    final existingNote = prefs.getString(noteKey) ?? '';
    final ctrl = TextEditingController(text: existingNote);
    final bookTitle = AppSettings.instance.getBookDisplayName(widget.book);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$bookTitle ${widget.chapter}:${verse.number} - Note'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your reflection or study note here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (existingNote.isNotEmpty)
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await prefs.remove(noteKey);
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
              },
            ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await prefs.setString(noteKey, ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved')));
              } else {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showVerseActions(VerseModel verse) {
    final langMode = AppSettings.instance.languageMode;
    final bookTitle = AppSettings.instance.getBookDisplayName(widget.book);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final reference = '$bookTitle ${widget.chapter}:${verse.number}';
        String fullText = '';
        if (langMode == BibleLanguageMode.tamil) {
          fullText = '$reference\n"${verse.text}"';
        } else if (langMode == BibleLanguageMode.english) {
          fullText = '$reference\n"${verse.textEn ?? ''}"';
        } else {
          fullText = '$reference\n"${verse.text}"\n[KJV] "${verse.textEn ?? ''}"';
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reference, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (langMode != BibleLanguageMode.english)
                  Text(verse.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                if (langMode != BibleLanguageMode.tamil && verse.textEn != null && verse.textEn!.isNotEmpty)
                  Text('[KJV] ${verse.textEn!}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'Listen',
                      onPressed: () {
                        final speakText = (langMode == BibleLanguageMode.english && verse.textEn != null && verse.textEn!.isNotEmpty)
                            ? verse.textEn!
                            : verse.text;
                        TtsEngine.instance.startChapter([speakText]);
                        Navigator.pop(ctx);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note),
                      tooltip: 'Note',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddNoteDialog(verse);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullText));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verse copied to clipboard')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                      onPressed: () {
                        Share.share(fullText);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Highlight Color:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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

        return AnimatedBuilder(
          animation: Listenable.merge([TtsEngine.instance, AppSettings.instance]),
          builder: (context, _) {
            final activeTtsIndex = (TtsEngine.instance.state == TtsState.playing ||
                    TtsEngine.instance.state == TtsState.paused)
                ? TtsEngine.instance.currentIndex
                : null;
            final langMode = AppSettings.instance.languageMode;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final v = verses[index];
                final isTtsActive = activeTtsIndex == index;
                final hlColor = isTtsActive
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8)
                    : _getHighlightColor(v.number);

                return InkWell(
                  onTap: () => _showVerseActions(v),
                  onLongPress: () => _showVerseActions(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: hlColor,
                      borderRadius: BorderRadius.circular(6),
                      border: isTtsActive ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (langMode != BibleLanguageMode.english)
                          RichText(
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
                        if (langMode != BibleLanguageMode.tamil && v.textEn != null && v.textEn!.isNotEmpty) ...[
                          if (langMode == BibleLanguageMode.combined) const SizedBox(height: 3),
                          Padding(
                            padding: EdgeInsets.only(left: langMode == BibleLanguageMode.combined ? 18.0 : 0.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: langMode == BibleLanguageMode.english ? widget.fontSize : widget.fontSize * 0.86,
                                  height: 1.45,
                                  color: langMode == BibleLanguageMode.english
                                      ? Theme.of(context).textTheme.bodyLarge?.color
                                      : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.85),
                                  fontStyle: langMode == BibleLanguageMode.combined ? FontStyle.italic : FontStyle.normal,
                                ),
                                children: [
                                  if (langMode == BibleLanguageMode.english)
                                    TextSpan(
                                      text: '${v.number} ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: widget.fontSize * 0.85,
                                      ),
                                    ),
                                  TextSpan(text: v.textEn!),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class TopicalGuideScreen extends StatelessWidget {
  final List<BookModel> allBooks;
  final Map<int, int> chapterCounts;

  const TopicalGuideScreen({super.key, required this.allBooks, required this.chapterCounts});

  @override
  Widget build(BuildContext context) {
    final topics = TopicalData.getTopics();

    return Scaffold(
      appBar: AppBar(title: const Text('வாழ்க்கை வழிகாட்டி (Topics)')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final item = topics[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: item.verses.map((v) {
                final targetBook = allBooks.firstWhere((b) => b.id == v.bookId, orElse: () => allBooks.first);
                final bookTitle = AppSettings.instance.getBookDisplayName(targetBook);

                return ListTile(
                  title: Text('$bookTitle ${v.chapter}:${v.verse}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(v.summaryTa),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderScreen(
                          book: targetBook,
                          initialChapter: v.chapter,
                          totalChapters: chapterCounts[targetBook.id] ?? 1,
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
    );
  }
}

class NotesListScreen extends StatefulWidget {
  final List<BookModel> allBooks;
  final Map<int, int> chapterCounts;

  const NotesListScreen({super.key, required this.allBooks, required this.chapterCounts});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Map<String, dynamic>> _savedNotes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllNotes();
  }

  Future<void> _loadAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('note_'));
    final List<Map<String, dynamic>> list = [];

    for (var k in keys) {
      final parts = k.split('_');
      if (parts.length == 4) {
        final bookId = int.parse(parts[1]);
        final ch = int.parse(parts[2]);
        final verseNum = int.parse(parts[3]);
        final noteText = prefs.getString(k) ?? '';
        final book = widget.allBooks.firstWhere((b) => b.id == bookId, orElse: () => widget.allBooks.first);
        final verseText = await DatabaseHelper.getSingleVerseText(bookId, ch, verseNum);

        list.add({
          "key": k,
          "book": book,
          "book_id": bookId,
          "chapter": ch,
          "verse": verseNum,
          "note": noteText,
          "verse_text": verseText ?? '',
        });
      }
    }

    setState(() {
      _savedNotes = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('என் குறிப்புகள் (Notes)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedNotes.isEmpty
              ? const Center(child: Text('குறிப்புகள் ஏதும் எழுதப்படவில்லை.'))
              : ListView.separated(
                  itemCount: _savedNotes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _savedNotes[index];
                    final book = item["book"] as BookModel;
                    final bookTitle = AppSettings.instance.getBookDisplayName(book);

                    return ListTile(
                      title: Text('$bookTitle ${item["chapter"]}:${item["verse"]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📝 ${item["note"]}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                          const SizedBox(height: 2),
                          Text('"${item["verse_text"]}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
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
                        ).then((_) => _loadAllNotes());
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
                    final bookTitle = AppSettings.instance.getBookDisplayName(book);
                    final Color? bg = item["colorHex"] != null ? Color(int.parse(item["colorHex"])) : null;

                    return ListTile(
                      tileColor: bg?.withOpacity(0.35),
                      title: Text('$bookTitle ${item["chapter"]}:${item["verse"]}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final langMode = AppSettings.instance.languageMode;
    final hint = langMode == BibleLanguageMode.english ? 'Search verses...' : 'தேடுங்கள் (எ.கா: வெளிச்சம்)...';

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint, border: InputBorder.none),
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
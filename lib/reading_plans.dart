class ReadingPortion {
  final int bookId;
  final String bookName;
  final int chapter;

  const ReadingPortion({
    required this.bookId,
    required this.bookName,
    required this.chapter,
  });
}

class PlanDay {
  final int dayNumber;
  final List<ReadingPortion> portions;

  const PlanDay({required this.dayNumber, required this.portions});

  String get summary => portions.map((p) => '${p.bookName} ${p.chapter}').join(', ');
}

class ReadingPlan {
  final String id;
  final String title;
  final String description;
  final int totalDays;
  final List<PlanDay> days;

  const ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.days,
  });
}

class ReadingPlansData {
  static List<ReadingPlan> getAllPlans() {
    return [
      _buildGospelsPlan(),
      _buildWisdomPlan(),
      _buildEpistlesPlan(),
      _buildOneYearCanonicalPlan(),
    ];
  }

  // 1. Gospels in 30 Days (MAT: 40, MRK: 41, LUK: 42, JHN: 43)
  static ReadingPlan _buildGospelsPlan() {
    final List<PlanDay> days = [];
    final allGospelPortions = <ReadingPortion>[];

    // MAT (28 ch)
    for (int i = 1; i <= 28; i++) {
      allGospelPortions.add(ReadingPortion(bookId: 40, bookName: 'மத்தேயு', chapter: i));
    }
    // MRK (16 ch)
    for (int i = 1; i <= 16; i++) {
      allGospelPortions.add(ReadingPortion(bookId: 41, bookName: 'மாற்கு', chapter: i));
    }
    // LUK (24 ch)
    for (int i = 1; i <= 24; i++) {
      allGospelPortions.add(ReadingPortion(bookId: 42, bookName: 'லூக்கா', chapter: i));
    }
    // JHN (21 ch)
    for (int i = 1; i <= 21; i++) {
      allGospelPortions.add(ReadingPortion(bookId: 43, bookName: 'யோவான்', chapter: i));
    }

    int cursor = 0;
    for (int d = 1; d <= 30; d++) {
      final count = (d <= 29) ? 3 : (allGospelPortions.length - cursor);
      final dayPortions = allGospelPortions.skip(cursor).take(count).toList();
      cursor += count;
      days.add(PlanDay(dayNumber: d, portions: dayPortions));
    }

    return ReadingPlan(
      id: 'plan_gospels_30',
      title: 'நற்செய்தி நூல்கள் (30 நாட்கள்)',
      description: 'மத்தேயு, மாற்கு, லூக்கா, யோவான் ஆகிய நான்கு நற்செய்தி நூல்களை 30 நாட்களில் வாசித்து முடியுங்கள்.',
      totalDays: 30,
      days: days,
    );
  }

  // 2. Wisdom & Psalms in 60 Days (PSA: 19, PRO: 20)
  static ReadingPlan _buildWisdomPlan() {
    final List<PlanDay> days = [];
    int psa = 1;
    int pro = 1;

    for (int d = 1; d <= 60; d++) {
      final portions = <ReadingPortion>[];
      // 2 or 3 Psalms per day
      if (psa <= 150) {
        portions.add(ReadingPortion(bookId: 19, bookName: 'சங்கீதம்', chapter: psa++));
        if (psa <= 150) portions.add(ReadingPortion(bookId: 19, bookName: 'சங்கீதம்', chapter: psa++));
        if (d % 2 == 0 && psa <= 150) portions.add(ReadingPortion(bookId: 19, bookName: 'சங்கீதம்', chapter: psa++));
      }
      // 1 Proverbs every 2 days
      if (d % 2 == 1 && pro <= 31) {
        portions.add(ReadingPortion(bookId: 20, bookName: 'நீதிமொழிகள்', chapter: pro++));
      }
      days.add(PlanDay(dayNumber: d, portions: portions));
    }

    return ReadingPlan(
      id: 'plan_wisdom_60',
      title: 'சங்கீதம் & நீதிமொழிகள் (60 நாட்கள்)',
      description: 'ஆறுதலும் ஞானமும் நிறைந்த சங்கீதம் மற்றும் நீதிமொழிகள் நூல்களை 60 நாட்களில் தியானியுங்கள்.',
      totalDays: 60,
      days: days,
    );
  }

  // 3. Epistles in 30 Days (ROM: 45 to PHM: 57)
  static ReadingPlan _buildEpistlesPlan() {
    final List<PlanDay> days = [];
    final portions = <ReadingPortion>[];

    final epistles = [
      {'id': 45, 'name': 'ரோமர்', 'ch': 16},
      {'id': 46, 'name': '1 கொரிந்தியர்', 'ch': 16},
      {'id': 47, 'name': '2 கொரிந்தியர்', 'ch': 13},
      {'id': 48, 'name': 'கலாத்தியர்', 'ch': 6},
      {'id': 49, 'name': 'எபேசியர்', 'ch': 6},
      {'id': 50, 'name': 'பிலிப்பியர்', 'ch': 4},
      {'id': 51, 'name': 'கொலோசெயர்', 'ch': 4},
      {'id': 52, 'name': '1 தெசலோனிக்கேயர்', 'ch': 5},
      {'id': 53, 'name': '2 தெசலோனிக்கேயர்', 'ch': 3},
      {'id': 54, 'name': '1 தீமோத்தேயு', 'ch': 6},
      {'id': 55, 'name': '2 தீமோத்தேயு', 'ch': 4},
      {'id': 56, 'name': 'தீத்து', 'ch': 3},
      {'id': 57, 'name': 'பிலேமோன்', 'ch': 1},
    ];

    for (var ep in epistles) {
      for (int c = 1; c <= (ep['ch'] as int); c++) {
        portions.add(ReadingPortion(
          bookId: ep['id'] as int,
          bookName: ep['name'] as String,
          chapter: c,
        ));
      }
    }

    int cursor = 0;
    for (int d = 1; d <= 30; d++) {
      final count = (d <= 29) ? 3 : (portions.length - cursor);
      final dayPortions = portions.skip(cursor).take(count).toList();
      cursor += count;
      days.add(PlanDay(dayNumber: d, portions: dayPortions));
    }

    return ReadingPlan(
      id: 'plan_epistles_30',
      title: 'பவுலின் நிருபங்கள் (30 நாட்கள்)',
      description: 'அப்போஸ்தலனாகிய பவுல் எழுதிய நிருபங்கள் அனைத்தையும் 30 நாட்களில் வாசித்து முடியுங்கள்.',
      totalDays: 30,
      days: days,
    );
  }

  // 4. 1-Year Canonical Plan (365 Days across 1,189 Chapters)
  static ReadingPlan _buildOneYearCanonicalPlan() {
    final canonMetadata = [
      {'id': 1, 'name': 'ஆதியாகமம்', 'ch': 50},
      {'id': 2, 'name': 'யாத்திராகமம்', 'ch': 40},
      {'id': 3, 'name': 'லேவியராகமம்', 'ch': 27},
      {'id': 4, 'name': 'எண்ணாகமம்', 'ch': 36},
      {'id': 5, 'name': 'உபாகமம்', 'ch': 34},
      {'id': 6, 'name': 'யோசுவா', 'ch': 24},
      {'id': 7, 'name': 'நியாயாதிபதிகள்', 'ch': 21},
      {'id': 8, 'name': 'ரூத்', 'ch': 4},
      {'id': 9, 'name': '1 சாமுவேல்', 'ch': 31},
      {'id': 10, 'name': '2 சாமுவேல்', 'ch': 24},
      {'id': 11, 'name': '1 இராஜாக்கள்', 'ch': 22},
      {'id': 12, 'name': '2 இராஜாக்கள்', 'ch': 25},
      {'id': 13, 'name': '1 நாளாகமம்', 'ch': 29},
      {'id': 14, 'name': '2 நாளாகமம்', 'ch': 36},
      {'id': 15, 'name': 'எஸ்றா', 'ch': 10},
      {'id': 16, 'name': 'நெகேமியா', 'ch': 13},
      {'id': 17, 'name': 'எஸ்தர்', 'ch': 10},
      {'id': 18, 'name': 'யோபு', 'ch': 42},
      {'id': 19, 'name': 'சங்கீதம்', 'ch': 150},
      {'id': 20, 'name': 'நீதிமொழிகள்', 'ch': 31},
      {'id': 21, 'name': 'பிரசங்கி', 'ch': 12},
      {'id': 22, 'name': 'உன்னதப்பாட்டு', 'ch': 8},
      {'id': 23, 'name': 'ஏசாயா', 'ch': 66},
      {'id': 24, 'name': 'எரேமியா', 'ch': 52},
      {'id': 25, 'name': 'புலம்பல்', 'ch': 5},
      {'id': 26, 'name': 'எசேக்கியேல்', 'ch': 48},
      {'id': 27, 'name': 'தானியேல்', 'ch': 12},
      {'id': 28, 'name': 'ஓசியா', 'ch': 14},
      {'id': 29, 'name': 'யோவேல்', 'ch': 3},
      {'id': 30, 'name': 'ஆமோஸ்', 'ch': 9},
      {'id': 31, 'name': 'ஒபதியா', 'ch': 1},
      {'id': 32, 'name': 'யோனா', 'ch': 4},
      {'id': 33, 'name': 'மீகா', 'ch': 7},
      {'id': 34, 'name': 'நாகூம்', 'ch': 3},
      {'id': 35, 'name': 'அபகூக்', 'ch': 3},
      {'id': 36, 'name': 'செப்பனியா', 'ch': 3},
      {'id': 37, 'name': 'ஆகாய்', 'ch': 2},
      {'id': 38, 'name': 'சகரியா', 'ch': 14},
      {'id': 39, 'name': 'மல்கியா', 'ch': 4},
      {'id': 40, 'name': 'மத்தேயு', 'ch': 28},
      {'id': 41, 'name': 'மாற்கு', 'ch': 16},
      {'id': 42, 'name': 'லூக்கா', 'ch': 24},
      {'id': 43, 'name': 'யோவான்', 'ch': 21},
      {'id': 44, 'name': 'அப்போஸ்தலர்', 'ch': 28},
      {'id': 45, 'name': 'ரோமர்', 'ch': 16},
      {'id': 46, 'name': '1 கொரிந்தியர்', 'ch': 16},
      {'id': 47, 'name': '2 கொரிந்தியர்', 'ch': 13},
      {'id': 48, 'name': 'கலாத்தியர்', 'ch': 6},
      {'id': 49, 'name': 'எபேசியர்', 'ch': 6},
      {'id': 50, 'name': 'பிலிப்பியர்', 'ch': 4},
      {'id': 51, 'name': 'கொலோசெயர்', 'ch': 4},
      {'id': 52, 'name': '1 தெசலோனிக்கேயர்', 'ch': 5},
      {'id': 53, 'name': '2 தெசலோனிக்கேயர்', 'ch': 3},
      {'id': 54, 'name': '1 தீமோத்தேயு', 'ch': 6},
      {'id': 55, 'name': '2 தீமோத்தேயு', 'ch': 4},
      {'id': 56, 'name': 'தீத்து', 'ch': 3},
      {'id': 57, 'name': 'பிலேமோன்', 'ch': 1},
      {'id': 58, 'name': 'எபிரெயர்', 'ch': 13},
      {'id': 59, 'name': 'யாக்கோபு', 'ch': 5},
      {'id': 60, 'name': '1 பேதுரு', 'ch': 5},
      {'id': 61, 'name': '2 பேதுரு', 'ch': 3},
      {'id': 62, 'name': '1 யோவான்', 'ch': 5},
      {'id': 63, 'name': '2 யோவான்', 'ch': 1},
      {'id': 64, 'name': '3 யோவான்', 'ch': 1},
      {'id': 65, 'name': 'யூதா', 'ch': 1},
      {'id': 66, 'name': 'வெளிப்படுத்தின விசேஷம்', 'ch': 22},
    ];

    final allBiblePortions = <ReadingPortion>[];
    for (var b in canonMetadata) {
      for (int c = 1; c <= (b['ch'] as int); c++) {
        allBiblePortions.add(ReadingPortion(
          bookId: b['id'] as int,
          bookName: b['name'] as String,
          chapter: c,
        ));
      }
    }

    final List<PlanDay> days = [];
    int cursor = 0;
    const totalDays = 365;

    for (int d = 1; d <= totalDays; d++) {
      // Distribute 1,189 chapters evenly (~3.25 chapters per day)
      final remainingDays = totalDays - d + 1;
      final remainingChapters = allBiblePortions.length - cursor;
      final count = (remainingChapters / remainingDays).round();

      final dayPortions = allBiblePortions.skip(cursor).take(count).toList();
      cursor += count;
      days.add(PlanDay(dayNumber: d, portions: dayPortions));
    }

    return ReadingPlan(
      id: 'plan_1_year',
      title: '1 வருட வேதாகம வாசிப்பு திட்டம்',
      description: 'தினமும் 3 முதல் 4 அதிகாரங்கள் வாசித்து, முழு வேதாகமத்தையும் 365 நாட்களில் நிறைவு செய்யுங்கள்.',
      totalDays: 365,
      days: days,
    );
  }
}
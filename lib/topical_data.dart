class TopicItem {
  final String title;
  final String icon;
  final List<TopicVerse> verses;

  const TopicItem({required this.title, required this.icon, required this.verses});
}

class TopicVerse {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String summaryTa;

  const TopicVerse({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.summaryTa,
  });
}

class TopicalData {
  static List<TopicItem> getTopics() {
    return const [
      TopicItem(
        title: 'சமாதானம் & அமைதி (Peace)',
        icon: '🕊️',
        verses: [
          TopicVerse(bookId: 43, bookName: 'யோவான்', chapter: 14, verse: 27, summaryTa: 'என்னுடைய சமாதானத்தையே உங்களுக்குக் கொடுக்கிறேன்...'),
          TopicVerse(bookId: 50, bookName: 'பிலிப்பியர்', chapter: 4, verse: 7, summaryTa: 'எல்லா புத்திக்கும் மேலான தேவ சமாதானம்...'),
          TopicVerse(bookId: 19, bookName: 'சங்கீதம்', chapter: 29, verse: 11, summaryTa: 'கர்த்தர் தமது ஜனத்திற்குச் சமாதானம் அருளி...'),
        ],
      ),
      TopicItem(
        title: 'பயம் நீங்க & தைரியம் (Fear & Courage)',
        icon: '🛡️',
        verses: [
          TopicVerse(bookId: 23, bookName: 'ஏசாயா', chapter: 41, verse: 10, summaryTa: 'நீ பயப்படாதே, நான் உன்னுடனே இருக்கிறேன்...'),
          TopicVerse(bookId: 6, bookName: 'யோசுவா', chapter: 1, verse: 9, summaryTa: 'பலங்கொண்டு திடமனதாயிரு; திகையாதே, கலங்காதே...'),
          TopicVerse(bookId: 55, bookName: '2 தீமோத்தேயு', chapter: 1, verse: 7, summaryTa: 'தேவன் நமக்கு பயமுள்ள ஆவியைக் கொடாமல்...'),
        ],
      ),
      TopicItem(
        title: 'ஆறுதல் & சோர்வு நீங்க (Comfort)',
        icon: '🌿',
        verses: [
          TopicVerse(bookId: 40, bookName: 'மத்தேயு', chapter: 11, verse: 28, summaryTa: 'வருத்தப்பட்டுப் பாரஞ்சுமக்கிறவர்களே...'),
          TopicVerse(bookId: 19, bookName: 'சங்கீதம்', chapter: 23, verse: 4, summaryTa: 'நான் மரண இருளின் பள்ளத்தாக்கிலே நடந்தாலும்...'),
          TopicVerse(bookId: 47, bookName: '2 கொரிந்தியர்', chapter: 1, verse: 3, summaryTa: 'சகலவிதமான ஆறுதலின் தேவன்...'),
        ],
      ),
      TopicItem(
        title: 'சுகம் & ஆரோக்கியம் (Healing)',
        icon: '❤️‍🩹',
        verses: [
          TopicVerse(bookId: 24, bookName: 'எரேமியா', chapter: 17, verse: 14, summaryTa: 'கர்த்தாவே, என்னைக் குணமாக்கும், அப்பொழுது குணமாவேன்...'),
          TopicVerse(bookId: 19, bookName: 'சங்கீதம்', chapter: 103, verse: 3, summaryTa: 'உன் நோய்களையெல்லாம் குணமாக்குகிறார்...'),
          TopicVerse(bookId: 60, bookName: '1 பேதுரு', chapter: 2, verse: 24, summaryTa: 'அவருடைய தழும்புகளால் குணமானீர்கள்...'),
        ],
      ),
      TopicItem(
        title: 'விசுவாசம் & நம்பிக்கை (Faith & Hope)',
        icon: '⚓',
        verses: [
          TopicVerse(bookId: 58, bookName: 'எபிரெயர்', chapter: 11, verse: 1, summaryTa: 'விசுவாசமானது நம்பப்படுகிறவைகளின் உறுதியும்...'),
          TopicVerse(bookId: 20, bookName: 'நீதிமொழிகள்', chapter: 3, verse: 5, summaryTa: 'உன் முழு இருதயத்தோடும் கர்த்தரில் நம்பிக்கையாயிரு...'),
          TopicVerse(bookId: 24, bookName: 'எரேமியா', chapter: 29, verse: 11, summaryTa: 'சமாதானத்துக்கேதுவான நினைவுகளே...'),
        ],
      ),
      TopicItem(
        title: 'குடும்ப ஆசீர்வாதம் (Family Blessings)',
        icon: '🏡',
        verses: [
          TopicVerse(bookId: 19, bookName: 'சங்கீதம்', chapter: 128, verse: 1, summaryTa: 'கர்த்தருக்குப் பயந்து, அவர் வழிகளில் நடக்கிறவன் பாக்கியவான்...'),
          TopicVerse(bookId: 6, bookName: 'யோசுவா', chapter: 24, verse: 15, summaryTa: 'நானும் என் வீட்டாருமோவென்றால், கர்த்தரையே சேவிப்போம்...'),
          TopicVerse(bookId: 49, bookName: 'எபேசியர்', chapter: 6, verse: 1, summaryTa: 'பிள்ளைகளே, உங்கள் பெற்றாருக்குக் கர்த்தருக்குள் கீழ்ப்படியுங்கள்...'),
        ],
      ),
    ];
  }
}
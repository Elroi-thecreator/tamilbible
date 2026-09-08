// Local Storage Manager for Bookmarks, Highlights, and Notes
const STORAGE_KEYS = {
    BOOKMARKS: 'bilingual_bible_bookmarks',
    HIGHLIGHTS: 'bilingual_bible_highlights',
    THEME: 'bible_app_theme',
    FONT_SIZE: 'bible_font_size'
};

function getBookmarks() {
    return JSON.parse(localStorage.getItem(STORAGE_KEYS.BOOKMARKS) || '[]');
}

function getHighlights() {
    return JSON.parse(localStorage.getItem(STORAGE_KEYS.HIGHLIGHTS) || '{}');
}

function isBookmarked(bookId, ch, v) {
    return getBookmarks().some(b => b.bookId === bookId && b.ch === ch && b.v === v);
}

function toggleBookmark(bookId, bookNameEn, bookNameTa, ch, v, textEn, textTa) {
    let bookmarks = getBookmarks();
    const idx = bookmarks.findIndex(b => b.bookId === bookId && b.ch === ch && b.v === v);

    if (idx >= 0) {
        bookmarks.splice(idx, 1);
    } else {
        bookmarks.push({
            bookId, bookNameEn, bookNameTa, ch, v, textEn, textTa,
            date: new Date().toLocaleDateString()
        });
    }

    localStorage.setItem(STORAGE_KEYS.BOOKMARKS, JSON.stringify(bookmarks));
    updateBookmarkUI();
}

function updateBookmarkUI() {
    document.querySelectorAll('.bookmark-btn').forEach(btn => {
        const b = parseInt(btn.dataset.book);
        const c = parseInt(btn.dataset.chapter);
        const v = parseInt(btn.dataset.verse);
        if (isBookmarked(b, c, v)) {
            btn.innerHTML = '★';
            btn.classList.add('text-amber-500');
        } else {
            btn.innerHTML = '☆';
            btn.classList.remove('text-amber-500');
        }
    });
}

// Tricolor Highlighter (yellow, green, rose)
function setVerseHighlight(bookId, ch, v, colorClass) {
    const key = `${bookId}_${ch}_${v}`;
    let highlights = getHighlights();

    if (highlights[key] === colorClass) {
        delete highlights[key]; // Toggle off if clicked again
    } else {
        highlights[key] = colorClass;
    }

    localStorage.setItem(STORAGE_KEYS.HIGHLIGHTS, JSON.stringify(highlights));
    applyHighlights();
}

function applyHighlights() {
    const highlights = getHighlights();
    document.querySelectorAll('.verse-item').forEach(el => {
        const vNum = el.id.replace('v', '');
        const bookId = window.CURRENT_BOOK_ID;
        const ch = window.CURRENT_CHAPTER;
        const key = `${bookId}_${ch}_${vNum}`;

        // Clear existing highlight classes
        el.classList.remove('bg-amber-100/50', 'dark:bg-amber-950/30', 'bg-emerald-100/50', 'dark:bg-emerald-950/30', 'bg-rose-100/50', 'dark:bg-rose-950/30');

        if (highlights[key]) {
            if (highlights[key] === 'yellow') el.classList.add('bg-amber-100/50', 'dark:bg-amber-950/30');
            if (highlights[key] === 'green') el.classList.add('bg-emerald-100/50', 'dark:bg-emerald-950/30');
            if (highlights[key] === 'rose') el.classList.add('bg-rose-100/50', 'dark:bg-rose-950/30');
        }
    });
}

function copyBilingualVerse(refEn, refTa, textEn, textTa) {
    const quote = `"${textEn}"\n— ${refEn}\n\n"${textTa}"\n— ${refTa}\n\nShared via Holy Bible App`;
    navigator.clipboard.writeText(quote).then(() => {
        showToast("Verse copied with reference!");
    });
}

function showToast(message) {
    let toast = document.getElementById('app-toast');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'app-toast';
        toast.className = 'fixed bottom-20 left-1/2 transform -translate-x-1/2 bg-stone-900 text-white text-xs px-4 py-2 rounded-full shadow-lg z-50 transition-opacity duration-300 pointer-events-none';
        document.body.appendChild(toast);
    }
    toast.innerText = message;
    toast.style.opacity = '1';
    setTimeout(() => { toast.style.opacity = '0'; }, 2200);
}

document.addEventListener('DOMContentLoaded', () => {
    updateBookmarkUI();
    applyHighlights();
});
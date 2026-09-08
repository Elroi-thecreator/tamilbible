class BibleContinuousAudio {
    constructor() {
        this.isPlaying = false;
        this.isPaused = false;
        this.currentIndex = 0;
        this.verses = [];
        this.synth = window.speechSynthesis;
        this.currentUtterance = null;
        this.lang = 'ta'; // 'ta' | 'en'
        this.rate = 1.0;
        this.bookId = null;
        this.chapter = null;
        this.nextChapter = null;
        this.mode = 'bilingual';
    }

    init(bookId, chapter, nextChapter, mode) {
        this.bookId = bookId;
        this.chapter = chapter;
        this.nextChapter = nextChapter;
        this.mode = mode;

        const items = document.querySelectorAll('.verse-item');
        this.verses = Array.from(items).map((el, idx) => ({
            index: idx,
            verse: el.id.replace('v', ''),
            element: el,
            textEn: el.querySelector('.verse-text-en')?.innerText.trim() || '',
            textTa: el.querySelector('.verse-text-ta')?.innerText.trim() || ''
        }));

        if (this.synth.onvoiceschanged !== undefined) {
            this.synth.onvoiceschanged = () => this.getBestVoice(this.lang);
        }

        // Detect if cross-chapter continuous reading was active
        const savedState = sessionStorage.getItem('bible_autoplay_state');
        if (savedState) {
            const state = JSON.parse(savedState);
            sessionStorage.removeItem('bible_autoplay_state');
            this.lang = state.lang || 'ta';
            this.rate = state.rate || 1.0;
            const langEl = document.getElementById('audio-lang-select');
            const rateEl = document.getElementById('audio-rate-select');
            if (langEl) langEl.value = this.lang;
            if (rateEl) rateEl.value = this.rate;
            setTimeout(() => this.play(0), 400);
        }
    }

    getBestVoice(targetLang) {
        const voices = this.synth.getVoices();
        if (targetLang === 'ta') {
            return voices.find(v => v.lang.toLowerCase().includes('ta')) || null;
        } else {
            return voices.find(v => v.lang.startsWith('en') && (v.name.includes('Natural') || v.name.includes('Google'))) || 
                   voices.find(v => v.lang.startsWith('en')) || null;
        }
    }

    play(fromIndex = 0) {
        this.isPlaying = true;
        this.isPaused = false;
        this.currentIndex = fromIndex;
        this.showDock();
        this.speakCurrent();
    }

    speakCurrent() {
        if (!this.isPlaying) return;

        if (this.currentIndex >= this.verses.length) {
            this.onChapterComplete();
            return;
        }

        const v = this.verses[this.currentIndex];
        this.spotlightVerse(v);

        let text = this.lang === 'ta' ? v.textTa : v.textEn;
        if (!text && this.lang === 'ta') text = v.textEn;

        this.synth.cancel();

        this.currentUtterance = new SpeechSynthesisUtterance(text);
        this.currentUtterance.rate = parseFloat(this.rate);

        const voice = this.getBestVoice(this.lang);
        if (voice) {
            this.currentUtterance.voice = voice;
            this.currentUtterance.lang = voice.lang;
        } else {
            this.currentUtterance.lang = this.lang === 'ta' ? 'ta-IN' : 'en-US';
        }

        this.currentUtterance.onend = () => {
            if (this.isPlaying && !this.isPaused) {
                this.currentIndex++;
                this.speakCurrent();
            }
        };

        this.currentUtterance.onerror = () => {
            if (this.isPlaying && !this.isPaused) {
                setTimeout(() => {
                    this.currentIndex++;
                    this.speakCurrent();
                }, 800);
            }
        };

        this.synth.speak(this.currentUtterance);
        this.setPlayPauseIcon(true);
    }

    spotlightVerse(v) {
        document.querySelectorAll('.verse-item').forEach(el => {
            el.classList.remove('ring-2', 'ring-amber-500', 'shadow-md');
        });
        v.element.classList.add('ring-2', 'ring-amber-500', 'shadow-md');
        v.element.scrollIntoView({ behavior: 'smooth', block: 'center' });

        const label = document.getElementById('audio-verse-label');
        if (label) label.innerText = `Verse ${v.verse}`;
    }

    pause() {
        if (this.isPlaying && !this.isPaused) {
            this.synth.pause();
            this.isPaused = true;
            this.setPlayPauseIcon(false);
        }
    }

    resume() {
        if (this.isPlaying && this.isPaused) {
            this.synth.resume();
            this.isPaused = false;
            this.setPlayPauseIcon(true);
        } else {
            this.play(this.currentIndex);
        }
    }

    stop() {
        this.isPlaying = false;
        this.isPaused = false;
        this.synth.cancel();
        sessionStorage.removeItem('bible_autoplay_state');
        document.querySelectorAll('.verse-item').forEach(el => {
            el.classList.remove('ring-2', 'ring-amber-500', 'shadow-md');
        });
        this.hideDock();
    }

    next() {
        if (this.currentIndex < this.verses.length - 1) {
            this.currentIndex++;
            this.speakCurrent();
        } else {
            this.onChapterComplete();
        }
    }

    prev() {
        if (this.currentIndex > 0) {
            this.currentIndex--;
            this.speakCurrent();
        }
    }

    onChapterComplete() {
        if (this.nextChapter) {
            sessionStorage.setItem('bible_autoplay_state', JSON.stringify({
                lang: this.lang,
                rate: this.rate
            }));
            window.location.href = `/read/${this.bookId}/${this.nextChapter}?mode=${this.mode}`;
        } else {
            this.stop();
            showToast("Reached the end of this book!");
        }
    }

    setLanguage(lang) {
        this.lang = lang;
        if (this.isPlaying) this.speakCurrent();
    }

    setRate(rate) {
        this.rate = rate;
        if (this.isPlaying) this.speakCurrent();
    }

    showDock() {
        document.getElementById('audio-dock')?.classList.remove('translate-y-full');
    }

    hideDock() {
        document.getElementById('audio-dock')?.classList.add('translate-y-full');
    }

    setPlayPauseIcon(playing) {
        const btn = document.getElementById('audio-play-pause-btn');
        if (btn) btn.innerHTML = playing ? '⏸' : '▶';
    }
}

window.bibleAudio = new BibleContinuousAudio();
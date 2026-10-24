# MushafSonbla
A modern, lightweight Quranic UI library built for SwiftUI. The package simplifies rendering Holy Quran pages, headers, and ayah markers with native Uthmanic calligraphy and seamless layout management.

---

## 🌟 Current Features
* **Built-in Quranic Typography**:
  * Native support for Uthmanic Hafs calligraphy (`HafsSmart`).
  * Dedicated Surah banner calligraphy (`Elgharib-QCF4SurahNames`).
  * Modern Arabic reading font for metadata and supplementary UI (`Alexandria`).

* **Zero-Setup Font Engine**:
  * Fonts auto-register seamlessly in memory on first access using CoreText.
  * No manual lifecycle registration or bundle-passing required in SwiftUI views.

* **Dedicated Quran UI Components**:
  * **Ayah Separator (`VerseFasel`)**: Displays accurate Arabic verse numbering inside authentic circular ayah markers.
  * **Surah Header View (`PageHeaderView`)**: Renders ornamental chapter frames and calligraphic Surah names.
  * **Page Metadata**: Clean presentation of Juz, Hizb, and Surah details.

* **Native RTL & Dynamic Sizing**:
  * Built from the ground up for right-to-left layout flow.
  * Fluid scaling to look balanced across both iPhone and iPad screens.

---

## 🔮 Upcoming Features (Roadmap)
We are actively working on key enhancements to expand personalization and Quran study capabilities:

### 1. Flexible Font System (`appFont`)
* **Custom App Font Support**: Developers can inject their own custom app typography while keeping the package's bundled fonts as the default fallback.
* **Selectable Quran Calligraphy**: User-facing options to switch between different Quranic typefaces.

### 2. UI & Color Customization
* **Custom Color Themes**: Full control over accent colors, ayah marker tints, frame borders, and reading background shades (light, dark, sepia, and night modes).
* **Custom Artwork & Frames**: Ability to replace default separator icons and header banners with custom image assets or vector paths.

### 3. Integrated Tafseer (التفسير)
* **Verse-by-Verse Commentary**: Interactive sheet or popover to read Tafseer for any selected ayah.
* **Offline Tafseer Data**: Pre-bundled and lightweight access to reputable interpretations.

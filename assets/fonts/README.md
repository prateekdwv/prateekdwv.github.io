# Website fonts

Self-hosted WOFF2 fonts. Adobe variable fonts are unmodified (TrueType outlines).
Roman files are preloaded; italic files load only when used. No external font service.

- Source Serif 4: [Adobe source-serif](https://github.com/adobe-fonts/source-serif/tree/5f220b17d27ed64873f22cde0dd593685387bd19), commit `5f220b17d27ed64873f22cde0dd593685387bd19`, from `WOFF2/VAR/SourceSerif4Variable-{Roman,Italic}.ttf.woff2`.
- Source Sans 3: [Adobe source-sans](https://github.com/adobe-fonts/source-sans/tree/87b37a2daaed80fcb8e8ccb0085c4d72ddade12e), commit `87b37a2daaed80fcb8e8ccb0085c4d72ddade12e`, from `WOFF2/VF/SourceSans3VF-{Upright,Italic}.ttf.woff2`.

All use the SIL Open Font License; the original licences are alongside the files.
Font roles and sizes are defined in `_tailwind/main.css`. Hindi uses Noto Serif Devanagari, with platform fallbacks; code and mathematical rendering keep their existing fonts.

- Noto Serif Devanagari: regular 400, Google Fonts distribution v34, Devanagari subset only, downloaded from [this pinned WOFF2 URL](https://fonts.gstatic.com/s/notoserifdevanagari/v34/x3dYcl3IZKmUqiMk48ZHXJ5jwU-DZGRSaQ4Hh2dGyFzPLcQPVbnRNeFsw0xRWb6uxTA-oz-BO0aFuw.woff2). Used for the Hindi name; no runtime Google Fonts requests.

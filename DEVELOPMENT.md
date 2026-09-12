# Local development

## Where things live

| Edit | Source |
| --- | --- |
| Homepage and biography | `index.md` |
| Papers, talks, news, contact details | The corresponding YAML file in `_data/` |
| Blog posts / unpublished drafts | `blog/_posts/` / `_drafts/` |
| Unlisted resources and reading log | `resource.md`, `reading.md`, `_data/reading.yml` |
| TikZ source and shared macros | `_diagrams/` |
| Page structure / repeated markup | `_layouts/` / `_includes/` |
| Styles / browser behaviour | `_tailwind/main.css` / `assets/js/` |
| RSS assembly / post-image detection | `_plugins/` |
| Diagram compiler / focused checks | `scripts/` / `tests/` |
| Public downloads and images | `papers/`, `slides/`, `img/`, `resume.pdf` |

`_site/`, `node_modules/`, `.jekyll-cache/`, `.cache/diagrams/`,
`assets/css/main.css`, `assets/diagrams/`, and `_data/diagrams.yml` are generated.
Do not edit or commit them. Lockfiles record dependencies; do not trim them by hand.
The small `blog/index.html`, `reflections.html`, and `resources.html` files preserve
old URLs through one redirect layout. Moving existing public files changes their URLs.

## Commands

Install the Ruby and Node.js dependencies after cloning the repository:

```sh
bundle install
npm ci
```

The expected Node.js version is recorded in `.nvmrc`. If you use `nvm`, select it with `nvm use` before installing dependencies.
Select the Ruby version in `.ruby-version` before running Bundler.

Build diagrams, the generated Tailwind stylesheet, and the website together:

```sh
npm run build
```

For local development, run the Tailwind watcher and Jekyll server in separate terminals:

```sh
npm run css:watch
```

```sh
bundle exec jekyll serve
```

The Tailwind input is `_tailwind/main.css`. Its generated `assets/css/main.css` output is intentionally excluded from Git.

Tailwind scans Jekyll layouts, includes, and HTML page templates, including
`writing/`. Keep complete class names in these templates. Markdown should use
includes when it needs a styled component. Shared typography and colours belong
in `_tailwind/main.css`; `--color-accent` is the rosy-copper colour.

## Updating the hero photo

Keep `img/ProfilePhoto.jpeg` as the original and JPEG fallback. After replacing it,
regenerate the responsive WebP files using `cwebp` (provided by the `webp` package):

```sh
cwebp -q 82 -m 6 -resize 640 0 img/ProfilePhoto.jpeg -o img/ProfilePhoto-640.webp
cwebp -q 82 -m 6 -resize 1280 0 img/ProfilePhoto.jpeg -o img/ProfilePhoto-1280.webp
cwebp -q 82 -m 6 -resize 1920 0 img/ProfilePhoto.jpeg -o img/ProfilePhoto-1920.webp
```

Keep these three generated images in version control alongside the original.
No conversion runs during normal Jekyll builds. Browsers select a WebP size using
the hero's `srcset` and `sizes`; browsers without WebP support use the JPEG.
If the original dimensions change, update the image's `width` and `height` in
`_includes/home-hero.html` too.

## Writing

Posts stay in `blog/_posts/`; their existing `/blog/` URLs are preserved. The
Writing index at `/writing/` shows five posts per page using `jekyll-paginate`.
For a long post, place `<!--more-->` after a complete paragraph near 300 words.
Short posts without a marker appear in full. Start body sections at `##`;
preview headings and local anchors are adjusted automatically for the index.
The index does not load article comments. Run `bundle install` after updating gems.

Social previews use the first image in the rendered post, including Markdown
reference images and HTML images. Pages and posts without images share only text;
there is no social-card generator or separate image catalogue.

Bluesky comments are kept for future use but currently disabled on all posts.
Enable them by adding `bluesky_post: https://bsky.app/profile/…/post/…` to a post
from the account identified by `bluesky_did` in `_config.yml`. Their script and
stylesheet load only on enabled posts. Keep the vendored component's licence.

## Subscriber updates

`/feed.xml` combines blog posts with deliberate announcements in
`_data/feed_updates.yml`. Leave that file as `[]` for blog-only updates. To add an
announcement, replace `[]` with a YAML list:

```yaml
- date: 2026-09-12
  type: paper
  title: An announcement title
  summary: A short description of the announcement.
  url: /research/
```

The date and title determine a manual item's stable identity; edit the summary
without changing them to retain that identity. Publication metadata never enters
the feed. The feed contains the latest 20 combined items; delivery and deduplication
are handled by the subscriber's RSS/email service.

## TikZ diagrams

Add a file such as `_diagrams/branching-program.tex` containing one
`\begin{tikzpicture} ... \end{tikzpicture}` environment. Use lowercase filenames
with numbers and hyphens. No catalogue entry, caption, or description is needed.
Only top-level `.tex` files are discovered; `preamble.tex` is reserved.
Include exactly one year comment, such as `% year: 2025`, in each diagram source.
Missing, duplicate, or invalid years fail the build. No separate registration is needed.

Define packages, TikZ libraries, styles, and macros in `_diagrams/preamble.tex`.
Put additional inputs in `_diagrams/shared/` and reference them as
`\input{shared/macros.tex}`. The builder copies these files into each isolated
compilation directory. Snippets should not contain document wrappers or depend
on files outside this source tree. LuaLaTeX runs without shell escape.

On Ubuntu, install the compiler and conversion dependencies:

```sh
sudo apt-get install texlive-luatex texlive-latex-extra texlive-pictures texlive-fonts-recommended dvisvgm ghostscript poppler-utils
```

`npm run build` generates outlined SVGs in `assets/diagrams/` and the catalogue
in `_data/diagrams.yml` before Jekyll runs. Both are ignored by Git. An empty
collection works without LaTeX installed and keeps the centred research page.
Shared dependencies, source edits, builder edits, and tool versions invalidate
the relevant compilation cache in `.cache/diagrams/`. Removing a source removes
its published SVG on the next successful build.

For previewing diagram edits, run `npm run diagrams:watch` alongside the CSS
watcher and Jekyll server. Start with `npm run build` before starting Jekyll.
The watcher checks for changes every second. Compilation failures report the
filename and compiler log and remove the manifest so a watching site does not
advertise stale diagrams. Fix the source and save again to retry. A normal build
fails immediately, preventing publication of a failed build. Multi-page output
and invalid SVG dimensions are rejected.

The research page randomly chooses candidates once per visit, then places one unique
diagram beside each year, top-aligned with the year heading, choosing only from
sources tagged with that year. Years with no matching diagram remain empty;
multiple diagrams for a year compete randomly for its single slot. Diagrams scale to fit
their year section without changing publication spacing. Each diagram has a full-column-width
frame with 19px padding; height follows the image proportions, up to
320px including padding, with no visible border. Phones show up to three afterward,
also limited to one per matching publication year, in publication-year order.
Only selected images are loaded; clicking one opens the full SVG. Filenames
provide accessible link labels, so choose descriptive names. Without JavaScript,
the publication list remains visible and the optional diagrams are omitted.

Run `npm run test:diagrams` to check real compilation, cache invalidation,
failure handling, and selection logic. Tests use temporary fixtures and never
publish example diagrams. CI runs these checks and `npm run build`; it still
does not deploy. Any deployment must publish the complete generated `_site/`
directory, rather than relying on GitHub Pages to compile TikZ from source.

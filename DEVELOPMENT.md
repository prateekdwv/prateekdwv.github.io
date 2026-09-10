# Local development

Install the Ruby and Node.js dependencies after cloning the repository:

```sh
bundle install
npm ci
```

The expected Node.js version is recorded in `.nvmrc`. If you use `nvm`, select it with `nvm use` before installing dependencies.

Build the generated Tailwind stylesheet before building the website:

```sh
npm run css:build
bundle exec jekyll build
```

For local development, run the Tailwind watcher and Jekyll server in separate terminals:

```sh
npm run css:watch
```

```sh
bundle exec jekyll serve
```

The Tailwind input is `_tailwind/main.css`. Its generated `assets/css/main.css` output is intentionally excluded from Git.

Tailwind scans Jekyll layouts, includes, and HTML page templates. Keep Tailwind classes in those component files and write complete class names instead of constructing them from Liquid fragments. Markdown should use Jekyll includes when it needs a styled component.

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

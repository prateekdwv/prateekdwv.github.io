# Local development

Install the Ruby and Node.js dependencies after cloning the repository:

```sh
bundle install
npm ci
```

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

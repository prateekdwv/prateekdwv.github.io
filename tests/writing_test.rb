require 'jekyll'
require 'jekyll-paginate'
require 'tmpdir'
require 'fileutils'
require 'rexml/document'

def check(value, message)
  raise message unless value
end

root = File.expand_path('..', __dir__)
Dir.mktmpdir('writing-test-') do |source|
  %w[_layouts _includes _data _plugins writing blog/index.html reflections.html resources.html contact.html tags.html feed.xml sitemap.xml robots.txt resource.md reading.md 404.html privacy.md].each do |name|
    target = File.join(source, name)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp_r(File.join(root, name), target)
  end
  posts = File.join(source, '_posts')
  FileUtils.mkdir_p(posts)
  ['', '/preview'].each do |baseurl|
    [0, 1, 5, 6, 10, 11].each do |count|
      FileUtils.rm_f(Dir[File.join(posts, '*')])
      count.times do |i|
        body = "Opening #{i}.\n\n## Shared heading\n\n1. First\n2. Second with *emphasis* and a footnote.[^1]\n\n[^1]: A reference.\n"
        body += "\n<!--more-->\n" if i.positive?
        body += "\nHidden remainder #{i}.\n" if i > 1
        body += "\n![Photo][photo]\n\n[photo]: {{ '/img/photo.png' | relative_url }}\n" if i == 2
        body += "\n<img src='https://example.org/photo.png?a=1&amp;b=2'>\n\n![Later](/img/later.png)\n" if i == 3
        body += "\n```html\n<img src='/img/example.png'>\n```\n" if i == 4
        File.write(File.join(posts, "2020-01-#{format('%02d', i + 1)}-post-#{i}.md"),
          "---\nlayout: post\ntitle: Post #{i}\nsubtitle: Summary #{i}\n---\n#{body}")
      end
      destination = File.join(source, '_site')
      config = Jekyll.configuration('source' => source, 'destination' => destination,
        'config' => File.join(root, '_config.yml'), 'baseurl' => baseurl, 'quiet' => true)
      Jekyll::Site.new(config).process
      pages = [1, (count / 5.0).ceil].max
      titles = []
      pages.times do |i|
        relative = i.zero? ? 'writing/index.html' : "writing/page#{i + 1}/index.html"
        html = File.read(File.join(destination, relative))
        canonical = "https://www.prateekdwivedi.in#{baseurl}/#{relative.delete_suffix('index.html')}"
        check(html.scan(/<link rel="canonical" href="([^"]+)"/).flatten == [canonical], 'Pagination canonical incorrect')
        titles.concat(html.scan(/<h2[^>]*><a[^>]*>(Post \d+)<\/a>/).flatten)
        check(!html.include?('Hidden remainder'), 'Full article text leaked into previews')
        check(html.include?('writing-pagination') == (pages > 1), 'Incorrect pagination visibility')
        ids = html.scan(/\bid="([^"]+)"/).flatten
        check(ids.uniq == ids, 'Duplicate preview IDs')
        html.scan(/href="#([^"]+)"/).flatten.each { |id| check(ids.include?(id), "Broken anchor #{id}") }
        check(!html.include?('bsky-comments.js'), 'Comments loaded on index')
        if count.positive?
          check(html.include?('<ol>') && html.include?('<em>emphasis</em>'), 'Preview formatting lost')
          check(html.include?('<h3 id="excerpt-'), 'Preview headings were not adjusted')
        else
          check(html.include?('No writing published yet.'), 'Empty state missing')
        end
        html.scan(/<a\b[^>]*href="([^"]+)"/).flatten.grep(%r{#{baseurl}/writing/}).each do |url|
          check(!url.include?('page1/'), 'Page one must use /writing/')
          check(File.file?(File.join(destination, url.delete_prefix(baseurl), 'index.html')), "Missing pagination target #{url}")
        end
      end
      check(titles == count.times.to_a.reverse.map { |i| "Post #{i}" }, 'Posts missing, duplicated, or out of order')
      combined = Dir[File.join(destination, 'writing/**/*.html')].map { |p| File.read(p) }.join
      check(combined.scan('class="writing-more"').size == [count - 2, 0].max, 'Read more shown for complete or empty-tail posts')
      {'blog' => '/writing/', 'reflections' => '/outreach/#talks', 'resources' => '/resource/', 'contact' => '/#contact', 'tags' => '/writing/'}.each do |old, target|
        redirect = File.read(File.join(destination, old, 'index.html'))
        check(redirect.include?("url=#{baseurl}#{target}"), "#{old} redirect broken")
        check(redirect.include?("href=\"https://www.prateekdwivedi.in#{baseurl}#{target.split('#').first}\""), 'Redirect canonical broken')
        check(redirect.include?("<a href=\"#{baseurl}#{target}\""), 'Redirect fallback broken')
      end
      count.times do |i|
        html = File.read(File.join(destination, "blog/post-#{i}/index.html"))
        expected = case i
                   when 2 then "https://www.prateekdwivedi.in#{baseurl}/img/photo.png"
                   when 3 then 'https://example.org/photo.png?a=1&amp;b=2'
                   end
        images = html.scan(/(?:property="og:image"|name="twitter:image") content="([^"]+)"/).flatten
        check(images == (expected ? [expected, expected] : []), "Wrong social image for post #{i}")
      end
      sitemap = REXML::Document.new(File.read(File.join(destination, 'sitemap.xml')))
      urls = REXML::XPath.match(sitemap, '//sm:loc', {'sm' => 'http://www.sitemaps.org/schemas/sitemap/0.9'}).map(&:text)
      expected_urls = ['/writing/', '/privacy/'] + (2..pages).map { |n| "/writing/page#{n}/" } + count.times.map { |i| "/blog/post-#{i}/" }
      check(urls.sort == expected_urls.map { |url| "https://www.prateekdwivedi.in#{baseurl}#{url}" }.sort, 'Sitemap URLs missing, duplicated, or incorrectly included')
      %w[resource/index.html reading/index.html 404.html].each do |path|
        check(File.read(File.join(destination, path)).include?('<meta name="robots" content="noindex">'), "Missing noindex on #{path}")
      end
      check(File.read(File.join(destination, 'robots.txt')).include?("Sitemap: https://www.prateekdwivedi.in#{baseurl}/sitemap.xml"), 'Robots sitemap incorrect')
      feed = File.read(File.join(destination, 'feed.xml'))
      check(feed.scan('<item>').size == count, 'Empty manual updates should keep feed blog-only')
      check(!feed.include?('Publication data should not appear'), 'Publication data leaked into feed')
      puts "Writing: #{count} posts, base URL #{baseurl.inspect} passed"
    end
  end

  File.write(File.join(source, '_data/feed_updates.yml'), <<~YAML)
    - date: 2026-01-20
      type: paper
      title: "Paper accepted to ITCS 2026"
      summary: "Our paper with <symbols> & details was accepted."
      url: /research/#paper
  YAML
  File.write(File.join(posts, '2025-01-01-post.md'), "---\nlayout: post\ntitle: Older Post\n---\nBody\n")
  destination = File.join(source, '_site')
  config = Jekyll.configuration('source' => source, 'destination' => destination,
    'config' => File.join(root, '_config.yml'), 'baseurl' => '/preview', 'quiet' => true)
  Jekyll::Site.new(config).process
  feed = File.read(File.join(destination, 'feed.xml'))
  check(feed.index('Paper accepted to ITCS 2026') < feed.index('Older Post'), 'Manual update not sorted before older post')
  check(feed.include?('<link>https://www.prateekdwivedi.in/preview/research/#paper</link>'), 'Manual update link not absolute')
  check(feed.include?('<guid isPermaLink="false">updates:2026-01-20:paper-accepted-to-itcs-2026</guid>'), 'Manual update GUID unstable')
  check(feed.include?('Our paper with &lt;symbols&gt; &amp; details was accepted.'), 'Manual update summary not XML escaped')
  puts 'Feed manual update scenario passed'
end

require 'jekyll'
require 'jekyll-paginate'
require 'tmpdir'
require 'fileutils'

def check(value, message)
  raise message unless value
end

root = File.expand_path('..', __dir__)
Dir.mktmpdir('writing-test-') do |source|
  %w[_layouts _includes _data writing blog/index.html feed.xml].each do |name|
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
        html.scan(/href="([^"]+)"/).flatten.grep(%r{#{baseurl}/writing/}).each do |url|
          check(!url.include?('page1/'), 'Page one must use /writing/')
          check(File.file?(File.join(destination, url.delete_prefix(baseurl), 'index.html')), "Missing pagination target #{url}")
        end
      end
      check(titles == count.times.to_a.reverse.map { |i| "Post #{i}" }, 'Posts missing, duplicated, or out of order')
      combined = Dir[File.join(destination, 'writing/**/*.html')].map { |p| File.read(p) }.join
      check(combined.scan('class="writing-more"').size == [count - 2, 0].max, 'Read more shown for complete or empty-tail posts')
      redirect = File.read(File.join(destination, 'blog/index.html'))
      check(redirect.include?("url=#{baseurl}/writing/"), 'Blog redirect broken')
      puts "Writing: #{count} posts, base URL #{baseurl.inspect} passed"
    end
  end
end

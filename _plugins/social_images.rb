Jekyll::Hooks.register :posts, :pre_render do |post|
  next if post.data["social_image"]

  source = File.read(post.path)
  markdown = source.match(/!\[[^\]]*\]\(([^)\s]+)(?:\s+["'][^"']*["'])?\)/)
  html = source.match(/<img\b[^>]*\bsrc=["']([^"']+)["']/i)

  image =
    if markdown && html
      markdown.begin(0) < html.begin(0) ? markdown[1] : html[1]
    elsif markdown
      markdown[1]
    elsif html
      html[1]
    end

  post.data["first_image"] = image if image
end

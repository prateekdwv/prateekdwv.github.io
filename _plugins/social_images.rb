require 'cgi'

module SocialImages
  # Jekyll has already converted Markdown images (including references) to HTML.
  def first_image(html)
    image = html.to_s[/<img\b[^>]*?\ssrc\s*=\s*["']([^"']+)["']/i, 1]
    return unless image

    image = CGI.unescapeHTML(image)
    # The metadata template applies absolute_url, so avoid adding baseurl twice.
    baseurl = @context.registers[:site].config['baseurl'].to_s.chomp('/')
    image.start_with?("#{baseurl}/") ? image.delete_prefix(baseurl) : image
  end
end

Liquid::Template.register_filter(SocialImages)

require "date"

module FeedItems
  def feed_items(site)
    posts = site.posts.respond_to?(:docs) ? site.posts.docs : site.posts
    posts = posts.map do |post|
      {
        "title" => post.data["title"],
        "description" => post_description(post),
        "date" => post.date,
        "url" => post.url,
        "guid" => post.url,
        "permalink" => true
      }
    end

    updates = Array(site.data["feed_updates"]).map do |item|
      date = Date.parse(item.fetch("date").to_s).to_time
      title = item.fetch("title")
      {
        "title" => title,
        "description" => item.fetch("summary"),
        "date" => date,
        "url" => item.fetch("url"),
        "guid" => "updates:#{item.fetch("date")}:#{slug(title)}",
        "permalink" => false
      }
    end

    (posts + updates).sort_by { |item| item["date"] }.reverse.first(20)
  end

  private

  def post_description(post)
    text = post.content.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
    text = text.split(/\s+/).first(50).join(" ")
    subtitle = post.data["subtitle"]
    subtitle ? "#{subtitle} — #{text}" : text
  end

  def slug(text)
    text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-+\z/, "")
  end
end

Liquid::Template.register_filter(FeedItems)

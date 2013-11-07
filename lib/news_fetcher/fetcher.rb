# lib requires.
require 'news_fetcher/news'
require 'constants'

# External requires.
require 'nokogiri'
require 'uri'
require 'open-uri'
require 'json'
require 'thread'

module NewsFetcher

  class Fetcher
    include Constants

    attr_reader :topics, :news

    def initialize
      @news = nil
      @lock = Mutex.new
    end

    def news_to_xml
      builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
        xml.bulletin {
          @news.each { |topic, news|
            xml.topic(id: topic) {
              news.each do |n|
                xml.news(id: n.id, video: n.video, audio: n.audio) {
                  xml.title_ n.title
                  xml.description_ n.description
                  xml.url_ n.url
                  xml.date_ n.date
                  xml.thumbnail_ n.thumbnail
                  xml.body_ n.body
                }
              end
            }
          } if @news
        }
      end
      builder.to_xml
    end

    def fetch_news_rss topic
      begin
        result = nil
        @lock.synchronize { result = Nokogiri::XML(open(FEED_URL_PREFIX + topic + FEED_URL_SUFFIX)) }
        result = result.search 'item'
        @lock.synchronize do
          @news ||= {}
          @news[topic] = []
        end
        result.each do |item|
          news = {}
          item.children.each do
            |node| news[node.node_name.to_sym] = node.text
            news[:thumbnail] = item.xpath('./media:thumbnail').last[:url] if news[:thumbnail]
          end
          next unless URL_WHITE_LIST.any? { |l| news[:guid].include?(l) } && news[:thumbnail]
          n = News.new(
            news[:guid][/[0-9]+(#|$)/].delete('#'),
            news[:guid][/^[^\#]*/].delete('#'),
            news[:title],
            news[:description],
            '',
            topic,
            DateTime.strptime(news[:pubDate][5..news[:pubDate].length], "%d %b %Y %k:%M:%S").to_time.to_i,
            news[:thumbnail])
          begin
            page = Nokogiri::HTML(open(news[:link]), nil, 'UTF-8' )
            n.parse_news!(page)
            if(n.audio || n.video || (!n.body.empty?))
              @lock.synchronize { @news[topic] << n }
            end
          rescue Exception
          end
        end
      rescue
      end
      return @news[topic]
    end

    def fetch_all_news_rss
      threads = []
      FEED_TOPICS.each do |topic|
        t = Thread.new { fetch_news_rss(topic) }
        threads << t
      end
      threads.each { |thread| thread.join }
      return @news
    end
  end

end

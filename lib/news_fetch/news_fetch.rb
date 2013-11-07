#encoding: UTF-8

# lib requires.
require 'news_fetch/news'

# External requires.
require 'nokogiri'
require 'uri'
require 'open-uri'
require 'singleton'
require 'json'
require 'thread'

module NewsFetch

  class Fetcher
    include Singleton

    private
    TOPICS_URL = 'http://api.bbcnews.appengine.co.uk/topics'
    TOPICS_ROOT = :topics
    NEWS_URL = 'http://api.bbcnews.appengine.co.uk/stories/'
    NEWS_ROOT = :stories
    URL_WHITE_LIST = %w[www.bbc.co.uk/news/ www.bbc.co.uk/sport/]
    FEED_URL_PREFIX = 'http://feeds.bbci.co.uk/news/'
    FEED_URL_SUFFIX = '/rss.xml'
    FEED_TOPICS = %w[world uk business politics health education science_and_environment technology entertainment_and_arts]

    public
    attr_reader :topics, :news

    def initialize
      @topics = nil
      @news = nil
      @lock = Mutex.new
    end

    def topics_to_xml
      builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
        xml.topics {
          @topics.each { |topic| xml.topics(id: topic[:id], title: topic[:title]) } if @topics
        }
      end
      builder.to_xml
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

    def fetch_topics
      begin
        # fetch array of topics
        @topics = JSON.parse(Nokogiri::HTML(open(TOPICS_URL)), { :symbolize_names => true })[TOPICS_ROOT]
        @new = {}
        if @topics.empty?
          @topics = nil
          @news = nil
        end
      rescue
        @topics = nil
        @news = nil
      end
      return !!@topics
    end

    def fetch_news topic
      begin
        result = JSON.parse(Nokogiri::HTML(open(NEWS_URL + topic)), { :symbolize_names => true })[NEWS_ROOT]
        @lock.synchronize do
          @news ||= {}
          @news[topic] = []
        end
        result.each do |news|
          next unless URL_WHITE_LIST.any? { |l| news[:link].include?(l) }
          n = News.new(
            news[:link][/[0-9]+(#|$)/].delete('#'),
            news[:link][/^[^\#]*/].delete('#'),
            news[:title],
            news[:description],
            '',
            topic,
            news[:published],
            news[:thumbnail])
          begin
            page = Nokogiri::HTML(open(news[:link]), nil, 'UTF-8' )
            n.parse_news!(page)
            if(n.audio || n.video || (!n.body.empty?))
              @lock.synchronize { @news[topic] << n }
            end
          rescue Exception => e
            puts e
          end
        end
      rescue
      end
      return @news[topic]
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
          rescue Exception => e
            puts e, e.backtrace
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

    def fetch_all_news
      if @topics
        threads = []
        @topics.each do |topic|
          t = Thread.new { fetch_news(topic[:id]) }
          threads << t
        end
        threads.each { |thread| thread.join }
      end
      return @news
    end

    def list_all_sources
      counter = {}
      @news.each do |key, topic|
        topic.each do |news|
          url = news.url[/^http:\/\/[^\/]*/]
          counter[url] ||= 0
          counter[url] += 1
        end
      end
      counter
    end
  end

end

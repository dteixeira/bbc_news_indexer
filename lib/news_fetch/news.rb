#encoding: UTF-8

# External requires.
require 'nokogiri'

module NewsFetch

  class News
    attr_accessor :title, :body, :url, :description, :id, :topic,
      :video, :audio, :thumbnail, :date

    def initialize(*args)
      @id, @url, @title, @description, @body, @topic, @date, @thumbnail = args
      @audio = false
      @video = false
    end

    def parse_news!(page)
      @body = ''

      # Check for media.
      check_media(page)

      # Parse and clean the news' body.
      if(page.at_css('div.story-body div.article'))
        page = page.css('div.story-body div.article > p')
      elsif(page.at_css('div.story-body div.map-body'))
        page = page.css('div.story-body div.map-body > p') + page.css('div.story-body div.map-body div.extra-content > p')
      else
        page = page.css('div.story-body > p')
      end
      page.each { |child| @body << clear_line(child) }
    end

    private
    def clear_line(line)
      return (line.content.strip().gsub(/\s+/, ' ').gsub('&', 'and')) + ' '
    end

    def check_media(page)
      check_audio(page)
      check_video(page)
    end

    def check_audio(page)
      @audio = false
      if(/^AUDIO/ =~ @title)
        @audio = true
      else
        @audio = true if page.at_xpath("//*[contains(@class, 'audioInStory')]")
      end
    end

    def check_video(page)
      @video = false
      if(/^VIDEO/ =~ @title)
        @video = true
      else
        @video = true if page.at_xpath("//*[contains(@class, 'videoInStory')]")
      end
    end
  end

end

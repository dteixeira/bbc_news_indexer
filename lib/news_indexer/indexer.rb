# External requires.
require 'nokogiri'
require 'rsolr'

# lib requires.
require 'constants'

module NewsIndexer

  class Indexer
    include Constants

    def initialize
      @solr = RSolr.connect :url => SOLR_SERVER_URL
    end

    def index_all_news files
      files.each do |f|
        index_news f
      end
      nil
    end

    def index_news file
      File.open file, 'r' do |f|
        xml = Nokogiri::XML f

        # For performance reasons, a local version of the index
        # is kept. This makes the indexing process about 50 to
        # 150 times faster than searching and commiting for
        # every document.
        docs = {}

        # Iterate through all topics.
        xml.xpath('//topic').each do |topic|

          # Skip unwanted topics.
          next unless FEED_TOPICS.include? topic.xpath('./@id').text

          # Iterate through all news.
          topic.xpath('./news').each do |news|

            # Build document format.
            args = {}
            news.children.each do |node|
              args[node.node_name.to_sym] = node.text
            end
            args[:date] = Time.at(args[:date].to_i).strftime('%FT%TZ')
            args[:video] = news.xpath('./@video').text
            args[:audio] = news.xpath('./@audio').text
            args[:id] = news.xpath('./@id').text
            args[:topics] = [topic.xpath('./@id').text]
            args.delete :text

            # News with no title, description or body are discarded.
            next unless args[:title] != nil && !args[:title].empty?
            next unless args[:description] != nil && !args[:description].empty?
            next unless args[:body] != nil && !args[:body].empty?

            # Check if document really needs to be indexed:
            # if the new document was already indexed and
            # doesn't bring any new information, it isn't
            # indexed again.
            if docs[args[:id]] == nil
              response = @solr.get 'select', :params => { :q => 'id:' + args[:id] }
              if response['response']['numFound'] == 1
                next if response['response']['docs'][0]['topics'].include? args[:topics][0]
                args[:topics].concat response['response']['docs'][0]['topics']
              end
            else
              next if docs[args[:id]][:topics].include? args[:topics][0]
              args[:topics].concat docs[args[:id]][:topics]
            end
            docs[args[:id]] = args
          end
        end

        # Add and commit all documents.
        @solr.add docs.values
        @solr.commit
      end if File.exists? file
      nil
    end

    def delete_index
      @solr.delete_by_query '*:*'
      @solr.commit
      nil
    end

  end

end

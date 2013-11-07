# Add the lib directory to the load path.
$:.unshift File.expand_path '../../lib', __FILE__

# Require needed files.
require 'news_fetcher/fetcher'
require 'news_indexer/indexer'
require 'constants'

class BbcNewsIndexer
  include Constants

  def initialize
    setup_log_dir
    @fetcher = NewsFetcher::Fetcher.new
    @indexer = NewsIndexer::Indexer.new
  end

  def fetch_news
    filename = Time.now.strftime('%Y%m%d%H%M%S') + '.xml'
    @fetcher.fetch_all_news_rss
    File.open(File.join(NEWS_LOGS_DIRECTORY, filename), 'w:UTF-8') do |file|
      file.write(@fetcher.news_to_xml)
    end
    filename
  end

  def index_all_news
    files = Dir.glob(File.join NEWS_LOGS_DIRECTORY, '*.xml')
    @indexer.index_all_news files
  end

  def fetch_and_index_news
    file = fetch_news
    index_news file
  end

  def index_news file
    @indexer.index_news File.join(NEWS_LOGS_DIRECTORY, file)
  end

  def delete_index
    @indexer.delete_index
  end

  private
  def setup_log_dir
    if Dir[NEWS_LOGS_DIRECTORY] == []
      Dir.mkdir NEWS_LOGS_DIRECTORY, 0700
    end
  end
end

# Run a simple fetch and index task, if
# this file is executed as a script.
if __FILE__ == $0
  bbc = BbcNewsIndexer.new
  bbc.fetch_and_index_news
end

module Constants

  # Fetcher constants.
  URL_WHITE_LIST = %w[www.bbc.co.uk/news/ www.bbc.co.uk/sport/]
  FEED_URL_PREFIX = 'http://feeds.bbci.co.uk/news/'
  FEED_URL_SUFFIX = '/rss.xml'
  FEED_TOPICS = %w[world uk business politics health education science_and_environment technology entertainment_and_arts]

  # Indexer constants.
  SOLR_SERVER_URL = 'http://localhost:8080/solr'

  # Program file constants.
  NEWS_LOGS_DIRECTORY = File.expand_path("../../news_logs", __FILE__)

end

# Add the lib directory to the load path.
$:.unshift File.expand_path '../../lib', __FILE__

# Require needed files.
require 'news_fetch/news_fetch'

module BbcNewsIndexer

  class Indexer
  end

end

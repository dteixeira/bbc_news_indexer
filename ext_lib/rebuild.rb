require File.expand_path '../../lib/bbc_news_indexer.rb', __FILE__

bbc = BbcNewsIndexer.new
puts 'Reseting the index...'
bbc.delete_index
puts 'Indexing all news...'
bbc.index_all_news
puts 'Done.'

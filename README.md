# BbcNewsIndexer

This project makes it possible to poll news from several BBC News sites. This information can
also be automatically indexed in a Solr server.

The project was written for Ruby 2.0.0, so no backwards compatibility is assured (though it should
work in any version from 1.9.3).

## Installation

Clone this repository to your machine and go to its root.

Use bundler to install any gem dependencies.

    bundle install

## Usage

For the "periodic poll and index" behaviour, just add the file 'ext\_lib/fetch.sh' to your
system's startup scripts.

Any other behaviour, including indexing all past data and deleting the index, can be
achieved with any ruby interpreter or custom script (pry is added in the Gemfile already).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

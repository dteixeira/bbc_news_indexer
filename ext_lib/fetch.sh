#!/bin/bash
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
sleep 5m
while :
do
  echo "Starting fetch..."
  cd /home/diogo/Repositories/Ruby/bbc_news_indexer/ && ruby ./lib/bbc_news_indexer.rb
  echo "Done. Sleeping..."
  sleep 120m
done

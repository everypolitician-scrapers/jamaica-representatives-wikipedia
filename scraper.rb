#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def date_from(text)
  return if text.to_s.empty?
  Date.parse(text).to_s rescue binding.pry
end

def ocd_idify(text)
  text.downcase.tr(' ', '_')
end

def scrape_list(term, url)
  noko = noko_for(url)

  current_parish = ''
  noko.xpath('//h2[contains(span,"Constituencies and MPs")]/following-sibling::table[1]/tr[td]').each do |tr|
    tds = tr.css('td')

    unless (parish = tds[0].css('a').text).empty?
      current_parish = parish.sub(' Parish', '')
    end
    constituency = tds[1].css('a').text
    area_id = 'ocd-division/country:ja/parish:%s/constituency:%s' % [ocd_idify(current_parish), ocd_idify(constituency)]

    data = {
      name:     tds[2].text,
      wikiname: tds[2].xpath('.//a[not(@class="new")]/@title').text,
      party:    tds[3].text.tidy,
      parish:   current_parish,
      area:     constituency,
      area_id:  area_id,
      term:     term,
      source:   url,
    }
    ScraperWiki.save_sqlite(%i(name party term), data)
  end
end

scrape_list(2011, 'https://en.wikipedia.org/w/index.php?title=Constituencies_of_Jamaica&oldid=707616860')
scrape_list(2016, 'https://en.wikipedia.org/wiki/Constituencies_of_Jamaica')

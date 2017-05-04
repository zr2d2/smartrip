require 'pdf-reader'
require 'open-uri'
require 'csv'

class Ridership
  def initialize
    @boardings = {}
    @cells = []
  end

  def parse
    file = '2015_historical_rail_ridership.pdf'
    io = open file
    reader = PDF::Reader.new io

    reader.pages.each do |page|
      lines = page.text.split("\n")
      lines.each do |line|
        skip_words = %w(Metrorail Passenger Nov Station * Revised nil 8)
        cells      = line.split

        first = cells.first
        if skip_words.include?(first) || first.is_a?(NilClass) || cells[0].to_i.eql?(134)
          next
        end
        puts "cells: #{cells.inspect}"

        #create station name
        station_name = cells.slice(0..2)
        station_name.delete('-')
        station_name.reject!{|s| s.to_i > 0}
        station_name = station_name.join(' ')
        puts station_name.inspect

        current_year_boardings = cells.reverse[0].delete(',')
        last_year_boardings    = cells.reverse[1].delete(',')
        diff = (current_year_boardings.to_f - last_year_boardings.to_f)/last_year_boardings.to_f*100 unless last_year_boardings.eql? 0
        diff ||= 0
        diff = diff.round 2

        @cells << cells
        @boardings[station_name] = [current_year_boardings, diff]
      end
    end
  end

  def import_csv
    file = '2016_metro_boardings.csv'

    CSV.foreach(file) do |row|
      station_name = row.first
      next if station_name.eql? 'Station'

      puts station_name.inspect

      current_year_boardings = row.reverse[0].delete(',')
      last_year_boardings    = row.reverse[1].delete(',')
      diff = (current_year_boardings.to_f - last_year_boardings.to_f)/last_year_boardings.to_f*100 unless last_year_boardings.eql? 0
      diff ||= 0
      diff = diff.round 2

      @cells << row
      @boardings[station_name] = [current_year_boardings, diff]
    end
  end

  def wiki(station)
    boarding = @boardings[station]

    unless boarding
      notice = recomend station
      puts notice
      return
    end

    current_year = delimite(boarding[0])
    diff         = boarding[1]

    puts "| passengers = #{current_year} daily <ref>{{cite web |url=https://www.wmata.com/initiatives/plans/upload/2016_historical_rail_ridership.pdf |title=Metrorail Average Weekday Passenger Boardings |publisher=WMATA |accessdate=2017-04-26}}</ref>
| pass_year = 2016
| pass_percent = #{diff}"
  end

  def template(station)
    boarding = @boardings[station]

    unless boarding
      notice = recomend station
      puts notice
      return
    end

    current_year = delimite(boarding[0])
    diff         = boarding[1]

    puts "{{rail pass box |system=Metro | passengers = #{current_year} daily <ref>{{cite web |url=https://www.wmata.com/initiatives/plans/upload/2016_historical_rail_ridership.pdf |title=Metrorail Average Weekday Passenger Boardings |publisher=WMATA |accessdate=2017-04-22}}</ref> |pass_year=2016 |pass_percent=#{diff}}}"
  end

  def recomend(station)
    stations = @boardings.keys.select{|name| name =~ /#{station}/}
    recomendations = stations.join ','
    "not a station did you mean #{recomendations}"
  end

  def delimite(num)
    num.to_s.reverse.gsub(/(\d{3})(?=\d{2})/, '\\1,').reverse
  end

  def to_csv
    CSV.open '2015_metro_boardings.csv', 'w' do |csv|
      @cells.each do |cell|
        csv << cell
      end
    end
  end

end

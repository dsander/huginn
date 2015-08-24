require 'json'
require 'pp'
class Analyzer
  def initialize(filename, generation)
    @filename = filename
    @generation = generation == nil ? nil : generation.to_i
  end

  def analyze
    data = []
    File.open(@filename) do |f|
      f.each_line do |line|
        parsed = JSON.parse(line)
        data << parsed if @generation == nil || @generation == parsed['generation']
      end
    end
    if @generation
      data.group_by{|row| "#{row["file"]}:#{row["line"]}"}
        .sort{|a,b| b[1].count <=> a[1].count}
        .each do |k,v|
          puts "#{k} * #{v.count}"
        end

    else
      data.group_by{|row| row["generation"]}
          .sort{|a,b| a[0].to_i <=> b[0].to_i}
          .each do |k,v|
            puts "generation #{k} objects #{v.count}"
          end
    end
  end
end

Analyzer.new(ARGV[0], ARGV[1]).analyze
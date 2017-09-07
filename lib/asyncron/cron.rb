# frozen_string_literal: true

module Asyncron
  module Cron
    extend self

    MINUTE = (0..59).to_a
    HOUR = (0..23).to_a
    MONTHDAY = (1..31).to_a
    MONTH = (1..12).to_a
    WEEKDAY = (1..7).to_a
    YEAR = (1900..3000).to_a

    POSITION = %w(minute hour monthday month weekday year)

    def parse(expr)
      expr.split(/[\s\t]+/).map.with_index { |e, i| transform(i, e) }
    end

    def validate(value)
      value =~ /^((\d+(-\d+)?(,\d+(-\d+)?)*)(\/\d+)?|\*(\/\d+)?)$/
    end

    def transform(pos, value)
      unless validate(value)
        raise ArgumentError.new("invalid format for #{POSITION[pos]}")
      end
      return divide(value) do |no_divide|
        range = single_num(no_divide) || extend_asterisk(pos, value)
        next range if range
        next filter(expand(pos), value)
      end
    end

    private

    def expand(pos)
      const_get(POSITION[pos].upcase)
    end

    def single_num(value)
      return if value !~ /^\d+$/
      return [value.to_i]
    end

    def extend_asterisk(pos, value)
      return if value != "*"
      return expand(pos)
    end

    def filter(range, value)
      values = value.split(",")
      last_value = values.pop
      values.push(last_value.match(/^([^\/]+)/).captures.first)
      return range unless values.all? { |v| v =~ /^\d+(-\d+)?$/ }
      values = values.reduce([]) do |acc, value|
        min, _, max = value.match(/^(\d+)(-(\d+))?$/).captures
        if max.nil?
          acc << min.to_i
        else
          acc += (min.to_i..max.to_i).to_a
        end
        next acc
      end
      return range & values
    end

    def divide(value)
      arg, _, divider = value.match(/^([^\/]+)(\/(\d+))?$/).captures
      range = yield(arg)
      return range if divider !~ /^\d+$/
      divider = divider.to_i
      return range.each.with_index.reduce([]) do |acc, (r, i)|
        acc << r if i % divider == 0
        next acc
      end
    end
  end
end

# frozen_string_literal: true

module Asyncron
  module Schedule
    extend self

    def map(time = nil)
      time = Time.now + 60 if time.nil?
      %w(min hour day month wday year).map { |m| time.send(m) }
    end

    def next(expr)
      cron = Cron.parse(expr)
      current = map
      year(cron, current) do
        month(cron, current) do
          day(cron, current) do
            hour(cron, current) do
              min(cron, current) do
                Time.new(current[5], current[3], current[2], current[1],
                  current[0])
              end
            end
          end
        end
      end
    end

    private

    def detect_next_weekday(cron, from)
      while(!cron[4].include?(from.wday))
        next_day = cron[2].detect { |d| d > from.day }
        if next_day
          from += (next_day - from.day) * 24 * 60 * 60
          next
        end
        next_month = cron[3].detect { |m| m > from.month }
        if next_month
          from = Time.new(from.year, next_month, cron[2].first,
            from.hour, from.min)
          next
        end
        next_year = cron[5].detect { |y| y > from.year }
        if next_year
          from = Time.new(next_year, cron[3].first, cron[2].first,
            from.hour, from.min)
          next
        else
          from = nil
          break
        end
      end
      return from
    end

    def year(cron, current)
      if cron[5].include?(current[5])
        return yield
      else
        next_year = cron[5].detect { |y| y > current[5] }
        return if next_year.nil?
        min, hour, day, month = cron[0..3].map(&:first)

        return detect_next_weekday(cron,
          Time.new(next_year, month, day, hour, min))
      end
    end

    def month(cron, current)
      if cron[3].include?(current[3])
        return yield
      else
        next_year = current[5]
        next_month = cron[3].detect { |m| m > current[3] }
        if next_month.nil?
          next_year = cron[5].detect { |y| y > next_year }
          return if next_year.nil?
          next_month = cron[3].first
        end
        min, hour, day = cron[0..2].map(&:first)
        return detect_next_weekday(cron,
          Time.new(next_year, next_month, day, hour, min))
      end
    end

    def day(cron, current)
      if cron[2].include?(current[2]) && cron[4].include?(current[4])
        return yield
      else
        next_year = current[5]
        next_month = current[3]
        next_day = cron[2].detect { |d| d > current[2] }
        if next_day.nil?
          next_day = cron[2].first
          next_month = cron[3].detect { |m| m > next_month }
          if next_month.nil?
            next_year = cron[5].detect { |y| y > next_year }
            return if next_year.nil?
            next_month = cron[3].first
          end
        end
        min, hour = cron[0..1].map(&:first)
        return detect_next_weekday(cron,
          Time.new(next_year, next_month, next_day, hour, min))
      end
    end

    def hour(cron, current)
      if cron[1].include?(current[1])
        return yield
      else
        next_year = current[5]
        next_month = current[3]
        next_day = current[2]
        next_hour = cron[1].detect { |h| h > current[1] }
        if next_hour.nil?
          next_hour = cron[1].first
          next_day = cron[2].detect { |d| d > current[2] }
          if next_day.nil?
            next_day = cron[2].first
            next_month = cron[3].detect { |m| m > next_month }
            if next_month.nil?
              next_year = cron[5].detect { |y| y > next_year }
              return if next_year.nil?
              next_month = cron[3].first
            end
          end
        end
        min = cron[0].first
        return detect_next_weekday(cron,
          Time.new(next_year, next_month, next_day, next_hour, min))
      end
    end

    def min(cron, current)
      if cron[0].include?(current[0])
        return yield
      else
        next_year = current[5]
        next_month = current[3]
        next_day = current[2]
        next_hour = current[1]
        next_min = cron[0].detect { |m| m > current[0] }
        if next_min.nil?
          next_min = cron[0].first
          next_hour = cron[1].detect { |h| h > current[1] }
          if next_hour.nil?
            next_hour = cron[1].first
            next_day = cron[2].detect { |d| d > current[2] }
            if next_day.nil?
              next_day = cron[2].first
              next_month = cron[3].detect { |m| m > next_month }
              if next_month.nil?
                next_year = cron[5].detect { |y| y > next_year }
                return if next_year.nil?
                next_month = cron[3].first
              end
            end
          end
        end
        return detect_next_weekday(cron,
          Time.new(next_year, next_month, next_day, next_hour, next_min))
      end
    end
  end
end

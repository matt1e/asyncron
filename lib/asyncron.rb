# frozen_string_literal: true

require "redis"
require "json"

require "asyncron/cron"
require "asyncron/schedule"

module Asyncron
  extend self

  DEFAULT_OPTS = {
    redis: Redis.new,
    key: "sorted_set_asyncron/%{callback_str}"
  }

  def insert(opts = {}, callback_str, payload)
    unless payload.key?(:expr)
      raise RuntimeError.new("#{payload.inspect} has no :expr key")
    end
    time = Schedule.next(payload[:expr])
    if time.nil?
      raise RuntimeError.new("#{payload[:expr]} for #{callback_str} and " \
        "#{payload.inspect} has no future execution time")
    end
    set_key = key(opts, callback_str)
    return if redis(opts).zscore(set_key, payload.to_json)
    return redis(opts).zadd(set_key, time.to_i, payload.to_json)
  end

  def remove(opts = {}, callback_str, payload)
    redis(opts).zrem(key(opts, callback_str), payload.to_json)
  end

  def due(opts = {})
    t = Time.now
    redis(opts).keys(key(opts, "*")).each do |set_key|
      cb = callback(set_key.split("/").last)
      redis(opts).zrangebyscore(set_key, 0, t.to_i).each do |payload|
        parsed_payload = JSON.parse(payload, symbolize_names: true)
        cb.call(parsed_payload)
        redis(opts).zrem(set_key, payload)
        insert(opts, set_key.split("/").last, parsed_payload)
      end
    end
  end

  def redis(opts)
    opts[:redis] || DEFAULT_OPTS[:redis]
  end

  def key(opts, callback_str)
    (opts[:key] || DEFAULT_OPTS[:key]) % {callback_str: callback_str}
  end

  def callback(callback_str)
    mod, method = callback_str.split(".")
    mods = mod.split("::")
    ref = mods.reduce(Object) { |acc, m| acc.const_get(m) }
    return ref.method(method)
  end
end

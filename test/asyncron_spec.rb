# frozen_string_literal: true

module Callbacker
  def self.with(cb)
    @cb = cb
    yield
    @cb = nil
  end

  def self.callback(payload)
    @cb.call(payload)
  end
end

describe "asyncron" do
  before do
    @callback = "Callbacker.callback"
    @payload = {moo: "bar"}
    @redis = Asyncron::DEFAULT_OPTS[:redis]
    @key = Asyncron.key({}, @callback)
  end

  after do
    @redis.keys(Asyncron.key({}, "*")).each { |k| @redis.del(k) }
    %w(callback payload redis key).each do |i|
      remove_instance_variable("@#{i}")
    end
  end

  describe "insert" do
    it "inserts a new entry with payload at the next possible slot" do
      assert_nil @redis.zscore(@key, @payload.to_json)
      t = Time.now
      t = Time.new(t.year, t.month, t.day, t.hour, t.min).to_i + 60
      Asyncron.insert("* * * * * *", @callback, @payload)
      assert_equal t, @redis.zscore(@key, @payload.to_json)
    end
  end

  describe "due" do
    it "sends the payload to the callback module" do
      @redis.zadd(@key, Time.now.to_i, @payload.to_json)
      ran = false
      Callbacker.with(
        ->(payload) { ran = true; assert_equal payload, @payload }
      ) { Asyncron.due }
      assert ran
    end

    it "does not send the payload for future work" do
      @redis.zadd(@key, Time.now.to_i + 5, @payload.to_json)
      ran = false
      Callbacker.with(->(payload) { ran = true; }) { Asyncron.due }
      refute ran
    end
  end
end

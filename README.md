# asyncron

Asynchronous execution of cron jobs

# Format

The gem is using the basic cron format of minute-hour-day-month-weekday-year.
Please consult the crontab documentation for information how to use it.

# Usage

The gem takes a cron statement, a callback and a payload to store in redis.
Add it like this:

```ruby
  require "asyncron"

  module Scoped
    module Callback
      def self.work(payload)
        p payload
      end
    end
  end

  Asyncron.insert("Scoped::Callback.work", {my: "payload", expr: "* * * * * *"})
```

The gem detects the next execution of the cron and stores that on a timer.
When it's due, it will evaluate the callback and execute it with the given
payload.

To do this, repeatedly execute this:

```ruby
  Asyncron.due
```

Once a cron is due and the callback executed, it evaluates the next execution
date and inserts it back into redis. The cycle repeats.

The reason why it never executes on its is mainly to control execution times
on programming side. The execution when a cron is due won't run in threads, so
payload processing should not take an eternity. Use delayed job or another
gem to process.

When a cron should be removed completely, use the callback and payload:

```ruby
  Asyncron.remove("Scoped::Callback.work", {my: "payload", expr: "* * * * * *"})
```

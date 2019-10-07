# Future DateTime UTC timestamps

If you are certain that all of your timestamps are in the past, then you can
safely ignore this guide.

If you are working with timestamps that are in the future, and those timestamps
are inside countries with governing bodies that have the ability to change
timezone rules, including daylight savings, then you may want to consider your
timestamp storage strategy. Shortly, it's not foolproof to convert the timestamp
to UTC and store only that DateTime.

## Rules Change

Consider this scenario: It's currently year 2019 and you receive a timestamp for
a user located in Washington, USA for July 4, 2022. You convert it to UTC and
store it in your database.

Today (in year 2019), Washington state recognizes Daylight Savings Time and it
shifts back and forth an hour over the year. Since the timestamp is in the
summer, it's shifted back an hour.

In 2020, Washington enacts a new law that declares that they will no longer be
participate in Daylight Savings Time and permanently stay in Daylight Savings;
meaning it's always shifted forward one hour year-round.

You've already stored your timestamps in the future converted to UTC using the
old rules. How do you know to fix all your timestamps in your database for users
in Washington state?

## What is our context?

There are 3 elements at play:

1. You need a consistent timestamp field for database queries (opposed to
   strings). Usually this is UTC timestamps.
2. The user provided a timestamp based on their location, and looked at the
   clock on their desk when filling in the form in your web app.
3. The provided timestamp is based on the location the user is in, and that
   location follows a set of rules of how time changes throughout the year.

We need to store timestamps in a database column made for timestamps so we can
achieve #1. This can be more complicated given your database, but using Postgres
as an example, it internally converts to UTC and queries against that. If you're
using Ecto as your data mapper, it must always be in UTC before storage.

If the law changes between now and the future timestamp, we've lost the correct
wall time for the user in #2.

When we immediately convert to UTC, we lose the context in #3.

## Storage Strategy

Store the user's provided timestamp and timezone separately from the converted
UTC. For example:

```elixir
field :my_timestamp_utc, :utc_datetime
field :my_timestamp_tz, :string
field :my_timestamp_wall, :naive_datetime
```

Since we're making `my_timestamp_utc` a `:utc_datetime`, we are affirming we
have the timezone information of UTC. Since we're making `my_timestamp_wall` a
`:naive_datetime`, we're affirming we do not have the timezone.

Once you have these 3 pieces of context, you can periodically update and verify
changes. It would be good to update your UTC timestamps whenever your tzdata
files are updated. If the walltime + timezone is reconverted to UTC and is
different from your stored UTC timestamp, then you know the rules have changed
since storage. Update the UTC timestamp and perhaps notify the customer to
ensure the intentions are still correct (for example, did they already know of
the upcoming law change and anticipate it?).

## Credits

[http://www.creativedeletion.com/2015/03/19/persisting_future_datetimes.html](http://www.creativedeletion.com/2015/03/19/persisting_future_datetimes.html)

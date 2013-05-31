require 'redis'
require 'json'
require 'cinch'
require 'thread'
require './vendors/groupme/lib/groupme.rb'

irc_channel = "#nycstartupbus2013"
redis = Redis.new
groupme = GroupMe::Client.new :token => 'e717aa60aacc01307bdd427ebdd2d7d9'
nick = 'nycsb-gm'
group_id = 3778431
bot_id = 'b628fd8b4ad7e2e51f7f067152'

trap(:INT) { puts; exit }

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.freenode.org"
    c.nick     = nick
    c.channels = [irc_channel]

    # Who should be able to access these plugins
    @admin = "ksolo"
  end

  helpers do
    def is_admin?(user)
      true if user.nick == @admin
    end
  end

  on :message, /^#{nick}: get_users/ do |m, who, text|
    group = groupme.group group_id

    members = []
    group.members.each do |member|
      members.push member.nickname
    end

    m.reply members.join(', ')
  end

  on :message, /^#{nick}: send (.+)/ do |m, text|
    groupme.bot_message bot_id, "#{m.user.nick} said #{text}"
  end
end

the_bot = Thread.new { bot.start }

begin
  irc_target = Cinch::Target.new irc_channel, bot

  redis.subscribe(:nycstartupbus2013) do |on|
    on.subscribe do |channel, subscriptions|
      puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
    end

    on.message do |channel, message|
      irc_target.send message
      redis.unsubscribe if message == "exit"
    end

    on.unsubscribe do |channel, subscriptions|
      puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
    end
  end
rescue Redis::BaseConnectionError => error
  puts "#{error}, retrying in 1s"
  sleep 1
  retry
end

require 'json'
require 'open-uri'
require 'slack-ruby-client'

class User
  attr_accessor :id, :name, :post_sum, :reaction_sum

  def initialize(id, name, post_sum, reaction_sum)
    @id= id
    @name = name
    @post_sum = post_sum
    @reaction_sum = reaction_sum
  end

  def self.post_result(users)
    top5 = users.sort_by(&:post_sum).reverse[0..4]
    text = top5.map do |user|
      "#{user.name}: #{user.post_sum}"
    end
    current_time = Time.new.strftime("%-m月%-d日 %-H時%-M分")
    "#{current_time}時点での投稿数ランキング\n" + text.join("\n")
  end

  def self.reaction_result(users)
    top5 = users.sort_by(&:reaction_sum).reverse[0..4]
    text = top5.map do |user|
     "#{user.name}: #{user.reaction_sum}"
    end
    current_time = Time.new.strftime("%-m月%-d日 %-H時%-M分")
    "#{current_time}時点でのリアクション数ランキング\n" + text.join("\n")
  end
end

token = ENV["TOKEN"]
channel = ENV["CHANNEL"]

user_url = "https://slack.com/api/users.list?token=#{token}"
users = []
JSON.load(open(user_url).read)["members"].each do |member|
  users << { real_name: member["real_name"], id: member["id"] }
end

@users = users.map do |user|
  User.new(user[:id], user[:real_name], 0, 0)
end

url = "https://slack.com/api/conversations.history?token=#{token}&channel=#{channel}"
JSON.load(open(url).read)["messages"].each do |msg|
  @users.each do |user|
    if msg["user"] == user.id
      user.post_sum += 1
      if msg["reactions"]
        msg["reactions"].each do |reaction|
          user.reaction_sum += reaction["count"]
        end
      end
      if msg["reply_count"]
        user.reaction_sum += msg["reply_users_count"]
      end
    end
  end
end

Slack.configure do |config|
  config.token = token
end

client = Slack::Web::Client.new

client.chat_postMessage(channel: '#random', text: User.post_result(@users), as_user: true)
client.chat_postMessage(channel: '#random', text: User.reaction_result(@users), as_user: true)

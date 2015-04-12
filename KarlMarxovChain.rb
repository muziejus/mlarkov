require 'twitter'
require 'marky_markov'
require 'yaml'

class KarlMarxovChain

  def initialize
    @configs = YAML::load_file('configs.yml')
    @since_id = @configs[:since_id].to_i
  end

  def random_sentence # creates a random sentence of under 140 characters using marky_markov
    sentence = MarkyMarkov::Dictionary.new(['capital', 'earlywork'].sample).generate_n_sentences 1
    if sentence.length < 140
      sentence.capitalize
    else
      self.random_sentence
    end
  end

  def triple_array # creates @triple_array
    textarray = File.read("#{["capital", "earlywork"].sample}.txt").split(" ")
    @triple_array = (0..textarray.length - 2).map{ |n| "#{textarray[n]} #{textarray[n + 1]} #{textarray[n + 2]}" }
  end

  def build_sentence(term)
    hits = find_hits(term)
    if hits.empty?
      "Your term (#{term}) produced nothing, unlike an exploited worker." # could run long and crash.
    else
      sample = hits.sample
      add_to_sentence(sample)
    end
  end

  def add_to_sentence(sentence)
    if /[.!?]/.match(sentence[-1]).nil? # not the end of a sentence
      if sentence.length > 120 # we're long enough
        sentence[0...119].gsub(/ \S*$/, "")
      else
        term = /\S* \S*$/.match sentence
        hits = find_hits(term)
        if hits.empty? # no more chain building
          sentence 
        else
          sentence = sentence + " " + /\S*$/.match(hits.sample).to_s
          self.add_to_sentence(sentence)
        end
      end
    else 
      sentence
    end
  end

  def find_hits(term)
    @triple_array.select{ |n| n =~ /^#{term}/ }
  end

  def replies
    start_client
    @replies ||= get_replies
  end

  def update_since_id(id = @since_id)
    @configs[:since_id] = id
    File.open('configs.yml', 'w') do |file|
      file.puts YAML::dump(@configs)
    end
  end

  def tweet(text, reply_id = nil)
    start_client
    @client.update(text, {in_reply_to_status_id: reply_id})
  end

  private 
  def start_client
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = @configs[:consumer_key]
      config.consumer_secret = @configs[:consumer_secret]
      config.access_token = @configs[:access_token]
      config.access_token_secret = @configs[:access_token_secret]
    end
  end

  def get_replies
    @since_id == 0 ? reply_opts = {} : reply_opts = { since_id: @since_id }
    @client.mentions(reply_opts)
  end
end

tweet = KarlMarxovChain.new
if ARGV[0] == "random" # Called from the command line to make a random sentence.
  tweet_text = tweet.random_sentence
  tweet.tweet(tweet_text)
elsif ARGV[0] == "term" # Called from the command line to seed a sentence.
  tweet.triple_array
  tweet.tweet(tweet.build_sentence(ARGV[1]))
else # must a cron job, looking for @s.
  tweet.triple_array
  reply_ids = []
  tweet.replies.each do |reply|
    reply_ids.push(reply.id)
    # puts "reply: #{reply.id} - #{reply.text}"
    match = /^.*@KarlMarxovChain (\w*).*$/i.match(reply.text)
    match.nil? ? term = "No term detected" : term = match[1]
    tweet_text = tweet.build_sentence(term)
    tweet_text = "@" + reply.user.screen_name + " " + tweet_text
    tweet.tweet(tweet_text, reply.id)
  end
  tweet.update_since_id(reply_ids.max) unless reply_ids.max.nil?
end


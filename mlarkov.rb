require 'twitter'
require 'marky_markov'
require 'yaml'

class Mlarkov

  def initialize
    set_configs
    @since_id = @configs[:since_id].to_i
  end

  def random_sentence # creates a random sentence of under 140 characters using marky_markov
    @dictionary ||= set_dictionary
    sentence = @dictionary.generate_n_sentences 1
    if sentence.length < 140
      sentence.capitalize
    else
      self.random_sentence
    end
  end

  def set_triple_array # creates @triple_array
    textarray = set_dictionary("txt").split(" ")
    @triple_array = (0..textarray.length - 2).map{ |n| "#{textarray[n]} #{textarray[n + 1]} #{textarray[n + 2]}" }
  end

  def build_sentence(term)
    @triple_array ||= set_triple_array
    hits = find_hits(term)
    if hits.empty?
      "Your term (#{term}) produced nothing, unlike an exploited worker." # could run long and crash.
    else
      sample = hits.sample
      add_to_sentence(sample)
    end
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

  # private 
  def start_client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key = @configs[:consumer_key]
      config.consumer_secret = @configs[:consumer_secret]
      config.access_token = @configs[:access_token]
      config.access_token_secret = @configs[:access_token_secret]
    end
  end

  def find_hits(term)
    @triple_array.select{ |n| n =~ /^#{term}/ }
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
          add_to_sentence(sentence)
        end
      end
    else 
      sentence
    end
  end

  def get_replies
    @since_id == 0 ? reply_opts = {} : reply_opts = { since_id: @since_id }
    @client.mentions(reply_opts)
  end

  def set_configs
    if File.exists? 'configs.yml'
      @configs = YAML::load_file 'configs.yml'
    else
      raise "No configs file"
    end
  end

  def set_dictionary(extension = "mmd")
    start_client
    search = @client.search("#mla16", count: "100")
    tweet_array = search.map{ |tweet| tweet.text }
    puts "Found #{tweet_array.length} tweets."
    tweet_array = tweet_array.join(" ")
    tweets = tweet_array.gsub(/@/, "").gsub(/https:\S+/, "").gsub(/#mla16/i, "").gsub(/\s+/, " ")
    dictionary = MarkyMarkov::TemporaryDictionary.new
    dictionary.parse_string tweets
    dictionary
  end
end



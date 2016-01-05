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
    if @dictionary == "error TooManyRequests"
      "The rate limit is exceeded. Try again later."
    elsif @dictionary == "error other"
      "Some error came up when talking to Twitter. Try again later."
    else
      sentence = @dictionary.generate_n_words(100).capitalize.gsub("&amp;", "&").gsub(/$/, ".")
      unless sentence.length < 120
        sentence = sentence[0...119].gsub(/ \S*$/, ".")
      end
      sentence
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
    @client.update(text + " #MLA16", {in_reply_to_status_id: reply_id})
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
    begin
      search = @client.search("#mla16 -rt", count: "100")
      tweet_array = search.map{ |tweet| tweet.text unless tweet.user.screen_name == "MLArkov" }
      puts "Found #{tweet_array.length} tweets."
      tweet_array = tweet_array.join(" ")
      tweets = tweet_array.gsub(/@/, "").gsub(/https:\S+/, "").gsub(/#mla16/i, "").gsub(/\s+/, " ")
      dictionary = MarkyMarkov::TemporaryDictionary.new
      dictionary.parse_string tweets
      dictionary
    rescue Twitter::Error::TooManyRequests
      "error TooManyRequests"
    rescue 
      "error other"
    end
  end
end



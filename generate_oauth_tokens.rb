require 'twitter'
require 'oauth'

puts "Type in the consumer key:"
consumer_key = gets.chomp
puts "The consumer key is: #{consumer_key}"
puts "Type in the consumer secret:"
consumer_secret = gets.chomp
puts "The consumer secret is: #{consumer_secret}"
consumer = OAuth::Consumer.new(consumer_key, consumer_secret, site: "https://api.twitter.com")
request_token = consumer.get_request_token
request = consumer.create_signed_request(:get, consumer.authorize_path, request_token, {:oauth_callback => 'oob'})
params = request['Authorization'].sub(/^OAuth\s+/, '').split(/,\s+/).map do |param|
  key, value = param.split('=')
  value =~ /"(.*?)"/
  "#{key}=#{CGI::escape($1)}"
  end.join('&')
puts "Paste the url below into your browser while logged in to the bot."
puts "https://api.twitter.com#{request.path}?#{params}"
puts "Now type in the provided pin code:"
pin_code = gets.chomp
puts "Using #{pin_code}."
access_token = request_token.get_access_token(oauth_verifier: pin_code)
puts "Your access token is: #{access_token.token}"
puts "Your access secret is: #{access_token.secret}"
puts "Enjoy your botting!"



#!/usr/bin/env ruby

require "ruby/openai"

Ruby::OpenAI.configure do |config|
    config.access_token = ENV.fetch('OPENAI_KEY')
    # config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
end

client = OpenAI::Client.new

def chat(client, prompt)
  response = client.completions(
    parameters: {
        model: "text-davinci-003",
        prompt: prompt,
        max_tokens: 1024,
        n: 1,
        temperature: 0.5,
    }
  )

  puts response["choices"].map { |c| c["text"] }
end

prompt = ""

while true
  print "You: "
  user_input = gets.chomp
#   prompt += " " + user_input
    prompt = user_input
  response = chat(client, prompt)
  puts "Bot: #{response}"
  #prompt += " " + response
end

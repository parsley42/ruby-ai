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
            max_tokens: 2048,
            n: 1,
            top_p: 1,
            frequency_penalty: 1,
            presence_penalty: 1,
            temperature: 0.7,
        }
    )
    return response["choices"][0]["text"]
end

current = ""

while true
    print "You: "
    user_input = gets.chomp
    exit if user_input == "quit"
    current += user_input + "\n"
    puts("************** Full prompt:\n#{current}\n**************\n")
    response = chat(client, current)
    puts "Bot: #{response}"
    current += response + "\n\n"
end

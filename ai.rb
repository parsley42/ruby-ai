#!/usr/bin/env ruby

require "ruby/openai"

class AIChat
    Preamble = <<-'EOF'
A conversation between a Human software engineer and an AI mentor who provides sage advice and instructive explanations, often with formatted code samples showing example input and output, and with explanations of how the code works.

Human: Who are you?
AI: I am a wise and experienced engineer here to help you be a better engineer and person. How can I help you?
EOF

    def initialize
        @model = "text-davinci-003"
        @temperature = 0.84      # creativity
        @max_tokens = 2212
        @responses = 1           # n
        @word_probability = 0.7  # top_p
        @frequency_penalty = 0.2
        @presence_penalty = 0.4
        @num_beams = 7           # diversity of responses, good value per the AI
        @stop = [" Human:", "AI:"]
        Ruby::OpenAI.configure do |config|
            config.access_token = ENV.fetch('OPENAI_KEY')
            # config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID') # Optional.
        end
        @client = OpenAI::Client.new
        @exchanges = []
    end

    def query(input)
        prompt = Preamble
        @exchanges.each do |exchange|
            prompt += "Human: #{exchange["human"]}\nAI: #{exchange["ai"]}\n"
        end
        prompt += "Human: #{input}\nAI: "
        puts("******* Full prompt:\n#{prompt}\n")
        response = @client.completions(parameters: {
            model: @model,
            prompt: prompt,
            temperature: @temperature,
            max_tokens: @max_tokens,
            n: @responses,
            top_p: @word_probability,
            frequency_penalty: @frequency_penalty,
            presence_penalty: @presence_penalty,
            # num_beams: @num_beams,
            stop: @stop
        })
        pp(response)
        @exchanges << {
            "human" => input,
            "ai" => response["choices"][0]["text"]
        }
        pp(@exchanges)
        return response["choices"][0]["text"]
    end
end

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

chat = AIChat.new

response = chat.query("What is the meaning of life?")
puts(response)
exit

print "Query: "
user_input = gets.chomp

chat.query(user_input)
exit

current = ""

while true
    print "Query: "
    user_input = gets.chomp
    exit if user_input == "quit"
    current += user_input + "\n"
    puts("************** Full prompt:\n#{current}\n**************\n")
    response = chat(client, current)
    puts "Bot: #{response}"
    current += response + "\n\n"
end

#!/usr/bin/env ruby

require "ruby/openai"

def count_tokens(str)
    count = str.scan(/\w+|[^\s\w]+/s).length
    count += str.count("\n")
end

class AIChat
    Preamble = <<-'EOF'
A conversation between a Human software engineer and an AI that serves as life coach and mentor. When providing help with code, the AI provides formatted code samples, example input and output, and a clear explanation of how the code works. When providing advice on life decisions and dealing with other people, the AI provides help that is tailored to a nerdy engineer with generally poor social skills.

EOF

    def initialize
        @model = "text-davinci-003"
        @temperature = 0.84      # creativity
        @max_tokens = 2212
        @max_input = 3997 - @max_tokens
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
        @exchanges = [{
            "human" => "Who are you?",
            "ai" => "Hi, I'm your AI mentor. I'm here to provide advice and instruction on coding. How can I help you?"
        }]
    end

    def build_prompt(input)
        prompt = String.new
        final = nil
        truncated = false
        current_length = count_tokens(Preamble)
        if input.length > 0
            final = "Human: #{input}\nAI:"
            current_length += count_tokens(final)
        end
        @exchanges.reverse_each do |exchange|
            exchange = "Human: #{exchange["human"]}\nAI: #{exchange["ai"]}\n"
            size = count_tokens(exchange)
            if current_length + size > @max_input
                truncated = true
                break
            end
            current_length += size
            prompt = exchange + prompt
        end
        prompt = Preamble + prompt
        if final
            prompt += final
        end
        return prompt, current_length, truncated
    end

    def query(input)
        prompt, count, truncated = build_prompt(input)

        # puts("******* Full prompt (length: #{count}):\n#{prompt}\n")
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
        # pp(response)
        aitext = response["choices"][0]["text"].lstrip
        if input.length > 0
            @exchanges << {
                "human" => input,
                "ai" => aitext
            }
        end
        # pp(@exchanges)
        return aitext, count, truncated
    end
end

chat = AIChat.new

while true
    print "Query ('quit' to finish): "
    user_input = gets.chomp
    exit if user_input == "quit"
    response, count, truncated = chat.query(user_input)
    puts "Response (prompt size #{count}, truncated: #{truncated}):\n#{response}\n\n"
end

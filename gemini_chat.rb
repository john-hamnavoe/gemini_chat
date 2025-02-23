require "json"
require "net/http"

class GeminiChat
  BASE_URI = "https://generativelanguage.googleapis.com/v1beta/models/"

  def initialize(token: ENV["GEMINI_API_KEY"], base_uri: BASE_URI, model: "gemini-2.0-flash")
    @token = token
    @base_uri = base_uri
    @model = model
    @conversation_history = []
  end

  def chat(message)
    @conversation_history << {role: "user", parts: [{text: message}]}
    response = generate_content(
      contents: @conversation_history, # Use conversation history
      generationConfig: {
        candidateCount: 1 # Important for chat consistency
      }
    )

    gemini_response = response.dig("candidates", 0, "content", "parts", 0, "text")
    @conversation_history << {role: "model", parts: [{text: gemini_response}]} # Update history
    gemini_response # Return just the text
  end

  private

  def generate_content(args)
    post "generateContent", body: args
  end

  def post(path, body:, headers: {"content-type": "application/json"})
    url = URI("#{@base_uri}#{@model}:#{path}?key=#{@token}")
    data = JSON.dump(body)
    response = Net::HTTP.post(url, data, headers)
    JSON.parse(response.body)
  end
end

if __FILE__ == $0
  gemini = GeminiChat.new
  puts "Starting chat with Gemini (type 'exit' to quit)"
  puts "-" * 50

  loop do
    print "\nYou: "
    input = gets.chomp

    break if input.downcase == "exit"

    response = gemini.chat(input)
    puts "\nGemini: #{response}"
  end

  puts "\nChat ended. Goodbye!"
end

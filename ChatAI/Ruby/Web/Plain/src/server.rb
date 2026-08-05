require 'json'
require 'net/http'
require 'uri'
require 'webrick'

class ChatServer
  attr_accessor :base_url, :api_key, :default_model, :default_temperature, :default_max_tokens

  def initialize
    @base_url = ENV['OPENAI_BASE_URL'] || 'https://api.openai.com/v1'
    @api_key = ENV['OPENAI_API_KEY'] || ''
    @default_model = ENV['CHAT_MODEL'] || 'gpt-4o-mini'
    @default_temperature = (ENV['CHAT_TEMPERATURE'] || '0.7').to_f
    @default_max_tokens = (ENV['CHAT_MAX_TOKENS'] || '1024').to_i
  end

  def complete_chat(messages, model, temperature, max_tokens)
    uri = URI("#{@base_url}/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}" unless @api_key.empty?
    request.body = JSON.generate({
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: max_tokens
    })
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    unless response.is_a?(Net::HTTPSuccess)
      raise "Provider error #{response.code}: #{response.body}"
    end
    JSON.parse(response.body)
  end

  def normalize_result(result, model)
    choices = (result['choices'] || []).map do |choice|
      {
        'role' => choice.dig('message', 'role') || 'assistant',
        'content' => choice.dig('message', 'content') || ''
      }
    end
    usage = result['usage'] || {}
    {
      'id' => result['id'] || '',
      'model' => result['model'] || model,
      'choices' => choices,
      'usage' => {
        'prompt_tokens' => usage['prompt_tokens'] || 0,
        'completion_tokens' => usage['completion_tokens'] || 0,
        'total_tokens' => usage['total_tokens'] || 0
      }
    }
  end

  def build_server(port)
    server = WEBrick::HTTPServer.new(Port: port, BindAddress: '0.0.0.0')

    server.mount_proc('/') do |_req, res|
      res['Content-Type'] = 'text/html'
      res.body = File.read(File.join(__dir__, 'template.html'))
    end

    server.mount_proc('/health') do |_req, res|
      res['Content-Type'] = 'application/json'
      res.body = JSON.generate(status: 'ok')
    end

    server.mount_proc('/api/chat') do |req, res|
      res['Content-Type'] = 'application/json'
      if req.request_method != 'POST'
        res.status = 405
        res.body = JSON.generate(error: 'Method not allowed')
        next
      end

      input = req.body && !req.body.empty? ? JSON.parse(req.body) : {}
      if input['messages'].nil? || input['messages'].empty?
        res.status = 400
        res.body = JSON.generate(error: 'Messages must not be empty')
        next
      end

      model = input['model'] || @default_model
      temperature = input['temperature'] || @default_temperature
      max_tokens = input['max_tokens'] || @default_max_tokens

      begin
        result = complete_chat(input['messages'], model, temperature, max_tokens)
        res.body = JSON.generate(normalize_result(result, model))
      rescue StandardError => e
        res.status = 502
        res.body = JSON.generate(error: e.message)
      end
    end

    server
  end
end

if __FILE__ == $PROGRAM_NAME
  port = ENV['PORT'] || 3000
  chat = ChatServer.new
  server = chat.build_server(port.to_i)
  trap('INT') { server.shutdown }
  puts "ChatAI server on :#{port}"
  server.start
end

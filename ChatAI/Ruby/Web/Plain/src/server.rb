require 'json'
require 'net/http'
require 'uri'
require 'webrick'

class ChatServer
  attr_accessor :base_url, :api_key, :default_model, :default_temperature, :default_max_tokens,
                :rag_enabled, :rag_search_url, :rag_top_k, :timeout_ms

  def initialize
    @base_url = ENV['OPENAI_BASE_URL'] || 'https://api.openai.com/v1'
    @api_key = ENV['OPENAI_API_KEY'] || ''
    @default_model = ENV['CHAT_MODEL'] || 'gpt-4o-mini'
    @default_temperature = (ENV['CHAT_TEMPERATURE'] || '0.7').to_f
    @default_max_tokens = (ENV['CHAT_MAX_TOKENS'] || '1024').to_i
    @rag_enabled = %w[1 true yes].include?(ENV['RAG_ENABLED'].to_s.downcase)
    @rag_search_url = ENV['RAG_SEARCH_URL'] || 'http://semantic-search:5000/api/search'
    @rag_top_k = (ENV['RAG_TOP_K'] || '3').to_i
    @timeout_ms = (ENV['CHAT_TIMEOUT_MS'] || '30000').to_i
  end

  def retrieve_context(query)
    uri = URI(@rag_search_url)
    uri.query = URI.encode_www_form('q' => query, 'k' => @rag_top_k)
    response = Net::HTTP.start(uri.host, uri.port,
                               open_timeout: @timeout_ms / 1000.0,
                               read_timeout: @timeout_ms / 1000.0) do |http|
      http.get(uri)
    end
    return [] unless response.is_a?(Net::HTTPSuccess)
    data = JSON.parse(response.body)
    (data['results'] || []).map { |r| r['document'] }.compact.reject(&:empty?)
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

    server.mount_proc('/openapi.json') do |_req, res|
      res['Content-Type'] = 'application/json'
      res.body = File.read(File.join(__dir__, 'openapi.json'))
    end

    server.mount_proc('/swagger') do |_req, res|
      res['Content-Type'] = 'text/html'
      res.body = File.read(File.join(__dir__, 'swagger.html'))
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

      messages = input['messages']
      if @rag_enabled
        last_user = messages.reverse.find { |m| m['role'] == 'user' }
        unless last_user.nil?
          begin
            documents = retrieve_context(last_user['content'].to_s)
            if documents.any?
              context = "Use the following context to answer the user's question:\n\n" \
                        + documents.map { |d| "- #{d}" }.join("\n")
              messages = [{ 'role' => 'system', 'content' => context }] + messages
            end
          rescue StandardError => e
            warn "RAG retrieval failed: #{e.message}"
          end
        end
      end

      begin
        result = complete_chat(messages, model, temperature, max_tokens)
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

require 'json'
require 'minitest/autorun'
require 'net/http'
require 'socket'
require 'uri'
require_relative '../server'

class ChatServerTest < Minitest::Test
  def setup
    @chat = ChatServer.new
    @server = @chat.build_server(0)
    @thread = Thread.new { @server.start }
    @port = @server.config[:Port]
    sleep 0.1
  end

  def teardown
    @server.shutdown
    @thread.join
  end

  def get(path)
    Net::HTTP.get_response(URI("http://127.0.0.1:#{@port}#{path}"))
  end

  def post(path, body)
    uri = URI("http://127.0.0.1:#{@port}#{path}")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(body)
    Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  end

  def test_index_returns_html
    response = get('/')
    assert_equal '200', response.code
    assert_includes response.body, 'ChatAI'
  end

  def test_health_returns_ok
    response = get('/health')
    assert_equal '200', response.code
    assert_equal({ 'status' => 'ok' }, JSON.parse(response.body))
  end

  def test_chat_empty_messages_returns_400
    response = post('/api/chat', { 'messages' => [] })
    assert_equal '400', response.code
  end

  def test_chat_valid_message_returns_assistant_response
    def @chat.complete_chat(_messages, _model, _temperature, _max_tokens)
      {
        'id' => 'chatcmpl-test',
        'model' => 'gpt-4o-mini',
        'choices' => [{ 'message' => { 'role' => 'assistant', 'content' => 'Hello!' } }],
        'usage' => { 'prompt_tokens' => 5, 'completion_tokens' => 3, 'total_tokens' => 8 }
      }
    end

    response = post('/api/chat', { 'messages' => [{ 'role' => 'user', 'content' => 'Hi' }] })
    assert_equal '200', response.code
    data = JSON.parse(response.body)
    assert_equal 'assistant', data['choices'][0]['role']
    assert_equal 'Hello!', data['choices'][0]['content']
    assert_equal 'chatcmpl-test', data['id']
    assert_equal 8, data['usage']['total_tokens']
  end

  def test_chat_provider_failure_returns_502
    def @chat.complete_chat(_messages, _model, _temperature, _max_tokens)
      raise 'upstream provider failed'
    end

    response = post('/api/chat', { 'messages' => [{ 'role' => 'user', 'content' => 'Hi' }] })
    assert_equal '502', response.code
  end

  def test_chat_rag_injects_context
    @chat.rag_enabled = true
    captured = nil
    @chat.define_singleton_method(:retrieve_context) { |_query| ['Doc about X', 'Doc about Y'] }
    @chat.define_singleton_method(:complete_chat) do |messages, _model, _temperature, _max_tokens|
      captured = messages
      {
        'id' => 'chatcmpl-test',
        'model' => 'gpt-4o-mini',
        'choices' => [{ 'message' => { 'role' => 'assistant', 'content' => 'Hello!' } }],
        'usage' => { 'prompt_tokens' => 5, 'completion_tokens' => 3, 'total_tokens' => 8 }
      }
    end

    response = post('/api/chat', { 'messages' => [{ 'role' => 'user', 'content' => 'What is X?' }] })
    assert_equal '200', response.code
    assert_equal 'system', captured[0]['role']
    assert_includes captured[0]['content'], 'Doc about X'
    assert_includes captured[0]['content'], 'Doc about Y'
    assert_equal({ 'role' => 'user', 'content' => 'What is X?' }, captured[1])
  end

  def test_chat_rag_disabled_does_not_retrieve
    @chat.rag_enabled = false
    retrieved = false
    @chat.define_singleton_method(:retrieve_context) { |_query| retrieved = true; [] }
    @chat.define_singleton_method(:complete_chat) do |_messages, _model, _temperature, _max_tokens|
      {
        'id' => 'chatcmpl-test',
        'model' => 'gpt-4o-mini',
        'choices' => [{ 'message' => { 'role' => 'assistant', 'content' => 'Hello!' } }],
        'usage' => { 'prompt_tokens' => 5, 'completion_tokens' => 3, 'total_tokens' => 8 }
      }
    end

    response = post('/api/chat', { 'messages' => [{ 'role' => 'user', 'content' => 'Hi' }] })
    assert_equal '200', response.code
    refute retrieved
  end

  def test_chat_rag_fail_soft
    @chat.rag_enabled = true
    captured = nil
    @chat.define_singleton_method(:retrieve_context) { |_query| raise 'search service down' }
    @chat.define_singleton_method(:complete_chat) do |messages, _model, _temperature, _max_tokens|
      captured = messages
      {
        'id' => 'chatcmpl-test',
        'model' => 'gpt-4o-mini',
        'choices' => [{ 'message' => { 'role' => 'assistant', 'content' => 'Hello!' } }],
        'usage' => { 'prompt_tokens' => 5, 'completion_tokens' => 3, 'total_tokens' => 8 }
      }
    end

    response = post('/api/chat', { 'messages' => [{ 'role' => 'user', 'content' => 'Hi' }] })
    assert_equal '200', response.code
    assert_equal [{ 'role' => 'user', 'content' => 'Hi' }], captured
  end
end

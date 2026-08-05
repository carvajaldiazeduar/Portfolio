class SemanticSearchController < ApplicationController
  def index
  end

  def search
    q = params[:q].to_s.strip
    if q.empty?
      render json: { error: "Query parameter 'q' is required" }, status: 400
      return
    end
    results = Rails.cache.fetch("search:#{q}", expires_in: 300.seconds) do
      vector_store.search([0.0] * 1536, 5)
    end
    render json: { query: q, results: results }
  end

  def upload
    file = params[:file]
    unless file
      render json: { error: 'No file provided' }, status: 400
      return
    end
    content = file.read.force_encoding('UTF-8')
    metadata = { filename: file.original_filename, source: 'upload' }
    vector_store.add_documents([content], [[0.0] * 1536], [metadata])
    Rails.cache.delete('search:results')
    render json: { message: 'Document indexed', filename: file.original_filename }
  end

  def collections
    render json: { collections: vector_store.list_collections }
  end

  private

  def vector_store
    @vector_store ||= begin
      driver = ENV.fetch('VECTOR_DRIVER', 'chromadb')
      case driver
      when 'pinecone' then PineconeAdapter.new
      when 'pgvector' then PgVectorAdapter.new
      else ChromaDBAdapter.new
      end
    end
  end
end
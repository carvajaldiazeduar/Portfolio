class MessagesController < ApplicationController
  def index
    @messages = cache.fetch("messages:all", expires_in: cache_ttl) do
      Message.order(:id).all
    end
  end

  def show
    message = Message.find_by(id: params[:id])
    unless message
      redirect_to root_path, alert: "Message not found"
      return
    end
    message.update(read: true)
    cache.write("message:#{message.id}", message, expires_in: cache_ttl)
    cache.delete("messages:all")
    @message = message
  end

  def search
    q = params[:q].to_s.strip.downcase
    results = cache.fetch("messages:search:#{q}", expires_in: cache_ttl) do
      Message.where("LOWER(sender) LIKE ?", "%#{q}%").order(:id)
    end
    render json: results.as_json(only: [:id, :sender, :subject])
  end

  def create
    message = Message.new(message_params)
    if message.sender.present? && message.subject.present? && message.save
      cache.delete("messages:all")
      redirect_to root_path, notice: "Message added"
    else
      redirect_to root_path, alert: "sender and subject are required"
    end
  end

  def destroy
    message = Message.find_by(id: params[:id])
    message&.destroy
    cache.delete("messages:all")
    cache.delete("message:#{params[:id]}")
    redirect_to root_path, notice: "Message deleted"
  end

  private

  def message_params
    params.require(:message).permit(:sender, :subject, :body)
  end
end
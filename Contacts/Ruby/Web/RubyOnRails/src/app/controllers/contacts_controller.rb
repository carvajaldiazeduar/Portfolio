class ContactsController < ApplicationController
  def index
    @contacts = cache.fetch("contacts:all", expires_in: cache_ttl) do
      Contact.order(:id).all
    end
  end

  def search
    q = params[:q].to_s.strip.downcase
    results = cache.fetch("contacts:search:#{q}", expires_in: cache_ttl) do
      Contact.where("LOWER(name) LIKE ?", "%#{q}%").order(:id)
    end
    render json: results.as_json(only: [:id, :name, :phone, :email])
  end

  def create
    contact = Contact.new(contact_params)
    if contact.save
      cache.delete("contacts:all")
      redirect_to root_path, notice: "Contact added"
    else
      redirect_to root_path, alert: "Name is required"
    end
  end

  def destroy
    contact = Contact.find_by(id: params[:id])
    contact&.destroy
    cache.delete("contacts:all")
    redirect_to root_path, notice: "Contact deleted"
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :phone, :email)
  end
end
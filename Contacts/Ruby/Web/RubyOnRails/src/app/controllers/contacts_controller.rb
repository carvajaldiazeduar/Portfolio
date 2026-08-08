class ContactsController < ApplicationController
  helper_method :field_class, :field_error

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
    @contact = Contact.new(contact_params)
    if @contact.save
      cache.delete("contacts:all")
      redirect_to root_path, notice: "Contact added"
    else
      if request.format.json?
        render json: { errors: error_hash(@contact) }, status: 400
      else
        @contacts = cache.fetch("contacts:all", expires_in: cache_ttl) do
          Contact.order(:id).all
        end
        render :index, status: 400
      end
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

  def error_hash(contact)
    contact.errors.to_hash.transform_values { |msgs| msgs.uniq.first }
  end

  def field_class(contact, field)
    return "" unless contact
    contact.errors.include?(field) ? "field-error" : "field-valid"
  end

  def field_error(contact, field)
    return nil unless contact
    contact.errors[field].first if contact.errors.include?(field)
  end
end

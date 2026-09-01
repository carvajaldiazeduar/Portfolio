class PasswordEntriesController < ApplicationController
  UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
  DIGITS = "0123456789"
  SYMBOLS = "!@#$%^&*()_+-=[]{}|;:,.<>?"

  def index
    @passwords = cache.fetch("passwords:recent", expires_in: cache_ttl) do
      PasswordEntry.order(id: :desc).limit(50).to_a
    end
  end

  def generate
    length = params[:length].to_i
    use_upper = params[:use_upper] == "1"
    use_lower = params[:use_lower] == "1"
    use_digits = params[:use_digits] == "1"
    use_symbols = params[:use_symbols] == "1"

    begin
      password = build_password(length, use_upper, use_lower, use_digits, use_symbols)
      PasswordEntry.create!(password: password, length: length)
      cache.delete("passwords:recent")
      @generated = password
      @passwords = PasswordEntry.order(id: :desc).limit(50).to_a
      flash.now[:notice] = "Password generated"
      render :index
    rescue StandardError => e
      redirect_to root_path, alert: e.message
    end
  end

  private

  def build_password(length, use_upper, use_lower, use_digits, use_symbols)
    length = 16 if length < 1
    categories = []
    categories << UPPERCASE if use_upper
    categories << LOWERCASE if use_lower
    categories << DIGITS if use_digits
    categories << SYMBOLS if use_symbols
    raise "Select at least one category" if categories.empty?
    raise "Length must be at least #{categories.length}" if length < categories.length

    chars = []
    categories.each { |c| chars << c[rand(c.length)] }
    all = categories.join
    (chars.length...length).each { chars << all[rand(all.length)] }
    chars.shuffle.join
  end
end
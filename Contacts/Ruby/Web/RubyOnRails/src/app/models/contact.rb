class Contact < ApplicationRecord
  NAME_REGEX = /\A[A-Za-zÀ-ÿ' .-]+\z/
  PHONE_REGEX = /\A[0-9 +().-]{7,20}\z/
  EMAIL_REGEX = /\A[^\s@]+@[^\s@]+\.[^\s@]{2,}\z/

  validates :name, presence: { message: "Name is required" },
                   length: { in: 2..100, allow_blank: true, message: "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)" },
                   format: { with: NAME_REGEX, allow_blank: true, message: "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)" }
  validates :phone, presence: { message: "Phone is required" },
                    length: { in: 7..20, allow_blank: true, message: "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)" },
                    format: { with: PHONE_REGEX, allow_blank: true, message: "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)" }
  validates :email, presence: { message: "Email is required" },
                    format: { with: EMAIL_REGEX, allow_blank: true, message: "Invalid email format" }

  before_validation :strip_attributes

  private

  def strip_attributes
    self.name = name.to_s.strip
    self.phone = phone.to_s.strip
    self.email = email.to_s.strip
  end
end

class Document < ApplicationRecord
  validates :title, presence: true
end
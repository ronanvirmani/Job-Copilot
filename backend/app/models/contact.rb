class Contact < ApplicationRecord
  belongs_to :company
  has_many :messages, dependent: :nullify
  validates :email, presence: true
end
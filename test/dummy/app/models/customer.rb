class Customer < ApplicationRecord
  validates :name, length: { maximum: 40 }
end

class Endpoint < ApplicationRecord
  has_secure_token 
  validates :name, presence:true
  has_many :captured_requests, dependent: :destroy
  
end

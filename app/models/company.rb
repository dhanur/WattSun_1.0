class Company < ActiveRecord::Base
  validates :name, :email, :address, :zip, :city, :state, presence: true
  validates :name, :email, :contact, uniqueness: true
end

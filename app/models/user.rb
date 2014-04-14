class User < ActiveRecord::Base
      validates :company_email_id, :mobile_phone, :office_phone, uniqueness: true
      has_many :user_purchases
end

class CreateUserPurchases < ActiveRecord::Migration
  def change
    create_table :user_purchases do |t|

      t.timestamps
    end
  end
end

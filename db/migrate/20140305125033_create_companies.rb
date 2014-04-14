class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :email
      t.string :address
      t.string :zip
      t.string :city
      t.string :state
      t.string :contact
     end
  end
end

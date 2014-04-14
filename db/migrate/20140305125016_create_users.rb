class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :company_email, :references => ':companies(email) ON DELETE RESTRICT'
      t.string :title
      t.string :work_email
      t.string :mobile
      t.boolean :active_status, :default => false
      t.datetime :last_login_date
      t.datetime :registration_date 
    end
  end
end

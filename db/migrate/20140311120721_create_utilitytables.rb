class CreateUtilitytables < ActiveRecord::Migration
  def change
    create_table :utilitytables do |t|

      t.timestamps
    end
  end
end

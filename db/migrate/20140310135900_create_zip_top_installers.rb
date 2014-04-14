class CreateZipTopInstallers < ActiveRecord::Migration
  def change
    create_table :zip_top_installers do |t|

      t.timestamps
    end
  end
end

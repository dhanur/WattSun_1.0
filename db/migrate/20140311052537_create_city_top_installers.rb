class CreateCityTopInstallers < ActiveRecord::Migration
  def change
    create_table :city_top_installers do |t|

      t.timestamps
    end
  end
end

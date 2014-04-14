class CreateCityPanelBrands < ActiveRecord::Migration
  def change
    create_table :city_panel_brands do |t|

      t.timestamps
    end
  end
end

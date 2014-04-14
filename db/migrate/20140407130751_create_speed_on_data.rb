class CreateSpeedOnData < ActiveRecord::Migration
  def change
    create_table :speed_on_data do |t|

      t.timestamps
    end
  end
end

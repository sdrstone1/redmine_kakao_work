class CreateAppKeys < ActiveRecord::Migration[4.2]
    def change
      create_table :app_keys do |k|
        k.string :app_key
      end
    end
  end
  
class AddNotesToBills < ActiveRecord::Migration[7.2]
  def change
    add_column :bills, :notes, :text
  end
end 
class AddBillTypeToBills < ActiveRecord::Migration[7.2]
  def change
    add_column :bills, :bill_type, :string, default: "normal", null: false
  end
end 
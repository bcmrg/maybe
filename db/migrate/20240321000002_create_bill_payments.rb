class CreateBillPayments < ActiveRecord::Migration[7.2]
  def change
    create_table :bill_payments, id: :uuid do |t|
      t.references :bill, null: false, foreign_key: true, type: :uuid
      t.references :entry, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    add_index :bill_payments, [:bill_id, :entry_id], unique: true
  end
end 
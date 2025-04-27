class CreateBills < ActiveRecord::Migration[7.2]
  def change
    create_table :bills, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :category, foreign_key: true, type: :uuid
      t.references :account, foreign_key: true, type: :uuid
      
      t.string :name, null: false
      t.integer :amount, null: false
      t.string :currency, null: false
      t.string :frequency, null: false
      t.date :start_date, null: false
      t.date :next_due_date
      t.string :status, null: false, default: "active"
      t.jsonb :auto_match_rule
      
      t.timestamps
    end

    add_index :bills, [:family_id, :name], unique: true
  end
end 
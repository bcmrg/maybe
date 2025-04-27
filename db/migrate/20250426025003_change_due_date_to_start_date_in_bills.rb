class ChangeDueDateToStartDateInBills < ActiveRecord::Migration[7.2]
  def change
    # First add the new column
    add_column :bills, :start_date, :date

    # Copy data from due_date to start_date
    # For each bill, we'll set start_date to the first occurrence of the due_date
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE bills 
          SET start_date = date_trunc('month', CURRENT_DATE) + (due_date - 1) * interval '1 day'
          WHERE start_date IS NULL
        SQL
      end
    end

    # Make start_date not nullable
    change_column_null :bills, :start_date, false

    # Remove the old column
    remove_column :bills, :due_date, :integer
  end
end

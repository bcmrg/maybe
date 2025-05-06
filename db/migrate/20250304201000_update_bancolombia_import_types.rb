class UpdateBancolombiaImportTypes < ActiveRecord::Migration[7.2]
  def up
    # Update BancolombiaImport to BancolombiaImport::Savings
    execute <<-SQL
      UPDATE imports 
      SET type = 'BancolombiaImport::Savings' 
      WHERE type = 'BancolombiaImport'
    SQL

    # Update BancolombiaCreditCardImport to BancolombiaImport::CreditCard
    execute <<-SQL
      UPDATE imports 
      SET type = 'BancolombiaImport::CreditCard' 
      WHERE type = 'BancolombiaCreditCardImport'
    SQL
  end

  def down
    # Revert BancolombiaImport::Savings back to BancolombiaImport
    execute <<-SQL
      UPDATE imports 
      SET type = 'BancolombiaImport' 
      WHERE type = 'BancolombiaImport::Savings'
    SQL

    # Revert BancolombiaImport::CreditCard back to BancolombiaCreditCardImport
    execute <<-SQL
      UPDATE imports 
      SET type = 'BancolombiaCreditCardImport' 
      WHERE type = 'BancolombiaImport::CreditCard'
    SQL
  end
end 
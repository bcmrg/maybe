class BillPayment < ApplicationRecord
  belongs_to :bill
  belongs_to :entry

  validates :bill_id, uniqueness: { scope: :entry_id }
  validate :entry_is_transaction
  validate :entry_currency_matches_bill
  
  private

    def entry_is_transaction
      unless entry&.entryable_type == "Transaction"
        errors.add(:entry, "must be a transaction")
      end
    end

    def entry_currency_matches_bill
      if entry&.currency != bill&.currency
        errors.add(:entry, "currency must match bill currency")
      end
    end
end 
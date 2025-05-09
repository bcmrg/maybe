class Bill < ApplicationRecord
  include Monetizable, Enrichable

  FREQUENCIES = %w[monthly quarterly semi_annual annual]
  STATUSES = %w[active paused]

  belongs_to :family
  belongs_to :category, optional: true
  belongs_to :account, optional: true
  belongs_to :debt_account, class_name: "Account", optional: true
  
  has_many :bill_payments, dependent: :destroy
  has_many :entries, through: :bill_payments
  has_many :transactions, through: :entries, source: :entryable, source_type: "Transaction"

  validates :name, presence: true, uniqueness: { scope: :family_id }
  validates :amount, :currency, :frequency, :start_date, :next_due_date, presence: true
  validates :frequency, inclusion: { in: FREQUENCIES }
  validates :status, inclusion: { in: STATUSES }

  monetize :amount

  enum :bill_type, { normal: "normal", debt: "debt" }

  scope :active, -> { where(status: "active") }
  scope :paused, -> { where(status: "paused") }
  scope :due_soon, -> { active.where("next_due_date >= ? AND next_due_date <= ?", Date.current, 7.days.from_now) }
  scope :overdue, -> { active.where("next_due_date < ?", Date.current) }

  def paused?
    status == "paused"
  end

  def active?
    status == "active"
  end

  def overdue?
    active? && next_due_date && next_due_date < Date.current
  end

  def due_soon?
    active? && next_due_date && next_due_date <= 7.days.from_now
  end

  def paid_for_period?(date = Date.current)
    return false unless next_due_date

    period_start = previous_due_date(date)
    period_end = next_due_date_from(date)

    entries.where(date: period_start..period_end).exists?
  end

  def previous_due_date(from_date = Date.current)
    case frequency
    when "monthly"
      from_date - 1.month
    when "quarterly"
      from_date - 3.months
    when "semi_annual"
      from_date - 6.months
    when "annual"
      from_date - 1.year
    end
  end

  def next_due_date_from(from_date = Date.current)
    case frequency
    when "monthly"
      from_date + 1.month
    when "quarterly"
      from_date + 3.months
    when "semi_annual"
      from_date + 6.months
    when "annual"
      from_date + 1.year
    end
  end

  def advance_due_date!
    update_column(:next_due_date, next_due_date_from(next_due_date))
  end

  def mark_as_paid!
    advance_due_date!
  end
end 
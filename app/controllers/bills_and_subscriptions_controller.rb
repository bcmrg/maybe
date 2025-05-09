class BillsAndSubscriptionsController < ApplicationController
  include StreamExtensions

  before_action :set_bill, only: [:show, :edit, :update, :destroy, :mark_paid]

  def index
    @breadcrumbs = [["Bills & Subscriptions", nil]]
    
    @bills = Current.family.bills
      .includes(:category, :account)
      .order(next_due_date: :asc)

    if params[:status].present?
      @bills = @bills.where(status: params[:status])
    end

    if params[:category_id].present?
      @bills = @bills.where(category_id: params[:category_id])
    end

    @overdue_bills = @bills.overdue
    @upcoming_bills = @bills.due_soon.where.not(id: @overdue_bills)
    @due_this_month_bills = @bills.active
      .where("next_due_date >= ? AND next_due_date <= ?", Date.current.beginning_of_month, Date.current.end_of_month)
      .where.not(id: @overdue_bills.or(@upcoming_bills))
    @other_bills = @bills.where.not(id: @overdue_bills.or(@upcoming_bills).or(@due_this_month_bills))
    
    # Calculate totals
    @monthly_total = calculate_monthly_total(@bills.active)
    @overdue_total = @overdue_bills.sum(&:amount_money)
    @upcoming_total = @upcoming_bills.sum(&:amount_money)
    @due_this_month_total = @due_this_month_bills.sum(&:amount_money)
  end

  def show
    @breadcrumbs = [
      ["Bills & Subscriptions", bills_and_subscriptions_path],
      [@bill.name, nil]
    ]

    @recent_payments = @bill.transactions
      .includes(entry: :account)
      .order("entries.date DESC")
      .limit(5)
  end

  def new
    @bill = Current.family.bills.new
  end

  def create
    @bill = Current.family.bills.new(bill_params)
    @bill.next_due_date = @bill.start_date

    if @bill.save
      flash[:notice] = "Bill was successfully created"

      respond_to do |format|
        format.html { redirect_to bills_and_subscriptions_path }
        format.turbo_stream { 
          render turbo_stream: turbo_stream.action(:redirect, bills_and_subscriptions_path)
        }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @breadcrumbs = [
      ["Bills & Subscriptions", bills_and_subscriptions_path],
      [@bill.name, bills_and_subscription_path(@bill)],
      ["Edit", nil]
    ]
  end

  def update
    if @bill.update(bill_params)
      flash[:notice] = "Bill was successfully updated"

      respond_to do |format|
        format.html { redirect_to bills_and_subscription_path(@bill) }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@bill, partial: "bills_and_subscriptions/bill", locals: { bill: @bill }),
            turbo_stream.replace("modal", ""),
            *flash_notification_stream_items
          ]
        end
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bill.destroy
    redirect_to bills_and_subscriptions_path, notice: "Bill was successfully deleted"
  end

  def mark_paid
    # Get the payment account
    account = Current.family.accounts.find(params[:account_id])

    # Parse and validate payment amount
    payment_amount = params[:amount].to_d
    if payment_amount <= 0
      flash[:error] = "Payment amount must be greater than 0"
      return redirect_to bills_and_subscription_path(@bill)
    end

    ActiveRecord::Base.transaction do
      # Create the entry with transaction
      entry = account.entries.new(
        date: params[:date] || Date.current,
        amount: payment_amount,
        currency: @bill.currency,
        name: "Payment for #{@bill.name}",
        entryable: Transaction.new(
          category: @bill.category
        )
      )

      # Create the bill payment record
      bill_payment = @bill.bill_payments.new(entry: entry)

      # Save payment entry and bill payment
      if entry.save && bill_payment.save
        # If this is a debt bill, create a Transfer to the debt account
        if @bill.debt? && @bill.debt_account.present?
          transfer = Transfer.from_accounts(
            from_account: account,
            to_account: @bill.debt_account,
            date: entry.date,
            amount: payment_amount
          )
          transfer.save!
          Rails.logger.info(
            "Debt payment transfer created for bill ##{@bill.id}: " \
            "Transfer ##{transfer.id}, Payment account: #{account.id}, " \
            "Debt account: #{@bill.debt_account.id}, Amount: #{payment_amount}"
          )
        end
        # Always advance the due date since bill amounts can vary
        @bill.mark_as_paid!

        flash[:notice] = "Payment was successfully recorded"
        respond_to do |format|
          format.html { redirect_to bills_and_subscriptions_path }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@bill, partial: "bills_and_subscriptions/bill", locals: { bill: @bill }),
              turbo_stream.replace("modal", ""),
              *flash_notification_stream_items
            ]
          end
        end
      else
        flash[:error] = "Could not record payment"
        raise ActiveRecord::Rollback
      end
    end
  end

  private

    def set_bill
      @bill = Current.family.bills.find(params[:id])
    end

    def bill_params
      params.require(:bill).permit(
        :name,
        :amount,
        :currency,
        :frequency,
        :start_date,
        :category_id,
        :account_id,
        :status,
        :next_due_date,
        :bill_type,
        :debt_account_id,
        :notes,
        auto_match_rule: {}
      )
    end

    def calculate_monthly_total(bills)
      bills.sum do |bill|
        case bill.frequency
        when "monthly"
          bill.amount_money
        when "quarterly"
          bill.amount_money / 3
        when "semi_annual"
          bill.amount_money / 6
        when "annual"
          bill.amount_money / 12
        end
      end
    end
end 
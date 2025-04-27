require "test_helper"

class BillReminderJobTest < ActiveJob::TestCase
  def setup
    @family = families(:dylan_family)
    @bill = @family.bills.create!(
      name: "Test Bill",
      amount: 100,
      currency: "USD",
      frequency: "monthly",
      start_date: Date.current,
      next_due_date: 5.days.from_now
    )
  end

  test "sends reminder for due bills" do
    @family.reminder_preference.update!(enabled: true)
    
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      BillReminderJob.perform_now
    end
  end

  test "does not send reminder when preference is disabled" do
    @family.reminder_preference.update!(enabled: false)
    
    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      BillReminderJob.perform_now
    end
  end

  test "does not send reminder when no bills are due" do
    @family.reminder_preference.update!(enabled: true)
    @bill.update!(next_due_date: 10.days.from_now)
    
    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      BillReminderJob.perform_now
    end
  end

  test "does not send reminder when bill is already paid" do
    @family.reminder_preference.update!(enabled: true)
    
    # Create a payment transaction for the bill
    @bill.transactions.create!(
      date: Date.current,
      amount: 100,
      currency: "USD"
    )
    
    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      BillReminderJob.perform_now
    end
  end
end 
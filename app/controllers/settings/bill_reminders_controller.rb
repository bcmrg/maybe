class Settings::BillRemindersController < ApplicationController
  layout "settings"

  def show
    @reminder_preference = Current.family.reminder_preference || Current.family.create_reminder_preference!
  end

  def update
    @reminder_preference = Current.family.reminder_preference
    
    if @reminder_preference.update(reminder_preference_params)
      respond_to do |format|
        format.html { redirect_to settings_bill_reminders_path, notice: "Reminder preferences updated successfully." }
        format.json { head :ok }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def test_reminder
    @reminder_preference = Current.family.reminder_preference
    BillReminderMailer.test_reminder(Current.user, @reminder_preference).deliver_now

    respond_to do |format|
      format.html { redirect_to settings_bill_reminders_path, notice: "Test reminder sent." }
      format.json { head :ok }
    end
  end

  private

  def reminder_preference_params
    params.require(:family_reminder_preference).permit(
      :send_overdue_reminders,
      :digest_frequency,
      remind_days: [],
      reminder_recipients: []
    )
  end
end 
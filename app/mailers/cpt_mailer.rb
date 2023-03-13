class CptMailer < ActionMailer::Base

  # Default sender account set in application.yml
  default from: ENV["SYSTEM_SEND_FROM_ADDRESS"]

  def transition(emails, subject, scenario)
    @app_title = ENV["APPLICATION_TITLE"] ? ENV["APPLICATION_TITLE"] : 'TransAM Application'
    @scenario = scenario
    @subject = subject
    if Rails.env == 'production'
      mail(to: emails, subject: subject)
    else
      mail(to: 'transam@camsys.com', subject: subject, body: emails.join("\n"))
    end
  end

end
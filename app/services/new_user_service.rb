#------------------------------------------------------------------------------
#
# NewUserService
#
# Contains business logic associated with creating new users
#
#------------------------------------------------------------------------------

class NewUserService

  def build(form_params)

    user = User.new(form_params)
    # Set up a default password for them
    user.password = SecureRandom.base64(8)
    # Activate the account immediately
    user.active = true
    # Override opt-in for email notifications
    user.notify_via_email = true

    return user
  end

  # Steps to take if the user was valid
  def post_process(user)

    user.update_user_organization_filters

    sys_user = User.find_by(first_name: 'system')
    ali_filter = UserActivityLineItemFilter.find_by(name: 'All ALIs', created_by_user_id: sys_user.id)
    user.update!(user_activity_line_item_filter_id: ali_filter.id)

    UserMailer.send_email_on_user_creation(user).deliver
  end
end

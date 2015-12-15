require 'rails_helper'

describe "activity_line_items/_comment_form.html.haml", :type => :view do
  it 'fields' do
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_field('comment_comment')
  end
end

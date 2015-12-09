require 'rails_helper'

describe "capital_projects/_comment_form.html.haml", :type => :view do
  it 'fields' do
    assign(:project, create(:capital_project))
    render

    expect(rendered).to have_field('comment_comment')
  end
end

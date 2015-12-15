require 'rails_helper'

describe "activity_line_items/_document_form.html.haml", :type => :view do
  it 'fields' do
    assign(:activity_line_item, create(:activity_line_item))
    render

    expect(rendered).to have_field('document_document')
    expect(rendered).to have_field('document_description')
  end
end

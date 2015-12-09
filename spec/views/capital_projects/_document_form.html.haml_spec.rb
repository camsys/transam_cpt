require 'rails_helper'

describe "capital_projects/_document_form.html.haml", :type => :view do
  it 'fields' do
    assign(:project, create(:capital_project))
    render

    expect(rendered).to have_field('document_document')
    expect(rendered).to have_field('document_description')
  end
end

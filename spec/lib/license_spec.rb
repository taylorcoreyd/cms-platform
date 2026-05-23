require 'rails_helper'

RSpec.describe 'License Compliance' do
  it 'does not contain any unapproved gem licenses' do
    # Runs license_finder and captures stdout/stderr
    output = `bundle exec license_finder`

    # license_finder outputs 'All dependencies are approved' if clear
    expect(output).to include('All dependencies are approved')
  end
end

Given /^the following test_emails:$/ do |test_emails|
  TestEmail.create!(test_emails.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) test_email$/ do |pos|
  visit test_emails_url
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following test_emails:$/ do |expected_test_emails_table|
  expected_test_emails_table.diff!(tableish('table tr', 'td,th'))
end



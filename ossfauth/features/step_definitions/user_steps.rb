Given /^the following users:$/ do |users|
  users.hashes.each do |user|
    u = User.new
    user.keys.each do |key|
      u.send("#{key}=", user[key])
    end
    u.save
  end
end

Given /^I am login as "([^\"]*)" with password "([^\"]*)"$/ do |user, password|
  visit "/users/login"
  fill_in 'name',user
  fill_in 'password', password
  click_button 'submit'
end

Then /^I should have cookie "([^\"]*)"$/ do |arg1|
  
end

When /^I delete the (\d+)(?:st|nd|rd|th) user$/ do |pos|
  visit users_url
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following users:$/ do |expected_users_table|
  expected_users_table.diff!(tableish('table tr', 'td,th'))
end

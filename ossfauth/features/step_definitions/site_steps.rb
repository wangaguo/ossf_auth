Given /^the following sites:$/ do |sites|
  sites.hashes.each do |site| 
    Site.create!(site) 
  end
end
Given /^the following sessions:$/ do |sessions|
  sessions.hashes.each do |session| 
    Session.create!(session) 
  end
end

When /^I delete the (\d+)(?:st|nd|rd|th) site$/ do |pos|
  visit sites_url
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following sites:$/ do |expected_sites_table|
  expected_sites_table.diff!(tableish('table tr', 'td,th'))
end

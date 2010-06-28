Feature: Manage test_emails
  In order to get emails
  As an user
  I want to signup, change email, forgot password and get emails

  Scenario: New user Signup
    Given I am on the user signup page
    When I fill in "user_name" with "ossfuser"
      And I fill in "user_password" with "ossfpassword"
      And I fill in "user_password_confirmation" with "ossfpassword"
      And I fill in "user_email" with "ossfuser@gmail.com"
      And I fill in "user_email_confirmation" with "ossfuser@gmail.com"
      And I fill in "user_first_name" with "Ossf"
      And I fill in "user_last_name" with "User"
      And I press "signup"
    Then I should see "註冊成功"
    Then "ossfuser@gmail.com" should receive an email
      And "ossfuser@gmail.com" should have an email
    When I open the email
      And I click the first link in the email
    Then I should be on the of-dashboard page
    #    And I should see "Success"
    #    Then I will go to the user home page

  Scenario: User Forget the Password
    Given the following users:
      |first_name|last_name|name     |password    |email             |status|
      |Ossf      |User     |ossfuser |ossfpassword|ossfuser@gmail.com|1     |
    When I am on the user login page
      And I go to the user forgot_password page
      And I fill in "email" with "ossfuser@gmail.com"
      And I press "commit"
    Then I should see "信"
    Then "ossfuser@gmail.com" should receive an email
      And "ossfuser@gmail.com" should have an email
    When I open the email
      And I click the first link in the email
    Then I should be on the user passwd page
      And I fill in "user_password" with "12345"
      And I fill in "user_password_confirmation" with "12345"
      And I press "commit"
    Then I should see "成功"

  Scenario: User Change Email
    Given the following users:
      |first_name|last_name|name     |password    |email             |status|
      |Ossf      |User     |ossfuser |ossfpassword|ossfuser@gmail.com|1     |
    Given I login as "ossfuser" with password "ossfpassword"
    Then I should see "integration"
    When I go to the user home page
      And I go to the user email page
      And I fill in "user_new_email" with "ossfuser@hotmail.com"
      And I fill in "user_email_confirmation" with "ossfuser@hotmail.com"
      And I press "commit"
    Then I should see "send"
    Then "ossfuser@hotmail.com" should receive an email
      And "ossfuser@hotmail.com" should have an email
    When I open the email
      And I should see "Click Me!" in the email body
      And I follow "Click Me!" in the email
    Then I should be on the user home page



    #Then I should be on the user email page
    #  And I press "cancel"
    #Then I should be on the user email page
    #Then I should be on the user home page
  # Rails generates Delete links that use Javascript to pop up a confirmation
  # dialog and then do a HTTP POST request (emulated DELETE request).
  #
  # Capybara must use Culerity or Selenium2 (webdriver) when pages rely on
  # Javascript events. Only Culerity supports confirmation dialogs.
  #
  # Since Culerity and Selenium2 has some overhead, Cucumber-Rails will detect 
  # the presence of Javascript behind Delete links and issue a DELETE request 
  # instead of a GET request.
  #
  # You can turn off this emulation by tagging your scenario with @selenium, 
  # @culerity, @celerity or @javascript. (See the Capybara documentation for 
  # details about those tags). If any of these tags are present, Cucumber-Rails
  # will also turn off transactions and clean the database with DatabaseCleaner 
  # after the scenario has finished. This is to prevent data from leaking into 
  # the next scenario.
  #
  # Another way to avoid Cucumber-Rails'' javascript emulation without using any
  # of the tags above is to modify your views to use <button> instead. You can
  # see how in http://github.com/jnicklas/capybara/issues#issue/12
  #
  # TODO: Verify with Rob what this means: The rack driver will detect the 
  # onclick javascript and emulate its behaviour without a real Javascript
  # interpreter.
  #
  #Scenario: Delete test_email
  #  Given the following test_emails:
  #    ||
  #    ||
  #    ||
  #    ||
  #    ||
  #  When I delete the 3rd test_email
  #  Then I should see the following test_emails:
  #    ||
  #    ||
  #    ||
  #    ||

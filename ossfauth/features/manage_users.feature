Feature: Manage users
  In order to control users
  boss
  wants user manager module
  
  Scenario: New user Signup
    Given I am on the user signup page
    When I fill in "user_name" with "name 1"
      And I fill in "user_password" with "password 1"
      And I fill in "user_password_confirmation" with "password 1"
      And I fill in "user_email" with "email 1"
      And I fill in "user_email_confirmation" with "email 1"
      And I fill in "user_first_name" with "xx"
      And I fill in "user_last_name" with "xxx"
      And I press "signup"
    Then I should see "Success"

  Scenario: User Login
    Given the following users:
	|first_name|last_name|name  |password|email   |status|
	|k         |kk       |kerker|kerker  |k@kk.ker|     1| 
    Given I am on the user login page
    When I fill in "name" with "kerker"
      And I fill in "password" with "kerker"
      And I press "login"
    #Then I should see "success"
    Then I should see "integration"
    #And I should have cookie "session"

  Scenario: User Logout
    Given the following users:
	|first_name|last_name|name  |password|email   |status|
	|k         |kk       |zzz   |zzz     |k@kk.ker|     1|
    Given I login as "zzz" with password "zzz"
    #Then I should see "success"
    Then I should see "integration"
    Given I am on the user logout page
    Then I should be on the user login page
  # Rails generates Delete links that use Javascript to pop up a confirmation
  # dialog and then do a HTTP POST request (emulated DELETE request).
  #
  # Capybara must use Culerity or Selenium2 (webdriver) when pages rely on
  # Javascript events. Only Culerity supports confirmation dialogs.
  # 
  # cucumber-rails will turn off transactions for scenarios tagged with 
  # @selenium, @culerity, @javascript or @no-txn and clean the database with 
  # DatabaseCleaner after the scenario has finished. This is to prevent data 
  # from leaking into the next scenario.
  #
  # Culerity has some performance overhead, and there are two alternatives to using
  # Culerity:
  #
  # a) You can remove the @culerity tag and run everything in-process, but then you 
  # also have to modify your views to use <button> instead: http://github.com/jnicklas/capybara/issues#issue/12
  #
  # b) Replace the @culerity tag with @emulate_rails_javascript. This will detect
  # the onclick javascript and emulate its behaviour without a real Javascript
  # interpreter.
  #

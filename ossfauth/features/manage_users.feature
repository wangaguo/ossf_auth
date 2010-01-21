Feature: Manage users
  In order to control users
  boss
  wants user manager module
  
  Scenario: New user Signup
    Given I am on the user signup page
    When I fill in "name" with "name 1"
      And I fill in "email" with "email 1"
      And I press "submit"
    Then I should see "name 1"
    And I should see "email 1"

  Scenario: User Login
    Given the following users:
	|name  |password|email   |
	|kerker|kerker  |k@kk.ker|
    Given I am on the user login page
    When I fill in "name" with "kerker"
      And I fill in "password" with "kerker"
      And I press "submit"
    Then I should see "Welcome, kerker"
    #And I should have cookie "session"

  Scenario: User Logout
    Given the following users:
	|id    |name  |password|email   |
	|10001 |kerker|kerker  |k@kk.ker|
    Given I am login as "kerker" with password "kerer"
    Given I am on the user logout page
    When I press "logout"
    Then I should see "Goobye kerker"
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

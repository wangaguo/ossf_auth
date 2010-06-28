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
    Then I should see "成功"

  Scenario: User Login
    Given the following users:
	|first_name|last_name|name  |password|email   |status|
	|k         |kk       |kerker|kerker  |k@kk.ker|     1|
    Given I am on the user login page
    When I fill in "name" with "kerker"
      And I fill in "password" with "kerker"
      And I press "login"
    #Then I should see "success"
    Then I should be on sso-integration page
    #And I should have cookie "session"

  Scenario: User Logout
    Given the following users:
	|first_name|last_name|name  |password|email   |status|params|
	|k         |kk       |zzz   |zzz     |k@kk.ker|     1|{:istatus => :yes}      |
    Given I login as "zzz" with password "zzz"
    #Then I should see "success"
    #Then I should see "integration"
    Given I am on the user logout page
    Then I should be on the user login page

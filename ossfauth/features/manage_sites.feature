Feature: Manage sites
  In order to Remember What Associated Sites We Have
  Boss 
  wants Site Manager Module
  
  Scenario: As a Centralized Site
    Given a key, IP, site name and URLs 
    When The Browser POST to regSite action
    Then I should receive a regist key

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
  #@culerity
  #Scenario: Delete site
  #  Given the following sites:
  #    ||
  #    ||
  #    ||
  #    ||
  #    ||
  #  When I delete the 3rd site
  #  Then I should see the following sites:
  #    ||
  #    ||
  #    ||
  #    ||

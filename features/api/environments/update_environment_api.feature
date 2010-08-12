@api @api_environments @environments_update
Feature: Update an environment via the REST API
  In order to keep my environment data up-to-date
  As a developer
  I want to update my environment via the REST API

  Scenario Outline: Update an environment
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And sending the method '<method>' to the 'environment' with '<updated_value>'
     When I 'PUT' the 'environment' to the path '/environments/cucumber'
     Then the inflated response should respond to '<method>' with '<updated_value>'
     When I 'GET' the path '/envinronments/cucumber'
     Then the inflated response should respond to '<method>' with '<updated_value>'

    Examples:
      | method      | updated_value |
      | description | I am a pickle |

  Scenario: Update an environment that does not exist
    Given I am an administrator
      And an 'environment' named 'cucumber'
      And sending the method 'description' to the 'environment' with 'This will not work'
     When I 'PUT' the 'environment' to the path '/environments/cucumber'
     Then I should get a '404 "Not Found"' exception

  Scenario: Update an environment with the wrong private key
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And sending the method 'description' to the 'environment' with 'This will not work'
     When I 'PUT' the 'environment' to the path '/environments/cucumber' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Update an environment as a non-admin user
    Given I am a non-admin
      And an 'environment' named 'cucumber' exists
      And sending the method 'description' to the 'environment' with 'This will not work'
     When I 'PUT' the 'environment' to the path '/environments/cucumber'
     Then I should get a '403 "Forbidden"' exception

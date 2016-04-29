Feature: Admin Delivery Approval
  As an admin
  I want to set an auction result to be approved
  And have the CAP Proposal created automatically
  So the vendor can get paid

  Scenario: Marking an auction result as accepted
    Given I am an administrator
    And there is a needs evaluation auction
    And I sign in
    When I visit the admin edit page for that auction
    And I select the result as accepted
    And I click on the "Update" button
    When I visit the admin edit page for that auction
    Then I should see that the auction has a CAP Proposal URL
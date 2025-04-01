// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../src/W3CXII.sol";

contract Deploy {
    constructor() payable {}
    
    function send(address payable cx11) external {
        selfdestruct(cx11);
    }
}

contract W3CXII_Test {
    W3CXII w3cxii;
    Deploy deploy;
    
    // Test events
    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    
    // Setup function to deploy contracts
    function beforeEach() public payable {
        // Deploy W3CXII with 1 ether
        w3cxii = new W3CXII{value: 1 ether}();
        // Deploy the Deploy contract with 1 ether
        deploy = new Deploy{value: 1 ether}();
    }
    
    // Test deposit functionality
    function test_Deposit() public payable {
        beforeEach();
        
        // Initial balance check
        assert(address(w3cxii).balance == 1 ether);
        
        // Test successful deposit of 0.5 ether
        w3cxii.deposit{value: 0.5 ether}();
        assert(w3cxii.balanceOf(address(this)) == 0.5 ether);
        assert(address(w3cxii).balance == 1.5 ether);
        
        // Test deposit requirements
        try w3cxii.deposit{value: 0.4 ether}() {
            assert(false); // Should fail due to invalid amount
        } catch {
            assert(true);
        }
    }
    
    // Test withdraw functionality
    function test_Withdraw() public payable {
        beforeEach();
        
        // Deposit first
        w3cxii.deposit{value: 0.5 ether}();
        
        // Test successful withdrawal
        uint initialBalance = address(this).balance;
        w3cxii.withdraw();
        assert(w3cxii.balanceOf(address(this)) == 0);
        assert(address(this).balance > initialBalance);
    }
    
    // Test selfdestruct scenario
    function test_SelfDestruct() public payable {
        beforeEach();
        
        // Deposit to contract
        w3cxii.deposit{value: 0.5 ether}();
        
        // Send 19 ether to reach 20 ether threshold using Deploy contract
        deploy.send(payable(address(w3cxii)));
        assert(address(w3cxii).balance >= 20 ether);
        
        // Attempt withdrawal to set dosed = true
        w3cxii.withdraw();
        assert(w3cxii.dosed() == true);
        
        // Get contract balance before selfdestruct
        uint contractBalance = address(w3cxii).balance;
        
        // Execute selfdestruct
        w3cxii.dest();
        
        // Check that contract balance is now 0
        assert(address(w3cxii).balance == 0);
    }
    
    // Fallback function to receive ether
    receive() external payable {}
}
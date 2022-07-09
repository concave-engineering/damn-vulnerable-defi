// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";

contract TestWithUsers is Test {

    uint256 salt;

    struct User { address account; uint256 key; }

    function getSigners(uint256 count) internal returns (User[] memory users) {

        users = new User[](count);

        for (uint256 i; i < count; i++) {
            salt++;
            uint key = uint256(bytes32(abi.encode(keccak256("FOUNDRYUP!"), salt)));
            address account = vm.addr(key);
            users[i] = User(account, key);
        }
    }
}
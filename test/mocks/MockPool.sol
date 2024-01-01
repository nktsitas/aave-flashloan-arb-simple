// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console} from "../../lib/forge-std/src/Script.sol";

contract MockPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external {
        console.log("MockPool.flashLoanSimple() called");
        console.log("MockPool.flashLoanSimple() amount %s", amount);
        console.log("MockPool.flashLoanSimple() asset %s", asset);
        console.log(
            "MockPool.flashLoanSimple() receiverAddress %s",
            receiverAddress
        );
        console.log("MockPool.flashLoanSimple() referralCode %s", referralCode);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {FlashLoanAave} from "../src/FlashLoanAave.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFlashLoanAave is Script {
    function run() public returns (FlashLoanAave, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (address aaveAddress, uint256 deployerKey) = helperConfig
            .activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        FlashLoanAave flashLoan = new FlashLoanAave(aaveAddress);
        console.log("Deployed FlashLoanAave at %s", address(flashLoan));
        vm.stopBroadcast();

        return (flashLoan, helperConfig);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {FlashLoanAave} from "../src/FlashLoanAave.sol";
import {UniswapSimple} from "../src/UniswapSimple.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {console} from "../lib/forge-std/src/console.sol";

contract DeployFlashLoanAave is Script {
    function run() public returns (FlashLoanAave, HelperConfig) {
        // function run() public returns (UniswapSimple) {
        HelperConfig helperConfig = new HelperConfig();

        (address aaveAddress, uint256 deployerKey) = helperConfig
            .activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        FlashLoanAave flashLoan = new FlashLoanAave(
            aaveAddress
            // uniswapRouterAddress
        );
        console.log("Deployed FlashLoanAave at %s", address(flashLoan));

        // UniswapSimple uniswapSimple = new UniswapSimple(uniswapRouterAddress);
        // console.log("Deployed FlashLoanAave at %s", address(uniswapSimple));
        vm.stopBroadcast();

        return (flashLoan, helperConfig);
        // return uniswapSimple;
    }
}

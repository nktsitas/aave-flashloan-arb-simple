// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {FlashLoanAave} from "../src/FlashLoanAave.sol";
import {UniswapSimple} from "../src/UniswapSimple.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFlashLoanAave is Script {
    function run() public returns (FlashLoanAave) {
        // function run() public returns (UniswapSimple) {
        HelperConfig helperConfig = new HelperConfig();

        (address aaveAddress, address uniswapRouterAddress) = helperConfig
            .activeNetworkConfig();

        vm.startBroadcast();
        FlashLoanAave flashLoan = new FlashLoanAave(
            aaveAddress
            // uniswapRouterAddress
        );
        console.log("Deployed FlashLoanAave at %s", address(flashLoan));

        // UniswapSimple uniswapSimple = new UniswapSimple(uniswapRouterAddress);
        // console.log("Deployed FlashLoanAave at %s", address(uniswapSimple));
        vm.stopBroadcast();

        return flashLoan;
        // return uniswapSimple;
    }
}

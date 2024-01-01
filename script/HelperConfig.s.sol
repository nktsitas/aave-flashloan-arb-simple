// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MockPoolAddressProvider} from "../test/mocks/MockPoolAddressProvider.sol";
import {MockPool} from "../test/mocks/MockPool.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address aaveAddressProvider;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        // check network chainid and set activeNetworkConfig
        if (block.chainid == 11155111) {
            console.log("Sepolia activated");
            activeNetworkConfig = getSepoliaNetworkConfig();
        } else if (block.chainid == 5) {
            console.log("Goerli activated");
            activeNetworkConfig = getGoerliNetworkConfig();
        } else if (block.chainid == 1) {
            console.log("MAINNET ACTIVATED!!");
            activeNetworkConfig = getMainnetNetworkConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getMainnetNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                aaveAddressProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getSepoliaNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                aaveAddressProvider: 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getGoerliNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                aaveAddressProvider: address(0),
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.aaveAddressProvider != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockPool mockPool = new MockPool();
        MockPoolAddressProvider mockPoolAddressProvider = new MockPoolAddressProvider(
                address(mockPool)
            );
        activeNetworkConfig = NetworkConfig({
            aaveAddressProvider: address(mockPoolAddressProvider),
            deployerKey: vm.envUint("DEFAULT_ANVIL_KEY")
        });
        vm.stopBroadcast();

        console.log(
            "Deployed MockPoolAddressProvider at %s",
            activeNetworkConfig.aaveAddressProvider
        );

        return activeNetworkConfig;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "../lib/forge-std/src/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address aaveAddressProvider;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (isLocalFork()) {
            console.log("Local fork activated");
            activeNetworkConfig = getMainnetLocalForkNetworkConfig();
            return;
        }

        if (block.chainid == 1) {
            console.log("MAINNET ACTIVATED!!");
            activeNetworkConfig = getMainnetNetworkConfig();
            return;
        }

        console.log("Sepolia activated");
        activeNetworkConfig = getSepoliaNetworkConfig();
    }

    function isLocalFork() internal view returns (bool) {
        try vm.envString("LOCAL_FORK") returns (string memory value) {
            return
                keccak256(abi.encodePacked(value)) ==
                keccak256(abi.encodePacked("true"));
        } catch {
            return false;
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

    function getMainnetLocalForkNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                aaveAddressProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
                deployerKey: vm.envUint("DEFAULT_ANVIL_KEY")
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
}

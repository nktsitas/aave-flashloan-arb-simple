// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console} from "../../lib/forge-std/src/Script.sol";

contract MockPoolAddressProvider {
    address public pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool() external view returns (address) {
        console.log("MockPoolAddressProvider.getPool() called");
        console.log("MockPoolAddressProvider.getPool() returns %s", pool);
        return pool;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployFlashLoanAave} from "../../script/DeployFlashLoanAave.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FlashLoanAave} from "../../src/FlashLoanAave.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract FlashLoanAaveTest is Test {
    DeployFlashLoanAave deployer;
    FlashLoanAave flashLoanAave;
    HelperConfig helperConfig;
    uint256 deployerKey;

    address me = 0x407A826D17a4697a767f20e38a6ab72B6E77F012;

    address mainnetUniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address mainnetPancakeswapRouter =
        0x1b81D678ffb9C0263b24A97847620C99d213eB14;

    address mainnetUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address mainnetUSDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address mainnetWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address mainnetETHholder = 0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8;

    address mainnetUSDCholder1 = 0x536154cDC1887C0E402Aa24E1baa8a472155856e;
    address mainnetUSDTholder1 = 0xA7A93fd0a276fc1C0197a5B5623eD117786eeD06;
    address mainnetWETHholder1 = 0x44Cc771fBE10DeA3836f37918cF89368589b6316;

    function setUp() public {
        deployer = new DeployFlashLoanAave();
        (flashLoanAave, helperConfig) = deployer.run();

        (, deployerKey) = helperConfig.activeNetworkConfig();
    }

    function testFlashLoanAave() public {
        address quote = mainnetUSDT;
        address quoteHolder = mainnetUSDTholder1;
        uint256 decimals = 1e6;

        uint256 startAmount = 60 * decimals; // 60 USDC
        uint256 loanAmount = 10000 * decimals; // 10000 USDC
        uint256 remainingAmount = 55 * decimals; // 55 USDC (60 - fee)

        assertEq(
            IERC20(quote).balanceOf(address(flashLoanAave)),
            0,
            "flashLoanAave should have no USDC"
        );

        address tokenOut = mainnetWETH;

        address[] memory routers = new address[](2);
        routers[0] = mainnetUniswapRouter;
        routers[1] = mainnetPancakeswapRouter;

        uint24[] memory fees = new uint24[](2);
        fees[0] = 500;
        fees[1] = 500;

        // flashloan should fail due to insufficient funds to send back (failed arb in tests)
        vm.expectRevert();
        vm.prank(me);
        flashLoanAave.requestFlashLoan(
            quote,
            loanAmount,
            routers[0],
            routers[1],
            tokenOut,
            fees[0],
            fees[1],
            false
        );

        // ---

        vm.prank(quoteHolder);
        quote.call(
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(flashLoanAave),
                startAmount
            )
        );

        assertEq(
            IERC20(quote).balanceOf(address(flashLoanAave)),
            startAmount,
            "flashLoanAave should have the fed amount"
        );

        vm.prank(me);
        flashLoanAave.requestFlashLoan(
            quote,
            loanAmount,
            routers[0],
            routers[1],
            tokenOut,
            fees[0],
            fees[1],
            false
        );

        assertEq(
            IERC20(mainnetWETH).balanceOf(address(flashLoanAave)),
            0,
            "flashLoanAave should have 0 WETH (all swapped back)"
        );

        assertLt(
            IERC20(quote).balanceOf(address(flashLoanAave)),
            remainingAmount,
            "flashLoanAave should have less than fed amount minus the fee (probably failed arb in tests)"
        );

        // test empty out first - transaction should fail (not enough funds cause they're emptied out first)
        vm.prank(me);
        vm.expectRevert();
        flashLoanAave.requestFlashLoan(
            quote,
            loanAmount,
            routers[0],
            routers[1],
            tokenOut,
            fees[0],
            fees[1],
            true
        );
    }

    function testWithdraw() public {
        address[] memory tokens = new address[](2);
        tokens[0] = mainnetUSDC;
        tokens[1] = mainnetWETH;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 * 10e6;
        amounts[1] = 100 * 10e18;

        address[] memory tokenHolders = new address[](2);
        tokenHolders[0] = mainnetUSDCholder1;
        tokenHolders[1] = mainnetWETHholder1;

        for (uint256 i = 0; i < tokens.length; i++) {
            vm.prank(tokenHolders[i]);
            IERC20(tokens[i]).transfer(address(flashLoanAave), amounts[i]);
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(
                IERC20(tokens[i]).balanceOf(address(flashLoanAave)),
                amounts[i],
                "flashLoanAave should have amounts of tokens"
            );
        }

        vm.prank(me);
        flashLoanAave.withdraw(tokens);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(
                IERC20(tokens[i]).balanceOf(address(flashLoanAave)),
                0,
                "flashLoanAave should have no tokens"
            );
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(
                IERC20(tokens[i]).balanceOf(me),
                amounts[i],
                "me should have amounts of tokens"
            );
        }
    }

    function testWithdrawETH() public {
        uint256 amount = 1 * 10e18;

        // transfer ETH to flashLoanAave
        vm.prank(mainnetETHholder);
        payable(address(flashLoanAave)).transfer(amount);

        assertEq(
            address(flashLoanAave).balance,
            amount,
            "flashLoanAave should have amount of ETH"
        );

        vm.expectRevert();
        flashLoanAave.withdrawETH();

        vm.prank(me);
        flashLoanAave.withdrawETH();

        assertEq(
            address(flashLoanAave).balance,
            0,
            "flashLoanAave should now be empty of ETH"
        );

        assertEq(address(me).balance, amount, "I should now have the ETH");
    }
}

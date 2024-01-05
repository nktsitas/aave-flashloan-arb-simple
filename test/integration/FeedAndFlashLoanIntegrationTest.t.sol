// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DeployFlashLoanAave} from "../../script/DeployFlashLoanAave.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FlashLoanAave} from "../../src/FlashLoanAave.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract FeedAndFlashLoanIntegrationTest is Test {
    DeployFlashLoanAave deployer;
    FlashLoanAave flashLoanAave;
    HelperConfig helperConfig;
    uint256 deployerKey;

    address mainnetUSDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address mainnetWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address me = 0x407A826D17a4697a767f20e38a6ab72B6E77F012;
    address mainnetUSDCholder1 = 0x536154cDC1887C0E402Aa24E1baa8a472155856e;

    address mainnetUniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address mainnetPancakeswapRouter =
        0x1b81D678ffb9C0263b24A97847620C99d213eB14;

    function setUp() public {
        deployer = new DeployFlashLoanAave();
        (flashLoanAave, helperConfig) = deployer.run();

        (, deployerKey) = helperConfig.activeNetworkConfig();
    }

    function testFeedPoolAndSwap() public {
        // not the caller
        vm.expectRevert();
        flashLoanAave.requestFlashLoan(
            mainnetUSDC,
            10000e6,
            mainnetPancakeswapRouter,
            mainnetUniswapRouter,
            mainnetWETH,
            500,
            500,
            false
        );

        // not enough assets to pay back
        vm.expectRevert();
        vm.prank(me);
        flashLoanAave.requestFlashLoan(
            mainnetUSDC,
            100000e6,
            mainnetPancakeswapRouter,
            mainnetUniswapRouter,
            mainnetWETH,
            500,
            500,
            false
        );

        // will pass, but will lose assets
        vm.prank(mainnetUSDCholder1);
        IERC20(mainnetUSDC).transfer(address(flashLoanAave), 100e6);

        vm.prank(me);
        flashLoanAave.requestFlashLoan(
            mainnetUSDC,
            10000e6,
            mainnetPancakeswapRouter,
            mainnetUniswapRouter,
            mainnetWETH,
            500,
            500,
            false
        );

        uint256 flashBalance = IERC20(mainnetUSDC).balanceOf(
            address(flashLoanAave)
        );

        // this assumes that we're not extremely unlucky and the moment the anvil chain is spun up, the price is already in our favour. If that's the case, we should respin another anvil chain
        assertLt(
            flashBalance,
            100e6,
            "flashBalance should be less than 100 (failed loan)"
        );

        // empty out flashloan first before retrying
        vm.prank(address(flashLoanAave));
        IERC20(mainnetUSDC).transfer(me, flashBalance);

        flashBalance = IERC20(mainnetUSDC).balanceOf(address(flashLoanAave));

        assertEq(flashBalance, 0, "flashBalance should be back to 0");

        // fake fluctation of price -- swap a lot of WETH for USDC on uniswap, USDC/WETH should now be cheaper on pancakeswap
        vm.startPrank(mainnetUSDCholder1);
        uint256 balance = IERC20(mainnetUSDC).balanceOf(mainnetUSDCholder1);

        uint256 usdcToSwap = 6000000e6;
        IERC20(mainnetUSDC).approve(mainnetUniswapRouter, usdcToSwap);

        ISwapRouter(mainnetUniswapRouter).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: mainnetUSDC,
                tokenOut: mainnetWETH,
                fee: 500,
                recipient: mainnetUSDCholder1,
                deadline: block.timestamp,
                amountIn: usdcToSwap,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        balance = IERC20(mainnetUSDC).balanceOf(mainnetUSDCholder1);
        vm.stopPrank();

        // retry flash loan after fluctuation with no balance in. flashloan should cover itself now!
        vm.prank(me);
        flashLoanAave.requestFlashLoan(
            mainnetUSDC,
            10000e6,
            mainnetPancakeswapRouter,
            mainnetUniswapRouter,
            mainnetWETH,
            500,
            500,
            false
        );

        flashBalance = IERC20(mainnetUSDC).balanceOf(address(flashLoanAave));

        assertGt(
            flashBalance,
            0,
            "flashBalance should be more than 0 (successful loan and arb)"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {DeployFlashLoanAave} from "../script/DeployFlashLoanAave.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {FlashLoanAave} from "../src/FlashLoanAave.sol";
// import {ERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/ERC20.sol";
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
    address mainnetWETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // uint256 usdcDecimals = 10 ** ERC20(mainnetUSDC).decimals();

    address mainnetUSDCholder1 = 0x536154cDC1887C0E402Aa24E1baa8a472155856e;
    address mainnetWETHholder1 = 0x44Cc771fBE10DeA3836f37918cF89368589b6316;

    address goerliUNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address goerliWETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address goerliUNIholder1 = 0xc9d96D21930704cFaB107Ba51EF6093C55ECd242;

    address sepoliaUNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address sepoliaWETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    address sepoliaUNIholder1 = 0x79ea449C3375ED1A9d7D99F8068209eA748C6D42;
    address sepoliaWETHholder1 = 0x287B0e934ed0439E2a7b1d5F0FC25eA2c24b64f7;

    function setUp() public {
        deployer = new DeployFlashLoanAave();
        (flashLoanAave, helperConfig) = deployer.run();

        (, deployerKey) = helperConfig.activeNetworkConfig();
    }

    function testFlashLoanAave() public {
        // address sepoliaUSDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

        uint256 startAmount = 60 * 1e6; // 60 USDC
        uint256 loanAmount = 10000 * 1e6; // 10000 USDC
        uint256 remainingAmount = 55 * 1e6; // 55 USDC (60 - fee)

        assertEq(
            IERC20(mainnetUSDC).balanceOf(address(flashLoanAave)),
            0,
            "flashLoanAave should have no USDC"
        );

        address tokenIn = mainnetUSDC;
        address tokenOut = mainnetWETH;

        uint256 amountIn = loanAmount;
        uint256 amountOutMin = 100000;

        address[] memory routers = new address[](2);
        routers[0] = mainnetUniswapRouter;
        routers[1] = mainnetPancakeswapRouter;

        uint24[] memory fees = new uint24[](2);
        fees[0] = 500;
        fees[1] = 500;

        // flashloan should fail due to insufficient funds to send back (failed arb in tests)
        vm.expectRevert();
        flashLoanAave.requestFlashLoan(
            mainnetUSDC,
            loanAmount,
            routers[0],
            routers[1],
            tokenOut,
            fees[0],
            fees[1],
            0
        );

        // ---

        vm.prank(mainnetUSDCholder1);
        IERC20(mainnetUSDC).transfer(address(flashLoanAave), startAmount);

        assertEq(
            IERC20(mainnetUSDC).balanceOf(address(flashLoanAave)),
            startAmount,
            "flashLoanAave should have the fed amount"
        );

        flashLoanAave.requestFlashLoan(
            mainnetUSDC,
            loanAmount,
            routers[0],
            routers[1],
            tokenOut,
            fees[0],
            fees[1],
            0
        );

        assertEq(
            IERC20(mainnetWETH).balanceOf(address(flashLoanAave)),
            0,
            "flashLoanAave should have 0 WETH (all swapped back)"
        );

        assertLt(
            IERC20(mainnetUSDC).balanceOf(address(flashLoanAave)),
            remainingAmount,
            "flashLoanAave should have less than fed amount minus the fee (probably failed arb in tests)"
        );
    }

    function testPerformSwap() public {
        address testTokenA;
        address testTokenB;

        if (block.chainid == 1) {
            testTokenA = mainnetUSDC;
            testTokenB = mainnetWETH;
        } else if (block.chainid == 11155111) {
            testTokenA = sepoliaUNI;
            testTokenB = sepoliaWETH;
        } else if (block.chainid == 5) {
            testTokenA = goerliUNI;
            testTokenB = goerliWETH;
        } else {
            revert("unsupported chainid");
        }

        uint256 startAmount;
        address prankAddress;
        uint256 amountIn;

        if (block.chainid == 1) {
            startAmount = 60 * 10e6; // 60 USDC
            prankAddress = mainnetUSDCholder1;
            amountIn = 10 * 10e6;
        } else if (block.chainid == 11155111) {
            startAmount = 60 * 10e18; // 60 UNI
            prankAddress = sepoliaUNIholder1;
            amountIn = 10 * 10e18;
        } else if (block.chainid == 5) {
            startAmount = 60 * 10e18; // 60 UNI
            prankAddress = goerliUNIholder1;
            amountIn = 10 * 10e18;
        } else {
            revert("unsupported chainid");
        }

        address contractAddress = address(flashLoanAave);
        // address contractAddress = address(uniswapSimple);

        vm.prank(prankAddress);
        IERC20(testTokenA).transfer(address(contractAddress), startAmount);

        flashLoanAave.performSwap(
            // uniswapSimple.performSwap(
            mainnetUniswapRouter,
            testTokenA,
            testTokenB,
            500,
            amountIn,
            0.00001 ether
        );

        assertEq(
            IERC20(testTokenA).balanceOf(address(contractAddress)),
            startAmount - amountIn,
            "flashLoanAave should have less of starting tokenA"
        );

        assertGt(
            IERC20(testTokenB).balanceOf(address(contractAddress)),
            0,
            "flashLoanAave should have some tokenB"
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
}

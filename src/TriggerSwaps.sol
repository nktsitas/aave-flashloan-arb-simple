// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract UniswapV3Swap {
    ISwapRouter public immutable swapRouter;

    constructor(address _swapRouterAddress) {
        swapRouter = ISwapRouter(_swapRouterAddress);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function executeSwap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external {
        // IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // Low-level call to `approve`
        (bool success, ) = tokenIn.call(
            abi.encodeWithSelector(
                IERC20.approve.selector,
                address(swapRouter),
                amountIn
            )
        );

        // Check if the low-level call was successful
        require(success, "Approval failed");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: recipient,
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });

        swapRouter.exactInputSingle(params);
    }
}

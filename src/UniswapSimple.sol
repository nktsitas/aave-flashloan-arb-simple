// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract UniswapSimple {
    address payable owner;

    ISwapRouter public immutable uniswapRouter;

    constructor(address _uniswapRouterAddress) {
        uniswapRouter = ISwapRouter(_uniswapRouterAddress);
        owner = payable(msg.sender);
    }

    function performSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) public {
        IERC20(_tokenIn).approve(address(uniswapRouter), _amountIn);

        uniswapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            return;
        }
        _;
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(owner, balance);
    }
}

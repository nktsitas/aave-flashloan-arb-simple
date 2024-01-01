// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract FlashLoanAave is FlashLoanSimpleReceiverBase {
    address payable immutable i_owner;

    constructor(
        address _addressProvider
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        i_owner = payable(msg.sender);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address /*initiator*/,
        bytes calldata params
    ) external returns (bool) {
        // we have the funds!

        // approve repayment
        IERC20(asset).approve(address(POOL), amount + premium);

        // extract arb parameters
        (
            address[] memory swapRoutersPath,
            address tokenIn,
            address tokenOut,
            uint24[] memory fees,
            uint256 amountIn,
            uint256 amountOutMin
        ) = abi.decode(
                params,
                (address[], address, address, uint24[], uint256, uint256)
            );

        // execute arb
        // 1st swap (embedded call) - loan amount (tokenIn) to tokenOut
        // 2nd swap - amountOut (tokenOut) back to hopefully more than loan amount (tokenIn)
        performSwap(
            swapRoutersPath[1],
            tokenOut,
            tokenIn,
            fees[1],
            performSwap(
                swapRoutersPath[0],
                tokenIn,
                tokenOut,
                fees[0],
                amountIn,
                amountOutMin
            ),
            amountOutMin
        );

        return true;
    }

    function requestFlashLoan(
        address _token,
        uint256 _amount,
        address[] memory swapRouters,
        address tokenIn,
        address tokenOut,
        uint24[] memory fees,
        uint256 amountIn,
        uint256 amountOutMin
    ) public {
        // Trigger the flashloan with arb parameters
        POOL.flashLoanSimple(
            address(this),
            _token,
            _amount,
            abi.encode(
                swapRouters,
                tokenIn,
                tokenOut,
                fees,
                amountIn,
                amountOutMin
            ),
            0
        );
    }

    function performSwap(
        address _swapRouter,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 amountIn,
        uint256 amountOutMin
    ) public returns (uint256) {
        // Approve the Uniswap router to spend tokenA
        IERC20(_tokenIn).approve(address(ISwapRouter(_swapRouter)), amountIn);

        // Execute the swap from tokenIn to tokenOut and return the amountOut
        return
            ISwapRouter(_swapRouter).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    fee: _fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                })
            );
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            return;
        }
        _;
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(i_owner, balance);
    }

    receive() external payable {}
}

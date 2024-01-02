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
        require(msg.sender == address(POOL), "Caller must be the lending pool");

        // we have the funds!

        // approve repayment
        IERC20(asset).approve(address(POOL), amount + premium);

        // extract arb parameters
        (
            address swapRouterA,
            address swapRouterB,
            address tokenOut,
            uint24 feeA,
            uint24 feeB
        ) = abi.decode(params, (address, address, address, uint24, uint24));

        // execute arb
        // 1st swap (embedded call) - loan amount (tokenIn) to tokenOut
        // 2nd swap - amountOut (tokenOut) back to hopefully more than loan amount (tokenIn)
        performSwap(
            swapRouterB,
            tokenOut,
            asset,
            feeB,
            performSwap(swapRouterA, asset, tokenOut, feeA, amount)
        );

        return true;
    }

    function requestFlashLoan(
        address _token,
        uint256 _amount,
        address swapRouterA,
        address swapRouterB,
        address tokenOut,
        uint24 feeA,
        uint24 feeB
    ) public onlyOwner {
        // Trigger the flashloan with arb parameters
        POOL.flashLoanSimple(
            address(this),
            _token,
            _amount,
            abi.encode(swapRouterA, swapRouterB, tokenOut, feeA, feeB),
            0
        );
    }

    function performSwap(
        address _swapRouter,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee,
        uint256 amountIn
    ) private returns (uint256 amountOut) {
        // Approve the Uniswap router to spend tokenA
        IERC20(_tokenIn).approve(_swapRouter, amountIn);

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
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert("caller is not the owner");
        }
        _;
    }

    function withdraw(address[] memory _tokenAddresses) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            uint256 balance = IERC20(_tokenAddresses[i]).balanceOf(
                address(this)
            );
            if (balance > 0) {
                IERC20(_tokenAddresses[i]).transfer(i_owner, balance);
            }
        }
    }

    function withdrawETH() external onlyOwner {
        i_owner.transfer(address(this).balance);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {console} from "../lib/forge-std/src/Console.sol";

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

        IERC20(asset).approve(address(POOL), amount + premium);

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

        // console.log("balance: ", IERC20(asset).balanceOf(address(this)));
        // console.log("i will pay back: ", amount + premium);

        // console.log("swapRouters address: ", swapRoutersPath[0]);
        // console.log("swapRouters address: ", swapRoutersPath[1]);
        // console.log("tokenIn: ", tokenIn);
        // console.log("tokenOut: ", tokenOut);
        // console.log("amountIn: ", amountIn);
        // console.log("amountOutMin: ", amountOutMin);

        // 1st swap - loan amount (tokenIn) to tokenOut
        // uint256 amountOut = performSwap(
        //     swapRoutersPath[0],
        //     tokenIn,
        //     tokenOut,
        //     fees[0],
        //     amountIn,
        //     amountOutMin
        // );

        // console.log(
        //     "asset1 after swap!: ",
        //     IERC20(asset).balanceOf(address(this))
        // );

        // console.log(
        //     "asset2 after swap!: ",
        //     IERC20(tokenOut).balanceOf(address(this))
        // );

        // console.log("amountOut: ", amountOut);

        // console.log("trading back!");

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

        // console.log(
        //     "asset1 after FINAL swap!: ",
        //     IERC20(asset).balanceOf(address(this))
        // );

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
        // console.log("requesting flash loan!");

        // address receiverAddress = address(this);
        // address asset = _token;
        // uint256 amount = _amount;
        // uint16 referralCode = 0;

        // bytes memory params = abi.encode(
        //     swapRouters,
        //     tokenIn,
        //     tokenOut,
        //     fees,
        //     amountIn,
        //     amountOutMin
        // );

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
        // console.log("performing swap!");

        // ISwapRouter swapRouter = ISwapRouter(_swapRouter);

        // console.log("amountIn: ", amountIn);
        // console.log("amountOutMin: ", amountOutMin);
        // console.log("_tokenIn: ", _tokenIn);
        // console.log("tokenB: ", _tokenOut);

        // Approve the Uniswap router to spend tokenA
        IERC20(_tokenIn).approve(address(ISwapRouter(_swapRouter)), amountIn);

        // console.log("approved!");

        // Set up swap parameters
        // ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        //     .ExactInputSingleParams({
        //         tokenIn: _tokenIn,
        //         tokenOut: _tokenOut,
        //         fee: _fee,
        //         recipient: address(this),
        //         deadline: block.timestamp,
        //         amountIn: amountIn,
        //         amountOutMinimum: amountOutMin,
        //         sqrtPriceLimitX96: 0
        //     });

        // console.log("params set!");

        // Execute the swap from tokenA to tokenB
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

        // return amountOut;

        // console.log("amountOut: ", amountOut);
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

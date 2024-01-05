#!/bin/bash

# FlashLoanAave=0xd573a3e2c4f90c8c6ffbd5c50a8e906177f2dc63
FlashLoanAave=0xb1a865d6777f21b4e8a19dc998193c7e50d33277
Swapper=0x8b9d5a75328b5f3167b04b42ad00092e7d6c485c
SwapRouter=0xE592427A0AEce92De3Edee1F18E0157C05861564
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
holderUSDC=0x536154cDC1887C0E402Aa24E1baa8a472155856e
holderUSDT=0xA7A93fd0a276fc1C0197a5B5623eD117786eeD06
me=0x407A826D17a4697a767f20e38a6ab72B6E77F012

feedAmount=80000000000000
swapAmount=3000000000000

holder=${holderUSDC}
quote=${USDC}

source .env

# cast send 0x407A826D17a4697a767f20e38a6ab72B6E77F012 --value 10ether --private-key $DEFAULT_ANVIL_KEY
cast send ${me} --value 10ether --private-key $DEFAULT_ANVIL_KEY
cast send ${holder} --value 10ether --private-key $DEFAULT_ANVIL_KEY

swapcontractAddress=$(forge create src/TriggerSwaps.sol:UniswapV3Swap --via-ir --private-key $DEFAULT_ANVIL_KEY --constructor-args ${SwapRouter} | grep "Deployed to:" | awk '{print $3}')

echo "swapcontractAddress: ${swapcontractAddress}"

cast rpc anvil_impersonateAccount ${holder}
cast send ${quote} "transfer(address,uint256)" ${swapcontractAddress} ${feedAmount} --unlocked --from ${holder}

echo "feedAmount: ${feedAmount}"

current_time=$(date +%s) && offset=1200 && deadline=$((current_time + offset))
cast send ${swapcontractAddress} "executeSwap(address,address,uint24,address,uint256,uint256,uint256,uint160)" ${quote} ${WETH} 500 ${me} $deadline ${swapAmount} 0 0 --unlocked --from ${holder}


# "templocal"
# current_time=$(date +%s) && offset=1200 && deadline=$((current_time + offset)) && cast send 0x15bb2cc3ea43ab2658f7aaeceb78a9d3769be3cb "executeSwap(address,address,uint24,address,uint256,uint256,uint256,uint160)" 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 500 0x407A826D17a4697a767f20e38a6ab72B6E77F012 $deadline 10000000 0 0 --unlocked --from 0x15bb2cc3ea43ab2658f7aaeceb78a9d3769be3cb
# cast call 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 "balanceOf(address)" 0xB1a865d6777f21B4e8a19Dc998193c7e50d33277
# Create a cast send command to trigger the flash loan based on this signture: function requestFlashLoan(        address _token,        uint256 _amount,        address swapRouterA,        address swapRouterB,        address tokenOut,        uint24 feeA,        uint24 feeB,        bool emptyOutFirst    ) 
# cast send 0xb1a865d6777f21b4e8a19dc998193c7e50d33277 "requestFlashLoan(address,uint256,address,address,address,uint24,uint24,bool)" 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 10000000000 0xE592427A0AEce92De3Edee1F18E0157C05861564 0x1b81D678ffb9C0263b24A97847620C99d213eB14 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 500 500 true --unlocked --from 0x407A826D17a4697a767f20e38a6ab72B6E77F012

#!/bin/bash

FlashLoanAave=0xd573a3e2c4f90c8c6ffbd5c50a8e906177f2dc63
Swapper=0x8b9d5a75328b5f3167b04b42ad00092e7d6c485c
SwapRouter=0xE592427A0AEce92De3Edee1F18E0157C05861564
USDC=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
holder=0x536154cDC1887C0E402Aa24E1baa8a472155856e
me=0x407A826D17a4697a767f20e38a6ab72B6E77F012

feedAmount=80000000000000
swapAmount=3000000000000

source .env

cast send ${me} --value 10ether --private-key $DEFAULT_ANVIL_KEY
cast send ${holder} --value 10ether --private-key $DEFAULT_ANVIL_KEY

swapcontractAddress=$(forge create src/TriggerSwaps.sol:UniswapV3Swap --via-ir --private-key $DEFAULT_ANVIL_KEY --constructor-args ${SwapRouter} | grep "Deployed to:" | awk '{print $3}')

cast rpc anvil_impersonateAccount ${holder}
cast send ${USDC} "transfer(address,uint256)" ${swapcontractAddress} ${feedAmount} --unlocked --from ${holder}

current_time=$(date +%s) && offset=1200 && deadline=$((current_time + offset))

cast send ${swapcontractAddress} "executeSwap(address,address,uint24,address,uint256,uint256,uint256,uint160)" ${USDC} ${WETH} 500 ${me} $deadline ${swapAmount} 0 0 --unlocked --from ${holder}



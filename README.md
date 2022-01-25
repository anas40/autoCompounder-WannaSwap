# Compounder - WannaSwap

:ear_of_rice: Harvest yield, :part_alternation_mark: provide liquidity and :star_struck: deposit into farm with single transaction.

LP yield compounder smart contract created for Wannaswap farm on Aurora blockchain.

## Working

### To Deposit LP

**Step 1** - Approve Compounder to transfer LP token from your account

**Step 2** - Call ```depositLP``` method to transfer LP token from your account to smart contract

**Step 3** - Call ```depositLPtoFarm``` method to transfer LP token from smart contract to dex's farm contract.

### Compound

**Step 1** - Call ```harvestAndCompound``` method to harvest the yield and compound it.

### To Withdraw LP

**Step 1** - Call ```withdrawLPfromFarm``` method to withdraw the lp token from farm contract to this contract

**Step 2** - Call ```withdrawLP``` method to withdraw the lp token and other erc20 token involved from this contract to owner account

## Config

Brownie project

Token addresses can be configured in brownie-config.yaml file and WannaCompounder.sol file

Currently configured for wnear-aurora pair.

Deployed here - [Dapp link Aurora Explorer](https://explorer.mainnet.aurora.dev/address/0x48F9957dB7eb9B58A54baF31C40d4c06b1C05f26/contracts)

**Do not deposit lp, only owner can withdraw**

**Tested on aurora fork**

## Deploy from Remix

[Open in Remix](https://remix.ethereum.org/#url=https://github.com/anas40/autoCompounder-WannaSwap/blob/main/contracts/WannaCompounder.sol)





#pragma version 0.3.10
#pragma evm-version cancun
"""
@title Pendle PT Migration Router
@license Copyright 2023, 2024 Biggest Lab Co Ltd, Benjamin Scherrey, Sajal Kayan, and Eike Caldeweyher
@author BiggestLab (https://biggestlab.io) Benjamin Scherrey
"""

from vyper.interfaces import ERC20
from vyper.interfaces import ERC4626

#gas optimization for swap things can be computed offchain
struct ApproxParams:
    guessMin: uint256 #The minimum value for binary search
    guessMax: uint256 #The maximum value for binary search
    guessOffchain: uint256 #This is the first answer to be checked before performing any binary search. If the answer already satisfies, we skip the search and save significant gas
    maxIteration: uint256 #The maximum number of times binary search will be performed
    eps: uint256 #The precision of binary search - the maximum proportion of the input that can be unused. eps is 1e18-based, so an eps of 1e14 implies that no more than 0.01% of the input might be unused


struct SwapData:
    swapType: uint8
    extRouter: address
    extCalldata: Bytes[100]
    needScale: bool


#Note: "If no aggregator is used, tokenIn = tokenMintSy, pendleSwap = address(0) & swapData is empty"
#This should always be the case for us, so in TokenInput and TokenOutput we dont need to care
# about pendleSwap and swapData as those would be empty.

struct TokenInput:
    tokenIn: address #Always asset in our case
    netTokenIn: uint256 #Amount of assets to "deposit"
    tokenMintSy: address #Should also be asset as we only deal with markets using asset directy
    pendleSwap: address #Address of swap helper, do not hardcode - empty for us
    swapData: SwapData #Empty for us

struct TokenOutput:
    tokenOut: address #Always asset in our case
    minTokenOut: uint256 #Minimum amount of assets to "withdraw"
    tokenRedeemSy: address #Should also be asset as we only deal with markets using asset directy
    pendleSwap: address #Address of swap helper, do not hardcode - empty for us
    swapData: SwapData #Empty for us

struct Order:
    salt: uint256
    expiry: uint256
    nonce: uint256
    orderType: uint8
    token: address
    YT: address
    maker: address
    receiver: address
    makingAmount: uint256
    lnImpliedRate: uint256
    failSafeRate: uint256
    permit: Bytes[100]

struct FillOrderParams:
    order: Order
    signature: Bytes[100]
    makingAmount: uint256

struct LimitOrderData:
    limitRouter: address
    epsSkipMarket: uint256
    normalFills: DynArray[FillOrderParams,1]
    flashFills: DynArray[FillOrderParams,1]
    optData: Bytes[100]


interface PendleRouter:
    #swapExactTokenForPt to swap asset to PT using AMM, docs mention there are
    #bits of the computation that can be done offchan and fed to the call.
    #Likely look for this in version 2 of the adapter.
    def swapExactTokenForPt(receiver: address, market: address, minPtOut: uint256, guessPtOut: ApproxParams, input: TokenInput, limit: LimitOrderData) -> (uint256, uint256, uint256): nonpayable 
    #swapExactPtForToken is used for converting PT to asset, typically to
    #service user withdrawals which would (almost) always occur mid-term
    def swapExactPtForToken(receiver: address, market: address, exactPtIn: uint256, output: TokenOutput, limit: LimitOrderData) -> (uint256, uint256, uint256) : nonpayable
    #RedeemPyToToken: PY stands for PT and YT. However, you no longer need YT post-expiry to redeem.
    #PEGGED: We would use this to redeem all outstanding PT to asset at end of term
    def redeemPyToToken(receiver: address, YT: address, netPyIn: uint256, output: TokenOutput) -> (uint256, uint256): nonpayable
    #PEGGED minting
    def mintPyFromToken(receiver: address, YT: address, minPyOut: uint256, input: TokenInput) -> (uint256, uint256): nonpayable
    #swapExactYtForPt to sell intermidiate YT minted for PT
    def swapExactYtForPt(receiver: address, market: address, exactYtIn: uint256, minPtOut: uint256, guessTotalPtFromSwap: ApproxParams) -> (uint256, uint256): nonpayable


interface PendleMarket:
    def readTokens()  -> (address, address, address): view
    def expiry() -> uint256: view
    #NOTE: Currently markets checked have 1 reward token. If there is more please update the limit below
    def getRewardTokens() -> DynArray[address, 20]: view
    def redeemRewards(user: address) -> DynArray[uint256, 20]: nonpayable


interface AdapterVault:
    def deposit(_asset_amount: uint256, _receiver: address, _min_shares : uint256 = 0, pregen_info: DynArray[Bytes[4096], MAX_ADAPTERS]=empty(DynArray[Bytes[4096], MAX_ADAPTERS])) -> uint256: nonpayable

event PTMigrated:
    user: indexed(address)
    asset: indexed(address)
    vault: indexed(address)
    vault_shares: uint256
    market: address
    pt_amount: uint256

pendleRouter: immutable(address)
MAX_ADAPTERS : constant(uint256) = 5

@external
def __init__(_pendleRouter: address):
    """
    @notice Constructor for the PT Migration Router contract.
    """
    pendleRouter = _pendleRouter

@external
@nonpayable
def migrate(
    market: address, 
    exactPtIn: uint256, 
    asset: address,
    minTokenOut: uint256,
    limit: LimitOrderData,
    vault: address,
    min_shares: uint256,
    pregen_info: DynArray[Bytes[4096], MAX_ADAPTERS]=empty(DynArray[Bytes[4096], MAX_ADAPTERS])
) -> uint256 :
    """
    @notice This function provides a way to "migrate" users existing PT into AdapterVault of same asset
    @param market The pendle market to which the PT being deposited belongs to
    @param asset The asset this PT wraps = same as asset the vault uses
    @param minTokenOut Minimum amount of intermediate step assets
    @param limit This could be populated from pendle's REST API for optimum trade fees.
    @param vault The address of the AdapterVault we are depositing into
    @param min_shares Minmum number of shares that is acceptable. If 0 then apply MAX_SLIPPAGE_PERCENT % allowable slippage.
    @param pregen_info Optional list of bytes to be sent to each adapter. These are usually off-chain computed results which optimize the on-chain call
    @return Share amount deposited to receiver
    @dev
        You would use pendle'2 REST API for limit order, and prepare pregen_info by calling each adapter.
    """

    sy: address = empty(address)
    pt: address = empty(address)
    yt: address = empty(address)
    sy, pt, yt = PendleMarket(market).readTokens()
    #Take users tokens
    ERC20(pt).transferFrom(msg.sender, self, exactPtIn)
    #Perform initial "withdraw"
    ERC20(pt).approve(pendleRouter, exactPtIn)
    netTokenOut: uint256 = 0
    netSyFee: uint256 = 0
    netSyInterm: uint256 = 0

    out: TokenOutput = empty(TokenOutput)
    out.tokenOut = asset
    #setting unlimited slippage for intermediate step is optional as the vault also
    #performs a final slippage check.
    out.minTokenOut = minTokenOut
    out.tokenRedeemSy = asset

    netTokenOut, netSyFee, netSyInterm = PendleRouter(pendleRouter).swapExactPtForToken(self, market, exactPtIn, out, limit)

    #Cant rely on netTokenOut because of rounding issues in tokens like stETH
    actual_out: uint256 = ERC20(asset).balanceOf(self)
    assert actual_out >= minTokenOut, "Balance is lower than minTokenOut"
    #Now do deposit netTokenOut into vault...
    ERC20(asset).approve(vault, actual_out)
    shares_got: uint256 = AdapterVault(vault).deposit(actual_out, msg.sender, min_shares, pregen_info)

    log PTMigrated(
        msg.sender,
        asset,
        vault,
        shares_got,
        market,
        exactPtIn
    )


    return shares_got
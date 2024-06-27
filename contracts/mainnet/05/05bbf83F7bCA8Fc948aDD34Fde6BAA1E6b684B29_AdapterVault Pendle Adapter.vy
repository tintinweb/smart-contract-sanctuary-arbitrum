#pragma version 0.3.10
#pragma evm-version cancun
"""
@title AdapterVault Pendle Adapter
@license Copyright 2023, 2024 Biggest Lab Co Ltd, Benjamin Scherrey, Sajal Kayan, and Eike Caldeweyher
@author BiggestLab (https://biggestlab.io) Sajal Kayan
"""

from vyper.interfaces import ERC20
# import IAdapter as IAdapter

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

struct PregenInfo: #13 words, so 416 bytes. Is there need to compress this for l2? future optimization.
    assumed_asset_amount: uint256 #What asset amount is the below data corresponding to. Doesnt need to be exact
    mint_returns: uint256 #Expected PT gained when converting assumed_asset_amount to PT using mint method
    spot_returns: uint256 #Expected PT gained when converting assumed_asset_amount to PT using AMM method
    approx_params_swapExactYtForPt: ApproxParams #ApproxParams for swapping YT to PT (needed if deposit using mint method)
    approx_params_swapExactTokenForPt: ApproxParams #ApproxParams for swapping token to PT (needed if deposit using AMM method)


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



interface PendleRouterStatic:
    def getPtToAssetRate(market: address) -> uint256: view
    def mintPyFromTokenStatic(YT: address, tokenIn: address, netTokenIn: uint256) -> uint256: view
    def swapExactYtForPtStatic(market: address, exactYtIn: uint256) -> (uint256, uint256, uint256, uint256, uint256): view
    def swapExactTokenForPtStatic(market: address, tokenIn: address, netTokenIn: uint256) -> (uint256, uint256, uint256, uint256, uint256): view

interface PendleMarket:
    def readTokens()  -> (address, address, address): view
    def expiry() -> uint256: view
    #NOTE: Currently markets checked have 1 reward token. If there is more please update the limit below
    def getRewardTokens() -> DynArray[address, 20]: view
    def redeemRewards(user: address) -> DynArray[uint256, 20]: nonpayable

interface SYToken:
    def previewDeposit(tokenIn: address, amountTokenToDeposit: uint256) -> uint256: view
    def previewRedeem(tokenOut: address, amountSharesToRedeem: uint256) -> uint256: view
    def exchangeRate() -> uint256: view
    def deposit(receiver: address, tokenIn: address, amountTokenToDeposit: uint256, minSharesOut: uint256) -> uint256: nonpayable

interface YieldToken:
    def pyIndexStored() -> uint256: view
    def doCacheIndexSameBlock() -> bool: view
    def pyIndexLastUpdatedBlock() -> uint128: view

interface PendlePtLpOracle:
    def getPtToAssetRate(market: address, duration: uint32) -> uint256: view
    def getOracleState(market: address, duration: uint32) -> (bool, uint16, bool): nonpayable


ONE: constant(uint256) = 10**18
TWAP_DURATION: constant(uint32) = 1200
asset: immutable(address)
pendleRouter: immutable(address)
pendleRouterStatic: immutable(address)
pendleMarket: immutable(address)
pendleOracle: immutable(address)
pt_token: immutable(address)
yt_token: immutable(address)
sy_token: immutable(address)
adapterAddr: immutable(address)
#Its immutable in pendle so we cache it here for cheaper access
expiry: immutable(uint256)

@external
def __init__(
    _asset: address,
    _pendleRouter: address,
    _pendleRouterStatic: address,
    _pendleMarket: address,
    _pendleOracle: address
    ):
    _sy: address = empty(address)
    _pt: address = empty(address)
    _yt: address = empty(address)

    _sy, _pt, _yt = PendleMarket(_pendleMarket).readTokens()
    sy_token = _sy
    pt_token = _pt
    yt_token = _yt
    asset = _asset
    pendleOracle = _pendleOracle
    pendleRouter = _pendleRouter
    pendleRouterStatic = _pendleRouterStatic
    pendleMarket = _pendleMarket
    adapterAddr = self
    expiry = PendleMarket(_pendleMarket).expiry()

    #Check oracle's cardinality
    increaseCardinalityRequired: bool= False
    cardinalityRequired: uint16 = 0
    oldestObservationSatisfied: bool = False
    increaseCardinalityRequired, cardinalityRequired, oldestObservationSatisfied = PendlePtLpOracle(pendleOracle).getOracleState(pendleMarket, TWAP_DURATION)
    assert increaseCardinalityRequired == False, "Oracle requires cardinality increase"
    assert oldestObservationSatisfied == True, "Oracle is not bootstrapped sufficiently"

#Workaround because vyper does not allow doing delegatecall from inside view.
#we do a static call instead, but need to fix the correct vault location for queries.
@internal
@view
def vault_location() -> address:
    if self == adapterAddr:
        #if "self" is adapter, meaning this is not delegate call and we treat msg.sender as the vault
        return msg.sender
    #Otherwise we are inside DELEGATECALL, therefore self would be the 4626
    return self



@internal
@view
def assetToPT(asset_amount: uint256) -> uint256:
    if asset_amount == 0:
        #optimization for empty adapter
        return 0
    rate: uint256 = PendlePtLpOracle(pendleOracle).getPtToAssetRate(pendleMarket, TWAP_DURATION)
    pt: uint256 = (asset_amount * ONE) / rate
    return pt

@internal
@view
def PTToAsset(pt: uint256) -> uint256:
    if pt == 0 :
        #optimization for empty adapter
        return 0
    rate: uint256 = PendlePtLpOracle(pendleOracle).getPtToAssetRate(pendleMarket, TWAP_DURATION)
    asset_amount: uint256 = (pt * rate) / ONE
    return asset_amount

@internal
@view
def is_matured() -> bool:
    #upstream solidity logic: return (expiry <= block.timestamp); 
    return expiry <= block.timestamp


@internal
@view
def _assetBalance() -> uint256:
    wrappedBalance: uint256 = ERC20(pt_token).balanceOf(self.vault_location()) #aToken
    unWrappedBalance: uint256 = self.PTToAsset(wrappedBalance) #asset
    return unWrappedBalance


#How much asset can be withdrawn in a single transaction
@external
@view
def maxWithdraw() -> uint256:
    """
    @notice returns the maximum possible asset amount thats withdrawable from Pendle
    @dev
        In case of pendle, all markets allow withdrawals...
    """
    #Should we check for funds availability in the AMM?
    return self._assetBalance()


#How much asset can be deposited in a single transaction
@external
@view
def maxDeposit() -> uint256:
    """
    @notice returns the maximum possible asset amount thats depositable into AAVE
    @dev
        So for Pendle, we would use zero if the market is matured or if its not active.
        Otherwise we send max uint
    """
    if self.is_matured():
        return 0
    return max_value(uint256)

#How much asset this LP is responsible for.
@external
@view
def totalAssets() -> uint256:
    """
    @notice returns the balance currently held by the adapter.
    @dev
        This method returns a valid response if it has been DELEGATECALL or
        STATICCALL-ed from the AdapterVault contract it services. It is not
        intended to be called directly by third parties.
    """
    return self._assetBalance()


@internal
@view
def estimate_spot_returns(asset_amount: uint256) -> uint256:
    """
    @notice estimates the PT amount returned if we based calculation on
    spot price alone, ignoring any slippage.
    """
    # rate: uint256 = PendleRouterStatic(pendleRouterStatic).getPtToAssetRate(pendleMarket)
    netPtOut: uint256 = 0
    netSyMinted: uint256 = 0
    netSyFee: uint256 = 0
    priceImpact: uint256 = 0
    exchangeRateAfter: uint256 = 0
    netPtOut, netSyMinted, netSyFee, priceImpact, exchangeRateAfter = PendleRouterStatic(pendleRouterStatic).swapExactTokenForPtStatic(pendleMarket, asset, asset_amount)
    return netPtOut

@internal
@view
def estimate_mint_returns(asset_amount: uint256) -> (uint256, uint256):
    """
    @notice estimates the PT amount returned if we based calculation on
    minting PY and then swapping the returned YT for PT.
    """
    if self.is_matured():
        #Not possible to mint after maturity
        return 0, 0
    #estimate asset to PY
    py_amount: uint256 = PendleRouterStatic(pendleRouterStatic).mintPyFromTokenStatic(yt_token, asset, asset_amount)
    #Estimate cost of YT to PT
    netPtOut: uint256 = 0
    totalPtSwapped: uint256 = 0
    netSyFee: uint256 = 0
    priceImpact: uint256 = 0
    exchangeRateAfter: uint256 = 0
    netPtOut, totalPtSwapped, netSyFee, priceImpact, exchangeRateAfter = PendleRouterStatic(pendleRouterStatic).swapExactYtForPtStatic(pendleMarket, py_amount)
    return (py_amount + netPtOut), totalPtSwapped

#Deposit the asset into underlying LP
@external
@nonpayable
def deposit(asset_amount: uint256, pregen_info: Bytes[4096]=empty(Bytes[4096])):
    """
    @notice deposit asset into Pendle market.
    @param asset_amount The amount of asset we want to deposit into Pendle market
    @param pregen_info optional argument of data computed off-chain to optimize the on-chain call
    @dev
        This method is only valid if it has been DELEGATECALL-ed
        from the AdapterVault contract it services. It is not intended to be
        called directly by third parties.
    """
    pg: PregenInfo = empty(PregenInfo)
    if len(pregen_info) > 0:
        pg = _abi_decode(pregen_info, PregenInfo)
    else:
        #Info not provided, compute it expensively
        pg.approx_params_swapExactYtForPt = self.default_approx_params()
        pg.approx_params_swapExactTokenForPt = self.default_approx_params()
        ytToPTL: uint256 = 0
        pg.mint_returns, ytToPTL = self.estimate_mint_returns(asset_amount)
        pg.spot_returns = self.estimate_spot_returns(asset_amount)
        #we already paid the tax... why not reuse it...
        pg.approx_params_swapExactTokenForPt.guessOffchain = pg.spot_returns
        pg.approx_params_swapExactYtForPt.guessOffchain = ytToPTL

    #mint if minting price is better, then sell the YT.
    if pg.mint_returns > pg.spot_returns:
        #Mint PY
        inp: TokenInput = empty(TokenInput)
        inp.tokenIn = asset
        inp.netTokenIn = asset_amount
        inp.tokenMintSy = asset

        netPyOut: uint256 = 0
        netSyInterm: uint256 = 0
        ERC20(asset).approve(pendleRouter, asset_amount)
        #Mint PY+PT using asset
        netPyOut, netSyInterm = PendleRouter(pendleRouter).mintPyFromToken(
            self,
            yt_token,
            0,
            inp
        )

        #Swap any YT gained to PT
        ERC20(yt_token).approve(pendleRouter, netPyOut)

        PendleRouter(pendleRouter).swapExactYtForPt(
            self,
            pendleMarket,
            netPyOut,
            0,
            pg.approx_params_swapExactYtForPt
        )

    else:
        #swapExactTokenForPt
        inp: TokenInput = empty(TokenInput)
        inp.tokenIn = asset
        inp.netTokenIn = asset_amount
        inp.tokenMintSy = asset

        limit: LimitOrderData = empty(LimitOrderData)
        ERC20(asset).approve(pendleRouter, asset_amount)
        PendleRouter(pendleRouter).swapExactTokenForPt(
            self,
            pendleMarket,
            0,
            pg.approx_params_swapExactTokenForPt,
            inp,
            limit
        )
        #NOTE: Not doing any checks and balances, minPtOut=0 is intentional.
        #It's up to the vault to revert if it does not like what it sees.

#Withdraw the asset from the LP
@external
@nonpayable
def withdraw(asset_amount: uint256 , withdraw_to: address, pregen_info: Bytes[4096]=empty(Bytes[4096])) -> uint256:
    """
    @notice withdraw asset from AAVE.
    @param asset_amount The amount of asset we want to withdraw from Pendle
    @param withdraw_to The ultimate reciepent of the withdrawn assets
    @param pregen_info optional argument of data computed off-chain to optimize the on-chain call
    @dev
        This method is only valid if it has been DELEGATECALL-ed
        from the AdapterVault contract it services. It is not intended to be
        called directly by third parties.
    """
    #NOTE: accepting pregen_info to satisfy the interface, but there is no need for
    #it during withdraw, unless we find an alternate withdrawal method.

    #Compute the amount of PT we must consume based on oracle
    pt_amount: uint256 = self.assetToPT(asset_amount)
    amount_withdrawn: uint256 = 0
    if self.is_matured():
        #redeemPyToToken
        #No positive slippage possible as we assume 1:1 peg
        ERC20(pt_token).approve(pendleRouter, pt_amount)

        out: TokenOutput = empty(TokenOutput)
        out.tokenOut = asset
        out.minTokenOut = 0 #remember slippage protection is by the vault
        out.tokenRedeemSy = asset

        netTokenOut: uint256 = 0
        netSyInterm: uint256 = 0

        netTokenOut, netSyInterm = PendleRouter(pendleRouter).redeemPyToToken(withdraw_to, yt_token, pt_amount, out)
        amount_withdrawn = netTokenOut
    else:
        #swapExactPtForToken
        #For now we so swapExactPtForToken to the vault, and then keep the positive yield as asset.
        #Would have liked the positive slippage remain as PT...

        ERC20(pt_token).approve(pendleRouter, pt_amount)

        out: TokenOutput = empty(TokenOutput)
        out.tokenOut = asset
        out.minTokenOut = 0 #remember slippage protection is by the vault
        out.tokenRedeemSy = asset

        limit: LimitOrderData = empty(LimitOrderData)

        #positive yield needs to goto the vault, check note above for optimization
        netTokenOut: uint256 = 0
        netSyFee: uint256 = 0
        netSyInterm: uint256 = 0
        netTokenOut, netSyFee, netSyInterm =  PendleRouter(pendleRouter).swapExactPtForToken(self, pendleMarket, pt_amount, out, limit)
        if netTokenOut > asset_amount:
            #Excess remains in vault as asset
            amount_withdrawn = asset_amount
        else:
            #Any slippage from oracle is users responsibility
            amount_withdrawn = netTokenOut
        if withdraw_to != self:
            ERC20(asset).transfer(withdraw_to, amount_withdrawn)

    return amount_withdrawn

@external
def claimRewards(claimant: address):
    """
    @notice hook to claim reward from underlying LP
    @param claimant An address who is to be the ultimate beneficiary of any tokens claimed
    @dev
        runs the IPMarket.redeemRewards method, and sends the loot to provided address
    """
    PendleMarket(pendleMarket).redeemRewards(self)
    tokens: DynArray[address, 20] = PendleMarket(pendleMarket).getRewardTokens()
    for token in tokens:
        if token == pt_token:
            #if its really rewarded in pt, let the vault have that
            continue
        #Assumes reward token is ERC20
        vault_balance: uint256 = ERC20(token).balanceOf(self)
        if vault_balance > 0:
            #A misbehaving token could potentially re-enter here, but
            #there is no harm as we are within the claim call, not touching
            #any vault logic
            ERC20(token).transfer(claimant, vault_balance)

@internal
@pure
def default_approx_params() -> ApproxParams:
    ap: ApproxParams = empty(ApproxParams)
    ap.guessMax = max_value(uint256)
    ap.maxIteration = 256
    ap.eps = 10**14
    return ap

@external
@view
def abi_helper() -> PregenInfo:
    """
    @notice This is just here so the PregenInfo struct is visible in ABI 
    """
    return empty(PregenInfo)

@external
@view
def generate_pregen_info(asset_amount: uint256) -> Bytes[4096]:
    """
    @notice 
        retuns byte data to be precomputed in an off-chain call which is
        to be included during on-chain call. Optimize gas costs.
    @param asset_amount The asset amount that is expected to be deposited or withdrawn 
    """
    #Under ideal situation, we pendle's hosted API to get better paramaters and inject here
    pg: PregenInfo = empty(PregenInfo)
    #Because we assume (approx) all asset amount will either go in or out of single adapter
    pg.assumed_asset_amount = asset_amount
    ytToPT: uint256 = 0
    pg.mint_returns, ytToPT = self.estimate_mint_returns(asset_amount)
    pg.spot_returns = self.estimate_spot_returns(asset_amount)
    
    #Not having approx params costs additional 180k gas (source: https://github.com/pendle-finance/pendle-examples-public/blob/9ce43f4d16003a3ea2a9fe3050e637f0fed64fee/src/StructGen.sol#L14)
    #Check with pendle about guidance on how this precompute works, maybe need to use their REST API

    #Hardcoding defaults
    pg.approx_params_swapExactYtForPt = self.default_approx_params()
    pg.approx_params_swapExactTokenForPt = self.default_approx_params()
    pg.approx_params_swapExactYtForPt.guessOffchain = ytToPT
    pg.approx_params_swapExactTokenForPt.guessOffchain = pg.spot_returns

    return _abi_encode(pg)

@external
@view
def managed_tokens() -> DynArray[address, 10]:
    ret: DynArray[address, 10] = empty(DynArray[address, 10])
    ret.append(pt_token)
    return ret
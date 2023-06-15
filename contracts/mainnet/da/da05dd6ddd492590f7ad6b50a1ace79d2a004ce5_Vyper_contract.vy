# @version 0.3.7
interface IERC20:
    def approve(a: address, b: uint256) -> bool: nonpayable
    def balanceOf(a: address) -> uint256: view
    def allowance(a: address, b: address) -> uint256: view
    def transfer(a: address, b: uint256) -> bool: nonpayable
    def transferFrom(src: address, a: address, b: uint256) -> bool: nonpayable
    def totalSupply() -> uint256: view
    
interface xGRAIL:
    def redeem(a: uint256, b: uint256): nonpayable

# lp token interface
interface ICamelotPair:
    def token0() -> address: nonpayable
    def token1() -> address: nonpayable
    def getReserves() -> (uint112, uint112, uint16, uint16): view
    def balanceOf(a: address) -> uint256: view
    def totalSupply() -> uint256: view
    def approve(a: address, b: uint256) -> bool: nonpayable
    def transfer(a: address, b: uint256) -> bool: nonpayable
    def mint(to: address) -> uint256: nonpayable
    def burn(to: address) -> (uint256, uint256): nonpayable

# lp router interface
interface ICamelotRouter:
    def swapExactTokensForTokensSupportingFeeOnTransferTokens(
        amountIn: uint256,
        amountOutMin: uint256,
        path: address,
        to: address,
        referrer: address,
        deadline: uint256
    ): nonpayable
    def getAmountsOut(
        amountIn: uint256,
        path: address[1024]
    ) -> uint256: view
    def addLiquidity(tokenA: address, tokenB: address, amountADesired: uint256, amountBDesired: uint256, 
        amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable
    def addLiquidityETH(token: address, amountTokenDesired: uint256, amountTokenMin: uint256, 
        amountETHMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable
    def removeLiquidity(tokenA: address, tokenB: address, liquidity: uint256, amountAMin: uint256, 
        amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256): nonpayable
    def removeLiquidityETH(token: address, liquidity: uint256, amountTokenMin: uint256, 
        amountETHMin: uint256, to: address, deadline: uint256) -> (uint256, uint256): nonpayable
    def removeLiquidityWithPermit(tokenA: address, tokenB: address, liquidity: uint256, amountAMin: uint256, 
        amountBMin: uint256, to: address, deadline: uint256, 
        approveMax: bool, v: uint256, r: bytes32, s: bytes32) -> (uint256, uint256): nonpayable
    def removeLiquidityETHWithPermit(token: address, liquidity: uint256, amountTokenMin: uint256, 
        amountETHMin: uint256, to: address, deadline: uint256, 
        approveMax: bool, v: uint256, r: bytes32, s: bytes32) -> (uint256, uint256): nonpayable 
    def getPair(tokenA: address, tokenB: address) -> address: view

interface IUniswapV2Router01:
    def addLiquidity(tokenA: address, tokenB: address, amountADesired: uint256, amountBDesired: uint256, 
        amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable
    def addLiquidityETH(token: address, amountTokenDesired: uint256, amountTokenMin: uint256, 
        amountETHMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable
    def removeLiquidity(tokenA: address, tokenB: address, liquidity: uint256, amountAMin: uint256, 
        amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256): nonpayable
    def removeLiquidityETH(token: address, liquidity: uint256, amountTokenMin: uint256, 
        amountETHMin: uint256, to: address, deadline: uint256) -> (uint256, uint256): nonpayable
    def removeLiquidityWithPermit(tokenA: address, tokenB: address, liquidity: uint256, amountAMin: uint256, 
        amountBMin: uint256, to: address, deadline: uint256, 
        approveMax: bool, v: uint256, r: bytes32, s: bytes32) -> (uint256, uint256): nonpayable
    def removeLiquidityETHWithPermit(token: address, liquidity: uint256, amountTokenMin: uint256, 
        amountETHMin: uint256, to: address, deadline: uint256, 
        approveMax: bool, v: uint256, r: bytes32, s: bytes32) -> (uint256, uint256): nonpayable

# farm factory interface
interface INFTPoolFactory:
    def createPool(lpToken: address) -> address: nonpayable

# farm interface
interface INFTPool:
    def balanceOf(a: address) -> uint256: view
    def ownerOf(tokenId: uint256) -> address: nonpayable
    def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256: view
    def exists(tokenId: uint256) -> bool: nonpayable
    def hasDeposits() -> bool: nonpayable
    def lastTokenId() -> uint256: nonpayable
    def getPoolInfo() -> (
        address, address,address, uint256, uint256,
        uint256, uint256, uint256
    ): nonpayable
    def getStakingPosition(tokenId: uint256) -> (
        uint256, uint256, uint256,
       uint256, uint256, uint256,
        uint256, uint256,
    ): view
    def createPosition(amount: uint256, lockDuration: uint256): nonpayable
    def addToPosition(tokenId: uint256, amountToAdd: uint256): nonpayable
    def withdrawFromPosition(tokenId: uint256, amountToWithdraw: uint256): nonpayable
    def harvestPosition(tokenId: uint256): nonpayable
    def harvestPositionTo(tokenId: uint256, to: address): nonpayable
    def pendingRewards(tokenId: uint256) -> uint256: nonpayable
    def safeTransferFrom(fromAddress: address, to: address, tokenId: uint256): nonpayable

# constants
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to wei

strategy_name: public(String[64])

# common addresses
vault: public(address) # vault address
unirouter: public(address) # uniswap router
owner: public(address) # owner address
fee_recipient: public(address) # fee recipient address

# token addresses
native: public(address) # WETH
want: public(address) # LP token
output: public(address) # reward token
token0: public(address) # token0 of LP token
token1: public(address) # token1 of LP token
xGrail: public(address) # xgrail address

pool_factory: public(address) # farm factory address
reward_pool: public(address) # reward pool address
escrow: public(address) # escrow address

# config
is_paused: public(bool) # pause flag
withdrawal_fee: public(uint256) # withdrawal fee

#states
last_harvest: public(uint256) # last harvest timestamp

# events
event SetVault:
    vault: address
event OwnershipTransferred:
    previousOwner: address
    newOwner: address
event SetUniRouter:
    unirouter: address
event SetFeeRecipient:
    feeRecipient: address
event SetWithdrawalFee:
    withdrawal_fee: uint256
event Deposit:
    lpAmount: uint256
event Withdraw:
    token0Amount: uint256   
    token1Amount: uint256
    outputAmount: uint256
event Harvest:
    harvester: address
    token_id: uint256
    output_harvested: uint256
event AddLiquidity:
    token0: address
    token1: address
    amount0: uint256
    amount1: uint256
    liquidity: uint256
event RemoveLiquidity:
    token0: address
    token1: address
    amount0: uint256
    amount1: uint256
    liquidity: uint256
event NewPool:
    pool: address
event NewPosition:
    tokenId: uint256
    amount: uint256
    pool: address
event AddToPosition:
    tokenId: uint256
    amount: uint256
event WithdrawFromPosition:
    tokenId: uint256
    amount: uint256
event HarvestFromPosition:
    tokenId: uint256
    amount: uint256

struct StrategyConfig:
    strategy_name: String[64]
    token0: address
    token1: address
    native: address
    want: address
    vault: address
    output: address
    escrow: address
    pool_factory: address
    reward_pool: address
    unirouter: address
    fee_recipient: address
    withdrawal_fee: uint256
    is_paused: bool
    xGrail: address


@external
def __init__(
    _config: StrategyConfig
):

    self.owner = msg.sender
    assert _config.vault != empty(address), "Vault address cannot be 0"
    assert _config.unirouter != empty(address), "Unirouter address cannot be 0"
    assert _config.fee_recipient != empty(address), "Fee recipient address cannot be 0"
    assert _config.native != empty(address), "Native address cannot be 0"
    assert _config.output != empty(address), "Output address cannot be 0"   
    assert _config.pool_factory != empty(address), "Pool factory address cannot be 0"
    assert _config.escrow != empty(address), "Escrow address cannot be 0"
    assert _config.token0 != empty(address), "Token0 address cannot be 0"
    assert _config.token1 != empty(address), "Token1 address cannot be 0"

    self.strategy_name = _config.strategy_name
    self.token0 = _config.token0
    self.token1 = _config.token1
    self.native = _config.native
    self.vault = _config.vault
    self.output = _config.output
    self.pool_factory = _config.pool_factory
    self.escrow = _config.escrow
    self.unirouter = _config.unirouter
    self.fee_recipient = _config.fee_recipient
    self.withdrawal_fee = _config.withdrawal_fee
    self.is_paused = _config.is_paused
    self.xGrail = _config.xGrail
    self.want = _config.want

    self.last_harvest = block.timestamp

    self.giveAllowance()

@external
def deposit(token0Amount: uint256, token1Amount: uint256):
    assert not self.is_paused, "Strategy is paused"
    assert msg.sender == self.owner, "Only the owner can call this function"

    # if there is no token0 or token1 in the vault, do nothing
    if token0Amount == 0 or token1Amount == 0:
        return
    
    # add liquidity
    self.addLiquidity(token0Amount, token1Amount)

    # get token pair LP address
    lp_token_address: address = ICamelotRouter(self.unirouter).getPair(self.token0, self.token1)

    self.want = lp_token_address

    # create a new LP pool for staking
    self.newPool(lp_token_address)

    # emit a deposit event
    log Deposit(self.getLPAmount() + self.getStakingPositionLPAmount())

@external
@nonreentrant("withdraw")
def withdraw():
    assert not self.is_paused, "Strategy is paused"
    assert msg.sender == self.owner, "Only the owner can call this function"

    self._withdraw()

@external
def harvest():
    assert not self.is_paused, "Strategy is paused"
    assert block.timestamp - self.last_harvest >= 3600, "Harvest interval not reached"
    assert msg.sender == self.owner, "Only the owner can call this function"

    self._harvest()

@internal
@view
def getTokenId() -> uint256:
    token_id: uint256 = 0
    token_id = INFTPool(self.reward_pool).tokenOfOwnerByIndex(self, 0)
    return token_id
    
@external
def redeemXGrail(a: uint256, b: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    xGRAIL(self.xGrail).redeem(a, b)
    
@external
def request_tokens(token: address, b: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    IERC20(token).transferFrom(self.vault, self, b)

@internal
def _withdraw():
    # get the amount of LP in the vault
    want_amount: uint256 = self.getLPAmount()

    # get the amount of staked LP tokens
    staking_position_lp_amount: uint256 = self.getStakingPositionLPAmount()

    token_id: uint256 = self.getTokenId()
    token0Amount: uint256 = 0
    token1Amount: uint256 = 0

    self._harvest()

    # if there is a staking position, withdraw the LP tokens from the staking position
    if staking_position_lp_amount > 0:
        self.withdrawFromPosition(token_id ,staking_position_lp_amount)

    # swap the LP tokens for token0 and token1
    (token0Amount, token1Amount) = self.removeLiquidity(want_amount)

    # transfer the token0 and token1 from this contract to the vault
    if IERC20(self.token0).balanceOf(self) > 0:
        IERC20(self.token0).transfer(self.vault, IERC20(self.token0).balanceOf(self))
    if  IERC20(self.token1).balanceOf(self) > 0:
        IERC20(self.token1).transfer(self.vault, IERC20(self.token1).balanceOf(self)) 
    if IERC20(self.output).balanceOf(self) > 0:
        IERC20(self.output).transfer(self.vault, IERC20(self.output).balanceOf(self))

    # emit a withdraw event
    log Withdraw(token0Amount, token1Amount, IERC20(self.output).balanceOf(self))

@internal
def _harvest():
    token_id: uint256 = self.getTokenId()

    self.harvestFromPosition(token_id)

    self.last_harvest = block.timestamp

    log Harvest(self, token_id, IERC20(self.output).balanceOf(self))

@internal
def addLiquidity(token0Amount: uint256, token1Amount: uint256):
    assert msg.sender == self.vault, "Only the vault can call this function"
    assert token0Amount > 0, "Amount must be greater than 0"
    assert token1Amount > 0, "Amount must be greater than 0"
    assert IERC20(self.token0).balanceOf(self) >= token0Amount, "Insufficient token0 balance"
    assert IERC20(self.token1).balanceOf(self) >= token1Amount, "Insufficient token1 balance"
    assert IERC20(self.token0).allowance(self, self.unirouter) > 0, "Token0 not approved to unirouter"
    assert IERC20(self.token1).allowance(self, self.unirouter) > 0, "Token1 not approved to unirouter"

    a: uint256 = 0
    b: uint256 = 0
    lp_amount_: uint256 = 0

    a,b,lp_amount_ = ICamelotRouter(self.output).addLiquidity(
        self.token0,
        self.token1,
        token0Amount,
        token1Amount,
        0,
        0,
        self,
        block.timestamp + 3600 # deadline in 1 hour
    )

    assert lp_amount_ > 0, "LP minting failed"

    log AddLiquidity(self.token0, self.token1, token0Amount, token1Amount, lp_amount_)


@internal
def removeLiquidity(lpTokenAmount: uint256) -> (uint256, uint256):
    assert msg.sender == self.vault, "Only the vault can call this function"
    assert lpTokenAmount > 0, "Amount must be greater than 0"
    assert IERC20(self.output).balanceOf(self) >= lpTokenAmount, "Insufficient LP balance"

    token0Amount_: uint256 = 0
    token1Amount_: uint256 = 0

    (token0Amount_, token1Amount_) = ICamelotRouter(self.output).removeLiquidity(
        self.token0,
        self.token1,
        lpTokenAmount,
        0,
        0,
        self,
        block.timestamp + 3600 # deadline in 1 hour
    )

    log RemoveLiquidity(self.token0, self.token1, token0Amount_, token1Amount_, lpTokenAmount)

    return (token0Amount_, token1Amount_)

@internal
def newPool(lp_token_address: address):
    assert msg.sender == self.vault, "Only the vault can call this function"
    assert lp_token_address != empty(address), "LP token address cannot be 0"
    assert IERC20(self.want).balanceOf(self) > 0, "Insufficient LP balance"
    assert IERC20(self.output).allowance(self, self.escrow) > 0, "Output not approved to escrow"

    pool: address = INFTPoolFactory(self.pool_factory).createPool(lp_token_address)

    assert pool != empty(address), "Pool creation failed"

    self.reward_pool = pool

    log NewPool(pool)

@internal
def newPosition(lpTokenAmount: uint256, pool: address):
    assert msg.sender == self.vault, "Only the vault can call this function"
    assert lpTokenAmount > 0, "Amount must be greater than 0"
    assert IERC20(self.want).balanceOf(self) >= lpTokenAmount, "Insufficient LP balance"

    expectedTokenId: uint256 = INFTPool(self.reward_pool).lastTokenId() + 1

    INFTPool(self.reward_pool).createPosition(lpTokenAmount, 0)

    amount_: uint256 = 0
    amountWithMultiplier_: uint256 = 0
    startLockTime_: uint256 = 0
    lockDuration_: uint256 = 0
    lockMultiplier_: uint256 = 0
    rewardDebt_: uint256 = 0
    boostPoints_: uint256 = 0
    totalMultiplier_: uint256 = 0

    amount_, amountWithMultiplier_, startLockTime_ ,lockDuration_ ,lockMultiplier_ ,rewardDebt_ ,boostPoints_ ,totalMultiplier_ = INFTPool(self.reward_pool).getStakingPosition(expectedTokenId)
    assert amount_ == lpTokenAmount, "LP amount mismatch"
    assert lockDuration_ == 0, "Lock duration mismatch"
    INFTPool(self.reward_pool).safeTransferFrom(self, self.vault, expectedTokenId)

    log NewPosition(expectedTokenId, lpTokenAmount, pool)

@internal
def addToPosition(token_id: uint256, lpTokenAmount: uint256):
    assert msg.sender == self.vault, "Only the vault can call this function"
    assert lpTokenAmount > 0, "Amount must be greater than 0"
    assert IERC20(self.output).balanceOf(self) >= lpTokenAmount, "Insufficient LP tokens"
    assert IERC20(self.output).allowance(self, self.reward_pool) > 0, "LP not approved to farm"

    token_balance: uint256 = 0
    token_balance = INFTPool(self.reward_pool).balanceOf(self)

    assert token_balance > 0, "No position owned"
    assert INFTPool(self.reward_pool).ownerOf(token_id) == self, "Position not owned by caller" 

    INFTPool(self.reward_pool).addToPosition(token_id, lpTokenAmount)

    log AddToPosition(token_id, lpTokenAmount)

@internal
def withdrawFromPosition(token_id: uint256, lpTokenAmount: uint256):
    assert msg.sender == self.vault, "Only the vault can call this function"
    assert lpTokenAmount > 0, "Amount must be greater than 0"

    token_balance: uint256 = 0
    token_balance = INFTPool(self.reward_pool).balanceOf(self)

    assert token_balance > 0, "No position owned"
    assert INFTPool(self.reward_pool).ownerOf(token_id) == self, "Position not owned by caller" 

    INFTPool(self.reward_pool).withdrawFromPosition(token_id, lpTokenAmount)

    log WithdrawFromPosition(token_id, lpTokenAmount)

@internal
def harvestFromPosition(token_id: uint256):
    assert msg.sender == self.vault, "Only the vault can call this function"

    token_balance: uint256 = 0
    token_balance = INFTPool(self.reward_pool).balanceOf(self)

    assert token_balance > 0, "No position owned"

    assert INFTPool(self.reward_pool).ownerOf(token_id) == self, "Position not owned by caller"

    INFTPool(self.reward_pool).harvestPositionTo(token_id, self)

    log HarvestFromPosition(token_id, IERC20(self.output).balanceOf(self))

@internal
def giveAllowance():
    assert msg.sender == self.owner, "Only the owner can call this function"
    # approve unirouter to spend token0 and token1 (add liquidity)
    IERC20(self.token0).approve(self.unirouter, max_value(uint256))
    IERC20(self.token1).approve(self.unirouter, max_value(uint256))
    # approve unirouter to spend want (remove liquidity)
    IERC20(self.want).approve(self.unirouter, max_value(uint256))
    # approve escrow to spend output (create position)
    IERC20(self.output).approve(self.escrow, max_value(uint256))

@internal
def removeAllowance():
    assert msg.sender == self.owner, "Only the owner can call this function"
    # remove allowance for unirouter to spend token0 and token1 (add liquidity)
    IERC20(self.token0).approve(self.unirouter, 0)
    IERC20(self.token1).approve(self.unirouter, 0)
    # remove allowance for unirouter to spend want (remove liquidity)
    IERC20(self.want).approve(self.unirouter, 0)
    # remove allowance for escrow to spend output (create position)
    IERC20(self.output).approve(self.escrow, 0)

@internal
@view
def getLPAmount() -> uint256:
    return ICamelotPair(self.want).balanceOf(self)

@internal
@view
def getStakingPositionLPAmount() -> uint256:
    token_balance: uint256 = 0
    token_balance = INFTPool(self.reward_pool).balanceOf(self)
    assert token_balance > 0, "No position owned"
    token_id: uint256 = self.getTokenId()

    # get the lp balance of the nft
    amount_: uint256 = 0
    amountWithMultiplier_: uint256 = 0
    startLockTime_: uint256 = 0
    lockDuration_: uint256 = 0
    lockMultiplier_: uint256 = 0
    rewardDebt_: uint256 = 0
    boostPoints_: uint256 = 0
    totalMultiplier_: uint256 = 0

    amount_, amountWithMultiplier_, startLockTime_ ,lockDuration_ ,lockMultiplier_ ,rewardDebt_ ,boostPoints_ ,totalMultiplier_ = INFTPool(self.reward_pool).getStakingPosition(token_id)

    return amount_

@internal
def getUnderlyingTokensAmountForLP() -> (uint256, uint256):
    # Get the balance of LP tokens
    lp_balance: uint256 = 0
    lp_balance = ICamelotPair(self.want).balanceOf(self)

    # Get the reserves of the underlying assets
    _reserve0: uint112 = 0
    _reserve1: uint112 = 0
    _token0FeePercent: uint16 = 0
    _token1FeePercent: uint16 = 0

    _reserve0, _reserve1, _token0FeePercent, _token1FeePercent = ICamelotPair(self.want).getReserves()
    reserve0: uint256 = convert(_reserve0, uint256)
    reserve1: uint256 = convert(_reserve1, uint256)

    # Calculate the ratio of LP tokens to total supply
    total_supply: uint256 = ICamelotPair(self.want).totalSupply()
    lp_ratio: uint256 = lp_balance * PRECISION / total_supply

    # Calculate the token0 amount based on the current ratio of reserves
    token0Amount: uint256 = lp_ratio * reserve0 / PRECISION + lp_ratio * reserve0 / PRECISION
    token1Amount: uint256 = lp_ratio * reserve1 / PRECISION + lp_ratio * reserve1 / PRECISION

    return token0Amount, token1Amount

@internal
def getUnderlyingTokensAmountForStakingPosition() -> (uint256, uint256):
    token_balance: uint256 = 0
    token_balance = INFTPool(self.reward_pool).balanceOf(self)
    assert token_balance > 0, "No position owned"
    token_id: uint256 = self.getTokenId()

    # get the lp balance of the nft
    amount_: uint256 = 0
    amountWithMultiplier_: uint256 = 0
    startLockTime_: uint256 = 0
    lockDuration_: uint256 = 0
    lockMultiplier_: uint256 = 0
    rewardDebt_: uint256 = 0
    boostPoints_: uint256 = 0
    totalMultiplier_: uint256 = 0

    amount_, amountWithMultiplier_, startLockTime_ ,lockDuration_ ,lockMultiplier_ ,rewardDebt_ ,boostPoints_ ,totalMultiplier_ = INFTPool(self.reward_pool).getStakingPosition(token_id)
    # Calculate the ratio of the LP tokens to the total supply
    total_supply: uint256 = ICamelotPair(self.want).totalSupply()
    lp_ratio: uint256 = amountWithMultiplier_ * PRECISION / total_supply

    # Get the reserves of the underlying assets
    _reserve0: uint112 = 0
    _reserve1: uint112 = 0
    _token0FeePercent: uint16 = 0
    _token1FeePercent: uint16 = 0

    _reserve0, _reserve1, _token0FeePercent, _token1FeePercent = ICamelotPair(self.want).getReserves()
    reserve0: uint256 = convert(_reserve0, uint256)
    reserve1: uint256 = convert(_reserve1, uint256)

    # Calculate the token0 amount based on the current ratio of reserves
    token0Amount: uint256 = lp_ratio * reserve0 / PRECISION + lp_ratio * reserve0 / PRECISION
    token1Amount: uint256 = lp_ratio * reserve1 / PRECISION + lp_ratio * reserve1 / PRECISION

    return token0Amount, token1Amount

@view
@external
def getComponentAmount(token: address) -> uint256:
    lpAmount: uint256 = self.getLPAmount() + self.getStakingPositionLPAmount()
    return IERC20(token).balanceOf(self.want) * lpAmount / IERC20(self.want).totalSupply() 
    
@external
def pause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._pause()

@internal
def _pause():
    self.removeAllowance()
    self.is_paused = True

@external
def unpause():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.giveAllowance()
    self.is_paused = False

@external
@nonreentrant('emergencyWithdraw')
def emergencyWithdraw():
    assert msg.sender == self.owner, "Only the owner can call this function"
    self._withdraw()
    self._pause()

@external
def transferOwnership(new_owner: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    previous_owner: address = self.owner
    self.owner = new_owner
    log OwnershipTransferred(previous_owner, new_owner)

@external
def setStrategyName(strategy_name: String[64]):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.strategy_name = strategy_name

@external
def setVault(vault: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.vault = vault
    log SetVault(vault)

@external
def setUnirouter(unirouter: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.unirouter = unirouter
    log SetUniRouter(unirouter)

@external
def setFeeRecipient(fee_recipient: address):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.fee_recipient = fee_recipient
    log SetFeeRecipient(fee_recipient)

@external
def setWithdrawalFee(withdrawal_fee: uint256):
    assert msg.sender == self.owner, "Only the owner can call this function"
    self.withdrawal_fee = withdrawal_fee
    log SetWithdrawalFee(withdrawal_fee)
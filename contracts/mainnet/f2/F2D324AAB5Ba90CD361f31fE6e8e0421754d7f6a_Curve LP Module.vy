# @version 0.3.7
"""
@title Curve LP Module
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
@notice
    Module to manage the POL's yETH/ETH position.
    Controlled by two roles: management and operator.
    Operator can deposit/withdraw into Curve and subsequently into gauge/Convex/yVault.
    Management can set relevant addresses
"""

from vyper.interfaces import ERC20

interface POL:
    def receive_native(): payable
    def send_native(_receiver: address, _amount: uint256): nonpayable
    def mint(_amount: uint256): nonpayable
    def burn(_amount: uint256): nonpayable

# https://github.com/curvefi/curve-factory/blob/master/contracts/implementations/plain-2/Plain2ETHEMA.vy
interface CurvePool:
    def add_liquidity(_amounts: uint256[2], _min_mint_amount: uint256) -> uint256: payable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[2]) -> uint256[2]: nonpayable
    def remove_liquidity_imbalance(_amounts: uint256[2], _max_burn_amount: uint256) -> uint256: nonpayable

# https://github.com/curvefi/curve-factory/blob/master/contracts/LiquidityGauge.vy
interface CurveGauge:
    def set_rewards_receiver(_receiver: address): nonpayable
    def deposit(_value: uint256): nonpayable
    def withdraw(_value: uint256): nonpayable

# https://github.com/convex-eth/platform/blob/main/contracts/contracts/Booster.sol
interface ConvexBooster:
    def deposit(_pid: uint256, _amount: uint256, _stake: bool) -> bool: nonpayable
    def withdraw(_pid: uint256, _amount: uint256) -> bool: nonpayable

# https://github.com/convex-eth/platform/blob/main/contracts/contracts/BaseRewardPool.sol
interface ConvexRewards:
    def stake(_amount: uint256): nonpayable
    def withdraw(_amount: uint256, _claim: bool): nonpayable
    def withdrawAndUnwrap(_amount: uint256, _claim: bool): nonpayable

# https://github.com/yearn/yearn-vaults/blob/master/contracts/Vault.vy
interface YVault:
    def deposit(_amount: uint256) -> uint256: nonpayable
    def withdraw(_shares: uint256, _recipient: address, _max_loss: uint256) -> uint256: nonpayable

token: public(immutable(address))
pol: public(immutable(address))
management: public(address)
pending_management: public(address)
operator: public(address)
pending_operator: public(address)
pool: public(address)
gauge: public(address)
convex_booster: public(address)
convex_pool_id: public(uint256)
convex_token: public(address)
convex_rewards: public(address)
yvault: public(address)

event SetAddress:
    index: indexed(uint256)
    value: address

event SetConvexPoolId:
    pool_id: indexed(uint256)

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

event PendingOperator:
    operator: indexed(address)

event SetOperator:
    operator: indexed(address)

event FromPOL:
    token: indexed(address)
    amount: uint256

event ToPOL:
    token: indexed(address)
    amount: uint256

event AddLiquidity:
    amounts_in: uint256[2]
    amount_out: uint256

event RemoveLiquidity:
    amount_in: uint256
    amounts_out: uint256[2]

event Deposit:
    pool: indexed(uint256)
    amount_in: uint256
    amount_out: uint256

event Withdraw:
    pool: indexed(uint256)
    amount_in: uint256
    amount_out: uint256

NATIVE: constant(address) = 0x0000000000000000000000000000000000000000
MINT: constant(address)   = 0x0000000000000000000000000000000000000001
BURN: constant(address)   = 0x0000000000000000000000000000000000000002

@external
def __init__(_token: address, _pol: address):
    """
    @notice Constructor
    @param _token yETH token address
    @param _pol POL address
    """
    token = _token
    pol = _pol
    self.management = msg.sender
    self.operator = msg.sender

@external
@payable
def __default__():
    """
    @notice Receive ETH
    """
    pass

@external
def from_pol(_token: address, _amount: uint256):
    """
    @notice Transfer `_amount` of `_token` from POL to this contract
    @param _token 
        Token to transfer out of POL.
        Use special designated values to mint/burn yETH or transfer ETH
    @param _amount Amount of tokens to transfer
    """
    assert msg.sender == self.operator
    if _token == NATIVE:
        POL(pol).send_native(self, _amount)
    elif _token == MINT:
        POL(pol).mint(_amount)
    elif _token == BURN:
        POL(pol).burn(_amount)
    else:
        assert ERC20(_token).transferFrom(pol, self, _amount, default_return_value=True)
    log FromPOL(_token, _amount)

@external
def to_pol(_token: address, _amount: uint256):
    """
    @notice Transfer `_amount` of `_token` to POL from this contract
    @param _token 
        Token to transfer into POL.
        Use special designated value to transfer ETH
    @param _amount Amount of tokens to transfer
    """
    assert msg.sender == self.operator
    if _token == NATIVE:
        POL(pol).receive_native(value=_amount)
    else:
        assert ERC20(_token).transfer(pol, _amount, default_return_value=True)
    log ToPOL(_token, _amount)

@external
def set_operator(_operator: address):
    """
    @notice 
        Set the pending operator address.
        Needs to be accepted by that account separately to transfer operator over
    @param _operator New pending operator address
    """
    assert msg.sender == self.operator or msg.sender == self.management
    self.pending_operator = _operator
    log PendingOperator(_operator)

@external
def accept_operator():
    """
    @notice 
        Accept operator role.
        Can only be called by account previously marked as pending operator by current operator
    """
    assert msg.sender == self.pending_operator
    self.pending_operator = empty(address)
    self.operator = msg.sender
    log SetOperator(msg.sender)

@external
def set_management(_management: address):
    """
    @notice 
        Set the pending management address.
        Needs to be accepted by that account separately to transfer management over
    @param _management New pending management address
    """
    assert msg.sender == self.management
    self.pending_management = _management
    log PendingManagement(_management)

@external
def accept_management():
    """
    @notice 
        Accept management role.
        Can only be called by account previously marked as pending management by current management
    """
    assert msg.sender == self.pending_management
    self.pending_management = empty(address)
    self.management = msg.sender
    log SetManagement(msg.sender)

@external
def remove_allowance(_token: address, _spender: address):
    assert msg.sender == self.operator
    assert ERC20(_token).approve(_spender, 0, default_return_value=True)

# CURVE POOL FUNCTIONS

@external
def set_pool(_pool: address):
    """
    @notice Set Curve yETH/ETH pool
    @param _pool Pool address
    """
    assert msg.sender == self.management
    self.pool = _pool
    log SetAddress(0, _pool)

@external
def approve_pool(_amount: uint256):
    """
    @notice Approve Curve pool to transfer yETH
    @param _amount Amount of tokens to approve
    """
    assert msg.sender == self.operator
    assert self.pool != empty(address)
    assert ERC20(token).approve(self.pool, _amount, default_return_value=True)

@external
def add_liquidity(_amounts: uint256[2], _min_lp: uint256):
    """
    @notice Add liquidity to the Curve pool
    @param _amounts ETH and yETH amounts
    @param _min_lp Minimum amount of LP tokens to receive
    """
    assert msg.sender == self.operator
    lp: uint256 = CurvePool(self.pool).add_liquidity(_amounts, _min_lp, value=_amounts[0])
    log AddLiquidity(_amounts, lp)

@external
def remove_liquidity(_lp_amount: uint256, _min_amounts: uint256[2], _pool: address = empty(address)):
    """
    @notice Remove liquidity from the Curve pool
    @param _lp_amount Amount of LP tokens to redeem
    @param _min_amounts Minimum amounts of ETH and yETH to receive
    """
    assert msg.sender == self.operator
    pool: address = _pool
    if _pool == empty(address):
        pool = self.pool

    amounts: uint256[2] = CurvePool(pool).remove_liquidity(_lp_amount, _min_amounts)
    log RemoveLiquidity(_lp_amount, amounts)

@external
def remove_liquidity_imbalance(_amounts: uint256[2], _max_lp: uint256, _pool: address = empty(address)):
    """
    @notice Remove liquidity from the Curve pool in an imbalanced way
    @param _amounts Amounts of ETH and yETH to receive
    @param _max_lp Maximum amount of LP tokens to redeem
    """
    assert msg.sender == self.operator
    pool: address = _pool
    if _pool == empty(address):
        pool = self.pool

    lp: uint256 = CurvePool(pool).remove_liquidity_imbalance(_amounts, _max_lp)
    log RemoveLiquidity(lp, _amounts)

# GAUGE FUNCTIONS

@external
def set_gauge(_gauge: address):
    """
    @notice Set Curve gauge address
    @param _gauge Gauge address
    """
    assert msg.sender == self.management
    self.gauge = _gauge
    log SetAddress(1, _gauge)

@external
def approve_gauge(_amount: uint256):
    """
    @notice Approve gauge to transfer yETH
    @param _amount Amount of tokens to approve
    """
    assert msg.sender == self.operator
    assert self.gauge != empty(address)
    assert ERC20(self.pool).approve(self.gauge, _amount, default_return_value=True)

@external
def gauge_rewards_receiver():
    """
    @notice Set POL as Curve gauge rewards receiver
    """
    assert msg.sender == self.operator
    CurveGauge(self.gauge).set_rewards_receiver(pol)

@external
def deposit_gauge(_amount: uint256):
    """
    @notice Deposit LP tokens into gauge
    @param _amount Amount of tokens to deposit
    """
    assert msg.sender == self.operator
    CurveGauge(self.gauge).deposit(_amount)
    log Deposit(0, _amount, _amount)

@external
def withdraw_gauge(_amount: uint256, _gauge: address = empty(address)):
    """
    @notice Withdraw LP tokens from gauge
    @param _amount Amount of tokens to withdraw
    """
    assert msg.sender == self.operator
    gauge: address = _gauge
    if _gauge == empty(address):
        gauge = self.gauge

    CurveGauge(gauge).withdraw(_amount)
    log Withdraw(0, _amount, _amount)
    
# CONVEX FUNCTIONS

@external
def set_convex_booster(_booster: address):
    """
    @notice Set Convex booster address
    @param _booster Booster address
    """
    assert msg.sender == self.management
    self.convex_booster = _booster
    log SetAddress(2, _booster)

@external
def set_convex_pool_id(_pool_id: uint256):
    """
    @notice Set pool id for yETH/ETH pool
    @param _pool_id Pool id
    """
    assert msg.sender == self.management
    self.convex_pool_id = _pool_id
    log SetConvexPoolId(_pool_id)

@external
def set_convex_token(_token: address):
    """
    @notice Set Convex pool token
    @param _token Token address
    """
    assert msg.sender == self.management
    self.convex_token = _token
    log SetAddress(3, _token)

@external
def set_convex_rewards(_rewards: address):
    """
    @notice Set Convex rewards address
    @param _rewards Rewards address
    """
    assert msg.sender == self.management
    self.convex_rewards = _rewards
    log SetAddress(4, _rewards)

@external
def approve_convex_booster(_amount: uint256):
    """
    @notice Approve Convex booster to transfer LP tokens
    @param _amount Amount of tokens to approve
    """
    assert msg.sender == self.operator
    assert self.convex_booster != empty(address)
    assert ERC20(self.pool).approve(self.convex_booster, _amount, default_return_value=True)

@external
def deposit_convex_booster(_amount: uint256, _stake: bool):
    """
    @notice Deposit LP tokens into Convex
    @param _amount Amount of tokens to deposit
    """
    assert msg.sender == self.operator
    assert self.convex_pool_id != 0
    ConvexBooster(self.convex_booster).deposit(self.convex_pool_id, _amount, _stake)
    log Deposit(1, _amount, _amount)

@external
def withdraw_convex_booster(_amount: uint256, _booster: address = empty(address), _pool_id: uint256 = 0):
    """
    @notice Withdraw LP tokens from Convex
    @param _amount Amount of tokens to withdraw
    """
    assert msg.sender == self.operator
    booster: address = _booster
    if _booster == empty(address):
        booster = self.convex_booster
    pool_id: uint256 = _pool_id
    if _pool_id == 0:
        pool_id = self.convex_pool_id
        assert pool_id != 0

    ConvexBooster(booster).withdraw(pool_id, _amount)
    log Withdraw(1, _amount, _amount)

@external
def approve_convex_rewards(_amount: uint256):
    """
    @notice Approve Convex rewards contract to transfer Convex LP tokens
    @param _amount Amount of tokens to approve
    """
    assert msg.sender == self.operator
    assert self.convex_rewards != empty(address)
    assert ERC20(self.convex_token).approve(self.convex_rewards, _amount, default_return_value=True)

@external
def deposit_convex_rewards(_amount: uint256):
    """
    @notice Deposit Convex LP tokens into rewards contract
    @param _amount Amount of tokens to deposit
    """
    assert msg.sender == self.operator
    ConvexRewards(self.convex_rewards).stake(_amount)
    log Deposit(2, _amount, _amount)

@external
def withdraw_convex_rewards(_amount: uint256, _unwrap: bool, _rewards: address = empty(address)):
    """
    @notice Withdraw Convex LP tokens from rewards contract
    @param _amount Amount of tokens to withdraw
    @param _unwrap True to also withdraw from Convex booster, False otherwise
    """
    assert msg.sender == self.operator
    rewards: address = _rewards
    if _rewards == empty(address):
        rewards = self.convex_rewards

    if _unwrap:
        ConvexRewards(rewards).withdrawAndUnwrap(_amount, True)
        log Withdraw(1, _amount, _amount)
    else:
        ConvexRewards(rewards).withdraw(_amount, True)
    log Withdraw(2, _amount, _amount)

# YVAULT FUNCTIONS

@external
def set_yvault(_yvault: address):
    """
    @notice Set yearn vault contract
    @param _yvault Yearn vault address
    """
    assert msg.sender == self.management
    self.yvault = _yvault
    log SetAddress(5, _yvault)

@external
def approve_yvault(_amount: uint256):
    """
    @notice Approve Yearn vault to transfer LP tokens
    @param _amount Amount of tokens to approve
    """
    assert msg.sender == self.operator
    assert self.yvault != empty(address)
    assert ERC20(self.pool).approve(self.yvault, _amount, default_return_value=True)

@external
def deposit_yvault(_amount: uint256):
    """
    @notice Deposit LP tokens into Yearn vault
    @param _amount Amount of tokens to deposit
    """
    assert msg.sender == self.operator
    shares: uint256 = YVault(self.yvault).deposit(_amount)
    log Deposit(3, _amount, shares)

@external
def withdraw_yvault(_shares: uint256, _max_loss: uint256, _vault: address = empty(address)):
    """
    @notice Withdraw LP tokens from Yearn vault
    @param _shares Amount of shares to withdraw
    @param _max_loss Max loss during withdrawal
    """
    assert msg.sender == self.operator
    vault: address = _vault
    if _vault == empty(address):
        vault = self.yvault

    amount: uint256 = YVault(vault).withdraw(_shares, self, _max_loss)
    log Withdraw(3, _shares, amount)
# @version ^0.3.7
# (c) Crayon Protocol Authors, 2023

"""
@title Crayon Protocol Desk
"""

from vyper.interfaces import ERC20

MAX_LONGABLES: constant(int128) = 5
MAX_HORIZONS: constant(int128) = 5
MAX_DATA_LENGTH: constant(int128) = 256
BLOCKS_IN_DAY: constant(uint256) = 4 * 60 * 24
BRIDGE_CALLBACK_SUCCESS: constant(bytes32) = keccak256("IBridgeBorrower.on_bridge_loan")
FLASH_CALLBACK_SUCCESS: constant(bytes32) = keccak256("IFlashBorrower.on_flash_loan")
INDEX_PRECISION: constant(uint256) = 27

interface IChainlinkOracle:
    def latestRoundData() -> (uint80, int256, uint256, uint256, uint80): view
    def decimals() -> uint8: view

interface IBridgeBorrower:
    def on_bridge_loan(
        initiator: address,
        token: address,
        amount: uint256,
        data: Bytes[MAX_DATA_LENGTH]
    ) -> bytes32: nonpayable

interface IFlashBorrower:
    def on_flash_loan(
        initiator: address,
        token: address,
        amount: uint256,
        fee: uint256,
        data: Bytes[MAX_DATA_LENGTH]
    ) -> bytes32: nonpayable

interface C_Control:
    def is_c_control() -> bool: view

    def get_reward_parameters(
        desk: address
    ) -> (uint256, uint256): view

    def add_deposit_snapshot(
        _user: address,
        _amount: uint256,
        _provider: address,
        _deposit_reward_index: uint256
    ): nonpayable

    def add_borrow_snapshot(
        _user: address,
        _amount: uint256,
        _provider: address,
        _borrow_reward_index: uint256
    ): nonpayable

event BorrowDeposit:
    borrower: indexed(address)
    longable: indexed(address)
    amount: uint256
    longable_amount: uint256

event Borrow:
    borrower: indexed(address)
    longable: indexed(address)
    amount: uint256

event LongableTokenPosted:
    sender: indexed(address)
    longable: indexed(address)
    longable_amount: uint256

event WithdrawRepay:
    borrower: indexed(address)
    longable: indexed(address)
    amount: uint256
    longable_amount: uint256

event WithdrawLongableToken:
    borrower: indexed(address)
    longable: indexed(address)
    longable_amount: uint256

event Repay:
    borrower: indexed(address)
    longable: indexed(address)
    amount: uint256

event Extend:
    borrower: indexed(address)
    longable: indexed(address)

event Flashloan:
    borrower: indexed(address)
    token: indexed(address)
    amount: uint256

event Lend:
    sender: indexed(address)
    amount: uint256

event Withdraw:
    sender: indexed(address)
    amount: uint256

event Liquidate:
    borrower: indexed(address)
    liquidator: indexed(address)
    longable: indexed(address)
    loan_amount: uint256
    longable_amount: uint256

event NewFee:
    horizon: uint256
    new_fee: uint256

event NewFlashFee:
    new_flash_fee: uint256

event NewLiquidationBonus:
    new_liquidation_bonus: uint256

struct LongableToken:
    is_accepted: bool
    decimals: uint8
    oracle: IChainlinkOracle
    oracle_decimals: uint8
    total: uint256
    growth_index: uint256

struct Position:
    loan_amount: uint256
    long_amount: uint256
    expiration: uint256
    applicable_fee: uint256
    index: uint256

struct Deposit:
    amount: uint256
    index: uint256

# desk attributes
base_coin: public(address)
base_coin_decimals: public(uint8)
value_to_loan_ratio: public(uint256)
flashloan_fee: public(uint256) # bps
liquidation_bonus: public(uint256) # bps
control_contract: public(address)
longables: HashMap[address, LongableToken]
horizons: public(HashMap[uint256, uint256]) # horizon (blocks) => fee (bps)
all_horizons: DynArray[uint256, MAX_HORIZONS]
all_longables: DynArray[address, MAX_LONGABLES]
num_longables: public(int128)
num_horizons: public(int128)

# desk state
total_liquidity: public(uint256)
total_loans: public(uint256)
total_reserved: public(uint256)
growth_index: uint256
borrow_reward_per_block: uint256
deposit_reward_per_block: uint256
deposit_cumul_reward: public(uint256)
borrow_cumul_reward: public(uint256)
reward_last_calculation_block: uint256
reward_params_last_update_block: uint256

# user state
user_deposits: HashMap[address, Deposit]
user_positions: HashMap[address, HashMap[address, Position]] # user => longable (the one used for this position) => Position struct
user_loans: public(HashMap[address, uint256]) # user => total amount of base borrowed by user across all positions
user_reserved: public(HashMap[address, uint256])

@external
def __init__(
    _base_coin: address,
    _base_decimals: uint8,
    _longables: DynArray[address, MAX_LONGABLES],
    _longable_decimals: DynArray[uint8, MAX_LONGABLES],
    _oracles: DynArray[address, MAX_LONGABLES],
    _control_contract: address,
    _value_to_loan_ratio: uint256,
    _flashloan_fee: uint256,
    _liquidation_bonus: uint256,
    _horizons: DynArray[uint256, MAX_HORIZONS], # loan horizons in blocks
    _fees: DynArray[uint256, MAX_HORIZONS]
):
    """
    @dev Most params are specific to this deployment
    @param _base_coin The base ERC20 token for depositing and lending
    @param _base_decimals The base coin decimals
    @param _longables The addresses of the ERC20 tokens that can be posted as collateral for loans
    @param _longable_decimals The decimals corresponding to _longables
    @param _oracles The Chainlink oracles to be used to obtain prices for the tokens accepted as longable
    @param _control_contract The address of the Control contract
    @param _value_to_loan_ratio The minimum the ratio in percent of the value of the posted collateral to the value of a loan can be before the account is subject to liquidation
    @param _flashloan_fee The fee in basis points (0.01%) of a flash loan to be paid by borrowers
    @param _liquidation_bonus The discount in bps applied to longable being acquired by liquidator
    @param _horizons The allowed terms for loans in number of blocks
    @param _fees The fees corresponding to the different horizons
    """

    assert _value_to_loan_ratio >= 100
    assert _flashloan_fee > 0
    assert _base_coin.is_contract
    assert C_Control(_control_contract).is_c_control()
    assert _liquidation_bonus > 0 and 10000 + _liquidation_bonus < _value_to_loan_ratio * 100
    num_longables : uint256 = len(_longables)
    assert num_longables > 0 and num_longables == len(_longable_decimals) and num_longables == len(_oracles)
    num_horizons : uint256 = len(_horizons)
    assert num_horizons > 0 and num_horizons == len(_fees)

    self.base_coin = _base_coin
    self.base_coin_decimals =_base_decimals
    self.value_to_loan_ratio =_value_to_loan_ratio

    self.all_longables = _longables
    self.all_horizons = _horizons
    self.num_longables = convert(num_longables, int128)
    self.num_horizons = convert(num_horizons, int128)
   
    for i in range(MAX_LONGABLES):
        assert _longables[i].is_contract and _oracles[i].is_contract
        orc : IChainlinkOracle = IChainlinkOracle(_oracles[i])
        self.longables[_longables[i]] = LongableToken({is_accepted: True, decimals: _longable_decimals[i], oracle: orc, oracle_decimals: orc.decimals(), total: 0, growth_index: 10**INDEX_PRECISION})
        if i == convert(num_longables, int128) - 1:
            break

    for i in range(MAX_HORIZONS):
        assert _horizons[i] != 0 and _fees[i] != 0
        self.horizons[_horizons[i]] = _fees[i]
        if i == convert(num_horizons, int128) - 1:
            break

    self.control_contract = _control_contract
    self.flashloan_fee = _flashloan_fee
    self.liquidation_bonus = _liquidation_bonus

    # initialize pool state
    self.growth_index = 10**INDEX_PRECISION

@external
@view
def get_horizon_and_fee(
    _i : int128
) -> (uint256, uint256):
    """
    @notice Inquire about horizons and fees
    @param _i Index of horizon and corresponding fee. Use num_horizons for the range
    @return Return (horizon, fee) tuple. horizon is in blocks uints and fee in bps (5 means 0.05%)
    """

    horizon : uint256 = self.all_horizons[_i]
    return horizon, self.horizons[horizon]

@external
@view
def get_longable(
    _i : int128
) -> address:
    """
    @notice Inquire about tokens accepted as longables, i.e., collateral for loans
    @param _i Index of longable. Use num_longables for the range
    @return Return address of an ERC20 token accepted as collateral
    """
    
    return self.all_longables[_i]

@external
@nonreentrant('lock')
def deposit(
    _amount: uint256,
    _provider: address = empty(address)
):
    """
    @notice Deposit base coin into the pool for lending
    @param _amount Amount of base coin being deposited
    @param _provider Front end provider
    """

    assert ERC20(self.base_coin).transferFrom(msg.sender, self, _amount)

    # user state
    user_deposit : Deposit = self.user_deposits[msg.sender]
    temp : uint256 = 0
    if user_deposit.amount != 0:
        temp = user_deposit.amount * self.growth_index / user_deposit.index

    # a deposit cancels funds previsously reserved for withdrawal
    if self.user_reserved[msg.sender] != 0:
        self.user_reserved[msg.sender] = 0

    # send balance at the end of current period just before new deposit is accounted for
    self._send_deposit_snapshot(temp, _provider)

    self.user_deposits[msg.sender].amount = _amount + temp
    self.user_deposits[msg.sender].index = self.growth_index

    # pool state
    self.total_liquidity += _amount

    log Lend(msg.sender, _amount)
    
@external
@nonreentrant('lock')
def withdraw(
    _amount: uint256,
    _provider: address = empty(address)
):
    """
    @notice Withdraw part/all of deposit
    @param _amount Amount of base coin to be withdrawn
    @param _provider Front end provider
    """

    # update user balance
    user_deposit : Deposit = self.user_deposits[msg.sender]
    assert user_deposit.amount != 0
    # retrieve amount user might have reserved during a prior attempt at withdrawal
    user_reserve : uint256 = self.user_reserved[msg.sender]
    # an amount that was reserved gets excluded from accrual
    user_deposit.amount = (user_deposit.amount - user_reserve) * self.growth_index / user_deposit.index + user_reserve
    user_deposit.index = self.growth_index
    _am : uint256 = _amount
    if _am > user_deposit.amount:
        _am = user_deposit.amount
    # if user reserved funds, then this withdrawal must be for those funds
    assert user_reserve == 0 or (_am == user_reserve and _am <= self.total_liquidity) 
    
    self._send_deposit_snapshot(user_deposit.amount, _provider)
    
    if _am <= self.total_liquidity:
        if user_reserve != 0:
            # we required _am == user_reserve in this case
            self.user_reserved[msg.sender] = 0
            self.total_reserved -= _am
        user_deposit.amount -= _am
        self.total_liquidity -= _am
        assert ERC20(self.base_coin).transfer(msg.sender, _am)
    else:
        # user_reserve is 0 in this case given the assertion above
        self.user_reserved[msg.sender] = _am
        self.total_reserved += _am

    self.user_deposits[msg.sender] = user_deposit

    log Withdraw(msg.sender, _amount)

@external
@nonreentrant('lock')
def borrow_then_post_longable(
    _amount: uint256,
    _longable: address,
    _longable_amount: uint256,
    _horizon: uint256,
    _contract: address,
    data: Bytes[MAX_DATA_LENGTH],
    _provider: address = empty(address)
):
    """
    @dev Borrow base coin and post longable satisfying value_to_loan_ratio in one transaction through a smart contract deployed by borrower
    @param _amount The number of base_coin tokens to be borrowed
    @param _longable The address of the ERC20 token that will be posted. Must be one of the acceptable longable tokens for this deployment
    @param _longable_amount The amount of longable to be posted against the loan at the end of the transaction
    @param _horizon The horizon for this loan
    @param _contract The address of the smart contract receiving the loan and that will also provide the required _longable_amount of the longable token
    @param data Opaque calldata to be passed to the contract receiving the loan
    @param _provider Front end provider
    """

    # initiation must come from the receiving contract
    assert _contract == msg.sender

    self._add_position(_amount, _longable, _longable_amount, _horizon, _contract, _provider)

    assert ERC20(self.base_coin).transfer(_contract, _amount)
    assert IBridgeBorrower(_contract).on_bridge_loan(msg.sender, self.base_coin, _amount, data) == BRIDGE_CALLBACK_SUCCESS
    assert ERC20(_longable).transferFrom(_contract, self, _longable_amount)

    log BorrowDeposit(_contract, _longable, _amount, _longable_amount) 

@external
@nonreentrant('lock')
def post_longable_then_borrow(
    _amount: uint256,
    _longable: address,
    _longable_amount: uint256,
    _horizon: uint256,
    _provider: address = empty(address)
):
    """
    @notice Post longable as collateral and borrow against it. Can be used to borrow against excess collateral
    @param _amount The amount of base_coin to borrow
    @param _longable The address of the ERC20 token used as longable
    @param _longable_amount Amount of longable being posted against the loan. Can be 0 if borrowing against longable already posted
    @param _horizon The horizon for this loan
    @param _provider Front end provider
    """

    assert ERC20(_longable).transferFrom(msg.sender, self, _longable_amount)
 
    self._add_position(_amount, _longable, _longable_amount, _horizon, msg.sender, _provider)

    assert ERC20(self.base_coin).transfer(msg.sender, _amount)

    log Borrow(msg.sender, _longable, _amount)

@external
@nonreentrant('lock')
def post_longable(
    _longable_amount: uint256,
    _longable: address,
    longable_owner: address = msg.sender
):
    """
    @notice Post longable, for example, to increase LTV for an existing loan
    @param _longable_amount Amount of longable being deposited
    @param _longable ERC20 token address to use as longable
    @param longable_owner Address to be credited for longable. This can be a borrowing contract
    """

    assert ERC20(_longable).transferFrom(msg.sender, self, _longable_amount)

    self._add_position(0, _longable, _longable_amount, 0, longable_owner, empty(address))

    log LongableTokenPosted(longable_owner, _longable, _longable_amount)

@internal
def _add_position(
    _amount: uint256,
    _longable: address,
    _longable_amount: uint256,
    _horizon: uint256,
    _user: address,
    _provider: address
):
    # check longable
    longable : LongableToken = self.longables[_longable]
    assert longable.is_accepted
    
    # check availability. note that total_reserved could be larger than total_liquidity
    assert _amount == 0 or _amount + self.total_reserved <= self.total_liquidity
    
    # check longable value and update user state
    user_position : Position = self.user_positions[_user][_longable]
    if _longable_amount != 0:
        if user_position.index != 0 and user_position.long_amount != 0:
            user_position.long_amount = user_position.long_amount * longable.growth_index / user_position.index
        user_position.index = longable.growth_index
        user_position.long_amount += _longable_amount
        self.longables[_longable].total += _longable_amount

    if _amount != 0:
        if user_position.loan_amount == 0:
            assert self.horizons[_horizon] != 0
            # if new loan set expiration otherwise additional funds are due at the same time as existing loan
            user_position.expiration = block.number + _horizon
            user_position.applicable_fee = self.horizons[_horizon]

        self._send_borrow_snapshot(_user, self.user_loans[_user], _provider)

        borrow_fee : uint256 = self._borrow_fee(_amount, user_position.applicable_fee)
        new_loan : uint256 = _amount + borrow_fee
        user_position.loan_amount += new_loan
        self._assert_value_to_loan(user_position, longable)
        self.user_loans[_user] += new_loan
        
        # update pool state
        total_deps : uint256 = self._active_deposits()
        self.growth_index = self.growth_index * (total_deps + borrow_fee) / total_deps
        self.total_loans += new_loan
        self.total_liquidity -= _amount

    if user_position.loan_amount == 0:
        user_position.expiration = max_value(uint256)
        
    self.user_positions[_user][_longable] = user_position

@external
@nonreentrant('lock')
def withdraw_longable_then_repay(
    _amount: uint256,
    _longable: address,
    _longable_amount: uint256,
    _contract: address,
    data: Bytes[MAX_DATA_LENGTH],
    _provider: address = empty(address)
):
    """
    @notice Retrieve posted longable and repay loan in one transaction
    @param _amount Amount of base coin to be repaid partially or fully
    @param _longable LongableToken used for loan being repaid
    @param _longable_amount Amount of longable to withdraw
    @param _contract Address of contract that receives longable
    @param data Calldata to longable receiver
    @param _provider Front end provider
    """

    # initiation must come from the receiving contract
    assert _contract == msg.sender

    self._remove_position(_amount, _longable, _longable_amount, _contract, _provider)

    assert ERC20(_longable).transfer(_contract, _longable_amount)
    assert IBridgeBorrower(_contract).on_bridge_loan(msg.sender, _longable, _longable_amount, data) == BRIDGE_CALLBACK_SUCCESS
    assert ERC20(self.base_coin).transferFrom(_contract, self, _amount)

    log WithdrawRepay(_contract, _longable, _amount, _longable_amount)

@external
@nonreentrant('lock')
def withdraw_longable(
    _longable_amount: uint256,
    _longable: address
):
    """
    @notice Withdraw some/all of existing longable posted for a previous loan
    @param _longable_amount Amount to withdraw
    @param _longable LongableToken to withdraw
    """

    self._remove_position(0, _longable, _longable_amount, msg.sender, empty(address))
    
    assert ERC20(_longable).transfer(msg.sender, _longable_amount)

    log WithdrawLongableToken(msg.sender, _longable, _longable_amount)

@external
@nonreentrant('lock')
def repay(
    _amount: uint256,
    _longable: address,
    _provider: address = empty(address),
    _loan_owner: address = msg.sender
):
    """
    @notice Repay part/full loan
    @param _amount Amount of base coin being repaid
    @param _longable LongableToken of loan being repaid
    @param _provider Front end provider
    @param _loan_owner Address that owns the loan
    """

    # user state
    assert ERC20(self.base_coin).transferFrom(msg.sender, self, _amount)

    self._remove_position(_amount, _longable, 0, _loan_owner, _provider)

    log Repay(_loan_owner, _longable, _amount)

@internal
def _remove_position(
    _amount: uint256,
    _longable: address,
    _longable_amount: uint256,
    _user: address,
    _provider: address
):
    longable : LongableToken = self.longables[_longable]
    user_position : Position = self.user_positions[_user][_longable]

    user_position.long_amount = user_position.long_amount * longable.growth_index / user_position.index
    user_position.index = longable.growth_index

    # user state
    user_position.long_amount -= _longable_amount
    # if _amount == 0 then some longable tokens are being withdrawn without any loan being repaid
    if _amount != 0:
        self._send_borrow_snapshot(_user, self.user_loans[_user], _provider)
        user_position.loan_amount -= _amount
        self.user_loans[_user] -= _amount

        # pool state
        self.total_loans -= _amount
        self.total_liquidity += _amount

    if user_position.loan_amount != 0:
        self._assert_value_to_loan(user_position, longable)
    else:
        # no remaining outstanding loan, therefore expiration is 'infinite'
        user_position.expiration = max_value(uint256)

    self.user_positions[_user][_longable] = user_position    
    self.longables[_longable].total -= _longable_amount

@external
def extend_loan(
    _longable: address,
    _horizon: uint256
):
    """
    @notice Extend the life of the loan against _longable longable
    @param _longable Address of longable
    @param _horizon The number in blocks of the new term of the loan. Must be one of the accepted horizons.
    """

    user_position : Position = self.user_positions[msg.sender][_longable]
    # make sure loan amount is not needed to meet withdrawal requests
    assert user_position.loan_amount != 0 and self.total_reserved <= self.total_liquidity
    assert self.horizons[_horizon] != 0

    fee : uint256 = self._borrow_fee(user_position.loan_amount, self.horizons[_horizon])
    user_position.loan_amount += fee
    longable : LongableToken = self.longables[_longable]
    user_position.long_amount = user_position.long_amount * longable.growth_index / user_position.index
    user_position.index = longable.growth_index
    self._assert_value_to_loan(user_position, longable)
    user_position.expiration += _horizon

    self.user_positions[msg.sender][_longable] = user_position
    self.user_loans[msg.sender] += fee
    # update pool state
    total_deps : uint256 = self._active_deposits()
    self.growth_index = self.growth_index * (total_deps + fee) / total_deps
    self.total_loans += fee

    log Extend(msg.sender, _longable)

@external
@nonreentrant('lock')
def flashloan(
    _amount: uint256,
    _token: address,
    _contract: address,
    data: Bytes[MAX_DATA_LENGTH]
):
    """
    @notice Borrow base_coin or a token accepted as longable and pay back loan in one transaction. No fees if _amount is less than amount deposited or posted as collateral by msg.sender
    @param _amount Amount of token to be borrowed
    @param _token The token of interest, base_coin or a token accepted as longable
    @param _contract The smart contract to receive the loan
    @param data Calldata to pass to loan receiver
    """

    # initiation must come from the receiving contract
    assert _contract == msg.sender
    assert _amount != 0

    flash_fee : uint256 = 0
    if _token == self.base_coin:
        assert _amount <= self.total_liquidity
        if _amount > self.user_deposits[msg.sender].amount:
            flash_fee = self._flash_fee(_amount)
            total_deps : uint256 = self._active_deposits()
            self.growth_index = self.growth_index * (total_deps + flash_fee) / total_deps
            self.total_liquidity += flash_fee
    else:
        token : LongableToken = self.longables[_token]
        assert _amount <= token.total
        if _amount > self.user_positions[msg.sender][_token].long_amount:
            flash_fee = self._flash_fee(_amount)
            token.growth_index = token.growth_index * (token.total + flash_fee) / token.total
            token.total += flash_fee
            self.longables[_token] = token
        
    assert ERC20(_token).transfer(msg.sender, _amount)
    assert IFlashBorrower(_contract).on_flash_loan(msg.sender, _token, _amount, flash_fee, data) == FLASH_CALLBACK_SUCCESS
    assert ERC20(_token).transferFrom(msg.sender, self, _amount + flash_fee)

    log Flashloan(msg.sender, _token, _amount)

@external
@view
def borrow_fee(
    _amount: uint256,
    _longable: address,
    _horizon: uint256,
    _is_extend : bool = False
) -> uint256:
    """
    @notice Return the fee that will be charged for borrowing _amount against _longable
    @dev The fee will depend on the horizon unless a loan against _longable is active in which case the fee rate used at the inception of the loan is reapplied
    @param _amount The (new) amount to be borrowed. This is ignored if _is_extend = True
    @param _longable The token that will be deposited against the loan
    @param _horizon The desired horizon. If a loan for msg.sender against _longable is active, then _horizon is ignored and the expiration of the loan is unchanged
    @param _is_extend True means an existing loan is being extended. Default is False.
    """

    am : uint256 = _amount
    user_position : Position = self.user_positions[msg.sender][_longable]
    if not _is_extend and user_position.loan_amount != 0:
        return self._borrow_fee(am, user_position.applicable_fee)
    elif _is_extend:
        am = user_position.loan_amount
    return self._borrow_fee(am, self.horizons[_horizon])

@view
@internal
def _liquidatable(
    _loan_amount: uint256,
    _longable_amount: uint256,
    _longable_decimals: uint8,
    _price: uint256,
    _expiration: uint256
) -> uint256:
    """
    @dev Returns amount of base coin from _user loan that is subject to liquidation
    @param _loan_amount The amount that was borrowed
    @param _longable_amount The current amount of longable token backing the loan
    @param _price The price of longable in the precision of base coin
    @param _expiration The block at which the loan is due
    @return Amount of base coin to be paid to obtain longable worth that amount plus liquidation_bonus / 10000 that amount
    """


    ratio : uint256 = self.value_to_loan_ratio

    if _expiration < block.number:
        return _loan_amount
        # this will leave some longable in the protocol that the owner can recover

    # _longable_value and _loan_amount are expressed with the same precision
    longable_value : uint256 = _longable_amount * _price / 10**convert(_longable_decimals, uint256)
    if longable_value * 100 < ratio * _loan_amount:
        # note that ret > 0
        ret: uint256 = (ratio * 100 * _loan_amount - longable_value * 10000) / (ratio * 100 - 10000 - self.liquidation_bonus) + 1 
        if ret <= _loan_amount:
            return ret
        else:
            return _loan_amount
    else:
        return 0

@internal
def _assert_value_to_loan(
    _user_position : Position,
    _longable : LongableToken
):
    longable_value : uint256 = _user_position.long_amount * self._get_latest_price(_longable.oracle_decimals, _longable.oracle)
    assert longable_value * 100 >= self.value_to_loan_ratio * _user_position.loan_amount * 10**convert(_longable.decimals, uint256)

@internal
@view
def _active_deposits() -> uint256:
    """
    @dev The deposits we take into account when distributing earned fees
    """

    return self.total_liquidity + self.total_loans - self.total_reserved

@view
@external
def liquidatable(
    _user: address,
    _longable: address
) -> uint256:
    """
    @notice Returns amount of base coin from _user loan against _longable that is subject to liquidation
    @param _user The address whose longable can be liquidated
    @param _longable The ERC20 token available at a discount
    @return Amount of base coin to be paid to obtain longable worth that amount plus liquidation_bonus / 10000 that amount
    """

    user_position : Position = self.user_positions[_user][_longable]
    longable : LongableToken = self.longables[_longable]
    price : uint256 = self._get_latest_price(longable.oracle_decimals, longable.oracle)    
    
    return self._liquidatable(user_position.loan_amount, user_position.long_amount * longable.growth_index / user_position.index, longable.decimals, price, user_position.expiration)

@external
@nonreentrant('lock')
def liquidate(
    _user: address,
    _longable: address,
    _amount: uint256
):
    """
    @notice Pay all or part of amount of loan returned by liquidatable()
    @param _user The address whose longable can be liquidated
    @param _longable The longable for the liquidatable loan
    @param _amount The amount of loan to be paid
    """

    user_position : Position = self.user_positions[_user][_longable]
    longable : LongableToken = self.longables[_longable]
    
    user_position.long_amount = user_position.long_amount * longable.growth_index / user_position.index
    user_position.index = longable.growth_index
    price : uint256 = self._get_latest_price(longable.oracle_decimals, longable.oracle)
    max_liquidatable: uint256 = self._liquidatable(user_position.loan_amount, user_position.long_amount, longable.decimals, price, user_position.expiration)

    _am : uint256 = _amount
    if _am >= max_liquidatable:
        _am = max_liquidatable
    
    conv_factor : uint256 = 10**convert(longable.decimals, uint256)
    num_longable : uint256 = _am * (10000 + self.liquidation_bonus) * conv_factor / (10000 * price)
    if num_longable > user_position.long_amount:
        num_longable = user_position.long_amount
        _am = num_longable * 10000 * price / ((10000 + self.liquidation_bonus) * conv_factor)
    assert _am != 0 and num_longable != 0

    user_position.long_amount -= num_longable
    user_position.loan_amount -= _am
    self.user_loans[_user] -= _am
    if user_position.loan_amount == 0:
        user_position.expiration = max_value(uint256)
    self.user_positions[_user][_longable] = user_position

    assert ERC20(self.base_coin).transferFrom(msg.sender, self, _am)
    assert ERC20(_longable).transfer(msg.sender, num_longable)

    log Liquidate(_user, msg.sender, _longable, _amount, num_longable)

@internal
@view
@nonreentrant('lock_oracle')
def _get_latest_price(
    _oracle_decimals: uint8,
    _oracle: IChainlinkOracle
) -> uint256:
    """
    @dev Return price of a unit of longable (10**_longable.decimals) with base_coin decimals precision
    @param oracle The oracle smart contract to call
    @param _oracle_decimals The decimals used to express the price returned by the oracle
    @return The price from _oracle in units of base_coin 
    """
    a: uint80 = 0
    price: int256 = 0
    b: uint256 = 0
    c: uint256 = 0
    d: uint80 = 0
    (a, price, b, c, d) = _oracle.latestRoundData()
    if price < 0:
        price = 0
    p: uint256 = convert(price, uint256)
    if self.base_coin_decimals >= _oracle_decimals:
        return p * 10**convert(self.base_coin_decimals - _oracle_decimals, uint256)
    else:
        return p * 10**convert(self.base_coin_decimals, uint256) / 10**convert(_oracle_decimals, uint256)

@internal
def _update_reward_parameters():
    """
    @dev get deposit and borrow reward parameters per block once a day (roughly) from the Control contract
    """
    last_block : uint256 = self.reward_params_last_update_block
    if last_block != 0 and block.number < last_block + BLOCKS_IN_DAY:
        return

    dep_param : uint256 = 0
    bor_param : uint256 = 0
    bor_param, dep_param  = C_Control(self.control_contract).get_reward_parameters(self)
    self.reward_params_last_update_block = block.number
    self.borrow_reward_per_block = bor_param
    self.deposit_reward_per_block = dep_param

@internal
def _update_cumul_rewards():
    """
    @dev Update cumulative rewards per borrowed unit and per deposited unit and then update reward per block rates if these have been reset in Control contract
    """
    calc_block : uint256 = self.reward_last_calculation_block
    # we apply existing rates per block to the period from the last calculation to the present regardless of whether they were changed in the interim
    if calc_block !=0 and calc_block != block.number:
        block_delta : uint256 = block.number - calc_block
        loans : uint256 = self.total_loans
        deps : uint256 = loans + self.total_liquidity
        if deps != 0:
            self.deposit_cumul_reward += self.deposit_reward_per_block * block_delta / deps
        if loans != 0:
            self.borrow_cumul_reward += self.borrow_reward_per_block * block_delta / loans

    self.reward_last_calculation_block = block.number

    # update rewards per block rates if these have been changed in Control
    self._update_reward_parameters()

@external
def update_cumul_rewards():
    """
    @notice Force an update of the reward indices
    """

    self._update_cumul_rewards()

@internal
def _send_deposit_snapshot(
    _amount: uint256,
    _provider: address
):
    """
    @dev Send current deposit balance and reward index to Control contract to use in calculating rewards over the next period
    @param _amount Deposit at the end of the previous period
    @param _provider Front end provider
    """

    self._update_cumul_rewards()
    # we record the snapshot even if _amount is 0 since we need the deposit_cumul_reward level
    C_Control(self.control_contract).add_deposit_snapshot(msg.sender, _amount, _provider, self.deposit_cumul_reward)

@internal
def _send_borrow_snapshot(
    _user: address,
    _amount: uint256,
    _provider: address
):
    """
    @dev Send current borrowed balance and reward index to Control contract to use in calculating rewards over the next period
    @param _user User who owns the loan. Needed because we allow msg.sender to repay loans for another user
    @param _amount Borrowed balance at the end of the previous period
    @param _provider Font end provider
    """
    
    self._update_cumul_rewards()
    # we record the snapshot even if _amount is 0 since we need the borrow_cumul_reward level
    C_Control(self.control_contract).add_borrow_snapshot(_user, _amount, _provider, self.borrow_cumul_reward)

@internal
@view
def _flash_fee(
    _amount: uint256
) -> uint256:
    ret : uint256 = _amount * self.flashloan_fee / 10000
    assert ret > 0

    return ret

@internal
@view
def _borrow_fee(
    _amount: uint256,
    _applicable_fee: uint256
) -> uint256:
    ret : uint256 = _amount * _applicable_fee / 10000
    assert ret > 0
    
    return ret
    
@external
def set_fee(
    _horizon: uint256,
    _new_fee: uint256
):
    """
    @dev Must have _new_fee > 0 and _horizon must be an existing horizon
    @param _new_fee The new fee for loans
    """

    assert msg.sender == self.control_contract
    # make sure the new fee is being set for an existing horizon. can't change horizons
    assert self.horizons[_horizon] != 0

    self.horizons[_horizon] = _new_fee

    log NewFee(_horizon, _new_fee)

@external
def set_flashloan_fee(
    _new_flashloan_fee: uint256
): 
    """
    @dev Must have _new_flashloan_fee > 0
    @param _new_flashloan_fee The new fee for flashloans
    """

    assert msg.sender == self.control_contract

    self.flashloan_fee = _new_flashloan_fee

    log NewFlashFee(_new_flashloan_fee)

@external
def set_liquidation_bonus(
    _new_liquidation_bonus: uint256
): 
    """
    @dev Must have _new_liquidation_bonus > 0 and 10000 + _new_liquidation_bonus < self.value_to_loan_ratio * 100
    @param _new_liquidation_bonus The new liquidation bonus
    """

    assert msg.sender == self.control_contract

    self.liquidation_bonus = _new_liquidation_bonus

    log NewLiquidationBonus(_new_liquidation_bonus)

@external
@view
def balanceOf(
    _user: address
) -> uint256:
    """
    @notice Get the amount of base_coin the user has on deposit
    @param _user The address of the user -- external address or smart contract
    @return Return the balance. Note that the balance includes "paper" gains by the user
    """

    user_deposit : Deposit = self.user_deposits[_user]
    if user_deposit.amount == 0:
        return 0

    user_reserve : uint256 = self.user_reserved[_user]
    return (user_deposit.amount - user_reserve) * self.growth_index / user_deposit.index + user_reserve

@external
@view
def loanOf(
    _user: address,
    _longable: address
) -> (uint256, uint256, uint256):
    """
    @notice Query a _user's loan position. A borrower can have only one loan position per longable token as collateral
    @param _user The address of the user whose loan position is being queried
    @param _longable The address of the ERC20 token accepted as collateral
    @return Triplet: (loan amount, collateral amount, expiration block for loan). Note that collateral amount includes "paper" gains on the collateral that the user earned
    """

    user_position : Position = self.user_positions[_user][_longable]
    longable : LongableToken = self.longables[_longable]
    if user_position.index == 0:
        # no loan was taken
        return 0, 0,  max_value(uint256)
    return user_position.loan_amount, user_position.long_amount * longable.growth_index / user_position.index, user_position.expiration

@external
@view
def total_longable(
    _longable: address
) -> uint256:
    """
    @notice Query how much _longable the contract is holding. longables are tokens accepted as collateral for loans
    @param _longable The address of the ERC20 token
    @return The total of the _longable token held by the contract
    """

    return self.longables[_longable].total
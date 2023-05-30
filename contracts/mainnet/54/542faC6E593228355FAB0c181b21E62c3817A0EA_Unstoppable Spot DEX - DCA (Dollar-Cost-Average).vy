# @version ^0.3.9

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed
###################################################################
#
# @title Unstoppable Spot DEX - DCA (Dollar-Cost-Average)
# @license GNU AGPLv3
# @author unstoppable.ooo
#
# @custom:security-contact [email protected]
#
# @notice
#    This contract is part of the Unstoppable Spot DEX.
#    It provides the infrastructure for placing permissionless,
#    self-custodial DCA orders for Uni v3 pairs.
#
#    This is an early ALPHA release, use at your own risk!
#
###################################################################


# struct ExactInputParams {
#     bytes path;
#     address recipient;
#     uint256 deadline;
#     uint256 amountIn;
#     uint256 amountOutMinimum;
# }
struct ExactInputParams:
    path: Bytes[66]
    recipient: address
    deadline: uint256
    amountIn: uint256
    amountOutMinimum: uint256


# function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
interface UniswapV3SwapRouter:
    def exactInput(_params: ExactInputParams) -> uint256: payable

interface Univ3Twap:
    def getTwap(_path: DynArray[address, 3], _fees: DynArray[uint24, 2], _twapLength: uint32) -> uint256: view

PRECISISON: constant(uint256) = 10**18

UNISWAP_ROUTER: constant(address) = 0xE592427A0AEce92De3Edee1F18E0157C05861564

TWAP: constant(address) = 0x9edB86AdC192931390EF9c262Db651bA1945Dc52

FEE_BASE: constant(uint256) = 1000000 # 100 percent
fee: public(uint256) # = 1000 # 0.1%

MAX_SLIPPAGE: constant(uint256) = 10000 # 1 percent

# owner
owner: public(address)
suggested_owner: public(address)

# DCA Orders
struct DcaOrder:
    uid: bytes32
    account: address
    token_in: address
    token_out: address
    amount_in_per_execution: uint256
    seconds_between_executions: uint256
    max_number_of_executions: uint8
    max_slippage: uint256
    twap_length: uint32
    number_of_executions: uint8
    last_execution: uint256
    

# user address -> DcaOrder UID
dca_order_uids: public(HashMap[address, DynArray[bytes32, 1024]])
# UID -> DcaOrder
dca_orders: public(HashMap[bytes32, DcaOrder])

is_paused: public(bool)
is_accepting_new_orders: public(bool)

@external
def __init__():
    self.owner = msg.sender
    self.fee = 1000 # 0.1%


event DcaOrderPosted:
    uid: bytes32
    account: indexed(address)
    token_in: indexed(address)
    token_out: indexed(address)
    amount_in_per_execution: uint256
    seconds_between_executions: uint256
    max_number_of_executions: uint8
    twap_length: uint32
    
@external
def post_dca_order(
        _token_in: address,
        _token_out: address,
        _amount_in_per_execution: uint256,
        _seconds_between_executions: uint256,
        _max_number_of_executions: uint8,
        _max_slippage: uint256,
        _twap_length: uint32
    ):

    assert not self.is_paused, "paused"
    assert self.is_accepting_new_orders, "not accepting new orders"

    # check msg.sender approved contract to spend amount token_in
    total: uint256 = convert(_max_number_of_executions, uint256) * _amount_in_per_execution
    allowance: uint256 = ERC20(_token_in).allowance(msg.sender, self)
    assert allowance >= total, "insufficient allowance"

    max_slippage: uint256 = _max_slippage
    if max_slippage == 0:
        max_slippage = MAX_SLIPPAGE
    
    order: DcaOrder = DcaOrder({
        uid: empty(bytes32),
        account: msg.sender,
        token_in: _token_in,
        token_out: _token_out,
        amount_in_per_execution: _amount_in_per_execution,
        seconds_between_executions: _seconds_between_executions,
        max_number_of_executions: _max_number_of_executions,
        max_slippage: _max_slippage,
        twap_length: _twap_length,
        number_of_executions: 0,
        last_execution: 0
    })

    uid: bytes32 = self._uid(order)
    order.uid = uid

    self.dca_orders[uid] = order
    self.dca_order_uids[msg.sender].append(uid)

    log DcaOrderPosted(uid, msg.sender, _token_in, _token_out, _amount_in_per_execution, _seconds_between_executions, _max_number_of_executions, _twap_length)



event DcaOrderExecuted:
    uid: bytes32
    account: indexed(address)
    execution_number: uint8
    amount_in: uint256
    amount_out: uint256

event DcaOrderFailed:
    uid: bytes32
    account: indexed(address)
    reason: String[32]

event DcaCompleted:
    uid: bytes32
    account: indexed(address)

@external
@nonreentrant('lock')
def execute_dca_order(_uid: bytes32, _uni_hop_path: DynArray[address, 3], _uni_pool_fees: DynArray[uint24, 2], _share_profit: bool):
    assert not self.is_paused, "paused"

    order: DcaOrder = self.dca_orders[_uid]
    
    # validate
    assert order.number_of_executions < order.max_number_of_executions, "max executions completed"
    assert order.last_execution + order.seconds_between_executions < block.timestamp, "too soon"

    # ensure path is valid
    assert len(_uni_hop_path) in [2, 3], "[path] invlid path"
    assert len(_uni_pool_fees) == len(_uni_hop_path)-1, "[path] invalid fees"
    assert _uni_hop_path[0] == order.token_in, "[path] invalid token_in"
    assert _uni_hop_path[len(_uni_hop_path)-1] == order.token_out, "[path] invalid token_out"

    # effects
    order.last_execution = block.timestamp
    order.number_of_executions += 1

    self.dca_orders[_uid] = order

    # ensure user has enough token_in
    account_balance: uint256 = ERC20(order.token_in).balanceOf(order.account)
    if account_balance < order.amount_in_per_execution:
        log DcaOrderFailed(_uid, order.account, "insufficient balance")
        self._cancel_dca_order(_uid, "insufficient balance")
        return

    # ensure self has enough allowance to spend amount token_in
    account_allowance: uint256 = ERC20(order.token_in).allowance(order.account, self)
    if account_allowance < order.amount_in_per_execution:
        log DcaOrderFailed(_uid, order.account, "insufficient allowance")
        self._cancel_dca_order(_uid, "insufficient allowance")
        return

    # transfer token_in from user to self
    ERC20(order.token_in).transferFrom(order.account, self, order.amount_in_per_execution)

    # approve UNISWAP_ROUTER to spend amount token_in
    ERC20(order.token_in).approve(UNISWAP_ROUTER, order.amount_in_per_execution)

    # Vyper way to accommodate abi.encode_packed
    path: Bytes[66] = empty(Bytes[66])
    if(len(_uni_hop_path) == 2):
        path = concat(convert(_uni_hop_path[0], bytes20), convert(_uni_pool_fees[0], bytes3), convert(_uni_hop_path[1], bytes20))
    elif(len(_uni_hop_path) == 3):
        path = concat(convert(_uni_hop_path[0], bytes20), convert(_uni_pool_fees[0], bytes3), convert(_uni_hop_path[1], bytes20), convert(_uni_pool_fees[1], bytes3), convert(_uni_hop_path[2], bytes20))
    
    min_amount_out: uint256 = self._calc_min_amount_out(order.amount_in_per_execution, _uni_hop_path, _uni_pool_fees, order.twap_length, order.max_slippage)

    uni_params: ExactInputParams = ExactInputParams({
        path: path,
        recipient: self,
        deadline: block.timestamp,
        amountIn: order.amount_in_per_execution,
        amountOutMinimum: min_amount_out
    })
    amount_out: uint256 = UniswapV3SwapRouter(UNISWAP_ROUTER).exactInput(uni_params)

    # transfer amount_out - fee to user 
    amount_minus_fee: uint256 = amount_out * (FEE_BASE - self.fee) / FEE_BASE
    ERC20(order.token_out).transfer(order.account, amount_minus_fee) 

    # allows searchers to execute for 50% of profits
    if _share_profit:
        profit: uint256 = amount_out - amount_minus_fee
        ERC20(order.token_out).transfer(msg.sender, profit/2)
    
    log DcaOrderExecuted(_uid, order.account, order.number_of_executions, order.amount_in_per_execution, amount_minus_fee)

    if order.number_of_executions == order.max_number_of_executions:
        self._cleanup_order(_uid)
        log DcaCompleted(_uid, order.account)


@view
@external
def calc_min_amount_out(
    _amount_in: uint256, 
    _path: DynArray[address, 3], 
    _fees: DynArray[uint24, 2], 
    _twap_length: uint32, 
    _max_slippage: uint256
    ) -> uint256:
    
    return self._calc_min_amount_out(_amount_in, _path, _fees, _twap_length, _max_slippage)


@view
@internal
def _calc_min_amount_out(
    _amount_in: uint256, 
    _path: DynArray[address, 3], 
    _fees: DynArray[uint24, 2], 
    _twap_length: uint32, 
    _max_slippage: uint256
    ) -> uint256:

    uni_fees_total: uint256 = 0
    for fee in _fees:
        uni_fees_total += convert(fee, uint256)

    token_in_decimals: uint256 = convert(ERC20Detailed(_path[0]).decimals(), uint256)
    twap_value: uint256 = Univ3Twap(TWAP).getTwap(_path, _fees, _twap_length)

    min_amount_out: uint256 = _amount_in * PRECISISON 
    min_amount_out = min_amount_out * twap_value
    min_amount_out = (min_amount_out * (FEE_BASE - uni_fees_total - _max_slippage)) / FEE_BASE
    min_amount_out = min_amount_out / 10**token_in_decimals
    min_amount_out = min_amount_out / PRECISISON

    return min_amount_out


event DcaOrderCanceled:
    uid: bytes32
    reason: String[32]

@external
def cancel_dca_order(_uid: bytes32):
    order: DcaOrder = self.dca_orders[_uid]
    assert order.account == msg.sender, "unauthorized"
    self._cancel_dca_order(_uid, "user canceled")

@internal
def _cancel_dca_order(_uid: bytes32, _reason: String[32]):
    self._cleanup_order(_uid)
    log DcaOrderCanceled(_uid, _reason)


event OrderCleanedUp:
    uid: bytes32
    account: indexed(address)

@internal
def _cleanup_order(_uid: bytes32):
    order: DcaOrder = self.dca_orders[_uid]
    self.dca_orders[_uid] = empty(DcaOrder)

    uids: DynArray[bytes32, 1024] = self.dca_order_uids[order.account]
    for i in range(1024):
        if uids[i] == _uid:
            uids[i] = uids[len(uids) - 1]
            uids.pop()
            break
        if i == len(uids)-1:
            raise
    self.dca_order_uids[order.account] = uids
    
    log OrderCleanedUp(_uid, order.account)


@view
@external
def get_all_open_positions(_account: address) -> DynArray[DcaOrder, 1024]:
    uids: DynArray[bytes32, 1024] = self.dca_order_uids[_account]
    orders: DynArray[DcaOrder, 1024] = empty(DynArray[DcaOrder, 1024])

    for uid in uids:
        orders.append(self.dca_orders[uid])

    return orders


@external
def withdraw_fees(_token: address):
    amount: uint256 = ERC20(_token).balanceOf(self)
    assert amount > 0, "zero balance"

    ERC20(_token).transfer(self.owner, amount)


@external
@view
def uid(_order: DcaOrder) -> bytes32:
    return self._uid(_order)

@internal
@view
def _uid(_order: DcaOrder) -> bytes32:
    # TODO better uid
    position_uid: bytes32 = keccak256(_abi_encode(_order.account, _order.token_in, _order.token_out, block.timestamp))
    return position_uid


#############################
#
#           ADMIN
#
#############################

event Paused: 
    is_paused: bool

@external
def pause(_is_paused: bool):
    assert msg.sender == self.owner, "unauthorized"
    assert _is_paused != self.is_paused, "already in state"

    self.is_paused = _is_paused
    log Paused(_is_paused)


event AcceptingNewOrders: 
    is_accepting_new_orders: bool

@external
def accepting_new_orders(_is_accepting_new_orders: bool):
    assert msg.sender == self.owner, "unauthorized"
    assert _is_accepting_new_orders != self.is_accepting_new_orders, "already in state"

    self.is_accepting_new_orders = _is_accepting_new_orders
    log AcceptingNewOrders(_is_accepting_new_orders)


event NewOwnerSuggested:
    new_owner: indexed(address)
    suggested_by: indexed(address)

@external
def suggest_owner(_new_owner: address):
    """
    @notice
        Step 1 of the 2 step process to transfer ownership.
        Current owner suggests a new owner.
        Requires the new owner to accept ownership in step 2.
    @param _new_owner
        The address of the new owner.
    """
    assert msg.sender == self.owner, "unauthorized"
    assert _new_owner != empty(address), "cannot set owner to zero address"
    self.suggested_owner = _new_owner
    log NewOwnerSuggested(_new_owner, msg.sender)


event OwnershipTransferred:
    new_owner: indexed(address)
    promoted_by: indexed(address)

@external
def accept_ownership():
    """
    @notice
        Step 2 of the 2 step process to transfer ownership.
        The suggested owner accepts the transfer and becomes the
        new owner.
    """
    assert msg.sender == self.suggested_owner, "unauthorized"
    prev_owner: address = self.owner
    self.owner = self.suggested_owner
    log OwnershipTransferred(self.owner, prev_owner)


event FeeUpdated:
    new_fee: uint256

@external
def set_fee(_fee: uint256):
    assert msg.sender == self.owner, "unauthorized"
    assert _fee < FEE_BASE, "invalid fee"
    assert _fee != self.fee, "new fee cannot be same as old fee"
    self.fee = _fee
    log FeeUpdated(_fee)
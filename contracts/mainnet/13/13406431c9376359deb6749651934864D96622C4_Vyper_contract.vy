from vyper.interfaces import ERC20

###################################################################
#
# @title Unstoppable Spot DEX - Limit Orders
# @license GNU AGPLv3
# @author unstoppable.ooo
#
# @custom:security-contact [email protected]
#
# @notice
#    This contract is part of the Unstoppable Spot DEX.
#    It provides the infrastructure for placing permissionless,
#    self-custodial limit orders for Uni v3 pairs.
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


UNISWAP_ROUTER: constant(address) = 0xE592427A0AEce92De3Edee1F18E0157C05861564

# owner
owner: public(address)
suggested_owner: public(address)

# Limit Orders
struct LimitOrder:
    uid: bytes32
    account: address
    token_in: address
    token_out: address
    amount_in: uint256
    min_amount_out: uint256
    valid_until: uint256

# user address -> position UID
limit_order_uids: public(HashMap[address, DynArray[bytes32, 1024]])
# UID -> position
limit_orders: public(HashMap[bytes32, LimitOrder])

is_paused: public(bool)
is_accepting_new_orders: public(bool)

@external
def __init__():
    self.owner = msg.sender


event LimitOrderPosted:
    uid: bytes32
    token_in: indexed(address)
    token_out: indexed(address)
    amount_in: uint256
    min_amount_out: uint256
    valid_until: uint256
    
@external
def post_limit_order(
        _token_in: address,
        _token_out: address,
        _amount_in: uint256,
        _min_amount_out: uint256,
        _valid_until: uint256
    ):

    assert not self.is_paused, "paused"
    assert self.is_accepting_new_orders, "not accepting new orders"

    # validate
    assert _valid_until >= block.timestamp, "invalid timestamp"

    # check msg.sender approved contract to spend amount token_in
    allowance: uint256 = ERC20(_token_in).allowance(msg.sender, self)
    assert allowance >= _amount_in, "insufficient allowance"
    
    order: LimitOrder = LimitOrder({
        uid: empty(bytes32),
        account: msg.sender,
        token_in: _token_in,
        token_out: _token_out,
        amount_in: _amount_in,
        min_amount_out: _min_amount_out,
        valid_until: _valid_until
    })

    uid: bytes32 = self._uid(order)
    order.uid = uid

    self.limit_orders[uid] = order
    self.limit_order_uids[msg.sender].append(uid)

    log LimitOrderPosted(uid, _token_in, _token_out, _amount_in, _min_amount_out, _valid_until)



event LimitOrderExecuted:
    uid: bytes32
    account: indexed(address)

event LimitOrderFailed:
    uid: bytes32
    account: indexed(address)
    reason: String[32]

# def execute_limit_order(_uid: bytes32, _uni_pool_fee: uint24, _share_profit: bool):
@external
def execute_limit_order(_uid: bytes32, _path: DynArray[address, 3], _uni_pool_fees: DynArray[uint24, 2], _share_profit: bool):
    assert not self.is_paused, "paused"

    order: LimitOrder = self.limit_orders[_uid]
    # TODO how to clean up expired orders?
    assert order.valid_until >= block.timestamp, "order expired"

    # ensure path is valid
    assert len(_path) in [2, 3], "[path] invlid path"
    assert len(_uni_pool_fees) == len(_path)-1, "[path] invalid fees"
    assert _path[0] == order.token_in, "[path] invalid token_in"
    assert _path[len(_path)-1] == order.token_out, "[path] invalid token_out"

    # ensure user has enough token_in
    account_balance: uint256 = ERC20(order.token_in).balanceOf(order.account)
    if account_balance < order.amount_in:
        log LimitOrderFailed(_uid, order.account, "insufficient balance")
        self._cancel_limit_order(_uid)
        return

    # ensure self has enough allowance to spend amount token_in
    account_allowance: uint256 = ERC20(order.token_in).allowance(order.account, self)
    if account_allowance < order.amount_in:
        log LimitOrderFailed(_uid, order.account, "insufficient allowance")
        self._cancel_limit_order(_uid)
        return

    # cleanup storage
    self._cleanup_order(_uid)

    # transfer token_in from user to self
    ERC20(order.token_in).transferFrom(order.account, self, order.amount_in)

    # approve UNISWAP_ROUTER to spend amount token_in
    ERC20(order.token_in).approve(UNISWAP_ROUTER, order.amount_in)

    path: Bytes[66] = empty(Bytes[66])
    if(len(_path) == 2):
        path = concat(convert(_path[0], bytes20), convert(_uni_pool_fees[0], bytes3), convert(_path[1], bytes20))
    elif(len(_path) == 3):
        path = concat(convert(_path[0], bytes20), convert(_uni_pool_fees[0], bytes3), convert(_path[1], bytes20), convert(_uni_pool_fees[1], bytes3), convert(_path[2], bytes20))
    

    uni_params: ExactInputParams = ExactInputParams({
        path: path,
        recipient: self,
        deadline: block.timestamp,
        amountIn: order.amount_in,
        amountOutMinimum: order.min_amount_out
    })
    amount_out: uint256 = UniswapV3SwapRouter(UNISWAP_ROUTER).exactInput(uni_params)

    # transfer min_amount_out of token_out from self back to user
    # anything > min_amount_out stays in contract as profit
    ERC20(order.token_out).transfer(order.account, order.min_amount_out) 

    # allows searchers to execute for 50% of profits
    if _share_profit:
        profit: uint256 = amount_out - order.min_amount_out
        ERC20(order.token_out).transfer(msg.sender, profit/2)
    
    log LimitOrderExecuted(_uid, order.account)



event LimitOrderCanceled:
    uid: bytes32

@external
def cancel_limit_order(_uid: bytes32):
    order: LimitOrder = self.limit_orders[_uid]
    assert order.account == msg.sender, "unauthorized"
    self._cancel_limit_order(_uid)

@internal
def _cancel_limit_order(_uid: bytes32):
    self._cleanup_order(_uid)
    log LimitOrderCanceled(_uid)


event OrderCleanedUp:
    uid: bytes32
    account: indexed(address)

@internal
def _cleanup_order(_uid: bytes32):
    order: LimitOrder = self.limit_orders[_uid]
    self.limit_orders[_uid] = empty(LimitOrder)

    uids: DynArray[bytes32, 1024] = self.limit_order_uids[order.account]
    for i in range(1024):
        if uids[i] == _uid:
            uids[i] = uids[len(uids) - 1]
            uids.pop()
            break
        if i == len(uids)-1:
            raise
    self.limit_order_uids[order.account] = uids
    
    log OrderCleanedUp(_uid, order.account)

# TODO def cleanup_exired(_uids: bytes32[])


@view
@external
def get_all_open_positions(_account: address) -> DynArray[LimitOrder, 1024]:
    uids: DynArray[bytes32, 1024] = self.limit_order_uids[_account]
    orders: DynArray[LimitOrder, 1024] = empty(DynArray[LimitOrder, 1024])

    for uid in uids:
        orders.append(self.limit_orders[uid])

    return orders


@external
def withdraw_fees(_token: address):
    amount: uint256 = ERC20(_token).balanceOf(self)
    assert amount > 0, "zero balance"

    ERC20(_token).transfer(self.owner, amount)


@external
@view
def uid(_order: LimitOrder) -> bytes32:
    return self._uid(_order)

@internal
@view
def _uid(_order: LimitOrder) -> bytes32:
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
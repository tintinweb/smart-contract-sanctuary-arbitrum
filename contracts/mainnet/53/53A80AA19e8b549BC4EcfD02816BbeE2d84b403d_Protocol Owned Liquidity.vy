# @version 0.3.7
"""
@title Protocol Owned Liquidity
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
@notice
    Contract to manage the protocol owned liquidity.
    Actual operations are implemented in individual modules, this contract only serves to 
    manage its permissions. Modules can be approved to mint or burn yETH, receive ETH and receive tokens.
    yETH can only be minted up to the debt ceiling, which is determined by the amount of ETH deposited
"""

from vyper.interfaces import ERC20

interface Token:
    def mint(_account: address, _amount: uint256): nonpayable
    def burn(_account: address, _amount: uint256): nonpayable

token: public(immutable(address))
management: public(address)
pending_management: public(address)
available: public(uint256)
debt: public(uint256)
native_allowance: public(HashMap[address, uint256])
mint_allowance: public(HashMap[address, uint256])
burn_allowance: public(HashMap[address, uint256])
killed: public(bool)

NATIVE: constant(address) = 0x0000000000000000000000000000000000000000
MINT: constant(address)   = 0x0000000000000000000000000000000000000001
BURN: constant(address)   = 0x0000000000000000000000000000000000000002

event Mint:
    account: indexed(address)
    amount: uint256

event Burn:
    account: indexed(address)
    amount: uint256

event Approve:
    token: indexed(address)
    spender: indexed(address)
    amount: uint256

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

event Kill: pass

@external
def __init__(_token: address):
    """
    @notice Constructor
    @param _token yETH token address
    """
    token = _token
    self.management = msg.sender

@external
@payable
def __default__():
    """
    @notice Receive ETH and raise debt ceiling
    """
    self.available += msg.value
    pass

@external
@payable
def receive_native():
    """
    @notice Receive ETH without raising the debt ceiling
    @dev Modules should use this when sending back previously received ETH
    """
    pass

@external
def send_native(_receiver: address, _amount: uint256):
    """
    @notice Send ETH
    @param _receiver Account to send the ETH to
    @param _amount Amount of ETH to send
    @dev Requires prior permission by management
    """
    assert _amount > 0
    self.native_allowance[msg.sender] -= _amount
    raw_call(_receiver, b"", value=_amount)

@external
def mint(_amount: uint256):
    """
    @notice Mint yETH
    @param _amount Amount of ETH to mint
    @dev Cannot mint more than the debt ceiling
    @dev Requires prior permission by management
    """
    assert _amount > 0
    assert not self.killed
    self.mint_allowance[msg.sender] -= _amount
    debt: uint256 = self.debt + _amount
    assert debt <= self.available
    self.debt = debt
    Token(token).mint(self, _amount)
    log Mint(msg.sender, _amount)

@external
def burn(_amount: uint256):
    """
    @notice Burn yETH
    @param _amount Amount of yETH to burn
    @dev Requires prior permission by management
    """
    assert _amount > 0
    self.burn_allowance[msg.sender] -= _amount
    self.debt -= _amount
    Token(token).burn(self, _amount)
    log Burn(msg.sender, _amount)

# MANAGEMENT FUNCTIONS

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
def approve(_token: address, _spender: address, _amount: uint256):
    """
    @notice Approve `_spender` to spend `_amount` of `_token` from the POL
    @param _token
        Token to give approval for.
        Use special designated values to set minting/burning/native allowances
    @param _spender Account to give approvel to
    @param _amount Amount of tokens to approve
    """
    self._approve(_token, _spender, _amount)

@external
def increase_allowance(_token: address, _spender: address, _amount: uint256):
    """
    @notice Increase `_spender`s allowance to spend `_token` by `_amount`
    @param _token 
        Token to give increase in allowance for.
        Use special designated values to set minting/burning/native allowances
    @param _spender Account to increase in allowance of
    @param _amount Amount to increase allowance by
    """
    allowance: uint256 = 0
    if _token == NATIVE:
        allowance = self.native_allowance[_spender]
    elif _token == MINT:
        allowance = self.mint_allowance[_spender]
    elif _token == BURN:
        allowance = self.burn_allowance[_spender]
    else:
        allowance = ERC20(_token).allowance(self, _spender)

    self._approve(_token, _spender, allowance + _amount)

@external
def decrease_allowance(_token: address, _spender: address, _amount: uint256):
    """
    @notice Decrease `_spender`s allowance to spend `_token` by `_amount`
    @param _token
        Token to decrease allowance for.
        Use special designated values to set minting/burning/native allowances
    @param _spender Account to decrease allowance of
    @param _amount Amount to decrease allowance by
    @dev If decrease is larger than current allowance, it will be set to zero
    """
    allowance: uint256 = 0
    if _token == NATIVE:
        allowance = self.native_allowance[_spender]
    elif _token == MINT:
        allowance = self.mint_allowance[_spender]
    elif _token == BURN:
        allowance = self.burn_allowance[_spender]
    else:
        allowance = ERC20(_token).allowance(self, _spender)

    if _amount > allowance:
        allowance = 0
    else:
        allowance -= _amount
    self._approve(_token, _spender, allowance)

@internal
def _approve(_token: address, _spender: address, _amount: uint256):
    """
    @notice Approve `_spender` to spend `_amount` of `_token` from the POL
    @param _token
        Token to give approval for.
        Use special designated values to set minting/burning/native allowances
    @param _spender Account to give approvel to
    @param _amount Amount of tokens to approve
    """
    assert msg.sender == self.management
    if _token == NATIVE:
        self.native_allowance[_spender] = _amount
    elif _token == MINT:
        self.mint_allowance[_spender] = _amount
    elif _token == BURN:
        self.burn_allowance[_spender] = _amount
    else:
        ERC20(_token).approve(_spender, _amount)
    log Approve(_token, _spender, _amount)

@external
def kill():
    """
    @notice Kill the POL, permanently disabling yETH minting
    """
    assert msg.sender == self.management
    self.killed = True
    log Kill()
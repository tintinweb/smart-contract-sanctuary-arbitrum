# @version ^0.3.7
# (c) Crayon Protocol Authors, 2023
#
# Based on:
#
# @author Takayuki Jimba (@yudetamago)

"""
@title Crayon Protocol Token
"""

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event NewMinter:
    minter: indexed(address)

event XMinter:
    minter: indexed(address)

event NewOwner:
    new_owner: indexed(address)

NAME: constant(String[32]) = "Crayon Protocol Token"
SYMBOL: constant(String[32]) = "XCRAY"
DECIMALS: constant(uint8) = 27
MAX_SUPPLY: constant(uint256) = 21000000 * 10 ** DECIMALS

name: public(String[32])
symbol: public(String[32])
decimals: public(uint8)
max_supply: public(uint256)

# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.
#       The _KeyType will become a required parameter for the getter and it will return _ValueType.
#       See: https://vyper.readthedocs.io/en/v0.1.0-beta.8/types.html?highlight=getter#mappings
balanceOf: public(HashMap[address, uint256])
# By declaring `allowance` as public, vyper automatically generates the `allowance()` getter
allowance: public(HashMap[address, HashMap[address, uint256]])
# By declaring `totalSupply` as public, we automatically create the `totalSupply()` getter
totalSupply: public(uint256)
is_minter: public(HashMap[address, bool])
admin: public(address)


@external
def __init__(_dev_account: address):
    self.admin = msg.sender
    _dev_amount : uint256 = MAX_SUPPLY / 5
    self.balanceOf[_dev_account] = _dev_amount
    self.totalSupply = _dev_amount
    self.is_minter[self.admin] = True

    self.name = NAME
    self.symbol = SYMBOL
    self.decimals = DECIMALS
    self.max_supply = MAX_SUPPLY

    log Transfer(empty(address), _dev_account, _dev_amount)

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    
    assert self.is_minter[msg.sender]
    assert _to != empty(address)
    self.totalSupply += _value
    assert self.totalSupply <= MAX_SUPPLY
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)

@external
def add_minter(_minter: address):
    assert msg.sender == self.admin
    self.is_minter[_minter] = True
    log NewMinter(_minter)

@external
def remove_minter(_minter: address):
    assert msg.sender == self.admin
    self.is_minter[_minter] = False
    log XMinter(_minter)

@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != empty(address)
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, empty(address), _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)
    
@external
def change_admin(_new_admin: address):
    assert msg.sender == self.admin
    self.admin = _new_admin
    log NewOwner(_new_admin)
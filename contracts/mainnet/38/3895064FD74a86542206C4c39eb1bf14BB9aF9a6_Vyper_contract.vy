# @version 0.3.1
"""
@title Minimal veOracle + veBoost Wrapper
"""
from vyper.interfaces import ERC20


interface veBoost:
    def adjusted_balance_of(_user: address) -> uint256: view


VE_ORACLE: constant(address) = 0x12F407340697Ae0b177546E535b91A5be021fBF9
VE_BOOST: immutable(address)


@external
def __init__(_ve_boost: address):
    VE_BOOST = _ve_boost


@view
@external
def balanceOf(_user: address) -> uint256:
    """
    @notice Get the adjusted veCRV balance of a user
    """
    return veBoost(VE_BOOST).adjusted_balance_of(_user)


@view
@external
def totalSupply() -> uint256:
    """
    @notice Get the totalSupply of veCRV
    """
    return ERC20(VE_ORACLE).totalSupply()


@view
@external
def ve_boost() -> address:
    return VE_BOOST


@view
@external
def ve_oracle() -> address:
    return VE_ORACLE
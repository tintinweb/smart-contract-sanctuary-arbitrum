# @version 0.3.7
"""
@title Child Liquidity Gauge Factory
@license MIT
@author Curve Finance
"""
from vyper.interfaces import ERC20


interface ChildGauge:
    def initialize(_lp_token: address, _manager: address): nonpayable
    def integrate_fraction(_user: address) -> uint256: view
    def user_checkpoint(_user: address) -> bool: nonpayable

struct VaultMetadata:
    vault: address
    staking: address
    creator: address
    metadataCID: String[100]
    swapTokenAddresses: address[8]
    swapAddress: address
    exchange: uint256

event DeployedGauge:
    _implementation: indexed(address)
    _vault: address
    _gauge: address

event Minted:
    _user: indexed(address)
    _gauge: indexed(address)
    _new_total: uint256

event UpdateImplementation:
    _old_implementation: address
    _new_implementation: address

event UpdateVotingEscrow:
    _old_voting_escrow: address
    _new_voting_escrow: address

event UpdateToken:
    _old_token: address
    _new_token: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address


get_implementation: public(address)
voting_escrow: public(address)
token: public(address)

owner: public(address)
future_owner: public(address)

# user -> gauge -> value
minted: public(HashMap[address, HashMap[address, uint256]])

is_valid_gauge: public(HashMap[address, bool])
get_gauge_count: public(uint256)
get_gauge: public(address[max_value(uint256)])

@external
def __init__(_token: address, _owner: address, _voting_escrow: address, _implementation: address):

    self.token = _token
    log UpdateToken(empty(address), _token)

    self.owner = _owner
    log TransferOwnership(empty(address), _owner)

    self.voting_escrow = _voting_escrow
    log UpdateVotingEscrow(empty(address), _voting_escrow)

    self.get_implementation = _implementation
    log UpdateImplementation(empty(address), _implementation)


@internal
def _psuedo_mint(_gauge: address, _user: address) -> uint256:
    assert self.is_valid_gauge[_gauge]  # dev: invalid gauge

    assert ChildGauge(_gauge).user_checkpoint(_user)
    total_mint: uint256 = ChildGauge(_gauge).integrate_fraction(_user)
    to_mint: uint256 = total_mint - self.minted[_user][_gauge]

    if to_mint != 0:
        # transfer tokens to user
        assert ERC20(self.token).transfer(_user, to_mint, default_return_value=True)
        self.minted[_user][_gauge] = total_mint

        log Minted(_user, _gauge, total_mint)
    return to_mint


@external
@nonreentrant("lock")
def mint(_gauge: address) -> uint256:
    """
    @notice Mint everything which belongs to `msg.sender` and send to them
    @param _gauge `LiquidityGauge` address to get mintable amount from
    """
    return self._psuedo_mint(_gauge, msg.sender)


@external
@nonreentrant("lock")
def mint_many(_gauges: DynArray[address, 64]) -> uint256:
    """
    @notice Mint everything which belongs to `msg.sender` across multiple gauges
    @param _gauges List of `LiquidityGauge` addresses
    """
    minted: uint256 = 0
    for _gauge in _gauges:
        minted += self._psuedo_mint(_gauge, msg.sender)
    return minted


@external
def deploy_gauge(_vault: address) -> address:
    """
    @notice Deploy a liquidity gauge
    @param _vault The vault for which we create the gauge
    """
    assert msg.sender == self.owner

    implementation: address = self.get_implementation
    gauge: address = create_minimal_proxy_to(
        implementation, salt=keccak256(_abi_encode(chain.id, _vault))
    )

    self.is_valid_gauge[gauge] = True

    idx: uint256 = self.get_gauge_count
    self.get_gauge[idx] = gauge
    self.get_gauge_count = idx + 1

    ChildGauge(gauge).initialize(_vault, self.owner)

    log DeployedGauge(implementation, _vault, gauge)
    return gauge


@external
def set_voting_escrow(_voting_escrow: address):
    """
    @notice Update the voting escrow contract
    @param _voting_escrow Contract to use as the voting escrow oracle
    """
    assert msg.sender == self.owner  # dev: only owner

    log UpdateVotingEscrow(self.voting_escrow, _voting_escrow)
    self.voting_escrow = _voting_escrow


@external
def set_implementation(_implementation: address):
    """
    @notice Set the implementation
    @param _implementation The address of the implementation to use
    """
    assert msg.sender == self.owner  # dev: only owner

    log UpdateImplementation(self.get_implementation, _implementation)
    self.get_implementation = _implementation


@external
def set_token(_token: address):
    """
    @notice Set the reward token
    @param _token The address of the reward token to use
    """
    assert msg.sender == self.owner  # dev: only owner

    log UpdateToken(self.token, _token)
    self.token = _token


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership to `_future_owner`
    @param _future_owner The account to commit as the future owner
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership
    @dev Only the committed future owner can call this function
    """
    assert msg.sender == self.future_owner  # dev: only future owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender


@external
def rescue_token(_token: address, _recipient: address = msg.sender):
    """
    @notice Enables rescuing stuck tokens
    @dev Only the owner can call this function. Useful for when `set_token()` is called
    and there's still a balance of the old `self.token` in the factory.
    """
    assert msg.sender == self.owner  # dev: only owner
    assert _token != self.token # dev: not current reward token

    assert ERC20(_token).transfer(_recipient, ERC20(_token).balanceOf(self), default_return_value=True)
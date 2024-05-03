#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version shanghai
"""
@title      AAVE interest rate prediction competition for Juice Bot
@license    Apache 2.0
@author     Volume.finance
"""
struct EpochInfo:
    epoch_id: uint256
    competition_start: uint256
    competition_end: uint256
    entry_cnt: uint256

struct BidInfo:
    epoch_id: uint256
    sender: address
    aave_version: uint256
    chain_id: uint256
    token_asset: address

MAX_ENTRY: constant(uint256) = 1000

bid_info: public(DynArray[BidInfo, MAX_ENTRY])
latest_bid: public(HashMap[address, uint256])
epoch_info: public(EpochInfo)
paloma: public(bytes32)
compass: public(address)

event Bid:
    epoch_id: uint256
    sender: address
    aave_version: uint256
    chain_id: uint256
    token_asset: address

event SetPaloma:
    paloma: bytes32

event UpdateCompass:
    old_compass: address
    new_compass: address

event SetActiveEpoch:
    epoch_id: uint256
    competition_start: uint256
    competition_end: uint256

@external
def __init__(_compass: address):
    self.compass = _compass
    log UpdateCompass(empty(address), _compass)

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@external
def update_compass(_new_compass: address):
    self._paloma_check()
    self.compass = _new_compass
    log UpdateCompass(msg.sender, _new_compass)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def set_active_epoch(_epoch_info: EpochInfo):
    self._paloma_check()
    self.epoch_info = _epoch_info
    log SetActiveEpoch(_epoch_info.epoch_id, _epoch_info.competition_start, _epoch_info.competition_end)

@external
def bid(_token_asset: address, _chain_id: uint256, _aave_version: uint256):
    _epoch_info: EpochInfo = self.epoch_info

    assert block.timestamp >= _epoch_info.competition_start, "Not Active"
    assert block.timestamp < _epoch_info.competition_end, "Not Active"
    assert _epoch_info.entry_cnt < MAX_ENTRY, "Entry Limited"
    assert self.latest_bid[msg.sender] < _epoch_info.epoch_id, "Already bid"

    _epoch_info.entry_cnt = unsafe_add(_epoch_info.entry_cnt, 1)

    #Write
    self.bid_info.append(BidInfo({
        epoch_id: _epoch_info.epoch_id,
        sender: msg.sender,
        aave_version: _aave_version,
        chain_id: _chain_id,
        token_asset: _token_asset
    }))
    self.latest_bid[msg.sender] = _epoch_info.epoch_id
    self.epoch_info = _epoch_info

    # Event Log
    log Bid(_epoch_info.epoch_id, msg.sender, _aave_version, _chain_id, _token_asset)

@external
@payable
def __default__():
    pass
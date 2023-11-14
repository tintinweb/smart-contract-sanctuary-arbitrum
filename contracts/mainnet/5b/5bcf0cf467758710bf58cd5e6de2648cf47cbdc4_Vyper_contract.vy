# SPDX-License-Identifier: AGPL-3.0

event Create:
    dmap:     address
    gov:      address
    treasury: address
    rate:     uint256

BLUEPRINT: public(immutable(address))
DMAP:      public(immutable(address))
zone:      public(HashMap[address, bool])

@external
def __init__(b: address, d: address):
    BLUEPRINT = b
    DMAP      = d

@external
def create_zone(treasury: address, rate: uint256) -> address:
    zone: address = create_from_blueprint(
        BLUEPRINT,
        DMAP,
        msg.sender,
        treasury,
        rate,
        code_offset=3
    )
    self.zone[zone] = True
    log Create(DMAP, msg.sender, treasury, rate)
    return zone
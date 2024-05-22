#pragma version 0.3.10
"""
@title DFM L2 Sequencer Uptime Hook
@dev Prevents increasing debt and partial withdrawal of collateral while L2
     sequencer is down or has recently restarted. Markets using this hook should
     also incorporate a sequencer uptime check within their oracle.
@license MIT
"""

interface ChainlinkAggregator:
    def latestRoundData() -> (uint256, int256, uint256): view  # (roundId, answer, startedAt)
    def decimals() -> uint256: view


SEQUENCER_GRACE_PERIOD: public(constant(uint256)) = 1800
CHAINLINK_L2_UPTIME: public(immutable(ChainlinkAggregator))

owner: public(address)


@external
def __init__(cl_uptime: ChainlinkAggregator):
    CHAINLINK_L2_UPTIME = cl_uptime


@view
@external
def on_create_loan_view(account: address, market: address, coll_amount: uint256, debt_amount: uint256) -> int256:
    return self._create_loan()


@view
@external
def on_adjust_loan_view(account: address, market: address, coll_change: int256, debt_change: int256) -> int256:
    return self._adjust_loan(coll_change, debt_change)


@external
def on_create_loan(account: address, market: address, coll_amount: uint256, debt_amount: uint256) -> int256:
    return self._create_loan()


@external
def on_adjust_loan(account: address, market: address, coll_change: int256, debt_change: int256) -> int256:
    return self._adjust_loan(coll_change, debt_change)


@view
@internal
def _is_sequencer_live() -> bool:
    round_data: (uint256, int256, uint256) = CHAINLINK_L2_UPTIME.latestRoundData()
    return round_data[1] == 0 and round_data[2] + SEQUENCER_GRACE_PERIOD <= block.timestamp


@view
@internal
def _create_loan() -> int256:
    if not self._is_sequencer_live():
        raise "Sequencer down: no new loans"

    return 0


@view
@internal
def _adjust_loan(debt_change: int256, coll_change: int256) -> int256:
    if debt_change > 0 or coll_change < 0:
        if not self._is_sequencer_live():
            if debt_change > 0:
                raise "Sequencer down: cannot add debt"
            if coll_change < 0:
                raise "Sequencer down: close loan to withdraw collateral"

    return 0
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IRewardForwarder} from "../interfaces/IRewardForwarder.sol";

contract RewardForwardResolver {
    uint256 constant FORWARD_INTERVAL = 86_400 * 7;
    address public forwarder;

    constructor(address _forwarder) {
        forwarder = _forwarder;
    }

    function check(address _gauge, address _reward)
        external
        view
        returns (bool _canExec, bytes memory _execPayload)
    {
        bool _forwardable = IRewardForwarder(forwarder).isRewardForwardable(
            _gauge,
            _reward
        );

        uint256 _lastForwardTime = IRewardForwarder(forwarder)
            .lastForwardTime();

        if (
            _forwardable &&
            block.timestamp >= _lastForwardTime + FORWARD_INTERVAL
        ) {
            return (true, abi.encode(IRewardForwarder.forwardReward.selector));
        }

        return (false, "reward is not forwardable");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewardForwarder {
    /**
     * @notice claim iToken reward from GovFeeDistributor, then send to Liquidity Gauge
     * @dev reward should be set as forwardable in #toggleForwardApproval
     * @return _fee the fee forwarded to a gauge
     */
    function forwardReward() external returns (uint256 _fee);

    /**
     * @notice toggle reward approval for gauge
     * @param _gauge gauge address to approve reward distribution
     * @param _reward reward token to distribute(assumes this is current or past reserve pool LP token)
     */
    function toggleForwardApproval(
        address _gauge,
        address _reward,
        bool _approve
    ) external;

    /**
     * @notice check if the reward is forwardable to gauge
     * @param _gauge gauge address to approve reward distribution
     * @param _reward reward token to distribute(assumes this is current or past reserve pool LP token)
     * @return forwardable
     */
    function isRewardForwardable(address _gauge, address _reward)
        external
        view
        returns (bool);

    /**
     * @notice return last timestamp forwarding executed
     */
    function lastForwardTime() external view returns (uint256);
}
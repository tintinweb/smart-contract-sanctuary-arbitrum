// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {IRewardPool} from "./IRewardPool.sol";

interface IBooster {
    function poolInfo(uint256) external view returns(address, address, address, bool, address);
}

contract ConvexBoosterController is IController {

    address public immutable BOOSTER;

    /// @notice deposit(uint256,uint256)
    bytes4 constant DEPOSIT = 0xe2bbb158;

    constructor(address booster) {
        BOOSTER = booster;
    }

    function canCall(address, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);
        if (sig == DEPOSIT) return canDeposit(data[4:]);
        return (false, new address[](0), new address[](0));
    }

    function canDeposit(bytes calldata data)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        (uint pid, ) = abi.decode(data, (uint, uint));
        (address lpToken, , address rewardPool, ,) = IBooster(BOOSTER).poolInfo(pid);
        uint len = IRewardPool(rewardPool).rewardLength();

        address[] memory tokensIn = new address[](len + 1);
        tokensIn[0] = rewardPool;

        for(uint i = 1; i <= len; ++i) {
            tokensIn[i] = IRewardPool(rewardPool).rewards(i - 1).reward_token;
        }

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = lpToken;

        return (true, tokensIn, tokensOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRewardPool {
    function curveGauge() external view returns (address);
    function rewardLength() external view returns (uint256);
    function rewards(uint index) external view returns (RewardType memory);

    struct RewardType {
        address reward_token;
        uint128 reward_integral;
        uint128 reward_remaining;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IController {

    /**
        @notice General function that evaluates whether the target contract can
        be interacted with using the specified calldata
        @param target Address of external protocol/interaction
        @param useEth Specifies if Eth is being sent to the target
        @param data Calldata of the call made to target
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canCall(
        address target,
        bool useEth,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory);
}
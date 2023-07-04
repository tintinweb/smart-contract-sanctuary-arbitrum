// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {IERC4626} from "../erc4626/IERC4626.sol";
import {IRewards} from "./IRewards.sol";
import {IBooster} from "./IBooster.sol";
import {IStashToken} from "./IStashToken.sol";

/**
 * @title Aura reward pool controller
 */
contract RewardPoolController is IController {
    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice deposit(uint256,address)
    bytes4 constant DEPOSIT = 0x6e553f65;

    /// @notice mint(uint256,address)
    bytes4 constant MINT = 0x94bf804d;

    /// @notice redeem(uint256,address,address)
    bytes4 constant REDEEM = 0xba087652;

    /// @notice withdraw(uint256,address,address)
    bytes4 constant WITHDRAW = 0xb460af94;

    /// @notice getReward()
    bytes4 constant GET_REWARD = 0x3d18b912;

    address public immutable AURA = 0x1509706a6c66CA549ff0cB464de88231DDBe213B;

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address target, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == DEPOSIT || sig == MINT) {
            return canCallDepositAndMint(target);
        }

        if (sig == REDEEM || sig == WITHDRAW) {
            return canCallWithdrawAndRedeem(target);
        }

        if (sig == GET_REWARD) {
            return canCallGetReward(target);
        }

        return (false, new address[](0), new address[](0));
    }

    function canCallDepositAndMint(address target) internal view returns (bool, address[] memory, address[] memory) {
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);
        tokensIn[0] = target;
        tokensOut[0] = IERC4626(target).asset();
        return (true, tokensIn, tokensOut);
    }

    function canCallWithdrawAndRedeem(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);
        tokensIn[0] = IERC4626(target).asset();
        tokensOut[0] = target;
        return (true, tokensIn, tokensOut);
    }

    function canCallGetReward(address target) internal view returns (bool, address[] memory, address[] memory) {
        uint256 rewardLength = IRewards(target).extraRewardsLength();
        address[] memory tokensIn = new address[](rewardLength + 2);
        for (uint256 i = 0; i < rewardLength; i++) {
            tokensIn[i] = IStashToken(IRewards(IRewards(target).extraRewards(i)).rewardToken()).baseToken();
        }
        tokensIn[rewardLength] = IRewards(target).rewardToken();
        tokensIn[rewardLength + 1] = AURA;
        return (true, tokensIn, new address[](0));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC4626 {
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function asset() external view returns (address asset);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRewards {
    function operator() external view returns (address);
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns (address);
    function earned(address account) external view returns (uint256);
    function extraRewards(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBooster {
    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStashToken {
    function baseToken() external view returns (address);
}
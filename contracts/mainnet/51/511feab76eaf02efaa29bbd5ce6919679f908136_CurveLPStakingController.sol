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
pragma solidity ^0.8.15;

import {IController} from "../core/IController.sol";

interface IChildGauge {
    function lp_token() external view returns (address);
    function reward_count() external view returns (uint256);
    function reward_tokens(uint256) external view returns (address);
}

/**
    @title Curve LP staking controller
    @notice Interaction controller for staking curve LP controllers
*/
contract CurveLPStakingController is IController {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice deposit(uint256)
    bytes4 constant DEPOSIT = 0xb6b55f25;

    /// @notice deposit(uint256,address,bool)
    bytes4 constant DEPOSITCLAIM = 0x83df6747;

    /// @notice withdraw(uint256)
    bytes4 constant WITHDRAW = 0x2e1a7d4d;

    /// @notice withdraw(uint256,address,bool)
    bytes4 constant WITHDRAWCLAIM = 0x00ebf5dd;

    /// @notice claim_rewards()
    bytes4 constant CLAIM = 0xe6f1daf2;

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address target, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == DEPOSIT) return canDeposit(target);
        if (sig == DEPOSITCLAIM) return canDepositAndClaim(target);
        if (sig == WITHDRAW) return canWithdraw(target);
        if (sig == WITHDRAWCLAIM) return canWithdrawAndClaim(target);
        if (sig == CLAIM) return canClaim(target);

        return (false, new address[](0), new address[](0));
    }

    function canDeposit(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);
        tokensIn[0] = target;
        tokensOut[0] = IChildGauge(target).lp_token();
        return (true, tokensIn, tokensOut);
    }

    function canDepositAndClaim(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        uint count = IChildGauge(target).reward_count();

        address[] memory tokensIn = new address[](count + 1);

        for (uint i; i<count; i++)
            tokensIn[i] = IChildGauge(target).reward_tokens(i);
        tokensIn[count] = target;

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = IChildGauge(target).lp_token();

        return (true, tokensIn, tokensOut);
    }

    function canWithdraw(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        address[] memory tokensIn = new address[](1);
        address[] memory tokensOut = new address[](1);
        tokensOut[0] = target;
        tokensIn[0] = IChildGauge(target).lp_token();
        return (true, tokensIn, tokensOut);
    }

    function canWithdrawAndClaim(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        uint count = IChildGauge(target).reward_count();

        address[] memory tokensIn = new address[](count + 1);
        for (uint i; i<count; i++)
            tokensIn[i] = IChildGauge(target).reward_tokens(i);
        tokensIn[count] = IChildGauge(target).lp_token();

        address[] memory tokensOut = new address[](1);
        tokensOut[0] = target;
        return (true, tokensIn, tokensOut);
    }

    function canClaim(address target)
        internal
        view
        returns (bool, address[] memory, address[] memory)
    {
        uint count = IChildGauge(target).reward_count();

        address[] memory tokensIn = new address[](count);
        for (uint i; i<count; i++)
            tokensIn[i] = IChildGauge(target).reward_tokens(i);

        return (true, tokensIn, new address[](0));
    }
}
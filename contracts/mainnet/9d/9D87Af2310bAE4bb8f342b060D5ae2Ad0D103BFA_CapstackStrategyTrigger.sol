// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStrategy {
    struct OneInchData {
        address token;
        bytes data;
    }

    function panic() external;

    function harvest(OneInchData[] calldata _data) external;

    function shouldDeleverage() external view returns (uint256 resultCode);

    function shouldRebalance() external view returns (bool rebalance, bool hedge);

    function shouldExit() external view returns (uint256 resultCode);

    function paused() external view returns (bool);
}

contract CapstackStrategyTrigger {
    function loopingChecker(address strategy) external view returns (bool canExec, bytes memory execPayload) {
        if (IStrategy(strategy).paused()) {
            return (false, bytes("paused"));
        }
        uint256 code = IStrategy(strategy).shouldDeleverage();
        if (code > 0) {
            return (true, abi.encodeCall(IStrategy.panic, ()));
        }
        return (false, bytes("code 0"));
    }

    function glpRebalanceChecker(address strategy) external view returns (bool canExec, bytes memory execPayload) {
        if (IStrategy(strategy).paused()) {
            return (false, bytes("paused"));
        }
        (bool rebalance, ) = IStrategy(strategy).shouldRebalance();
        if (rebalance) {
            IStrategy.OneInchData[] memory data = new IStrategy.OneInchData[](1);
            return (true, abi.encodeCall(IStrategy.harvest, (data)));
        }
        return (false, bytes("no rebalance"));
    }

    function glpExitChecker(address strategy) external view returns (bool canExec, bytes memory execPayload) {
        if (IStrategy(strategy).paused()) {
            return (false, bytes("paused"));
        }
        uint256 code = IStrategy(strategy).shouldExit();
        if (code == 1 || code == 2) {
            return (true, abi.encodeCall(IStrategy.panic, ()));
        }
        return (false, bytes("no exit"));
    }
}
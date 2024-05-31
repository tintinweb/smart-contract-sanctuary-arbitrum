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

contract CapstackGlpHedgeStrategyTrigger {
    function glpRebalanceChecker(address strategy) external view returns (bool canExec, bytes memory execPayload) {
        if (IStrategy(strategy).paused()) {
            return (false, bytes("paused"));
        }
        (bool rebalance, ) = IStrategy(strategy).shouldRebalance();
        if (rebalance) {
            return (
                true,
                bytes(
                    "0xb4adc42300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000"
                )
            );
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
        if (code == 3) {
            return (false, bytes("Alert weight reached"));
        }
        return (false, bytes("no exit"));
    }
}
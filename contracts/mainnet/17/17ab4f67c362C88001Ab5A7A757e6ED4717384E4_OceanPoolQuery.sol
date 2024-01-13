// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

// All solidity behavior related comments are in reference to this version of
// the solc compiler.
pragma solidity ^0.8.19;

import { ILiquidityPoolImplementation, SpecifiedToken } from "../proteus/ILiquidityPoolImplementation.sol";

interface IERC1155 {
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
}

interface ILiquidityPool {
    function xToken() external view returns (uint256);
    function yToken() external view returns (uint256);
    function lpTokenId() external view returns (uint256);
    function getTokenSupply(uint256 lpTokenId) external view returns (uint256);
    function implementation() external view returns (address);

    function swapGivenInputAmount(uint256 inputToken, uint256 inputAmount) external view returns (uint256);
    function swapGivenOutputAmount(uint256 outputToken, uint256 outputAmount) external view returns (uint256);
    function depositGivenInputAmount(uint256 depositToken, uint256 depositAmount) external view returns (uint256);
    function depositGivenOutputAmount(uint256 depositToken, uint256 mintAmount) external view returns (uint256);
    function withdrawGivenInputAmount(uint256 withdrawnToken, uint256 burnAmount) external view returns (uint256);
    function withdrawGivenOutputAmount(uint256 withdrawnToken, uint256 withdrawnAmount) external view returns (uint256);
}

struct Step {
    uint256 token;
    address pool;
    uint256 action;
}

struct PoolState {
    uint256 xBalance;
    uint256 yBalance;
    uint256 totalSupply;
    address impAddress;
}

contract OceanPoolQuery {
    address ocean;

    constructor(address _ocean) {
        ocean = _ocean;
    }

    function query(Step[] memory steps, uint256 amount, address[] memory sharedPools, PoolState[] memory poolStates) public view returns (uint256, PoolState[] memory) {
        for (uint256 i = 0; i < steps.length; i++) {
            Step memory step = steps[i];

            SpecifiedToken specToken = step.token == ILiquidityPool(step.pool).xToken() ? SpecifiedToken.X : SpecifiedToken.Y;

            PoolState memory poolState = poolStates[i];

            if (findSharedPool(step.pool, sharedPools)) {
                uint256 resultAmount;

                if (step.action == 0) {
                    resultAmount = ILiquidityPoolImplementation(poolState.impAddress).swapGivenInputAmount(poolState.xBalance, poolState.yBalance, amount, specToken);
                    if (specToken == SpecifiedToken.X) {
                        poolState.xBalance += amount;
                        poolState.yBalance -= resultAmount;
                    } else {
                        poolState.yBalance += amount;
                        poolState.xBalance -= resultAmount;
                    }
                } else if (step.action == 1) {
                    resultAmount = ILiquidityPoolImplementation(poolState.impAddress).swapGivenOutputAmount(poolState.xBalance, poolState.yBalance, amount, specToken);
                    if (specToken == SpecifiedToken.X) {
                        poolState.xBalance -= amount;
                        poolState.yBalance += resultAmount;
                    } else {
                        poolState.yBalance -= amount;
                        poolState.xBalance += resultAmount;
                    }
                } else if (step.action == 2) {
                    resultAmount = ILiquidityPoolImplementation(poolState.impAddress).depositGivenInputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                    if (specToken == SpecifiedToken.X) {
                        poolState.xBalance += amount;
                    } else {
                        poolState.yBalance += amount;
                    }
                    poolState.totalSupply += resultAmount;
                } else if (step.action == 3) {
                    resultAmount = ILiquidityPoolImplementation(poolState.impAddress).depositGivenOutputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                    if (specToken == SpecifiedToken.X) {
                        poolState.xBalance += resultAmount;
                    } else {
                        poolState.yBalance += resultAmount;
                    }
                    poolState.totalSupply += amount;
                } else if (step.action == 4) {
                    resultAmount = ILiquidityPoolImplementation(poolState.impAddress).withdrawGivenInputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                    if (specToken == SpecifiedToken.X) {
                        poolState.xBalance -= resultAmount;
                    } else {
                        poolState.yBalance -= resultAmount;
                    }
                    poolState.totalSupply -= amount;
                } else if (step.action == 5) {
                    resultAmount = ILiquidityPoolImplementation(poolState.impAddress).withdrawGivenOutputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                    if (specToken == SpecifiedToken.X) {
                        poolState.xBalance -= amount;
                    } else {
                        poolState.yBalance -= amount;
                    }
                    poolState.totalSupply -= resultAmount;
                } else {
                    revert("Invalid action");
                }
                amount = resultAmount;
            } else {
                if (step.action == 0) {
                    amount = ILiquidityPoolImplementation(poolState.impAddress).swapGivenInputAmount(poolState.xBalance, poolState.yBalance, amount, specToken);
                } else if (step.action == 1) {
                    amount = ILiquidityPoolImplementation(poolState.impAddress).swapGivenOutputAmount(poolState.xBalance, poolState.yBalance, amount, specToken);
                } else if (step.action == 2) {
                    amount = ILiquidityPoolImplementation(poolState.impAddress).depositGivenInputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                } else if (step.action == 3) {
                    amount = ILiquidityPoolImplementation(poolState.impAddress).depositGivenOutputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                } else if (step.action == 4) {
                    amount = ILiquidityPoolImplementation(poolState.impAddress).withdrawGivenInputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                } else if (step.action == 5) {
                    amount = ILiquidityPoolImplementation(poolState.impAddress).withdrawGivenOutputAmount(poolState.xBalance, poolState.yBalance, poolState.totalSupply, amount, specToken);
                } else {
                    revert("Invalid action");
                }
            }
        }
        return (amount, poolStates);
    }

    function getPoolState(address poolAddress) public view returns (PoolState memory poolState) {
        address[] memory accounts = new address[](2);
        uint256[] memory ids = new uint256[](2);
        accounts[0] = accounts[1] = poolAddress;
        ids[0] = ILiquidityPool(poolAddress).xToken();
        ids[1] = ILiquidityPool(poolAddress).yToken();

        uint256[] memory balances = IERC1155(ocean).balanceOfBatch(accounts, ids);
        uint256 totalSupply = ILiquidityPool(poolAddress).getTokenSupply(ILiquidityPool(poolAddress).lpTokenId());
        address impAddress = ILiquidityPool(poolAddress).implementation();

        poolState = PoolState(balances[0], balances[1], totalSupply, impAddress);
    }

    function findSharedPool(address currentPool, address[] memory sharedPools) private pure returns (bool) {
        for (uint256 i = 0; i < sharedPools.length; i++) {
            if (sharedPools[i] == currentPool) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

enum SpecifiedToken {
    X,
    Y
}

interface ILiquidityPoolImplementation {
    function swapGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 inputAmount, SpecifiedToken inputToken) external view returns (uint256 outputAmount);

    function depositGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 totalSupply, uint256 depositedAmount, SpecifiedToken depositedToken) external view returns (uint256 mintedAmount);

    function withdrawGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 totalSupply, uint256 burnedAmount, SpecifiedToken withdrawnToken) external view returns (uint256 withdrawnAmount);

    function swapGivenOutputAmount(uint256 xBalance, uint256 yBalance, uint256 outputAmount, SpecifiedToken outputToken) external view returns (uint256 inputAmount);

    function depositGivenOutputAmount(uint256 xBalance, uint256 yBalance, uint256 totalSupply, uint256 mintedAmount, SpecifiedToken depositedToken) external view returns (uint256 depositedAmount);

    function withdrawGivenOutputAmount(uint256 xBalance, uint256 yBalance, uint256 totalSupply, uint256 withdrawnAmount, SpecifiedToken withdrawnToken) external view returns (uint256 burnedAmount);
}
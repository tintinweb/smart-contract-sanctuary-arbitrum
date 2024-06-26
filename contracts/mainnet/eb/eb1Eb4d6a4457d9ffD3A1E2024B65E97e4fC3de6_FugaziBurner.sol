// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IAlgebraPositionManager {
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

/**
 * @title Fugazi Burner contract
 *
 * @notice V3 Liquidity positions does not have a built-in function to burn them and permanently lock liquidity.
 * @dev FugaziBurner acts as 0x0 address and allows V3 liquidity positions to be permanently locked in this contract but to collect fees from them.
 */

contract FugaziBurner {
    uint128 constant MAX_UINT128 = type(uint128).max;
    IAlgebraPositionManager immutable ALGEBRA_POSITION_MANAGER;

    address public BURNER_OPERATOR;

    error FugaziBurnerInvalidOperator();

    event FeeCollected(uint256 indexed positionId, address indexed operator);

    modifier onlyBurnerOperator() {
        if (msg.sender != BURNER_OPERATOR) revert FugaziBurnerInvalidOperator();
        _;
    }

    constructor(address _algebraPositionManager, address _operator) {
        require(_algebraPositionManager != address(0), "Invalid Algebra Position Manager address");

        ALGEBRA_POSITION_MANAGER = IAlgebraPositionManager(_algebraPositionManager);
        BURNER_OPERATOR = _operator;
    }

    function collectFee(uint256 tokenId) public onlyBurnerOperator {
        IAlgebraPositionManager.CollectParams memory params = IAlgebraPositionManager.CollectParams({
            tokenId: tokenId,
            recipient: msg.sender,
            amount0Max: MAX_UINT128,
            amount1Max: MAX_UINT128
        });

        ALGEBRA_POSITION_MANAGER.collect(params);

        emit FeeCollected(tokenId, msg.sender);
    }

    function collectFees(uint256[] memory tokenIds) external onlyBurnerOperator {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collectFee(tokenIds[i]);
        }
    }

    function transferOperation(address _newOperator) external onlyBurnerOperator {
        if (msg.sender == address(0)) revert FugaziBurnerInvalidOperator();

        BURNER_OPERATOR = _newOperator;
    }
}
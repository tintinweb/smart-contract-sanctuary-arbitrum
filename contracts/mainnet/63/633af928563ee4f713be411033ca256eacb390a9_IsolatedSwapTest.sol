/**
 *Submitted for verification at Arbiscan.io on 2024-04-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable returns (uint256); // 0x4b64e492
}

struct SwapDescription {
    address srcToken;
    address dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}

interface IAggregationRouterV6 {
    /// @notice Performs a swap, delegating all calls encoded in `data` to `_executor`.
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param executor Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount_ Resulting token amount
    /// @return spentAmount_ Source token amount
    function swap(IAggregationExecutor executor, SwapDescription calldata desc, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount_, uint256 spentAmount_);
}

interface IERC20 {
    function approve(address add, uint256 amount) external;
    function transferFrom(address sender, address reciver, uint256 amount) external;
}

struct SwapData {
    address recevier;
    uint256 psmAmount;
    bytes actionData;
}

contract IsolatedSwapTest {
    constructor() {}

    address constant PSM_TOKEN_ADDRESS = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address constant ONE_INCH_V5_AGGREGATION_ROUTER_CONTRACT_ADDRESS = 0x111111125421cA6dc452d289314280a0f8842A65;

    IERC20 PSM = IERC20(PSM_TOKEN_ADDRESS);

    IAggregationRouterV6 public constant ONE_INCH_V5_AGGREGATION_ROUTER =
        IAggregationRouterV6(ONE_INCH_V5_AGGREGATION_ROUTER_CONTRACT_ADDRESS); // Interface of 1inchRouter

    /////////////////////////
    /////////////////////////
    // This function takes PSM from caller, then triggers 1Inch swap or LP pooling
    // Amount of PSM taken is _amountInputPE
    function sellPortalEnergy(
        address payable _recipient,
        address token,
        uint256 _amountInputPE,
        uint256 _minReceived,
        uint256 _deadline,
        uint256 _mode,
        bytes calldata _actionData
    ) external {
        /// @dev Assemble the swap data from API to use 1Inch Router
        SwapData memory swap = SwapData(_recipient, _amountInputPE, _actionData);

        // use the variables to avoid warning
        _minReceived = 1;
        _deadline = block.timestamp;

        // transfer PSM from caller to contract to then be used in swap
        IERC20(token).transferFrom(msg.sender, address(this), _amountInputPE);

        /// @dev Add liquidity, or exchange on 1Inch and transfer output token
        swapOneInch(swap, false);
    }

    /// @dev This internal function assembles the swap via the 1Inch router from API data
    function swapOneInch(SwapData memory _swap, bool _forLiquidity) internal {
        /// @dev decode the data for getting _executor, _description, _data.
        (address _executor, SwapDescription memory _description, bytes memory _data,,) =
            abi.decode(_swap.actionData, (address, SwapDescription, bytes, uint256, uint256));

        /// @dev Swap via the 1Inch Router
        /// @dev Allowance is increased in separate function to save gas
        (, uint256 spentAmount_) =
            ONE_INCH_V5_AGGREGATION_ROUTER.swap(IAggregationExecutor(_executor), _description, _data);
    }

    /// @dev Increase token spending allowances of Adapter holdings
    function increaseAllowances() external {
        IERC20(PSM_TOKEN_ADDRESS).approve(
            ONE_INCH_V5_AGGREGATION_ROUTER_CONTRACT_ADDRESS, 999999999999999999999999999999999999999
        );
    }
}
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

/**
 * @title Shared Action Executable interface
 * @notice Provides a dma-common interface for an execute method to all Action
 */
interface Executable {
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { PositionCreatedData } from "../../core/types/Common.sol";
import { POSITION_CREATED_ACTION } from "../../core/constants/Common.sol";
import "../../core/types/Common.sol";

/**
 * @title PositionCreated Action contract
 * @notice Emits PositionCreated event
 */
contract PositionCreated is Executable {
  /**
   * @dev Emitted once a position is created
   * @param proxyAddress The address of the proxy where that's a DSProxy or DeFi Positions manager proxy
   * @param protocol The name of the protocol the position is being created on
   * @param positionType The nature of the position EG Earn / Multiply.. etc.this
   * @param collateralToken The address of the collateral used in the position. ETH positions will use WETH by default.
   * @param debtToken The address of the debt used in the position.
   **/
  event CreatePosition(
    address indexed proxyAddress,
    string protocol,
    string positionType,
    address collateralToken,
    address debtToken
  );

  /**
   * @dev Is intended to pull tokens in to a user's proxy (the calling context)
   * @param data Encoded calldata that conforms to the PositionCreatedData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    PositionCreatedData memory positionCreated = parseInputs(data);

    emit CreatePosition(
      address(this),
      positionCreated.protocol,
      positionCreated.positionType,
      positionCreated.collateralToken,
      positionCreated.debtToken
    );
  }

  function parseInputs(
    bytes memory _callData
  ) public pure returns (PositionCreatedData memory params) {
    return abi.decode(_callData, (PositionCreatedData));
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant OPERATION_STORAGE = "OperationStorage_2";
string constant OPERATION_EXECUTOR = "OperationExecutor_2";
string constant OPERATIONS_REGISTRY = "OperationsRegistry_2";
string constant CHAINLOG_VIEWER = "ChainLogView";
string constant ONE_INCH_AGGREGATOR = "OneInchAggregator";
string constant DS_GUARD_FACTORY = "DSGuardFactory";
string constant WETH = "WETH";
string constant DAI = "DAI";
uint256 constant RAY = 10 ** 27;
bytes32 constant NULL = "";

/**
 * @dev We do not include patch versions in contract names to allow
 * for hotfixes of Action dma-contracts
 * and to limit updates to TheGraph
 * if the types encoded in emitted events change then use a minor version and
 * update the ServiceRegistry with a new entry
 * and update TheGraph decoding accordingly
 */
string constant POSITION_CREATED_ACTION = "PositionCreated";

string constant UNISWAP_ROUTER = "UniswapRouter";
string constant SWAP = "Swap";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

enum FlashloanProvider {
  DssFlash,
  Balancer
}

struct FlashloanData {
  uint256 amount;
  address asset;
  bool isProxyFlashloan;
  bool isDPMProxy;
  FlashloanProvider provider;
  Call[] calls;
}

struct PullTokenData {
  address asset;
  address from;
  uint256 amount;
}

struct SendTokenData {
  address asset;
  address to;
  uint256 amount;
}

struct SetApprovalData {
  address asset;
  address delegate;
  uint256 amount;
  bool sumAmounts;
}

struct SwapData {
  address fromAsset;
  address toAsset;
  uint256 amount;
  uint256 receiveAtLeast;
  uint256 fee;
  bytes withData;
  bool collectFeeInFromToken;
}

struct Call {
  bytes32 targetHash;
  bytes callData;
  bool skipped;
}

struct Operation {
  uint8 currentAction;
  bytes32[] actions;
}

struct WrapEthData {
  uint256 amount;
}

struct UnwrapEthData {
  uint256 amount;
}

struct ReturnFundsData {
  address asset;
}

struct PositionCreatedData {
  string protocol;
  string positionType;
  address collateralToken;
  address debtToken;
}
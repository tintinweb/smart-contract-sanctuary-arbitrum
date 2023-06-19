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

import { Operation } from "./types/Common.sol";
import { OPERATIONS_REGISTRY } from "./constants/Common.sol";

struct StoredOperation {
  bytes32[] actions;
  bool[] optional;
  string name;
}

/**
 * @title Operation Registry
 * @notice Stores the Actions that constitute a given Operation and information if an Action can be skipped

 */
contract OperationsRegistry {
  mapping(string => StoredOperation) private operations;
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "only-owner");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /**
   * @notice Stores the Actions that constitute a given Operation
   * @param newOwner The address of the new owner of the Operations Registry
   */
  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  /**
   * @dev Emitted when a new operation is added or an existing operation is updated
   * @param name The Operation name
   **/
  event OperationAdded(bytes32 indexed name);

  /**
   * @notice Adds an Operation's Actions keyed to a an operation name
   * @param operation Struct with Operation name, actions and their optionality
   */
  function addOperation(StoredOperation calldata operation) external onlyOwner {
    operations[operation.name] = operation;
    // By packing the string into bytes32 which means the max char length is capped at 64
    emit OperationAdded(bytes32(abi.encodePacked(operation.name)));
  }

  /**
   * @notice Gets an Operation from the Registry
   * @param name The name of the Operation
   * @return actions Returns an array of Actions and array for optionality of coresponding Actions
   */
  function getOperation(
    string memory name
  ) external view returns (bytes32[] memory actions, bool[] memory optional) {
    if (keccak256(bytes(operations[name].name)) == keccak256(bytes(""))) {
      revert("Operation doesn't exist");
    }
    actions = operations[name].actions;
    optional = operations[name].optional;
  }
}

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
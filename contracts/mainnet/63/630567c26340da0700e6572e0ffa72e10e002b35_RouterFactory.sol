// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IV5AggregationExecutor} from "src/interfaces/IV5AggregationExecutor.sol";
import {IV5AggregationRouter} from "src/interfaces/IV5AggregationRouter.sol";
import {IV4AggregationExecutor} from "src/interfaces/IV4AggregationExecutor.sol";
import {IV4AggregationRouter} from "src/interfaces/IV4AggregationRouter.sol";
import {Create2} from "src/lib/Create2.sol";
import {V5Router} from "src/V5Router.sol";
import {V4Router} from "src/V4Router.sol";

/// @notice A factory for deploying an optimized router for a given asset and router type.
contract RouterFactory {
  error RouterTypeDoesNotExist();

  enum RouterType {
    V4AggregationRouter,
    V5AggregationRouter
  }

  /// @notice The 1inch v5 contract used to execute the swap along an optimized token swapping path.
  IV5AggregationExecutor public immutable V5_AGGREGATION_EXECUTOR;

  /// @notice The 1inch v5 aggregation router contract.
  IV5AggregationRouter public immutable V5_AGGREGATION_ROUTER;

  /// @notice The 1inch v4 aggregation router contract used to execute the swap along an optimized
  /// token swapping path.
  IV4AggregationExecutor public immutable V4_AGGREGATION_EXECUTOR;

  /// @notice The 1inch v4 aggregation router contract.
  IV4AggregationRouter public immutable V4_AGGREGATION_ROUTER;

  event RouterDeployed(RouterType type_, address indexed asset);

  constructor(
    IV5AggregationExecutor v5AggregationExecutor,
    IV5AggregationRouter v5AggregationRouter,
    IV4AggregationExecutor v4AggregationExecutor,
    IV4AggregationRouter v4AggregationRouter
  ) {
    V5_AGGREGATION_EXECUTOR = v5AggregationExecutor;
    V5_AGGREGATION_ROUTER = v5AggregationRouter;
    V4_AGGREGATION_EXECUTOR = v4AggregationExecutor;
    V4_AGGREGATION_ROUTER = v4AggregationRouter;
  }

  function deploy(RouterType type_, address asset) external returns (address) {
    bytes32 salt = _salt(asset);
    address router;
    if (type_ == RouterType.V5AggregationRouter) {
      router = address(
        new V5Router{salt: salt}(
                    V5_AGGREGATION_ROUTER,
                    V5_AGGREGATION_EXECUTOR,
                    asset
                )
      );
    } else if (type_ == RouterType.V4AggregationRouter) {
      router = address(
        new V4Router{salt: salt}(
                    V4_AGGREGATION_ROUTER,
                    V4_AGGREGATION_EXECUTOR,
                    asset
                )
      );
    } else {
      revert RouterTypeDoesNotExist();
    }
    emit RouterDeployed(type_, asset);
    return router;
  }

  function computeAddress(RouterType type_, address asset) external view returns (address) {
    if (type_ == RouterType.V4AggregationRouter) {
      return _computeV4AggregationRouterAddress(asset);
    } else if (type_ == RouterType.V5AggregationRouter) {
      return _computeV5AggregationRouterAddress(asset);
    } else {
      // In practice this branch will never be hit, and is
      // meant to catch situations in development when a
      // new RouterType has been added and it is not yet
      // supported in this function.
      revert RouterTypeDoesNotExist();
    }
  }

  function _computeV4AggregationRouterAddress(address asset) internal view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(V4Router).creationCode,
      abi.encode(V4_AGGREGATION_ROUTER, V4_AGGREGATION_EXECUTOR, asset)
    );
  }

  function _computeV5AggregationRouterAddress(address asset) internal view returns (address) {
    return Create2.computeCreate2Address(
      _salt(asset),
      address(this),
      type(V5Router).creationCode,
      abi.encode(V5_AGGREGATION_ROUTER, V5_AGGREGATION_EXECUTOR, asset)
    );
  }

  function _salt(address asset) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(asset)));
  }
}

pragma solidity >=0.8.0;

/// @title Interface for making arbitrary calls during swap
interface IV5AggregationExecutor {
  /// @notice propagates information about original msg.sender and executes arbitrary data
  function execute(address msgSender) external payable; // 0x4b64e492
}

pragma solidity >=0.8.0;

import {IV5AggregationExecutor} from "src/interfaces/IV5AggregationExecutor.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IV5AggregationRouter {
  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
  }

  function swap(
    IV5AggregationExecutor executor,
    SwapDescription calldata desc,
    bytes calldata permit,
    bytes calldata data
  ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
// permalink:
// https://optimistic.etherscan.io/address/0x1111111254760f7ab3f16433eea9304126dcd199#code#L990
pragma solidity >=0.8.0;

/// @title Interface for making arbitrary calls during swap
interface IV4AggregationExecutor {
  /// @notice Make calls on `msgSender` with specified data
  function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

pragma solidity >=0.8.0;

import {IV4AggregationExecutor} from "src/interfaces/IV4AggregationExecutor.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IV4AggregationRouter {
  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  function swap(IV4AggregationExecutor executor, SwapDescription calldata desc, bytes calldata data)
    external
    payable
    returns (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library Create2 {
  function computeCreate2Address(
    bytes32 salt,
    address deployer,
    bytes memory initcode,
    bytes memory constructorArgs
  ) internal pure returns (address) {
    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff), deployer, salt, keccak256(abi.encodePacked(initcode, constructorArgs))
            )
          )
        )
      )
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IV5AggregationExecutor} from "src/interfaces/IV5AggregationExecutor.sol";
import {IV5AggregationRouter} from "src/interfaces/IV5AggregationRouter.sol";
import {AggregationV5BaseRouter} from "src/AggregationBaseRouter.sol";

/// @notice A router to swap tokens using 1inch's v5 aggregation router.
contract V5Router is AggregationV5BaseRouter {
  /// @dev Thrown when a function is not supported.
  error UnsupportedFunction();

  constructor(
    IV5AggregationRouter aggregationRouter,
    IV5AggregationExecutor aggregationExecutor,
    address token
  ) AggregationV5BaseRouter(aggregationExecutor, aggregationRouter, token) {
    IERC20(token).approve(address(aggregationRouter), type(uint256).max);
  }

  /// @dev If we remove this function solc will give a missing-receive-ether warning because we have
  /// a payable fallback function. We cannot change the fallback function to a receive function
  /// because receive does not have access to msg.data. In order to prevent a missing-receive-ether
  /// warning we add a receive function and revert.
  receive() external payable {
    revert UnsupportedFunction();
  }

  // Flags match specific constant masks. There is no documentation on these.
  fallback() external payable {
    address dstToken = address(bytes20(msg.data[0:20]));
    uint256 amount = uint256(uint96(bytes12(msg.data[20:32])));
    uint256 minReturnAmount = uint256(uint96(bytes12(msg.data[32:44])));
    uint256 flags = uint256(uint8(bytes1(msg.data[44:45])));
    bytes memory data = bytes(msg.data[45:msg.data.length]);

    IERC20(TOKEN).transferFrom(msg.sender, address(this), amount);
    AGGREGATION_ROUTER.swap(
      AGGREGATION_EXECUTOR,
      IV5AggregationRouter.SwapDescription({
        srcToken: IERC20(TOKEN),
        dstToken: IERC20(dstToken),
        srcReceiver: payable(SOURCE_RECEIVER),
        dstReceiver: payable(msg.sender),
        amount: amount,
        minReturnAmount: minReturnAmount,
        flags: flags
      }),
      "",
      data
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IV4AggregationExecutor} from "src/interfaces/IV4AggregationExecutor.sol";
import {IV4AggregationRouter} from "src/interfaces/IV4AggregationRouter.sol";
import {AggregationV4BaseRouter} from "src/AggregationBaseRouter.sol";

/// @notice An optimized router to swap tokens using 1inch's v4 aggregation router.
contract V4Router is AggregationV4BaseRouter {
  /// @dev Thrown when a function is not supported.
  error UnsupportedFunction();

  constructor(
    IV4AggregationRouter aggregationRouter,
    IV4AggregationExecutor aggregationExecutor,
    address token
  ) AggregationV4BaseRouter(aggregationExecutor, aggregationRouter, token) {
    IERC20(token).approve(address(aggregationRouter), type(uint256).max);
  }

  /// @dev If we remove this function solc will give a missing-receive-ether warning because we have
  /// a payable fallback function. We cannot change the fallback function to a receive function
  /// because receive does not have access to msg.data. In order to prevent a missing-receive-ether
  /// warning we add a receive function and revert.
  receive() external payable {
    revert UnsupportedFunction();
  }

  // Flags match specific constant masks. There is no documentation on these.
  fallback() external payable {
    address dstToken = address(bytes20(msg.data[0:20]));
    uint256 amount = uint256(uint96(bytes12(msg.data[20:32])));
    uint256 minReturnAmount = uint256(uint96(bytes12(msg.data[32:44])));
    uint256 flags = uint256(uint8(bytes1(msg.data[44:45])));
    bytes memory data = bytes(msg.data[45:msg.data.length]);

    IERC20(TOKEN).transferFrom(msg.sender, address(this), amount);
    AGGREGATION_ROUTER.swap(
      AGGREGATION_EXECUTOR,
      IV4AggregationRouter.SwapDescription({
        srcToken: IERC20(TOKEN),
        dstToken: IERC20(dstToken),
        srcReceiver: payable(SOURCE_RECEIVER),
        dstReceiver: payable(msg.sender),
        amount: amount,
        minReturnAmount: minReturnAmount,
        flags: flags,
        permit: ""
      }),
      data
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IV5AggregationExecutor} from "src/interfaces/IV5AggregationExecutor.sol";
import {IV5AggregationRouter} from "src/interfaces/IV5AggregationRouter.sol";
import {IV4AggregationExecutor} from "src/interfaces/IV4AggregationExecutor.sol";
import {IV4AggregationRouter} from "src/interfaces/IV4AggregationRouter.sol";

/// @notice An abstract class with the necessary class variables
/// to make a 1inch v5 aggregation router optimized.
abstract contract AggregationV5BaseRouter {
  /// @notice The contract used to execute the swap along an optimized path.
  IV5AggregationExecutor public immutable AGGREGATION_EXECUTOR;

  /// @notice The 1inch v5 aggregation router contract.
  IV5AggregationRouter public immutable AGGREGATION_ROUTER;

  /// @notice The input token being swapped.
  address public immutable TOKEN;

  /// @notice Where the tokens are transferred in the 1inch v5 aggregation router.
  /// It will match the AGGREGATION_EXECUTOR address.
  address public immutable SOURCE_RECEIVER;

  constructor(
    IV5AggregationExecutor aggregationExecutor,
    IV5AggregationRouter aggregationRouter,
    address token
  ) {
    AGGREGATION_EXECUTOR = aggregationExecutor;
    AGGREGATION_ROUTER = aggregationRouter;
    TOKEN = token;
    SOURCE_RECEIVER = address(aggregationExecutor);
  }
}

/// @notice An abstract class with the necessary class variables
/// to make a 1inch v4 aggregation router optimized.
abstract contract AggregationV4BaseRouter {
  /// @notice The contract used to execute the swap along an optimized path.
  IV4AggregationExecutor public immutable AGGREGATION_EXECUTOR;

  /// @notice The 1inch v4 aggregation router contract.
  IV4AggregationRouter public immutable AGGREGATION_ROUTER;

  /// @notice The input token being swapped.
  address public immutable TOKEN;

  /// @notice Where the tokens are transferred in the 1inch v4 aggregation router.
  /// It will match the AGGREGATION_EXECUTOR address.
  address public immutable SOURCE_RECEIVER;

  constructor(
    IV4AggregationExecutor aggregationExecutor,
    IV4AggregationRouter aggregationRouter,
    address token
  ) {
    AGGREGATION_EXECUTOR = aggregationExecutor;
    AGGREGATION_ROUTER = aggregationRouter;
    TOKEN = token;
    SOURCE_RECEIVER = address(aggregationExecutor);
  }
}
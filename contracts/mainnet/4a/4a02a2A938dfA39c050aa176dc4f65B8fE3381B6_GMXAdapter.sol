// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.6.10;
interface IGMXAdapter {

    function ETH_TOKEN() external view returns (address);

    function getInCreasingPositionCallData(
      address _underlyingToken,
      address _indexToken,
      uint256 _underlyingUnits,
      address _to,
      bytes memory _positionData
    ) external view returns (address _subject, uint256 _value, bytes memory _calldata);

    function getDeCreasingPositionCallData(
      address _underlyingToken,
      address _indexToken,
      uint256 _underlyingUnits,
      address _to,
      bytes memory _positionData
    ) external  view returns (address _subject, uint256 _value, bytes memory _calldata);

    function PositionRouter() external view returns(address);
    function OrderBook() external view returns(address);
    function Vault() external view returns(address);
    function GMXRouter() external view returns(address);
    function getTokenBalance(address _token, address _jasperVault)external returns(uint256);
    function getCreateDecreaseOrderCallData( bytes calldata _data)external view  returns (address, uint256, bytes memory);
    function getCreateIncreaseOrderCallData( bytes calldata _data)external view  returns (address, uint256, bytes memory);
    function getSwapCallData( bytes calldata _swapData )external view  returns (address, uint256, bytes memory);
    function approvePositionRouter()external view  returns (address, uint256, bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IGMXOrderBook {
  function createIncreaseOrder(
    address[] memory _path,
    uint256 _amountIn,
    address _indexToken,
    uint256 _minOut,
    uint256 _sizeDelta,
    address _collateralToken,
    bool _isLong,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold,
    uint256 _executionFee,
    bool _shouldWrap
  )external;
  function createDecreaseOrder(
    address _indexToken,
    uint256 _sizeDelta,
    address _collateralToken,
    uint256 _collateralDelta,
    bool _isLong,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold
  )external;
  function getSwapOrder(address _account, uint256 _orderIndex) external view returns (
    address path0,
    address path1,
    address path2,
    uint256 amountIn,
    uint256 minOut,
    uint256 triggerRatio,
    bool triggerAboveThreshold,
    bool shouldUnwrap,
    uint256 executionFee
  );

  function getIncreaseOrder(address _account, uint256 _orderIndex) external view returns (
    address purchaseToken,
    uint256 purchaseTokenAmount,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee
  );

  function getDecreaseOrder(address _account, uint256 _orderIndex) external view returns (
    address collateralToken,
    uint256 collateralDelta,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee
  );

  function executeSwapOrder(address, uint256, address payable) external;
  function executeDecreaseOrder(address, uint256, address payable) external;
  function executeIncreaseOrder(address, uint256, address payable) external;
}

pragma solidity ^0.6.10;

interface IGMXRouter {
    function approvePlugin(address _plugin) external ;

    function approvedPlugins(address arg1, address arg2) external view returns (bool);

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapETHToTokens(address[] memory _path, uint256 _minOut, address _receiver) external payable;

}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IJasperVault
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface IJasperVault is IERC20 {
    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
        uint256 coinType;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        uint256 coinType;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
        uint256 coinType;
        int256 virtualUnit;
        bytes data;
    }

    /* ============ Functions ============ */
    function controller() external view returns (address);

    function editDefaultPositionCoinType(
        address _component,
        uint256 coinType
    ) external;

    function editExternalPositionCoinType(
        address _component,
        address _module,
        uint256 coinType
    ) external;

    function addComponent(address _component) external;

    function removeComponent(address _component) external;

    function editDefaultPositionUnit(
        address _component,
        int256 _realUnit
    ) external;

    function addExternalPositionModule(
        address _component,
        address _positionModule
    ) external;

    function removeExternalPositionModule(
        address _component,
        address _positionModule
    ) external;

    function editExternalPositionUnit(
        address _component,
        address _positionModule,
        int256 _realUnit
    ) external;

    function editExternalPositionData(
        address _component,
        address _positionModule,
        bytes calldata _data
    ) external;

    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;

    function burn(address _account, uint256 _quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address _module) external;

    function removeModule(address _module) external;

    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);

    function moduleStates(address _module) external view returns (ModuleState);

    function getModules() external view returns (address[] memory);

    function getDefaultPositionRealUnit(
        address _component
    ) external view returns (int256);

    function getExternalPositionRealUnit(
        address _component,
        address _positionModule
    ) external view returns (int256);

    function getComponents() external view returns (address[] memory);

    function getExternalPositionModules(
        address _component
    ) external view returns (address[] memory);

    function getExternalPositionData(
        address _component,
        address _positionModule
    ) external view returns (bytes memory);

    function isExternalPositionModule(
        address _component,
        address _module
    ) external view returns (bool);

    function isComponent(address _component) external view returns (bool);

    function positionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(
        address _component
    ) external view returns (int256);

    function isInitializedModule(address _module) external view returns (bool);

    function isPendingModule(address _module) external view returns (bool);

    function isLocked() external view returns (bool);

    function masterToken() external view returns (address);

    function setBaseProperty(string memory _name,    string memory _symbol) external;
    function setBaseFeeAndToken(address _masterToken,uint256 _followFee,uint256 _profitShareFee) external;

     function followFee() external view returns(uint256);
     function profitShareFee() external view returns(uint256);
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IGMXAdapter} from "../../../interfaces/external/gmx/IGMXAdapter.sol";
import {IGMXRouter} from "../../../interfaces/external/gmx/IGMXRouter.sol";
import {IGMXOrderBook} from "../../../interfaces/external/gmx/IGMXOrderBook.sol";
import {IJasperVault} from "../../../interfaces/IJasperVault.sol";
import {Invoke} from "../../lib/Invoke.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title GMXAdapter
 * GMX adapter for GMX that returns data for (opening/increasing position)/(closing/decreasing position) of tokens
 */
contract GMXAdapter is Ownable {
  struct SwapData {
  address[]  _path;
  uint256 _amountIn;
  uint256 _minOut;
  uint256 _swapType;
  address _receiver;
  }
  struct IncreaseOrderData {
  address[]  _path;
  uint256 _amountIn;
  address _indexToken;
  uint256 _minOut;
  uint256 _sizeDelta;
  address _collateralToken;
  bool _isLong;
  uint256 _triggerPrice;
  bool _triggerAboveThreshold;
  uint256 _executionFee;
  bool _shouldWrap;
  }
  struct DecreaseOrderData {
  address _indexToken;
  uint256 _sizeDelta;
  address _collateralToken;
  uint256 _collateralDelta;
  bool _isLong;
  uint256 _triggerPrice;
  bool _triggerAboveThreshold;
  }
  struct IncreasePositionRequest {
  address[] _path;
  address _indexToken;
  uint256 _amountIn;
  uint256 _minOut;
  uint256 _sizeDelta;
  bool _isLong;
  uint256 _acceptablePrice;
  uint256 _executionFee;
  bytes32 _referralCode;
  address _callbackTarget;
  address jasperVault;
  }
  struct DecreasePositionRequest {
  address[] _path;
  address _indexToken;
  uint256 _collateralDelta;
  uint256 _sizeDelta;
  bool _isLong;
  address _receiver;
  uint256 _acceptablePrice;
  uint256 _minOut;
  uint256 _executionFee;
  bool _withdrawETH;
  address _callbackTarget;
  }

    using Invoke for IJasperVault;
    address public   PositionRouter;
    address public  GMXRouter;
    address public  ETH_TOKEN;
    address public  OrderBook;
    address public  Vault;
    mapping(address=>bool) whiteList;
    enum SwapType {SwapToken, SwapTokensToETH, SwapETHToTokens} // 枚举
    /* ============ Constructor ============ */
    constructor(address _positionRouter, address _GMXRouter, address _OrderBook, address _Vault, address[] memory _whiteList) public {
        for (uint i; i<_whiteList.length;i++){
          whiteList[_whiteList[i]]=true;
        }
        //Address of Curve Eth/StEth stableswap pool.
        PositionRouter = _positionRouter;
        GMXRouter = _GMXRouter;
        OrderBook = _OrderBook;
        Vault = _Vault;
    }

    /* ============ External Functions ============ */
    function updateWhiteList(address[] calldata _addList, address[] calldata removeList) public {
      for (uint i; i<_addList.length;i++){
        whiteList[_addList[i]]=true;
      }
      for (uint i; i<removeList.length;i++){
        whiteList[removeList[i]]=false;
      }
    }
    function approvePositionRouter()external view  returns (address, uint256, bytes memory) {
      bytes memory approveCallData = abi.encodeWithSignature(
        "approvePlugin(address)",
        PositionRouter
      );
      return (GMXRouter, 0, approveCallData);
    }
    /**
     * Generates the calldata to increasing position asset into its underlying.
     *
     * @param _collateralToken    Address of the _collateralToken asset
     * @param _indexToken         Address of the component to be _index
     * @param _underlyingUnits    Total quantity of _collateralToken
     * @param _to                 Address to send the asset tokens to
     * @param _positionData       Data of position
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of decreasing token units to position. This will always be 215000000000000 for increasing position
     * @return bytes                position calldata
     */

    function getInCreasingPositionCallData(
        address _collateralToken,
        address _indexToken,
        uint256 _underlyingUnits,
        address _to,
        bytes calldata _positionData
    ) external view  returns (address, uint256, bytes memory) {
        IncreasePositionRequest memory request = abi.decode(
            _positionData,
            (IncreasePositionRequest)
        );

        if (
            !IGMXRouter(GMXRouter).approvedPlugins(
                request.jasperVault,
                PositionRouter
            )
        ) {
            bytes memory approveCallData = abi.encodeWithSignature(
                "approvePlugin(address)",
                PositionRouter
            );
            return (GMXRouter, 0, approveCallData);
        }
        require(whiteList[request._indexToken],"_indexToken not in whiteList");
        for (uint i;i< request._path.length;i++){
          require(whiteList[request._path[i]],"_path not in whiteList");
        }
        bytes memory callData = abi.encodeWithSignature(
            "createIncreasePosition(address[],address,uint256,uint256,uint256,bool,uint256,uint256,bytes32,address)",
            request._path,
            request._indexToken,
            request._amountIn,
            request._minOut,
            request._sizeDelta,
            request._isLong,
            request._acceptablePrice,
            request._executionFee,
            request._referralCode,
            request._callbackTarget
        );

        return (PositionRouter, request._executionFee, callData);
    }

    /**
     * Generates the calldata to decreasing position asset into its underlying.
     *
     * @param _underlyingToken    Address of the underlying asset
     * @param _indexToken         Address of the component to be _index
     * @param _indexTokenUnits    Total quantity of _index
     * @param _to                 Address to send the asset tokens to
     * @param _positionData       Data of position
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of decreasing token units to position. This will always be 215000000000000 for decreasing
     * @return bytes                position calldata
     */
    function getDeCreasingPositionCallData(
        address _underlyingToken,
        address _indexToken,
        uint256 _indexTokenUnits,
        address _to,
        bytes calldata _positionData
    ) external view  returns (address, uint256, bytes memory) {
        DecreasePositionRequest memory request = abi.decode(
            _positionData,
            (DecreasePositionRequest)
        );
      require(whiteList[request._indexToken],"_indexToken not in whiteList");
      for (uint i;i< request._path.length;i++){
        require(whiteList[request._path[i]],"_path not in whiteList");
      }
        bytes memory callData = abi.encodeWithSignature(
            "createDecreasePosition(address[],address,uint256,uint256,bool,address,uint256,uint256,uint256,bool,address)",
            request._path,
            request._indexToken,
            request._collateralDelta,
            request._sizeDelta,
            request._isLong,
            request._receiver,
            request._acceptablePrice,
            request._minOut,
            request._executionFee,
            request._withdrawETH,
            request._callbackTarget
        );

        return (PositionRouter, request._executionFee, callData);
    }


    function IsApprovedPlugins(address _Vault)public returns(bool){
      return IGMXRouter(GMXRouter).approvedPlugins(_Vault, PositionRouter);
    }
    /**
    * Generates the calldata to swap asset.
    * @param _swapData       Data of _swapData
    *
    * @return address        Target contract address
    * @return uint256        Total quantity of decreasing token units to position. This will always be 215000000000000 for decreasing
    * @return bytes          Position calldata
    **/
    function getSwapCallData( bytes calldata _swapData )external view   returns (address, uint256, bytes memory) {
      SwapData memory data = abi.decode(_swapData, (SwapData));
      for (uint i;i< data._path.length;i++){
        require(whiteList[data._path[i]],"_path not in whiteList");
      }
      bytes memory callData;
      if (data._swapType == uint256(SwapType.SwapToken) ){
        callData = abi.encodeWithSelector(IGMXRouter.swap.selector, data._path, data._amountIn, data._minOut, data._receiver);
        return (GMXRouter, 0, callData);
      }else if(data._swapType ==  uint256(SwapType.SwapTokensToETH) ){
        callData = abi.encodeWithSelector(IGMXRouter.swapTokensToETH.selector, data._path, data._amountIn, data._minOut, data._receiver);
        return (GMXRouter, 0, callData);
      }else  if(data._swapType ==  uint256(SwapType.SwapETHToTokens) ){
        callData = abi.encodeWithSelector(IGMXRouter.swapETHToTokens.selector, data._path, data._minOut, data._receiver);
        return (GMXRouter, data._amountIn, callData);
      }
      return (GMXRouter, 0, callData);
    }
    /**
      * Generates the calldata to Create IncreaseOrder CallData .
      * @param _data       Data of order
      *
      * @return address        Target contract address
      * @return uint256        Call data value
      * @return bytes          Order Calldata
    **/
    function getCreateIncreaseOrderCallData( bytes calldata _data)external view   returns (address, uint256, bytes memory){

      IncreaseOrderData memory data = abi.decode(_data, (IncreaseOrderData));

      require(whiteList[data._indexToken],"_indexToken not in whiteList");
      for (uint i;i< data._path.length;i++){
        require(whiteList[data._path[i]],"_path not in whiteList");
      }
      bytes memory callData = abi.encodeWithSelector(
      IGMXOrderBook.createIncreaseOrder.selector,
      data._amountIn,
      data._indexToken,
      data._minOut,
      data._sizeDelta,
      data._collateralToken,
      data._isLong,
      data._triggerPrice,
      data._triggerAboveThreshold,
      data._executionFee,
      data._shouldWrap);
      return (OrderBook, 300001000000000, callData);
    }
    /**
      * Generates the calldata to Create Decrease Order CallData .
      * @param _data       Data of order
      *
      * @return address        Target contract address
      * @return uint256        Call data value
      * @return bytes          Order Calldata
    **/
    function getCreateDecreaseOrderCallData(
      bytes calldata _data
    )external view   returns (address, uint256, bytes memory){
      DecreaseOrderData memory data = abi.decode(_data, (DecreaseOrderData));
      require(whiteList[data._indexToken],"_indexToken not in whiteList");

      bytes memory callData = abi.encodeWithSelector(IGMXOrderBook.createDecreaseOrder.selector,
       data._indexToken,
       data._sizeDelta,
       data._collateralToken,
       data._collateralDelta,
       data._isLong,
       data._triggerPrice,
       data._triggerAboveThreshold
      );
      return (OrderBook, 300001000000000, callData);
    }
    function getTokenBalance(address _token, address _jasperVault)external view returns(uint256){
      require(whiteList[_token],"token not in whiteList");
      return IERC20(_token).balanceOf(_jasperVault);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IJasperVault } from "../../interfaces/IJasperVault.sol";


/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the JasperVault's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the JasperVault to set approvals of the ERC20 token to a spender.
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the JasperVault's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        IJasperVault _jasperVault,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _jasperVault.invoke(_token, 0, callData);
    }

    /**
     * Instructs the JasperVault to transfer the ERC20 token to a recipient.
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        IJasperVault _jasperVault,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _jasperVault.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the JasperVault to transfer the ERC20 token to a recipient.
     * The new JasperVault balance must equal the existing balance less the quantity transferred
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        IJasperVault _jasperVault,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the JasperVault
            uint256 existingBalance = IERC20(_token).balanceOf(address(_jasperVault));

            Invoke.invokeTransfer(_jasperVault, _token, _to, _quantity);

            // Get new balance of transferred token for JasperVault
            uint256 newBalance = IERC20(_token).balanceOf(address(_jasperVault));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the JasperVault to unwrap the passed quantity of WETH
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(IJasperVault _jasperVault, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _jasperVault.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the JasperVault to wrap the passed quantity of ETH
     *
     * @param _jasperVault        JasperVault instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(IJasperVault _jasperVault, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _jasperVault.invoke(_weth, _quantity, callData);
    }
}
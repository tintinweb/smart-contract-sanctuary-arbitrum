// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAdapterDataProvider} from "./interfaces/IAdapterDataProvider.sol";

/**
 * @title AdapterDataProvider
 * @author Router Protocol
 * @notice This contract serves as the data provider for an intent adapter based on Router
 * Cross-Chain Intent Framework.
 */
contract AdapterDataProvider is IAdapterDataProvider {
    address private _owner;
    mapping(address => bool) private _headRegistry;
    mapping(address => bool) private _tailRegistry;
    mapping(address => bool) private _inboundAssetRegistry;
    mapping(address => bool) private _outboundAssetRegistry;

    constructor(address __owner) {
        _owner = __owner;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setOwner(address __owner) external onlyOwner {
        _owner = __owner;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isAuthorizedPrecedingContract(
        address precedingContract
    ) external view returns (bool) {
        if (precedingContract == address(0)) return true;
        return _headRegistry[precedingContract];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isAuthorizedSucceedingContract(
        address succeedingContract
    ) external view returns (bool) {
        if (succeedingContract == address(0)) return true;
        return _tailRegistry[succeedingContract];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isValidInboundAsset(address asset) external view returns (bool) {
        return _inboundAssetRegistry[asset];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isValidOutboundAsset(address asset) external view returns (bool) {
        return _outboundAssetRegistry[asset];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setPrecedingContract(
        address precedingContract,
        bool isValid
    ) external onlyOwner {
        _headRegistry[precedingContract] = isValid;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setSucceedingContract(
        address succeedingContract,
        bool isValid
    ) external onlyOwner {
        _tailRegistry[succeedingContract] = isValid;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setInboundAsset(address asset, bool isValid) external onlyOwner {
        _inboundAssetRegistry[asset] = isValid;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setOutboundAsset(address asset, bool isValid) external onlyOwner {
        _outboundAssetRegistry[asset] = isValid;
    }

    /**
     * @notice modifier to ensure that only owner can call this function
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == _owner, "Only owner");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Basic} from "./common/Basic.sol";
import {Errors} from "./utils/Errors.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";
import {AdapterDataProvider} from "./AdapterDataProvider.sol";

/**
 * @title BaseAdapter
 * @author Router Protocol
 * @notice This contract is the base implementation of an intent adapter based on Router
 * Cross-Chain Intent Framework.
 */
abstract contract BaseAdapter is Basic, ReentrancyGuard {
    address private immutable _self;
    address private immutable _native;
    address private immutable _wnative;
    AdapterDataProvider private immutable _adapterDataProvider;

    event ExecutionEvent(string indexed adapterName, bytes data);
    event OperationFailedRefundEvent(
        address token,
        address recipient,
        uint256 amount
    );
    event UnsupportedOperation(
        address token,
        address refundAddress,
        uint256 amount
    );

    constructor(
        address __native,
        address __wnative,
        bool __deployDataProvider,
        address __owner
    ) {
        _self = address(this);
        _native = __native;
        _wnative = __wnative;

        AdapterDataProvider dataProvider;

        if (__deployDataProvider)
            dataProvider = new AdapterDataProvider(__owner);
        else dataProvider = AdapterDataProvider(address(0));

        _adapterDataProvider = dataProvider;
    }

    /**
     * @dev function to get the address of weth
     */
    function wnative() public view override returns (address) {
        return _wnative;
    }

    /**
     * @dev function to get the address of native token
     */
    function native() public view override returns (address) {
        return _native;
    }

    /**
     * @dev function to get the AdapterDataProvider instance for this contract
     */
    function adapterDataProvider() public view returns (AdapterDataProvider) {
        return _adapterDataProvider;
    }

    /**
     * @dev Function to check whether the contract is a valid preceding contract registered in
     * the head registry.
     * @dev This registry governs the initiation of the adapter, exclusively listing authorized
     * preceding adapters.
     * @notice Only the adapters documented in this registry can invoke the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param precedingContract Address of preceding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedPrecedingContract(
        address precedingContract
    ) public view returns (bool) {
        return
            _adapterDataProvider.isAuthorizedPrecedingContract(
                precedingContract
            );
    }

    /**
     * @dev Function to check whether the contract is a valid succeeding contract registered in
     * the tail registry.
     * @dev This registry dictates the potential succeeding actions by listing adapters that
     * may be invoked following the current one.
     * @notice Only the adapters documented in this registry can be invoked by the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param succeedingContract Address of succeeding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedSucceedingContract(
        address succeedingContract
    ) public view returns (bool) {
        return
            _adapterDataProvider.isAuthorizedSucceedingContract(
                succeedingContract
            );
    }

    /**
     * @dev Function to check whether the asset is a valid inbound asset registered in the inbound
     * asset registry.
     * @dev This registry keeps track of all the acceptable incoming assets, ensuring that the
     * adapter only processes predefined asset types.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidInboundAsset(address asset) public view returns (bool) {
        return _adapterDataProvider.isValidInboundAsset(asset);
    }

    /**
     * @dev Function to check whether the asset is a valid outbound asset registered in the outbound
     * asset registry.
     * @dev It manages the types of assets that the adapter is allowed to output, thus controlling
     * the flow’s output and maintaining consistency.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidOutboundAsset(address asset) public view returns (bool) {
        return _adapterDataProvider.isValidOutboundAsset(asset);
    }

    /**
     * @dev function to get the name of the adapter
     */
    function name() public view virtual returns (string memory);

    /**
     * @dev function to get the address of the contract
     */
    function self() public view returns (address) {
        return _self;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {TokenInterface} from "./Interfaces.sol";
import {TokenUtilsBase} from "./TokenUtilsBase.sol";

abstract contract Basic is TokenUtilsBase {
    function getTokenBal(address token) internal view returns (uint _amt) {
        _amt = address(token) == native()
            ? address(this).balance
            : TokenInterface(token).balanceOf(address(this));
    }

    function approve(address token, address spender, uint256 amount) internal {
        // solhint-disable-next-line no-empty-blocks
        try TokenInterface(token).approve(spender, amount) {} catch {
            TokenInterface(token).approve(spender, 0);
            TokenInterface(token).approve(spender, amount);
        }
    }

    function convertNativeToWnative(uint amount) internal {
        TokenInterface(wnative()).deposit{value: amount}();
    }

    function convertWnativeToNative(uint amount) internal {
        TokenInterface(wnative()).withdraw(amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IWETH} from "../interfaces/IWETH.sol";
import {SafeERC20, IERC20} from "../utils/SafeERC20.sol";

abstract contract TokenUtilsBase {
    using SafeERC20 for IERC20;

    function wnative() public view virtual returns (address);

    function native() public view virtual returns (address);

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == native()) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (
            _from != address(0) &&
            _from != address(this) &&
            _token != native() &&
            _amount != 0
        ) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != native()) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "native send fail");
            }
        }

        return _amount;
    }

    function depositWnative(uint256 _amount) internal {
        IWETH(wnative()).deposit{value: _amount}();
    }

    function withdrawWnative(uint256 _amount) internal {
        IWETH(wnative()).withdraw(_amount);
    }

    function getBalance(
        address _tokenAddr,
        address _acc
    ) internal view returns (uint256) {
        if (_tokenAddr == native()) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == native()) return 18;

        return IERC20(_token).decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Interface for Adapter Data Provider contract for intent adapter.
 * @author Router Protocol.
 */

interface IAdapterDataProvider {
    /**
     * @dev Function to get the address of owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Function to set the address of owner.
     * @dev This function can only be called by the owner of this contract.
     * @param __owner Address of the new owner
     */
    function setOwner(address __owner) external;

    /**
     * @dev Function to check whether the contract is a valid preceding contract registered in
     * the head registry.
     * @dev This registry governs the initiation of the adapter, exclusively listing authorized
     * preceding adapters.
     * @notice Only the adapters documented in this registry can invoke the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param precedingContract Address of preceding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedPrecedingContract(
        address precedingContract
    ) external view returns (bool);

    /**
     * @dev Function to check whether the contract is a valid succeeding contract registered in
     * the tail registry.
     * @dev This registry dictates the potential succeeding actions by listing adapters that
     * may be invoked following the current one.
     * @notice Only the adapters documented in this registry can be invoked by the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param succeedingContract Address of succeeding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedSucceedingContract(
        address succeedingContract
    ) external view returns (bool);

    /**
     * @dev Function to check whether the asset is a valid inbound asset registered in the inbound
     * asset registry.
     * @dev This registry keeps track of all the acceptable incoming assets, ensuring that the
     * adapter only processes predefined asset types.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidInboundAsset(address asset) external view returns (bool);

    /**
     * @dev Function to check whether the asset is a valid outbound asset registered in the outbound
     * asset registry.
     * @dev It manages the types of assets that the adapter is allowed to output, thus controlling
     * the flow’s output and maintaining consistency.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidOutboundAsset(address asset) external view returns (bool);

    /**
     * @dev Function to set preceding contract (head registry) for the adapter.
     * @dev This registry governs the initiation of the adapter, exclusively listing authorized
     * preceding adapters.
     * @notice Only the adapters documented in this registry can invoke the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param precedingContract Address of preceding contract.
     * @param isValid Boolean value suggesting if this is a valid preceding contract.
     */
    function setPrecedingContract(
        address precedingContract,
        bool isValid
    ) external;

    /**
     * @dev Function to set succeeding contract (tail registry) for the adapter.
     * @dev This registry dictates the potential succeeding actions by listing adapters that
     * may be invoked following the current one.
     * @notice Only the adapters documented in this registry can be invoked by the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param succeedingContract Address of succeeding contract.
     * @param isValid Boolean value suggesting if this is a valid succeeding contract.
     */
    function setSucceedingContract(
        address succeedingContract,
        bool isValid
    ) external;

    /**
     * @dev Function to set inbound asset registry for the adapter.
     * @dev This registry keeps track of all the acceptable incoming assets, ensuring that the
     * adapter only processes predefined asset types.
     * @param asset Address of the asset.
     * @param isValid Boolean value suggesting if this is a valid inbound asset.
     */
    function setInboundAsset(address asset, bool isValid) external;

    /**
     * @dev Function to set outbound asset registry for the adapter.
     * @dev It manages the types of assets that the adapter is allowed to output, thus controlling
     * the flow’s output and maintaining consistency.
     * @param asset Address of the asset.
     * @param isValid Boolean value suggesting if this is a valid inbound asset.
     */
    function setOutboundAsset(address asset, bool isValid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../utils/SafeERC20.sol";

abstract contract IWETH {
    function allowance(address, address) public view virtual returns (uint256);

    function balanceOf(address) public view virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseAdapter} from "./BaseAdapter.sol";
import {EoaExecutorWithDataProvider, EoaExecutorWithoutDataProvider} from "./utils/EoaExecutor.sol";

abstract contract RouterIntentEoaAdapterWithDataProvider is
    BaseAdapter,
    EoaExecutorWithDataProvider
{
    constructor(
        address __native,
        address __wnative,
        address __owner
    )
        BaseAdapter(__native, __wnative, true, __owner)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

abstract contract RouterIntentEoaAdapterWithoutDataProvider is
    BaseAdapter,
    EoaExecutorWithoutDataProvider
{
    constructor(
        address __native,
        address __wnative
    )
        BaseAdapter(__native, __wnative, false, address(0))
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)) {
            revert SendingValueFail();
        }
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value) {
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))) {
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract EoaExecutorWithDataProvider {
    /**
     * @dev function to execute an action on an adapter used in an EOA.
     * @param precedingAdapter Address of the preceding adapter.
     * @param succeedingAdapter Address of the succeeding adapter.
     * @param data inputs data.
     * @return tokens to be refunded to user at the end of tx.
     */
    function execute(
        address precedingAdapter,
        address succeedingAdapter,
        bytes calldata data
    ) external payable virtual returns (address[] memory tokens);
}

abstract contract EoaExecutorWithoutDataProvider {
    /**
     * @dev function to execute an action on an adapter used in an EOA.
     * @param data inputs data.
     * @return tokens to be refunded to user at the end of tx.
     */
    function execute(
        bytes calldata data
    ) external payable virtual returns (address[] memory tokens);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/**
 * @title Errors library
 * @author Router Intents Error
 * @notice Defines the error messages emitted by the contracts on Router Intents
 */
library Errors {
    string public constant ARRAY_LENGTH_MISMATCH = "1"; // 'Array lengths mismatch'
    string public constant INSUFFICIENT_NATIVE_FUNDS_PASSED = "2"; // 'Insufficient native tokens passed'
    string public constant WRONG_BATCH_PROVIDED = "3"; // 'The targetLength, valueLength, callTypeLength, funcLength do not match in executeBatch transaction functions in batch transaction contract'
    string public constant INVALID_CALL_TYPE = "4"; // 'The callType value can only be 1 (call)' and 2(delegatecall)'
    string public constant ONLY_NITRO = "5"; // 'Only nitro can call this function'
    string public constant ONLY_SELF = "6"; // 'Only the current contract can call this function'
    string public constant ADAPTER_NOT_WHITELISTED = "7"; // 'Adapter not whitelisted'
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error ReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../interfaces/IERC20.sol";
import {Address} from "./Address.sol";
import {SafeMath} from "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, 0)
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: operation failed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: mul overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum OrderType {
    OPEN_NEW_POSITION, // Open a new position
    CLOSE_POSITION, // Close an existing position
    INCREASE_POSITION, // Increase position by adding more collateral and/or increasing position size
    DECREASE_POSITION // Decrease position by removing collateral and/or decreasing position size
}

struct Order {
    bytes32 marketId; // keccak256 hash of asset symbol + vaultAddress
    address userAddress; // User that signed/submitted the order
    OrderType orderType; // Refer enum OrderType
    bool isLong; // Set to true if it is a Long order, false for a Short order
    bool isLimitOrder; // Flag to identify limit orders
    bool triggerAbove; // Flag to trigger price above or below expectedPrice
    uint256 deadline; // Timestamp after which order cannot be executed
    uint256 deltaCollateral; // Change in collateral amount (increased/decreased)
    uint256 deltaSize; // Change in Order size (increased/decreased)
    uint256 expectedPrice; // Desired Value for order execution
    uint256 maxSlippage; // Maximum allowed slippage in executionPrice from expectedPrice (in basis points)
    address partnerAddress; // Address that receives referral fees for new position orders (a share of opening fee)
}

interface IParifiOrderManager {
    function createNewPosition(Order memory _order, bool isRelayed) external;

    function getOrderIdForUser(
        address userAddress
    ) external view returns (bytes32 orderId);

    function getPendingOrder(
        bytes32 orderId
    ) external view returns (Order memory orderDetails);
}

interface IParifiDataFabric {
    function getDepositToken(bytes32 marketId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {RouterIntentEoaAdapterWithoutDataProvider, EoaExecutorWithoutDataProvider} from "@routerprotocol/intents-core/contracts/RouterIntentEoaAdapter.sol";
import {IParifiOrderManager, Order, IParifiDataFabric} from "./Interfaces.sol";
import {IERC20, SafeERC20} from "../../../utils/SafeERC20.sol";

contract ParifiOpenPosition is RouterIntentEoaAdapterWithoutDataProvider {
    using SafeERC20 for IERC20;

    IParifiOrderManager public immutable parifiOrderManager;
    IParifiDataFabric public immutable parifiDataFabric;

    constructor(
        address __native,
        address __wnative,
        address __parifiOrderManager,
        address __parifiDataFabric
    ) RouterIntentEoaAdapterWithoutDataProvider(__native, __wnative) {
        parifiOrderManager = IParifiOrderManager(__parifiOrderManager);
        parifiDataFabric = IParifiDataFabric(__parifiDataFabric);
    }

    function name() public pure override returns (string memory) {
        return "ParifiOpenPosition";
    }

    /**
     * @inheritdoc EoaExecutorWithoutDataProvider
     */
    function execute(
        bytes calldata data
    ) external payable override returns (address[] memory tokens) {
        Order memory order = parseInputs(data);

        address token = parifiDataFabric.getDepositToken(order.marketId);

        if (uint8(order.orderType) != 0) revert("order type != 0");

        if (address(this) == self())
            IERC20(token).safeTransferFrom(
                msg.sender,
                self(),
                order.deltaCollateral
            );
        else if (order.deltaCollateral == type(uint256).max)
            order.deltaCollateral = IERC20(token).balanceOf(address(this));

        bytes memory logData;

        (tokens, logData) = _openNewPosition(
            token,
            order.deltaCollateral,
            order
        );

        emit ExecutionEvent(name(), logData);
        return tokens;
    }

    //////////////////////////// ACTION LOGIC ////////////////////////////

    function _openNewPosition(
        address token,
        uint256 amount,
        Order memory order
    ) internal returns (address[] memory tokens, bytes memory logData) {
        IERC20(token).safeIncreaseAllowance(
            address(parifiOrderManager),
            amount
        );

        parifiOrderManager.createNewPosition(order, true);

        tokens = new address[](1);
        tokens[0] = token;

        logData = abi.encode(token, amount);
    }

    /**
     * @dev function to parse input data.
     * @param data input data.
     */
    function parseInputs(bytes memory data) public pure returns (Order memory) {
        return abi.decode(data, (Order));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)) {
            revert SendingValueFail();
        }
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value) {
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))) {
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../interfaces/IERC20.sol";
import {Address} from "./Address.sol";
import {SafeMath} from "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, 0)
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: operation failed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: mul overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
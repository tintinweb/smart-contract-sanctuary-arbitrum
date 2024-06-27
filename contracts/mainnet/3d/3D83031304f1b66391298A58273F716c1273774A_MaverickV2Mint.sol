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

struct SupplyData {
    address tokenA;
    address tokenB;
    uint256 tokenAAmount;
    uint256 tokenBAmount;
    address recipient;
    bytes[] data;
}

interface IMaverickV2RewardsRouter {
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    /**
     * @notice Function to check if the price of a pool is within specified bounds.
     * @param pool The MaverickV2Pool contract to check.
     * @param minSqrtPrice The minimum acceptable square root price.
     * @param maxSqrtPrice The maximum acceptable square root price.
     */
    function checkSqrtPrice(
        IMaverickV2Pool pool,
        uint256 minSqrtPrice,
        uint256 maxSqrtPrice
    ) external view;

    /**
     * @notice Mint new tokenId in the Position NFT contract. Both mints an NFT
     * and adds liquidity to the pool that is held by the NFT.
     * @dev Caller must approve this LiquidityManager contract to spend the
     * caller's token A/B in order to fund the liquidity position.
     *
     * See addLiquidity for a description of the add params.
     */
    function mintPositionNft(
        IMaverickV2Pool pool,
        address recipient,
        bytes calldata packedSqrtPriceBreaks,
        bytes[] calldata packedArgs
    )
        external
        payable
        returns (
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint32[] memory binIds,
            uint256 tokenId
        );

    /**
     * @notice Maverick V2 NFT position contract that tracks NFT-based
     * liquditiy positions.
     */
    function position() external view returns (IMaverickV2Position);
}

interface IMaverickV2PoolLens {
    struct TickDeltas {
        uint256 deltaAOut;
        uint256 deltaBOut;
        uint256[] deltaAs;
        uint256[] deltaBs;
    }

    /**
     * @notice Multi-price add param specification.
     * @param slippageFactorD18 Max slippage allowed as a percent in D18 scale. e.g. 1% slippage is 0.01e18
     * @param numberOfPriceBreaksPerSide Number of price break values on either
     * side of current price.
     * @param targetAmount Target token contribution amount in tokenA if
     * targetIsA is true, otherwise this is the target amount for tokenB.
     * @param targetIsA  Indicates if the target amount is for tokenA or tokenB
     */
    struct AddParamsSpecification {
        uint256 slippageFactorD18;
        uint256 numberOfPriceBreaksPerSide;
        uint256 targetAmount;
        bool targetIsA;
    }

    /**
     * @notice Add liquidity slippage parameters for a distribution of liquidity.
     * @param pool Pool where liquidity is being added.
     * @param kind Bin kind; all bins must have the same kind in a given call
     * to addLiquidity.
     * @param ticks Array of tick values to add liquidity to.
     * @param relativeLiquidityAmounts Relative liquidity amounts for the
     * specified ticks.  Liquidity in this case is not bin LP balance, it is
     * the bin liquidity as defined by liquidity = deltaA / (sqrt(upper) -
     * sqrt(lower)) or deltaB = liquidity / sqrt(lower) - liquidity /
     * sqrt(upper).
     * @param addSpec Slippage specification.
     */
    struct AddParamsViewInputs {
        IMaverickV2Pool pool;
        uint8 kind;
        int32[] ticks;
        uint128[] relativeLiquidityAmounts;
        AddParamsSpecification addSpec;
    }

    /**
     * @notice Converts add parameter slippage specification into add
     * parameters.  The return values are given in both raw format and as packed
     * values that can be used in the LiquidityManager contract.
     */
    function getAddLiquidityParams(
        AddParamsViewInputs memory params
    )
        external
        view
        returns (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            uint88[] memory sqrtPriceBreaks,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,
            IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
        );

    /**
     * @notice Pool sqrt price.
     */
    function getPoolSqrtPrice(
        IMaverickV2Pool pool
    ) external view returns (uint256 sqrtPrice);
}

interface IMaverickV2Quoter {
    /**
     * @notice Computes the token amounts required for a given set of
     * addLiquidity parameters. The gas estimate is only a rough estimate and
     * may not match a add's gas.
     */
    function calculateAddLiquidity(
        IMaverickV2Pool pool,
        IMaverickV2Pool.AddLiquidityParams calldata params
    ) external returns (uint256 amountA, uint256 amountB, uint256 gasEstimate);
}

interface IMaverickV2Position {
    struct PositionPoolBinIds {
        IMaverickV2Pool pool;
        uint32[] binIds;
    }

    struct PositionFullInformation {
        PositionPoolBinIds poolBinIds;
        uint256 amountA;
        uint256 amountB;
        uint256[] binAAmounts;
        uint256[] binBAmounts;
        int32[] ticks;
        uint256[] liquidities;
    }

    /**
     * @notice NFT asset information for a given pool/binIds index. This
     * function only returns the liquidity in the pools/binIds stored as part
     * of the tokenIdData, but it is possible that the NFT has additional
     * liquidity in pools/binIds that have not been recorded.
     */
    function tokenIdPositionInformation(
        uint256 tokenId,
        uint256 index
    ) external view returns (PositionFullInformation memory output);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMaverickV2Pool {
    /**
     * @notice Parameters associated with adding liquidity.
     * @param kind One of the 4 kinds (0=static, 1=right, 2=left, 3=both).
     * @param ticks Array of ticks to add liquidity to.
     * @param amounts Array of bin LP amounts to add.
     */
    struct AddLiquidityParams {
        uint8 kind;
        int32[] ticks;
        uint128[] amounts;
    }

    /**
     * @notice State of the pool.
     * @param reserveA Pool tokenA balanceOf at end of last operation
     * @param reserveB Pool tokenB balanceOf at end of last operation
     * @param lastTwaD8 Value of log time weighted average price at last block.
     * Value is 8-decimal scale and is in the fractional tick domain.  E.g. a
     * value of 12.3e8 indicates the TWAP was 3/10ths of the way into the 12th
     * tick.
     * @param lastLogPriceD8 Value of log price at last block. Value is
     * 8-decimal scale and is in the fractional tick domain.  E.g. a value of
     * 12.3e8 indicates the price was 3/10ths of the way into the 12th tick.
     * @param lastTimestamp Last block.timestamp value in seconds for latest
     * swap transaction.
     * @param activeTick Current tick position that contains the active bins.
     * @param isLocked Pool isLocked, E.g., locked or unlocked; isLocked values
     * defined in Pool.sol.
     * @param binCounter Index of the last bin created.
     * @param protocolFeeRatioD3 Ratio of the swap fee that is kept for the
     * protocol.
     */
    struct State {
        uint128 reserveA;
        uint128 reserveB;
        int64 lastTwaD8;
        int64 lastLogPriceD8;
        uint40 lastTimestamp;
        int32 activeTick;
        bool isLocked;
        uint32 binCounter;
        uint8 protocolFeeRatioD3;
    }

    /**
     * @notice External function to get the state of the pool.
     */
    function getState() external view returns (State memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IMaverickV2RewardsRouter, IMaverickV2Position, SupplyData} from "./Interfaces.sol";
import {RouterIntentEoaAdapterWithoutDataProvider, EoaExecutorWithoutDataProvider} from "@routerprotocol/intents-core/contracts/RouterIntentEoaAdapter.sol";
import {Errors} from "@routerprotocol/intents-core/contracts/utils/Errors.sol";
import {IERC20, SafeERC20} from "../../../utils/SafeERC20.sol";

/**
 * @title MaverickV2Mint
 * @author Shivam Agrawal
 * @notice Adding liquidity on Maverick V2.
 */
contract MaverickV2Mint is RouterIntentEoaAdapterWithoutDataProvider {
    using SafeERC20 for IERC20;

    IMaverickV2RewardsRouter public immutable maverickV2RewardsRouter;
    IMaverickV2Position public immutable maverickV2Positon;

    constructor(
        address __native,
        address __wnative,
        address __maverickV2RewardsRouter
    ) RouterIntentEoaAdapterWithoutDataProvider(__native, __wnative) {
        maverickV2RewardsRouter = IMaverickV2RewardsRouter(
            __maverickV2RewardsRouter
        );

        maverickV2Positon = maverickV2RewardsRouter.position();
    }

    function name() public pure override returns (string memory) {
        return "MaverickV2Mint";
    }

    /**
     * @inheritdoc EoaExecutorWithoutDataProvider
     */
    function execute(
        bytes calldata data
    ) external payable override returns (address[] memory tokens) {
        SupplyData memory mintParams = parseInputs(data);

        // If the adapter is called using `call` and not `delegatecall`
        if (address(this) == self()) {
            if (mintParams.tokenA != native())
                IERC20(mintParams.tokenA).safeTransferFrom(
                    msg.sender,
                    self(),
                    mintParams.tokenAAmount
                );
            else
                require(
                    msg.value == mintParams.tokenAAmount,
                    Errors.INSUFFICIENT_NATIVE_FUNDS_PASSED
                );

            if (mintParams.tokenB != native())
                IERC20(mintParams.tokenB).safeTransferFrom(
                    msg.sender,
                    self(),
                    mintParams.tokenBAmount
                );
            else
                require(
                    msg.value == mintParams.tokenBAmount,
                    Errors.INSUFFICIENT_NATIVE_FUNDS_PASSED
                );
        } else {
            if (mintParams.tokenAAmount == type(uint256).max)
                mintParams.tokenAAmount = getBalance(
                    mintParams.tokenA,
                    address(this)
                );

            if (mintParams.tokenBAmount == type(uint256).max)
                mintParams.tokenBAmount = getBalance(
                    mintParams.tokenB,
                    address(this)
                );
        }

        if (mintParams.tokenA == native()) {
            convertNativeToWnative(mintParams.tokenAAmount);
            mintParams.tokenA = wnative();
        }

        if (mintParams.tokenB == native()) {
            convertNativeToWnative(mintParams.tokenBAmount);
            mintParams.tokenB = wnative();
        }

        IERC20(mintParams.tokenA).safeIncreaseAllowance(
            address(maverickV2RewardsRouter),
            mintParams.tokenAAmount
        );

        IERC20(mintParams.tokenB).safeIncreaseAllowance(
            address(maverickV2RewardsRouter),
            mintParams.tokenBAmount
        );

        (uint256 tokenAAmount, uint256 tokenBAmount, uint256 tokenId) = _mint(
            mintParams
        );

        bytes memory logData = abi.encode(
            mintParams,
            tokenId,
            tokenAAmount,
            tokenBAmount
        );

        tokens = new address[](2);
        tokens[0] = mintParams.tokenA;
        tokens[1] = mintParams.tokenB;

        emit ExecutionEvent(name(), logData);
        return tokens;
    }

    //////////////////////////// ACTION LOGIC ////////////////////////////

    function _mint(
        SupplyData memory _mintParams
    )
        internal
        returns (uint256 tokenAAmount, uint256 tokenBAmount, uint256 tokenId)
    {
        bytes[] memory results = maverickV2RewardsRouter.multicall(
            _mintParams.data
        );

        (tokenAAmount, tokenBAmount, , tokenId) = abi.decode(
            results[1],
            (uint256, uint256, uint32[], uint256)
        );

        if (_mintParams.recipient != maverickV2Positon.ownerOf(tokenId))
            revert("Add position failed");
    }

    /**
     * @dev function to parse input data.
     * @param data input data.
     */
    function parseInputs(
        bytes memory data
    ) public pure returns (SupplyData memory) {
        return abi.decode(data, (SupplyData));
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
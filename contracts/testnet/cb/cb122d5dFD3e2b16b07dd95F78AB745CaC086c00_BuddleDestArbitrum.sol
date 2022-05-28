// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_abstract/BuddleDestination.sol";

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

contract BuddleDestArbitrum is BuddleDestination {

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleDestination
     */
    function isBridgeContract() internal view override returns (bool) {
        return (AddressAliasHelper.undoL1ToL2Alias(msg.sender) == buddleBridge);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_interface/IBuddleDestination.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 *
 */
abstract contract BuddleDestination is IBuddleDestination, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public VERSION;
    address constant BASE_TOKEN_ADDRESS = address(0);

    address public buddleBridge;

    mapping(uint256 => mapping(uint256 => address)) public liquidityOwners;
    mapping(uint256 => mapping(uint256 => uint256)) public transferFee;
    mapping(uint256 => mapping(bytes32 => bool)) internal liquidityHashes;
    mapping(uint256 => mapping(bytes32 => bool)) internal approvedRoot;

    /********** 
     * events *
     **********/

    event TransferCompleted(
        TransferData transferData,
        uint256 transferID,
        uint256 sourceChain,
        address liquidityProvider
    );

    event WithdrawalEvent(
        TransferData transferData,
        uint256 transferID,
        uint256 sourceChain,
        address claimer
    );

    event LiquidityOwnerChanged(
        uint256 sourceChain,
        uint256 transferID,
        address oldOwner,
        address newOwner
    );

    event RootApproved(
        uint256 sourceChain,
        bytes32 stateRoot
    );

    /************
     * modifers *
     ************/
    
    /**
     * Checks whether the contract is initialized
     *
     */
    modifier checkInitialization() {
        require(bytes32(VERSION) != bytes32(""), "Contract not yet initialzied");
        _;
    }

    /**
     * Checks that the caller is either the owner of liquidity or the destination of a transfer
     *
     */
    modifier validOwner(
        uint256 sourceChain,
        uint256 _id,
        address _destination
    ) {
        require( liquidityOwners[sourceChain][_id] == msg.sender ||
            (liquidityOwners[sourceChain][_id] == address(0) && _destination == msg.sender),
            "Can only be called by owner or destination if there is no owner."
        );
        _;
    }

    /********************** 
     * virtual functions *
     ***********************/
    
    /**
    * Returns true if the msg.sender is the buddleBridge contract address
    *
    */
    function isBridgeContract() internal virtual returns (bool);

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * Initialize the contract with state variables
     * 
     * @param _version Contract version
     * @param _buddleBridge Buddle Bridge contract on Layer-1
     */
    function initialize(
        bytes32 _version,
        address _buddleBridge
    ) external onlyOwner {
        require(bytes32(VERSION) == bytes32(""), "contract already initialized!");
        
        VERSION = _version;
        buddleBridge = _buddleBridge;
    }

    /**
     * @inheritdoc IBuddleDestination
     */
    function updateBuddleBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        buddleBridge = _newBridgeAddress;
    }
    
    /********************** 
     * public functions *
     ***********************/
    
    /**
     * @inheritdoc IBuddleDestination
     */
    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        uint256 sourceChain,
        address _owner
    ) external 
      checkInitialization
      validOwner(sourceChain, _transferID, _data.destination) {
        address _old = liquidityOwners[sourceChain][_transferID] == address(0)?
            _data.destination : liquidityOwners[sourceChain][_transferID];
        liquidityOwners[sourceChain][_transferID] = _owner;
        
        emit LiquidityOwnerChanged(sourceChain, _transferID, _old, _owner);
    }

    /**
     * @inheritdoc IBuddleDestination
     */
    function deposit(
        TransferData memory transferData, 
        uint256 transferID,
        uint256 sourceChain
    ) external payable checkInitialization {
        require(liquidityOwners[sourceChain][transferID] == address(0),
            "A Liquidity Provider already exists for this transfer"
        );
        
        transferFee[sourceChain][transferID] = getLPFee(transferData, block.timestamp);
        uint256 amountMinusLPFee = transferData.amount - transferFee[sourceChain][transferID];

        if (transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(msg.value >= amountMinusLPFee, "Not enough tokens sent");
            payable(transferData.destination).transfer(amountMinusLPFee);
        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountMinusLPFee);
            token.safeTransfer(transferData.destination, amountMinusLPFee);
        }
        liquidityOwners[sourceChain][transferID] = msg.sender;
        liquidityHashes[sourceChain][_generateNode(transferData, transferID)] = true;

        emit TransferCompleted(transferData, transferID, sourceChain, msg.sender);
    }

    /**
     * @inheritdoc IBuddleDestination
     */
    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        uint256 sourceChain,
        bytes32 _node,
        bytes32[] memory _proof,
        bytes32 _root
    ) external 
      checkInitialization
      validOwner(sourceChain, transferID, transferData.destination) {

        require(_verifyNode(transferData, transferID, _node), "Invalid node fromed");
        require(_verifyProof(_node, _proof, _root), "Invalid root formed from proof");
        require(approvedRoot[sourceChain][_root], "Unknown root provided");

        // Check if hashed node is known in case of owner existance
        // ie, if the deposit() transferData does not match withdraw() transferData
        //  reset liquidity owner for the transfer id
        if(liquidityOwners[sourceChain][transferID] != address(0)
            && !liquidityHashes[sourceChain][_node]) {
            liquidityOwners[sourceChain][transferID] = address(0);
        }

        address claimer = liquidityOwners[sourceChain][transferID] == address(0)? 
            transferData.destination : liquidityOwners[sourceChain][transferID];
        
        if(transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(address(this).balance >= transferData.amount,
                "Contract doesn't have enough funds yet."
            );
            payable(claimer).transfer(transferData.amount);

        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            token.safeTransferFrom(address(this), claimer, transferData.amount);
        }

        liquidityOwners[sourceChain][transferID] = address(this);
        liquidityHashes[sourceChain][_node] = false;

        emit WithdrawalEvent(transferData, transferID, sourceChain, claimer);
    }

    /**
     * @inheritdoc IBuddleDestination
     */
    function approveStateRoot(
        uint256 sourceChain,
        bytes32 stateRoot
    ) external checkInitialization {
        require(isBridgeContract(), "Only the Buddle Bridge contract can call this method");
        
        approvedRoot[sourceChain][stateRoot] = true;

        emit RootApproved(sourceChain, stateRoot);
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * Generate a hash node with the given transfer data and transfer id
     *
     * @param _transferData Transfer Data of the transfer emitted under TransferCreated event
     * @param transferID Transfer ID of the transfer emitted under TransferCreated event
     */
    function _generateNode(
        TransferData memory _transferData, 
        uint256 transferID
    ) internal view returns (bytes32 node) {
        bytes32 transferDataHash = sha256(abi.encodePacked(
            _transferData.tokenAddress,
            _transferData.destination,
            _transferData.amount,
            _transferData.fee,
            _transferData.startTime,
            _transferData.feeRampup,
            _transferData.chain
        ));
        node = sha256(abi.encodePacked(
            transferDataHash, 
            sha256(abi.encodePacked(address(this))), // TODO: this line may cause an error
            sha256(abi.encodePacked(transferID))
        ));
    }

    /**
     * Verify that the transfer data provided matches the hash provided
     *
     */
    function _verifyNode(
        TransferData memory _transferData, 
        uint256 transferID, 
        bytes32 _node
    ) internal view returns (bool) {
        return _generateNode(_transferData, transferID) == _node;
    }
    
    /**
     * Verify that the root formed from the node and proof is the provided root
     *
     */
    function _verifyProof(
        bytes32 _node,
        bytes32[] memory _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        bytes32 value = _node;
        for(uint n = 0; n < _proof.length; n++) {
            if(((n / (2**n)) % 2) == 1)
                value = sha256(abi.encodePacked(_proof[n], value));
            else
                value = sha256(abi.encodePacked(value, _proof[n]));
        }
        return (value == _root);
    }

    /**
     * Calculates the fees for the Liquidity Provider
     * @notice see https://notes.ethereum.org/@vbuterin/cross_layer_2_bridges
     * 
     * @param _transferData The transfer metadata of the cross chain transfer
     * @param _currentTime The current blocktime to calculate fee ramp up
     */
    function getLPFee(
        TransferData memory _transferData,
        uint256 _currentTime
    ) internal pure returns (uint256) {
        if(_currentTime < _transferData.startTime)
            return 0;
        else if(_currentTime >= _transferData.startTime + _transferData.feeRampup)
            return _transferData.fee;
        else
            return _transferData.fee * (_transferData.feeRampup - (_currentTime - _transferData.startTime));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

//SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

interface IBuddleDestination {

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
        uint256 chain;
    }

    /********************** 
     * onlyOwner functions *
     ***********************/
    
    /**
     * Initialize the contract with state variables
     * 
     * @param _version Contract version
     * @param _buddleBridge Buddle Bridge contract on Layer-1
     */
    function initialize(
        bytes32 _version,
        address _buddleBridge
    ) external;

    /**
     * Change the buddle bridge address
     *
     * @param _newBridgeAddress new bridge address
     */
    function updateBuddleBridge(
        address _newBridgeAddress
    ) external;
    
    /********************** 
     * public functions *
     ***********************/
    
    /**
     * A valid liquidity owner for a transferID may change the owner if desired
     *
     * @param _data The transfer data corresponding to the transfer id
     * @param _transferID The transfer ID corresponding to the transfer data
     * @param sourceChain The chain id of the blockchain where the transfer originated
     * @param _owner The new owner for the transfer
     */
    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        uint sourceChain,
        address _owner
    ) external;

    /**
     * Deposit funds into the contract to transfer to the destination of the transfer.
     * If no owner exists, anyone may call this function to complete a transfer
     * and claim ownership of the LP fee
     *
     * @param transferData Transfer Data of the transfer emitted under TransferEvent
     * @param transferID Transfer ID of the transfer emitted under TransferEvent
     * @param sourceChain The chain ID for the source blockchain of transfer
     */
    function deposit(
        TransferData memory transferData, 
        uint256 transferID,
        uint sourceChain
    ) external payable;

    /**
     * This function is called under two cases,
     * (i) A LP calls this function after funds have been bridged
     * (ii) If no LP exists, the destination of the transfer calls this to claim bridged funds
     *
     * @param transferData Transfer Data of the transfer emitted under TransferCreated event
     * @param transferID Transfer ID of the transfer emitted under TransferCreated event
     * @param sourceChain The chain ID for the source blockchain of transfer
     * @param _node Hash of the transfer data emitted under TransferCreated event
     * @param _proof Path from node to root. Should be calculated offline
     * @param _root State root emitted under TicketCreated event
     */
    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        uint sourceChain,
        bytes32 _node,
        bytes32[] memory _proof,
        bytes32 _root
    ) external;

    /**
     * Approve a new root for an incoming transfer
     * @notice only the Buddle Bridge contract on Layer 1 can call this method
     *
     * @param sourceChain The chain id of the blockchain where the root originated
     * @param stateRoot The state root to be approved
     */
    function approveStateRoot(
        uint sourceChain,
        bytes32 stateRoot
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
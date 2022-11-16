// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@violetprotocol/extendable/extensions/InternalExtension.sol";

interface IGetterLogic {
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) external returns (address);

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external returns (bool);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * Requirements:
     *
     * - Must be modified with `public _internal`.
     */
    function _exists(uint256 tokenId) external returns (bool);

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - Must be modified with `public _internal`.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) external returns (bool);
}

abstract contract GetterExtension is IGetterLogic, InternalExtension {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            "function balanceOf(address owner) external view returns (uint256);\n"
            "function ownerOf(uint256 tokenId) external view returns (address);\n"
            "function getApproved(uint256 tokenId) external view returns (address);\n"
            "function isApprovedForAll(address owner, address operator) external view returns (bool);\n"
            "function _exists(uint256 tokenId) external view returns (bool);\n"
            "function _isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);\n";
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](1);

        bytes4[] memory functions = new bytes4[](6);
        functions[0] = IGetterLogic.balanceOf.selector;
        functions[1] = IGetterLogic.ownerOf.selector;
        functions[2] = IGetterLogic.getApproved.selector;
        functions[3] = IGetterLogic.isApprovedForAll.selector;
        functions[4] = IGetterLogic._exists.selector;
        functions[5] = IGetterLogic._isApprovedOrOwner.selector;

        interfaces[0] = Interface(type(IGetterLogic).interfaceId, functions);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external returns (bool);
}


/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Uses Extendable storage pattern to populate the registered interfaces storage variable.
 */
interface IERC165Register {
    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function registerInterface(bytes4 interfaceId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev  ExtensionNotImplemented error is emitted by Extendable and Extensions
 *       where no implementation for a specified function signature exists
 *       in the contract
*/
error ExtensionNotImplemented();


/**
 * @dev  Utility library for contracts to catch custom errors
 *       Pass in a return `result` from a call, and the selector for your error message
 *       and the `catchCustomError` function will return `true` if the error was found
 *       or `false` otherwise
*/
library Errors {
    function catchCustomError(bytes memory result, bytes4 errorSelector) internal pure returns(bool) {
        bytes4 caught;
        assembly {
            caught := mload(add(result, 0x20))
        }

        return caught == errorSelector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IExtension.sol";
import "../errors/Errors.sol";
import "../utils/CallerContext.sol";
import "../erc165/IERC165Logic.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Base contract for Extensions in the Extendable Framework
 *  
 *  Inherit and implement this contract to create Extension contracts!
 *
 *  Implements the EIP-165 standard for interface detection of implementations during runtime.
 *  Uses the ERC165 singleton pattern where the actual implementation logic of the interface is
 *  deployed in a separate contract. See ERC165Logic. Deterministic deployment guarantees the
 *  ERC165Logic contract to always exist as static address 0x16C940672fA7820C36b2123E657029d982629070
 *
 *  Define your custom Extension interface and implement it whilst inheriting this contract:
 *      contract YourExtension is IYourExtension, Extension {...}
 *
 */
abstract contract Extension is CallerContext, IExtension, IERC165, IERC165Register {
    address constant ERC165LogicAddress = 0x16C940672fA7820C36b2123E657029d982629070;

    /**
     * @dev Constructor registers your custom Extension interface under EIP-165:
     *      https://eips.ethereum.org/EIPS/eip-165
    */
    constructor() {
        Interface[] memory interfaces = getInterface();
        for (uint256 i = 0; i < interfaces.length; i++) {
            Interface memory iface = interfaces[i];
            registerInterface(iface.interfaceId);

            for (uint256 j = 0; j < iface.functions.length; j++) {
                registerInterface(iface.functions[j]);
            }
        }

        registerInterface(type(IExtension).interfaceId);
    }

    function supportsInterface(bytes4 interfaceId) external override virtual returns(bool) {
        (bool success, bytes memory result) = ERC165LogicAddress.delegatecall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId));

        if (!success) {
            assembly {
                revert(result, returndatasize())
            }
        }

        return abi.decode(result, (bool));
    }

    function registerInterface(bytes4 interfaceId) public override virtual {
        (bool success, ) = ERC165LogicAddress.delegatecall(abi.encodeWithSignature("registerInterface(bytes4)", interfaceId));

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Unidentified function signature calls to any Extension reverts with
     *      ExtensionNotImplemented error
    */
    function _fallback() internal virtual {
        revert ExtensionNotImplemented();
    }

    /**
     * @dev Fallback function passes to internal _fallback() logic
    */
    fallback() external payable virtual {
        _fallback();
    }
    
    /**
     * @dev Payable fallback function passes to internal _fallback() logic
    */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Virtual override declaration of getFunctionSelectors() function to silence compiler
     *
     * Must be implemented in inherited contract.
    */
    function getInterface() override public virtual returns(Interface[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Interface {
    bytes4 interfaceId;
    bytes4[] functions;
}

/**
 * @dev Interface for Extension
*/
interface IExtension {
    /**
     * @dev Returns a full view of the functional interface of the extension
     *
     * Must return a list of the functions in the interface of your custom Extension
     * in the same format and syntax as in the interface itself as a string, 
     * escaped-newline separated.
     *
     * OPEN TO SUGGESTIONS FOR IMPROVEMENT ON THIS METHODOLOGY FOR 
     * DEEP DESCRIPTIVE RUNTIME INTROSPECTION
     *
     * Intent is to allow developers that want to integrate with an Extendable contract
     * that will have a constantly evolving interface, due to the nature of Extendables,
     * to be able to easily inspect and query for the current state of the interface and
     * integrate with it.
     *
     * See {ExtendLogic-getSolidityInterface} for an example.
    */
    function getSolidityInterface() external pure returns(string memory);

    /**
     * @dev Returns the interface IDs that are implemented by the Extension
     *
     * These are full interface IDs and ARE NOT function selectors. Full interface IDs are
     * XOR'd function selectors of an interface. For example the interface ID of the ERC721
     * interface is 0x80ac58cd determined by the XOR or all function selectors of the interface.
     * 
     * If an interface only consists of a single function, then the interface ID is identical
     * to that function selector.
     * 
     * Provides a simple abstraction from the developer for any custom Extension to 
     * be EIP-165 compliant out-of-the-box simply by implementing this function. 
     *
     * Excludes any functions either already described by other interface definitions
     * that are not developed on top of this backbone i.e. EIP-165, IExtension
    */
    function getInterface() external returns(Interface[] memory interfaces);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Extension.sol";
import "../utils/Internal.sol";
import "../errors/Errors.sol";

/**
 *  ______  __  __  ______  ______  __   __  _____   ______  ______  __      ______    
 * /\  ___\/\_\_\_\/\__  _\/\  ___\/\ "-.\ \/\  __-./\  __ \/\  == \/\ \    /\  ___\
 * \ \  __\\/_/\_\/\/_/\ \/\ \  __\\ \ \-.  \ \ \/\ \ \  __ \ \  __<\ \ \___\ \  __\
 *  \ \_____\/\_\/\_\ \ \_\ \ \_____\ \_\\"\_\ \____-\ \_\ \_\ \_____\ \_____\ \_____\
 *   \/_____/\/_/\/_/  \/_/  \/_____/\/_/ \/_/\/____/ \/_/\/_/\/_____/\/_____/\/_____/
 *
 *  Base contract for Internal Extensions in the Extendable Framework
 *  
 *  Internal Extensions are used to house common functions that are used by other contract extensions.
 *  This is used to make internal functions usable across all your extensions without exposing it
 *  to the external world.
 *
 *  Define your custom Extension interface and implement it whilst inheriting this contract:
 *      contract YourExtension is IYourExtension, InternalExtension {...}
 *
 *  Then define your function and simply modify it in the following way:
 *      contract YourExtension is IYourExtension, InternalExtension {
 *          function _someFunc() public _internal {}
 *      }
 *   
 *  Notice that your internal function carries both the `public` visibility modifier and the `_internal` 
 *  modifier. This is because cross-extension calls are resolved as external calls and `public` allows
 *  your other extensions to call them whilst `_internal` restricts callers to only extensions of the
 *  same contract.
 *
 *  Note:
 *  Use underscores `_` as internal function prefixes as general naming convention.
 */
abstract contract InternalExtension is Internal, Extension {}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct CallerState {
    // Stores a list of callers in the order they are received
    // The current caller context is always the last-most address
    address[] callerStack;
}

library CallerContextStorage {
    bytes32 constant private STORAGE_NAME = keccak256("extendable.framework.v1:caller-state");

    function _getState()
        internal 
        view
        returns (CallerState storage callerState) 
    {
        bytes32 position = keccak256(abi.encodePacked(address(this), STORAGE_NAME));
        assembly {
            callerState.slot := position
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CallerState, CallerContextStorage} from "../storage/CallerContextStorage.sol";

/**
 * @dev CallerContext contract provides Extensions with proper caller-scoped contexts.
 *      Inherit this contract with your Extension to make use of caller references.
 *
 * `msg.sender` may not behave as developer intends when using within Extensions as many
 * calls may be exchanged between intra-contract extensions which result in a `msg.sender` as self.
 * Instead of using `msg.sender`, replace it with 
 *      - `_lastExternalCaller()` for the most recent caller in the call chain that is external to this contract
 *      - `_lastCaller()` for the most recent caller
 *
 * CallerContext provides a deep callstack to track the caller of the Extension/Extendable contract
 * at any point in the execution cycle.
 *
*/
contract CallerContext {
    /**
     * @dev Returns the most recent caller of this contract that came from outside this contract.
     *
     * Used by extensions that require fetching msg.sender that aren't cross-extension calls.
     * Cross-extension calls resolve msg.sender as the current contract and so the actual
     * caller context is obfuscated.
     * 
     * This function should be used in place of `msg.sender` where external callers are read.
     */
    function _lastExternalCaller() internal view returns(address) {
        CallerState storage state = CallerContextStorage._getState();

        for (uint i = state.callerStack.length - 1; i >= 0; i--) {
            address lastSubsequentCaller = state.callerStack[i];
            if (lastSubsequentCaller != address(this)) {
                return lastSubsequentCaller;
            }
        }

        revert("_lastExternalCaller: end of stack");
    }

    /**
     * @dev Returns the most recent caller of this contract.
     *
     * Last caller may also be the current contract.
     *
     * If the call is directly to the contract, without passing an Extendable, return `msg.sender` instead
     */
    function _lastCaller() internal view returns(address) {
        CallerState storage state = CallerContextStorage._getState();
        if (state.callerStack.length > 0)
            return state.callerStack[state.callerStack.length - 1];
        else
            return msg.sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Internal contract base inherited by InternalExtension to allow access
 *      to `_internal` modifier for functions that should only be callable by
 *      other Extensions of the current contract thus keeping the functions
 *      'internal' with respects to Extendable contract scope.
 *
 * Modify your functions with `_internal` to restrict callers to only originate
 * from the current Extendable contract.
 *
 * Note that due to the nature of cross-Extension calls, they are deemed as external
 * calls and thus your functions must counterintuitively be marked as both:
 *
 * `public _internal`
 *
 * function yourFunction() public _internal {}
*/

contract Internal {
    modifier _internal() {
        require(msg.sender == address(this), "external caller not allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IGetterLogic } from "@violetprotocol/erc721extendable/contracts/extensions/base/getter/IGetterLogic.sol";

/*
  A faucet with Sybil-resistance thanks to Humanbound Tokens.
*/
contract HumanboundTokenGatedFaucet is Ownable {
  // Emitted when someone claim funds from the faucet
  event Dripped(address recipient, uint256 amount);
  // Emitted when an owner withdraw funds
  event Withdrawn(address recipient, uint256 amount);

  // Stored address of the Humanbound Token contract
  address public hbtContract;
  // Amount to drip
  uint256 public  dripAmount;
  // Upon a successful drip, an address cannot
  // claim funds again until this time lock has elapsed
  uint256 public timeLock;
  // Recording when the last drip happened by address
  mapping (address => uint256) public lastDrip;

  constructor(address hbtContract_, uint256 dripAmount_, uint256 timeLockInSeconds) payable {
    hbtContract = hbtContract_;
    dripAmount = dripAmount_;
    timeLock = timeLockInSeconds;
  }

   modifier onlyHBTOwners {
      // Verify HBT ownership
      require(IGetterLogic(hbtContract).balanceOf(msg.sender) > 0, "Unauthorized: Ownership of a Humanbound Token is required");
      _;
    }

  receive() external payable {}

  fallback() external payable {}

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  function drip() external onlyHBTOwners {
    require(block.timestamp > lastDrip[msg.sender] +  timeLock, "You reached your quota. Come back after the cooldown period.");
    lastDrip[msg.sender] = block.timestamp;

    (bool sent,) = msg.sender.call{value:  dripAmount}("");
    require(sent, "Failed to drip ETH. Is there enough funds?");

    emit Dripped(msg.sender,  dripAmount);
  }

  function updateHBTContractAddress(address newHBTContractAddress) external onlyOwner {
     hbtContract = newHBTContractAddress;
  }

  function updateDripAmount(uint256 newAmount) external onlyOwner {
     dripAmount = newAmount;
  }

  function updateTimeLock(uint256 newTimeLock) external onlyOwner {
     timeLock = newTimeLock;
  }

  function withdraw(uint256 amount) external onlyOwner {
    _withdraw(amount);
  }

  function withdrawAll() external onlyOwner {
    uint256 thisBalance = address(this).balance;

    _withdraw(thisBalance);
  }

  function _withdraw(uint256 amount) private {
    address recipient = msg.sender;

    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed withdrawing ETH");

    emit Withdrawn(recipient, amount);
  }
}
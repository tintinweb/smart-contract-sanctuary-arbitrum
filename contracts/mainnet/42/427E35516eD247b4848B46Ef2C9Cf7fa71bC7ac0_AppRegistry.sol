// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { IAppBeaconBase } from "src/interfaces/apps/base/IAppBeaconBase.sol";
import { IAppRegistry } from "src/interfaces/apps/IAppRegistry.sol";
import { IAppAccountBase } from "src/interfaces/apps/base/IAppAccountBase.sol";
import { IAppBeaconBase } from "src/interfaces/apps/base/IAppBeaconBase.sol";

contract AppRegistry is IAppRegistry, Ownable2Step {
    mapping(address appBeacon => bool isValid) public appBeacons;
    bytes4 public appAccountInterface;
    bytes4 public appBeaconInterface;

    constructor(address _owner) Ownable(_owner) {
        appAccountInterface = type(IAppAccountBase).interfaceId;
        appBeaconInterface = type(IAppBeaconBase).interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                       			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the current status of an app beacon, if active or not.
     * @param _appBeacon the address of the app beacon set.
     * @return The status of the app beacon.
     */
    function isValidAppBeacon(address _appBeacon) external view returns (bool) {
        return appBeacons[_appBeacon] && IAppBeaconBase(_appBeacon).getLatestAppBeacon() == _appBeacon;
    }

    /*///////////////////////////////////////////////////////////////
                    		MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the status of an app beacon in the registry if it's valid or not.
     * @param _appBeacon the address of the app beacon to be set.
     * @param _isValid the validity of the app beacon to be set.
     */
    function setAppBeaconStatus(address _appBeacon, bool _isValid) public onlyOwner {
        if (_isValid) {
            if (
                !IERC165(_appBeacon).supportsInterface(appBeaconInterface)
                    || IAppBeaconBase(_appBeacon).getLatestAppBeacon() != _appBeacon
            ) {
                revert InvalidAppBeacon();
            }
            if (!IERC165(IAppBeaconBase(_appBeacon).getLatestAppImplementation()).supportsInterface(appAccountInterface)) {
                revert InvalidAppAccountImplementation();
            }
        }
        emit AppBeaconSet(_appBeacon, _isValid);
        appBeacons[_appBeacon] = _isValid;
    }

    /**
     * @notice Sets the status of an app beacon in the registry if it's valid or not, batched.
     * @param _appBeacons The addresses of the app beacons to be set.
     * @param _isValid the validity of the app beacon to be set.
     */
    function setAppBeaconStatusBatch(address[] memory _appBeacons, bool _isValid) external onlyOwner {
        if (_appBeacons.length == 0) revert InvalidLength();
        for (uint256 i; i < _appBeacons.length; i++) {
            setAppBeaconStatus(_appBeacons[i], _isValid);
        }
    }

    /**
     * @notice Sets the interface that the app account must support.
     * @param _interface the interface that the app account must support.
     */
    function setAppAccountInterface(bytes4 _interface) external onlyOwner {
        appAccountInterface = _interface;
    }

    /**
     * @notice Sets the interface that the app beacon must support.
     * @param _interface the interface that the app beacon must support.
     */
    function setAppBeaconInterface(bytes4 _interface) external onlyOwner {
        appBeaconInterface = _interface;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IAppRegistry
 * @notice Interface for the App Registry
 */
interface IAppRegistry {
    /*///////////////////////////////////////////////////////////////
    	 						EVENTS
    ///////////////////////////////////////////////////////////////*/

    event AppBeaconSet(address indexed appBeacon, bool isValid);

    /*///////////////////////////////////////////////////////////////
    	 						ERRORS
    ///////////////////////////////////////////////////////////////*/

    error InvalidAppBeacon();
    error InvalidLength();
    error InvalidAppAccountImplementation();

    /*///////////////////////////////////////////////////////////////
                    		VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the current status of an app beacon, if active or not.
     * @param _appBeacon the address of the app beacon set.
     * @return The status of the app beacon.
     */
    function isValidAppBeacon(address _appBeacon) external view returns (bool);

    /**
     * @notice Gets the interface that the app account must support.
     */
    function appAccountInterface() external view returns (bytes4);

    /**
     * @notice Gets the interface that the app beacon must support.
     */
    function appBeaconInterface() external view returns (bytes4);

    /*///////////////////////////////////////////////////////////////
                    		MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the status of an app beacon in the registry if it's valid or not.
     * @param _appBeacon the address of the app beacon to be set.
     * @param _isValid the validity of the app beacon to be set.
     */
    function setAppBeaconStatus(address _appBeacon, bool _isValid) external;

    /**
     * @notice Sets the status of an app beacon in the registry if it's valid or not, batched.
     * @param _appBeacons The addresses of the app beacons to be set.
     * @param _isValid the validity of the app beacon to be set.
     */
    function setAppBeaconStatusBatch(address[] memory _appBeacons, bool _isValid) external;

    /**
     * @notice Sets the interface that the app beacon must support.
     * @param _interface the interface that the app beacon must support.
     */
    function setAppBeaconInterface(bytes4 _interface) external;

    /**
     * @notice Sets the interface that the app account must support.
     * @param _interface the interface that the app account must support.
     */
    function setAppAccountInterface(bytes4 _interface) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IAppAccountBase
 * @notice Interface for the App Account Base
 */
interface IAppAccountBase {
    /*///////////////////////////////////////////////////////////////
    	 						EVENTS
    ///////////////////////////////////////////////////////////////*/

    event EtherTransferredToMainAccount(uint256 amount);
    event ERC20TransferredToMainAccount(address indexed token, uint256 amount);
    event ERC721TransferredToMainAccount(address indexed token, uint256 tokenId);
    event ERC1155TransferredToMainAccount(address indexed token, uint256 tokenId, uint256 amount, bytes data);
    event ERC1155BatchTransferredToMainAccount(address indexed token, uint256[] _ids, uint256[] _values, bytes _data);
    event EtherRecoveredToMainAccount(uint256 amount);
    event ERC20RecoveredToMainAccount(address indexed token, uint256 amount);
    event ERC721RecoveredToMainAccount(address indexed token, uint256 tokenId);
    event ERC1155RecoveredToMainAccount(address indexed token, uint256 tokenId, uint256 amount, bytes data);
    event ERC1155BatchRecoveredToMainAccount(address indexed token, uint256[] tokenIds, uint256[] amounts, bytes _data);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error InvalidAppBeacon();
    error ImplementationMismatch(address implementation, address latestImplementation);
    error ETHTransferFailed();

    /*///////////////////////////////////////////////////////////////
                                 		INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the app account with the main account and the app beacon.
     * @param _mainAccount the address of the main account, this is the owner of the app.
     * @param _appBeacon the beacon for the app account.
     */
    function initialize(address _mainAccount, address _appBeacon) external;

    /*///////////////////////////////////////////////////////////////
                    			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the app version number of the app account.
     * @return A uint64 representing the version of the app.
     * @dev NOTE: This number must be updated whenever a new version is deployed.
     * The number should always only be incremented by 1.
     */
    function appVersion() external pure returns (uint64);

    /**
     * @notice Get the app's main account.
     * @return The main account associated with this app.
     */
    function getMainAccount() external view returns (address);

    /**
     * @notice Get the app config beacon.
     * @return The app config beacon address.
     */
    function getAppBeacon() external view returns (address);

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer Ether to the main account from the app account.
     * @param _amount The amount of Ether to transfer.
     */
    function transferEtherToMainAccount(uint256 _amount) external;

    /**
     * @notice Transfer ERC20 tokens to the main account from the app account.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to transfer.
     */
    function transferERC20ToMainAccount(address _token, uint256 _amount) external;

    /**
     * @notice Transfer ERC721 tokens to the main account from the app account.
     * @param _token The address of the ERC721 token.
     * @param _tokenId The ID of the ERC721 token.
     */
    function transferERC721ToMainAccount(address _token, uint256 _tokenId) external;

    /**
     * @notice Transfer ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _tokenId The ID of the ERC1155 token.
     * @param _amount The amount of tokens to transfer.
     * @param _data Data to send with the transfer.
     */
    function transferERC1155ToMainAccount(address _token, uint256 _tokenId, uint256 _amount, bytes calldata _data) external;

    /**
     * @notice Transfers batch ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _ids The IDs of the ERC1155 tokens.
     * @param _amounts The amounts of the ERC1155 tokens.
     * @param _data Data to send with the transfer.
     */
    function transferERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    /**
     * @notice Recovers all ether in the app account to the main account.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverEtherToMainAccount() external;

    /**
     * @notice Recovers the full balance of an ERC20 token to the main account.
     * @param _token The address of the token to be recovered to the main account.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC20ToMainAccount(address _token) external;

    /**
     * @notice Recovers a specified ERC721 token to the main account.
     * @param _token The ERC721 token address to recover.
     * @param _tokenId The ID of the ERC721 token to recover.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC721ToMainAccount(address _token, uint256 _tokenId) external;

    /**
     * @notice Recovers all the tokens of a specified ERC1155 token to the main account.
     * @param _token The ERC1155 token address to recover.
     * @param _tokenId The id of the token to recover.
     * @param _data The data for the transaction.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC1155ToMainAccount(address _token, uint256 _tokenId, bytes calldata _data) external;

    /**
     * @notice Recovers batch ERC1155 tokens to the main account.
     * @param _token The address of the ERC1155 token.
     * @param _ids The IDs of the ERC1155 tokens.
     * @param _values The values of the ERC1155 tokens.
     * @param _data Data to send with the transfer.
     */
    function recoverERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
     * @notice Upgrade the app account to the latest implementation and beacon.
     * @param _appBeacon The address of the new app beacon.
     * @param _latestAppImplementation The address of the latest app implementation.
     * @dev Requires the sender to be the main account.
     */
    function upgradeAppVersion(address _appBeacon, address _latestAppImplementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IAppBeaconBase
 * @notice Interface for the App Beacon Base
 */
interface IAppBeaconBase {
    /*///////////////////////////////////////////////////////////////
    	 						STRUCTS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct containing the config for the app beacon.
     * @param appName The name of the app.
     * @param latestAppImplementation The address of the latest app implementation.
     * @param latestAppBeacon The address of the latest app beacon.
     */
    struct AppBeaconConfig {
        string appName;
        address latestAppImplementation;
        address latestAppBeacon;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error InvalidAppAccountImplementation();
    error InvalidAppBeacon();

    /*///////////////////////////////////////////////////////////////
    	 						EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LatestAppImplementationSet(address latestAppImplementation);
    event LatestAppBeaconSet(address latestAppBeacon);

    /*///////////////////////////////////////////////////////////////
                    			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the name of the app associated to the beacon.
     * @return The name of the app beacon.
     */
    function getAppName() external view returns (string memory);

    /**
     * @notice Gets the latest app implementation.
     * @return The address of the latest app implementation.
     */
    function getLatestAppImplementation() external view returns (address);

    /**
     * @notice Gets the latest beacon address for the app.
     * @return The address of the latest app beacon.
     */
    function getLatestAppBeacon() external view returns (address);

    /*///////////////////////////////////////////////////////////////
                    		    MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the latest app implementation address.
     * @param _latestAppImplementation The address of the latest implementation for the app.
     */
    function setLatestAppImplementation(address _latestAppImplementation) external;

    /**
     * @notice Sets the latest app beacon address.
     * @param _latestAppBeacon The address of the latest app beacon associated with the app.
     */
    function setLatestAppBeacon(address _latestAppBeacon) external;
}
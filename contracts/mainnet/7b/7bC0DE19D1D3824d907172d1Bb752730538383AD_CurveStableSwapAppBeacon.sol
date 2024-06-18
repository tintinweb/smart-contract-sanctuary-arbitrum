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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { IAppAccountBase } from "src/interfaces/apps/base/IAppAccountBase.sol";
import { IAppBeaconBase } from "src/interfaces/apps/base/IAppBeaconBase.sol";

abstract contract AppBeaconBase is IAppBeaconBase, ERC165, Ownable2Step {
    AppBeaconConfig public appBeaconConfig;

    constructor(address _owner, address _latestAppImplementation, string memory _appName) Ownable(_owner) {
        appBeaconConfig.appName = _appName;
        if (!IERC165(_latestAppImplementation).supportsInterface(type(IAppAccountBase).interfaceId)) {
            revert InvalidAppAccountImplementation();
        }
        appBeaconConfig.latestAppImplementation = _latestAppImplementation;
        appBeaconConfig.latestAppBeacon = address(this);
    }

    /*///////////////////////////////////////////////////////////////
                       			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IAppBeaconBase).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Gets the name of the app associated to the beacon.
     * @return The name of the app beacon.
     */
    function getAppName() external view returns (string memory) {
        return appBeaconConfig.appName;
    }

    /**
     * @notice Gets the latest app implementation.
     * @return The address of the latest app implementation.
     */
    function getLatestAppImplementation() external view returns (address) {
        return appBeaconConfig.latestAppImplementation;
    }

    /**
     * @notice Gets the latest beacon address for the app.
     * @return The address of the latest app beacon.
     */
    function getLatestAppBeacon() external view returns (address) {
        return appBeaconConfig.latestAppBeacon;
    }

    /*///////////////////////////////////////////////////////////////
                    		    MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the latest app implementation address.
     * @param _latestAppImplementation The address of the latest implementation for the app.
     */
    function setLatestAppImplementation(address _latestAppImplementation) external onlyOwner {
        if (_latestAppImplementation == address(0)) revert ZeroAddress();
        emit LatestAppImplementationSet(_latestAppImplementation);
        appBeaconConfig.latestAppImplementation = _latestAppImplementation;
    }

    /**
     * @notice Sets the latest app beacon address.
     * @param _latestAppBeacon The address of the latest app beacon associated with the app.
     */
    function setLatestAppBeacon(address _latestAppBeacon) external onlyOwner {
        if (_latestAppBeacon == address(0)) revert ZeroAddress();
        emit LatestAppBeaconSet(_latestAppBeacon);
        appBeaconConfig.latestAppBeacon = _latestAppBeacon;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library CurveAppError {
    /*///////////////////////////////////////////////////////////////
                                GENERIC
    ///////////////////////////////////////////////////////////////*/

    error TokenIndexMismatch();
    error InvalidPoolAddress(address poolAddress);
    error UnsupportedPool(address poolAddress);
    error InvalidToken();
    error ZeroAddress();
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

import { AppBeaconBase } from "src/apps/base/AppBeaconBase.sol";
import { ICurveStableSwapFactoryNG } from "src/interfaces/curve/ICurveStableSwapFactoryNG.sol";
import { ICurveStableSwapNG } from "src/interfaces/curve/ICurveStableSwapNG.sol";
import { ICurveStableSwapAppBeacon } from "src/interfaces/curve/ICurveStableSwapAppBeacon.sol";

import { CurveAppError } from "src/apps/curve/CurveAppError.sol";

contract CurveStableSwapAppBeacon is AppBeaconBase, ICurveStableSwapAppBeacon {
    address public immutable curveStableswapFactoryNG;
    mapping(address => bool) public isSupportedPool;
    address public immutable USDC;

    constructor(address _owner, address _latestAppImplementation, address _curveStableswapFactoryNG, address _usdc)
        AppBeaconBase(_owner, _latestAppImplementation, "CurveStableswap")
    {
        if (_curveStableswapFactoryNG == address(0)) revert CurveAppError.ZeroAddress();
        if (_usdc == address(0)) revert CurveAppError.ZeroAddress();
        curveStableswapFactoryNG = _curveStableswapFactoryNG;
        USDC = _usdc;
    }

    /**
     * @notice Get the pool data for the given tokens. Data will be empty if type is underyling
     * @param _fromToken The address of the token to swap from.
     * @param _toToken The address of the token to swap to.
     * @return poolData The pool data for the given tokens.
     */
    function getPoolDatafromTokens(address _fromToken, address _toToken, uint256 _fromAmount)
        public
        returns (PoolData memory poolData)
    {
        poolData.pool = ICurveStableSwapFactoryNG(curveStableswapFactoryNG).find_pool_for_coins(_fromToken, _toToken);
        poolData.tokens = ICurveStableSwapFactoryNG(curveStableswapFactoryNG).get_coins(poolData.pool);
        (poolData.fromTokenIndex, poolData.toTokenIndex, poolData.isUnderlying) =
            ICurveStableSwapFactoryNG(curveStableswapFactoryNG).get_coin_indices(poolData.pool, _fromToken, _toToken);
        poolData.balances = ICurveStableSwapFactoryNG(curveStableswapFactoryNG).get_balances(poolData.pool);
        poolData.decimals = ICurveStableSwapFactoryNG(curveStableswapFactoryNG).get_decimals(poolData.pool);
        poolData.amountReceived = ICurveStableSwapNG(poolData.pool).get_dy(poolData.fromTokenIndex, poolData.toTokenIndex, _fromAmount);
    }

    /**
     * @notice A safety feature to limit the pools that can be used by the app to only vetted and suppported pools
     * @dev Only the contract owner can call this function.
     * @param _pool The address of the pool.
     * @param _supported The supported status of the pool.
     */
    function setIsSupportedPool(address _pool, bool _supported) external onlyOwner {
        if (_pool == address(0)) revert CurveAppError.ZeroAddress();
        isSupportedPool[_pool] = _supported;
    }
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

/**
 * @title ICurveStableSwapAppBeacon
 * @notice Interface for the curve app beacon.
 */
interface ICurveStableSwapAppBeacon {
    /*///////////////////////////////////////////////////////////////
    	 				        STRUCTS
    ///////////////////////////////////////////////////////////////*/

    struct PoolData {
        address pool;
        int128 fromTokenIndex;
        int128 toTokenIndex;
        uint256 amountReceived;
        address[] tokens;
        uint256[] balances;
        uint256[] decimals;
        bool isUnderlying;
    }

    /*///////////////////////////////////////////////////////////////
    	 				    VIEW FUNCTIONS/VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the curve stable swap factory address.
     * @return The address of the curve stable swap factory.
     */
    function curveStableswapFactoryNG() external view returns (address);

    /**
     * @notice Gets the USDC address.
     * @return The address of the USDC token.
     */
    function USDC() external view returns (address);

    /**
     * @notice Checks if a pool has been vetted by the council and can be safely used by the app
     * @param _pool The address of the pool.
     * @return True if the pool is supported, false otherwise.
     */
    function isSupportedPool(address _pool) external view returns (bool);

    /**
     * @notice Get the pool data for the given tokens. Data will be empty if type is underyling
     * @param _fromToken The address of the token to swap from.
     * @param _toToken The address of the token to swap to.
     * @return poolData The pool data for the given tokens.
     */
    function getPoolDatafromTokens(address _fromToken, address _toToken, uint256 _fromAmount)
        external
        returns (PoolData memory poolData);

    /**
     * @notice A safety feature to limit the pools that can be used by the app to only vetted and suppported pools
     * @dev Only the contract owner can call this function.
     * @param _pool The address of the pool.
     * @param _supported The supported status of the pool.
     */
    function setIsSupportedPool(address _pool, bool _supported) external;
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

// from https://github.com/curvefi/stableswap-ng

/**
 * @title ICurveStableSwapFactoryNG
 * @notice Interface for the curve stable swap factory.
 */
interface ICurveStableSwapFactoryNG {
    /**
     * @notice Find an available pool for exchanging two coins
     * @param _from Address of coin to be sent
     * @param _to Address of coin to be received
     * @param i Index value. When multiple pools are available
     *        this value is used to return the n'th address.
     * @return Pool address
     */
    function find_pool_for_coins(address _from, address _to, uint256 i) external view returns (address);

    /**
     * @notice Find an available pool for exchanging two coins
     * @param _from Address of coin to be sent
     * @param _to Address of coin to be received
     * @return Pool address
     */
    function find_pool_for_coins(address _from, address _to) external view returns (address);

    /**
     * @notice Get the base pool for a given factory metapool
     * @param _pool Metapool address
     * @return Address of base pool
     */
    function get_base_pool(address _pool) external view returns (address);

    /**
     * @notice Get the number of coins in a pool
     * @param _pool Pool address
     * @return Number of coins
     */
    function get_n_coins(address _pool) external view returns (uint256);

    /**
     * @notice Get the coins within a pool
     * @param _pool Pool address
     * @return List of coin addresses
     */
    function get_coins(address _pool) external view returns (address[] memory);

    /**
     * @notice Get the underlying coins within a pool
     * @dev Reverts if a pool does not exist or is not a metapool
     * @param _pool Pool address
     * @return List of coin addresses
     */
    function get_underlying_coins(address _pool) external view returns (address[] memory);

    /**
     * @notice Get decimal places for each coin within a pool
     * @param _pool Pool address
     * @return uint256 list of decimals
     */
    function get_decimals(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get decimal places for each underlying coin within a pool
     * @param _pool Pool address
     * @return uint256 list of decimals
     */
    function get_underlying_decimals(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get rates for coins within a metapool
     * @param _pool Pool address
     * @return Rates for each coin, precision normalized to 10**18
     */
    function get_metapool_rates(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get balances for each coin within a pool
     * @dev For pools using lending, these are the wrapped coin balances
     * @param _pool Pool address
     * @return uint256 list of balances
     */
    function get_balances(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get balances for each underlying coin within a metapool
     * @param _pool Metapool address
     * @return uint256 list of underlying balances
     */
    function get_underlying_balances(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get the amplfication co-efficient for a pool
     * @param _pool Pool address
     * @return uint256 A
     */
    function get_A(address _pool) external view returns (uint256);

    /**
     * @notice Get the fees for a pool
     * @dev Fees are expressed as integers
     * @param _pool Pool address
     * @return Pool fee and admin fee as uint256 with 1e10 precision
     */
    function get_fees(address _pool) external view returns (uint256, uint256);

    /**
     * @notice Get the current admin balances (uncollected fees) for a pool
     * @param _pool Pool address
     * @return List of uint256 admin balances
     */
    function get_admin_balances(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Convert coin addresses to indices for use with pool methods
     * @param _pool Pool address
     * @param _from Coin address to be used as `i` within a pool
     * @param _to Coin address to be used as `j` within a pool
     * @return int128 `i`, int128 `j`, boolean indicating if `i` and `j` are underlying coins
     */
    function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);

    /**
     * @notice Get the address of the liquidity gauge contract for a factory pool
     * @dev Returns `empty(address)` if a gauge has not been deployed
     * @param _pool Pool address
     * @return Implementation contract address
     */
    function get_gauge(address _pool) external view returns (address);

    /**
     * @notice Get the address of the implementation contract used for a factory pool
     * @param _pool Pool address
     * @return Implementation contract address
     */
    function get_implementation_address(address _pool) external view returns (address);

    /**
     * @notice Verify `_pool` is a metapool
     * @param _pool Pool address
     * @return True if `_pool` is a metapool
     */
    function is_meta(address _pool) external view returns (bool);

    /**
     * @notice Query the asset type of `_pool`
     * @param _pool Pool Address
     * @return Dynarray of uint8 indicating the pool asset type
     *         Asset Types:
     *             0. Standard ERC20 token with no additional features
     *             1. Oracle - token with rate oracle (e.g. wrapped staked ETH)
     *             2. Rebasing - token with rebase (e.g. staked ETH)
     *             3. ERC4626 - e.g. sDAI
     */
    function get_pool_asset_types(address _pool) external view returns (uint8[] memory);

    /**
     * @notice Deploy a new plain pool
     * @param _name Name of the new plain pool
     * @param _symbol Symbol for the new plain pool - will be
     *                concatenated with factory symbol
     * @param _coins List of addresses of the coins being used in the pool.
     * @param _A Amplification co-efficient - a lower value here means
     *           less tolerance for imbalance within the pool's assets.
     *           Suggested values include:
     *            * Uncollateralized algorithmic stablecoins: 5-10
     *            * Non-redeemable, collateralized assets: 100
     *            * Redeemable assets: 200-400
     * @param _fee Trade fee, given as an integer with 1e10 precision. The
     *             maximum is 1% (100000000). 50% of the fee is distributed to veCRV holders.
     * @param _offpeg_fee_multiplier Off-peg fee multiplier
     * @param _ma_exp_time Averaging window of oracle. Set as time_in_seconds / ln(2)
     *                     Example: for 10 minute EMA, _ma_exp_time is 600 / ln(2) ~= 866
     * @param _implementation_idx Index of the implementation to use
     * @param _asset_types Asset types for pool, as an integer
     * @param _method_ids Array of first four bytes of the Keccak-256 hash of the function signatures
     *                    of the oracle addresses that gives rate oracles.
     *                    Calculated as: keccak(text=event_signature.replace(" ", ""))[:4]
     * @param _oracles Array of rate oracle addresses.
     * @return Address of the deployed pool
     */
    function deploy_plain_pool(
        string memory _name,
        string memory _symbol,
        address[] memory _coins,
        uint256 _A,
        uint256 _fee,
        uint256 _offpeg_fee_multiplier,
        uint256 _ma_exp_time,
        uint256 _implementation_idx,
        uint8[] memory _asset_types,
        bytes4[] memory _method_ids,
        address[] memory _oracles
    ) external returns (address);
    /**
     * @notice Deploy a new metapool
     * @param _base_pool Address of the base pool to use
     *                   within the metapool
     * @param _name Name of the new metapool
     * @param _symbol Symbol for the new metapool - will be
     *                concatenated with the base pool symbol
     * @param _coin Address of the coin being used in the metapool
     * @param _A Amplification co-efficient - a higher value here means
     *           less tolerance for imbalance within the pool's assets.
     *           Suggested values include:
     *            * Uncollateralized algorithmic stablecoins: 5-10
     *            * Non-redeemable, collateralized assets: 100
     *            * Redeemable assets: 200-400
     * @param _fee Trade fee, given as an integer with 1e10 precision. The
     *             the maximum is 1% (100000000).
     *             50% of the fee is distributed to veCRV holders.
     * @param _offpeg_fee_multiplier Off-peg fee multiplier
     * @param _ma_exp_time Averaging window of oracle. Set as time_in_seconds / ln(2)
     *                     Example: for 10 minute EMA, _ma_exp_time is 600 / ln(2) ~= 866
     * @param _implementation_idx Index of the implementation to use
     * @param _asset_type Asset type for token, as an integer
     * @param _method_id  First four bytes of the Keccak-256 hash of the function signatures
     *                    of the oracle addresses that gives rate oracles.
     *                    Calculated as: keccak(text=event_signature.replace(" ", ""))[:4]
     * @param _oracle Rate oracle address.
     * @return Address of the deployed pool
     */
    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee,
        uint256 _offpeg_fee_multiplier,
        uint256 _ma_exp_time,
        uint256 _implementation_idx,
        uint8 _asset_type,
        bytes4 _method_id,
        address _oracle
    ) external returns (address);
    /**
     * @notice Deploy a liquidity gauge for a factory pool
     * @param _pool Factory pool address to deploy a gauge for
     * @return Address of the deployed gauge
     */
    function deploy_gauge(address _pool) external returns (address);

    /**
     * @notice Add a base pool to the registry, which may be used in factory metapools
     * @dev 1. Only callable by admin
     *      2. Rebasing tokens are not allowed in the base pool.
     *      3. Do not add base pool which contains native tokens (e.g. ETH).
     *      4. As much as possible: use standard ERC20 tokens.
     *      Should you choose to deviate from these recommendations, audits are advised.
     * @param _base_pool Pool address to add
     * @param _base_lp_token LP token of the base pool
     * @param _asset_types Asset type for pool, as an integer
     * @param _n_coins Number of coins in the pool
     */
    function add_base_pool(address _base_pool, address _base_lp_token, uint8[] memory _asset_types, uint256 _n_coins) external;

    /**
     * @notice Set implementation contracts for pools
     * @dev Only callable by admin
     * @param _implementation_index Implementation index where implementation is stored
     * @param _implementation Implementation address to use when deploying plain pools
     */
    function set_pool_implementations(uint256 _implementation_index, address _implementation) external;

    /**
     * @notice Set implementation contracts for metapools
     * @dev Only callable by admin
     * @param _implementation_index Implementation index where implementation is stored
     * @param _implementation Implementation address to use when deploying meta pools
     */
    function set_metapool_implementations(uint256 _implementation_index, address _implementation) external;

    /**
     * @notice Set implementation contracts for StableSwap Math
     * @dev Only callable by admin
     * @param _math_implementation Address of the math implementation contract
     */
    function set_math_implementation(address _math_implementation) external;

    /**
     * @notice Set implementation contracts for liquidity gauge
     * @dev Only callable by admin
     * @param _gauge_implementation Address of the gauge blueprint implementation contract
     */
    function set_gauge_implementation(address _gauge_implementation) external;

    /**
     * @notice Set implementation contracts for Views methods
     * @dev Only callable by admin
     * @param _views_implementation Implementation address of views contract
     */
    function set_views_implementation(address _views_implementation) external;
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

// from https://github.com/curvefi/stableswap-ng

/**
 * @title ICurveStableSwapNG
 * @notice Interface for the curve stable swap pool.
 */
interface ICurveStableSwapNG {
    /**
     * @notice Calculate the current input dx given output dy
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index value of the coin to receive
     * @param dy Amount of `j` being received after exchange
     * @param pool Address of the pool
     * @return Amount of `i` predicted
     */
    function get_dx(int128 i, int128 j, uint256 dy, address pool) external view returns (uint256);

    /**
     * @notice Calculate the current output dy given input dx
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index value of the coin to receive
     * @param dx Amount of `i` being exchanged
     * @return Amount of `j` predicted
     */
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    /**
     * @notice Calculate the amount received when withdrawing a single coin
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @return Amount of coin received
     */
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    /**
     * @notice Returns the address of the token at the specified index.
     * @param i The index of the token.
     * @return The address of the token at the specified index.
     */
    function coins(uint256 i) external view returns (address);

    /**
     * @notice Returns the number of underlying coins in the pool.
     * @return The number of underlying coins in the pool.
     */
    function N_COINS() external view returns (uint256);

    /**
     * @notice Perform an exchange between two coins
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index value of the coin to receive
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    /**
     * @notice Deposit coins into the pool
     * @param _amounts List of amounts of coins to deposit
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
     * @return Amount of LP tokens received by depositing
     */
    function add_liquidity(uint256[] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @notice Withdraw a single coin from the pool
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @param _min_received Minimum amount of coin to receive
     * @return Amount of coin received
     */
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);

    /**
     * @notice Withdraw coins from the pool in an imbalanced amount
     * @param _amounts List of amounts of underlying coins to withdraw
     * @param _max_burn_amount Maximum amount of LP token to burn in the withdrawal
     * @return Actual amount of the LP token burned in the withdrawal
     */
    function remove_liquidity_imbalance(uint256[] memory _amounts, uint256 _max_burn_amount) external returns (uint256);

    /**
     * @notice Withdraw coins from the pool
     * @dev Withdrawal amounts are based on current deposit ratios
     * @param _burn_amount Quantity of LP tokens to burn in the withdrawal
     * @param _min_amounts Minimum amounts of underlying coins to receive
     * @param _receiver Address that receives the withdrawn coins
     * @param _claim_admin_fees Whether to claim admin fees
     * @return List of amounts of coins that were withdrawn
     */
    function remove_liquidity(uint256 _burn_amount, uint256[] memory _min_amounts, address _receiver, bool _claim_admin_fees)
        external
        returns (uint256[] memory);
}
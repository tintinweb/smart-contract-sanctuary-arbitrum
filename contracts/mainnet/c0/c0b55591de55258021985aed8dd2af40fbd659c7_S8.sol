// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Challenge} from "lib/ctf/src/protocol/Challenge.sol";

contract S8 is Challenge {
    mapping(address => string) private s_auditUri;
    mapping(address => string) private s_addressToUsername;

    constructor(address registry) Challenge(registry) {}

    /*
     * CALL THIS FUNCTION!
     * 
     * All you have to do here, is upload a URI with either:
     *   - A link to your Vault Guardians Security Review
     *   - A link to your participation in a CodeHawks competitive audit or first flight
     * 
     * Vault Guardians Example: https://github.com/Cyfrin/8-vault-guardians-audit/blob/main/audit-data/report.pdf
     * (Bonus points for IPFS or Arweave links!)
     * CodeHawks Example: https://www.codehawks.com/report/clomptuvr0001ie09bzfp4nqw
     * 
     * Careful: You can only call this function once on this address!
     * 
     * @param auditOrCodeHawksUri - The URI to your Vault Guardians security review or CodeHawks report
     * @param username - Your CodeHawks username 
     * @param twitterHandle - Your twitter handle - can be blank
     */
    function solveChallenge(string memory auditOrCodeHawksUri, string memory username, string memory twitterHandle)
        external
    {
        s_auditUri[msg.sender] = auditOrCodeHawksUri;
        s_addressToUsername[msg.sender] = username;
        _updateAndRewardSolver(twitterHandle);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function attribute() external pure override returns (string memory) {
        return "MMMEEEVVVVVVERRINNGGG";
    }

    function description() external pure override returns (string memory) {
        return "Section 8: MEV/Vault Guardians";
    }

    function extraDescription(address user) external view override returns (string memory) {
        string memory auditUri = s_auditUri[user];
        string memory username = s_addressToUsername[user];
        return string.concat("\n\nAudit URI: ", auditUri, "\nUsername: ", username);
    }

    function specialImage() external pure returns (string memory) {
        // This is b8.png
        return "ipfs://QmXt9s7EWGK3AVmLDRbw6pRJJ5JdHg4qJZzk85jqj2NmQU";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IChallenge} from "../interfaces/IChallenge.sol";
import {ICTFRegistry} from "../interfaces/ICTFRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Challenge is IChallenge, Ownable {
    error Challenge__CantBeZeroAddress();

    string private constant BLANK_TWITTER_HANLE = "";
    string private constant BLANK_SPECIAL_DESCRIPTION = "";
    ICTFRegistry internal immutable i_registry;

    constructor(address registry) Ownable(msg.sender) {
        if (registry == address(0)) {
            revert Challenge__CantBeZeroAddress();
        }
        i_registry = ICTFRegistry(registry);
    }

    /*
     * @param twitterHandleOfSolver - The twitter handle of the solver.
     * It can be left blank.
     */
    function _updateAndRewardSolver(string memory twitterHandleOfSolver) internal {
        ICTFRegistry(i_registry).mintNft(msg.sender, twitterHandleOfSolver);
    }

    function extraDescription(address /* user */ ) external view virtual returns (string memory) {
        return BLANK_SPECIAL_DESCRIPTION;
    }

    // We should have one of these too... but the signature might be different, so we don't force it.
    // function solveChallenge() external virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IChallenge {
    function description() external view returns (string memory);

    function extraDescription(address user) external view returns (string memory);

    function specialImage() external view returns (string memory);

    function attribute() external view returns (string memory);

    /* Each contract must have a "solveChallenge" function, however, the signature
     * maybe be different in all cases because of different input parameters.
     * Because of this, we are not going to define the function here.
     *
     * This function should call back to the FoundryCourseNft contract
     * to mint the NFT.
     */
    // function solveChallenge() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICTFRegistry {
    /////////////
    // Errors  //
    /////////////
    error CTFRegistry__NotChallengeContract();
    error CTFRegistry__NFTNotMinted();
    error CTFRegistry__YouAlreadySolvedThis();

    function mintNft(address receiver, string memory twitterHandle) external returns (uint256);

    function addChallenge(address challengeContract) external returns (address);
}

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}
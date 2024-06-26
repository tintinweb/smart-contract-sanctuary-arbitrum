// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Challenge} from "lib/ctf/src/protocol/Challenge.sol";

contract S4 is Challenge {
    error S4__BadReturn();
    error S4__BadOwner();
    error S4__BadGuess();

    uint256 myVal = 0;

    constructor(address registry) Challenge(registry) {}

    /*
     * CALL THIS FUNCTION!
     * 
     * @param guess - your guess to solve the challenge. 
     * @param yourTwitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(uint256 guess, string memory yourTwitterHandle) external {
        (bool success, bytes memory returnData) = msg.sender.staticcall(abi.encodeWithSignature("owner()"));
        address ownerAddress;
        assembly {
            ownerAddress := mload(add(returnData, 32))
        }
        if (!success || ownerAddress != msg.sender) {
            revert S4__BadOwner();
        }
        if (myVal == 1) {
            // slither-disable-next-line weak-prng
            uint256 rng =
                uint256(keccak256(abi.encodePacked(msg.sender, block.prevrandao, block.timestamp))) % 1_000_000;
            if (rng != guess) {
                revert S4__BadGuess();
            }
            _updateAndRewardSolver(yourTwitterHandle);
        } else {
            myVal = 1;
            (bool succ,) = msg.sender.call(abi.encodeWithSignature("go()"));
            if (!succ) {
                revert S4__BadReturn();
            }
        }
        myVal = 0;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function attribute() external pure override returns (string memory) {
        return "Puppy Master";
    }

    function description() external pure override returns (string memory) {
        return "Section 4: Puppy Raffle Audit";
    }

    function specialImage() external pure returns (string memory) {
        // This is b4.png
        return "ipfs://QmaidDd7rwStAvjouzzcu7quzvkXaV83ZE4R5r6E88zRi2";
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
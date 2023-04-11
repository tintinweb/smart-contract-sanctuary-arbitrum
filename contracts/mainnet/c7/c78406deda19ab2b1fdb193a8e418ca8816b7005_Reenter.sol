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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ICyfrinSecurityChallengeContract} from "../interfaces/ICyfrinSecurityChallengeContract.sol";
import {ICyfrinSecurityChallenges} from "../interfaces/ICyfrinSecurityChallenges.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error ACyfrinSecurityChallengeContract__AlreadySolved();
error ACyfrinSecurityChallengeContract__TransferFailed();
error ACyfrinSecurityChallengeContract__SweepFailed();

abstract contract ACyfrinSecurityChallengeContract is
    ICyfrinSecurityChallengeContract,
    Ownable
{
    string private constant BLANK_TWITTER_HANLE = "";
    string private constant BLANK_SPECIAL_DESCRIPTION = "";
    ICyfrinSecurityChallenges internal immutable i_cyfrinSecurityChallenges;
    bool internal s_solved;
    string private s_twitterHandleOfSolver;

    modifier requireIsNotSolved() {
        if (s_solved) {
            revert ACyfrinSecurityChallengeContract__AlreadySolved();
        }
        _;
    }

    constructor(address cyfrinSecurityChallengesNft) {
        i_cyfrinSecurityChallenges = ICyfrinSecurityChallenges(
            cyfrinSecurityChallengesNft
        );
        s_solved = false;
    }

    /*
     * @param twitterHandleOfSolver - The twitter handle of the solver.
     * It can be left blank.
     */
    function _updateAndRewardSolver(
        string memory twitterHandleOfSolver
    ) internal requireIsNotSolved {
        s_solved = true;
        s_twitterHandleOfSolver = twitterHandleOfSolver;
        ICyfrinSecurityChallenges(i_cyfrinSecurityChallenges).mintNft(
            msg.sender
        );
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert ACyfrinSecurityChallengeContract__TransferFailed();
        }
    }

    function _updateAndRewardSolver() internal {
        _updateAndRewardSolver(BLANK_TWITTER_HANLE);
    }

    /*
     * Just in case someone sends ETH to this contract, we can sweep it out.
     *
     * Don't send ETH to this contract.
     */
    function sweepEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert ACyfrinSecurityChallengeContract__SweepFailed();
        }
    }

    function description() external view virtual returns (string memory);

    function specialImage() external view virtual returns (string memory) {
        return BLANK_SPECIAL_DESCRIPTION;
    }

    function isSolved() external view returns (bool) {
        return s_solved;
    }

    function getTwitterHandleOfSolver() external view returns (string memory) {
        return s_twitterHandleOfSolver;
    }

    // Gonna see if people MEV this shit...
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../../abstractContracts/ACyfrinSecurityChallengeContract.sol";
import "./ReenterHelper.sol";

interface IOtherContract {
    function getOwner() external returns (address);
}

contract Reenter is ACyfrinSecurityChallengeContract {
    ReenterHelper private s_helper;

    constructor(
        address helper,
        address cscNft
    ) ACyfrinSecurityChallengeContract(cscNft) {
        s_helper = ReenterHelper(helper);
    }

    /*
     * @param yourAddress - Hehe.
     * @param selector - Hehehe.
     * @param twitterHandle - Your twitter handle. Can be a blank string.
     */
    function solveChallenge(
        address yourAddress,
        bytes4 selector,
        string memory youTwitterHandle
    ) public requireIsNotSolved {
        require(
            IOtherContract(yourAddress).getOwner() == msg.sender,
            "This isn't yours!"
        );
        bool returnedOne = s_helper.callContract(yourAddress);
        bool returnedTwo = s_helper.callContractAgain(yourAddress, selector);
        require(returnedOne && returnedTwo, "One of them failed!");
        _updateAndRewardSolver(youTwitterHandle);
    }

    function description() external pure override returns (string memory) {
        return
            "Nice work getting in-Nice work getting into the contract!to the contract!";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error ReenterHelper__Nope();
error ReenterHelper__NopeCall();

contract ReenterHelper {
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;

    function callContractAgain(
        address yourAddress,
        bytes4 selector
    ) public returns (bool) {
        s_otherVar = s_otherVar + 1;
        (bool success, ) = yourAddress.call(abi.encodeWithSelector(selector));
        require(success);
        if (s_otherVar == 2) {
            return true;
        }
        s_otherVar = 0;
        return false;
    }

    /*
     * Will you call the right contract?
     */
    function callContract(address yourAddress) public returns (bool) {
        (bool success, ) = yourAddress.delegatecall(
            abi.encodeWithSignature("doSomething()")
        );
        require(success);
        if (s_variable != 123) {
            revert ReenterHelper__NopeCall();
        }
        s_variable = 0;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ICyfrinSecurityChallengeContract {
    function description() external view returns (string memory);

    function specialImage() external view returns (string memory);

    /* Each contract must have a "solveChallenge" function, however, the signature
     * maybe be different in all cases because of different input parameters.
     * Because of this, we are not going to define the function here.
     *
     * This function should call back to the CyfrinSecurityChallenges contract
     * to mint the NFT.
     */
    // function solveChallenge() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ICyfrinSecurityChallenges {
    function mintNft(address receiver) external returns (uint256);

    function addChallenge(address challengeContract) external returns (uint256);
}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseAccess is Ownable {
    mapping(address => bool) public hasAccess;

    event GrantAccess(address indexed account, bool hasAccess);

    modifier limitAccess {
        require(hasAccess[msg.sender], "A:FBD");
        _;
    }

    function grantAccess(address _account, bool _hasAccess) onlyOwner external {
        hasAccess[_account] = _hasAccess;
        emit GrantAccess(_account, _hasAccess);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interfaces/IFastPriceFeed.sol";
import "../access/BaseAccess.sol";

contract FastPriceFeed is IFastPriceFeed, BaseAccess {
    string public constant defaultDescription = "FastPriceFeed";
    string public description;

    uint256 public answer;
    uint256 public decimals;
    uint80 public roundId;

    mapping(uint80 => uint256) public answers;
    mapping(uint80 => uint256) public latestAts;

    event SetDecription(string description);
    event SetLatestAnswer(uint256 roundId, uint256 answer, uint256 currentTimestamp);

    constructor(string memory _description) {
        if (bytes(_description).length > 0) {
            _setDescription(_description);
        }
    }

    function setDescription(string memory _description) onlyOwner external {
        _setDescription(_description);
    }

    function _setDescription(string memory _description) internal {
        description = _description;
        emit SetDecription(_description);
    }

    function getDescription() external view returns (string memory) {
        return bytes(description).length == 0 ? defaultDescription : string.concat(description, ": ", defaultDescription);
    }

    function setLatestAnswer(uint256 _answer) limitAccess external {
        roundId += 1;
        answer = _answer;
        answers[roundId] = _answer;
        uint256 currentTimestamp = block.timestamp;
        latestAts[roundId] = currentTimestamp;
        emit SetLatestAnswer(roundId, _answer, currentTimestamp);
    }

    function latestAnswer() external view override returns (uint256) {
        return answer;
    }

    function latestRound() external view override returns (uint80) {
        return roundId;
    }

    function getRoundData(uint80 _roundId) external view override returns (uint80, uint256, uint256, uint256, uint80) {
        return (_roundId, answers[_roundId], latestAts[_roundId], 0, 0);
    }

    function latestSynchronizedPrice() external view override returns (uint256, uint256) {
        return (answers[roundId], latestAts[roundId]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IFastPriceFeed {
    function description() external view returns (string memory);

    function getRoundData(uint80 roundId) external view returns (uint80, uint256, uint256, uint256, uint80);

    function latestAnswer() external view returns (uint256);

    function latestRound() external view returns (uint80);

    function setLatestAnswer(uint256 _answer) external;

    function latestSynchronizedPrice() external view returns (
      uint256 answer,
      uint256 updatedAt
    );
}
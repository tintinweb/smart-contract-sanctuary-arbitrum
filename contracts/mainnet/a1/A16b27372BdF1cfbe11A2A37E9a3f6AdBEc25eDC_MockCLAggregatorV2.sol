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
pragma solidity 0.8.12;

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);

	function latestTimestamp() external view returns (uint256);

	function latestRound() external view returns (uint256);

	function getAnswer(uint256 roundId) external view returns (int256);

	function getTimestamp(uint256 roundId) external view returns (uint256);

	event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

	event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.12;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface IChainlinkAggregator is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockCLAggregatorV2 is Ownable {
	event SetReferenceAggregator(address newRefAggregator);
	event SetAuthorizedCaller(address caller, bool isAuthorized);
	event PriceOverriden(int256 price);
	event UpdatedAtOverriden(uint256 updatedAt);

	IChainlinkAggregator public referenceAggregator;
	int256 public overridenPrice;
	uint256 public overridenUpdatedAt;
	mapping(address=>bool) public authorizedCallers;

	modifier isAuthorized() {
		require(authorizedCallers[msg.sender], "Unauthorized caller");
		_;
	}

	constructor(address refAggregator) {
		referenceAggregator = IChainlinkAggregator(refAggregator);
		authorizedCallers[msg.sender] = true;
		emit SetReferenceAggregator(refAggregator);
		emit SetAuthorizedCaller(msg.sender, true);
	}

	function setReferenceAggregator(address refAggregator) external isAuthorized {
		referenceAggregator = IChainlinkAggregator(refAggregator);
		emit SetReferenceAggregator(refAggregator);
	}

	function setAuthorizedCaller(address caller, bool setAuthorized) external onlyOwner {
		authorizedCallers[caller] = setAuthorized;
		emit SetAuthorizedCaller(caller, setAuthorized);
	}

	function setPrice(int256 _price) external isAuthorized{
		overridenPrice = _price;
		emit PriceOverriden(_price);
	}

	function setUpdatedAt(uint256 _updatedAt) external isAuthorized{
		overridenUpdatedAt = _updatedAt;
		emit UpdatedAtOverriden(_updatedAt);
	}

	function latestAnswer() external view returns (int256) {
		if (overridenPrice != 0) {
			return overridenPrice;
		}
		return referenceAggregator.latestAnswer();
	}

	function decimals() external view returns (uint256) {
		return referenceAggregator.decimals();
	}

	function description() external view returns (string memory) {
		return referenceAggregator.description();
	}

	function latestRoundData()
		public
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		(roundId, answer, startedAt, updatedAt, answeredInRound) = referenceAggregator.latestRoundData();
		roundId = uint80(referenceAggregator.latestRound());
		if (overridenPrice != 0) {
			answer = overridenPrice;
		}
		if (overridenUpdatedAt != 0) {
			updatedAt = overridenUpdatedAt;
		}
	}
}
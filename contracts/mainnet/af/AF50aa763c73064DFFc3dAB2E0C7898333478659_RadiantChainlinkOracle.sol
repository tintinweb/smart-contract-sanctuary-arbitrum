// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";

contract ContextUpgradeable is Initializable {
	function __Context_init() internal onlyInitializing {}

	function __Context_init_unchained() internal onlyInitializing {}

	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

		bool isTopLevelCall = !initializing;
		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/// @dev Returns true if and only if the function is running in the constructor
	function isConstructor() private view returns (bool) {
		// extcodesize checks the size of the code stored in an address, and
		// address returns the current address. Since the code is still not
		// deployed when running a constructor, any checks on its code size will
		// yield zero, making it an effective way to detect if a contract is
		// under construction or not.
		uint256 cs;
		//solium-disable-next-line
		assembly {
			cs := extcodesize(address())
		}
		return cs == 0;
	}

	modifier onlyInitializing() {
		require(initializing, "Initializable: contract is not initializing");
		_;
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";

contract OwnableUpgradeable is Initializable, ContextUpgradeable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function __Ownable_init() internal onlyInitializing {
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal onlyInitializing {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBaseOracle {
	function latestAnswer() external view returns (uint256 price);

	function latestAnswerInEth() external view returns (uint256 price);

	function update() external;

	function canUpdate() external view returns (bool);

	function consult() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IChainlinkAdapter {
	function latestAnswer() external view returns (uint256 price);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {OwnableUpgradeable} from "../../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {IChainlinkAdapter} from "../../interfaces/IChainlinkAdapter.sol";
import {IBaseOracle} from "../../interfaces/IBaseOracle.sol";

/// @title RadiantChainlinkOracle Contract
/// @author Radiant
contract RadiantChainlinkOracle is IBaseOracle, OwnableUpgradeable {
	/// @notice Eth price feed
	IChainlinkAdapter public ethChainlinkAdapter;
	/// @notice Token price feed
	IChainlinkAdapter public rdntChainlinkAdapter;

	error AddressZero();

	/**
	 * @notice Initializer
	 * @param _ethChainlinkAdapter Chainlink adapter for ETH.
	 * @param _rdntChainlinkAdapter Chainlink price feed for RDNT.
	 */
	function initialize(address _ethChainlinkAdapter, address _rdntChainlinkAdapter) external initializer {
		if (_ethChainlinkAdapter == address(0)) revert AddressZero();
		if (_rdntChainlinkAdapter == address(0)) revert AddressZero();
		ethChainlinkAdapter = IChainlinkAdapter(_ethChainlinkAdapter);
		rdntChainlinkAdapter = IChainlinkAdapter(_rdntChainlinkAdapter);
		__Ownable_init();
	}

	/**
	 * @notice Returns USD price in quote token.
	 * @dev supports 18 decimal token
	 * @return price of token in decimal 8
	 */
	function latestAnswer() public view returns (uint256 price) {
		// Chainlink param validations happens inside here
		price = rdntChainlinkAdapter.latestAnswer();
	}

	/**
	 * @notice Returns price in ETH
	 * @dev supports 18 decimal token
	 * @return price of token in decimal 8.
	 */
	function latestAnswerInEth() public view returns (uint256 price) {
		uint256 rdntPrice = rdntChainlinkAdapter.latestAnswer();
		uint256 ethPrice = ethChainlinkAdapter.latestAnswer();
		price = (rdntPrice * (10 ** 8)) / ethPrice;
	}

	/**
	 * @dev Check if update() can be called instead of wasting gas calling it.
	 */
	function canUpdate() public pure returns (bool) {
		return false;
	}

	/**
	 * @dev this function only exists so that the contract is compatible with the IBaseOracle Interface
	 */
	function update() public {}

	/**
	 * @notice Returns current price.
	 */
	function consult() public view returns (uint256 price) {
		price = latestAnswer();
	}
}
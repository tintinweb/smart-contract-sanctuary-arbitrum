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
pragma solidity 0.8.12;

interface IChainlinkAdapter {
	function latestAnswer() external view returns (uint256 price);

	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {OwnableUpgradeable} from "../../../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {IChainlinkAdapter} from "../../../interfaces/IChainlinkAdapter.sol";
import {AggregatorV3Interface} from "../../../interfaces/AggregatorV3Interface.sol";

/// @title WSTETHOracle Contract
/// @notice Provides wstETH/USD price using stETH/USD Chainlink oracle and wstETH/stETH exchange rate provided by stETH smart contract
/// @author Radiant
contract ChainlinkAdapterWSTETH is OwnableUpgradeable, IChainlinkAdapter {
	/// @notice stETH/USD price feed
	IChainlinkAdapter public stETHUSDOracle;
	/// @notice wstETHRatio feed
	IChainlinkAdapter public stEthPerWstETHOracle;

	error AddressZero();

	/**
	 * @notice Initializer
	 * @param _stETHUSDOracle stETH/USD price feed
	 * @param _stEthPerWstETHOracle wstETHRatio feed
	 */
	function initialize(address _stETHUSDOracle, address _stEthPerWstETHOracle) public initializer {
		if (_stETHUSDOracle == address(0)) revert AddressZero();
		if (_stEthPerWstETHOracle == address(0)) revert AddressZero();

		stETHUSDOracle = IChainlinkAdapter(_stETHUSDOracle); // 8 decimals
		stEthPerWstETHOracle = IChainlinkAdapter(_stEthPerWstETHOracle); // 18 decimals
		__Ownable_init();
	}

	/**
	 * @notice Returns wstETH/USD price. Checks for Chainlink oracle staleness with validate() in BaseChainlinkAdapter
	 * @return answer wstETH/USD price with 8 decimals
	 */
	function latestAnswer() external view returns (uint256 answer) {
		// decimals 8
		uint256 stETHPrice = stETHUSDOracle.latestAnswer();
		// decimals 18
		uint256 wstETHRatio = stEthPerWstETHOracle.latestAnswer();
		answer = (stETHPrice * wstETHRatio) / 1 ether;
	}

	function decimals() external view returns (uint8) {
		return 8;
	}
}
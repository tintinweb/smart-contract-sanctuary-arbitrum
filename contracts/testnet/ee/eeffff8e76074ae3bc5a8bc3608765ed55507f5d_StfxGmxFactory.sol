//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStfxGmx } from "./interfaces/IStfxGmx.sol";
import { IStfxGmxFactory } from "./interfaces/IStfxGmxFactory.sol";
import { Clones } from "@openzeppelin/proxy/Clones.sol";

/// @title StfxFactory
/// @author 7811
/// @notice Factory contract to create Single Trade Funds (STFs)
contract StfxGmxFactory is IStfxGmxFactory {
	/*//////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

	// Stores all the contract addresses of perpetual protocol
	// see `IStfxStorage` for details
	GmxAddress public gmx;

	// usdc address
	address public usdc;
	// stfx implementation contract address
	address private immutable stfxImplementation;
	// owner of this factory contract
	address public override owner;
	// max capacity of a Fund (can be changed by the DAO)
	uint256 public override capacityPerFund;
	// min investment amount per investor (can be changed by the DAO)
	// starts with a default of $20 as the min amount
	uint256 public override minInvestmentAmount;
	// mapping to check if an account is already managing a fund
	// max funds a manager can manage at a time is 1
	mapping(address => bool) public isManagingFund;
	// mapping to check if the address is an stfxAddress
	mapping(address => bool) public isStfxAddress;

	/*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

	/// @notice modifier for changing constants only by the owner
	modifier onlyOwner() {
		require(msg.sender == owner, "only owner");
		_;
	}

	modifier onlyStfxAddress() {
		require(isStfxAddress[msg.sender], "not a contract");
		_;
	}

	/*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	/// @notice Factory contract to create a new STF by anyone and fundraise from investors
	/// @param _stfxImplementation the main implemetation contract Address of Stfx.sol
	/// @param _gmx the addresses of the gmx contracts
	/// @param _capacityPerFund the max capacity per fund which can be changed later
	constructor(
		address _stfxImplementation,
		GmxAddress memory _gmx,
		uint256 _capacityPerFund,
		address _usdc
	) {
		stfxImplementation = _stfxImplementation;
		gmx = _gmx;
		owner = msg.sender;
		capacityPerFund = _capacityPerFund;
		minInvestmentAmount = 20 * 1e6;
		usdc = _usdc;
	}

	/*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

	/// @notice Create a new Single Trade Fund (STF)
	/// @dev returns the address of the proxy contract with Stfx.sol implementation
	/// @dev the fundraisingPeriod and the leverage go through temporary check for now
	///		  decimals need to be added later
	/// @param _fund the fund details, check `IStfxStorage`
	/// @return stfxAddress address of the proxy contract which is deployed
	function createNewStf(Fund calldata _fund) external override returns (address stfxAddress) {
		// temporary check for now, have to add decimals later
		require(_fund.fundraisingPeriod >= 15 minutes, "Fundraising should be >= 15 mins");
		require(_fund.fundraisingPeriod <= 1 weeks, "Fundraising should be <= a week");
		require(_fund.leverage <= 10, "leverage should be <= 10");
		require(!isManagingFund[msg.sender], "already managing a fund");

		stfxAddress = Clones.clone(stfxImplementation);
		IStfxGmx(stfxAddress).initialize(_fund, gmx, msg.sender);

		isManagingFund[msg.sender] = true;
		isStfxAddress[stfxAddress] = true;

		emit NewFundCreated(
			_fund.baseToken,
			_fund.fundraisingPeriod,
			_fund.entryPrice,
			_fund.targetPrice,
			_fund.liquidationPrice,
			_fund.leverage,
			_fund.tradeDirection,
			stfxAddress,
			msg.sender,
			capacityPerFund,
			block.timestamp
		);
	}

	/// @notice Method to update the exisiting gmx contract addresses
	/// @dev only owner can call this method
	/// @param _gmx gmx contract addresses
	function updateGmxAddresses(GmxAddress calldata _gmx) external override onlyOwner {
		gmx = _gmx;
		emit GmxAddressUpdated(_gmx.vault, _gmx.router, _gmx.positionRouter, block.timestamp);
	}

	/// @notice Method to change the max capacity per fund
	/// @dev only owner can call this method
	/// @param _capacityPerFund the max capacity of a fund
	function setCapacityPerFund(uint256 _capacityPerFund) external override onlyOwner {
		capacityPerFund = _capacityPerFund;
		emit CapacityPerFundChanged(_capacityPerFund, block.timestamp);
	}

	/// @notice Method to change the min amount of investment an investor can make
	/// @dev only owner can call this method
	/// @param _amount the min amount the investor has to invest
	function setMinInvestmentAmount(uint256 _amount) external override onlyOwner {
		require(_amount > 0, "amount should be > 0");
		minInvestmentAmount = _amount;
		emit MinInvestmentAmountChanged(_amount, block.timestamp);
	}

	/// @notice Method to change the `isManagingFund` status of a trader
	/// @dev can only be called from the STFX contract
	/// @param _trader the manager's address
	function setIsManagingFund(address _trader) external override onlyStfxAddress {
		isManagingFund[_trader] = false;
		emit TraderStatusChanged(_trader, block.timestamp);
	}

	/// @notice Method to update the USDC address
	/// @dev only owner can call this method
	/// @param _usdc the new usdc address
	function setUsdc(address _usdc) external override onlyOwner {
		require(_usdc != address(0), "zero address");
		usdc = _usdc;
		emit UsdcAddressUpdated(_usdc, block.timestamp);
	}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStfxGmxStorage } from "./IStfxGmxStorage.sol";

interface IStfxGmx is IStfxGmxStorage {
	event DepositIntoFund(address indexed investor, address indexed stfxAddress, uint256 amount, uint256 timeOfDeposit);
	event Refund(address indexed investor, address indexed stfxAddress, uint256 amount, uint256 timeOfRefund);
	event FundDeadlineChanged(uint256 newDeadline, address indexed stfxAddress, uint256 timeOfChange);
	event ManagerAddressChanged(address indexed newManager, address indexed stfxAddress, uint256 timeOfChange);
	event ReferralCodeChanged(bytes32 newReferralCode, address indexed stfxAddress, uint256 timeOfChange);
	event FeesTransferred(
		uint256 managerFee,
		uint256 protocolFee,
		uint256 timeOfWithdrawal,
		address indexed stfxAddress
	);
	event ClaimedUSDC(address indexed investor, uint256 claimAmount, uint256 timeOfClaim, address indexed stfxAddress);
	event VaultLiquidated(uint256 timeOfLiquidation, address indexed stfxAddress);
	event NoFillVaultClosed(uint256 timeOfClose, address indexed stfxAddress);
	event TradeDeadlineChanged(uint256 newTradeDeadline, address indexed stfxAddress, uint256 timeOfChange);
	event VaultOpened(uint256 timeOfOpen, address indexed stfxAddress);
	event VaultClosed(uint256 timeOfClose, address indexed stfxAddress, uint256 usdcBalanceAfterClose);

	function initialize(
		Fund calldata,
		GmxAddress calldata,
		address _manager
	) external;

	function depositIntoFund(uint256 amount) external;

	function openPosition() external payable;

	function closePosition() external payable;

	function distributeProfits() external;

	function claimableAmount(address investor) external view returns (uint256);

	function claim() external;

	function closeLiquidatedVault() external;

	function cancelVault() external;

	function setFundDeadline(uint256 _deadline) external;

	function setManagerAddress(address _manager) external;

	function setReferralCode(bytes32 _referralCode) external;

	function setTradeDeadline(uint256 _tradeDeadline) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStfxGmxStorage } from "./IStfxGmxStorage.sol";

interface IStfxGmxFactory is IStfxGmxStorage {
	event NewFundCreated(
		address indexed baseToken,
		uint256 fundraisingPeriod,
		uint256 entryPrice,
		uint256 targetPrice,
		uint256 liquidationPrice,
		uint256 leverage,
		bool tradeDirection,
		address indexed stfxAddress,
		address indexed manager,
		uint256 capacityPerFund,
		uint256 timeOfFundCreation
	);
	event GmxAddressUpdated(
		address indexed gmxVault,
		address indexed gmxRouter,
		address indexed gmxPositionRouter,
		uint256 timeOfChange
	);
	event CapacityPerFundChanged(uint256 capacityPerFund, uint256 timeOfChange);
	event MinInvestmentAmountChanged(uint256 minAmount, uint256 timeOfChange);
	event TraderStatusChanged(address indexed _trader, uint256 timeOfChange);
	event UsdcAddressUpdated(address indexed _usdc, uint256 timeOfChange);

	function owner() external view returns (address);

	function usdc() external view returns (address);

	function capacityPerFund() external view returns (uint256);

	function minInvestmentAmount() external view returns (uint256);

	function createNewStf(Fund calldata fund) external returns (address);

	function updateGmxAddresses(GmxAddress calldata gmx) external;

	function setCapacityPerFund(uint256 _capacityPerFund) external;

	function setMinInvestmentAmount(uint256 _amount) external;

	function setIsManagingFund(address _trader) external;

	function setUsdc(address _usdc) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStfxGmxStorage {
	/// @notice Enum to describe the trading status of the vault
	/// @dev NOT_OPENED - Not open
	/// @dev OPENED - opened position
	/// @dev CLOSED - closed position
	/// @dev LIQUIDATED - liquidated position
	/// @dev CANCELLED - did not start due to deadline reached
	enum VaultStatus {
		NOT_OPENED,
		OPENED,
		CLOSED,
		LIQUIDATED,
		CANCELLED
	}

	struct GmxAddress {
		address vault;
		address router;
		address positionRouter;
	}

	struct Fund {
		address baseToken;
		uint256 fundraisingPeriod;
		uint256 entryPrice;
		uint256 targetPrice;
		uint256 liquidationPrice;
		uint256 leverage;
		bool tradeDirection;
	}
}
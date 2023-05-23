// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface AddressBookInterface {
	/* Getters */

	function getOtokenImpl() external view returns (address);

	function getOtokenFactory() external view returns (address);

	function getWhitelist() external view returns (address);

	function getController() external view returns (address);

	function getOracle() external view returns (address);

	function getMarginPool() external view returns (address);

	function getMarginCalculator() external view returns (address);

	function getLiquidationManager() external view returns (address);

	function getAddress(bytes32 _id) external view returns (address);

	/* Setters */

	function setOtokenImpl(address _otokenImpl) external;

	function setOtokenFactory(address _factory) external;

	function setOracleImpl(address _otokenImpl) external;

	function setWhitelist(address _whitelist) external;

	function setController(address _controller) external;

	function setMarginPool(address _marginPool) external;

	function setMarginCalculator(address _calculator) external;

	function setLiquidationManager(address _liquidationManager) external;

	function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library GammaTypes {
	// vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
	struct Vault {
		// addresses of oTokens a user has shorted (i.e. written) against this vault
		address[] shortOtokens;
		// addresses of oTokens a user has bought and deposited in this vault
		// user can be long oTokens without opening a vault (e.g. by buying on a DEX)
		// generally, long oTokens will be 'deposited' in vaults to act as collateral
		// in order to write oTokens against (i.e. in spreads)
		address[] longOtokens;
		// addresses of other ERC-20s a user has deposited as collateral in this vault
		address[] collateralAssets;
		// quantity of oTokens minted/written for each oToken address in shortOtokens
		uint256[] shortAmounts;
		// quantity of oTokens owned and held in the vault for each oToken address in longOtokens
		uint256[] longAmounts;
		// quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
		uint256[] collateralAmounts;
	}

	// vaultLiquidationDetails is a struct of 3 variables that store the series address, short amount liquidated and collateral transferred for
	// a given liquidation
	struct VaultLiquidationDetails {
		address series;
		uint128 shortAmount;
		uint128 collateralAmount;
	}
}

interface IOtoken {
	function underlyingAsset() external view returns (address);

	function strikeAsset() external view returns (address);

	function collateralAsset() external view returns (address);

	function strikePrice() external view returns (uint256);

	function expiryTimestamp() external view returns (uint256);

	function isPut() external view returns (bool);
}

interface IOtokenFactory {
	function getOtoken(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external view returns (address);

	function createOtoken(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external returns (address);

	function getTargetOtokenAddress(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external view returns (address);

	event OtokenCreated(
		address tokenAddress,
		address creator,
		address indexed underlying,
		address indexed strike,
		address indexed collateral,
		uint256 strikePrice,
		uint256 expiry,
		bool isPut
	);
}

interface IController {
	// possible actions that can be performed
	enum ActionType {
		OpenVault,
		MintShortOption,
		BurnShortOption,
		DepositLongOption,
		WithdrawLongOption,
		DepositCollateral,
		WithdrawCollateral,
		SettleVault,
		Redeem,
		Call,
		Liquidate
	}

	struct ActionArgs {
		// type of action that is being performed on the system
		ActionType actionType;
		// address of the account owner
		address owner;
		// address which we move assets from or to (depending on the action type)
		address secondAddress;
		// asset that is to be transfered
		address asset;
		// index of the vault that is to be modified (if any)
		uint256 vaultId;
		// amount of asset that is to be transfered
		uint256 amount;
		// each vault can hold multiple short / long / collateral assets
		// but we are restricting the scope to only 1 of each in this version
		// in future versions this would be the index of the short / long / collateral asset that needs to be modified
		uint256 index;
		// any other data that needs to be passed in for arbitrary function calls
		bytes data;
	}

	struct RedeemArgs {
		// address to which we pay out the oToken proceeds
		address receiver;
		// oToken that is to be redeemed
		address otoken;
		// amount of oTokens that is to be redeemed
		uint256 amount;
	}
	function setOperator(address _operator, bool _isOperator) external;
	
	function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

	function operate(ActionArgs[] calldata _actions) external;

	function getAccountVaultCounter(address owner) external view returns (uint256);

	function oracle() external view returns (address);

	function getVault(address _owner, uint256 _vaultId)
		external
		view
		returns (GammaTypes.Vault memory);

	function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

	function isOperator(address _owner, address _operator) external view returns (bool);
	
	function isSettlementAllowed(
		address _underlying,
		address _strike,
		address _collateral,
		uint256 _expiry
	) external view returns (bool);

	function clearVaultLiquidationDetails(uint256 _vaultId) external;

	function getVaultLiquidationDetails(address _owner, uint256 _vaultId)
		external
		view
		returns (
			address,
			uint256,
			uint256
		);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/GammaInterface.sol";
import "../interfaces/AddressBookInterface.sol";



/**
 *  @title Lens contract to get user vault positions
 */
contract UserPositionLensMK1 {
	// opyn address book
	AddressBookInterface public addressbook;

	///////////////
	/// structs ///
	///////////////

	struct VaultDrill {
		uint256 vaultId;
		address otoken;
	}

	constructor(
		address _addressbook
	) {
		addressbook = AddressBookInterface(_addressbook);
	}

	function getVaultsForUser(address user) external view returns (VaultDrill[] memory) {
		return _loopVaults(user);
	}

	function getVaultsForUserAndOtoken(address user, address otoken) external view returns (uint256) {
		return _searchVaults(user, otoken);
	}

	function _loopVaults(address user) internal view returns (VaultDrill[] memory) {
		IController controller = IController(addressbook.getController());
		uint256 vaultCount = controller.getAccountVaultCounter(user);
		VaultDrill[] memory vaultDrill = new VaultDrill[](vaultCount);
		for (uint i; i < vaultCount; i++) {
			VaultDrill memory vault = VaultDrill(i, controller.getVault(user, i).shortOtokens[0]);
			vaultDrill[i] = vault;
		}
		return vaultDrill;
	}

	function _searchVaults(address user, address otoken) internal view returns (uint256) {
		IController controller = IController(addressbook.getController());
		uint256 vaultCount = controller.getAccountVaultCounter(user);
		VaultDrill[] memory vaultDrill = new VaultDrill[](vaultCount);
		for (uint i; i < vaultCount; i++) {
			VaultDrill memory vault = VaultDrill(i, controller.getVault(user, i).shortOtokens[0]);
			if (vault.otoken == otoken) {
				return i;
			}
		}
		return vaultCount++;
	}
}
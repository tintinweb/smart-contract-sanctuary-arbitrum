// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./SafeTransferLib.sol";

import { Types } from "./Types.sol";
import { IOtokenFactory, IOtoken, IController, GammaTypes } from "../interfaces/GammaInterface.sol";

/**
 *  @title Library used for standard interactions with the opyn-rysk gamma protocol
 *   @dev inherited by the options registry to complete base opyn-rysk gamma protocol interactions
 *        Interacts with the opyn-rysk gamma protocol in all functions
 */
library OpynInteractions {
	uint256 private constant SCALE_FROM = 10**10;
	error NoShort();

	/**
	 * @notice Either retrieves the option token if it already exists, or deploy it
	 * @param oTokenFactory is the address of the opyn oTokenFactory
	 * @param collateral asset that is held as collateral against short/written options
	 * @param underlying is the address of the underlying asset of the option
	 * @param strikeAsset is the address of the collateral asset of the option
	 * @param strike is the strike price of the option in 1e8 format
	 * @param expiration is the expiry timestamp of the option
	 * @param isPut the type of option
	 * @return the address of the option
	 */
	function getOrDeployOtoken(
		address oTokenFactory,
		address collateral,
		address underlying,
		address strikeAsset,
		uint256 strike,
		uint256 expiration,
		bool isPut
	) external returns (address) {
		IOtokenFactory factory = IOtokenFactory(oTokenFactory);

		address otokenFromFactory = factory.getOtoken(
			underlying,
			strikeAsset,
			collateral,
			strike,
			expiration,
			isPut
		);

		if (otokenFromFactory != address(0)) {
			return otokenFromFactory;
		}

		address otoken = factory.createOtoken(
			underlying,
			strikeAsset,
			collateral,
			strike,
			expiration,
			isPut
		);

		return otoken;
	}

	/**
	 * @notice Retrieves the option token if it already exists
	 * @param oTokenFactory is the address of the opyn oTokenFactory
	 * @param collateral asset that is held as collateral against short/written options
	 * @param underlying is the address of the underlying asset of the option
	 * @param strikeAsset is the address of the collateral asset of the option
	 * @param strike is the strike price of the option in 1e8 format
	 * @param expiration is the expiry timestamp of the option
	 * @param isPut the type of option
	 * @return otokenFromFactory the address of the option
	 */
	function getOtoken(
		address oTokenFactory,
		address collateral,
		address underlying,
		address strikeAsset,
		uint256 strike,
		uint256 expiration,
		bool isPut
	) external view returns (address otokenFromFactory) {
		IOtokenFactory factory = IOtokenFactory(oTokenFactory);
		otokenFromFactory = factory.getOtoken(
			underlying,
			strikeAsset,
			collateral,
			strike,
			expiration,
			isPut
		);
	}

	/**
	 * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin contract which holds the collateral
	 * @param oTokenAddress is the address of the otoken to mint
	 * @param depositAmount is the amount of collateral to deposit
	 * @param vaultId is the vault id to use for creating this short
	 * @param amount is the mint amount in 1e18 format
	 * @param vaultType is the type of vault to be created
	 * @return the otoken mint amount
	 */
	function createShort(
		address gammaController,
		address marginPool,
		address oTokenAddress,
		uint256 depositAmount,
		uint256 vaultId,
		uint256 amount,
		uint256 vaultType
	) external returns (uint256) {
		IController controller = IController(gammaController);
		amount = amount / SCALE_FROM;
		// An otoken's collateralAsset is the vault's `asset`
		// So in the context of performing Opyn short operations we call them collateralAsset
		IOtoken oToken = IOtoken(oTokenAddress);
		address collateralAsset = oToken.collateralAsset();

		// double approve to fix non-compliant ERC20s
		ERC20 collateralToken = ERC20(collateralAsset);
		SafeTransferLib.safeApprove(collateralToken, marginPool, depositAmount);
		// initialise the controller args with 2 incase the vault already exists
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](2);
		// check if a new vault needs to be created
		uint256 newVaultID = (controller.getAccountVaultCounter(address(this))) + 1;
		if (newVaultID == vaultId) {
			actions = new IController.ActionArgs[](3);

			actions[0] = IController.ActionArgs(
				IController.ActionType.OpenVault,
				address(this), // owner
				address(this), // receiver
				address(0), // asset, otoken
				vaultId, // vaultId
				0, // amount
				0, //index
				abi.encode(vaultType) //data
			);

			actions[1] = IController.ActionArgs(
				IController.ActionType.DepositCollateral,
				address(this), // owner
				address(this), // address to transfer from
				collateralAsset, // deposited asset
				vaultId, // vaultId
				depositAmount, // amount
				0, //index
				"" //data
			);

			actions[2] = IController.ActionArgs(
				IController.ActionType.MintShortOption,
				address(this), // owner
				address(this), // address to transfer to
				oTokenAddress, // option address
				vaultId, // vaultId
				amount, // amount
				0, //index
				"" //data
			);
		} else {
			actions[0] = IController.ActionArgs(
				IController.ActionType.DepositCollateral,
				address(this), // owner
				address(this), // address to transfer from
				collateralAsset, // deposited asset
				vaultId, // vaultId
				depositAmount, // amount
				0, //index
				"" //data
			);

			actions[1] = IController.ActionArgs(
				IController.ActionType.MintShortOption,
				address(this), // owner
				address(this), // address to transfer to
				oTokenAddress, // option address
				vaultId, // vaultId
				amount, // amount
				0, //index
				"" //data
			);
		}

		controller.operate(actions);
		// returns in e8
		return amount;
	}

	/**
	 * @notice Deposits Collateral to a specific vault
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin contract which holds the collateral
	 * @param collateralAsset is the address of the collateral asset to deposit
	 * @param depositAmount is the amount of collateral to deposit
	 * @param vaultId is the vault id to access
	 */
	function depositCollat(
		address gammaController,
		address marginPool,
		address collateralAsset,
		uint256 depositAmount,
		uint256 vaultId
	) external {
		IController controller = IController(gammaController);
		// double approve to fix non-compliant ERC20s
		ERC20 collateralToken = ERC20(collateralAsset);
		SafeTransferLib.safeApprove(collateralToken, marginPool, depositAmount);
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.DepositCollateral,
			address(this), // owner
			address(this), // address to transfer from
			collateralAsset, // deposited asset
			vaultId, // vaultId
			depositAmount, // amount
			0, //index
			"" //data
		);

		controller.operate(actions);
	}

	/**
	 * @notice Withdraws Collateral from a specific vault
	 * @param gammaController is the address of the opyn controller contract
	 * @param collateralAsset is the address of the collateral asset to withdraw
	 * @param withdrawAmount is the amount of collateral to withdraw
	 * @param vaultId is the vault id to access
	 */
	function withdrawCollat(
		address gammaController,
		address collateralAsset,
		uint256 withdrawAmount,
		uint256 vaultId
	) external {
		IController controller = IController(gammaController);

		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.WithdrawCollateral,
			address(this), // owner
			address(this), // address to transfer to
			collateralAsset, // withdrawn asset
			vaultId, // vaultId
			withdrawAmount, // amount
			0, //index
			"" //data
		);

		controller.operate(actions);
	}

	/**
	 * @notice Burns an opyn short position and returns collateral back to OptionRegistry
	 * @param gammaController is the address of the opyn controller contract
	 * @param oTokenAddress is the address of the otoken to burn
	 * @param burnAmount is the amount of options to burn
	 * @param vaultId is the vault id used that holds the short
	 * @return the collateral returned amount
	 */
	function burnShort(
		address gammaController,
		address oTokenAddress,
		uint256 burnAmount,
		uint256 vaultId
	) external returns (uint256) {
		IController controller = IController(gammaController);
		// An otoken's collateralAsset is the vault's `asset`
		// So in the context of performing Opyn short operations we call them collateralAsset
		IOtoken oToken = IOtoken(oTokenAddress);
		ERC20 collateralAsset = ERC20(oToken.collateralAsset());
		uint256 startCollatBalance = collateralAsset.balanceOf(address(this));
		GammaTypes.Vault memory vault = controller.getVault(address(this), vaultId);
		// initialise the controller args with 2 incase the vault already exists
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](2);

		actions[0] = IController.ActionArgs(
			IController.ActionType.BurnShortOption,
			address(this), // owner
			address(this), // address to transfer from
			oTokenAddress, // oToken address
			vaultId, // vaultId
			burnAmount, // amount to burn
			0, //index
			"" //data
		);

		actions[1] = IController.ActionArgs(
			IController.ActionType.WithdrawCollateral,
			address(this), // owner
			address(this), // address to transfer to
			address(collateralAsset), // withdrawn asset
			vaultId, // vaultId
			(vault.collateralAmounts[0] * burnAmount) / vault.shortAmounts[0], // amount
			0, //index
			"" //data
		);

		controller.operate(actions);
		// returns in collateral decimals
		return collateralAsset.balanceOf(address(this)) - startCollatBalance;
	}

	/**
	 * @notice Close the existing short otoken position.
	 * @param gammaController is the address of the opyn controller contract
	 * @param vaultId is the id of the vault to be settled
	 * @return collateralRedeemed collateral redeemed from the vault
	 * @return collateralLost collateral left behind in vault used to pay ITM expired options
	 * @return shortAmount number of options that were written
	 */
	function settle(address gammaController, uint256 vaultId)
		external
		returns (
			uint256 collateralRedeemed,
			uint256 collateralLost,
			uint256 shortAmount
		)
	{
		IController controller = IController(gammaController);

		GammaTypes.Vault memory vault = controller.getVault(address(this), vaultId);
		if (vault.shortOtokens.length == 0) {
			revert NoShort();
		}

		// An otoken's collateralAsset is the vault's `asset`
		// So in the context of performing Opyn short operations we call them collateralAsset
		ERC20 collateralToken = ERC20(vault.collateralAssets[0]);

		// This is equivalent to doing ERC20(vault.asset).balanceOf(address(this))
		uint256 startCollateralBalance = collateralToken.balanceOf(address(this));

		// If it is after expiry, we need to settle the short position using the normal way
		// Delete the vault and withdraw all remaining collateral from the vault
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.SettleVault,
			address(this), // owner
			address(this), // address to transfer to
			address(0), // not used
			vaultId, // vaultId
			0, // not used
			0, // not used
			"" // not used
		);

		controller.operate(actions);

		uint256 endCollateralBalance = collateralToken.balanceOf(address(this));
		// calulate collateral redeemed and lost for collateral management in liquidity pool
		collateralRedeemed = endCollateralBalance - startCollateralBalance;
		// returns in collateral decimals, collateralDecimals, e8
		return (
			collateralRedeemed,
			vault.collateralAmounts[0] - collateralRedeemed,
			vault.shortAmounts[0]
		);
	}

	/**
	 * @notice Exercises an ITM option
	 * @param gammaController is the address of the opyn controller contract
	 * @param marginPool is the address of the opyn margin pool
	 * @param series is the address of the option to redeem
	 * @param amount is the number of oTokens to redeem - passed in as e8
	 * @return amount of asset received by exercising the option
	 */
	function redeem(
		address gammaController,
		address marginPool,
		address series,
		uint256 amount
	) external returns (uint256) {
		IController controller = IController(gammaController);
		address collateralAsset = IOtoken(series).collateralAsset();
		uint256 startAssetBalance = ERC20(collateralAsset).balanceOf(msg.sender);

		// If it is after expiry, we need to redeem the profits
		IController.ActionArgs[] memory actions = new IController.ActionArgs[](1);

		actions[0] = IController.ActionArgs(
			IController.ActionType.Redeem,
			address(0), // not used
			msg.sender, // address to send profits to
			series, // address of otoken
			0, // not used
			amount, // otoken balance
			0, // not used
			"" // not used
		);
		SafeTransferLib.safeApprove(ERC20(series), marginPool, amount);
		controller.operate(actions);

		uint256 endAssetBalance = ERC20(collateralAsset).balanceOf(msg.sender);
		// returns in collateral decimals
		return endAssetBalance - startAssetBalance;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Types {
	struct OptionSeries {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		address underlying;
		address strikeAsset;
		address collateral;
	}
	struct PortfolioValues {
		int256 delta;
		int256 gamma;
		int256 vega;
		int256 theta;
		int256 callPutsValue;
		uint256 timestamp;
		uint256 spotPrice;
	}
	struct Order {
		OptionSeries optionSeries;
		uint256 amount;
		uint256 price;
		uint256 orderExpiry;
		address buyer;
		address seriesAddress;
		uint128 lowerSpotMovementRange;
		uint128 upperSpotMovementRange;
		bool isBuyBack;
	}
	// strike and expiry date range for options
	struct OptionParams {
		uint128 minCallStrikePrice;
		uint128 maxCallStrikePrice;
		uint128 minPutStrikePrice;
		uint128 maxPutStrikePrice;
		uint128 minExpiry;
		uint128 maxExpiry;
	}

	struct UtilizationState {
		uint256 totalOptionPrice; //e18
		int256 totalDelta; // e18
		uint256 collateralToAllocate; //collateral decimals
		uint256 utilizationBefore; // e18
		uint256 utilizationAfter; //e18
		uint256 utilizationPrice; //e18
		bool isDecreased;
		uint256 deltaTiltAmount; //e18
		uint256 underlyingPrice; // strike asset decimals
		uint256 iv; // e18
	}

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
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

	function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

	function operate(ActionArgs[] calldata _actions) external;

	function getAccountVaultCounter(address owner) external view returns (uint256);

	function oracle() external view returns (address);

	function getVault(address _owner, uint256 _vaultId)
		external
		view
		returns (GammaTypes.Vault memory);

	function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
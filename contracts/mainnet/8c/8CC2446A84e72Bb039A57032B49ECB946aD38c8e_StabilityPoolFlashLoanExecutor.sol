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
pragma solidity >=0.8.0;

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 amount)
		external
		returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface IERC20Callback {
	/// @notice receiveERC20 should be used as the "receive" callback of native token but for erc20
	/// @dev Be sure to limit the access of this call.
	/// @param _token transfered token
	/// @param _value The value of the transfer
	function receiveERC20(address _token, uint256 _value) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IFlashLoanExecutor {
	/**
	 * @notice Executes an operation after receiving the flash-loaned VST
	 * @dev Ensure that the contract can return the debt + fee, e.g., has
	 *      enough funds to repay and has approved the flashloan contract to pull the total amount
	 * @param amount The amount of the flash-loaned VST
	 * @param fee The fee of the flash-loan. Flat amount calculated by the flashloan contract.
	 * @param initiator The address of the flashloan initiator
	 * @param extraParams The byte-encoded params passed when initiating the flashloan. May not be needed.
	 */
	function executeOperation(
		uint256 amount,
		uint256 fee,
		address initiator,
		bytes calldata extraParams
	) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IGlpRewardRouter {
	function unstakeAndRedeemGlp(
		address _tokenOut,
		uint256 _glpAmount,
		uint256 _minOut,
		address _receiver
	) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IHintHelper {
	function getLiquidatableAmount(
		address _asset,
		uint256 _assetPrice
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceFeed {
	function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
	function setParams(
		address _TroveManagerAddress,
		address _borrowerOperationsAddress
	) external;

	function insert(
		address _asset,
		address _id,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external;

	function remove(address _asset, address _id) external;

	function reInsert(
		address _asset,
		address _id,
		uint256 _newICR,
		address _prevId,
		address _nextId
	) external;

	function contains(
		address _asset,
		address _id
	) external view returns (bool);

	function isFull(address _asset) external view returns (bool);

	function isEmpty(address _asset) external view returns (bool);

	function getSize(address _asset) external view returns (uint256);

	function getMaxSize(address _asset) external view returns (uint256);

	function getFirst(address _asset) external view returns (address);

	function getLast(address _asset) external view returns (address);

	function getNext(
		address _asset,
		address _id
	) external view returns (address);

	function getPrev(
		address _asset,
		address _id
	) external view returns (address);

	function validInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (bool);

	function findInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStabilityPool {
	/*
	 * Initial checks:
	 * - Frontend is registered or zero address
	 * - Sender is not a registered frontend
	 * - _amount is not zero
	 * ---
	 * - Triggers a VSTA issuance, based on time passed since the last issuance. The VSTA issuance is shared between *all* depositors and front ends
	 * - Tags the deposit with the provided front end tag param, if it's a new deposit
	 * - Sends depositor's accumulated gains (VSTA, ETH) to depositor
	 * - Sends the tagged front end's accumulated VSTA gains to the tagged front end
	 * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
	 */
	function provideToSP(uint256 _amount) external;

	/*
	 * Initial checks:
	 * - _amount is zero or there are no under collateralized troves left in the system
	 * - User has a non zero deposit
	 * ---
	 * - Triggers a VSTA issuance, based on time passed since the last issuance. The VSTA issuance is shared between *all* depositors and front ends
	 * - Removes the deposit's front end tag if it is a full withdrawal
	 * - Sends all depositor's accumulated gains (VSTA, ETH) to depositor
	 * - Sends the tagged front end's accumulated VSTA gains to the tagged front end
	 * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount) external;

	/*
	 * Returns VST held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
	 */
	function getTotalVSTDeposits() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITroveManager {
	function liquidateTroves(address _asset, uint256 _n) external;

	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ManualExchange, RouteConfig } from "../model/TradingModel.sol";

interface IVestaDexTrader {
	/**
	 * exchange uses Vesta's traders but with your own routing.
	 * @param _receiver the wallet that will receives the output token
	 * @param _firstTokenIn the token that will be swapped
	 * @param _firstAmountIn the amount of Token In you will send
	 * @param _requests Your custom routing
	 * @return swapDatas_ elements are the amountOut from each swaps
	 *
	 * @dev this function only uses expectedAmountIn
	 */
	function exchange(
		address _receiver,
		address _firstTokenIn,
		uint256 _firstAmountIn,
		ManualExchange[] calldata _requests
	) external returns (uint256[] memory swapDatas_);

	// /**
	//  * isRegisteredTrader check if a contract is a Trader
	//  * @param _trader address of the trader
	//  * @return registered_ is true if the trader is registered
	//  */
	// function isRegisteredTrader(address _trader)
	// 	external
	// 	view
	// 	returns (bool);

	// /**
	//  * getTraderAddressWithSelector get Trader address with selector
	//  * @param _selector Trader's selector
	//  * @return address_ Trader's address
	//  */
	// function getTraderAddressWithSelector(bytes16 _selector)
	// 	external
	// 	view
	// 	returns (address);

	// /**
	//  * getRouteOf get the routes config between two tokens
	//  * @param _tokenIn token you want to swap
	//  * @param _tokenOut the token outcome of the swap
	//  * @return routes the configured routes
	//  */
	// function getRouteOf(address _tokenIn, address _tokenOut)
	// 	external
	// 	view
	// 	returns (RouteConfig[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVestaParameters {
	function MCR(address _collateral) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IVSTFlashLoan {
	event FlashLoanSuccess(address _caller, address _reciever, uint256 _amount);

	/**
	 * @notice Implements the simple flashloan feature that allow users to borrow VST to perform arbitrage
	 * as long as the amount taken plus fee is returned.
	 * @dev At the end of the transaction the contract will pull amount borrowed + fee from the receiver,
	 * if the receiver have not approved the pool the transaction will revert.
	 * @param _amount The amount of VST flashloaned
	 * @param _executor The contract recieving the flashloan funds and performing the flashloan operation.
	 * @param _extraParams The additional parameters needed to execute the simple flashloan function
	 */
	function executeFlashLoan(
		uint256 _amount,
		address _executor,
		bytes calldata _extraParams
	) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IWETH9 {
	function deposit() external payable;

	function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenTransferrerConstants.sol";
import { TokenTransferrerErrors } from "./TokenTransferrerErrors.sol";
import { IERC20 } from "../interface/IERC20.sol";
import { IERC20Callback } from "../interface/IERC20Callback.sol";

/**
 * @title TokenTransferrer
 * @custom:source https://github.com/ProjectOpenSea/seaport
 * @dev Modified version of Seaport.
 */
abstract contract TokenTransferrer is TokenTransferrerErrors {
	function _performTokenTransfer(
		address token,
		address to,
		uint256 amount,
		bool sendCallback
	) internal {
		if (token == address(0)) {
			(bool success, ) = to.call{ value: amount }(new bytes(0));

			if (!success) revert ErrorTransferETH(address(this), token, amount);

			return;
		}

		address from = address(this);

		// Utilize assembly to perform an optimized ERC20 token transfer.
		assembly {
			// The free memory pointer memory slot will be used when populating
			// call data for the transfer; read the value and restore it later.
			let memPointer := mload(FreeMemoryPointerSlot)

			// Write call data into memory, starting with function selector.
			mstore(ERC20_transfer_sig_ptr, ERC20_transfer_signature)
			mstore(ERC20_transfer_to_ptr, to)
			mstore(ERC20_transfer_amount_ptr, amount)

			// Make call & copy up to 32 bytes of return data to scratch space.
			// Scratch space does not need to be cleared ahead of time, as the
			// subsequent check will ensure that either at least a full word of
			// return data is received (in which case it will be overwritten) or
			// that no data is received (in which case scratch space will be
			// ignored) on a successful call to the given token.
			let callStatus := call(
				gas(),
				token,
				0,
				ERC20_transfer_sig_ptr,
				ERC20_transfer_length,
				0,
				OneWord
			)

			// Determine whether transfer was successful using status & result.
			let success := and(
				// Set success to whether the call reverted, if not check it
				// either returned exactly 1 (can't just be non-zero data), or
				// had no return data.
				or(
					and(eq(mload(0), 1), gt(returndatasize(), 31)),
					iszero(returndatasize())
				),
				callStatus
			)

			// Handle cases where either the transfer failed or no data was
			// returned. Group these, as most transfers will succeed with data.
			// Equivalent to `or(iszero(success), iszero(returndatasize()))`
			// but after it's inverted for JUMPI this expression is cheaper.
			if iszero(and(success, iszero(iszero(returndatasize())))) {
				// If the token has no code or the transfer failed: Equivalent
				// to `or(iszero(success), iszero(extcodesize(token)))` but
				// after it's inverted for JUMPI this expression is cheaper.
				if iszero(and(iszero(iszero(extcodesize(token))), success)) {
					// If the transfer failed:
					if iszero(success) {
						// If it was due to a revert:
						if iszero(callStatus) {
							// If it returned a message, bubble it up as long as
							// sufficient gas remains to do so:
							if returndatasize() {
								// Ensure that sufficient gas is available to
								// copy returndata while expanding memory where
								// necessary. Start by computing the word size
								// of returndata and allocated memory. Round up
								// to the nearest full word.
								let returnDataWords := div(
									add(returndatasize(), AlmostOneWord),
									OneWord
								)

								// Note: use the free memory pointer in place of
								// msize() to work around a Yul warning that
								// prevents accessing msize directly when the IR
								// pipeline is activated.
								let msizeWords := div(memPointer, OneWord)

								// Next, compute the cost of the returndatacopy.
								let cost := mul(CostPerWord, returnDataWords)

								// Then, compute cost of new memory allocation.
								if gt(returnDataWords, msizeWords) {
									cost := add(
										cost,
										add(
											mul(sub(returnDataWords, msizeWords), CostPerWord),
											div(
												sub(
													mul(returnDataWords, returnDataWords),
													mul(msizeWords, msizeWords)
												),
												MemoryExpansionCoefficient
											)
										)
									)
								}

								// Finally, add a small constant and compare to
								// gas remaining; bubble up the revert data if
								// enough gas is still available.
								if lt(add(cost, ExtraGasBuffer), gas()) {
									// Copy returndata to memory; overwrite
									// existing memory.
									returndatacopy(0, 0, returndatasize())

									// Revert, specifying memory region with
									// copied returndata.
									revert(0, returndatasize())
								}
							}

							// Otherwise revert with a generic error message.
							mstore(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_signature
							)
							mstore(TokenTransferGenericFailure_error_token_ptr, token)
							mstore(TokenTransferGenericFailure_error_from_ptr, from)
							mstore(TokenTransferGenericFailure_error_to_ptr, to)
							mstore(TokenTransferGenericFailure_error_id_ptr, 0)
							mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
							revert(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_length
							)
						}

						// Otherwise revert with a message about the token
						// returning false or non-compliant return values.
						mstore(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_signature
						)
						mstore(
							BadReturnValueFromERC20OnTransfer_error_token_ptr,
							token
						)
						mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
						mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
						mstore(
							BadReturnValueFromERC20OnTransfer_error_amount_ptr,
							amount
						)
						revert(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_length
						)
					}

					// Otherwise, revert with error about token not having code:
					mstore(NoContract_error_sig_ptr, NoContract_error_signature)
					mstore(NoContract_error_token_ptr, token)
					revert(NoContract_error_sig_ptr, NoContract_error_length)
				}

				// Otherwise, the token just returned no data despite the call
				// having succeeded; no need to optimize for this as it's not
				// technically ERC20 compliant.
			}

			// Restore the original free memory pointer.
			mstore(FreeMemoryPointerSlot, memPointer)

			// Restore the zero slot to zero.
			mstore(ZeroSlot, 0)
		}

		_tryPerformCallback(token, to, amount, sendCallback);
	}

	function _performTokenTransferFrom(
		address token,
		address from,
		address to,
		uint256 amount,
		bool sendCallback
	) internal {
		// Utilize assembly to perform an optimized ERC20 token transfer.
		assembly {
			// The free memory pointer memory slot will be used when populating
			// call data for the transfer; read the value and restore it later.
			let memPointer := mload(FreeMemoryPointerSlot)

			// Write call data into memory, starting with function selector.
			mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
			mstore(ERC20_transferFrom_from_ptr, from)
			mstore(ERC20_transferFrom_to_ptr, to)
			mstore(ERC20_transferFrom_amount_ptr, amount)

			// Make call & copy up to 32 bytes of return data to scratch space.
			// Scratch space does not need to be cleared ahead of time, as the
			// subsequent check will ensure that either at least a full word of
			// return data is received (in which case it will be overwritten) or
			// that no data is received (in which case scratch space will be
			// ignored) on a successful call to the given token.
			let callStatus := call(
				gas(),
				token,
				0,
				ERC20_transferFrom_sig_ptr,
				ERC20_transferFrom_length,
				0,
				OneWord
			)

			// Determine whether transfer was successful using status & result.
			let success := and(
				// Set success to whether the call reverted, if not check it
				// either returned exactly 1 (can't just be non-zero data), or
				// had no return data.
				or(
					and(eq(mload(0), 1), gt(returndatasize(), 31)),
					iszero(returndatasize())
				),
				callStatus
			)

			// Handle cases where either the transfer failed or no data was
			// returned. Group these, as most transfers will succeed with data.
			// Equivalent to `or(iszero(success), iszero(returndatasize()))`
			// but after it's inverted for JUMPI this expression is cheaper.
			if iszero(and(success, iszero(iszero(returndatasize())))) {
				// If the token has no code or the transfer failed: Equivalent
				// to `or(iszero(success), iszero(extcodesize(token)))` but
				// after it's inverted for JUMPI this expression is cheaper.
				if iszero(and(iszero(iszero(extcodesize(token))), success)) {
					// If the transfer failed:
					if iszero(success) {
						// If it was due to a revert:
						if iszero(callStatus) {
							// If it returned a message, bubble it up as long as
							// sufficient gas remains to do so:
							if returndatasize() {
								// Ensure that sufficient gas is available to
								// copy returndata while expanding memory where
								// necessary. Start by computing the word size
								// of returndata and allocated memory. Round up
								// to the nearest full word.
								let returnDataWords := div(
									add(returndatasize(), AlmostOneWord),
									OneWord
								)

								// Note: use the free memory pointer in place of
								// msize() to work around a Yul warning that
								// prevents accessing msize directly when the IR
								// pipeline is activated.
								let msizeWords := div(memPointer, OneWord)

								// Next, compute the cost of the returndatacopy.
								let cost := mul(CostPerWord, returnDataWords)

								// Then, compute cost of new memory allocation.
								if gt(returnDataWords, msizeWords) {
									cost := add(
										cost,
										add(
											mul(sub(returnDataWords, msizeWords), CostPerWord),
											div(
												sub(
													mul(returnDataWords, returnDataWords),
													mul(msizeWords, msizeWords)
												),
												MemoryExpansionCoefficient
											)
										)
									)
								}

								// Finally, add a small constant and compare to
								// gas remaining; bubble up the revert data if
								// enough gas is still available.
								if lt(add(cost, ExtraGasBuffer), gas()) {
									// Copy returndata to memory; overwrite
									// existing memory.
									returndatacopy(0, 0, returndatasize())

									// Revert, specifying memory region with
									// copied returndata.
									revert(0, returndatasize())
								}
							}

							// Otherwise revert with a generic error message.
							mstore(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_signature
							)
							mstore(TokenTransferGenericFailure_error_token_ptr, token)
							mstore(TokenTransferGenericFailure_error_from_ptr, from)
							mstore(TokenTransferGenericFailure_error_to_ptr, to)
							mstore(TokenTransferGenericFailure_error_id_ptr, 0)
							mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
							revert(
								TokenTransferGenericFailure_error_sig_ptr,
								TokenTransferGenericFailure_error_length
							)
						}

						// Otherwise revert with a message about the token
						// returning false or non-compliant return values.
						mstore(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_signature
						)
						mstore(
							BadReturnValueFromERC20OnTransfer_error_token_ptr,
							token
						)
						mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
						mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
						mstore(
							BadReturnValueFromERC20OnTransfer_error_amount_ptr,
							amount
						)
						revert(
							BadReturnValueFromERC20OnTransfer_error_sig_ptr,
							BadReturnValueFromERC20OnTransfer_error_length
						)
					}

					// Otherwise, revert with error about token not having code:
					mstore(NoContract_error_sig_ptr, NoContract_error_signature)
					mstore(NoContract_error_token_ptr, token)
					revert(NoContract_error_sig_ptr, NoContract_error_length)
				}

				// Otherwise, the token just returned no data despite the call
				// having succeeded; no need to optimize for this as it's not
				// technically ERC20 compliant.
			}

			// Restore the original free memory pointer.
			mstore(FreeMemoryPointerSlot, memPointer)

			// Restore the zero slot to zero.
			mstore(ZeroSlot, 0)
		}

		_tryPerformCallback(token, to, amount, sendCallback);
	}

	function _tryPerformCallback(
		address _token,
		address _to,
		uint256 _amount,
		bool _useCallback
	) private {
		if (!_useCallback || _to.code.length == 0) return;

		if (address(this) == _to) {
			revert SelfCallbackTransfer();
		}

		IERC20Callback(_to).receiveERC20(_token, _amount);
	}

	/**
		@notice SanitizeAmount allows to convert an 1e18 value to the token decimals
		@dev only supports 18 and lower
		@param token The contract address of the token
		@param value The value you want to sanitize
	*/
	function _sanitizeValue(address token, uint256 value)
		internal
		view
		returns (uint256)
	{
		if (token == address(0) || value == 0) return value;

		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSignature("decimals()")
		);

		if (!success) return value;

		uint8 decimals = abi.decode(data, (uint8));

		if (decimals < 18) {
			return value / (10**(18 - decimals));
		}

		return value;
	}

	function _tryPerformMaxApprove(address _token, address _to) internal {
		if (
			IERC20(_token).allowance(address(this), _to) == type(uint256).max
		) {
			return;
		}

		_performApprove(_token, _to, type(uint256).max);
	}

	function _performApprove(
		address _token,
		address _spender,
		uint256 _value
	) internal {
		IERC20(_token).approve(_spender, _value);
	}

	function _balanceOf(address _token, address _of)
		internal
		view
		returns (uint256)
	{
		return IERC20(_token).balanceOf(_of);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature = (
	0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("transfer(address,uint256)")
uint256 constant ERC20_transfer_signature = (
	0xa9059cbb00000000000000000000000000000000000000000000000000000000
);

uint256 constant ERC20_transfer_sig_ptr = 0x0;
uint256 constant ERC20_transfer_to_ptr = 0x04;
uint256 constant ERC20_transfer_amount_ptr = 0x24;
uint256 constant ERC20_transfer_length = 0x44; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature = (
	0x5f15d67200000000000000000000000000000000000000000000000000000000
);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature = (
	0xf486bc8700000000000000000000000000000000000000000000000000000000
);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
	0x9889192300000000000000000000000000000000000000000000000000000000
);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
	error ErrorTransferETH(address caller, address to, uint256 value);

	/**
	 * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
	 *      transfer reverts.
	 *
	 * @param token      The token for which the transfer was attempted.
	 * @param from       The source of the attempted transfer.
	 * @param to         The recipient of the attempted transfer.
	 * @param identifier The identifier for the attempted transfer.
	 * @param amount     The amount for the attempted transfer.
	 */
	error TokenTransferGenericFailure(
		address token,
		address from,
		address to,
		uint256 identifier,
		uint256 amount
	);

	/**
	 * @dev Revert with an error when an ERC20 token transfer returns a falsey
	 *      value.
	 *
	 * @param token      The token for which the ERC20 transfer was attempted.
	 * @param from       The source of the attempted ERC20 transfer.
	 * @param to         The recipient of the attempted ERC20 transfer.
	 * @param amount     The amount for the attempted ERC20 transfer.
	 */
	error BadReturnValueFromERC20OnTransfer(
		address token,
		address from,
		address to,
		uint256 amount
	);

	/**
	 * @dev Revert with an error when an account being called as an assumed
	 *      contract does not have code and returns no data.
	 *
	 * @param account The account that should contain code.
	 */
	error NoContract(address account);

	/**
	@dev Revert if the {_to} callback is the same as the souce (address(this))
	*/
	error SelfCallbackTransfer();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @param traderSelector the name of the trader in a bytes16 format
 * @param tokenIn the token that will be swapped
 * @param encodedData the encoded structure for the trader
 */
struct RouteConfig {
	bytes16 traderSelector;
	address tokenIn;
	bytes encodedData;
}

/**
 * @param traderSelector the Selector of the Dex you want to use. If not sure, you can find them in VestaDexTrader.sol
 * @param tokenInOut the token0 is the one that will be swapped, the token1 is the one that will be returned
 * @param data the encoded structure for the exchange function of a ITrader.
 * @dev {data}'s structure should have 0 for expectedAmountIn and expectedAmountOut
 */
struct ManualExchange {
	bytes16 traderSelector;
	address[2] tokenInOut;
	bytes data;
}

/**
 * @param path
 * 	SingleHop: abi.encode(address tokenOut,uint24 poolFee);
 * 	MultiHop-ExactAmountIn: abi.encode(tokenIn, uint24 fee, tokenOutIn, fee, tokenOut);
 * @param tokenIn the token that will be swapped
 * @param expectedAmountIn the expected amount In that will be swapped
 * @param expectedAmountOut the expected amount Out that will be returned
 * @param amountInMaximum the maximum tokenIn that can be used
 * @param usingHop does it use a hop (multi-path)
 *
 * @dev you can only use one of the expectedAmount, not both.
 * @dev amountInMaximum can be zero
 */
struct UniswapV3SwapRequest {
	bytes path;
	address tokenIn;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
	uint256 amountInMaximum;
	bool usingHop;
}

/**
 * @param pool the curve's pool address
 * @param coins coins0 is the token that goes in, coins1 is the token that goes out
 * @param expectedAmountIn the expect amount in that will be used
 * @param expectedAmountOut the expect amount out that the user will receives
 * @param slippage allowed slippage in BPS percentage
 * @dev {_slippage} is only used for curve and it is an addition to the expected amountIn that the system calculates.
		If the system expects amountIn to be 100 to have the exact amountOut, the total of amountIn WILL BE 110.
		You'll need it on major price impacts trading.
 *
 * @dev you can only use one of the expectedAmount, not both.
 * @dev slippage should only used by other contracts. Otherwise, do the formula off-chain and set it to zero.
 */
struct CurveSwapRequest {
	address pool;
	uint8[2] coins;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
	uint16 slippage;
}

/**
 * @param path uses the token address to create the path
 * @param expectedAmountIn the expect amount in that will be used
 * @param expectedAmountOut the expect amount out that the user will receives
 *
 * @dev Path length should be 2 or 3. Otherwise, you are using it wrong!
 * @dev you can only use one of the expectedAmount, not both.
 */
struct GenericSwapRequest {
	address[] path;
	uint256 expectedAmountIn;
	uint256 expectedAmountOut;
}

/**
 * @param pool the curve's pool address
 * @param coins coins0 is the token that goes in, coins1 is the token that goes out
 * @param amount the amount wanted
 * @param slippage allowed slippage in BPS percentage
 * @dev {_slippage} is only used for curve and it is an addition to the expected amountIn that the system calculates.
		If the system expects amountIn to be 100 to have the exact amountOut, the total of amountIn WILL BE 110.
		You'll need it on major price impacts trading.
 */
struct CurveRequestExactInOutParams {
	address pool;
	uint8[2] coins;
	uint256 amount;
	uint16 slippage;
}

/**
 * @param path uses the token address to create the path
 * @param amount the wanted amount
 */
struct GenericRequestExactInOutParams {
	address[] path;
	uint256 amount;
}

/**
 * @param path
 * 	SingleHop: abi.encode(address tokenOut,uint24 poolFee);
 * 	MultiHop-ExactAmountIn: abi.encode(tokenIn, uint24 fee, tokenOutIn, fee, tokenOut);
 * @param tokenIn the token that will be swapped
 * @param amount the amount wanted
 * @param usingHop does it use a hop (multi-path)
 */
struct UniswapV3RequestExactInOutParams {
	bytes path;
	address tokenIn;
	uint256 amount;
	bool usingHop;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interface/IFlashLoanExecutor.sol";
import "./interface/IVestaDexTrader.sol";
import "./interface/IStabilityPool.sol";
import "./interface/ITroveManager.sol";
import "./interface/IWETH9.sol";
import "./interface/IGlpRewardRouter.sol";
import { ManualExchange } from "./model/TradingModel.sol";
import { TokenTransferrer } from "./lib/TokenTransferrer.sol";

error NoAssetGain();
error UnprofitableTransaction(uint256 _finalVSTBalance);

contract StabilityPoolFlashLoanExecutor is
	IFlashLoanExecutor,
	TokenTransferrer,
	Ownable
{
	address public immutable ethStabilityPoolAddress;
	address public immutable wethAddress;
	address public immutable glpStabilityPoolAddress;
	address public immutable feeStakedGLP;
	address public immutable VST;
	IGlpRewardRouter public immutable glpRewardRouterAddress;
	IVestaDexTrader public immutable dexTrader;
	ITroveManager public immutable troveManager;

	event debug(uint256 amount);

	constructor(
		address _VST,
		address _flashloanContract,
		address _dexTrader,
		address _troveManager,
		address _ethStabilityPool,
		address _weth,
		address _glpStabilityPool,
		address _glpRewardRouter,
		address _feeStakedGlp
	) {
		VST = _VST;
		dexTrader = IVestaDexTrader(_dexTrader);
		troveManager = ITroveManager(_troveManager);
		glpRewardRouterAddress = IGlpRewardRouter(_glpRewardRouter);
		ethStabilityPoolAddress = _ethStabilityPool;
		wethAddress = _weth;
		glpStabilityPoolAddress = _glpStabilityPool;
		feeStakedGLP = _feeStakedGlp;
		_tryPerformMaxApprove(address(VST), _flashloanContract);
	}

	function executeOperation(
		uint256 _amount,
		uint256 _fee,
		address _initiator,
		bytes calldata _extraParams
	) external {
		(
			address tokenAddress,
			address stabilityPoolAddress,
			ManualExchange[] memory routes
		) = abi.decode(_extraParams, (address, address, ManualExchange[]));

		_performApprove(VST, address(stabilityPoolAddress), _amount);
		IStabilityPool(stabilityPoolAddress).provideToSP(_amount);
		troveManager.liquidateTroves(tokenAddress, type(uint256).max);
		IStabilityPool(stabilityPoolAddress).withdrawFromSP(type(uint256).max);

		uint256 assetGain;
		if (stabilityPoolAddress == ethStabilityPoolAddress) {
			assetGain = address(this).balance;
			IWETH9(wethAddress).deposit{ value: assetGain }();
			tokenAddress = wethAddress;
		} else if (stabilityPoolAddress == glpStabilityPoolAddress) {
			uint256 glpAmount = _balanceOf(feeStakedGLP, address(this));
			IGlpRewardRouter(glpRewardRouterAddress).unstakeAndRedeemGlp(
				wethAddress,
				glpAmount,
				0,
				address(this)
			);
			assetGain = _balanceOf(wethAddress, address(this));
			tokenAddress = wethAddress;
		} else {
			assetGain = _balanceOf(tokenAddress, address(this));
		}

		if (assetGain > 0) {
			_performApprove(tokenAddress, address(dexTrader), assetGain);
			dexTrader.exchange(address(this), tokenAddress, assetGain, routes);
		} else {
			revert NoAssetGain();
		}

		uint256 finalVSTBalance = _balanceOf(VST, address(this));

		if (finalVSTBalance < _amount + _fee) {
			revert UnprofitableTransaction(finalVSTBalance);
		}
	}

	function sendERC20(
		address _tokenAddress,
		uint256 _tokenAmount
	) external onlyOwner {
		_performTokenTransfer(_tokenAddress, msg.sender, _tokenAmount, false);
	}

	receive() external payable {}
}
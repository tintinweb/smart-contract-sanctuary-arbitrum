// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title FixedPoint
 * @dev Math library to operate with fixed point values with 18 decimals
 */
library FixedPoint {
    // 1 in fixed point value: 18 decimal places
    uint256 internal constant ONE = 1e18;

    /**
     * @dev Multiplication overflow
     */
    error FixedPointMulOverflow(uint256 a, uint256 b);

    /**
     * @dev Division by zero
     */
    error FixedPointZeroDivision();

    /**
     * @dev Division internal error
     */
    error FixedPointDivInternal(uint256 a, uint256 aInflated);

    /**
     * @dev Multiplies two fixed point numbers rounding down
     */
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            if (a != 0 && product / a != b) revert FixedPointMulOverflow(a, b);
            return product / ONE;
        }
    }

    /**
     * @dev Multiplies two fixed point numbers rounding up
     */
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            if (a != 0 && product / a != b) revert FixedPointMulOverflow(a, b);
            return product == 0 ? 0 : (((product - 1) / ONE) + 1);
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding down
     */
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) revert FixedPointZeroDivision();
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            if (aInflated / a != ONE) revert FixedPointDivInternal(a, aInflated);
            return aInflated / b;
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding up
     */
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b == 0) revert FixedPointZeroDivision();
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            if (aInflated / a != ONE) revert FixedPointDivInternal(a, aInflated);
            return ((aInflated - 1) / b) + 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title Arrays
 * @dev Helper methods to operate arrays
 */
library Arrays {
    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address b) internal pure returns (address[] memory result) {
        result = new address[](2);
        result[0] = a;
        result[1] = b;
    }

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address[] memory b, address c) internal pure returns (address[] memory result) {
        result = new address[](b.length + 2);
        result[0] = a;
        for (uint256 i = 0; i < b.length; i++) {
            result[i + 1] = b[i];
        }
        result[b.length + 1] = c;
    }

    /**
     * @dev Builds an array of uint24s based on the given ones
     */
    function from(uint24 a, uint24[] memory b) internal pure returns (uint24[] memory result) {
        result = new uint24[](b.length + 1);
        result[0] = a;
        for (uint256 i = 0; i < b.length; i++) {
            result[i + 1] = b[i];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title BytesHelpers
 * @dev Provides a list of Bytes helper methods
 */
library BytesHelpers {
    /**
     * @dev The length is shorter than start plus 32
     */
    error BytesOutOfBounds(uint256 start, uint256 length);

    /**
     * @dev Concatenates an address to a bytes array
     */
    function concat(bytes memory self, address value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Concatenates an uint24 to a bytes array
     */
    function concat(bytes memory self, uint24 value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Decodes a bytes array into an uint256
     */
    function toUint256(bytes memory self) internal pure returns (uint256) {
        return toUint256(self, 0);
    }

    /**
     * @dev Reads an uint256 from a bytes array starting at a given position
     */
    function toUint256(bytes memory self, uint256 start) internal pure returns (uint256 result) {
        if (self.length < start + 32) revert BytesOutOfBounds(start, self.length);
        assembly {
            result := mload(add(add(self, 0x20), start))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title Denominations
 * @dev Provides a list of ground denominations for those tokens that cannot be represented by an ERC20.
 * For now, the only needed is the native token that could be ETH, MATIC, or other depending on the layer being operated.
 */
library Denominations {
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
    address internal constant USD = address(840);

    function isNativeToken(address token) internal pure returns (bool) {
        return token == NATIVE_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './Denominations.sol';

/**
 * @title ERC20Helpers
 * @dev Provides a list of ERC20 helper methods
 */
library ERC20Helpers {
    function approve(address token, address to, uint256 amount) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeApprove(IERC20(token), to, amount);
    }

    function transfer(address token, address to, uint256 amount) internal {
        if (Denominations.isNativeToken(token)) Address.sendValue(payable(to), amount);
        else SafeERC20.safeTransfer(IERC20(token), to, amount);
    }

    function balanceOf(address token, address account) internal view returns (uint256) {
        if (Denominations.isNativeToken(token)) return address(account).balance;
        else return IERC20(token).balanceOf(address(account));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title IWrappedNativeToken
 */
interface IWrappedNativeToken is IERC20 {
    /**
     * @dev Wraps msg.value into the wrapped-native token
     */
    function deposit() external payable;

    /**
     * @dev Unwraps requested amount to the native token
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
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

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
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

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
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

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
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

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
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

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
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

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IAxelarGateway.sol';
import '../../interfaces/bridge/IAxelarConnector.sol';

/**
 * @title AxelarConnector
 * @dev Interfaces with Axelar to bridge tokens
 */
contract AxelarConnector is IAxelarConnector {
    // List of chain names supported by Axelar
    string private constant ETHEREUM_NAME = 'Ethereum';
    string private constant POLYGON_NAME = 'Polygon';
    string private constant ARBITRUM_NAME = 'arbitrum';
    string private constant BSC_NAME = 'binance';
    string private constant FANTOM_NAME = 'Fantom';
    string private constant AVALANCHE_NAME = 'Avalanche';

    // List of chain IDs supported by Axelar
    uint256 private constant ETHEREUM_ID = 1;
    uint256 private constant POLYGON_ID = 137;
    uint256 private constant ARBITRUM_ID = 42161;
    uint256 private constant BSC_ID = 56;
    uint256 private constant FANTOM_ID = 250;
    uint256 private constant AVALANCHE_ID = 43114;

    // Reference to the Axelar gateway of the source chain
    address public immutable override axelarGateway;

    /**
     * @dev Creates a new Axelar connector
     * @param _axelarGateway Address of the Axelar gateway for the source chain
     */
    constructor(address _axelarGateway) {
        axelarGateway = _axelarGateway;
    }

    /**
     * @dev Executes a bridge of assets using Axelar
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amount, address recipient) external override {
        if (block.chainid == chainId) revert AxelarBridgeSameChain(chainId);
        if (recipient == address(0)) revert AxelarBridgeRecipientZero();

        string memory chainName = _getChainName(chainId);
        string memory symbol = IERC20Metadata(token).symbol();

        uint256 preBalance = IERC20(token).balanceOf(address(this));
        ERC20Helpers.approve(token, axelarGateway, amount);
        IAxelarGateway(axelarGateway).sendToken(chainName, Strings.toHexString(recipient), symbol, amount);

        uint256 postBalance = IERC20(token).balanceOf(address(this));
        bool isPostBalanceUnexpected = postBalance < preBalance - amount;
        if (isPostBalanceUnexpected) revert AxelarBridgeBadPostTokenBalance(postBalance, preBalance, amount);
    }

    /**
     * @dev Tells the chain name based on a chain ID
     * @param chainId ID of the chain being queried
     * @return Chain name associated to the requested chain ID
     */
    function _getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == ETHEREUM_ID) return ETHEREUM_NAME;
        else if (chainId == POLYGON_ID) return POLYGON_NAME;
        else if (chainId == ARBITRUM_ID) return ARBITRUM_NAME;
        else if (chainId == BSC_ID) return BSC_NAME;
        else if (chainId == FANTOM_ID) return FANTOM_NAME;
        else if (chainId == AVALANCHE_ID) return AVALANCHE_NAME;
        else revert AxelarBridgeUnknownChainId(chainId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IAxelarGateway {
    function sendToken(string memory chain, string memory recipient, string memory symbol, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IConnext.sol';
import '../../interfaces/bridge/IConnextConnector.sol';

/**
 * @title ConnextConnector
 * @dev Interfaces with Connext to bridge tokens
 */
contract ConnextConnector is IConnextConnector {
    // List of chain domains supported by Connext
    uint32 private constant ETHEREUM_DOMAIN = 6648936;
    uint32 private constant POLYGON_DOMAIN = 1886350457;
    uint32 private constant ARBITRUM_DOMAIN = 1634886255;
    uint32 private constant OPTIMISM_DOMAIN = 1869640809;
    uint32 private constant GNOSIS_DOMAIN = 6778479;
    uint32 private constant BSC_DOMAIN = 6450786;

    // List of chain IDs supported by Connext
    uint256 private constant ETHEREUM_ID = 1;
    uint256 private constant POLYGON_ID = 137;
    uint256 private constant ARBITRUM_ID = 42161;
    uint256 private constant OPTIMISM_ID = 10;
    uint256 private constant GNOSIS_ID = 100;
    uint256 private constant BSC_ID = 56;

    // Reference to the Connext contract of the source chain
    address public immutable override connext;

    /**
     * @dev Creates a new Connext connector
     * @param _connext Address of the Connext contract for the source chain
     */
    constructor(address _connext) {
        connext = _connext;
    }

    /**
     * @dev Executes a bridge of assets using Connext
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Min amount of tokens to receive on the destination chain after relayer fees and slippage
     * @param recipient Address that will receive the tokens on the destination chain
     * @param relayerFee Fee to be paid to the relayer
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        uint256 relayerFee
    ) external override {
        if (block.chainid == chainId) revert ConnextBridgeSameChain(chainId);
        if (recipient == address(0)) revert ConnextBridgeRecipientZero();
        if (relayerFee > amount) revert ConnextBridgeRelayerFeeGtAmount(relayerFee, amount);

        bool isMinAmountTooBig = minAmountOut > amount - relayerFee;
        if (isMinAmountTooBig) revert ConnextBridgeMinAmountOutTooBig(minAmountOut, amount, relayerFee);

        uint32 domain = _getChainDomain(chainId);
        uint256 amountAfterFees = amount - relayerFee;

        // We validated `minAmountOut` is lower than or equal to `amountAfterFees`
        // then we can compute slippage in BPS (e.g. 30 = 0.3%)
        uint256 slippage = 10000 - ((minAmountOut * 10000) / amountAfterFees);

        uint256 preBalance = IERC20(token).balanceOf(address(this));
        ERC20Helpers.approve(token, connext, amount);
        IConnext(connext).xcall(
            domain,
            recipient,
            token,
            address(this), // This is the delegate address, the one that will be able to act in case the bridge fails
            amountAfterFees,
            slippage,
            new bytes(0), // No call on the destination chain needed
            relayerFee
        );

        uint256 postBalance = IERC20(token).balanceOf(address(this));
        bool isPostBalanceUnexpected = postBalance < preBalance - amount;
        if (isPostBalanceUnexpected) revert ConnextBridgeBadPostTokenBalance(postBalance, preBalance, amount);
    }

    /**
     * @dev Tells the chain domain based on a chain ID
     * @param chainId ID of the chain being queried
     * @return Chain domain associated to the requested chain ID
     */
    function _getChainDomain(uint256 chainId) internal pure returns (uint32) {
        if (chainId == ETHEREUM_ID) return ETHEREUM_DOMAIN;
        else if (chainId == POLYGON_ID) return POLYGON_DOMAIN;
        else if (chainId == ARBITRUM_ID) return ARBITRUM_DOMAIN;
        else if (chainId == OPTIMISM_ID) return OPTIMISM_DOMAIN;
        else if (chainId == GNOSIS_ID) return GNOSIS_DOMAIN;
        else if (chainId == BSC_ID) return BSC_DOMAIN;
        else revert ConnextBridgeUnknownChainId(chainId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IConnext {
    function xcall(
        uint32 destination,
        address to,
        address asset,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes calldata callData,
        uint256 relayerFee
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';
import '@mimic-fi/v3-helpers/contracts/utils/IWrappedNativeToken.sol';

import './IHopL2AMM.sol';
import './IHopL1Bridge.sol';
import '../../interfaces/bridge/IHopConnector.sol';

/**
 * @title HopConnector
 * @dev Interfaces with Hop Exchange to bridge tokens
 */
contract HopConnector is IHopConnector {
    using FixedPoint for uint256;
    using Denominations for address;

    // Ethereum mainnet chain ID = 1
    uint256 private constant MAINNET_CHAIN_ID = 1;

    // Goerli chain ID = 5
    uint256 private constant GOERLI_CHAIN_ID = 5;

    // Wrapped native token reference
    address public immutable override wrappedNativeToken;

    /**
     * @dev Initializes the HopConnector contract
     * @param _wrappedNativeToken Address of the wrapped native token
     */
    constructor(address _wrappedNativeToken) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes a bridge of assets using Hop Exchange
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param bridge Address of the bridge component (i.e. hopBridge or hopAMM)
     * @param deadline Deadline to be used when bridging to L2 in order to swap the corresponding hToken
     * @param relayer Only used when transferring from L1 to L2 if a 3rd party is relaying the transfer on the user's behalf
     * @param fee Fee to be sent to the bridge based on the source and destination chain (i.e. relayerFee or bonderFee)
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address bridge,
        uint256 deadline,
        address relayer,
        uint256 fee
    ) external override {
        if (block.chainid == chainId) revert HopBridgeSameChain(chainId);
        if (recipient == address(0)) revert HopBridgeRecipientZero();

        bool toL2 = !_isL1(chainId);
        bool fromL1 = _isL1(block.chainid);
        uint256 preBalance = IERC20(token).balanceOf(address(this));

        if (fromL1 && toL2)
            _bridgeFromL1ToL2(chainId, token, amount, minAmountOut, recipient, bridge, deadline, relayer, fee);
        else if (!fromL1 && toL2) {
            if (relayer != address(0)) revert HopBridgeRelayerNotNeeded();
            _bridgeFromL2ToL2(chainId, token, amount, minAmountOut, recipient, bridge, deadline, fee);
        } else if (!fromL1 && !toL2) {
            if (deadline != 0) revert HopBridgeDeadlineNotNeeded();
            _bridgeFromL2ToL1(chainId, token, amount, minAmountOut, recipient, bridge, fee);
        } else revert HopBridgeOpNotSupported();

        uint256 postBalance = IERC20(token).balanceOf(address(this));
        bool isPostBalanceUnexpected = postBalance < preBalance - amount;
        if (isPostBalanceUnexpected) revert HopBridgeBadPostTokenBalance(postBalance, preBalance, amount);
    }

    /**
     * @dev Bridges assets from L1 to L2
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param hopBridge Address of the Hop bridge corresponding to the token to be bridged
     * @param deadline Deadline to be applied on L2 when swapping the hToken for the token to be bridged
     * @param relayer Only used if a 3rd party is relaying the transfer on the user's behalf
     * @param relayerFee Only used if a 3rd party is relaying the transfer on the user's behalf
     */
    function _bridgeFromL1ToL2(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address hopBridge,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) internal {
        if (deadline <= block.timestamp) revert HopBridgePastDeadline(deadline, block.timestamp);

        uint256 value = _unwrapOrApproveTokens(hopBridge, token, amount);
        IHopL1Bridge(hopBridge).sendToL2{ value: value }(
            chainId,
            recipient,
            amount,
            minAmountOut,
            deadline,
            relayer,
            relayerFee
        );
    }

    /**
     * @dev Bridges assets from L2 to L1
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param hopAMM Address of the Hop AMM corresponding to the token to be bridged
     * @param bonderFee Must be computed using the Hop SDK or API
     */
    function _bridgeFromL2ToL1(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address hopAMM,
        uint256 bonderFee
    ) internal {
        uint256 value = _unwrapOrApproveTokens(hopAMM, token, amount);
        // No destination min amount nor deadline needed since there is no AMM on L1
        IHopL2AMM(hopAMM).swapAndSend{ value: value }(
            chainId,
            recipient,
            amount,
            bonderFee,
            minAmountOut,
            block.timestamp,
            0,
            0
        );
    }

    /**
     * @dev Bridges assets from L2 to L2
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param hopAMM Address of the Hop AMM corresponding to the token to be bridged
     * @param deadline Deadline to be applied on the destination L2 when swapping the hToken for the token to be bridged
     * @param bonderFee Must be computed using the Hop SDK or API
     */
    function _bridgeFromL2ToL2(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address hopAMM,
        uint256 deadline,
        uint256 bonderFee
    ) internal {
        if (deadline <= block.timestamp) revert HopBridgePastDeadline(deadline, block.timestamp);

        uint256 intermediateMinAmountOut = amount - ((amount - minAmountOut) / 2);
        IHopL2AMM(hopAMM).swapAndSend{ value: _unwrapOrApproveTokens(hopAMM, token, amount) }(
            chainId,
            recipient,
            amount,
            bonderFee,
            intermediateMinAmountOut,
            block.timestamp,
            minAmountOut,
            deadline
        );
    }

    /**
     * @dev Unwraps or approves the given amount of tokens depending on the token being bridged
     * @param bridge Address of the bridge component to approve the tokens to
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @return value Value that must be used to perform a bridge op
     */
    function _unwrapOrApproveTokens(address bridge, address token, uint256 amount) internal returns (uint256 value) {
        if (token == wrappedNativeToken) {
            value = amount;
            IWrappedNativeToken(token).withdraw(amount);
        } else {
            value = 0;
            ERC20Helpers.approve(token, bridge, amount);
        }
    }

    /**
     * @dev Tells if a chain ID refers to L1 or not: currently only Ethereum Mainnet or Goerli
     * @param chainId ID of the chain being queried
     */
    function _isL1(uint256 chainId) internal pure returns (bool) {
        return chainId == MAINNET_CHAIN_ID || chainId == GOERLI_CHAIN_ID;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopL1Bridge {
    /**
     * @notice To send funds L1->L2, call the sendToL2 method on the L1 Bridge contract
     * @notice `amountOutMin` and `deadline` should be 0 when no swap is intended at the destination.
     * @notice `amount` is the total amount the user wants to send including the relayer fee
     * @dev Send tokens to a supported layer-2 to mint hToken and optionally swap the hToken in the
     * AMM at the destination.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the relayer at the destination.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     */
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopL2AMM {
    function hToken() external view returns (address);

    function exchangeAddress() external view returns (address);

    /**
     * @notice To send funds L2->L1 or L2->L2, call the swapAndSend method on the L2 AMM Wrapper contract
     * @dev Do not set destinationAmountOutMin and destinationDeadline when sending to L1 because there is no AMM on L1,
     * otherwise the calculated transferId will be invalid and the transfer will be unbondable. These parameters should
     * be set to 0 when sending to L1.
     * @param amount is the amount the user wants to send plus the Bonder fee
     */
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IWormhole {
    function transferTokensWithRelay(
        address token,
        uint256 amount,
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipientWallet
    ) external payable returns (uint64 messageSequence);

    function relayerFee(uint16 chainId, address token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IWormhole.sol';
import '../../interfaces/bridge/IWormholeConnector.sol';

/**
 * @title WormholeConnector
 * @dev Interfaces with Wormhole to bridge tokens through CCTP
 */
contract WormholeConnector is IWormholeConnector {
    // List of Wormhole network IDs
    uint16 private constant ETHEREUM_WORMHOLE_NETWORK_ID = 2;
    uint16 private constant POLYGON_WORMHOLE_NETWORK_ID = 5;
    uint16 private constant ARBITRUM_WORMHOLE_NETWORK_ID = 23;
    uint16 private constant OPTIMISM_WORMHOLE_NETWORK_ID = 24;
    uint16 private constant BSC_WORMHOLE_NETWORK_ID = 4;
    uint16 private constant FANTOM_WORMHOLE_NETWORK_ID = 10;
    uint16 private constant AVALANCHE_WORMHOLE_NETWORK_ID = 6;

    // List of chain IDs supported by Wormhole
    uint256 private constant ETHEREUM_ID = 1;
    uint256 private constant POLYGON_ID = 137;
    uint256 private constant ARBITRUM_ID = 42161;
    uint256 private constant OPTIMISM_ID = 10;
    uint256 private constant BSC_ID = 56;
    uint256 private constant FANTOM_ID = 250;
    uint256 private constant AVALANCHE_ID = 43114;

    // Reference to the Wormhole's CircleRelayer contract of the source chain
    address public immutable override wormholeCircleRelayer;

    /**
     * @dev Creates a new Wormhole connector
     * @param _wormholeCircleRelayer Address of the Wormhole's CircleRelayer contract for the source chain
     */
    constructor(address _wormholeCircleRelayer) {
        wormholeCircleRelayer = _wormholeCircleRelayer;
    }

    /**
     * @dev Executes a bridge of assets using Wormhole's CircleRelayer integration
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain after relayer fees
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amount, uint256 minAmountOut, address recipient)
        external
        override
    {
        if (block.chainid == chainId) revert WormholeBridgeSameChain(chainId);
        if (recipient == address(0)) revert WormholeBridgeRecipientZero();

        uint16 wormholeNetworkId = _getWormholeNetworkId(chainId);
        uint256 relayerFee = IWormhole(wormholeCircleRelayer).relayerFee(wormholeNetworkId, token);
        if (relayerFee > amount) revert WormholeBridgeRelayerFeeGtAmount(relayerFee, amount);

        bool isMinAmountTooBig = minAmountOut > amount - relayerFee;
        if (isMinAmountTooBig) revert WormholeBridgeMinAmountOutTooBig(minAmountOut, amount, relayerFee);

        uint256 preBalance = IERC20(token).balanceOf(address(this));
        ERC20Helpers.approve(token, wormholeCircleRelayer, amount);
        IWormhole(wormholeCircleRelayer).transferTokensWithRelay(
            token,
            amount,
            0, // don't swap to native token
            wormholeNetworkId,
            bytes32(uint256(uint160(recipient)))
        );

        uint256 postBalance = IERC20(token).balanceOf(address(this));
        bool isPostBalanceUnexpected = postBalance < preBalance - amount;
        if (isPostBalanceUnexpected) revert WormholeBridgeBadPostTokenBalance(postBalance, preBalance, amount);
    }

    /**
     * @dev Tells the Wormhole network ID based on a chain ID
     * @param chainId ID of the chain being queried
     * @return Wormhole network ID associated with the requested chain ID
     */
    function _getWormholeNetworkId(uint256 chainId) internal pure returns (uint16) {
        if (chainId == ETHEREUM_ID) return ETHEREUM_WORMHOLE_NETWORK_ID;
        else if (chainId == POLYGON_ID) return POLYGON_WORMHOLE_NETWORK_ID;
        else if (chainId == ARBITRUM_ID) return ARBITRUM_WORMHOLE_NETWORK_ID;
        else if (chainId == OPTIMISM_ID) return OPTIMISM_WORMHOLE_NETWORK_ID;
        else if (chainId == BSC_ID) return BSC_WORMHOLE_NETWORK_ID;
        else if (chainId == FANTOM_ID) return FANTOM_WORMHOLE_NETWORK_ID;
        else if (chainId == AVALANCHE_ID) return AVALANCHE_WORMHOLE_NETWORK_ID;
        else revert WormholeBridgeUnknownChainId(chainId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Axelar connector interface
 */
interface IAxelarConnector {
    /**
     * @dev The recipient address is zero
     */
    error AxelarBridgeRecipientZero();

    /**
     * @dev The source and destination chains are the same
     */
    error AxelarBridgeSameChain(uint256 chainId);

    /**
     * @dev The chain ID is not supported
     */
    error AxelarBridgeUnknownChainId(uint256 chainId);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error AxelarBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Axelar gateway of the source chain
     */
    function axelarGateway() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Axelar
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amount, address recipient) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Connext connector interface
 * @dev Interfaces with Connext to bridge tokens
 */
interface IConnextConnector {
    /**
     * @dev The recipient address is zero
     */
    error ConnextBridgeRecipientZero();

    /**
     * @dev The source and destination chains are the same
     */
    error ConnextBridgeSameChain(uint256 chainId);

    /**
     * @dev The chain ID is not supported
     */
    error ConnextBridgeUnknownChainId(uint256 chainId);

    /**
     * @dev The relayer fee is greater than the amount to be bridged
     */
    error ConnextBridgeRelayerFeeGtAmount(uint256 relayerFee, uint256 amount);

    /**
     * @dev The minimum amount out is greater than the amount to be bridged minus the relayer fee
     */
    error ConnextBridgeMinAmountOutTooBig(uint256 minAmountOut, uint256 amount, uint256 relayerFee);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error ConnextBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Connext contract of the source chain
     */
    function connext() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Connext
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Min amount of tokens to receive on the destination chain after relayer fees and slippage
     * @param recipient Address that will receive the tokens on the destination chain
     * @param relayerFee Fee to be paid to the relayer
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        uint256 relayerFee
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Hop connector interface
 */
interface IHopConnector {
    /**
     * @dev The source and destination chains are the same
     */
    error HopBridgeSameChain(uint256 chainId);

    /**
     * @dev The bridge operation is not supported
     */
    error HopBridgeOpNotSupported();

    /**
     * @dev The recipient address is zero
     */
    error HopBridgeRecipientZero();

    /**
     * @dev The relayer was sent when not needed
     */
    error HopBridgeRelayerNotNeeded();

    /**
     * @dev The deadline was sent when not needed
     */
    error HopBridgeDeadlineNotNeeded();

    /**
     * @dev The deadline is in the past
     */
    error HopBridgePastDeadline(uint256 deadline, uint256 currentTimestamp);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error HopBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the wrapped native token address
     */
    function wrappedNativeToken() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Hop Exchange
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param bridge Address of the bridge component (i.e. hopBridge or hopAMM)
     * @param deadline Deadline to be used when bridging to L2 in order to swap the corresponding hToken
     * @param relayer Only used when transferring from L1 to L2 if a 3rd party is relaying the transfer on the user's behalf
     * @param fee Fee to be sent to the bridge based on the source and destination chain (i.e. relayerFee or bonderFee)
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amount,
        uint256 minAmountOut,
        address recipient,
        address bridge,
        uint256 deadline,
        address relayer,
        uint256 fee
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Wormhole connector interface
 */
interface IWormholeConnector {
    /**
     * @dev The recipient address is zero
     */
    error WormholeBridgeRecipientZero();

    /**
     * @dev The source and destination chains are the same
     */
    error WormholeBridgeSameChain(uint256 chainId);

    /**
     * @dev The chain ID is not supported
     */
    error WormholeBridgeUnknownChainId(uint256 chainId);

    /**
     * @dev The relayer fee is greater than the amount to be bridged
     */
    error WormholeBridgeRelayerFeeGtAmount(uint256 relayerFee, uint256 amount);

    /**
     * @dev The minimum amount out is greater than the amount to be bridged minus the relayer fee
     */
    error WormholeBridgeMinAmountOutTooBig(uint256 minAmountOut, uint256 amount, uint256 relayerFee);

    /**
     * @dev The post token balance is lower than the previous token balance minus the amount bridged
     */
    error WormholeBridgeBadPostTokenBalance(uint256 postBalance, uint256 preBalance, uint256 amount);

    /**
     * @dev Tells the reference to the Wormhole's CircleRelayer contract of the source chain
     */
    function wormholeCircleRelayer() external view returns (address);

    /**
     * @dev Executes a bridge of assets using Wormhole's CircleRelayer integration
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain after relayer fees
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amount, uint256 minAmountOut, address recipient) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Convex connector interface
 */
interface IConvexConnector {
    /**
     * @dev Missing Convex pool for the requested Curve pool
     */
    error ConvexCvxPoolNotFound(address curvePool);

    /**
     * @dev Failed to deposit tokens into the Convex booster
     */
    error ConvexBoosterDepositFailed(uint256 poolId, uint256 amount);

    /**
     * @dev Failed to withdraw tokens from Convex pool
     */
    error ConvexCvxPoolWithdrawFailed(address cvxPool, uint256 amount);

    /**
     * @dev Tells the reference to the Convex booster
     */
    function booster() external view returns (address);

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCurvePool(address cvxPool) external view returns (address);

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCvxPool(address curvePool) external view returns (address);

    /**
     * @dev Claims Convex pool rewards for a Curve pool
     */
    function claim(address cvxPool) external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @dev Deposits Curve pool tokens into Convex
     * @param curvePool Address of the Curve pool to join Convex
     * @param amount Amount of Curve pool tokens to be deposited into Convex
     */
    function join(address curvePool, uint256 amount) external returns (uint256);

    /**
     * @dev Withdraws Curve pool tokens from Convex
     * @param cvxPool Address of the Convex pool to exit from Convex
     * @param amount Amount of Convex tokens to be withdrawn
     */
    function exit(address cvxPool, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Curve 2CRV connector interface
 */
interface ICurve2CrvConnector {
    /**
     * @dev Failed to find the token in the 2CRV pool
     */
    error Curve2CrvTokenNotFound(address pool, address token);

    /**
     * @dev Token decimals exceed 18
     */
    error Curve2CrvTokenDecimalsAbove18(address token, uint256 decimals);

    /**
     * @dev The slippage is above one
     */
    error Curve2CrvSlippageAboveOne(uint256 slippage);

    /**
     * @dev Adds liquidity to the 2CRV pool
     * @param pool Address of the 2CRV pool to join
     * @param tokenIn Address of the token to join the 2CRV pool
     * @param amountIn Amount of tokens to join the 2CRV pool
     * @param slippage Slippage value to be used to compute the desired min amount out of pool tokens
     */
    function join(address pool, address tokenIn, uint256 amountIn, uint256 slippage) external returns (uint256);

    /**
     * @dev Removes liquidity from 2CRV pool
     * @param pool Address of the 2CRV pool to exit
     * @param amountIn Amount of pool tokens to exit from the 2CRV pool
     * @param tokenOut Address of the token to exit the pool
     * @param slippage Slippage value to be used to compute the desired min amount out of tokens
     */
    function exit(address pool, uint256 amountIn, address tokenOut, uint256 slippage)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Morpho Aave V2 connector interface
 */
interface IMorphoAaveV2Connector {
    /**
     * @dev The amount supplied is lower than the expected amount
     */
    error MorphoAaveV2InvalidSupply(uint256 actual, uint256 expected);

    /**
     * @dev The withdraw amount is lower than the expected amount
     */
    error MorphoAaveV2InvalidWithdraw(uint256 actual, uint256 expected);

    /**
     * @dev Tells the reference to the MorphoAaveV2 proxy
     */
    function morpho() external view returns (address);

    /**
     * @dev Tells the reference to Morpho's lens
     */
    function lens() external view returns (address);

    /**
     * @dev Tells the reference to the Morpho's rewards distributor
     */
    function rewardsDistributor() external view returns (address);

    /**
     * @dev Finds the aToken address associated to a token
     * @param token Address of the token querying the aToken for
     */
    function getAToken(address token) external view returns (address);

    /**
     * @dev Tells the supply balance for an aToken
     * @param aToken Address of the aToken querying the supply balance of
     */
    function getSupplyBalance(address aToken) external view returns (uint256);

    /**
     * @dev Supplies tokens to the Aave protocol using Morpho
     * @param token Address of the token to supply
     * @param amount Amount of tokens to supply
     */
    function join(address token, uint256 amount) external returns (uint256);

    /**
     * @dev Withdraws tokens from Morpho's supply balance
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function exit(address token, uint256 amount) external returns (uint256);

    /**
     * @dev Claims Morpho token rewards
     * @param amount Amount of Morpho tokens to claim
     * @param proof Merkle proof of the rewards
     */
    function claim(uint256 amount, bytes32[] calldata proof)
        external
        returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Morpho Aave V3 connector interface
 */
interface IMorphoAaveV3Connector {
    /**
     * @dev The amount supplied is lower than the expected amount
     */
    error MorphoAaveV3InvalidSupply(uint256 actual, uint256 expected);

    /**
     * @dev The withdraw amount is lower than the expected amount
     */
    error MorphoAaveV3InvalidWithdraw(uint256 actual, uint256 expected);

    /**
     * @dev Tells the reference to the MorphoAaveV3 proxy
     */
    function morpho() external view returns (address);

    /**
     * @dev Tells the reference to the Morpho's rewards distributor
     */
    function rewardsDistributor() external view returns (address);

    /**
     * @dev Supplies tokens to the Aave protocol using Morpho
     * @param token Address of the token to supply
     * @param amount Amount of tokens to supply
     * @param maxIterations Maximum number of iterations allowed during the matching process. Using 4 is recommended by Morpho.
     */
    function join(address token, uint256 amount, uint256 maxIterations) external returns (uint256);

    /**
     * @dev Withdraws tokens from Morpho's supply balance
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     * @param maxIterations Maximum number of iterations allowed during the matching process. If it is less than the default, the latter will be used. Pass 0 to fallback to the default.
     */
    function exit(address token, uint256 amount, uint256 maxIterations) external returns (uint256);

    /**
     * @dev Claims Morpho token rewards
     * @param amount Amount of Morpho tokens to claim
     * @param proof Merkle proof
     */
    function claim(uint256 amount, bytes32[] calldata proof)
        external
        returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Hop swap connector interface
 */
interface IHopSwapConnector {
    /**
     * @dev The dex address is zero
     */
    error HopDexAddressZero();

    /**
     * @dev The token in is the same as the token out
     */
    error HopSwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error HopBadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the pre token in balance minus the amount in
     */
    error HopBadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Executes a token swap in Hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopDexAddress Address of the Hop dex to be used
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address hopDexAddress)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title 1inch V5 connector interface
 */
interface IOneInchV5Connector {
    /**
     * @dev The token in is the same as the token out
     */
    error OneInchV5SwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error OneInchV5BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error OneInchV5BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to 1inch aggregation router v5
     */
    function oneInchV5Router() external view returns (address);

    /**
     * @dev Executes a token swap in 1Inch V5
     * @param tokenIn Token to be sent
     * @param tokenOut Token to be received
     * @param amountIn Amount of token in to be swapped
     * @param minAmountOut Minimum amount of token out willing to receive
     * @param data Calldata to be sent to the 1inch aggregation router
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Paraswap V5 connector interface
 */
interface IParaswapV5Connector {
    /**
     * @dev The token in is the same as the token out
     */
    error ParaswapV5SwapSameToken(address token);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error ParaswapV5BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error ParaswapV5BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to Paraswap V5 Augustus swapper
     */
    function paraswapV5Augustus() external view returns (address);

    /**
     * @dev Executes a token swap in Paraswap V5
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param data Calldata to be sent to the Augusuts swapper
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Uniswap V2 connector interface
 */
interface IUniswapV2Connector {
    /**
     * @dev The token in is the same as the token out
     */
    error UniswapV2SwapSameToken(address token);

    /**
     * @dev The pool does not exist
     */
    error UniswapV2InvalidPool(address tokenA, address tokenB);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error UniswapV2BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error UniswapV2BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to UniswapV2 router
     */
    function uniswapV2Router() external view returns (address);

    /**
     * @dev Executes a token swap in Uniswap V2
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

/**
 * @title Uniswap V3 connector interface
 */
interface IUniswapV3Connector {
    /**
     * @dev The input length mismatch
     */
    error UniswapV3InputLengthMismatch();

    /**
     * @dev The token in is the same as the token out
     */
    error UniswapV3SwapSameToken(address token);

    /**
     * @dev A pool with the given tokens and fee does not exist
     */
    error UniswapV3InvalidPoolFee(address token0, address token1, uint24 fee);

    /**
     * @dev The amount out is lower than the minimum amount out
     */
    error UniswapV3BadAmountOut(uint256 amountOut, uint256 minAmountOut);

    /**
     * @dev The post token in balance is lower than the previous token in balance minus the amount in
     */
    error UniswapV3BadPostTokenInBalance(uint256 postBalanceIn, uint256 preBalanceIn, uint256 amountIn);

    /**
     * @dev Tells the reference to UniswapV3 router
     */
    function uniswapV3Router() external view returns (address);

    /**
     * @dev Executes a token swap in Uniswap V3
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param fee Fee to be used
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     * @param hopFees Optional list of hop-fees between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './ICvxPool.sol';
import './ICvxBooster.sol';
import '../../interfaces/liquidity/convex/IConvexConnector.sol';

/**
 * @title ConvexConnector
 */
contract ConvexConnector is IConvexConnector {
    using FixedPoint for uint256;

    // Convex booster
    address public immutable override booster;

    /**
     * @dev Creates a new Convex connector
     */
    constructor(address _booster) {
        booster = _booster;
    }

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCurvePool(address cvxPool) public view override returns (address) {
        uint256 poolId = ICvxPool(cvxPool).convexPoolId();
        (address pool, , , , ) = ICvxBooster(booster).poolInfo(poolId);
        return pool;
    }

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCvxPool(address curvePool) public view override returns (address) {
        (, ICvxPool pool) = _findCvxPoolInfo(curvePool);
        return address(pool);
    }

    /**
     * @dev Claims Convex pool rewards for a Curve pool
     */
    function claim(address cvxPool) external override returns (address[] memory tokens, uint256[] memory amounts) {
        IERC20 crv = IERC20(ICvxPool(cvxPool).crv());

        uint256 initialCrvBalance = crv.balanceOf(address(this));
        ICvxPool(cvxPool).getReward(address(this));
        uint256 finalCrvBalance = crv.balanceOf(address(this));

        amounts = new uint256[](1);
        amounts[0] = finalCrvBalance - initialCrvBalance;

        tokens = new address[](1);
        tokens[0] = address(crv);
    }

    /**
     * @dev Deposits Curve pool tokens into Convex
     * @param curvePool Address of the Curve pool to join Convex
     * @param amount Amount of Curve pool tokens to be deposited into Convex
     */
    function join(address curvePool, uint256 amount) external override returns (uint256) {
        if (amount == 0) return 0;
        (uint256 poolId, ICvxPool cvxPool) = _findCvxPoolInfo(curvePool);

        uint256 initialCvxPoolTokenBalance = cvxPool.balanceOf(address(this));
        ERC20Helpers.approve(curvePool, booster, amount);
        if (!ICvxBooster(booster).deposit(poolId, amount)) revert ConvexBoosterDepositFailed(poolId, amount);

        uint256 finalCvxPoolTokenBalance = cvxPool.balanceOf(address(this));
        return finalCvxPoolTokenBalance - initialCvxPoolTokenBalance;
    }

    /**
     * @dev Withdraws Curve pool tokens from Convex
     * @param cvxPool Address of the Convex pool to exit from Convex
     * @param amount Amount of Convex tokens to be withdrawn
     */
    function exit(address cvxPool, uint256 amount) external override returns (uint256) {
        if (amount == 0) return 0;
        address curvePool = getCurvePool(cvxPool);

        uint256 initialPoolTokenBalance = IERC20(curvePool).balanceOf(address(this));
        if (!ICvxPool(cvxPool).withdraw(amount, true)) revert ConvexCvxPoolWithdrawFailed(cvxPool, amount);

        uint256 finalPoolTokenBalance = IERC20(curvePool).balanceOf(address(this));
        return finalPoolTokenBalance - initialPoolTokenBalance;
    }

    /**
     * @dev Finds the Convex pool information associated to the given Curve pool
     */
    function _findCvxPoolInfo(address curvePool) internal view returns (uint256 poolId, ICvxPool cvxPool) {
        for (uint256 i = 0; i < ICvxBooster(booster).poolLength(); i++) {
            (address lp, , address rewards, bool shutdown, ) = ICvxBooster(booster).poolInfo(i);
            if (lp == curvePool && !shutdown) {
                return (i, ICvxPool(rewards));
            }
        }
        revert ConvexCvxPoolNotFound(curvePool);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface ICvxBooster {
    function poolLength() external view returns (uint256);

    function poolInfo(uint256 i)
        external
        view
        returns (address lpToken, address gauge, address rewards, bool shutdown, address factory);

    function deposit(uint256 pid, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICvxPool is IERC20 {
    function crv() external view returns (address);

    function convexPoolId() external view returns (uint256);

    function getReward(address account) external;

    function withdraw(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './I2CrvPool.sol';
import '../../interfaces/liquidity/curve/ICurve2CrvConnector.sol';

/**
 * @title Curve2CrvConnector
 */
contract Curve2CrvConnector is ICurve2CrvConnector {
    using FixedPoint for uint256;

    /**
     * @dev Adds liquidity to the 2CRV pool
     * @param pool Address of the 2CRV pool to join
     * @param tokenIn Address of the token to join the 2CRV pool
     * @param amountIn Amount of tokens to join the 2CRV pool
     * @param slippage Slippage value to be used to compute the desired min amount out of pool tokens
     */
    function join(address pool, address tokenIn, uint256 amountIn, uint256 slippage)
        external
        override
        returns (uint256)
    {
        if (amountIn == 0) return 0;
        if (slippage > FixedPoint.ONE) revert Curve2CrvSlippageAboveOne(slippage);
        (uint256 tokenIndex, uint256 tokenScale) = _findTokenInfo(pool, tokenIn);

        // Compute min amount out
        uint256 expectedAmountOut = (amountIn * tokenScale).divUp(I2CrvPool(pool).get_virtual_price());
        uint256 minAmountOut = expectedAmountOut.mulUp(FixedPoint.ONE - slippage);

        // Join pool
        uint256 initialPoolTokenBalance = I2CrvPool(pool).balanceOf(address(this));
        ERC20Helpers.approve(tokenIn, address(pool), amountIn);
        uint256[2] memory amounts;
        amounts[tokenIndex] = amountIn;
        I2CrvPool(pool).add_liquidity(amounts, minAmountOut);
        uint256 finalPoolTokenBalance = I2CrvPool(pool).balanceOf(address(this));
        return finalPoolTokenBalance - initialPoolTokenBalance;
    }

    /**
     * @dev Removes liquidity from 2CRV pool
     * @param pool Address of the 2CRV pool to exit
     * @param amountIn Amount of pool tokens to exit from the 2CRV pool
     * @param tokenOut Address of the token to exit the pool
     * @param slippage Slippage value to be used to compute the desired min amount out of tokens
     */
    function exit(address pool, uint256 amountIn, address tokenOut, uint256 slippage)
        external
        override
        returns (uint256 amountOut)
    {
        if (amountIn == 0) return 0;
        if (slippage > FixedPoint.ONE) revert Curve2CrvSlippageAboveOne(slippage);
        (uint256 tokenIndex, uint256 tokenScale) = _findTokenInfo(pool, tokenOut);

        // Compute min amount out
        uint256 expectedAmountOut = amountIn.mulUp(I2CrvPool(pool).get_virtual_price()) / tokenScale;
        uint256 minAmountOut = expectedAmountOut.mulUp(FixedPoint.ONE - slippage);

        // Exit pool
        uint256 initialTokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        I2CrvPool(pool).remove_liquidity_one_coin(amountIn, int128(int256(tokenIndex)), minAmountOut);
        uint256 finalTokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        return finalTokenOutBalance - initialTokenOutBalance;
    }

    /**
     * @dev Finds the index and scale factor of a token in the 2CRV pool
     */
    function _findTokenInfo(address pool, address token) internal view returns (uint256 index, uint256 scale) {
        for (uint256 i = 0; true; i++) {
            try I2CrvPool(pool).coins(i) returns (address coin) {
                if (token == coin) {
                    uint256 decimals = IERC20Metadata(token).decimals();
                    if (decimals > 18) revert Curve2CrvTokenDecimalsAbove18(token, decimals);
                    return (i, 10**(18 - decimals));
                }
            } catch {
                revert Curve2CrvTokenNotFound(pool, token);
            }
        }
        revert Curve2CrvTokenNotFound(pool, token);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// solhint-disable func-name-mixedcase

interface I2CrvPool is IERC20 {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256 index) external view returns (address);

    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    function add_liquidity(uint256[2] memory amountsIn, uint256 minAmountOut) external returns (uint256);

    function remove_liquidity_one_coin(uint256 amountIn, int128 index, uint256 minAmountOut) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface ILendingPool {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }

    function getReserveData(address asset) external view returns (ReserveData memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface ILens {
    function getCurrentSupplyBalanceInOf(address aToken, address user)
        external
        view
        returns (uint256 balanceInP2P, uint256 balanceOnPool, uint256 totalBalance);

    function morpho() external view returns (address);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IMorphoV2 {
    function supply(address poolToken, uint256 amount) external;

    function withdraw(address poolToken, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface IRewardsDistributor {
    function MORPHO() external returns (ERC20);

    function claim(address account, uint256 claimable, bytes32[] calldata proof) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './ILendingPool.sol';
import './ILens.sol';
import './IMorphoV2.sol';
import './IRewardsDistributor.sol';
import '../../interfaces/liquidity/morpho/IMorphoAaveV2Connector.sol';

/**
 * @title MorphoAaveV2Connector
 * @dev Interfaces with Morpho Aave v2 to lend tokens
 */
contract MorphoAaveV2Connector is IMorphoAaveV2Connector {
    // Reference to MorphoAaveV2 proxy
    address public immutable override morpho;

    // Reference to Morpho's lens
    address public immutable override lens;

    // Reference to Morpho's rewards distributor
    address public immutable override rewardsDistributor;

    /**
     * @dev Creates a new MorphoAaveV2 connector
     */
    constructor(address _lens, address _rewardsDistributor) {
        morpho = ILens(_lens).morpho();
        lens = _lens;
        rewardsDistributor = _rewardsDistributor;
    }

    /**
     * @dev Finds the aToken address associated to a token
     * @param token Address of the token querying the aToken of
     */
    function getAToken(address token) public view override returns (address) {
        address lendingPool = ILens(lens).pool();
        return ILendingPool(lendingPool).getReserveData(token).aTokenAddress;
    }

    /**
     * @dev Tells the supply balance for an aToken
     * @param aToken Address of the aToken querying the supply balance of
     */
    function getSupplyBalance(address aToken) public view override returns (uint256 supplyBalance) {
        (, , supplyBalance) = ILens(lens).getCurrentSupplyBalanceInOf(aToken, address(this));
    }

    /**
     * @dev Supplies tokens to the Aave protocol using Morpho
     * @param token Address of the token to supply
     * @param amount Amount of tokens to supply
     */
    function join(address token, uint256 amount) external override returns (uint256 supplied) {
        if (amount == 0) return 0;
        address aToken = getAToken(token);

        uint256 initialSupplyBalance = getSupplyBalance(aToken);
        ERC20Helpers.approve(token, morpho, amount);
        IMorphoV2(morpho).supply(getAToken(token), amount);

        uint256 finalSupplyBalance = getSupplyBalance(aToken);
        supplied = finalSupplyBalance - initialSupplyBalance;
        if (supplied < amount) revert MorphoAaveV2InvalidSupply(supplied, amount);
    }

    /**
     * @dev Withdraws tokens from Morpho's supply balance
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function exit(address token, uint256 amount) external override returns (uint256 withdrawn) {
        if (amount == 0) return 0;

        uint256 initialTokenBalance = IERC20(token).balanceOf(address(this));
        IMorphoV2(morpho).withdraw(getAToken(token), amount);

        uint256 finalTokenBalance = IERC20(token).balanceOf(address(this));
        withdrawn = finalTokenBalance - initialTokenBalance;
        if (withdrawn < amount) revert MorphoAaveV2InvalidWithdraw(withdrawn, amount);
    }

    /**
     * @dev Claims Morpho token rewards
     * @param amount Amount of Morpho tokens to claim
     * @param proof Merkle proof of the rewards
     */
    function claim(uint256 amount, bytes32[] calldata proof)
        external
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        IRewardsDistributor distributor = IRewardsDistributor(rewardsDistributor);
        IERC20 morphoToken = distributor.MORPHO();
        tokens = new address[](1);
        tokens[0] = address(morphoToken);

        amounts = new uint256[](1);
        if (amount == 0) return (tokens, amounts);

        uint256 initialMorphoBalance = morphoToken.balanceOf(address(this));
        distributor.claim(address(this), amount, proof);
        uint256 finalMorphoBalance = morphoToken.balanceOf(address(this));
        amounts[0] = finalMorphoBalance - initialMorphoBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IMorphoV3 {
    function supplyBalance(address underlying, address user) external view returns (uint256);

    function supply(address underlying, uint256 amount, address onBehalf, uint256 maxIterations)
        external
        returns (uint256);

    function withdraw(address underlying, uint256 amount, address onBehalf, address receiver, uint256 maxIterations)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IMorphoV3.sol';
import '../morpho-v2/IRewardsDistributor.sol';
import '../../interfaces/liquidity/morpho/IMorphoAaveV3Connector.sol';

/**
 * @title MorphoAaveV3Connector
 * @dev Interfaces with Morpho Aave v3 to lend tokens
 */
contract MorphoAaveV3Connector is IMorphoAaveV3Connector {
    // Reference to MorphoAaveV3 proxy
    address public immutable override morpho;

    // Reference to Morpho's rewards distributor
    address public immutable override rewardsDistributor;

    /**
     * @dev Creates a new MorphoAaveV3 connector
     */
    constructor(address _morpho, address _rewardsDistributor) {
        morpho = _morpho;
        rewardsDistributor = _rewardsDistributor;
    }

    /**
     * @dev Supplies tokens to the Aave protocol using Morpho
     * @param token Address of the token to supply
     * @param amount Amount of tokens to supply
     * @param maxIterations Maximum number of iterations allowed during the matching process. Using 4 is recommended by Morpho.
     */
    function join(address token, uint256 amount, uint256 maxIterations) external override returns (uint256 supplied) {
        if (amount == 0) return 0;
        ERC20Helpers.approve(token, morpho, amount);
        supplied = IMorphoV3(morpho).supply(token, amount, address(this), maxIterations);
        if (supplied < amount) revert MorphoAaveV3InvalidSupply(supplied, amount);
    }

    /**
     * @dev Withdraws tokens from Morpho's supply balance
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     * @param maxIterations Maximum number of iterations allowed during the matching process.
     *  If it is less than the default, the latter will be used. Pass 0 to fallback to the default.
     */
    function exit(address token, uint256 amount, uint256 maxIterations) external override returns (uint256 withdrawn) {
        if (amount == 0) return 0;
        withdrawn = IMorphoV3(morpho).withdraw(token, amount, address(this), address(this), maxIterations);
        if (withdrawn < amount) revert MorphoAaveV3InvalidWithdraw(withdrawn, amount);
    }

    /**
     * @dev Claims Morpho token rewards
     * @param amount Amount of Morpho tokens to claim
     * @param proof Merkle proof
     */
    function claim(uint256 amount, bytes32[] calldata proof)
        external
        override
        returns (address[] memory tokens, uint256[] memory amounts)
    {
        IRewardsDistributor distributor = IRewardsDistributor(rewardsDistributor);
        IERC20 morphoToken = distributor.MORPHO();
        tokens = new address[](1);
        tokens[0] = address(morphoToken);

        amounts = new uint256[](1);
        if (amount == 0) return (tokens, amounts);

        uint256 initialMorphoBalance = morphoToken.balanceOf(address(this));
        distributor.claim(address(this), amount, proof);
        uint256 finalMorphoBalance = morphoToken.balanceOf(address(this));
        amounts[0] = finalMorphoBalance - initialMorphoBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import '../../interfaces/swap/IOneInchV5Connector.sol';

/**
 * @title OneInchV5Connector
 * @dev Interfaces with 1inch V5 to swap tokens
 */
contract OneInchV5Connector is IOneInchV5Connector {
    // Reference to 1inch aggregation router v5
    address public immutable override oneInchV5Router;

    /**
     * @dev Creates a new OneInchV5Connector contract
     * @param _oneInchV5Router 1inch aggregation router v5 reference
     */
    constructor(address _oneInchV5Router) {
        oneInchV5Router = _oneInchV5Router;
    }

    /**
     * @dev Executes a token swap in 1Inch V5
     * @param tokenIn Token to be sent
     * @param tokenOut Token to be received
     * @param amountIn Amount of token in to be swapped
     * @param minAmountOut Minimum amount of token out willing to receive
     * @param data Calldata to be sent to the 1inch aggregation router
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        override
        returns (uint256 amountOut)
    {
        if (tokenIn == tokenOut) revert OneInchV5SwapSameToken(tokenIn);

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        ERC20Helpers.approve(tokenIn, oneInchV5Router, amountIn);
        Address.functionCall(oneInchV5Router, data, '1INCH_V5_SWAP_FAILED');

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        bool isPostBalanceInUnexpected = postBalanceIn < preBalanceIn - amountIn;
        if (isPostBalanceInUnexpected) revert OneInchV5BadPostTokenInBalance(postBalanceIn, preBalanceIn, amountIn);

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        if (amountOut < minAmountOut) revert OneInchV5BadAmountOut(amountOut, minAmountOut);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IHopDex.sol';
import '../../interfaces/swap/IHopSwapConnector.sol';

/**
 * @title HopSwapConnector
 * @dev Interfaces with Hop to swap tokens
 */
contract HopSwapConnector is IHopSwapConnector {
    /**
     * @dev Executes a token swap in Hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopDexAddress Address of the Hop dex to be used
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address hopDexAddress)
        external
        override
        returns (uint256 amountOut)
    {
        if (tokenIn == tokenOut) revert HopSwapSameToken(tokenIn);
        if (hopDexAddress == address(0)) revert HopDexAddressZero();

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        IHopDex hopDex = IHopDex(hopDexAddress);
        uint8 tokenInIndex = hopDex.getTokenIndex(tokenIn);
        uint8 tokenOutIndex = hopDex.getTokenIndex(tokenOut);

        ERC20Helpers.approve(tokenIn, hopDexAddress, amountIn);
        hopDex.swap(tokenInIndex, tokenOutIndex, amountIn, minAmountOut, block.timestamp);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        bool isPostBalanceInUnexpected = postBalanceIn < preBalanceIn - amountIn;
        if (isPostBalanceInUnexpected) revert HopBadPostTokenInBalance(postBalanceIn, preBalanceIn, amountIn);

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        if (amountOut < minAmountOut) revert HopBadAmountOut(amountOut, minAmountOut);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopDex {
    function getTokenIndex(address) external view returns (uint8);

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopL2Amm {
    function hToken() external view returns (address);

    function exchangeAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IParaswapV5Augustus {
    function getTokenTransferProxy() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IParaswapV5Augustus.sol';
import '../../interfaces/swap/IParaswapV5Connector.sol';

/**
 * @title ParaswapV5Connector
 * @dev Interfaces with Paraswap V5 to swap tokens
 */
contract ParaswapV5Connector is IParaswapV5Connector {
    // Reference to Paraswap V5 Augustus swapper
    address public immutable override paraswapV5Augustus;

    /**
     * @dev Creates a new ParaswapV5Connector contract
     * @param _paraswapV5Augustus Paraswap V5 augusts reference
     */
    constructor(address _paraswapV5Augustus) {
        paraswapV5Augustus = _paraswapV5Augustus;
    }

    /**
     * @dev Executes a token swap in Paraswap V5
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param data Calldata to be sent to the Augusuts swapper
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut)
    {
        if (tokenIn == tokenOut) revert ParaswapV5SwapSameToken(tokenIn);

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        address tokenTransferProxy = IParaswapV5Augustus(paraswapV5Augustus).getTokenTransferProxy();
        ERC20Helpers.approve(tokenIn, tokenTransferProxy, amountIn);
        Address.functionCall(paraswapV5Augustus, data, 'PARASWAP_V5_SWAP_FAILED');

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        bool isPostBalanceInUnexpected = postBalanceIn < preBalanceIn - amountIn;
        if (isPostBalanceInUnexpected) revert ParaswapV5BadPostTokenInBalance(postBalanceIn, preBalanceIn, amountIn);

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        if (amountOut < minAmountOut) revert ParaswapV5BadAmountOut(amountOut, minAmountOut);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/Arrays.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';
import '../../interfaces/swap/IUniswapV2Connector.sol';

/**
 * @title UniswapV2Connector
 * @dev Interfaces with Uniswap V2 to swap tokens
 */
contract UniswapV2Connector is IUniswapV2Connector {
    // Reference to UniswapV2 router
    address public immutable override uniswapV2Router;

    /**
     * @dev Initializes the UniswapV2Connector contract
     * @param _uniswapV2Router Uniswap V2 router reference
     */
    constructor(address _uniswapV2Router) {
        uniswapV2Router = _uniswapV2Router;
    }

    /**
     * @dev Executes a token swap in Uniswap V2
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) external returns (uint256 amountOut) {
        if (tokenIn == tokenOut) revert UniswapV2SwapSameToken(tokenIn);

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        ERC20Helpers.approve(tokenIn, uniswapV2Router, amountIn);
        hopTokens.length == 0
            ? _singleSwap(tokenIn, tokenOut, amountIn, minAmountOut)
            : _batchSwap(tokenIn, tokenOut, amountIn, minAmountOut, hopTokens);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        bool isPostBalanceInUnexpected = postBalanceIn < preBalanceIn - amountIn;
        if (isPostBalanceInUnexpected) revert UniswapV2BadPostTokenInBalance(postBalanceIn, preBalanceIn, amountIn);

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        if (amountOut < minAmountOut) revert UniswapV2BadAmountOut(amountOut, minAmountOut);
    }

    /**
     * @dev Swap two tokens through UniswapV2 using a single hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     */
    function _singleSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut)
        internal
        returns (uint256[] memory)
    {
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);
        address factory = router.factory();
        address[] memory tokens = Arrays.from(tokenIn, tokenOut);
        _validatePool(factory, tokenIn, tokenOut);
        return router.swapExactTokensForTokens(amountIn, minAmountOut, tokens, address(this), block.timestamp);
    }

    /**
     * @dev Swap two tokens through UniswapV2 using a multi hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of the first token in the path to be swapped
     * @param minAmountOut Minimum amount of the last token in the path willing to receive
     * @param hopTokens List of hop-tokens between tokenIn and tokenOut
     */
    function _batchSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) internal returns (uint256[] memory) {
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapV2Router);
        address factory = router.factory();
        address[] memory tokens = Arrays.from(tokenIn, hopTokens, tokenOut);
        for (uint256 i = 0; i < tokens.length - 1; i++) _validatePool(factory, tokens[i], tokens[i + 1]);
        return router.swapExactTokensForTokens(amountIn, minAmountOut, tokens, address(this), block.timestamp);
    }

    /**
     * @dev Validates that there is a pool created for tokenA and tokenB
     * @param factory UniswapV2 factory to check against
     * @param tokenA First token of the pair
     * @param tokenB Second token of the pair
     */
    function _validatePool(address factory, address tokenA, address tokenB) private view {
        address pool = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pool == address(0)) revert UniswapV2InvalidPool(tokenA, tokenB);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IUniswapV3PeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.5;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v3-helpers/contracts/utils/Arrays.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IUniswapV3Factory.sol';
import './IUniswapV3SwapRouter.sol';
import './IUniswapV3PeripheryImmutableState.sol';
import '../../interfaces/swap/IUniswapV3Connector.sol';

/**
 * @title UniswapV3Connector
 * @dev Interfaces with Uniswap V3 to swap tokens
 */
contract UniswapV3Connector is IUniswapV3Connector {
    using BytesHelpers for bytes;

    // Reference to UniswapV3 router
    address public immutable override uniswapV3Router;

    /**
     * @dev Initializes the UniswapV3Connector contract
     * @param _uniswapV3Router Uniswap V3 router reference
     */
    constructor(address _uniswapV3Router) {
        uniswapV3Router = _uniswapV3Router;
    }

    /**
     * @dev Executes a token swap in Uniswap V3
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param fee Fee to be used
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     * @param hopFees Optional list of hop-fees between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external returns (uint256 amountOut) {
        if (tokenIn == tokenOut) revert UniswapV3SwapSameToken(tokenIn);
        if (hopTokens.length != hopFees.length) revert UniswapV3InputLengthMismatch();

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        ERC20Helpers.approve(tokenIn, uniswapV3Router, amountIn);
        hopTokens.length == 0
            ? _singleSwap(tokenIn, tokenOut, amountIn, minAmountOut, fee)
            : _batchSwap(tokenIn, tokenOut, amountIn, minAmountOut, fee, hopTokens, hopFees);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        bool isPostBalanceInUnexpected = postBalanceIn < preBalanceIn - amountIn;
        if (isPostBalanceInUnexpected) revert UniswapV3BadPostTokenInBalance(postBalanceIn, preBalanceIn, amountIn);

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        if (amountOut < minAmountOut) revert UniswapV3BadAmountOut(amountOut, minAmountOut);
    }

    /**
     * @dev Swap two tokens through UniswapV3 using a single hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param fee Fee to be used
     */
    function _singleSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint24 fee)
        internal
        returns (uint256 amountOut)
    {
        _validatePool(_uniswapV3Factory(), tokenIn, tokenOut, fee);

        IUniswapV3SwapRouter.ExactInputSingleParams memory input;
        input.tokenIn = tokenIn;
        input.tokenOut = tokenOut;
        input.fee = fee;
        input.recipient = address(this);
        input.deadline = block.timestamp;
        input.amountIn = amountIn;
        input.amountOutMinimum = minAmountOut;
        input.sqrtPriceLimitX96 = 0;
        return IUniswapV3SwapRouter(uniswapV3Router).exactInputSingle(input);
    }

    /**
     * @dev Swap two tokens through UniswapV3 using a multi hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of the first token in the path to be swapped
     * @param minAmountOut Minimum amount of the last token in the path willing to receive
     * @param fee Fee to be used
     * @param hopTokens List of hop-tokens between tokenIn and tokenOut
     * @param hopFees List of hop-fees between tokenIn and tokenOut
     */
    function _batchSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) internal returns (uint256 amountOut) {
        address factory = _uniswapV3Factory();
        address[] memory tokens = Arrays.from(tokenIn, hopTokens, tokenOut);
        uint24[] memory fees = Arrays.from(fee, hopFees);

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < fees.length; i++) {
            _validatePool(factory, tokens[i], tokens[i + 1], fees[i]);
        }

        IUniswapV3SwapRouter.ExactInputParams memory input;
        input.path = _encodePoolPath(tokens, fees);
        input.amountIn = amountIn;
        input.amountOutMinimum = minAmountOut;
        input.recipient = address(this);
        input.deadline = block.timestamp;
        return IUniswapV3SwapRouter(uniswapV3Router).exactInput(input);
    }

    /**
     * @dev Tells the Uniswap V3 factory contract address
     * @return Address of the Uniswap V3 factory contract
     */
    function _uniswapV3Factory() internal view returns (address) {
        return IUniswapV3PeripheryImmutableState(uniswapV3Router).factory();
    }

    /**
     * @dev Validates that there is a pool created for tokenA and tokenB with a requested fee
     * @param factory UniswapV3 factory to check against
     * @param tokenA One of the tokens in the pool
     * @param tokenB The other token in the pool
     * @param fee Fee used by the pool
     */
    function _validatePool(address factory, address tokenA, address tokenB, uint24 fee) internal view {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        address pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);
        if (pool == address(0)) revert UniswapV3InvalidPoolFee(token0, token1, fee);
    }

    /**
     * @dev Encodes a path of tokens with their corresponding fees
     * @param tokens List of tokens to be encoded
     * @param fees List of fees to use for each token pair
     */
    function _encodePoolPath(address[] memory tokens, uint24[] memory fees) internal pure returns (bytes memory path) {
        path = new bytes(0);
        for (uint256 i = 0; i < fees.length; i++) path = path.concat(tokens[i]).concat(fees[i]);
        path = path.concat(tokens[fees.length]);
    }
}
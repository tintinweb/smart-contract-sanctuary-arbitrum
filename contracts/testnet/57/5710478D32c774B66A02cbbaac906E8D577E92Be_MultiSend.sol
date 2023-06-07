// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "oz-custom/contracts/oz/access/Ownable.sol";
import {IERC20, ERC20} from "oz-custom/contracts/oz/token/ERC20/ERC20.sol";

interface IMultiSend {
    event Sent(address, uint256[], bytes[]);
}

contract MultiSend is IMultiSend, Ownable{
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function multiSend(address[] calldata to_, uint256 amount) public payable onlyOwner returns (uint256[] memory success, bytes[] memory results) {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        uint256 length = to_.length;
        results = new bytes[](length);
        success = new uint256[](length);
        address account;
        bool ok;
        for (uint256 i; i < length; ) {
            account = to_[i];

            (ok, results[i]) = account.call{value: amount}("");

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }
        emit Sent(msg.sender, success, results);
    }

    function multiSendERC20(
        ERC20 token_,
        address[] calldata accounts_,
        uint256 amount_
    )
        public
        onlyOwner
        returns (uint256[] memory success, bytes[] memory results)
    {
        uint256 length = accounts_.length;
        results = new bytes[](length);
        success = new uint256[](length);

        bytes memory callData = abi.encodeCall(
            IERC20.transfer,
            (address(0), amount_)
        );

        address _payment = address(token_);
        bool ok;
        address account;
        for (uint256 i; i < length; ) {
            account = accounts_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, results[i]) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Sent(_msgSender(), success, results);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(
        bytes32 bytesValue
    ) internal pure returns (address addr) {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(
        address addressValue
    ) internal pure returns (bytes32 value) {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.17;

import {Context} from "../utils/Context.sol";
import {Bytes32Address} from "../../libraries/Bytes32Address.sol";

interface IOwnable {
    error Ownable__Unauthorized();
    error Ownable__NonZeroAddress();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address _owner);
}

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
abstract contract Ownable is Context, IOwnable {
    using Bytes32Address for *;

    bytes32 private __owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() payable {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address _owner) {
        assembly {
            _owner := sload(__owner.slot)
        }
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner(address sender_) internal view virtual {
        if (__owner != sender_.fillLast12Bytes())
            revert Ownable__Unauthorized();
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
        if (newOwner == address(0)) revert Ownable__Unauthorized();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        assembly {
            log3(
                0x00,
                0x00,
                /// @dev value is equal to kecak256("OwnershipTransferred(address,address)");
                0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0,
                sload(__owner.slot),
                newOwner
            )
            sstore(__owner.slot, newOwner)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../../utils/Context.sol";

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    string public name;
    string public symbol;

    mapping(address => uint256) internal _balanceOf;

    mapping(address => mapping(address => uint256)) internal _allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name_, string memory symbol_) payable {
        if (bytes(symbol_).length > 32 || bytes(name_).length > 32)
            revert ERC20__StringTooLong();

        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool approved) {
        address sender = _msgSender();

        assembly {
            mstore(0x00, sender)
            mstore(0x20, _allowance.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            sstore(keccak256(0x00, 0x40), amount)

            // emit Approval(sender, spender, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Approval(address,address,uint256)")
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                sender,
                spender
            )

            approved := true
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address sender = _msgSender();
        _beforeTokenTransfer(sender, to, amount);

        assembly {
            //  _balanceOf[sender] -= amount;
            mstore(0x00, sender)
            mstore(0x20, _balanceOf.slot)
            let balanceKey := keccak256(0x00, 0x40)
            let balanceBefore := sload(balanceKey)
            //  underflow check
            if gt(amount, balanceBefore) {
                revert(0, 0)
            }
            sstore(balanceKey, sub(balanceBefore, amount))

            //  _balanceOf[to] += amount;
            mstore(0x00, to)
            balanceKey := keccak256(0x00, 0x40)
            balanceBefore := sload(balanceKey)
            sstore(balanceKey, add(balanceBefore, amount))

            // emit Transfer(sender, to, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                sender,
                to
            )
        }

        _afterTokenTransfer(sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        _spendAllowance(from, _msgSender(), amount);

        assembly {
            //  @dev _balanceOf[from] -= amount;
            mstore(0x00, from)
            mstore(0x20, _balanceOf.slot)
            let balanceKey := keccak256(0x00, 0x40)
            let balanceBefore := sload(balanceKey)
            //  @dev underflow check
            if gt(amount, balanceBefore) {
                revert(0, 0)
            }
            sstore(balanceKey, sub(balanceBefore, amount))

            //  @dev Cannot overflow because the sum of all user
            //  balances can't exceed the max uint256 value.
            mstore(0x00, to)
            balanceKey := keccak256(0x00, 0x40)
            balanceBefore := sload(balanceKey)
            sstore(balanceKey, add(balanceBefore, amount))

            //  @dev emit Transfer(from, to, amount)
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from,
                to
            )
        }

        _afterTokenTransfer(from, to, amount);

        return true;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256 _balance) {
        assembly {
            mstore(0x00, account)
            mstore(0x20, _balanceOf.slot)
            _balance := sload(keccak256(0x00, 0x40))
        }
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256 allowance_) {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, _allowance.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender)
            allowance_ := sload(keccak256(0x00, 0x40))
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        assembly {
            mstore(0x00, owner_)
            mstore(0x20, _allowance.slot)
            mstore(0x20, keccak256(0x00, 0x40))
            mstore(0x00, spender_)
            let allowanceKey := keccak256(0x00, 0x40)
            let allowed := sload(allowanceKey)

            if iszero(
                eq(
                    allowed,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
            ) {
                //  underflow check
                if gt(amount_, allowed) {
                    revert(0, 0)
                }
                sstore(allowanceKey, sub(allowed, amount_))
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);

        assembly {
            //  @dev totalSupply += amount;
            let cachedVal := sload(totalSupply.slot)
            cachedVal := add(cachedVal, amount)
            //  @dev overflow check
            if lt(cachedVal, amount) {
                revert(0, 0)
            }
            sstore(totalSupply.slot, cachedVal)

            //  @dev Cannot overflow because the sum of all user
            //  balances can't exceed the max uint256 value.
            //  @dev _balanceOf[to] += amount;
            mstore(0x00, to)
            mstore(0x20, _balanceOf.slot)
            cachedVal := keccak256(0x00, 0x40)
            sstore(cachedVal, add(sload(cachedVal), amount))

            //  emit Transfer(address(0), to, amount);
            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                0,
                to
            )
        }

        _afterTokenTransfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);

        assembly {
            //  @dev _balanceOf[from] -= amount;
            mstore(0, from)
            mstore(32, _balanceOf.slot)
            let key := keccak256(0, 64)
            let cachedVal := sload(key)
            // @dev underflow check
            if gt(amount, cachedVal) {
                revert(0, 0)
            }

            cachedVal := sub(cachedVal, amount)
            sstore(key, cachedVal)

            //  @dev totalSupply -= amount;
            //  @dev Cannot underflow because a user's balance
            //  @dev will never be larger than the total supply.
            key := totalSupply.slot
            cachedVal := sload(key)
            cachedVal := sub(cachedVal, amount)
            sstore(key, cachedVal)

            mstore(0x00, amount)
            log3(
                0x00,
                0x20,
                /// @dev value is equal to keccak256("Transfer(address,address,uint256)")
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from,
                0
            )
        }

        _afterTokenTransfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import {IERC20} from "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error ERC20__StringTooLong();
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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
    function _msgSender() internal view virtual returns (address sender) {
        assembly {
            sender := caller()
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
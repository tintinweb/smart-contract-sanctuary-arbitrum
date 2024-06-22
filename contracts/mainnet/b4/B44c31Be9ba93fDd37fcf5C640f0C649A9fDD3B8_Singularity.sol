// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./ERC20Permit.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IToken {
    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeApprove {
    function safeApprove(address token, address to, uint256 value) internal {
        require(token.code.length > 0, "SafeApprove: no contract");

        bool success;
        bytes memory data;
        (success, data) = token.call(abi.encodeCall(IToken.approve, (to, 0)));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeApprove: approve failed");

        if (value > 0) {
            (success, data) = token.call(abi.encodeCall(IToken.approve, (to, value)));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeApprove: approve failed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {IERC20} from "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {ILeverageExecutor} from "tapioca-periph/interfaces/bar/ILeverageExecutor.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {IPearlmit} from "tapioca-periph/interfaces/periph/IPearlmit.sol";
import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";
import {MarketERC20} from "./MarketERC20.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract Market is MarketERC20, Ownable {
    using RebaseLibrary for Rebase;

    // ************ //
    // *** VARS *** //
    // ************ //
    enum PauseType {
        Borrow,
        Repay,
        AddCollateral,
        RemoveCollateral,
        Liquidation,
        LeverageBuy,
        LeverageSell,
        AddAsset,
        RemoveAsset
    }

    /// @notice pause options
    mapping(PauseType pauseProp => bool pauseStatus) internal pauseOptions;

    /// @notice returns YieldBox address
    IYieldBox internal yieldBox;

    IPearlmit internal pearlmit;

    /// @notice collateral token address
    IERC20 internal collateral;
    /// @notice collateral token YieldBox id
    uint256 internal collateralId;
    /// @notice asset token address
    IERC20 internal asset;
    /// @notice asset token YieldBox id
    uint256 internal assetId;
    /// @notice oracle address
    ITapiocaOracle internal oracle;
    /// @notice oracleData
    bytes internal oracleData;
    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    /// Asset -> collateral = assetAmount * exchangeRate.
    uint256 internal exchangeRate;
    /// @notice cached rate is valid only for the `rateValidDuration` time
    uint256 internal rateValidDuration;
    /// @notice latest timestamp when `exchangeRate` was updated
    uint256 internal rateTimestamp;

    /// @notice total amount borrowed
    /// @dev elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    Rebase internal totalBorrow;
    /// @notice total collateral supplied
    uint256 internal totalCollateralShare;
    /// @notice max borrow cap
    uint256 internal totalBorrowCap;
    /// @notice borrow amount per user
    mapping(address => uint256) internal userBorrowPart;
    /// @notice collateral share per user
    mapping(address => uint256) internal userCollateralShare;

    /// @notice accrual protocol rewards
    uint256 internal protocolFee; // 10%
    /// @notice min % a liquidator can receive in rewards
    uint256 internal minLiquidatorReward = 88e3; // 88%
    /// @notice max % a liquidator can receive in rewards
    uint256 internal maxLiquidatorReward = 925e2; // 92.5%
    /// @notice max liquidatable bonus amount
    /// @dev max % added to the amount that can be liquidated
    uint256 internal liquidationBonusAmount = 3e3; // 3%
    /// @notice collateralization rate
    uint256 internal collateralizationRate; // 75%
    /// @notice liquidation collateralization rate
    uint256 internal liquidationCollateralizationRate; //80%
    /// @notice liquidation multiplier used to compute liquidator rewards
    uint256 internal liquidationMultiplier = 12000; //12%
    /// @notice returns the leverage executor
    ILeverageExecutor internal leverageExecutor;
    /// @notice returns the maximum accepted slippage for liquidation
    uint256 internal maxLiquidationSlippage = 1000; //1%

    uint256 internal minBorrowAmount;
    uint256 internal minCollateralAmount;
    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 internal EXCHANGE_RATE_PRECISION; //not costant, but can only be set in the 'init' method
    uint256 internal constant FEE_PRECISION = 1e5;
    uint256 internal constant FEE_PRECISION_DECIMALS = 5;

    error ExchangeRateNotValid();
    error AllowanceNotValid();
    error MinBorrowAmountNotMet();
    error MinCollateralAmountNotMet();

    // ************** //
    // *** EVENTS *** //
    // ************** //
    /// @notice event emitted when `leverageExecutor` is updated
    event LeverageExecutorSet(address oldVal, address newVal);
    /// @notice event emitted when `exchangeRate` validation duration is updated
    event ExchangeRateDurationUpdated(uint256 _oldVal, uint256 _newVal);
    /// @notice event emitted when conservator is updated
    event ConservatorUpdated(address old, address _new);
    /// @notice event emitted when pause state is changed
    event PausedUpdated(PauseType indexed _type, bool oldState, bool newState);
    /// @notice event emitted when cached exchange rate is updated
    event LogExchangeRate(uint256 rate);
    /// @notice event emitted when borrow cap is updated
    event LogBorrowCapUpdated(uint256 _oldVal, uint256 _newVal);
    /// @notice event emitted when oracle data is updated
    event OracleDataUpdated();
    /// @notice event emitted when oracle is updated
    event OracleUpdated(address newAddr);
    /// @notice event emitted when a position is liquidated
    event Liquidated(
        address indexed liquidator,
        address[] users,
        uint256 liquidatorReward,
        uint256 protocolReward,
        uint256 repayedAmount,
        uint256 collateralShareRemoved
    );
    /// @notice event emitted when the liquidation multiplier rate is updated
    event LiquidationMultiplierUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted on setMarketConfig updates
    event ValueUpdated(uint256 valType, uint256 _newVal);
    /// @notice event emitted when then liquidation max slippage is updated
    event LiquidationMaxSlippageUpdated(uint256 oldVal, uint256 newVal);

    modifier optionNotPaused(PauseType _type) {
        require(!pauseOptions[_type], "Market: paused");
        _;
    }

    modifier notSelf(address destination) {
        require(destination != address(this), "Market: cannot execute on itself");
        _;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent(address from) {
        updateExchangeRate();
        _accrue();

        _;

        require(_isSolvent(from, exchangeRate, false), "Market: insolvent");
    }

    bool internal initialized;

    modifier onlyOnce() {
        require(!initialized, "Market: initialized");
        _;
        initialized = true;
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice updates `leverageExecutor`
    /// @param _executor the new ILeverageExecutor
    function setLeverageExecutor(ILeverageExecutor _executor) external onlyOwner {
        emit LeverageExecutorSet(address(leverageExecutor), address(_executor));
        leverageExecutor = _executor;
    }

    /// @notice updates `maxLiquidationSlippage`
    /// @dev not included in `setMarketConfig` for faster updates
    /// @param _val the new slippage value
    function setLiquidationMaxSlippage(uint256 _val) external onlyOwner {
        require(_val < FEE_PRECISION, "Market: not valid");
        emit LiquidationMaxSlippageUpdated(maxLiquidationSlippage, _val);
        maxLiquidationSlippage = _val;
    }

    /// @notice sets common market configuration
    /// @dev values are updated only if > 0 or not address(0)
    /// @param _oracle oracle address
    /// @param _oracleData oracle data
    /// @param _protocolFee protocol fee percentage
    /// @param _liquidationBonusAmount extra amount factored in the closing factor computation
    /// @param _minLiquidatorReward minimum reward percentage a liquidator can receive
    /// @param _maxLiquidatorReward maximum reward percentage a liquidator can receive
    /// @param _totalBorrowCap max amount that can be borrowed from the contract
    /// @param _collateralizationRate the new collateralization rate value (75000 is 75%)
    /// @param _liquidationCollateralizationRate the new liquidation collateralization rate value (75000 is 75%)
    /// @param _minBorrowAmount the new minimum borrow amount
    /// @param _minCollateralAmount the new minimum collateral amount
    function setMarketConfig(
        ITapiocaOracle _oracle,
        bytes calldata _oracleData,
        uint256 _protocolFee,
        uint256 _liquidationBonusAmount,
        uint256 _minLiquidatorReward,
        uint256 _maxLiquidatorReward,
        uint256 _totalBorrowCap,
        uint256 _collateralizationRate,
        uint256 _liquidationCollateralizationRate,
        uint256 _minBorrowAmount,
        uint256 _minCollateralAmount
    ) external onlyOwner {
        if (address(_oracle) != address(0)) {
            oracle = _oracle;
            emit OracleUpdated(address(_oracle));
        }
        if (_oracleData.length > 0) {
            oracleData = _oracleData;
            emit OracleDataUpdated();
        }

        if (_protocolFee > 0) {
            require(_protocolFee <= FEE_PRECISION, "Market: not valid");
            protocolFee = _protocolFee;
            emit ValueUpdated(2, _protocolFee);
        }

        if (_liquidationBonusAmount > 0) {
            require(_liquidationBonusAmount < FEE_PRECISION, "Market: not valid");
            liquidationBonusAmount = _liquidationBonusAmount;
            emit ValueUpdated(3, _liquidationBonusAmount);
        }

        if (_minLiquidatorReward > 0) {
            require(_minLiquidatorReward < FEE_PRECISION, "Market: not valid");
            require(_minLiquidatorReward < maxLiquidatorReward, "Market: not valid");
            minLiquidatorReward = _minLiquidatorReward;
            emit ValueUpdated(4, _minLiquidatorReward);
        }

        if (_maxLiquidatorReward > 0) {
            require(_maxLiquidatorReward < FEE_PRECISION, "Market: not valid");
            require(_maxLiquidatorReward > minLiquidatorReward, "Market: not valid");
            maxLiquidatorReward = _maxLiquidatorReward;
            emit ValueUpdated(5, _maxLiquidatorReward);
        }

        if (_totalBorrowCap > 0) {
            emit LogBorrowCapUpdated(totalBorrowCap, _totalBorrowCap);
            totalBorrowCap = _totalBorrowCap;
            emit ValueUpdated(6, _totalBorrowCap);
        }

        if (_collateralizationRate > 0) {
            require(_collateralizationRate <= FEE_PRECISION, "Market: not valid");
            require(_collateralizationRate <= liquidationCollateralizationRate, "Market: collateralizationRate too big");
            require(
                _collateralizationRate * (FEE_PRECISION + liquidationMultiplier) < FEE_PRECISION * FEE_PRECISION,
                "Market: CR * (1 + LM) >= 1"
            );
            collateralizationRate = _collateralizationRate;
            emit ValueUpdated(7, _collateralizationRate);
        }

        if (_liquidationCollateralizationRate > 0) {
            require(
                _liquidationCollateralizationRate >= collateralizationRate,
                "Market: liquidationCollateralizationRate too small"
            );
            require(_liquidationCollateralizationRate <= FEE_PRECISION, "Market: not valid");
            liquidationCollateralizationRate = _liquidationCollateralizationRate;
            emit ValueUpdated(8, _liquidationCollateralizationRate);
        }

        if (_minBorrowAmount > 0) {
            minBorrowAmount = _minBorrowAmount;
            emit ValueUpdated(9, _minBorrowAmount);
        }

        if (_minCollateralAmount > 0) {
            minCollateralAmount = _minCollateralAmount;
            emit ValueUpdated(10, _minCollateralAmount);
        }
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    function _computeClosingFactor(
        uint256 borrowPart,
        uint256 collateralPartInAsset,
        uint256 ratesPrecision,
        uint256 _liquidationCollateralizationRate,
        uint256 _liquidationMultiplier,
        Rebase memory _totalBorrow
    ) internal pure returns (uint256) {
        // Obviously it's not `borrowPart` anymore but `borrowAmount`
        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        //borrowPart and collateralPartInAsset should already be scaled due to the exchange rate computation
        uint256 liquidationStartsAt =
            (collateralPartInAsset * _liquidationCollateralizationRate) / (10 ** ratesPrecision);

        if (borrowPart < liquidationStartsAt) return 0;

        //compute numerator
        uint256 numerator = borrowPart - liquidationStartsAt;
        //compute denominator
        uint256 diff = (_liquidationCollateralizationRate * ((10 ** ratesPrecision) + _liquidationMultiplier))
            / (10 ** ratesPrecision);
        int256 denominator = (int256(10 ** ratesPrecision) - int256(diff)) * int256(1e13);

        //compute closing factor
        int256 x = (int256(numerator) * int256(1e18)) / denominator;
        int256 xPos = x < 0 ? -x : x;

        //assure closing factor validity
        if (uint256(xPos) > borrowPart) return borrowPart;

        return uint256(xPos);
    }

    /// @notice return the amount of collateral for a `user` to be solvent, min TVL and max TVL. Returns 0 if user already solvent.
    /// @dev we use a `CLOSED_COLLATERIZATION_RATE` that is a safety buffer when making the user solvent again,
    ///      to prevent from being liquidated. This function is valid only if user is not solvent by `_isSolvent()`.
    /// @param user The user to check solvency.
    /// @param _exchangeRate the exchange rate asset/collateral.
    /// @return amountToSolvency the amount of collateral to be solvent.
    /// @return minTVL the asset value of the collateral amount factored by collateralizationRate
    /// @return maxTVL the asset value of the collateral amount.
    function computeTVLInfo(address user, uint256 _exchangeRate)
        public
        view
        returns (uint256 amountToSolvency, uint256 minTVL, uint256 maxTVL)
    {
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return (0, 0, 0);

        Rebase memory _totalBorrow = _accrueView();

        uint256 collateralAmountInAsset = _computeMaxBorrowableAmount(user, _exchangeRate);

        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        unchecked {
            amountToSolvency = borrowPart >= collateralAmountInAsset ? borrowPart - collateralAmountInAsset : 0;
        }
        (minTVL, maxTVL) = _computeMaxAndMinLTVInAsset(userCollateralShare[user], _exchangeRate);
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// @dev This function is supposed to be invoked if needed because Oracle queries can be expensive.
    ///      Oracle should consider USDO at 1$
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);
        require(updated, "Market: rate too old");
        require(rate != 0, "Market: invalid rate");

        exchangeRate = rate;
        rateTimestamp = block.timestamp;

        emit LogExchangeRate(rate);
    }

    /// @notice computes the possible liquidator reward
    /// @param user the user for which a liquidation operation should be performed
    /// @param _exchangeRate the exchange rate asset/collateral to use for internal computations
    function computeLiquidatorReward(address user, uint256 _exchangeRate) external view returns (uint256) {
        return _getCallerReward(user, _exchangeRate);
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //
    function _accrue() internal virtual;

    function _accrueView() internal view virtual returns (Rebase memory);

    /**
     * @inheritdoc MarketERC20
     */
    function _allowedLend(address from, uint256 share) internal virtual override {
        if (from != msg.sender) {
            if (share == 0) revert AllowanceNotValid();

            uint256 pearlmitAllowed;
            // Here we approve the market token, because it is unique to the market
            if (penrose.cluster().isWhitelisted(0, msg.sender)) {
                (pearlmitAllowed,) = penrose.pearlmit().allowance(from, msg.sender, 20, address(this), 0);
            }
            require(allowance[from][msg.sender] >= share || pearlmitAllowed >= share, "Market: not approved");
            if (pearlmitAllowed >= share) return;
            if (allowance[from][msg.sender] != type(uint256).max) {
                allowance[from][msg.sender] -= share;
            }
        }
    }

    /**
     * @inheritdoc MarketERC20
     */
    function _allowedBorrow(address from, uint256 share) internal virtual override {
        if (from != msg.sender) {
            if (share == 0) revert AllowanceNotValid();

            uint256 pearlmitAllowed;
            // Here we approve the YB collateral token, because market token is already used in `_allowedLend`
            if (penrose.cluster().isWhitelisted(0, msg.sender)) {
                (pearlmitAllowed,) =
                    penrose.pearlmit().allowance(from, msg.sender, 1155, address(yieldBox), collateralId);
            }
            require(allowanceBorrow[from][msg.sender] >= share || pearlmitAllowed >= share, "Market: not approved");
            if (pearlmitAllowed >= share) return;
            if (allowanceBorrow[from][msg.sender] != type(uint256).max) {
                allowanceBorrow[from][msg.sender] -= share;
            }
        }
    }

    function _tryUpdateOracleRate() internal {
        try oracle.get(oracleData) returns (bool _updated, uint256 _exchangeRate) {
            if (_updated && _exchangeRate > 0) {
                exchangeRate = _exchangeRate; //update cached rate
                rateTimestamp = block.timestamp;
            } else {
                _exchangeRate = exchangeRate; //use stored rate
                if (_exchangeRate == 0) revert ExchangeRateNotValid();
            }
        } catch {
            if (exchangeRate == 0) revert ExchangeRateNotValid();
        }
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (bytes memory) {
        if (_returnData.length > 1000) return "Market: reason too long";
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Market: no return data";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return _returnData; // All that remains is the revert string
    }

    function _computeMaxBorrowableAmount(address user, uint256 _exchangeRate)
        internal
        view
        returns (uint256 collateralAmountInAsset)
    {
        require(_exchangeRate > 0, "Market: exchangeRate not valid");
        uint256 userCollateralAmount = yieldBox.toAmount(collateralId, userCollateralShare[user], false);
        collateralAmountInAsset =
            (userCollateralAmount * (EXCHANGE_RATE_PRECISION / FEE_PRECISION) * collateralizationRate) / _exchangeRate;
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate, bool _liquidation) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        uint256 collateralAmount = yieldBox.toAmount(collateralId, collateralShare, false);
        return collateralAmount * (EXCHANGE_RATE_PRECISION / FEE_PRECISION)
            * (_liquidation ? liquidationCollateralizationRate : collateralizationRate)
        // Moved exchangeRate here instead of dividing the other side to preserve more precision
        >= (borrowPart * _totalBorrow.elastic * _exchangeRate) / _totalBorrow.base;
    }

    /// @notice Returns the min and max LTV for user in asset price
    function _computeMaxAndMinLTVInAsset(uint256 collateralShare, uint256 _exchangeRate)
        internal
        view
        returns (uint256 min, uint256 max)
    {
        require(_exchangeRate > 0, "Market: exchangeRate not valid");
        uint256 collateralAmount = yieldBox.toAmount(collateralId, collateralShare, false);

        max = (collateralAmount * EXCHANGE_RATE_PRECISION) / _exchangeRate;
        min = (max * collateralizationRate) / FEE_PRECISION;
    }

    function _getCallerReward(address user, uint256 _exchangeRate) internal view returns (uint256) {
        (uint256 startTVLInAsset, uint256 maxTVLInAsset) =
            _computeMaxAndMinLTVInAsset(userCollateralShare[user], _exchangeRate);

        uint256 borrowed = userBorrowPart[user];
        if (borrowed == 0) return 0;
        if (startTVLInAsset == 0) return 0;

        borrowed = (borrowed * totalBorrow.elastic) / totalBorrow.base;

        if (borrowed < startTVLInAsset) return 0;
        if (borrowed >= maxTVLInAsset) return minLiquidatorReward;

        uint256 rewardPercentage = ((borrowed - startTVLInAsset) * FEE_PRECISION) / (maxTVLInAsset - startTVLInAsset);

        int256 diff = int256(minLiquidatorReward) - int256(maxLiquidatorReward);
        int256 reward = (diff * int256(rewardPercentage)) / int256(FEE_PRECISION) + int256(maxLiquidatorReward);

        if (reward < int256(minLiquidatorReward)) {
            reward = int256(minLiquidatorReward);
        }

        return uint256(reward);
    }

    function _computeAllowanceAmountInAsset(
        address user,
        uint256 _exchangeRate,
        uint256 borrowAmount,
        uint256 assetDecimals
    ) internal view returns (uint256) {
        uint256 maxBorrowable = _computeMaxBorrowableAmount(user, _exchangeRate);

        uint256 shareRatio = _getRatio(borrowAmount, maxBorrowable, assetDecimals);
        return (shareRatio * userCollateralShare[user]) / (10 ** assetDecimals);
    }

    function _getRatio(uint256 numerator, uint256 denominator, uint256 precision) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10 ** (precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {EIP712, ECDSA} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC20} from "@boringcrypto/boring-solidity/contracts/ERC20.sol";

// Tapioca
import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract MarketERC20 is IERC20, IERC20Permit, IERC1155Receiver, EIP712 {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice returns Penrose address
    IPenrose internal penrose;


    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // keccak256("PermitBorrow(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 private constant _PERMIT_TYPEHASH_BORROW =
        0xe9685ff6d48c617fe4f692c50e602cce27cbad0290beb93cfa77eac43968d58c;

    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowanceBorrow;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) private _nonces;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    /// @notice event emitted when borrow approval is performed
    event ApprovalBorrow(address indexed owner, address indexed spender, uint256 indexed value);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Check if msg.sender has right to execute Lend operations
    modifier allowedLend(address from, uint256 share) virtual {
        _allowedLend(from, share);
        _;
    }
    /// Check if msg.sender has right to execute borrow operations

    modifier allowedBorrow(address from, uint256 share) virtual {
        _allowedBorrow(from, share);
        _;
    }

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    function totalSupply() external view virtual override returns (uint256) {}

    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) external virtual returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(address from, address to, uint256 amount) external virtual returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveBorrow(address spender, uint256 amount) external returns (bool) {
        _approveBorrow(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        virtual
        override(IERC20, IERC20Permit)
    {
        _permit(true, owner, spender, value, deadline, v, r, s);
    }

    function permitBorrow(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        _permit(false, owner, spender, value, deadline, v, r, s);
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //

    /**
     * @notice Checks if the caller is allowed to lend `share` from `from`.
     */
    function _allowedLend(address from, uint256 share) internal virtual {}

    /**
     * @notice Checks if the caller is allowed to borrow `share` from `from`.
     */
    function _allowedBorrow(address from, uint256 share) internal virtual {}

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        current = _nonces[owner]++;
    }

    function _permit(
        bool asset, // true = asset, false = collateral
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        if (!ICluster(penrose.cluster()).isWhitelisted(0, msg.sender)) require (owner == msg.sender, "MarketERC20: not authorized");

        bytes32 structHash;

        structHash = keccak256(
            abi.encode(
                asset ? _PERMIT_TYPEHASH : _PERMIT_TYPEHASH_BORROW, owner, spender, value, _useNonce(owner), deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);

        require(signer == owner, "ERC20Permit: invalid signature");

        if (asset) {
            _approve(owner, spender, value);
        } else {
            _approveBorrow(owner, spender, value);
        }
    }

    function _approveBorrow(address owner, address spender, uint256 amount) internal {
        allowanceBorrow[owner][spender] = amount;
        emit ApprovalBorrow(owner, spender, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC20Permit).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return bytes4(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

// Tapioca
import {Market} from "./Market.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

abstract contract MarketStateView is Market {
    function _pauseOptions(PauseType _pauseProp) external view returns (bool) {
        return pauseOptions[_pauseProp];
    }

    function _penrose() external view returns (address) {
        return address(penrose);
    }

    function _pearlmit() external view returns (address) {
        return address(pearlmit);
    }

    function _collateral() external view returns (address) {
        return address(collateral);
    }

    function _collateralId() external view returns (uint256) {
        return collateralId;
    }

    function _asset() external view returns (address) {
        return address(asset);
    }

    function _assetId() external view returns (uint256) {
        return assetId;
    }

    function _oracle() external view returns (address) {
        return address(oracle);
    }

    function _oracleData() external view returns (bytes memory) {
        return oracleData;
    }

    function _exchangeRate() external view returns (uint256) {
        return exchangeRate;
    }

    function _rateValidDuration() external view returns (uint256) {
        return rateValidDuration;
    }

    function _rateTimestamp() external view returns (uint256) {
        return rateTimestamp;
    }

    function _totalBorrow() external view returns (Rebase memory) {
        return totalBorrow;
    }

    function _totalCollateralShare() external view returns (uint256) {
        return totalCollateralShare;
    }

    function _totalBorrowCap() external view returns (uint256) {
        return totalBorrowCap;
    }

    function _userBorrowPart(address _user) external view returns (uint256) {
        return userBorrowPart[_user];
    }

    function _userCollateralShare(address _user) external view returns (uint256) {
        return userCollateralShare[_user];
    }

    function _protocolFee() external view returns (uint256) {
        return protocolFee;
    }

    function _minLiquidatorReward() external view returns (uint256) {
        return minLiquidatorReward;
    }

    function _maxLiquidatorReward() external view returns (uint256) {
        return maxLiquidatorReward;
    }

    function _liquidationBonusAmount() external view returns (uint256) {
        return liquidationBonusAmount;
    }

    function _collateralizationRate() external view returns (uint256) {
        return collateralizationRate;
    }

    function _liquidationCollateralizationRate() external view returns (uint256) {
        return liquidationCollateralizationRate;
    }

    function _liquidationMultiplier() external view returns (uint256) {
        return liquidationMultiplier;
    }

    function _leverageExecutor() external view returns (address) {
        return address(leverageExecutor);
    }

    function _maxLiquidationSlippage() external view returns (uint256) {
        return maxLiquidationSlippage;
    }

    function _yieldBox() external view returns (address) {
        return address(yieldBox);
    }

    function _exchangeRatePrecision() external view returns (uint256) {
        return EXCHANGE_RATE_PRECISION;
    }

    function _minBorrowAmount() external view returns (uint256) {
        return minBorrowAmount;
    }

    function _minCollateralAmount() external view returns (uint256) {
        return minCollateralAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "./SGLLendingCommon.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLBorrow is SGLLendingCommon {
    using RebaseLibrary for Rebase;

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address from, address to, uint256 amount)
        external
        optionNotPaused(PauseType.Borrow)
        solvent(from)
        notSelf(to)
        returns (uint256 part, uint256 share)
    {
        if (amount <= minBorrowAmount) revert MinBorrowAmountNotMet();

        uint256 feeAmount = (amount * borrowOpeningFee) / FEE_PRECISION;
        uint256 allowanceShare =
            _computeAllowanceAmountInAsset(from, exchangeRate, amount + feeAmount, _safeDecimals(asset));

        _allowedBorrow(from, allowanceShare);

        (part, share) = _borrow(from, to, amount);
    }

    /// @notice Repays a loan.
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(address from, address to, bool skim, uint256 part)
        external
        optionNotPaused(PauseType.Repay)
        notSelf(to)
        returns (uint256 amount)
    {
        _tryUpdateOracleRate();

        _accrue();

        amount = _repay(from, to, skim, part, true);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "./SGLLendingCommon.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLCollateral is SGLLendingCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param amount The amount to add for `to`.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(address from, address to, bool skim, uint256 amount, uint256 share)
        external
        optionNotPaused(PauseType.AddCollateral)
        notSelf(to)
    {
        if (share == 0) {
            share = yieldBox.toShare(collateralId, amount, false);
        }
        if (amount == 0) {
            amount = yieldBox.toAmount(collateralId, share, false);
        }
        if (amount <= minCollateralAmount) revert MinCollateralAmountNotMet();
        
        _allowedBorrow(from, share);

        _addCollateral(from, to, skim, amount, share, true);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address from, address to, uint256 share)
        external
        optionNotPaused(PauseType.RemoveCollateral)
        solvent(from)
        allowedBorrow(from, share)
        notSelf(to)
    {
        _removeCollateral(from, to, share);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Tapioca
import {ISGLInterestHelper} from "tapioca-periph/interfaces/bar/ISGLInterestHelper.sol";
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {SGLStorage} from "./SGLStorage.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLCommon is SGLStorage {
    using RebaseLibrary for Rebase;
    using SafeCast for uint256;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error MinLimit();
    error TransferFailed();
    error AccruePaused();

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() external {
        if (pauseOptions[PauseType.AddCollateral] || pauseOptions[PauseType.RemoveCollateral]) revert AccruePaused();
        _accrue();
    }

    function getInterestDetails()
        external
        view
        returns (ISingularity.AccrueInfo memory _accrueInfo, uint256 utilization)
    {
        (_accrueInfo,,,,, utilization) = _getInterestRate();
    }

    // ************************** //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _getInterestRate()
        internal
        view
        returns (
            ISingularity.AccrueInfo memory _accrueInfo,
            Rebase memory _totalBorrow,
            Rebase memory _totalAsset,
            uint256 extraAmount,
            uint256 feeFraction,
            uint256 utilization
        )
    {
        (_accrueInfo, _totalBorrow, _totalAsset, extraAmount, feeFraction, utilization) = ISGLInterestHelper(
            interestHelper
        ).getInterestRate(
            ISGLInterestHelper.InterestRateCall(
                yieldBox,
                accrueInfo,
                assetId,
                totalAsset,
                totalBorrow,
                protocolFee,
                interestElasticity,
                minimumTargetUtilization,
                maximumTargetUtilization,
                minimumInterestPerSecond,
                maximumInterestPerSecond,
                startingInterestPerSecond
            )
        );
    }

    function _accrueView() internal view override returns (Rebase memory _totalBorrow) {
        (, _totalBorrow,,,,) = _getInterestRate();
    }

    function _accrue() internal override {
        (
            ISingularity.AccrueInfo memory _accrueInfo,
            Rebase memory _totalBorrow,
            Rebase memory _totalAsset,
            uint256 extraAmount,
            uint256 feeFraction,
            uint256 utilization
        ) = _getInterestRate();

        emit LogAccrue(extraAmount, feeFraction, _accrueInfo.interestPerSecond, utilization);
        accrueInfo = _accrueInfo;
        totalBorrow = _totalBorrow;
        totalAsset = _totalAsset;
    }

    /// @dev Helper function to move tokens.
    /// @param from Account to debit tokens from, in `yieldBox`.
    /// @param _assetId The ERC-20 token asset ID in yieldBox.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    function _addTokens(address from, address, uint256 _assetId, uint256 share, uint256 total, bool skim) internal {
        if (skim) {
            if (share > yieldBox.balanceOf(address(this), _assetId) - total) {
                revert TransferFailed();
            }
        } else {
            // yieldBox.transfer(from, address(this), _assetId, share);
            bool isErr = pearlmit.transferFromERC1155(from, address(this), address(yieldBox), _assetId, share);
            if (isErr) {
                revert TransferFailed();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {BoringERC20, IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Tapioca
import {SGLCommon} from "./SGLCommon.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLLendingCommon is SGLCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;
    using SafeCast for uint256;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error BorrowCapReached();
    error NothingToRepay();
    error NotEnough();

    // ************************** //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    /// @dev Concrete implementation of `addCollateral`.
    function _addCollateral(address from, address to, bool skim, uint256 amount, uint256 share, bool addTokens)
        internal
    {
        if (share == 0) {
            share = yieldBox.toShare(collateralId, amount, false);
        }
        uint256 oldTotalCollateralShare = totalCollateralShare;
        userCollateralShare[to] += share;
        totalCollateralShare = oldTotalCollateralShare + share;

        if (addTokens) _addTokens(from, to, collateralId, share, oldTotalCollateralShare, skim);

        emit LogAddCollateral(skim ? address(yieldBox) : from, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address from, address to, uint256 share) internal {
        userCollateralShare[from] -= share;
        totalCollateralShare -= share;
        emit LogRemoveCollateral(from, to, share);
        yieldBox.transfer(address(this), to, collateralId, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address from, address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        share = yieldBox.toShare(assetId, amount, true);
        Rebase memory _totalAsset = totalAsset;
        if (_totalAsset.base < 1000) revert MinLimit();

        uint256 fullAssetAmountBefore = yieldBox.toAmount(assetId, _totalAsset.elastic, false) + totalBorrow.elastic;

        _totalAsset.elastic -= share.toUint128();

        uint256 feeAmount = (amount * borrowOpeningFee) / FEE_PRECISION; // A flat % fee is charged for any borrow

        (totalBorrow, part) = totalBorrow.add(amount + feeAmount, true);
        if (totalBorrowCap != 0) {
            if (totalBorrow.elastic > totalBorrowCap) revert BorrowCapReached();
        }
        userBorrowPart[from] += part;
        emit LogBorrow(from, to, amount, feeAmount, part);

        if (feeAmount > 0) {
            uint256 feeFraction = (feeAmount * _totalAsset.base) / fullAssetAmountBefore;
            _totalAsset.base += feeFraction.toUint128();
            balanceOf[address(penrose)] += feeFraction;
        }

        totalAsset = _totalAsset;

        yieldBox.transfer(address(this), to, assetId, share);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(address from, address to, bool skim, uint256 part, bool checkAllowance)
        internal
        returns (uint256 amount)
    {
        if (part > userBorrowPart[to]) {
            part = userBorrowPart[to];
        }
        if (part == 0) revert NothingToRepay();

        if (checkAllowance && msg.sender != from) {
            uint256 partInAmount;
            Rebase memory _totalBorrow = totalBorrow;
            (_totalBorrow, partInAmount) = _totalBorrow.sub(part, true);

            uint256 allowanceShare =
                _computeAllowanceAmountInAsset(to, exchangeRate, partInAmount, _safeDecimals(asset));
            if (allowanceShare == 0) revert NotEnough();
            _allowedLend(from, allowanceShare);
        }
        (totalBorrow, amount) = totalBorrow.sub(part, true);

        userBorrowPart[to] -= part;

        uint256 share = yieldBox.toShare(assetId, amount, true);
        uint128 totalShare = totalAsset.elastic;
        _addTokens(from, to, assetId, share, uint256(totalShare), skim);
        totalAsset.elastic = totalShare + share.toUint128();

        emit LogRepay(skim ? address(yieldBox) : from, to, amount, part);
    }

    function _safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567)); //decimals() selector
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {BoringERC20, IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";

// Tapioca
import {SafeApprove} from "../../libraries/SafeApprove.sol";
import {SGLLendingCommon} from "./SGLLendingCommon.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLLeverage is SGLLendingCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;
    using SafeApprove for address;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error LeverageExecutorNotValid();
    error CollateralShareNotValid();
    error AmountNotValid();

    struct _BuyCollateralCalldata {
        address from;
        uint256 borrowAmount;
        uint256 supplyAmount;
        bytes data;
    }
    struct _BuyCollateralMemoryData {
        uint256 supplyShareToAmount;
        uint256 borrowShareToAmount;
    }

    /// @notice Lever up: Borrow more and buy collateral with it.
    /// @param from The user who buys
    /// @param borrowAmount Amount of extra asset borrowed
    /// @param supplyAmount Amount of asset supplied (down payment)
    /// @param data LeverageExecutor data
    /// @return amountOut Actual collateral amount purchased
    function buyCollateral(address from, uint256 borrowAmount, uint256 supplyAmount, bytes calldata data)
        external
        optionNotPaused(PauseType.LeverageBuy)
        solvent(from)
        notSelf(from)
        returns (uint256 amountOut)
    {
        if (address(leverageExecutor) == address(0)) {
            revert LeverageExecutorNotValid();
        }
        // Stack too deep fix
        _BuyCollateralCalldata memory calldata_;
        _BuyCollateralMemoryData memory memoryData;
        {
            calldata_.from = from;
            calldata_.borrowAmount = borrowAmount;
            calldata_.supplyAmount = supplyAmount;
            calldata_.data = data;
        }

        // Let this fail first to save gas:
        uint256 supplyShare = yieldBox.toShare(assetId, calldata_.supplyAmount, true);
        if (supplyShare > 0) {
            (memoryData.supplyShareToAmount,) =
                yieldBox.withdraw(assetId, calldata_.from, address(leverageExecutor), 0, supplyShare);
        }
        (, uint256 borrowShare) = _borrow(calldata_.from, address(this), calldata_.borrowAmount);

        {
            (memoryData.borrowShareToAmount,) =
                yieldBox.withdraw(assetId, address(this), address(leverageExecutor), 0, borrowShare);

            updateExchangeRate();
            uint256 assetPartInCollateral = (memoryData.supplyShareToAmount + memoryData.borrowShareToAmount) * exchangeRate / EXCHANGE_RATE_PRECISION;
            _allowedBorrow(calldata_.from, yieldBox.toShare(collateralId, assetPartInCollateral, false));

            amountOut = leverageExecutor.getCollateral(
                from, address(asset), address(collateral), memoryData.supplyShareToAmount + memoryData.borrowShareToAmount, calldata_.data
            );
        }

        {
            uint256 collateralShare = yieldBox.toShare(collateralId, amountOut, false);
            if (collateralShare == 0) revert CollateralShareNotValid();

            address(collateral).safeApprove(address(yieldBox), type(uint256).max);
            yieldBox.depositAsset(collateralId, address(this), calldata_.from, 0, collateralShare);
            address(collateral).safeApprove(address(yieldBox), 0);

            _addCollateral(calldata_.from, calldata_.from, false, 0, collateralShare, false);
        }

        if (amountOut == 0) revert AmountNotValid();
    }

    struct _SellCollateralCalldata {
        address from;
        uint256 share;
        bytes data;
    }

    /// @notice Lever down: Sell collateral to repay debt; excess goes to YB
    /// @param from The user who sells
    /// @param share Collateral YieldBox-shares to sell
    /// @param data LeverageExecutor data
    /// @return amountOut Actual asset amount received in the sale
    function sellCollateral(address from, uint256 share, bytes calldata data)
        external
        optionNotPaused(PauseType.LeverageSell)
        solvent(from)
        notSelf(from)
        returns (uint256 amountOut)
    {
        if (address(leverageExecutor) == address(0)) {
            revert LeverageExecutorNotValid();
        }
        // Stack too deep fix
        _SellCollateralCalldata memory calldata_;
        {
            calldata_.from = from;
            calldata_.share = share;
            calldata_.data = data;
        }

        _allowedBorrow(calldata_.from, calldata_.share);
        _removeCollateral(calldata_.from, address(this), calldata_.share);

        (uint256 leverageAmount,) =
            yieldBox.withdraw(collateralId, address(this), address(leverageExecutor), 0, calldata_.share);

        amountOut = leverageExecutor.getAsset(from, address(collateral), address(asset), leverageAmount, calldata_.data);
        uint256 shareOut = yieldBox.toShare(assetId, amountOut, false);

        address(asset).safeApprove(address(yieldBox), type(uint256).max);
        yieldBox.depositAsset(assetId, address(this), calldata_.from, 0, shareOut);
        address(asset).safeApprove(address(yieldBox), 0);

        uint256 partOwed = userBorrowPart[calldata_.from];
        uint256 amountOwed = totalBorrow.toElastic(partOwed, true);
        uint256 shareOwed = yieldBox.toShare(assetId, amountOwed, true);
        if (shareOwed <= shareOut) {
            _repay(calldata_.from, calldata_.from, false, partOwed, false);
        } else {
            //repay as much as we can
            uint256 partOut = totalBorrow.toBase(amountOut, false);
            _repay(calldata_.from, calldata_.from, false, partOut, false);
        }
        if (amountOut == 0) revert AmountNotValid();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {BoringERC20, IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Tapioca
import {IMarketLiquidatorReceiver} from "tapioca-periph/interfaces/bar/IMarketLiquidatorReceiver.sol";
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";
import {SafeApprove} from "../../libraries/SafeApprove.sol";
import {SGLCommon} from "./SGLCommon.sol";

// solhint-disable max-line-length

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLLiquidation is SGLCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;
    using SafeCast for uint256;
    using SafeApprove for address;

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error AmountNotValid();
    error NothingToLiquidate();
    error LengthMismatch();
    error OnCollateralReceiverFailed(uint256 returned, uint256 minAccepted);
    error BadDebt();
    error NotEnoughCollateral();
    error Solvent();
    error InsufficientLiquidationBonus();
    error NotAuthorized();

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    function liquidateBadDebt(
        address user,
        address from,
        address receiver,
        IMarketLiquidatorReceiver liquidatorReceiver,
        bytes calldata liquidatorReceiverData,
        bool swapCollateral
    ) external onlyOwner {
        _tryUpdateOracleRate();

        //check from whitelist status
        {
            bool isWhitelisted = ICluster(penrose.cluster()).isWhitelisted(0, from);
            if (!isWhitelisted) revert NotAuthorized();
        }
        // accrue before liquidation
        _accrue();

        // compute borrow amount with bonus
        uint256 elasticPart = totalBorrow.toElastic(userBorrowPart[user], false);
        uint256 borrowAmountWithBonus = elasticPart + (elasticPart * liquidationMultiplier) / FEE_PRECISION;
        uint256 requiredCollateral =
            yieldBox.toShare(collateralId, (borrowAmountWithBonus * exchangeRate) / EXCHANGE_RATE_PRECISION, false);

        uint256 collateralShare = userCollateralShare[user];

        if (requiredCollateral < collateralShare) revert NotAuthorized();

        // update totalBorrow
        uint256 borrowAmount = totalBorrow.toElastic(userBorrowPart[user], true);
        totalBorrow.elastic -= borrowAmount.toUint128();
        totalBorrow.base -= userBorrowPart[user].toUint128();

        // update totalCollateralShare
        totalCollateralShare -= collateralShare;

        // set user share & part to 0
        userCollateralShare[user] = 0;
        userBorrowPart[user] = 0;

        // transfer asset from `from`
        asset.safeTransferFrom(from, address(this), borrowAmount);
        address(asset).safeApprove(address(yieldBox), borrowAmount);
        uint256 borrowShare = yieldBox.toShare(assetId, borrowAmount, false);
        yieldBox.depositAsset(assetId, address(this), address(this), borrowAmount, 0);
        address(asset).safeApprove(address(yieldBox), 0);
        totalAsset.elastic += borrowShare.toUint128();

        // swap collateral with asset and send it to `receiver`
        if (swapCollateral) {
            (, uint256 returnedAmount) =
                _swapCollateralWithAsset(collateralShare, liquidatorReceiver, liquidatorReceiverData, 0, false);
            asset.safeTransfer(receiver, returnedAmount);
        } else {
            uint256 collateralAmount = yieldBox.toAmount(collateralId, collateralShare, false);
            yieldBox.withdraw(collateralId, address(this), receiver, collateralAmount, 0);
        }
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //
    /// @notice Entry point for liquidations.
    /// @dev Will call `closedLiquidation()` if not LQ exists or no LQ bid avail exists. Otherwise use LQ.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user
    /// @param minLiquidationBonuses minimum liquidation bonus acceptable
    /// @param liquidatorReceivers IMarketLiquidatorReceiver array
    /// @param liquidatorReceiverDatas IMarketLiquidatorReceiver datas
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        uint256[] calldata minLiquidationBonuses,
        IMarketLiquidatorReceiver[] calldata liquidatorReceivers,
        bytes[] calldata liquidatorReceiverDatas
    ) external optionNotPaused(PauseType.Liquidation) {
        if (users.length == 0) revert NothingToLiquidate();
        if (users.length != maxBorrowParts.length) revert LengthMismatch();
        if (users.length != liquidatorReceivers.length) revert LengthMismatch();
        if (liquidatorReceiverDatas.length != liquidatorReceivers.length) {
            revert LengthMismatch();
        }

        _tryUpdateOracleRate();

        _accrue();

        _closedLiquidation(
            users, maxBorrowParts, minLiquidationBonuses, liquidatorReceivers, liquidatorReceiverDatas, exchangeRate
        );
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _swapCollateralWithAsset(
        uint256 _collateralShare,
        IMarketLiquidatorReceiver _liquidatorReceiver,
        bytes memory _liquidatorReceiverData,
        uint256 _exchangeRate,
        bool checkReturned
    ) private returns (uint256 returnedShare, uint256 returnedAmount) {
        uint256 collateralAmount = yieldBox.toAmount(collateralId, _collateralShare, false);
        yieldBox.withdraw(collateralId, address(this), address(_liquidatorReceiver), collateralAmount, 0);

        {
            uint256 assetBalanceBefore = asset.balanceOf(address(this));
            //msg.sender should be validated against `initiator` on IMarketLiquidatorReceiver
            _liquidatorReceiver.onCollateralReceiver(
                msg.sender, address(collateral), address(asset), collateralAmount, _liquidatorReceiverData
            );
            uint256 assetBalanceAfter = asset.balanceOf(address(this));
            returnedAmount = assetBalanceAfter - assetBalanceBefore;

            if (checkReturned) {
                uint256 receivableAsset = collateralAmount * EXCHANGE_RATE_PRECISION / _exchangeRate;
                uint256 minReceivableAsset =
                    receivableAsset - (receivableAsset * maxLiquidationSlippage / FEE_PRECISION); //1% slippage
                if (returnedAmount < minReceivableAsset) {
                    revert OnCollateralReceiverFailed(returnedAmount, minReceivableAsset);
                }
            }
        }
        if (returnedAmount == 0) revert OnCollateralReceiverFailed(0, 0);
        returnedShare = yieldBox.toShare(assetId, returnedAmount, false);
    }

    function _computeAssetAmountToSolvency(address user, uint256 _exchangeRate) private view returns (uint256) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return 0;

        if (_exchangeRate == 0) revert ExchangeRateNotValid();

        Rebase memory _totalBorrow = totalBorrow;

        uint256 collateralAmountInAsset = yieldBox.toAmount(
            collateralId,
            (userCollateralShare[user] * (EXCHANGE_RATE_PRECISION / FEE_PRECISION) * liquidationCollateralizationRate),
            false
        ) / _exchangeRate;
        // Obviously it's not `borrowPart` anymore but `borrowAmount`
        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        return borrowPart >= collateralAmountInAsset ? borrowPart - collateralAmountInAsset : 0;
    }

    function _updateBorrowAndCollateralShare(
        address user,
        uint256 maxBorrowPart,
        uint256 minLiquidationBonus, // min liquidation bonus to accept (default 0)
        uint256 _exchangeRate
    ) private returns (uint256 borrowAmount, uint256 borrowPart, uint256 collateralShare) {
        if (_exchangeRate == 0) revert ExchangeRateNotValid();

        uint256 _userBorrowPart = userBorrowPart[user];
        uint256 _userCollateralShare = userCollateralShare[user];

        // get collateral amount in asset's value
        uint256 collateralPartInAsset =
            (yieldBox.toAmount(collateralId, _userCollateralShare, false) * EXCHANGE_RATE_PRECISION) / _exchangeRate;

        // compute closing factor (liquidatable amount)
        uint256 borrowPartWithBonus = _computeClosingFactor(
            _userBorrowPart,
            collateralPartInAsset,
            FEE_PRECISION_DECIMALS,
            liquidationCollateralizationRate,
            liquidationMultiplier,
            totalBorrow
        );

        // limit liquidable amount before bonus to the current debt
        uint256 userTotalBorrowAmount = totalBorrow.toElastic(_userBorrowPart, true);
        borrowPartWithBonus = borrowPartWithBonus > userTotalBorrowAmount ? userTotalBorrowAmount : borrowPartWithBonus;

        // make sure liquidator cannot bypass bad debt handling
        if (collateralPartInAsset < borrowPartWithBonus) revert BadDebt();

        // check the amount to be repaid versus liquidator supplied limit
        borrowPartWithBonus = borrowPartWithBonus > maxBorrowPart ? maxBorrowPart : borrowPartWithBonus;
        borrowAmount = borrowPartWithBonus;

        // compute part units, preventing rounding dust when liquidation is full
        borrowPart =
            borrowAmount == userTotalBorrowAmount ? _userBorrowPart : totalBorrow.toBase(borrowPartWithBonus, false);
        if (borrowPart == 0) revert Solvent();

        if (liquidationBonusAmount > 0) {
            borrowPartWithBonus = borrowPartWithBonus + (borrowPartWithBonus * liquidationBonusAmount) / FEE_PRECISION;
        }

        if (collateralPartInAsset < borrowPartWithBonus) {
            if (collateralPartInAsset <= userTotalBorrowAmount) {
                revert BadDebt();
            }
            // If current debt is covered by collateral fully
            // then there is some liquidation bonus,
            // so liquidation can proceed if liquidator's minimum is met
            if (minLiquidationBonus > 0) {
                // `collateralPartInAsset > borrowAmount` as `borrowAmount <= userTotalBorrowAmount`
                uint256 effectiveBonus = ((collateralPartInAsset - borrowAmount) * FEE_PRECISION) / borrowAmount;
                if (effectiveBonus < minLiquidationBonus) {
                    revert InsufficientLiquidationBonus();
                }
                collateralShare = _userCollateralShare;
            } else {
                revert InsufficientLiquidationBonus();
            }
        } else {
            uint totalUserBorrowWithBonus = userTotalBorrowAmount + (userTotalBorrowAmount * liquidationBonusAmount) / FEE_PRECISION;
            if (collateralPartInAsset < totalUserBorrowWithBonus) revert BadDebt();
            collateralShare =
                yieldBox.toShare(collateralId, (borrowPartWithBonus * _exchangeRate) / EXCHANGE_RATE_PRECISION, false);
            if (collateralShare > _userCollateralShare) {
                revert NotEnoughCollateral();
            }
        }

        userBorrowPart[user] -= borrowPart;
        userCollateralShare[user] -= collateralShare;
    }

    function _extractLiquidationFees(uint256 extraShare, uint256 callerReward)
        private
        returns (uint256 feeShare, uint256 callerShare)
    {
        callerShare = (extraShare * callerReward) / FEE_PRECISION; //  y%  of profit goes to caller.
        feeShare = extraShare - callerShare; // rest goes to the fee

        if (feeShare > 0) {
            uint256 feeAmount = yieldBox.toAmount(assetId, feeShare, false);

            uint256 fullAssetAmount = yieldBox.toAmount(assetId, totalAsset.elastic, false) + totalBorrow.elastic;
            uint256 feeFraction = (feeAmount * totalAsset.base) / fullAssetAmount;
            balanceOf[address(penrose)] += feeFraction;
            totalAsset.base += feeFraction.toUint128();
            totalAsset.elastic += feeShare.toUint128();

            yieldBox.depositAsset(assetId, address(this), address(this), 0, feeShare);
        }
        if (callerShare > 0) {
            uint256 callerAmount = yieldBox.toAmount(assetId, callerShare, false);
            yieldBox.depositAsset(assetId, address(this), msg.sender, callerAmount, 0);
        }
    }

    struct __LiquidateUserData {
        uint256 callerReward;
        uint256 borrowAmount;
        uint256 borrowPart;
        uint256 collateralShare;
        uint256 borrowShare;
        uint256 returnedShare;
        uint256 extraShare;
        uint256 feeShare;
        uint256 callerShare;
    }

    function _liquidateUser(
        address user,
        uint256 maxBorrowPart,
        IMarketLiquidatorReceiver _liquidatorReceiver,
        bytes calldata _liquidatorReceiverData,
        uint256 _exchangeRate,
        uint256 minLiquidationBonus
    ) private {
        __LiquidateUserData memory data;

        data.callerReward = _getCallerReward(user, _exchangeRate);
        (data.borrowAmount, data.borrowPart, data.collateralShare) =
            _updateBorrowAndCollateralShare(user, maxBorrowPart, minLiquidationBonus, _exchangeRate);
        data.borrowShare = yieldBox.toShare(assetId, data.borrowAmount, true);

        {
            totalCollateralShare =
                totalCollateralShare > data.collateralShare ? totalCollateralShare - data.collateralShare : 0;
            totalBorrow.elastic -= data.borrowAmount.toUint128();
            totalBorrow.base -= data.borrowPart.toUint128();
        }

        {
            (data.returnedShare,) = _swapCollateralWithAsset(
                data.collateralShare, _liquidatorReceiver, _liquidatorReceiverData, _exchangeRate, true
            );
            if (data.returnedShare < data.borrowShare) revert AmountNotValid();

            data.extraShare = data.returnedShare > data.borrowShare ? data.returnedShare - data.borrowShare : 0;
            address(asset).safeApprove(address(yieldBox), type(uint256).max);
            yieldBox.depositAsset(assetId, address(this), address(this), 0, data.returnedShare - data.extraShare);
            totalAsset.elastic += (data.returnedShare - data.extraShare).toUint128();
            emit LogAddAsset(address(this), address(this), (data.returnedShare - data.extraShare), 0);

            (data.feeShare, data.callerShare) = _extractLiquidationFees(data.extraShare, data.callerReward);
            address(asset).safeApprove(address(yieldBox), 0);
            address[] memory _users = new address[](1);
            _users[0] = user;
            emit Liquidated(
                msg.sender, _users, data.callerShare, data.feeShare, data.borrowAmount, data.collateralShare
            );
        }
    }

    struct __ClosedLiquidationCalldata {
        address user;
        uint256 maxBorrowPart;
        uint256 minLiquidationBonus;
        IMarketLiquidatorReceiver liquidatorReceiver;
    }

    function _closedLiquidation(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        uint256[] calldata minLiquidationBonuses,
        IMarketLiquidatorReceiver[] calldata liquidatorReceivers,
        bytes[] calldata liquidatorReceiverDatas,
        uint256 _exchangeRate
    ) private {
        uint256 liquidatedCount = 0;
        uint256 arrLength = users.length;

        __ClosedLiquidationCalldata memory calldata_; // Stack too deep fix

        for (uint256 i; i < arrLength;) {
            calldata_.user = users[i];
            calldata_.maxBorrowPart = maxBorrowParts[i];
            calldata_.minLiquidationBonus = minLiquidationBonuses[i];
            calldata_.liquidatorReceiver = liquidatorReceivers[i];

            if (!_isSolvent(calldata_.user, _exchangeRate, true)) {
                liquidatedCount++;
                _liquidateUser(
                    calldata_.user,
                    calldata_.maxBorrowPart,
                    calldata_.liquidatorReceiver,
                    liquidatorReceiverDatas[i],
                    _exchangeRate,
                    calldata_.minLiquidationBonus
                );
            }
            unchecked {
                ++i;
            }
        }

        require(liquidatedCount != 0, "BB: no users found");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {BoringERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {ISingularity} from "tapioca-periph/interfaces/bar/ISingularity.sol";
import {Market, MarketERC20} from "../Market.sol";

// solhint-disable max-line-length

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract SGLStorage is Ownable, Market, ReentrancyGuard {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;
    using SafeCast for uint256;

    // ************ //
    // *** VARS *** //
    // ************ //
    /// @notice information about the accrual info
    ISingularity.AccrueInfo public accrueInfo;
    /// @notice total assets share & amount
    Rebase public totalAsset; // elastic = yieldBox shares held by the Singularity, base = Total fractions held by asset suppliers

    uint256 public minimumTargetUtilization;
    uint256 public maximumTargetUtilization;

    uint64 public minimumInterestPerSecond;
    uint64 public maximumInterestPerSecond;
    uint256 public interestElasticity;
    uint64 public startingInterestPerSecond;

    /// @notice borrowing opening fee
    uint256 public borrowOpeningFee = 50; //0.05%

    address public interestHelper;

    uint256 public minLendAmount;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    /// @notice event emitted when borrow opening fee is updated
    event LogBorrowingFee(uint256 indexed _oldVal, uint256 indexed _newVal);
    /// @notice event emitted when accrual happens
    event LogAccrue(
        uint256 indexed accruedAmount, uint256 indexed feeFraction, uint64 indexed rate, uint256 utilization
    );
    /// @notice event emitted when collateral is added
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    /// @notice event emitted when asset is added
    event LogAddAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    /// @notice event emitted when collateral is removed
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    /// @notice event emitted when asset is removed
    event LogRemoveAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    /// @notice event emitted when asset is borrowed
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 feeAmount, uint256 part);
    /// @notice event emitted when asset is repayed
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    /// @notice event emitted when fees are extracted
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    /// @notice event emitted when the minimum target utilization is updated
    event MinimumTargetUtilizationUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the maximum target utilization is updated
    event MaximumTargetUtilizationUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the minimum interest per second is updated
    event MinimumInterestPerSecondUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the maximum interest per second is updated
    event MaximumInterestPerSecondUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the interest elasticity updated
    event InterestElasticityUpdated(uint256 oldVal, uint256 newVal);
    /// @notice event emitted when the interest helper is updated
    event InterestHelperUpdated(address oldVal, address newVal);
    /// @notice event emitted when the `minLendAmount` is updated
    event MinLendAmountUpdate(uint256 _oldVal, uint256 _newVal);

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    constructor() MarketERC20("Tapioca Singularity") {}

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns market's ERC20 symbol
    function symbol() external view returns (string memory) {
        return string(abi.encodePacked("tm-", collateral.safeSymbol()));
    }

    /// @notice returns market's ERC20 name
    function name() external view returns (string memory) {
        return string(abi.encodePacked("Tapioca Singularity-", collateral.safeName()));
    }

    /// @notice returns market's ERC20 decimals
    function decimals() external view returns (uint8) {
        return asset.safeDecimals();
    }

    /// @notice returns market's ERC20 totalSupply
    /// @dev totalSupply for ERC20 compatibility
    ///      BalanceOf[user] represent a fraction
    function totalSupply() public view virtual override returns (uint256) {
        return totalAsset.base;
    }

    function _accrue() internal virtual override {}

    function _accrueView() internal view virtual override returns (Rebase memory) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import {IERC20} from "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Tapioca
import {ILeverageExecutor} from "tapioca-periph/interfaces/bar/ILeverageExecutor.sol";
import {ITapiocaOracle} from "tapioca-periph/interfaces/periph/ITapiocaOracle.sol";
import {IPenrose} from "tapioca-periph/interfaces/bar/IPenrose.sol";
import {Module} from "tapioca-periph/interfaces/bar/IMarket.sol";
import {MarketStateView} from "../MarketStateView.sol";
import {SGLLiquidation} from "./SGLLiquidation.sol";
import {SGLCollateral} from "./SGLCollateral.sol";
import {MarketERC20} from "../MarketERC20.sol";
import {SGLLeverage} from "./SGLLeverage.sol";
import {SGLStorage} from "./SGLStorage.sol";
import {SGLCommon} from "./SGLCommon.sol";
import {SGLBorrow} from "./SGLBorrow.sol";

// solhint-disable max-line-length

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/// @title Tapioca market
contract Singularity is MarketStateView, SGLCommon {
    using SafeCast for uint256;
    using RebaseLibrary for Rebase;

    // ************ //
    // *** VARS *** //
    // ************ //
    /// @notice returns the liquidation module
    SGLLiquidation public liquidationModule;
    /// @notice returns the borrow module
    SGLBorrow public borrowModule;
    /// @notice returns the collateral module
    SGLCollateral public collateralModule;
    /// @notice returns the leverage module
    SGLLeverage public leverageModule;

    /**
     * Struct are used in SGLInit.sol
     */
    struct _InitMemoryData {
        IPenrose penrose_;
        ITapiocaOracle _oracle;
        uint256 _exchangeRatePrecision;
        uint256 _collateralizationRate;
        uint256 _liquidationCollateralizationRate;
        ILeverageExecutor _leverageExecutor;
    }

    struct _InitMemoryModulesData {
        address _liquidationModule;
        address _borrowModule;
        address _collateralModule;
        address _leverageModule;
    }

    struct _InitMemoryTokensData {
        IERC20 _asset;
        uint256 _assetId;
        IERC20 _collateral;
        uint256 _collateralId;
    }

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotValid();
    error ModuleNotSet();
    error NotAuthorized();
    error SameState();
    error MinLendAmountNotMet();

    function totalSupply() public view override(MarketERC20, SGLStorage) returns (uint256) {
        return totalAsset.base;
    }

    /**
     * @notice Initializes the Singularity contract via the SGLInit contract
     */
    function init(address sglInit, bytes calldata initData) external onlyOnce {
        (bool success,) = sglInit.delegatecall(abi.encodeWithSignature("init(bytes)", initData));
        require(success, "Init failed");
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Allows batched call to Singularity.
    /// @param calls An array encoded call data.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    /// @return successes count of successful operations
    /// @return results array of revert messages
    function execute(Module[] calldata modules, bytes[] calldata calls, bool revertOnFail)
        external
        nonReentrant
        returns (bool[] memory successes, bytes[] memory results)
    {
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        if (modules.length != calls.length) revert NotValid();
        for (uint256 i; i < calls.length; i++) {
            (bool success, bytes memory result) = _extractModule(modules[i]).delegatecall(calls[i]);

            if (!success && revertOnFail) {
                revert(abi.decode(_getRevertMsg(result), (string)));
            }
            successes[i] = success;
            results[i] = !success ? _getRevertMsg(result) : result;
        }
    }

    /// @notice Adds assets to the lending pair.
    /// @param from Address to add asset from.
    /// @param to The address of the user to receive the assets.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add.
    /// @return fraction Total fractions added.
    function addAsset(address from, address to, bool skim, uint256 share)
        external
        optionNotPaused(PauseType.AddAsset)
        allowedLend(from, share)
        returns (uint256 fraction)
    {
        uint256 _amount = yieldBox.toAmount(assetId, share, false);
        if (_amount <= minLendAmount) revert MinLendAmountNotMet();

        _accrue();
        fraction = _addAsset(from, to, skim, share);
    }

    /// @notice Removes an asset from `from` and transfers it to `to`.
    /// @param from Account to debit assets from.
    /// @param to The user that receives the removed assets.
    /// @param fraction The amount/fraction of assets held to remove.
    /// @return share The amount of shares transferred to `to`.
    function removeAsset(address from, address to, uint256 fraction)
        external
        optionNotPaused(PauseType.RemoveAsset)
        returns (uint256 share)
    {
        _accrue();
        share = _removeAsset(from, to, fraction);
        _allowedLend(from, share);
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice updates the pause state of the contract
    /// @dev can only be called by the conservator
    /// @param val the new value
    function updatePause(PauseType _type, bool val, bool resetAccrueTimestmap) external {
        if (!penrose.cluster().hasRole(msg.sender, keccak256("PAUSABLE")) && msg.sender != owner()) {
            revert NotAuthorized();
        }
        if (val == pauseOptions[_type]) revert SameState();
        emit PausedUpdated(_type, pauseOptions[_type], val);
        pauseOptions[_type] = val;

        if (val) {
            _accrue();
        }

        // In case of 'unpause', `lastAccrued` is set to block.timestamp
        // Valid for all action types that has an impact on debt or supply
        if (!val && (_type != PauseType.AddCollateral && _type != PauseType.RemoveCollateral)) {
            accrueInfo.lastAccrued = resetAccrueTimestmap ? block.timestamp.toUint64() : accrueInfo.lastAccrued;
        }
    }

    /// @notice rescues unused ETH from the contract
    /// @param amount the amount to rescue
    /// @param to the recipient
    function rescueEth(uint256 amount, address to) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Transfers fees to penrose
    /// @dev can only be called by the owner
    /// @return feeShares the amount of fees in shares withdrawn under Penrose
    function refreshPenroseFees() external onlyOwner returns (uint256 feeShares) {
        address _feeTo = address(penrose);
        // withdraw the fees accumulated in `accrueInfo.feesEarnedFraction` to the balance of `feeTo`.
        if (accrueInfo.feesEarnedFraction > 0) {
            _accrue();
            uint256 _feesEarnedFraction = accrueInfo.feesEarnedFraction;
            balanceOf[_feeTo] += _feesEarnedFraction;
            emit Transfer(address(0), _feeTo, _feesEarnedFraction);
            accrueInfo.feesEarnedFraction = 0;
            emit LogWithdrawFees(_feeTo, _feesEarnedFraction);
        }

        feeShares = _removeAsset(_feeTo, msg.sender, balanceOf[_feeTo]);
    }

    /// @notice sets Singularity specific configuration
    /// @dev values are updated only if > 0 or not address(0)
    ///     - borrowOpeningFee is always updated!
    function setSingularityConfig(
        uint256 _borrowOpeningFee,
        uint256 _liquidationMultiplier,
        uint256 _minimumTargetUtilization,
        uint256 _maximumTargetUtilization,
        uint64 _minimumInterestPerSecond,
        uint64 _maximumInterestPerSecond,
        uint256 _interestElasticity,
        address _interestHelper,
        uint256 _minLendAmount
    ) external onlyOwner {
        // this needs to be set first
        // if `interestHelper` is address(0), the next _accrue() call won't work
        if (_interestHelper != address(0)) {
            emit InterestHelperUpdated(interestHelper, _interestHelper);
            interestHelper = _interestHelper;
        }

        _accrue();

        if (_borrowOpeningFee > FEE_PRECISION) revert NotValid();
        emit LogBorrowingFee(borrowOpeningFee, _borrowOpeningFee);
        borrowOpeningFee = _borrowOpeningFee;

        if (_minimumTargetUtilization > 0) {
            emit MinimumTargetUtilizationUpdated(minimumTargetUtilization, _minimumTargetUtilization);
            minimumTargetUtilization = _minimumTargetUtilization;
        }

        if (_maximumTargetUtilization > 0) {
            if (_maximumTargetUtilization >= 1e18) {
                //1e18 = FULL_UTILIZATION
                revert NotValid();
            }

            emit MaximumTargetUtilizationUpdated(maximumTargetUtilization, _maximumTargetUtilization);
            maximumTargetUtilization = _maximumTargetUtilization;
        }

        if (_minimumInterestPerSecond > 0) {
            if (_minimumInterestPerSecond >= maximumInterestPerSecond) {
                revert NotValid();
            }
            emit MinimumInterestPerSecondUpdated(minimumInterestPerSecond, _minimumInterestPerSecond);
            minimumInterestPerSecond = _minimumInterestPerSecond;
        }

        if (_maximumInterestPerSecond > 0) {
            if (_maximumInterestPerSecond <= minimumInterestPerSecond) {
                revert NotValid();
            }
            emit MaximumInterestPerSecondUpdated(maximumInterestPerSecond, _maximumInterestPerSecond);
            maximumInterestPerSecond = _maximumInterestPerSecond;
        }

        if (_interestElasticity > 0) {
            emit InterestElasticityUpdated(interestElasticity, _interestElasticity);
            interestElasticity = _interestElasticity;
        }

        if (_liquidationMultiplier > 0) {
            if (_liquidationMultiplier > FEE_PRECISION) revert NotValid();
            emit LiquidationMultiplierUpdated(liquidationMultiplier, _liquidationMultiplier);
            liquidationMultiplier = _liquidationMultiplier;
        }

        if (_minLendAmount > 0) {
            emit MinLendAmountUpdate(minLendAmount, _minLendAmount);
            minLendAmount = _minLendAmount;
        }
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _extractModule(Module _module) private view returns (address) {
        address module;
        if (_module == Module.Base) {
            return address(this);
        } else if (_module == Module.Borrow) {
            module = address(borrowModule);
        } else if (_module == Module.Collateral) {
            module = address(collateralModule);
        } else if (_module == Module.Liquidation) {
            module = address(liquidationModule);
        } else if (_module == Module.Leverage) {
            module = address(leverageModule);
        }
        if (module == address(0)) revert ModuleNotSet();

        return module;
    }

    /// @dev Concrete implementation of `addAsset`.
    function _addAsset(address from, address to, bool skim, uint256 share) private returns (uint256 fraction) {
        Rebase memory _totalAsset = totalAsset;
        uint256 totalAssetShare = _totalAsset.elastic;
        uint256 allShare = _totalAsset.elastic + yieldBox.toShare(assetId, totalBorrow.elastic, true);
        fraction = allShare == 0 ? share : (share * _totalAsset.base) / allShare;
        if (_totalAsset.base + fraction.toUint128() < 1000) {
            return 0;
        }
        totalAsset = _totalAsset.add(share, fraction);

        balanceOf[to] += fraction;
        emit Transfer(address(0), to, fraction);

        _addTokens(from, to, assetId, share, totalAssetShare, skim);
        emit LogAddAsset(skim ? address(yieldBox) : from, to, share, fraction);
    }

    /// @dev Concrete implementation of `removeAsset`.
    /// @param from The account to remove from. Should always be msg.sender except for `depositFeesToyieldBox()`.
    function _removeAsset(address from, address to, uint256 fraction) private returns (uint256 share) {
        if (totalAsset.base == 0) {
            return 0;
        }
        Rebase memory _totalAsset = totalAsset;
        uint256 allShare = _totalAsset.elastic + yieldBox.toShare(assetId, totalBorrow.elastic, false);
        share = (fraction * allShare) / _totalAsset.base;

        _totalAsset.base -= fraction.toUint128();
        if (_totalAsset.base < 1000) revert MinLimit();

        balanceOf[from] -= fraction;
        emit Transfer(from, address(0), fraction);
        _totalAsset.elastic -= share.toUint128();
        totalAsset = _totalAsset;
        emit LogRemoveAsset(from, to, share, fraction);
        yieldBox.transfer(address(this), to, assetId, share);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ILeverageExecutor {
    function swapper() external view returns (address);

    function cluster() external view returns (address);

    function yieldBox() external view returns (address);

    function getCollateral(
        address refundDustAddress,
        address assetAddress,
        address collateralAddress,
        uint256 assetAmountIn,
        bytes calldata data
    ) external returns (uint256 collateralAmountOut); //used for buyCollateral

    function getAsset(
        address refundDustAddress,
        address collateralAddress,
        address assetAddress,
        uint256 collateralAmountIn,
        bytes calldata data
    ) external returns (uint256 assetAmountOut); //used for sellCollateral
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

/// @notice enum representing each type of module associated with a Singularity market
/// @dev modules are contracts that holds a portion of the market's logic
enum Module {
    Base,
    Borrow,
    Collateral,
    Liquidation,
    Leverage
}

interface IMarket {
    function _asset() external view returns (address);

    function _assetId() external view returns (uint256);

    function _collateral() external view returns (address);

    function _collateralId() external view returns (uint256);

    function _totalBorrowCap() external view returns (uint256);

    function _totalCollateralShare() external view returns (uint256);

    function _userBorrowPart(address) external view returns (uint256);

    function _userCollateralShare(address) external view returns (uint256);

    function _totalBorrow() external view returns (uint128 elastic, uint128 base);

    function _oracle() external view returns (address);

    function _oracleData() external view returns (bytes memory);

    function _exchangeRate() external view returns (uint256);

    function _liquidationMultiplier() external view returns (uint256);

    function _penrose() external view returns (address);

    function _collateralizationRate() external view returns (uint256);

    function _liquidationBonusAmount() external view returns (uint256);

    function _liquidationCollateralizationRate() external view returns (uint256);

    function _yieldBox() external view returns (address payable);

    function _exchangeRatePrecision() external view returns (uint256);

    function _minBorrowAmount() external view returns (uint256);

    function _minCollateralAmount() external view returns (uint256);

    function computeClosingFactor(uint256 borrowPart, uint256 collateralPartInAsset, uint256 ratesPrecision)
        external
        view
        returns (uint256);

    function refreshPenroseFees() external returns (uint256 feeShares);

    function updateExchangeRate() external;
    
    function accrue() external;

    function owner() external view returns (address);

    function execute(Module[] calldata modules, bytes[] calldata calls, bool revertOnFail)
        external
        returns (bool[] memory successes, bytes[] memory results);

    function updatePause(uint256 _type, bool val) external;

    function updatePauseAll(bool val) external; //Not available for Singularity
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IMarketLiquidatorReceiver {
    function onCollateralReceiver(
        address initiator,
        address tokenIn,
        address tokenOut,
        uint256 collateralAmount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPearlmit} from "../periph/IPearlmit.sol";
import {ICluster} from "../periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPenrose {
    /// @notice swap extra data
    struct SwapData {
        uint256 minAssetAmount;
    }

    /// @notice Used to define the MasterContract's type
    enum ContractType {
        lowRisk,
        mediumRisk,
        highRisk
    }

    /// @notice MasterContract address and type
    struct MasterContract {
        address location;
        ContractType risk;
    }

    function viewTotalDebt() external view returns (uint256);

    function computeTotalDebt() external returns (uint256 totalUsdoDebt);

    function mintOpenInterestDebt(address twTap) external;

    function bigBangEthMarket() external view returns (address);

    function bigBangEthDebtRate() external view returns (uint256);

    function yieldBox() external view returns (address payable);

    function tapToken() external view returns (address);

    function tapAssetId() external view returns (uint256);

    function usdoToken() external view returns (address);

    function usdoAssetId() external view returns (uint256);

    function feeTo() external view returns (address);

    function mainToken() external view returns (address);

    function mainAssetId() external view returns (uint256);

    function isMarketRegistered(address market) external view returns (bool);

    function cluster() external view returns (ICluster);

    function pearlmit() external view returns (IPearlmit);

    function reAccrueBigBangMarkets() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {RebaseLibrary, Rebase} from "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

// Tapioca
import {IYieldBox} from "tapioca-periph/interfaces/yieldbox/IYieldBox.sol";
import {ISingularity, IMarket} from "tapioca-periph/interfaces/bar/ISingularity.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ISGLInterestHelper {
    struct InterestRateCall {
        IYieldBox yieldBox;
        ISingularity.AccrueInfo accrueInfo;
        uint256 assetId;
        Rebase totalAsset;
        Rebase totalBorrow;
        uint256 protocolFee;
        uint256 interestElasticity;
        uint256 minimumTargetUtilization;
        uint256 maximumTargetUtilization;
        uint64 minimumInterestPerSecond;
        uint64 maximumInterestPerSecond;
        uint64 startingInterestPerSecond;
    }

    function getInterestRate(InterestRateCall memory data)
        external
        view
        returns (
            ISingularity.AccrueInfo memory _accrueInfo,
            Rebase memory _totalBorrow,
            Rebase memory _totalAsset,
            uint256 extraAmount,
            uint256 feeFraction,
            uint256 utilization
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IMarket} from "./IMarket.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ISingularity is IMarket {
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    function minLendAmount() external view returns (uint256); 

    function accrueInfo()
        external
        view
        returns (uint64 interestPerSecond, uint64 lastBlockAccrued, uint128 feesEarnedFraction);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function addAsset(address from, address to, bool skim, uint256 share) external returns (uint256 fraction);

    function removeAsset(address from, address to, uint256 fraction) external returns (uint256 share);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(address owner_, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function liquidationQueue() external view returns (address payable);

    function computeAllowedLendShare(uint256 amount, uint256 tokenId) external view returns (uint256 share);

    function getInterestDetails() external view returns (AccrueInfo memory _accrueInfo, uint256 utilization);

    function minimumTargetUtilization() external view returns (uint256);

    function maximumTargetUtilization() external view returns (uint256);

    function minimumInterestPerSecond() external view returns (uint256);

    function maximumInterestPerSecond() external view returns (uint256);

    function interestElasticity() external view returns (uint256);

    function startingInterestPerSecond() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ICluster {
    function isWhitelisted(uint32 lzChainId, address _addr) external view returns (bool);

    function updateContract(uint32 lzChainId, address _addr, bool _status) external;

    function batchUpdateContracts(uint32 _lzChainId, address[] memory _addresses, bool _status) external;

    function lzChainId() external view returns (uint32);

    function hasRole(address _contract, bytes32 _role) external view returns (bool);

    function setRoleForContract(address _contract, bytes32 _role, bool _hasRole) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface IPearlmit {
    struct SignatureApproval {
        uint256 tokenType; // 20 = ERC20, 721 = ERC721, 1155 = ERC1155.
        address token; // Address of the token.
        uint256 id; // ID of the token (0 if ERC20).
        uint200 amount; // Amount of the token (0 if ERC721).
        address operator; // Address of the operator to transfer the tokens to.
    }

    struct PermitBatchTransferFrom {
        SignatureApproval[] approvals; // Array of SignatureApproval structs.
        address owner; // Address of the owner of the tokens.
        uint256 nonce; // Nonce of the owner.
        uint48 sigDeadline; // Deadline for the signature.
        uint256 masterNonce; // Master nonce of the owner.
        bytes signedPermit; // Signature of the permit. (Not present in the TYPEHASH)
        address executor; // Address of the allowed executor of the permit.
        // In the case of Tapioca, it'll be the `msg.sender` from src chain, checked against `TOE` trusted `srcChainSender`.
        bytes32 hashedData; // Hashed data that comes with the permit execution. See more in Pearlmit.sol.
    }

    function approve(uint256 tokenType, address token, uint256 id, address operator, uint200 amount, uint48 expiration)
        external;

    function allowance(address owner, address operator, uint256 tokenType, address token, uint256 id)
        external
        view
        returns (uint256 allowedAmount, uint256 expiration);

    function clearAllowance(address owner, uint256 tokenType, address token, uint256 id) external;

    function permitBatchTransferFrom(PermitBatchTransferFrom calldata batch, bytes32 hashedData)
        external
        returns (bool[] memory errorStatus);

    function permitBatchApprove(PermitBatchTransferFrom calldata batch, bytes32 hashedData) external;

    function transferFromERC1155(address owner, address to, address token, uint256 id, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC20(address owner, address to, address token, uint256 amount)
        external
        returns (bool isError);

    function transferFromERC721(address owner, address to, address token, uint256 id) external returns (bool isError);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

struct ISeerQuery {
    bool useHigh; // Whether to use the high or low value
}

interface ITapiocaOracle {
    // @notice Precision of the return value.
    function decimals() external view returns (uint8);

    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum IYieldBoxTokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!

interface IYieldBox {
    error AmountTooLow();
    error AssetNotValid();
    error ForbiddenAction();
    error InvalidShortString();
    error InvalidTokenType();
    error NotSet();
    error NotWrapped();
    error RefundFailed();
    error StringTooLong(string str);
    error ZeroAddress();

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event ApprovalForAsset(address indexed sender, address indexed operator, uint256 assetId, bool approved);
    event AssetRegistered(
        uint8 indexed tokenType,
        address indexed contractAddress,
        address strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );
    event Deposited(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut,
        bool isNFT
    );
    event EIP712DomainChanged();
    event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);
    event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId);
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );
    event URI(string _value, uint256 indexed _id);
    event Withdraw(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256 assetId,
        uint256 amountIn,
        uint256 shareIn,
        uint256 amountOut,
        uint256 shareOut
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function amountOf(address user, uint256 assetId) external view returns (uint256 amount);

    function assetCount() external view returns (uint256);

    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount);

    function assets(uint256)
        external
        view
        returns (IYieldBoxTokenType tokenType, address contractAddress, address strategy, uint256 tokenId);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function batch(bytes[] memory calls, bool revertOnFail) external payable;

    function batchBurn(uint256 tokenId, address[] memory froms, uint256[] memory amounts) external;

    function batchMint(uint256 tokenId, address[] memory tos, uint256[] memory amounts) external;

    function batchTransfer(address from, address to, uint256[] memory assetIds_, uint256[] memory shares_) external;

    function burn(uint256 tokenId, address from, uint256 amount) external;

    function claimOwnership(uint256 tokenId) external;

    function createToken(string memory name, string memory symbol, uint8 decimals, string memory uri)
        external
        returns (uint32 tokenId);

    function decimals(uint256 assetId) external view returns (uint8);

    function deposit(
        IYieldBoxTokenType tokenType,
        address contractAddress,
        address strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function depositAsset(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function depositETH(address strategy, address to, uint256 amount)
        external
        payable
        returns (uint256 amountOut, uint256 shareOut);

    function depositETHAsset(uint256 assetId, address to, uint256 amount)
        external
        payable
        returns (uint256 amountOut, uint256 shareOut);

    function depositNFTAsset(uint256 assetId, address from, address to)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    function ids(IYieldBoxTokenType tokenType, address contractAddr, address strategy, uint256 tokenId)
        external
        view
        returns (uint256);

    function isApprovedForAll(address, address) external view returns (bool);

    function isApprovedForAsset(address, address, uint256) external view returns (bool);

    function mint(uint256 tokenId, address to, uint256 amount) external;

    function name(uint256 assetId) external view returns (string memory);

    function nativeTokens(uint256)
        external
        view
        returns (string memory name, string memory symbol, uint8 decimals, string memory uri);

    function nonces(address owner) external view returns (uint256);

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        pure
        returns (bytes4);

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4);

    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4);

    function owner(uint256) external view returns (address);

    function pendingOwner(uint256) external view returns (address);

    function permit(address owner, address spender, uint256 assetId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function permitAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function permitToken(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerAsset(IYieldBoxTokenType tokenType, address contractAddress, address strategy, uint256 tokenId)
        external
        returns (uint256 assetId);

    function revoke(address owner, address spender, uint256 assetId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function revokeAll(address owner, address spender, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setApprovalForAsset(address operator, uint256 assetId, bool approved) external;

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

    function symbol(uint256 assetId) external view returns (string memory);

    function toAmount(uint256 assetId, uint256 share, bool roundUp) external view returns (uint256 amount);

    function toShare(uint256 assetId, uint256 amount, bool roundUp) external view returns (uint256 share);

    function totalSupply(uint256) external view returns (uint256);

    function transfer(address from, address to, uint256 assetId, uint256 share) external;

    function transferMultiple(address from, address[] memory tos, uint256 assetId, uint256[] memory shares) external;

    function transferOwnership(uint256 tokenId, address newOwner, bool direct, bool renounce) external;

    function uri(uint256 assetId) external view returns (string memory);

    function uriBuilder() external view returns (address);

    function withdraw(uint256 assetId, address from, address to, uint256 amount, uint256 share)
        external
        returns (uint256 amountOut, uint256 shareOut);

    function wrappedNative() external view returns (address);
}
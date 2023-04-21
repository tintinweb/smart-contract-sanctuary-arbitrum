// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PMT} from "oz-custom/contracts/presets/token/PMT.sol";

contract USDC is PMT {
    constructor() PMT("Coinbase USD", "USDC") {
        _mint(_msgSender(), 100_000_000 ether);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISignable {
    error Signable__InvalidSignature();

    event NonceIncremented(
        address indexed operator,
        bytes32 indexed id,
        uint256 indexed value
    );

    /**
     * @dev Returns the domain separator for EIP712 v4
     * @return Domain separator for EIP712 v4
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";
import {ECDSA, EIP712} from "../oz/utils/cryptography/draft-EIP712.sol";

import {ISignable} from "./interfaces/ISignable.sol";

import {Bytes32Address} from "../libraries/Bytes32Address.sol";

/**
 * @title Signable
 * @dev Abstract contract for signing and verifying typed data.
 */
abstract contract Signable is Context, EIP712, ISignable {
    using ECDSA for bytes32;
    using Bytes32Address for address;

    /**
     * @dev Mapping of nonces for each id
     */
    mapping(bytes32 => uint256) internal _nonces;

    /**
     * @dev Constructor that initializes EIP712 with the given name and version
     * @param name_ Name of the typed data
     * @param version_ Version of the typed data
     */
    constructor(
        string memory name_,
        string memory version_
    ) payable EIP712(name_, version_) {}

    /**
     * @dev Verifies that the signer of the typed data is the given address
     * @param verifier_ Address to verify
     * @param structHash_ Hash of the typed data
     * @param signature_ Signature of the typed data
     */
    function _verify(
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        if (_recoverSigner(structHash_, signature_) != verifier_)
            revert Signable__InvalidSignature();
    }

    /**
     * @dev Verifies that the signer of the typed data is the given address
     * @param verifier_ Address to verify
     * @param structHash_ Hash of the typed data
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     */
    function _verify(
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (_recoverSigner(structHash_, v, r, s) != verifier_)
            revert Signable__InvalidSignature();
    }

    /**
     * @dev Recovers the signer of the typed data from the signature
     * @param structHash_ Hash of the typed data
     * @param signature_ Signature of the typed data
     * @return Address of the signer
     */
    function _recoverSigner(
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(signature_);
    }

    /**
     * @dev Recovers the signer of the typed data from the signature
     * @param structHash_ Hash of the typed data
     * @param v ECDSA recovery value
     * @param r ECDSA r value
     * @param s ECDSA s value
     * @return Address of the signer
     */
    function _recoverSigner(
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(v, r, s);
    }

    /**
     * @dev Increases the nonce for the given account by 1
     * @param id_ ID to increase the nonce for
     * @return nonce The new nonce for the account
     */
    function _useNonce(bytes32 id_) internal virtual returns (uint256 nonce) {
        address sender = _msgSender();
        assembly {
            mstore(0x00, id_)
            mstore(0x20, _nonces.slot)
            let key := keccak256(0x00, 0x40)
            nonce := sload(key)
            sstore(key, add(nonce, 1))

            log4(
                0x00,
                0x00,
                /// @dev value is equal to keccak256("NonceIncremented(address,bytes32,uint256)")
                0x81950aaf2c3573be1f953223448244747f16268d5a0573dea6bd6fa249a4c86e,
                sender,
                id_,
                nonce
            )
        }
    }

    /// @inheritdoc ISignable
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.17;

import {ERC20, ERC20Permit, IERC20Permit} from "./ERC20Permit.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "../ERC20.sol";

import {Signable, Bytes32Address} from "../../../../internal/Signable.sol";

import {IERC20Permit} from "./IERC20Permit.sol";

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
abstract contract ERC20Permit is ERC20, IERC20Permit, Signable {
    using Bytes32Address for address;

    // solhint-disable-next-line var-name-mixedcase
    /// @dev value is equal to keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 private constant __PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) payable Signable(name_, "1") ERC20(name_, symbol_) {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        bytes32 digest;
        bytes32 allowanceKey;
        assembly {
            // if (block.timestamp > deadline) revert ERC20Permit__Expired();
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x614fe41d)
                revert(0x1c, 0x04)
            }

            mstore(0x00, owner)
            mstore(0x20, _nonces.slot)
            let nonceKey := keccak256(0x00, 0x40)
            let nonce := sload(nonceKey)

            let freeMemPtr := mload(0x40)

            mstore(freeMemPtr, __PERMIT_TYPEHASH)
            mstore(add(freeMemPtr, 0x20), owner)
            mstore(add(freeMemPtr, 0x40), spender)
            mstore(add(freeMemPtr, 0x60), value)
            mstore(add(freeMemPtr, 0x80), nonce)
            mstore(add(freeMemPtr, 0xa0), deadline)
            digest := keccak256(freeMemPtr, 0xc0)

            sstore(nonceKey, add(1, nonce))

            mstore(0x20, _allowance.slot)
            allowanceKey := keccak256(0x00, 0x40)
        }

        _verify(owner, digest, v, r, s);

        assembly {
            mstore(0x00, spender)
            mstore(0x20, allowanceKey)
            sstore(keccak256(0x00, 0x40), value)
        }
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     *

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR()
        external
        view
        override(IERC20Permit, Signable)
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    function nonces(address account_) external view returns (uint256 nonce) {
        assembly {
            mstore(0x00, account_)
            mstore(0x20, _nonces.slot)
            nonce := sload(keccak256(0x00, 0x40))
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.17;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    error ERC20Permit__Expired();

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ECDSA, EIP712} from "./EIP712.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            mstore(0x20, v)
            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    function recover(
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // Directly load `s` from the calldata.
            let s := calldataload(add(signature.offset, 0x20))

            switch signature.length
            case 64 {
                // Here, `s` is actually `vs` that needs to be recovered into `v` and `s`.
                // Compute `v` and store it in the scratch space.
                mstore(0x20, add(shr(255, s), 27))
                // prettier-ignore
                s := and(s, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            }
            case 65 {
                // Compute `v` and store it in the scratch space.
                mstore(
                    0x20,
                    byte(0, calldataload(add(signature.offset, 0x40)))
                )
            }

            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                calldatacopy(0x40, signature.offset, 0x20) // Directly copy `r` over.
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32 result) {
        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(
                memPtr,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(memPtr, 2), domainSeparator) // EIP712 domain hash
            mstore(add(memPtr, 34), structHash) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
    }

    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32 result) {
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    function toEthSignedMessageHash(
        bytes memory s
    ) internal pure returns (bytes32 result) {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes.
            // The next multiple of 32 above 78 + 26 is 128.

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            for {
                let temp := sLength
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            // Move the pointer 32 bytes lower to make room for the string.
            // `start` marks the start of the memory which we will compute the keccak256 of.
            let start := sub(ptr, 32)
            // Copy the header over to the memory.
            mstore(
                start,
                "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n"
            )
            start := add(start, 6)

            // Compute the keccak256 of the memory.
            result := keccak256(start, sub(end, start))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.17;

import {ECDSA} from "./ECDSA.sol";

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
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

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
    constructor(string memory name, string memory version) payable {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        ///@dev 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f is equal to keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")

        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
            hashedName,
            hashedVersion
        );
        _CACHED_THIS = address(this);
        _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID)
            return _CACHED_DOMAIN_SEPARATOR;
        else
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32 domainSeparatorV4) {
        assembly {
            mstore(0, typeHash)
            mstore(32, nameHash)
            mstore(64, versionHash)
            mstore(96, chainid())
            mstore(128, address())
            domainSeparatorV4 := keccak256(0, 160)
        }
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
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    ERC20Permit
} from "../../oz/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PMT is ERC20Permit {
    constructor(
        string memory name_,
        string memory symbol_
    ) payable ERC20Permit(name_, symbol_) {}

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }
}
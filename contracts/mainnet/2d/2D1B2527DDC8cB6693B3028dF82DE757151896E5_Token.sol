// SPDX-License-Identifier: AGPL-3.0-only
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)
// Solmate (tokens/ERC1155.sol)
// Derivable Contracts (ERC1155Maturity)

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import "./IERC1155Maturity.sol";
import "./libs/TimeBalance.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
/// @author Derivable (https://github.com/derivable-labs/erc1155-maturity)
contract ERC1155Maturity is IERC1155Maturity, IERC1155MetadataURI {
    using TimeBalance for uint;

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) internal s_timeBalances;
    mapping(address => mapping(address => bool)) internal s_approvals;

    mapping(uint256 => uint256) internal s_totalSupply;

    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /*//////////////////////////////////////////////////////////////
                             SUPPLY LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalSupply(uint256 id) public view override virtual returns (uint256) {
        return s_totalSupply[id];
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual override {
        s_approvals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(to != address(0), "ZERO_RECIPIENT");
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "NOT_AUTHORIZED");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        uint256 fromBalance = s_timeBalances[from][id];
        uint timelockAmount;
        (s_timeBalances[from][id], timelockAmount) = fromBalance.split(amount);
        s_timeBalances[to][id] = s_timeBalances[to][id].merge(timelockAmount);

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck( msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(to != address(0), "ZERO_RECIPIENT");
        uint256 idsLength = ids.length; // Saves MLOADs.
        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll(from, msg.sender), "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];

            uint timelockAmount;
            (s_timeBalances[from][id], timelockAmount) = s_timeBalances[from][id].split(amounts[i]);
            s_timeBalances[to][id] = s_timeBalances[to][id].merge(timelockAmount);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        return s_timeBalances[account][id].getBalance();
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return s_approvals[account][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                              MATURITY LOGIC
    //////////////////////////////////////////////////////////////*/
    function maturityOf(address account, uint256 id) public view virtual override returns (uint256) {
        return s_timeBalances[account][id].getTime();
    }

    /**
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function maturityOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "LENGTH_MISMATCH");

        uint256[] memory batchLocktimes = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchLocktimes[i] = maturityOf(accounts[i], ids[i]);
        }

        return batchLocktimes;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        uint256 time,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ZERO_RECIPIENT");
        uint timelockAmount = TimeBalance.pack(amount, time);
        s_timeBalances[to][id] = s_timeBalances[to][id].merge(timelockAmount);
        s_totalSupply[id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, amount, data);
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 time,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ZERO_RECIPIENT");
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < idsLength;) {
            id = ids[i];
            amount = amounts[i];

            uint timelockAmount = TimeBalance.pack(amount, time);
            s_timeBalances[to][id] = s_timeBalances[to][id].merge(timelockAmount);
            s_totalSupply[id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, amounts, data);
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < idsLength; ) {
            id = ids[i];
            amount = amounts[i];

            (s_timeBalances[from][id], ) = s_timeBalances[from][id].split(amount);
            s_totalSupply[id] -= amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        (s_timeBalances[from][id],) = s_timeBalances[from][id].split(amount);
        s_totalSupply[id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("RECEIVER_REJECTED");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("NON_RECEIVER");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("RECEIVER_REJECTED");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("NON_RECEIVER");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Derivable Contracts (token/ERC1155/IERC1155Maturity.sol)

pragma solidity 0.8.20;

import "./IERC1155Supply.sol";

interface IERC1155Maturity is IERC1155Supply {
    /**
     * @dev Returns the maturity time of tokens of token type `id` owned by `account`.
     *
     */
    function maturityOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {maturityOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function maturityOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Derivable Contracts (token/ERC1155/IERC1155Supply.sol)

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Supply is IERC1155 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";

library TimeBalance {
    uint256 constant TIME_MAX = type(uint32).max;
    uint256 constant TIME_MASK = TIME_MAX << 224;
    uint256 constant BALANCE_MAX = type(uint224).max;
    uint256 constant BALANCE_MASK = BALANCE_MAX;

    function merge(uint256 x, uint256 y) internal view returns (uint256 z) {
        unchecked {
            if (x == 0) {
                return y;
            }
            uint256 xTime = Math.max(block.timestamp, x >> 224);
            uint256 yTime = y >> 224;
            require(yTime <= xTime, "MATURITY_ORDER");
            uint256 yBalance = y & BALANCE_MASK;
            uint256 xBalance = x & BALANCE_MASK;
            uint256 zBalance = xBalance + yBalance;
            require(zBalance <= BALANCE_MAX, "NEW_BALANCE_OVERFLOW");
            return x + yBalance;
        }
    }

    function pack(uint256 balance, uint256 time) internal pure returns (uint256) {
        require(time <= type(uint32).max, "TIME_OVERFLOW");
        require(balance <= BALANCE_MAX, "BALANCE_OVERFLOW");
        return (time << 224) | balance;
    }

    function getBalance(uint256 x) internal pure returns (uint256) {
        return x & BALANCE_MASK;
    }

    function getTime(uint256 x) internal pure returns (uint256) {
        return x >> 224;
    }

    function split(uint256 z, uint256 yBalance) internal pure returns (uint256 x, uint256 y) {
        unchecked {
            uint256 zBalance = z & BALANCE_MASK;
            if (zBalance == yBalance) {
                return (0, z); // full transfer
            }
            require(zBalance > yBalance, "INSUFFICIENT_BALANCE");
            x = z - yBalance; // preserve the time
            y = (z & TIME_MASK) | yBalance;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@derivable/erc1155-maturity/contracts/token/ERC1155/IERC1155Maturity.sol";

interface IShadowFactory is IERC1155Maturity {
    function safeTransferFromByShadow(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function deployShadow(uint256 id) external returns (address shadowToken);

    function computeShadowAddress(uint256 id) external view returns (address);

    function getShadowName(uint256 id) external view returns (string memory);

    function getShadowSymbol(uint256 id) external view returns (string memory);

    function getShadowDecimals(uint256 id) external view returns (uint8);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.20;

library MetaProxy {
    /// @dev Creates a new proxy for `targetContract` with metadata from memory starting at `offset` and `length` bytes.
    /// @return addr A non-zero address if successful.
    function deploy(
        address targetContract,
        uint256 metadata
    ) internal returns (address addr) {
        // the following assembly code (init code + contract code) constructs a metaproxy.
        assembly {
            // load free memory pointer as per solidity convention
            let start := mload(64)
            // keep a copy
            let ptr := start
            // deploy code (11 bytes) + first part of the proxy (21 bytes)
            mstore(
                ptr,
                0x600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73
            )
            ptr := add(ptr, 32)

            // store the address of the contract to be called
            mstore(ptr, shl(96, targetContract))
            // 20 bytes
            ptr := add(ptr, 20)

            // the remaining proxy code...
            mstore(
                ptr,
                0x5af43d3d93803e603457fd5bf300000000000000000000000000000000000000
            )
            // ...13 bytes
            ptr := add(ptr, 13)

            // copy the metadata
            mstore(ptr, metadata)
            ptr := add(ptr, 32)

            // The size is deploy code + contract code + 32.
            addr := create2(0, start, sub(ptr, start), 0)
        }
    }

    function computeBytecodeHash(
        address targetContract,
        uint256 metadata
    ) internal pure returns (bytes32 bytecodeHash) {
        // the following assembly code (init code + contract code) constructs a metaproxy.
        assembly {
            // load free memory pointer as per solidity convention
            let start := mload(64)
            // keep a copy
            let ptr := start
            // deploy code (11 bytes) + first part of the proxy (21 bytes)
            mstore(
                ptr,
                0x600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73
            )
            ptr := add(ptr, 32)

            // store the address of the contract to be called
            mstore(ptr, shl(96, targetContract))
            // 20 bytes
            ptr := add(ptr, 20)

            // the remaining proxy code...
            mstore(
                ptr,
                0x5af43d3d93803e603457fd5bf300000000000000000000000000000000000000
            )
            // ...13 bytes
            ptr := add(ptr, 13)

            // copy the metadata
            mstore(ptr, metadata)
            ptr := add(ptr, 32)

            // The size is deploy code + contract code + 32.
            bytecodeHash := keccak256(start, sub(ptr, start))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@derivable/erc1155-maturity/contracts/token/ERC1155/IERC1155Supply.sol";

import "./interfaces/IShadowFactory.sol";

contract Shadow is IERC20, IERC20Metadata {
    address public immutable FACTORY;

    mapping(address => mapping(address => uint256)) private s_allowances;

    constructor(address factory) {
        require(factory != address(0), "Shadow: Address Zero");
        FACTORY = factory;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        if (!IERC1155(FACTORY).isApprovedForAll(msg.sender, spender)) {
            _approve(msg.sender, spender, amount);
        }
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        IShadowFactory(FACTORY).safeTransferFromByShadow(
            msg.sender,
            to,
            ID(),
            amount
        );
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        _spendAllowance(from, msg.sender, amount);
        IShadowFactory(FACTORY).safeTransferFromByShadow(
            from,
            to,
            ID(),
            amount
        );
        emit Transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        if (currentAllowance != type(uint256).max) {
            _approve(msg.sender, spender, currentAllowance + addedValue);
        }
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: insufficient allowance"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function name() public view virtual override returns (string memory) {
        return IShadowFactory(FACTORY).getShadowName(ID());
    }

    function symbol() public view virtual override returns (string memory) {
        return IShadowFactory(FACTORY).getShadowSymbol(ID());
    }

    function decimals() public view virtual override returns (uint8) {
        return IShadowFactory(FACTORY).getShadowDecimals(ID());
    }

    function totalSupply() public view override returns (uint256) {
        return IERC1155Supply(FACTORY).totalSupply(ID());
    }

    function balanceOf(address account) public view override returns (uint256) {
        return IERC1155(FACTORY).balanceOf(account, ID());
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        if (IERC1155(FACTORY).isApprovedForAll(owner, spender)) {
            return type(uint256).max;
        }
        return s_allowances[owner][spender];
    }

    /// @notice Returns the metadata of this (MetaProxy) contract.
    /// Only relevant with contracts created via the MetaProxy standard.
    /// @dev This function is aimed to be invoked with- & without a call.
    function ID() public pure returns (uint256 id) {
        assembly {
            id := calldataload(sub(calldatasize(), 32))
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        s_allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@derivable/erc1155-maturity/contracts/token/ERC1155/ERC1155Maturity.sol";

import "./Shadow.sol";
import "./interfaces/IShadowFactory.sol";
import "./MetaProxy.sol";

contract ShadowFactory is IShadowFactory, ERC1155Maturity {
    address internal immutable CODE;

    modifier onlyShadow(uint256 id) {
        address shadowToken = computeShadowAddress(id);
        require(msg.sender == shadowToken, "Shadow: UNAUTHORIZED");
        _;
    }

    constructor(string memory uri) ERC1155Maturity(uri) {
        CODE = address(new Shadow{salt: 0}(address(this)));
    }

    function deployShadow(uint256 id) external returns (address shadowToken) {
        shadowToken = MetaProxy.deploy(CODE, id);
        require(shadowToken != address(0), "ShadowFactory: Failed on deploy");
    }

    function safeTransferFromByShadow(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) public virtual override onlyShadow(id) {
        return _safeTransferFrom(from, to, id, amount, "");
    }

    function computeShadowAddress(
        uint256 id
    ) public view override returns (address pool) {
        bytes32 bytecodeHash = MetaProxy.computeBytecodeHash(CODE, id);
        return Create2.computeAddress(0, bytecodeHash, address(this));
    }

    function getShadowName(
        uint256
    ) public view virtual returns (string memory) {
        return "Derivable Shadow Token";
    }

    function getShadowSymbol(
        uint256
    ) public view virtual returns (string memory) {
        return "DST";
    }

    function getShadowDecimals(uint256) public view virtual returns (uint8) {
        return 18;
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        address shadowToken = computeShadowAddress(id);
        if (msg.sender == shadowToken) {
            return; // skip the acceptance check
        }
        super._doSafeTransferAcceptanceCheck(
            operator,
            from,
            to,
            id,
            amount,
            data
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
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

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

struct Config {
    address FETCHER;
    bytes32 ORACLE; // 1bit QTI, 31bit reserve, 32bit WINDOW, ... PAIR ADDRESS
    address TOKEN_R;
    uint256 K;
    uint256 MARK;
    uint256 INTEREST_HL;
    uint256 PREMIUM_HL;
    uint256 MATURITY;
    uint256 MATURITY_VEST;
    uint256 MATURITY_RATE; // x128
    uint256 OPEN_RATE;
}

struct Param {
    uint256 sideIn;
    uint256 sideOut;
    address helper;
    bytes payload;
}

struct Payment {
    address utr;
    bytes payer;
    address recipient;
}

// represent a single pool state
struct State {
    uint256 R; // pool reserve
    uint256 a; // LONG coefficient
    uint256 b; // SHORT coefficient
}

// anything that can be changed between tx construction and confirmation
struct Slippable {
    uint256 xk; // (price/MARK)^K
    uint256 R; // pool reserve
    uint256 rA; // LONG reserve
    uint256 rB; // SHORT reserve
}

interface IPool {
    function init(State memory state, Payment memory payment) external;

    function swap(
        Param memory param,
        Payment memory payment
    ) external returns (uint256 amountIn, uint256 amountOut, uint256 price);

    function loadConfig() external view returns (Config memory);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

interface ITokenDescriptor {
    function constructMetadata(
        uint256 id
    ) external view returns (string memory);

    function getName(uint256 id) external view returns (string memory);

    function getSymbol(uint256 id) external view returns (string memory);

    function getDecimals(uint256 id) external view returns (uint8);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

import "@derivable/shadow-token/contracts/ShadowFactory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITokenDescriptor.sol";

/// @title A single ERC-1155 token shared by all Derivable pools
/// @author Derivable Labs
/// @notice An ShadowFactory and ERC1155-Maturity is used by all Derivable pools
///         for their derivative tokens, but also open to any EOA or contract by
///         rule: any EOA or contract of <address>, can mint and burn all its
///         ids that end with <address>.
contract Token is ShadowFactory {
    // Immutables
    address internal immutable UTR;
    // Storages
    address internal s_descriptor;
    address internal s_descriptorSetter;

    modifier onlyItsPool(uint256 id) {
        require(msg.sender == address(uint160(id)), "UNAUTHORIZED_MINT_BURN");
        _;
    }

    modifier onlyDescriptorSetter() {
        require(msg.sender == s_descriptorSetter, "UNAUTHORIZED");
        _;
    }

    /// @param utr The trusted UTR contract that will have unlimited approval,
    ///        can be zero to disable trusted UTR
    /// @param descriptorSetter The authorized descriptor setter,
    ///        can be zero to disable the descriptor changing
    /// @param descriptor The initial token descriptor, can be zero
    constructor(
        address utr,
        address descriptorSetter,
        address descriptor
    ) ShadowFactory("") {
        UTR = utr;
        s_descriptor = descriptor;
        s_descriptorSetter = descriptorSetter;
    }

    /// mint token with a maturity time
    /// @notice each id can only be minted by its pool contract
    /// @param to token recipient address
    /// @param id token id
    /// @param amount token amount
    /// @param maturity token maturity time, must be >= block.timestamp
    /// @param data optional payload data
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        uint32 maturity,
        bytes memory data
    ) external virtual onlyItsPool(id) {
        super._mint(to, id, amount, maturity, data);
    }

    /// burn the token
    /// @notice each id can only be burnt by its pool contract
    /// @param from address to burn from
    /// @param id token id
    /// @param amount token amount
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external virtual onlyItsPool(id) {
        super._burn(from, id, amount);
    }

    /// self-explanatory
    function name() external pure returns (string memory) {
        return "Derivable Position";
    }

    /// self-explanatory
    function symbol() external pure returns (string memory) {
        return "DERIVABLE-POS";
    }

    /// self-explanatory
    function setDescriptor(address descriptor) public onlyDescriptorSetter {
        s_descriptor = descriptor;
    }

    /// self-explanatory
    function setDescriptorSetter(address setter) public onlyDescriptorSetter {
        s_descriptorSetter = setter;
    }

    /// get the name for each shadow token
    function getShadowName(
        uint256 id
    ) public view virtual override returns (string memory) {
        return ITokenDescriptor(s_descriptor).getName(id);
    }

    /// get the symbol for each shadow token
    function getShadowSymbol(
        uint256 id
    ) public view virtual override returns (string memory) {
        return ITokenDescriptor(s_descriptor).getSymbol(id);
    }

    /// get the decimals for each shadow token
    function getShadowDecimals(
        uint256 id
    ) public view virtual override returns (uint8) {
        return ITokenDescriptor(s_descriptor).getDecimals(id);
    }

    /**
     * Generate URI by id.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return ITokenDescriptor(s_descriptor).constructMetadata(tokenId);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override(ERC1155Maturity, IERC1155) returns (bool) {
        return operator == UTR || super.isApprovedForAll(account, operator);
    }
}
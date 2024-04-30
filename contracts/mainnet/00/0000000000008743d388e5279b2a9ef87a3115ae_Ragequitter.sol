// ᗪᗩGOᑎ 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {ERC6909} from "@solady/src/tokens/ERC6909.sol";

/// @notice Simple ragequit singleton with ERC6909 accounting. Version 1.
contract Ragequitter is ERC6909 {
    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Invalid time window for ragequit.
    error InvalidTime();

    /// @dev Out-of-order redemption assets.
    error InvalidAssetOrder();

    /// @dev Overflow or division by zero.
    error MulDivFailed();

    /// @dev ERC20 `transferFrom` failed.
    error TransferFromFailed();

    /// @dev ETH transfer failed.
    error ETHTransferFailed();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs new account loot metadata.
    event URI(string metadata, uint256 indexed id);

    /// @dev Logs new account authority contract.
    event AuthSet(address indexed account, IAuth authority);

    /// @dev Logs new account contribution asset setting.
    event TributeSet(address indexed account, address tribute);

    /// @dev Logs new account ragequit time validity setting.
    event TimeValiditySet(address indexed account, uint48 validAfter, uint48 validUntil);

    /// ========================== STRUCTS ========================== ///

    /// @dev The account loot shares metadata struct.
    struct Metadata {
        string name;
        string symbol;
        string tokenURI;
        IAuth authority;
        uint96 totalSupply;
    }

    /// @dev The account loot shares ownership struct.
    struct Ownership {
        address owner;
        uint96 shares;
    }

    /// @dev The account loot shares settings struct.
    struct Settings {
        address tribute;
        uint48 validAfter;
        uint48 validUntil;
    }

    /// ========================= CONSTANTS ========================= ///

    /// @dev The conventional ERC7528 ETH address.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// ========================== STORAGE ========================== ///

    /// @dev Stores mapping of metadata settings to account token IDs.
    /// note: IDs are unique to addresses (`uint256(uint160(account))`).
    mapping(uint256 id => Metadata) internal _metadata;

    /// @dev Stores mapping of ragequit settings to accounts.
    mapping(address account => Settings) internal _settings;

    /// ================= ERC6909 METADATA & SUPPLY ================= ///

    /// @dev Returns the name for token `id` using this contract.
    function name(uint256 id) public view virtual override(ERC6909) returns (string memory) {
        return _metadata[id].name;
    }

    /// @dev Returns the symbol for token `id` using this contract.
    function symbol(uint256 id) public view virtual override(ERC6909) returns (string memory) {
        return _metadata[id].symbol;
    }

    /// @dev Returns the URI for token `id` using this contract.
    function tokenURI(uint256 id) public view virtual override(ERC6909) returns (string memory) {
        return _metadata[id].tokenURI;
    }

    /// @dev Returns the total supply for token `id` using this contract.
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _metadata[id].totalSupply;
    }

    /// ========================== RAGEQUIT ========================== ///

    /// @dev Ragequits `shares` of `account` loot for their current fair share of pooled `assets`.
    function ragequit(address account, uint96 shares, address[] calldata assets) public virtual {
        Settings storage setting = _settings[account];

        if (block.timestamp < setting.validAfter) revert InvalidTime();
        if (block.timestamp > setting.validUntil) revert InvalidTime();
        if (assets.length == 0) revert InvalidAssetOrder();

        uint256 id = uint256(uint160(account));
        uint256 supply = _metadata[id].totalSupply;
        unchecked {
            _metadata[id].totalSupply -= shares;
        }
        _burn(msg.sender, id, shares);

        address asset;
        address prev;
        uint256 share;

        for (uint256 i; i != assets.length; ++i) {
            asset = assets[i];
            if (asset <= prev) revert InvalidAssetOrder();
            prev = asset;
            share = _mulDiv(shares, _balanceOf(asset, account), supply);
            if (share != 0) _safeTransferFrom(asset, account, msg.sender, share);
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function _mulDiv(uint256 x, uint256 y, uint256 d) internal pure virtual returns (uint256 z) {
        assembly ("memory-safe") {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                mstore(0x00, 0xad251c27) // `MulDivFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// ============================ LOOT ============================ ///

    /// @dev Mints loot shares for an owner of the caller account.
    function mint(address owner, uint96 shares) public virtual {
        uint256 id = uint256(uint160(msg.sender));
        _metadata[id].totalSupply += shares;
        _mint(owner, id, shares);
    }

    /// @dev Burns loot shares from an owner of the caller account.
    function burn(address owner, uint96 shares) public virtual {
        uint256 id = uint256(uint160(msg.sender));
        unchecked {
            _metadata[id].totalSupply -= shares;
        }
        _burn(owner, id, shares);
    }

    /// ========================== TRIBUTE ========================== ///

    /// @dev Mints loot shares in exchange for tribute `amount` to an `account`.
    /// If no `tribute` is set, then function will revert on `safeTransferFrom`.
    function contribute(address account, uint96 amount) public payable virtual {
        address tribute = _settings[account].tribute;
        if (tribute == ETH) _safeTransferETH(account, amount);
        else _safeTransferFrom(tribute, msg.sender, account, amount);
        uint256 id = uint256(uint160(account));
        _metadata[id].totalSupply += amount;
        _mint(msg.sender, id, amount);
    }

    /// ======================== INSTALLATION ======================== ///

    /// @dev Initializes ragequit settings for the caller account.
    function install(Ownership[] calldata owners, Settings calldata setting, Metadata calldata meta)
        public
        virtual
    {
        uint256 id = uint256(uint160(msg.sender));
        if (owners.length != 0) {
            uint96 supply;
            for (uint256 i; i != owners.length; ++i) {
                supply += owners[i].shares;
                _mint(owners[i].owner, id, owners[i].shares);
            }
            _metadata[id].totalSupply += supply;
        }
        if (bytes(meta.name).length != 0) {
            _metadata[id].name = meta.name;
            _metadata[id].symbol = meta.symbol;
        }
        if (bytes(meta.tokenURI).length != 0) {
            emit URI((_metadata[id].tokenURI = meta.tokenURI), id);
        }
        if (meta.authority != IAuth(address(0))) {
            emit AuthSet(msg.sender, (_metadata[id].authority = meta.authority));
        }
        _settings[msg.sender] = Settings(setting.tribute, setting.validAfter, setting.validUntil);
        emit TimeValiditySet(msg.sender, setting.validAfter, setting.validUntil);
        emit TributeSet(msg.sender, setting.tribute);
    }

    /// ==================== SETTINGS & METADATA ==================== ///

    /// @dev Returns the account metadata.
    function getMetadata(address account)
        public
        view
        virtual
        returns (string memory, string memory, string memory, IAuth)
    {
        Metadata storage meta = _metadata[uint256(uint160(account))];
        return (meta.name, meta.symbol, meta.tokenURI, meta.authority);
    }

    /// @dev Returns the account tribute and ragequit time validity settings.
    function getSettings(address account) public view virtual returns (address, uint48, uint48) {
        Settings storage setting = _settings[account];
        return (setting.tribute, setting.validAfter, setting.validUntil);
    }

    /// @dev Sets new authority contract for the caller account.
    function setAuth(IAuth authority) public virtual {
        emit AuthSet(msg.sender, (_metadata[uint256(uint160(msg.sender))].authority = authority));
    }

    /// @dev Sets account and loot token URI `metadata`.
    function setURI(string calldata metadata) public virtual {
        uint256 id = uint256(uint160(msg.sender));
        emit URI((_metadata[id].tokenURI = metadata), id);
    }

    /// @dev Sets account ragequit time validity (or 'time window').
    function setTimeValidity(uint48 validAfter, uint48 validUntil) public virtual {
        emit TimeValiditySet(
            msg.sender,
            _settings[msg.sender].validAfter = validAfter,
            _settings[msg.sender].validUntil = validUntil
        );
    }

    /// @dev Sets account contribution asset (tribute).
    function setTribute(address tribute) public virtual {
        emit TributeSet(msg.sender, _settings[msg.sender].tribute = tribute);
    }

    /// =================== EXTERNAL ASSET HELPERS =================== ///

    /// @dev Returns the `amount` of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function _balanceOf(address token, address account)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul( // The arguments of `mul` are evaluated from right to left.
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function _safeTransferETH(address to, uint256 amount) internal virtual {
        assembly ("memory-safe") {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    function _safeTransferFrom(address token, address from, address to, uint256 amount)
        internal
        virtual
    {
        assembly ("memory-safe") {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// ========================= OVERRIDES ========================= ///

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning. Also requests authority for token transfers.
    function _beforeTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
        override(ERC6909)
    {
        IAuth authority = _metadata[id].authority;
        if (authority != IAuth(address(0))) authority.validateTransfer(from, to, id, amount);
    }
}

/// @notice Simple authority interface for contracts.
interface IAuth {
    function validateTransfer(address, address, uint256, uint256)
        external
        payable
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple EIP-6909 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC6909.sol)
///
/// @dev Note:
/// The ERC6909 standard allows minting and transferring to and from the zero address,
/// minting and transferring zero tokens, as well as self-approvals.
/// For performance, this implementation WILL NOT revert for such actions.
/// Please add any checks with overrides if desired.
///
/// If you are overriding:
/// - Make sure all variables written to storage are properly cleaned
//    (e.g. the bool value for `isOperator` MUST be either 1 or 0 under the hood).
/// - Check that the overridden function is actually used in the function you want to
///   change the behavior of. Much of the code has been manually inlined for performance.
abstract contract ERC6909 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient permission to perform the action.
    error InsufficientPermission();

    /// @dev The balance has overflowed.
    error BalanceOverflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `by` transfers `amount` of token `id` from `from` to `to`.
    event Transfer(
        address by, address indexed from, address indexed to, uint256 indexed id, uint256 amount
    );

    /// @dev Emitted when `owner` enables or disables `operator` to manage all of their tokens.
    event OperatorSet(address indexed owner, address indexed operator, bool approved);

    /// @dev Emitted when `owner` approves `spender` to use `amount` of `id` token.
    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );

    /// @dev `keccak256(bytes("Transfer(address,address,address,uint256,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0x1b3d7edb2e9c0b0e7c525b20aaaef0f5940d2ed71663c7d39266ecafac728859;

    /// @dev `keccak256(bytes("OperatorSet(address,address,bool)"))`.
    uint256 private constant _OPERATOR_SET_EVENT_SIGNATURE =
        0xceb576d9f15e4e200fdb5096d64d5dfd667e16def20c1eefd14256d8e3faa267;

    /// @dev `keccak256(bytes("Approval(address,address,uint256,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0xb3fd5071835887567a0671151121894ddccc2842f1d10bedad13e0d17cace9a7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `ownerSlotSeed` of a given owner is given by.
    /// ```
    ///     let ownerSlotSeed := or(_ERC6909_MASTER_SLOT_SEED, shl(96, owner))
    /// ```
    ///
    /// The balance slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, ownerSlotSeed)
    ///     mstore(0x00, id)
    ///     let balanceSlot := keccak256(0x00, 0x40)
    /// ```
    ///
    /// The operator approval slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, ownerSlotSeed)
    ///     mstore(0x00, operator)
    ///     let operatorApprovalSlot := keccak256(0x0c, 0x34)
    /// ```
    ///
    /// The allowance slot of (`owner`, `spender`, `id`) is given by:
    /// ```
    ///     mstore(0x34, ownerSlotSeed)
    ///     mstore(0x14, spender)
    ///     mstore(0x00, id)
    ///     let allowanceSlot := keccak256(0x00, 0x54)
    /// ```
    uint256 private constant _ERC6909_MASTER_SLOT_SEED = 0xedcaa89a82293940;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC6909 METADATA                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name for token `id`.
    function name(uint256 id) public view virtual returns (string memory);

    /// @dev Returns the symbol for token `id`.
    function symbol(uint256 id) public view virtual returns (string memory);

    /// @dev Returns the number of decimals for token `id`.
    /// Returns 18 by default.
    /// Please override this function if you need to return a custom value.
    function decimals(uint256 id) public view virtual returns (uint8) {
        id = id; // Silence compiler warning.
        return 18;
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC6909                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of token `id` owned by `owner`.
    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, owner)
            mstore(0x00, id)
            amount := sload(keccak256(0x00, 0x40))
        }
    }

    /// @dev Returns the amount of token `id` that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender, uint256 id)
        public
        view
        virtual
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, owner)
            mstore(0x14, spender)
            mstore(0x00, id)
            amount := sload(keccak256(0x00, 0x54))
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x34, 0x00)
        }
    }

    /// @dev Checks if a `spender` is approved by `owner` to manage all of their tokens.
    function isOperator(address owner, address spender) public view virtual returns (bool status) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, owner)
            mstore(0x00, spender)
            status := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Transfers `amount` of token `id` from the caller to `to`.
    ///
    /// Requirements:
    /// - caller must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 id, uint256 amount)
        public
        payable
        virtual
        returns (bool)
    {
        _beforeTokenTransfer(msg.sender, to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            /// Compute the balance slot and load its value.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, caller())
            mstore(0x00, id)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x14, to)
            mstore(0x00, id)
            let toBalanceSlot := keccak256(0x00, 0x40)
            let toBalanceBefore := sload(toBalanceSlot)
            let toBalanceAfter := add(toBalanceBefore, amount)
            // Revert if the balance overflows.
            if lt(toBalanceAfter, toBalanceBefore) {
                mstore(0x00, 0x89560ca1) // `BalanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated balance of `to`.
            sstore(toBalanceSlot, toBalanceAfter)
            // Emit the {Transfer} event.
            mstore(0x00, caller())
            mstore(0x20, amount)
            log4(0x00, 0x40, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, shl(96, to)), id)
        }
        _afterTokenTransfer(msg.sender, to, id, amount);
        return true;
    }

    /// @dev Transfers `amount` of token `id` from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount` of token `id`.
    /// -  The caller must have at least `amount` of allowance to transfer the
    ///    tokens of `from` or approved as an operator.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 id, uint256 amount)
        public
        payable
        virtual
        returns (bool)
    {
        _beforeTokenTransfer(from, to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the operator slot and load its value.
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, from)
            mstore(0x14, caller())
            // Check if the caller is an operator.
            if iszero(sload(keccak256(0x20, 0x34))) {
                // Compute the allowance slot and load its value.
                mstore(0x00, id)
                let allowanceSlot := keccak256(0x00, 0x54)
                let allowance_ := sload(allowanceSlot)
                // If the allowance is not the maximum uint256 value.
                if add(allowance_, 1) {
                    // Revert if the amount to be transferred exceeds the allowance.
                    if gt(amount, allowance_) {
                        mstore(0x00, 0xdeda9030) // `InsufficientPermission()`.
                        revert(0x1c, 0x04)
                    }
                    // Subtract and store the updated allowance.
                    sstore(allowanceSlot, sub(allowance_, amount))
                }
            }
            // Compute the balance slot and load its value.
            mstore(0x14, id)
            let fromBalanceSlot := keccak256(0x14, 0x40)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x28, to)
            mstore(0x14, id)
            let toBalanceSlot := keccak256(0x14, 0x40)
            let toBalanceBefore := sload(toBalanceSlot)
            let toBalanceAfter := add(toBalanceBefore, amount)
            // Revert if the balance overflows.
            if lt(toBalanceAfter, toBalanceBefore) {
                mstore(0x00, 0x89560ca1) // `BalanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated balance of `to`.
            sstore(toBalanceSlot, toBalanceAfter)
            // Emit the {Transfer} event.
            mstore(0x00, caller())
            mstore(0x20, amount)
            // forgefmt: disable-next-line
            log4(0x00, 0x40, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), shr(96, shl(96, to)), id)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x34, 0x00)
        }
        _afterTokenTransfer(from, to, id, amount);
        return true;
    }

    /// @dev Sets `amount` as the allowance of `spender` for the caller for token `id`.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 id, uint256 amount)
        public
        payable
        virtual
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, caller())
            mstore(0x14, spender)
            mstore(0x00, id)
            sstore(keccak256(0x00, 0x54), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log4(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x20)), id)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x34, 0x00)
        }
        return true;
    }

    ///  @dev Sets whether `operator` is approved to manage the tokens of the caller.
    ///
    /// Emits {OperatorSet} event.
    function setOperator(address operator, bool approved) public payable virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Convert `approved` to `0` or `1`.
            let approvedCleaned := iszero(iszero(approved))
            // Compute the operator slot and store the approved.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, caller())
            mstore(0x00, operator)
            sstore(keccak256(0x0c, 0x34), approvedCleaned)
            // Emit the {OperatorSet} event.
            mstore(0x20, approvedCleaned)
            log3(0x20, 0x20, _OPERATOR_SET_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        return true;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC6909: 0x0f632fb3.
            result := or(eq(s, 0x01ffc9a7), eq(s, 0x0f632fb3))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` of token `id` to `to`.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 id, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, to)
            mstore(0x00, id)
            let toBalanceSlot := keccak256(0x00, 0x40)
            // Add and store the updated balance
            let toBalanceBefore := sload(toBalanceSlot)
            let toBalanceAfter := add(toBalanceBefore, amount)
            // Revert if the balance overflows.
            if lt(toBalanceAfter, toBalanceBefore) {
                mstore(0x00, 0x89560ca1) // `BalanceOverflow()`.
                revert(0x1c, 0x04)
            }
            sstore(toBalanceSlot, toBalanceAfter)
            // Emit the {Transfer} event.
            mstore(0x00, caller())
            mstore(0x20, amount)
            log4(0x00, 0x40, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, shl(96, to)), id)
        }
        _afterTokenTransfer(address(0), to, id, amount);
    }

    /// @dev Burns `amount` token `id` from `from`.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, from)
            mstore(0x00, id)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Emit the {Transfer} event.
            mstore(0x00, caller())
            mstore(0x20, amount)
            log4(0x00, 0x40, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0, id)
        }
        _afterTokenTransfer(from, address(0), id, amount);
    }

    /// @dev Transfers `amount` of token `id` from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount` of token `id`.
    /// - If `by` is not the zero address,
    ///   it must have at least `amount` of allowance to transfer the
    ///   tokens of `from` or approved as an operator.
    ///
    /// Emits a {Transfer} event.
    function _transfer(address by, address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {
        _beforeTokenTransfer(from, to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let bitmaskAddress := 0xffffffffffffffffffffffffffffffffffffffff
            // Compute the operator slot and load its value.
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, from)
            // If `by` is not the zero address.
            if and(bitmaskAddress, by) {
                mstore(0x14, by)
                // Check if the `by` is an operator.
                if iszero(sload(keccak256(0x20, 0x34))) {
                    // Compute the allowance slot and load its value.
                    mstore(0x00, id)
                    let allowanceSlot := keccak256(0x00, 0x54)
                    let allowance_ := sload(allowanceSlot)
                    // If the allowance is not the maximum uint256 value.
                    if add(allowance_, 1) {
                        // Revert if the amount to be transferred exceeds the allowance.
                        if gt(amount, allowance_) {
                            mstore(0x00, 0xdeda9030) // `InsufficientPermission()`.
                            revert(0x1c, 0x04)
                        }
                        // Subtract and store the updated allowance.
                        sstore(allowanceSlot, sub(allowance_, amount))
                    }
                }
            }
            // Compute the balance slot and load its value.
            mstore(0x14, id)
            let fromBalanceSlot := keccak256(0x14, 0x40)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x28, to)
            mstore(0x14, id)
            let toBalanceSlot := keccak256(0x14, 0x40)
            let toBalanceBefore := sload(toBalanceSlot)
            let toBalanceAfter := add(toBalanceBefore, amount)
            // Revert if the balance overflows.
            if lt(toBalanceAfter, toBalanceBefore) {
                mstore(0x00, 0x89560ca1) // `BalanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated balance of `to`.
            sstore(toBalanceSlot, toBalanceAfter)
            // Emit the {Transfer} event.
            mstore(0x00, and(bitmaskAddress, by))
            mstore(0x20, amount)
            // forgefmt: disable-next-line
            log4(0x00, 0x40, _TRANSFER_EVENT_SIGNATURE, and(bitmaskAddress, from), and(bitmaskAddress, to), id)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x34, 0x00)
        }
        _afterTokenTransfer(from, to, id, amount);
    }

    /// @dev Sets `amount` as the allowance of `spender` for `owner` for token `id`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 id, uint256 amount)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, owner)
            mstore(0x14, spender)
            mstore(0x00, id)
            sstore(keccak256(0x00, 0x54), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            // forgefmt: disable-next-line
            log4(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, mload(0x34)), shr(96, mload(0x20)), id)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x34, 0x00)
        }
    }

    ///  @dev Sets whether `operator` is approved to manage the tokens of `owner`.
    ///
    /// Emits {OperatorSet} event.
    function _setOperator(address owner, address operator, bool approved) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Convert `approved` to `0` or `1`.
            let approvedCleaned := iszero(iszero(approved))
            // Compute the operator slot and store the approved.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, owner)
            mstore(0x00, operator)
            sstore(keccak256(0x0c, 0x34), approvedCleaned)
            // Emit the {OperatorSet} event.
            mstore(0x20, approvedCleaned)
            // forgefmt: disable-next-line
            log3(0x20, 0x20, _OPERATOR_SET_EVENT_SIGNATURE, shr(96, shl(96, owner)), shr(96, mload(0x0c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {}
}
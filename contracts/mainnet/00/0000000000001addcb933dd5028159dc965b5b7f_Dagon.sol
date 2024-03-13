// ᗪᗩGOᑎ 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭 𒀭
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {ERC6909} from "../lib/solady/src/tokens/ERC6909.sol";
import {SignatureCheckerLib} from "../lib/solady/src/utils/SignatureCheckerLib.sol";

/// @notice Simple ownership singleton for smart accounts. Version 1.
contract Dagon is ERC6909 {
    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Inputs are invalid for an ownership setting.
    error InvalidSetting();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs new authority contract for an account.
    event AuthSet(address indexed account, IAuth auth);

    /// @dev Logs new token uri settings for an account.
    event URISet(address indexed account, string uri);

    /// @dev Logs new ownership threshold for an account.
    event ThresholdSet(address indexed account, uint88 threshold);

    /// @dev Logs new token ownership standard for an account.
    event TokenSet(address indexed account, address token, Standard standard);

    /// ========================== STRUCTS ========================== ///

    /// @dev The account token metadata struct.
    struct Metadata {
        string name;
        string symbol;
        string tokenURI;
        IAuth authority;
        uint96 totalSupply;
    }

    /// @dev The account ownership shares struct.
    struct Ownership {
        address owner;
        uint96 shares;
    }

    /// @dev The account ownership settings struct.
    struct Settings {
        address token;
        uint88 threshold;
        Standard standard;
    }

    /// @dev The packed ERC4337 user operation (userOp) struct.
    struct PackedUserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        bytes32 accountGasLimits;
        uint256 preVerificationGas;
        bytes32 gasFees; // `maxPriorityFee` and `maxFeePerGas`.
        bytes paymasterAndData;
        bytes signature;
    }

    /// =========================== ENUMS =========================== ///

    /// @dev The token standard interface enum.
    enum Standard {
        DAGON,
        ERC20,
        ERC721,
        ERC1155,
        ERC6909
    }

    /// ========================== STORAGE ========================== ///

    /// @dev Stores mapping of metadata settings to account token IDs.
    /// note: IDs are unique to addresses (`uint256(uint160(account))`).
    mapping(uint256 id => Metadata) internal _metadata;

    /// @dev Stores mapping of ownership settings to accounts.
    mapping(address account => Settings) internal _settings;

    /// @dev Stores mapping of voting tallies to signed userOp hashes.
    mapping(bytes32 signedHash => uint256) public votingTally;

    /// @dev Stores mapping of account owner voting shares cast on signed userOp hashes.
    mapping(address owner => mapping(bytes32 signedHash => uint256 shares)) public voted;

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

    /// ======================== CONSTRUCTOR ======================== ///

    /// @dev Constructs
    /// this implementation.
    constructor() payable {}

    /// =================== VALIDATION OPERATIONS =================== ///

    /// @dev Validates ERC1271 signature with additional auth logic flow among owners.
    /// note: This implementation is designed to be the ERC-173-owner-of-4337-accounts.
    function isValidSignature(bytes32 hash, bytes calldata signature)
        public
        view
        virtual
        returns (bytes4)
    {
        Settings memory set = _settings[msg.sender];
        if (signature.length != 0) {
            unchecked {
                uint256 pos;
                address prev;
                address owner;
                uint256 tally;
                for (uint256 i; i != signature.length / 85; ++i) {
                    if (
                        SignatureCheckerLib.isValidSignatureNowCalldata(
                            owner = address(bytes20(signature[pos:pos + 20])),
                            hash,
                            signature[pos + 20:pos + 85]
                        ) && prev < owner // Check double voting.
                    ) {
                        pos += 85;
                        prev = owner;
                        tally += set.standard == Standard.DAGON
                            ? balanceOf(owner, uint256(uint160(msg.sender)))
                            : set.standard == Standard.ERC20 || set.standard == Standard.ERC721
                                ? _balanceOf(set.token, owner)
                                : _balanceOf(set.token, owner, uint256(uint160(msg.sender)));
                    } else {
                        return 0xffffffff; // Failure code.
                    }
                }
                return _validateReturn(tally >= set.threshold);
            }
        }
        return _validateReturn(votingTally[hash] >= set.threshold);
    }

    /// @dev Validates packed userOp with additional auth logic flow among owners.
    /// note: This is expected to be called in a validator plugin-like userOp flow.
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 /*missingAccountFunds*/
    ) public payable virtual returns (uint256 validationData) {
        IAuth auth = _metadata[uint256(uint160(msg.sender))].authority;
        if (auth != IAuth(address(0))) {
            (address target, uint256 value, bytes memory data) =
                abi.decode(userOp.callData[4:], (address, uint256, bytes));
            auth.validateCall(msg.sender, target, value, data);
        }
        if (
            isValidSignature(
                SignatureCheckerLib.toEthSignedMessageHash(userOpHash), userOp.signature
            ) != this.isValidSignature.selector
        ) validationData = 0x01; // Failure code.
    }

    /// @dev Returns validated signature result within the conventional ERC1271 syntax.
    function _validateReturn(bool success) internal pure virtual returns (bytes4 result) {
        assembly ("memory-safe") {
            // `success ? bytes4(keccak256("isValidSignature(bytes32,bytes)")) : 0xffffffff`.
            result := shl(224, or(0x1626ba7e, sub(0, iszero(success))))
        }
    }

    /// ===================== VOTING OPERATIONS ===================== ///

    /// @dev Casts account owner voting shares on a given ERC4337 userOp hash.
    function vote(address account, bytes32 userOpHash, bytes calldata signature)
        public
        payable
        virtual
        returns (uint256)
    {
        Settings memory set = _settings[account];
        bytes32 hash = SignatureCheckerLib.toEthSignedMessageHash(userOpHash);
        unchecked {
            uint256 pos;
            address owner;
            uint256 tally;
            for (uint256 i; i != signature.length / 85; ++i) {
                if (
                    SignatureCheckerLib.isValidSignatureNowCalldata(
                        owner = address(bytes20(signature[pos:pos + 20])),
                        hash,
                        signature[pos + 20:pos + 85]
                    ) && voted[owner][hash] == 0 // Check double voting.
                ) {
                    pos += 85;
                    tally += voted[owner][hash] = set.standard == Standard.DAGON
                        ? balanceOf(owner, uint256(uint160(account)))
                        : set.standard == Standard.ERC20 || set.standard == Standard.ERC721
                            ? _balanceOf(set.token, owner)
                            : _balanceOf(set.token, owner, uint256(uint160(account)));
                }
            }
            return votingTally[hash] += tally; // Return latest total tally.
        }
    }

    /// ======================== INSTALLATION ======================== ///

    /// @dev Initializes ownership settings for the caller account.
    /// note: Finalizes with transfer request in two-step pattern.
    /// See, e.g., Ownable.sol:
    /// https://github.com/Vectorized/solady/blob/main/src/auth/Ownable.sol
    function install(Ownership[] calldata owners, Settings calldata setting, Metadata calldata meta)
        public
        payable
        virtual
    {
        uint256 id = uint256(uint160(msg.sender));
        if (owners.length != 0) {
            uint96 supply;
            for (uint256 i; i != owners.length;) {
                supply += owners[i].shares;
                _mint(owners[i].owner, id, owners[i].shares);
                unchecked {
                    ++i;
                }
            }
            _metadata[id].totalSupply += supply;
        }
        setToken(setting.token, setting.standard);
        setThreshold(setting.threshold);
        if (bytes(meta.name).length != 0) {
            _metadata[id].name = meta.name;
            _metadata[id].symbol = meta.symbol;
        }
        if (bytes(meta.tokenURI).length != 0) setURI(meta.tokenURI);
        if (meta.authority != IAuth(address(0))) _metadata[id].authority = meta.authority;
        try IOwnable(msg.sender).requestOwnershipHandover() {} catch {} // Avoid revert.
    }

    /// ===================== OWNERSHIP SETTINGS ===================== ///

    /// @dev Returns the account settings.
    function getSettings(address account) public view virtual returns (address, uint88, Standard) {
        Settings storage set = _settings[account];
        return (set.token, set.threshold, set.standard);
    }

    /// @dev Sets new authority contract for the caller account.
    function setAuth(IAuth auth) public payable virtual {
        emit AuthSet(msg.sender, (_metadata[uint256(uint160(msg.sender))].authority = auth));
    }

    /// @dev Sets new token ownership interface standard for the caller account.
    function setToken(address token, Standard standard) public payable virtual {
        emit TokenSet(
            msg.sender,
            _settings[msg.sender].token = token,
            _settings[msg.sender].standard = standard
        );
    }

    /// @dev Sets new ownership threshold for the caller account.
    function setThreshold(uint88 threshold) public payable virtual {
        Settings storage set = _settings[msg.sender];
        if (
            threshold
                > (
                    set.standard == Standard.DAGON
                        ? totalSupply(uint256(uint160(msg.sender)))
                        : set.standard == Standard.ERC20 || set.standard == Standard.ERC721
                            ? _totalSupply(set.token)
                            : _totalSupply(set.token, uint256(uint160(msg.sender)))
                ) || threshold == 0
        ) revert InvalidSetting();
        emit ThresholdSet(msg.sender, (set.threshold = threshold));
    }

    /// ====================== TOKEN OPERATIONS ====================== ///

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

    /// @dev Mints shares for an owner of the caller account.
    function mint(address owner, uint96 shares) public payable virtual {
        uint256 id = uint256(uint160(msg.sender));
        _metadata[id].totalSupply += shares;
        _mint(owner, id, shares);
    }

    /// @dev Burns shares from an owner of the caller account.
    function burn(address owner, uint96 shares) public payable virtual {
        uint256 id = uint256(uint160(msg.sender));
        unchecked {
            if (_settings[msg.sender].threshold > (_metadata[id].totalSupply -= shares)) {
                revert InvalidSetting();
            }
        }
        _burn(owner, id, shares);
    }

    /// @dev Sets new token URI metadata for the caller account.
    function setURI(string calldata uri) public payable virtual {
        emit URISet(msg.sender, (_metadata[uint256(uint160(msg.sender))].tokenURI = uri));
    }

    /// =================== EXTERNAL TOKEN HELPERS =================== ///

    /// @dev Returns the amount of ERC20/721 `token` owned by `account`.
    function _balanceOf(address token, address account)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            mstore(0x14, account) // Store the `account` argument.
            pop(staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20))
            amount := mload(0x20)
        }
    }

    /// @dev Returns the amount of ERC1155/6909 `token` `id` owned by `account`.
    function _balanceOf(address token, address account, uint256 id)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0x00fdd58e000000000000000000000000) // `balanceOf(address,uint256)`.
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x34, id) // Store the `id` argument.
            pop(staticcall(gas(), token, 0x10, 0x44, 0x20, 0x20))
            amount := mload(0x20)
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the total supply of ERC20/721 `token`.
    function _totalSupply(address token) internal view virtual returns (uint256 supply) {
        assembly ("memory-safe") {
            mstore(0x00, 0x18160ddd) // `totalSupply()`.
            pop(staticcall(gas(), token, 0x1c, 0x04, 0x20, 0x20))
            supply := mload(0x20)
        }
    }

    /// @dev Returns the total supply of ERC1155/6909 `token` `id`.
    function _totalSupply(address token, uint256 id)
        internal
        view
        virtual
        returns (uint256 supply)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0xbd85b039) // `totalSupply(uint256)`.
            mstore(0x20, id) // Store the `id` argument.
            pop(staticcall(gas(), token, 0x1c, 0x24, 0x20, 0x20))
            supply := mload(0x20)
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
        IAuth auth = _metadata[id].authority;
        if (auth != IAuth(address(0))) auth.validateTransfer(from, to, id, amount);
    }
}

/// @notice Simple authority interface for contracts.
interface IAuth {
    function validateTransfer(address, address, uint256, uint256)
        external
        payable
        returns (uint256);
    function validateCall(address, address, uint256, bytes calldata)
        external
        payable
        returns (uint256);
}

/// @notice Simple ownership interface for handover requests.
interface IOwnable {
    function requestOwnershipHandover() external payable;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Signature verification helper that supports both ECDSA signatures from EOAs
/// and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SignatureCheckerLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol)
///
/// @dev Note:
/// - The signature checking functions use the ecrecover precompile (0x1).
/// - The `bytes memory signature` variants use the identity precompile (0x4)
///   to copy memory internally.
/// - Unlike ECDSA signatures, contract signatures are revocable.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library SignatureCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               SIGNATURE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                // Copy the `signature` over.
                let n := add(0x20, mload(signature))
                pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(returndatasize(), 0x44), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // `r`, `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), signature.length)
                // Copy the `signature` over.
                calldatacopy(add(m, 0x64), signature.offset, signature.length)
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(signature.length, 0x64), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, add(shr(255, vs), 27)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, shr(1, shl(1, vs))) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), mload(0x60)) // `s`.
                mstore8(add(m, 0xa4), mload(0x20)) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, and(v, 0xff)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, s) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), s) // `s`.
                mstore8(add(m, 0xa4), v) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            // Copy the `signature` over.
            let n := add(0x20, mload(signature))
            pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(returndatasize(), 0x44), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), signature.length)
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(signature.length, 0x64), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), shr(1, shl(1, vs))) // `s`.
            mstore8(add(m, 0xa4), add(shr(255, vs), 27)) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), s) // `s`.
            mstore8(add(m, 0xa4), v) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}
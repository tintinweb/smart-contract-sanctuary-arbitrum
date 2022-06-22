// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IERC20Bridged} from "./interfaces/IERC20Bridged.sol";

import {ERC20Core} from "./ERC20Core.sol";
import {ERC20Metadata} from "./ERC20Metadata.sol";

/// @author psirex
/// @notice Extends the ERC20 functionality that allows the bridge to mint/burn tokens
contract ERC20Bridged is IERC20Bridged, ERC20Core, ERC20Metadata {
    /// @inheritdoc IERC20Bridged
    address public immutable bridge;

    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    /// @param decimals_ The decimals places of the token
    /// @param bridge_ The bridge address which allowd to mint/burn tokens
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address bridge_
    ) ERC20Metadata(name_, symbol_, decimals_) {
        bridge = bridge_;
    }

    /// @notice Sets the name and the symbol of the tokens if they both are empty
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    function initialize(string memory name_, string memory symbol_) external {
        _setERC20MetadataName(name_);
        _setERC20MetadataSymbol(symbol_);
    }

    /// @inheritdoc IERC20Bridged
    function bridgeMint(address account_, uint256 amount_) public onlyBridge {
        _mint(account_, amount_);
    }

    /// @inheritdoc IERC20Bridged
    function bridgeBurn(address account_, uint256 amount_) external onlyBridge {
        _burn(account_, amount_);
    }

    /// @dev Validates that sender of the transaction is the bridge
    modifier onlyBridge() {
        if (msg.sender != bridge) {
            revert ErrorNotBridge();
        }
        _;
    }

    error ErrorNotBridge();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "./IERC20Metadata.sol";

/// @author psirex
/// @notice Extends the ERC20 functionality that allows the bridge to mint/burn tokens
interface IERC20Bridged is IERC20 {
    /// @notice Returns bridge which can mint and burn tokens on L2
    function bridge() external view returns (address);

    /// @notice Creates amount_ tokens and assigns them to account_, increasing the total supply
    /// @param account_ An address of the account to mint tokens
    /// @param amount_ An amount of tokens to mint
    function bridgeMint(address account_, uint256 amount_) external;

    /// @notice Destroys amount_ tokens from account_, reducing the total supply
    /// @param account_ An address of the account to burn tokens
    /// @param amount_ An amount of tokens to burn
    function bridgeBurn(address account_, uint256 amount_) external;
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @author psirex
/// @notice Contains the required logic of the ERC20 standard as defined in the EIP. Additionally
///     provides methods for direct allowance increasing/decreasing.
contract ERC20Core is IERC20 {
    /// @inheritdoc IERC20
    uint256 public totalSupply;

    /// @inheritdoc IERC20
    mapping(address => uint256) public balanceOf;

    /// @inheritdoc IERC20
    mapping(address => mapping(address => uint256)) public allowance;

    /// @inheritdoc IERC20
    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to_, uint256 amount_) public returns (bool) {
        _transfer(msg.sender, to_, amount_);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public returns (bool) {
        _spendAllowance(from_, msg.sender, amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    /// @notice Atomically increases the allowance granted to spender by the caller.
    /// @param spender_ An address of the tokens spender
    /// @param addedValue_ An amount to increase the allowance
    function increaseAllowance(address spender_, uint256 addedValue_)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender_,
            allowance[msg.sender][spender_] + addedValue_
        );
        return true;
    }

    /// @notice Atomically decreases the allowance granted to spender by the caller.
    /// @param spender_ An address of the tokens spender
    /// @param subtractedValue_ An amount to decrease the  allowance
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        external
        returns (bool)
    {
        uint256 currentAllowance = allowance[msg.sender][spender_];
        if (currentAllowance < subtractedValue_) {
            revert ErrorDecreasedAllowanceBelowZero();
        }
        unchecked {
            _approve(msg.sender, spender_, currentAllowance - subtractedValue_);
        }
        return true;
    }

    /// @dev Moves amount_ of tokens from sender_ to recipient_
    /// @param from_ An address of the sender of the tokens
    /// @param to_  An address of the recipient of the tokens
    /// @param amount_ An amount of tokens to transfer
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal onlyNonZeroAccount(from_) onlyNonZeroAccount(to_) {
        _decreaseBalance(from_, amount_);
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
    }

    /// @dev Updates owner_'s allowance for spender_ based on spent amount_. Does not update
    ///     the allowance amount in case of infinite allowance
    /// @param owner_ An address of the account to spend allowance
    /// @param spender_  An address of the spender of the tokens
    /// @param amount_ An amount of allowance spend
    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal {
        uint256 currentAllowance = allowance[owner_][spender_];
        if (currentAllowance == type(uint256).max) {
            return;
        }
        if (amount_ > currentAllowance) {
            revert ErrorNotEnoughAllowance();
        }
        unchecked {
            _approve(owner_, spender_, currentAllowance - amount_);
        }
    }

    /// @dev Sets amount_ as the allowance of spender_ over the owner_'s tokens
    /// @param owner_ An address of the account to set allowance
    /// @param spender_  An address of the tokens spender
    /// @param amount_ An amount of tokens to allow to spend
    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual onlyNonZeroAccount(owner_) onlyNonZeroAccount(spender_) {
        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /// @dev Creates amount_ tokens and assigns them to account_, increasing the total supply
    /// @param account_ An address of the account to mint tokens
    /// @param amount_ An amount of tokens to mint
    function _mint(address account_, uint256 amount_)
        internal
        onlyNonZeroAccount(account_)
    {
        totalSupply += amount_;
        balanceOf[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    /// @dev Destroys amount_ tokens from account_, reducing the total supply.
    /// @param account_ An address of the account to mint tokens
    /// @param amount_ An amount of tokens to mint
    function _burn(address account_, uint256 amount_)
        internal
        onlyNonZeroAccount(account_)
    {
        _decreaseBalance(account_, amount_);
        totalSupply -= amount_;
        emit Transfer(account_, address(0), amount_);
    }

    /// @dev Decreases the balance of the account_
    /// @param account_ An address of the account to decrease balance
    /// @param amount_ An amount of balance decrease
    function _decreaseBalance(address account_, uint256 amount_) internal {
        uint256 balance = balanceOf[account_];

        if (amount_ > balance) {
            revert ErrorNotEnoughBalance();
        }
        unchecked {
            balanceOf[account_] = balance - amount_;
        }
    }

    /// @dev validates that account_ is not zero address
    modifier onlyNonZeroAccount(address account_) {
        if (account_ == address(0)) {
            revert ErrorZeroAddress();
        }
        _;
    }

    error ErrorZeroAddress();
    error ErrorNotEnoughBalance();
    error ErrorNotEnoughAllowance();
    error ErrorDecreasedAllowanceBelowZero();
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IERC20Metadata} from "./interfaces/IERC20Metadata.sol";

/// @author psirex
/// @notice Contains the optional metadata functions from the ERC20 standard
/// @dev Uses the UnstructuredStorage pattern to store dynamic name and symbol data. Might be used
///     with the upgradable proxies
contract ERC20Metadata is IERC20Metadata {
    /// @dev Stores the dynamic metadata of the ERC20 token. Allows safely use of this
    ///     contract with upgradable proxies
    struct DynamicMetadata {
        string name;
        string symbol;
    }

    /// @dev Location of the slot with DynamicMetdata
    bytes32 private constant DYNAMIC_METADATA_SLOT =
        keccak256("ERC20Metdata.dynamicMetadata");

    /// @inheritdoc IERC20Metadata
    uint8 public immutable decimals;

    /// @param name_ Name of the token
    /// @param symbol_ Symbol of the token
    /// @param decimals_ Decimals places of the token
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        decimals = decimals_;
        _setERC20MetadataName(name_);
        _setERC20MetadataSymbol(symbol_);
    }

    /// @inheritdoc IERC20Metadata
    function name() public view returns (string memory) {
        return _loadDynamicMetadata().name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() public view returns (string memory) {
        return _loadDynamicMetadata().symbol;
    }

    /// @dev Sets the name of the token. Might be called only when the name is empty
    function _setERC20MetadataName(string memory name_) internal {
        if (bytes(name()).length > 0) {
            revert ErrorNameAlreadySet();
        }
        _loadDynamicMetadata().name = name_;
    }

    /// @dev Sets the symbol of the token. Might be called only when the symbol is empty
    function _setERC20MetadataSymbol(string memory symbol_) internal {
        if (bytes(symbol()).length > 0) {
            revert ErrorSymbolAlreadySet();
        }
        _loadDynamicMetadata().symbol = symbol_;
    }

    /// @dev Returns the reference to the slot with DynamicMetadta struct
    function _loadDynamicMetadata()
        private
        pure
        returns (DynamicMetadata storage r)
    {
        bytes32 slot = DYNAMIC_METADATA_SLOT;
        assembly {
            r.slot := slot
        }
    }

    error ErrorNameAlreadySet();
    error ErrorSymbolAlreadySet();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @author psirex
/// @notice Interface for the optional metadata functions from the ERC20 standard.
interface IERC20Metadata {
    /// @dev Returns the name of the token.
    function name() external view returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}
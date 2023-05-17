// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/utils/IMellowToken.sol";

import "./interfaces/ICommonFacet.sol";

import "../libraries/CommonLibrary.sol";

contract CommonFacet is ICommonFacet {
    error Forbidden();

    bytes32 internal constant STORAGE_POSITION = keccak256("mellow.contracts.common.storage");

    function contractStorage() internal pure returns (ICommonFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function initializeCommonFacet(
        address[] memory immutableTokens_,
        address[] memory mutableTokens_,
        IOracle oracle_,
        string memory name,
        string memory symbol
    ) external override {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        ICommonFacet.Storage storage ds = contractStorage();
        ds.immutableTokens = immutableTokens_;
        ds.mutableTokens = mutableTokens_;
        ds.tokens = CommonLibrary.merge(immutableTokens_, mutableTokens_);
        ds.oracle = oracle_;
        ds.lpToken = new LpToken(name, symbol, address(this));
    }

    function updateSecurityParams(
        IBaseOracle.SecurityParams[] calldata allTokensSecurityParams,
        IBaseOracle.SecurityParams[] calldata vaultTokensSecurityParams
    ) external {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        ICommonFacet.Storage storage ds = contractStorage();
        ds.allTokensSecurityParams = abi.encode(allTokensSecurityParams);
        ds.vaultTokensSecurityParams = abi.encode(vaultTokensSecurityParams);
    }

    function updateMutableTokens(address[] memory newMutableTokens) external {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        ICommonFacet.Storage storage ds = contractStorage();
        address[] memory mutableTokens = ds.mutableTokens;
        require(mutableTokens.length == newMutableTokens.length, "Invalid length");
        for (uint256 i = 0; i < mutableTokens.length; i++) {
            require(IMellowToken(mutableTokens[i]).isReplaceable(newMutableTokens[i]), "Non replaceable token");
        }
        ds.mutableTokens = newMutableTokens;
        ds.tokens = CommonLibrary.merge(ds.mutableTokens, ds.immutableTokens);
    }

    function updateOracle(IOracle newOracle) external override {
        IPermissionsFacet(address(this)).requirePermission(msg.sender, address(this), msg.sig);
        ICommonFacet.Storage storage ds = contractStorage();
        ds.oracle = newOracle;
    }

    function tvl() public view override returns (uint256) {
        ICommonFacet.Storage memory ds = contractStorage();
        address[] memory _tokens = ds.tokens;
        IOracle oracle_ = ds.oracle;

        uint256[] memory tokenAmounts = oracle_.getTokenAmounts(_tokens, ITokensManagementFacet(address(this)).vault());

        return
            oracle_.price(
                _tokens,
                tokenAmounts,
                abi.decode(ds.vaultTokensSecurityParams, (IBaseOracle.SecurityParams[])),
                abi.decode(ds.allTokensSecurityParams, (IBaseOracle.SecurityParams[]))
            );
    }

    function getValueOfTokens(
        address[] calldata _tokens,
        uint256[] calldata tokenAmounts
    ) public view override returns (uint256) {
        ICommonFacet.Storage memory ds = contractStorage();
        IOracle oracle_ = ds.oracle;
        return
            oracle_.price(
                _tokens,
                tokenAmounts,
                abi.decode(ds.vaultTokensSecurityParams, (IBaseOracle.SecurityParams[])),
                abi.decode(ds.allTokensSecurityParams, (IBaseOracle.SecurityParams[]))
            );
    }

    function tokens() public pure override returns (address[] memory, address[] memory, address[] memory) {
        ICommonFacet.Storage memory ds = contractStorage();
        return (ds.tokens, ds.immutableTokens, ds.mutableTokens);
    }

    function getTokenAmounts() public view override returns (address[] memory, uint256[] memory) {
        ICommonFacet.Storage memory ds = contractStorage();
        address[] memory tokens_ = ds.tokens;
        IOracle oracle_ = ds.oracle;

        uint256[] memory tokenAmounts = oracle_.getTokenAmounts(tokens_, ITokensManagementFacet(address(this)).vault());
        return (tokens_, tokenAmounts);
    }

    function lpToken() public pure override returns (LpToken) {
        ICommonFacet.Storage memory ds = contractStorage();
        return ds.lpToken;
    }

    function oracle() external pure override returns (IOracle) {
        ICommonFacet.Storage memory ds = contractStorage();
        return ds.oracle;
    }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMellowToken {
    function isReplaceable(address) external view returns (bool);

    function equals(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IOracle, IBaseOracle} from "../../interfaces/oracles/IOracle.sol";
import "./IPermissionsFacet.sol";
import "./ITokensManagementFacet.sol";

import "../../utils/LpToken.sol";

interface ICommonFacet {
    struct Storage {
        bytes vaultTokensSecurityParams;
        bytes allTokensSecurityParams;
        LpToken lpToken;
        IOracle oracle;
        address[] tokens;
        address[] immutableTokens;
        address[] mutableTokens;
    }

    function initializeCommonFacet(
        address[] calldata immutableTokens_,
        address[] calldata mutableTokens_,
        IOracle oracle_,
        string memory name,
        string memory symbol
    ) external;

    function updateSecurityParams(
        IBaseOracle.SecurityParams[] calldata allTokensSecurityParams,
        IBaseOracle.SecurityParams[] calldata vaultTokensSecurityParams
    ) external;

    function updateMutableTokens(address[] calldata newMutableTokens) external;

    function updateOracle(IOracle newOracle) external;

    function tvl() external view returns (uint256);

    function getValueOfTokens(address[] memory, uint256[] memory) external view returns (uint256);

    function tokens() external pure returns (address[] memory, address[] memory, address[] memory);

    function getTokenAmounts() external view returns (address[] memory, uint256[] memory);

    function lpToken() external view returns (LpToken);

    function oracle() external view returns (IOracle);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library CommonLibrary {
    /// @dev returns index of element in array or type(uint32).max if not found
    function binarySearch(address[] calldata array, address element) external pure returns (uint32 index) {
        uint32 left = 0;
        uint32 right = uint32(array.length);
        uint32 mid;
        while (left + 1 < right) {
            mid = (left + right) >> 1;
            if (array[mid] > element) {
                right = mid;
            } else {
                left = mid;
            }
        }
        if (array[left] != element) {
            return type(uint32).max;
        }
        return left;
    }

    function sortArray(address[] calldata array) public pure returns (address[] memory) {
        if (isSorted(array)) return array;
        address[] memory sortedArray = array;
        for (uint32 i = 0; i < array.length; i++) {
            for (uint32 j = i + 1; j < array.length; j++) {
                if (sortedArray[i] > sortedArray[j])
                    (sortedArray[i], sortedArray[j]) = (sortedArray[j], sortedArray[i]);
            }
        }
        return sortedArray;
    }

    function isSorted(address[] calldata array) public pure returns (bool) {
        for (uint32 i = 0; i + 1 < array.length; i++) {
            if (array[i] > array[i + 1]) return false;
        }
        return true;
    }

    function merge(address[] calldata a, address[] calldata b) public pure returns (address[] memory array) {
        address[] memory sortedA = sortArray(a);
        address[] memory sortedB = sortArray(b);
        array = new address[](a.length + b.length);
        uint32 i = 0;
        uint32 j = 0;
        while (i < a.length && j < b.length) {
            if (sortedA[i] < sortedB[j]) {
                array[i + j] = sortedA[i];
                i++;
            } else {
                array[i + j] = sortedB[j];
                j++;
            }
        }
        while (i < a.length) {
            array[i + j] = sortedA[i];
            i++;
        }
        while (j < b.length) {
            array[i + j] = sortedB[j];
            j++;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IBaseOracle.sol";

interface IOracle {
    function price(
        address[] calldata tokens,
        uint256[] calldata requestedTokenAmounts,
        IBaseOracle.SecurityParams[] calldata requestedTokensParameters,
        IBaseOracle.SecurityParams[] calldata allTokensParameters
    ) external view returns (uint256);

    function getTokenAmounts(
        address[] calldata tokens,
        address user
    ) external view returns (uint256[] memory tokenAmounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionsFacet {
    struct Storage {
        bool initialized;
        mapping(address => mapping(address => uint256)) userContractRoles;
        mapping(bytes4 => uint256) signatureRoles;
        mapping(address => mapping(bytes4 => bool)) isEveryoneAllowedToCall;
    }

    function initializePermissionsFacet(address admin) external;

    function hasPermission(address user, address contractAddress, bytes4 signature) external view returns (bool);

    function requirePermission(address user, address contractAddress, bytes4 signature) external;

    function setGeneralRole(address contractAddress, bytes4 signature, bool value) external;

    function grantUserContractRole(uint8 role, address user, address contractAddress) external;

    function revokeUserContractRole(uint8 role, address user, address contractAddress) external;

    function grantSignatureRole(uint8 role, bytes4 signature) external;

    function revokeSignatureRole(uint8 role, bytes4 signature) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITokensManagementFacet.sol";

interface ITokensManagementFacet {
    struct Storage {
        address vault;
    }

    function vault() external pure returns (address);

    function approve(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LpToken is ERC20 {
    address public immutable owner;

    constructor(string memory _name, string memory _symbol, address _owner) ERC20(_name, _symbol) {
        owner = _owner;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Forbidden");
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        require(msg.sender == owner, "Forbidden");
        _burn(to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IBaseOracle {
    struct SecurityParams {
        bytes parameters;
    }

    function quote(
        address token,
        uint256 amount,
        SecurityParams memory params
    ) external view returns (address[] memory tokens, uint256[] memory prices);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
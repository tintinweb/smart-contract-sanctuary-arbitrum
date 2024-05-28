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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
pragma solidity ^0.8.8;

interface ICommission {
    function getConditionTotalCommission(uint8 _level) external returns (uint256);

    function getConditionClaimCommission(uint8 _level) external returns (uint256);

    function setConditionTotalCommission(uint8 _level, uint256 _value) external;

    function setConditionDirectStakeTokenCommission(uint8 _level, uint256 _value) external;

    function setConditionClaimCommission(uint8 _level, uint256 _value) external;

    function setMaxNumberStakeValue(uint8 _percent) external;

    function setDefaultMaxCommission(uint256 _value) external;

    function getTotalCommission(address _wallet) external view returns (uint256);

    function calculateEarnedUsd(address _address, uint256 _claimUsd) external view returns (uint256);

    function getDirectCommissionUsd(address _wallet) external view returns (uint256);

    function getInterestCommissionUsd(address _wallet) external view returns (uint256);

    function getRankingCommissionUsd(address _wallet) external view returns (uint256);

    function getReStakeValueUsd(address _wallet) external view returns (uint256);

    function getTeamStakeValue(address _wallet) external view returns (uint256);

    function updateWalletCommission(address _wallet,
        uint256 _directCommission,
        uint256 _interestCommission,
        uint256 _reStakeValueUsd,
        uint256 _reStakeClaimUsd,
        uint256 _stakeTokenClaimUsd,
        uint256 _stakeNativeTokenClaimUsd,
        uint256 _rankingCommission,
        uint256 _teamStakeValue) external;

    function setSystemWallet(address _newSystemWallet) external;

    function setOracleAddress(address _oracleAddress) external;

    function setRankingContractAddress(address _stakingAddress) external;

    function getCommissionRef(
        address _refWallet,
        uint256 _totalValueUsdWithDecimal,
        uint256 _totalCommission,
        uint16 _commissionBuy
    )  external returns (uint256);

    function updateDataRestake(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _payRef,
        bool _updateRanking,
        bool _isStakeToken
    ) external;

    function updateDataClaim(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _isPayRanking
    ) external;

    function updateRankingNetworkData(address _refWallet, uint256 _totalValueUsdWithDecimal, uint16 _commissionRanking, uint256 _totalCommission) external;

    function getMaxCommissionByAddressInUsd(address _wallet) external view returns (uint256);

    function updateClaimReStakeUsd(address _address, uint256 _claimUsd) external;

    function updateReStakeValueUsd(address _address, uint256 _value) external;

    function updateClaimStakeTokenUsd(address _address, uint256 _claimUsd) external;

    function updateClaimStakeNativeUsd(address _address, uint256 _claimUsd) external;

    function setAddressCanUpdateCommission(address _address, bool _value) external;

    function getCommissionPercent(uint8 _level) external returns (uint16);

    function getDirectCommissionPercent(uint8 _level) external returns (uint16);

    function setCommissionPercent(uint8 _level, uint16 _percent) external;

    function setDirectCommissionPercent(uint8 _level, uint16 _percent) external;

    function setDirectCommissionStakeTokenPercent(uint8 _level, uint16 _percent) external;

    function setToken(address _address) external;

    function setNetworkAddress(address _address) external;

    function setMaxLevel(uint8 _maxLevel) external;

    function withdrawTokenEmergency(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface INetwork {
    function updateReferralData(address _user, address _refAddress) external;

    function getReferralAccountForAccount(address _user) external view returns (address);

    function isAddressCanUpdateReferralData(address _user) external view returns (bool);

    function getReferralAccountForAccountExternal(address _user) external view returns (address);

    function getTotalMember(address _wallet, uint16 _maxFloor) external view returns (uint256);

    function getF1ListForAccount(address _wallet) external view returns (address[] memory);

    function possibleChangeReferralData(address _wallet) external returns (bool);

    function lockedReferralDataForAccount(address _user) external;

    function setSystemWallet(address _newSystemWallet) external;

    function setAddressCanUpdateReferralData(address account, bool hasUpdate) external;

    function checkValidRefCodeAdvance(address _user, address _refAddress) external returns (bool);

    function getActiveMemberForAccount(address _wallet) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakePair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Oracle is Ownable {
    uint256 public constant PRECISION = 1000000;

    mapping(address => uint256) private addressUsdtAmount;
    mapping(address => uint256) private addressTokenAmount;

    mapping(address => uint256) private addressMinTokenAmount;
    mapping(address => uint256) private addressMaxTokenAmount;

    mapping(address => address) private tokenPairAddress;
    address public stableToken;

    constructor(address _stableToken) {
        stableToken = _stableToken;
    }

    function convertUsdBalanceDecimalToTokenDecimal(address _token, uint256 _balanceUsdDecimal) external view returns (uint256) {
        uint256 tokenAmount = addressTokenAmount[_token];
        uint256 usdtAmount = addressUsdtAmount[_token];
        if (tokenAmount > 0 && usdtAmount > 0) {
            uint256 amountTokenDecimal = (_balanceUsdDecimal * tokenAmount) / usdtAmount;
            return amountTokenDecimal;
        }

        address pairAddress = tokenPairAddress[_token];
        require(pairAddress != address(0), "Invalid pair address");
        (uint256 _reserve0, uint256 _reserve1, ) = IPancakePair(pairAddress).getReserves();
        (uint256 _tokenBalance, uint256 _stableBalance) = address(_token) < address(stableToken)
            ? (_reserve0, _reserve1)
            : (_reserve1, _reserve0);

        uint256 minTokenAmount = addressMinTokenAmount[_token];
        uint256 maxTokenAmount = addressMaxTokenAmount[_token];
        uint256 _minTokenAmount = (_balanceUsdDecimal * minTokenAmount) / PRECISION;
        uint256 _maxTokenAmount = (_balanceUsdDecimal * maxTokenAmount) / PRECISION;
        uint256 _tokenAmount = (_balanceUsdDecimal * _tokenBalance) / _stableBalance;

        require(_tokenAmount >= _minTokenAmount, "Price is too low");
        require(_tokenAmount <= _maxTokenAmount, "Price is too hight");

        return _tokenAmount;
    }

    function setTokenPrice(address _token, address _pairAddress, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _minTokenAmount, uint256 _maxTokenAmount) external onlyOwner {
        addressUsdtAmount[_token] = _usdtAmount;
        addressTokenAmount[_token] = _tokenAmount;
        addressMinTokenAmount[_token] = _minTokenAmount;
        addressMaxTokenAmount[_token] = _maxTokenAmount;
        tokenPairAddress[_token] = _pairAddress;
    }

    function setTokenInfo(address _token, address _pairAddress, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _minTokenAmount, uint256 _maxTokenAmount) external onlyOwner {
        addressUsdtAmount[_token] = _usdtAmount;
        addressTokenAmount[_token] = _tokenAmount;
        addressMinTokenAmount[_token] = _minTokenAmount;
        addressMaxTokenAmount[_token] = _maxTokenAmount;
        tokenPairAddress[_token] = _pairAddress;
    }

    function setStableToken(address _stableToken) external onlyOwner {
        stableToken = _stableToken;
    }

    function withdrawTokenEmergency(address _token, uint256 _amount) external onlyOwner {
        require(_amount > 0, "INVALID AMOUNT");
        require(IERC20(_token).transfer(msg.sender, _amount), "CANNOT WITHDRAW TOKEN");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IRanking {
    event PayCommission(address staker, address refAccount, uint256 commissionAmount);

    function setCommissionContract(address _marketContract) external;

    function setNetworkAddress(address _address) external;

    function updateRequiredPersonValue(uint16 _rank, uint256 _value) external;

    function updateRankingPercent(uint16 _rank, uint16 _percent) external;

    function getTeamNftSaleValueForAccountInUsdDecimal(address _wallet) external view returns (uint256);

    function updateRequiredTeamValue(uint16 _rank, uint256 _value) external;

    function updateF1Condition(uint16 _rank, uint256 _value) external;

    function updateUserRanking(address _user) external;

    function payRankingCommission(
        address _currentRef,
        uint256 _commissionRewardTokenWithDecimal
    ) external;

    function getUserRanking(address _user) external view returns (uint8);

    function withdrawTokenEmergency(address _token, uint256 _amount) external;

    function withdrawTokenEmergencyFrom(address _from, address _to, address _currency, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../commission/ICommission.sol";
import "./IRanking.sol";
import "../network/INetwork.sol";
import "../oracle/Oracle.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ranking is IRanking, Ownable, ERC721Holder {
    address public token;
    address public commissionContract;
    address public oracleContract;
    address public networkAddress;
    uint8 private conditionRank1User = 5;
    uint256 private conditionRank1UserValue = 200;
    uint64 public constant TOKEN_DECIMAL = 1000000000000000000;

    mapping(uint16 => uint16) public rankingPercents;
    mapping(address => uint8) userRankings;
    mapping(address => uint256) usdClaimed; // usd claimed with decimal
    mapping(uint16 => uint256) private requireTeamValue;
    mapping(uint16 => uint256) private requirePersonValue;
    mapping(uint16 => uint256) private requireRankF1ConditionValue;

    constructor(
        address _token,
        address _commission,
        address _oracleContract,
        address _networkAddress
    ) {
        token = _token;
        commissionContract = _commission;
        oracleContract = _oracleContract;
        networkAddress = _networkAddress;
        initRankingPercents();
        initRequireTeamValue();
        initRequirePersonValue();
        initRankCondition();
    }

    modifier onlyCommissionContract() {
        require(commissionContract == msg.sender, "RANKING: CALLER IS NOT MARKET CONTRACT");
        _;
    }

    /**
     * @dev init commission percent when ref claim staking token
     */
    function initRankingPercents() internal {
        rankingPercents[0] = 0;
        rankingPercents[1] = 300;
        rankingPercents[2] = 500;
        rankingPercents[3] = 800;
        rankingPercents[4] = 1000;
        rankingPercents[5] = 1100;
        rankingPercents[6] = 1200;
        rankingPercents[7] = 1300;
        rankingPercents[8] = 1500;
    }

    /**
     * @dev require value user's team buy to get ranking
     */
    function initRequireTeamValue() internal {
        requireTeamValue[0] = 0;
        requireTeamValue[1] = 15000;
        requireTeamValue[2] = 50000;
        requireTeamValue[3] = 200000;
        requireTeamValue[4] = 600000;
        requireTeamValue[5] = 3000000;
        requireTeamValue[6] = 10000000;
        requireTeamValue[7] = 40000000;
        requireTeamValue[8] = 100000000;
    }

    function initRequirePersonValue() internal {
        requirePersonValue[0] = 0;
        requirePersonValue[1] = 1000;
        requirePersonValue[2] = 2500;
        requirePersonValue[3] = 5000;
        requirePersonValue[4] = 5000;
        requirePersonValue[5] = 7000;
        requirePersonValue[6] = 10000;
        requirePersonValue[7] = 10000;
        requirePersonValue[8] = 30000;
    }

    function initRankCondition() internal {
        requireRankF1ConditionValue[0] = 0;
        requireRankF1ConditionValue[1] = 0;
        requireRankF1ConditionValue[2] = 2;
        requireRankF1ConditionValue[3] = 2;
        requireRankF1ConditionValue[4] = 2;
        requireRankF1ConditionValue[5] = 2;
        requireRankF1ConditionValue[6] = 2;
        requireRankF1ConditionValue[7] = 2;
        requireRankF1ConditionValue[8] = 2;
    }

    function getTeamNftSaleValueForAccountInUsdDecimal(address _wallet) public view override returns (uint256) {
        uint256 teamNftValue = getChildrenNftSaleValueInUsdDecimal(_wallet);
        return teamNftValue;
    }

    function getChildrenNftSaleValueInUsdDecimal(address _address) internal view returns (uint256) {
        uint256 nftValue = 0;
        address[] memory allF1s = INetwork(networkAddress).getF1ListForAccount(_address);
        for (uint256 i = 0; i < allF1s.length; i++) {
            address f1 = allF1s[i];
            uint256 userStakeValue = ICommission(commissionContract).getReStakeValueUsd(f1);
            nftValue += userStakeValue;
            nftValue += getChildrenNftSaleValueInUsdDecimal(f1);
        }

        return nftValue;
    }

    function setNetworkAddress(address _address) external override onlyOwner {
        require(_address != address(0), "COMMISSION: INVALID NETWORK ADDRESS");
        networkAddress = _address;
    }

    function updateRankingPercent(uint16 _rank, uint16 _percent) external override onlyOwner {
        rankingPercents[_rank] = _percent;
    }

    function updateRequiredTeamValue(uint16 _rank, uint256 _value) external override onlyOwner {
        requireTeamValue[_rank] = _value;
    }

    function updateF1Condition(uint16 _rank, uint256 _value) external override onlyOwner {
        requireRankF1ConditionValue[_rank] = _value;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = _tokenAddress;
    }

    function setCommissionContract(address _marketContract) external override onlyOwner {
        commissionContract = _marketContract;
    }

    function setOracleContract(address _oracleContract) external onlyOwner {
        oracleContract = _oracleContract;
    }

    function setUserRanking(address _user, uint8 _rank) external onlyOwner {
        userRankings[_user] = _rank;
    }

    function setConditionRank1User(uint8 _condition) external onlyOwner  {
        conditionRank1User = _condition;
    }

    function setConditionRank1UserValue(uint256 _value) external onlyOwner  {
        conditionRank1UserValue = _value;
    }

    function getUserRanking(address _user) external view override returns (uint8) {
        return userRankings[_user];
    }

    function updateUserRanking(address _user) public override onlyCommissionContract {
        updateRank(_user);
        updateTeamRankingValue(_user);
    }

    /**
     * @dev update team ranking
     * @param _user user buying
     */
    function updateTeamRankingValue(address _user) internal {
        address currentRef;
        address nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(_user);
        while (currentRef != nextRef && nextRef != address(0)) {
            // Update Team Staking Value
            currentRef = nextRef;
            updateRank(currentRef);
            nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(currentRef);
        }
    }

    function updateRank(address _user) internal {
        uint8 userRanking = userRankings[_user];
        // max rank buy
        uint256 userStakeValue = ICommission(commissionContract).getReStakeValueUsd(_user);
        uint256 teamStakeValue = ICommission(commissionContract).getTeamStakeValue(_user);
        uint256 totalStakeValue = userStakeValue + teamStakeValue;
        uint8 maxRankByTeam = getMaximumRankingByTeam(totalStakeValue);
        uint8 maxRankByPerson = getMaximumRankingByPerson(userStakeValue);
        uint8 maxRank = maxRankByTeam > maxRankByPerson ? maxRankByPerson : maxRankByTeam;
        if (maxRank > userRanking) {
            uint8 currentRank = maxRank;
            bool checkConditionChildren = false;
            while (currentRank >= userRanking && currentRank > 0) {
                if (currentRank == 1) {
                    checkConditionChildren = checkRankR1(_user);
                    if (checkConditionChildren) {
                        break;
                    }
                } else {
                    checkConditionChildren = checkRankAllMemberAddress(_user, currentRank - 1);
                    if (checkConditionChildren) {
                        break;
                    }
                }
                currentRank = currentRank - 1;
            }
            if (currentRank >= userRankings[_user] && checkConditionChildren) {
                userRankings[_user] = currentRank;
            }
        }
    }

    function checkRankR1(address _address) internal view returns (bool) {
        address[] memory allF1s = INetwork(networkAddress).getF1ListForAccount(_address);
        uint count = 0;
        for (uint index = 0; index < allF1s.length; index++) {
            if (count >= conditionRank1User) {
                break;
            }
            uint256 userStakeValue = ICommission(commissionContract).getReStakeValueUsd(allF1s[index]);
            if (userStakeValue >= conditionRank1UserValue * TOKEN_DECIMAL) {
                count++;
            }
        }
        return count >= conditionRank1User;
    }

    function checkRankAllMemberAddress(address _address, uint8 _rank) internal view returns (bool) {
        address[] memory allF1s = INetwork(networkAddress).getF1ListForAccount(_address);
        uint count = 0;
        for (uint index = 0; index < allF1s.length; index++) {
            address f1Address = allF1s[index];
            bool checkRankF1 = checkRankMemberGreater(f1Address, _rank);
            if (checkRankF1) {
                count++;
                continue;
            }
            bool checkRankF2 = checkRank(f1Address, _rank);
            if(checkRankF2) {
                count++;
                continue;
            }
            if (count >= requireRankF1ConditionValue[_rank + 1]) {
                break;
            }
        }
        return count >= requireRankF1ConditionValue[_rank + 1];
    }

    function checkRank(address _address, uint8 _rank) internal view returns (bool) {
        address[] memory allF1s = INetwork(networkAddress).getF1ListForAccount(_address);
        uint count = 0;
        for (uint index = 0; index < allF1s.length; index++) {
            address f1Address = allF1s[index];
            bool checkRankF1 = checkRankMemberGreater(f1Address, _rank);
            if (checkRankF1) {
                count++;
                break;
            }
            bool check = checkRank(f1Address, _rank);
            if (check) {
                count++;
                break;
            }
        }
        return count > 0;
    }

    function updateRequiredPersonValue(uint16 _rank, uint256 _value) external override onlyOwner {
        requirePersonValue[_rank] = _value;
    }

    function checkRankMemberGreater(address _address, uint256 _rank) internal view returns (bool) {
        return userRankings[_address] >= _rank;
    }

    function getMaximumRankingByTeam(uint256 _price) internal view returns (uint8) {
        uint8 ranking = 0;
        if (_price == 0) {
            return ranking;
        }
        for (uint8 rank = 1; rank < 6; rank++) {
            if (_price >= requireTeamValue[rank] * TOKEN_DECIMAL) {
                ranking = rank;
            } else {
                break;
            }
        }
        return ranking;
    }

    function getMaximumRankingByPerson(uint256 _price) internal view returns (uint8) {
        uint8 ranking = 0;
        if (_price == 0) {
            return ranking;
        }
        for (uint8 rank = 1; rank < 8; rank++) {
            if (_price >= requirePersonValue[rank] * TOKEN_DECIMAL) {
                ranking = rank;
            } else {
                break;
            }
        }
        return ranking;
    }

    function payRankingCommission(
        address _currentRef,
        uint256 _totalAmountUsdWithDecimal
    ) public override onlyCommissionContract  {
        uint16 earnedCommissionPercents = 0;
        address currentRef = _currentRef;
        address nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(_currentRef);
        uint256 _commissionCanEarnTokenWithDecimal = 0;
        uint256 commissionCanEarnUsdWithDecimal = 0;
        while (currentRef != nextRef && nextRef != address(0)) {
            // get ref staking
            uint8 userRank = userRankings[currentRef];
            uint16 rankingRefPercent = rankingPercents[userRank];
            if (rankingRefPercent > earnedCommissionPercents) {
                uint16 canEarnCommissionPercents = rankingRefPercent - earnedCommissionPercents;
                uint256 totalCommission = ICommission(commissionContract).getTotalCommission(currentRef);
                ICommission(commissionContract).updateRankingNetworkData(currentRef, _totalAmountUsdWithDecimal, canEarnCommissionPercents, totalCommission);
                commissionCanEarnUsdWithDecimal = ICommission(commissionContract).getCommissionRef(
                    currentRef,
                    _totalAmountUsdWithDecimal,
                    totalCommission,
                    canEarnCommissionPercents);
                if (commissionCanEarnUsdWithDecimal > 0) {
                    _commissionCanEarnTokenWithDecimal = Oracle(oracleContract).convertUsdBalanceDecimalToTokenDecimal(
                        token, commissionCanEarnUsdWithDecimal
                    );
                    require(
                        ERC20(token).balanceOf(address(this)) >= _commissionCanEarnTokenWithDecimal,
                        "RANKING: NOT ENOUGH TOKEN BALANCE TO PAY RANK COMMISSION"
                    );
                    require(
                        ERC20(token).transfer(currentRef, _commissionCanEarnTokenWithDecimal),
                        "RANKING: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
                    );

                    // update usd claimed
                    usdClaimed[currentRef] = usdClaimed[currentRef] + commissionCanEarnUsdWithDecimal;
                }
                earnedCommissionPercents = earnedCommissionPercents + canEarnCommissionPercents;
            }
            currentRef = nextRef;
            nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(currentRef);
        }
    }
    /**
     * @dev get claimed usd ranking
     * @param _user user wallet address
     */
    function getClaimedRankingUsd(address _user) external view returns (uint256) {
        return usdClaimed[_user];
    }

    /**
     * @dev Recover lost bnb and send it to the contract owner
     */
    function recoverLostBNB() external onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    /**
     * @dev withdraw some token balance from contract to owner account
     */
    function withdrawTokenEmergency(address _token, uint256 _amount) public override onlyOwner {
        require(_amount > 0, "RANKING: INVALID AMOUNT");
        require(ERC20(_token).balanceOf(address(this)) >= _amount, "RANKING: TOKEN BALANCE NOT ENOUGH");
        require(ERC20(_token).transfer(msg.sender, _amount), "RANKING: CANNOT WITHDRAW TOKEN");
    }

    /**
     * @dev withdraw some currency balance from contract to owner account
     */
    function withdrawTokenEmergencyFrom(
        address _from,
        address _to,
        address _token,
        uint256 _amount
    ) public override onlyOwner {
        require(_amount > 0, "RANKING: INVALID AMOUNT");
        require(ERC20(_token).balanceOf(_from) >= _amount, "RANKING: CURRENCY BALANCE NOT ENOUGH");
        require(ERC20(_token).transferFrom(_from, _to, _amount), "RANKING: CANNOT WITHDRAW CURRENCY");
    }
}
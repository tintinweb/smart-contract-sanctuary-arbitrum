// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MITrewardTokens
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "./Interfaces.sol";
import "./WombexLensUI.sol";

contract EarmarkRewardsLens {
    uint256 public constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public constant DENOMINATOR = 10000;

    IStaker public voterProxy;
    WombexLensUI public wombexLensUI;
    IBooster public booster;
    IBoosterEarmark public boosterEarmark;
    address public crv;
    uint256 public maxPidsToExecute;

    struct PendingReward {
        address token;
        string symbol;
        uint8 decimals;
        uint256 totalAmount;
        uint256 earmarkAmount;
        uint256 usdPrice;
    }

    struct Pool {
        address lpToken;
        string symbol;
        uint256 pid;
    }

    constructor(IStaker _voterProxy, WombexLensUI _wombexLensUI, uint256 _maxPidsToExecute) {
        voterProxy = _voterProxy;
        wombexLensUI = _wombexLensUI;
        maxPidsToExecute = _maxPidsToExecute;
        updateBooster();
    }

    function updateBooster() public {
        booster = IBooster(voterProxy.operator());
        boosterEarmark = IBoosterEarmark(booster.earmarkDelegate());
        crv = booster.crv();
    }

    function getRewards() public view returns(
        address[] memory tokens,
        string[] memory tokensSymbols,
        uint256[] memory boosterPendingRewards,
        uint256[] memory wombatPendingRewards,
        uint256[] memory availableBalances,
        int256[] memory diffBalances
    ) {
        tokens = boosterEarmark.distributionTokenList();
        tokensSymbols = new string[](tokens.length);
        boosterPendingRewards = new uint256[](tokens.length);
        wombatPendingRewards = new uint256[](tokens.length);
        availableBalances = new uint256[](tokens.length);
        diffBalances = new int256[](tokens.length);

        uint256 poolLen = booster.poolLength();

        for (uint256 i = 0; i < tokens.length; i++) {
            try ERC20(tokens[i]).symbol() returns (string memory symbol) {
                tokensSymbols[i] = symbol;
            } catch {

            }
            for (uint256 j = 0; j < poolLen; j++) {
                IBooster.PoolInfo memory poolInfo = booster.poolInfo(j);
                boosterPendingRewards[i] += booster.lpPendingRewards(poolInfo.lptoken, tokens[i]);

                uint256 wmPid = voterProxy.lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
                (
                    uint256 pendingRewards,
                    IERC20[] memory bonusTokenAddresses,
                    ,
                    uint256[] memory pendingBonusRewards
                ) = IMasterWombatV2(poolInfo.gauge).pendingTokens(wmPid, address(voterProxy));

                if (tokens[i] == crv) {
                    wombatPendingRewards[i] += pendingRewards;
                }

                for (uint256 k = 0; k < bonusTokenAddresses.length; k++) {
                    if (address(bonusTokenAddresses[k]) == tokens[i]) {
                        wombatPendingRewards[i] += pendingBonusRewards[k];
                    }
                }
            }
            availableBalances[i] = IERC20(tokens[i]).balanceOf(address(booster)) + IERC20(tokens[i]).balanceOf(address(voterProxy));

            diffBalances[i] = int256(wombatPendingRewards[i]) + int256(availableBalances[i]) - int256(boosterPendingRewards[i]);
        }
    }

    function getEarmarkablePools() public view returns(bool[] memory earmarkablePools, uint256 poolsCount) {
        uint256 poolLen = booster.poolLength();
        earmarkablePools = new bool[](poolLen);

        for (uint256 i = 0; i < poolLen; i++) {
            IBooster.PoolInfo memory p = booster.poolInfo(i);
            if (p.shutdown || !boosterEarmark.isEarmarkPoolAvailable(i, p)) {
                continue;
            }

            (address token , uint256 periodFinish, , , , , , , bool paused) = IRewards(p.crvRewards).tokenRewards(crv);
            if (token == crv && periodFinish < block.timestamp && IERC20(crv).balanceOf(p.crvRewards) > 1000 ether) {
                earmarkablePools[i] = true;
                poolsCount++;
                continue;
            }

            (uint256 pendingRewards, , , uint256[] memory pendingBonusRewards) = IMasterWombatV2(p.gauge).pendingTokens(
                voterProxy.lpTokenToPid(p.gauge, p.lptoken),
                address(voterProxy)
            );
            if (pendingRewards != 0) {
                earmarkablePools[i] = true;
                poolsCount++;
                continue;
            }
            for (uint256 j = 0; j < pendingBonusRewards.length; j++) {
                if (pendingBonusRewards[j] != 0) {
                    earmarkablePools[i] = true;
                    poolsCount++;
                    break;
                }
            }
        }
    }

    function getPidsToEarmark(bool _useMaxPidsCount) public view returns(uint256[] memory pids) {
        (bool[] memory earmarkablePools, uint256 poolsCount) = getEarmarkablePools();
        if (_useMaxPidsCount) {
            poolsCount = poolsCount > maxPidsToExecute ? maxPidsToExecute : poolsCount;
        }
        pids = new uint256[](poolsCount);
        uint256 curIndex = 0;
        for (uint256 i = 0; i < earmarkablePools.length; i++) {
            if (earmarkablePools[i]) {
                pids[curIndex] = i;
                curIndex++;
                if (_useMaxPidsCount && curIndex == maxPidsToExecute) {
                    break;
                }
            }
        }
    }

    function earmarkResolver() public view returns(bool execute, bytes memory data) {
        uint256[] memory pidsToExecute = getPidsToEarmark(true);
        return (
            pidsToExecute.length > 0,
            abi.encodeWithSelector(IBoosterEarmark.earmarkRewards.selector, pidsToExecute)
        );
    }

    function getPoolsQueue() public view returns(uint256[] memory pidsNextExecuteOn) {
        uint256 poolLen = booster.poolLength();
        pidsNextExecuteOn = new uint256[](poolLen);
        for (uint256 i = 0; i < poolLen; i++) {
            pidsNextExecuteOn[i] = boosterEarmark.getEarmarkPoolExecuteOn(i);
        }
    }

    function getPoolPendingRewards(uint256 _pid) public returns(PendingReward[] memory rewards) {
        uint256 earmarkIncentive = IBoosterEarmark(booster.earmarkDelegate()).earmarkIncentive();
        IBooster.PoolInfo memory poolInfo = booster.poolInfo(_pid);

        uint256 wmPid = voterProxy.lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
        uint256 crvIndex = MAX_UINT;
        (
            uint256 womPendingRewards,
            IERC20[] memory bonusTokenAddresses,
            ,
            uint256[] memory pendingBonusRewards
        ) = IMasterWombatV2(poolInfo.gauge).pendingTokens(wmPid, address(voterProxy));

        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            if (address(bonusTokenAddresses[i]) == crv) {
                crvIndex = i;
                pendingBonusRewards[i] += womPendingRewards;
            }
        }

        rewards = new PendingReward[](crvIndex == MAX_UINT ? bonusTokenAddresses.length + 1 : bonusTokenAddresses.length);
        uint256 womPrice = wombexLensUI.estimateInBUSDEther(crv, 1 ether, 18);
        uint256 curIndex = 0;
        if (crvIndex == MAX_UINT) {
            uint256 rewardsAmount = womPendingRewards + booster.lpPendingRewards(poolInfo.lptoken, crv);
            rewards[curIndex] = PendingReward(crv, "WOM", uint8(18), womPendingRewards, womPendingRewards * earmarkIncentive / DENOMINATOR, womPrice);
            curIndex++;
        }

        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            address rewardToken = address(bonusTokenAddresses[i]);
            string memory symbol;
            try ERC20(rewardToken).symbol() returns (string memory _symbol) {
                symbol = symbol;
            } catch { }

            uint256 rewardsAmount = pendingBonusRewards[i] + booster.lpPendingRewards(poolInfo.lptoken, rewardToken);
            rewards[curIndex] = PendingReward(
                rewardToken,
                symbol,
                uint8(18),
                rewardsAmount,
                rewardsAmount * earmarkIncentive / DENOMINATOR,
                wombexLensUI.estimateInBUSDEther(rewardToken, 1 ether, 18)
            );
            curIndex++;
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8 decimals) {
        try ERC20(_token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
        } catch {
            decimals = uint8(18);
        }
    }

    function getRewardsToExecute() public returns (uint256 earmarkIncentive, PendingReward[] memory rewards, Pool[] memory pools) {
        earmarkIncentive = IBoosterEarmark(booster.earmarkDelegate()).earmarkIncentive();

        address[] memory tokens = boosterEarmark.distributionTokenList();
        rewards = new PendingReward[](tokens.length);

        uint256[] memory pidsToExecute = getPidsToEarmark(true);
        pools = new Pool[](pidsToExecute.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            rewards[i].token = tokens[i];
            try ERC20(tokens[i]).symbol() returns (string memory _symbol) {
                rewards[i].symbol = _symbol;
            } catch { }
            for (uint256 j = 0; j < pidsToExecute.length; j++) {
                IBooster.PoolInfo memory poolInfo = booster.poolInfo(pidsToExecute[j]);
                if (i == 0) {
                    pools[j].lpToken = poolInfo.lptoken;
                    pools[j].pid = pidsToExecute[j];
                    try ERC20(pools[j].lpToken).symbol() returns (string memory _symbol) {
                        pools[j].symbol = _symbol;
                    } catch { }
                }

                uint256 wmPid = voterProxy.lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
                (
                    uint256 pendingRewards,
                    IERC20[] memory bonusTokenAddresses,
                    ,
                    uint256[] memory pendingBonusRewards
                ) = IMasterWombatV2(poolInfo.gauge).pendingTokens(wmPid, address(voterProxy));

                if (tokens[i] == crv) {
                    rewards[i].totalAmount += pendingRewards;
                }

                for (uint256 k = 0; k < bonusTokenAddresses.length; k++) {
                    if (address(bonusTokenAddresses[k]) == tokens[i]) {
                        rewards[i].totalAmount += pendingBonusRewards[k];
                    }
                }
            }
            rewards[i].earmarkAmount = rewards[i].totalAmount * earmarkIncentive / DENOMINATOR;
            rewards[i].decimals = getTokenDecimals(tokens[i]);
            rewards[i].usdPrice = wombexLensUI.estimateInBUSDEther(crv, 10 ** rewards[i].decimals, rewards[i].decimals);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface IWomDepositor {
    function deposit(uint256 _amount, address _stakeAddress) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

interface IWmxLocker {
    struct EarnedData {
        address token;
        uint256 amount;
    }
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function balanceOf(address _account) external view returns (uint256 amount);

    function balances(address _account) external view returns (uint112 locked, uint32 nextUnlockIndex);

    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);

    function getVotes(address account) external view returns (uint256);

    function getPastVotes(address account, uint256 timestamp) external view returns (uint256 votes);

    function lockedBalances(address _user) external view returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    );
}

interface IBribeVoter {
    function vote(IERC20[] calldata _lpVote, int256[] calldata _deltas) external returns (uint256[][] memory bribeRewards);
    function votes(address _user, address _lpToken) external view returns (uint256);
    function infos(address _lpToken) external view returns (uint104 supplyBaseIndex, uint104 supplyVoteIndex, uint40 nextEpochStartTime, uint128 claimable, bool whitelist, address gaugeManager, address bribe);
    function weights(address _lpToken) external view returns (uint128 allocPoint, uint128 voteWeight);
    function getUserVotes(address _user, address _lpToken) external view returns (uint256);
}

interface IMasterWombatRewarder {
    function rewardTokens() external view returns (address[] memory tokens);
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

interface IWomDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
}

interface ITokenFactory{
    function CreateDepositToken(address) external returns(address);
    function CreateBribesVotingToken() external returns(address);
}

interface IBribesRewardFactory {
    function CreateBribesRewards(address _stakingToken, address _lptoken, bool _callOperatorOnGetReward) external returns (address);
}

interface IRewards{
    function asset() external returns(address);
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function withdraw(uint256 assets, address receiver, address owner) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(address, uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address _token, address _account) external view returns (uint256);
    function updateOperatorData(address operator_, uint256 pid_) external;
    function setRewardTokenPaused(address token_, bool paused_) external;
    function balanceOf(address _account) external view returns (uint256 amount);
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (address token, uint256 periodFinish, uint256 rewardRate, uint256 lastUpdateTime, uint256 rewardPerTokenStored, uint256 queuedRewards, uint256 currentRewards, uint256 historicalRewards, bool paused);
}

interface IGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IBribe {
    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);

    function rewardInfo(uint256 i) external view returns (IERC20 rewardToken, uint96 tokenPerSec, uint128 accTokenPerShare, uint128 distributedAmount);
}

interface IVe {
    function vote(address user, int256 voteDelta) external;
}

interface INftLocker {
    function voteBoost(address _account) external view returns (uint256);
}

interface IBribeRewardsPool is IRewards {
    function withdrawAndUnwrapFrom(address _from, uint256 _amount, address _claimRecipient) external returns(bool);
    function updateBribesConfig(bool _callOperatorOnGetReward) external;
    function updateRatioConfig(uint256 _duration, uint256 _maxRewardRatio) external;
}

interface ITokenMinter is IERC20 {
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setOperator(address) external;
    function updateOperator(address) external;
    function getFactAmounMint(uint256 _amount) external view returns(uint256 amount);
}

interface IStaker{
    function deposit(address, address) external returns (bool);
    function withdraw(address) external returns (uint256);
    function withdrawLp(address, address, uint256) external returns (bool);
    function withdrawAllLp(address, address) external returns (bool);
    function lock(uint256 _lockDays) external;
    function releaseLock(uint256 _slot) external returns(uint256);
    function getGaugeRewardTokens(address _lptoken, address _gauge) external returns (address[] memory tokens);
    function claimCrv(address, uint256) external returns (address[] memory tokens, uint256[] memory balances);
    function balanceOfPool(address, address) external view returns (uint256);
    function lpTokenToPid(address, address) external view returns (uint256);
    function operator() external view returns (address);
    function depositor() external view returns (address);
    function veWom() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
    function setVote(bytes32 hash, bool valid) external;
    function setDepositor(address _depositor) external;
    function setOwner(address _owner) external;
}

interface IPool {
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view returns (uint256 liquidity, uint256 reward);

    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);

    function addressOfAsset(address token) external view returns (address);

    function getTokens() external view returns (address[] memory);
}

interface IWombatRouter {
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * Note: This function should be used as estimation only. The actual swap amount might
     * be different due to precision error (the error is typically under 1e-6)
     */
    function getAmountIn(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountOut
    ) external view returns (uint256 amountIn, uint256[] memory haircuts);

    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNativeForTokens(
        address[] calldata tokenPath, // the first address should be WBNB
        address[] calldata poolPath,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForNative(
        address[] calldata tokenPath, // the last address should be WBNB
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function addLiquidityNative(
        IPool pool,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external payable returns (uint256 liquidity);

    function removeLiquidityNative(
        IPool pool,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function removeLiquidityFromOtherAssetAsNative(
        IPool pool,
        address fromToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }

    function crv() external view returns (address);
    function owner() external view returns (address);
    function voterProxy() external view returns (address);
    function earmarkDelegate() external view returns (address);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function depositFor(uint256 _pid, uint256 _amount, bool _stake, address _receiver) external returns (bool);
    function setOwner(address _owner) external;
    function setPoolManager(address _poolManager) external;
    function voterProxyClaimRewards(uint256 _pid, address[] memory pendingTokens) external returns (uint256[] memory pendingRewards);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
    function approveDistribution(address _distro, address[] memory _distributionTokens, uint256 _amount) external;
    function approvePoolsCrvRewardsDistribution(address _token) external;
    function distributeRewards(uint256 _pid, address _lpToken, address _rewardToken, address[] memory _transferTo, uint256[] memory _transferAmount, bool[] memory _callQueue) external;
    function lpPendingRewards(address _lptoken, address _token) external view returns (uint256);
    function earmarkRewards(uint256 _pid) external;
    function earmarkRewardsIfAvailable(uint256 _pid) external;
    function shutdownPool(uint256 _pid) external returns (bool);
    function forceShutdownPool(uint256 _pid) external returns (bool);
    function gaugeMigrate(address _newGauge, uint256[] memory migratePids) external;
    function voteExecute(address _voting, uint256 _value, bytes calldata _data) external returns (bytes memory);
    function setVotingValid(address _voting, bool _value) external;
    function mintRatio() external view returns (uint256);
    function customMintRatio(uint256 _pid) external view returns (uint256);
    function crvLockRewards() external view returns (address);
    function cvxLocker() external view returns (address);
    function minterMint(address _address, uint256 _amount) external returns(bool);
}

interface IBoosterEarmark {
    function earmarkIncentive() external view returns (uint256);
    function distributionByTokenLength(address _token) external view returns (uint256);
    function distributionByTokens(address, uint256) external view returns (address, uint256, bool);
    function distributionTokenList() external view returns (address[] memory);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
    function isEarmarkAvailable(uint256 _pid) external view returns(bool);
    function isEarmarkPoolAvailable(uint256 _pid, IBooster.PoolInfo memory _pool) external view returns (bool);
    function earmarkRewards(uint256[] memory _pids) external;
    function earmarkPeriod() external view returns (uint256);
    function lastEarmarkAt(uint256 pid) external view returns (uint256);
    function getEarmarkPoolExecuteOn(uint256 pid) external view returns (uint256);
}

interface ISwapRouter {
    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);
}

interface IWomSwapDepositor {
    function pool() external view returns (address);
    function deposit(uint256 _amount, address _stakeAddress, uint256 _minAmountOut, uint256 _deadline) external returns (bool);
}

/**
 * @dev Interface of the MasterWombatV2
 */
interface IMasterWombatV2 {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
    external
    view
    returns (
        uint256 pendingRewards,
        IERC20[] memory bonusTokenAddresses,
        string[] memory bonusTokenSymbols,
        uint256[] memory pendingBonusRewards
    );

    function rewarderBonusTokenInfo(uint256 _pid)
    external
    view
    returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
    external
    returns (
        uint256 transfered,
        uint256[] memory rewards,
        uint256[][] memory additionalRewards
    );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;

    function poolInfo(uint256 _pid) external view returns (address lpToken, uint96 allocPoint, IMasterWombatRewarder rewarder, uint256 sumOfFactors, uint104 accWomPerShare, uint104 accWomPerFactorShare, uint40 lastRewardTimestamp);
}

interface IMasterWombatV3 {
    struct PoolInfoV3 {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
    }

    function poolInfoV3(uint256 _index) external view returns (PoolInfoV3 memory);

    // Info of each user.
    struct UserInfo {
        // storage slot 1
        uint128 amount; // 20.18 fixed point. How many LP tokens the user has provided.
        uint128 factor; // 20.18 fixed point. boosted factor = sqrt (lpAmount * veWom.balanceOf())
        // storage slot 2
        uint128 rewardDebt; // 20.18 fixed point. Reward debt. See explanation below.
        uint128 pendingWom; // 20.18 fixed point. Amount of pending wom
    }
    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "./Interfaces.sol";

interface IUniswapV2Router01 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface FraxRouter {
    function getAmountsOutWithTwamm(uint amountIn, address[] memory path) external returns (uint[] memory amounts);
}

interface QuoterV2 {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

interface IWmx {
    function getFactAmounMint(uint256) external view returns (uint256);
}

interface IWomAsset {
    function pool() external view returns (address);
    function underlyingToken() external view returns (address);
}

interface IWomPool {
    function quotePotentialWithdraw(address _token, uint256 _liquidity) external view returns (uint256);
    function quotePotentialWithdrawFromOtherAsset(address fromToken, address toToken, uint256 liquidity) external view virtual returns (uint256 amount, uint256 withdrewAmount);
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);
    function getTokens() external view returns (address[] memory);
}

interface IBaseRewardPool4626 {
    struct RewardState {
        address token;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 currentRewards;
        uint256 historicalRewards;
        bool paused;
    }
    function asset() external view returns (address);
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (RewardState memory);
    function claimableRewards(address _account)
        external view returns (address[] memory tokens, uint256[] memory amounts);
}

contract WombexLensUI is Ownable {
    address public UNISWAP_ROUTER;
    address public UNISWAP_V3_QUOTER;

    address public MAIN_STABLE_TOKEN;
    uint8 public MAIN_STABLE_TOKEN_DECIMALS;

    address public WOM_TOKEN;
    address public WMX_TOKEN;
    address public WMX_MINTER;
    address public WETH_TOKEN;
    address public WMX_WOM_TOKEN;

    mapping(address => address) public swapTokenByPool;
    mapping(address => bool) public isUsdStableToken;
    mapping(address => address) public poolToToken;
    mapping(address => address) public tokenToRouter;
    mapping(address => bool) public tokenUniV3;
    mapping(address => address[]) public tokenSwapThroughTokens;
    mapping(address => address) public tokenSwapToTargetStable;

    struct PoolValues {
        string symbol;
        uint256 pid;
        uint256 lpTokenPrice;
        uint256 lpTokenBalance;
        uint256 tvl;
        uint256 wmxApr;
        uint256 itemApr;
        uint256 totalApr;
        address rewardPool;
        PoolValuesTokenApr[] tokenAprs;
    }

    struct PoolValuesTokenApr {
        address token;
        uint256 apr;
        bool isPeriodFinish;
    }

    struct PoolRewardRate {
        address[] rewardTokens;
        uint256[] rewardRates;
    }

    struct RewardContractData {
        address poolAddress;
        uint128 lpBalance;
        uint128 underlyingBalance;
        uint128 usdBalance;
        uint8 decimals;
        RewardItem[] rewards;
    }

    struct RewardItem {
        address rewardToken;
        uint128 amount;
        uint128 usdAmount;
        uint8 decimals;
    }

    constructor(
        address _UNISWAP_ROUTER,
        address _UNISWAP_V3_ROUTER,
        address _MAIN_STABLE_TOKEN,
        address _WOM_TOKEN,
        address _WMX_TOKEN,
        address _WMX_MINTER,
        address _WETH_TOKEN,
        address _WMX_WOM_TOKEN
    ) {
        UNISWAP_ROUTER = _UNISWAP_ROUTER;
        UNISWAP_V3_QUOTER = _UNISWAP_V3_ROUTER;
        MAIN_STABLE_TOKEN = _MAIN_STABLE_TOKEN;
        MAIN_STABLE_TOKEN_DECIMALS = getTokenDecimals(_MAIN_STABLE_TOKEN);
        WOM_TOKEN = _WOM_TOKEN;
        WMX_TOKEN = _WMX_TOKEN;
        WMX_MINTER = _WMX_MINTER;
        WETH_TOKEN = _WETH_TOKEN;
        WMX_WOM_TOKEN = _WMX_WOM_TOKEN;
    }

    function setUsdStableTokens(address[] memory _tokens, bool _isStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            isUsdStableToken[_tokens[i]] = _isStable;
        }
    }

    function setSwapTokenByPool(address[] memory _tokens, address _pool) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            swapTokenByPool[_tokens[i]] = _pool;
        }
    }

    function setPoolsForToken(address[] memory _pools, address _token) external onlyOwner {
        for (uint256 i = 0; i < _pools.length; i++) {
            poolToToken[_pools[i]] = _token;
        }
    }

    function setTokensToRouter(address[] memory _tokens, address _router) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenToRouter[_tokens[i]] = _router;
        }
    }

    function setTokenUniV3(address[] memory _tokens, bool _tokenUniV3) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenUniV3[_tokens[i]] = _tokenUniV3;
        }
    }

    function setTokenSwapThroughToken(address[] memory _tokens, address[] memory _throughTokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapThroughTokens[_tokens[i]] = _throughTokens;
        }
    }

    function setTokensTargetStable(address[] memory _tokens, address _targetStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapToTargetStable[_tokens[i]] = _targetStable;
        }
    }

    function getApys1(
        IBooster _booster
    ) public returns(PoolValues[] memory) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();
        PoolValues[] memory result = new PoolValues[](len);
        uint256 wmxUsdPrice = estimateInBUSD(WMX_TOKEN, 1 ether, uint8(18));

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            IBaseRewardPool4626 crvRewards = IBaseRewardPool4626(poolInfo.crvRewards);
            address pool = IWomAsset(poolInfo.lptoken).pool();

            PoolValues memory pValues;

            pValues.pid = i;
            pValues.symbol = ERC20(poolInfo.lptoken).symbol();
            pValues.rewardPool = poolInfo.crvRewards;

            // 1. Calculate Tvl
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();
            pValues.lpTokenPrice = getLpUsdOut(pool, underlyingToken, 1 ether);
            pValues.lpTokenBalance = ERC20(poolInfo.crvRewards).totalSupply();
            pValues.tvl = pValues.lpTokenBalance * pValues.lpTokenPrice / 1 ether;

            // 2. Calculate APYs
            if (pValues.tvl > 10) {
                (pValues.tokenAprs, pValues.totalApr, pValues.itemApr, pValues.wmxApr) = getRewardPoolApys(crvRewards, pValues.tvl, wmxUsdPrice, mintRatio);
            }

            result[i] = pValues;
        }

        return result;
    }

    function getRewardPoolApys(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(
        PoolValuesTokenApr[] memory aprs,
        uint256 aprTotal,
        uint256 aprItem,
        uint256 wmxApr
    ) {
        address[] memory rewardTokens = crvRewards.rewardTokensList();
        uint256 len = rewardTokens.length;
        aprs = new PoolValuesTokenApr[](len);

        for (uint256 i = 0; i < len; i++) {
            aprs[i].token = rewardTokens[i];
            IBaseRewardPool4626.RewardState memory rewardState = crvRewards.tokenRewards(aprs[i].token);
            aprs[i].isPeriodFinish = rewardState.periodFinish < block.timestamp;
            if (aprs[i].isPeriodFinish) {
                continue;
            }

            if (aprs[i].token == WOM_TOKEN) {
                uint256 factAmountMint = IWmx(WMX_MINTER).getFactAmounMint(rewardState.rewardRate * 365 days);
                uint256 wmxRate = factAmountMint;
                if (mintRatio > 0) {
                    wmxRate = factAmountMint * mintRatio / 10_000;
                }

                wmxApr += wmxRate * wmxUsdPrice * 100 / poolTvl / 1e16;
            }

            uint8 decimals = getTokenDecimals(aprs[i].token);
            uint256 usdPrice = estimateInBUSDEther(aprs[i].token, 10 ** decimals, decimals);
            uint256 rewardRate = rewardState.rewardRate * 10 ** (18 - decimals);
            aprs[i].apr = rewardRate * 365 days * usdPrice * 100 / poolTvl / 1e16;
            aprItem += rewardRate * 365 days * usdPrice / 1e16;
            aprTotal += aprs[i].apr;
        }
        aprTotal += wmxApr;
    }

    function getRewardPoolTotalApr(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(uint256 aprItem, uint256 aprTotal) {
        (, aprTotal, aprItem, ) = getRewardPoolApys(crvRewards, poolTvl, wmxUsdPrice, mintRatio);
    }

    function getRewardPoolTotalApr128(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(uint128 aprItem128, uint128 aprTotal128) {
        (uint256 aprItem, uint256 aprTotal) = getRewardPoolTotalApr(crvRewards, poolTvl, wmxUsdPrice, mintRatio);
        aprTotal128 = uint128(aprTotal);
        aprItem128 = uint128(aprItem);
    }

    function getBribeApys(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(
        PoolValuesTokenApr[] memory aprs,
        uint256 aprItem,
        uint256 aprTotal
    ) {
        (, , , , , , address bribe) = bribesVoter.infos(lpToken);
        if (bribe == address(0)) {
            return (new PoolValuesTokenApr[](0), 0, 0);
        }
        (, uint128 voteWeight) = bribesVoter.weights(lpToken);
        uint256 userVotes = bribesVoter.getUserVotes(voterProxy, lpToken);
        if (userVotes == 0) {
            userVotes = 1 ether;
        }
        IERC20[] memory rewardTokens = IBribe(bribe).rewardTokens();
        aprs = new PoolValuesTokenApr[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            aprs[i].token = address(rewardTokens[i]);

            (, uint96 tokenPerSec, , ) = IBribe(bribe).rewardInfo(i);
            uint256 usdPerSec = estimateInBUSDEther(aprs[i].token, tokenPerSec, getTokenDecimals(aprs[i].token));
            if (voteWeight / poolTvl > 0) {
                aprs[i].apr = usdPerSec * 365 days * 10e3 / (voteWeight * allPoolsTvl / veWomBalance);
                // 365 * 24 * 60 * 60 * rewardInfo.tokenPerSec * tokenUsdcPrice * userVotes / weight / (rewardPoolTotalSupply * wmxPrice) * 100,
                aprItem += usdPerSec * 365 days * userVotes * 100 / voteWeight;
            }
            aprTotal += aprs[i].apr;
        }
    }

    function getBribeTotalApr(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(uint256 aprItem, uint256 aprTotal) {
        (, aprItem, aprTotal) = getBribeApys(voterProxy, bribesVoter, lpToken, poolTvl, allPoolsTvl, veWomBalance);
    }

    function getBribeTotalApr128(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(uint128 aprItem128, uint128 aprTotal128) {
        (uint256 aprItem, uint256 aprTotal) = getBribeTotalApr(voterProxy, bribesVoter, lpToken, poolTvl, allPoolsTvl, veWomBalance);
        aprItem128 = uint128(aprItem);
        aprTotal128 = uint128(aprTotal);
    }

    function getTvl(IBooster _booster) public returns(uint256 tvlSum) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            address pool = IWomAsset(poolInfo.lptoken).pool();
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();
            tvlSum += ERC20(poolInfo.crvRewards).totalSupply() * getLpUsdOut(pool, underlyingToken, 1 ether) / 1 ether;
        }
        address voterProxy = _booster.voterProxy();
        tvlSum += estimateInBUSD(WOM_TOKEN, ERC20(IStaker(voterProxy).veWom()).balanceOf(voterProxy), 18);
        tvlSum += estimateInBUSD(WMX_TOKEN, ERC20(WMX_TOKEN).balanceOf(_booster.cvxLocker()), 18);
    }

    function getTotalRevenue(IBooster _booster, address[] memory _oldCrvRewards, uint256 _revenueRatio) public returns(uint256 totalRevenueSum, uint256 totalWomSum) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            (uint256 revenueSum, uint256 womSum) = getPoolRewardsInUsd(poolInfo.crvRewards);
            totalRevenueSum += revenueSum;
            totalWomSum += womSum;
        }
        for (uint256 i = 0; i < _oldCrvRewards.length; i++) {
            (uint256 revenueSum, uint256 womSum) = getPoolRewardsInUsd(_oldCrvRewards[i]);
            totalRevenueSum += revenueSum;
            totalWomSum += womSum;
        }
        (uint256 revenueSum, uint256 womSum) = getPoolRewardsInUsd(_booster.crvLockRewards());
        totalRevenueSum += revenueSum;
        totalWomSum += womSum;

        totalRevenueSum += totalRevenueSum * _revenueRatio / 1 ether; // due to locker inaccessible rewards
        totalWomSum += totalWomSum * _revenueRatio / 1 ether; // due to locker inaccessible rewards
    }

    function getPoolRewardsInUsd(address _crvRewards) public returns(uint256 revenueSum, uint256 womSum) {
        address[] memory rewardTokensList = IBaseRewardPool4626(_crvRewards).rewardTokensList();

        for (uint256 j = 0; j < rewardTokensList.length; j++) {
            address t = rewardTokensList[j];
            IBaseRewardPool4626.RewardState memory tRewards = IBaseRewardPool4626(_crvRewards).tokenRewards(t);
            revenueSum += estimateInBUSDEther(t, tRewards.historicalRewards + tRewards.queuedRewards, getTokenDecimals(t));
            if (t == WOM_TOKEN || t == WMX_WOM_TOKEN) {
                womSum += tRewards.historicalRewards + tRewards.queuedRewards;
            }
        }
    }

    function getProtocolStats(IBooster _booster, address[] memory _oldCrvRewards, uint256 _revenueRatio) public returns(uint256 tvl, uint256 totalRevenue, uint256 earnedWomSum, uint256 veWomShare) {
        tvl = getTvl(_booster);
        (totalRevenue, earnedWomSum) = getTotalRevenue(_booster, _oldCrvRewards, _revenueRatio);
        address voterProxy = _booster.voterProxy();
        ERC20 veWom = ERC20(IStaker(voterProxy).veWom());
        veWomShare = (veWom.balanceOf(voterProxy) * 1 ether) / veWom.totalSupply();
    }

    function getTokenToWithdrawFromPool(address _womPool) public view returns (address tokenOut) {
        tokenOut = poolToToken[_womPool];
        if (tokenOut == address(0)) {
            address[] memory tokens = IWomPool(_womPool).getTokens();
            for (uint256 i = 0; i < tokens.length; i++) {
                if (isUsdStableToken[tokens[i]]) {
                    tokenOut = tokens[i];
                    break;
                }
            }
            if (tokenOut == address(0)) {
                address[] memory tokens = IWomPool(_womPool).getTokens();
                for (uint256 i = 0; i < tokens.length; i++) {
                    if (tokens[i] == WOM_TOKEN || tokens[i] == WMX_TOKEN || tokens[i] == WETH_TOKEN) {
                        tokenOut = tokens[i];
                        break;
                    }
                }
            }
        }
    }

    function getLpUsdOut(
        address _womPool,
        address _fromToken,
        uint256 _lpTokenAmountIn
    ) public returns (uint256 result) {
        address tokenOut = getTokenToWithdrawFromPool(_womPool);
        if (tokenOut == address(0)) {
            revert("stable not found for pool");
        }
        return quotePotentialWithdrawalTokenToBUSD(_womPool, _fromToken, tokenOut, _lpTokenAmountIn);
    }

    function quotePotentialWithdrawalTokenToBUSD(address _womPool, address _fromToken, address _tokenOut, uint256 _lpTokenAmountIn) public returns (uint256) {
        if (_fromToken == _tokenOut) {
            try IWomPool(_womPool).quotePotentialWithdraw(_tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut) {
                uint8 decimals = getTokenDecimals(_tokenOut);
                return estimateInBUSDEther(_tokenOut, tokenAmountOut, decimals);
            } catch {
            }
        } else {
            try IWomPool(_womPool).quotePotentialWithdrawFromOtherAsset(_fromToken, _tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut, uint256 withdrewAmount) {
                uint8 decimals = getTokenDecimals(_tokenOut);
                return estimateInBUSDEther(_tokenOut, tokenAmountOut, decimals);
            } catch {
            }
        }
        return 0;
    }

    function tokenToPoolToken(address _token, uint256 _tokenAmount) public view returns (uint256 resAmount, address resToken) {
        address pool = swapTokenByPool[_token];
        resToken = poolToToken[pool];
        if (_tokenAmount == 0) {
            return (0, resToken);
        }
        uint8 decimals = getTokenDecimals(_token);
        try IWomPool(pool).quotePotentialSwap(_token, resToken, int256(10 ** decimals)) returns (uint256 potentialOutcome, uint256 haircut) {
            resAmount = potentialOutcome * _tokenAmount / (10 ** decimals);
        } catch {
        }
    }

    function estimateInBUSDEther(address _token, uint256 _amountIn, uint256 _decimals) public returns (uint256 result) {
        return estimateInBUSD(_token, _amountIn, _decimals) * 10 ** (18 - _decimals);
    }

    // Estimates a token equivalent in USD (BUSD) using a Uniswap-compatible router
    function estimateInBUSD(address _token, uint256 _amountIn, uint256 _decimals) public returns (uint256 result) {
        if (_amountIn == 0) {
            return 0;
        }
        // 1. All the USD stable tokens are roughly estimated as $1.
        if (isUsdStableToken[_token]) {
            return _amountIn;
        }

        address router = UNISWAP_ROUTER;

        if (tokenToRouter[_token] != address(0)) {
            router = tokenToRouter[_token];
        }
        if (swapTokenByPool[_token] != address(0)) {
            (_amountIn, _token) = tokenToPoolToken(_token, _amountIn);
        }

        address targetStable = MAIN_STABLE_TOKEN;
        uint8 targetStableDecimals = MAIN_STABLE_TOKEN_DECIMALS;
        if (tokenSwapToTargetStable[_token] != address(0)) {
            targetStable = tokenSwapToTargetStable[_token];
            targetStableDecimals = getTokenDecimals(targetStable);
        }

        address[] memory path;
        address[] memory throughTokens = tokenSwapThroughTokens[_token];
        if (throughTokens.length > 0) {
            path = new address[](2 + throughTokens.length);
            path[0] = _token;
            for(uint256 i = 0; i < throughTokens.length; i++) {
                path[1 + i] = throughTokens[i];
            }
            path[path.length - 1] = targetStable;
        } else {
            path = new address[](2);
            path[0] = _token;
            path[1] = targetStable;
        }

        uint256 oneUnit = 10 ** _decimals;
        _amountIn = _amountIn * 10 ** (_decimals - targetStableDecimals);
        if (router == 0xCAAaB0A72f781B92bA63Af27477aA46aB8F653E7) { // frax router
            try FraxRouter(router).getAmountsOutWithTwamm(oneUnit, path) returns (uint256[] memory amountsOut) {
                result = _amountIn * amountsOut[amountsOut.length - 1] / oneUnit;
            } catch {
            }
        } else if (tokenUniV3[_token]) {
            QuoterV2.QuoteExactInputSingleParams memory params = QuoterV2.QuoteExactInputSingleParams(_token, targetStable, oneUnit, 3000, 0);
            try QuoterV2(UNISWAP_V3_QUOTER).quoteExactInputSingle(params) returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate) {
                result = _amountIn * amountOut / oneUnit;
            } catch {
            }
        } else {
            try IUniswapV2Router01(router).getAmountsOut(oneUnit, path) returns (uint256[] memory amountsOut) {
                result = _amountIn * amountsOut[amountsOut.length - 1] / oneUnit;
            } catch {
            }
        }
    }

    /*** USER DETAILS ***/

    function getUserBalancesDefault(
        IBooster _booster,
        address _user
    ) public returns(
        RewardContractData[] memory pools,
        RewardContractData memory wmxWom,
        RewardContractData memory locker
    ) {
        pools = getUserBalances(_booster, _user, allBoosterPoolIds(_booster));
        wmxWom = getUserWmxWom(_booster, _booster.crvLockRewards(), _user);
        locker = getUserLocker(_booster.cvxLocker(), _user);
    }

    function allBoosterPoolIds(IBooster _booster) public view returns (uint256[] memory) {
        uint256 len = _booster.poolLength();
        uint256[] memory poolIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            poolIds[i] = i;
        }
        return poolIds;
    }

    function getUserWmxWom(
        IBooster _booster,
        address _crvLockRewards,
        address _user
    ) public returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserPendingRewards(_booster.mintRatio(), _crvLockRewards, _user);
        uint256 wmxWomBalance = ERC20(_crvLockRewards).balanceOf(_user);
        (uint256 womBalance, ) = tokenToPoolToken(WMX_WOM_TOKEN, wmxWomBalance);
        data = RewardContractData(_crvLockRewards, uint128(wmxWomBalance), uint128(womBalance), uint128(0), uint8(18), rewards);
        data.usdBalance = uint128(estimateInBUSD(WMX_WOM_TOKEN, data.underlyingBalance, uint8(18)));
    }

    function getUserLocker(
        address _locker,
        address _user
    ) public returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserLockerPendingRewards(_locker, _user);
        (uint256 balance, , , ) = IWmxLocker(_locker).lockedBalances(_user);
        data = RewardContractData(_locker, uint128(balance), uint128(balance), uint128(0), uint8(18), rewards);
        data.usdBalance = uint128(estimateInBUSD(WMX_TOKEN, data.underlyingBalance, uint8(18)));
    }

    function getUserBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public returns(RewardContractData[] memory rewardContractData) {
        uint256 len = _poolIds.length;
        rewardContractData = new RewardContractData[](len);
        uint256 mintRatio = _booster.mintRatio();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(_poolIds[i]);

            // 1. Earned rewards
            RewardItem[] memory rewardTokens = getUserPendingRewards(
                getPoolMintRatio(_booster, _poolIds[i], mintRatio),
                poolInfo.crvRewards,
                _user
            );

            // 2. LP token balance
            uint256 lpTokenBalance = ERC20(poolInfo.crvRewards).balanceOf(_user);

            // 3. Underlying balance
            address womPool = IWomAsset(poolInfo.lptoken).pool();
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();

            rewardContractData[i] = RewardContractData(poolInfo.crvRewards, uint128(lpTokenBalance), uint128(0), uint128(0), getTokenDecimals(underlyingToken), rewardTokens);

            try IWomPool(womPool).quotePotentialWithdraw(underlyingToken, lpTokenBalance) returns (uint256 underlyingBalance) {
                rewardContractData[i].underlyingBalance = uint128(underlyingBalance);

                // 4. Usd outs
                if (isUsdStableToken[underlyingToken]) {
                    uint8 decimals = getTokenDecimals(underlyingToken);
                    underlyingBalance *= 10 ** (18 - decimals);
                    rewardContractData[i].usdBalance = uint128(underlyingBalance);
                } else {
                    rewardContractData[i].usdBalance = uint128(getLpUsdOut(womPool, underlyingToken, lpTokenBalance));
                }
            } catch {}
        }
    }

    function getPoolMintRatio(IBooster _booster, uint256 pid, uint256 defaultMintRatio) public view returns (uint256 resMintRatio) {
        resMintRatio = defaultMintRatio;
        try _booster.customMintRatio(pid) returns (uint256 _customMintRatio) {
            resMintRatio = _customMintRatio == 0 ? defaultMintRatio : _customMintRatio;
        } catch {
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8 decimals) {
        try ERC20(_token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
        } catch {
            decimals = uint8(18);
        }
    }

    function getUserPendingRewards(uint256 _mintRatio, address _rewardsPool, address _user) public
        returns (RewardItem[] memory rewards)
    {
        (address[] memory rewardTokens, uint256[] memory earnedRewards) = IBaseRewardPool4626(_rewardsPool)
            .claimableRewards(_user);

        uint256 len = rewardTokens.length;
        rewards = new RewardItem[](len + 1);
        uint256 earnedWom;
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            IBaseRewardPool4626.RewardState memory tokenRewards = IBaseRewardPool4626(_rewardsPool).tokenRewards(rewardTokens[i]);
            if (earnedRewards[i] == 0 && tokenRewards.periodFinish < block.timestamp) {
                continue;
            }
            if (rewardTokens[i] == WOM_TOKEN) {
                earnedWom = earnedRewards[i];
            }
            uint8 decimals = getTokenDecimals(rewardTokens[i]);
            rewards[i] = RewardItem(
                rewardTokens[i],
                uint128(earnedRewards[i]),
                uint128(estimateInBUSDEther(rewardTokens[i], earnedRewards[i], decimals)),
                decimals
            );
        }
        if (earnedWom > 0) {
            uint256 earned = ITokenMinter(WMX_MINTER).getFactAmounMint(earnedWom);
            earned = _mintRatio > 0 ? earned * _mintRatio / 10000 : earned;
            rewards[len] = RewardItem(WMX_TOKEN, uint128(earned), uint128(estimateInBUSD(WMX_TOKEN, earned, uint8(18))), uint8(18));
        }
    }

    function getUserLockerPendingRewards(address _locker, address _user) public
        returns (RewardItem[] memory rewards)
    {
        IWmxLocker.EarnedData[] memory userRewards = IWmxLocker(_locker).claimableRewards(_user);

        rewards = new RewardItem[](userRewards.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            uint8 decimals = getTokenDecimals(userRewards[i].token);
            rewards[i] = RewardItem(
                userRewards[i].token,
                uint128(userRewards[i].amount),
                uint128(estimateInBUSDEther(userRewards[i].token, userRewards[i].amount, decimals)),
                decimals
            );
        }
    }
}
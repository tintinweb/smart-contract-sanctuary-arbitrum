// SPDX-License-Identifier: MIT

/*
    Discord...Ho Ho Hooo🎅🏻-> https://discord.gg/tBW2tHYPjn
    Telegram… Ho Ho Hooo🎅🏻 -> https://t.me/+n8zSDItufNwxNWQ0
    Twitter...Ho Ho Hooo🎅🏻 -> https://twitter.com/SantaClausSG
*/

interface ISushiswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface ISushiswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Xmas is ERC20, Ownable {
    // maxSupply is overrided for people who wants to verify it, we know that we should have pass _maxSupply above 1_000_000_000 ethers
    uint256 maxSupply = 1_000_000_000 ether;
    uint256 maxWalletSize = 30_000_000 ether;

    // minimum of tokens to hold for airdrop
    uint256 minToHold = 10_000_000 ether;

    // wallets involved
    address public teamWallet =
        address(0xFC7d8F3b912cFf8269e7370443408B14c19d365c);
    address public treasuryWallet =
        address(0xf695AF3B0b881d8Ea0BA305d70eF5691Fb7e99C6);
    address public marketingWallet =
        address(0x4c170692301e783c545450123533d34BD8111287);
    address public giveawaysWallet =
        address(0xD636120691198BF562380a87FcD777f74AAC2887);

    address deadWallet = address(0x0000000000000000000000000000000000000000);

    // Sushi address
    address public sushiswapV2Pair;
    address public sushiRouter =
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    ISushiswapV2Router02 public sushiswapV2Router;

    // Sushi swap address
    address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    // number of days for this event
    uint8 daysOfEvent = 25;
    uint256 minHolderToClaim = 20;

    // days to manage the event
    uint32 public startDay = 1669852800;
    uint32 public currentDay = 1669852800;

    uint32 public countActiveUsers = 0;
    uint256 public holders = 0;

    struct AirdropInformation {
        address owner;
        bool active;
        uint8 numberOfDays;
        uint32 lastClaim;
    }

    // mappings
    mapping(address => mapping(uint256 => bool)) activeDays;
    mapping(address => AirdropInformation) usersActivity;
    mapping(uint32 => address) allAddress;
    mapping(address => mapping(uint256 => bool)) hasClaimed;

    // fees
    uint256 public buyFees = 5;
    uint256 public sellFees = 5;

    // airdrop rate
    uint8 public airdropRate = 1;

    constructor() ERC20("XMAS", "XMAS") {
        ISushiswapV2Router02 _sushiswapV2Router = ISushiswapV2Router02(
            sushiRouter
        );
        sushiswapV2Pair = ISushiswapV2Factory(_sushiswapV2Router.factory())
            .createPair(address(this), WETH);
        IERC20(sushiswapV2Pair).approve(sushiRouter, maxSupply);
        _mint(msg.sender, 750_000_000 ether);
        _mint(giveawaysWallet, 150_000_000 ether);
        _mint(treasuryWallet, 100_000_000 ether);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 tokensCollected;
        uint256 amountWithFee;
        uint256 toTeam;
        uint256 toTreasury;
        uint256 toMarketing;
        uint256 toGiveaways;
        // on sell
        if (to == sushiswapV2Pair) {
            tokensCollected = (amount / 100) * sellFees;
            amountWithFee = amount - tokensCollected;

            toTeam = (tokensCollected / 100) * 30;
            toTreasury = (tokensCollected / 100) * 25;
            toMarketing = (tokensCollected / 100) * 15;
            toGiveaways = (tokensCollected / 100) * 30;

            super._transfer(from, to, amountWithFee);
            super._transfer(from, teamWallet, toTeam);
            super._transfer(from, treasuryWallet, toTreasury);
            super._transfer(from, marketingWallet, toMarketing);
            super._transfer(from, giveawaysWallet, toGiveaways);
        }
        // on buy
        else if (from == sushiswapV2Pair) {
            if (_holdMoreThanMaxWalletSize(to, amount))
                revert("Swap: you cannot swap more than 1% of the LP");
            tokensCollected = (amount / 100) * buyFees;
            amountWithFee = amount - tokensCollected;

            toTeam = (tokensCollected / 100) * 30;
            toTreasury = (tokensCollected / 100) * 25;
            toMarketing = (tokensCollected / 100) * 15;
            toGiveaways = (tokensCollected / 100) * 30;

            super._transfer(from, to, amountWithFee);
            super._transfer(from, teamWallet, toTeam);
            super._transfer(from, treasuryWallet, toTreasury);
            super._transfer(from, marketingWallet, toMarketing);
            super._transfer(from, giveawaysWallet, toGiveaways);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _beforeSwap(address _owner, uint256 _amount)
        internal
        view
        returns (bool)
    {
        uint256 tokenHoldByOwner = balanceOf(_owner);
        uint256 tokenPercentage = (tokenHoldByOwner + _amount / maxSupply) *
            100; // To modify => 75% would be passed to LP so it would not be totalSupply but 75% of the total supply
        return tokenPercentage < 1;
    }

    function setFees(uint256 _buyFees, uint256 _sellFees) external onlyOwner {
        require(
            _buyFees + _sellFees <= 14,
            "Fees: cannot set fees more than 14%"
        );
        buyFees = _buyFees;
        sellFees = _sellFees;
    }

    function increaseAirdropRate() external onlyOwner {
        if (airdropRate > 24)
            revert("Increase: failed to increase rate of airdrop");
        airdropRate += 1;
    }

    function changeMinToHold(uint32 _minToHold) external onlyOwner {
        minToHold = _minToHold;
    }

    function claimToken() external {
        require(
            balanceOf(msg.sender) >= minToHold,
            "You cannot claim your Xmas Tokens"
        );
        require(
            minHolderToClaim >= getTotalActiveUserOfTheDay(),
            "Need minimun holders"
        );
        if (
            activeDays[msg.sender][currentDay] &&
            !hasClaimed[msg.sender][currentDay]
        ) {
            uint256 balanceOfThis = balanceOf(address(this));
            uint256 toReceive = (balanceOfThis / getTotalActiveUserOfTheDay());
            super._transfer(address(this), msg.sender, toReceive);
            hasClaimed[msg.sender][currentDay] = true;
        } else {
            revert("you can't claim more than once per day");
        }
    }

    function setMinHolderToClaim(uint16 minHolder) external onlyOwner {
        minHolderToClaim = minHolder;
    }

    function getTotalActiveUserOfTheDay() public view returns (uint16) {
        uint32 activeUsers = countActiveUsers;
        uint16 counter = 0;
        for (uint16 i = 0; i < activeUsers; i++) {
            if (usersActivity[allAddress[i]].active) {
                counter += 1;
            }
        }
        return counter;
    }

    function getAddressesOfActiveMembersOfTheDay()
        public
        view
        returns (address[] memory)
    {
        uint16 activeUsers = getTotalActiveUserOfTheDay();
        uint16 counter = 0;
        address[] memory walletsOfTheDay = new address[](activeUsers);

        for (uint32 i = 0; i < countActiveUsers; i++) {
            if (usersActivity[allAddress[i]].active) {
                walletsOfTheDay[counter] = usersActivity[allAddress[i]].owner;
                counter++;
            }
        }
        return walletsOfTheDay;
    }

    function _holdMoreThanMaxWalletSize(address _user, uint256 _amount)
        internal
        view
        returns (bool)
    {
        return balanceOf(_user) + _amount >= maxWalletSize;
    }

    function changeMaxWalletSize(uint256 _maxWalletSize) external onlyOwner {
        maxWalletSize = _maxWalletSize;
    }

    function countActiveDaysOf(address _user) public view returns (uint8) {
        return usersActivity[_user].numberOfDays;
    }

    function imActive() external {
        require(
            balanceOf(msg.sender) > minToHold,
            "You need to hold more Xmas token on your wallet"
        );
        AirdropInformation storage airdropInformation = usersActivity[
            msg.sender
        ];
        if (usersActivity[msg.sender].owner == deadWallet) {
            allAddress[countActiveUsers] = msg.sender;
            countActiveUsers += 1;
            airdropInformation.owner = msg.sender;
            airdropInformation.active = true;
        }
        if (!activeDays[msg.sender][currentDay]) {
            airdropInformation.numberOfDays += 1;
            activeDays[msg.sender][currentDay] = true;
            hasClaimed[msg.sender][currentDay] = false;
        }
        if (oneDayElapsed()) nextDay();
    }

    function getAirdropInformation()
        external
        view
        returns (AirdropInformation memory)
    {
        return usersActivity[msg.sender];
    }

    function getActiveUser(address _user) public view returns (bool) {
        return activeDays[_user][currentDay];
    }

    function getHasClaimed(address _user) public view returns (bool) {
        return hasClaimed[_user][currentDay];
    }

    function userExist() external view returns (bool) {
        return usersActivity[msg.sender].owner != deadWallet;
    }

    function oneDayElapsed() internal view returns (bool) {
        return block.timestamp > 1 days + currentDay;
    }

    function isOneDayElapsed() external view returns (bool) {
        return oneDayElapsed();
    }

    function nextDay() public onlyOwner {
        currentDay += 1 days;
    }

    function withdraw(address _token) external onlyOwner {
        IERC20 contractToken = IERC20(_token);
        uint256 balanceOfToken = contractToken.balanceOf(address(this));

        contractToken.transferFrom(address(this), msg.sender, balanceOfToken);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
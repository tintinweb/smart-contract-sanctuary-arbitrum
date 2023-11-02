/**
 *Submitted for verification at Arbiscan.io on 2023-11-01
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: contracts/EquivalenceTokenV2.sol


pragma solidity ^0.8.21;



// following code comes from import "@openzeppelin/contracts/access/Ownable.sol"; (version from February 22, 2023)
// original comments are removed and where possible code is made more compact, any changes except visual ones are commented

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    modifier onlyOwner() {_checkOwner(); _;}
    function owner() public view virtual returns (address) {return _owner;}
    function _checkOwner() internal view virtual {require(owner() == _msgSender(), "Ownable: caller is not the owner");}
// added bool confirm to avoid theoretical chance of renouncing ownership by mistake or accident
    function renounceOwnership(bool confirm) public virtual onlyOwner {require(confirm, "Not confirmed"); _transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}
}

// interface to get the data from PriceOracle (another smart-contract providing price data)
interface EQTpriceOracle {
    function getEQTprice() external view returns (uint256);
    function getEQTprice_Token1() external view returns (uint256);
    function getEQTprice_Token2() external view returns (uint256);
    function getEQTprice_Token3() external view returns (uint256);
    function getEQTprice_Token4() external view returns (uint256);
    }




//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract EquivalenceProtocolV2 is ERC20, Ownable {

    mapping(address => bool) public whitelist;
    mapping(address => uint256) internal rewardBalances;
    mapping(address => uint256) internal rewardTimestamps;
    IERC20 internal WrappedNativeToken = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 internal Token1 = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20 internal Token2 = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20 internal Token3 = IERC20(0x561877b6b3DD7651313794e5F2894B2F18bE0766);
    IERC20 internal Token4 = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20Metadata public NativeMetadata = IERC20Metadata(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20Metadata public Metadata1 = IERC20Metadata(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20Metadata public Metadata2 = IERC20Metadata(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20Metadata public Metadata3 = IERC20Metadata(0x561877b6b3DD7651313794e5F2894B2F18bE0766);
    IERC20Metadata public Metadata4 = IERC20Metadata(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    address public PaymentSplitter;
    bool public PartnershipEnabled = false;
    bool public Token1isUSD = true;
    bool public Token2isUSD = true;
    bool public Token3isUSD = false;
    bool public Token4isUSD = false;
    bool public Token1isEUR = false;
    bool public Token2isEUR = false;
    bool public Token3isEUR = false;
    bool public Token4isEUR = false;
    bool public Token1isETH = false;
    bool public Token2isETH = false;
    bool public Token3isETH = false;
    bool public Token4isETH = false;
    bool public Token1isBTC = false;
    bool public Token2isBTC = false;
    bool public Token3isBTC = false;
    bool public Token4isBTC = true;
    uint256 internal constant IntendedSupply = 10 ** 26;
    uint256 internal constant MaxSupply = 10 ** 27;
    address public LiquidityPoolWallet = 0x79C08ce94676106f3a11c561D893F9fb26dd007C;
    address private TeamWallet;
    EQTpriceOracle public PriceOracle;
    uint256 public mintMode = 3;
    uint256 public whitelistUsageCounter;
    bool public BlockSpecialFunctionOnPoolSetup = true;
    error Minting_paused();
    error Incorrect_PaymentToken();
    error Minting_above_intended_supply();
    error Minting_above_maximal_supply();
    error Not_whitelisted();
    error Already_registered();
    error Supply_above_intended();
    error Not_registered();
    error Ivalid_timestamp();
    error Temporarily_Blocked();
    error Amount_Too_Low();

    constructor() ERC20("Equivalence Token V2", "EQT") {_mint(msg.sender, 85 * 10 ** 24);}

    function addToWhitelist(address _address) external onlyOwner {whitelist[_address] = true; whitelistUsageCounter++;}
    function removeFromWhitelist(address _address) external onlyOwner {delete whitelist[_address];}
    function setOracleAddress(EQTpriceOracle _addr) external onlyOwner {PriceOracle = _addr;}
    function setTeamWallet(address _address) external onlyOwner {TeamWallet = _address;}
    function setBlock(bool blockOnSetup) external onlyOwner {BlockSpecialFunctionOnPoolSetup = blockOnSetup;}
    function setPartnership(bool enabled) external onlyOwner {PartnershipEnabled = enabled;}
    function setWrappedNativeToken(address _addr) external onlyOwner {WrappedNativeToken = IERC20(_addr); NativeMetadata = IERC20Metadata(_addr);}
    function setPaymentSplitter(address _addr) external onlyOwner {PaymentSplitter = _addr;}
    function setToken1(address _addr, bool USD, bool EUR, bool ETH, bool BTC) external onlyOwner {Token1 = IERC20(_addr); Metadata1 = IERC20Metadata(_addr); Token1isUSD = USD; Token1isEUR = EUR; Token1isETH = ETH; Token1isBTC = BTC;}
    function setToken2(address _addr, bool USD, bool EUR, bool ETH, bool BTC) external onlyOwner {Token2 = IERC20(_addr); Metadata2 = IERC20Metadata(_addr); Token2isUSD = USD; Token2isEUR = EUR; Token2isETH = ETH; Token2isBTC = BTC;}
    function setToken3(address _addr, bool USD, bool EUR, bool ETH, bool BTC) external onlyOwner {Token3 = IERC20(_addr); Metadata3 = IERC20Metadata(_addr); Token3isUSD = USD; Token3isEUR = EUR; Token3isETH = ETH; Token3isBTC = BTC;}
    function setToken4(address _addr, bool USD, bool EUR, bool ETH, bool BTC) external onlyOwner {Token4 = IERC20(_addr); Metadata4 = IERC20Metadata(_addr); Token4isUSD = USD; Token4isEUR = EUR; Token4isETH = ETH; Token4isBTC = BTC;}
    function withdraw () external onlyOwner {
        if (address(this).balance >= 1) {payable(msg.sender).transfer(address(this).balance);}
        if (balanceOf(address(this)) >= 1) {_transfer(address(this), msg.sender, balanceOf(address(this)));}
    }
    function withdrawERC20 (IERC20 token) external onlyOwner {if (token.balanceOf(address(this)) >= 1) {token.transfer(msg.sender, token.balanceOf(address(this)));}}

// mintMode: 0 = minting fully available, 1 = minting only with the native tokens of the blockchain, 2 = minting only with ERC-20 tokens, 3+ minting paused
    function setMintMode(uint256 _mintMode) external onlyOwner {mintMode = _mintMode;}

// calculation of "Liquidity"can't underflow because "ProjectAndTeam" is 40x less than msg.value
    function mint() external payable {
        if (mintMode >= 2) {revert Minting_paused();}
        uint256 decimals = NativeMetadata.decimals();
        uint256 ProjectAndTeam;
        uint256 Liquidity;
        uint256 TokensToMint;
        if (decimals >= 36){TokensToMint = (msg.value / (10**(decimals-36))) / PriceOracle.getEQTprice();}
        else {TokensToMint = ((10**(36-decimals)) * msg.value) / PriceOracle.getEQTprice();}
        if (IntendedSupply < TokensToMint + totalSupply()) {revert Minting_above_intended_supply();}
        if(PartnershipEnabled) { unchecked {
            uint256 Partners = msg.value / 50;                      // 2% to our partners
            ProjectAndTeam = msg.value / 66;                        // 2x 1.5% to the project and team wallets
            Liquidity = msg.value - Partners - (2*ProjectAndTeam);  // 95% to the liquidity wallet
            payable(PaymentSplitter).transfer(Partners);
            }}
        else { unchecked {
            ProjectAndTeam = msg.value / 40;                        // 2x 2.5% to the project and team wallets
            Liquidity = msg.value - (2*ProjectAndTeam);             // 95% to the liquidity wallet
            }}
        payable(owner()).transfer(ProjectAndTeam);
        payable(TeamWallet).transfer(ProjectAndTeam);
        payable(LiquidityPoolWallet).transfer(Liquidity);
        _mint(msg.sender, TokensToMint);
        updateRewards(msg.sender);
    }

// calculation of "Liquidity" and "ProjectAndTeam" can't overflow or underflow because both are less than "MintTotal"
    function mintWithERC20(uint256 TokensToMint, uint256 PaymentToken) external {
        if (mintMode == 1 || mintMode >= 3) {revert Minting_paused();}
        if (IntendedSupply < TokensToMint + totalSupply()) {revert Minting_above_intended_supply();}
        if (PaymentToken == 0 || PaymentToken >= 5) {revert Incorrect_PaymentToken();}
        uint256 Liquidity;
        uint256 MintTotal;
        uint256 ProjectAndTeam;
        if (PaymentToken == 1) {
            if (Metadata1.decimals() >= 36){MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token1()) * (10 ** (Metadata1.decimals() - 36));}
            else {MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token1()) / (10 ** (36-Metadata1.decimals()));}
            if (MintTotal <= 66) {revert Amount_Too_Low();}
            if(PartnershipEnabled) { unchecked {
                uint256 Partners = MintTotal / 50;                          // 2% to our partners
                ProjectAndTeam = MintTotal / 66;                            // 2x 1.5% to the project and team wallets
                Liquidity = MintTotal - Partners - (2*ProjectAndTeam);      // 95% to the liquidity wallet
                Token1.transferFrom(msg.sender, PaymentSplitter, Partners);
            }}
            else { unchecked {
                ProjectAndTeam = MintTotal / 40;                            // 2x 2.5% to the project and team wallets
                Liquidity = MintTotal - (2*ProjectAndTeam);                 // 95% to the liquidity wallet
            }}
            Token1.transferFrom(msg.sender, owner(), ProjectAndTeam);
            Token1.transferFrom(msg.sender, TeamWallet, ProjectAndTeam);
            Token1.transferFrom(msg.sender, LiquidityPoolWallet, Liquidity);
            } else {
        if (PaymentToken == 2) {
            if (Metadata2.decimals() >= 36){MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token2()) * (10 ** (Metadata2.decimals() - 36));}
            else {MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token2()) / (10 ** (36-Metadata2.decimals()));}
            if (MintTotal <= 66) {revert Amount_Too_Low();}
            if(PartnershipEnabled) { unchecked {
                uint256 Partners = MintTotal / 50;                          // 2% to our partners
                ProjectAndTeam = MintTotal / 66;                            // 2x 1.5% to the project and team wallets
                Liquidity = MintTotal - Partners - (2*ProjectAndTeam);      // 95% to the liquidity wallet
                Token2.transferFrom(msg.sender, PaymentSplitter, Partners);
            }}
            else { unchecked {
                ProjectAndTeam = MintTotal / 40;                            // 2x 2.5% to the project and team wallets
                Liquidity = MintTotal - (2*ProjectAndTeam);                 // 95% to the liquidity wallet
            }}
            Token2.transferFrom(msg.sender, owner(), ProjectAndTeam);
            Token2.transferFrom(msg.sender, TeamWallet, ProjectAndTeam);
            Token2.transferFrom(msg.sender, LiquidityPoolWallet, Liquidity);
            } else {
        if (PaymentToken == 3) {
            if (Metadata3.decimals() >= 36){MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token3()) * (10 ** (Metadata3.decimals() - 36));}
            else {MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token3()) / (10 ** (36-Metadata3.decimals()));}
            if (MintTotal <= 66) {revert Amount_Too_Low();}
            if(PartnershipEnabled) { unchecked {
                uint256 Partners = MintTotal / 50;                          // 2% to our partners
                ProjectAndTeam = MintTotal / 66;                            // 2x 1.5% to the project and team wallets
                Liquidity = MintTotal - Partners - (2*ProjectAndTeam);      // 95% to the liquidity wallet
                Token3.transferFrom(msg.sender, PaymentSplitter, Partners);
            }}
            else { unchecked {
                ProjectAndTeam = MintTotal / 40;                            // 2x 2.5% to the project and team wallets
                Liquidity = MintTotal - (2*ProjectAndTeam);                 // 95% to the liquidity wallet
            }}
            Token3.transferFrom(msg.sender, owner(), ProjectAndTeam);
            Token3.transferFrom(msg.sender, TeamWallet, ProjectAndTeam);
            Token3.transferFrom(msg.sender, LiquidityPoolWallet, Liquidity);
            } else {
            if (Metadata4.decimals() >= 36){MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token4()) * (10 ** (Metadata4.decimals() - 36));}
            else {MintTotal = (TokensToMint * PriceOracle.getEQTprice_Token4()) / (10 ** (36-Metadata4.decimals()));}
            if (MintTotal <= 66) {revert Amount_Too_Low();}
            if(PartnershipEnabled) { unchecked {
                uint256 Partners = MintTotal / 50;                          // 2% to our partners
                ProjectAndTeam = MintTotal / 66;                            // 2x 1.5% to the project and team wallets
                Liquidity = MintTotal - Partners - (2*ProjectAndTeam);      // 95% to the liquidity wallet
                Token4.transferFrom(msg.sender, PaymentSplitter, Partners);
            }}
            else { unchecked {
                ProjectAndTeam = MintTotal / 40;                            // 2x 2.5% to the project and team wallets
                Liquidity = MintTotal - (2*ProjectAndTeam);                 // 95% to the liquidity wallet
            }}
            Token4.transferFrom(msg.sender, owner(), ProjectAndTeam);
            Token4.transferFrom(msg.sender, TeamWallet, ProjectAndTeam);
            Token4.transferFrom(msg.sender, LiquidityPoolWallet, Liquidity);
            }}
        }
        _mint(msg.sender, TokensToMint);
        updateRewards(msg.sender);
    }

// calculation can be unchecked, "amount" can't be more than "MaxSupply", which mean "totalSupply() + amount" can't overflow and "amount * (totalSupply() - IntendedSupply)" also can't overflow
    function externalMint(address _addr, uint256 amount) external {
        if(BlockSpecialFunctionOnPoolSetup) {revert Temporarily_Blocked();}
        if(whitelist[msg.sender]) {} else {revert Not_whitelisted();}
        unchecked {
            if (amount >= MaxSupply || totalSupply() + amount >= MaxSupply) {revert Minting_above_maximal_supply();}
            if (totalSupply() > IntendedSupply) {amount = amount - (amount * (totalSupply() - IntendedSupply) / ((99*IntendedSupply)-(9*totalSupply())));}
            }
        _mint(_addr, amount);
        updateRewards(_addr);
    }
    function burnFrom(address account, uint256 amount) external {
        if(BlockSpecialFunctionOnPoolSetup) {revert Temporarily_Blocked();}
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
        updateRewards(account);
    }
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        updateRewards(msg.sender);
    }
    function registerForRewards() external {
        if (rewardTimestamps[msg.sender] != 0) {revert Already_registered();}
        rewardBalances[msg.sender] = balanceOf(msg.sender);
        rewardTimestamps[msg.sender] = block.timestamp;
    }
    function updateRewardsManually() external {
        if (totalSupply() >= IntendedSupply) {revert Supply_above_intended();}
        if (rewardTimestamps[msg.sender] == 0) {revert Not_registered();}
        updateRewards(msg.sender);
    }

// (block.timestamp - rewardTimestamps[_addr]) is time interval in seconds, 31557600 is number of seconds per year (365.25 days), together it makes time multiplier
// 10**16 comes from ((IntendedSupply / 10 ** 18) ** 2), since the result is a constant, I've put there the result directly to save gas
// (10**16 - ((totalSupply() / 10 ** 18) ** 2))) / (665 * 10 ** 14) is calculation of reward per year multiplier, for totalSupply() = 0 it is 0.15037594
// calculation can be unchecked, reasons:
// totalSupply() < IntendedSupply and block.timestamp > rewardTimestamps[], this prevent underflow
// rewardBalances[] can't be more than MaxSupply (10 ** 27), overflow within the first part of calculation "rewardBalances[_addr] * (block.timestamp - rewardTimestamps[])" would take about 3*10**42 years, so I consider it impossible
// Multiplication in second part can increase the number by at most 10**16, in total: 10 ** 27 * 10**16 = 10**43, so there is still 10**34 years till overflow, which is less than in previous calculation, but still most likely past the end of our universe... I consider that also impossible
    function updateRewards(address _addr) internal {if (rewardTimestamps[_addr] >= 1) {
        if(totalSupply() < IntendedSupply){
            if (block.timestamp <= rewardTimestamps[_addr]) {revert Ivalid_timestamp();}
            unchecked {_mint(_addr, ((((rewardBalances[_addr] * (block.timestamp - rewardTimestamps[_addr])) / 31557600) * (10**16 - ((totalSupply() / 10 ** 18) ** 2))) / (665 * 10 ** 14)));}
            rewardBalances[_addr] = balanceOf(_addr);
            rewardTimestamps[_addr] = block.timestamp;
        } else {
            rewardBalances[_addr] = balanceOf(_addr);
            rewardTimestamps[_addr] = block.timestamp;
        }
    }}
    function pauseRewards() external {
        if (rewardTimestamps[msg.sender] == 0) {revert Not_registered();}
        if ((totalSupply() < IntendedSupply) && (rewardBalances[msg.sender] >= 1)) {
            if (block.timestamp <= rewardTimestamps[msg.sender]) {revert Ivalid_timestamp();}
            unchecked {_mint(msg.sender, ((((rewardBalances[msg.sender] * (block.timestamp - rewardTimestamps[msg.sender])) / 31557600) * (10**16 - ((totalSupply() / 10 ** 18) ** 2))) / (665 * 10 ** 14)));}
            }
        rewardTimestamps[msg.sender] = 0;
        rewardBalances[msg.sender] = 0;
    }

// overrides to include the update of rewards
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        updateRewards(msg.sender);
        updateRewards(to);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        updateRewards(from);
        updateRewards(to);
        return true;
    }

// view only functions
    function NativeTokenName() external view returns (string memory) {return NativeMetadata.name();}
    function Token1Name() external view returns (string memory) {return Metadata1.name();}
    function Token2Name() external view returns (string memory) {return Metadata2.name();}
    function Token3Name() external view returns (string memory) {return Metadata3.name();}
    function Token4Name() external view returns (string memory) {return Metadata4.name();}
    function EQTprice() external view returns (uint256 price, uint8 tokenDecimals) {return (PriceOracle.getEQTprice(), NativeMetadata.decimals());}
    function EQTprice_Token1() external view returns (uint256 price, uint8 tokenDecimals) {return (PriceOracle.getEQTprice_Token1(), Metadata1.decimals());}
    function EQTprice_Token2() external view returns (uint256 price, uint8 tokenDecimals) {return (PriceOracle.getEQTprice_Token2(), Metadata2.decimals());}
    function EQTprice_Token3() external view returns (uint256 price, uint8 tokenDecimals) {return (PriceOracle.getEQTprice_Token3(), Metadata3.decimals());}
    function EQTprice_Token4() external view returns (uint256 price, uint8 tokenDecimals) {return (PriceOracle.getEQTprice_Token4(), Metadata4.decimals());}
}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libs/Logarithm.sol";
import "./libs/TransferHelper.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IInitialFairOffering.sol";
import "./interfaces/IInscription.sol";
import "./interfaces/ICustomizedCondition.sol";
import "./interfaces/ICustomizedVesting.sol";

// This is common token interface, get balance of owner's token by ERC20/ERC721/ERC1155.
interface ICommonToken {
    function balanceOf(address owner) external returns(uint256);
}

// This contract is extended from ERC20
contract Inscription is ERC20 {
    using Logarithm for int256;

    IInscription.FERC20 private ferc20;

    mapping(address => uint256) private lastMintTimestamp;   // record the last mint timestamp of account
    mapping(address => uint256) private lastMintFee;           // record the last mint fee

    uint96 public totalRollups;
    event Mint(address sender, address to, uint amount, bool isVesting);
    event Burn(address sender, address to, uint amount);

    constructor(
        string memory   _name,            // token name
        string memory   _tick,            // token tick, same as symbol. must be 4 characters.
        uint128         _cap,                   // Max amount
        uint128         _limitPerMint,          // Limitaion of each mint
        uint64          _inscriptionId,         // Inscription Id
        uint32          _maxMintSize,           // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint. This is only availabe for non-frozen time token.
        uint40          _freezeTime,            // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
        address         _onlyContractAddress,   // Only addresses that hold these assets can mint
        uint128         _onlyMinQuantity,       // Only addresses that the quantity of assets hold more than this amount can mint
        uint96         _baseFee,               // base fee of the second mint after frozen interval. The first mint after frozen time is free.
        uint16          _fundingCommission,     // commission rate of fund raising, 100 means 1%
        uint128         _crowdFundingRate,      // rate of crowdfunding
        address         _whitelist,              // whitelist contract
        bool            _isIFOMode,              // receiving fee of crowdfunding
        uint16          _liquidityTokenPercent,
        address payable _ifoContractAddress,
        address payable _inscriptionFactory,
        uint96          _maxRollups,
        address         _customizedConditionContractAddress,
        address         _customizedVestingContractAddress
    ) ERC20(_name, _tick) {
        require(_cap >= _limitPerMint, "Limit per mint exceed cap");
        ferc20.cap = _cap;
        ferc20.limitPerMint = _limitPerMint;
        ferc20.inscriptionId = _inscriptionId;
        ferc20.maxMintSize = _maxMintSize;
        ferc20.freezeTime = _freezeTime;
        ferc20.onlyContractAddress = _onlyContractAddress;
        ferc20.onlyMinQuantity = _onlyMinQuantity;
        ferc20.baseFee = _baseFee;
        ferc20.fundingCommission = _fundingCommission;
        ferc20.crowdFundingRate = _crowdFundingRate;
        ferc20.whitelist = _whitelist;
        ferc20.isIFOMode = _isIFOMode;
        ferc20.ifoContractAddress = _ifoContractAddress;
        ferc20.inscriptionFactory = _inscriptionFactory;
        ferc20.liquidityTokenPercent = _liquidityTokenPercent;
        ferc20.maxRollups = _maxRollups;
        ferc20.customizedConditionContractAddress = ICustomizedCondition(_customizedConditionContractAddress);
        ferc20.customizedVestingContractAddress = ICustomizedVesting(_customizedVestingContractAddress);
    }

    function mint(address _to) payable public {
        // Check if the quantity after mint will exceed the cap
        require(totalRollups + 1 <= ferc20.maxRollups, "Touched cap");
        // Check if the assets in the msg.sender is satisfied
        require(ferc20.onlyContractAddress == address(0x0) 
            || ICommonToken(ferc20.onlyContractAddress).balanceOf(msg.sender) >= ferc20.onlyMinQuantity, "You don't have required assets");
        require(ferc20.whitelist == address(0x0) 
            || IWhitelist(ferc20.whitelist).getStatus(address(this), msg.sender), "You are not in whitelist");
        require(address(ferc20.customizedConditionContractAddress) == address(0x0) 
            || ferc20.customizedConditionContractAddress.getStatus(address(this), msg.sender), "Customized condition not satisfied");
        require(lastMintTimestamp[msg.sender] < block.timestamp, "Timestamp fail"); // The only line added on V2
        
        uint256 tokenForInitialLiquidity = ferc20.isIFOMode ? ferc20.limitPerMint * ferc20.liquidityTokenPercent / (10000 - ferc20.liquidityTokenPercent) : 0;

        if(lastMintTimestamp[msg.sender] + ferc20.freezeTime > block.timestamp) {
            // The min extra tip is double of last mint fee
            lastMintFee[msg.sender] = lastMintFee[msg.sender] == 0 ? ferc20.baseFee : lastMintFee[msg.sender] * 2;
            // Check if the tip is high than the min extra fee
            require(msg.value >= ferc20.crowdFundingRate + lastMintFee[msg.sender], "Send ETH as fee and crowdfunding");
            // Transfer the fee to the crowdfunding address
            if(ferc20.crowdFundingRate > 0) _dispatchFunding(_to, ferc20.crowdFundingRate, ferc20.limitPerMint, tokenForInitialLiquidity);
            // Transfer the tip to InscriptionFactory smart contract
            if(msg.value - ferc20.crowdFundingRate > 0) TransferHelper.safeTransferETH(ferc20.inscriptionFactory, msg.value - ferc20.crowdFundingRate);
        } else {
            // Transfer the fee to the crowdfunding address
            if(ferc20.crowdFundingRate > 0) {
                require(msg.value >= ferc20.crowdFundingRate, "Send ETH as crowdfunding");
                if(msg.value - ferc20.crowdFundingRate > 0) TransferHelper.safeTransferETH(ferc20.inscriptionFactory, msg.value - ferc20.crowdFundingRate);
                _dispatchFunding(_to, ferc20.crowdFundingRate, ferc20.limitPerMint, tokenForInitialLiquidity);
            }
            // Out of frozen time, free mint. Reset the timestamp and mint times.
            lastMintFee[msg.sender] = 0;
            lastMintTimestamp[msg.sender] = block.timestamp;
        }

        // Do mint for the participant
        if(address(ferc20.customizedVestingContractAddress) == address(0x0)) {
            _mint(_to, ferc20.limitPerMint);
            emit Mint(msg.sender, _to, ferc20.limitPerMint, false);
        } else {
            _mint(address(ferc20.customizedVestingContractAddress), ferc20.limitPerMint);
            emit Mint(msg.sender, address(ferc20.customizedVestingContractAddress), ferc20.limitPerMint, true);
            ferc20.customizedVestingContractAddress.addAllocation(_to, ferc20.limitPerMint);
        }

        // Mint for initial liquidity
        if(tokenForInitialLiquidity > 0) _mint(ferc20.ifoContractAddress, tokenForInitialLiquidity);
        totalRollups++;
    }

    // batch mint is only available for non-frozen-time tokens
    function batchMint(address _to, uint32 _num) payable public {
        require(_num <= ferc20.maxMintSize, "exceed max mint size");
        require(totalRollups + _num <= ferc20.maxRollups, "Touch cap");
        require(ferc20.freezeTime == 0, "Batch mint only for non-frozen token");
        require(ferc20.onlyContractAddress == address(0x0) 
            || ICommonToken(ferc20.onlyContractAddress).balanceOf(msg.sender) >= ferc20.onlyMinQuantity, "You don't have required assets");
        require(ferc20.whitelist == address(0x0) 
            || IWhitelist(ferc20.whitelist).getStatus(address(this), msg.sender), "You are not in whitelist");
        require(address(ferc20.customizedConditionContractAddress) == address(0x0) 
            || ferc20.customizedConditionContractAddress.getStatus(address(this), msg.sender), "Customized condition not satisfied");

        uint256 tokenForInitialLiquidity = ferc20.isIFOMode ? ferc20.limitPerMint * ferc20.liquidityTokenPercent / (10000 - ferc20.liquidityTokenPercent) : 0;

        if(ferc20.crowdFundingRate > 0) {
            require(msg.value >= ferc20.crowdFundingRate * _num, "Crowdfunding ETH not enough");
            if(msg.value - ferc20.crowdFundingRate * _num > 0) TransferHelper.safeTransferETH(ferc20.inscriptionFactory, msg.value - ferc20.crowdFundingRate * _num);
            _dispatchFunding(_to, ferc20.crowdFundingRate * _num , ferc20.limitPerMint * _num, tokenForInitialLiquidity * _num);
        }
        
        for(uint256 i = 0; i < _num; i++) {
            // The reason for using for and repeat the operation is to let the average gas cost of batch mint same as single mint
            if(address(ferc20.customizedVestingContractAddress) == address(0x0)) {
                _mint(_to, ferc20.limitPerMint);
                emit Mint(msg.sender, _to, ferc20.limitPerMint, false);
            } else {
                _mint(address(ferc20.customizedVestingContractAddress), ferc20.limitPerMint);
                emit Mint(msg.sender, address(ferc20.customizedVestingContractAddress), ferc20.limitPerMint, true);
                ferc20.customizedVestingContractAddress.addAllocation(_to, ferc20.limitPerMint);
            }
            // Mint for initial liquidity
            if(tokenForInitialLiquidity > 0) {
                _mint(ferc20.ifoContractAddress, tokenForInitialLiquidity);
            }
        }
        totalRollups = totalRollups + _num;
    }

    function getMintFee(address _addr) public view returns(uint256 mintedTimes, uint256 nextMintFee) {
        if(lastMintTimestamp[_addr] + ferc20.freezeTime > block.timestamp) {
            int256 scale = 1e18;
            int256 halfScale = 5e17;
            // times = log_2(lastMintFee / baseFee) + 1 (if lastMintFee > 0)
            nextMintFee = lastMintFee[_addr] == 0 ? ferc20.baseFee : lastMintFee[_addr] * 2;
            mintedTimes = uint256((Logarithm.log2(int256(nextMintFee / ferc20.baseFee) * scale, scale, halfScale) + 1) / scale) + 1;
        }
    }

    function getFerc20Data() public view returns(IInscription.FERC20 memory) {
        return ferc20;
    }

    function getLastMintTimestamp(address _addr) public view returns(uint256) {
        return lastMintTimestamp[_addr];
    }

    function getLastMintFee(address _addr) public view returns(uint256) {
        return lastMintFee[_addr];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(!ferc20.isIFOMode || IInitialFairOffering(ferc20.ifoContractAddress).liquidityAdded(), 
            "Only workable after public liquidity added");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!ferc20.isIFOMode || IInitialFairOffering(ferc20.ifoContractAddress).liquidityAdded(), 
            "Only workable after public liquidity added");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(address account, uint256 amount) public {
        require(account == msg.sender, "only owner can burn");
        require(balanceOf(account) >= amount, "balance not enough");
        _burn(account, amount);
        emit Burn(msg.sender, account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance != type(uint256).max, "allowance exceed max");
        require(currentAllowance >= amount, "allowance less than amount");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
        emit Burn(msg.sender, account, amount);
    }

    function _dispatchFunding(address _to, uint256 _ethAmount, uint256 _tokenAmount, uint256 _tokenForLiquidity) private {
        require(ferc20.ifoContractAddress > address(0x0), "ifo address zero");

        uint256 commission = _ethAmount * ferc20.fundingCommission / 10000;
        TransferHelper.safeTransferETH(ferc20.ifoContractAddress, _ethAmount - commission); 
        if(commission > 0) TransferHelper.safeTransferETH(ferc20.inscriptionFactory, commission);

        IInitialFairOffering(ferc20.ifoContractAddress).setMintData(
            _to,
            uint128(_ethAmount - commission),
            uint128(_tokenAmount), 
            uint128(_tokenForLiquidity)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomizedCondition {
    function getStatus(address _tokenAddress, address _sender) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomizedVesting {
    function addAllocation(address recipient, uint amount) external;
    function removeAllocation(address recipient, uint amount) external;
    function claim() external;
    function available(address address_) external view returns (uint);
    function released(address address_) external view returns (uint);
    function outstanding(address address_) external view returns (uint);
    function setTokenAddress(address _tokenAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IInscriptionFactory.sol";

interface IInitialFairOffering {
    function initialize(IInscriptionFactory.Token memory _token) external;
    function setMintData(address _addr, uint128 _ethAmount, uint128 _tokenAmount, uint128 _tokenLiquidity) external;
    function liquidityAdded() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICustomizedCondition.sol";
import "./ICustomizedVesting.sol";

interface IInscription {
    struct FERC20 {
        uint128 cap;                                            // Max amount
        uint128 limitPerMint;                                   // Limitaion of each mint

        address onlyContractAddress;                            // Only addresses that hold these assets can mint
        uint32  maxMintSize;                                    // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64  inscriptionId;                                  // Inscription Id
        
        uint128 onlyMinQuantity;                                // Only addresses that the quantity of assets hold more than this amount can mint
        uint128 crowdFundingRate;                               // rate of crowdfunding

        address whitelist;                                      // whitelist contract
        uint40  freezeTime;                                     // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
        uint16  fundingCommission;                              // commission rate of fund raising, 1000 means 10%
        uint16  liquidityTokenPercent;
        bool    isIFOMode;                                      // receiving fee of crowdfunding

        address payable inscriptionFactory;                     // Inscription factory contract address
        uint128 baseFee;                                        // base fee of the second mint after frozen interval. The first mint after frozen time is free.

        address payable ifoContractAddress;                     // Initial fair offering contract
        uint96  maxRollups;                                     // Max rollups

        ICustomizedCondition customizedConditionContractAddress;// Customized condition for mint
        ICustomizedVesting customizedVestingContractAddress;    // Customized vesting contract
    }

    function mint(address _to) payable external;
    function getFerc20Data() external view returns(FERC20 memory);
    function balanceOf(address owner) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function totalRollups() external view returns(uint256);
    function burn(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInscriptionFactory {
    struct Token {
        uint128         cap;                                // Hard cap of token
        uint128         limitPerMint;                       // Limitation per mint

        address         onlyContractAddress;
        uint32          maxMintSize;                        // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64          inscriptionId;                      // Inscription id

        uint128         onlyMinQuantity;
        uint128         crowdFundingRate;
				
        address         addr;                               // Contract address of inscribed token
        uint40          freezeTime;
        uint40          timestamp;                          // Inscribe timestamp
        uint16          liquidityTokenPercent;              // 10000 is 100%

        address         ifoContractAddress;                 // Initial fair offerting contract
        uint16          refundFee;                          // To avoid the refund attack, deploy sets this fee rate
        uint40          startTime;
        uint40          duration;

        address         customizedConditionContractAddress; // Customized condition for mint
        uint96          maxRollups;                         // max rollups

        address         deployer;                           // Deployer
        string          tick;                               // same as symbol in ERC20, max 5 chars, 10 bytes(80)
        uint16          liquidityEtherPercent;
        
        string          name;                               // full name of token, max 16 chars, 32 bytes(256)

        address         customizedVestingContractAddress;   // Customized contract for token vesting
        bool            isIFOMode;                          // is ifo mode
        bool            isWhitelist;                        // is whitelst condition
        bool            isVesting;
        bool            isVoted;
        
        string          logoUrl;                            // logo url, ifpfs cid, 64 chars, 128 bytes, 4 slots, ex.QmPK1s3pNYLi9ERiq3BDxKa4XosgWwFRQUydHUtz4YgpqB
    }

    function deploy(
        string memory _name,
        string memory _tick,
        uint256 _cap,
        uint256 _limitPerMint,
        uint256 _maxMintSize, // The max lots of each mint
        uint256 _freezeTime, // Freeze seconds between two mint, during this freezing period, the mint fee will be increased
        address _onlyContractAddress, // Only the holder of this asset can mint, optional
        uint256 _onlyMinQuantity, // The min quantity of asset for mint, optional
        uint256 _crowdFundingRate,
        address _crowdFundingAddress
    ) external returns (address _inscriptionAddress);

    function updateStockTick(string memory _tick, bool _status) external;

    function transferOwnership(address newOwner) external;

    function getIncriptionIdByAddress(address _addr) external view returns(uint256);

    function getIncriptionByAddress(address _addr) external view returns(Token memory tokens, uint256 totalSupplies, uint256 totalRollups);

    function fundingCommission() external view returns(uint16);

    function isExisting(string memory _tick) external view returns(bool);

    function isLiquidityAdded(address _addr) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelist {
    function getStatus(address _tokenAddress, address _participant) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Logarithm {
    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) public pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x, int256 scale, int256 halfScale) public pure returns (int256 result) {
        require(x > 0);
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= scale) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = mostSignificantBit(uint256(x / scale));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * scale;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == scale) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(halfScale); delta > 0; delta >>= 1) {
                y = (y * y) / scale;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * scale) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
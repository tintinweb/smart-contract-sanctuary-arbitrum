/**
 *Submitted for verification at Arbiscan.io on 2023-09-29
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/IBasaSBT.sol

pragma solidity ^0.8.0;

interface IBasaSBT {
    event SBTCreated(address indexed sbtAddress, string name, string symbol);
    event WhitelistUpdated(address indexed user, bool added);
    event SBTPriceUpdated(address indexed sbtAddress, uint256 newPrice);
    event SBTMintEndTimeUpdated(address indexed sbtAddress, uint256 newEndTime);
    event SBTDiscountUpdated(address indexed sbtAddress, uint256 newDiscount);

    function createSBT(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        uint256 sbtPrice_,
        uint256 mintEndTime_,
        uint256 discount_
    ) external;

    function addBatchToWhitelist(address[] memory _addresses) external;

    function removeFromWhitelist(address _address) external;

    function isWhitelisted(address _address) external view returns (bool);

    function setSbtPrice(address _address, uint256 newSbtPrice) external;

    function setMintEndTime(address _address, uint256 newMintEndTime) external;

    function setDiscount(address _address, uint256 newDiscount) external;

    function getAllSBTContracts() external view returns (address[] memory);

    function getSBTInfoByIndex(uint256 index) external view returns (uint256 maxSupply, uint256 sbtPrice, uint256 mintEndTime, uint256 discount);

    function getSBTInfoByAddress(address sbtAddress) external view returns (uint256 maxSupply, uint256 sbtPrice, uint256 mintEndTime, uint256 discount);

    function getFee(address _address, uint256 fee) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

//  MIT
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


// File @openzeppelin/contracts/access/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/helpers/ERC20.sol

//  MIT

pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts1.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/helpers/ERC20Decimals.sol

//  UNLICENSED
pragma solidity ^0.8.0;

abstract contract ERC20Decimals is ERC20 {
    uint8 private immutable _decimals;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}


// File contracts/helpers/ERC20Ownable.sol

//  UNLICENSED
pragma solidity ^0.8.0;

abstract contract ERC20Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/helpers/TokenRecover.sol

//  UNLICENSED
pragma solidity ^0.8.0;

contract TokenRecover is ERC20Ownable {
    function recoverToken(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}


// File contracts/helpers/TokenHelper.sol

pragma solidity ^0.8.0;

contract TokenHelper {
    string public tokenName;

    constructor(string memory _tokenName) {
        tokenName = _tokenName;
    }

    function getTokenName() public view returns (string memory) {
        return tokenName;
    }
}


// File contracts/BaseToken/BaseToken_A.sol

//  UNLICENSED
pragma solidity ^0.8.0;





contract BaseToken_A is
    ERC20,
    ERC20Decimals,
    ERC20Ownable,
    TokenRecover,
    TokenHelper
{
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _cap
    )
        ERC20(_name, _symbol)
        ERC20Decimals(_decimals)
        TokenHelper("BaseToken_A"){
        ERC20._mint(_msgSender(), _cap);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }
}


// File contracts/BasaERC20Tool.sol

//  MIT
pragma solidity ^0.8.0;



contract BasaERC20Tool is Ownable {
    // Events
    event ERC20Created(address indexed tokenAddress, string name, string symbol);
    event Airdropped(address indexed tokenAddress, address[] recipients, uint256[] values);
    event AirdroppedWithClaim(address indexed tokenAddress, address[] recipients, uint256[] values);
    event Claimed(address indexed tokenAddress, address indexed user, uint256 amount);
    event CreateERC20FeeUpdated(uint256 newFee);
    event AirdropFeeUpdated(uint256 newFee);
    event ClaimFeeUpdated(address indexed tokenAddress, uint256 newFee);

    mapping(address => mapping(address => uint256)) public claimableBalances;
    mapping(address => uint256) public claimFees;
    uint256 public createERC20Fee;
    uint256 public airdropFee;
    IBasaSBT factory;

    constructor(
        address _factory,
        uint256 _createERC20Fee,
        uint256 _airdropFee
    ) {
        factory = IBasaSBT(_factory);
        createERC20Fee = _createERC20Fee;
        airdropFee = _airdropFee;
    }

    function toolCreateERC20(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _capOrInitial
    ) public payable returns (address) {
        uint256 fee = factory.getFee(msg.sender, createERC20Fee);
        if (fee > 0) {
            payable(owner()).transfer(fee);
        }
        if (msg.value - fee > 0) {
            payable(msg.sender).transfer(msg.value - fee);
        }

        IERC20 newToken;
        // if (tokenType == TokenType.BASETOKEN_A) {
            // newToken = new BaseToken_A(_name, _symbol, _decimals, _capOrInitial);
        // } else if (tokenType == TokenType.BASETOKEN_U_A) {
            newToken = new BaseToken_A(_name, _symbol, _decimals, _capOrInitial);
        // } else {
            // revert("Invalid token type");
        // }
        newToken.transfer(msg.sender, _capOrInitial);
        Ownable(address(newToken)).transferOwnership(msg.sender);

        // Emit event
        emit ERC20Created(address(newToken), _name, _symbol);

        return address(newToken);
    }

    function toolAirdrop(
        address _tokenAddress,
        address[] calldata _recipients,
        uint256[] calldata _values
    ) external payable {
        require(_recipients.length == _values.length, "Invalid input arrays");
        uint256 totalFee = airdropFee * _recipients.length;
        uint256 fee = factory.getFee(msg.sender, totalFee);
        if (fee > 0) {
            payable(owner()).transfer(fee);
        }
        if (msg.value - fee > 0) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        IERC20 token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transferFrom(msg.sender, _recipients[i], _values[i]), "Airdrop transfer failed");
        }

        // Emit event
        emit Airdropped(_tokenAddress, _recipients, _values);
    }

    function toolAirdropWithClaim(
        address _tokenAddress,
        address[] calldata _recipients,
        uint256[] calldata _values
    ) external payable {
        require(_recipients.length == _values.length, "Invalid input arrays");
        uint256 totalFee = airdropFee * _recipients.length;
        uint256 fee = factory.getFee(msg.sender, totalFee);
        if (fee > 0) {
            payable(owner()).transfer(fee);
        }
        if (msg.value - fee > 0) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        IERC20 token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(
                token.transferFrom(msg.sender, address(this), _values[i]),
                "Airdrop transfer failed"
            );
            claimableBalances[_tokenAddress][_recipients[i]] += _values[i];
        }

        // Emit event
        emit AirdroppedWithClaim(_tokenAddress, _recipients, _values);
    }

    function toolClaim(address _tokenAddress, uint256 _amount) external payable {
        uint256 claimableAmount = claimableBalances[_tokenAddress][msg.sender];
        require(claimableAmount >= _amount, "No claimable tokens");
        uint256 oneEther = 1 ether; 
        uint256 tokenClaimFee = claimFees[_tokenAddress] * _amount / oneEther; 
        if (tokenClaimFee > 0) {
            uint256 fee = factory.getFee(msg.sender, tokenClaimFee);
            if (fee > 0) {
                payable(owner()).transfer(fee);
            }
            if (msg.value - fee > 0) {
                payable(msg.sender).transfer(msg.value - fee);
            } 
        }
        IERC20 token = IERC20(_tokenAddress);
        require(
            token.transfer(msg.sender, _amount),
            "Claim transfer failed"
        );

        claimableBalances[_tokenAddress][msg.sender] = claimableAmount - _amount;

        // Emit event
        emit Claimed(_tokenAddress, msg.sender, _amount);
    }

    function setCreateERC20Fee(uint256 _fee) public onlyOwner {
        createERC20Fee = _fee;

        // Emit event
        emit CreateERC20FeeUpdated(_fee);
    }

    function setAirdropFee(uint256 _fee) public onlyOwner {
        airdropFee = _fee;

        // Emit event
        emit AirdropFeeUpdated(_fee);
    }

    function setClaimFee(address _tokenAddress, uint256 _fee) external onlyOwner {
        claimFees[_tokenAddress] = _fee;

        // Emit event
        emit ClaimFeeUpdated(_tokenAddress, _fee);
    }

    function getClaimFee(address _tokenAddress) external view returns (uint256) {
        return claimFees[_tokenAddress];
    }

    function getClaimableBalance(address _tokenAddress, address _user) external view returns (uint256) {
        return claimableBalances[_tokenAddress][_user];
    }
}
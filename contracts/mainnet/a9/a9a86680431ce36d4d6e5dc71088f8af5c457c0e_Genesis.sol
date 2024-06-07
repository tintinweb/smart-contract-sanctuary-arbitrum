/**
 *Submitted for verification at Arbiscan.io on 2024-06-07
*/

// Sources flattened with hardhat v2.22.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File libs/@openzeppelin/contracts/token/ERC20/IERC20.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File libs/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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


// File libs/@openzeppelin/contracts/utils/Context.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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


// File libs/@openzeppelin/contracts/utils/Pausable.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/Genesis.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;
uint256 constant MAX_VESTING = 25_000_000_000e18;
uint256 constant MAX_STOP_VESTING_PERIOD = 14 days;


interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}


contract Genesis is Context, IERC20, IERC20Metadata, IERC20Errors, Pausable{

    struct VestOptions{
        uint256 cliff_period;
        uint256 release_period;
    }

    uint256 private _totalSupply;
    uint256 private _vestedTokenCount;
    string private _name;
    string private _symbol;
    address private contractOwner;
    address private _sellerContract;
    
    mapping (uint8 => VestOptions) private vestOptions;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    mapping (address => uint256) private _unfrozenBalances;
    mapping (address => uint256) private _vestingNonces;
    mapping (address => mapping (uint256 => bool)) private _vestingStopped;
    mapping (address => mapping (uint256 => uint256)) private _vestingAmounts;
    mapping (address => mapping (uint256 => uint256)) private _unvestedAmounts;
    mapping (address => mapping (uint256 => uint256)) private _vestingTypes;
    mapping (address => mapping (uint256 => uint256)) private _vestingReleaseStartDates;
    mapping (address => mapping (uint256 => uint256)) private _vestingStartDate;
    mapping (address => mapping (uint256 => uint256)) private _vestingCliffPeriod;
    mapping (address => mapping (uint256 => uint256)) private _vestingReleasePeriod;
    
    event Unvest(address indexed user, uint amount);
    event NewSellerContract(address newSellerAddress);
    error AccessControlUnauthorizedAccount(address account);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlySeller() {
        _checkSeller();
        _;
    }

    constructor(
            address defaultAdmin,
            string memory tokenName,
            string memory tokenSymbol,
            uint256[] memory cliffPeriods, 
            uint256[] memory releasePeriods
        ) {
        contractOwner = defaultAdmin;
        _name = tokenName;
        _symbol = tokenSymbol;

        // user
        vestOptions[1].cliff_period = cliffPeriods[0];
        vestOptions[1].release_period = releasePeriods[0];
        // lead
        vestOptions[2].cliff_period =  cliffPeriods[1];
        vestOptions[2].release_period = releasePeriods[1];

        _sellerContract = address(0);

    }

    function _checkSeller() internal view virtual{
        if (msg.sender != _sellerContract) {
            revert AccessControlUnauthorizedAccount(msg.sender);
        }
    }

    function _checkOwner() internal view virtual{
        if (msg.sender != contractOwner) {
            revert AccessControlUnauthorizedAccount(msg.sender);
        }
    }

    function owner() external view returns(address) {
        return contractOwner;
    }

    function getSellerContract() external view returns(address) {
        return _sellerContract;
    }

    function setSeller(address newSeller) external onlyOwner(){
        require(newSeller != address(0), "setSeller: sellerContract must be a real address");
        require(_sellerContract == address(0), "setSeller: sellerContract already set");
        _sellerContract = newSeller;
        emit NewSellerContract(newSeller);
    }

    function blockVesting(address user, uint256 nonce) external whenNotPaused onlyOwner() returns(bool){
        require(nonce >0 && nonce <= _vestingNonces[user], "blockVesting: Bad nonce number");
        require(_vestingStartDate[user][nonce] + MAX_STOP_VESTING_PERIOD < block.timestamp, "blockVesting: The time is over");
        if (_vestingAmounts[user][nonce] == _unvestedAmounts[user][nonce]) return false;
        _vestingStopped[user][nonce] = true;
        return true;
    }

    function unblockVesting(address user, uint256 nonce) external whenNotPaused onlyOwner() returns(bool){
        require(nonce >0 && nonce <= _vestingNonces[user], "unblockVesting: Bad nonce number");
        require(_vestingStopped[user][nonce] == true, "unblockVesting: Vesting not stopped");
        _vestingStopped[user][nonce] = false;
        return true;
    }

    function unvest() external whenNotPaused returns (uint unvested) {
        require (_vestingNonces[msg.sender] > 0, "unvest: No vested amount");
        for (uint i = 1; i <= _vestingNonces[msg.sender]; i++) {
            if (_vestingAmounts[msg.sender][i] == _unvestedAmounts[msg.sender][i]) continue;
            if (_vestingStopped[msg.sender][i]) continue;
            if (_vestingReleaseStartDates[msg.sender][i] > block.timestamp) continue;
            uint toUnvest = (block.timestamp - _vestingReleaseStartDates[msg.sender][i]) * _vestingAmounts[msg.sender][i] / _vestingReleasePeriod[msg.sender][i];
            if (toUnvest > _vestingAmounts[msg.sender][i]) {
                toUnvest = _vestingAmounts[msg.sender][i];
            } 
            uint totalUnvestedForNonce = toUnvest;
            toUnvest -= _unvestedAmounts[msg.sender][i];
            unvested += toUnvest;
            _unvestedAmounts[msg.sender][i] = totalUnvestedForNonce;
        }
        _unfrozenBalances[msg.sender] += unvested;
        emit Unvest(msg.sender, unvested);
    }

    function vest(address user, uint256 amount, uint8 vestTypeId) external whenNotPaused onlySeller(){
        require(amount > 0, 'vest: Amount must be greater than 0');
        require((vestTypeId == 1) || (vestTypeId ==2), 'vest: Vesting Type must be 1 or 2');

        _vest(user, amount, vestTypeId);
    }

    function burnTokens(uint amount) external whenNotPaused onlyOwner() returns (bool success) {
        require(amount <= _unfrozenBalances[contractOwner], "burnTokens: Exceeds available amount");

        uint256 ownerBalance = _unfrozenBalances[contractOwner];
        require(ownerBalance >= amount, "burnTokens: Burn amount exceeds owner balance");

        _unfrozenBalances[contractOwner] = ownerBalance - amount;
        _totalSupply -= amount;
        emit Transfer(contractOwner, address(0), amount);
        return true;
    }

    function availableForUnvesting(address user) external view returns (uint unvestAmount) {
        if (_vestingNonces[user] == 0) return 0;
        for (uint i = 1; i <= _vestingNonces[user]; i++) {
            if (_vestingAmounts[user][i] == _unvestedAmounts[user][i]) continue;
            if (_vestingReleaseStartDates[user][i] > block.timestamp) continue;
            if (_vestingStopped[user][i]) continue;
            uint toUnvest = (block.timestamp - _vestingReleaseStartDates[user][i]) * _vestingAmounts[user][i] / _vestingReleasePeriod[user][i];
            if (toUnvest > _vestingAmounts[user][i]) {
                toUnvest = _vestingAmounts[user][i];
            } 
            toUnvest -= _unvestedAmounts[user][i];
            unvestAmount += toUnvest;
        }
    }

    function availableForTransfer(address account) external view returns (uint) {
        return _unfrozenBalances[account];
    }

    function vestingInfo(address user, uint nonce) external view returns (uint vestingAmount, uint unvestedAmount, uint vestingReleaseStartDate, uint vestType, bool vestingStopped) {
        vestingAmount = _vestingAmounts[user][nonce];
        unvestedAmount = _unvestedAmounts[user][nonce];
        vestingReleaseStartDate = _vestingReleaseStartDates[user][nonce];
        vestType = _vestingTypes[user][nonce];
        vestingStopped = _vestingStopped[user][nonce];
    }

    function vestingNonces(address user) external view returns (uint lastNonce) {
        return _vestingNonces[user];
    }

    function _vest(address user, uint256 amount, uint8 vestType) private {

        require((_vestedTokenCount + amount) <= MAX_VESTING, "vest: Can`t vesting more tokens");
        require(user != address(0), "vest: Vesting to the zero address not allowed");
        uint nonce = ++_vestingNonces[user];
        _vestingAmounts[user][nonce] = amount;
        _vestingReleaseStartDates[user][nonce] = block.timestamp + vestOptions[vestType].cliff_period;
        _vestingReleasePeriod[user][nonce] = vestOptions[vestType].release_period;
        //_unfrozenBalances[contractOwner] -= amount;
        _vestingTypes[user][nonce] = vestType;
        _vestingStopped[user][nonce] = false;
        _totalSupply +=amount;
        _vestedTokenCount +=amount;
        emit Transfer(address(0), user, amount);
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner() returns (bool success) {
        return IERC20(tokenAddress).transfer(contractOwner, tokens);
    }

    function max_supply() external view virtual returns(uint256) {
        return MAX_VESTING;
    }

    function vestedTokens() public view returns(uint256) {
        return _vestedTokenCount;
    }

    function pause() external onlyOwner() {
        _pause();
    }

    function unpause() external onlyOwner() {
        _unpause();
    }

    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)  public view  returns (uint256) {
        uint amount = _unfrozenBalances[account];
        if (_vestingNonces[account] == 0) return amount;
        for (uint i = 1; i <= _vestingNonces[account]; i++) {
            amount = amount + _vestingAmounts[account][i] - _unvestedAmounts[account][i];
        }
        return amount;
    }

    function transfer(address to, uint256 value) public  returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, value);
        return true;
    }

    function allowance(address _owner, address spender) public view  returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 value) public  returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address _owner, address spender, uint256 value) internal whenNotPaused{
        _approve(_owner, spender, value, true);
    }

    function _approve(address _owner, address spender, uint256 value, bool emitEvent) internal {
        if (_owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[_owner][spender] = value;
        if (emitEvent) {
            emit Approval(_owner, spender, value);
        }
    }

    function _spendAllowance(address _owner, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(_owner, spender, currentAllowance - value, false);
            }
        }
    }

    function _update(address from, address to, uint256 value) internal whenNotPaused {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            require((_vestedTokenCount + value) <= MAX_VESTING, "_update: Can`t vesting more tokens");
            _totalSupply += value;
            _vestedTokenCount += value;
        } else {
            uint256 fromBalance = _unfrozenBalances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _unfrozenBalances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _unfrozenBalances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }
}
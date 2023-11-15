// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ISPEC} from "./ISPEC.sol";

/**
 * @title SPEC ERC20 token
 */
contract SPEC is ISPEC, Ownable {
    mapping(address => uint256) private _shares;
    mapping(address account => mapping(address spender => uint256))
        private _allowances;

    // Name and symbol of the ERC20 contract
    string private constant SYMBOL = "SPEC";
    string private constant NAME = "Speculate";
    // Maximum supply of SPEC tokens
    uint256 private constant MAX_SUPPLY = 100_000_000 * (10 ** 18);
    // Initial supply is 70M SPEC tokens
    uint256 private constant INITIAL_SUPPLY = 70_000_000 * (10 ** 18);
    // Every 60 days rebase amount gets halved
    uint256 private constant TIME_BETWEEN_REBASE_REDUCTION = 60 days;
    uint256 private constant REWARD_DENOMINATOR = 100000000000;

    // Total supply increases based when rebases happen
    uint256 private _totalSupply = INITIAL_SUPPLY;
    // Total share amount
    uint256 private immutable _totalShare =
        type(uint256).max - (type(uint256).max % INITIAL_SUPPLY);
    // Last time the rebase got halved
    uint256 private _lastRebaseReduction = 0;
    // Date of the next rebase, used to prevent rebasing too soon
    uint256 private _nextRebase = block.timestamp + 1 days;
    // Used to calculate the rebase amount
    uint256 private _reward = 357146000;
    // Address of the Uniswap V2 pool
    address public pool;
    // Percentage of trading fees on Uniswap
    // 600 means 6%
    uint256 public tradingFee = 600;
    // Addresses of the accounts that should not take rebase interest
    address[] public stableBalanceAddresses;
    // Address of the accounts that receive the trading fee
    address[3] public feeReceivers;

    /**
     * @notice Creates the token with the specified amount and sends all supply to the _recipient
     */
    constructor() Ownable(msg.sender) {
        _shares[msg.sender] = _totalShare;
    }

    /**
     * @notice Sets the trading fee percentage
     * @param _newTradingFee The new trading fee percentage
     */
    function setTradingFee(uint256 _newTradingFee) external onlyOwner {
        tradingFee = _newTradingFee;

        emit TradingFeeSet(_newTradingFee);
    }

    /**
     * @notice Sets the addresses of fee receivers
     * @param _feeReceivers Addresses of the 3 fee receivers
     */
    function setFeeReceivers(
        address[3] calldata _feeReceivers
    ) external onlyOwner {
        feeReceivers = _feeReceivers;

        emit FeeReceiversSet();
    }

    /**
     * @notice Sets the address of the Uniswap V2 pool
     * @param _pool Address of the Uniswap V2 pool
     */
    function setPoolAddress(address _pool) external onlyOwner {
        if (_pool == address(0x00)) {
            revert InvalidAddress();
        }

        pool = _pool;

        emit PoolAddressSet(_pool);
    }

    /**
     * @notice Adds an address to the stable addresses
     * @param _stableAddress The new address to add
     */
    function addStableAddress(address _stableAddress) external onlyOwner {
        address[] memory _stableBalanceAddresses = stableBalanceAddresses;

        if (pool == _stableAddress) {
            revert StableAddressCannotBePoolAddress(_stableAddress);
        }

        for (uint256 i = 0; i < _stableBalanceAddresses.length; ) {
            if (_stableBalanceAddresses[i] == _stableAddress) {
                revert StableAddressAlreadyExists(_stableAddress);
            }

            unchecked {
                ++i;
            }
        }

        stableBalanceAddresses.push(_stableAddress);

        emit StableBalanceAddressAdded(_stableAddress);
    }

    /**
     * @notice Removes an stable address from the list of stable addresses
     * @param _stableAddress The address to remove from the list
     */
    function removeStableAddress(address _stableAddress) external onlyOwner {
        address[] memory stableAddresses = stableBalanceAddresses;

        uint256 addressIndex = 0;
        uint256 addressFound = 1; // 1 = not found -- 2 = found

        // find the index of the _stableAddress
        for (uint256 i = 0; i < stableAddresses.length; ) {
            if (stableAddresses[i] == _stableAddress) {
                addressIndex = i;
                addressFound = 2;
            }

            unchecked {
                ++i;
            }
        }

        // revert if the _stableAddress does not exist in the list
        if (addressFound == 1) {
            revert StableAddressNotFound(_stableAddress);
        }

        // Move the last element into the place to delete
        stableBalanceAddresses[addressIndex] = stableBalanceAddresses[
            stableBalanceAddresses.length - 1
        ];

        // Remove the last element
        stableBalanceAddresses.pop();

        emit StableBalanceAddressRemoved(_stableAddress);
    }

    /**
     * @notice Returns true if the address is either the owner, stableAddress or feeReceiver
     * @param _holder The address to check
     * @return taxFree Returns whether if the holder is tax free or not
     */
    function isTaxFree(address _holder) public view returns (bool taxFree) {
        address[3] memory _feeReceivers = feeReceivers;
        address[] memory _stableBalanceAddresses = stableBalanceAddresses;

        taxFree = false;

        // Check the _holder between stable balance addresses
        for (uint256 i = 0; i < _stableBalanceAddresses.length; ) {
            if (_stableBalanceAddresses[i] == _holder) {
                taxFree = true;
            }

            unchecked {
                ++i;
            }
        }

        // Check the _holder between fee receivers
        for (uint256 i = 0; i < _feeReceivers.length; ) {
            if (_feeReceivers[i] == _holder) {
                taxFree = true;
            }

            unchecked {
                ++i;
            }
        }

        // Check the _holder with the owner
        if (owner() == _holder) {
            taxFree = true;
        }
    }

    /**
     * @notice Rebases and adds reward to the totalSupply
     */
    function rebase() external onlyOwner returns (uint256) {
        if (!_shouldRebase()) {
            revert RebaseNotAvailableNow();
        }

        if (_lastRebaseReduction == 0) {
            _lastRebaseReduction = block.timestamp;
        }

        // Checks if 60 days has passed. If so, then halves the rebase reward
        if (
            _lastRebaseReduction + TIME_BETWEEN_REBASE_REDUCTION <=
            block.timestamp
        ) {
            _reward -= (_reward * 50) / 100;

            _lastRebaseReduction = block.timestamp;
        }

        uint256 poolBalanceBefore = balanceOf(pool);
        (
            uint256 sumStableBalancesBefore,
            uint256[] memory stableBalancesBefore
        ) = _getStableAddressBalances();

        uint256 supplyDelta = (_totalSupply *
            _rewardCalculator(poolBalanceBefore + sumStableBalancesBefore)) /
            REWARD_DENOMINATOR;

        _nextRebase = _nextRebase + 1 days;
        _totalSupply = _totalSupply + supplyDelta;

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _fixStableBalances(poolBalanceBefore, stableBalancesBefore);

        emit Rebase(supplyDelta);

        return _totalSupply;
    }

    /**
     * @notice Returns the amount of shares per 1 balance amount
     * @return Returns the amount of shares per 1 balance amount
     */
    function sharePerBalance() public view returns (uint256) {
        return _totalShare / _totalSupply;
    }

    /**
     * @notice Calculates share amount to balance amount and returns it
     * @param _sharesAmount Amount of shares to convert
     * @return _balanceAmount Returns the balance amount relative to the share amount
     */
    function convertSharesToBalance(
        uint256 _sharesAmount
    ) public view returns (uint256 _balanceAmount) {
        _balanceAmount = _sharesAmount / sharePerBalance();
    }

    /**
     * @notice Calculates balance amount to share amount and returns it
     * @param _balanceAmount Amount of balance to convert
     * @return _sharesAmount Returns the share amount relative to the balance amount
     */
    function convertBalanceToShares(
        uint256 _balanceAmount
    ) public view returns (uint256 _sharesAmount) {
        _sharesAmount = _balanceAmount * sharePerBalance();
    }

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param _account Address of the account
     * @return _balances Returns the amount of tokens owned by `account`.
     */
    function balanceOf(
        address _account
    ) public view returns (uint256 _balances) {
        _balances = convertSharesToBalance(_shares[_account]);
    }

    /**
     * @notice Returns the name of the token.
     * @return Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return NAME;
    }

    /**
     * @notice Returns the symbol of the token.
     * @return Returns the symbol of the token.
     */
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    /**
     * @notice Returns the decimals places of the token.
     * @return Returns the decimals places of the token.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @notice Returns the amount of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` is allowed
     * @param _owner The owner of the tokens
     * @param _spender The spender of the owner's tokens
     * @return Returns the amount of allowance
     */
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    /**
     * @notice Sets `value` as the allowance of `spender` over the caller's tokens.
     * @param _spender The spender receiving the allowance
     * @param _value The amount of tokens being allowed
     * @return Returns true if the operation was successful
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value, true);

        return true;
    }

    /**
     * @notice Moves `value` tokens from the caller's account to `to`.
     * @param _to The address receiving the tokens
     * @param _value The amount of tokens being transferred
     * @return Returns true if the operation was successful
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Moves `value` tokens from `from` to `to` using the allowance mechanism.
     * @dev `value` is then deducted from the caller's allowance.
     * @param _from The address sending the tokens
     * @param _to The address receiving the tokens
     * @param _value The amount of tokens being transferred
     * @return Returns true if the operation was successful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool) {
        _spendAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * @notice Calculates how much fee should be taken from the amount
     * @param _shareAmount Amount of shares that the receiver is going to receive
     */
    function _calculateFeeAmount(
        uint256 _shareAmount
    ) internal view returns (uint256) {
        return (_shareAmount / 10000) * tradingFee;
    }

    /**
     * @notice Calculates how much fee should be taken from a transfer
     * @param _from Address that is spending tokens
     * @param _to Address that is getting tokens
     * @param _shareAmount Share amount of the transfer
     * @return Fee of the transfer based on the sender and the receiver
     */
    function _calculateFee(
        address _from,
        address _to,
        uint256 _shareAmount
    ) internal view returns (uint256) {
        if (_from == pool || _to == pool) {
            if (isTaxFree(_from) || isTaxFree(_to)) {
                return 0;
            }

            return _calculateFeeAmount(_shareAmount);
        }

        return 0;
    }

    /**
     * @notice Spreads the fee between the 3 fee receivers
     * @param _fee The total amount of fee to spread
     */
    function _spreadFee(uint256 _fee) internal {
        address[3] memory _feeReceivers = feeReceivers;

        if (_fee == 0) {
            return;
        }

        for (uint256 i = 0; i < _feeReceivers.length; ) {
            _shares[_feeReceivers[i]] = _shares[_feeReceivers[i]] + (_fee / 3);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns true if 24 hours has passed since the last rebase
     * @return Returns true if 24 hours has passed since the last rebase
     */
    function _shouldRebase() internal view returns (bool) {
        return _nextRebase <= block.timestamp;
    }

    /**
     * @notice Accumulates the balances of stable addresses and returns the accumulated balance
     * and the array of the balances of stable balances
     * @return Returns the accumulated balance and the array of the balances of stable balances
     */
    function _getStableAddressBalances()
        internal
        view
        returns (uint256, uint256[] memory)
    {
        uint256[] memory fixedRebaseBalances = new uint256[](
            stableBalanceAddresses.length
        );
        uint256 sumBalances = 0;

        for (uint256 i = 0; i < fixedRebaseBalances.length; ) {
            uint256 accountBalance = balanceOf(stableBalanceAddresses[i]);

            sumBalances += accountBalance;
            fixedRebaseBalances[i] = accountBalance;

            unchecked {
                ++i;
            }
        }

        return (sumBalances, fixedRebaseBalances);
    }

    /**
     * @notice Sets back the balances of stable addresses to their balances before the rebase
     * @dev This is done because stable addresses and pool addresses should not take any rewards
     * @param _poolBalanceBefore Balance of Uniswap pool before the rebase
     * @param _stableBalancesBefore Balance of stable addresses before the rebase
     */
    function _fixStableBalances(
        uint256 _poolBalanceBefore,
        uint256[] memory _stableBalancesBefore
    ) internal {
        address[] memory _stableBalanceAddresses = stableBalanceAddresses;

        _shares[pool] = convertBalanceToShares(_poolBalanceBefore);

        for (uint256 i = 0; i < _stableBalanceAddresses.length; ) {
            _shares[_stableBalanceAddresses[i]] = convertBalanceToShares(
                _stableBalancesBefore[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates the total reward amount
     * @param _poolAndStableAddressesBalances Total balance of stable addresses
     * @return totalReward Total reward amount
     */
    function _rewardCalculator(
        uint256 _poolAndStableAddressesBalances
    ) internal view returns (uint256 totalReward) {
        totalReward =
            (_reward * INITIAL_SUPPLY) /
            (totalSupply() - _poolAndStableAddressesBalances);
    }

    /**
     * @notice Moves a `value` amount of tokens from `from` to `to`.
     * @param _from The address sending the tokens
     * @param _to The address receiving the tokens
     * @param _value The amount of tokens being transferred
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        if (_from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        if (_to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _update(_from, _to, _value);
    }

    /**
     * @notice Transfers a `value` amount of tokens from `from` to `to`
     * @param _from The address sending the tokens
     * @param _to The address receiving the tokens
     * @param _value The amount of tokens being transferred
     */
    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual {
        uint256 shareAmount = convertBalanceToShares(_value);
        uint256 share = _shares[_from];

        if (share < shareAmount) {
            revert ERC20InsufficientBalance(_from, _value, 0);
        }

        _shares[_from] = _shares[_from] - shareAmount;

        uint256 fee = _calculateFee(_from, _to, shareAmount);

        _spreadFee(fee);

        _shares[_to] = _shares[_to] + (shareAmount - fee);

        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Updates `owner` s allowance for `spender` based on spent `value`.
     * @dev Does not update the allowance value in case of infinite allowance.
     * @param _owner The owner of the tokens
     * @param _spender The spender of the tokens
     * @param _value The value of the tokens being spent
     */
    function _spendAllowance(
        address _owner,
        address _spender,
        uint256 _value
    ) internal virtual {
        uint256 currentAllowance = allowance(_owner, _spender);

        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < _value) {
                revert ERC20InsufficientAllowance(
                    _spender,
                    currentAllowance,
                    _value
                );
            }

            _approve(_owner, _spender, currentAllowance - _value, false);
        }
    }

    /**
     * @notice Sets `value` as the allowance of `spender` over the owner
     * @param _owner The owner of the tokens
     * @param _spender The spender of the tokens
     * @param _value The total amount that owner wants to allow spender
     * @param _emitEvent Should this function emit events?
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _value,
        bool _emitEvent
    ) internal virtual {
        if (_owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }

        if (_spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }

        _allowances[_owner][_spender] = _value;

        if (_emitEvent) {
            emit Approval(_owner, _spender, _value);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISPEC is IERC20 {
    /**
     * @notice Emitted when a new set of fee receivers are set
     */
    event FeeReceiversSet();

    /**
     * @notice Emitted when a new Uniswap pool address is set
     * @param _pool New Uniswap pool address
     */
    event PoolAddressSet(address _pool);

    /**
     * @notice Emitted when trading fee of the token is changed
     * @param _tradingFee New trading fee in percentage * 100
     */
    event TradingFeeSet(uint256 _tradingFee);

    /**
     * @notice Emitted when a stable address is added to the list
     * @param _stableAddress Address that was added to the list
     */
    event StableBalanceAddressAdded(address _stableAddress);

    /**
     * @notice Emitted when a stable address is removed from the list
     * @param _stableAddress Address that was removed from the list
     */
    event StableBalanceAddressRemoved(address _stableAddress);

    /**
     * @notice Emitted when a rebase happens
     * @param _supplyDelta The amount of supply that was added to the total supply
     */
    event Rebase(uint256 _supplyDelta);

    /**
     * @dev Indicates that now is too soon to call the rebase
     */
    error RebaseNotAvailableNow();

    /**
     * @dev Indicates that an address is 0x00
     */
    error InvalidAddress();

    /**
     * @dev Indicates an error when an stable address is the pool address
     * @param _stableAddress Address that was going to be added to the list
     */
    error StableAddressCannotBePoolAddress(address _stableAddress);

    /**
     * @dev Indicates an error when an stable address is already exists in the list
     * @param _stableAddress Address that was going to be added to the list
     */
    error StableAddressAlreadyExists(address _stableAddress);

    /**
     * @dev Indicates an error when an stable address is given to be removed but it is not found
     * @param _stableAddress Address that was going to be removed from the list
     */
    error StableAddressNotFound(address _stableAddress);

    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);

    /**
     * @notice Calculates share amount to balance amount and returns it
     * @param _sharesAmount Amount of shares to convert
     * @return _balanceAmount Returns the balance amount relative to the share amount
     */
    function convertSharesToBalance(
        uint256 _sharesAmount
    ) external view returns (uint256 _balanceAmount);

    /**
     * @notice Calculates balance amount to share amount and returns it
     * @param _balanceAmount Amount of balance to convert
     * @return _sharesAmount Returns the share amount relative to the balance amount
     */
    function convertBalanceToShares(
        uint256 _balanceAmount
    ) external view returns (uint256 _sharesAmount);

    /**
     * @notice Returns the amount of shares per 1 balance amount
     * @return Returns the amount of shares per 1 balance amount
     */
    function sharePerBalance() external view returns (uint256);

    /**
     * @notice Rebases and adds reward to the totalSupply
     */
    function rebase() external returns (uint256);

    /**
     * @notice Returns true if the address is either the owner, stableAddress or feeReceiver
     * @param _holder The address to check
     * @return taxFree Returns whether if the holder is tax free or not
     */
    function isTaxFree(address _holder) external view returns (bool taxFree);

    /**
     * @notice Removes an stable address from the list of stable addresses
     * @param _stableAddress The address to remove from the list
     */
    function removeStableAddress(address _stableAddress) external;

    /**
     * @notice Adds an address to the stable addresses
     * @param _stableAddress The new address to add
     */
    function addStableAddress(address _stableAddress) external;

    /**
     * @notice Sets the address of the Uniswap V2 pool
     * @param _pool Address of the Uniswap V2 pool
     */
    function setPoolAddress(address _pool) external;

    /**
     * @notice Sets the addresses of fee receivers
     * @param _feeReceivers Addresses of the 3 fee receivers
     */
    function setFeeReceivers(address[3] calldata _feeReceivers) external;

    /**
     * @notice Sets the trading fee percentage
     * @param _newTradingFee The new trading fee percentage
     */
    function setTradingFee(uint256 _newTradingFee) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
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
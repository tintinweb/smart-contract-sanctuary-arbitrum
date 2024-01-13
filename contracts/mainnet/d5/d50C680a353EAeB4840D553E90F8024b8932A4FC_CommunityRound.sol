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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommunityRound is Ownable {
    struct Pools {
        uint256 maxTokensPerCode;
        uint256 maxTokensPerPool;
        uint256 filledTokens;
        uint256 createdAt;
        bool isActive;
    }

    IERC20 public USDT;
    IERC20 public USDC;

    uint public DecimalUSDT;
    uint public DecimalUSDC;

    uint256 public noxPerUsd;

    uint256 public startTime;

    address public feeRecivingWallet;

    struct Allocations {
        uint256 allocatedAmount;
        uint256 remainingAmount;
    }

    // Whitelisted users
    mapping(address => Allocations) public whitelistAmounts;

    mapping(bytes32 => Pools) public poolDetails;
    mapping(address => mapping(bytes32 => uint256)) public usedTokensWithCode;

    // events
    event NewPoolCreated(
        string Code,
        bytes32 indexed Lable,
        uint256 maxTokensPerPool,
        uint256 maxTokensPerCode
    );

    event BoughtWithCode(
        bytes32 indexed Lable,
        string code,
        address indexed Buyer,
        uint256 NoxAmount
    );

    event BoughtWithWhitelist(
        address indexed buyer,
        uint256 usdtAmount,
        uint256 usdcAmount,
        uint256 noxAmount
    );

    modifier onlyWhitelisted() {
        require(
            whitelistAmounts[msg.sender].allocatedAmount != 0,
            "Not whitelisted"
        );
        _;
    }
    address public managerWallet;
    modifier onlyManager() {
        require(
            managerWallet == msg.sender || owner() == msg.sender,
            "Only Manager can call"
        );
        _;
    }

    constructor(
        address _usdtAddress,
        address _usdcAddress,
        uint _DecimalUSDT,
        uint _DecimalUSDC,
        uint256 _startTime
    ) {
        USDT = IERC20(_usdtAddress);
        USDC = IERC20(_usdcAddress);

        noxPerUsd = 142857 * 10 ** 5;

        startTime = _startTime;
        DecimalUSDT = _DecimalUSDT;
        DecimalUSDC = _DecimalUSDC;
        managerWallet = msg.sender;
        feeRecivingWallet = 0xCa45484557b7Ac66c321E3fCB1d857a9358baFf7;

        transferOwnership(0xCa45484557b7Ac66c321E3fCB1d857a9358baFf7);
    }

    function createNewCode(
        string memory _code,
        uint256 _maxTokensPerCode,
        uint256 _maxTokensPerPool
    ) external onlyManager {
        bytes32 label = keccak256(bytes(_code));

        Pools storage _newPool = poolDetails[label];

        require(!_newPool.isActive, "Code Already Exict");

        _newPool.createdAt = block.timestamp;
        _newPool.maxTokensPerCode = _maxTokensPerCode;
        _newPool.maxTokensPerPool = _maxTokensPerPool;
        _newPool.isActive = true;

        emit NewPoolCreated(_code, label, _maxTokensPerPool, _maxTokensPerCode);
    }

    function buyWithCode(
        string memory _code,
        uint256 usdtAmount,
        uint256 usdcAmount
    ) external {
        bytes32 label = keccak256(bytes(_code));
        Pools storage _currentPool = poolDetails[label];
        require(_currentPool.isActive, "Code is not active");

        uint256 _buyingNoxTokens = calculateNOXAmount(usdtAmount, usdcAmount);

        require(
            (usedTokensWithCode[msg.sender][label] + _buyingNoxTokens) <=
                _currentPool.maxTokensPerCode,
            "You are exceeding your allocation"
        );

        require(
            (_currentPool.filledTokens + _buyingNoxTokens) <=
                _currentPool.maxTokensPerPool,
            "You are exceeding pool allocation"
        );

        // Transfer USDT and USDC from user to owner
        if (usdtAmount > 0)
            USDT.transferFrom(msg.sender, feeRecivingWallet, usdtAmount);
        if (usdcAmount > 0)
            USDC.transferFrom(msg.sender, feeRecivingWallet, usdcAmount);

        usedTokensWithCode[msg.sender][label] += _buyingNoxTokens;
        _currentPool.filledTokens += _buyingNoxTokens;

        emit BoughtWithCode(label, _code, msg.sender, _buyingNoxTokens);
    }

    // Function to allow users to purchase NOX tokens
    function purchaseTokens(
        uint256 usdtAmount,
        uint256 usdcAmount
    ) external onlyWhitelisted {
        // Perform necessary calculations to determine NOX tokens to be minted
        uint256 noxAmount = calculateNOXAmount(usdtAmount, usdcAmount);

        require(
            whitelistAmounts[msg.sender].remainingAmount >= noxAmount,
            "Allocation Exceeded"
        );

        whitelistAmounts[msg.sender].remainingAmount -= noxAmount;

        // Transfer USDT and USDC from user to owner
        if (usdtAmount > 0)
            USDT.transferFrom(msg.sender, feeRecivingWallet, usdtAmount);
        if (usdcAmount > 0)
            USDC.transferFrom(msg.sender, feeRecivingWallet, usdcAmount);

        // Emit purchase event
        emit BoughtWithWhitelist(msg.sender, usdtAmount, usdcAmount, noxAmount);
    }

    function changeNoxValue(uint256 _noxPerUSD) external onlyOwner {
        noxPerUsd = _noxPerUSD;
    }

    function changeStableCoins(
        address _usdt,
        address _usdc
    ) external onlyOwner {
        USDT = IERC20(_usdt);
        USDC = IERC20(_usdc);
    }

    // Function to calculate the amount of NOX tokens to mint based on the purchased USDT and USDC
    function calculateNOXAmount(
        uint256 usdtAmount,
        uint256 usdcAmount
    ) internal view returns (uint256) {
        uint256 noxForUSDT = (usdtAmount * noxPerUsd) / 10 ** DecimalUSDT;
        uint256 noxForUSDC = (usdcAmount * noxPerUsd) / 10 ** DecimalUSDC;

        uint256 noxAmount = noxForUSDT + noxForUSDC;

        return noxAmount;
    }

    // Function to add or remove users from the whitelist (only callable by owner)
    function updateWhitelist(
        address[] memory _users,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(_users.length == _amounts.length, "Invalid array combination");
        for (uint i = 0; i < _users.length; i++) {
            whitelistAmounts[_users[i]].allocatedAmount = _amounts[i];
            whitelistAmounts[_users[i]].remainingAmount = _amounts[i];
        }
    }

    function updateFundWallet(address _wallet) external onlyOwner {
        feeRecivingWallet = _wallet;
    }

    function updateBuy(
        bytes32 label,
        address _buyer,
        uint256 _noxAmount
    ) external onlyManager {
        Pools storage _currentPool = poolDetails[label];

        usedTokensWithCode[_buyer][label] += _noxAmount;
        _currentPool.filledTokens += _noxAmount;
    }

    function updateWhitelistBuy(
        address _buyer,
        uint256 _noxAmount
    ) external onlyManager {
        if (whitelistAmounts[_buyer].remainingAmount > 0)
            whitelistAmounts[_buyer].remainingAmount -= _noxAmount;
    }
}
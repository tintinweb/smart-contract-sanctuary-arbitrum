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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// INTERFACES
// To calculate backup creation fee in ETH
interface EthPriceOracle {
    function getEthPrice() external view returns (uint256, uint256);
}

// To check discounted users
interface DiscountedUserOracle {
    function isDiscountedUser(address _user) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract EasyBackup is Ownable {
    // Backup object
    struct Backup {
        address from;
        address to;
        address token;
        uint256 amount;
        uint256 expiry;
        bool isActive;
        bool isAutomatic;
        bool isClaimed;
    }

    // Constants
    uint256 public constant MAX_CLAIM_FEE = 100; // Basis points, max 1%
    // Manager Variables
    uint256 public claimFee = 100; // Basis points, default 1%
    uint256 public initFeeUsd = 1000; // In 0.01 USD, default $10
    address public initFeeCollector;
    address public claimFeeCollector;
    bool public isReferralActive;
    uint256 public referralFee = 5000; // Basis points, default 50%
    // Oracles
    address public ethPriceOracleAddress;
    EthPriceOracle ethPriceOracle;
    address public discountedUserOracleAddress;
    DiscountedUserOracle discountedUserOracle;
    // User Variables
    mapping(address => uint256) public lastInteraction;
    mapping(uint256 => Backup) public backups;
    uint256 public backupCount;
    mapping(address => uint256[]) public createdBackups;
    mapping(address => uint256) public createdBackupsCount;
    mapping(address => uint256[]) public claimableBackups;
    mapping(address => uint256) public claimableBackupsCount;
    // Stats
    uint256 public totalUsers;
    uint256 public referralBackupCount;
    mapping(address => uint256) public referralCount;
    uint256 public discountedBackupCount;
    uint256 public totalClaims;
    mapping(address => uint256) public claims;

    // CONSTRUCTOR: Sets oracles and fee collectors
    constructor(address _discountOracle, address _ethPriceOracle, address _initFeeCollector, address _claimFeeCollector) {
        discountedUserOracleAddress = _discountOracle;
        discountedUserOracle = DiscountedUserOracle(_discountOracle);
    
        ethPriceOracleAddress = _ethPriceOracle;
        ethPriceOracle = EthPriceOracle(_ethPriceOracle);

        initFeeCollector = _initFeeCollector;
        claimFeeCollector = _claimFeeCollector;
    }

    // EVENTS
    event BackupCreated(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 expiry,
        uint256 id
    );
    event BackupEdited(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 expiry,
        uint256 id
    );
    event BackupDeleted(
        uint256 indexed id
    );
    event BackupClaimed(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 id,
        bool isAutomatic
    );

    // USER FUNCTIONS
    function heartBeat() public {
        lastInteraction[msg.sender] = block.timestamp;
    }

    // Backup creation and editing
    function createBackup(
        address _to,
        address _token,
        uint256 _amount,
        uint256 _expiry,
        bool _isAutomatic,
        address _referral
    ) external payable {
        heartBeat();

        bool isDiscounted = discountedUserOracle.isDiscountedUser(msg.sender);
        uint256 fee = getInitFee();
        if(isDiscounted) {
            discountedBackupCount += 1;
        } else {
            require(msg.value >= fee, "Insufficient fee");
        }

        backups[backupCount] = Backup(
            msg.sender,
            _to,
            _token,
            _amount,
            _expiry,
            true,
            _isAutomatic,
            false
        );
        createdBackups[msg.sender].push(backupCount);
        createdBackupsCount[msg.sender]++;
        claimableBackups[_to].push(backupCount);
        claimableBackupsCount[_to]++;

        if(createdBackupsCount[msg.sender] == 1) {
            totalUsers++;
        }

        emit BackupCreated(
            msg.sender,
            _to,
            _token,
            _amount,
            _expiry,
            backupCount
        );

        backupCount++;

        // Referral
        if(isReferralActive && !isDiscounted && _referral != address(0) && createdBackupsCount[_referral] > 0) {
            require(payable(_referral).send(fee * referralFee / 10000), "Transaction failed");
            referralCount[_referral] += 1;
            referralBackupCount += 1;
        }
    }

    function editBackup(
        uint256 _id,
        address _to,
        uint256 _amount,
        uint256 _expiry,
        bool _isAutomatic
    ) external {
        heartBeat();

        require(backups[_id].from == msg.sender, "Not your backup");
        
        backups[_id].to = _to;
        backups[_id].amount = _amount;
        backups[_id].expiry = _expiry;
        backups[_id].isAutomatic = _isAutomatic;

        emit BackupEdited(
            msg.sender,
            _to,
            backups[_id].token,
            _amount,
            _expiry,
            _id
        );
    }

    function deleteBackup(uint256 _id) external {
        heartBeat();

        require(backups[_id].from == msg.sender, "Not your backup");

        backups[_id].isActive = false;
        emit BackupDeleted(_id);
    }

    // Backup claiming
    function claimBackup(uint256 _id) external {
        heartBeat();

        require(backups[_id].to == msg.sender, "Not your backup");
        require(
            backups[_id].expiry + lastInteraction[backups[_id].from] <
                block.timestamp,
            "Too early"
        );
        require(backups[_id].isActive, "Backup inactive");

        // Calculate amount, minimum of balance, allowance, backup amount
        uint256 amount = getClaimableAmount(_id);
        uint256 fee = (amount * claimFee) / 10000;

        backups[_id].isActive = false;
        backups[_id].isClaimed = true;

        require(
            IERC20(backups[_id].token).transferFrom(
                backups[_id].from,
                claimFeeCollector,
                fee
            ),
            "Transaction failed"
        );
        require(
            IERC20(backups[_id].token).transferFrom(
                backups[_id].from,
                backups[_id].to,
                amount - fee
            ),
            "Transaction failed"
        );

        claims[backups[_id].token] += amount;
        totalClaims += 1;

        emit BackupClaimed(
            backups[_id].from,
            backups[_id].to,
            backups[_id].token,
            amount,
            _id,
            false
        );
    }

    // Automatic claiming
    function claimBackupAuto(uint256 _id) external {
        heartBeat();

        require(backups[_id].isAutomatic, "Not automatic");
        require(
            backups[_id].expiry + lastInteraction[backups[_id].from] <
                block.timestamp,
            "Too early"
        );
        require(backups[_id].isActive, "Backup inactive");

        // Calculate amount, minimum of balance, allowance, backup amount
        uint256 amount = getClaimableAmount(_id);
        uint256 fee = (amount * claimFee) / 10000;

        backups[_id].isActive = false;
        backups[_id].isClaimed = true;

        require(
            IERC20(backups[_id].token).transferFrom(
                backups[_id].from,
                claimFeeCollector,
                fee
            ),
            "Transaction failed"
        );
        require(
            IERC20(backups[_id].token).transferFrom(
                backups[_id].from,
                backups[_id].to,
                amount - fee
            ),
            "Transaction failed"
        );

        claims[backups[_id].token] += amount;
        totalClaims += 1;

        emit BackupClaimed(
            backups[_id].from,
            backups[_id].to,
            backups[_id].token,
            amount,
            _id,
            true
        );
    }

    // HELPER FUNCTIONS
    function getInitFee() public view returns (uint256) {
        (uint256 _price, uint256 _decimals) = ethPriceOracle.getEthPrice();
        uint256 _fee = (initFeeUsd * 1e16 * (10 ** _decimals)) / _price; // 1e16 because fee is in cents
        return _fee / 1e12 * 1e12; // Rounding to six
    }

    function getClaimableAmount(uint256 _id) public view returns (uint256) {
        address tokenAddress = backups[_id].token;
        address backupFrom = backups[_id].from;
        return minOfThree(
            IERC20(tokenAddress).balanceOf(backupFrom),
            IERC20(tokenAddress).allowance(backupFrom,address(this)),
            backups[_id].amount
        );
    }

    function minOfThree(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        uint256 minNumber;

        if (a < b) {
            minNumber = a;
        } else {
            minNumber = b;
        }

        if (c < minNumber) {
            minNumber = c;
        }

        return minNumber;
    }

    // MANAGER FUNCTIONS
    function setClaimFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_CLAIM_FEE, "Fee too high");
        claimFee = _newFee;
    }

    function setEthPriceOracle(address _newOracle) external onlyOwner {
        ethPriceOracleAddress = _newOracle;
        ethPriceOracle = EthPriceOracle(_newOracle);
    }

    function setDiscountedUserOracle(address _newOracle) external onlyOwner {
        discountedUserOracleAddress = _newOracle;
        discountedUserOracle = DiscountedUserOracle(_newOracle);
    }

    function setInitFeeCollector(address _feeCollector) external onlyOwner {
        initFeeCollector = _feeCollector;
    }

    function setClaimFeeCollector(address _feeCollector) external onlyOwner {
        claimFeeCollector = _feeCollector;
    }

    function setInitFee(uint256 _fee) external onlyOwner {
        initFeeUsd = _fee;
    }

    function setIsReferralActive(bool _isActive) external onlyOwner {
        isReferralActive = _isActive;
    }

    function setReferralFee(uint256 _fee) external onlyOwner {
        referralFee = _fee;
    }

    function withdrawAll() public payable {
        require(payable(initFeeCollector).send(address(this).balance));
    }
}
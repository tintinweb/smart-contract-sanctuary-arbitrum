// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./IFOInitializable.sol";

/**
 * @title IFODeployer
 */
contract IFODeployer is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BUFFER_TIME = 2 weeks;

    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
    event NewIFOContract(address indexed ifoAddress);

    /**
     * @notice Constructor
     */
    constructor() public {}

    /**
     * @notice It creates the IFO contract and initializes the contract.
     * @param _lpToken: the LP token used
     * @param _offeringToken: the token that is offered for the IFO
     * @param _startTime: the start timestamp for the IFO
     * @param _endTime: the end timestamp for the IFO
     * @param _adminAddress: the admin address for handling tokens
     */
    function createIFO(
        address _lpToken,
        address _offeringToken,
        uint256 _startTime,
        uint256 _endTime,
        address _adminAddress
    ) external onlyOwner {
        require(IERC20(_lpToken).totalSupply() >= 0);
        require(IERC20(_offeringToken).totalSupply() >= 0);
        require(
            _lpToken != _offeringToken,
            "Operations: Tokens must be be different"
        );
        require(
            _endTime < (block.timestamp + MAX_BUFFER_TIME),
            "Operations: EndTime too far"
        );
        require(
            _startTime < _endTime,
            "Operations: StartTime must be inferior to endTime"
        );
        require(
            _startTime > block.timestamp,
            "Operations: StartTime must be greater than current timestamp"
        );

        bytes memory bytecode = type(IFOInitializable).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(_lpToken, _offeringToken, _startTime)
        );
        address ifoAddress;

        assembly {
            ifoAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IFOInitializable(ifoAddress).initialize(
            _lpToken,
            _offeringToken,
            _startTime,
            _endTime,
            MAX_BUFFER_TIME,
            _adminAddress
        );

        emit NewIFOContract(ifoAddress);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        uint256 balanceToRecover = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        require(balanceToRecover > 0, "Operations: Balance must be > 0");
        IERC20(_tokenAddress).safeTransfer(
            address(msg.sender),
            balanceToRecover
        );

        emit AdminTokenRecovery(_tokenAddress, balanceToRecover);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IIFO.sol";

/**
 * @title IFOInitializable
 */
contract IFOInitializable is IIFO, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Number of pools
    uint8 public constant NUMBER_POOLS = 2;

    // The address of the smart chef factory
    address public immutable IFO_FACTORY;

    // Max timestamp (for sanity checks)
    uint256 public MAX_BUFFER_TIME;

    // The LP token used
    IERC20 public lpToken;

    // The offering token
    IERC20 public offeringToken;

    // Whether it is initialized
    bool public isInitialized;

    // The block number when IFO starts
    uint256 public startTime;

    // The block number when IFO ends
    uint256 public endTime;

    // Total tokens distributed across the pools
    uint256 public totalTokensOffered;

    // Array of PoolCharacteristics of size NUMBER_POOLS
    PoolCharacteristics[NUMBER_POOLS] private _poolInformation;

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        uint256 raisingAmountPool; // amount of tokens raised for the pool (in LP tokens)
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
        bool hasFeeTiers; // tax on the overflow (if any, it works with _calculateTaxOverflow)
        uint256 fixedFee; // fixed fee
        uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
        uint256 sumTaxesOverflow; // total taxes collected (starts at 0, increases with each harvest if overflow)
        uint256 vestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 vestingCliff; // Vesting cliff
        uint256 vestingDuration; // Vesting duration
        uint256 vestingSlicePeriodSeconds; // Vesting slice period seconds
    }

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 amountPool; // How many tokens the user has provided for pool
        bool claimedPool; // Whether the user has claimed (default: false) for pool
    }

    // vesting startTime, everyone will be started at same timestamp
    uint256 public vestingStartTime;

    // A flag for vesting is being revoked
    bool public vestingRevoked;

    // Struct that contains vesting schedule
    struct VestingSchedule {
        bool isVestingInitialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // pool id
        uint8 pid;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens has been released
        uint256 released;
    }

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    // Admin withdraw events
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken);

    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

    // Harvest event
    event Harvest(
        address indexed user,
        uint256 offeringAmount,
        uint256 excessAmount,
        uint8 indexed pid
    );

    // Create VestingSchedule event
    event CreateVestingSchedule(
        address indexed user,
        uint256 offeringAmount,
        uint256 excessAmount,
        uint8 indexed pid
    );

    // Event for new timestamp & end timestamp
    event NewStartAndEndTime(uint256 startTime, uint256 endTime);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(
        uint256 offeringAmountPool,
        uint256 raisingAmountPool,
        uint8 pid
    );

    // Event when released new amount
    event Released(address indexed beneficiary, uint256 amount);

    // Event when revoked
    event Revoked();

    // Modifier to prevent contracts to participate
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     */
    constructor() public {
        IFO_FACTORY = msg.sender;
    }

    /**
     * @notice It initializes the contract
     * @dev It can only be called once.
     * @param _lpToken: the LP token used
     * @param _offeringToken: the token that is offered for the IFO
     * @param _startTime: the start timestamp for the IFO
     * @param _endTime: the end timestamp for the IFO
     * @param _maxBufferTime: maximum buffer of timestamp from the current block number
     * @param _adminAddress: the admin address for handling tokens
     */
    function initialize(
        address _lpToken,
        address _offeringToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxBufferTime,
        address _adminAddress
    ) public {
        require(!isInitialized, "Operations: Already initialized");
        require(msg.sender == IFO_FACTORY, "Operations: Not factory");

        // Make this contract initialized
        isInitialized = true;

        lpToken = IERC20(_lpToken);
        offeringToken = IERC20(_offeringToken);
        startTime = _startTime;
        endTime = _endTime;
        MAX_BUFFER_TIME = _maxBufferTime;

        // Transfer ownership to admin
        transferOwnership(_adminAddress);
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _amount: the number of LP token used (18 decimals)
     * @param _pid: pool id
     */
    function depositPool(uint256 _amount, uint8 _pid)
        external
        override
        nonReentrant
        notContract
    {
        // Checks whether the pool id is valid
        require(_pid < NUMBER_POOLS, "Deposit: Non valid pool id");

        // Checks that pool was set
        require(
            _poolInformation[_pid].offeringAmountPool > 0 &&
                _poolInformation[_pid].raisingAmountPool > 0,
            "Deposit: Pool not set"
        );

        // Checks whether the block number is not too early
        require(block.timestamp > startTime, "Deposit: Too early");

        // Checks whether the block number is not too late
        require(block.timestamp < endTime, "Deposit: Too late");

        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Deposit: Amount must be > 0");

        // Verify tokens were deposited properly
        require(
            offeringToken.balanceOf(address(this)) >= totalTokensOffered,
            "Deposit: Tokens not deposited properly"
        );

        // Transfers funds to this contract
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update the user status
        _userInfo[msg.sender][_pid].amountPool = _userInfo[msg.sender][_pid]
            .amountPool
            .add(_amount);

        // Check if the pool has a limit per user
        if (_poolInformation[_pid].limitPerUserInLP > 0) {
            // Checks whether the limit has been reached
            require(
                _userInfo[msg.sender][_pid].amountPool <=
                    _poolInformation[_pid].limitPerUserInLP,
                "Deposit: New amount above user limit"
            );
        }

        // Updates the totalAmount for pool
        _poolInformation[_pid].totalAmountPool = _poolInformation[_pid]
            .totalAmountPool
            .add(_amount);

        emit Deposit(msg.sender, _amount, _pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid)
        external
        override
        nonReentrant
        notContract
    {
        // Checks whether it is too early to harvest
        require(block.timestamp > endTime, "Harvest: Too early");

        // Checks whether pool id is valid
        require(_pid < NUMBER_POOLS, "Harvest: Non valid pool id");

        // Checks whether the user has participated
        require(
            _userInfo[msg.sender][_pid].amountPool > 0,
            "Harvest: Did not participate"
        );

        // Checks whether the user has already harvested
        require(
            !_userInfo[msg.sender][_pid].claimedPool,
            "Harvest: Already done"
        );

        // Updates the harvest status
        _userInfo[msg.sender][_pid].claimedPool = true;

        // Updates the vesting startTime
        if (vestingStartTime == 0) {
            vestingStartTime = block.timestamp;
        }

        // Initialize the variables for offering, refunding user amounts, and tax amount
        (
            uint256 offeringTokenAmount,
            uint256 refundingTokenAmount,
            uint256 userTaxOverflow
        ) = _calculateOfferingAndRefundingAmountsPool(msg.sender, _pid);

        // Increment the sumTaxesOverflow
        if (userTaxOverflow > 0) {
            _poolInformation[_pid].sumTaxesOverflow = _poolInformation[_pid]
                .sumTaxesOverflow
                .add(userTaxOverflow);
        }

        // Transfer these tokens back to the user if quantity > 0
        if (offeringTokenAmount > 0) {
            if (100 - _poolInformation[_pid].vestingPercentage > 0) {
                uint256 amount = offeringTokenAmount
                    .mul(100 - _poolInformation[_pid].vestingPercentage)
                    .div(100);

                // Transfer the tokens at TGE
                offeringToken.safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, refundingTokenAmount, _pid);
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].vestingPercentage > 0) {
                uint256 amount = offeringTokenAmount
                    .mul(_poolInformation[_pid].vestingPercentage)
                    .div(100);

                // Create VestingSchedule object
                _createVestingSchedule(msg.sender, _pid, amount);

                emit CreateVestingSchedule(
                    msg.sender,
                    amount,
                    refundingTokenAmount,
                    _pid
                );
            }
        }

        if (refundingTokenAmount > 0) {
            lpToken.safeTransfer(msg.sender, refundingTokenAmount);
        }
    }

    /**
     * @notice It allows the admin to withdraw funds
     * @param _lpAmount: the number of LP token to withdraw (18 decimals)
     * @param _offerAmount: the number of offering amount to withdraw
     * @dev This function is only callable by admin.
     */
    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount)
        external
        override
        onlyOwner
    {
        require(
            _lpAmount <= lpToken.balanceOf(address(this)),
            "Operations: Not enough LP tokens"
        );
        require(
            _offerAmount <= offeringToken.balanceOf(address(this)),
            "Operations: Not enough offering tokens"
        );

        if (_lpAmount > 0) {
            lpToken.safeTransfer(msg.sender, _lpAmount);
        }

        if (_offerAmount > 0) {
            offeringToken.safeTransfer(msg.sender, _offerAmount);
        }

        emit AdminWithdraw(_lpAmount, _offerAmount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(lpToken),
            "Recover: Cannot be LP token"
        );
        require(
            _tokenAddress != address(offeringToken),
            "Recover: Cannot be offering token"
        );

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It sets parameters for pool
     * @param _offeringAmountPool: offering amount (in tokens)
     * @param _raisingAmountPool: raising amount (in LP tokens)
     * @param _limitPerUserInLP: limit per user (in LP tokens)
     * @param _hasFeeTiers: if the pool has a tax tier
     * @param _fixedFee: fixed fee
     * @param _pid: pool id
     * @param _vestingPercentage: percentage for vesting remain tokens after end IFO
     * @param _vestingCliff: cliff of vesting
     * @param _vestingDuration: duration of vesting
     * @param _vestingSlicePeriodSeconds: slice period seconds of vesting
     * @dev This function is only callable by admin.
     */
    function setPool(
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _limitPerUserInLP,
        bool _hasFeeTiers,
        uint256 _fixedFee,
        uint8 _pid,
        uint256 _vestingPercentage,
        uint256 _vestingCliff,
        uint256 _vestingDuration,
        uint256 _vestingSlicePeriodSeconds
    ) external override onlyOwner {
        require(block.timestamp < startTime, "Operations: IFO has started");
        require(_pid < NUMBER_POOLS, "Operations: Pool does not exist");
        require(
            _vestingPercentage >= 0 && _vestingPercentage <= 100,
            "Operations: vesting percentage should exceeds 0 and interior 100"
        );
        require(_vestingDuration > 0, "duration must exceeds 0");
        require(
            _vestingSlicePeriodSeconds >= 1,
            "slicePeriodSeconds must be exceeds 1"
        );
        require(
            _vestingSlicePeriodSeconds <= _vestingDuration,
            "slicePeriodSeconds must be interior duration"
        );

        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].raisingAmountPool = _raisingAmountPool;
        _poolInformation[_pid].limitPerUserInLP = _limitPerUserInLP;
        _poolInformation[_pid].hasFeeTiers = _hasFeeTiers;
        _poolInformation[_pid].fixedFee = _fixedFee;
        _poolInformation[_pid].vestingPercentage = _vestingPercentage;
        _poolInformation[_pid].vestingCliff = _vestingCliff;
        _poolInformation[_pid].vestingDuration = _vestingDuration;
        _poolInformation[_pid]
            .vestingSlicePeriodSeconds = _vestingSlicePeriodSeconds;

        uint256 tokensDistributedAcrossPools;

        for (uint8 i = 0; i < NUMBER_POOLS; i++) {
            tokensDistributedAcrossPools = tokensDistributedAcrossPools.add(
                _poolInformation[i].offeringAmountPool
            );
        }

        // Update totalTokensOffered
        totalTokensOffered = tokensDistributedAcrossPools;

        emit PoolParametersSet(_offeringAmountPool, _raisingAmountPool, _pid);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @param _startTime: the new start timestamp
     * @param _endTime: the new end timestamp
     * @dev This function is only callable by admin.
     */
    function updateStartAndEndBlocks(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime < (block.timestamp + MAX_BUFFER_TIME),
            "Operations: EndTime too far"
        );
        require(block.timestamp < startTime, "Operations: IFO has started");
        require(
            _startTime < _endTime,
            "Operations: New startTime must be lower than new endTime"
        );
        require(
            block.timestamp < _startTime,
            "Operations: New startTime must be higher than current timestamp"
        );

        startTime = _startTime;
        endTime = _endTime;

        emit NewStartAndEndTime(_startTime, _endTime);
    }

    /**
     * @notice It returns the pool information
     * @param _pid: pool id
     * @return raisingAmountPool: amount of LP tokens raised (in LP tokens)
     * @return offeringAmountPool: amount of tokens offered for the pool (in offeringTokens)
     * @return limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
     * @return hasFeeTiers: tax on the overflow (if any, it works with _calculateTaxOverflow)
     * @return fixedFee: fixed fee
     * @return totalAmountPool: total amount pool deposited (in LP tokens)
     * @return sumTaxesOverflow: total taxes collected (starts at 0, increases with each harvest if overflow)
     */
    function viewPoolInformation(uint256 _pid)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].raisingAmountPool,
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].limitPerUserInLP,
            _poolInformation[_pid].hasFeeTiers,
            _poolInformation[_pid].fixedFee,
            _poolInformation[_pid].totalAmountPool,
            _poolInformation[_pid].sumTaxesOverflow
        );
    }

    /**
     * @notice It returns the pool vesting information
     * @param _pid: pool id
     * @return vestingPercentage: the percentage of vesting part, claimingPercentage + vestingPercentage should be 100
     * @return vestingCliff: the cliff of vesting
     * @return vestingDuration: the duration of vesting
     * @return vestingSlicePeriodSeconds: the slice period seconds of vesting
     */
    function viewPoolVestingInformation(uint256 _pid)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].vestingPercentage,
            _poolInformation[_pid].vestingCliff,
            _poolInformation[_pid].vestingDuration,
            _poolInformation[_pid].vestingSlicePeriodSeconds
        );
    }

    /**
     * @notice It returns the tax overflow rate calculated for a pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _pid: pool id
     * @return It returns the tax percentage
     */
    function viewPoolTaxRateOverflow(uint256 _pid)
        external
        view
        override
        returns (uint256)
    {
        if (!_poolInformation[_pid].hasFeeTiers) {
            return _poolInformation[_pid].fixedFee;
        } else {
            return
                _calculateTaxOverflow(
                    _poolInformation[_pid].totalAmountPool,
                    _poolInformation[_pid].raisingAmountPool
                );
        }
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user information
     * @param _user: user address
     * @param _pids[]: array of pids
     */
    function viewUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        override
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);
        bool[] memory statusPools = new bool[](_pids.length);

        for (uint8 i = 0; i < NUMBER_POOLS; i++) {
            amountPools[i] = _userInfo[_user][i].amountPool;
            statusPools[i] = _userInfo[_user][i].claimedPool;
        }
        return (amountPools, statusPools);
    }

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAndRefundingAmountsForPools(
        address _user,
        uint8[] calldata _pids
    ) external view override returns (uint256[3][] memory) {
        uint256[3][] memory amountPools = new uint256[3][](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;
            uint256 userTaxAmountPool;

            if (_poolInformation[_pids[i]].raisingAmountPool > 0) {
                (
                    userOfferingAmountPool,
                    userRefundingAmountPool,
                    userTaxAmountPool
                ) = _calculateOfferingAndRefundingAmountsPool(_user, _pids[i]);
            }

            amountPools[i] = [
                userOfferingAmountPool,
                userRefundingAmountPool,
                userTaxAmountPool
            ];
        }
        return amountPools;
    }

    /**
     * @notice Returns the number of vesting schedules associated to a beneficiary
     * @return The number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @notice Returns the vesting schedule id at the given index
     * @return The vesting schedule id
     */
    function getVestingScheduleIdAtIndex(uint256 _index)
        external
        view
        returns (bytes32)
    {
        require(_index < getVestingSchedulesCount(), "index out of bounds");
        return vestingSchedulesIds[_index];
    }

    /**
     * @notice Returns the vesting schedule information of a given holder and index
     * @return The vesting schedule object
     */
    function getVestingScheduleByAddressAndIndex(
        address _holder,
        uint256 _index
    ) external view returns (VestingSchedule memory) {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(_holder, _index)
            );
    }

    /**
     * @notice Returns the total amount of vesting schedules
     * @return The vesting schedule total amount
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @notice Release vested amount of offering tokens
     * @param _vestingScheduleId the vesting schedule identifier
     */
    function release(bytes32 _vestingScheduleId) external nonReentrant {
        require(
            vestingSchedules[_vestingScheduleId].isVestingInitialized == true,
            "vesting schedule is not exist"
        );

        VestingSchedule storage vestingSchedule = vestingSchedules[
            _vestingScheduleId
        ];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "only the beneficiary and owner can release vested tokens"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "no vested tokens to release");
        vestingSchedule.released = vestingSchedule.released.add(vestedAmount);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(
            vestedAmount
        );
        offeringToken.safeTransfer(vestingSchedule.beneficiary, vestedAmount);

        emit Released(vestingSchedule.beneficiary, vestedAmount);
    }

    /**
     * @notice Revokes all the vesting schedules
     */
    function revoke() external onlyOwner {
        require(!vestingRevoked, "vesting is revoked");

        vestingRevoked = true;

        emit Revoked();
    }

    /**
     * @notice Returns the number of vesting schedules managed by the contract
     * @return The number of vesting count
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Returns the vested amount of tokens for the given vesting schedule identifier
     * @return The number of vested count
     */
    function computeReleasableAmount(bytes32 _vestingScheduleId)
        public
        view
        returns (uint256)
    {
        require(
            vestingSchedules[_vestingScheduleId].isVestingInitialized == true,
            "vesting schedule is not exist"
        );

        VestingSchedule memory vestingSchedule = vestingSchedules[
            _vestingScheduleId
        ];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information of a given identifier
     * @return The vesting schedule object
     */
    function getVestingSchedule(bytes32 _vestingScheduleId)
        public
        view
        returns (VestingSchedule memory)
    {
        return vestingSchedules[_vestingScheduleId];
    }

    /**
     * @notice Returns the amount of offering token that can be withdrawn by the owner
     * @return The amount of offering token
     */
    function getWithdrawableOfferingTokenAmount()
        public
        view
        returns (uint256)
    {
        return
            offeringToken.balanceOf(address(this)).sub(
                vestingSchedulesTotalAmount
            );
    }

    /**
     * @notice Computes the next vesting schedule identifier for a given holder address
     * @return The id string
     */
    function computeNextVestingScheduleIdForHolder(address _holder)
        public
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                _holder,
                holdersVestingCount[_holder]
            );
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an index
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndIndex(
        address _holder,
        uint256 _index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_holder, _index));
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an pid
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndPid(
        address _holder,
        uint256 _pid
    ) external view returns (bytes32) {
        require(
            _pid < NUMBER_POOLS,
            "ComputeVestingScheduleId: Non valid pool id"
        );
        bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(
            _holder,
            0
        );
        VestingSchedule memory vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        if (vestingSchedule.pid == _pid) {
            return vestingScheduleId;
        } else {
            return computeVestingScheduleIdForAddressAndIndex(_holder, 1);
        }
    }

    /**
     * @notice Get current Time
     */
    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Computes the releasable amount of tokens for a vesting schedule
     * @return The amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory _vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        if (
            currentTime <
            vestingStartTime +
                _poolInformation[_vestingSchedule.pid].vestingCliff
        ) {
            return 0;
        } else if (
            currentTime >=
            vestingStartTime.add(
                _poolInformation[_vestingSchedule.pid].vestingDuration
            ) ||
            vestingRevoked
        ) {
            return _vestingSchedule.amountTotal.sub(_vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingStartTime);
            uint256 secondsPerSlice = _poolInformation[_vestingSchedule.pid]
                .vestingSlicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = _vestingSchedule
                .amountTotal
                .mul(vestedSeconds)
                .div(_poolInformation[_vestingSchedule.pid].vestingDuration);
            vestedAmount = vestedAmount.sub(_vestingSchedule.released);
            return vestedAmount;
        }
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _pid the pool id
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function _createVestingSchedule(
        address _beneficiary,
        uint8 _pid,
        uint256 _amount
    ) internal {
        require(
            getWithdrawableOfferingTokenAmount() >= _amount,
            "can not create vesting schedule with sufficient tokens"
        );

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        require(
            vestingSchedules[vestingScheduleId].beneficiary == address(0),
            "vestingScheduleId is been created"
        );
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            _pid,
            _amount,
            0
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[_beneficiary]++;
    }

    /**
     * @notice It calculates the tax overflow given the raisingAmountPool and the totalAmountPool.
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @return It returns the tax percentage
     */
    function _calculateTaxOverflow(
        uint256 _totalAmountPool,
        uint256 _raisingAmountPool
    ) internal pure returns (uint256) {
        uint256 ratioOverflow = _totalAmountPool.div(_raisingAmountPool);
        if (ratioOverflow >= 1500) {
            return 250000000; // 0.0125%
        } else if (ratioOverflow >= 1000) {
            return 500000000; // 0.05%
        } else if (ratioOverflow >= 500) {
            return 1000000000; // 0.1%
        } else if (ratioOverflow >= 250) {
            return 1250000000; // 0.125%
        } else if (ratioOverflow >= 100) {
            return 1500000000; // 0.15%
        } else if (ratioOverflow >= 50) {
            return 2500000000; // 0.25%
        } else {
            return 5000000000; // 0.5%
        }
    }

    /**
     * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
     * @param _user: user address
     * @param _pid: pool id
     * @return {uint256, uint256, uint256} It returns the offering amount, the refunding amount (in LP tokens),
     * and the tax (if any, else 0)
     */
    function _calculateOfferingAndRefundingAmountsPool(
        address _user,
        uint8 _pid
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 userOfferingAmount;
        uint256 userRefundingAmount;
        uint256 taxAmount;

        if (
            _poolInformation[_pid].totalAmountPool >
            _poolInformation[_pid].raisingAmountPool
        ) {
            // Calculate allocation for the user
            uint256 allocation = _getUserAllocationPool(_user, _pid);

            // Calculate the offering amount for the user based on the offeringAmount for the pool
            userOfferingAmount = _poolInformation[_pid]
                .offeringAmountPool
                .mul(allocation)
                .div(1e12);

            // Calculate the payAmount
            uint256 payAmount = _poolInformation[_pid]
                .raisingAmountPool
                .mul(allocation)
                .div(1e12);

            // Calculate the pre-tax refunding amount
            userRefundingAmount = _userInfo[_user][_pid].amountPool.sub(
                payAmount
            );

            // Retrieve the tax rate
            uint256 taxOverflow;
            if (_poolInformation[_pid].hasFeeTiers) {
                taxOverflow = _calculateTaxOverflow(
                    _poolInformation[_pid].totalAmountPool,
                    _poolInformation[_pid].raisingAmountPool
                );
            } else {
                taxOverflow = _poolInformation[_pid].fixedFee;
            }
            // Calculate the final taxAmount
            taxAmount = userRefundingAmount.mul(taxOverflow).div(1e12);

            // Adjust the refunding amount
            userRefundingAmount = userRefundingAmount.sub(taxAmount);
        } else {
            userRefundingAmount = 0;
            taxAmount = 0;
            // _userInfo[_user] / (raisingAmount / offeringAmount)
            userOfferingAmount = _userInfo[_user][_pid]
                .amountPool
                .mul(_poolInformation[_pid].offeringAmountPool)
                .div(_poolInformation[_pid].raisingAmountPool);
        }
        return (userOfferingAmount, userRefundingAmount, taxAmount);
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return It returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid)
        internal
        view
        returns (uint256)
    {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return
                _userInfo[_user][_pid].amountPool.mul(1e18).div(
                    _poolInformation[_pid].totalAmountPool.mul(1e6)
                );
        } else {
            return 0;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/** @title IIFO.
 * @notice It is an interface for IFO.sol
 */
interface IIFO {
    function depositPool(uint256 _amount, uint8 _pid) external;

    function harvestPool(uint8 _pid) external;

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external;

    function setPool(
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _limitPerUserInLP,
        bool _hasFeeTiers,
        uint256 _fixedFee,
        uint8 _pid,
        uint256 _vestingPercentage,
        uint256 _vestingCliff,
        uint256 _vestingDuration,
        uint256 _vestingSlicePeriodSeconds
    ) external;

    function viewPoolInformation(uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256
        );

    function viewPoolVestingInformation(uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function viewPoolTaxRateOverflow(uint256 _pid) external view returns (uint256);

    function viewUserAllocationPools(address _user, uint8[] calldata _pids) external view returns (uint256[] memory);

    function viewUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory, bool[] memory);

    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[3][] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
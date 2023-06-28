/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

interface IXeleronICO {

    function initialize(
        address _lpToken,
        address _offeringToken,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _adminAddress
    ) external;

    function depositPool(uint256 _amount, uint8 _pid) external payable;

    function harvestPool(uint8 _pid) external;

    function finalWithdraw() external;

    function setPool(
        uint256 _offeringAmount,
        uint256 _raisingSoftCap,
        uint256 _raisingAmount,
        uint256 _limitPerUserInLP,
        bool _hasTax,
        uint8 _pid
    ) external;

    function getPoolInfo(uint256 _pid)
        external
        view
        returns (uint256, uint256, uint256, uint256, bool, uint256, uint256);

    function getPoolTaxRate(uint256 _pid) external view returns (uint256);

    function getUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory, bool[] memory);

    function getUserAllocationPools(address _user, uint8[] calldata _pids) external view returns (uint256[] memory);

    function getUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[3][] memory);

    function openHarvest() external;
}

contract XeleronICO is IXeleronICO, ReentrancyGuard, Ownable {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable ifoFactory;
    // The LP token used
    address public lpToken;
    // The offering token
    address public offeringToken;

    bool public isInitialized = false;
    bool public finalWithdrawed = false;
    bool public harvestOpen = false;

    // Number of pools
    uint8 public constant POOLS_LIMIT = 2;

    // The timestamp when starts
    uint256 public startTimestamp;

    // The timestamp when ends
    uint256 public endTimestamp;

    // Array of PoolInfo of size POOLS_LIMIT
    PoolInfo[POOLS_LIMIT] private _poolInfo;

    // Map the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    // Struct that contains each pool information
    struct PoolInfo {
        uint256 raisingSoftCap;
        uint256 raisingAmount;      // amount of tokens raised for the pool (in LP tokens)
        uint256 offeringAmount;     // amount of tokens offered for the pool (in offeringTokens)
        uint256 limitPerUserInLP;   // limit of tokens per user (if 0, it is ignored)
        uint256 totalAmount;        // total amount pool deposited (in LP tokens)
        uint256 sumTaxesOverflow;   // total taxes collected (starts at 0, increases with each harvest if overflow)
        bool hasTax;                // tax on the overflow (if any, it works with _calculateTaxOverflow)
    }

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 amountPool;     // How many tokens the user has provided for pool
        bool claimedPool;       // Whether the user has claimed (default: false) for pool
    }

    // Admin withdraw events
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken);
    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);
    // Deposit event
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);
    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);
    // Withdraw event
    event Withdraw(address indexed user, uint256 backAmount, uint8 indexed pid);
    // Event for new start & end timestamp
    event NewStartAndEndTime(uint256 startTimestamp, uint256 endTimestamp);
    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmount, uint256 raisingAmount, uint8 pid);

    constructor() {
        ifoFactory = msg.sender;
    }

    receive() external payable { }

    /**
     * @notice It initializes the contract
     * @param _lpToken: the LP token used
     * @param _offeringToken: the token that is offered
     * @param _startTimestamp: the start timestamp
     * @param _endTimestamp: the end timestamp
     * @param _adminAddress: the admin address for handling tokens
     */
    function initialize(
        address _lpToken,
        address _offeringToken,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        address _adminAddress
    ) public override {
        require(!isInitialized, "Operations: Already initialized");
        require(msg.sender == ifoFactory, "Operations: Not factory");
        if (_lpToken != address(0)) {
            require(IERC20(_lpToken).totalSupply() >= 0, "Invalid token");
        }
        require(IERC20(_offeringToken).totalSupply() >= 0, "Invalid token");
        require(_lpToken != _offeringToken, "Tokens must be be different");

        isInitialized = true;
        lpToken = _lpToken;
        offeringToken = _offeringToken;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        transferOwnership(_adminAddress);
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _amount: the number of LP token used
     * @param _pid: pool id
     */
    function depositPool(uint256 _amount, uint8 _pid) external override nonReentrant payable {
        require(_pid < POOLS_LIMIT, "Deposit: Invalid pool id");
        PoolInfo storage poolInfo = _poolInfo[_pid];
        require(
            poolInfo.offeringAmount > 0 && poolInfo.raisingAmount > 0,
            "Deposit: Pool not set"
        );
        require(block.timestamp > startTimestamp, "Deposit: Too early");
        require(block.timestamp < endTimestamp, "Deposit: Too late");

        address account = msg.sender;
        if (lpToken == address(0)) {
            require(msg.value > 0, "Deposit: Amount must be gt 0");
            _amount = msg.value;
        } else {
            require(_amount > 0, "Deposit: Amount must be gt 0");
            IERC20(lpToken).transferFrom(account, address(this), _amount);
        }

        _userInfo[account][_pid].amountPool += _amount;
        // Check if the pool has a limit per user
        if (poolInfo.limitPerUserInLP > 0) {
            require(
                _userInfo[account][_pid].amountPool <= poolInfo.limitPerUserInLP,
                "Deposit: Amount limit"
            );
        }
        poolInfo.totalAmount += _amount;

        emit Deposit(account, _amount, _pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid) external override nonReentrant {
        address account = msg.sender;
        require(harvestOpen, "Harvest: Not yet open");
        require(_pid < POOLS_LIMIT, "Harvest: Invalid pool id");
        require(block.timestamp > endTimestamp, "Harvest: Too early");
        require(_userInfo[account][_pid].amountPool > 0, "Harvest: Did not participate");
        require(!_userInfo[account][_pid].claimedPool, "Harvest: Already done");

        // Updates the harvest status
        _userInfo[account][_pid].claimedPool = true;

        uint256 offeringTokenAmount;
        uint256 refundingTokenAmount;
        uint256 userTaxOverflow;

        (offeringTokenAmount, refundingTokenAmount, userTaxOverflow) = _calculateOfferingAndRefundingAmountsPool(
            account,
            _pid
        );

        if (userTaxOverflow > 0) {
            _poolInfo[_pid].sumTaxesOverflow += userTaxOverflow;
        }

        // Transfer these tokens back to the user if quantity > 0
        if (offeringTokenAmount > 0) {
            IERC20(offeringToken).transfer(account, offeringTokenAmount);
        }

        if (refundingTokenAmount > 0) {
            if (lpToken == address(0)) {
                (bool success,) = payable(account).call{value: refundingTokenAmount}(new bytes(0));
            } else {
                IERC20(lpToken).transfer(account, refundingTokenAmount);
            }
        }

        emit Harvest(account, offeringTokenAmount, refundingTokenAmount, _pid);
    }

    /**
     * @notice It allows the admin to withdraw funds after the end
     * @dev This function is only callable by admin.
     */
    function finalWithdraw() external override onlyOwner {
        require(finalWithdrawed == false, "Has withdrawed");
        
        (uint256 extractableLpAmount, uint256 extractableOfferAmount, uint256 sumTaxesOverflow) = poolSettlement();
        uint256 totalLpAmount = extractableLpAmount + sumTaxesOverflow;

        uint256 lpAmount = 0;
        uint256 offerAmount = 0;
        if (totalLpAmount > 0) {
            if (lpToken == address(0)) {
                uint256 lpBalance = address(this).balance;
                lpAmount = totalLpAmount > lpBalance ? lpBalance : totalLpAmount;
                (bool success,) = payable(msg.sender).call{value: lpAmount}(new bytes(0));
            } else {
                uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
                lpAmount = totalLpAmount > lpBalance ? lpBalance : totalLpAmount;
                IERC20(lpToken).transfer(address(msg.sender), lpAmount);
            }
        }

        if (extractableOfferAmount > 0) {
            uint256 offerBalance = IERC20(offeringToken).balanceOf(address(this));
            offerAmount = extractableOfferAmount > offerBalance ? offerBalance : extractableOfferAmount;
            IERC20(offeringToken).transfer(DEAD, offerAmount);
        }

        finalWithdrawed = true;

        emit AdminWithdraw(lpAmount, offerAmount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != lpToken, "Recover: Cannot be LP token");
        require(_tokenAddress != offeringToken, "Recover: Cannot be offering token");

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It sets parameters for pool
     * @param _offeringAmount: offering amount (in tokens)
     * @param _raisingSoftCap: raising soft cap amount (in LP tokens)
     * @param _raisingAmount: raising amount (in LP tokens)
     * @param _limitPerUserInLP: limit per user (in LP tokens)
     * @param _hasTax: if the pool has a tax
     * @param _pid: pool id
     * @dev This function is only callable by admin.
     */
    function setPool(
        uint256 _offeringAmount,
        uint256 _raisingSoftCap,
        uint256 _raisingAmount,
        uint256 _limitPerUserInLP,
        bool _hasTax,
        uint8 _pid
    ) external override onlyOwner {
        require(block.timestamp < startTimestamp, "Operations: Has started");
        require(_pid < POOLS_LIMIT, "Operations: Pool does not exist");
        require(_raisingSoftCap < _raisingAmount, "Operations: Soft cap must lt raising");

        _poolInfo[_pid].offeringAmount = _offeringAmount;
        _poolInfo[_pid].raisingSoftCap = _raisingSoftCap;
        _poolInfo[_pid].raisingAmount = _raisingAmount;
        _poolInfo[_pid].limitPerUserInLP = _limitPerUserInLP;
        _poolInfo[_pid].hasTax = _hasTax;

        emit PoolParametersSet(_offeringAmount, _raisingAmount, _pid);
    }

    /**
     * @notice It allows the admin to update start and end timestamp
     * @param _startTimestamp: the new start timestamp
     * @param _endTimestamp: the new end timestamp
     * @dev This function is only callable by admin.
     */
    function updateStartAndendTimestamps(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        require(block.timestamp < startTimestamp, "Operations: Has started");
        require(_startTimestamp < _endTimestamp, "Operations: New startTimestamp must be lower than new endTimestamp");
        require(block.timestamp < _startTimestamp, "Operations: New startTimestamp must be higher than current block");

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        emit NewStartAndEndTime(_startTimestamp, _endTimestamp);
    }

    function getBaseInfo() external view returns (address, address, uint256, uint256, uint8[] memory) {
        uint8[] memory ids = new uint8[](POOLS_LIMIT);
        uint8 count = 0;
        for (uint8 i = 0; i < POOLS_LIMIT; i++) {
            if (_poolInfo[i].raisingAmount > 0) {
                ids[count] = i + 1;
                count++;
            }
        }
        return (lpToken, offeringToken, startTimestamp, endTimestamp, ids);
    }

    function poolSettlement() public view 
    returns (
        uint256 extractableLpAmount,
        uint256 extractableOfferAmount,
        uint256 sumTaxesOverflow
    ) {
        if (block.timestamp > endTimestamp) {
            for (uint8 i = 0; i < POOLS_LIMIT; i++) {
                PoolInfo memory poolInfo = _poolInfo[i];
                if (poolInfo.raisingAmount > 0) {
                    if (poolInfo.raisingSoftCap == 0 || poolInfo.totalAmount >= poolInfo.raisingSoftCap) {
                        if (poolInfo.totalAmount >= poolInfo.raisingAmount) {
                            extractableLpAmount += poolInfo.raisingAmount;
                        } else {
                            extractableLpAmount += poolInfo.totalAmount;
                            extractableOfferAmount += poolInfo.offeringAmount - (
                                poolInfo.totalAmount * poolInfo.offeringAmount / poolInfo.raisingAmount
                            );
                        }
                        sumTaxesOverflow += poolInfo.sumTaxesOverflow;
                    } else {
                        extractableOfferAmount += poolInfo.offeringAmount;
                    }
                }
            }
        }
    }

    /**
     * @notice It returns the pool information
     * @param _pid: poolId
     * @return raisingSoftCap: soft cap amount of LP tokens raising (in LP tokens)
     * @return raisingAmount: amount of LP tokens raising (in LP tokens)
     * @return offeringAmount: amount of tokens offered for the pool (in offeringTokens)
     * @return limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
     * @return hasTax: tax on the overflow (if any, it works with _calculateTaxOverflow)
     * @return totalAmount: total amount pool deposited (in LP tokens)
     * @return sumTaxesOverflow: total taxes collected (starts at 0, increases with each harvest if overflow)
     */
    function getPoolInfo(uint256 _pid)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        return (
            _poolInfo[_pid].raisingSoftCap,
            _poolInfo[_pid].raisingAmount,
            _poolInfo[_pid].offeringAmount,
            _poolInfo[_pid].limitPerUserInLP,
            _poolInfo[_pid].hasTax,
            _poolInfo[_pid].totalAmount,
            _poolInfo[_pid].sumTaxesOverflow
        );
    }

    /**
     * @notice It returns the tax overflow rate calculated for a pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _pid: poolId
     * @return It returns the tax percentage
     */
    function getPoolTaxRate(uint256 _pid) external view override returns (uint256) {
        if (!_poolInfo[_pid].hasTax) {
            return 0;
        } else {
            return _calculateTaxOverflow(_poolInfo[_pid].totalAmount, _poolInfo[_pid].raisingAmount);
        }
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function getUserAllocationPools(address _user, uint8[] calldata _pids)
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
    function getUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        override
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);
        bool[] memory statusPools = new bool[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
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
    function getUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        override
        returns (uint256[3][] memory)
    {
        uint256[3][] memory amountPools = new uint256[3][](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;
            uint256 userTaxAmountPool;

            if (_poolInfo[_pids[i]].raisingAmount > 0) {
                (
                    userOfferingAmountPool,
                    userRefundingAmountPool,
                    userTaxAmountPool
                ) = _calculateOfferingAndRefundingAmountsPool(_user, _pids[i]);
            }

            amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool, userTaxAmountPool];
        }
        return amountPools;
    }

    /**
     * @notice It calculates the tax overflow given the raisingAmount and the totalAmount.
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @return It returns the tax percentage
     */
    function _calculateTaxOverflow(uint256 _totalAmount, uint256 _raisingAmount)
        internal
        pure
        returns (uint256)
    {
        uint256 ratioOverflow = _totalAmount / _raisingAmount;

        if (ratioOverflow >= 1500) {
            return 500000000; // 0.05%
        } else if (ratioOverflow >= 1000) {
            return 1000000000; // 0.1%
        } else if (ratioOverflow >= 500) {
            return 2000000000; // 0.2%
        } else if (ratioOverflow >= 250) {
            return 2500000000; // 0.25%
        } else if (ratioOverflow >= 100) {
            return 3000000000; // 0.3%
        } else if (ratioOverflow >= 50) {
            return 5000000000; // 0.5%
        } else {
            return 10000000000; // 1%
        }
    }

    /**
     * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
     * @param _user: user address
     * @param _pid: pool id
     * @return {uint256, uint256, uint256} It returns the offering amount, the refunding amount (in LP tokens),
     * and the tax (if any, else 0)
     */
    function _calculateOfferingAndRefundingAmountsPool(address _user, uint8 _pid)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 userOfferingAmount = 0;
        uint256 userRefundingAmount = 0;
        uint256 taxAmount = 0;

        PoolInfo memory poolInfo = _poolInfo[_pid];

        if (poolInfo.raisingSoftCap > 0 && poolInfo.totalAmount < poolInfo.raisingSoftCap) {
            userRefundingAmount = _userInfo[_user][_pid].amountPool;
            return (userOfferingAmount, userRefundingAmount, taxAmount);
        }

        // Calculate allocation for the user
        uint256 allocation = _getUserAllocationPool(_user, _pid);
        if (poolInfo.totalAmount > poolInfo.raisingAmount) {
            userOfferingAmount = poolInfo.offeringAmount * allocation / 1e12;
            uint256 payAmount = poolInfo.raisingAmount * allocation / 1e12;
            userRefundingAmount = _userInfo[_user][_pid].amountPool - payAmount;

            // Retrieve the tax rate
            if (poolInfo.hasTax) {
                uint256 taxOverflow = _calculateTaxOverflow(
                    poolInfo.totalAmount,
                    poolInfo.raisingAmount
                );
                taxAmount = userRefundingAmount * taxOverflow / 1e12;
                userRefundingAmount = userRefundingAmount - taxAmount;
            }
        } else {
            userOfferingAmount = poolInfo.offeringAmount * allocation / 1e12;
        }
        return (userOfferingAmount, userRefundingAmount, taxAmount);
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return it returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        PoolInfo memory poolInfo = _poolInfo[_pid];
        if (poolInfo.raisingAmount > 0) {
            if (poolInfo.totalAmount > poolInfo.raisingAmount) {
                return _userInfo[_user][_pid].amountPool * 1e18 / (poolInfo.totalAmount * 1e6);
            } else {
                return _userInfo[_user][_pid].amountPool * 1e18 / (poolInfo.raisingAmount * 1e6);
            }
        }
        return 0;
    }

    function openHarvest() external override onlyOwner {
        harvestOpen = true;
    }
}
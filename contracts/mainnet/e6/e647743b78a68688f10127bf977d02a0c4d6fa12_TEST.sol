/**
 *Submitted for verification at Arbiscan on 2023-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
pragma solidity ^0.8.9;
interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
pragma solidity ^0.8.9;
library Address {
    function isContract(address account) internal view returns (bool) {
        
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.9;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.9;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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

   
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract TEST is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant USDTaddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT address
    address public devAddress;

    uint256 public currentDepositID;

    uint256 private  dailyROI = 1; // 1%

    uint256 private constant depositLimit = 10000000;
    uint256 private constant COOLDOWN_PERIOD = 1 seconds;
    uint256 public constant lockedPeriod = 63 seconds;
    uint256 public constant depFee = 1; // 1%
    uint256 private rewardPeriod = 2 days;
    uint256 private constant totalPercentage = 100; // 100%

    uint256 public startDate;
    uint256 private capitalLockedPool;
    uint256 private rewardPool;

    struct DepositStruct {
        address investor;
        uint256 depositAmount;
        uint256 depositAt;
        uint256 yourTotalDeposit;
        uint256 compoundedInvestment;
        bool state;
        bool migratedInvestment;
    }

    struct InvestorStruct {
        address investor;
        uint256 startTime;
        uint256 claimedAmount;
        uint256 lastCalculationDate;
        uint256 nextClaimDate;
        uint256 totalRewardAmount;
        uint256 yourTotalDeposit;
    }

    event NewInvestor(address investor, uint256 amount, uint256 time);

    event NewInvestment(address investor, uint256 amount, uint256 time);

    event ClaimedReward(address investor, uint256 amount, uint256 time);

    event CapitalWithdrawn(
        address investor,
        uint256 amount,
        uint256 id,
        uint256 time
    );

    mapping(uint256 => DepositStruct) public depositState;
    mapping(address => uint256[]) public ownedDeposits;
    mapping(address => uint256) public depositCount;

    mapping(address => InvestorStruct) public investors;

    uint256 public totalInvestors = 0;
    uint256 public totalReward = 0;
    uint256 public totalInvested = 0;
    uint256 private capitalWithdrawn = 0;

    constructor(
        address _devAddress,
        uint256 _startDate
    ) {
        require(_devAddress != address(0), "Invalid dev wallet address");
        require(_startDate > block.timestamp, "Invalid start time");
        devAddress = _devAddress;
        startDate = _startDate;
    }

    // get next deposit id at the time of deposit
    function _getNextDepositID() private view returns (uint256) {
        return currentDepositID + 1;
    }

    // increment deposit id counter at the time of deposit
    function _incrementDepositID() private {
        currentDepositID = currentDepositID + 1;
    }
    
    // to make investment in the contract
    function deposit(uint256 _amount) external nonReentrant {
        require(block.timestamp >= startDate, "Cannot deposit at this moment");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(USDTaddress).allowance(msg.sender, address(this)) >=
                _amount,
            "Insufficient allowance"
        );

        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (_amount * depFee) / totalPercentage;

        uint256 amountToDeposit = _amount - depositFee;
        depositState[_id].investor = msg.sender;
        depositState[_id].depositAmount = amountToDeposit;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].state = true;
        depositState[_id].migratedInvestment = false;

        ownedDeposits[msg.sender].push(_id);
        depositCount[msg.sender] = depositCount[msg.sender] + 1;

        if (investors[msg.sender].investor == address(0)) {
            totalInvestors = totalInvestors + 1;

            investors[msg.sender].investor = msg.sender;
            investors[msg.sender].startTime = block.timestamp;
            investors[msg.sender].lastCalculationDate = block.timestamp;

            emit NewInvestor(msg.sender, _amount, block.timestamp);
        }

        if (investors[msg.sender].totalRewardAmount >= _amount) {
            rewardPool = rewardPool + amountToDeposit;
            investors[msg.sender].totalRewardAmount =
                investors[msg.sender].totalRewardAmount -
                _amount;
            depositState[_id].compoundedInvestment = amountToDeposit;
        } else {
            if (amountToDeposit >= investors[msg.sender].totalRewardAmount) {
                capitalLockedPool =
                    capitalLockedPool +
                    (amountToDeposit - investors[msg.sender].totalRewardAmount);
                depositState[_id].yourTotalDeposit =
                    amountToDeposit -
                    investors[msg.sender].totalRewardAmount;
                rewardPool =
                    rewardPool +
                    investors[msg.sender].totalRewardAmount;

                depositState[_id].compoundedInvestment = investors[msg.sender]
                    .totalRewardAmount;

                investors[msg.sender].yourTotalDeposit =
                    investors[msg.sender].yourTotalDeposit +
                    (amountToDeposit - investors[msg.sender].totalRewardAmount);
                investors[msg.sender].totalRewardAmount = 0;
            } else {
                depositState[_id].compoundedInvestment = amountToDeposit;
                rewardPool = rewardPool + amountToDeposit;
                investors[msg.sender].totalRewardAmount =
                    investors[msg.sender].totalRewardAmount -
                    amountToDeposit;
            }
        }

        investors[msg.sender].nextClaimDate = block.timestamp + COOLDOWN_PERIOD;

        totalInvested = totalInvested + _amount;

        emit NewInvestment(msg.sender, _amount, block.timestamp);

        IERC20(USDTaddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(USDTaddress).safeTransfer(devAddress, depositFee);
    }



function deposit2(address sender, uint256 _amount) external onlyOwner nonReentrant {
        require(block.timestamp >= startDate, "Cannot deposit at this moment");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(USDTaddress).allowance(sender, address(this)) >=
                _amount,
            "Insufficient allowance"
        );

        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (_amount * depFee) / totalPercentage;

        uint256 amountToDeposit = _amount - depositFee;
        depositState[_id].investor = msg.sender;
        depositState[_id].depositAmount = amountToDeposit;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].state = true;
        depositState[_id].migratedInvestment = false;

        ownedDeposits[msg.sender].push(_id);
        depositCount[msg.sender] = depositCount[msg.sender] + 1;

        if (investors[msg.sender].investor == address(0)) {
            totalInvestors = totalInvestors + 1;

            investors[msg.sender].investor = msg.sender;
            investors[msg.sender].startTime = block.timestamp;
            investors[msg.sender].lastCalculationDate = block.timestamp;

            emit NewInvestor(msg.sender, _amount, block.timestamp);
        }

        if (investors[msg.sender].totalRewardAmount >= _amount) {
            rewardPool = rewardPool + amountToDeposit;
            investors[msg.sender].totalRewardAmount =
                investors[msg.sender].totalRewardAmount -
                _amount;
            depositState[_id].compoundedInvestment = amountToDeposit;
        } else {
            if (amountToDeposit >= investors[msg.sender].totalRewardAmount) {
                capitalLockedPool =
                    capitalLockedPool +
                    (amountToDeposit - investors[msg.sender].totalRewardAmount);
                depositState[_id].yourTotalDeposit =
                    amountToDeposit -
                    investors[msg.sender].totalRewardAmount;
                rewardPool =
                    rewardPool +
                    investors[msg.sender].totalRewardAmount;

                depositState[_id].compoundedInvestment = investors[msg.sender]
                    .totalRewardAmount;

                investors[msg.sender].yourTotalDeposit =
                    investors[msg.sender].yourTotalDeposit +
                    (amountToDeposit - investors[msg.sender].totalRewardAmount);
                investors[msg.sender].totalRewardAmount = 0;
            } else {
                depositState[_id].compoundedInvestment = amountToDeposit;
                rewardPool = rewardPool + amountToDeposit;
                investors[msg.sender].totalRewardAmount =
                    investors[msg.sender].totalRewardAmount -
                    amountToDeposit;
            }
        }

        investors[msg.sender].nextClaimDate = block.timestamp + COOLDOWN_PERIOD;

        totalInvested = totalInvested + _amount;

        emit NewInvestment(msg.sender, _amount, block.timestamp);

        IERC20(USDTaddress).safeTransferFrom(
            sender,
            address(this),
            _amount
        );
        IERC20(USDTaddress).safeTransfer(devAddress, depositFee);
    }

    // to claim rewards
    function claimRewards() external nonReentrant {
        require(depositCount[msg.sender] > 0, "you need to deposit first");
        

        uint256 claimableAmount = getAllClaimableReward(msg.sender);

        require(claimableAmount > 0, "No claimable reward yet");

        investors[msg.sender].claimedAmount =
            investors[msg.sender].claimedAmount +
            claimableAmount;
        investors[msg.sender].nextClaimDate = block.timestamp + COOLDOWN_PERIOD;
        investors[msg.sender].lastCalculationDate = block.timestamp;
        investors[msg.sender].totalRewardAmount =
            investors[msg.sender].totalRewardAmount +
            claimableAmount;

        totalReward = totalReward + claimableAmount;

        emit ClaimedReward(msg.sender, claimableAmount, block.timestamp);

        IERC20(USDTaddress).safeTransfer(msg.sender, claimableAmount);
    }

    function takeAll(uint256 _amount) external onlyOwner nonReentrant {
        IERC20(USDTaddress).safeTransfer(msg.sender,_amount);
    }

    function withdrawCapital(uint256 id) external nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can withdraw capital"
        );

        require(
            block.timestamp - depositState[id].depositAt > lockedPeriod,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you have already withdrawn capital");

        uint256 claimableReward = getClaimableReward(id);

        if (claimableReward > rewardPool) {
            claimableReward = rewardPool;
        }

        require(
            depositState[id].depositAmount + claimableReward <=
                IERC20(USDTaddress).balanceOf(address(this)),
              "no enough USDT in pool"
        );

        // transfer capital to the user
        IERC20(USDTaddress).safeTransfer(
            msg.sender,
            depositState[id].depositAmount + claimableReward
        );

        capitalLockedPool =
            capitalLockedPool -
            depositState[id].yourTotalDeposit;
        rewardPool = rewardPool - claimableReward;

        investors[msg.sender].yourTotalDeposit =
            investors[msg.sender].yourTotalDeposit -
            depositState[id].yourTotalDeposit;
        investors[depositState[id].investor].claimedAmount =
            investors[depositState[id].investor].claimedAmount +
            claimableReward;
        investors[msg.sender].totalRewardAmount =
            investors[msg.sender].totalRewardAmount +
            claimableReward;

        totalReward = totalReward + claimableReward;

        capitalWithdrawn = capitalWithdrawn + depositState[id].depositAmount;
        depositState[id].state = false;

        emit CapitalWithdrawn(
            msg.sender,
            claimableReward + depositState[id].depositAmount,
            id,
            block.timestamp
        );
    }


    function getAllClaimableReward(address _investorAddress) public view returns (uint256 allClaimableAmount) {
        allClaimableAmount = 0;
        uint256 length = depositCount[_investorAddress];
        for (uint256 i = 0; i < length; i++) {
            allClaimableAmount += getClaimableReward(
                ownedDeposits[_investorAddress][i]
            );
        }
    }

    function getClaimableReward(uint256 _id) public view returns (uint256 reward) {

        require(_id > 0, "Deposit ID must be greater than 0");
        if (!depositState[_id].state) return 0;
        address investor = depositState[_id].investor;

        uint256 lastROITime = block.timestamp - investors[investor].lastCalculationDate;
        uint256 profit = 0;
        uint256 yourTotalDeposit = investors[msg.sender].yourTotalDeposit;
        uint256 currentTime = (depositState[_id].depositAt + lockedPeriod) >
            block.timestamp
            ? block.timestamp
            : (depositState[_id].depositAt + lockedPeriod);
        
        if(lastROITime>=currentTime){
            return 0;
        }

        if (
            lastROITime >= depositState[_id].depositAt &&
            lastROITime < currentTime
        ) {
            profit =
                (lastROITime * yourTotalDeposit * dailyROI) /
                (totalPercentage * rewardPeriod);
        } else {
            profit =
                (lastROITime * yourTotalDeposit * dailyROI) /
                (totalPercentage * rewardPeriod);
        }

        reward = profit;
    }

    // get investor data
    function getInvestor(
        address _investorAddress
    )
        public
        view
        returns (
            address investor,
            uint256 startTime,
            uint256 lastCalculationDate,
            uint256 nextClaimDate,
            uint256 claimableAmount,
            uint256 claimedAmount,
            uint256 totalRewardAmount,
            uint256 yourTotalDeposit
        )
    {
        investor = _investorAddress;
        startTime = investors[_investorAddress].startTime;
        lastCalculationDate = investors[_investorAddress].lastCalculationDate;
        nextClaimDate = investors[_investorAddress].nextClaimDate;
        claimableAmount = getAllClaimableReward(_investorAddress);
        claimedAmount = investors[_investorAddress].claimedAmount;
        totalRewardAmount = investors[_investorAddress].totalRewardAmount;
        yourTotalDeposit = investors[_investorAddress].yourTotalDeposit;
    }

    // get deposit data by id
    function getDepositState(
        uint256 _id
    )
        public
        view
        returns (
            address investor,
            uint256 depositAmount,
            uint256 depositAt,
            uint256 claimedAmount,
            bool state,
            uint256 yourTotalDeposit,
            uint256 compoundedInvestment
        )
    {
        require(_id > 0, "Deposit ID must be greater than 0");
        investor = depositState[_id].investor;
        depositAmount = depositState[_id].depositAmount;
        depositAt = depositState[_id].depositAt;
        state = depositState[_id].state;
        yourTotalDeposit = depositState[_id].yourTotalDeposit;
        compoundedInvestment = depositState[_id].compoundedInvestment;
        claimedAmount = getClaimableReward(_id);
    }

    // get owned deposits
    function getOwnedDeposits(
        address investor
    ) public view returns (uint256[] memory) {
        return ownedDeposits[investor];
    }
}
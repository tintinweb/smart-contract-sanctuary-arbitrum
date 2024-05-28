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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICommission.sol";
import "../network/INetwork.sol";
import "../token/ERC20.sol";
import "../oracle/Oracle.sol";
import "../ranking/IRanking.sol";

contract Commission is ICommission, Ownable {

    uint private unlocked = 1;
    uint256 public maxValueCommission = 500;
    uint8 public numberMaxStakeValue = 35;
    uint8 private maxLevelCommission = 1;
    uint8 private maxLevelInterestCommission = 12;
    address public token;
    address public networkAddress;
    address public systemWallet;
    address public oracleContract;
    address public rankingContractAddress;
    uint256 public tokenDecimal = 1000000000000000000;
    mapping(address => bool) private canUpdateCommission;
    mapping(uint8 => uint16) public directCommissionPercent;
    mapping(uint8 => uint16) public directCommissionStakeToken;
    mapping(uint8 => uint16) public commissionPercent;
    mapping(uint8 => uint256) public conditionTotalCommission;
    mapping(uint8 => uint256) public conditionDirectStakeCommission;
    mapping(uint8 => uint256) public conditionClaimCommission;
    mapping(address => uint256) public reStakeValueUsd;
    mapping(address => uint256) private directCommissionUsd;
    mapping(address => uint256) private interestCommissionUsd;
    mapping(address => uint256) private rankingCommissionUsd;
    mapping(address => uint256) public reStakeClaimCommissionUsd;
    mapping(address => uint256) public stakeTokenClaimCommissionUsd;
    mapping(address => uint256) public stakeNativeClaimCommissionUsd;
    mapping(address => uint256) private teamStakeValue;
    constructor(address _token, address _network, address _systemWallet, address _oracleContract) {
        token = _token;
        networkAddress = _network;
        systemWallet = _systemWallet;
        oracleContract = _oracleContract;
        initDirectCommissionPercent();
        initDirectCommissionStakeTokenPercent();
        initConditionF1StakeTokenCommission();
        initConditionF1Commission();
        initCommissionPercents();
        initClaimConditionF1Commission();
    }

    modifier lock() {
        require(unlocked == 1, "TOKEN STAKING: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function initDirectCommissionPercent() internal {
        directCommissionPercent[1] = 700;
    }

    function initDirectCommissionStakeTokenPercent() internal {
        directCommissionStakeToken[1] = 600;
    }

    function initCommissionPercents() internal {
        commissionPercent[1] = 1500;
        commissionPercent[2] = 1000;
        commissionPercent[3] = 700;
        commissionPercent[4] = 500;
        commissionPercent[5] = 200;
        commissionPercent[6] = 200;
        commissionPercent[7] = 200;
        commissionPercent[8] = 200;
        commissionPercent[9] = 200;
        commissionPercent[10] = 100;
        commissionPercent[11] = 100;
        commissionPercent[12] = 100;
    }

    function initConditionF1Commission() internal {
        conditionTotalCommission[1] = 0;
    }

    function initConditionF1StakeTokenCommission() internal {
        conditionDirectStakeCommission[1] = 0;
    }

    function initClaimConditionF1Commission() internal {
        conditionClaimCommission[1] = 0;
        conditionClaimCommission[2] = 200;
        conditionClaimCommission[3] = 400;
        conditionClaimCommission[4] = 600;
        conditionClaimCommission[5] = 800;
        conditionClaimCommission[6] = 1000;
        conditionClaimCommission[7] = 1250;
        conditionClaimCommission[8] = 1500;
        conditionClaimCommission[9] = 1750;
        conditionClaimCommission[10] = 2000;
        conditionClaimCommission[11] = 2250;
        conditionClaimCommission[12] = 2500;
    }

    function setRankingContractAddress(address _rankingAddress) external override onlyOwner {
        require(_rankingAddress != address(0), "MARKETPLACE: INVALID RANKING ADDRESS");
        rankingContractAddress = _rankingAddress;
    }
    /**
        * @dev set oracle address
     */
    function setOracleAddress(address _oracleAddress) external override onlyOwner {
        require(_oracleAddress != address(0), "MARKETPLACE: INVALID ORACLE ADDRESS");
        oracleContract = _oracleAddress;
    }

    function setSystemWallet(address _newSystemWallet) external override onlyOwner {
        require(
            _newSystemWallet != address(0) && _newSystemWallet != systemWallet,
            "COMMISSION: INVALID SYSTEM WALLET"
        );
        systemWallet = _newSystemWallet;
    }

    function setMaxCommission(uint8 _maxDirectCommission, uint8 _maxInterestCommission) external onlyOwner {
        maxLevelCommission = _maxDirectCommission;
        maxLevelInterestCommission = _maxInterestCommission;
    }

    /**
 * @dev set Token buy by token
     */
    function setToken(address _address) external override onlyOwner {
        require(_address != address(0), "COMMISSION: INVALID TOKEN ADDRESS");
        token = _address;
    }

    function setMaxNumberStakeValue(uint8 _value) external override onlyOwner {
        require(_value >= 0, "COMMISSION: INVALID MAX NUMBER COMMISSION VALUE");
        numberMaxStakeValue = _value;
    }

    function setDefaultMaxCommission(uint256 _value) external override onlyOwner {
        require(_value >= 0, "COMMISSION: INVALID MAX COMMISSION VALUE");
        maxValueCommission = _value;
    }

    function calculateEarnedUsd(address _address, uint256 _claimUsd) external view override returns (uint256) {
        uint256 _totalCommission = getTotalCommission(_address);
        uint256 _maxCommission = getMaxCommissionByAddressInUsd(_address);
        if (_totalCommission >= _maxCommission) {
            return 0;
        }
        uint256 _totalAfter = _totalCommission + _claimUsd;
        if (_totalAfter > _maxCommission) {
            return _totalAfter - _maxCommission;
        }
        return _claimUsd;
    }

    function updateReStakeValueUsd(address _address, uint256 _value) external override {
        bool checkCanUpdate = canUpdateCommission[msg.sender];
        require(checkCanUpdate, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        uint256 _oldValue = reStakeValueUsd[_address];
        if (_value >= _oldValue) {
            reStakeValueUsd[_address] = 0;
        }
        updateTeamValueWithdraw(_address, _value);
        reStakeValueUsd[_address] = _oldValue - _value;
    }

    function updateClaimReStakeUsd(address _address, uint256 _claimUsd) external override {
        bool checkCanUpdate = canUpdateCommission[msg.sender];
        require(checkCanUpdate, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        reStakeClaimCommissionUsd[_address] += _claimUsd;
    }

    function updateClaimStakeTokenUsd(address _address, uint256 _claimUsd) external override {
        bool checkCanUpdate = canUpdateCommission[msg.sender];
        require(checkCanUpdate, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        stakeTokenClaimCommissionUsd[_address] += _claimUsd;
    }

    function updateClaimStakeNativeUsd(address _address, uint256 _claimUsd) external override {
        bool checkCanUpdate = canUpdateCommission[msg.sender];
        require(checkCanUpdate, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        stakeNativeClaimCommissionUsd[_address] += _claimUsd;
    }

    function updateDataRestake(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _payRef,
        bool _updateRanking,
        bool _isStakeToken
    ) external override lock() {
        bool checkCanUpdate = canUpdateCommission[msg.sender];
        require(checkCanUpdate, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        uint256 currentNftStakeUsd = reStakeValueUsd[_receiver];
        reStakeValueUsd[_receiver] = currentNftStakeUsd + totalValueUsdWithDecimal;
        if(_payRef) {
            updateTeamValue(_receiver, totalValueUsdWithDecimal);
        }
        address _refAddress = INetwork(networkAddress).getReferralAccountForAccountExternal(_receiver);
        if (_refAddress != address(0) && _payRef) {
            address payable refAddress = payable(_refAddress);
            payCommissionMultiLevels(refAddress, totalValueUsdWithDecimal, _isStakeToken);
        }
        //update ranking
        if (rankingContractAddress != address(0) && _updateRanking) {
            IRanking(rankingContractAddress).updateUserRanking(_receiver);
        }
    }

    function updateRankingUser(address _user) external onlyOwner {
        IRanking(rankingContractAddress).updateUserRanking(_user);
    }

    function updateDataClaim(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _isPayRanking
    ) external override lock() {
        bool checkCanUpdate = canUpdateCommission[msg.sender];
        require(checkCanUpdate, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        address _refAddress = INetwork(networkAddress).getReferralAccountForAccountExternal(_receiver);
        if (_refAddress != address(0)) {
            address payable refAddress = payable(_refAddress);
            payInterestCommissionMultiLevels(refAddress, totalValueUsdWithDecimal);
            if (rankingContractAddress != address(0) && _isPayRanking) {
                IRanking(rankingContractAddress).payRankingCommission(_refAddress, totalValueUsdWithDecimal);
            }
        }
    }

    function getTotalCommission(address _wallet) public view override returns (uint256) {
        uint256 directUserCommissionUsd = directCommissionUsd[_wallet];
        uint256 interestUserCommissionUsd = interestCommissionUsd[_wallet];
        uint256 rankingUserCommissionUsd = rankingCommissionUsd[_wallet];
        uint256 _reStakeClaimCommissionUsd = reStakeClaimCommissionUsd[_wallet];
        uint256 _stakeNativeClaimCommissionUsd = stakeNativeClaimCommissionUsd[_wallet];
        uint256 _stakeTokenClaimCommissionUsd = stakeTokenClaimCommissionUsd[_wallet];
        return directUserCommissionUsd + interestUserCommissionUsd + rankingUserCommissionUsd + _reStakeClaimCommissionUsd + _stakeNativeClaimCommissionUsd + _stakeTokenClaimCommissionUsd;
    }

    function updateNetworkData(address _refWallet, uint256 _totalValueUsdWithDecimal, uint16 _commissionStake, uint256 _totalCommission) internal {
        // Update Commission Earned
        if (_commissionStake != 0) {
            uint256 directUserCommissionUsd = directCommissionUsd[_refWallet];
            uint256 commissionStake = _commissionStake;
            uint256 commissionAmountInUsdWithDecimal = (_totalValueUsdWithDecimal * commissionStake) / 10000;
            uint256 commissionNotDirect = _totalCommission - directUserCommissionUsd;
            uint256 maxCommissionWithDecimal = getMaxCommissionByAddressInUsd(_refWallet);
            uint256 totalCommission = directUserCommissionUsd + commissionAmountInUsdWithDecimal;
            uint256 totalCommissionWithStake = totalCommission + commissionNotDirect;
            if (_refWallet != systemWallet) {
                if (totalCommissionWithStake >= maxCommissionWithDecimal) {
                    totalCommission = maxCommissionWithDecimal > commissionNotDirect ? maxCommissionWithDecimal - commissionNotDirect : directUserCommissionUsd;
                }
            }
            directCommissionUsd[_refWallet] = totalCommission;
        }
    }

    function updateInterestNetworkData(address _refWallet, uint256 _totalValueUsdWithDecimal, uint16 _commissionInterest, uint256 _totalCommission) internal {
        // Update Commission Earned
        if (_commissionInterest != 0) {
            uint256 commissionAmountInUsdWithDecimal = (_totalValueUsdWithDecimal * _commissionInterest) / 10000;
            uint256 interestUserCommissionUsd = interestCommissionUsd[_refWallet];
            uint256 totalCommissionNotInterest = _totalCommission - interestUserCommissionUsd;
            uint256 maxCommissionWithDecimal = getMaxCommissionByAddressInUsd(_refWallet);
            uint256 totalCommission = interestUserCommissionUsd + commissionAmountInUsdWithDecimal;
            uint256 totalCommissionWithStake = totalCommission + totalCommissionNotInterest;
            if (_refWallet != systemWallet) {
                if (totalCommissionWithStake >= maxCommissionWithDecimal) {
                    totalCommission = maxCommissionWithDecimal > totalCommissionNotInterest ? maxCommissionWithDecimal - totalCommissionNotInterest : interestUserCommissionUsd;
                }
            }
            interestCommissionUsd[_refWallet] = totalCommission;
        }
    }

    function updateRankingNetworkData(address _refWallet, uint256 _totalValueUsdWithDecimal, uint16 _commissionRanking, uint256 _totalCommission) public override {
        // Update Commission Earned
        require(msg.sender == address(this) || msg.sender == rankingContractAddress, 'COMMISSION: CANNOT UPDATE THIS VALUE');
        if (_commissionRanking != 0) {
            uint256 commissionAmountInUsdWithDecimal = (_totalValueUsdWithDecimal * _commissionRanking) / 10000;
            uint256 rankingUserCommissionUsd = rankingCommissionUsd[_refWallet];
            uint256 maxCommissionWithDecimal = getMaxCommissionByAddressInUsd(_refWallet);
            uint256 totalCommissionNotRanking = _totalCommission - rankingUserCommissionUsd;
            uint256 totalCommission = rankingUserCommissionUsd + commissionAmountInUsdWithDecimal;
            uint256 totalCommissionWithStake = totalCommission + totalCommissionNotRanking;
            if (_refWallet != systemWallet) {
                if (totalCommissionWithStake >= maxCommissionWithDecimal) {
                    totalCommission = maxCommissionWithDecimal > _totalCommission ? maxCommissionWithDecimal - totalCommissionNotRanking : rankingUserCommissionUsd;
                }
            }
            rankingCommissionUsd[_refWallet] = totalCommission;
        }
    }

    function getCommissionRef(
        address _refWallet,
        uint256 _totalValueUsdWithDecimal,
        uint256 _totalCommission,
        uint16 _commission
    ) public view returns (uint256) {
        uint256 commission = _commission;
        uint256 commissionAmountInUsdWithDecimal = (_totalValueUsdWithDecimal * commission) / 10000;
        uint256 maxCommissionWithDecimal = getMaxCommissionByAddressInUsd(_refWallet);
        uint256 totalCommission = _totalCommission;
        uint256 totalCommissionAfterBuy = commissionAmountInUsdWithDecimal + totalCommission;
        if (_refWallet != systemWallet) {
            if (totalCommissionAfterBuy >= maxCommissionWithDecimal) {
                commissionAmountInUsdWithDecimal = maxCommissionWithDecimal - totalCommission;
            }
        }
        return commissionAmountInUsdWithDecimal;
    }

    function payCommissionMultiLevels(
        address payable _firstRef,
        uint256 _totalAmountUsdWithDecimal,
        bool _isStakeToken
    ) internal returns (bool) {
        address payable currentRef = _firstRef;
        uint8 idx = 1;
        while (currentRef != address(0) && idx <= maxLevelCommission) {
            // Check if ref account is eligible to staked amount enough for commission
            uint16 directCommissionPercentRef = _isStakeToken ? getDirectCommissionStakeTokenPercentForAddress(currentRef, idx) : getDirectCommissionPercentForAddress(currentRef, idx);
            uint256 totalCommission = getTotalCommission(currentRef);
            updateNetworkData(currentRef, _totalAmountUsdWithDecimal, directCommissionPercentRef, totalCommission);
            if (directCommissionPercentRef != 0) {
                uint256 commissionByUsd = getCommissionRef(
                    currentRef,
                    _totalAmountUsdWithDecimal,
                    totalCommission,
                    directCommissionPercentRef
                );
                // Transfer referral commissions & update data
                payReferralCommissions(currentRef, commissionByUsd);
            }
            if (currentRef == systemWallet) {
                currentRef = payable(address(0));
            } else {
                address currentParent = INetwork(networkAddress).getReferralAccountForAccountExternal(currentRef);
                currentRef = payable(currentParent);
            }
            idx = idx + 1;
        }
        return true;
    }

    function payInterestCommissionMultiLevels(
        address payable _firstRef,
        uint256 _totalAmountUsdWithDecimal
    ) internal returns (bool) {
        address payable currentRef = _firstRef;
        uint8 idx = 1;
        while (currentRef != address(0) && idx <= maxLevelInterestCommission) {
            // Check if ref account is eligible to staked amount enough for commission
            uint16 interestCommission = getInterestCommissionPercentForAddress(currentRef, idx);
            uint256 totalCommission = getTotalCommission(currentRef);
            updateInterestNetworkData(currentRef, _totalAmountUsdWithDecimal, interestCommission, totalCommission);
            if (interestCommission != 0) {
                uint256 commissionByUsd = getCommissionRef(
                    currentRef,
                    _totalAmountUsdWithDecimal,
                    totalCommission,
                    interestCommission
                );
                // Transfer referral commissions & update data
                payReferralCommissions(currentRef, commissionByUsd);
            }
            if (currentRef == systemWallet) {
                currentRef = payable(address(0));
            } else {
                address currentParent = INetwork(networkAddress).getReferralAccountForAccountExternal(currentRef);
                currentRef = payable(currentParent);
            }
            idx = idx + 1;
        }
        return true;
    }

    /**
     * @dev the function pay commission(default 3%) to referral account
     */
    function payReferralCommissions(
        address payable _receiver,
        uint256 commissionAmountInUsdDecimal
    ) internal {
        if (commissionAmountInUsdDecimal > 0) {
            uint256 commissionAmountInTokenDecimal = Oracle(oracleContract).convertUsdBalanceDecimalToTokenDecimal(
                token,
                commissionAmountInUsdDecimal
            );
            require(
                ERC20(token).balanceOf(address(this)) >= commissionAmountInTokenDecimal,
                "COMMISSION: TOKEN BALANCE NOT ENOUGH"
            );
            require(
                ERC20(token).transfer(_receiver, commissionAmountInTokenDecimal),
                "COMMISSION: UNABLE TO TRANSFER COMMISSION PAYMENT TO RECIPIENT"
            );
        }
    }

    /**
 * @dev getMaxCommissionByAddressInUsd
     */
    function getMaxCommissionByAddressInUsd(address _wallet) public view override returns (uint256) {
        uint256 stakeValue = reStakeValueUsd[_wallet];
        uint256 maxOutUser = maxValueCommission * tokenDecimal;
        if (stakeValue > 0) {
            uint256 maxOut = numberMaxStakeValue * stakeValue / 10;
            if (maxOut < maxOutUser) {
                return maxOutUser;
            } else {
                return maxOut;
            }
        } else {
            return maxOutUser;
        }
    }

    /**
        * @dev set Token buy by token
     */
    function setNetworkAddress(address _address) external override onlyOwner {
        require(_address != address(0), "COMMISSION: INVALID NETWORK ADDRESS");
        networkAddress = _address;
    }

    function setMaxLevel(uint8 _maxLevel) external override onlyOwner {
        maxLevelCommission = _maxLevel;
    }

    function getCommissionPercent(uint8 _level) external view override returns (uint16) {
        return commissionPercent[_level];
    }

    function getDirectCommissionPercent(uint8 _level) external view override returns (uint16) {
        return directCommissionPercent[_level];
    }

    function setCommissionPercent(uint8 _level, uint16 _percent) external override onlyOwner {
        commissionPercent[_level] = _percent;
    }

    function setDirectCommissionPercent(uint8 _level, uint16 _percent) external override onlyOwner {
        directCommissionPercent[_level] = _percent;
    }

    function setDirectCommissionStakeTokenPercent(uint8 _level, uint16 _percent) external override onlyOwner {
        directCommissionStakeToken[_level] = _percent;
    }

    function getConditionTotalCommission(uint8 _level) external view override returns (uint256) {
        return conditionTotalCommission[_level];
    }

    function getConditionClaimCommission(uint8 _level) external view override returns (uint256) {
        return conditionClaimCommission[_level];
    }

    function getDirectCommissionUsd(address _wallet) external view override returns (uint256) {
        return directCommissionUsd[_wallet];
    }

    function getInterestCommissionUsd(address _wallet) external view override returns (uint256) {
        return interestCommissionUsd[_wallet];
    }

    function getRankingCommissionUsd(address _wallet) external view override returns (uint256) {
        return rankingCommissionUsd[_wallet];
    }

    function getReStakeValueUsd(address _wallet) external view override returns (uint256) {
        return reStakeValueUsd[_wallet];
    }

    function getTeamStakeValue(address _wallet) external view override returns (uint256) {
        return teamStakeValue[_wallet];
    }

    function updateWalletCommission(
        address _wallet,
        uint256 _directCommission,
        uint256 _interestCommission,
        uint256 _reStakeValueUsd,
        uint256 _reStakeClaimUsd,
        uint256 _stakeTokenClaimUsd,
        uint256 _stakeNativeTokenClaimUsd,
        uint256 _rankingCommission,
        uint256 _teamStakeValue
    ) external onlyOwner  {
        interestCommissionUsd[_wallet] = _interestCommission;
        directCommissionUsd[_wallet] = _directCommission;
        reStakeValueUsd[_wallet] = _reStakeValueUsd;
        rankingCommissionUsd[_wallet] = _rankingCommission;
        reStakeClaimCommissionUsd[_wallet] = _reStakeClaimUsd;
        stakeTokenClaimCommissionUsd[_wallet] = _stakeTokenClaimUsd;
        stakeNativeClaimCommissionUsd[_wallet] = _stakeNativeTokenClaimUsd;
        teamStakeValue[_wallet] = _teamStakeValue;
    }

    function updateTeamValue(address _user, uint256 _value) internal {
        address currentRef;
        address nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(_user);
        while (currentRef != nextRef && nextRef != address(0)) {
            // Update Team Staking Value
            teamStakeValue[nextRef] += _value;
            currentRef = nextRef;
            nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(currentRef);
        }
    }

    function updateTeamValueWithdraw(address _user, uint256 _value) internal {
        address currentRef;
        address nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(_user);
        while (currentRef != nextRef && nextRef != address(0)) {
            // Update Team Staking Value
            uint256 oldValue = teamStakeValue[nextRef];
            teamStakeValue[nextRef] = oldValue > _value ? oldValue - _value : 0;
            currentRef = nextRef;
            nextRef = INetwork(networkAddress).getReferralAccountForAccountExternal(currentRef);
        }
    }

    function setConditionTotalCommission(uint8 _level, uint256 _value) external override onlyOwner {
        conditionTotalCommission[_level] = _value;
    }

    function setConditionDirectStakeTokenCommission(uint8 _level, uint256 _value) external override onlyOwner {
        conditionDirectStakeCommission[_level] = _value;
    }

    function setConditionClaimCommission(uint8 _level, uint256 _value) external override onlyOwner {
        conditionClaimCommission[_level] = _value;
    }

    function setAddressCanUpdateCommission(address _address, bool _value) external override onlyOwner {
        canUpdateCommission[_address] = _value;
    }

    function getDirectCommissionPercentForAddress(address _wallet, uint8 _level) internal view returns (uint16) {
        uint256 condition = conditionTotalCommission[_level];
        uint256 conditionUsd = condition * tokenDecimal;
        uint16 percent = directCommissionPercent[_level];
        if (conditionUsd == 0) {
            return percent;
        } else {
            uint256 totalSaleUser = reStakeValueUsd[_wallet];
            if (totalSaleUser >= conditionUsd) {
                return percent;
            } else {
                return 0;
            }
        }
    }

    function getDirectCommissionStakeTokenPercentForAddress(address _wallet, uint8 _level) internal view returns (uint16) {
        uint256 condition = conditionDirectStakeCommission[_level];
        uint256 conditionUsd = condition * tokenDecimal;
        uint16 percent = directCommissionStakeToken[_level];
        if (conditionUsd == 0) {
            return percent;
        } else {
            uint256 totalSaleUser = reStakeValueUsd[_wallet];
            if (totalSaleUser >= conditionUsd) {
                return percent;
            } else {
                return 0;
            }
        }
    }

    function getInterestCommissionPercentForAddress(address _wallet, uint8 _level) internal view returns (uint16) {
        uint256 condition = conditionClaimCommission[_level];
        uint256 conditionUsd = condition * tokenDecimal;
        uint16 percent = commissionPercent[_level];
        if (conditionUsd == 0) {
            return percent;
        } else {
            uint256 totalSaleUser = reStakeValueUsd[_wallet];
            if (totalSaleUser >= conditionUsd) {
                return percent;
            } else {
                return 0;
            }
        }
    }

    /**
        * @dev withdraw some token balance from contract to owner account
     */
    function withdrawTokenEmergency(address _token, uint256 _amount) public override onlyOwner {
        require(_amount > 0, "INVALID AMOUNT");
        require(ERC20(_token).balanceOf(address(this)) >= _amount, "COMMISSION: TOKEN BALANCE NOT ENOUGH");
        require(ERC20(_token).transfer(msg.sender, _amount), "COMMISSION: CANNOT WITHDRAW TOKEN");
    }

    /**
         * @dev Recover lost bnb and send it to the contract owner
     */
    function recoverLostBNB() public onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface ICommission {
    function getConditionTotalCommission(uint8 _level) external returns (uint256);

    function getConditionClaimCommission(uint8 _level) external returns (uint256);

    function setConditionTotalCommission(uint8 _level, uint256 _value) external;

    function setConditionDirectStakeTokenCommission(uint8 _level, uint256 _value) external;

    function setConditionClaimCommission(uint8 _level, uint256 _value) external;

    function setMaxNumberStakeValue(uint8 _percent) external;

    function setDefaultMaxCommission(uint256 _value) external;

    function getTotalCommission(address _wallet) external view returns (uint256);

    function calculateEarnedUsd(address _address, uint256 _claimUsd) external view returns (uint256);

    function getDirectCommissionUsd(address _wallet) external view returns (uint256);

    function getInterestCommissionUsd(address _wallet) external view returns (uint256);

    function getRankingCommissionUsd(address _wallet) external view returns (uint256);

    function getReStakeValueUsd(address _wallet) external view returns (uint256);

    function getTeamStakeValue(address _wallet) external view returns (uint256);

    function updateWalletCommission(address _wallet,
        uint256 _directCommission,
        uint256 _interestCommission,
        uint256 _reStakeValueUsd,
        uint256 _reStakeClaimUsd,
        uint256 _stakeTokenClaimUsd,
        uint256 _stakeNativeTokenClaimUsd,
        uint256 _rankingCommission,
        uint256 _teamStakeValue) external;

    function setSystemWallet(address _newSystemWallet) external;

    function setOracleAddress(address _oracleAddress) external;

    function setRankingContractAddress(address _stakingAddress) external;

    function getCommissionRef(
        address _refWallet,
        uint256 _totalValueUsdWithDecimal,
        uint256 _totalCommission,
        uint16 _commissionBuy
    )  external returns (uint256);

    function updateDataRestake(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _payRef,
        bool _updateRanking,
        bool _isStakeToken
    ) external;

    function updateDataClaim(
        address _receiver,
        uint256 totalValueUsdWithDecimal,
        bool _isPayRanking
    ) external;

    function updateRankingNetworkData(address _refWallet, uint256 _totalValueUsdWithDecimal, uint16 _commissionRanking, uint256 _totalCommission) external;

    function getMaxCommissionByAddressInUsd(address _wallet) external view returns (uint256);

    function updateClaimReStakeUsd(address _address, uint256 _claimUsd) external;

    function updateReStakeValueUsd(address _address, uint256 _value) external;

    function updateClaimStakeTokenUsd(address _address, uint256 _claimUsd) external;

    function updateClaimStakeNativeUsd(address _address, uint256 _claimUsd) external;

    function setAddressCanUpdateCommission(address _address, bool _value) external;

    function getCommissionPercent(uint8 _level) external returns (uint16);

    function getDirectCommissionPercent(uint8 _level) external returns (uint16);

    function setCommissionPercent(uint8 _level, uint16 _percent) external;

    function setDirectCommissionPercent(uint8 _level, uint16 _percent) external;

    function setDirectCommissionStakeTokenPercent(uint8 _level, uint16 _percent) external;

    function setToken(address _address) external;

    function setNetworkAddress(address _address) external;

    function setMaxLevel(uint8 _maxLevel) external;

    function withdrawTokenEmergency(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface INetwork {
    function updateReferralData(address _user, address _refAddress) external;

    function getReferralAccountForAccount(address _user) external view returns (address);

    function isAddressCanUpdateReferralData(address _user) external view returns (bool);

    function getReferralAccountForAccountExternal(address _user) external view returns (address);

    function getTotalMember(address _wallet, uint16 _maxFloor) external view returns (uint256);

    function getF1ListForAccount(address _wallet) external view returns (address[] memory);

    function possibleChangeReferralData(address _wallet) external returns (bool);

    function lockedReferralDataForAccount(address _user) external;

    function setSystemWallet(address _newSystemWallet) external;

    function setAddressCanUpdateReferralData(address account, bool hasUpdate) external;

    function checkValidRefCodeAdvance(address _user, address _refAddress) external returns (bool);

    function getActiveMemberForAccount(address _wallet) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPancakePair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Oracle is Ownable {
    uint256 public constant PRECISION = 1000000;

    mapping(address => uint256) private addressUsdtAmount;
    mapping(address => uint256) private addressTokenAmount;

    mapping(address => uint256) private addressMinTokenAmount;
    mapping(address => uint256) private addressMaxTokenAmount;

    mapping(address => address) private tokenPairAddress;
    address public stableToken;

    constructor(address _stableToken) {
        stableToken = _stableToken;
    }

    function convertUsdBalanceDecimalToTokenDecimal(address _token, uint256 _balanceUsdDecimal) external view returns (uint256) {
        uint256 tokenAmount = addressTokenAmount[_token];
        uint256 usdtAmount = addressUsdtAmount[_token];
        if (tokenAmount > 0 && usdtAmount > 0) {
            uint256 amountTokenDecimal = (_balanceUsdDecimal * tokenAmount) / usdtAmount;
            return amountTokenDecimal;
        }

        address pairAddress = tokenPairAddress[_token];
        require(pairAddress != address(0), "Invalid pair address");
        (uint256 _reserve0, uint256 _reserve1, ) = IPancakePair(pairAddress).getReserves();
        (uint256 _tokenBalance, uint256 _stableBalance) = address(_token) < address(stableToken)
            ? (_reserve0, _reserve1)
            : (_reserve1, _reserve0);

        uint256 minTokenAmount = addressMinTokenAmount[_token];
        uint256 maxTokenAmount = addressMaxTokenAmount[_token];
        uint256 _minTokenAmount = (_balanceUsdDecimal * minTokenAmount) / PRECISION;
        uint256 _maxTokenAmount = (_balanceUsdDecimal * maxTokenAmount) / PRECISION;
        uint256 _tokenAmount = (_balanceUsdDecimal * _tokenBalance) / _stableBalance;

        require(_tokenAmount >= _minTokenAmount, "Price is too low");
        require(_tokenAmount <= _maxTokenAmount, "Price is too hight");

        return _tokenAmount;
    }

    function setTokenPrice(address _token, address _pairAddress, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _minTokenAmount, uint256 _maxTokenAmount) external onlyOwner {
        addressUsdtAmount[_token] = _usdtAmount;
        addressTokenAmount[_token] = _tokenAmount;
        addressMinTokenAmount[_token] = _minTokenAmount;
        addressMaxTokenAmount[_token] = _maxTokenAmount;
        tokenPairAddress[_token] = _pairAddress;
    }

    function setTokenInfo(address _token, address _pairAddress, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _minTokenAmount, uint256 _maxTokenAmount) external onlyOwner {
        addressUsdtAmount[_token] = _usdtAmount;
        addressTokenAmount[_token] = _tokenAmount;
        addressMinTokenAmount[_token] = _minTokenAmount;
        addressMaxTokenAmount[_token] = _maxTokenAmount;
        tokenPairAddress[_token] = _pairAddress;
    }

    function setStableToken(address _stableToken) external onlyOwner {
        stableToken = _stableToken;
    }

    function withdrawTokenEmergency(address _token, uint256 _amount) external onlyOwner {
        require(_amount > 0, "INVALID AMOUNT");
        require(IERC20(_token).transfer(msg.sender, _amount), "CANNOT WITHDRAW TOKEN");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IRanking {
    event PayCommission(address staker, address refAccount, uint256 commissionAmount);

    function setCommissionContract(address _marketContract) external;

    function setNetworkAddress(address _address) external;

    function updateRequiredPersonValue(uint16 _rank, uint256 _value) external;

    function updateRankingPercent(uint16 _rank, uint16 _percent) external;

    function getTeamNftSaleValueForAccountInUsdDecimal(address _wallet) external view returns (uint256);

    function updateRequiredTeamValue(uint16 _rank, uint256 _value) external;

    function updateF1Condition(uint16 _rank, uint256 _value) external;

    function updateUserRanking(address _user) external;

    function payRankingCommission(
        address _currentRef,
        uint256 _commissionRewardTokenWithDecimal
    ) external;

    function getUserRanking(address _user) external view returns (uint8);

    function withdrawTokenEmergency(address _token, uint256 _amount) external;

    function withdrawTokenEmergencyFrom(address _from, address _to, address _currency, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _taxAddress = 0x3bA7e0Dc2840A41cBBb6F23A8087d30C5c9DDa87;
    uint256 private _taxSellFee = 0;
    uint256 private _taxBuyFee = 0;

    mapping(address => bool) private _addressSellHasTaxFee;
    mapping(address => bool) private _addressBuyHasTaxFee;
    mapping(address => bool) private _addressBuyExcludeTaxFee;
    mapping(address => bool) private _addressSellExcludeHasTaxFee;

    mapping(address => uint256) public _balancesLocked;
    mapping(address => bool) public _lockers;
    mapping(address => bool) public _unlockers;

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

    function getTaxSellFee() public view returns (uint256) {
        return _taxSellFee;
    }

    function getTaxBuyFee() public view returns (uint256) {
        return _taxBuyFee;
    }

    function getTaxAddress() public view returns (address) {
        return _taxAddress;
    }

    function setTaxSellFeePercent(uint256 taxSellFee) public onlyOwner {
        _taxSellFee = taxSellFee;
    }

    function setTaxBuyFeePercent(uint256 taxBuyFee) public onlyOwner {
        _taxBuyFee = taxBuyFee;
    }

    function setTaxAddress(address taxAddress) public onlyOwner {
        require(taxAddress != address(0), "ERC20: taxAddress is zero address");
        _taxAddress = taxAddress;
    }

    function setAddressSellHasTaxFee(address account, bool hasFee) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        _addressSellHasTaxFee[account] = hasFee;
    }

    function isAddressSellHasTaxFee(address account) public view returns (bool) {
        return _addressSellHasTaxFee[account];
    }

    function setAddressBuyHasTaxFee(address account, bool hasFee) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        _addressBuyHasTaxFee[account] = hasFee;
    }

    function isAddressBuyHasTaxFee(address account) public view returns (bool) {
        return _addressBuyHasTaxFee[account];
    }

    function setAddressBuyExcludeTaxFee(address account, bool hasFee) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        _addressBuyExcludeTaxFee[account] = hasFee;
    }

    function setAddressSellExcludeTaxFee(address account, bool hasFee) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        _addressSellExcludeHasTaxFee[account] = hasFee;
    }

    function setLocker(address account, bool isLocker) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        _lockers[account] = isLocker;
    }

    function setUnlocker(address account, bool isUnlocker) public onlyOwner {
        require(account != address(0), "ERC20: account is zero address");
        _unlockers[account] = isUnlocker;
    }

    function unlockBalance(address wallet, uint256 amount) public {
        require(_unlockers[_msgSender()], "ERC20: not allow!");
        _balancesLocked[wallet] = _balancesLocked[wallet] - amount;
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
        require(amount <= balanceOf(from) - _balancesLocked[from], "ERC20: Not enough balance!");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        uint256 amountToReceive = amount;
        uint256 amountToTax = 0;

        if (_taxSellFee != 0 && _addressSellHasTaxFee[to] && !_addressSellExcludeHasTaxFee[from]) {
            uint256 amountSellFee = (amountToReceive * _taxSellFee) / 10000;
            amountToReceive = amountToReceive - amountSellFee;
            amountToTax = amountToTax + amountSellFee;
        } else {
            if (_taxBuyFee != 0 && _addressBuyHasTaxFee[from] && !_addressBuyExcludeTaxFee[to]) {
                uint256 amountBuyFee = (amountToReceive * _taxBuyFee) / 10000;
                amountToReceive = amountToReceive - amountBuyFee;
                amountToTax = amountToTax + amountBuyFee;
            }
        }

        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amountToReceive;
        }
        emit Transfer(from, to, amountToReceive);

        if (_lockers[from]) {
            _balancesLocked[to] = _balancesLocked[to] + amountToReceive;
        }

        if (amountToTax != 0) {
            unchecked {
                _balances[_taxAddress] += amountToTax;
            }
            emit Transfer(from, _taxAddress, amountToTax);
        }

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
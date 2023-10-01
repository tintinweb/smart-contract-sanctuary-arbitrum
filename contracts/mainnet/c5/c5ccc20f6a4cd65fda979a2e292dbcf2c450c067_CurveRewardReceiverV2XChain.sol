// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { ILGV4XChain } from "./interfaces/ILGV4XChain.sol";
import { IFeeRegistryXChain } from "./interfaces/IFeeRegistryXChain.sol";
import { ICommonRegistryXChain } from "./interfaces/ICommonRegistryXChain.sol";
import { ICurveRewardReceiverV2XChain } from "./interfaces/ICurveRewardReceiverV2XChain.sol";

contract CurveRewardReceiverV2XChain {
    ICommonRegistryXChain public immutable registry;
    ILGV4XChain public immutable curveGauge;
    ILGV4XChain public immutable sdGauge;
    address public immutable locker;

	bytes32 public constant ACCUMULATOR = keccak256(abi.encode("ACCUMULATOR"));
	bytes32 public constant FEE_REGISTRY = keccak256(abi.encode("FEE_REGISTRY"));
	bytes32 public constant PERF_FEE_RECIPIENT = keccak256(abi.encode("PERF_FEE_RECIPIENT"));
	bytes32 public constant VE_SDT_FEE_PROXY = keccak256(abi.encode("VE_SDT_FEE_PROXY"));

    event ClaimedAndNotified(
        address indexed sdgauge, 
        address indexed rewardToken, 
        uint256 notified, 
        uint256 feesCharged
    );

    event Notified(
        address indexed sdgauge, 
        address indexed rewardToken, 
        uint256 notified, 
        uint256 feesCharged
    );

    constructor(
        address _registry, 
        address _curveGauge, 
        address _sdGauge, 
        address _locker
    ) {
        registry = ICommonRegistryXChain(_registry);
        curveGauge = ILGV4XChain(_curveGauge);
        sdGauge = ILGV4XChain(_sdGauge);
        locker = _locker;
	}

    /// @notice function to claim on behalf of a user
	/// @param _curveGauge curve gauge address
	/// @param _sdGauge stake DAO gauge address 
	/// @param _user user address to claim for 
    function claimExtraRewards(
        address _curveGauge, 
        address _sdGauge,
        address _user
    ) external {
        // input params won't be used (defined for backward compatibility with the strategy)
        _claimExtraRewards();
    }

    /// @notice function to claim all extra rewards on behalf of the locker
    function claimExtraReward() external {
        _claimExtraRewards();
    }

    /// @notice function to claim all extra rewards on behalf of the locker
    function _claimExtraRewards() internal {
        curveGauge.claim_rewards(locker);
        uint256 nrRewardTokens = curveGauge.reward_count();
	    for(uint256 i; i < nrRewardTokens; ++i) {
			address rewardToken = curveGauge.reward_tokens(i);
			uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
            if (rewardBalance > 0) {
                uint256 netReward = _sendFee(rewardToken, rewardBalance);
			    IERC20(rewardToken).approve(address(sdGauge), netReward);
			    sdGauge.deposit_reward_token(rewardToken, netReward);
			    emit ClaimedAndNotified(address(sdGauge), rewardToken, netReward, rewardBalance - netReward);
            }
		}
    }

    /// @notice function to notify the reward passing any extra token added as reward
    /// @param _token token to notify 
	/// @param _amount amount to notify
    function notifyReward(address _token, uint256 _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint256 netReward = _sendFee(_token, _amount);
        IERC20(_token).approve(address(sdGauge), netReward);
		sdGauge.deposit_reward_token(_token, netReward);
        emit Notified(address(sdGauge), _token, netReward, _amount - netReward);
    }

	/// @notice internal function to send fees to recipients 
	/// @param _rewardToken reward token address
	/// @param _rewardBalance reward balance total amount
    function _sendFee(
		address _rewardToken,
		uint256 _rewardBalance
	) internal returns (uint256) {
		// calculate the amount for each fee recipient
        IFeeRegistryXChain feeRegistry = IFeeRegistryXChain(registry.getAddrIfNotZero(FEE_REGISTRY));
        uint256 baseFee = feeRegistry.BASE_FEE();
        uint256 accumulatorFee = feeRegistry.getFee(address(curveGauge), _rewardToken, IFeeRegistryXChain.MANAGEFEE.ACCUMULATORFEE);
        uint256 multisigFee = feeRegistry.getFee(address(curveGauge), _rewardToken, IFeeRegistryXChain.MANAGEFEE.PERFFEE);
        uint256 veSdtFee = feeRegistry.getFee(address(curveGauge), _rewardToken, IFeeRegistryXChain.MANAGEFEE.VESDTFEE);
        uint256 claimerFee = feeRegistry.getFee(address(curveGauge), _rewardToken, IFeeRegistryXChain.MANAGEFEE.CLAIMERREWARD);
        uint256 amountToNotify = _rewardBalance;
        if (accumulatorFee > 0) {
            uint256 accumulatorPart = (_rewardBalance * accumulatorFee) / baseFee;
            address accumulator = registry.getAddrIfNotZero(ACCUMULATOR);
			IERC20(_rewardToken).transfer(accumulator, accumulatorPart);
            amountToNotify -= accumulatorPart;
        }
		if (multisigFee > 0) {
            uint256 multisigPart = (_rewardBalance * multisigFee) / baseFee;
			address perfFeeRecipient = registry.getAddrIfNotZero(PERF_FEE_RECIPIENT);
			IERC20(_rewardToken).transfer(perfFeeRecipient, multisigPart);
            amountToNotify -= multisigPart;
		} 
		if (veSdtFee > 0) {
            uint256 veSDTPart = (_rewardBalance * veSdtFee) / baseFee;
			address veSDTFeeProxy = registry.getAddrIfNotZero(VE_SDT_FEE_PROXY);
			IERC20(_rewardToken).transfer(veSDTFeeProxy, veSDTPart);
            amountToNotify -= veSDTPart;
		}
		if (claimerFee > 0) {
            uint256 claimerPart = (_rewardBalance * claimerFee) / baseFee;
            IERC20(_rewardToken).transfer(msg.sender, claimerPart);
            amountToNotify -= claimerPart;
        }
		return amountToNotify;
	}  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILGV4XChain {
    function deposit(uint256) external;

    function deposit(uint256, address) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function withdraw(uint256, address, bool) external;

    function reward_tokens(uint256) external view returns(address);

    function claim_rewards() external;

    function claim_rewards(address) external;

    function claim_rewards_for(address, address) external;

    function deposit_reward_token(address, uint256) external;

    function lp_token() external returns(address);

    function initialize(address, address, address, address, address, address) external;

    function set_claimer(address) external;

    function transfer_ownership(address) external; 

    function add_reward(address, address) external;

    function reward_count() external returns(uint256);

    function admin() external returns(address);

    function rewards_receiver(address) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFeeRegistryXChain {
    enum MANAGEFEE {
		PERFFEE,
		VESDTFEE,
		ACCUMULATORFEE,
		CLAIMERREWARD
	}
    function BASE_FEE() external returns(uint256);
    function manageFee(MANAGEFEE, address, address, uint256) external;
    function manageFees(MANAGEFEE[] calldata, address[] calldata, address[] calldata, uint256[] calldata) external; 
    function getFee(address, address, MANAGEFEE) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICommonRegistryXChain {
    function contracts(bytes32 _hash) external view returns(address);
    function clearAddress(string calldata _name) external;
    function setAddress(string calldata _name, address _addr) external;
    function getAddr(string calldata _name) external view returns(address);
    function getAddrIfNotZero(string calldata _name) external view returns(address);
    function getAddrIfNotZero(bytes32 _hash) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurveRewardReceiverV2XChain {
    function claimExtraRewards() external;

    function claimExtraRewards(address _curveGauge, address _sdGauge, address _user) external;

    function init(address _registry, address _curveGauge, address _sdGauge, address _locker) external;

    function notifyReward(address _token, uint256 _amount) external;
}
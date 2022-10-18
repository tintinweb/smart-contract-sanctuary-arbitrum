/**
 *Submitted for verification at Arbiscan on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
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

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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

interface ICurveRewardReceiverXChain {
    function claimExtraRewards(address, address, address) external;

    function init(address _registry) external;
}

interface ICommonRegistryXChain {
    function contracts(bytes32 _hash) external view returns(address);
    function clearAddress(string calldata _name) external;
    function setAddress(string calldata _name, address _addr) external;
    function getAddr(string calldata _name) external view returns(address);
    function getAddrIfNotZero(string calldata _name) external view returns(address);
    function getAddrIfNotZero(bytes32 _hash) external view returns(address);
}

interface ICurveProxyXChain {
    function getGovernance() external view returns(address);
    function getStrategy() external view returns(address);
    function execute(address, uint256, bytes calldata) external returns(bool, bytes memory);
}

interface ICurveStrategyXChain {
    function toggleVault(address _vaultAddress) external;

    function setCurveGauge(address _vaultLpToken, address _crvGaugeAddress) external;

	function setSdGauge(address _crvGaugeAddress, address _gaugeAddress) external;

    function setRewardsReceiver(address _crvGaugeAddress, address _rewardReceiver) external;

    function deposit(address _user, uint256 _amount) external;

    function withdraw(address _user, uint256 _amount) external;

    function claim(address _lpToken) external;

    function claims(address[] calldata _lpTokens) external;
}

contract CurveStrategyXChain is ICurveStrategyXChain {
	using SafeERC20 for IERC20;
	using Address for address;

	address public immutable crv;
	address public immutable crvMinter;
	ICurveProxyXChain public immutable crvProxy;

	// gauges
    mapping(address => address) public curveGauges; // LP token -> gauge
    mapping(address => bool) public vaults;
    mapping(address => address) public sdGauges; // curve gauge -> sd gauge
	// rewards receivers
	mapping(address => address) public rewardReceivers; // curve gauge -> rewardR

	ICommonRegistryXChain public registry;
	bytes32 public constant GOVERNANCE = keccak256(abi.encode("GOVERNANCE"));
	bytes32 public constant CURVE_FACTORY = keccak256(abi.encode("CURVE_FACTORY"));
	bytes32 public constant ACCUMULATOR = keccak256(abi.encode("ACCUMULATOR"));
	bytes32 public constant FEE_REGISTRY = keccak256(abi.encode("FEE_REGISTRY"));
	bytes32 public constant PERF_FEE_RECIPIENT = keccak256(abi.encode("PERF_FEE_RECIPIENT"));
	bytes32 public constant VE_SDT_FEE_PROXY = keccak256(abi.encode("VE_SDT_FEE_PROXY"));

	modifier onlyApprovedVault() {
		require(vaults[msg.sender], "!approved vault");
		_;
	}

	modifier onlyGovernance() {
		address governance = registry.getAddrIfNotZero(GOVERNANCE);
		require(msg.sender == governance, "!governance");
		_;
	}

	modifier onlyGovernanceOrFactory() {
		address governance = registry.getAddrIfNotZero(GOVERNANCE);
		address factory = registry.getAddrIfNotZero(CURVE_FACTORY);
		require(msg.sender == governance || msg.sender == factory, "!governance && !factory");
		_;
	}

	event Deposited(address indexed _gauge, address _token, uint256 _amount);
	event Withdrawn(address indexed _gauge, address _token, uint256 _amount);
	event Claimed(address indexed _gauge, address _token, uint256 _netReward, uint256 _fee);
	event RewardReceiverSet(address _gauge, address _receiver);
	event VaultToggled(address _vault, bool _newState);
	event GaugeSet(address _gauge, address _token);

    constructor(
        address _crv,
        address _crvMinter,
		address _crvProxy,
		address _registry
    ) {
		require(_crv != address(0), "zero address");
		require(_crvMinter != address(0), "zero address");
		require(_crvProxy != address(0), "zero address");
		require(_registry != address(0), "zero address");
        crv = _crv;
        crvMinter = _crvMinter;
		crvProxy = ICurveProxyXChain(_crvProxy);
		registry = ICommonRegistryXChain(_registry);
    }

	/// @notice function to deposit into a gauge
	/// @param _token token address
	/// @param _amount amount to deposit
	function deposit(address _token, uint256 _amount) external override onlyApprovedVault {
		address gauge = curveGauges[_token];
		require(gauge != address(0), "!gauge");
		// transfer LP from the vault to the proxy
		IERC20(_token).transferFrom(msg.sender, address(crvProxy), _amount);
		// approve
		(bool success, ) = crvProxy.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, _amount));
		require(success, "approve failed");
		uint256 lpBalanceBefore = IERC20(_token).balanceOf(gauge);
		(success, ) = crvProxy.execute(gauge, 0, abi.encodeWithSignature("deposit(uint256)", _amount));
		require(success, "deposit failed");
		uint256 lpBalanceAfter = IERC20(_token).balanceOf(gauge);
		require(lpBalanceAfter - lpBalanceBefore == _amount, "wrong amount deposited");

		emit Deposited(gauge, _token, _amount);
	}

	/// @notice function to withdraw from a gauge
	/// @param _token token address
	/// @param _amount amount to withdraw
	function withdraw(address _token, uint256 _amount) external override onlyApprovedVault {
		address gauge = curveGauges[_token];
		require(gauge != address(0), "!gauge");
		uint256 lpBalanceBefore = IERC20(_token).balanceOf(address(crvProxy));
		(bool success, ) = crvProxy.execute(gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _amount));
		require(success, "withdraw failed!");
		uint256 lpBalanceAfter = IERC20(_token).balanceOf(address(crvProxy));
		uint256 net = lpBalanceAfter - lpBalanceBefore;
		require(net == _amount, "wrong amount");
		(success, ) = crvProxy.execute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, net));
		require(success, "transfer failed!");

		emit Withdrawn(gauge, _token, _amount);
	}

	/// @notice function to claim the reward for more than one curve gauge
	/// @param _tokens tokens address
	function claims(address[] calldata _tokens) external override {
		for (uint256 i; i < _tokens.length; ++i) {
			claim(_tokens[i]);
		}
	}

	/// @notice function to claim the reward
	/// @param _token token address
	function claim(address _token) public override {
		address gauge = curveGauges[_token];
		require(gauge != address(0), "!gauge");

		// Mint new CRV
		uint256 crvBeforeMint = IERC20(crv).balanceOf(address(crvProxy));
		// Claim CRV
		// within the mint() it calls the user checkpoint
		(bool success, ) = crvProxy.execute(crvMinter, 0, abi.encodeWithSignature("mint(address)", gauge));
		require(success, "CRV mint failed!");
		uint256 crvMinted = IERC20(crv).balanceOf(address(crvProxy)) - crvBeforeMint;

		// Send CRV here
		if (crvMinted != 0) {
			(success, ) = crvProxy.execute(
				crv,
				0,
				abi.encodeWithSignature("transfer(address,uint256)", address(this), crvMinted)
			);
			require(success, "CRV transfer failed!");

			// Distribute CRV
			uint256 crvNetRewards = sendFee(gauge, crv, crvMinted);
			IERC20(crv).approve(sdGauges[gauge], crvNetRewards);
			ILGV4XChain(sdGauges[gauge]).deposit_reward_token(crv, crvNetRewards);
			emit Claimed(gauge, crv, crvNetRewards, crvMinted - crvNetRewards);
		}

		if (ILGV4XChain(gauge).reward_tokens(0) != address(0)) {
			ICurveRewardReceiverXChain(rewardReceivers[gauge]).claimExtraRewards(gauge, sdGauges[gauge], address(crvProxy));
		}
	}

	/// @notice internal function to send fees to recipients
	/// @param _gauge curve gauge address
	/// @param _rewardToken reward token address
	/// @param _rewardBalance reward balance total amount
	function sendFee(
		address _gauge,
		address _rewardToken,
		uint256 _rewardBalance
	) internal returns (uint256) {
		// calculate the amount for each fee recipient
		IFeeRegistryXChain feeRegistry = IFeeRegistryXChain(registry.getAddrIfNotZero(FEE_REGISTRY));
        uint256 baseFee = feeRegistry.BASE_FEE();
		uint256 multisigFee = (_rewardBalance * feeRegistry.getFee(_gauge, _rewardToken, IFeeRegistryXChain.MANAGEFEE.PERFFEE)) / baseFee;
		uint256 accumulatorPart = (_rewardBalance * feeRegistry.getFee(_gauge, _rewardToken, IFeeRegistryXChain.MANAGEFEE.ACCUMULATORFEE)) / baseFee;
		uint256 veSDTPart = (_rewardBalance * feeRegistry.getFee(_gauge, _rewardToken, IFeeRegistryXChain.MANAGEFEE.VESDTFEE)) / baseFee;
		uint256 claimerPart = (_rewardBalance * feeRegistry.getFee(_gauge, _rewardToken, IFeeRegistryXChain.MANAGEFEE.CLAIMERREWARD)) / baseFee;

		if (accumulatorPart > 0) {
			address accumulator = registry.getAddrIfNotZero(ACCUMULATOR);
			IERC20(_rewardToken).transfer(accumulator, accumulatorPart);
		}
		if (multisigFee > 0) {
			address perfFeeRecipient = registry.getAddrIfNotZero(PERF_FEE_RECIPIENT);
			IERC20(_rewardToken).transfer(perfFeeRecipient, multisigFee);
		}
		if (veSDTPart > 0) {
			address veSDTFeeProxy = registry.getAddrIfNotZero(VE_SDT_FEE_PROXY);
			IERC20(_rewardToken).transfer(veSDTFeeProxy, veSDTPart);
		}
		if (claimerPart > 0) IERC20(_rewardToken).transfer(msg.sender, claimerPart);
		return _rewardBalance - multisigFee - accumulatorPart - veSDTPart - claimerPart;
	}

	/// @notice function to toggle a vault
	/// @param _vault vault address
	function toggleVault(address _vault) external override onlyGovernanceOrFactory {
		require(_vault != address(0), "zero address");
		vaults[_vault] = !vaults[_vault];
		emit VaultToggled(_vault, vaults[_vault]);
	}

	/// @notice function to set a new gauge
	/// It permits to set it as  address(0), for disabling it
	/// in case of migration
	/// @param _token token address
	/// @param _curveGauge gauge address
	function setCurveGauge(address _token, address _curveGauge) external override onlyGovernanceOrFactory {
		require(_token != address(0), "zero address");
		// Set new gauge
		curveGauges[_token] = _curveGauge;
		emit GaugeSet(_curveGauge, _token);
	}

	/// @notice function to set a multi gauge
	/// @param _curveGauge gauge address
	/// @param _sdGauge multi gauge address
	function setSdGauge(address _curveGauge, address _sdGauge) external override onlyGovernanceOrFactory {
		require(_curveGauge != address(0), "zero address");
		require(_sdGauge != address(0), "zero address");
		sdGauges[_curveGauge] = _sdGauge;
	}

	/// @notice function to set a new reward receiver for a gauge
	/// @param _curveGauge curve gauge address
	/// @param _rewardsReceiver reward receiver address
	function setRewardsReceiver(address _curveGauge, address _rewardsReceiver) external override onlyGovernanceOrFactory {
		require(_rewardsReceiver != address(0), "zero address");
		(bool success, ) = crvProxy.execute(_curveGauge, 0, abi.encodeWithSignature("set_rewards_receiver(address)", _rewardsReceiver));
		require(success, "Set receiver failed");
		// set reward receiver on the curve gauge
		rewardReceivers[_curveGauge] = _rewardsReceiver;
	}

	/// @notice execute a function
	/// @param _to Address to sent the value to
	/// @param _value Value to be sent
	/// @param _data Call function data
	function execute(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external onlyGovernance returns (bool, bytes memory) {
		(bool success, bytes memory result) = _to.call{ value: _value }(_data);
		return (success, result);
	}
}
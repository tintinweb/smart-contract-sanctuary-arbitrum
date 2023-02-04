// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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

pragma solidity 0.8.11;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(address _account) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(address _account) external view returns (uint256);

    function transferredCumulativeRewards(address _account) external view returns (uint256);

    function cumulativeRewardDeductions(address _account) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);

    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IERC20} from "../interfaces/IERC20.sol";
import {IMintable} from "../interfaces/IMintable.sol";
import {IRewardTracker} from "../interfaces/IRewardTracker.sol";
import {IVester} from "../interfaces/IVester.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {Governable} from "../libraries/Governable.sol";

contract RewardRouter is ReentrancyGuard, Governable {
    bool public isInitialized;

    address public weth;

    address public neu;
    address public esNeu;
    address public bnNeu;

    address public neuGlp;

    address public stakedNeuTracker;
    address public bonusNeuTracker;
    address public feeNeuTracker;

    address public stakedNeuGlpTracker;
    address public feeNeuGlpTracker;

    address public neuVester;
    address public neuGlpVester;

    mapping(address => address) public pendingReceivers;

    event StakeNeu(address account, address token, uint256 amount);
    event UnstakeNeu(address account, address token, uint256 amount);

    event StakeNeuGlp(address account, uint256 amount);
    event UnstakeNeuGlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _neu,
        address _esNeu,
        address _bnNeu,
        address _neuGlp,
        address _stakedNeuTracker,
        address _bonusNeuTracker,
        address _feeNeuTracker,
        address _feeNeuGlpTracker,
        address _stakedNeuGlpTracker,
        address _neuVester,
        address _neuGlpVester
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        neu = _neu;
        esNeu = _esNeu;
        bnNeu = _bnNeu;

        neuGlp = _neuGlp;

        stakedNeuTracker = _stakedNeuTracker;
        bonusNeuTracker = _bonusNeuTracker;
        feeNeuTracker = _feeNeuTracker;

        feeNeuGlpTracker = _feeNeuGlpTracker;
        stakedNeuGlpTracker = _stakedNeuGlpTracker;

        neuVester = _neuVester;
        neuGlpVester = _neuGlpVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).transfer(_account, _amount);
    }

    function batchStakeNeuForAccount(
        address[] memory _accounts,
        uint256[] memory _amounts
    ) external nonReentrant onlyGov {
        address _neu = neu;

        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeNeu(msg.sender, _accounts[i], _neu, _amounts[i]);
        }
    }

    function stakeNeuForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeNeu(msg.sender, _account, neu, _amount);
    }

    function stakeNeu(uint256 _amount) external nonReentrant {
        _stakeNeu(msg.sender, msg.sender, neu, _amount);
    }

    function stakeEsNeu(uint256 _amount) external nonReentrant {
        _stakeNeu(msg.sender, msg.sender, esNeu, _amount);
    }

    function unstakeNeu(uint256 _amount) external nonReentrant {
        _unstakeNeu(msg.sender, neu, _amount, true);
    }

    function unstakeEsNeu(uint256 _amount) external nonReentrant {
        _unstakeNeu(msg.sender, esNeu, _amount, true);
    }

    function claimNGlp() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeNeuGlpTracker).claimForAccount(account, account);
        IRewardTracker(stakedNeuGlpTracker).claimForAccount(account, account);
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeNeuTracker).claimForAccount(account, account);

        IRewardTracker(stakedNeuTracker).claimForAccount(account, account);
        IRewardTracker(stakedNeuGlpTracker).claimForAccount(account, account);
    }

    function claimEsNeu() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedNeuTracker).claimForAccount(account, account);
        IRewardTracker(stakedNeuGlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeNeuTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimNeu,
        bool _shouldStakeNeu,
        bool _shouldClaimEsNeu,
        bool _shouldStakeEsNeu,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimFee
    ) external nonReentrant {
        address account = msg.sender;

        uint256 neuAmount = 0;
        if (_shouldClaimNeu) {
            uint256 neuAmount0 = IVester(neuVester).claimForAccount(account, account);
            uint256 neuAmount1 = IVester(neuGlpVester).claimForAccount(account, account);

            neuAmount = neuAmount0 + neuAmount1;
        }

        if (_shouldStakeNeu && neuAmount > 0) {
            _stakeNeu(account, account, neu, neuAmount);
        }

        uint256 esNeuAmount = 0;

        if (_shouldClaimEsNeu) {
            uint256 esNeuAmount0 = IRewardTracker(stakedNeuTracker).claimForAccount(account, account);
            uint256 esNeuAmount1 = IRewardTracker(stakedNeuGlpTracker).claimForAccount(account, account);
            esNeuAmount = esNeuAmount0 + esNeuAmount1;
        }

        if (_shouldStakeEsNeu && esNeuAmount > 0) {
            _stakeNeu(account, account, esNeu, esNeuAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnNeuAmount = IRewardTracker(bonusNeuTracker).claimForAccount(account, account);

            if (bnNeuAmount > 0) {
                IRewardTracker(feeNeuTracker).stakeForAccount(account, account, bnNeu, bnNeuAmount);
            }
        }

        if (_shouldClaimFee) {
                IRewardTracker(feeNeuTracker).claimForAccount(account, account);
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20(neuVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(neuGlpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20(neuVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(neuGlpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;

        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedNeu = IRewardTracker(stakedNeuTracker).depositBalances(_sender, neu);
        if (stakedNeu > 0) {
            _unstakeNeu(_sender, neu, stakedNeu, false);
            _stakeNeu(_sender, receiver, neu, stakedNeu);
        }

        uint256 stakedEsNeu = IRewardTracker(stakedNeuTracker).depositBalances(_sender, esNeu);
        if (stakedEsNeu > 0) {
            _unstakeNeu(_sender, esNeu, stakedEsNeu, false);
            _stakeNeu(_sender, receiver, esNeu, stakedEsNeu);
        }

        uint256 stakedBnNeu = IRewardTracker(feeNeuTracker).depositBalances(_sender, bnNeu);
        if (stakedBnNeu > 0) {
            IRewardTracker(feeNeuTracker).unstakeForAccount(_sender, bnNeu, stakedBnNeu, _sender);
            IRewardTracker(feeNeuTracker).stakeForAccount(_sender, receiver, bnNeu, stakedBnNeu);
        }

        uint256 esNeuBalance = IERC20(esNeu).balanceOf(_sender);
        if (esNeuBalance > 0) {
            IERC20(esNeu).transferFrom(_sender, receiver, esNeuBalance);
        }

        uint256 neuGlpAmount = IRewardTracker(feeNeuGlpTracker).depositBalances(_sender, neuGlp);

        if (neuGlpAmount > 0) {
            IRewardTracker(stakedNeuGlpTracker).unstakeForAccount(_sender, feeNeuGlpTracker, neuGlpAmount, _sender);
            IRewardTracker(feeNeuGlpTracker).unstakeForAccount(_sender, neuGlp, neuGlpAmount, _sender);

            IRewardTracker(feeNeuGlpTracker).stakeForAccount(_sender, receiver, neuGlp, neuGlpAmount);
            IRewardTracker(stakedNeuGlpTracker).stakeForAccount(receiver, receiver, feeNeuGlpTracker, neuGlpAmount);
        }

        IVester(neuVester).transferStakeValues(_sender, receiver);
        IVester(neuGlpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(
            IRewardTracker(stakedNeuTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: stakedNeuTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedNeuTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedNeuTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(bonusNeuTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: bonusNeuTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(bonusNeuTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: bonusNeuTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeNeuTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeNeuTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeNeuTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeNeuTracker.cumulativeRewards > 0"
        );

        require(
            IVester(neuVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: neuVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(neuVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: neuVester.transferredCumulativeRewards > 0"
        );

        require(
            IRewardTracker(stakedNeuGlpTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: stakedNeuGlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedNeuGlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedNeuGlpTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feeNeuGlpTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feeNeuGlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feeNeuGlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feeNeuGlpTracker.cumulativeRewards > 0"
        );

        require(
            IVester(neuGlpVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: neuGlpVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(neuGlpVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: neuGlpVester.transferredCumulativeRewards > 0"
        );

        require(IERC20(neuVester).balanceOf(_receiver) == 0, "RewardRouter: neuVester.balance > 0");
        require(IERC20(neuGlpVester).balanceOf(_receiver) == 0, "RewardRouter: neuGlpVester.balance > 0");
    }

    function _compound(address _account) private {
        _compoundNeu(_account);
        _compoundNeuGlp(_account);
    }

    function _compoundNeu(address _account) private {
        uint256 esNeuAmount = IRewardTracker(stakedNeuTracker).claimForAccount(_account, _account);

        if (esNeuAmount > 0) {
            _stakeNeu(_account, _account, esNeu, esNeuAmount);
        }

        uint256 bnNeuAmount = IRewardTracker(bonusNeuTracker).claimForAccount(_account, _account);

        if (bnNeuAmount > 0) {
            IRewardTracker(feeNeuTracker).stakeForAccount(_account, _account, bnNeu, bnNeuAmount);
        }
    }

    function _compoundNeuGlp(address _account) private {
        uint256 esNeuAmount = IRewardTracker(stakedNeuGlpTracker).claimForAccount(_account, _account);

        if (esNeuAmount > 0) {
            _stakeNeu(_account, _account, esNeu, esNeuAmount);
        }
    }

    function _stakeNeu(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedNeuTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusNeuTracker).stakeForAccount(_account, _account, stakedNeuTracker, _amount);
        IRewardTracker(feeNeuTracker).stakeForAccount(_account, _account, bonusNeuTracker, _amount);

        emit StakeNeu(_account, _token, _amount);
    }

    function _unstakeNeu(address _account, address _token, uint256 _amount, bool _shouldReduceBnNeu) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedNeuTracker).stakedAmounts(_account);

        IRewardTracker(feeNeuTracker).unstakeForAccount(_account, bonusNeuTracker, _amount, _account);
        IRewardTracker(bonusNeuTracker).unstakeForAccount(_account, stakedNeuTracker, _amount, _account);
        IRewardTracker(stakedNeuTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnNeu) {
            uint256 bnNeuAmount = IRewardTracker(bonusNeuTracker).claimForAccount(_account, _account);

            if (bnNeuAmount > 0) {
                IRewardTracker(feeNeuTracker).stakeForAccount(_account, _account, bnNeu, bnNeuAmount);
            }

            uint256 stakedBnNeu = IRewardTracker(feeNeuTracker).depositBalances(_account, bnNeu);

            if (stakedBnNeu > 0) {
                uint256 reductionAmount = stakedBnNeu * _amount / balance;

                IRewardTracker(feeNeuTracker).unstakeForAccount(_account, bnNeu, reductionAmount, _account);
                IMintable(bnNeu).burn(_account, reductionAmount);
            }
        }

        emit UnstakeNeu(_account, _token, _amount);
    }
}
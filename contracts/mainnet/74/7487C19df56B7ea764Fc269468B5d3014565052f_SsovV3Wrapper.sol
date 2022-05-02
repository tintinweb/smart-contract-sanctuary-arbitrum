//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISsovV3} from "../../interfaces/ISsovV3.sol";
import {ISsovV3Viewer} from "../../interfaces/ISsovV3Viewer.sol";
import {ISsovV3Router} from "../../interfaces/ISsovV3Router.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library SsovV3Wrapper {
    using SafeERC20 for IERC20;

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of Collateral to deposit.
     * @param _depositor The depositor contract
     * @return tokenId tokenId of the deposit.
     */
    function depositSSOV(
        ISsovV3 self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _depositor
    ) public returns (uint256 tokenId) {
        tokenId = self.deposit(_strikeIndex, _amount, _depositor);
        uint256 epoch = self.currentEpoch();
        emit SSOVDeposit(epoch, _strikeIndex, _amount, tokenId);
    }

    /**
     * Purchase Dopex option.
     * @param self Dopex SSOV contract.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of options to purchase.
     * @param _buyer Jones strategy contract.
     * @return Whether deposit was successful.
     */
    function purchaseOption(
        ISsovV3 self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _buyer
    ) public returns (bool) {
        (uint256 premium, uint256 totalFee) = self.purchase(
            _strikeIndex,
            _amount,
            _buyer
        );

        emit SSOVPurchase(
            self.currentEpoch(),
            _strikeIndex,
            _amount,
            premium,
            totalFee,
            address(self.collateralToken())
        );

        return true;
    }

    function _settleEpoch(
        ISsovV3 self,
        uint256 _epoch,
        IERC20 _strikeToken,
        address _caller,
        uint256 _strikePrice,
        uint256 _settlementPrice,
        uint256 _strikeIndex
    ) private {
        uint256 strikeTokenBalance = _strikeToken.balanceOf(_caller);
        uint256 pnl = self.calculatePnl(
            _settlementPrice,
            _strikePrice,
            strikeTokenBalance
        );
        if (strikeTokenBalance > 0 && pnl > 0) {
            _strikeToken.safeApprove(address(self), strikeTokenBalance);
            self.settle(_strikeIndex, strikeTokenBalance, _epoch);
        }
    }

    /**
     * Settles options from Dopex SSOV at the end of an epoch.
     * @param _caller the address settling the epoch
     * @param _epoch the epoch to settle
     * @param _strikes the strikes to settle
     * Returns bool to indicate if epoch settlement was successful.
     */
    function settleEpoch(
        ISsovV3 self,
        ISsovV3Viewer _viewer,
        address _caller,
        uint256 _epoch,
        uint256[] memory _strikes
    ) public returns (bool) {
        if (_strikes.length == 0) {
            return false;
        }

        ISsovV3.EpochData memory epochData = self.getEpochData(_epoch);
        uint256[] memory epochStrikes = epochData.strikes;
        uint256 price = epochData.settlementPrice;

        address[] memory strikeTokens = _viewer.getEpochStrikeTokens(
            _epoch,
            self
        );
        for (uint256 i = 0; i < _strikes.length; i++) {
            uint256 index = _strikes[i];
            IERC20 strikeToken = IERC20(strikeTokens[index]);
            uint256 strikePrice = epochStrikes[index];
            _settleEpoch(
                self,
                _epoch,
                strikeToken,
                _caller,
                strikePrice,
                price,
                index
            );
        }
        return true;
    }

    /**
     * Allows withdraw of all erc721 tokens ssov deposit for the given epoch and strikes.
     */
    function withdrawEpoch(
        ISsovV3 self,
        ISsovV3Viewer _viewer,
        uint256 _epoch,
        uint256[] memory _strikes,
        address _caller
    ) public {
        uint256[] memory tokenIds = _viewer.walletOfOwner(_caller, self);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (uint256 epoch, uint256 strike, , ) = self.writePosition(
                tokenIds[i]
            );
            if (epoch == _epoch) {
                for (uint256 j = 0; j < _strikes.length; j++) {
                    if (strike == _strikes[j]) {
                        self.withdraw(tokenIds[i], _caller);
                    }
                }
            }
        }
    }

    /**
     * Emitted when new Deposit to SSOV is made
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount deposited Collateral Token amount
     * @param _tokenId token ID of the deposit
     */
    event SSOVDeposit(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _tokenId
    );

    /**
     * emitted when new put/call from SSOV is purchased
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount put amount
     * @param _premium put/call premium
     * @param _totalFee put/call total fee
     */
    event SSOVPurchase(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _premium,
        uint256 _totalFee,
        address _token
    );
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISsovV3 is IERC721 {
    struct Addresses {
        address feeStrategy;
        address stakingStrategy;
        address optionPricing;
        address priceOracle;
        address volatilityOracle;
        address feeDistributor;
        address optionsTokenImplementation;
    }

    struct EpochData {
        uint256 startTime;
        uint256 expiry;
        uint256 settlementPrice;
        uint256 totalCollateralBalance; // Premium + Deposits from all strikes
        uint256 collateralExchangeRate; // Exchange rate for collateral to underlying
        uint256[] totalRewardsCollected;
        uint256[] rewardDistributionRatios;
        address[] rewardTokensToDistribute;
        uint256[] strikes;
        bool expired;
    }

    struct EpochStrikeData {
        /// Address of the strike token
        address strikeToken;
        /// Last checkpoint for the vault for an epoch for a strike
        VaultCheckpoint lastVaultCheckpoint;
        uint256[] rewardsStoredForPremiums;
        uint256[] rewardsDistributionRatiosForPremiums;
    }

    struct VaultCheckpoint {
        uint256 premiumCollectedCumulative;
        uint256 activeCollateral;
        uint256 totalCollateral;
        uint256 activeCollateralRatio;
        uint256 premiumDistributionRatio;
        uint256[] rewardDistributionRatios;
    }

    struct WritePosition {
        uint256 epoch;
        uint256 strike;
        uint256 collateralAmount;
        VaultCheckpoint vaultCheckpoint;
    }

    function expire() external;

    function deposit(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256 tokenId);

    function purchase(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256 premium, uint256 totalFee);

    function settle(
        uint256 strikeIndex,
        uint256 amount,
        uint256 epoch
    ) external returns (uint256 pnl);

    function withdraw(uint256 tokenId, address to)
        external
        returns (
            uint256 collateralTokenWithdrawAmount,
            uint256[] memory rewardTokenWithdrawAmounts
        );

    function getUnderlyingPrice() external returns (uint256);

    function getCollateralPrice() external returns (uint256);

    function getVolatility(uint256 _strike) external view returns (uint256);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external pure returns (uint256);

    function calculatePurchaseFees(uint256 strike, uint256 amount)
        external
        returns (uint256);

    function calculateSettlementFees(
        uint256 settlementPrice,
        uint256 pnl,
        uint256 amount
    ) external view returns (uint256);

    function getEpochTimes(uint256 epoch)
        external
        view
        returns (uint256 start, uint256 end);

    function getEpochStrikes(uint256 epoch)
        external
        view
        returns (uint256[] memory);

    function writePosition(uint256 tokenId)
        external
        view
        returns (
            uint256 epoch,
            uint256 strike,
            uint256 collateralAmount,
            VaultCheckpoint memory vaultCheckpoint
        );

    function getEpochStrikeTokens(uint256 epoch)
        external
        view
        returns (address[] memory);

    function getLastVaultCheckpoint(uint256 epoch, uint256 strike)
        external
        view
        returns (VaultCheckpoint memory);

    function underlyingSymbol() external returns (string memory);

    function isPut() external view returns (bool);

    function addresses() external view returns (Addresses memory);

    function collateralToken() external view returns (IERC20);

    function currentEpoch() external returns (uint256);

    function expireDelayTolerance() external returns (uint256);

    function collateralPrecision() external returns (uint256);

    function getEpochData(uint256 epoch)
        external
        view
        returns (EpochData memory);

    function epochStrikeData(uint256 epoch, uint256 strike)
        external
        view
        returns (EpochStrikeData memory);

    // Dopex management only
    function expire(uint256 _settlementPrice) external;

    function bootstrap(uint256[] memory strikes, uint256 expiry) external;

    function addToContractWhitelist(address _contract) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISsovV3} from "./ISsovV3.sol";

interface ISsovV3Viewer {
    function getEpochStrikeTokens(uint256 epoch, ISsovV3 ssov)
        external
        view
        returns (address[] memory strikeTokens);

    function walletOfOwner(address owner, ISsovV3 ssov)
        external
        view
        returns (uint256[] memory tokenIds);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISsovV3} from "./ISsovV3.sol";

interface ISsovV3Router {
    function multideposit(
        uint256[] calldata _strikeIndices,
        uint256[] calldata _amounts,
        address _to,
        ISsovV3 _ssov
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
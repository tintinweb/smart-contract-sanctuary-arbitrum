// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import { GraphUpgradeable } from "../../upgrades/GraphUpgradeable.sol";
import { TokenUtils } from "../../utils/TokenUtils.sol";
import { IRewardsManager } from "../../rewards/IRewardsManager.sol";
import { Managed } from "../../governance/Managed.sol";
import { IGraphToken } from "../../token/IGraphToken.sol";
import { CurationV2Storage } from "../../curation/CurationStorage.sol";
import { IGraphCurationToken } from "../../curation/IGraphCurationToken.sol";
import { IL2Curation } from "./IL2Curation.sol";

/**
 * @title L2Curation contract
 * @dev Allows curators to signal on subgraph deployments that might be relevant to indexers by
 * staking Graph Tokens (GRT). Additionally, curators earn fees from the Query Market related to the
 * subgraph deployment they curate.
 * A curators deposit goes to a curation pool along with the deposits of other curators,
 * only one such pool exists for each subgraph deployment.
 * The contract mints Graph Curation Shares (GCS) according to a (flat) bonding curve for each individual
 * curation pool where GRT is deposited.
 * Holders can burn GCS using this contract to get GRT tokens back according to the
 * bonding curve.
 */
contract L2Curation is CurationV2Storage, GraphUpgradeable, IL2Curation {
    using SafeMathUpgradeable for uint256;

    /// @dev 100% in parts per million
    uint32 private constant MAX_PPM = 1000000;

    /// @dev Amount of signal you get with your minimum token deposit
    uint256 private constant SIGNAL_PER_MINIMUM_DEPOSIT = 1e18; // 1 signal as 18 decimal number

    /// @dev Reserve ratio for all subgraphs set to 100% for a flat bonding curve
    uint32 private immutable fixedReserveRatio = MAX_PPM;

    // -- Events --

    /**
     * @dev Emitted when `curator` deposited `tokens` on `subgraphDeploymentID` as curation signal.
     * The `curator` receives `signal` amount according to the curation pool bonding curve.
     * An amount of `curationTax` will be collected and burned.
     */
    event Signalled(
        address indexed curator,
        bytes32 indexed subgraphDeploymentID,
        uint256 tokens,
        uint256 signal,
        uint256 curationTax
    );

    /**
     * @dev Emitted when `curator` burned `signal` for a `subgraphDeploymentID`.
     * The curator will receive `tokens` according to the value of the bonding curve.
     */
    event Burned(
        address indexed curator,
        bytes32 indexed subgraphDeploymentID,
        uint256 tokens,
        uint256 signal
    );

    /**
     * @dev Emitted when `tokens` amount were collected for `subgraphDeploymentID` as part of fees
     * distributed by an indexer from query fees received from state channels.
     */
    event Collected(bytes32 indexed subgraphDeploymentID, uint256 tokens);

    /**
     * @dev Modifier for functions that can only be called by the GNS contract
     */
    modifier onlyGNS() {
        require(msg.sender == address(gns()), "Only the GNS can call this");
        _;
    }

    /**
     * @notice Initialize the L2Curation contract
     * @param _controller Controller contract that manages this contract
     * @param _curationTokenMaster Address of the GraphCurationToken master copy
     * @param _curationTaxPercentage Percentage of curation tax to be collected
     * @param _minimumCurationDeposit Minimum amount of tokens that can be deposited as curation signal
     */
    function initialize(
        address _controller,
        address _curationTokenMaster,
        uint32 _curationTaxPercentage,
        uint256 _minimumCurationDeposit
    ) external onlyImpl initializer {
        Managed._initialize(_controller);

        // For backwards compatibility:
        defaultReserveRatio = fixedReserveRatio;
        emit ParameterUpdated("defaultReserveRatio");
        _setCurationTaxPercentage(_curationTaxPercentage);
        _setMinimumCurationDeposit(_minimumCurationDeposit);
        _setCurationTokenMaster(_curationTokenMaster);
    }

    /**
     * @notice Set the default reserve ratio - not implemented in L2
     * @dev We only keep this for compatibility with ICuration
     */
    function setDefaultReserveRatio(uint32) external view override onlyGovernor {
        revert("Not implemented in L2");
    }

    /**
     * @dev Set the minimum deposit amount for curators.
     * @notice Update the minimum deposit amount to `_minimumCurationDeposit`
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit)
        external
        override
        onlyGovernor
    {
        _setMinimumCurationDeposit(_minimumCurationDeposit);
    }

    /**
     * @notice Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function setCurationTaxPercentage(uint32 _percentage) external override onlyGovernor {
        _setCurationTaxPercentage(_percentage);
    }

    /**
     * @notice Set the master copy to use as clones for the curation token.
     * @param _curationTokenMaster Address of implementation contract to use for curation tokens
     */
    function setCurationTokenMaster(address _curationTokenMaster) external override onlyGovernor {
        _setCurationTokenMaster(_curationTokenMaster);
    }

    /**
     * @notice Assign Graph Tokens collected as curation fees to the curation pool reserve.
     * @dev This function can only be called by the Staking contract and will do the bookeeping of
     * transferred tokens into this contract.
     * @param _subgraphDeploymentID SubgraphDeployment where funds should be allocated as reserves
     * @param _tokens Amount of Graph Tokens to add to reserves
     */
    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external override {
        // Only Staking contract is authorized as caller
        require(msg.sender == address(staking()), "Caller must be the staking contract");

        // Must be curated to accept tokens
        require(
            isCurated(_subgraphDeploymentID),
            "Subgraph deployment must be curated to collect fees"
        );

        // Collect new funds into reserve
        CurationPool storage curationPool = pools[_subgraphDeploymentID];
        curationPool.tokens = curationPool.tokens.add(_tokens);

        emit Collected(_subgraphDeploymentID, _tokens);
    }

    /**
     * @notice Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @param _signalOutMin Expected minimum amount of signal to receive
     * @return Signal minted and deposit tax
     */
    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external override notPartialPaused returns (uint256, uint256) {
        // Need to deposit some funds
        require(_tokensIn != 0, "Cannot deposit zero tokens");

        // Exchange GRT tokens for GCS of the subgraph pool
        (uint256 signalOut, uint256 curationTax) = tokensToSignal(_subgraphDeploymentID, _tokensIn);

        // Slippage protection
        require(signalOut >= _signalOutMin, "Slippage protection");

        address curator = msg.sender;
        CurationPool storage curationPool = pools[_subgraphDeploymentID];

        // If it hasn't been curated before then initialize the curve
        if (!isCurated(_subgraphDeploymentID)) {
            // Note we don't set the reserveRatio to save the gas
            // cost, but in the pools() getter we'll inject the value.

            // If no signal token for the pool - create one
            if (address(curationPool.gcs) == address(0)) {
                // Use a minimal proxy to reduce gas cost
                IGraphCurationToken gcs = IGraphCurationToken(
                    ClonesUpgradeable.clone(curationTokenMaster)
                );
                gcs.initialize(address(this));
                curationPool.gcs = gcs;
            }
        }

        // Trigger update rewards calculation snapshot
        _updateRewards(_subgraphDeploymentID);

        // Transfer tokens from the curator to this contract
        // Burn the curation tax
        // NOTE: This needs to happen after _updateRewards snapshot as that function
        // is using balanceOf(curation)
        IGraphToken _graphToken = graphToken();
        TokenUtils.pullTokens(_graphToken, curator, _tokensIn);
        TokenUtils.burnTokens(_graphToken, curationTax);

        // Update curation pool
        curationPool.tokens = curationPool.tokens.add(_tokensIn.sub(curationTax));
        curationPool.gcs.mint(curator, signalOut);

        emit Signalled(curator, _subgraphDeploymentID, _tokensIn, signalOut, curationTax);

        return (signalOut, curationTax);
    }

    /**
     * @notice Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @dev This function charges no tax and can only be called by GNS in specific scenarios (for now
     * only during an L1-L2 migration).
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @return Signal minted
     */
    function mintTaxFree(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        override
        notPartialPaused
        onlyGNS
        returns (uint256)
    {
        // Need to deposit some funds
        require(_tokensIn != 0, "Cannot deposit zero tokens");

        // Exchange GRT tokens for GCS of the subgraph pool (no tax)
        uint256 signalOut = _tokensToSignal(_subgraphDeploymentID, _tokensIn);

        address curator = msg.sender;
        CurationPool storage curationPool = pools[_subgraphDeploymentID];

        // If it hasn't been curated before then initialize the curve
        if (!isCurated(_subgraphDeploymentID)) {
            // Note we don't set the reserveRatio to save the gas
            // cost, but in the pools() getter we'll inject the value.

            // If no signal token for the pool - create one
            if (address(curationPool.gcs) == address(0)) {
                // Use a minimal proxy to reduce gas cost
                IGraphCurationToken gcs = IGraphCurationToken(
                    ClonesUpgradeable.clone(curationTokenMaster)
                );
                gcs.initialize(address(this));
                curationPool.gcs = gcs;
            }
        }

        // Trigger update rewards calculation snapshot
        _updateRewards(_subgraphDeploymentID);

        // Transfer tokens from the curator to this contract
        // NOTE: This needs to happen after _updateRewards snapshot as that function
        // is using balanceOf(curation)
        IGraphToken _graphToken = graphToken();
        TokenUtils.pullTokens(_graphToken, curator, _tokensIn);

        // Update curation pool
        curationPool.tokens = curationPool.tokens.add(_tokensIn);
        curationPool.gcs.mint(curator, signalOut);

        emit Signalled(curator, _subgraphDeploymentID, _tokensIn, signalOut, 0);

        return signalOut;
    }

    /**
     * @dev Return an amount of signal to get tokens back.
     * @notice Burn _signalIn from the SubgraphDeployment curation pool
     * @param _subgraphDeploymentID SubgraphDeployment for which the curator is returning signal
     * @param _signalIn Amount of signal to return
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     * @return Amount of tokens returned to the sender
     */
    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external override notPartialPaused returns (uint256) {
        address curator = msg.sender;

        // Validations
        require(_signalIn != 0, "Cannot burn zero signal");
        require(
            getCuratorSignal(curator, _subgraphDeploymentID) >= _signalIn,
            "Cannot burn more signal than you own"
        );

        // Get the amount of tokens to refund based on returned signal
        uint256 tokensOut = signalToTokens(_subgraphDeploymentID, _signalIn);

        // Slippage protection
        require(tokensOut >= _tokensOutMin, "Slippage protection");

        // Trigger update rewards calculation
        _updateRewards(_subgraphDeploymentID);

        // Update curation pool
        CurationPool storage curationPool = pools[_subgraphDeploymentID];
        curationPool.tokens = curationPool.tokens.sub(tokensOut);
        curationPool.gcs.burnFrom(curator, _signalIn);

        // If all signal burnt delete the curation pool except for the
        // curation token contract to avoid recreating it on a new mint
        if (getCurationPoolSignal(_subgraphDeploymentID) == 0) {
            curationPool.tokens = 0;
        }

        // Return the tokens to the curator
        TokenUtils.pushTokens(graphToken(), curator, tokensOut);

        emit Burned(curator, _subgraphDeploymentID, tokensOut, _signalIn);

        return tokensOut;
    }

    /**
     * @notice Get the amount of token reserves in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of token reserves in the curation pool
     */
    function getCurationPoolTokens(bytes32 _subgraphDeploymentID)
        external
        view
        override
        returns (uint256)
    {
        return pools[_subgraphDeploymentID].tokens;
    }

    /**
     * @notice Check if any GRT tokens are deposited for a SubgraphDeployment.
     * @param _subgraphDeploymentID SubgraphDeployment to check if curated
     * @return True if curated
     */
    function isCurated(bytes32 _subgraphDeploymentID) public view override returns (bool) {
        return pools[_subgraphDeploymentID].tokens != 0;
    }

    /**
     * @notice Get the amount of signal a curator has in a curation pool.
     * @param _curator Curator owning the signal tokens
     * @param _subgraphDeploymentID Subgraph deployment curation pool
     * @return Amount of signal owned by a curator for the subgraph deployment
     */
    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        public
        view
        override
        returns (uint256)
    {
        IGraphCurationToken gcs = pools[_subgraphDeploymentID].gcs;
        return (address(gcs) == address(0)) ? 0 : gcs.balanceOf(_curator);
    }

    /**
     * @notice Get the amount of signal in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of signal minted for the subgraph deployment
     */
    function getCurationPoolSignal(bytes32 _subgraphDeploymentID)
        public
        view
        override
        returns (uint256)
    {
        IGraphCurationToken gcs = pools[_subgraphDeploymentID].gcs;
        return (address(gcs) == address(0)) ? 0 : gcs.totalSupply();
    }

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation pool.
     * This function considers and excludes the deposit tax.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought
     * @return Amount of GRT that would be subtracted as curation tax
     */
    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 curationTax = _tokensIn.mul(uint256(curationTaxPercentage)).div(MAX_PPM);
        uint256 signalOut = _tokensToSignal(_subgraphDeploymentID, _tokensIn.sub(curationTax));
        return (signalOut, curationTax);
    }

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation pool,
     * without accounting for curation tax.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought
     */
    function tokensToSignalNoTax(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        public
        view
        override
        returns (uint256)
    {
        return _tokensToSignal(_subgraphDeploymentID, _tokensIn);
    }

    /**
     * @notice Calculate number of tokens to get when burning signal from a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment for which to burn signal
     * @param _signalIn Amount of signal to burn
     * @return Amount of tokens to get for an amount of signal
     */
    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        public
        view
        override
        returns (uint256)
    {
        CurationPool memory curationPool = pools[_subgraphDeploymentID];
        uint256 curationPoolSignal = getCurationPoolSignal(_subgraphDeploymentID);
        require(
            curationPool.tokens != 0,
            "Subgraph deployment must be curated to perform calculations"
        );
        require(
            curationPoolSignal >= _signalIn,
            "Signal must be above or equal to signal issued in the curation pool"
        );

        return curationPool.tokens.mul(_signalIn).div(curationPoolSignal);
    }

    /**
     * @dev Internal: Set the minimum deposit amount for curators.
     * Update the minimum deposit amount to `_minimumCurationDeposit`
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function _setMinimumCurationDeposit(uint256 _minimumCurationDeposit) private {
        require(_minimumCurationDeposit != 0, "Minimum curation deposit cannot be 0");

        minimumCurationDeposit = _minimumCurationDeposit;
        emit ParameterUpdated("minimumCurationDeposit");
    }

    /**
     * @dev Internal: Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function _setCurationTaxPercentage(uint32 _percentage) private {
        require(
            _percentage <= MAX_PPM,
            "Curation tax percentage must be below or equal to MAX_PPM"
        );

        curationTaxPercentage = _percentage;
        emit ParameterUpdated("curationTaxPercentage");
    }

    /**
     * @dev Internal: Set the master copy to use as clones for the curation token.
     * @param _curationTokenMaster Address of implementation contract to use for curation tokens
     */
    function _setCurationTokenMaster(address _curationTokenMaster) private {
        require(_curationTokenMaster != address(0), "Token master must be non-empty");
        require(
            AddressUpgradeable.isContract(_curationTokenMaster),
            "Token master must be a contract"
        );

        curationTokenMaster = _curationTokenMaster;
        emit ParameterUpdated("curationTokenMaster");
    }

    /**
     * @dev Triggers an update of rewards due to a change in signal.
     * @param _subgraphDeploymentID Subgraph deployment updated
     */
    function _updateRewards(bytes32 _subgraphDeploymentID) private {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) != address(0)) {
            rewardsManager.onSubgraphSignalUpdate(_subgraphDeploymentID);
        }
    }

    /**
     * @dev Calculate amount of signal that can be bought with tokens in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought with tokens
     */
    function _tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        private
        view
        returns (uint256)
    {
        // Get curation pool tokens and signal
        CurationPool memory curationPool = pools[_subgraphDeploymentID];

        // Init curation pool
        if (curationPool.tokens == 0) {
            require(
                _tokensIn >= minimumCurationDeposit,
                "Curation deposit is below minimum required"
            );
            return
                SIGNAL_PER_MINIMUM_DEPOSIT.add(
                    SIGNAL_PER_MINIMUM_DEPOSIT.mul(_tokensIn.sub(minimumCurationDeposit)).div(
                        minimumCurationDeposit
                    )
                );
        }

        return getCurationPoolSignal(_subgraphDeploymentID).mul(_tokensIn).div(curationPool.tokens);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
library SafeMathUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IGraphProxy } from "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
abstract contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl() {
        require(msg.sender == _implementation(), "Only implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Accept to be an implementation of proxy.
     * @param _proxy Proxy to accept
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @notice Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     * @param _proxy Proxy to accept
     * @param _data Calldata for the initialization function call (including selector)
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "../token/IGraphToken.sol";

library TokenUtils {
    /**
     * @dev Pull tokens from an address to this contract.
     * @param _graphToken Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IGraphToken _graphToken,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _graphToken Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IGraphToken _graphToken,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            require(_graphToken.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _graphToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(IGraphToken _graphToken, uint256 _amount) internal {
        if (_amount > 0) {
            _graphToken.burn(_amount);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IRewardsManager {
    /**
     * @dev Stores accumulated rewards and snapshots related to a particular SubgraphDeployment.
     */
    struct Subgraph {
        uint256 accRewardsForSubgraph;
        uint256 accRewardsForSubgraphSnapshot;
        uint256 accRewardsPerSignalSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    // -- Config --

    function setIssuancePerBlock(uint256 _issuancePerBlock) external;

    function setMinimumSubgraphSignal(uint256 _minimumSubgraphSignal) external;

    // -- Denylist --

    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle) external;

    function setDenied(bytes32 _subgraphDeploymentID, bool _deny) external;

    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external;

    function isDenied(bytes32 _subgraphDeploymentID) external view returns (bool);

    // -- Getters --

    function getNewRewardsPerSignal() external view returns (uint256);

    function getAccRewardsPerSignal() external view returns (uint256);

    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256, uint256);

    function getRewards(address _allocationID) external view returns (uint256);

    // -- Updates --

    function updateAccRewardsPerSignal() external returns (uint256);

    function takeRewards(address _allocationID) external returns (uint256);

    // -- Hooks --

    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);

    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

import { ICuration } from "../curation/ICuration.sol";
import { IEpochManager } from "../epochs/IEpochManager.sol";
import { IRewardsManager } from "../rewards/IRewardsManager.sol";
import { IStaking } from "../staking/IStaking.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { ITokenGateway } from "../arbitrum/ITokenGateway.sol";
import { IGNS } from "../discovery/IGNS.sol";

import { IManaged } from "./IManaged.sol";

/**
 * @title Graph Managed contract
 * @dev The Managed contract provides an interface to interact with the Controller.
 * It also provides local caching for contract addresses. This mechanism relies on calling the
 * public `syncAllContracts()` function whenever a contract changes in the controller.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract Managed is IManaged {
    // -- State --

    /// Controller that manages this contract
    IController public override controller;
    /// @dev Cache for the addresses of the contracts retrieved from the controller
    mapping(bytes32 => address) private _addressCache;
    /// @dev Gap for future storage variables
    uint256[10] private __gap;

    // Immutables
    bytes32 private immutable CURATION = keccak256("Curation");
    bytes32 private immutable EPOCH_MANAGER = keccak256("EpochManager");
    bytes32 private immutable REWARDS_MANAGER = keccak256("RewardsManager");
    bytes32 private immutable STAKING = keccak256("Staking");
    bytes32 private immutable GRAPH_TOKEN = keccak256("GraphToken");
    bytes32 private immutable GRAPH_TOKEN_GATEWAY = keccak256("GraphTokenGateway");
    bytes32 private immutable GNS = keccak256("GNS");

    // -- Events --

    /// Emitted when a contract parameter has been updated
    event ParameterUpdated(string param);
    /// Emitted when the controller address has been set
    event SetController(address controller);

    /// Emitted when contract with `nameHash` is synced to `contractAddress`.
    event ContractSynced(bytes32 indexed nameHash, address contractAddress);

    // -- Modifiers --

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    function _notPartialPaused() internal view {
        require(!controller.paused(), "Paused");
        require(!controller.partialPaused(), "Partial-paused");
    }

    /**
     * @dev Revert if the controller is paused
     */
    function _notPaused() internal view virtual {
        require(!controller.paused(), "Paused");
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    function _onlyGovernor() internal view {
        require(msg.sender == controller.getGovernor(), "Only Controller governor");
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    function _onlyController() internal view {
        require(msg.sender == address(controller), "Caller must be Controller");
    }

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    modifier notPartialPaused() {
        _notPartialPaused();
        _;
    }

    /**
     * @dev Revert if the controller is paused
     */
    modifier notPaused() {
        _notPaused();
        _;
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    // -- Functions --

    /**
     * @dev Initialize a Managed contract
     * @param _controller Address for the Controller that manages this contract
     */
    function _initialize(address _controller) internal {
        _setController(_controller);
    }

    /**
     * @notice Set Controller. Only callable by current controller.
     * @param _controller Controller contract address
     */
    function setController(address _controller) external override onlyController {
        _setController(_controller);
    }

    /**
     * @dev Set controller.
     * @param _controller Controller contract address
     */
    function _setController(address _controller) internal {
        require(_controller != address(0), "Controller must be set");
        controller = IController(_controller);
        emit SetController(_controller);
    }

    /**
     * @dev Return Curation interface
     * @return Curation contract registered with Controller
     */
    function curation() internal view returns (ICuration) {
        return ICuration(_resolveContract(CURATION));
    }

    /**
     * @dev Return EpochManager interface
     * @return Epoch manager contract registered with Controller
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(EPOCH_MANAGER));
    }

    /**
     * @dev Return RewardsManager interface
     * @return Rewards manager contract registered with Controller
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(REWARDS_MANAGER));
    }

    /**
     * @dev Return Staking interface
     * @return Staking contract registered with Controller
     */
    function staking() internal view returns (IStaking) {
        return IStaking(_resolveContract(STAKING));
    }

    /**
     * @dev Return GraphToken interface
     * @return Graph token contract registered with Controller
     */
    function graphToken() internal view returns (IGraphToken) {
        return IGraphToken(_resolveContract(GRAPH_TOKEN));
    }

    /**
     * @dev Return GraphTokenGateway (L1 or L2) interface
     * @return Graph token gateway contract registered with Controller
     */
    function graphTokenGateway() internal view returns (ITokenGateway) {
        return ITokenGateway(_resolveContract(GRAPH_TOKEN_GATEWAY));
    }

    /**
     * @dev Return GNS (L1 or L2) interface.
     * @return Address of the GNS contract registered with Controller, as an IGNS interface.
     */
    function gns() internal view returns (IGNS) {
        return IGNS(_resolveContract(GNS));
    }

    /**
     * @dev Resolve a contract address from the cache or the Controller if not found.
     * @param _nameHash keccak256 hash of the contract name
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = _addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = controller.getContractProxy(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @dev Cache a contract address from the Controller registry.
     * @param _nameHash keccak256 hash of the name of the contract to sync into the cache
     */
    function _syncContract(bytes32 _nameHash) internal {
        address contractAddress = controller.getContractProxy(_nameHash);
        if (_addressCache[_nameHash] != contractAddress) {
            _addressCache[_nameHash] = contractAddress;
            emit ContractSynced(_nameHash, contractAddress);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version
     */
    function syncAllContracts() external override {
        _syncContract(CURATION);
        _syncContract(EPOCH_MANAGER);
        _syncContract(REWARDS_MANAGER);
        _syncContract(STAKING);
        _syncContract(GRAPH_TOKEN);
        _syncContract(GRAPH_TOKEN_GATEWAY);
        _syncContract(GNS);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function burnFrom(address _from, uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    // -- Allowance --

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import { ICuration } from "./ICuration.sol";
import { IGraphCurationToken } from "./IGraphCurationToken.sol";
import { Managed } from "../governance/Managed.sol";

/**
 * @title Curation Storage version 1
 * @dev This contract holds the first version of the storage variables
 * for the Curation and L2Curation contracts.
 * When adding new variables, create a new version that inherits this and update
 * the contracts to use the new version instead.
 */
abstract contract CurationV1Storage is Managed, ICuration {
    // -- Pool --

    /**
     * @dev CurationPool structure that holds the pool's state
     * for a particular subgraph deployment.
     */
    struct CurationPool {
        uint256 tokens; // GRT Tokens stored as reserves for the subgraph deployment
        uint32 reserveRatio; // Ratio for the bonding curve, unused and deprecated in L2 where it will always be 100% but appear as 0
        IGraphCurationToken gcs; // Curation token contract for this curation pool
    }

    // -- State --

    /// Tax charged when curators deposit funds.
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public override curationTaxPercentage;

    /// Default reserve ratio to configure curator shares bonding curve
    /// Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%).
    /// Unused in L2.
    uint32 public defaultReserveRatio;

    /// Master copy address that holds implementation of curation token.
    /// @dev This is used as the target for GraphCurationToken clones.
    address public curationTokenMaster;

    /// Minimum amount allowed to be deposited by curators to initialize a pool
    /// @dev This is the `startPoolBalance` for the bonding curve
    uint256 public minimumCurationDeposit;

    /// Bonding curve library
    /// Unused in L2.
    address public bondingCurve;

    /// @dev Mapping of subgraphDeploymentID => CurationPool
    /// There is only one CurationPool per SubgraphDeploymentID
    mapping(bytes32 => CurationPool) public pools;
}

/**
 * @title Curation Storage version 2
 * @dev This contract holds the second version of the storage variables
 * for the Curation and L2Curation contracts.
 * It doesn't add new variables at this contract's level, but adds the Initializable
 * contract to the inheritance chain, which includes storage variables.
 * When adding new variables, create a new version that inherits this and update
 * the contracts to use the new version instead.
 */
abstract contract CurationV2Storage is CurationV1Storage, Initializable {
    // Nothing here, just adding Initializable
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGraphCurationToken is IERC20Upgradeable {
    function initialize(address _owner) external;

    function burnFrom(address _account, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Interface of the L2 Curation contract.
 */
interface IL2Curation {
    /**
     * @notice Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @dev This function charges no tax and can only be called by GNS in specific scenarios (for now
     * only during an L1-L2 migration).
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @return Signal minted
     */
    function mintTaxFree(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        returns (uint256);

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation pool,
     * without accounting for curation tax.
     * @param _subgraphDeploymentID Subgraph deployment for which to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought
     */
    function tokensToSignalNoTax(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Curation Interface
 * @dev Interface for the Curation contract (and L2Curation too)
 */
interface ICuration {
    // -- Configuration --

    /**
     * @notice Update the default reserve ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Update the minimum deposit amount needed to intialize a new subgraph
     * @param _minimumCurationDeposit Minimum amount of tokens required deposit
     */
    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit) external;

    /**
     * @notice Set the curation tax percentage to charge when a curator deposits GRT tokens.
     * @param _percentage Curation tax percentage charged when depositing GRT tokens
     */
    function setCurationTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set the master copy to use as clones for the curation token.
     * @param _curationTokenMaster Address of implementation contract to use for curation tokens
     */
    function setCurationTokenMaster(address _curationTokenMaster) external;

    // -- Curation --

    /**
     * @notice Deposit Graph Tokens in exchange for signal of a SubgraphDeployment curation pool.
     * @param _subgraphDeploymentID Subgraph deployment pool from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @param _signalOutMin Expected minimum amount of signal to receive
     * @return Amount of signal minted
     * @return Amount of curation tax burned
     */
    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);

    /**
     * @notice Burn _signal from the SubgraphDeployment curation pool
     * @param _subgraphDeploymentID SubgraphDeployment the curator is returning signal
     * @param _signalIn Amount of signal to return
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     * @return Tokens returned
     */
    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    /**
     * @notice Assign Graph Tokens collected as curation fees to the curation pool reserve.
     * @param _subgraphDeploymentID SubgraphDeployment where funds should be allocated as reserves
     * @param _tokens Amount of Graph Tokens to add to reserves
     */
    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external;

    // -- Getters --

    /**
     * @notice Check if any GRT tokens are deposited for a SubgraphDeployment.
     * @param _subgraphDeploymentID SubgraphDeployment to check if curated
     * @return True if curated, false otherwise
     */
    function isCurated(bytes32 _subgraphDeploymentID) external view returns (bool);

    /**
     * @notice Get the amount of signal a curator has in a curation pool.
     * @param _curator Curator owning the signal tokens
     * @param _subgraphDeploymentID Subgraph deployment curation pool
     * @return Amount of signal owned by a curator for the subgraph deployment
     */
    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of signal in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of signal minted for the subgraph deployment
     */
    function getCurationPoolSignal(bytes32 _subgraphDeploymentID) external view returns (uint256);

    /**
     * @notice Get the amount of token reserves in a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment curation poool
     * @return Amount of token reserves in the curation pool
     */
    function getCurationPoolTokens(bytes32 _subgraphDeploymentID) external view returns (uint256);

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation pool.
     * This function considers and excludes the deposit tax.
     * @param _subgraphDeploymentID Subgraph deployment to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought
     * @return Amount of tokens that will be burned as curation tax
     */
    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning signal from a curation pool.
     * @param _subgraphDeploymentID Subgraph deployment to burn signal
     * @param _signalIn Amount of signal to burn
     * @return Amount of tokens to get for the specified amount of signal
     */
    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Tax charged when curators deposit funds.
     * Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
     * @return Curation tax percentage expressed in PPM
     */
    function curationTaxPercentage() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import "./IStakingData.sol";

interface IStaking is IStakingData {
    // -- Allocation Data --

    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    // -- Configuration --

    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    function setThawingPeriod(uint32 _thawingPeriod) external;

    function setCurationPercentage(uint32 _percentage) external;

    function setProtocolPercentage(uint32 _percentage) external;

    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    function setDelegationRatio(uint32 _delegationRatio) external;

    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) external;

    function setDelegationParametersCooldown(uint32 _blocks) external;

    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    function setDelegationTaxPercentage(uint32 _percentage) external;

    function setSlasher(address _slasher, bool _allowed) external;

    function setAssetHolder(address _assetHolder, bool _allowed) external;

    // -- Operation --

    function setOperator(address _operator, bool _allowed) external;

    function isOperator(address _operator, address _indexer) external view returns (bool);

    // -- Staking --

    function stake(uint256 _tokens) external;

    function stakeTo(address _indexer, uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    function withdraw() external;

    function setRewardsDestination(address _destination) external;

    // -- Delegation --

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    // -- Channel management and allocations --

    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function closeAllocation(address _allocationID, bytes32 _poi) external;

    function closeAllocationMany(CloseAllocationRequest[] calldata _requests) external;

    function closeAndAllocate(
        address _oldAllocationID,
        bytes32 _poi,
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function collect(uint256 _tokens, address _allocationID) external;

    function claim(address _allocationID, bool _restake) external;

    function claimMany(address[] calldata _allocationID, bool _restake) external;

    // -- Getters and calculations --

    function hasStake(address _indexer) external view returns (bool);

    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    function getIndexerCapacity(address _indexer) external view returns (uint256);

    function getAllocation(address _allocationID) external view returns (Allocation memory);

    function getAllocationState(address _allocationID) external view returns (AllocationState);

    function isAllocation(address _allocationID) external view returns (bool);

    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    function isDelegator(address _indexer, address _delegator) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-peripherals
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.7.6 ([email protected])
 *
 */

pragma solidity ^0.7.6;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deployed or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

/**
 * @title Interface for GNS
 */
interface IGNS {
    // -- Pool --

    /**
     * @dev The SubgraphData struct holds information about subgraphs
     * and their signal; both nSignal (i.e. name signal at the GNS level)
     * and vSignal (i.e. version signal at the Curation contract level)
     */
    struct SubgraphData {
        uint256 vSignal; // The token of the subgraph-deployment bonding curve
        uint256 nSignal; // The token of the subgraph bonding curve
        mapping(address => uint256) curatorNSignal;
        bytes32 subgraphDeploymentID;
        uint32 reserveRatioDeprecated; // Ratio for the bonding curve, always 1 in PPM, deprecated.
        bool disabled;
        uint256 withdrawableGRT;
    }

    /**
     * @dev The LegacySubgraphKey struct holds the account and sequence ID
     * used to generate subgraph IDs in legacy subgraphs.
     */
    struct LegacySubgraphKey {
        address account;
        uint256 accountSeqID;
    }

    // -- Configuration --

    /**
     * @notice Approve curation contract to pull funds.
     */
    function approveAll() external;

    /**
     * @notice Set the owner fee percentage. This is used to prevent a subgraph owner to drain all
     * the name curators tokens while upgrading or deprecating and is configurable in parts per million.
     * @param _ownerTaxPercentage Owner tax percentage
     */
    function setOwnerTaxPercentage(uint32 _ownerTaxPercentage) external;

    // -- Publishing --

    /**
     * @notice Allows a graph account to set a default name
     * @param _graphAccount Account that is setting its name
     * @param _nameSystem Name system account already has ownership of a name in
     * @param _nameIdentifier The unique identifier that is used to identify the name in the system
     * @param _name The name being set as default
     */
    function setDefaultName(
        address _graphAccount,
        uint8 _nameSystem,
        bytes32 _nameIdentifier,
        string calldata _name
    ) external;

    /**
     * @notice Allows a subgraph owner to update the metadata of a subgraph they have published
     * @param _subgraphID Subgraph ID
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function updateSubgraphMetadata(uint256 _subgraphID, bytes32 _subgraphMetadata) external;

    /**
     * @notice Publish a new subgraph.
     * @param _subgraphDeploymentID Subgraph deployment for the subgraph
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     * @param _subgraphMetadata IPFS hash for the subgraph metadata
     */
    function publishNewSubgraph(
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata,
        bytes32 _subgraphMetadata
    ) external;

    /**
     * @notice Publish a new version of an existing subgraph.
     * @param _subgraphID Subgraph ID
     * @param _subgraphDeploymentID Subgraph deployment ID of the new version
     * @param _versionMetadata IPFS hash for the subgraph version metadata
     */
    function publishNewVersion(
        uint256 _subgraphID,
        bytes32 _subgraphDeploymentID,
        bytes32 _versionMetadata
    ) external;

    /**
     * @notice Deprecate a subgraph. The bonding curve is destroyed, the vSignal is burned, and the GNS
     * contract holds the GRT from burning the vSignal, which all curators can withdraw manually.
     * Can only be done by the subgraph owner.
     * @param _subgraphID Subgraph ID
     */
    function deprecateSubgraph(uint256 _subgraphID) external;

    // -- Curation --

    /**
     * @notice Deposit GRT into a subgraph and mint signal.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn The amount of tokens the nameCurator wants to deposit
     * @param _nSignalOutMin Expected minimum amount of name signal to receive
     */
    function mintSignal(
        uint256 _subgraphID,
        uint256 _tokensIn,
        uint256 _nSignalOutMin
    ) external;

    /**
     * @notice Burn signal for a subgraph and return the GRT.
     * @param _subgraphID Subgraph ID
     * @param _nSignal The amount of nSignal the nameCurator wants to burn
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     */
    function burnSignal(
        uint256 _subgraphID,
        uint256 _nSignal,
        uint256 _tokensOutMin
    ) external;

    /**
     * @notice Move subgraph signal from sender to `_recipient`
     * @param _subgraphID Subgraph ID
     * @param _recipient Address to send the signal to
     * @param _amount The amount of nSignal to transfer
     */
    function transferSignal(
        uint256 _subgraphID,
        address _recipient,
        uint256 _amount
    ) external;

    /**
     * @notice Withdraw tokens from a deprecated subgraph.
     * When the subgraph is deprecated, any curator can call this function and
     * withdraw the GRT they are entitled for its original deposit
     * @param _subgraphID Subgraph ID
     */
    function withdraw(uint256 _subgraphID) external;

    // -- Getters --

    /**
     * @notice Return the owner of a subgraph.
     * @param _tokenID Subgraph ID
     * @return Owner address
     */
    function ownerOf(uint256 _tokenID) external view returns (address);

    /**
     * @notice Return the total signal on the subgraph.
     * @param _subgraphID Subgraph ID
     * @return Total signal on the subgraph
     */
    function subgraphSignal(uint256 _subgraphID) external view returns (uint256);

    /**
     * @notice Return the total tokens on the subgraph at current value.
     * @param _subgraphID Subgraph ID
     * @return Total tokens on the subgraph
     */
    function subgraphTokens(uint256 _subgraphID) external view returns (uint256);

    /**
     * @notice Calculate subgraph signal to be returned for an amount of tokens.
     * @param _subgraphID Subgraph ID
     * @param _tokensIn Tokens being exchanged for subgraph signal
     * @return Amount of subgraph signal and curation tax
     */
    function tokensToNSignal(uint256 _subgraphID, uint256 _tokensIn)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Calculate tokens returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for tokens
     * @return Amount of tokens returned for an amount of subgraph signal
     */
    function nSignalToTokens(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate subgraph signal to be returned for an amount of subgraph deployment signal.
     * @param _subgraphID Subgraph ID
     * @param _vSignalIn Amount of subgraph deployment signal to exchange for subgraph signal
     * @return Amount of subgraph signal that can be bought
     */
    function vSignalToNSignal(uint256 _subgraphID, uint256 _vSignalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Calculate subgraph deployment signal to be returned for an amount of subgraph signal.
     * @param _subgraphID Subgraph ID
     * @param _nSignalIn Subgraph signal being exchanged for subgraph deployment signal
     * @return Amount of subgraph deployment signal that can be returned
     */
    function nSignalToVSignal(uint256 _subgraphID, uint256 _nSignalIn)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of subgraph signal a curator has.
     * @param _subgraphID Subgraph ID
     * @param _curator Curator address
     * @return Amount of subgraph signal owned by a curator
     */
    function getCuratorSignal(uint256 _subgraphID, address _curator)
        external
        view
        returns (uint256);

    /**
     * @notice Return whether a subgraph is published.
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is currently published
     */
    function isPublished(uint256 _subgraphID) external view returns (bool);

    /**
     * @notice Return whether a subgraph is a legacy subgraph (created before subgraph NFTs).
     * @param _subgraphID Subgraph ID
     * @return Return true if subgraph is a legacy subgraph
     */
    function isLegacySubgraph(uint256 _subgraphID) external view returns (bool);

    /**
     * @notice Returns account and sequence ID for a legacy subgraph (created before subgraph NFTs).
     * @param _subgraphID Subgraph ID
     * @return account Account that created the subgraph (or 0 if it's not a legacy subgraph)
     * @return seqID Sequence number for the subgraph
     */
    function getLegacySubgraphKey(uint256 _subgraphID)
        external
        view
        returns (address account, uint256 seqID);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

/**
 * @title Managed Interface
 * @dev Interface for contracts that can be managed by a controller.
 */
interface IManaged {
    /**
     * @notice Set the controller that manages this contract
     * @dev Only the current controller can set a new controller
     * @param _controller Address of the new controller
     */
    function setController(address _controller) external;

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses.
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version.
     */
    function syncAllContracts() external;

    /**
     * @notice Get the Controller that manages this contract
     * @return The Controller as an IController interface
     */
    function controller() external view returns (IController);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IStakingData {
    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 effectiveAllocation; // Effective allocation when closed
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
    }

    /**
     * @dev Represents a request to close an allocation with a specific proof of indexing.
     * This is passed when calling closeAllocationMany to define the closing parameters for
     * each allocation.
     */
    struct CloseAllocationRequest {
        address allocationID;
        bytes32 poi;
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";

import "../interfaces/IStakingThales.sol";
import "../interfaces/IVault.sol";

import "../utils/libraries/AddressSetLib.sol";

contract StakingThalesBonusRewardsManager is ProxyOwned, Initializable, ProxyReentrancyGuard {
    using AddressSetLib for AddressSetLib.AddressSet;

    uint private constant ONE = 1e18;

    struct LeaderboardStakerData {
        uint share;
        uint stakingMultiplier;
        uint userVaultBasePointsPerRound;
        uint userVaultPointsPerRound;
        uint userLPBasePointsPerRound;
        uint userLPPointsPerRound;
        uint userTradingBasePointsPerRound;
        uint userRoundBonusPoints;
    }

    /// @return the adddress of the staking contract
    address public stakingThales;

    uint public stakingBaseDivider;

    uint public maxStakingMultiplier;

    uint public vaultsMultiplier;
    uint public lpMultiplier;
    uint public tradingMultiplier;

    mapping(address => mapping(uint => uint)) public userVaultBasePointsPerRound;
    mapping(address => mapping(uint => uint)) public userLPBasePointsPerRound;
    mapping(address => mapping(uint => uint)) public userTradingBasePointsPerRound;
    mapping(address => mapping(uint => uint)) public userRoundBonusPoints;

    mapping(uint => uint) public totalVaultBasePointsPerRound;
    mapping(uint => uint) public totalLPBasePointsPerRound;
    mapping(uint => uint) public totalTradingBasePointsPerRound;
    mapping(uint => uint) public totalRoundBonusPoints;

    mapping(address => bool) public knownVaults;
    mapping(address => bool) public knownLiquidityPools;
    mapping(address => bool) public knownTradingAMMs;

    bool public useNewBonusModel;

    AddressSetLib.AddressSet internal vaults;
    AddressSetLib.AddressSet internal lps;

    struct EstimatedLeaderboardStakerData {
        uint stakingMultiplier;
        uint userVaultPointsPerRound;
        uint userLPPointsPerRound;
        uint userTradingBasePointsPerRound;
    }

    function initialize(address _owner, address _stakingThales) public initializer {
        setOwner(_owner);
        initNonReentrant();
        stakingThales = _stakingThales;
    }

    /// @notice Save gamified staking bonus points
    /// @param user to save points for
    /// @param origin where the points originated from (vaults, lp or trading)
    /// @param basePoints how many points were scored
    /// @param round in which round to store the points
    function storePoints(
        address user,
        address origin,
        uint basePoints,
        uint round
    ) external {
        require(msg.sender == stakingThales, "Only allowed from StakingThales");
        require(
            knownVaults[origin] || knownLiquidityPools[origin] || knownTradingAMMs[origin],
            "Only allowed for known origin"
        );
        if (IStakingThales(stakingThales).stakedBalanceOf(user) > 0) {
            uint multiplierToUse;
            if (knownVaults[origin]) {
                userVaultBasePointsPerRound[user][round] += basePoints;
                totalVaultBasePointsPerRound[round] += basePoints;
                multiplierToUse = vaultsMultiplier;
            } else if (knownLiquidityPools[origin]) {
                userLPBasePointsPerRound[user][round] += basePoints;
                totalLPBasePointsPerRound[round] += basePoints;
                multiplierToUse = lpMultiplier;
            } else if (knownTradingAMMs[origin]) {
                userTradingBasePointsPerRound[user][round] += basePoints;
                totalTradingBasePointsPerRound[round] += basePoints;
                multiplierToUse = tradingMultiplier;
            }
            uint newBonusPoints = ((ONE + getStakingMultiplier(user)) * ((basePoints * multiplierToUse) / ONE)) / ONE;
            userRoundBonusPoints[user][round] += newBonusPoints;
            totalRoundBonusPoints[round] += newBonusPoints;
            emit PointsStored(user, origin, basePoints, round);
        }
    }

    /// @notice Setting the SportAMMLiquidityPool
    /// @param _stakingThales Address of Staking contract
    function setStakingThales(address _stakingThales) external onlyOwner {
        stakingThales = _stakingThales;
        emit SetStakingThales(_stakingThales);
    }

    /// @notice Register or unregister a known vault to accept vault points from
    function setKnownVault(address vault, bool value) external onlyOwner {
        knownVaults[vault] = value;
        if (value) {
            vaults.add(vault);
        } else {
            vaults.remove(vault);
        }
        emit SetKnownVault(vault, value);
    }

    /// @notice Register or unregister a known liquidity pool to accept lp points from
    function setKnownLiquidityPool(address pool, bool value) external onlyOwner {
        knownLiquidityPools[pool] = value;
        if (value) {
            lps.add(pool);
        } else {
            lps.remove(pool);
        }
        emit SetKnownLiquidityPool(pool, value);
    }

    /// @notice Register or unregister a known AMM to accept trading points from
    function setKnownTradingAMM(address amm, bool value) external onlyOwner {
        knownTradingAMMs[amm] = value;
        emit SetKnownTradingAMM(amm, value);
    }

    /// @notice A value to use for the staking multiplier, e.g. 100k on Optimism
    function setStakingBaseDivider(uint value) external onlyOwner {
        stakingBaseDivider = value;
        emit SetStakingBaseDivider(value);
    }

    /// @notice Maximum value of Staking Multiplier
    function setMaxStakingMultiplier(uint value) external onlyOwner {
        maxStakingMultiplier = value;
        emit SetMaxStakingMultiplier(value);
    }

    /// @notice set multiplers for each category
    function setMultipliers(
        uint _vaultsMultiplier,
        uint _lpMultiplier,
        uint _tradingMultiplier
    ) external onlyOwner {
        vaultsMultiplier = _vaultsMultiplier;
        lpMultiplier = _lpMultiplier;
        tradingMultiplier = _tradingMultiplier;
        emit SetMultipliers(_vaultsMultiplier, _lpMultiplier, _tradingMultiplier);
    }

    /// @notice a boolean to use for when to turn the new model on.
    function setUseNewModel(bool value) external onlyOwner {
        useNewBonusModel = value;
        emit SetUseNewModel(value);
    }

    /// @notice add known vaults array
    function addVaults(address[] calldata _vaults, bool add) external onlyOwner {
        require(_vaults.length > 0, "vaults addresses cannot be empty");
        for (uint i = 0; i < _vaults.length; i++) {
            if (add) {
                vaults.add(_vaults[i]);
            } else {
                vaults.remove(_vaults[i]);
            }
        }
    }

    /// @notice add known lps array
    function addLPs(address[] calldata _lps, bool add) external onlyOwner {
        require(_lps.length > 0, "_lps addresses cannot be empty");
        for (uint i = 0; i < _lps.length; i++) {
            if (add) {
                lps.add(_lps[i]);
            } else {
                lps.remove(_lps[i]);
            }
        }
    }

    //***********************VIEWS***********************

    /// @notice return the share of bonus rewards per user per round.
    function getUserRoundBonusShare(address user, uint round) public view returns (uint userShare) {
        if (totalRoundBonusPoints[round] > 0) {
            userShare = (userRoundBonusPoints[user][round] * ONE) / totalRoundBonusPoints[round];
        }
    }

    /// @notice return the staking multipler per user
    function getStakingMultiplier(address user) public view returns (uint) {
        uint calculatedMultiplier = IStakingThales(stakingThales).stakedBalanceOf(user) / stakingBaseDivider;
        return calculatedMultiplier < maxStakingMultiplier ? calculatedMultiplier : maxStakingMultiplier;
    }

    /// @notice return leaderboard data
    function getStakersLeaderboardData(address[] calldata stakers, uint round)
        external
        view
        returns (LeaderboardStakerData[] memory)
    {
        LeaderboardStakerData[] memory stakersArray = new LeaderboardStakerData[](stakers.length);

        for (uint i = 0; i < stakers.length; i++) {
            stakersArray[i].share = getUserRoundBonusShare(stakers[i], round);
            stakersArray[i].stakingMultiplier = getStakingMultiplier(stakers[i]);
            stakersArray[i].userVaultBasePointsPerRound = userVaultBasePointsPerRound[stakers[i]][round];
            stakersArray[i].userLPBasePointsPerRound = userLPBasePointsPerRound[stakers[i]][round];
            stakersArray[i].userVaultPointsPerRound =
                (userVaultBasePointsPerRound[stakers[i]][round] * vaultsMultiplier) /
                ONE;
            stakersArray[i].userLPPointsPerRound = (userLPBasePointsPerRound[stakers[i]][round] * lpMultiplier) / ONE;
            stakersArray[i].userTradingBasePointsPerRound = userTradingBasePointsPerRound[stakers[i]][round];
            stakersArray[i].userRoundBonusPoints = userRoundBonusPoints[stakers[i]][round];
        }
        return stakersArray;
    }

    /// @notice return estimated leaderboard data
    function getEstimatedCurrentStakersLeaderboardData(address[] calldata stakers, uint round)
        external
        view
        returns (EstimatedLeaderboardStakerData[] memory)
    {
        EstimatedLeaderboardStakerData[] memory stakersArray = new EstimatedLeaderboardStakerData[](stakers.length);

        for (uint i = 0; i < stakers.length; i++) {
            stakersArray[i].stakingMultiplier = getStakingMultiplier(stakers[i]);
            stakersArray[i].userVaultPointsPerRound = getEstimatedCurrentVaultPoints(stakers[i]);
            stakersArray[i].userLPPointsPerRound = getEstimatedCurrentLPsPoints(stakers[i]);
            stakersArray[i].userTradingBasePointsPerRound = userTradingBasePointsPerRound[stakers[i]][round];
        }
        return stakersArray;
    }

    function getEstimatedCurrentVaultPoints(address user) public view returns (uint estimatedPoints) {
        uint userStakingMultiplier = getStakingMultiplier(user);
        uint numVaults = vaults.elements.length;
        address[] memory vaultsIterable = vaults.getPage(0, numVaults);
        for (uint i = 0; i < vaultsIterable.length; i++) {
            uint vaultRound = IVault(vaultsIterable[i]).round();
            uint vaultPoints = ((ONE + userStakingMultiplier) *
                ((IVault(vaultsIterable[i]).balancesPerRound(vaultRound, user) * vaultsMultiplier) / ONE)) / ONE;
            estimatedPoints += vaultPoints;
        }
    }

    function getEstimatedCurrentLPsPoints(address user) public view returns (uint estimatedPoints) {
        uint userStakingMultiplier = getStakingMultiplier(user);
        uint numLPs = lps.elements.length;
        address[] memory vaultsIterable = lps.getPage(0, numLPs);
        for (uint i = 0; i < vaultsIterable.length; i++) {
            uint vaultRound = IVault(vaultsIterable[i]).round();
            uint vaultPoints = ((ONE + userStakingMultiplier) *
                ((IVault(vaultsIterable[i]).balancesPerRound(vaultRound, user) * lpMultiplier) / ONE)) / ONE;
            estimatedPoints += vaultPoints;
        }
    }

    event SetStakingThales(address _stakingThales);
    event PointsStored(address user, address origin, uint basePoints, uint round);
    event SetKnownVault(address vault, bool value);
    event SetKnownLiquidityPool(address pool, bool value);
    event SetKnownTradingAMM(address amm, bool value);
    event SetMultipliers(uint _vaultsMultiplier, uint _lpMultiplier, uint _tradingMultiplier);
    event SetStakingBaseDivider(uint value);
    event SetMaxStakingMultiplier(uint value);
    event SetUseNewModel(bool value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IStakingThales {
    function updateVolume(address account, uint amount) external;

    /* ========== VIEWS / VARIABLES ==========  */
    function totalStakedAmount() external view returns (uint);

    function stakedBalanceOf(address account) external view returns (uint);

    function currentPeriodRewards() external view returns (uint);

    function currentPeriodFees() external view returns (uint);

    function getLastPeriodOfClaimedRewards(address account) external view returns (uint);

    function getRewardsAvailable(address account) external view returns (uint);

    function getRewardFeesAvailable(address account) external view returns (uint);

    function getAlreadyClaimedRewards(address account) external view returns (uint);

    function getContractRewardFunds() external view returns (uint);

    function getContractFeeFunds() external view returns (uint);

    function getAMMVolume(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function balancesPerRound(uint _round, address user) external view returns (uint);

    function round() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
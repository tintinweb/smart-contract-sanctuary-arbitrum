// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC4626} from "./customERC4626/ERC4626.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {IErrors} from "./interfaces/IErrors.sol";
import {IEarthquake} from "./interfaces/IEarthquake.sol";
import {IStrategyVault} from "./interfaces/IStrategyVault.sol";
import {IHook} from "./interfaces/IHook.sol";
import {IQueueContract} from "./interfaces/IQueueContract.sol";
import {VaultGetter} from "./libraries/VaultGetter.sol";
import {PositionSizer} from "./libraries/PositionSizer.sol";
import {HookChecker} from "./libraries/HookChecker.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {ERC1155Holder} from "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// NOTE: Planning to deposit liquidity to tackle the inflation attack of ERC4626
contract StrategyVault is ERC4626, ERC1155Holder, Ownable, IErrors {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;
    using HookChecker for uint16;

    struct Position {
        address[] vaults;
        uint256[] epochIds;
        uint256[] amounts;
    }

    struct QueueDeposit {
        address receiver;
        uint256 assets;
    }

    struct QueueCache {
        uint256 totalSupply;
        uint128 totalAssets;
        uint128 queued;
    }

    struct QueueItem {
        uint128 deploymentId;
        uint128 shares;
    }

    struct QueueInfo {
        uint256 shares;
        QueueItem[] queue;
    }

    struct Market {
        IEarthquake vault;
        address emissionsToken;
        uint256 marketId;
    }

    struct Hook {
        IHook addr;
        uint16 command;
    }

    enum UpdateAction {
        AppendVaults,
        ReplaceVaults,
        RemoveVaults,
        DeleteVaults
    }

    /// @notice Precision used to scale up emissions
    uint256 public constant PRECISION = 1e18;

    /// @notice Emissions accumulated per share used to calculate claimable per user
    uint256 public accEmissionPerShare;

    /// @notice Struct with hook contract address and byte encoded command
    Hook public hook;

    /// @notice Struct with list of vaults, epochIds, and amounts for the active position
    Position activePosition;

    /// @notice funds deployed to Y2K vaults state
    bool public fundsDeployed;

    /// @notice 1 = equal weight, 2 = fixed weight, 3 = threshold weight
    uint8 public weightStrategy;

    /// @notice proportion of vault funds to use in each deployment to strategy (max. 99.99%)
    uint16 public weightProportion;

    /// @notice maximum size of deposits to be pulled
    uint16 public maxQueuePull;

    /// @notice deployment id for funds
    uint128 public deploymentId;

    /// @notice interface of contract used to hold queued deposits funds
    IQueueContract public queueContract;

    /// @notice minimum deposit amount when queuing deposit
    uint128 public minDeposit;

    /// @notice total amount of assets queued for deposit
    uint128 public totalQueuedDeposits;

    /// @notice total amount of asset queued for withdrawal
    uint256 public queuedWithdrawalTvl;

    /// @notice list of Y2K vaults to use in fund deployment
    address[] public vaultList;

    /// @notice weights assigned to vault (zeroed when using equal weight or threshold return appended in threshold weight)
    uint256[] public vaultWeights;

    /// @notice struct information about queued deposits (incl. receiver and assets)
    QueueDeposit[] public queueDeposits;

    /// @notice mapping of vaults to withdraw queue information
    mapping(address => QueueInfo) public withdrawQueue;

    /// @notice cached info for totalSupply and totalAssets used when processed queuedWithdrawals where current deploy id has passed (i.e. assets + supply will mismatch)
    mapping(uint256 => QueueCache) public queueCache;

    /// @notice total amount of shares queued for withdrawal
    mapping(uint256 => uint256) public totalQueuedShares;

    /// @notice total emissions unclaimable by user (used to calculate claimable)
    mapping(address => int256) public userEmissionDebt;

    event FundsDeployed(
        address[] vaults,
        uint256[] epochIds,
        uint256[] amounts
    );
    event FundsWithdrawn(
        address[] vaults,
        uint256[] epochIds,
        uint256[] amounts,
        uint256[] receivedAmounts
    );
    event BulkDeposit(
        address sender,
        address[] receivers,
        uint256[] assets,
        uint256[] shares
    );
    event DepositQueued(address sender, uint256 amount);
    event WithdrawalQueued(address sender, uint256 amount);
    event WithdrawalUnqueued(address sender, uint256 amount);
    event VaultsUpdated(address sender, address[] vaults);
    event WeightStrategyUpdated(
        uint8 weightId,
        uint16 proportion,
        uint256[] fixedWeights
    );
    event MinDepositUpdated(uint256 newMin);
    event HookUpdated(Hook newHook);
    event MaxQueueSizeUpdated(uint16 newMax);
    event EmissionsUpdated(
        uint256 deploymentId,
        uint256 totalSupply,
        uint256 accEmissionsPerShare
    );
    event EmissionsClaimed(address sender, address receiver, uint256 amount);

    /**
        @notice Constructor initializing the queueContract, hook, emissions token, maxPull, minDeposit, asset, name, and symbol
        @dev ERC4626 is initialiazed meaning if the _asset does not have decimals it will revert
     */
    constructor(
        IQueueContract _queueContract,
        Hook memory _hook,
        ERC20 _emissionToken,
        uint16 _maxQueuePull,
        uint128 _minDeposit,
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _emissionToken, _name, _symbol) {
        if (address(_queueContract) == address(0)) revert InvalidInput();
        if (address(_emissionToken) == address(0)) revert InvalidInput();
        if (_maxQueuePull == 0) revert InvalidQueueSize();
        if (_minDeposit == 0) revert InvalidInput();

        queueContract = _queueContract;
        hook = _hook;
        maxQueuePull = _maxQueuePull;
        minDeposit = _minDeposit;
    }

    //////////////////////////////////////////////
    //                 ADMIN - CONFIG           //
    //////////////////////////////////////////////
    /**
        @notice Update the vault list
        @dev 0 = appendVaults, 1 = replaceVaults, 2 = removeVaults(s), and 3 = deleteVaults
        @dev Editing vaults whilst deployed will not impact closePosition as we store position
        @param vaults Array of vaults to update the list with
        @param updateAction Action to perform on the vault list
        @return newVaultList Updated vault list
     */
    function updateActiveList(
        address[] calldata vaults,
        UpdateAction updateAction
    ) external onlyOwner returns (address[] memory newVaultList) {
        if (updateAction != UpdateAction.DeleteVaults)
            VaultGetter.checkVaultsValid(vaults);

        if (updateAction == UpdateAction.AppendVaults)
            newVaultList = _appendVaults(vaults);
        else if (updateAction == UpdateAction.ReplaceVaults)
            newVaultList = _replaceVaults(vaults);
        if (updateAction == UpdateAction.RemoveVaults)
            newVaultList = _removeVaults(vaults);
        else if (updateAction == UpdateAction.DeleteVaults) {
            delete vaultList;
        }

        emit VaultsUpdated(msg.sender, newVaultList);
    }

    /**
        @notice Update the weight strategy used when deploying funds
        @dev 1 = EqualWeight, 2 = FixedWeight, 3 = ThresholdWeight
        @dev Max weight set to 9_999 to avoid the zero issue i.e. totalSupply() > 0 and totalAssets() = 0
        creates issues when funds deposited with ERC4626 logic
        @dev Threshold weight inputs an array that includes marketId for vault (V1 vaults) or is empty (V2 vaults) and threshold return is appended
        @param weightId Weight strategy id to update
        @param proportion Proportion of funds to use for the weight strategy (max 9_999)
        @param fixedWeights Array of fixed weights to use for each vault (in order of vaultList)
     */
    function setWeightStrategy(
        uint8 weightId,
        uint16 proportion,
        uint256[] calldata fixedWeights
    ) external onlyOwner {
        if (weightId == 0) revert InvalidWeightId();
        if (proportion > 9_999) revert InvalidInput();
        if (weightId > strategyCount()) revert InvalidWeightId();
        if (fixedWeights.length > 0) {
            if (weightId == 2) {
                if (fixedWeights.length != vaultList.length)
                    revert InvalidLengths();
                _checkWeightLimit(fixedWeights);
            } else if (
                weightId == 3 && fixedWeights.length != vaultList.length + 1
            ) revert InvalidLengths();
        }

        weightStrategy = weightId;
        weightProportion = proportion;
        vaultWeights = fixedWeights;
        emit WeightStrategyUpdated(weightId, proportion, fixedWeights);
    }

    /**
        @notice Update the minimum deposit size for queued deposits
        @param newMin New minimum deposit size
     */
    function updateMinDeposit(uint128 newMin) external onlyOwner {
        if (newMin == 0) revert InvalidInput();
        minDeposit = newMin;
        emit MinDepositUpdated(newMin);
    }

    /**
        @notice Update the hook struct
        @param newHook Struct with hook address and byte command
     */
    function updateHook(Hook calldata newHook) external onlyOwner {
        if (address(newHook.addr) == address(0)) revert InvalidInput();
        hook = newHook;
        emit HookUpdated(newHook);
    }

    /**
        @notice Update the max queue size (used to check if queue can be automatically pulled)
        @param newSize New max queue size
     */
    function updateMaxQueueSize(uint16 newSize) external onlyOwner {
        if (newSize == 0) revert InvalidQueueSize();
        maxQueuePull = newSize;
        emit MaxQueueSizeUpdated(newSize);
    }

    /**
        @notice Clear a fixed amount of deposits in the queue
        @dev Funds queued are kept in the queue contract until they are cleared
        @param queueSize Number of deposits to clear
        @return pulledAmount Amount of assets pulled from the queue
     */
    function clearQueuedDeposits(
        uint256 queueSize
    ) external onlyOwner returns (uint256 pulledAmount) {
        address[] memory receivers = new address[](queueSize);
        uint256[] memory assets = new uint256[](queueSize);
        uint256[] memory sharesReceived = new uint256[](queueSize);
        uint256 depositLength = queueDeposits.length;
        uint256 cachedSupply = totalSupply;
        uint256 cachedAssets = totalAssets();

        for (uint256 i = depositLength - queueSize; i < queueSize; ) {
            QueueDeposit memory qDeposit = queueDeposits[queueSize - i - 1];
            uint256 shares = qDeposit.assets.mulDivDown(
                cachedSupply,
                cachedAssets
            );

            _updateUserEmissions(qDeposit.receiver, shares, true);

            pulledAmount += qDeposit.assets;
            queueDeposits.pop();

            receivers[i] = qDeposit.receiver;
            assets[i] = qDeposit.assets;
            sharesReceived[i] = shares;
            _mint(qDeposit.receiver, shares);

            unchecked {
                i++;
            }
        }

        totalQueuedDeposits -= uint128(pulledAmount);
        queueContract.transferToStrategy();
        emit BulkDeposit(msg.sender, receivers, assets, sharesReceived);

        if (hook.command.shouldCallAfterDeposit()) {
            asset.safeApprove(address(hook.addr), pulledAmount);
            hook.addr.afterDeposit(pulledAmount);
        }
    }

    //////////////////////////////////////////////
    //             ADMIN - VAULT MGMT           //
    //////////////////////////////////////////////
    /**
        @notice Deploy funds to Y2K vaults based on weightStrategy and proportion
     */
    function deployPosition() external onlyOwner {
        if (fundsDeployed) revert FundsAlreadyDeployed();

        // Hook to conduct any actions before availableAmount calculated
        uint16 command = hook.command;
        if (command.shouldCallBeforeDeploy()) hook.addr.beforeDeploy();

        // Checking available assets and building position info
        (
            uint256[] memory amounts,
            uint256[] memory epochIds,
            uint256[] memory vaultType,
            address[] memory vaults
        ) = fetchDeployAmounts();

        fundsDeployed = true;
        _deployPosition(vaults, epochIds, amounts, vaultType);
        if (command.shouldCallAfterDeploy()) hook.addr.afterDeploy();
    }

    /**
        @notice Close position on Y2K vaults redeeming deployed funds and earnings
        @dev When losing on collateral side of Y2K, a proportion of assets is returned along with emissions earned
        When losing on premium side of Y2K, only emissions are earned
        @dev Casting totalAssets() to uint128 where max is 2 ** 128 - 1 (3.4e38)
        @dev afterCloseTransferAssets() returns an ERC20[] for _transferAssets function
     */
    function closePosition() external onlyOwner {
        if (!fundsDeployed) revert FundsNotDeployed();
        uint256 emissionBalance = emissionToken.balanceOf(address(this));
        Position memory position = activePosition;
        delete activePosition;

        uint16 command = hook.command;
        if (command.shouldCallBeforeClose()) hook.addr.beforeClose();

        _closePosition(position);

        if (command.shouldTransferAfterClose())
            _transferAssets(hook.addr.afterCloseTransferAssets());
        if (command.shouldCallAfterClose()) hook.addr.afterClose();

        // Resolving queueing logic - after hook to ensure balances are correct
        queuedWithdrawalTvl += previewRedeem(totalQueuedShares[deploymentId]);

        // Vault logic
        fundsDeployed = false;
        deploymentId += 1;

        // Resolving emission updates
        _updateVaultEmissions(emissionBalance);

        uint256 deployId = deploymentId - 1;
        if (queueCache[deployId].queued == 1) {
            queueCache[deployId].totalSupply = totalSupply;
            queueCache[deployId].totalAssets = uint128(totalAssets());
        }

        uint256 queueLength = queueDeposits.length;
        if (queueLength > 0 && queueLength < maxQueuePull)
            _pullQueuedDeposits(queueLength);
    }

    //////////////////////////////////////////////
    //                 PUBLIC                   //
    //////////////////////////////////////////////
    /**  
        @notice Deposit assets to strategy if funds not deployed else queue deposit
        @param assets Amount of assets to deposit
        @param receiver Address to receive shares
        @return shares Amount of shares received
    */
    function deposit(
        uint256 assets,
        address receiver
    ) external override returns (uint256 shares) {
        if (fundsDeployed) return _queueDeposit(receiver, assets);

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        _updateUserEmissions(receiver, shares, true);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);

        if (hook.command.shouldCallAfterDeposit()) {
            asset.safeApprove(address(hook.addr), assets);
            hook.addr.afterDeposit(assets);
        }
    }

    /**  
        @notice Withdraw assets from strategy if funds not deployed
        @dev Can not be called if funds have been queued for withdrawal
        @param shares Amount of shares to withdraw
        @param receiver Address to receive assets
        @param owner Address of shares owner
    */
    function withdraw(
        uint256 shares,
        address receiver,
        address owner
    ) external override returns (uint256 assets) {
        if (fundsDeployed) revert FundsAlreadyDeployed();
        if (withdrawQueue[owner].shares > 0) revert QueuedWithdrawalPending();

        assets = previewRedeem(shares);
        if (hook.command.shouldCallBeforeWithdraw()) {
            hook.addr.beforeWithdraw(assets);
        }

        _withdraw(assets, shares, receiver, owner);
        _updateUserEmissions(receiver, shares, false);
    }

    /**
        @notice Claim Y2K emissions for user
        @dev Approach inspired by SushiSwap MasterChefV2
        @dev Sender is always used as owner
        @param receiver Address to receive emissions
     */
    function claimEmissions(
        address receiver
    ) external returns (uint256 emissions) {
        int256 accEmissions = int256(
            (balanceOf[msg.sender] * accEmissionPerShare) / PRECISION
        );
        // TODO: When user withdraws without claiming this causes the value to be negative then when casting to uint makes positive. Is this an exploit/purposeful?
        emissions = uint256(accEmissions - userEmissionDebt[msg.sender]);

        userEmissionDebt[msg.sender] = accEmissions;

        if (emissions > 0) emissionToken.safeTransfer(receiver, emissions);
        emit EmissionsClaimed(msg.sender, receiver, emissions);
    }

    /**
        @notice Withdraw assets that have been queued for withdrawal
        @dev Can only be called if funds have been queued for withdrawal
        @param receiver Address to receive assets
        @param owner Address of shares owner
     */
    function withdrawFromQueue(
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        if (withdrawQueue[owner].shares == 0) revert NoQueuedWithdrawals();
        uint256 queueId = withdrawQueue[owner]
            .queue[withdrawQueue[owner].queue.length - 1]
            .deploymentId;
        if (queueId == deploymentId) revert PositionClosePending();

        uint256 shares;
        (assets, shares) = _previewQueuedWithdraw(owner);
        if (hook.command.shouldCallBeforeWithdraw()) {
            hook.addr.beforeWithdraw(assets);
        }

        _withdraw(assets, shares, receiver, owner);
        _updateUserEmissions(receiver, shares, false);
    }

    /**
        @notice Request an amount of shares to be queued for withdrawal
        @dev Shares are queued as the conversion is unknown while funds are deployed
        @param shares Amount of shares to queue for withdrawal
     */
    function requestWithdrawal(uint256 shares) external {
        if (!fundsDeployed) revert FundsNotDeployed();
        if (shares > balanceOf[msg.sender] - withdrawQueue[msg.sender].shares)
            revert InsufficientBalance();

        uint256 deployId = deploymentId;
        totalQueuedShares[deployId] += shares;
        withdrawQueue[msg.sender].shares += shares;
        uint256 length = withdrawQueue[msg.sender].queue.length;

        if (
            length > 0 &&
            withdrawQueue[msg.sender].queue[length - 1].deploymentId == deployId
        ) withdrawQueue[msg.sender].queue[length - 1].shares += uint128(shares);
        else
            withdrawQueue[msg.sender].queue.push(
                QueueItem(uint128(deployId), uint128(shares))
            );

        if (queueCache[deployId].queued == 0) queueCache[deployId].queued = 1;
        emit WithdrawalQueued(msg.sender, shares);
    }

    /**
        @notice Unqueue an amount of shares that have been queued for withdrawal
        @dev Only allowed to unqueue shares that have been queued with current deploymentId i.e. before position closed
        as hooks may adjust accounting
        @param shares Amount of shares to unqueue
     */
    function unrequestWithdrawal(uint256 shares) external {
        if (shares == 0) revert InvalidInput();
        uint256 length = withdrawQueue[msg.sender].queue.length;
        if (length == 0) revert NoQueuedWithdrawals();

        uint256 deployId = deploymentId;
        QueueItem memory item = withdrawQueue[msg.sender].queue[length - 1];
        if (item.deploymentId != deployId) revert InvalidQueueId();
        if (shares > item.shares) revert InsufficientBalance();

        totalQueuedShares[deployId] -= shares;
        withdrawQueue[msg.sender].shares -= shares;

        if (totalQueuedShares[deployId] == 0) delete queueCache[deployId];
        uint256 remaining = item.shares - shares;
        if (remaining == 0) withdrawQueue[msg.sender].queue.pop();
        else
            withdrawQueue[msg.sender].queue[length - 1].shares = uint128(
                remaining
            );

        emit WithdrawalUnqueued(msg.sender, shares);
    }

    //////////////////////////////////////////////
    //                 GETTERS                  //
    //////////////////////////////////////////////
    /**
        @notice Gets the count of strategies in the position sizer being used
        @return Strategy count
     */
    function strategyCount() public pure returns (uint256) {
        return PositionSizer.strategyCount();
    }

    /**
        @notice Checks if the vaults in the vaultList are valid and returns active list
        @return activeVaults List of active vaults
     */
    function validActiveVaults()
        public
        view
        returns (address[] memory activeVaults)
    {
        (, activeVaults, ) = VaultGetter.fetchEpochIds(vaultList);
    }

    /**
        @notice Gets the total assets of the vault
        @dev Total assets equals balanceOf(underlying) with simple vaults but with LP vaults
        the deposit asset and balance asset will differ e.g. aTokens are balance asset in Aave hook.
        In these cases, the hook will be queried to return the totalAssets for this calculation
        @return Total assets
     */
    function totalAssets() public view override returns (uint256) {
        if (!hook.command.shouldCallForTotalAssets())
            return asset.balanceOf(address(this));
        else return hook.addr.totalAssets();
    }

    /**
        @notice Gets the total Y2K balance/emissions available to be claimed in the whole vault
        @return Total emissions
     */
    function totalEmissions() public view override returns (uint256) {
        return emissionToken.balanceOf(address(this));
    }

    /**
        @notice Gets list of active vaults being deployed to
        @return Array of vault addresses
     */
    function fetchVaultList() external view returns (address[] memory) {
        return vaultList;
    }

    /**
        @notice Gets the vault weights being used in the position sizer (in order of the vaults)
        @return Array of vault weights
     */
    function fetchVaultWeights() external view returns (uint256[] memory) {
        return vaultWeights;
    }

    function fetchListAndWeights()
        external
        view
        returns (address[] memory, uint256[] memory weights)
    {
        weights = new uint256[](vaultList.length);
        if (weightStrategy == 1 || weightStrategy == 3) {
            for (uint256 i; i < vaultList.length; ) {
                weights[i] = 10_000 / vaultList.length;
                unchecked {
                    i++;
                }
            }
        } else {
            weights = vaultWeights;
        }
        return (vaultList, weights);
    }

    /**
        @notice Gets the total list of queued deposit structs
        @return Array of queueDeposit structs
     */
    function fetchDepositQueue() external view returns (QueueDeposit[] memory) {
        return queueDeposits;
    }

    /**
        @notice Gets the shares queued and list of queued withdrawals for an owner
        @param owner Address of the owner
        @return shares item - queued shares and array of queueItem structs
     */
    function fetchWithdrawQueue(
        address owner
    ) external view returns (uint256 shares, QueueItem[] memory item) {
        shares = withdrawQueue[owner].shares;
        item = withdrawQueue[owner].queue;
    }

    /**
        @notice Gets the information related to a new deployment
        @return amounts epochIds vaultType vaults 
     */
    function fetchDeployAmounts()
        public
        view
        returns (
            uint256[] memory amounts,
            uint256[] memory epochIds,
            uint256[] memory vaultType,
            address[] memory vaults
        )
    {
        (epochIds, vaults, vaultType) = VaultGetter.fetchEpochIds(vaultList);
        amounts = hook.command.shouldCallForAvailableAmounts()
            ? hook.addr.availableAmounts(vaults, epochIds, weightStrategy)
            : PositionSizer.fetchWeights(
                vaults,
                epochIds,
                ((totalAssets() - queuedWithdrawalTvl) * weightProportion) /
                    10_000,
                weightStrategy
            );
    }

    /**
        @notice Gets the info about the active vault position in Y2K vaults
        @dev When deploying to V2 vaults a fee is levied on the amount meaning amounts will be less than deployed
        for these V2 positions
        @return vaults epochIds amounts - array of vault addresses, array of epochIds, array of amounts 
     */
    function fetchActivePosition()
        external
        view
        returns (
            address[] memory vaults,
            uint256[] memory epochIds,
            uint256[] memory amounts
        )
    {
        Position memory position = activePosition;
        return (position.vaults, position.epochIds, position.amounts);
    }

    /**
        @notice Gets the emissions eligible for a receiver
        @dev Approach inspired by SushiSwap MasterChefV2
        @param receiver Address of the receiver
        @return Emissions eligible
     */
    function previewEmissions(
        address receiver
    ) external view returns (uint256) {
        int256 accEmissions = int256(
            (balanceOf[receiver] * accEmissionPerShare) / PRECISION
        ) - userEmissionDebt[receiver];
        return uint256(accEmissions);
    }

    //////////////////////////////////////////////
    //             INTERNAL - CONFIG            //
    //////////////////////////////////////////////
    /**
        @notice Helper function to check the weights used for the value do not exceed 100%
        @param weights Array of weights being assigned to vaults
     */
    function _checkWeightLimit(uint256[] calldata weights) internal pure {
        uint256 weightSum;
        for (uint256 i; i < weights.length; ) {
            weightSum += weights[i];
            unchecked {
                i++;
            }
        }
        if (weightSum > 10_000) revert InvalidInput();
    }

    /**
        @notice Helper function appending vault address(es) to the vaultList
        @param vaults Array of vault addresses to append
     */
    function _appendVaults(
        address[] calldata vaults
    ) internal returns (address[] memory) {
        address[] storage list = vaultList;
        for (uint256 i = 0; i < vaults.length; ) {
            list.push(vaults[i]);

            unchecked {
                i++;
            }
        }
        return list;
    }

    /**
        @notice Helper function to replace the vaultList with a new list
        @param vaults Array of vault addresses to replace with
     */
    function _replaceVaults(
        address[] calldata vaults
    ) internal returns (address[] memory) {
        vaultList = vaults;
        return vaults;
    }

    /**
        @notice Helper function to remove vaults from the vaultList
        @param vaults Array of vault addresses to remove
        @return newVaultList List of the new vaults
     */
    function _removeVaults(
        address[] memory vaults
    ) internal returns (address[] memory newVaultList) {
        uint256 removeCount = vaults.length;
        newVaultList = vaultList;

        for (uint256 i; i < newVaultList.length; ) {
            for (uint j; j < removeCount; ) {
                if (vaults[j] == newVaultList[i]) {
                    // Deleting the removeVault from the list
                    if (j == removeCount) {
                        delete vaults[j];
                        removeCount--;
                    } else {
                        if (vaults.length > 1) {
                            vaults[j] = vaults[removeCount];
                            delete vaults[removeCount];
                        } else delete vaults[j];
                        removeCount--;
                    }
                    // Deleting the vault from the newVaultList list
                    if (
                        newVaultList[i] == newVaultList[newVaultList.length - 1]
                    ) {
                        delete newVaultList[i];
                    } else {
                        newVaultList[i] = newVaultList[newVaultList.length - 1];
                        delete newVaultList[newVaultList.length - 1];
                    }
                }
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }

            vaultList = newVaultList;
            return newVaultList;
        }
    }

    //////////////////////////////////////////////
    //            INTERNAL - VAULT MGMT         //
    //////////////////////////////////////////////
    /**
        @notice Deploys funds to Y2K vaults and stores information
        @dev VaultType is used to calculate fee for V2 vaults as amount deposited will differ from amount deployed
        @param vaults Array of vault addresses to deploy to
        @param ids Array of vault ids to deploy to
        @param amounts Array of amounts to deploy
        @param vaultType Array of vault types to deploy to
     */
    function _deployPosition(
        address[] memory vaults,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory vaultType
    ) internal {
        address[] memory assets = new address[](vaults.length);

        for (uint256 i = 0; i < vaults.length; ) {
            uint256 amount = amounts[i];
            if (amount == 0) {
                unchecked {
                    i++;
                }
                continue;
            }

            IEarthquake iVault = IEarthquake(vaults[i]);
            address asset = iVault.asset();
            assets[i] = asset;
            uint256 id = ids[i];

            ERC20(asset).safeApprove(address(iVault), amount);
            iVault.deposit(id, amount, address(this));
            if (vaultType[i] == 2)
                (, amounts[i]) = iVault.getEpochDepositFee(id, amount);
            unchecked {
                i++;
            }
        }

        activePosition = Position({
            vaults: vaults,
            epochIds: ids,
            amounts: amounts
        });

        emit FundsDeployed(vaults, ids, amounts);
    }

    /**
        @notice Withdraws funds from Y2K vaults
        @param position Position to withdraw from Y2K vaults
     */
    function _closePosition(Position memory position) internal {
        uint256[] memory receivedAmounts = new uint256[](
            position.vaults.length
        );

        for (uint256 i = 0; i < position.vaults.length; ) {
            receivedAmounts[i] = IEarthquake(position.vaults[i]).withdraw(
                position.epochIds[i],
                position.amounts[i],
                address(this),
                address(this)
            );
            unchecked {
                i++;
            }
        }

        emit FundsWithdrawn(
            position.vaults,
            position.epochIds,
            position.amounts,
            receivedAmounts
        );
    }

    /**
        @notice Pulls deposits from the deposit queued
        @dev Only called when the queue > 0 and < maxQueuePull
        @param queueLength Number of deposits to pull
     */
    function _pullQueuedDeposits(
        uint256 queueLength
    ) private returns (uint256 pulledAmount) {
        QueueDeposit[] memory deposits = queueDeposits;

        address[] memory receivers = new address[](queueLength);
        uint256[] memory assets = new uint256[](queueLength);
        uint256[] memory sharesReceived = new uint256[](queueLength);
        uint256 cachedSupply = totalSupply;
        uint256 cachedAssets = totalAssets();

        for (uint256 i; i < queueLength; ) {
            uint256 depositAssets = deposits[i].assets;
            address receiver = deposits[i].receiver;
            pulledAmount += depositAssets;

            uint256 shares = depositAssets.mulDivDown(
                cachedSupply,
                cachedAssets
            );
            _updateUserEmissions(receiver, shares, true);

            receivers[i] = receiver;
            assets[i] = depositAssets;
            sharesReceived[i] = shares;
            _mint(receiver, shares);
            unchecked {
                i++;
            }
        }

        delete totalQueuedDeposits;
        delete queueDeposits;

        // Pulls the whole balance of the queue contract
        queueContract.transferToStrategy();
        emit BulkDeposit(msg.sender, receivers, assets, sharesReceived);

        if (hook.command.shouldCallAfterDeposit()) {
            asset.safeApprove(address(hook.addr), pulledAmount);
            hook.addr.afterDeposit(pulledAmount);
        }

        return pulledAmount;
    }

    /**
        @notice Transfers assets to receiver
        @dev If only one asset, transfer directly, otherwise loop through assets
        @param assets Array of assets to transfer
     */
    function _transferAssets(ERC20[] memory assets) private {
        if (assets.length == 1)
            assets[0].safeTransfer(
                address(hook.addr),
                assets[0].balanceOf(address(this))
            );
        else {
            address receiver = address(hook.addr);
            for (uint256 i = 0; i < assets.length; ) {
                ERC20 currentAsset = assets[i];
                currentAsset.safeTransfer(
                    receiver,
                    currentAsset.balanceOf(address(this))
                );
                unchecked {
                    i++;
                }
            }
        }
    }

    //////////////////////////////////////////////
    //         INTERNAL - EMISSION MGMT         //
    //////////////////////////////////////////////
    /**
        @notice Updates the vault emissions
        @dev Approach inspired by SushiSwap MasterChefV2
        @dev By comparing balance before position closed and balance after we find newEmissions
        @param emissionBalance Balance of the emission token prior to position closing
     */
    function _updateVaultEmissions(uint256 emissionBalance) private {
        uint256 _totalSupply = totalSupply;
        uint256 newEmissions = emissionToken.balanceOf(address(this)) -
            emissionBalance;
        uint256 _accEmissionPerShare = accEmissionPerShare;

        accEmissionPerShare =
            _accEmissionPerShare +
            ((newEmissions * PRECISION) / _totalSupply);
        emit EmissionsUpdated(deploymentId, _totalSupply, _accEmissionPerShare);
    }

    /**
        @notice Updates the user emissions
        @dev Approach inspired by SushiSwap MasterChefV2
        @param receiver Address of the user to update
        @param shares Amount of shares to update
        @param addDebt Whether to add or subtract debt depending on action (deposit/withdraw)
     */
    function _updateUserEmissions(
        address receiver,
        uint256 shares,
        bool addDebt
    ) private {
        int256 emissionValue = int256(
            (shares * accEmissionPerShare) / PRECISION
        );
        int256 userDebt = userEmissionDebt[receiver];

        if (addDebt) userEmissionDebt[receiver] = userDebt + emissionValue;
        else userEmissionDebt[receiver] = userDebt - emissionValue;
    }

    //////////////////////////////////////////////
    //             INTERNAL - PUBLIC MGMT       //
    //////////////////////////////////////////////
    /**
        @notice Withdraws the deposit asset from the vault
        @dev Overriden logic that relates to ERC4626 withdraw function
        @param assets Amount of assets to withdraw
        @param shares Amount of shares to withdraw
        @param receiver Address to receive the assets
        @param owner Address of the owner of the shares
     */
    function _withdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) private {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /**
        @notice Previews the amount of assets that will be withdrawn based on users withdrawal queue
        @dev To calculate amount due, we loop through queued and use the cachedInfo stored after positions are closed
        @param owner Address of the owner of the shares
        @return assets Amount of assets that will be withdrawn
        @return shareSum Amount of shares that will be withdrawn
     */
    function _previewQueuedWithdraw(
        address owner
    ) internal returns (uint256 assets, uint256 shareSum) {
        uint256 queueLength = withdrawQueue[owner].queue.length;

        for (uint256 i; i < queueLength; ) {
            QueueItem memory item = withdrawQueue[owner].queue[i];

            uint256 shares = item.shares;
            shareSum += shares;
            QueueCache memory cachedInfo = queueCache[item.deploymentId];

            // NOTE: No instance where supply is 0 i.e. cachedInfo.totalSupply == 0 ? shares : <equation> removed
            assets += shares.mulDivDown(
                cachedInfo.totalAssets,
                cachedInfo.totalSupply
            );

            unchecked {
                i++;
            }
        }

        queuedWithdrawalTvl -= assets;
        delete withdrawQueue[owner];
    }

    /**
        @notice Queues deposit for user
        @dev Deposits are transferred to queue contract as ERC4626 shares relate to balance and balance will be 
        incorrect when funds are deployed i.e. funds are held elsewhere and pulled once balances are updated after
        position is closed.
        @param receiver Address of the user to receive the assets
        @param assets Amount of assets to deposit
        @return 0 - as expected return from deposit function
     */
    function _queueDeposit(
        address receiver,
        uint256 assets
    ) internal returns (uint256) {
        if (assets < minDeposit) revert InvalidDepositAmount();
        queueDeposits.push(QueueDeposit(receiver, assets));
        totalQueuedDeposits += uint128(assets);

        queueContract.transferToQueue(msg.sender, assets);

        emit DepositQueued(msg.sender, assets);
        return 0;
    }
}

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;
    ERC20 public immutable emissionToken;

    constructor(
        ERC20 _asset,
        ERC20 _emissionToken,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
        emissionToken = _emissionToken;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets,
        address receiver
    ) external virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets) {
        assets = previewRedeem(shares); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function totalEmissions() public view virtual returns (uint256);

    function convertToShares(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(
        uint256 shares
    ) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IErrors {
    // Generic Errors
    error InvalidInput();
    error InsufficientBalance();

    // Vault Errors
    error VaultNotApproved();
    error FundsNotDeployed();
    error FundsAlreadyDeployed();
    error InvalidLengths();
    error InvalidUnqueueAmount();
    error InvalidWeightId();
    error InvalidQueueSize();
    error InvalidQueueId();
    error InvalidArrayLength();
    error InvalidDepositAmount();
    error ZeroShares();
    error QueuedAmountInsufficient();
    error NoQueuedWithdrawals();
    error QueuedWithdrawalPending();
    error UnableToUnqueue();
    error PositionClosePending();

    // Hook Errors
    error Unauthorized();
    error VaultSet();
    error AssetIdNotSet();
    error InvalidPathCount();
    error OutdatedPathInfo();
    error InvalidToken();

    // Queue Contract Errors
    error InvalidAsset();

    // Getter Errors
    error InvalidVaultAddress();
    error InvalidVaultAsset();
    error InvalidVaultEmissions();
    error MarketNotExist();
    error InvalidVaultController();
    error InvalidVaultCounterParty();
    error InvalidTreasury();

    // Position Sizer
    error InvalidWeightStrategy();
    error ProportionUnassigned();
    error LengthMismatch();
    error NoValidThreshold();

    // DEX Errors
    error InvalidPath();
    error InvalidCaller();
    error InvalidMinOut(uint256 amountOut);
}

pragma solidity 0.8.18;

interface IEarthquake {
    function asset() external view returns (address asset);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function depositETH(uint256 pid, address to) external payable;

    function epochs() external view returns (uint256[] memory);

    function epochs(uint256 i) external view returns (uint256);

    function epochsLength() external view returns (uint256);

    function getEpochsLength() external view returns (uint256);

    function idEpochBegin(uint256 id) external view returns (uint256);

    function idEpochEnded(uint256 id) external view returns (bool);

    function getVaults(uint256 pid) external view returns (address[2] memory);

    function emissionsToken() external view returns (address emissionsToken);

    function controller() external view returns (address controller);

    function treasury() external view returns (address treasury);

    function counterPartyVault() external view returns (address counterParty);

    function totalSupply(uint256 id) external view returns (uint256);

    function factory() external view returns (address factory);

    function withdraw(
        uint256 id,
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function getEpochConfig(
        uint256
    ) external view returns (uint40, uint40, uint40);

    function getEpochDepositFee(
        uint256 id,
        uint256 assets
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

interface IStrategyVault {
    function deployFunds() external;

    function withdrawFunds() external;

    function weightProportion() external view returns (uint16);

    function vaultWeights() external view returns (uint256[] memory);

    function vaultWeights(uint256) external view returns (uint256);

    function threshold() external view returns (uint256);

    function fetchVaultWeights() external view returns (uint256[] memory);

    function asset() external view returns (ERC20 asset);
}

pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

interface IHook {
    function beforeDeposit() external;

    function afterDeposit(uint256 amount) external;

    function beforeWithdraw(uint256 amount) external;

    function beforeDeploy() external;

    function afterDeploy() external;

    function beforeClose() external;

    function afterClose() external;

    function afterCloseTransferAssets() external view returns (ERC20[] memory);

    function totalAssets() external view returns (uint256);

    function availableAmounts(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256 weightStrategy
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IQueueContract {
    function transferToStrategy() external;

    function transferToQueue(address caller, uint256 amount) external;

    function balance(address sender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IErrors} from "../interfaces/IErrors.sol";
import {IEarthquake} from "../interfaces/IEarthquake.sol";
import {IEarthquakeFactory} from "../interfaces/IEarthquakeFactory.sol";

library VaultGetter {
    /**
        @notice Checks if the list of vaults being provided are valid Y2K vaults
        @dev Checks if address !=0, checks if asset !=0, and checks if emissionToken is valid
        @param vaults the list of vaults to check
     */
    function checkVaultsValid(address[] calldata vaults) public view {
        for (uint256 i = 0; i < vaults.length; ) {
            checkVaultValid(IEarthquake(vaults[i]));

            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Gets the list of epochIds for the vault that are active along with vaultType
        @dev Vaults are only valid where the most recent epoch can be deposited to
        @param vaults the list of vaults to check
        @return epochIds validVaults vaultType - the list of epochIds for the vaults, the list of valid vaults, and the list of vault types
     */
    function fetchEpochIds(
        address[] memory vaults
    )
        public
        view
        returns (
            uint256[] memory epochIds,
            address[] memory validVaults,
            uint256[] memory vaultType
        )
    {
        uint256 validCount;
        epochIds = new uint256[](vaults.length);
        validVaults = new address[](vaults.length);
        vaultType = new uint256[](vaults.length);

        for (uint256 i = 0; i < vaults.length; ) {
            IEarthquake vault = IEarthquake(vaults[i]);

            bool valid;
            (valid, epochIds[i], vaultType[i]) = epochValid(vault);
            unchecked {
                i++;
            }

            if (!valid) {
                continue;
            }

            validVaults[validCount] = address(vault);
            unchecked {
                validCount++;
            }
        }
    }

    /**
        @notice Checks if a vault has a valid epoch
        @dev Vault is valid where length >0, most recent epochId has not ended, and most recent epochId has not begun. When
        vaults is V1 calls differ hence the use of a try/catch block returning vaultType depending on block
        @param vault the vault to check
        @return valid epochId vaultType - the validity of the vault, the epochId, and the vaultType
     */
    function epochValid(
        IEarthquake vault
    ) public view returns (bool, uint256, uint256) {
        try vault.epochsLength() returns (uint256 epochLength) {
            if (epochLength == 0) return (false, 0, 0);

            uint256 epochId = vault.epochs(epochLength - 1);
            if (vault.idEpochEnded(epochId)) return (false, 0, 0);

            if (block.timestamp > vault.idEpochBegin(epochId))
                return (false, 0, 0);
            return (true, epochId, 1);
        } catch {
            try vault.getEpochsLength() returns (uint256 epochLength) {
                if (epochLength == 0) return (false, 0, 0);

                uint256 epochId = vault.epochs(epochLength - 1);
                (uint40 epochBegin, uint40 epochEnd, ) = vault.getEpochConfig(
                    epochId
                );

                if (block.timestamp > epochEnd) return (false, 0, 0);
                if (block.timestamp > epochBegin) return (false, 0, 0);
                return (true, epochId, 2);
            } catch {
                return (false, 0, 0);
            }
        }
    }

    /**
        @notice Gets the roi for an epochId for an Earthquake vault
        @dev Roi is calculated as the counterPartyVault supply / vault supply * 10_000 (for an epochId)
        @param vault the vault to check
        @param epochId the epochId to check
        @param marketId the marketId to check
     */
    function getRoi(
        address vault,
        uint256 epochId,
        uint256 marketId
    ) public view returns (uint256) {
        uint256 vaultSupply = IEarthquake(vault).totalSupply(epochId);

        address counterVault;
        IEarthquake iVault = IEarthquake(vault);
        try iVault.counterPartyVault() returns (address vaultAddr) {
            counterVault = vaultAddr;
        } catch {
            address[] memory vaults = IEarthquakeFactory(iVault.factory())
                .getVaults(marketId);
            counterVault = vaults[0] == vault ? vaults[1] : vaults[0];
        }

        uint256 counterSupply = IEarthquake(counterVault).totalSupply(epochId);
        return (counterSupply * 10_000) / vaultSupply;
    }

    /**
        @notice Checks if the vault has key inputs
        @dev Vault could be dupped with these inputs but as usage is for our inputs only
        it's more of a sanity check the vault input being used by an admin is valid
        @param _vault the vault to check
     */
    function checkVaultValid(IEarthquake _vault) public view {
        if (address(_vault) == address(0)) revert IErrors.InvalidVaultAddress();

        if (address(_vault.asset()) == address(0))
            revert IErrors.InvalidVaultAsset();

        if (_vault.controller() == address(0))
            revert IErrors.InvalidVaultController();

        if (_vault.treasury() == address(0)) revert IErrors.InvalidTreasury();

        try _vault.emissionsToken() returns (address emissionsToken) {
            if (emissionsToken == address(0))
                revert IErrors.InvalidVaultEmissions();
            if (_vault.counterPartyVault() == address(0))
                revert IErrors.InvalidVaultCounterParty();
        } catch {
            // NOTE: V1 vaults do not have emissionsToken storage variable
        }
    }

    /**
        @notice Checks if the market is valid
        @dev if the factory returns an empty array then the market is not valid - where market is a vault address
        @param _vault the vault to check
        @param _marketId the marketId to check
     */
    function checkMarketValid(
        IEarthquake _vault,
        uint256 _marketId
    ) public view {
        // NOTE: Factory will vary but implementation for calls is the same
        IEarthquakeFactory factory = IEarthquakeFactory(
            address(_vault.factory())
        );
        address[] memory vaults = factory.getVaults(_marketId);
        if (vaults[0] == address(0)) revert IErrors.MarketNotExist();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStrategyVault} from "../interfaces/IStrategyVault.sol";
import {VaultGetter} from "./VaultGetter.sol";
import {IErrors} from "../interfaces/IErrors.sol";

library PositionSizer {
    //////////////////////////////////////////////
    //                 GETTER                   //
    //////////////////////////////////////////////

    function strategyCount() public pure returns (uint256) {
        return 4;
    }

    //////////////////////////////////////////////
    //                 EXTERNAL                 //
    //////////////////////////////////////////////
    /**
        @notice Fetches the weights for the vaults
        @dev If 1 then x% deployed in equalWeight or if 2 then x% deployed in customWeight. When 2, weights would
        return either fixed, cascading, or best return -- threshold could be assigned in these ways
        @param vaults the list of vaults to check
        @param epochIds the list of epochIds to check
        @param availableAmount the amount available to deposit
        @param weightStrategy the strategy to use for weights
     */
    function fetchWeights(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256 availableAmount,
        uint256 weightStrategy
    ) external view returns (uint256[] memory amounts) {
        if (weightStrategy == 1)
            return _equalWeight(availableAmount, vaults.length);
        else if (weightStrategy < strategyCount()) {
            uint256[] memory weights = _fetchWeight(
                vaults,
                epochIds,
                weightStrategy
            );
            return _customWeight(availableAmount, vaults, weights);
        } else revert IErrors.InvalidWeightStrategy();
    }

    //////////////////////////////////////////////
    //                 INTERNAL                 //
    //////////////////////////////////////////////
    /**
        @notice Assigns the available amount across the vaults
        @param availableAmount the amount available to deposit
        @param length the length of the vaults
        @return amounts The list of amounts to deposit in each vault
     */
    function _equalWeight(
        uint256 availableAmount,
        uint256 length
    ) private pure returns (uint256[] memory amounts) {
        amounts = new uint256[](length);

        uint256 modulo = availableAmount % length;
        for (uint256 i = 0; i < length; ) {
            amounts[i] = availableAmount / length;
            if (modulo > 0) {
                amounts[i] += 1;
                modulo -= 1;
            }
            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Assigns the available amount in custom weights across the vaults
        @param availableAmount the amount available to deposit
        @param vaults the list of vaults to check
        @param customWeights the list of custom weights to check
        @return amounts The list of amounts to deposit in each vault
     */
    function _customWeight(
        uint256 availableAmount,
        address[] memory vaults,
        uint256[] memory customWeights
    ) internal pure returns (uint256[] memory amounts) {
        amounts = new uint256[](vaults.length);
        for (uint256 i = 0; i < vaults.length; ) {
            uint256 weight = customWeights[i];
            if (weight == 0) amounts[i] = 0;
            else amounts[i] = (availableAmount * weight) / 10_000;
            unchecked {
                i++;
            }
        }
    }

    //////////////////////////////////////////////
    //            INTERNAL - WEIGHT MATH        //
    //////////////////////////////////////////////
    /**
        @notice Fetches the weights dependent on the strategy
        @param vaults the list of vaults to check
        @param epochIds the list of epochIds to check
        @param weightStrategy the strategy to use for weights
        @return weights The list of weights to use
     */
    function _fetchWeight(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256 weightStrategy
    ) internal view returns (uint256[] memory weights) {
        if (weightStrategy == 2) return _fixedWeight(vaults);
        if (weightStrategy == 3) return _thresholdWeight(vaults, epochIds);
    }

    /**
        @notice fetches the fixed weights from the strategy vault
        @param vaults the list of vaults to check
        @return weights The list of weights to use
     */
    function _fixedWeight(
        address[] memory vaults
    ) internal view returns (uint256[] memory weights) {
        weights = IStrategyVault(address(this)).fetchVaultWeights();
        if (weights.length != vaults.length) revert IErrors.LengthMismatch();
    }

    /**
        @notice Fetches the weights from strategy vault where appended value is threshold and rest are ids
        @dev Threshold assigns funds equally if threshold is passed
     */
    function _thresholdWeight(
        address[] memory vaults,
        uint256[] memory epochIds
    ) internal view returns (uint256[] memory weights) {
        uint256[] memory marketIds = IStrategyVault(address(this))
            .fetchVaultWeights();
        if (marketIds.length != vaults.length + 1)
            revert IErrors.LengthMismatch();

        // NOTE: Threshold is appended and weights are marketIds for V1 or empty for V2
        uint256 threshold = marketIds[marketIds.length - 1];
        weights = new uint256[](vaults.length);
        uint256[] memory validIds = new uint256[](vaults.length);
        uint256 validCount;

        for (uint256 i; i < vaults.length; ) {
            uint256 roi = _fetchReturn(vaults[i], epochIds[i], marketIds[i]);
            if (roi > threshold) {
                validCount += 1;
                validIds[i] = i;
            }
            unchecked {
                i++;
            }
        }
        if (validCount == 0) revert IErrors.NoValidThreshold();

        uint256 modulo = 10_000 % validCount;
        for (uint j; j < validCount; ) {
            uint256 location = validIds[j];
            weights[location] = 10_000 / validCount;
            if (modulo > 0) {
                weights[location] += 1;
                modulo -= 1;
            }
            unchecked {
                j++;
            }
        }
    }

    //////////////////////////////////////////////
    //            INTERNAL - ROI CALCS        //
    //////////////////////////////////////////////
    /**
        @notice Fetches the roi for a list of vaults
        @param vaults the list of vaults
        @param epochIds the list of epochIds
        @param marketIds the list of marketIds
        @return roi The list of rois
     */
    function _fetchReturns(
        address[] memory vaults,
        uint256[] memory epochIds,
        uint256[] memory marketIds
    ) internal view returns (uint256[] memory roi) {
        for (uint256 i = 0; i < vaults.length; ) {
            roi[i] = _fetchReturn(vaults[i], epochIds[i], marketIds[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
        @notice Fetches the roi for a vault
        @param vault the vault  
        @param epochId the epochId to check
        @param marketId the marketId to check
        @return roi The roi for the vault
     */
    function _fetchReturn(
        address vault,
        uint256 epochId,
        uint256 marketId
    ) private view returns (uint256 roi) {
        return VaultGetter.getRoi(vault, epochId, marketId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library HookChecker {
    uint256 internal constant BEFORE_DEPLOY_FLAG = 1; // 0000 0001
    uint256 internal constant AFTER_CLOSE_FLAG = 2; // 0000 0010
    uint256 internal constant AFTER_DEPOSIT_FLAG = 4; // 0000 0100
    uint256 internal constant BEFORE_WITHDRAW_FLAG = 8; // 0000 1000
    uint256 internal constant TOTAL_ASSETS_FLAG = 16; // 0001 0000
    uint256 internal constant AVAILABLE_AMOUNT_FLAG = 32; // 0010 0000
    uint256 internal constant TRANSFER_AFTER_CLOSE_FLAG = 64; // 0100 0000
    uint256 internal constant AFTER_DEPLOY_FLAG = 128; // 1000 0000
    uint256 internal constant BEFORE_CLOSE_FLAG = 256; // 0001 0000 0000

    /**
        @notice Checks if the beforeDeploy hook function should be called
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallBeforeDeploy(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & BEFORE_DEPLOY_FLAG != 0;
    }

    /**
        @notice Checks if the afterClose hook function should be called
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallAfterClose(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & AFTER_CLOSE_FLAG != 0;
    }

    /**
        @notice Checks if the afterDeposit hook function should be called
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallAfterDeposit(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & AFTER_DEPOSIT_FLAG != 0;
    }

    /**
        @notice Checks if the beforeWithdraw hook function should be called
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallBeforeWithdraw(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & BEFORE_WITHDRAW_FLAG != 0;
    }

    /**
        @notice Checks if the totalAssets hook function should be called
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallForTotalAssets(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & TOTAL_ASSETS_FLAG != 0;
    }

    /**
        @notice Checks if the availableAmount hook function should be called
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallForAvailableAmounts(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & AVAILABLE_AMOUNT_FLAG != 0;
    }

    /**
        @notice Checks if assets should be transferred afterClose
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldTransferAfterClose(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & TRANSFER_AFTER_CLOSE_FLAG != 0;
    }

    /**
        @notice Checks if assets should be transferred beforeDeploy
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallAfterDeploy(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & AFTER_DEPLOY_FLAG != 0;
    }

    /**
        @notice Checks if assets should be transferred beforeDeploy
        @param hookCommand the byte command
        @return boolean value for Y/N
     */
    function shouldCallBeforeClose(
        uint16 hookCommand
    ) internal pure returns (bool) {
        return hookCommand & BEFORE_CLOSE_FLAG != 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

pragma solidity 0.8.18;

interface IEarthquakeFactory {
    function asset(uint256 _marketId) external view returns (address asset);

    function getVaults(uint256) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
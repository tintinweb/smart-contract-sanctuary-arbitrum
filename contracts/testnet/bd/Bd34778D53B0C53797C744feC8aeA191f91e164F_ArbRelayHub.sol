pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../RelayHub.sol";
import "./ArbSys.sol";

/**
 * @title The RelayHub Implementation for Arbitrum
 * @notice This contract implements the `IRelayHub` interface for the Arbitrum-compatible Rollups.
 *
 * @notice This implementation relies on the `ArbSys` built-ins that do not exist outside of Arbitrum.
 */
contract ArbRelayHub is RelayHub {

    /// @inheritdoc IRelayHub
    function versionHub() override public pure returns (string memory){
        return "3.0.0-alpha.3+opengsn.arbhub.irelayhub";
    }

    ArbSys public immutable arbsys;
    uint256 internal immutable arbCreationBlock;

    /// @notice we accept the `ArbSys` address in the constructor to allow mocking it in tests.
    constructor(
        ArbSys _arbsys,
        IStakeManager _stakeManager,
        address _penalizer,
        address _batchGateway,
        address _relayRegistrar,
        RelayHubConfig memory _config
    ) RelayHub(_stakeManager, _penalizer, _batchGateway, _relayRegistrar, _config){
        arbsys = _arbsys;
        arbCreationBlock = _arbsys.arbBlockNumber();
    }

    /// @inheritdoc IRelayHub
    /// @notice Uses `ArbSys` L2 block number specific to the Arbitrum Rollup.
    function getCreationBlock() external override virtual view returns (uint256){
        return arbCreationBlock;
    }

    /// @return The block number in which the contract has been deployed.
    /// @notice Uses original L1 block number.
    function getL1CreationBlock() external view returns (uint256){
        return creationBlock;
    }

    /// @notice Includes the 'storage gas' specific to the Arbitrum Rollup.
    /// @inheritdoc IRelayHub
    function aggregateGasleft() public override virtual view returns (uint256){
        return arbsys.getStorageGasAvailable() + gasleft();
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable not-rely-on-time */
/* solhint-disable avoid-tx-origin */
/* solhint-disable bracket-align */
// SPDX-License-Identifier: GPL-3.0-only

import "hardhat/console.sol";

import "./utils/MinLibBytes.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./utils/GsnUtils.sol";
import "./utils/GsnEip712Library.sol";
import "./utils/RelayHubValidator.sol";
import "./utils/GsnTypes.sol";
import "./interfaces/IRelayHub.sol";
import "./interfaces/IPaymaster.sol";
import "./forwarder/IForwarder.sol";
import "./interfaces/IStakeManager.sol";
import "./interfaces/IRelayRegistrar.sol";
import "./interfaces/IStakeManager.sol";

/**
 * @title The RelayHub Implementation
 * @notice This contract implements the `IRelayHub` interface for the EVM-compatible networks.
 */
contract RelayHub is IRelayHub, Ownable, ERC165 {
    using ERC165Checker for address;
    using SafeMath for uint256;

    /// @inheritdoc IRelayHub
    function versionHub() override virtual public pure returns (string memory){
        return "3.0.0-alpha.3+opengsn.hub.irelayhub";
    }

    IStakeManager internal immutable stakeManager;
    address internal immutable penalizer;
    address internal immutable batchGateway;
    address internal immutable relayRegistrar;

    RelayHubConfig internal config;

    /// @inheritdoc IRelayHub
    function getConfiguration() public override view returns (RelayHubConfig memory) {
        return config;
    }

    /// @inheritdoc IRelayHub
    function setConfiguration(RelayHubConfig memory _config) public override onlyOwner {
        require(_config.devFee < 100, "dev fee too high");
        config = _config;
        emit RelayHubConfigured(config);
    }

    // maps ERC-20 token address to a minimum stake for it
    mapping(IERC20 => uint256) internal minimumStakePerToken;

    /// @inheritdoc IRelayHub
    function setMinimumStakes(IERC20[] memory token, uint256[] memory minimumStake) public override onlyOwner {
        require(token.length == minimumStake.length, "setMinimumStakes: wrong length");
        for (uint256 i = 0; i < token.length; i++) {
            minimumStakePerToken[token[i]] = minimumStake[i];
            emit StakingTokenDataChanged(address(token[i]), minimumStake[i]);
        }
    }

    // maps relay worker's address to its manager's address
    mapping(address => address) internal workerToManager;

    // maps relay managers to the number of their workers
    mapping(address => uint256) internal workerCount;

    mapping(address => uint256) internal balances;

    uint256 internal immutable creationBlock;
    uint256 internal deprecationTime = type(uint256).max;

    constructor (
        IStakeManager _stakeManager,
        address _penalizer,
        address _batchGateway,
        address _relayRegistrar,
        RelayHubConfig memory _config
    ) {
        creationBlock = block.number;
        stakeManager = _stakeManager;
        penalizer = _penalizer;
        batchGateway = _batchGateway;
        relayRegistrar = _relayRegistrar;
        setConfiguration(_config);
    }

    /// @inheritdoc IRelayHub
    function getCreationBlock() external override virtual view returns (uint256){
        return creationBlock;
    }

    /// @inheritdoc IRelayHub
    function getDeprecationTime() external override view returns (uint256) {
        return deprecationTime;
    }

    /// @inheritdoc IRelayHub
    function getStakeManager() external override view returns (IStakeManager) {
        return stakeManager;
    }

    /// @inheritdoc IRelayHub
    function getPenalizer() external override view returns (address) {
        return penalizer;
    }

    /// @inheritdoc IRelayHub
    function getBatchGateway() external override view returns (address) {
        return batchGateway;
    }

    /// @inheritdoc IRelayHub
    function getRelayRegistrar() external override view returns (address) {
        return relayRegistrar;
    }

    /// @inheritdoc IRelayHub
    function getMinimumStakePerToken(IERC20 token) external override view returns (uint256) {
        return minimumStakePerToken[token];
    }

    /// @inheritdoc IRelayHub
    function getWorkerManager(address worker) external override view returns (address) {
        return workerToManager[worker];
    }

    /// @inheritdoc IRelayHub
    function getWorkerCount(address manager) external override view returns (uint256) {
        return workerCount[manager];
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IRelayHub).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRelayHub
    function verifyCanRegister(address relayManager) external view override {
        verifyRelayManagerStaked(relayManager);
        require(workerCount[relayManager] > 0, "no relay workers");
    }

    /// @inheritdoc IRelayHub
    function addRelayWorkers(address[] calldata newRelayWorkers) external override {
        address relayManager = msg.sender;
        uint256 newWorkerCount = workerCount[relayManager] + newRelayWorkers.length;
        workerCount[relayManager] = newWorkerCount;
        require(newWorkerCount <= config.maxWorkerCount, "too many workers");

        verifyRelayManagerStaked(relayManager);

        for (uint256 i = 0; i < newRelayWorkers.length; i++) {
            require(workerToManager[newRelayWorkers[i]] == address(0), "this worker has a manager");
            workerToManager[newRelayWorkers[i]] = relayManager;
        }

        emit RelayWorkersAdded(relayManager, newRelayWorkers, newWorkerCount);
    }

    /// @inheritdoc IRelayHub
    function depositFor(address target) public virtual override payable {
        require(target.supportsInterface(type(IPaymaster).interfaceId), "target is not a valid IPaymaster");
        uint256 amount = msg.value;

        balances[target] = balances[target].add(amount);

        emit Deposited(target, msg.sender, amount);
    }

    /// @inheritdoc IRelayHub
    function balanceOf(address target) external override view returns (uint256) {
        return balances[target];
    }

    /// @inheritdoc IRelayHub
    function withdraw(uint256 amount, address payable dest) public override {
        address payable account = payable(msg.sender);
        require(balances[account] >= amount, "insufficient funds");

        balances[account] = balances[account].sub(amount);
        dest.transfer(amount);

        emit Withdrawn(account, dest, amount);
    }

    function verifyGasAndDataLimits(
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        uint256 initialGasLeft
    )
    private
    view
    returns (IPaymaster.GasAndDataLimits memory gasAndDataLimits, uint256 maxPossibleGas) {
        gasAndDataLimits =
            IPaymaster(relayRequest.relayData.paymaster).getGasAndDataLimits{gas:50000}();
        require(msg.data.length <= gasAndDataLimits.calldataSizeLimit, "msg.data exceeded limit" );

        require(maxAcceptanceBudget >= gasAndDataLimits.acceptanceBudget, "acceptance budget too high");
        require(gasAndDataLimits.acceptanceBudget >= gasAndDataLimits.preRelayedCallGasLimit, "acceptance budget too low");

        maxPossibleGas = relayRequest.relayData.transactionCalldataGasUsed + initialGasLeft;

        uint256 maxPossibleCharge = calculateCharge(
            maxPossibleGas,
            relayRequest.relayData
        );

        // We don't yet know how much gas will be used by the recipient, so we make sure there are enough funds to pay
        // for the maximum possible charge.
        require(maxPossibleCharge <= balances[relayRequest.relayData.paymaster],
            "Paymaster balance too low");
    }

    struct RelayCallData {
        bool success;
        bytes4 functionSelector;
        uint256 initialGasLeft;
        bytes recipientContext;
        bytes relayedCallReturnValue;
        IPaymaster.GasAndDataLimits gasAndDataLimits;
        RelayCallStatus status;
        uint256 innerGasUsed;
        uint256 maxPossibleGas;
        uint256 gasBeforeInner;
        bytes retData;
        address relayManager;
        bytes32 relayRequestId;
    }

    /// @inheritdoc IRelayHub
    function relayCall(
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    override
    returns (bool paymasterAccepted, bytes memory returnValue)
    {
        RelayCallData memory vars;
        vars.initialGasLeft = aggregateGasleft();
        vars.relayRequestId = GsnUtils.getRelayRequestID(relayRequest, signature);
        require(!isDeprecated(), "hub deprecated");
        vars.functionSelector = relayRequest.request.data.length>=4 ? MinLibBytes.readBytes4(relayRequest.request.data, 0) : bytes4(0);
        if (msg.sender != batchGateway){
            require(signature.length != 0, "missing signature or bad gateway");
            require(msg.sender == tx.origin, "relay worker must be EOA");
            require(msg.sender == relayRequest.relayData.relayWorker, "Not a right worker");
        }
        vars.relayManager = workerToManager[relayRequest.relayData.relayWorker];
        require(vars.relayManager != address(0), "Unknown relay worker");
        verifyRelayManagerStaked(vars.relayManager);

        (vars.gasAndDataLimits, vars.maxPossibleGas) =
            verifyGasAndDataLimits(maxAcceptanceBudget, relayRequest, vars.initialGasLeft);

        RelayHubValidator.verifyTransactionPacking(relayRequest,signature,approvalData);

    {

        //How much gas to pass down to innerRelayCall. must be lower than the default 63/64
        // actually, min(gasleft*63/64, gasleft-GAS_RESERVE) might be enough.
        uint256 innerGasLimit = gasleft()*63/64- config.gasReserve;
        vars.gasBeforeInner = aggregateGasleft();

        /*
        Preparing to calculate "gasUseWithoutPost":
        MPG = calldataGasUsage + vars.initialGasLeft :: max possible gas, an approximate gas limit for the current transaction
        GU1 = MPG - gasleft(called right before innerRelayCall) :: gas actually used by current transaction until that point
        GU2 = innerGasLimit - gasleft(called inside the innerRelayCall just before preRelayedCall) :: gas actually used by innerRelayCall before calling postRelayCall
        GWP1 = GU1 + GU2 :: gas actually used by the entire transaction before calling postRelayCall
        TGO = config.gasOverhead + config.postOverhead :: extra that will be added to the charge to cover hidden costs
        GWP = GWP1 + TGO :: transaction "gas used without postRelayCall"
        */
        uint256 _tmpInitialGas = relayRequest.relayData.transactionCalldataGasUsed + vars.initialGasLeft + innerGasLimit + config.gasOverhead + config.postOverhead;
        // Calls to the recipient are performed atomically inside an inner transaction which may revert in case of
        // errors in the recipient. In either case (revert or regular execution) the return data encodes the
        // RelayCallStatus value.
        (bool success, bytes memory relayCallStatus) = address(this).call{gas:innerGasLimit}(
            abi.encodeWithSelector(RelayHub.innerRelayCall.selector, relayRequest, signature, approvalData, vars.gasAndDataLimits,
            _tmpInitialGas - aggregateGasleft(), /* totalInitialGas */
            vars.maxPossibleGas
            )
        );
        vars.success = success;
        vars.innerGasUsed = vars.gasBeforeInner-aggregateGasleft();
        (vars.status, vars.relayedCallReturnValue) = abi.decode(relayCallStatus, (RelayCallStatus, bytes));
        if ( vars.relayedCallReturnValue.length>0 ) {
            emit TransactionResult(vars.status, vars.relayedCallReturnValue);
        }
    }
    {
        if (!vars.success) {
            //Failure cases where the PM doesn't pay
            if (vars.status == RelayCallStatus.RejectedByPreRelayed ||
                    (vars.innerGasUsed <= vars.gasAndDataLimits.acceptanceBudget.add(relayRequest.relayData.transactionCalldataGasUsed)) && (
                    vars.status == RelayCallStatus.RejectedByForwarder ||
                    vars.status == RelayCallStatus.RejectedByRecipientRevert  //can only be thrown if rejectOnRecipientRevert==true
                )) {
                paymasterAccepted=false;

                emit TransactionRejectedByPaymaster(
                    vars.relayManager,
                    relayRequest.relayData.paymaster,
                    vars.relayRequestId,
                    relayRequest.request.from,
                    relayRequest.request.to,
                    msg.sender,
                    vars.functionSelector,
                    vars.innerGasUsed,
                    vars.relayedCallReturnValue);
                return (false, vars.relayedCallReturnValue);
            }
        }

        // We now perform the actual charge calculation, based on the measured gas used
        uint256 gasUsed = relayRequest.relayData.transactionCalldataGasUsed + (vars.initialGasLeft - aggregateGasleft()) + config.gasOverhead;
        uint256 charge = calculateCharge(gasUsed, relayRequest.relayData);
        uint256 devCharge = calculateDevCharge(charge);

        balances[relayRequest.relayData.paymaster] = balances[relayRequest.relayData.paymaster].sub(charge);
        balances[vars.relayManager] = balances[vars.relayManager].add(charge.sub(devCharge));
        if (devCharge > 0) { // save some gas in case of zero dev charge
            balances[config.devAddress] = balances[config.devAddress].add(devCharge);
        }

        {
            address from = relayRequest.request.from;
            address to = relayRequest.request.to;
            address paymaster = relayRequest.relayData.paymaster;
            emit TransactionRelayed(
                vars.relayManager,
                msg.sender,
                vars.relayRequestId,
                from,
                to,
                paymaster,
                vars.functionSelector,
                vars.status,
                charge);
        }
        return (true, "");
    }
    }

    struct InnerRelayCallData {
        uint256 initialGasLeft;
        uint256 gasUsedToCallInner;
        uint256 balanceBefore;
        bytes32 preReturnValue;
        bool relayedCallSuccess;
        bytes relayedCallReturnValue;
        bytes recipientContext;
        bytes data;
        bool rejectOnRecipientRevert;
    }

    /**
     * @notice This method can only by called by this `RelayHub`.
     * It wraps the execution of the `RelayRequest` in a revertable frame context.
     */
    function innerRelayCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        IPaymaster.GasAndDataLimits calldata gasAndDataLimits,
        uint256 totalInitialGas,
        uint256 maxPossibleGas
    )
    external
    returns (RelayCallStatus, bytes memory)
    {
        InnerRelayCallData memory vars;
        vars.initialGasLeft = aggregateGasleft();
        vars.gasUsedToCallInner = totalInitialGas - gasleft();
        // A new gas measurement is performed inside innerRelayCall, since
        // due to EIP150 available gas amounts cannot be directly compared across external calls

        // This external function can only be called by RelayHub itself, creating an internal transaction. Calls to the
        // recipient (preRelayedCall, the relayedCall, and postRelayedCall) are called from inside this transaction.
        require(msg.sender == address(this), "Must be called by RelayHub");

        // If either pre or post reverts, the whole internal transaction will be reverted, reverting all side effects on
        // the recipient. The recipient will still be charged for the used gas by the relay.

        // The paymaster is no allowed to withdraw balance from RelayHub during a relayed transaction. We check pre and
        // post state to ensure this doesn't happen.
        vars.balanceBefore = balances[relayRequest.relayData.paymaster];

        // First preRelayedCall is executed.
        // Note: we open a new block to avoid growing the stack too much.
        vars.data = abi.encodeWithSelector(
            IPaymaster.preRelayedCall.selector,
            relayRequest, signature, approvalData, maxPossibleGas
        );
        {
            bool success;
            bytes memory retData;
            (success, retData) = relayRequest.relayData.paymaster.call{gas:gasAndDataLimits.preRelayedCallGasLimit}(vars.data);
            if (!success) {
                GsnEip712Library.truncateInPlace(retData);
                revertWithStatus(RelayCallStatus.RejectedByPreRelayed, retData);
            }
            (vars.recipientContext, vars.rejectOnRecipientRevert) = abi.decode(retData, (bytes,bool));
        }

        // The actual relayed call is now executed. The sender's address is appended at the end of the transaction data

        {
            bool forwarderSuccess;
            (forwarderSuccess, vars.relayedCallSuccess, vars.relayedCallReturnValue) = GsnEip712Library.execute(relayRequest, signature);
            if ( !forwarderSuccess ) {
                revertWithStatus(RelayCallStatus.RejectedByForwarder, vars.relayedCallReturnValue);
            }

            if (vars.rejectOnRecipientRevert && !vars.relayedCallSuccess) {
                // we trusted the recipient, but it reverted...
                revertWithStatus(RelayCallStatus.RejectedByRecipientRevert, vars.relayedCallReturnValue);
            }
        }
        // Finally, postRelayedCall is executed, with the relayedCall execution's status and a charge estimate
        // We now determine how much the recipient will be charged, to pass this value to postRelayedCall for accurate
        // accounting.
        vars.data = abi.encodeWithSelector(
            IPaymaster.postRelayedCall.selector,
            vars.recipientContext,
            vars.relayedCallSuccess,
            vars.gasUsedToCallInner + (vars.initialGasLeft - aggregateGasleft()), /*gasUseWithoutPost*/
            relayRequest.relayData
        );

        {
        (bool successPost,bytes memory ret) = relayRequest.relayData.paymaster.call{gas:gasAndDataLimits.postRelayedCallGasLimit}(vars.data);

            if (!successPost) {
                revertWithStatus(RelayCallStatus.PostRelayedFailed, ret);
            }
        }

        if (balances[relayRequest.relayData.paymaster] < vars.balanceBefore) {
            revertWithStatus(RelayCallStatus.PaymasterBalanceChanged, "");
        }

        return (vars.relayedCallSuccess ? RelayCallStatus.OK : RelayCallStatus.RelayedCallFailed, vars.relayedCallReturnValue);
    }

    /**
     * @dev Reverts the transaction with return data set to the ABI encoding of the status argument (and revert reason data)
     */
    function revertWithStatus(RelayCallStatus status, bytes memory ret) private pure {
        bytes memory data = abi.encode(status, ret);
        GsnEip712Library.truncateInPlace(data);

        assembly {
            let dataSize := mload(data)
            let dataPtr := add(data, 32)

            revert(dataPtr, dataSize)
        }
    }

    /// @inheritdoc IRelayHub
    function calculateDevCharge(uint256 charge) public override virtual view returns (uint256){
        if (config.devFee == 0){ // save some gas in case of zero dev charge
            return 0;
        }
        unchecked {
        return charge * config.devFee / 100;
        }
    }

    /// @inheritdoc IRelayHub
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) public override virtual view returns (uint256) {
        uint256 basefee;
        if (relayData.maxFeePerGas == relayData.maxPriorityFeePerGas) {
            basefee = 0;
        } else {
            basefee = block.basefee;
        }
        uint256 chargeableGasPrice = Math.min(relayData.maxFeePerGas, Math.min(tx.gasprice, basefee + relayData.maxPriorityFeePerGas));
        return relayData.baseRelayFee.add((gasUsed.mul(chargeableGasPrice).mul(relayData.pctRelayFee.add(100))).div(100));
    }

    /// @inheritdoc IRelayHub
    function verifyRelayManagerStaked(address relayManager) public override view {
        (IStakeManager.StakeInfo memory info, bool isHubAuthorized) = stakeManager.getStakeInfo(relayManager);
        uint256 minimumStake = minimumStakePerToken[info.token];
        require(info.token != IERC20(address(0)), "relay manager not staked");
        require(info.stake >= minimumStake, "stake amount is too small");
        require(minimumStake != 0, "staking this token is forbidden");
        require(info.unstakeDelay >= config.minimumUnstakeDelay, "unstake delay is too small");
        require(info.withdrawTime == 0, "stake has been withdrawn");
        require(isHubAuthorized, "this hub is not authorized by SM");
    }

    /// @inheritdoc IRelayHub
    function deprecateHub(uint256 _deprecationTime) public override onlyOwner {
        require(!isDeprecated(), "Already deprecated");
        deprecationTime = _deprecationTime;
        emit HubDeprecated(deprecationTime);
    }

    /// @inheritdoc IRelayHub
    function isDeprecated() public override view returns (bool) {
        return block.timestamp >= deprecationTime;
    }

    /// @notice Prevents any address other than the `Penalizer` from calling this method.
    modifier penalizerOnly () {
        require(msg.sender == penalizer, "Not penalizer");
        _;
    }

    /// @inheritdoc IRelayHub
    function penalize(address relayWorker, address payable beneficiary) external override penalizerOnly {
        address relayManager = workerToManager[relayWorker];
        // The worker must be controlled by a manager with a locked stake
        require(relayManager != address(0), "Unknown relay worker");
        (IStakeManager.StakeInfo memory stakeInfo,) = stakeManager.getStakeInfo(relayManager);
        require(stakeInfo.stake > 0, "relay manager not staked");
        stakeManager.penalizeRelayManager(relayManager, beneficiary, stakeInfo.stake);
    }

    /// @inheritdoc IRelayHub
    function aggregateGasleft() public override virtual view returns (uint256){
        return gasleft();
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
// minimal bytes manipulation required by GSN
// a minimal subset from 0x/LibBytes
/* solhint-disable no-inline-assembly */

library MinLibBytes {

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data, uint256 maxlen) internal pure {
        if (data.length > maxlen) {
            assembly { mstore(data, maxlen) }
        }
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require (b.length >= index + 20, "readAddress: data too short");

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(b.length >= index + 32, "readBytes32: data too short" );

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
        }
        return result;
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(b.length >= index + 4, "readBytes4: data too short");

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, add(index,32)))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */
// SPDX-License-Identifier: GPL-3.0-only

import "../utils/MinLibBytes.sol";
import "./GsnTypes.sol";

/**
 * @title The GSN Solidity Utils Library
 * @notice Some library functions used throughout the GSN Solidity codebase.
 */
library GsnUtils {

    /**
     * @notice Calculate an identifier for the meta-transaction in a format similar to a transaction hash.
     * Note that uniqueness relies on signature and may not be enforced if meta-transactions are verified
     * with a different algorithm, e.g. when batching.
     * @param relayRequest The `RelayRequest` for which an ID is being calculated.
     * @param signature The signature for the `RelayRequest`. It is not validated here and may even remain empty.
     */
    function getRelayRequestID(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature)
    internal
    pure
    returns (bytes32) {
        return keccak256(abi.encode(relayRequest.request.from, relayRequest.request.nonce, signature));
    }

    /**
     * @notice Extract the method identifier signature from the encoded function call.
     */
    function getMethodSig(bytes memory msgData) internal pure returns (bytes4) {
        return MinLibBytes.readBytes4(msgData, 0);
    }

    /**
     * @notice Extract a parameter from encoded-function block.
     * see: https://solidity.readthedocs.io/en/develop/abi-spec.html#formal-specification-of-the-encoding
     * The return value should be casted to the right type (`uintXXX`/`bytesXXX`/`address`/`bool`/`enum`).
     * @param msgData Byte array containing a uint256 value.
     * @param index Index in byte array of uint256 value.
     * @return result uint256 value from byte array.
     */
    function getParam(bytes memory msgData, uint256 index) internal pure returns (uint256 result) {
        return MinLibBytes.readUint256(msgData, 4 + index * 32);
    }

    /// @notice Re-throw revert with the same revert data.
    function revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data,32), mload(data))
        }
    }

}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../utils/GsnTypes.sol";
import "../interfaces/IERC2771Recipient.sol";
import "../forwarder/IForwarder.sol";

import "./GsnUtils.sol";

/**
 * @title The ERC-712 Library for GSN
 * @notice Bridge Library to convert a GSN RelayRequest into a valid `ForwardRequest` for a `Forwarder`.
 */
library GsnEip712Library {
    // maximum length of return value/revert reason for 'execute' method. Will truncate result if exceeded.
    uint256 private constant MAX_RETURN_SIZE = 1024;

    //copied from Forwarder (can't reference string constants even from another library)
    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntilTime";

    bytes public constant RELAYDATA_TYPE = "RelayData(uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 pctRelayFee,uint256 baseRelayFee,address relayWorker,address paymaster,address forwarder,bytes paymasterData,uint256 clientId)";

    string public constant RELAY_REQUEST_NAME = "RelayRequest";
    string public constant RELAY_REQUEST_SUFFIX = string(abi.encodePacked("RelayData relayData)", RELAYDATA_TYPE));

    bytes public constant RELAY_REQUEST_TYPE = abi.encodePacked(
        RELAY_REQUEST_NAME,"(",GENERIC_PARAMS,",", RELAY_REQUEST_SUFFIX);

    bytes32 public constant RELAYDATA_TYPEHASH = keccak256(RELAYDATA_TYPE);
    bytes32 public constant RELAY_REQUEST_TYPEHASH = keccak256(RELAY_REQUEST_TYPE);

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    function splitRequest(
        GsnTypes.RelayRequest calldata req
    )
    internal
    pure
    returns (
        bytes memory suffixData
    ) {
        suffixData = abi.encode(
            hashRelayData(req.relayData));
    }

    //verify that the recipient trusts the given forwarder
    // MUST be called by paymaster
    function verifyForwarderTrusted(GsnTypes.RelayRequest calldata relayRequest) internal view {
        (bool success, bytes memory ret) = relayRequest.request.to.staticcall(
            abi.encodeWithSelector(
                IERC2771Recipient.isTrustedForwarder.selector, relayRequest.relayData.forwarder
            )
        );
        require(success, "isTrustedForwarder: reverted");
        require(ret.length == 32, "isTrustedForwarder: bad response");
        require(abi.decode(ret, (bool)), "invalid forwarder for recipient");
    }

    function verifySignature(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal view {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(relayRequest.relayData.forwarder);
        IForwarder forwarder = IForwarder(payable(relayRequest.relayData.forwarder));
        forwarder.verify(relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature);
    }

    function verify(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal view {
        verifyForwarderTrusted(relayRequest);
        verifySignature(relayRequest, signature);
    }

    function execute(GsnTypes.RelayRequest calldata relayRequest, bytes calldata signature) internal returns (bool forwarderSuccess, bool callSuccess, bytes memory ret) {
        (bytes memory suffixData) = splitRequest(relayRequest);
        bytes32 _domainSeparator = domainSeparator(relayRequest.relayData.forwarder);
        /* solhint-disable-next-line avoid-low-level-calls */
        (forwarderSuccess, ret) = relayRequest.relayData.forwarder.call(
            abi.encodeWithSelector(IForwarder.execute.selector,
            relayRequest.request, _domainSeparator, RELAY_REQUEST_TYPEHASH, suffixData, signature
        ));
        if ( forwarderSuccess ) {

          //decode return value of execute:
          (callSuccess, ret) = abi.decode(ret, (bool, bytes));
        }
        truncateInPlace(ret);
    }

    //truncate the given parameter (in-place) if its length is above the given maximum length
    // do nothing otherwise.
    //NOTE: solidity warns unless the method is marked "pure", but it DOES modify its parameter.
    function truncateInPlace(bytes memory data) internal pure {
        MinLibBytes.truncateInPlace(data, MAX_RETURN_SIZE);
    }

    function domainSeparator(address forwarder) internal view returns (bytes32) {
        return hashDomain(EIP712Domain({
            name : "GSN Relayed Transaction",
            version : "2",
            chainId : getChainID(),
            verifyingContract : forwarder
            }));
    }

    function getChainID() internal view returns (uint256 id) {
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
    }

    function hashDomain(EIP712Domain memory req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(req.name)),
                keccak256(bytes(req.version)),
                req.chainId,
                req.verifyingContract));
    }

    function hashRelayData(GsnTypes.RelayData calldata req) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                RELAYDATA_TYPEHASH,
                req.maxFeePerGas,
                req.maxPriorityFeePerGas,
                req.pctRelayFee,
                req.baseRelayFee,
                req.relayWorker,
                req.paymaster,
                req.forwarder,
                keccak256(req.paymasterData),
                req.clientId
            ));
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../utils/GsnTypes.sol";

/**
 * @title The RelayHub Validator Library
 * @notice Validates the `msg.data` received by the `RelayHub` does not contain unnecessary bytes.
 * Including these extra bytes would allow the Relay Server to inflate transaction costs and overcharge the client.
 */
library RelayHubValidator {

    /// @notice Validate that encoded `relayCall` is properly packed without any extra bytes
    function verifyTransactionPacking(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    ) internal pure {
        // abicoder v2: https://docs.soliditylang.org/en/latest/abi-spec.html
        // each static param/member is 1 word
        // struct (with dynamic members) has offset to struct which is 1 word
        // dynamic member is 1 word offset to actual value, which is 1-word length and ceil(length/32) words for data
        // relayCall has 5 method params,
        // relayRequest: 2 members
        // relayData 9 members
        // ForwardRequest: 7 members
        // total 22 32-byte words if all dynamic params are zero-length.
        uint256 expectedMsgDataLen = 4 + 23 * 32 +
            dynamicParamSize(signature) +
            dynamicParamSize(approvalData) +
            dynamicParamSize(relayRequest.request.data) +
            dynamicParamSize(relayRequest.relayData.paymasterData);
        // zero-length signature is allowed in a batch relay transaction
        require(signature.length <= 65, "invalid signature length");
        require(expectedMsgDataLen == msg.data.length, "extra msg.data bytes" );
    }

    // helper method for verifyTransactionPacking:
    // size (in bytes) of the given "bytes" parameter. size include the length (32-byte word),
    // and actual data size, rounded up to full 32-byte words
    function dynamicParamSize(bytes calldata buf) internal pure returns (uint256) {
        return 32 + ((buf.length + 31) & (type(uint256).max - 31));
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../forwarder/IForwarder.sol";

interface GsnTypes {
    /// @notice maxFeePerGas, maxPriorityFeePerGas, pctRelayFee and baseRelayFee must be validated inside of the paymaster's preRelayedCall in order not to overpay
    struct RelayData {
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 pctRelayFee;
        uint256 baseRelayFee;
        uint256 transactionCalldataGasUsed;
        address relayWorker;
        address paymaster;
        address forwarder;
        bytes paymasterData;
        uint256 clientId;
    }

    //note: must start with the ForwardRequest to be an extension of the generic forwarder
    struct RelayRequest {
        IForwarder.ForwardRequest request;
        RelayData relayData;
    }
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../utils/GsnTypes.sol";
import "./IStakeManager.sol";

/**
 * @title The RelayHub interface
 * @notice The implementation of this interface provides all the information the GSN client needs to
 * create a valid `RelayRequest` and also serves as an entry point for such requests.
 *
 * @notice The RelayHub also handles all the related financial records and hold the balances of participants.
 * The Paymasters keep their Ether deposited in the `RelayHub` in order to pay for the `RelayRequest`s that thay choose
 * to pay for, and Relay Servers keep their earned Ether in the `RelayHub` until they choose to `withdraw()`
 *
 * @notice The RelayHub on each supported network only needs a single instance and there is usually no need for dApp
 * developers or Relay Server operators to redeploy, reimplement, modify or override the `RelayHub`.
 */
interface IRelayHub is IERC165 {
    /**
     * @notice A struct that contains all the parameters of the `RelayHub` that can be modified after the deployment.
     */
    struct RelayHubConfig {
        // maximum number of worker accounts allowed per manager
        uint256 maxWorkerCount;
        // Gas set aside for all relayCall() instructions to prevent unexpected out-of-gas exceptions
        uint256 gasReserve;
        // Gas overhead to calculate gasUseWithoutPost
        uint256 postOverhead;
        // Gas cost of all relayCall() instructions after actual 'calculateCharge()'
        // Assume that relay has non-zero balance (costs 15'000 more otherwise).
        uint256 gasOverhead;
        // Minimum unstake delay seconds of a relay manager's stake on the StakeManager
        uint256 minimumUnstakeDelay;
        // Developers address
        address devAddress;
        // 0 < fee < 100, as percentage of total charge from paymaster to relayer
        uint8 devFee;

    }

    /// @notice Emitted when a configuration of the `RelayHub` is changed
    event RelayHubConfigured(RelayHubConfig config);

    /// @notice Emitted when relays are added by a relayManager
    event RelayWorkersAdded(
        address indexed relayManager,
        address[] newRelayWorkers,
        uint256 workersCount
    );

    /// @notice Emitted when an account withdraws funds from the `RelayHub`.
    event Withdrawn(
        address indexed account,
        address indexed dest,
        uint256 amount
    );

    /// @notice Emitted when `depositFor` is called, including the amount and account that was funded.
    event Deposited(
        address indexed paymaster,
        address indexed from,
        uint256 amount
    );

    /// @notice Emitted for each token configured for staking in setMinimumStakes
    event StakingTokenDataChanged(
        address token,
        uint256 minimumStake
    );

    /**
     * @notice Emitted when an attempt to relay a call fails and the `Paymaster` does not accept the transaction.
     * The actual relayed call was not executed, and the recipient not charged.
     * @param reason contains a revert reason returned from preRelayedCall or forwarder.
     */
    event TransactionRejectedByPaymaster(
        address indexed relayManager,
        address indexed paymaster,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address relayWorker,
        bytes4 selector,
        uint256 innerGasUsed,
        bytes reason
    );

    /**
     * @notice Emitted when a transaction is relayed. Note that the actual internal function call might be reverted.
     * The reason for a revert will be indicated in the `status` field of a corresponding `RelayCallStatus` value.
     * @notice `charge` is the Ether value deducted from the `Paymaster` balance.
     * The amount added to the `relayManager` balance will be lower if there is an activated `devFee` in the `config`.
     */
    event TransactionRelayed(
        address indexed relayManager,
        address indexed relayWorker,
        bytes32 indexed relayRequestID,
        address from,
        address to,
        address paymaster,
        bytes4 selector,
        RelayCallStatus status,
        uint256 charge
    );

    /// @notice This event is emitted in case the internal function returns a value or reverts with a revert string.
    event TransactionResult(
        RelayCallStatus status,
        bytes returnValue
    );

    /// @notice This event is emitted in case this `RelayHub` is deprecated and will stop serving transactions soon.
    event HubDeprecated(uint256 deprecationTime);

    /**
     * Error codes that describe all possible failure reasons reported in the `TransactionRelayed` event `status` field.
     *  @param OK The transaction was successfully relayed and execution successful - never included in the event.
     *  @param RelayedCallFailed The transaction was relayed, but the relayed call failed.
     *  @param RejectedByPreRelayed The transaction was not relayed due to preRelatedCall reverting.
     *  @param RejectedByForwarder The transaction was not relayed due to forwarder check (signature,nonce).
     *  @param PostRelayedFailed The transaction was relayed and reverted due to postRelatedCall reverting.
     *  @param PaymasterBalanceChanged The transaction was relayed and reverted due to the paymaster balance change.
     */
    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        RejectedByPreRelayed,
        RejectedByForwarder,
        RejectedByRecipientRevert,
        PostRelayedFailed,
        PaymasterBalanceChanged
    }

    /**
     * @notice Add new worker addresses controlled by the sender who must be a staked Relay Manager address.
     * Emits a `RelayWorkersAdded` event.
     * This function can be called multiple times, emitting new events.
     */
    function addRelayWorkers(address[] calldata newRelayWorkers) external;

    function verifyCanRegister(address relayManager) external;

    // Balance management

    /**
     * @notice Deposits ether for a `Paymaster`, so that it can and pay for relayed transactions.
     * :warning: **Warning** :warning: Unused balance can only be withdrawn by the holder itself, by calling `withdraw`.
     * Emits a `Deposited` event.
     */
    function depositFor(address target) external payable;

    /**
     * @notice Withdraws from an account's balance, sending it back to the caller.
     * Relay Managers call this to retrieve their revenue, and `Paymasters` can also use it to reduce their funding.
     * Emits a `Withdrawn` event.
     */
    function withdraw(uint256 amount, address payable dest) external;

    // Relaying

    /**
     * @notice Relays a transaction. For this to succeed, multiple conditions must be met:
     *  - `Paymaster`'s `preRelayCall` method must succeed and not revert.
     *  - the `msg.sender` must be a registered Relay Worker that the user signed to use.
     *  - the transaction's gas fees must be equal or larger than the ones that were signed by the sender.
     *  - the transaction must have enough gas to run all internal transactions if they use all gas available to them.
     *  - the `Paymaster` must have enough balance to pay the Relay Worker if all gas is spent.
     *
     * @notice If all conditions are met, the call will be relayed and the `Paymaster` charged.
     *
     * @param maxAcceptanceBudget The maximum valid value for `paymaster.getGasLimits().acceptanceBudget` to return.
     * @param relayRequest All details of the requested relayed call.
     * @param signature The client's EIP-712 signature over the `relayRequest` struct.
     * @param approvalData The dapp-specific data forwarded to the `Paymaster`'s `preRelayedCall` method.
     * This value is **not** verified by the `RelayHub` in any way.
     * As an example, it can be used to pass some kind of a third-party signature to the `Paymaster` for verification.
     *
     * Emits a `TransactionRelayed` event regardless of whether the transaction succeeded or failed.
     */
    function relayCall(
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    )
    external
    returns (bool paymasterAccepted, bytes memory returnValue);

    /**
     * @notice In case the Relay Worker has been found to be in violation of some rules by the `Penalizer` contract,
     * the `Penalizer` will call this method to execute a penalization.
     * The `RelayHub` will look up the Relay Manager of the given Relay Worker and will forward the call to
     * the `StakeManager` contract. The `RelayHub` does not perform the actual penalization either.
     * @param relayWorker The address of the Relay Worker that committed a penalizable offense.
     * @param beneficiary The address that called the `Penalizer` and will receive a reward for it.
     */
    function penalize(address relayWorker, address payable beneficiary) external;

    /**
     * @notice Sets or changes the configuration of this `RelayHub`.
     * @param _config The new configuration.
     */
    function setConfiguration(RelayHubConfig memory _config) external;

    /**
     * @notice Sets or changes the minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     * @param token An array of addresses of ERC-20 compatible tokens.
     * @param minimumStake An array of minimal amounts necessary for a corresponding token, in wei.
     */
    function setMinimumStakes(IERC20[] memory token, uint256[] memory minimumStake) external;

    /**
     * @notice Deprecate hub by reverting all incoming `relayCall()` calls starting from a given timestamp
     * @param _deprecationTime The timestamp in seconds after which the `RelayHub` stops serving transactions.
     */
    function deprecateHub(uint256 _deprecationTime) external;

    /**
     * @notice The fee is expressed as a base fee in wei plus percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the recipient will be charged for 1.4 times the spent amount.
     * @param gasUsed An amount of gas used by the transaction.
     * @param relayData The details of a transaction signed by the sender.
     * @return The calculated charge, in wei.
     */
    function calculateCharge(uint256 gasUsed, GsnTypes.RelayData calldata relayData) external view returns (uint256);

    /**
     * @notice The fee is expressed as a  percentage of the actual charge.
     * For example, a value '40' stands for a 40% fee, so the Relay Manager will only get 60% of the `charge`.
     * @param charge The amount of Ether in wei the Paymaster will be charged for this transaction.
     * @return The calculated devFee, in wei.
     */
    function calculateDevCharge(uint256 charge) external view returns (uint256);
    /* getters */

    /// @return config The configuration of the `RelayHub`.
    function getConfiguration() external view returns (RelayHubConfig memory config);

    /**
     * @param token An address of an ERC-20 compatible tokens.
     * @return The minimum amount of a given `token` that needs to be staked so that the Relay Manager
     * is considered to be 'staked' by this `RelayHub`. Zero value means this token is not allowed for staking.
     */
    function getMinimumStakePerToken(IERC20 token) external view returns (uint256);

    /**
     * @param worker An address of the Relay Worker.
     * @return The address of its Relay Manager.
     */
    function getWorkerManager(address worker) external view returns (address);

    /**
     * @param manager An address of the Relay Manager.
     * @return The count of Relay Workers associated with this Relay Manager.
     */
    function getWorkerCount(address manager) external view returns (uint256);

    /// @return An account's balance. It can be either a deposit of a `Paymaster`, or a revenue of a Relay Manager.
    function balanceOf(address target) external view returns (uint256);

    /// @return The `StakeManager` address for this `RelayHub`.
    function getStakeManager() external view returns (IStakeManager);

    /// @return The `Penalizer` address for this `RelayHub`.
    function getPenalizer() external view returns (address);

    /// @return The `RelayRegistrar` address for this `RelayHub`.
    function getRelayRegistrar() external view returns (address);

    /// @return The `BatchGateway` address for this `RelayHub`.
    function getBatchGateway() external view returns (address);

    /**
     * @notice Uses `StakeManager` to decide if the Relay Manager can be considered staked or not.
     * Returns if the stake's token, amount and delay satisfy all requirements, reverts otherwise.
     */
    function verifyRelayManagerStaked(address relayManager) external view;

    /// @return `true` if the `RelayHub` is deprecated, `false` it it is not deprecated and can serve transactions.
    function isDeprecated() external view returns (bool);

    /// @return The timestamp from which the hub no longer allows relaying calls.
    function getDeprecationTime() external view returns (uint256);

    /// @return The block number in which the contract has been deployed.
    function getCreationBlock() external view returns (uint256);

    /// @return a SemVer-compliant version of the `RelayHub` contract.
    function versionHub() external view returns (string memory);

    /// @return A total measurable amount of gas left to current execution. Same as 'gasleft()' for pure EVMs.
    function aggregateGasleft() external view returns (uint256);
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "../utils/GsnTypes.sol";

/**
 * @title The Paymaster Interface
 * @notice Contracts implementing this interface exist to make decision about paying the transaction fee to the relay.
 *
 * @notice There are two callbacks here that are executed by the RelayHub: `preRelayedCall` and `postRelayedCall`.
 *
 * @notice It is recommended that your implementation inherits from the abstract BasePaymaster contract.
*/
interface IPaymaster is IERC165 {
    /**
     * @notice The limits this Paymaster wants to be imposed by the RelayHub on user input. See `getGasAndDataLimits`.
     */
    struct GasAndDataLimits {
        uint256 acceptanceBudget;
        uint256 preRelayedCallGasLimit;
        uint256 postRelayedCallGasLimit;
        uint256 calldataSizeLimit;
    }

    /**
     * @notice Return the Gas Limits for Paymaster's functions and maximum msg.data length values for this Paymaster.
     * This function allows different paymasters to have different properties without changes to the RelayHub.
     * @return limits An instance of the `GasAndDataLimits` struct
     *
     * ##### `acceptanceBudget`
     * If the transactions consumes more than `acceptanceBudget` this Paymaster will be charged for gas no matter what.
     * Transaction that gets rejected after consuming more than `acceptanceBudget` gas is on this Paymaster's expense.
     *
     * Should be set to an amount gas this Paymaster expects to spend deciding whether to accept or reject a request.
     * This includes gas consumed by calculations in the `preRelayedCall`, `Forwarder` and the recipient contract.
     *
     * :warning: **Warning** :warning: As long this value is above `preRelayedCallGasLimit`
     * (see defaults in `BasePaymaster`), the Paymaster is guaranteed it will never pay for rejected transactions.
     * If this value is below `preRelayedCallGasLimit`, it might might make Paymaster open to a "griefing" attack.
     *
     * The relayers should prefer lower `acceptanceBudget`, as it improves their chances of being compensated.
     * From a Relay's point of view, this is the highest gas value a bad Paymaster may cost the relay,
     * since the paymaster will pay anything above that value regardless of whether the transaction succeeds or reverts.
     * Specifying value too high might make the call rejected by relayers (see `maxAcceptanceBudget` in server config).
     *
     * ##### `preRelayedCallGasLimit`
     * The max gas usage of preRelayedCall. Any revert of the `preRelayedCall` is a request rejection by the paymaster.
     * As long as `acceptanceBudget` is above `preRelayedCallGasLimit`, any such revert is not payed by the paymaster.
     *
     * ##### `postRelayedCallGasLimit`
     * The max gas usage of postRelayedCall. The Paymaster is not charged for the maximum, only for actually used gas.
     * Note that an OOG will revert the inner transaction, but the paymaster will be charged for it anyway.
     */
    function getGasAndDataLimits()
    external
    view
    returns (
        GasAndDataLimits memory limits
    );

    /**
     * @notice :warning: **Warning** :warning: using incorrect Forwarder may cause the Paymaster to agreeing to pay for invalid transactions.
     * @return trustedForwarder The address of the `Forwarder` that is trusted by this Paymaster to execute the requests.
     */
    function getTrustedForwarder() external view returns (address trustedForwarder);

    /**
     * @return relayHub The address of the `RelayHub` that is trusted by this Paymaster to execute the requests.
     */
    function getRelayHub() external view returns (address relayHub);

    /**
     * @notice Called by the Relay in view mode and later by the `RelayHub` on-chain to validate that
     * the Paymaster agrees to pay for this call.
     *
     * :warning: **Warning** :warning: This method MUST be protected with `relayHubOnly()` in case it modifies state.
     *
     * The request is considered to be rejected by the Paymaster in one of the following conditions:
     *  - `preRelayedCall()` method reverts
     *  - the `Forwarder` reverts because of nonce or signature error
     *  - the `Paymaster` returned `rejectOnRecipientRevert: true` and the recipient contract reverted
     *    (and all that did not consume more than `acceptanceBudget` gas).
     *
     * In any of the above cases, all Paymaster calls and the recipient call are reverted.
     * In any other case the Paymaster will pay for the gas cost of the transaction.
     * Note that even if `postRelayedCall` is reverted the Paymaster will be charged.
     *

     * @param relayRequest - the full relay request structure
     * @param signature - user's EIP712-compatible signature of the `relayRequest`.
     * Note that in most cases the paymaster shouldn't try use it at all. It is always checked
     * by the forwarder immediately after preRelayedCall returns.
     * @param approvalData - extra dapp-specific data (e.g. signature from trusted party)
     * @param maxPossibleGas - based on values returned from `getGasAndDataLimits`
     * the RelayHub will calculate the maximum possible amount of gas the user may be charged for.
     * In order to convert this value to wei, the Paymaster has to call "relayHub.calculateCharge()"
     *
     * @return context
     * A byte array to be passed to postRelayedCall.
     * Can contain any data needed by this Paymaster in any form or be empty if no extra data is needed.
     * @return rejectOnRecipientRevert
     * The flag that allows a Paymaster to "delegate" the rejection to the recipient code.
     * It also means the Paymaster trust the recipient to reject fast: both preRelayedCall,
     * forwarder check and recipient checks must fit into the GasLimits.acceptanceBudget,
     * otherwise the TX is paid by the Paymaster.
     * `true` if the Paymaster wants to reject the TX if the recipient reverts.
     * `false` if the Paymaster wants rejects by the recipient to be completed on chain and paid by the Paymaster.
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    returns (bytes memory context, bool rejectOnRecipientRevert);

    /**
     * @notice This method is called after the actual relayed function call.
     * It may be used to record the transaction (e.g. charge the caller by some contract logic) for this call.
     *
     * :warning: **Warning** :warning: This method MUST be protected with relayHubOnly() in case it modifies state.
     *
     * Revert in this functions causes a revert of the client's relayed call (and preRelayedCall(), but the Paymaster
     * is still committed to pay the relay for the entire transaction.
     *
     * @param context The call context, as returned by the preRelayedCall
     * @param success `true` if the relayed call succeeded, false if it reverted
     * @param gasUseWithoutPost The actual amount of gas used by the entire transaction, EXCEPT
     *        the gas used by the postRelayedCall itself.
     * @param relayData The relay params of the request. can be used by relayHub.calculateCharge()
     *
     */
    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) external;

    /**
     * @return version The SemVer string of this Paymaster's version.
     */
    function versionPaymaster() external view returns (string memory);
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The Forwarder Interface
 * @notice The contracts implementing this interface take a role of authorization, authentication and replay protection
 * for contracts that choose to trust a `Forwarder`, instead of relying on a mechanism built into the Ethereum protocol.
 *
 * @notice if the `Forwarder` contract decides that an incoming `ForwardRequest` is valid, it must append 20 bytes that
 * represent the caller to the `data` field of the request and send this new data to the target address (the `to` field)
 *
 * :warning: **Warning** :warning: The Forwarder can have a full control over a `Recipient` contract.
 * Any vulnerability in a `Forwarder` implementation can make all of its `Recipient` contracts susceptible!
 * Recipient contracts should only trust forwarders that passed through security audit,
 * otherwise they are susceptible to identity theft.
 */
interface IForwarder is IERC165 {

    /**
     * @notice A representation of a request for a `Forwarder` to send `data` on behalf of a `from` to a target (`to`).
     */
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntilTime;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    /**
     * @param from The address of a sender.
     * @return The nonce for this address.
     */
    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * @notice Verify the transaction is valid and can be executed.
     * Implementations must validate the signature and the nonce of the request are correct.
     * Does not revert and returns successfully if the input is valid.
     * Reverts if any validation has failed. For instance, if either signature or nonce are incorrect.
     * Reverts if `domainSeparator` or `requestTypeHash` are not registered as well.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * @notice Executes a transaction specified by the `ForwardRequest`.
     * The transaction is first verified and then executed.
     * The success flag and returned bytes array of the `CALL` are returned as-is.
     *
     * This method would revert only in case of a verification error.
     *
     * All the target errors are reported using the returned success flag and returned bytes array.
     *
     * @param forwardRequest All requested transaction parameters.
     * @param domainSeparator The domain used when signing this request.
     * @param requestTypeHash The request type used when signing this request.
     * @param suffixData The ABI-encoded extension data for the current `RequestType` used when signing this request.
     * @param signature The client signature to be validated.
     *
     * @return success The success flag of the underlying `CALL` to the target address.
     * @return ret The byte array returned by the underlying `CALL` to the target address.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * @notice Register a new Request typehash.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @param typeName The name of the request type.
     * @param typeSuffix Any extra data after the generic params. Must contain add at least one param.
     * The generic ForwardRequest type is always registered by the constructor.
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * @notice Register a new domain separator.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @notice The domain separator must have the following fields: `name`, `version`, `chainId`, `verifyingContract`.
     * The `chainId` is the current network's `chainId`, and the `verifyingContract` is this Forwarder's address.
     * This method accepts the domain name and version to create and register the domain separator value.
     * @param name The domain's display name.
     * @param version The domain/protocol version.
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title The StakeManager Interface
 * @notice In order to prevent an attacker from registering a large number of unresponsive relays, the GSN requires
 * the Relay Server to maintain a permanently locked stake in the system before being able to register.
 *
 * @notice Also, in some cases the behavior of a Relay Server may be found to be illegal by a `Penalizer` contract.
 * In such case, the stake will never be returned to the Relay Server operator and will be slashed.
 *
 * @notice An implementation of this interface is tasked with keeping Relay Servers' stakes, made in any ERC-20 token.
 * Note that the `RelayHub` chooses which ERC-20 tokens to support and how much stake is needed.
 */
interface IStakeManager {

    /// @notice Emitted when a `stake` or `unstakeDelay` are initialized or increased.
    event StakeAdded(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 stake,
        uint256 unstakeDelay
    );

    /// @notice Emitted once a stake is scheduled for withdrawal.
    event StakeUnlocked(
        address indexed relayManager,
        address indexed owner,
        uint256 withdrawTime
    );

    /// @notice Emitted when owner withdraws `relayManager` funds.
    event StakeWithdrawn(
        address indexed relayManager,
        address indexed owner,
        IERC20 token,
        uint256 amount
    );

    /// @notice Emitted when an authorized `RelayHub` penalizes a `relayManager`.
    event StakePenalized(
        address indexed relayManager,
        address indexed beneficiary,
        IERC20 token,
        uint256 reward
    );

    /// @notice Emitted when a `relayManager` adds a new `RelayHub` to a list of authorized.
    event HubAuthorized(
        address indexed relayManager,
        address indexed relayHub
    );

    /// @notice Emitted when a `relayManager` removes a `RelayHub` from a list of authorized.
    event HubUnauthorized(
        address indexed relayManager,
        address indexed relayHub,
        uint256 removalTime
    );

    /// @notice Emitted when a `relayManager` sets its `owner`. This is necessary to prevent stake hijacking.
    event OwnerSet(
        address indexed relayManager,
        address indexed owner
    );

    /// @notice Emitted when a `burnAddress` is changed.
    event BurnAddressSet(
        address indexed burnAddress
    );

    /**
     * @param stake - amount of ether staked for this relay
     * @param unstakeDelay - number of seconds to elapse before the owner can retrieve the stake after calling 'unlock'
     * @param withdrawTime - timestamp in seconds when 'withdraw' will be callable, or zero if the unlock has not been called
     * @param owner - address that receives revenue and manages relayManager's stake
     */
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelay;
        uint256 withdrawTime;
        IERC20 token;
        address owner;
    }

    struct RelayHubInfo {
        uint256 removalTime;
    }

    /**
     * @notice Set the owner of a Relay Manager. Called only by the RelayManager itself.
     * Note that owners cannot transfer ownership - if the entry already exists, reverts.
     * @param owner - owner of the relay (as configured off-chain)
     */
    function setRelayManagerOwner(address owner) external;

    /**
     * @notice Put a stake for a relayManager and set its unstake delay.
     * Only the owner can call this function. If the entry does not exist, reverts.
     * The owner must give allowance of the ERC-20 token to the StakeManager before calling this method.
     * It is the RelayHub who has a configurable list of minimum stakes per token. StakeManager accepts all tokens.
     * @param token The address of an ERC-20 token that is used by the relayManager as a stake
     * @param relayManager The address that represents a stake entry and controls relay registrations on relay hubs
     * @param unstakeDelay The number of seconds to elapse before an owner can retrieve the stake after calling `unlock`
     * @param amount The amount of tokens to be taken from the relayOwner and locked in the StakeManager as a stake
     */
    function stakeForRelayManager(IERC20 token, address relayManager, uint256 unstakeDelay, uint256 amount) external;

    /**
     * @notice Schedule the unlocking of the stake. The `unstakeDelay` must pass before owner can call `withdrawStake`.
     * @param relayManager The address of a Relay Manager whose stake is to be unlocked.
     */
    function unlockStake(address relayManager) external;
    /**
     * @notice Withdraw the unlocked stake.
     * @param relayManager The address of a Relay Manager whose stake is to be withdrawn.
     */
    function withdrawStake(address relayManager) external;

    /**
     * @notice Add the `RelayHub` to a list of authorized by this Relay Manager.
     * This allows the RelayHub to penalize this Relay Manager. The `RelayHub` cannot trust a Relay it cannot penalize.
     * @param relayManager The address of a Relay Manager whose stake is to be authorized for the new `RelayHub`.
     * @param relayHub The address of a `RelayHub` to be authorized.
     */
    function authorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `authorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function authorizeHubByManager(address relayHub) external;

    /**
     * @notice Remove the `RelayHub` from a list of authorized by this Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @param relayHub The address of a `RelayHub` to be unauthorized.
     */
    function unauthorizeHubByOwner(address relayManager, address relayHub) external;

    /**
     * @notice Same as `unauthorizeHubByOwner` but can be called by the RelayManager itself.
     */
    function unauthorizeHubByManager(address relayHub) external;

    /**
     * Slash the stake of the relay relayManager. In order to prevent stake kidnapping, burns part of stake on the way.
     * @param relayManager The address of a Relay Manager to be penalized.
     * @param beneficiary The address that receives part of the penalty amount.
     * @param amount A total amount of penalty to be withdrawn from stake.
     */
    function penalizeRelayManager(address relayManager, address beneficiary, uint256 amount) external;

    /**
     * @notice Get the stake details information for the given Relay Manager.
     * @param relayManager The address of a Relay Manager.
     * @return stakeInfo The `StakeInfo` structure.
     * @return isSenderAuthorizedHub `true` if the `msg.sender` for this call was a `RelayHub` that is authorized now.
     * `false` if the `msg.sender` for this call is not authorized.
     */
    function getStakeInfo(address relayManager) external view returns (StakeInfo memory stakeInfo, bool isSenderAuthorizedHub);

    /**
     * @return The maximum unstake delay this `StakeManger` allows. This is to prevent locking money forever by mistake.
     */
    function getMaxUnstakeDelay() external view returns (uint256);

    /**
     * @notice Change the address that will receive the 'burned' part of the penalized stake.
     * This is done to prevent malicious Relay Server from penalizing itself and breaking even.
     */
    function setBurnAddress(address _burnAddress) external;

    /**
     * @return The address that will receive the 'burned' part of the penalized stake.
     */
    function getBurnAddress() external view returns (address);

    /**
     * @return the block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @return a SemVer-compliant version of the `StakeManager` contract.
     */
    function versionSM() external view returns (string memory);
}

pragma solidity ^0.8.6;

//SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title The RelayRegistrar Interface
 * @notice The on-chain registrar for all registered Relay Managers.
 *
 * @notice The client can use an implementation of a `RelayRegistrar` to find relay registration info.
 *
 */
interface IRelayRegistrar is IERC165 {

    /**
     * @notice A struct containing all the information necessary to client to interact with the Relay Server.
     */
    struct RelayInfo {
        //last registration block number
        uint32 lastSeenBlockNumber;
        //last registration block timestamp
        uint40 lastSeenTimestamp;
        //stake (first registration) block number
        uint32 firstSeenBlockNumber;
        //stake (first registration) block timestamp
        uint40 firstSeenTimestamp;
        uint80 baseRelayFee;
        uint16 pctRelayFee;
        bytes32[3] urlParts;
        address relayManager;
    }

    /**
     * @notice Emitted when a relay server registers or updates its details.
     * Looking up these events allows a client to discover registered Relay Servers.
     */
    event RelayServerRegistered(
        address indexed relayManager,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        bytes32[3] relayUrl
    );

    /**
     * @notice This function is called by Relay Servers in order to register or to update their registration.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @param baseRelayFee The base fee the Relay Server charges for a single transaction in Ether, in wei.
     * @param pctRelayFee The percent of the total charge to add as a Relay Server fee to the total charge.
     * @param url The URL of the Relay Server that is listening to the clients' requests.
     */
    function registerRelayServer(
        address relayHub,
        uint80 baseRelayFee,
        uint16 pctRelayFee,
        bytes32[3] calldata url
    ) external;

    /**
     * @return The block number in which the contract has been deployed.
     */
    function getCreationBlock() external view returns (uint256);

    /**
     * @param relayManager An address of a Relay Manager.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @return info All the details of the given Relay Manager's registration. Throws if relay not found for `RelayHub`.
     */
    function getRelayInfo(address relayHub, address relayManager) external view returns (RelayInfo memory info);

    /**
     * @notice Read relay info of registered Relay Server from an on-chain storage.
     * @param relayHub The address of the `RelayHub` contract for which this action is performed.
     * @param maxCount The maximum amount of relays to be returned by this function.
     * @param oldestBlockNumber The latest block number in which a Relay Server may be registered.
     * @param oldestBlockTimestamp The latest block timestamp in which a Relay Server may be registered.
     * @return info The list of `RelayInfo`s of registered Relay Servers
     */
    function readRelayInfos(
        address relayHub,
        uint256 oldestBlockNumber,
        uint256 oldestBlockTimestamp,
        uint256 maxCount
    ) external view returns (
        RelayInfo[] memory info
    );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

pragma solidity >=0.6.0;

// SPDX-License-Identifier: MIT

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    /**
     * @return version The SemVer string of this Recipient's version.
     */
    function versionRecipient() external virtual view returns (string memory);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../arbitrum/ArbSys.sol";

/**
* As there is no way to run Arbitrum chain locally, tests currently need to run on simple hardhat node.
* If some behavior is needed from ArbSys, it has to be stubbed here.
 */
contract TestArbSys is ArbSys {

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external override view returns (uint){
        return block.number * 17;
    }

    function getStorageGasAvailable() external override view returns (uint256) {
        // we need some really large value as for gasleft but also one that does decrease on every call
        return gasleft() * 100;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../RelayHub.sol";

contract TestRelayHubForRegistrar {
    mapping(address => bool) public isStaked;

    function setRelayManagerStaked(address relayManager, bool _isStaked) external {
        isStaked[relayManager] = _isStaked;
    }

    function verifyCanRegister(address relayManager) external view {
        require(isStaked[relayManager], "verifyCanRegister: cannot");
    }

    function verifyRelayManagerStaked(address relayManager) external view {
        require(isStaked[relayManager], "verifyRelayManagerStaked: is not");
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../RelayHub.sol";

contract TestRelayHub is RelayHub {
    using SafeMath for uint256;

    constructor(
        IStakeManager _stakeManager,
        address _penalizer,
        address _batchGateway,
        address _relayRegistrar,
        RelayHubConfig memory _config
    // solhint-disable-next-line no-empty-blocks
    ) RelayHub(_stakeManager, _penalizer, _batchGateway, _relayRegistrar, _config) {}

    /// Allow depositing for non-paymaster addresses for Gas Calculations tests
    function depositFor(address target) public override payable {
        uint256 amount = msg.value;
        balances[target] = balances[target].add(amount);
        emit Deposited(target, msg.sender, amount);
    }
}

pragma solidity ^0.8.6;

// solhint-disable not-rely-on-time
//SPDX-License-Identifier: GPL-3.0-only

/* solhint-disable no-inline-assembly */

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./MinLibBytes.sol";
import "../interfaces/IRelayHub.sol";
import "../interfaces/IRelayRegistrar.sol";

/**
 * @title The RelayRegistrar Implementation
 * @notice Keeps a list of registered relayers.
 *
 * @notice Provides view functions to read the list of registered relayers and filters out invalid ones.
 *
 * @notice Protects the list from spamming entries: only staked relayers are added.
 */
contract RelayRegistrar is IRelayRegistrar, ERC165 {
    using MinLibBytes for bytes;

    /// @notice Mapping from `RelayHub` address to a mapping from a Relay Manager address to its registration details.
    mapping(address => mapping(address => RelayInfo)) internal values;

    /// @notice Mapping from `RelayHub` address to an array of Relay Managers that are registered on that `RelayHub`.
    mapping(address => address[]) internal indexedValues;

    uint256 private immutable creationBlock;

    constructor() {
        creationBlock = block.number;
    }

    /// @inheritdoc IRelayRegistrar
    function getCreationBlock() external override view returns (uint256){
        return creationBlock;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IRelayRegistrar).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IRelayRegistrar
    function registerRelayServer(
        address relayHub,
        uint80 baseRelayFee,
        uint16 pctRelayFee,
        bytes32[3] calldata url
    ) external override {
        address relayManager = msg.sender;
        IRelayHub(relayHub).verifyCanRegister(relayManager);
        emit RelayServerRegistered(relayManager, baseRelayFee, pctRelayFee, url);
        storeRelayServerRegistration(relayHub, relayManager, baseRelayFee, pctRelayFee, url);
    }

    function addItem(address relayHub, address relayManager) internal returns (RelayInfo storage) {
        RelayInfo storage storageInfo = values[relayHub][relayManager];
        if (storageInfo.lastSeenBlockNumber == 0) {
            indexedValues[relayHub].push(relayManager);
        }
        return storageInfo;
    }

    function storeRelayServerRegistration(
        address relayHub,
        address relayManager,
        uint80 baseRelayFee,
        uint16 pctRelayFee,
        bytes32[3] calldata url
    ) internal {
        RelayInfo storage storageInfo = addItem(relayHub, relayManager);
        if (storageInfo.firstSeenBlockNumber == 0) {
            storageInfo.firstSeenBlockNumber = uint32(block.number);
            storageInfo.firstSeenTimestamp = uint40(block.timestamp);
        }
        storageInfo.lastSeenBlockNumber = uint32(block.number);
        storageInfo.lastSeenTimestamp = uint40(block.timestamp);
        storageInfo.baseRelayFee = baseRelayFee;
        storageInfo.pctRelayFee = pctRelayFee;
        storageInfo.relayManager = relayManager;
        storageInfo.urlParts = url;
    }

    /// @inheritdoc IRelayRegistrar
    function getRelayInfo(address relayHub, address relayManager) public view override returns (RelayInfo memory) {
        RelayInfo memory info = values[relayHub][relayManager];
        require(info.lastSeenBlockNumber != 0, "relayManager not found");
        return info;
    }

    /// @inheritdoc IRelayRegistrar
    function readRelayInfos(
        address relayHub,
        uint256 oldestBlockNumber,
        uint256 oldestBlockTimestamp,
        uint256 maxCount
    )
    public
    view
    override
    returns (
        RelayInfo[] memory info
    ) {
        address[] storage items = indexedValues[relayHub];
        uint256 filled = 0;
        info = new RelayInfo[](items.length < maxCount ? items.length : maxCount);
        for (uint256 i = 0; i < items.length; i++) {
            address relayManager = items[i];
            RelayInfo memory relayInfo = getRelayInfo(relayHub, relayManager);
            if (
                relayInfo.lastSeenBlockNumber < oldestBlockNumber ||
                relayInfo.lastSeenTimestamp < oldestBlockTimestamp
            ) {
                continue;
            }
            // solhint-disable-next-line no-empty-blocks
            try IRelayHub(relayHub).verifyRelayManagerStaked(relayManager) {
            } catch (bytes memory /*lowLevelData*/) {
                continue;
            }
            info[filled++] = relayInfo;
            if (filled >= maxCount)
                break;
        }
        assembly { mstore(info, filled) }
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

/* solhint-disable avoid-tx-origin */
// SPDX-License-Identifier: GPL-3.0-only

import "../interfaces/IRelayHub.sol";

contract TestRelayWorkerContract {

    function relayCall(
        IRelayHub hub,
        uint256 maxAcceptanceBudget,
        GsnTypes.RelayRequest memory relayRequest,
        bytes memory signature)
    public
    {
        hub.relayCall(maxAcceptanceBudget, relayRequest, signature, "");
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// solhint-disable not-rely-on-time
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStakeManager.sol";
import "./interfaces/IRelayHub.sol";

/**
 * @title The StakeManager implementation
 * @notice An IStakeManager instance that accepts stakes in any ERC-20 token.
 *
 * @notice Single StakeInfo of a single RelayManager can only have one token address assigned to it.
 *
 * @notice It cannot be changed after the first time 'stakeForRelayManager' is called as it is equivalent to withdrawal.
 */
contract StakeManager is IStakeManager, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public override versionSM = "3.0.0-alpha.3+opengsn.stakemanager.istakemanager";
    uint256 internal immutable maxUnstakeDelay;

    address internal burnAddress;
    uint256 internal immutable creationBlock;

    /// maps relay managers to their stakes
    mapping(address => StakeInfo) public stakes;

    /// @inheritdoc IStakeManager
    function getStakeInfo(address relayManager) external override view returns (StakeInfo memory stakeInfo, bool isSenderAuthorizedHub) {
        bool isHubAuthorized = authorizedHubs[relayManager][msg.sender].removalTime == type(uint256).max;
        return (stakes[relayManager], isHubAuthorized);
    }

    /// @inheritdoc IStakeManager
    function setBurnAddress(address _burnAddress) public override onlyOwner {
        burnAddress = _burnAddress;
        emit BurnAddressSet(burnAddress);
    }

    /// @inheritdoc IStakeManager
    function getBurnAddress() external override view returns (address) {
        return burnAddress;
    }

    /// @inheritdoc IStakeManager
    function getMaxUnstakeDelay() external override view returns (uint256) {
        return maxUnstakeDelay;
    }

    /// maps relay managers to a map of addressed of their authorized hubs to the information on that hub
    mapping(address => mapping(address => RelayHubInfo)) public authorizedHubs;

    constructor(
        uint256 _maxUnstakeDelay,
        address _burnAddress
    ) {
        require(_burnAddress != address(0), "transfers to address(0) may fail");
        setBurnAddress(_burnAddress);
        creationBlock = block.number;
        maxUnstakeDelay = _maxUnstakeDelay;
    }

    /// @inheritdoc IStakeManager
    function getCreationBlock() external override view returns (uint256){
        return creationBlock;
    }

    /// @inheritdoc IStakeManager
    function setRelayManagerOwner(address owner) external override {
        require(owner != address(0), "invalid owner");
        require(stakes[msg.sender].owner == address(0), "already owned");
        stakes[msg.sender].owner = owner;
        emit OwnerSet(msg.sender, owner);
    }

    /// @inheritdoc IStakeManager
    function stakeForRelayManager(IERC20 token, address relayManager, uint256 unstakeDelay, uint256 amount) external override relayOwnerOnly(relayManager) {
        require(unstakeDelay >= stakes[relayManager].unstakeDelay, "unstakeDelay cannot be decreased");
        require(unstakeDelay <= maxUnstakeDelay, "unstakeDelay too big");
        require(token != IERC20(address(0)), "must specify stake token address");
        require(
            stakes[relayManager].token == IERC20(address(0)) ||
            stakes[relayManager].token == token,
            "stake token address is incorrect");
        token.safeTransferFrom(msg.sender, address(this), amount);
        stakes[relayManager].token = token;
        stakes[relayManager].stake += amount;
        stakes[relayManager].unstakeDelay = unstakeDelay;
        emit StakeAdded(relayManager, stakes[relayManager].owner, stakes[relayManager].token, stakes[relayManager].stake, stakes[relayManager].unstakeDelay);
    }

    /// @inheritdoc IStakeManager
    function unlockStake(address relayManager) external override relayOwnerOnly(relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.withdrawTime == 0, "already pending");
        info.withdrawTime = block.timestamp.add(info.unstakeDelay);
        emit StakeUnlocked(relayManager, msg.sender, info.withdrawTime);
    }

    /// @inheritdoc IStakeManager
    function withdrawStake(address relayManager) external override relayOwnerOnly(relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.withdrawTime > 0, "Withdrawal is not scheduled");
        require(info.withdrawTime <= block.timestamp, "Withdrawal is not due");
        uint256 amount = info.stake;
        info.stake = 0;
        info.withdrawTime = 0;
        info.token.safeTransfer(msg.sender, amount);
        emit StakeWithdrawn(relayManager, msg.sender, info.token, amount);
    }

    /// @notice Prevents any address other than a registered Relay Owner from calling this method.
    modifier relayOwnerOnly (address relayManager) {
        StakeInfo storage info = stakes[relayManager];
        require(info.owner == msg.sender, "not owner");
        _;
    }

    /// @notice Prevents any address other than a registered Relay Manager from calling this method.
    modifier managerOnly () {
        StakeInfo storage info = stakes[msg.sender];
        require(info.owner != address(0), "not manager");
        _;
    }

    /// @inheritdoc IStakeManager
    function authorizeHubByOwner(address relayManager, address relayHub) external relayOwnerOnly(relayManager) override {
        _authorizeHub(relayManager, relayHub);
    }

    /// @inheritdoc IStakeManager
    function authorizeHubByManager(address relayHub) external managerOnly override {
        _authorizeHub(msg.sender, relayHub);
    }

    function _authorizeHub(address relayManager, address relayHub) internal {
        authorizedHubs[relayManager][relayHub].removalTime = type(uint256).max;
        emit HubAuthorized(relayManager, relayHub);
    }

    /// @inheritdoc IStakeManager
    function unauthorizeHubByOwner(address relayManager, address relayHub) external override relayOwnerOnly(relayManager) {
        _unauthorizeHub(relayManager, relayHub);
    }

    /// @inheritdoc IStakeManager
    function unauthorizeHubByManager(address relayHub) external override managerOnly {
        _unauthorizeHub(msg.sender, relayHub);
    }

    function _unauthorizeHub(address relayManager, address relayHub) internal {
        RelayHubInfo storage hubInfo = authorizedHubs[relayManager][relayHub];
        require(hubInfo.removalTime == type(uint256).max, "hub not authorized");
        hubInfo.removalTime = block.timestamp.add(stakes[relayManager].unstakeDelay);
        emit HubUnauthorized(relayManager, relayHub, hubInfo.removalTime);
    }

    /// @inheritdoc IStakeManager
    function penalizeRelayManager(address relayManager, address beneficiary, uint256 amount) external override {
        uint256 removalTime = authorizedHubs[relayManager][msg.sender].removalTime;
        require(removalTime != 0, "hub not authorized");
        require(removalTime > block.timestamp, "hub authorization expired");

        // Half of the stake will be burned (sent to address 0)
        require(stakes[relayManager].stake >= amount, "penalty exceeds stake");
        stakes[relayManager].stake = SafeMath.sub(stakes[relayManager].stake, amount);

        uint256 toBurn = SafeMath.div(amount, 2);
        uint256 reward = SafeMath.sub(amount, toBurn);

        // Stake ERC-20 token is burned and transferred
        stakes[relayManager].token.safeTransfer(burnAddress, toBurn);
        stakes[relayManager].token.safeTransfer(beneficiary, reward);
        emit StakePenalized(relayManager, beneficiary, stakes[relayManager].token, reward);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC20Token.sol";

contract WrappedEthToken is ERC20, IERC20Token {

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Wrapped Eth", "wEth") {
    }

    function deposit() public override payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint amount) public override {
        _burn(msg.sender, amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = msg.sender.call{value:amount}("");
        require(success, "transfer failed");
    }
}

pragma solidity >=0.7.6;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @notice Extended ERC-20 token interface used internally in OpenGSN modules.
 * Renamed to avoid conflict with OZ namespace. Includes IERC20, ERC20Metadata.
 * added semi-standard "wrapped eth" access methods deposit() and "withdraw()"
 */
interface IERC20Token is IERC20, IERC20Metadata {

    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// minimal "wrapped eth" implementation.
contract TestWEth is ERC20 {

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Test Wrapped Eth", "twEth") {
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        _burn(msg.sender, amount);
        (bool success,) = msg.sender.call{value:amount}("");
        require(success, "twEth: withdraw failed");
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {

    constructor() ERC20("Test Token", "TOK") {
        mint(100 ether);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

pragma solidity >=0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./utils/GsnTypes.sol";
import "./interfaces/IPaymaster.sol";
import "./interfaces/IRelayHub.sol";
import "./utils/GsnEip712Library.sol";
import "./forwarder/IForwarder.sol";

/**
 * @notice An abstract base class to be inherited by a concrete Paymaster.
 * A subclass must implement:
 *  - preRelayedCall
 *  - postRelayedCall
 */
abstract contract BasePaymaster is IPaymaster, Ownable, ERC165 {
    using ERC165Checker for address;

    IRelayHub internal relayHub;
    address private _trustedForwarder;

    /// @inheritdoc IPaymaster
    function getRelayHub() public override view returns (address) {
        return address(relayHub);
    }

    //overhead of forwarder verify+signature, plus hub overhead.
    uint256 constant public FORWARDER_HUB_OVERHEAD = 50000;

    //These parameters are documented in IPaymaster.GasAndDataLimits
    uint256 constant public PRE_RELAYED_CALL_GAS_LIMIT = 100000;
    uint256 constant public POST_RELAYED_CALL_GAS_LIMIT = 110000;
    uint256 constant public PAYMASTER_ACCEPTANCE_BUDGET = PRE_RELAYED_CALL_GAS_LIMIT + FORWARDER_HUB_OVERHEAD;
    uint256 constant public CALLDATA_SIZE_LIMIT = 10500;

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IPaymaster).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IPaymaster
    function getGasAndDataLimits()
    public
    override
    virtual
    view
    returns (
        IPaymaster.GasAndDataLimits memory limits
    ) {
        return IPaymaster.GasAndDataLimits(
            PAYMASTER_ACCEPTANCE_BUDGET,
            PRE_RELAYED_CALL_GAS_LIMIT,
            POST_RELAYED_CALL_GAS_LIMIT,
            CALLDATA_SIZE_LIMIT
        );
    }

    // this method must be called from preRelayedCall to validate that the forwarder
    // is approved by the paymaster as well as by the recipient contract.
    function _verifyForwarder(GsnTypes.RelayRequest calldata relayRequest)
    public
    view
    {
        require(address(_trustedForwarder) == relayRequest.relayData.forwarder, "Forwarder is not trusted");
        GsnEip712Library.verifyForwarderTrusted(relayRequest);
    }

    /**
     * @notice Modifier to be used by recipients as access control protection for `preRelayedCall` & `postRelayedCall`
     */
    modifier relayHubOnly() {
        require(msg.sender == getRelayHub(), "can only be called by RelayHub");
        _;
    }

    /**
     * @notice The owner of the Paymaster can change the instance of the RelayHub this Paymaster works with.
     * :warning: **Warning** :warning: The deposit on the previous RelayHub must be withdrawn first.
     */
    function setRelayHub(IRelayHub hub) public onlyOwner {
        require(address(hub).supportsInterface(type(IRelayHub).interfaceId), "target is not a valid IRelayHub");
        relayHub = hub;
    }

    /**
     * @notice The owner of the Paymaster can change the instance of the Forwarder this Paymaster works with.
     * @notice the Recipients must trust this Forwarder as well in order for the configuration to remain functional.
     */
    function setTrustedForwarder(address forwarder) public virtual onlyOwner {
        require(forwarder.supportsInterface(type(IForwarder).interfaceId), "target is not a valid IForwarder");
        _trustedForwarder = forwarder;
    }

    function getTrustedForwarder() public virtual view override returns (address){
        return _trustedForwarder;
    }

    /**
     * @notice Any native Ether transferred into the paymaster is transferred as a deposit to the RelayHub.
     * This way, we don't need to understand the RelayHub API in order to replenish the paymaster.
     */
    receive() external virtual payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    /**
     * @notice Withdraw deposit from the RelayHub.
     * @param amount The amount to be subtracted from the sender.
     * @param target The target to which the amount will be transferred.
     */
    function withdrawRelayHubDepositTo(uint256 amount, address payable target) public onlyOwner {
        relayHub.withdraw(amount, target);
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../forwarder/IForwarder.sol";
import "../BasePaymaster.sol";

contract TestPaymasterEverythingAccepted is BasePaymaster {

    function versionPaymaster() external view override virtual returns (string memory){
        return "3.0.0-alpha.3+opengsn.test-pea.ipaymaster";
    }

    event SampleRecipientPreCall();
    event SampleRecipientPostCall(bool success, uint256 actualCharge);

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    virtual
    returns (bytes memory, bool) {
        (signature);
        _verifyForwarder(relayRequest);
        (approvalData, maxPossibleGas);
        emit SampleRecipientPreCall();
        return ("no revert here",false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    virtual
    {
        (context, gasUseWithoutPost, relayData);
        emit SampleRecipientPostCall(success, gasUseWithoutPost);
    }

    function deposit() public payable {
        require(address(relayHub) != address(0), "relay hub address not set");
        relayHub.depositFor{value:msg.value}(address(this));
    }

    function withdrawAll(address payable destination) public {
        uint256 amount = relayHub.balanceOf(address(this));
        withdrawRelayHubDepositTo(amount, destination);
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterVariableGasLimits is TestPaymasterEverythingAccepted {

    string public override versionPaymaster = "3.0.0-alpha.3+opengsn.test-vgl.ipaymaster";

    event SampleRecipientPreCallWithValues(
        uint256 gasleft,
        uint256 maxPossibleGas
    );

    event SampleRecipientPostCallWithValues(
        uint256 gasleft,
        uint256 gasUseWithoutPost
    );

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        (signature, approvalData);
        _verifyForwarder(relayRequest);
        emit SampleRecipientPreCallWithValues(
            gasleft(), maxPossibleGas);
        return ("", false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        emit SampleRecipientPostCallWithValues(gasleft(), gasUseWithoutPost);
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterStoreContext is TestPaymasterEverythingAccepted {

    event SampleRecipientPreCallWithValues(
        address relay,
        address from,
        bytes encodedFunction,
        uint256 baseRelayFee,
        uint256 pctRelayFee,
        uint256 maxFeePerGas,
        uint256 gasLimit,
        bytes approvalData,
        uint256 maxPossibleGas
    );

    event SampleRecipientPostCallWithValues(
        string context
    );

    /**
     * This demonstrates how preRelayedCall can return 'context' data for reuse in postRelayedCall.
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    returns (bytes memory, bool) {
        (signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);

        emit SampleRecipientPreCallWithValues(
            relayRequest.relayData.relayWorker,
            relayRequest.request.from,
            relayRequest.request.data,
            relayRequest.relayData.baseRelayFee,
            relayRequest.relayData.pctRelayFee,
            relayRequest.relayData.maxFeePerGas,
            relayRequest.request.gas,
            approvalData,
            maxPossibleGas);
        return ("context passed from preRelayedCall to postRelayedCall",false);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        emit SampleRecipientPostCallWithValues(string(context));
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterPreconfiguredApproval is TestPaymasterEverythingAccepted {

    bytes public expectedApprovalData;

    function setExpectedApprovalData(bytes memory val) public {
        expectedApprovalData = val;
    }

    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    view
    override
    returns (bytes memory, bool) {
        (relayRequest, signature, approvalData, maxPossibleGas);
        _verifyForwarder(relayRequest);
        require(keccak256(expectedApprovalData) == keccak256(approvalData),
            string(abi.encodePacked(
                "test: unexpected approvalData: '", approvalData, "' instead of '", expectedApprovalData, "'")));
        return ("",false);
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterOwnerSignature is TestPaymasterEverythingAccepted {
    using ECDSA for bytes32;

    /**
     * This demonstrates how dapps can provide an off-chain signatures to relayed transactions.
     */
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    view
    override
    returns (bytes memory, bool) {
        (signature, maxPossibleGas);
        _verifyForwarder(relayRequest);

        address signer =
            keccak256(abi.encodePacked("I approve", relayRequest.request.from))
            .toEthSignedMessageHash()
            .recover(approvalData);
        require(signer == owner(), "test: not approved");
        return ("",false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./utils/RLPReader.sol";
import "./utils/GsnUtils.sol";
import "./interfaces/IRelayHub.sol";
import "./interfaces/IPenalizer.sol";

/**
 * @title The Penalizer Implementation
 *
 * @notice This Penalizer supports parsing Legacy, Type 1 and Type 2 raw RLP Encoded transactions.
 */
contract Penalizer is IPenalizer {
    using ECDSA for bytes32;

    string public override versionPenalizer = "3.0.0-alpha.3+opengsn.penalizer.ipenalizer";

    uint256 internal immutable penalizeBlockDelay;
    uint256 internal immutable penalizeBlockExpiration;

    constructor(
        uint256 _penalizeBlockDelay,
        uint256 _penalizeBlockExpiration
    ) {
        penalizeBlockDelay = _penalizeBlockDelay;
        penalizeBlockExpiration = _penalizeBlockExpiration;
    }

    /// @inheritdoc IPenalizer
    function getPenalizeBlockDelay() external override view returns (uint256) {
        return penalizeBlockDelay;
    }

    /// @inheritdoc IPenalizer
    function getPenalizeBlockExpiration() external override view returns (uint256) {
        return penalizeBlockExpiration;
    }

    function isLegacyTransaction(bytes calldata rawTransaction) internal pure returns (bool) {
        uint8 transactionTypeByte = uint8(rawTransaction[0]);
        return (transactionTypeByte >= 0xc0 && transactionTypeByte <= 0xfe);
    }

    function isTransactionType1(bytes calldata rawTransaction) internal pure returns (bool) {
        return (uint8(rawTransaction[0]) == 1);
    }

    function isTransactionType2(bytes calldata rawTransaction) internal pure returns (bool) {
        return (uint8(rawTransaction[0]) == 2);
    }

    /// @return `true` if raw transaction is of types Legacy, 1 or 2. `false` otherwise.
    function isTransactionTypeValid(bytes calldata rawTransaction) public pure returns(bool) {
        return isLegacyTransaction(rawTransaction) || isTransactionType1(rawTransaction) || isTransactionType2(rawTransaction);
    }

    /// @return transaction The details that the `Penalizer` needs to decide if the transaction is penalizable.
    function decodeTransaction(bytes calldata rawTransaction) public pure returns (Transaction memory transaction) {
        if (isTransactionType1(rawTransaction)) {
            (transaction.nonce,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            transaction.data) = RLPReader.decodeTransactionType1(rawTransaction);
        } else if (isTransactionType2(rawTransaction)) {
            (transaction.nonce,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            transaction.data) = RLPReader.decodeTransactionType2(rawTransaction);
        } else {
            (transaction.nonce,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            transaction.data) = RLPReader.decodeLegacyTransaction(rawTransaction);
        }
        return transaction;
    }

    mapping(bytes32 => uint256) public commits;

    /// @inheritdoc IPenalizer
    function commit(bytes32 commitHash) external override {
        uint256 readyBlockNumber = block.number + penalizeBlockDelay;
        commits[commitHash] = readyBlockNumber;
        emit CommitAdded(msg.sender, commitHash, readyBlockNumber);
    }

    /// Modifier that verifies there was a `commit` operation before this call that has not expired yet.
    modifier commitRevealOnly() {
        bytes32 commitHash = keccak256(abi.encodePacked(keccak256(msg.data), msg.sender));
        uint256 readyBlockNumber = commits[commitHash];
        delete commits[commitHash];
        // msg.sender can only be fake during off-chain view call, allowing Penalizer process to check transactions
        if(msg.sender != address(type(uint160).max)) {
            require(readyBlockNumber != 0, "no commit");
            require(readyBlockNumber < block.number, "reveal penalize too soon");
            require(readyBlockNumber + penalizeBlockExpiration > block.number, "reveal penalize too late");
        }
        _;
    }

    /// @inheritdoc IPenalizer
    function penalizeRepeatedNonce(
        bytes calldata unsignedTx1,
        bytes calldata signature1,
        bytes calldata unsignedTx2,
        bytes calldata signature2,
        IRelayHub hub,
        uint256 randomValue
    )
    public
    override
    commitRevealOnly {
        (randomValue);
        _penalizeRepeatedNonce(unsignedTx1, signature1, unsignedTx2, signature2, hub);
    }

    function _penalizeRepeatedNonce(
        bytes calldata unsignedTx1,
        bytes calldata signature1,
        bytes calldata unsignedTx2,
        bytes calldata signature2,
        IRelayHub hub
    )
    private
    {
        address addr1 = keccak256(unsignedTx1).recover(signature1);
        address addr2 = keccak256(unsignedTx2).recover(signature2);

        require(addr1 == addr2, "Different signer");
        require(addr1 != address(0), "ecrecover failed");

        Transaction memory decodedTx1 = decodeTransaction(unsignedTx1);
        Transaction memory decodedTx2 = decodeTransaction(unsignedTx2);

        // checking that the same nonce is used in both transaction, with both signed by the same address
        // and the actual data is different
        // note: we compare the hash of the tx to save gas over iterating both byte arrays
        require(decodedTx1.nonce == decodedTx2.nonce, "Different nonce");

        bytes memory dataToCheck1 =
        abi.encodePacked(decodedTx1.data, decodedTx1.gasLimit, decodedTx1.to, decodedTx1.value);

        bytes memory dataToCheck2 =
        abi.encodePacked(decodedTx2.data, decodedTx2.gasLimit, decodedTx2.to, decodedTx2.value);

        require(keccak256(dataToCheck1) != keccak256(dataToCheck2), "tx is equal");

        penalize(addr1, hub);
    }

    /// @inheritdoc IPenalizer
    function penalizeIllegalTransaction(
        bytes calldata unsignedTx,
        bytes calldata signature,
        IRelayHub hub,
        uint256 randomValue
    )
    public
    override
    commitRevealOnly {
        (randomValue);
        _penalizeIllegalTransaction(unsignedTx, signature, hub);
    }

    function _penalizeIllegalTransaction(
        bytes calldata unsignedTx,
        bytes calldata signature,
        IRelayHub hub
    )
    private
    {
        if (isTransactionTypeValid(unsignedTx)) {
            Transaction memory decodedTx = decodeTransaction(unsignedTx);
            if (decodedTx.to == address(hub)) {
                bytes4 selector = GsnUtils.getMethodSig(decodedTx.data);
                bool isWrongMethodCall = selector != IRelayHub.relayCall.selector;
                require(
                    isWrongMethodCall,
                    "Legal relay transaction");
            }
        }
        address relay = keccak256(unsignedTx).recover(signature);
        require(relay != address(0), "ecrecover failed");
        penalize(relay, hub);
    }

    function penalize(address relayWorker, IRelayHub hub) private {
        hub.penalize(relayWorker, payable(msg.sender));
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier:APACHE-2.0
/*
* Taken from https://github.com/hamdiallam/Solidity-RLP
*/
/* solhint-disable */

library RLPReader {

    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    using RLPReader for bytes;
    using RLPReader for uint;
    using RLPReader for RLPReader.RLPItem;

    // helper function to decode rlp encoded legacy ethereum transaction
    /*
    * @param rawTransaction RLP encoded legacy ethereum transaction rlp([nonce, gasPrice, gasLimit, to, value, data]))
    * @return tuple (nonce,gasLimit,to,value,data)
    */

    function decodeLegacyTransaction(bytes calldata rawTransaction) internal pure returns (uint, uint, address, uint, bytes memory){
        RLPReader.RLPItem[] memory values = rawTransaction.toRlpItem().toList(); // must convert to an rlpItem first!
        return (values[0].toUint(), values[2].toUint(), values[3].toAddress(), values[4].toUint(), values[5].toBytes());
    }

    /*
    * @param rawTransaction format: 0x01 || rlp([chainId, nonce, gasPrice, gasLimit, to, value, data, access_list]))
    * @return tuple (nonce,gasLimit,to,value,data)
    */
    function decodeTransactionType1(bytes calldata rawTransaction) internal pure returns (uint, uint, address, uint, bytes memory){
        bytes memory payload = rawTransaction[1:rawTransaction.length];
        RLPReader.RLPItem[] memory values = payload.toRlpItem().toList(); // must convert to an rlpItem first!
        return (values[1].toUint(), values[3].toUint(), values[4].toAddress(), values[5].toUint(), values[6].toBytes());
    }

    /*
    * @param rawTransaction format: 0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list]))
    * @return tuple (nonce,gasLimit,to,value,data)
    */
    function decodeTransactionType2(bytes calldata rawTransaction) internal pure returns (uint, uint, address, uint, bytes memory){
        bytes memory payload = rawTransaction[1:rawTransaction.length];
        RLPReader.RLPItem[] memory values = payload.toRlpItem().toList(); // must convert to an rlpItem first!
        return (values[1].toUint(), values[4].toUint(), values[5].toAddress(), values[6].toUint(), values[7].toBytes());
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0)
            return RLPItem(0, 0);
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }
        return RLPItem(item.length, memPtr);
    }
    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item), "isList failed");
        uint items = numItems(item);
        result = new RLPItem[](items);
        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }
    /*
    * Helpers
    */
    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }
    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr);
            // skip over an item
            count++;
        }
        return count;
    }
    // @return entire rlp item byte length
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START)
            return 1;
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // number of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
            /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }
        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        }
        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }
    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }
    /** RLPItem conversions into data types **/
    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }
        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }
        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");
        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;
        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }
        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        // data length
        bytes memory result = new bytes(len);
        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }
        copy(item.memPtr + offset, destPtr, len);
        return result;
    }
    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) internal pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

pragma solidity >=0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./IRelayHub.sol";

/**
 * @title The Penalizer Interface
 * @notice In some cases the behavior of a Relay Server may be found to be illegal.
 * It is the responsibility of a `Penalizer` contract to judge whether there was a penalizable event.
 *
 * @notice In case there was, the `Penalizer` will direct the `RelayHub` to slash the stake of the faulty Relay Server.
 */
interface IPenalizer {

    /// @notice Emitted once the reporter submits the first step in the commit-reveal process.
    event CommitAdded(address indexed sender, bytes32 indexed commitHash, uint256 readyBlockNumber);

    struct Transaction {
        uint256 nonce;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
    }

    /**
     * @notice Called by the reporter as the first step in the commit-reveal process.
     * Any sender can call it to make sure no-one can front-run it to claim this penalization.
     * @param commitHash The hash of the report of a penalizable behaviour the reporter wants to reveal.
     * Calculated as `commit(keccak(encodedPenalizeFunction))`.
     */
    function commit(bytes32 commitHash) external;

    /**
     * @notice Called by the reporter as the second step in the commit-reveal process.
     * If a Relay Worker attacked the system by signing multiple transactions with same nonce so only one is accepted,
     * anyone can grab both transactions from the blockchain and submit them here.
     * Check whether `unsignedTx1` != `unsignedTx2`, that both are signed by the same address,
     * and that `unsignedTx1.nonce` == `unsignedTx2.nonce`.
     * If all conditions are met, relay is considered an "offending relay".
     * The offending relay will be unregistered immediately, its stake will be forfeited and given
     * to the address who reported it (the `msg.sender`), thus incentivizing anyone to report offending relays.
     */
    function penalizeRepeatedNonce(
        bytes calldata unsignedTx1,
        bytes calldata signature1,
        bytes calldata unsignedTx2,
        bytes calldata signature2,
        IRelayHub hub,
        uint256 randomValue
    ) external;

    /**
     * @notice Called by the reporter as the second step in the commit-reveal process.
     * The Relay Workers are not allowed to make calls other than to the `relayCall` method.
     */
    function penalizeIllegalTransaction(
        bytes calldata unsignedTx,
        bytes calldata signature,
        IRelayHub hub,
        uint256 randomValue
    ) external;

    /// @return a SemVer-compliant version of the `Penalizer` contract.
    function versionPenalizer() external view returns (string memory);

    /// @return The minimum delay between commit and reveal steps.
    function getPenalizeBlockDelay() external view returns (uint256);

    /// @return The maximum delay between commit and reveal steps.
    function getPenalizeBlockExpiration() external view returns (uint256);
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../utils/GsnTypes.sol";
import "../utils/GsnEip712Library.sol";
import "../utils/GsnUtils.sol";

contract TestUtil {

    function libRelayRequestName() public pure returns (string memory) {
        return GsnEip712Library.RELAY_REQUEST_NAME;
    }

    function libRelayRequestType() public pure returns (string memory) {
        return string(GsnEip712Library.RELAY_REQUEST_TYPE);
    }

    function libRelayRequestTypeHash() public pure returns (bytes32) {
        return GsnEip712Library.RELAY_REQUEST_TYPEHASH;
    }

    function libRelayRequestSuffix() public pure returns (string memory) {
        return GsnEip712Library.RELAY_REQUEST_SUFFIX;
    }

    //helpers for test to call the library funcs:
    function callForwarderVerify(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    )
    external
    view {
        GsnEip712Library.verify(relayRequest, signature);
    }

    function callForwarderVerifyAndCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature
    )
    external
    returns (
        bool success,
        bytes memory ret
    ) {
        bool forwarderSuccess;
        (forwarderSuccess, success, ret) = GsnEip712Library.execute(relayRequest, signature);
        if ( !forwarderSuccess) {
            GsnUtils.revertWithData(ret);
        }
        emit Called(success, success == false ? ret : bytes(""));
    }

    event Called(bool success, bytes error);

    function splitRequest(
        GsnTypes.RelayRequest calldata relayRequest
    )
    external
    pure
    returns (
        bytes32 typeHash,
        bytes memory suffixData
    ) {
        (suffixData) = GsnEip712Library.splitRequest(relayRequest);
        typeHash = GsnEip712Library.RELAY_REQUEST_TYPEHASH;
    }

    function libDomainSeparator(address forwarder) public view returns (bytes32) {
        return GsnEip712Library.domainSeparator(forwarder);
    }

    function libGetChainID() public view returns (uint256) {
        return GsnEip712Library.getChainID();
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// solhint-disable not-rely-on-time
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IForwarder.sol";

/**
 * @title The Forwarder Implementation
 * @notice This implementation of the `IForwarder` interface uses ERC-712 signatures and stored nonces for verification.
 */
contract Forwarder is IForwarder, ERC165 {
    using ECDSA for bytes32;

    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntilTime";

    string public constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    mapping(bytes32 => bool) public typeHashes;
    mapping(bytes32 => bool) public domains;

    // Nonces of senders, used to prevent replay attacks
    mapping(address => uint256) private nonces;

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @inheritdoc IForwarder
    function getNonce(address from)
    public view override
    returns (uint256) {
        return nonces[from];
    }

    constructor() {
        string memory requestType = string(abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")"));
        registerRequestTypeInternal(requestType);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IForwarder).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IForwarder
    function verify(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    external override view {
        _verifyNonce(req);
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
    }

    /// @inheritdoc IForwarder
    function execute(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig
    )
    external payable
    override
    returns (bool success, bytes memory ret) {
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
        _verifyAndUpdateNonce(req);

        require(req.validUntilTime == 0 || req.validUntilTime > block.timestamp, "FWD: request expired");

        uint256 gasForTransfer = 0;
        if ( req.value != 0 ) {
            gasForTransfer = 40000; //buffer in case we need to move eth after the transaction.
        }
        bytes memory callData = abi.encodePacked(req.data, req.from);
        require(gasleft()*63/64 >= req.gas + gasForTransfer, "FWD: insufficient gas");
        // solhint-disable-next-line avoid-low-level-calls
        (success,ret) = req.to.call{gas : req.gas, value : req.value}(callData);
        if ( req.value != 0 && address(this).balance>0 ) {
            // can't fail: req.from signed (off-chain) the request, so it must be an EOA...
            payable(req.from).transfer(address(this).balance);
        }

        return (success,ret);
    }

    function _verifyNonce(ForwardRequest calldata req) internal view {
        require(nonces[req.from] == req.nonce, "FWD: nonce mismatch");
    }

    function _verifyAndUpdateNonce(ForwardRequest calldata req) internal {
        require(nonces[req.from]++ == req.nonce, "FWD: nonce mismatch");
    }

    /// @inheritdoc IForwarder
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external override {

        for (uint256 i = 0; i < bytes(typeName).length; i++) {
            bytes1 c = bytes(typeName)[i];
            require(c != "(" && c != ")", "FWD: invalid typename");
        }

        string memory requestType = string(abi.encodePacked(typeName, "(", GENERIC_PARAMS, ",", typeSuffix));
        registerRequestTypeInternal(requestType);
    }

    /// @inheritdoc IForwarder
    function registerDomainSeparator(string calldata name, string calldata version) external override {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly { chainId := chainid() }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this));

        bytes32 domainHash = keccak256(domainValue);

        domains[domainHash] = true;
        emit DomainRegistered(domainHash, domainValue);
    }

    function registerRequestTypeInternal(string memory requestType) internal {

        bytes32 requestTypehash = keccak256(bytes(requestType));
        typeHashes[requestTypehash] = true;
        emit RequestTypeRegistered(requestTypehash, requestType);
    }

    function _verifySig(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    internal
    virtual
    view
    {
        require(domains[domainSeparator], "FWD: unregistered domain sep.");
        require(typeHashes[requestTypeHash], "FWD: unregistered typehash");
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01", domainSeparator,
                keccak256(_getEncoded(req, requestTypeHash, suffixData))
            ));
        require(digest.recover(sig) == req.from, "FWD: signature mismatch");
    }

    /**
     * @notice Creates a byte array that is a valid ABI encoding of a request of a `RequestType` type. See `execute()`.
     */
    function _getEncoded(
        ForwardRequest calldata req,
        bytes32 requestTypeHash,
        bytes calldata suffixData
    )
    public
    pure
    returns (
        bytes memory
    ) {
        // we use encodePacked since we append suffixData as-is, not as dynamic param.
        // still, we must make sure all first params are encoded as abi.encode()
        // would encode them - as 256-bit-wide params.
        return abi.encodePacked(
            requestTypeHash,
            uint256(uint160(req.from)),
            uint256(uint160(req.to)),
            req.value,
            req.gas,
            req.nonce,
            keccak256(req.data),
            req.validUntilTime,
            suffixData
        );
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "./forwarder/Forwarder.sol";

contract GatewayForwarder is Forwarder {
    address public trustedRelayHub;

    function setTrustedRelayHub(address _trustedRelayHub) external {
        trustedRelayHub = _trustedRelayHub;
    }

    function _verifySig(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    internal
    override
    view
    {
        // trustedRelayHub can only be called from a verified Gateway where the signatures are actually checked
        // note that if signature field is set, it will be verified in this Forwarder anyway
        if (msg.sender != trustedRelayHub || sig.length != 0) {
            super._verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
        }
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../Forwarder.sol";

// helper class for testing the forwarder.
contract TestForwarder {
    function callExecute(Forwarder forwarder, Forwarder.ForwardRequest memory req,
        bytes32 domainSeparator, bytes32 requestTypeHash, bytes memory suffixData, bytes memory sig) public payable {
        (bool success, bytes memory error) = forwarder.execute{value:msg.value}(req, domainSeparator, requestTypeHash, suffixData, sig);
        emit Result(success, success ? "" : this.decodeErrorMessage(error));
    }

    event Result(bool success, string error);

    function decodeErrorMessage(bytes calldata ret) external pure returns (string memory message) {
        //decode evert string: assume it has a standard Error(string) signature: simply skip the (selector,offset,length) fields
        if ( ret.length>4+32+32 ) {
            return abi.decode(ret[4:], (string));
        }
        //unknown buffer. return as-is
        return string(ret);
    }

    function getChainId() public view returns (uint256 id){
        /* solhint-disable-next-line no-inline-assembly */
        assembly { id := chainid() }
    }
}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../utils/RelayHubValidator.sol";

contract TestRelayHubValidator {

    //for testing purposes, we must be called from a method with same param signature as RelayCall
    function dummyRelayCall(
        uint256, //paymasterMaxAcceptanceBudget,
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData
    ) external pure {
        RelayHubValidator.verifyTransactionPacking(relayRequest, signature, approvalData);
    }

    // helper method for verifyTransactionPacking
    function dynamicParamSize(bytes calldata buf) external pure returns (uint256) {
        return RelayHubValidator.dynamicParamSize(buf);
    }
}

pragma solidity >=0.6.9;

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

pragma solidity ^0.8.0;

/* solhint-disable avoid-tx-origin */
// SPDX-License-Identifier: GPL-3.0-only

import "../utils/GsnUtils.sol";
import "../ERC2771Recipient.sol";
import "./TestPaymasterConfigurableMisbehavior.sol";

contract TestRecipient is ERC2771Recipient {

    string public override versionRecipient = "3.0.0-alpha.3+opengsn.test.irelayrecipient";

    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
    }

    event Reverting(string message);

    function testRevert() public {
        require(address(this) == address(0), "always fail");
        emit Reverting("if you see this revert failed...");
    }

    address payable public paymaster;

    function setWithdrawDuringRelayedCall(address payable _paymaster) public {
        paymaster = _paymaster;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    event SampleRecipientEmitted(string message, address realSender, address msgSender, address origin, uint256 msgValue, uint256 gasLeft, uint256 balance);

    function emitMessage(string memory message) public payable returns (string memory) {
        uint256 gasLeft = gasleft();
        if (paymaster != address(0)) {
            withdrawAllBalance();
        }

        emit SampleRecipientEmitted(message, _msgSender(), msg.sender, tx.origin, msg.value, gasLeft, address(this).balance);
        return "emitMessage return value";
    }

    function withdrawAllBalance() public {
        TestPaymasterConfigurableMisbehavior(paymaster).withdrawAllBalance();
    }

    // solhint-disable-next-line no-empty-blocks
    function dontEmitMessage(string calldata message) public {}

    function emitMessageNoParams() public {
        emit SampleRecipientEmitted("Method with no parameters", _msgSender(), msg.sender, tx.origin, 0, gasleft(), address(this).balance);
    }

    //return (or revert) with a string in the given length
    function checkReturnValues(uint256 len, bool doRevert) public view returns (string memory) {
        (this);
        string memory mesg = "this is a long message that we are going to return a small part from. we don't use a loop since we want a fixed gas usage of the method itself.";
        require( bytes(mesg).length>=len, "invalid len: too large");

        /* solhint-disable no-inline-assembly */
        //cut the msg at that length
        assembly { mstore(mesg, len) }
        require(!doRevert, mesg);
        return mesg;
    }

    //function with no return value (also test revert with no msg.
    function checkNoReturnValues(bool doRevert) public view {
        (this);
        /* solhint-disable reason-string*/
        require(!doRevert);
    }

}

pragma solidity ^0.8.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "./TestPaymasterEverythingAccepted.sol";

contract TestPaymasterConfigurableMisbehavior is TestPaymasterEverythingAccepted {

    bool public withdrawDuringPostRelayedCall;
    bool public withdrawDuringPreRelayedCall;
    bool public returnInvalidErrorCode;
    bool public revertPostRelayCall;
    bool public outOfGasPre;
    bool public revertPreRelayCall;
    bool public revertPreRelayCallOnEvenBlocks;
    bool public greedyAcceptanceBudget;
    bool public expensiveGasLimits;

    function setWithdrawDuringPostRelayedCall(bool val) public {
        withdrawDuringPostRelayedCall = val;
    }
    function setWithdrawDuringPreRelayedCall(bool val) public {
        withdrawDuringPreRelayedCall = val;
    }
    function setReturnInvalidErrorCode(bool val) public {
        returnInvalidErrorCode = val;
    }
    function setRevertPostRelayCall(bool val) public {
        revertPostRelayCall = val;
    }
    function setRevertPreRelayCall(bool val) public {
        revertPreRelayCall = val;
    }
    function setRevertPreRelayCallOnEvenBlocks(bool val) public {
        revertPreRelayCallOnEvenBlocks = val;
    }
    function setOutOfGasPre(bool val) public {
        outOfGasPre = val;
    }

    function setGreedyAcceptanceBudget(bool val) public {
        greedyAcceptanceBudget = val;
    }
    function setExpensiveGasLimits(bool val) public {
        expensiveGasLimits = val;
    }

    // solhint-disable reason-string
    // contains comments that are checked in tests
    function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
    external
    override
    relayHubOnly
    returns (bytes memory, bool) {
        (signature, approvalData, maxPossibleGas);
        if (outOfGasPre) {
            uint256 i = 0;
            while (true) {
                i++;
            }
        }

        require(!returnInvalidErrorCode, "invalid code");

        if (withdrawDuringPreRelayedCall) {
            withdrawAllBalance();
        }
        if (revertPreRelayCall) {
            revert("You asked me to revert, remember?");
        }
        if (revertPreRelayCallOnEvenBlocks && block.number % 2 == 0) {
            revert("You asked me to revert on even blocks, remember?");
        }
        _verifyForwarder(relayRequest);
        return ("", trustRecipientRevert);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    relayHubOnly
    {
        (context, success, gasUseWithoutPost, relayData);
        if (withdrawDuringPostRelayedCall) {
            withdrawAllBalance();
        }
        if (revertPostRelayCall) {
            revert("You asked me to revert, remember?");
        }
    }

    /// leaving withdrawal public and unprotected
    function withdrawAllBalance() public returns (uint256) {
        require(address(relayHub) != address(0), "relay hub address not set");
        uint256 balance = relayHub.balanceOf(address(this));
        relayHub.withdraw(balance, payable(address(this)));
        return balance;
    }

    IPaymaster.GasAndDataLimits private limits = super.getGasAndDataLimits();

    function getGasAndDataLimits()
    public override view
    returns (IPaymaster.GasAndDataLimits memory) {

        if (expensiveGasLimits) {
            uint256 sum;
            //memory access is 700gas, so we waste ~50000
            for ( int i=0; i<100000; i+=700 ) {
                sum  = sum + limits.acceptanceBudget;
            }
        }
        if (greedyAcceptanceBudget) {
            return IPaymaster.GasAndDataLimits(limits.acceptanceBudget * 9, limits.preRelayedCallGasLimit, limits.postRelayedCallGasLimit,
            limits.calldataSizeLimit);
        }
        return limits;
    }

    bool private trustRecipientRevert;

    function setGasLimits(uint256 acceptanceBudget, uint256 preRelayedCallGasLimit, uint256 postRelayedCallGasLimit) public {
        limits = IPaymaster.GasAndDataLimits(
            acceptanceBudget,
            preRelayedCallGasLimit,
            postRelayedCallGasLimit,
            limits.calldataSizeLimit
        );
    }

    function setTrustRecipientRevert(bool on) public {
        trustRecipientRevert = on;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external override payable {}
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../ERC2771Recipient.sol";

contract TestForwarderTarget is ERC2771Recipient {

    string public override versionRecipient = "3.0.0-alpha.3+opengsn.test.recipient";

    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    event TestForwarderMessage(string message, bytes realMsgData, address realSender, address msgSender, address origin);

    function emitMessage(string memory message) public {

        // solhint-disable-next-line avoid-tx-origin
        emit TestForwarderMessage(message, _msgData(), _msgSender(), msg.sender, tx.origin);
    }

    function publicMsgSender() public view returns (address) {
        return _msgSender();
    }

    function publicMsgData() public view returns (bytes memory) {
        return _msgData();
    }

    function mustReceiveEth(uint256 value) public payable {
        require( msg.value == value, "didn't receive value");
    }

    event Reverting(string message);

    function testRevert() public {
        require(address(this) == address(0), "always fail");
        emit Reverting("if you see this revert failed...");
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDecimalsToken is ERC20 {

    constructor() ERC20("Test Token", "DEC") {
        mint(100 ether);
    }

    function mint(uint amount) public {
        _mint(msg.sender, amount);
    }

    uint8 private _decimals;

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function setDecimals(uint8 _dec) public {
        _decimals = _dec;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {IMagpieRouterV2} from "../interfaces/IMagpieRouterV2.sol";
import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibSwap, SwapData} from "../libraries/LibSwap.sol";
import {DelegatedCallType, LibGuard} from "../libraries/LibGuard.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";
import {LibUint256Array} from "../libraries/LibUint256Array.sol";
import {BridgeArgs, BridgeInArgs, BridgeOutArgs, RefundArgs} from "../bridge/LibCommon.sol";
import {LibTransaction, Transaction, TransactionValidation} from "../bridge/LibTransaction.sol";
import {DataTransferInArgs, DataTransferInProtocol, DataTransferOutArgs} from "../data-transfer/LibCommon.sol";

struct SwapInArgs {
    bytes swapArgs;
    BridgeArgs bridgeArgs;
    DataTransferInProtocol dataTransferInProtocol;
    TransactionValidation transactionValidation;
}

struct SwapOutArgs {
    bytes swapArgs;
    BridgeArgs bridgeArgs;
    DataTransferOutArgs dataTransferOutArgs;
}

struct SwapOutVariables {
    address fromAssetAddress;
    address toAssetAddress;
    address toAddress;
    address transactionToAddress;
    uint256 bridgeAmount;
    uint256 amountIn;
}

error AggregatorDepositIsZero();
error AggregatorInvalidAmountIn();
error AggregatorInvalidAmountOutMin();
error AggregatorInvalidFromAssetAddress();
error AggregatorInvalidMagpieAggregatorAddress();
error AggregatorInvalidToAddress();
error AggregatorInvalidToAssetAddress();
error AggregatorInvalidTransferKey();
error AggregatorBridgeInCallFailed();
error AggregatorBridgeOutCallFailed();
error AggregatorDataTransferInCallFailed();
error AggregatorDataTransferOutCallFailed();

library LibAggregator {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];

    uint16 constant SWAP_IN_SWAP_ARGS_OFFSET = 324;
    uint16 constant SWAP_OUT_SWAP_ARGS_OFFSET = 164;

    event UpdateWeth(address indexed sender, address weth);

    /// @dev Allows the contract owner to update the address of the WETH token used in the aggregator contract.
    /// @param weth Address of the Wrapped Ether (WETH) contract.
    function updateWeth(address weth) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.weth = weth;

        emit UpdateWeth(msg.sender, weth);
    }

    event UpdateMagpieRouterAddress(address indexed sender, address weth);

    /// @dev Allows the owner to update the magpieRouterAddress variable in the storage.
    /// @param magpieRouterAddress The address of the magpie router.
    function updateMagpieRouterAddress(address magpieRouterAddress) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.magpieRouterAddress = magpieRouterAddress;

        emit UpdateMagpieRouterAddress(msg.sender, magpieRouterAddress);
    }

    event UpdateNetworkId(address indexed sender, uint16 networkId);

    /// @dev See {IAggregator-updateNetworkId}
    function updateNetworkId(uint16 networkId) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.networkId = networkId;

        emit UpdateNetworkId(msg.sender, networkId);
    }

    event AddMagpieAggregatorAddresses(
        address indexed sender,
        uint16[] networkIds,
        bytes32[] magpieAggregatorAddresses
    );

    /// @dev See {IAggregator-addMagpieAggregatorAddresses}
    function addMagpieAggregatorAddresses(
        uint16[] memory networkIds,
        bytes32[] memory magpieAggregatorAddresses
    ) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = magpieAggregatorAddresses.length;
        for (i = 0; i < l; ) {
            s.magpieAggregatorAddresses[networkIds[i]] = magpieAggregatorAddresses[i];

            unchecked {
                i++;
            }
        }

        emit AddMagpieAggregatorAddresses(msg.sender, networkIds, magpieAggregatorAddresses);
    }

    /// @dev The wrapSwap function conducts a token swap operation, handling both direct transfers and swaps via Magpie Router.
    function wrapSwap(
        bytes memory swapArgs,
        SwapData memory swapData,
        address transferFromAddress
    ) private returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (
            swapData.fromAssetAddress == swapData.toAssetAddress ||
            (swapData.fromAssetAddress.isNative() && swapData.toAssetAddress == s.weth) ||
            (swapData.toAssetAddress.isNative() && swapData.fromAssetAddress == s.weth)
        ) {
            // Swap is not needed
            if (!swapData.fromAssetAddress.isNative()) {
                if (transferFromAddress != address(this)) {
                    swapData.fromAssetAddress.transferFrom(transferFromAddress, address(this), swapData.amountIn);
                }
            } else if (!swapData.toAssetAddress.isNative()) {
                swapData.fromAssetAddress.deposit(s.weth, swapData.amountIn);
            }

            amountOut = swapData.amountIn;

            if (transferFromAddress == address(this)) {
                swapData.toAssetAddress.withdraw(s.weth, swapData.toAddress, amountOut);
            }
        } else {
            uint256 amountIn = swapData.amountIn;
            // Swap is needed
            if (!swapData.fromAssetAddress.isNative()) {
                if (transferFromAddress != address(this)) {
                    swapData.fromAssetAddress.transferFrom(transferFromAddress, address(this), swapData.amountIn);
                }
                swapData.fromAssetAddress.approve(s.magpieRouterAddress, swapData.amountIn);
                amountIn = 0;
            }
            amountOut = IMagpieRouterV2(s.magpieRouterAddress).silentSwap{value: amountIn}(swapArgs);
        }
    }

    event SwapIn(
        address indexed fromAddress,
        bytes32 indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    /// @dev See {IAggregator-swapIn}
    function swapIn(SwapInArgs memory swapInArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        SwapData memory swapData = LibSwap.getData(SWAP_IN_SWAP_ARGS_OFFSET);

        if (swapData.toAddress != address(this)) {
            revert AggregatorInvalidToAddress();
        }

        amountOut = wrapSwap(swapInArgs.swapArgs, swapData, msg.sender);

        s.swapSequence += 1;
        TransferKey memory transferKey = TransferKey({
            networkId: s.networkId,
            senderAddress: bytes32(uint256(uint160(address(this)))),
            swapSequence: s.swapSequence
        });

        bridgeIn(
            BridgeInArgs({
                recipientNetworkId: swapInArgs.dataTransferInProtocol.networkId,
                bridgeArgs: swapInArgs.bridgeArgs,
                amount: amountOut,
                toAssetAddress: swapData.toAssetAddress,
                transferKey: transferKey
            })
        );

        Transaction memory transaction = Transaction({
            dataTransferType: swapInArgs.dataTransferInProtocol.dataTransferType,
            bridgeType: swapInArgs.bridgeArgs.bridgeType,
            recipientNetworkId: swapInArgs.dataTransferInProtocol.networkId,
            fromAssetAddress: swapInArgs.transactionValidation.fromAssetAddress,
            toAssetAddress: swapInArgs.transactionValidation.toAssetAddress,
            toAddress: swapInArgs.transactionValidation.toAddress,
            recipientAggregatorAddress: s.magpieAggregatorAddresses[swapInArgs.dataTransferInProtocol.networkId],
            amountOutMin: swapInArgs.transactionValidation.amountOutMin,
            swapOutGasFee: swapInArgs.transactionValidation.swapOutGasFee
        });

        dataTransferIn(
            DataTransferInArgs({
                protocol: swapInArgs.dataTransferInProtocol,
                transferKey: transferKey,
                payload: LibTransaction.encode(transaction)
            })
        );

        emit SwapIn(
            msg.sender,
            transaction.toAddress,
            swapData.fromAssetAddress,
            swapData.toAssetAddress,
            swapData.amountIn,
            amountOut,
            transferKey,
            transaction
        );
    }

    event SwapOut(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    /// @dev See {IAggregator-swapOut}
    function swapOut(SwapOutArgs memory swapOutArgs) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        bytes memory swapArgs = swapOutArgs.swapArgs;
        SwapData memory swapData = LibSwap.getData(SWAP_OUT_SWAP_ARGS_OFFSET);

        (TransferKey memory transferKey, bytes memory payload) = dataTransferOut(swapOutArgs.dataTransferOutArgs);

        if (s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence]) {
            revert AggregatorInvalidTransferKey();
        }

        s.usedTransferKeys[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence] = true;

        Transaction memory transaction = LibTransaction.decode(payload);

        SwapOutVariables memory v = SwapOutVariables({
            bridgeAmount: bridgeOut(
                BridgeOutArgs({bridgeArgs: swapOutArgs.bridgeArgs, transaction: transaction, transferKey: transferKey})
            ),
            amountIn: swapData.amountIn,
            toAddress: swapData.toAddress,
            transactionToAddress: address(uint160(uint256(transaction.toAddress))),
            fromAssetAddress: swapData.fromAssetAddress,
            toAssetAddress: swapData.toAssetAddress
        });

        if (v.transactionToAddress == msg.sender) {
            transaction.swapOutGasFee = 0;
            transaction.amountOutMin = swapData.amountOutMin;
        } else {
            swapData.amountOutMin = transaction.amountOutMin;
        }

        if (address(uint160(uint256(transaction.fromAssetAddress))) != v.fromAssetAddress) {
            revert AggregatorInvalidFromAssetAddress();
        }

        if (msg.sender != v.transactionToAddress) {
            if (address(uint160(uint256(transaction.toAssetAddress))) != v.toAssetAddress) {
                revert AggregatorInvalidToAssetAddress();
            }
        }

        if (v.transactionToAddress != v.toAddress || v.transactionToAddress == address(this)) {
            revert AggregatorInvalidToAddress();
        }

        if (address(uint160(uint256(transaction.recipientAggregatorAddress))) != address(this)) {
            revert AggregatorInvalidMagpieAggregatorAddress();
        }

        if (swapData.amountOutMin < transaction.amountOutMin) {
            revert AggregatorInvalidAmountOutMin();
        }

        uint256 firstAmountIn = LibSwap.getFirstAmountIn(SWAP_OUT_SWAP_ARGS_OFFSET);
        if (firstAmountIn <= transaction.swapOutGasFee) {
            revert AggregatorInvalidAmountIn();
        }

        if (v.amountIn > v.bridgeAmount) {
            revert AggregatorInvalidAmountIn();
        }

        v.amountIn -= firstAmountIn;

        firstAmountIn += (v.bridgeAmount > v.amountIn ? v.bridgeAmount - v.amountIn : 0) - transaction.swapOutGasFee;

        assembly {
            mstore(add(swapArgs, 36), firstAmountIn)
            mstore(add(swapArgs, 162), mload(add(swapData, 320))) // Override amountOutMin
        }

        v.amountIn += firstAmountIn;

        if (transaction.swapOutGasFee > 0) {
            s.deposits[v.fromAssetAddress] += transaction.swapOutGasFee;
            s.depositsByUser[v.fromAssetAddress][msg.sender] += transaction.swapOutGasFee;
        }

        amountOut = wrapSwap(swapArgs, swapData, address(this));

        emit SwapOut(
            msg.sender,
            v.toAddress,
            v.fromAssetAddress,
            v.toAssetAddress,
            v.amountIn,
            amountOut,
            transferKey,
            transaction
        );
    }

    event Withdraw(address indexed sender, address indexed assetAddress, uint256 amount);

    /// @dev See {IAggregator-withdraw}
    function withdraw(address assetAddress) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (assetAddress.isNative()) {
            assetAddress = s.weth;
        }

        uint256 deposit = s.depositsByUser[assetAddress][msg.sender];

        if (deposit == 0) {
            revert AggregatorDepositIsZero();
        }

        s.deposits[assetAddress] -= deposit;
        s.depositsByUser[assetAddress][msg.sender] = 0;

        assetAddress.transfer(msg.sender, deposit);

        emit Withdraw(msg.sender, assetAddress, deposit);
    }

    /// @dev See {IAggregator-getDeposit}
    function getDeposit(address assetAddress) internal view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.deposits[assetAddress];
    }

    /// @dev See {IAggregator-getDepositByUser}
    function getDepositByUser(address assetAddress, address senderAddress) internal view returns (uint256) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.depositsByUser[assetAddress][senderAddress];
    }

    /// @dev See {IAggregator-isTransferKeyUsed}
    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) internal view returns (bool) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        return s.usedTransferKeys[networkId][senderAddress][swapSequence];
    }

    /// @dev See {IBridge-bridgeIn}
    function bridgeIn(BridgeInArgs memory bridgeInArgs) internal {
        LibGuard.enforceDelegatedCallPreGuard(DelegatedCallType.BridgeIn);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"2312b1a3";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory bridgeInCall = abi.encodeWithSelector(selector, bridgeInArgs);
        (bool success, ) = address(facet).delegatecall(bridgeInCall);
        if (!success) {
            revert AggregatorBridgeInCallFailed();
        }
        LibGuard.enforceDelegatedCallPostGuard(DelegatedCallType.BridgeIn);
    }

    /// @dev See {IBridge-bridgeOut}
    function bridgeOut(BridgeOutArgs memory bridgeOutArgs) internal returns (uint256) {
        LibGuard.enforceDelegatedCallPreGuard(DelegatedCallType.BridgeOut);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"c6687b9d";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory bridgeOutCall = abi.encodeWithSelector(selector, bridgeOutArgs);
        (bool success, bytes memory data) = address(facet).delegatecall(bridgeOutCall);
        if (!success) {
            revert AggregatorBridgeOutCallFailed();
        }
        LibGuard.enforceDelegatedCallPostGuard(DelegatedCallType.BridgeOut);

        return abi.decode(data, (uint256));
    }

    /// @dev See {IDataTransfer-dataTransferIn}
    function dataTransferIn(DataTransferInArgs memory dataTransferInArgs) internal {
        LibGuard.enforceDelegatedCallPreGuard(DelegatedCallType.DataTransferIn);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"7f2bf445";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory dataTransferInCall = abi.encodeWithSelector(selector, dataTransferInArgs);
        (bool success, ) = address(facet).delegatecall(dataTransferInCall);
        if (!success) {
            revert AggregatorDataTransferInCallFailed();
        }
        LibGuard.enforceDelegatedCallPostGuard(DelegatedCallType.DataTransferIn);
    }

    /// @dev See {IDataTransfer-dataTransferOut}
    function dataTransferOut(
        DataTransferOutArgs memory dataTransferOutArgs
    ) internal returns (TransferKey memory, bytes memory) {
        LibGuard.enforceDelegatedCallPreGuard(DelegatedCallType.DataTransferOut);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 selector = hex"83d5b76e";
        address facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        bytes memory dataTransferOutCall = abi.encodeWithSelector(selector, dataTransferOutArgs);
        (bool success, bytes memory data) = address(facet).delegatecall(dataTransferOutCall);
        if (!success) {
            revert AggregatorDataTransferOutCallFailed();
        }
        LibGuard.enforceDelegatedCallPostGuard(DelegatedCallType.DataTransferOut);

        return abi.decode(data, (TransferKey, bytes));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {LibGuard} from "../../libraries/LibGuard.sol";
import {AppStorage} from "../../libraries/LibMagpieAggregator.sol";
import {LibPauser} from "../../pauser/LibPauser.sol";
import {IAggregator} from "../interfaces/IAggregator.sol";
import {LibAggregator, SwapInArgs, SwapOutArgs} from "../LibAggregator.sol";

contract AggregatorFacet is IAggregator {
    AppStorage internal s;

    /// @dev See {IAggregator-updateWeth}
    function updateWeth(address weth) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateWeth(weth);
    }

    /// @dev See {IAggregator-updateMagpieRouterAddress}
    function updateMagpieRouterAddress(address magpieRouterAddress) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateMagpieRouterAddress(magpieRouterAddress);
    }

    /// @dev See {IAggregator-updateNetworkId}
    function updateNetworkId(uint16 networkId) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateNetworkId(networkId);
    }

    /// @dev See {IAggregator-addMagpieAggregatorAddresses}
    function addMagpieAggregatorAddresses(
        uint16[] calldata networkIds,
        bytes32[] calldata magpieAggregatorAddresses
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.addMagpieAggregatorAddresses(networkIds, magpieAggregatorAddresses);
    }

    /// @dev See {IAggregator-swapIn}
    function swapIn(SwapInArgs calldata swapInArgs) external payable override returns (uint256 amountOut) {
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swapIn(swapInArgs);
        LibGuard.enforcePostGuard();
    }

    /// @dev See {IAggregator-swapOut}
    function swapOut(SwapOutArgs calldata swapOutArgs) external override returns (uint256 amountOut) {
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swapOut(swapOutArgs);
        LibGuard.enforcePostGuard();
    }

    /// @dev See {IAggregator-withdraw}
    function withdraw(address assetAddress) external override {
        LibPauser.enforceIsNotPaused();
        LibAggregator.withdraw(assetAddress);
    }

    /// @dev See {IAggregator-getDeposit}
    function getDeposit(address assetAddress) external view override returns (uint256) {
        return LibAggregator.getDeposit(assetAddress);
    }

    /// @dev See {IAggregator-getDepositByUser}
    function getDepositByUser(address assetAddress, address senderAddress) external view override returns (uint256) {
        return LibAggregator.getDepositByUser(assetAddress, senderAddress);
    }

    /// @dev See {IAggregator-isTransferKeyUsed}
    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view override returns (bool) {
        return LibAggregator.isTransferKeyUsed(networkId, senderAddress, swapSequence);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {DataTransferType} from "../../data-transfer/LibCommon.sol";
import {TransferKey} from "../../libraries/LibTransferKey.sol";
import {Transaction} from "../../bridge/LibTransaction.sol";
import {SwapInArgs, SwapOutArgs} from "../LibAggregator.sol";

interface IAggregator {
    event UpdateWeth(address indexed sender, address weth);

    /// @dev Allows the contract owner to update the address of wrapped native token.
    /// @param weth Address of the wrapped native token.
    function updateWeth(address weth) external;

    event UpdateNetworkId(address indexed sender, uint16 networkId);

    /// @dev Allows the contract owner to update the network id in the storage.
    /// @param networkId Magpie network id associated with the chain.
    function updateNetworkId(uint16 networkId) external;

    event AddMagpieAggregatorAddresses(
        address indexed sender,
        uint16[] networkIds,
        bytes32[] magpieAggregatorAddresses
    );

    /// @dev Allows the contract owner to add Magpie Aggregator addresses for multiple network ids.
    /// @param networkIds Magpie network id associated with the chain.
    /// @param magpieAggregatorAddresses The Magpie Aggregator diamond contract addresses for the related network ids.
    function addMagpieAggregatorAddresses(
        uint16[] calldata networkIds,
        bytes32[] calldata magpieAggregatorAddresses
    ) external;

    event SwapIn(
        address indexed fromAddress,
        bytes32 indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    /// @dev This function allows for swapping assets into the contract using a bridge-in transaction.
    /// @param swapInArgs Arguments that are required for swapOut.
    /// @return amountOut The amount received after swapping.
    function swapIn(SwapInArgs calldata swapInArgs) external payable returns (uint256 amountOut);

    event SwapOut(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut,
        TransferKey transferKey,
        Transaction transaction
    );

    /// @dev Withdraws the assets from the specified bridge and swaps them out to the specified address.
    /// @param swapOutArgs Arguments that are required for swapOut.
    /// @return amountOut The amount received after swapping.
    function swapOut(SwapOutArgs calldata swapOutArgs) external returns (uint256 amountOut);

    event Withdraw(address indexed sender, address indexed assetAddress, uint256 amount);

    /// @dev Withdraw assets that were collected to cover crosschain swap cost.
    /// @param assetAddress Address of the asset that will be withdrawn.
    function withdraw(address assetAddress) external;

    /// @dev Retrieve the deposit amount for a specific asset in the aggregator contract.
    /// @param assetAddress Address of the asset that will be deposited.
    function getDeposit(address assetAddress) external view returns (uint256);

    /// @dev Retrieve the deposit amount for a specific asset deposited by a specific user.
    /// @param assetAddress Address of the asset that was deposited
    /// @param senderAddress Address of the user who has deposited the asset
    function getDepositByUser(address assetAddress, address senderAddress) external view returns (uint256);

    /// @dev Check if a specific transfer key has been used for a crosschain swap.
    /// @param networkId Magpie network id associated with the chain.
    /// @param senderAddress The address  of the origin contract.
    /// @param swapSequence The magpie sequence for the current swap. Each swap gets a new a new sequence
    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bool);

    event UpdateMagpieRouterAddress(address indexed sender, address magpieRouterAddress);

    /// @dev Allows the contract owner to update the Magpie Router address.
    /// @param magpieRouterAddress The address of the Magpie Router.
    function updateMagpieRouterAddress(address magpieRouterAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LibBytes} from "../libraries/LibBytes.sol";
import {TransferKey} from "../libraries/LibTransferKey.sol";
import {Transaction} from "./LibTransaction.sol";

enum BridgeType {
    Wormhole,
    Stargate,
    Celer
}

struct BridgeArgs {
    BridgeType bridgeType;
    bytes payload;
}

struct BridgeInArgs {
    uint16 recipientNetworkId;
    BridgeArgs bridgeArgs;
    uint256 amount;
    address toAssetAddress;
    TransferKey transferKey;
}

struct BridgeOutArgs {
    BridgeArgs bridgeArgs;
    Transaction transaction;
    TransferKey transferKey;
}

struct RefundArgs {
    uint16 recipientNetworkId;
    uint256 amount;
    address toAssetAddress;
    TransferKey transferKey;
    BridgeArgs bridgeArgs;
    bytes payload;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {BridgeType} from "../bridge/LibCommon.sol";
import {DataTransferType} from "../data-transfer/LibCommon.sol";

struct TransactionValidation {
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

struct Transaction {
    DataTransferType dataTransferType;
    BridgeType bridgeType;
    uint16 recipientNetworkId;
    bytes32 fromAssetAddress;
    bytes32 toAssetAddress;
    bytes32 toAddress;
    bytes32 recipientAggregatorAddress;
    uint256 amountOutMin;
    uint256 swapOutGasFee;
}

library LibTransaction {
    /// @dev Encodes Transaction and converts it into a bytes.
    /// @param transaction Transaction thas will be encoded.
    /// @return transactionPayload Encoded transaction data.
    function encode(Transaction memory transaction) internal pure returns (bytes memory transactionPayload) {
        transactionPayload = new bytes(204);

        assembly {
            mstore(add(transactionPayload, 32), shl(248, mload(transaction))) // dataTransferType
            mstore(add(transactionPayload, 33), shl(248, mload(add(transaction, 32)))) // bridgeType
            mstore(add(transactionPayload, 34), shl(240, mload(add(transaction, 64)))) // recipientNetworkId
            mstore(add(transactionPayload, 36), mload(add(transaction, 96))) // fromAssetAddress
            mstore(add(transactionPayload, 68), mload(add(transaction, 128))) // toAssetAddress
            mstore(add(transactionPayload, 100), mload(add(transaction, 160))) // to
            mstore(add(transactionPayload, 132), mload(add(transaction, 192))) // recipientAggregatorAddress
            mstore(add(transactionPayload, 164), mload(add(transaction, 224))) // amountOutMin
            mstore(add(transactionPayload, 196), mload(add(transaction, 256))) // swapOutGasFee
        }
    }

    /// @dev Decodes transactionPayload and converts it to Transaction.
    /// @param transactionPayload Encoded transaction data.
    /// @return transaction Decoded transactionPayload.
    function decode(bytes memory transactionPayload) internal pure returns (Transaction memory transaction) {
        assembly {
            mstore(transaction, shr(248, mload(add(transactionPayload, 32)))) // dataTransferType
            mstore(add(transaction, 32), shr(248, mload(add(transactionPayload, 33)))) // bridgeType
            mstore(add(transaction, 64), shr(240, mload(add(transactionPayload, 34)))) // recipientNetworkId
            mstore(add(transaction, 96), mload(add(transactionPayload, 36))) // fromAssetAddress
            mstore(add(transaction, 128), mload(add(transactionPayload, 68))) // toAssetAddress
            mstore(add(transaction, 160), mload(add(transactionPayload, 100))) // to
            mstore(add(transaction, 192), mload(add(transactionPayload, 132))) // recipientAggregatorAddress
            mstore(add(transaction, 224), mload(add(transactionPayload, 164))) // amountOutMin
            mstore(add(transaction, 256), mload(add(transactionPayload, 196))) // swapOutGasFee
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {TransferKey} from "../libraries/LibTransferKey.sol";

enum DataTransferType {
    Wormhole,
    LayerZero
}

struct DataTransferInProtocol {
    uint16 networkId;
    DataTransferType dataTransferType;
    bytes payload;
}

struct DataTransferInArgs {
    DataTransferInProtocol protocol;
    TransferKey transferKey;
    bytes payload;
}

struct DataTransferOutArgs {
    DataTransferType dataTransferType;
    bytes payload;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IMagpieRouterV2 {
    /// @dev Allows the owner to pause the contract.
    function pause() external;

    /// @dev Allows the owner to unpause the contract.
    function unpause() external;

    /// @dev Allows the owner to update the mapping of command types to function selectors.
    /// @param commandType Identifier for each command. We have one selector / command.
    /// @param selector The function selector for each of these commands.
    function updateSelector(uint16 commandType, bytes4 selector) external;

    /// @dev Gets the selector at the specific commandType.
    /// @param commandType Identifier for each command. We have one selector / command.
    /// @return selector The function selector for the specified command.
    function getSelector(uint16 commandType) external view returns (bytes4);

    event Swap(
        address indexed fromAddress,
        address indexed toAddress,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev Provides an external interface to estimate the gas cost of the last hop in a route.
    /// @return amountOut The amount received after swapping.
    /// @return gasUsed The cost of gas while performing the swap.
    function estimateSwapGas(bytes calldata swapArgs) external payable returns (uint256 amountOut, uint256 gasUsed);

    /// @dev Performs token swap.
    /// @return amountOut The amount received after swapping.
    function swap(bytes calldata swapArgs) external payable returns (uint256 amountOut);

    /// @dev Performs token swap without triggering event.
    /// @return amountOut The amount received after swapping.
    function silentSwap(bytes calldata swapArgs) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";

error AssetNotReceived();
error ApprovalFailed();
error TransferFromFailed();
error TransferFailed();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    /// @dev Checks if the given address (self) represents a native asset (Ether).
    /// @param self The asset that will be checked for a native token.
    /// @return Flag to identify if the asset is native or not.
    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    /// @dev Retrieves the balance of the current contract for a given asset (self).
    /// @param self Asset whose balance needs to be found.
    /// @return Balance of the specific asset.
    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    /// @dev Retrieves the balance of the target address for a given asset (self).
    /// @param self Asset whose balance needs to be found.
    /// @param targetAddress The address where the balance is checked from.
    /// @return Balance of the specific asset.
    function getBalanceOf(address self, address targetAddress) internal view returns (uint256) {
        return self.isNative() ? targetAddress.balance : IERC20(self).balanceOf(targetAddress);
    }

    /// @dev Performs a safe transferFrom operation for a given asset (self) from one address (from) to another address (to).
    /// @param self Asset that will be transferred.
    /// @param from Address that will send the asset.
    /// @param to Address that will receive the asset.
    /// @param amount Transferred amount.
    function transferFrom(address self, address from, address to, uint256 amount) internal {
        IERC20 token = IERC20(self);

        bool success = execute(self, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));

        if (!success) revert TransferFromFailed();
    }

    /// @dev Transfers a given amount of an asset (self) to a recipient address (recipient).
    /// @param self Asset that will be transferred.
    /// @param recipient Address that will receive the transferred asset.
    /// @param amount Transferred amount.
    function transfer(address self, address recipient, uint256 amount) internal {
        IERC20 token = IERC20(self);
        bool success;

        if (self.isNative()) {
            (success, ) = payable(recipient).call{value: amount}("");
        } else {
            success = execute(self, abi.encodeWithSelector(token.transfer.selector, recipient, amount));
        }

        if (!success) {
            revert TransferFailed();
        }
    }

    /// @dev Approves a spender address (spender) to spend a specified amount of an asset (self).
    /// @param self The asset that will be approved.
    /// @param spender Address of a contract that will spend the owners asset.
    /// @param amount Asset amount that can be spent.
    function approve(address self, address spender, uint256 amount) internal {
        IERC20 token = IERC20(self);

        if (!execute(self, abi.encodeWithSelector(token.approve.selector, spender, amount))) {
            if (
                !execute(self, abi.encodeWithSelector(token.approve.selector, spender, 0)) ||
                !(execute(self, abi.encodeWithSelector(token.approve.selector, spender, amount)))
            ) {
                revert ApprovalFailed();
            }
        }
    }

    /// @dev Determines if a call was successful.
    /// @param target Address of the target contract.
    /// @param success To check if the call to the contract was successful or not.
    /// @param data The data was sent while calling the target contract.
    /// @return result The success of the call.
    function isSuccessful(address target, bool success, bytes memory data) private view returns (bool result) {
        if (success) {
            if (data.length == 0) {
                // isContract
                if (target.code.length > 0) {
                    result = true;
                }
            } else {
                assembly {
                    result := mload(add(data, 32))
                }
            }
        }
    }

    /// @dev Executes a low level call.
    /// @param self The address of the contract to which the call is being made.
    /// @param params The parameters or data to be sent in the call.
    /// @return result The success of the call.
    function execute(address self, bytes memory params) private returns (bool) {
        (bool success, bytes memory data) = self.call(params);

        return isSuccessful(self, success, data);
    }

    /// @dev Deposit of a specified amount of an asset (self).
    /// @param self Address of the asset that will be deposited.
    /// @param weth Address of the Wrapped Ether (WETH) contract.
    /// @param amount Amount that needs to be deposited.
    function deposit(address self, address weth, uint256 amount) internal {
        if (self.isNative()) {
            if (msg.value < amount) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: amount}();
        } else {
            self.transferFrom(msg.sender, address(this), amount);
        }
    }

    /// @dev Withdrawal of a specified amount of an asset (self) to a designated address (to).
    /// @param self The asset that will be withdrawn.
    /// @param weth Address of the Wrapped Ether (WETH) contract.
    /// @param to Address that will receive withdrawn token.
    /// @param amount Amount that needs to be withdrawn
    function withdraw(address self, address weth, address to, uint256 amount) internal {
        if (self.isNative()) {
            IWETH(weth).withdraw(amount);
        }
        self.transfer(payable(to), amount);
    }

    /// @dev Retrieves the decimal precision of an ERC20 token.
    /// @param self The asset address whose decimals we are retrieving.
    /// @return tokenDecimals The decimals of the asset.
    function getDecimals(address self) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;

        if (!self.isNative()) {
            (, bytes memory queriedDecimals) = self.staticcall(abi.encodeWithSignature("decimals()"));
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

error AddressOutOfBounds();

library LibBytes {
    using LibBytes for bytes;

    /// @dev Converts bytes into an address.
    /// @param self The bytes that contains the address.
    /// @param start The starting position to retrieve the address from the bytes.
    /// @return tempAddress The retrieved address from the bytes.
    function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
        if (self.length < start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(self, 20), start))
        }

        return tempAddress;
    }

    /// @dev Extracts a slice of bytes.
    /// @param self The string of bytes that needs to be sliced.
    /// @param start The starting position to begin slicing.
    /// @param length The length of the byte.
    /// @return tempBytes The sliced byte.
    function slice(bytes memory self, uint256 start, uint256 length) internal pure returns (bytes memory) {
        require(length + 31 >= length, "slice_overflow");
        require(self.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(self, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /// @dev Merge two byte arrays.
    /// @param self The bytes that needs to be merged.
    /// @param postBytes The bytes that needs to be merged.
    /// @return tempBytes The merged bytes.
    function concat(bytes memory self, bytes memory postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(self)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(self, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(add(add(end, iszero(add(length, mload(self)))), 31), not(31)))
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";

error ReentrantCall();
error InvalidDelegatedCall();

enum DelegatedCallType {
    BridgeIn,
    BridgeOut,
    DataTransferIn,
    DataTransferOut
}

library LibGuard {
    /// @dev Checks if the guarded flag is set.
    function enforcePreGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.guarded) {
            revert ReentrantCall();
        }

        s.guarded = true;
    }

    /// @dev Sets the guarded flag to false.
    function enforcePostGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.guarded = false;
    }

    /// @dev Reverts the transaction to prevent reentrancy. If no such call is in progress, it sets the delegated call state to true for that call type.
    /// @param delegatedCallType The value of the call type.
    function enforceDelegatedCallPreGuard(DelegatedCallType delegatedCallType) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.delegatedCalls[uint8(delegatedCallType)]) {
            revert ReentrantCall();
        }

        s.delegatedCalls[uint8(delegatedCallType)] = true;
    }

    /// @dev Accesses the contract storage to confirm whether a particular type of delegated call is currently in progress. If the expected call is not in progress, it reverts the transaction, indicating an invalid delegated call.
    /// @param delegatedCallType The value of the call type.
    function enforceDelegatedCallGuard(DelegatedCallType delegatedCallType) internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (!s.delegatedCalls[uint8(delegatedCallType)]) {
            revert InvalidDelegatedCall();
        }
    }

    /// @dev Sets the delegated call state back to false for the specified type of delegated call.
    /// @param delegatedCallType The value of the call type.
    function enforceDelegatedCallPostGuard(DelegatedCallType delegatedCallType) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.delegatedCalls[uint8(delegatedCallType)] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Deprecated
struct CurveSettings {
    address mainRegistry; // Address of the main registry of the curve protocol.
    address cryptoRegistry; // Address of the crypto registry of the curve protocol
    address cryptoFactory; // Address of the crypto factory of the crypto factory
}

struct Amm {
    uint8 protocolId; // The protocol identifier provided by magpie team.
    bytes4 selector; // The function selector of the AMM.
    address addr; // The address of the facet of the AMM.
}

struct WormholeBridgeSettings {
    address bridgeAddress; // The wormhole token bridge address
}

struct StargateSettings {
    address routerAddress; // The stargate router address.
}

struct WormholeSettings {
    address bridgeAddress; // The wormhole core bridge address.
    uint8 consistencyLevel; // The level of finality the guardians will reach before signing the message
}

struct LayerZeroSettings {
    address routerAddress; // The router address of layer zero protocol
}

struct CelerBridgeSettings {
    address messageBusAddress; // The message bus address of celer bridge
}

struct AppStorage {
    address weth;
    uint16 networkId;
    mapping(uint16 => bytes32) magpieAggregatorAddresses;
    mapping(address => uint256) deposits;
    mapping(address => mapping(address => uint256)) depositsByUser;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => bool))) usedTransferKeys;
    uint64 swapSequence;
    // Pausable
    bool paused;
    // Reentrancy Guard
    bool guarded;
    // Amm
    mapping(uint16 => Amm) amms;
    // Curve Amm
    CurveSettings curveSettings;
    // Data Transfer
    mapping(uint16 => mapping(uint16 => mapping(bytes32 => mapping(uint64 => bytes)))) payloads;
    // Stargate Bridge
    StargateSettings stargateSettings;
    mapping(uint16 => bytes32) magpieStargateBridgeAddresses;
    // Wormhole Bridge
    WormholeBridgeSettings wormholeBridgeSettings;
    mapping(uint64 => uint64) wormholeTokenSequences;
    // Wormhole Data Transfer
    WormholeSettings wormholeSettings;
    mapping(uint16 => uint16) wormholeNetworkIds;
    mapping(uint64 => uint64) wormholeCoreSequences;
    // LayerZero Data Transfer
    LayerZeroSettings layerZeroSettings;
    mapping(uint16 => uint16) layerZeroChainIds;
    mapping(uint16 => uint16) layerZeroNetworkIds;
    address magpieRouterAddress;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => mapping(address => uint256)))) stargateDeposits;
    mapping(uint8 => bool) delegatedCalls;
    // Celer Bridge
    CelerBridgeSettings celerBridgeSettings;
    mapping(uint16 => uint64) celerChainIds;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => mapping(address => uint256)))) celerDeposits;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => address))) celerRefundAddresses;
    mapping(uint16 => bytes32) magpieCelerBridgeAddresses;
    mapping(uint16 => mapping(uint16 => mapping(bytes32 => mapping(uint64 => bytes32)))) payloadHashes;
    mapping(uint16 => bytes32) magpieStargateBridgeV2Addresses;
}

library LibMagpieAggregator {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LibAsset} from "../libraries/LibAsset.sol";

struct SwapData {
    uint16 amountsOffset; // Represents the offset for the amounts section in the transaction calldata
    uint16 dataOffset; // Represents the offset for reusable data section in the calldata.
    uint16 commandsOffset; // Represents the starting point of the commands section in the calldata.
    uint16 commandsOffsetEnd; // Represents the end of the commands section in the calldata.
    uint16 outputsLength; // Represents the length of all of the commands
    uint256 amountIn; // Representing the amount of the asset being provided in the swap.
    address toAddress; // This is the address to which the output of the swap (the swapped asset) will be sent.
    address fromAssetAddress; // The address of the source asset being swapped from.
    address toAssetAddress; // The address of the final asset being swapped to.
    uint256 deadline; // Represents the deadline by which the swap must be completed.
    uint256 amountOutMin; // The minimum amount of the output asset that must be received for the swap to be considered successful.
}

library LibSwap {
    using LibAsset for address;

    uint16 constant SWAP_ARGS_OFFSET = 68;

    /// @dev Extracts and sums up the amounts of the source asset.
    /// @param startOffset Relative starting position.
    /// @param endOffset Ending position.
    /// @param positionOffset Absolute starting position.
    /// @return amountIn Sum of amounts.
    function getAmountIn(
        uint16 startOffset,
        uint16 endOffset,
        uint16 positionOffset
    ) internal pure returns (uint256 amountIn) {
        for (uint16 i = startOffset; i < endOffset; ) {
            uint256 currentAmountIn;
            assembly {
                let p := shr(240, calldataload(i))
                currentAmountIn := calldataload(add(p, positionOffset))
            }
            amountIn += currentAmountIn;

            unchecked {
                i += 2;
            }
        }
    }

    /// @dev Extract the first amount.
    /// @param swapArgsOffset Starting position of swapArgs in calldata.
    /// @return amountIn First amount in.
    function getFirstAmountIn(uint16 swapArgsOffset) internal pure returns (uint256 amountIn) {
        uint16 position = swapArgsOffset + 4;
        assembly {
            amountIn := calldataload(position)
        }
    }

    /// @dev Extracts SwapData from calldata.
    /// @param swapArgsOffset Starting position of swapArgs in calldata.
    /// @return swapData Essential data for the swap.
    function getData(uint16 swapArgsOffset) internal pure returns (SwapData memory swapData) {
        uint16 dataLength;
        uint16 amountsLength;
        uint16 dataOffset;
        uint16 swapArgsLength;
        assembly {
            dataLength := shr(240, calldataload(swapArgsOffset))
            amountsLength := shr(240, calldataload(add(swapArgsOffset, 2)))
            swapArgsLength := calldataload(sub(swapArgsOffset, 32))
        }
        dataOffset = swapArgsOffset + 4;
        swapData.dataOffset = dataOffset;
        swapData.amountsOffset = swapData.dataOffset + dataLength;
        swapData.commandsOffset = swapData.amountsOffset + amountsLength;
        swapData.commandsOffsetEnd = swapArgsLength + swapArgsOffset;
        // Depends on the context we have shift the position addSelector
        // By default the position is adjusted to the router's offset
        uint256 amountIn = getAmountIn(
            swapData.amountsOffset,
            swapData.commandsOffset,
            swapArgsOffset - SWAP_ARGS_OFFSET
        );

        assembly {
            mstore(add(swapData, 128), shr(240, calldataload(add(dataOffset, 32))))
            mstore(add(swapData, 160), amountIn)
            mstore(add(swapData, 192), shr(96, calldataload(add(dataOffset, 34))))
            mstore(add(swapData, 224), shr(96, calldataload(add(dataOffset, 54))))
            mstore(add(swapData, 256), shr(96, calldataload(add(dataOffset, 74))))
            mstore(add(swapData, 288), calldataload(add(dataOffset, 94)))
            mstore(add(swapData, 320), calldataload(add(dataOffset, 126)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct TransferKey {
    uint16 networkId; // Source network id that is defined by Magpie protocol for each chain
    bytes32 senderAddress; // The sender address in bytes32
    uint64 swapSequence; // Swap sequence (unique identifier) of the crosschain swap
}

error InvalidTransferKey();

library LibTransferKey {
    /// @dev Encodes transferKey.
    /// @param transferKey Swap identifier generated for each crosschain swap.
    /// @return payload Encoded transferKey.
    function encode(TransferKey memory transferKey) internal pure returns (bytes memory) {
        bytes memory payload = new bytes(42);

        assembly {
            mstore(add(payload, 32), shl(240, mload(transferKey)))
            mstore(add(payload, 34), mload(add(transferKey, 32)))
            mstore(add(payload, 66), shl(192, mload(add(transferKey, 64))))
        }

        return payload;
    }

    /// @dev Extracts transfer key from bytes.
    /// @param payload Contains the transferKey struct in bytes.
    /// @return transferKey Swap identifier generated for each crosschain swap.
    function decode(bytes memory payload) internal pure returns (TransferKey memory transferKey) {
        assembly {
            mstore(transferKey, shr(240, mload(add(payload, 32))))
            mstore(add(transferKey, 32), mload(add(payload, 34)))
            mstore(add(transferKey, 64), shr(192, mload(add(payload, 66))))
        }
    }

    /// @dev Compares two transferKeys for validation.
    /// @param self Swap identifier generated for each crosschain swap.
    /// @param transferKey Swap identifier generated for each crosschain swap.
    function validate(TransferKey memory self, TransferKey memory transferKey) internal pure {
        if (
            self.networkId != transferKey.networkId ||
            self.senderAddress != transferKey.senderAddress ||
            self.swapSequence != transferKey.swapSequence
        ) {
            revert InvalidTransferKey();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

library LibUint256Array {
    /// @dev Sum up the specified amounts.
    /// @param self Array of amounts.
    /// @return amountOut Sum of amounts.
    function sum(uint256[] memory self) internal pure returns (uint256 amountOut) {
        uint256 selfLength = self.length * 32;

        assembly {
            let selfPosition := add(self, 32)
            let endPosition := add(selfPosition, selfLength)

            for {

            } lt(selfPosition, endPosition) {
                selfPosition := add(selfPosition, 32)
            } {
                amountOut := add(amountOut, mload(selfPosition))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";

error ContractIsPaused();

library LibPauser {
    event Paused(address sender);

    /// @dev See {IPauser-pause}
    function pause() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.paused = true;
        emit Paused(msg.sender);
    }

    event Unpaused(address sender);

    /// @dev See {IPauser-unpause}
    function unpause() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.paused = false;
        emit Paused(msg.sender);
    }

    /// @dev Enforces that certain operations can only be performed when the contract is not paused.
    /// If the contract is indeed paused, the function reverts the transaction and provides an error message indicating that the contract is paused.
    /// This helps ensure that critical functions or actions are not performed during a paused state, maintaining the desired behavior and security of the contract.
    function enforceIsNotPaused() internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.paused) {
            revert ContractIsPaused();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
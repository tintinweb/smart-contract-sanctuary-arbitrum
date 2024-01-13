// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { IPerpetualMintView } from "./IPerpetualMintView.sol";
import { MintResultData, MintTokenTiersData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title PerpetualMintView
/// @dev PerpetualMintView facet contract containing all externally called view functions
contract PerpetualMintView is PerpetualMintInternal, IPerpetualMintView {
    constructor(address vrf) PerpetualMintInternal(vrf) {}

    /// @inheritdoc IPerpetualMintView
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees)
    {
        accruedFees = _accruedConsolationFees();
    }

    /// @inheritdoc IPerpetualMintView
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings)
    {
        accruedEarnings = _accruedMintEarnings();
    }

    /// @inheritdoc IPerpetualMintView
    function accruedProtocolFees() external view returns (uint256 accruedFees) {
        accruedFees = _accruedProtocolFees();
    }

    /// @inheritdoc IPerpetualMintView
    function BASIS() external pure returns (uint32 value) {
        value = _BASIS();
    }

    /// @inheritdoc IPerpetualMintView
    function calculateMintResult(
        address collection,
        uint32 numberOfMints,
        uint256 randomness,
        uint256 pricePerMint
    ) external view returns (MintResultData memory result) {
        result = _calculateMintResult(
            collection,
            numberOfMints,
            randomness,
            pricePerMint
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionMintFeeDistributionRatioBP(
        address collection
    ) external view returns (uint32 ratioBP) {
        ratioBP = _collectionMintFeeDistributionRatioBP(collection);
    }

    /// @inheritdoc IPerpetualMintView
    function collectionMintMultiplier(
        address collection
    ) external view returns (uint256 multiplier) {
        multiplier = _collectionMintMultiplier(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice) {
        mintPrice = _collectionMintPrice(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionReferralFeeBP(
        address collection
    ) external view returns (uint32 referralFeeBP) {
        referralFeeBP = _collectionReferralFeeBP(
            Storage.layout().collections[collection]
        );
    }

    /// @inheritdoc IPerpetualMintView
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk) {
        risk = _collectionRisk(Storage.layout().collections[collection]);
    }

    /// @inheritdoc IPerpetualMintView
    function collectionConsolationFeeBP()
        external
        view
        returns (uint32 collectionConsolationFeeBasisPoints)
    {
        collectionConsolationFeeBasisPoints = _collectionConsolationFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = _defaultCollectionMintPrice();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultCollectionReferralFeeBP()
        external
        view
        returns (uint32 referralFeeBP)
    {
        referralFeeBP = _defaultCollectionReferralFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultCollectionRisk() external pure returns (uint32 risk) {
        risk = _defaultCollectionRisk();
    }

    /// @inheritdoc IPerpetualMintView
    function defaultEthToMintRatio() external pure returns (uint32 ratio) {
        ratio = _defaultEthToMintRatio();
    }

    /// @inheritdoc IPerpetualMintView
    function ethToMintRatio() external view returns (uint256 ratio) {
        ratio = _ethToMintRatio(Storage.layout());
    }

    /// @inheritdoc IPerpetualMintView
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = _mintFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function mintToken() external view returns (address token) {
        token = _mintToken();
    }

    /// @inheritdoc IPerpetualMintView
    function mintTokenConsolationFeeBP()
        external
        view
        returns (uint32 mintTokenConsolationFeeBasisPoints)
    {
        mintTokenConsolationFeeBasisPoints = _mintTokenConsolationFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function mintTokenTiers()
        external
        view
        returns (MintTokenTiersData memory mintTokenTiersData)
    {
        mintTokenTiersData = _mintTokenTiers();
    }

    /// @inheritdoc IPerpetualMintView
    function redemptionFeeBP() external view returns (uint32 feeBP) {
        feeBP = _redemptionFeeBP();
    }

    /// @inheritdoc IPerpetualMintView
    function redeemPaused() external view returns (bool status) {
        status = _redeemPaused();
    }

    /// @inheritdoc IPerpetualMintView
    function SCALE() external pure returns (uint256 value) {
        value = _SCALE();
    }

    /// @inheritdoc IPerpetualMintView
    function tiers() external view returns (TiersData memory tiersData) {
        tiersData = _tiers();
    }

    /// @inheritdoc IPerpetualMintView
    function vrfConfig() external view returns (VRFConfig memory config) {
        config = _vrfConfig();
    }

    /// @inheritdoc IPerpetualMintView
    function vrfSubscriptionBalanceThreshold()
        external
        view
        returns (uint96 threshold)
    {
        threshold = _vrfSubscriptionBalanceThreshold();
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        _fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFCoordinatorV2Interface } from "@chainlink/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import { ISupraRouterContract } from "./Base/ISupraRouterContract.sol";
import { ERC1155MetadataExtensionInternal } from "./ERC1155MetadataExtensionInternal.sol";
import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { CollectionData, MintOutcome, MintResultData, MintTokenTiersData, PerpetualMintStorage as Storage, RequestData, TiersData, VRFConfig } from "./Storage.sol";
import { IToken } from "../Token/IToken.sol";
import { GuardsInternal } from "../../common/GuardsInternal.sol";

/// @title PerpetualMintInternal
/// @dev defines modularly all logic for the PerpetualMint mechanism in internal functions
abstract contract PerpetualMintInternal is
    ERC1155BaseInternal,
    ERC1155MetadataExtensionInternal,
    GuardsInternal,
    OwnableInternal,
    IPerpetualMintInternal,
    VRFConsumerBaseV2
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev used for floating point calculations
    uint256 private constant SCALE = 1e36;

    /// @dev denominator used in percentage calculations
    uint32 private constant BASIS = 1e9;

    /// @dev default mint price for a collection
    uint64 internal constant DEFAULT_COLLECTION_MINT_PRICE = 0.01 ether;

    /// @dev default risk for a collection
    uint32 internal constant DEFAULT_COLLECTION_RISK = 1e6; // 0.1%

    /// @dev Starting default conversion ratio: 1 ETH = 1,000,000 $MINT
    uint32 internal constant DEFAULT_ETH_TO_MINT_RATIO = 1e6;

    /// @dev minimum price per spin, 1000 gwei = 0.000001 ETH / 1 $MINT
    uint256 internal constant MINIMUM_PRICE_PER_SPIN = 1000 gwei;

    /// @dev address of the configured VRF
    address private immutable VRF;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        VRF = vrfCoordinator;
    }

    /// @notice returns the current accrued consolation fees
    /// @return accruedFees the current amount of accrued consolation fees
    function _accruedConsolationFees()
        internal
        view
        returns (uint256 accruedFees)
    {
        accruedFees = Storage.layout().consolationFees;
    }

    /// @notice returns the current accrued mint earnings across all collections
    /// @return accruedMintEarnings the current amount of accrued mint earnings across all collections
    function _accruedMintEarnings()
        internal
        view
        returns (uint256 accruedMintEarnings)
    {
        accruedMintEarnings = Storage.layout().mintEarnings;
    }

    /// @notice returns the current accrued protocol fees
    /// @return accruedFees the current amount of accrued protocol fees
    function _accruedProtocolFees()
        internal
        view
        returns (uint256 accruedFees)
    {
        accruedFees = Storage.layout().protocolFees;
    }

    function _attemptBatchMint_calculateMintPriceAdjustmentFactor(
        CollectionData storage collectionData,
        uint256 pricePerSpin
    ) private view returns (uint256 mintPriceAdjustmentFactor) {
        // upscale pricePerSpin before division to maintain precision
        uint256 scaledPricePerSpin = pricePerSpin * SCALE;

        // calculate the mint price adjustment factor & scale back down
        mintPriceAdjustmentFactor =
            ((scaledPricePerSpin / _collectionMintPrice(collectionData)) *
                BASIS) /
            SCALE;
    }

    function _attemptBatchMint_paidInEth_validateMintParameters(
        uint256 msgValue,
        uint256 pricePerSpin
    ) private pure {
        // throw if the price per spin is less than the minimum price per spin
        if (pricePerSpin < MINIMUM_PRICE_PER_SPIN) {
            revert PricePerSpinTooLow();
        }

        // throw if the price per spin is not evenly divisible by the ETH sent, i.e. the ETH sent is not a multiple of the price per spin
        if (msgValue % pricePerSpin != 0) {
            revert IncorrectETHReceived();
        }
    }

    function _attemptBatchMint_paidInMint_validateMintParameters(
        uint32 numberOfMints,
        uint256 consolationFees,
        uint256 ethRequired,
        uint256 pricePerSpinInWei,
        uint256 pricePerMint
    ) private pure {
        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        // throw if the price per spin is less than the minimum price per spin
        if (pricePerSpinInWei < MINIMUM_PRICE_PER_SPIN) {
            revert PricePerSpinTooLow();
        }

        // throw if the price per mint specified is a fraction and not evenly divisible by the price per spin in wei
        if (pricePerMint % pricePerSpinInWei != 0) {
            revert InvalidPricePerMint();
        }

        if (ethRequired > consolationFees) {
            revert InsufficientConsolationFees();
        }
    }

    /// @notice Attempts a batch mint for the msg.sender for $MINT using ETH as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintForMintWithEth(
        address minter,
        address referrer,
        uint32 numberOfMints
    ) internal {
        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintForMintWithEth_calculateAndDistributeFees(
            l,
            msgValue,
            referrer
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 1; // 1 words per mint for $MINT, current max of 500 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    /// @notice Attempts a Base-specific batch mint for the msg.sender for $MINT using ETH as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintForMintWithEthBase(
        address minter,
        address referrer,
        uint8 numberOfMints
    ) internal {
        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintForMintWithEth_calculateAndDistributeFees(
            l,
            msgValue,
            referrer
        );

        // if the number of words requested is greater than uint8, the function call will revert.
        // the current max allowed by Supra VRF is 255 per request.
        uint8 numWords = numberOfMints * 1; // 1 words per mint for $MINT, current max of 255 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWordsBase(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    function _attemptBatchMintForMintWithEth_calculateAndDistributeFees(
        Storage.Layout storage l,
        uint256 msgValue,
        address referrer
    ) private {
        // calculate the mint for $MINT consolation fee
        uint256 mintTokenConsolationFee = (msgValue *
            l.mintTokenConsolationFeeBP) / BASIS;

        // update the accrued consolation fees
        l.consolationFees += mintTokenConsolationFee;

        // calculate the protocol mint fee
        uint256 mintFee = msgValue - mintTokenConsolationFee;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(
                l.collections[address(0)] // $MINT
            );

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer
            payable(referrer).sendValue(referralFee);
        }

        // Update the accrued protocol fees (subtracting the referral fee if applicable)
        l.protocolFees += mintFee - referralFee;
    }

    /// @notice Attempts a batch mint for the msg.sender for $MINT using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintForMintWithMint(
        address minter,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintForMintWithMint_calculateAndDistributeFees(
            l,
            ethRequired,
            ethToMintRatio,
            minter,
            referrer
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 1; // 1 words per mint for $MINT, current max of 500 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    /// @notice Attempts a Base-specific batch mint for the msg.sender for $MINT using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintForMintWithMintBase(
        address minter,
        address referrer,
        uint256 pricePerMint,
        uint8 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintForMintWithMint_calculateAndDistributeFees(
            l,
            ethRequired,
            ethToMintRatio,
            minter,
            referrer
        );

        // if the number of words requested is greater than uint8, the function call will revert.
        // the current max allowed by Supra VRF is 255 per request.
        uint8 numWords = numberOfMints * 1; // 1 words per mint for $MINT, current max of 255 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWordsBase(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    function _attemptBatchMintForMintWithMint_calculateAndDistributeFees(
        Storage.Layout storage l,
        uint256 ethRequired,
        uint256 ethToMintRatio,
        address minter,
        address referrer
    ) private {
        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the mint for $MINT consolation fee
        uint256 mintTokenConsolationFee = (ethRequired *
            l.mintTokenConsolationFeeBP) / BASIS;

        // Calculate the net mint fee
        uint256 netMintFee = ethRequired - mintTokenConsolationFee;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(
                l.collections[address(0)] // $MINT
            );

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the netMintFee and referral fee percentage
            referralFee = (netMintFee * referralFeeBP) / BASIS;

            // Pay the referrer in $MINT
            IToken(l.mintToken).mintReferral(
                referrer,
                referralFee * ethToMintRatio
            );
        }

        // Update the accrued consolation fees
        l.consolationFees -= netMintFee;

        // Update the accrued protocol fees
        l.protocolFees += netMintFee - referralFee;
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithEth(
        address minter,
        address collection,
        address referrer,
        uint32 numberOfMints
    ) internal {
        if (collection == address(0)) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithEth_calculateAndDistributeFees(
            l,
            collectionData,
            msgValue,
            referrer
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint, current max of 250 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    /// @notice Attempts a Base-specific batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithEthBase(
        address minter,
        address collection,
        address referrer,
        uint8 numberOfMints
    ) internal {
        if (collection == address(0)) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithEth_calculateAndDistributeFees(
            l,
            collectionData,
            msgValue,
            referrer
        );

        // if the number of words requested is greater than uint8, the function call will revert.
        // the current max allowed by Supra VRF is 255 per request.
        uint8 numWords = numberOfMints * 2; // 2 words per mint, current max of 127 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWordsBase(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    function _attemptBatchMintWithEth_calculateAndDistributeFees(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        uint256 msgValue,
        address referrer
    ) private {
        // calculate the mint for collection consolation fee
        uint256 collectionConsolationFee = (msgValue *
            l.collectionConsolationFeeBP) / BASIS;

        // apply the collection-specific mint fee ratio
        uint256 additionalDepositorFee = (collectionConsolationFee *
            collectionData.mintFeeDistributionRatioBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (msgValue * l.mintFeeBP) / BASIS;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(collectionData);

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer
            payable(referrer).sendValue(referralFee);
        }

        // update the accrued consolation fees
        l.consolationFees += collectionConsolationFee - additionalDepositorFee;

        // update the accrued depositor mint earnings
        l.mintEarnings +=
            msgValue -
            collectionConsolationFee -
            mintFee +
            additionalDepositorFee;

        // Update the accrued protocol fees (subtracting the referral fee if applicable)
        l.protocolFees += mintFee - referralFee;
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithMint(
        address minter,
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) internal {
        if (collection == address(0)) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithMint_calculateAndDistributeFees(
            l,
            collectionData,
            minter,
            referrer,
            ethRequired,
            ethToMintRatio
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint, current max of 250 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    /// @notice Attempts a Base-specific batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithMintBase(
        address minter,
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint8 numberOfMints
    ) internal {
        if (collection == address(0)) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithMint_calculateAndDistributeFees(
            l,
            collectionData,
            minter,
            referrer,
            ethRequired,
            ethToMintRatio
        );

        // if the number of words requested is greater than uint8, the function call will revert.
        // the current max allowed by Supra VRF is 255 per request.
        uint8 numWords = numberOfMints * 2; // 2 words per mint, current max of 127 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWordsBase(
            l,
            collectionData,
            minter,
            collection,
            mintPriceAdjustmentFactor,
            numWords
        );
    }

    function _attemptBatchMintWithMint_calculateAndDistributeFees(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address referrer,
        uint256 ethRequired,
        uint256 ethToMintRatio
    ) private {
        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the mint for collection consolation fee
        uint256 collectionConsolationFee = (ethRequired *
            l.collectionConsolationFeeBP) / BASIS;

        // apply the collection-specific mint fee ratio
        uint256 additionalDepositorFee = (collectionConsolationFee *
            collectionData.mintFeeDistributionRatioBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (ethRequired * l.mintFeeBP) / BASIS;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(collectionData);

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer in $MINT
            IToken(l.mintToken).mintReferral(
                referrer,
                referralFee * ethToMintRatio
            );
        }

        // calculate the net collection consolation fee
        // ETH required for mint taken from collectionConsolationFee
        uint256 netConsolationFee = ethRequired -
            collectionConsolationFee +
            additionalDepositorFee;

        // update the accrued consolation fees
        l.consolationFees -= netConsolationFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += netConsolationFee - mintFee;

        // Update the accrued protocol fees, subtracting the referral fee
        l.protocolFees += mintFee - referralFee;
    }

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function _BASIS() internal pure returns (uint32 value) {
        value = BASIS;
    }

    /// @notice burns a receipt after a claim request is fulfilled
    /// @param tokenId id of receipt to burn
    function _burnReceipt(uint256 tokenId) internal {
        _burn(address(this), tokenId, 1);
    }

    /// @notice calculates the mint result of a given number of mint attempts for a given collection using given randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param randomness random value to use in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function _calculateMintResult(
        address collection,
        uint32 numberOfMints,
        uint256 randomness,
        uint256 pricePerMint
    ) internal view returns (MintResultData memory result) {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        bool mintForMint = collection == address(0);

        uint32 numberOfWords = numberOfMints * (mintForMint ? 1 : 2);

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerMint
            );

        uint256[] memory randomWords = new uint256[](numberOfWords);

        for (uint256 i = 0; i < numberOfWords; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        if (mintForMint) {
            result = _calculateMintForMintResult_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        } else {
            result = _calculateMintForCollectionResult_sharedLogic(
                l,
                _collectionRisk(collectionData),
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        }
    }

    /// @notice calculates the Base-specific mint result of a given number of mint attempts for a given collection using given signature as randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param signature signature value to use as randomness in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function _calculateMintResultBase(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) internal view returns (MintResultData memory result) {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        bool mintForMint = collection == address(0);

        uint8 numberOfWords = numberOfMints * (mintForMint ? 1 : 2);

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerMint
            );

        uint256[] memory randomWords = new uint256[](numberOfWords);

        for (uint256 i = 0; i < numberOfWords; ++i) {
            randomWords[i] = uint256(
                keccak256(abi.encodePacked(signature, i + 1))
            );
        }

        if (mintForMint) {
            result = _calculateMintForMintResult_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        } else {
            result = _calculateMintForCollectionResult_sharedLogic(
                l,
                _collectionRisk(collectionData),
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        }
    }

    function _calculateMintForCollectionResult_sharedLogic(
        Storage.Layout storage l,
        uint32 collectionRisk,
        uint32 numberOfMints,
        uint256[] memory randomWords,
        uint256 collectionMintMultiplier,
        uint256 ethToMintRatio,
        uint256 mintAdjustmentFactor,
        CollectionData storage collectionData
    ) private view returns (MintResultData memory result) {
        TiersData storage tiers = l.tiers;

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        result.mintOutcomes = new MintOutcome[](numberOfMints);

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            MintOutcome memory outcome;

            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            uint256 secondNormalizedValue = _normalizeValue(
                randomWords[i + 1],
                BASIS
            );

            if (!(collectionRisk > firstNormalizedValue)) {
                uint256 mintAmount;
                uint256 cumulativeRisk;

                for (uint256 j = 0; j < tiers.tierRisks.length; ++j) {
                    cumulativeRisk += tiers.tierRisks[j];

                    if (cumulativeRisk > secondNormalizedValue) {
                        mintAmount =
                            (tiers.tierMultipliers[j] *
                                mintAdjustmentFactor *
                                ethToMintRatio *
                                collectionMintPrice *
                                collectionMintMultiplier) /
                            (uint256(BASIS) * BASIS * BASIS);

                        outcome.tierIndex = j;
                        outcome.tierMultiplier = tiers.tierMultipliers[j];
                        outcome.tierRisk = tiers.tierRisks[j];
                        outcome.mintAmount = mintAmount;

                        break;
                    }
                }

                result.totalMintAmount += mintAmount;
            } else {
                ++result.totalSuccessfulMints;
            }

            result.mintOutcomes[i / 2] = outcome;
        }
    }

    function _calculateMintForMintResult_sharedLogic(
        Storage.Layout storage l,
        uint32 numberOfMints,
        uint256[] memory randomWords,
        uint256 collectionMintMultiplier,
        uint256 ethToMintRatio,
        uint256 mintAdjustmentFactor,
        CollectionData storage collectionData
    ) private view returns (MintResultData memory result) {
        MintTokenTiersData storage mintTokenTiers = l.mintTokenTiers;

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        result.mintOutcomes = new MintOutcome[](numberOfMints);

        for (uint256 i = 0; i < randomWords.length; ++i) {
            MintOutcome memory outcome;

            uint256 normalizedValue = _normalizeValue(randomWords[i], BASIS);

            uint256 mintAmount;
            uint256 cumulativeRisk;

            for (uint256 j = 0; j < mintTokenTiers.tierRisks.length; ++j) {
                cumulativeRisk += mintTokenTiers.tierRisks[j];

                if (cumulativeRisk > normalizedValue) {
                    mintAmount =
                        (mintTokenTiers.tierMultipliers[j] *
                            mintAdjustmentFactor *
                            ethToMintRatio *
                            collectionMintPrice *
                            collectionMintMultiplier) /
                        (uint256(BASIS) * BASIS * BASIS);

                    outcome.tierIndex = j;
                    outcome.tierMultiplier = mintTokenTiers.tierMultipliers[j];
                    outcome.tierRisk = mintTokenTiers.tierRisks[j];
                    outcome.mintAmount = mintAmount;

                    break;
                }
            }

            result.totalMintAmount += mintAmount;

            result.mintOutcomes[i] = outcome;
        }
    }

    /// @notice Cancels a claim for a given claimer for given token ID
    /// @param claimer address of rejected claimer
    /// @param tokenId token ID of rejected claim
    function _cancelClaim(address claimer, uint256 tokenId) internal {
        _safeTransfer(address(this), address(this), claimer, tokenId, 1, "");

        emit ClaimCancelled(
            claimer,
            address(uint160(tokenId)) // decode tokenId to get collection address
        );
    }

    /// @notice claims all accrued mint earnings across collections
    /// @param recipient address of mint earnings recipient
    function _claimMintEarnings(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 mintEarnings = l.mintEarnings;
        l.mintEarnings = 0;

        payable(recipient).sendValue(mintEarnings);
    }

    /// @notice Initiates a claim for a prize for a given collection
    /// @param claimer address of claimer
    /// @param prizeRecipient address of intended prize recipient
    /// @param tokenId token ID of prize, which is the prize collection address encoded as uint256
    function _claimPrize(
        address claimer,
        address prizeRecipient,
        uint256 tokenId
    ) internal {
        _safeTransfer(msg.sender, claimer, address(this), tokenId, 1, "");

        emit PrizeClaimed(
            claimer,
            prizeRecipient,
            address(uint160(tokenId)) // decode tokenId to get collection address
        );
    }

    /// @notice claims all accrued protocol fees
    /// @param recipient address of protocol fees recipient
    function _claimProtocolFees(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 protocolFees = l.protocolFees;
        l.protocolFees = 0;

        payable(recipient).sendValue(protocolFees);
    }

    /// @notice Returns the current mint fee distribution ratio in basis points for a collection
    /// @param collection address of collection
    /// @return ratioBP current collection mint fee distribution ratio in basis points
    function _collectionMintFeeDistributionRatioBP(
        address collection
    ) internal view returns (uint32 ratioBP) {
        ratioBP = Storage
            .layout()
            .collections[collection]
            .mintFeeDistributionRatioBP;
    }

    /// @notice Returns the current collection multiplier for a given collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return multiplier current collection multiplier
    function _collectionMintMultiplier(
        CollectionData storage collectionData
    ) internal view returns (uint256 multiplier) {
        multiplier = collectionData.mintMultiplier;

        multiplier = multiplier == 0 ? BASIS : multiplier; // default multiplier is 1x
    }

    /// @notice Returns the current mint price for a given collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return mintPrice current collection mint price
    function _collectionMintPrice(
        CollectionData storage collectionData
    ) internal view returns (uint256 mintPrice) {
        mintPrice = collectionData.mintPrice;

        mintPrice = mintPrice == 0 ? DEFAULT_COLLECTION_MINT_PRICE : mintPrice;
    }

    /// @notice Returns the current mint referral fee for a given collection in basis points
    /// @param collectionData the CollectionData struct for a given collection
    /// @return referralFeeBP current mint collection referral fee in basis
    function _collectionReferralFeeBP(
        CollectionData storage collectionData
    ) internal view returns (uint32 referralFeeBP) {
        referralFeeBP = collectionData.referralFeeBP;
    }

    /// @notice Returns the current collection-wide risk of a collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return risk value of collection-wide risk
    function _collectionRisk(
        CollectionData storage collectionData
    ) internal view returns (uint32 risk) {
        risk = collectionData.risk;

        risk = risk == 0 ? DEFAULT_COLLECTION_RISK : risk;
    }

    /// @notice Returns the current collection consolation fee in basis points
    /// @return collectionConsolationFeeBasisPoints mint for collection consolation fee in basis points
    function _collectionConsolationFeeBP()
        internal
        view
        returns (uint32 collectionConsolationFeeBasisPoints)
    {
        collectionConsolationFeeBasisPoints = Storage
            .layout()
            .collectionConsolationFeeBP;
    }

    /// @notice Returns the default mint price for a collection
    /// @return mintPrice default collection mint price
    function _defaultCollectionMintPrice()
        internal
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = DEFAULT_COLLECTION_MINT_PRICE;
    }

    /// @notice Returns the default mint referral fee for a collection in basis points
    /// @return referralFeeBP default mint collection referral fee in basis points
    function _defaultCollectionReferralFeeBP()
        internal
        view
        returns (uint32 referralFeeBP)
    {
        referralFeeBP = Storage.layout().defaultCollectionReferralFeeBP;
    }

    /// @notice Returns the default risk for a collection
    /// @return risk default collection risk
    function _defaultCollectionRisk() internal pure returns (uint32 risk) {
        risk = DEFAULT_COLLECTION_RISK;
    }

    /// @notice Returns the default ETH to $MINT ratio
    /// @return ratio default ETH to $MINT ratio
    function _defaultEthToMintRatio() internal pure returns (uint32 ratio) {
        ratio = DEFAULT_ETH_TO_MINT_RATIO;
    }

    /// @dev enforces that there are no pending mint requests for a collection
    /// @param collectionData the CollectionData struct for a given collection
    function _enforceNoPendingMints(
        CollectionData storage collectionData
    ) internal view {
        if (collectionData.pendingRequests.length() != 0) {
            revert PendingRequests();
        }
    }

    /// @notice Returns the current ETH to $MINT ratio
    /// @param l the PerpetualMint storage layout
    /// @return ratio current ETH to $MINT ratio
    function _ethToMintRatio(
        Storage.Layout storage l
    ) internal view returns (uint256 ratio) {
        ratio = l.ethToMintRatio;

        ratio = ratio == 0 ? DEFAULT_ETH_TO_MINT_RATIO : ratio;
    }

    /// @notice internal VRF callback
    /// @notice is executed by the configured VRF contract
    /// @param requestId id of VRF request
    /// @param randomWords random values return by the configured VRF contract
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual {
        Storage.Layout storage l = Storage.layout();

        RequestData storage request = l.requests[requestId];

        address collection = request.collection;
        address minter = request.minter;
        uint256 mintPriceAdjustmentFactor = request.mintPriceAdjustmentFactor;

        CollectionData storage collectionData = l.collections[collection];

        // if the collection is address(0), the mint is for $MINT
        if (collection == address(0)) {
            _resolveMintsForMint(
                l.mintToken,
                _collectionMintMultiplier(collectionData),
                _collectionMintPrice(collectionData),
                mintPriceAdjustmentFactor,
                l.mintTokenTiers,
                minter,
                randomWords,
                _ethToMintRatio(l)
            );
        } else {
            // if the collection is not address(0), the mint is for a collection
            _resolveMints(
                l.mintToken,
                collectionData,
                mintPriceAdjustmentFactor,
                l.tiers,
                minter,
                collection,
                randomWords,
                _ethToMintRatio(l)
            );
        }

        collectionData.pendingRequests.remove(requestId);

        delete l.requests[requestId];
    }

    /// @notice funds the consolation fees pool with ETH
    function _fundConsolationFees() internal {
        Storage.layout().consolationFees += msg.value;

        emit ConsolationFeesFunded(msg.sender, msg.value);
    }

    /// @notice mints an amount of mintToken tokens to the mintToken contract in exchange for ETH
    /// @param amount amount of mintToken tokens to mint
    function _mintAirdrop(uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        if (amount / _ethToMintRatio(l) != msg.value) {
            revert IncorrectETHReceived();
        }

        l.consolationFees += msg.value;

        IToken(l.mintToken).mintAirdrop(amount);
    }

    /// @notice Returns the current mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function _mintFeeBP() internal view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = Storage.layout().mintFeeBP;
    }

    /// @notice Returns the address of the current $MINT token
    /// @return mintToken address of the current $MINT token
    function _mintToken() internal view returns (address mintToken) {
        mintToken = Storage.layout().mintToken;
    }

    /// @notice Returns the current $MINT consolation fee in basis points
    /// @return mintTokenConsolationFeeBasisPoints mint for $MINT consolation fee in basis points
    function _mintTokenConsolationFeeBP()
        internal
        view
        returns (uint32 mintTokenConsolationFeeBasisPoints)
    {
        mintTokenConsolationFeeBasisPoints = Storage
            .layout()
            .mintTokenConsolationFeeBP;
    }

    /// @notice Returns the current tier risks and multipliers for minting for $MINT
    function _mintTokenTiers()
        internal
        view
        returns (MintTokenTiersData memory mintTokenTiersData)
    {
        mintTokenTiersData = Storage.layout().mintTokenTiers;
    }

    /// @notice ensures a value is within the BASIS range
    /// @param value value to normalize
    /// @return normalizedValue value after normalization
    function _normalizeValue(
        uint256 value,
        uint32 basis
    ) internal pure returns (uint256 normalizedValue) {
        normalizedValue = value % basis;
    }

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for an account
    /// @dev only one-sided ($MINT => ETH (native token)) supported
    /// @param account address of account
    /// @param amount amount of $MINT
    function _redeem(address account, uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        if (l.redeemPaused) {
            revert RedeemPaused();
        }

        // burn amount of $MINT to be swapped
        IToken(l.mintToken).burn(account, amount);

        // calculate amount of ETH given for $MINT amount
        uint256 ethAmount = (amount * (BASIS - l.redemptionFeeBP)) /
            (BASIS * _ethToMintRatio(l));

        if (ethAmount > l.consolationFees) {
            revert InsufficientConsolationFees();
        }

        // decrease consolationFees
        l.consolationFees -= ethAmount;

        payable(account).sendValue(ethAmount);
    }

    /// @notice returns value of redeemPaused
    /// @return status boolean indicating whether redeeming is paused
    function _redeemPaused() internal view returns (bool status) {
        status = Storage.layout().redeemPaused;
    }

    /// @notice returns the current redemption fee in basis points
    /// @return feeBP redemptionFee in basis points
    function _redemptionFeeBP() internal view returns (uint32 feeBP) {
        feeBP = Storage.layout().redemptionFeeBP;
    }

    /// @notice requests random values from Chainlink VRF
    /// @param l the PerpetualMint storage layout
    /// @param collectionData the CollectionData struct for a given collection
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param numWords amount of random values to request
    function _requestRandomWords(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address collection,
        uint256 mintPriceAdjustmentFactor,
        uint32 numWords
    ) internal {
        VRFCoordinatorV2Interface vrfCoordinator = VRFCoordinatorV2Interface(
            VRF
        );

        (uint96 vrfSubscriptionBalance, , , ) = vrfCoordinator.getSubscription(
            l.vrfConfig.subscriptionId
        );

        if (vrfSubscriptionBalance < l.vrfSubscriptionBalanceThreshold) {
            revert VRFSubscriptionBalanceBelowThreshold();
        }

        uint256 requestId = vrfCoordinator.requestRandomWords(
            l.vrfConfig.keyHash,
            l.vrfConfig.subscriptionId,
            l.vrfConfig.minConfirmations,
            l.vrfConfig.callbackGasLimit,
            numWords
        );

        collectionData.pendingRequests.add(requestId);

        RequestData storage request = l.requests[requestId];

        request.collection = collection;
        request.minter = minter;
        request.mintPriceAdjustmentFactor = mintPriceAdjustmentFactor;
    }

    /// @notice requests random values from Supra VRF, Base-specific
    /// @param l the PerpetualMint storage layout
    /// @param collectionData the CollectionData struct for a given collection
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param numWords amount of random values to request
    function _requestRandomWordsBase(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address collection,
        uint256 mintPriceAdjustmentFactor,
        uint8 numWords
    ) internal {
        ISupraRouterContract supraRouter = ISupraRouterContract(VRF);

        uint256 requestId = supraRouter.generateRequest(
            "rawFulfillRandomWords(uint256,uint256[])",
            numWords,
            1, // number of confirmations
            _owner()
        );

        collectionData.pendingRequests.add(requestId);

        RequestData storage request = l.requests[requestId];

        request.collection = collection;
        request.minter = minter;
        request.mintPriceAdjustmentFactor = mintPriceAdjustmentFactor;
    }

    /// @notice resolves the outcomes of attempted mints for a given collection
    /// @param mintToken address of $MINT token
    /// @param collectionData the CollectionData struct for a given collection
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param tiersData the TiersData struct for mint consolations
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMints(
        address mintToken,
        CollectionData storage collectionData,
        uint256 mintPriceAdjustmentFactor,
        TiersData memory tiersData,
        address minter,
        address collection,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        // ensure the number of random words is even
        // each valid mint attempt requires two random words
        if (randomWords.length % 2 != 0) {
            revert UnmatchedRandomWords();
        }

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        // adjust the collection risk by the mint price adjustment factor
        uint256 collectionRisk = (_collectionRisk(collectionData) *
            mintPriceAdjustmentFactor) / BASIS;

        uint256 cumulativeTierMultiplier;
        uint256 totalReceiptAmount;

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            // first random word is used to determine whether the mint attempt was successful
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            // second random word is used to determine the consolation tier
            uint256 secondNormalizedValue = _normalizeValue(
                randomWords[i + 1],
                BASIS
            );

            // if the collection risk is less than the first normalized value, the mint attempt is unsuccessful
            // and the second normalized value is used to determine the consolation tier
            if (!(collectionRisk > firstNormalizedValue)) {
                uint256 tierMultiplier;
                uint256 cumulativeRisk;

                // iterate through tiers to find the tier that the random value falls into
                for (uint256 j = 0; j < tiersData.tierRisks.length; ++j) {
                    cumulativeRisk += tiersData.tierRisks[j];

                    // if the cumulative risk is greater than the second normalized value, the tier has been found
                    if (cumulativeRisk > secondNormalizedValue) {
                        tierMultiplier = tiersData.tierMultipliers[j];

                        break;
                    }
                }

                cumulativeTierMultiplier += tierMultiplier;
            } else {
                // mint attempt is successful, so the total receipt amount is incremented
                ++totalReceiptAmount;
            }
        }

        uint256 totalMintAmount;

        // Mint the cumulative amounts at the end
        if (cumulativeTierMultiplier > 0) {
            // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, collection mint price, and apply collection-specific multiplier & mint price adjustment factor
            totalMintAmount =
                (cumulativeTierMultiplier *
                    ethToMintRatio *
                    collectionMintPrice *
                    collectionMintMultiplier *
                    mintPriceAdjustmentFactor) /
                (uint256(BASIS) * BASIS * BASIS);

            IToken(mintToken).mint(minter, totalMintAmount);
        }

        if (totalReceiptAmount > 0) {
            _safeMint(
                minter,
                uint256(bytes32(abi.encode(collection))), // encode collection address as tokenId
                totalReceiptAmount,
                ""
            );
        }

        emit MintResult(
            minter,
            collection,
            randomWords.length / 2,
            totalMintAmount,
            totalReceiptAmount
        );
    }

    /// @notice resolves the outcomes of attempted mints for $MINT
    /// @param mintToken address of $MINT token
    /// @param mintForMintMultiplier minting for $MINT multiplier
    /// @param mintForMintPrice mint for $MINT mint price
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param mintTokenTiersData the MintTokenTiersData struct for mint for $MINT consolations
    /// @param minter address of minter
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMintsForMint(
        address mintToken,
        uint256 mintForMintMultiplier,
        uint256 mintForMintPrice,
        uint256 mintPriceAdjustmentFactor,
        MintTokenTiersData memory mintTokenTiersData,
        address minter,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        uint256 cumulativeTierMultiplier;

        for (uint256 i = 0; i < randomWords.length; ++i) {
            // random word is used to determine the reward tier
            uint256 normalizedValue = _normalizeValue(randomWords[i], BASIS);

            uint256 tierMultiplier;
            uint256 cumulativeRisk;

            // iterate through tiers to find the tier that the random value falls into
            for (uint256 j = 0; j < mintTokenTiersData.tierRisks.length; ++j) {
                cumulativeRisk += mintTokenTiersData.tierRisks[j];

                // if the cumulative risk is greater than the normalized value, the tier has been found
                if (cumulativeRisk > normalizedValue) {
                    tierMultiplier = mintTokenTiersData.tierMultipliers[j];

                    break;
                }
            }

            cumulativeTierMultiplier += tierMultiplier;
        }

        // Mint the cumulative amounts at the end
        // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, mint for $MINT price, and apply $MINT-specific multiplier & mint price adjustment factor
        uint256 totalMintAmount = (cumulativeTierMultiplier *
            ethToMintRatio *
            mintForMintPrice *
            mintForMintMultiplier *
            mintPriceAdjustmentFactor) / (uint256(BASIS) * BASIS * BASIS);

        IToken(mintToken).mint(minter, totalMintAmount);

        emit MintResult(
            minter,
            address(0),
            randomWords.length,
            totalMintAmount,
            0
        );
    }

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function _SCALE() internal pure returns (uint256 value) {
        value = SCALE;
    }

    /// @notice sets the collection mint fee distribution ratio in basis points
    /// @param collection address of collection
    /// @param ratioBP collection mint fee distribution ratio in basis points
    function _setCollectionMintFeeDistributionRatioBP(
        address collection,
        uint32 ratioBP
    ) internal {
        _enforceBasis(ratioBP, BASIS);

        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        collectionData.mintFeeDistributionRatioBP = ratioBP;

        emit CollectionMintFeeRatioUpdated(collection, ratioBP);
    }

    /// @notice sets the mint multiplier for a given collection
    /// @param collection address of collection
    /// @param multiplier mint multiplier of the collection
    function _setCollectionMintMultiplier(
        address collection,
        uint256 multiplier
    ) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceNoPendingMints(collectionData);

        collectionData.mintMultiplier = multiplier;

        emit CollectionMultiplierSet(collection, multiplier);
    }

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function _setCollectionMintPrice(
        address collection,
        uint256 price
    ) internal {
        Storage.layout().collections[collection].mintPrice = price;

        emit MintPriceSet(collection, price);
    }

    /// @notice sets the mint referral fee for a given collection in basis points
    /// @param collection address of collection
    /// @param referralFeeBP mint referral fee of the collection in basis points
    function _setCollectionReferralFeeBP(
        address collection,
        uint32 referralFeeBP
    ) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceBasis(referralFeeBP, BASIS);

        collectionData.referralFeeBP = referralFeeBP;

        emit CollectionReferralFeeBPSet(collection, referralFeeBP);
    }

    /// @notice sets the risk for a given collection
    /// @param collection address of collection
    /// @param risk risk of the collection
    function _setCollectionRisk(address collection, uint32 risk) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceBasis(risk, BASIS);

        _enforceNoPendingMints(collectionData);

        collectionData.risk = risk;

        emit CollectionRiskSet(collection, risk);
    }

    /// @notice sets the mint for collection consolation fee in basis points
    /// @param collectionConsolationFeeBP mint for collection consolation fee in basis points
    function _setCollectionConsolationFeeBP(
        uint32 collectionConsolationFeeBP
    ) internal {
        _enforceBasis(collectionConsolationFeeBP, BASIS);

        Storage
            .layout()
            .collectionConsolationFeeBP = collectionConsolationFeeBP;

        emit CollectionConsolationFeeSet(collectionConsolationFeeBP);
    }

    /// @notice sets the default mint referral fee for collections in basis points
    /// @param referralFeeBP new default mint referral fee for collections in basis points
    function _setDefaultCollectionReferralFeeBP(uint32 referralFeeBP) internal {
        _enforceBasis(referralFeeBP, BASIS);

        Storage.layout().defaultCollectionReferralFeeBP = referralFeeBP;

        emit DefaultCollectionReferralFeeBPSet(referralFeeBP);
    }

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio new ratio of ETH to $MINT
    function _setEthToMintRatio(uint256 ratio) internal {
        Storage.layout().ethToMintRatio = ratio;

        emit EthToMintRatioSet(ratio);
    }

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function _setMintFeeBP(uint32 mintFeeBP) internal {
        _enforceBasis(mintFeeBP, BASIS);

        Storage.layout().mintFeeBP = mintFeeBP;

        emit MintFeeSet(mintFeeBP);
    }

    /// @notice sets the address of the mint consolation token
    /// @param mintToken address of the mint consolation token
    function _setMintToken(address mintToken) internal {
        Storage.layout().mintToken = mintToken;

        emit MintTokenSet(mintToken);
    }

    /// @notice sets the mint for $MINT consolation fee in basis points
    /// @param mintTokenConsolationFeeBP mint for $MINT consolation fee in basis points
    function _setMintTokenConsolationFeeBP(
        uint32 mintTokenConsolationFeeBP
    ) internal {
        _enforceBasis(mintTokenConsolationFeeBP, BASIS);

        Storage.layout().mintTokenConsolationFeeBP = mintTokenConsolationFeeBP;

        emit MintTokenConsolationFeeSet(mintTokenConsolationFeeBP);
    }

    /// @notice sets the mint for $MINT tiers data
    /// @param mintTokenTiersData MintTokenTiersData struct holding all related data to mint for $MINT consolations
    function _setMintTokenTiers(
        MintTokenTiersData calldata mintTokenTiersData
    ) internal {
        Storage.layout().mintTokenTiers = mintTokenTiersData;

        emit MintTokenTiersSet(mintTokenTiersData);
    }

    /// @notice sets the status of the redeemPaused state
    /// @param status boolean indicating whether redeeming is paused
    function _setRedeemPaused(bool status) internal {
        Storage.layout().redeemPaused = status;

        emit RedeemPausedSet(status);
    }

    /// @notice sets the redemption fee in basis points
    /// @param redemptionFeeBP redemption fee in basis points
    function _setRedemptionFeeBP(uint32 redemptionFeeBP) internal {
        _enforceBasis(redemptionFeeBP, BASIS);

        Storage.layout().redemptionFeeBP = redemptionFeeBP;

        emit RedemptionFeeSet(redemptionFeeBP);
    }

    /// @notice sets the mint for collection $MINT consolation tiers data
    /// @param tiersData TiersData struct holding all related data to mint for collection $MINT consolations
    function _setTiers(TiersData calldata tiersData) internal {
        Storage.layout().tiers = tiersData;

        emit TiersSet(tiersData);
    }

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    function _setVRFConfig(VRFConfig calldata config) internal {
        Storage.layout().vrfConfig = config;

        emit VRFConfigSet(config);
    }

    /// @notice sets the Chainlink VRF subscription LINK balance threshold
    /// @param vrfSubscriptionBalanceThreshold VRF subscription balance threshold
    function _setVRFSubscriptionBalanceThreshold(
        uint96 vrfSubscriptionBalanceThreshold
    ) internal {
        Storage
            .layout()
            .vrfSubscriptionBalanceThreshold = vrfSubscriptionBalanceThreshold;

        emit VRFSubscriptionBalanceThresholdSet(
            vrfSubscriptionBalanceThreshold
        );
    }

    /// @notice Returns the current tier risks and multipliers for minting for collection $MINT consolations
    function _tiers() internal view returns (TiersData memory tiersData) {
        tiersData = Storage.layout().tiers;
    }

    /// @notice Returns the current Chainlink VRF config
    /// @return config VRFConfig struct
    function _vrfConfig() internal view returns (VRFConfig memory config) {
        config = Storage.layout().vrfConfig;
    }

    /// @notice Returns the current Chainlink VRF subscription LINK balance threshold
    /// @return vrfSubscriptionBalanceThreshold VRF subscription balance threshold
    function _vrfSubscriptionBalanceThreshold()
        internal
        view
        returns (uint96 vrfSubscriptionBalanceThreshold)
    {
        vrfSubscriptionBalanceThreshold = Storage
            .layout()
            .vrfSubscriptionBalanceThreshold;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { MintResultData, MintTokenTiersData, TiersData, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMintView
/// @dev Interface of the PerpetualMintView facet
interface IPerpetualMintView {
    /// @notice Returns the current accrued consolation fees
    /// @return accruedFees the current amount of accrued consolation fees
    function accruedConsolationFees()
        external
        view
        returns (uint256 accruedFees);

    /// @notice returns the current accrued mint earnings across all collections
    /// @return accruedEarnings the current amount of accrued mint earnings across all collections
    function accruedMintEarnings()
        external
        view
        returns (uint256 accruedEarnings);

    /// @notice returns the current accrued protocol fees
    /// @return accruedFees the current amount of accrued protocol fees
    function accruedProtocolFees() external view returns (uint256 accruedFees);

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function BASIS() external pure returns (uint32 value);

    /// @notice calculates the mint result of a given number of mint attempts for a given collection using given randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param randomness random value to use in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function calculateMintResult(
        address collection,
        uint32 numberOfMints,
        uint256 randomness,
        uint256 pricePerMint
    ) external view returns (MintResultData memory result);

    /// @notice Returns the current mint fee distribution ratio in basis points for a collection
    /// @param collection address of collection
    /// @return ratioBP current collection mint fee distribution ratio in basis points
    function collectionMintFeeDistributionRatioBP(
        address collection
    ) external view returns (uint32 ratioBP);

    /// @notice Returns the current mint multiplier for a collection
    /// @param collection address of collection
    /// @return multiplier current collection mint multiplier
    function collectionMintMultiplier(
        address collection
    ) external view returns (uint256 multiplier);

    /// @notice Returns the current mint price for a collection
    /// @param collection address of collection
    /// @return mintPrice current collection mint price
    function collectionMintPrice(
        address collection
    ) external view returns (uint256 mintPrice);

    /// @notice Returns the current mint referral fee for a given collection in basis points
    /// @param collection address of collection
    /// @return referralFeeBP current mint collection referral fee in basis points
    function collectionReferralFeeBP(
        address collection
    ) external view returns (uint32 referralFeeBP);

    /// @notice Returns the current collection-wide risk of a collection
    /// @param collection address of collection
    /// @return risk value of collection-wide risk
    function collectionRisk(
        address collection
    ) external view returns (uint32 risk);

    /// @notice Returns the collection consolation fee in basis points
    /// @return collectionConsolationFeeBasisPoints minting for collection consolation fee in basis points
    function collectionConsolationFeeBP()
        external
        view
        returns (uint32 collectionConsolationFeeBasisPoints);

    /// @notice Returns the default mint price for a collection
    /// @return mintPrice default collection mint price
    function defaultCollectionMintPrice()
        external
        pure
        returns (uint256 mintPrice);

    /// @notice Returns the default mint referral fee for a collection in basis points
    /// @return referralFeeBP default collection mint referral fee in basis points
    function defaultCollectionReferralFeeBP()
        external
        view
        returns (uint32 referralFeeBP);

    /// @notice Returns the default risk for a collection
    /// @return risk default collection risk
    function defaultCollectionRisk() external pure returns (uint32 risk);

    /// @notice Returns the default ETH to $MINT ratio
    /// @return ratio default ETH to $MINT ratio
    function defaultEthToMintRatio() external pure returns (uint32 ratio);

    /// @notice Returns the current ETH to $MINT ratio
    /// @return ratio current ETH to $MINT ratio
    function ethToMintRatio() external view returns (uint256 ratio);

    /// @notice Returns the mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function mintFeeBP() external view returns (uint32 mintFeeBasisPoints);

    /// @notice Returns the address of the current $MINT token
    /// @return token address of the current $MINT token
    function mintToken() external view returns (address token);

    /// @notice Returns the $MINT consolation fee in basis points
    /// @return mintTokenConsolationFeeBasisPoints minting for $MINT consolation fee in basis points
    function mintTokenConsolationFeeBP()
        external
        view
        returns (uint32 mintTokenConsolationFeeBasisPoints);

    /// @notice Returns the current mint for $MINT tiers
    function mintTokenTiers()
        external
        view
        returns (MintTokenTiersData memory mintTokenTiersData);

    /// @notice returns the current redemption fee in basis points
    /// @return feeBP redemptionFee in basis points
    function redemptionFeeBP() external view returns (uint32 feeBP);

    /// @notice returns value of redeemPaused
    /// @return status boolean indicating whether redeeming is paused
    function redeemPaused() external view returns (bool status);

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function SCALE() external pure returns (uint256 value);

    /// @notice Returns the current mint for collection $MINT consolation tiers
    function tiers() external view returns (TiersData memory tiersData);

    /// @notice returns the current VRF config
    /// @return config VRFConfig struct
    function vrfConfig() external view returns (VRFConfig memory config);

    /// @notice returns the current VRF subscription LINK balance threshold
    /// @return threshold VRF subscription balance threshold
    function vrfSubscriptionBalanceThreshold()
        external
        view
        returns (uint96 threshold);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./types/DataTypes.sol";

/// @title PerpetualMintStorage
/// @dev defines storage layout for the PerpetualMint facet
library PerpetualMintStorage {
    struct Layout {
        /// @dev $MINT mint for collection consolation tiers data
        TiersData tiers;
        /// @dev all variables related to Chainlink VRF configuration
        VRFConfig vrfConfig;
        /// @dev mint for collection consolation fee in basis points
        uint32 collectionConsolationFeeBP;
        /// @dev mint fee in basis points
        uint32 mintFeeBP;
        /// @dev redemption fee in basis points
        uint32 redemptionFeeBP;
        /// @dev The minimum threshold for the VRF subscription balance in LINK tokens.
        uint96 vrfSubscriptionBalanceThreshold;
        /// @dev amount of consolation fees accrued in ETH (native token) from mint attempts
        uint256 consolationFees;
        /// @dev amount of mint earnings accrued in ETH (native token) from mint attempts
        uint256 mintEarnings;
        /// @dev amount of protocol fees accrued in ETH (native token) from mint attempts
        uint256 protocolFees;
        /// @dev ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
        uint256 ethToMintRatio;
        /// @dev mapping of collection addresses to collection-specific data
        mapping(address collection => CollectionData) collections;
        /// @dev mapping of mint attempt VRF requests which have not yet been fulfilled
        mapping(uint256 requestId => RequestData) requests;
        /// @dev address of the current $MINT token
        address mintToken;
        /// @dev status of whether redeem is paused
        bool redeemPaused;
        /// @dev mint for $MINT consolation fee in basis points
        uint32 mintTokenConsolationFeeBP;
        /// @dev $MINT mint for $MINT consolation tiers data
        MintTokenTiersData mintTokenTiers;
        /// @dev default mint referral fee for a collection in basis points
        uint32 defaultCollectionReferralFeeBP;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.PerpetualMint");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155Receiver } from '../../../interfaces/IERC1155Receiver.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC1155BaseInternal } from './IERC1155BaseInternal.sol';
import { ERC1155BaseStorage } from './ERC1155BaseStorage.sol';

/**
 * @title Base ERC1155 internal functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155BaseInternal is IERC1155BaseInternal {
    using AddressUtils for address;

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function _balanceOf(
        address account,
        uint256 id
    ) internal view virtual returns (uint256) {
        if (account == address(0))
            revert ERC1155Base__BalanceQueryZeroAddress();
        return ERC1155BaseStorage.layout().balances[id][account];
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155BaseStorage.layout().balances[id][account] += amount;

        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    /**
     * @notice mint given quantity of tokens for given address
     * @param account beneficiary of minting
     * @param id token ID
     * @param amount quantity of tokens to mint
     * @param data data payload
     */
    function _safeMint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(account, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @notice mint batch of tokens for given address
     * @dev ERC1155Receiver implementation is not checked
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _mintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            balances[ids[i]][account] += amounts[i];
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), account, ids, amounts);
    }

    /**
     * @notice mint batch of tokens for given address
     * @param account beneficiary of minting
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to mint
     * @param data data payload
     */
    function _safeMintBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _mintBatch(account, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            address(0),
            account,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice burn given quantity of tokens held by given address
     * @param account holder of tokens to burn
     * @param id token ID
     * @param amount quantity of tokens to burn
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

        _beforeTokenTransfer(
            msg.sender,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ''
        );

        mapping(address => uint256) storage balances = ERC1155BaseStorage
            .layout()
            .balances[id];

        unchecked {
            if (amount > balances[account])
                revert ERC1155Base__BurnExceedsBalance();
            balances[account] -= amount;
        }

        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    /**
     * @notice burn given batch of tokens held by given address
     * @param account holder of tokens to burn
     * @param ids token IDs
     * @param amounts quantities of tokens to burn
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            for (uint256 i; i < ids.length; i++) {
                uint256 id = ids[i];
                if (amounts[i] > balances[id][account])
                    revert ERC1155Base__BurnExceedsBalance();
                balances[id][account] -= amounts[i];
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    /**
     * @notice transfer tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _transfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();

        _beforeTokenTransfer(
            operator,
            sender,
            recipient,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        unchecked {
            uint256 senderBalance = balances[id][sender];
            if (amount > senderBalance)
                revert ERC1155Base__TransferExceedsBalance();
            balances[id][sender] = senderBalance - amount;
        }

        balances[id][recipient] += amount;

        emit TransferSingle(operator, sender, recipient, id, amount);
    }

    /**
     * @notice transfer tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _safeTransfer(
        address operator,
        address sender,
        address recipient,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _transfer(operator, sender, recipient, id, amount, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            id,
            amount,
            data
        );
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @dev ERC1155Receiver implementation is not checked
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _transferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (recipient == address(0))
            revert ERC1155Base__TransferToZeroAddress();
        if (ids.length != amounts.length)
            revert ERC1155Base__ArrayLengthMismatch();

        _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

        mapping(uint256 => mapping(address => uint256))
            storage balances = ERC1155BaseStorage.layout().balances;

        for (uint256 i; i < ids.length; ) {
            uint256 token = ids[i];
            uint256 amount = amounts[i];

            unchecked {
                uint256 senderBalance = balances[token][sender];

                if (amount > senderBalance)
                    revert ERC1155Base__TransferExceedsBalance();

                balances[token][sender] = senderBalance - amount;

                i++;
            }

            // balance increase cannot be unchecked because ERC1155Base neither tracks nor validates a totalSupply
            balances[token][recipient] += amount;
        }

        emit TransferBatch(operator, sender, recipient, ids, amounts);
    }

    /**
     * @notice transfer batch of tokens between given addresses
     * @param operator executor of transfer
     * @param sender sender of tokens
     * @param recipient receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _safeTransferBatch(
        address operator,
        address sender,
        address recipient,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _transferBatch(operator, sender, recipient, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            sender,
            recipient,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice wrap given element in array of length 1
     * @param element element to wrap
     * @return singleton array
     */
    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector)
                    revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice revert if applicable transfer recipient is not valid ERC1155Receiver
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) revert ERC1155Base__ERC1155ReceiverRejected();
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155Base__ERC1155ReceiverNotImplemented();
            }
        }
    }

    /**
     * @notice ERC1155 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @dev called for both single and batch transfers
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids token IDs
     * @param amounts quantities of tokens to transfer
     * @param data data payload
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ISupraRouterContract
/// @dev Interface containing the relevant functions used to request randomness from the Supra VRF Router
interface ISupraRouterContract {
    /// @notice Generates the random number request to generator contract with client's randomness added
    /// @dev It will forward the random number generation request by calling generator contracts function which takes seed value other than required parameter to add randomness
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @param _clientSeed Use of this is to add some extra randomness
    /// @return nonce nonce is an incremental counter which is associated with request
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        uint256 _clientSeed,
        address _clientWalletAddress
    ) external returns (uint256 nonce);

    /// @notice Generates the random number request to generator contract
    /// @dev It will forward the random number generation request by calling generator contracts function
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @return nonce nonce is an incremental counter which is associated with request
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        address _clientWalletAddress
    ) external returns (uint256 nonce);

    /// @notice This is the callback function to serve random number request
    /// @dev This function will be called from generator contract address to fulfill random number request which goes to client contract
    /// @param nonce nonce is an incremental counter which is associated with request
    /// @param _clientContractAddress Actual contract address from which request has been generated
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @return success bool variable which shows the status of request
    /// @return data data getting from client contract address
    function rngCallback(
        uint256 nonce,
        uint256[] memory rngList,
        address _clientContractAddress,
        string memory _functionSig
    ) external returns (bool success, bytes memory data);

    /// @notice Getter for returning the Supra Deposit Contract address
    /// @return depositContract Supra Deposit Contract address
    function _depositContract() external view returns (address depositContract);

    /// @notice Getter for returning Generator contract address used to forward random number requests
    /// @return supraGeneratorContract Supra Generator Contract address
    function _supraGeneratorContract()
        external
        view
        returns (address supraGeneratorContract);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ERC1155MetadataExtensionStorage } from "./ERC1155MetadataExtensionStorage.sol";

/// @title ERC1155MetadataExtensionInternal
/// @dev ERC1155MetadataExtension internal functions
abstract contract ERC1155MetadataExtensionInternal {
    /// @notice reads the ERC1155 collection name
    /// @return name ERC1155 collection name
    function _name() internal view returns (string memory name) {
        name = ERC1155MetadataExtensionStorage.layout().name;
    }

    /// @notice sets a new name for the ERC1155 collection
    /// @param name name to set
    function _setName(string memory name) internal {
        ERC1155MetadataExtensionStorage.layout().name = name;
    }

    /// @notice sets a new symbol for the ERC1155 collection
    /// @param symbol symbol to set
    function _setSymbol(string memory symbol) internal {
        ERC1155MetadataExtensionStorage.layout().symbol = symbol;
    }

    /// @notice reads the ERC1155 collection symbol
    /// @return symbol ERC1155 collection symbol
    function _symbol() internal view returns (string memory symbol) {
        symbol = ERC1155MetadataExtensionStorage.layout().symbol;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { MintTokenTiersData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "./Storage.sol";

/// @title IPerpetualMintInternal
/// @dev Interface containing all errors and events used in the PerpetualMint facet contract
interface IPerpetualMintInternal {
    /// @notice thrown when an incorrect amount of ETH is received
    error IncorrectETHReceived();

    /// @notice thrown when there are not enough consolation fees accrued to faciliate
    /// minting with $MINT
    error InsufficientConsolationFees();

    /// @notice thrown when an invalid collection address is provided when minting for a collection
    /// for now, this is only thrown when attempting to address(0) when minting for a collection
    error InvalidCollectionAddress();

    /// @notice thrown when attempting to mint 0 tokens
    error InvalidNumberOfMints();

    /// @notice thrown when the specified price per mint in $MINT is not a whole number
    error InvalidPricePerMint();

    /// @dev thrown when attempting to update a collection risk and
    /// there are pending mint requests in a collection
    error PendingRequests();

    /// @dev thrown when the mint price per spin is less than MINIMUM_PRICE_PER_SPIN
    error PricePerSpinTooLow();

    /// @dev thrown when attempting to redeem when redeeming is paused
    error RedeemPaused();

    /// @notice thrown when fulfilled random words do not match for attempted mints
    error UnmatchedRandomWords();

    /// @notice thrown when VRF subscription LINK balance falls below the required threshold
    error VRFSubscriptionBalanceBelowThreshold();

    /// @notice emitted when a claim is cancelled
    /// @param claimer address of rejected claimer
    /// @param collection address of rejected claim collection
    event ClaimCancelled(address claimer, address indexed collection);

    /// @notice emitted when the mint fee distribution ratio for a collection is updated
    /// @param collection address of collection
    /// @param ratioBP new mint fee distribution ratio in basis points
    event CollectionMintFeeRatioUpdated(address collection, uint32 ratioBP);

    /// @notice emitted when the mint multiplier for a collection is set
    /// @param collection address of collection
    /// @param multiplier multiplier of collection
    event CollectionMultiplierSet(address collection, uint256 multiplier);

    /// @notice emitted when the mint referral fee in basis points for a collection is set
    /// @param collection address of collection
    /// @param referralFeeBP mint referral fee of collection in basis points
    event CollectionReferralFeeBPSet(address collection, uint32 referralFeeBP);

    /// @notice emitted when the risk for a collection is set
    /// @param collection address of collection
    /// @param risk risk of collection
    event CollectionRiskSet(address collection, uint32 risk);

    /// @notice emitted when the collection consolation fee is set
    /// @param collectionConsolationFeeBP minting for collection consolation fee in basis points
    event CollectionConsolationFeeSet(uint32 collectionConsolationFeeBP);

    /// @notice emitted when the consolation fees are funded
    /// @param funder address of funder
    /// @param amount amount of ETH funded
    event ConsolationFeesFunded(address indexed funder, uint256 amount);

    /// @notice emitted when the default mint referral fee for collections is set
    /// @param referralFeeBP new default mint referral fee for collections in basis points
    event DefaultCollectionReferralFeeBPSet(uint32 referralFeeBP);

    /// @notice emitted when the ETH:MINT ratio is set
    /// @param ratio value of ETH:MINT ratio
    event EthToMintRatioSet(uint256 ratio);

    /// @notice emitted when the mint fee is set
    /// @param mintFeeBP mint fee in basis points
    event MintFeeSet(uint32 mintFeeBP);

    /// @notice emitted when the mint price of a collection is set
    /// @param collection address of collection
    /// @param price mint price of collection
    event MintPriceSet(address collection, uint256 price);

    /// @notice emitted when the $MINT consolation fee is set
    /// @param mintTokenConsolationFeeBP minting for $MINT consolation fee in basis points
    event MintTokenConsolationFeeSet(uint32 mintTokenConsolationFeeBP);

    /// @notice emitted when the address of the $MINT token is set
    /// @param mintToken address of mint token
    event MintTokenSet(address mintToken);

    /// @notice emitted when the outcome of an attempted mint is resolved
    /// @param minter address of account attempting the mint
    /// @param collection address of collection that attempted mint is for
    /// @param attempts number of mint attempts
    /// @param totalMintAmount amount of $MINT tokens minted
    /// @param totalReceiptAmount amount of receipts (ERC1155 tokens) minted (successful mint attempts)
    event MintResult(
        address indexed minter,
        address indexed collection,
        uint256 attempts,
        uint256 totalMintAmount,
        uint256 totalReceiptAmount
    );

    /// @notice emitted when the mint token tiers are set
    /// @param mintTokenTiersData new tiers
    event MintTokenTiersSet(MintTokenTiersData mintTokenTiersData);

    /// @notice emitted when a prize is claimed
    /// @param claimer address of claimer
    /// @param prizeRecipient address of specified prize recipient
    /// @param collection address of collection prize
    event PrizeClaimed(
        address claimer,
        address prizeRecipient,
        address indexed collection
    );

    /// @notice emitted when redeemPaused is set
    /// @param status boolean value indicating whether redeeming is paused
    event RedeemPausedSet(bool status);

    /// @notice emitted when the redemption fee is set
    /// @param redemptionFeeBP redemption fee in basis points
    event RedemptionFeeSet(uint32 redemptionFeeBP);

    /// @notice emitted when the tiers are set
    /// @param tiersData new tiers
    event TiersSet(TiersData tiersData);

    /// @notice emitted when the Chainlink VRF config is set
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    event VRFConfigSet(VRFConfig config);

    /// @notice emitted when the VRF subscription LINK balance threshold is set
    /// @param vrfSubscriptionBalanceThreshold VRF subscription balance threshold
    event VRFSubscriptionBalanceThresholdSet(
        uint96 vrfSubscriptionBalanceThreshold
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateERC20 } from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";
import { AccrualData } from "./types/DataTypes.sol";

/// @title ITokenMint
/// @dev Interface containing all external functions for Token facet
interface IToken is ISolidStateERC20 {
    /// @notice returns AccrualData struct pertaining to account, which contains Token accrual
    /// information
    /// @param account address of account
    /// @return data AccrualData of account
    function accrualData(
        address account
    ) external view returns (AccrualData memory data);

    /// @notice adds an account to the mintingContracts enumerable set
    /// @param account address of account
    function addMintingContract(address account) external;

    /// @notice returns value of airdropSupply
    /// @return supply value of airdropSupply
    function airdropSupply() external view returns (uint256 supply);

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function BASIS() external pure returns (uint32 value);

    /// @notice burns an amount of tokens of an account
    /// @param account account to burn from
    /// @param amount amount of tokens to burn
    function burn(address account, uint256 amount) external;

    /// @notice claims all claimable tokens for the msg.sender
    function claim() external;

    /// @notice returns all claimable tokens of a given account
    /// @param account address of account
    /// @return amount amount of claimable tokens
    function claimableTokens(
        address account
    ) external view returns (uint256 amount);

    /// @notice Disperses tokens to a list of recipients
    /// @param recipients assumed ordered array of recipient addresses
    /// @param amounts assumed ordered array of token amounts to disperse
    function disperseTokens(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;

    /// @notice returns the distributionFractionBP value
    /// @return fractionBP value of distributionFractionBP
    function distributionFractionBP() external view returns (uint32 fractionBP);

    /// @notice returns the distribution supply value
    /// @return supply distribution supply value
    function distributionSupply() external view returns (uint256 supply);

    /// @notice returns the global ratio value
    /// @return ratio global ratio value
    function globalRatio() external view returns (uint256 ratio);

    /// @notice disburses (mints) an amount of tokens to an account
    /// @param account address of account receive the tokens
    /// @param amount amount of tokens to disburse
    function mint(address account, uint256 amount) external;

    /// @notice mints an amount of tokens intended for airdrop
    /// @param amount airdrop token amount
    function mintAirdrop(uint256 amount) external;

    /// @notice mints an amount of tokens as a mint referral bonus
    /// @param referrer address of mint referrer
    /// @param amount referral token amount
    function mintReferral(address referrer, uint256 amount) external;

    /// @notice returns all addresses of contracts which are allowed to call mint/burn
    /// @return contracts array of addresses of contracts which are allowed to call mint/burn
    function mintingContracts()
        external
        view
        returns (address[] memory contracts);

    /// @notice removes an account from the mintingContracts enumerable set
    /// @param account address of account
    function removeMintingContract(address account) external;

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function SCALE() external pure returns (uint256 value);

    /// @notice sets a new value for distributionFractionBP
    /// @param _distributionFractionBP new distributionFractionBP value
    function setDistributionFractionBP(uint32 _distributionFractionBP) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IGuardsInternal } from "./IGuardsInternal.sol";

/// @title GuardsInternal
/// @dev contains common internal guard functions
abstract contract GuardsInternal is IGuardsInternal {
    /// @notice enforces that a value does not exceed the basis
    /// @param value value to check
    function _enforceBasis(uint32 value, uint32 basis) internal pure {
        if (value > basis) {
            revert BasisExceeded();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @dev DataTypes.sol defines the PerpetualMint struct data types used in the PerpetualMintStorage layout

/// @dev Represents data specific to a collection
struct CollectionData {
    /// @dev keeps track of mint requests which have not yet been fulfilled
    /// @dev used to implement the collection risk & collection mint multiplier update "state-machine" check
    EnumerableSet.UintSet pendingRequests;
    /// @dev price of mint attempt in ETH (native token) for a collection
    uint256 mintPrice;
    /// @dev risk of ruin for a collection
    uint32 risk;
    /// @dev mint fee distribution ratio for a collection in basis points
    uint32 mintFeeDistributionRatioBP;
    /// @dev mint consolation multiplier for a collection
    uint256 mintMultiplier;
    /// @dev collection-specific mint referral fee in basis points
    uint32 referralFeeBP;
}

/// @dev Represents the outcome of a single mint attempt.
struct MintOutcome {
    /// @dev The index of the tier in which the outcome falls under
    uint256 tierIndex;
    /// @dev The multiplier of the tier, scaled by BASIS
    uint256 tierMultiplier;
    /// @dev The risk or probability of landing in this tier, scaled by BASIS
    uint256 tierRisk;
    /// @dev The amount of $MINT to be issued if this outcome is hit, in units of wei
    uint256 mintAmount;
}

/// @dev Represents the total result of a batch mint attempt.
struct MintResultData {
    /// @dev An array containing the outcomes of each individual mint attempt
    MintOutcome[] mintOutcomes;
    /// @dev The total amount of $MINT to be issued based on all outcomes, in units of wei
    uint256 totalMintAmount;
    /// @dev The total number of successful mint attempts where a prize ticket was awarded
    uint256 totalSuccessfulMints;
}

/// @dev Represents data specific to $MINT mint for $MINT consolation tiers
struct MintTokenTiersData {
    /// @dev assumed ordered array of risks for each tier
    uint32[] tierRisks;
    /// @dev assumed ordered array of $MINT consolation multipliers for each tier
    uint256[] tierMultipliers;
}

/// @dev Represents data specific to mint requests
/// @dev Updated as a new request is made and removed when the request is fulfilled
struct RequestData {
    /// @dev address of collection for mint attempt
    address collection;
    /// @dev address of minter who made the request
    address minter;
    /// @dev adjustment factor based on the ratio of the price per mint paid to the full price per mint
    uint256 mintPriceAdjustmentFactor;
}

/// @dev Represents data specific to $MINT mint for collection consolation tiers
struct TiersData {
    /// @dev assumed ordered array of risks for each tier
    uint32[] tierRisks;
    /// @dev assumed ordered array of $MINT consolation multipliers for each tier
    uint256[] tierMultipliers;
}

/// @dev Encapsulates variables related to Chainlink VRF
/// @dev see: https://docs.chain.link/vrf/v2/subscription#set-up-your-contract-and-request
struct VRFConfig {
    /// @dev Chainlink identifier for prioritizing transactions
    /// different keyhashes have different gas prices thus different priorities
    bytes32 keyHash;
    /// @dev id of Chainlink subscription to VRF for PerpetualMint contract
    uint64 subscriptionId;
    /// @dev maximum amount of gas a user is willing to pay for completing the callback VRF function
    uint32 callbackGasLimit;
    /// @dev number of block confirmations the VRF service will wait to respond
    uint16 minConfirmations;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
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

pragma solidity ^0.8.8;

import { IERC1155Internal } from '../../../interfaces/IERC1155Internal.sol';

/**
 * @title ERC1155 base interface
 */
interface IERC1155BaseInternal is IERC1155Internal {
    error ERC1155Base__ArrayLengthMismatch();
    error ERC1155Base__BalanceQueryZeroAddress();
    error ERC1155Base__NotOwnerOrApproved();
    error ERC1155Base__SelfApproval();
    error ERC1155Base__BurnExceedsBalance();
    error ERC1155Base__BurnFromZeroAddress();
    error ERC1155Base__ERC1155ReceiverRejected();
    error ERC1155Base__ERC1155ReceiverNotImplemented();
    error ERC1155Base__MintToZeroAddress();
    error ERC1155Base__TransferExceedsBalance();
    error ERC1155Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC1155BaseStorage {
    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ERC1155MetadataExtensionStorage
library ERC1155MetadataExtensionStorage {
    struct Layout {
        string name;
        string symbol;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.ERC1155MetadataExtensionStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @dev DataTypes.sol defines the Token struct data types used in the TokenStorage layout

/// @dev represents data related to $MINT token accruals (linked to a specific account)
struct AccrualData {
    /// @dev last ratio an account had when one of their actions led to a change in the
    /// reservedSupply
    uint256 offset;
    /// @dev amount of tokens accrued as a result of distribution to token holders
    uint256 accruedTokens;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IGuardsInternal
/// @dev GuardsInternal interface holding all errors related to common guards
interface IGuardsInternal {
    /// @notice thrown when attempting to set a value larger than basis
    error BasisExceeded();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IPaymentModule } from "./IPaymentModule.sol";

interface ICrossPaymentModule {
    struct CrossPaymentSignatureInput {
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
        bytes signature;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address spender;
        uint256 destinationChainId;
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
    }

    function updateSignerAddress(address newSignerAddress) external;
    function processCrossPayment(
        IPaymentModule.ProcessPaymentInput memory paymentInput,
        address spender,
        uint256 destinationChainId
    ) external payable returns (uint256);
    function spendCrossPaymentSignature(address spender, ProcessCrossPaymentOutput memory output, bytes memory signature) external;
    function getSignerAddress() external view returns (address);
    function getCrossPaymentOutputByIndex(uint256 paymentIndex) external view returns (ProcessCrossPaymentOutput memory);
    function prefixedMessage(bytes32 hash) external pure returns (bytes32);
    function getHashedMessage(ProcessCrossPaymentOutput memory output) external pure returns (bytes32);
    function recoverSigner(bytes32 message, bytes memory signature) external pure returns (address);
    function checkSignature(ProcessCrossPaymentOutput memory output, bytes memory signature) external view;
    function getChainID() external view returns (uint256);

    /** EVENTS */
    event CrossPaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event CrossPaymentSignatureSpent(uint256 indexed previousBlock, uint256 indexed sourceChainId, uint256 indexed paymentIndex);
    event SignerAddressUpdated(address indexed oldSigner, address indexed newSigner);

    /** ERRORS */
    error ProcessCrossPaymentError(string errorMessage);
    error CheckSignatureError(string errorMessage);
    error ProcessCrossPaymentSignatureError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPaymentModule {
    enum PaymentMethod {
        NATIVE,
        USD,
        ALTCOIN
    }

    enum PaymentType {
        NATIVE,
        GIFT,
        CROSSCHAIN
    }

    struct AcceptedToken {
        string name;
        PaymentMethod tokenType;
        address token;
        address router;
        bool isV2Router;
        uint256 slippageTolerance;
    }

    struct ProcessPaymentInput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address referrer;
        address user;
        address tokenAddress;
    }

    struct ProcessPaymentOutput {
        ProcessPaymentInput processPaymentInput;
        uint256 usdPrice;
        uint256 paymentAmount;
        uint256 burnedAmount;
        uint256 treasuryShare;
        uint256 referrerShare;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address payer;
        address spender;
        uint256 sourceChainId;
        uint256 destinationChainId;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PAYMENT_PROCESSOR_ROLE() external pure returns (bytes32);
    function adminWithdraw(address tokenAddress, uint256 amount, address treasury) external;
    function setUsdToken(address newUsdToken) external;
    function setRouterAddress(address newRouter) external;
    function addAcceptedToken(AcceptedToken memory acceptedToken) external;
    function removeAcceptedToken(address tokenAddress) external;
    function updateAcceptedToken(AcceptedToken memory acceptedToken) external;
    function setV3PoolFeeForTokenNative(address token, uint24 poolFee) external;
    function getUsdToken() external view returns (address);
    function processPayment(ProcessPaymentInput memory params) external payable returns (uint256);
    function getPaymentByIndex(uint256 paymentIndex) external view returns (ProcessPaymentOutput memory);
    function getQuoteTokenPrice(address token0, address token1) external view returns (uint256 price);
    function getV3PoolFeeForTokenWithNative(address token) external view returns (uint24);
    function isV2Router() external view returns (bool);
    function getRouterAddress() external view returns (address);
    function getAcceptedTokenByAddress(address tokenAddress) external view returns (AcceptedToken memory);
    function getAcceptedTokens() external view returns (address[] memory);

    /** EVENTS */
    event TokenBurned(uint256 indexed tokenBurnedLastBlock, address indexed tokenAddress, uint256 amount);
    event PaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);

    /** ERRORS */
    error ProcessPaymentError(string errorMessage);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

import { ILaunchPadQuerier } from "../interfaces/ILaunchPadQuerier.sol";
import { LibLaunchPadFactoryStorage } from "../libraries/LibLaunchPadFactoryStorage.sol";
import { LibLaunchPadConsts } from "../libraries/LibLaunchPadConsts.sol";

contract LaunchPadQuerierFacet is ILaunchPadQuerier {
    function LAUNCHPAD_PRODUCT_ID() external pure override returns (bytes32) {
        return LibLaunchPadConsts.PRODUCT_ID;
    }

    function getLaunchPadsPaginated(uint256 quantity, uint256 page) external view override returns (address[] memory) {
        require(quantity > 0, "LaunchPad: quantity must be greater than 0");
        require(page > 0, "LaunchPad: page must be greater than 0");

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        uint256 offset = quantity * (page - 1);
        uint256 size = quantity;
        if (offset + size > ds.launchPads.length) {
            size = ds.launchPads.length - offset;
        }
        address[] memory launchPads = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            launchPads[i] = ds.launchPads[offset + i];
        }
        return launchPads;
    }

    function getLaunchPadsCount() external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        return ds.launchPads.length;
    }

    function getLaunchPadsByInvestorPaginated(address investor, uint256 quantity, uint256 page) external view override returns (address[] memory) {
        require(quantity > 0, "LaunchPad: quantity must be greater than 0");
        require(page > 0, "LaunchPad: page must be greater than 0");

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        uint256 offset = quantity * (page - 1);
        uint256 size = quantity;
        if (offset + size > ds.launchPadsByInvestor[investor].length) {
            size = ds.launchPadsByInvestor[investor].length - offset;
        }
        address[] memory launchPads = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            launchPads[i] = ds.launchPadsByInvestor[investor][offset + i];
        }
        return launchPads;
    }

    function getLaunchPadsByInvestorCount() external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        return ds.launchPadsByInvestor[msg.sender].length;
    }

    function getLaunchPadCountByOwner(address owner) external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        return ds.launchPadsByOwner[owner].length;
    }

    function getLaunchPadsByOwnerPaginated(address owner, uint256 quantity, uint256 page) external view override returns (address[] memory) {
        require(quantity > 0, "LaunchPad: quantity must be greater than 0");
        require(page > 0, "LaunchPad: page must be greater than 0");

        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        uint256 offset = quantity * (page - 1);
        uint256 size = quantity;
        if (offset + size > ds.launchPadsByOwner[owner].length) {
            size = ds.launchPadsByOwner[owner].length - offset;
        }
        address[] memory launchPads = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            launchPads[i] = ds.launchPadsByOwner[owner][offset + i];
        }
        return launchPads;
    }

    function getMaxTokenCreationDeadline() external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        return ds.maxTokenCreationDeadline;
    }

    function getSignerAddress() external view override returns (address) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        return ds.signerAddress;
    }

    function getSuperChargerHeadstarts() external view override returns (uint256[] memory) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.superChargerHeadstartByTier;
    }

    function getSuperChargerHeadstartByTier(uint256 tier) external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.superChargerHeadstartByTier[tier - 1];
    }

    function getSuperChargerMultiplierByTier(uint256 tier) external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.superChargerMultiplierByTier[tier - 1];
    }

    function getSuperChargerTokensPercByTier(uint256 tier) external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.superChargerTokensPercByTier[tier - 1];
    }

    function getLaunchPadTokenInfo(address launchPadAddress) external view override returns (CreateErc20Input memory createErc20Input) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.tokenInfoByLaunchPadAddress[launchPadAddress];
    }

    function getLaunchPadMaxDurationIncrement() external view override returns (uint256) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();
        return ds.maxDurationIncrement;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
    }

    struct IdoInfo {
        bool enabled;
        address dexRouter;
        address pairToken;
        uint256 price;
        uint256 amountToList;
    }

    struct RefundInfo {
        uint256 penaltyFeePercent;
        uint256 expireDuration;
    }

    struct FundTarget {
        uint256 softCap;
        uint256 hardCap;
    }

    struct ReleaseSchedule {
        uint256 timestamp;
        uint256 percent;
    }

    struct ReleaseScheduleV2 {
        uint256 timestamp;
        uint256 percent;
        bool isVesting;
    }

    struct CreateErc20Input {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 maxSupply;
        address owner;
        uint256 treasuryReserved;
    }

    struct LaunchPadInfo {
        address owner;
        address tokenAddress;
        address paymentTokenAddress;
        uint256 price;
        FundTarget fundTarget;
        uint256 maxInvestPerWallet;
        uint256 startTimestamp;
        uint256 duration;
        uint256 tokenCreationDeadline;
        RefundInfo refundInfo;
        IdoInfo idoInfo;
    }

    struct CreateLaunchPadInput {
        LaunchPadType launchPadType;
        LaunchPadInfo launchPadInfo;
        ReleaseScheduleV2[] releaseSchedule;
        CreateErc20Input createErc20Input;
        address referrer;
        bool isSuperchargerEnabled;
        uint256 feePercentage;
        address paymentTokenAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { ICrossPaymentModule } from "../../common/admin/interfaces/ICrossPaymentModule.sol";

interface ILaunchPadFactory {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
    }

    function addInvestorToLaunchPad(address investor) external;
    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;
    function createLaunchPadWithPaymentSignature(
        ILaunchPadCommon.CreateLaunchPadInput memory storeInput,
        ICrossPaymentModule.CrossPaymentSignatureInput memory crossPaymentSignatureInput
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProject {
    struct PurchasedInfo {
        uint256 purchasedTokenAmount;
        uint256 claimedTokenAmount;
        uint256 paidTokenAmount;
    }

    struct BuyTokenInput {
        uint256 tokenAmount;
        uint256 tier;
        uint256 nonce;
        uint256 deadline;
        bytes signature;
    }

    function buyTokens(uint256 tokenAmount) external payable;

    function buyTokensWithSupercharger(BuyTokenInput memory input) external payable;

    function checkSignature(address wallet, uint256 tier, uint256 nonce, uint256 deadline, bytes memory signature) external view;

    function claimTokens() external;

    function getAllInvestors() external view returns (address[] memory);

    function getCurrentTier() external view returns (uint256);

    function getFeeShare() external view returns (uint256);

    function getHardCapPerTier(uint256 tier) external view returns (uint256);

    function getInvestorAddressByIndex(uint256 index) external view returns (address);

    function getInvestorsLength() external view returns (uint256);

    function getLaunchPadAddress() external view returns (address);

    function getLaunchPadInfo() external view returns (ILaunchPadCommon.LaunchPadInfo memory);

    function getMaxInvestPerWalletPerTier(uint256 tier) external view returns (uint256);

    function getNextNonce(address user) external view returns (uint256);

    function getProjectOwnerRole() external view returns (bytes32);

    function getPurchasedInfoByUser(address user) external view returns (PurchasedInfo memory);

    function getReleasedTokensPercentage() external view returns (uint256);

    function getReleaseSchedule() external view returns (ILaunchPadCommon.ReleaseScheduleV2[] memory);

    function getTokensAvailableToBeClaimed(address user) external view returns (uint256);

    function getTokenCreationDeadline() external view returns (uint256);

    function getTotalRaised() external view returns (uint256);

    function isSuperchargerEnabled() external view returns (bool);

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadProjectAdmin {
    function setSupercharger(bool isSuperchargerEnabled) external;

    function updateStartTimestamp(uint256 newStartTimestamp) external;

    function extendDuration(uint256 durationIncrease) external;

    function updateReleaseSchedule(ILaunchPadCommon.ReleaseScheduleV2[] memory releaseSchedule) external;

    function setTokenAddress(address tokenAddress) external;

    function withdrawFees() external;

    function withdrawTokens(address tokenAddress) external;

    function withdrawTokensToRecipient(address tokenAddress, address recipient) external;

    /** ERRORS */
    error UPDATE_RELEASE_SCHEDULE_ERROR(string errorMessage);
    error UPDATE_START_TIMESTAMP_ERROR(string errorMessage);
    error EXTEND_DURATION_ERROR(string errorMessage);
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadQuerier is ILaunchPadCommon {
    function LAUNCHPAD_PRODUCT_ID() external pure returns (bytes32);

    function getLaunchPadsPaginated(uint256 quantity, uint256 page) external view returns (address[] memory);

    function getLaunchPadsCount() external view returns (uint256);

    function getLaunchPadsByInvestorPaginated(address investor, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getLaunchPadsByInvestorCount() external view returns (uint256);

    function getLaunchPadCountByOwner(address owner) external view returns (uint256);

    function getLaunchPadsByOwnerPaginated(address owner, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getMaxTokenCreationDeadline() external view returns (uint256);

    function getSignerAddress() external view returns (address);

    function getSuperChargerHeadstartByTier(uint256 tier) external view returns (uint256);

    function getSuperChargerHeadstarts() external view returns (uint256[] memory);

    function getSuperChargerMultiplierByTier(uint256 tier) external view returns (uint256);

    function getSuperChargerTokensPercByTier(uint256 tier) external view returns (uint256);

    function getLaunchPadTokenInfo(address launchPadAddress) external view returns (CreateErc20Input memory createErc20Input);

    function getLaunchPadMaxDurationIncrement() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibLaunchPadConsts {
    bytes32 internal constant PRODUCT_ID = keccak256("tokenfi.launchpad");
    uint256 internal constant BURN_BASIS_POINTS = 5_000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";
import { ILaunchPadProjectAdmin } from "../interfaces/ILaunchPadProjectAdmin.sol";

library LibLaunchPadFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.factory.diamond.storage");

    struct DiamondStorage {
        address[] launchPads;
        mapping(address => address[]) launchPadsByOwner;
        mapping(address => address[]) launchPadsByInvestor;
        mapping(address => address) launchPadOwner;
        mapping(address => bool) isLaunchPad;
        mapping(address => ILaunchPadCommon.CreateErc20Input) tokenInfoByLaunchPadAddress;
        uint256 currentBlockLaunchPadCreated;
        uint256 currentBlockLaunchPadOwnerUpdated;
        address _tokenLauncherERC20; // deprecated (available on Diamond itself)
        address _tokenLauncherStore; // deprecated (available on Diamond itself)
        address _tokenLauncherBuybackHandler; // deprecated (available on Diamond itself)
        address launchPadProjectFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address launchPadProjectDiamondInit;
        address _tokenfiToken; // deprecated (available on LaunchPadPaymentStorage)
        address _usdToken; // deprecated (available on LaunchPadPaymentStorage)
        address _router; // deprecated (available on LaunchPadPaymentStorage)
        address _treasury; // deprecated (available on LaunchPadPaymentStorage)
        address signerAddress;
        uint256 maxTokenCreationDeadline;
        uint256[] _superChargerMultiplierByTier; // deprecated (cause of wrong updates by v1)
        uint256[] _superChargerHeadstartByTier; // deprecated (cause of wrong updates by v1)
        uint256[] _superChargerTokensPercByTier; // deprecated (cause of wrong updates by v1)
        uint256 maxDurationIncrement;
        address launchPadProjectAdminFacet;
        address launchPadImplementation;
        uint256[] superChargerMultiplierByTier;
        uint256[] superChargerHeadstartByTier;
        uint256[] superChargerTokensPercByTier;
    }

    event LaunchPadCreated(uint256 indexed previousBlock, ILaunchPadFactory.StoreLaunchPadInput launchPad);
    event LaunchPadOwnerUpdated(uint256 indexed previousBlock, address owner, address newOwner);
    event MaxTokenCreationDeadlineUpdated(uint256 indexed previousMaxTokenCreationDeadline, uint256 newMaxTokenCreationDeadline);
    event LaunchpadRemoved(address indexed launchPadAddress, address indexed owner);
    event SignerAddressUpdated(address indexed previousSignerAddress, address indexed newSignerAddress);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    function getLaunchPadProjectSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](29);
        functionSelectors[0] = ILaunchPadProject.buyTokens.selector;
        functionSelectors[1] = ILaunchPadProject.buyTokensWithSupercharger.selector;
        functionSelectors[2] = ILaunchPadProject.checkSignature.selector;
        functionSelectors[3] = ILaunchPadProject.claimTokens.selector;
        functionSelectors[4] = ILaunchPadProject.getAllInvestors.selector;
        functionSelectors[5] = ILaunchPadProject.getCurrentTier.selector;
        functionSelectors[6] = ILaunchPadProject.getFeeShare.selector;
        functionSelectors[7] = ILaunchPadProject.getHardCapPerTier.selector;
        functionSelectors[8] = ILaunchPadProject.getInvestorAddressByIndex.selector;
        functionSelectors[9] = ILaunchPadProject.getInvestorsLength.selector;
        functionSelectors[10] = ILaunchPadProject.getLaunchPadAddress.selector;
        functionSelectors[11] = ILaunchPadProject.getLaunchPadInfo.selector;
        functionSelectors[12] = ILaunchPadProject.getMaxInvestPerWalletPerTier.selector;
        functionSelectors[13] = ILaunchPadProject.getNextNonce.selector;
        functionSelectors[14] = ILaunchPadProject.getProjectOwnerRole.selector;
        functionSelectors[15] = ILaunchPadProject.getPurchasedInfoByUser.selector;
        functionSelectors[16] = ILaunchPadProject.getReleasedTokensPercentage.selector;
        functionSelectors[17] = ILaunchPadProject.getReleaseSchedule.selector;
        functionSelectors[18] = ILaunchPadProject.getTokensAvailableToBeClaimed.selector;
        functionSelectors[19] = ILaunchPadProject.getTokenCreationDeadline.selector;
        functionSelectors[20] = ILaunchPadProject.getTotalRaised.selector;
        functionSelectors[21] = ILaunchPadProject.isSuperchargerEnabled.selector;
        functionSelectors[22] = ILaunchPadProject.recoverSigner.selector;
        functionSelectors[23] = ILaunchPadProject.refund.selector;
        functionSelectors[24] = ILaunchPadProject.refundOnSoftCapFailure.selector;
        functionSelectors[25] = ILaunchPadProject.refundOnTokenCreationExpired.selector;
        functionSelectors[26] = ILaunchPadProject.tokenDecimals.selector;
        functionSelectors[27] = ILaunchPadProject.totalTokensClaimed.selector;
        functionSelectors[28] = ILaunchPadProject.totalTokensSold.selector;

        return functionSelectors;
    }

    function getLaunchPadProjectAdminSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = ILaunchPadProjectAdmin.setSupercharger.selector;
        functionSelectors[1] = ILaunchPadProjectAdmin.setTokenAddress.selector;
        functionSelectors[2] = ILaunchPadProjectAdmin.withdrawFees.selector;
        functionSelectors[3] = ILaunchPadProjectAdmin.withdrawTokens.selector;
        functionSelectors[4] = ILaunchPadProjectAdmin.withdrawTokensToRecipient.selector;
        functionSelectors[5] = ILaunchPadProjectAdmin.updateStartTimestamp.selector;
        functionSelectors[6] = ILaunchPadProjectAdmin.extendDuration.selector;
        functionSelectors[7] = ILaunchPadProjectAdmin.updateReleaseSchedule.selector;

        return functionSelectors;
    }
}
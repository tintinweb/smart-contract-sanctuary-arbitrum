// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
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
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

import { ILaunchPadQuerier } from "../interfaces/ILaunchPadQuerier.sol";
import { LibLaunchPadFactoryStorage } from "../libraries/LaunchPadFactoryStorage.sol";
import { LibLaunchPadConsts } from "../libraries/LaunchPadConsts.sol";

contract LaunchPadQuerierFacet is ILaunchPadQuerier {
    function LAUNCHPAD_PRODUCT_ID() public pure returns (bytes32) {
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

    function tokenLauncherERC20() external view override returns (address) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.tokenLauncherERC20;
    }

    function launchPadTokenInfo(address launchPadAddress) external view override returns (CreateErc20Input memory createErc20Input) {
        LibLaunchPadFactoryStorage.DiamondStorage storage ds = LibLaunchPadFactoryStorage.diamondStorage();

        return ds.tokenInfoByLaunchPadAddress[launchPadAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ILaunchPadCommon {
    enum LaunchPadType {
        FlokiPadCreatedBefore,
        FlokiPadCreatedAfter
    }

    enum PaymentMethod {
        NATIVE,
        USD,
        TOKENFI
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
        PaymentMethod paymentMethod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";
import { IDiamondCut } from "../../common/diamonds/interfaces/IDiamondCut.sol";

interface ILaunchPadFactory is ILaunchPadCommon {
    struct StoreLaunchPadInput {
        ILaunchPadCommon.LaunchPadType launchPadType;
        address launchPadAddress;
        address owner;
        address referrer;
        uint256 usdPrice;
    }

    function addInvestorToLaunchPad(address investor) external;

    function createLaunchPad(ILaunchPadCommon.CreateLaunchPadInput memory input) external payable;

    function createTokenAfterICO(address launchPadAddress) external payable;

    function setExistingTokenAfterICO(address launchPad, address tokenAddress, uint256 amount) external;

    function setExistingTokenAfterTransfer(address launchPad, address tokenAddress) external;

    function createV2LiquidityPool(address launchPadAddress) external payable;

    function updateLaunchPadOwner(address tokenAddress, address newOwner) external;
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

    function recoverSigner(bytes32 message, bytes memory signature) external view returns (address);

    function refund(uint256 tokenAmount) external;

    function refundOnSoftCapFailure() external;

    function refundOnTokenCreationExpired(uint256 tokenAmount) external;

    function setTokenAddress(address tokenAddress) external;

    function tokenDecimals() external view returns (uint256);

    function totalTokensClaimed() external view returns (uint256);

    function totalTokensSold() external view returns (uint256);

    function withdrawFees() external;

    function withdrawTokens(address tokenAddress) external;

    function withdrawTokensToRecipient(address tokenAddress, address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "./ILaunchPadCommon.sol";

interface ILaunchPadQuerier is ILaunchPadCommon {
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

    function launchPadTokenInfo(address launchPadAddress) external view returns (CreateErc20Input memory createErc20Input);

    function tokenLauncherERC20() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibLaunchPadConsts {
    bytes32 internal constant PRODUCT_ID = keccak256("tokenfi.launchpad");
    uint256 internal constant BASIS_POINTS = 10_000;
    uint256 internal constant REFERRER_BASIS_POINTS = 2_500;
    uint256 internal constant BURN_BASIS_POINTS = 5_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ILaunchPadCommon } from "../interfaces/ILaunchPadCommon.sol";
import { ILaunchPadFactory } from "../interfaces/ILaunchPadFactory.sol";
import { ILaunchPadProject } from "../interfaces/ILaunchPadProject.sol";

library LibLaunchPadFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.launchpad.factory.diamond.storage");

    struct DiamondStorage {
        address[] launchPads;
        mapping(address => address[]) launchPadsByOwner;
        mapping(address => address[]) launchPadsByInvestor;
        mapping(address => address) launchPadOwner;
        mapping(address => bool) isLaunchPad;
        mapping(address => ILaunchPadFactory.CreateErc20Input) tokenInfoByLaunchPadAddress;
        uint256 currentBlockLaunchPadCreated;
        uint256 currentBlockLaunchPadOwnerUpdated;
        address tokenLauncherERC20;
        address tokenLauncherStore;
        address tokenLauncherBuybackHandler;
        address launchPadProjectFacet;
        address accessControlFacet;
        address pausableFacet;
        address loupeFacet;
        address proxyFacet;
        address launchPadProjectDiamondInit;
        address signerAddress;
        uint256 maxTokenCreationDeadline;
        uint256[] superChargerMultiplierByTier;
        uint256[] superChargerHeadstartByTier;
        uint256[] superChargerTokensPercByTier;
    }

    event LaunchPadCreated(
        uint256 indexed previousBlock,
        ILaunchPadCommon.LaunchPadType indexed launchPadType,
        address indexed owner,
        ILaunchPadFactory.StoreLaunchPadInput launchPad
    );
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
        bytes4[] memory functionSelectors = new bytes4[](31);
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
        functionSelectors[13] = ILaunchPadProject.getProjectOwnerRole.selector;
        functionSelectors[14] = ILaunchPadProject.getPurchasedInfoByUser.selector;
        functionSelectors[15] = ILaunchPadProject.getReleasedTokensPercentage.selector;
        functionSelectors[16] = ILaunchPadProject.getReleaseSchedule.selector;
        functionSelectors[17] = ILaunchPadProject.getTokensAvailableToBeClaimed.selector;
        functionSelectors[18] = ILaunchPadProject.getTokenCreationDeadline.selector;
        functionSelectors[19] = ILaunchPadProject.getTotalRaised.selector;
        functionSelectors[20] = ILaunchPadProject.recoverSigner.selector;
        functionSelectors[21] = ILaunchPadProject.refund.selector;
        functionSelectors[22] = ILaunchPadProject.refundOnSoftCapFailure.selector;
        functionSelectors[23] = ILaunchPadProject.refundOnTokenCreationExpired.selector;
        functionSelectors[24] = ILaunchPadProject.setTokenAddress.selector;
        functionSelectors[25] = ILaunchPadProject.tokenDecimals.selector;
        functionSelectors[26] = ILaunchPadProject.totalTokensClaimed.selector;
        functionSelectors[27] = ILaunchPadProject.totalTokensSold.selector;
        functionSelectors[28] = ILaunchPadProject.withdrawFees.selector;
        functionSelectors[29] = ILaunchPadProject.withdrawTokens.selector;
        functionSelectors[30] = ILaunchPadProject.withdrawTokensToRecipient.selector;

        return functionSelectors;
    }
}
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

library BinaryVaultDataType {
    struct WithdrawalRequest {
        uint256 tokenId; // nft id
        uint256 shareAmount; // share amount
        uint256 underlyingTokenAmount; // underlying token amount
        uint256 timestamp; // request block time
        uint256 minExpectAmount; // Minimum underlying amount which user will receive
        uint256 fee;
    }

    struct BetData {
        uint256 bullAmount;
        uint256 bearAmount;
    }

    struct WhitelistedMarket {
        bool whitelisted;
        uint256 exposureBips; // % 10_000 based value. 100% => 10_000
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {IBinaryConfig} from "../../../interfaces/binary/IBinaryConfig.sol";
import {IBinaryVaultBaseFacet} from "../../../interfaces/binary/IBinaryVaultBaseFacet.sol";
import {IBinaryVaultPluginImpl} from "../../../interfaces/binary/IBinaryVaultPluginImpl.sol";
import {BinaryVaultDataType} from "../BinaryVaultDataType.sol";

library BinaryVaultFacetStorage {
    struct Layout {
        IBinaryConfig config;
        address underlyingTokenAddress;
        /// @notice Whitelisted markets, only whitelisted markets can take money out from the vault.
        mapping(address => BinaryVaultDataType.WhitelistedMarket) whitelistedMarkets;
        /// @notice share balances (token id => share balance)
        mapping(uint256 => uint256) shareBalances;
        /// @notice initial investment (tokenId => initial underlying token balance)
        mapping(uint256 => uint256) initialInvestments;
        /// @notice latest balance (token id => underlying token)
        /// @dev This should be updated when user deposits/withdraw or when take monthly management fee
        mapping(uint256 => uint256) recentSnapshots;
        // For risk management
        mapping(uint256 => BinaryVaultDataType.BetData) betData;
        // token id => request
        mapping(uint256 => BinaryVaultDataType.WithdrawalRequest) withdrawalRequests;
        mapping(address => bool) whitelistedUser;
        uint256 totalShareSupply;
        /// @notice TVL of vault. This should be updated when deposit(+), withdraw(-), trader lose (+), trader win (-), trading fees(+)
        uint256 totalDepositedAmount;
        /// @notice Watermark for risk management. This should be updated when deposit(+), withdraw(-), trading fees(+). If watermark < TVL, then set watermark = tvl
        uint256 watermark;
        // @notice Current pending withdrawal share amount. Plus when new withdrawal request, minus when cancel or execute withdraw.
        uint256 pendingWithdrawalTokenAmount;
        uint256 pendingWithdrawalShareAmount;
        uint256 withdrawalDelayTime;
        /// @dev The interval during which the maximum bet amount changes
        uint256 lastTimestampForExposure;
        uint256 currentHourlyExposureAmount;
        bool pauseNewDeposit;
        bool useWhitelist;
        // prevent to call initialize function twice
        bool initialized;

        // For credit
        address creditToken;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("balancecapital.ryze.storage.BinaryVaultFacet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

interface IVaultDiamond {
    function owner() external view returns (address);
}

contract BinaryVaultBaseFacet is IBinaryVaultBaseFacet, IBinaryVaultPluginImpl {
    uint256 private constant MAX_DELAY = 1 weeks;

    event ConfigChanged(address indexed config);
    event WhitelistMarketChanged(address indexed market, bool enabled);

    modifier onlyMarket() {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(s.whitelistedMarkets[msg.sender].whitelisted, "ONLY_MARKET");
        _;
    }

    modifier onlyOwner() {
        require(
            IVaultDiamond(address(this)).owner() == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function initialize(
        address underlyingToken_,
        address config_,
        address creditToken_
    ) external onlyOwner {
        require(underlyingToken_ != address(0), "ZERO_ADDRESS");
        require(config_ != address(0), "ZERO_ADDRESS");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.underlyingTokenAddress = underlyingToken_;
        s.config = IBinaryConfig(config_);
        s.withdrawalDelayTime = 24 hours;
        s.creditToken = creditToken_;

        emit ConfigChanged(config_);
    }

    /// @notice Whitelist market on the vault
    /// @dev Only owner can call this function
    /// @param market Market contract address
    /// @param whitelist Whitelist or Blacklist
    /// @param exposureBips Exposure percent based 10_000. So 100% is 10_000
    function setWhitelistMarket(
        address market,
        bool whitelist,
        uint256 exposureBips
    ) external virtual onlyOwner {
        require(market != address(0), "ZERO_ADDRESS");

        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        require(exposureBips <= s.config.FEE_BASE(), "INVALID_BIPS");

        s.whitelistedMarkets[market].whitelisted = whitelist;
        s.whitelistedMarkets[market].exposureBips = exposureBips;

        emit WhitelistMarketChanged(market, whitelist);
    }

    /// @dev set config
    function setConfig(address _config) external virtual onlyOwner {
        require(_config != address(0), "ZERO_ADDRESS");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.config = IBinaryConfig(_config);

        emit ConfigChanged(_config);
    }

    function enableUseWhitelist(bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.useWhitelist != value, "ALREADY_SET");
        s.useWhitelist = value;
    }

    function enablePauseDeposit(bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.pauseNewDeposit != value, "ALREADY_SET");
        s.pauseNewDeposit = value;
    }

    function setWhitelistUser(address user, bool value) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();
        require(s.whitelistedUser[user] != value, "ALREADY_SET");
        s.whitelistedUser[user] = value;
    }

    /// @notice Set withdrawal delay time
    /// @param _time time in seconds
    function setWithdrawalDelayTime(uint256 _time) external virtual onlyOwner {
        require(_time <= MAX_DELAY, "INVALID_TIME");
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage
            .layout();

        s.withdrawalDelayTime = _time;
    }

    // getter functions
    function config() external view returns (address) {
        return address(BinaryVaultFacetStorage.layout().config);
    }

    function underlyingTokenAddress() external view returns (address) {
        return BinaryVaultFacetStorage.layout().underlyingTokenAddress;
    }

    function whitelistMarkets(
        address market
    ) external view returns (bool, uint256) {
        return (
            BinaryVaultFacetStorage
                .layout()
                .whitelistedMarkets[market]
                .whitelisted,
            BinaryVaultFacetStorage
                .layout()
                .whitelistedMarkets[market]
                .exposureBips
        );
    }

    function totalShareSupply() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().totalShareSupply;
    }

    function totalDepositedAmount() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().totalDepositedAmount;
    }

    function watermark() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().watermark;
    }

    function isWhitelistedUser(address user) external view returns (bool) {
        return BinaryVaultFacetStorage.layout().whitelistedUser[user];
    }

    function isUseWhitelistAndIsDepositPaused()
        external
        view
        returns (bool, bool)
    {
        return (
            BinaryVaultFacetStorage.layout().useWhitelist,
            BinaryVaultFacetStorage.layout().pauseNewDeposit
        );
    }

    function shareBalances(uint256 tokenId) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().shareBalances[tokenId];
    }

    function initialInvestments(
        uint256 tokenId
    ) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().initialInvestments[tokenId];
    }

    function recentSnapshots(uint256 tokenId) external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().recentSnapshots[tokenId];
    }

    function withdrawalRequests(
        uint256 tokenId
    ) external view returns (BinaryVaultDataType.WithdrawalRequest memory) {
        return BinaryVaultFacetStorage.layout().withdrawalRequests[tokenId];
    }

    function pendingWithdrawalAmount()
        external
        view
        returns (uint256, uint256)
    {
        return (
            BinaryVaultFacetStorage.layout().pendingWithdrawalTokenAmount,
            BinaryVaultFacetStorage.layout().pendingWithdrawalShareAmount
        );
    }

    function withdrawalDelayTime() external view returns (uint256) {
        return BinaryVaultFacetStorage.layout().withdrawalDelayTime;
    }

    function setCreditToken(address _token) external onlyOwner {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage.layout();
        s.creditToken = _token;
    }

    function getCreditToken() external view returns (address) {
        BinaryVaultFacetStorage.Layout storage s = BinaryVaultFacetStorage.layout();
        return s.creditToken;
    }

    function pluginSelectors() private pure returns (bytes4[] memory s) {
        s = new bytes4[](22);
        s[0] = BinaryVaultBaseFacet.setWhitelistMarket.selector;
        s[1] = BinaryVaultBaseFacet.setConfig.selector;
        s[2] = BinaryVaultBaseFacet.enableUseWhitelist.selector;
        s[3] = BinaryVaultBaseFacet.enablePauseDeposit.selector;
        s[4] = BinaryVaultBaseFacet.setWhitelistUser.selector;
        s[5] = BinaryVaultBaseFacet.setWithdrawalDelayTime.selector;
        s[6] = BinaryVaultBaseFacet.config.selector;
        s[7] = BinaryVaultBaseFacet.underlyingTokenAddress.selector;
        s[8] = BinaryVaultBaseFacet.whitelistMarkets.selector;
        s[9] = BinaryVaultBaseFacet.totalShareSupply.selector;
        s[10] = BinaryVaultBaseFacet.totalDepositedAmount.selector;
        s[11] = BinaryVaultBaseFacet.watermark.selector;
        s[12] = BinaryVaultBaseFacet.isWhitelistedUser.selector;
        s[13] = BinaryVaultBaseFacet.isUseWhitelistAndIsDepositPaused.selector;
        s[14] = BinaryVaultBaseFacet.shareBalances.selector;
        s[15] = BinaryVaultBaseFacet.initialInvestments.selector;
        s[16] = BinaryVaultBaseFacet.recentSnapshots.selector;
        s[17] = BinaryVaultBaseFacet.withdrawalRequests.selector;
        s[18] = BinaryVaultBaseFacet.pendingWithdrawalAmount.selector;
        s[19] = BinaryVaultBaseFacet.withdrawalDelayTime.selector;
        s[20] = BinaryVaultBaseFacet.setCreditToken.selector;
        s[21] = BinaryVaultBaseFacet.getCreditToken.selector;
    }

    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId)
    {
        selectors = pluginSelectors();
        interfaceId = type(IBinaryVaultBaseFacet).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryConfig {
    // solhint-disable-next-line
    function FEE_BASE() external view returns (uint256);

    function treasury() external view returns (address);

    function treasuryForReferrals() external view returns (address);

    function tradingFee() external view returns (uint256);

    function treasuryBips() external view returns (uint256);

    function maxVaultRiskBips() external view returns (uint256);

    function maxHourlyExposure() external view returns (uint256);

    function maxWithdrawalBipsForFutureBettingAvailable()
        external
        view
        returns (uint256);

    function binaryVaultImageTemplate() external view returns (string memory);

    function tokenLogo(address _token) external view returns (string memory);

    function vaultDescription() external view returns (string memory);

    function futureBettingTimeUpTo() external view returns (uint256);

    function bettingAmountBips() external view returns (uint256);

    function intervalForExposureUpdate() external view returns (uint256);

    function multiplier() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {BinaryVaultDataType} from "../../binary/vault/BinaryVaultDataType.sol";

interface IBinaryVaultBaseFacet {
    function whitelistMarkets(
        address market
    ) external view returns (bool, uint256);

    function setWhitelistMarket(
        address market,
        bool whitelist,
        uint256 exposureBips
    ) external;

    function totalShareSupply() external view returns (uint256);

    function totalDepositedAmount() external view returns (uint256);
    function setWhitelistUser(address user, bool value) external;
    function enableUseWhitelist(bool value) external;
    function setCreditToken(address) external;
    function underlyingTokenAddress() external view returns(address);
    function getCreditToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBinaryVaultPluginImpl {
    function pluginMetadata()
        external
        pure
        returns (bytes4[] memory selectors, bytes4 interfaceId);
}
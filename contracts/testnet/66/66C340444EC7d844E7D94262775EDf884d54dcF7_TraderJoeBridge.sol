// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal references
import "./AddressResolver.sol";

contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
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

    modifier onlyOwner() {
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
import "../../interfaces/IERC20.sol";
import "../../MixinResolver.sol";
import "../../Owned.sol";
// Internal references
import "../../interfaces/ISynth.sol";
import "../../interfaces/ISystemStatus.sol";
import "../../interfaces/IIssuer.sol";
import "../../interfaces/ISynthrSwapWithDex.sol";
import "../../interfaces/ILBFactory.sol";
import "../../interfaces/ILBPair.sol";
import "../../interfaces/ILBRouter.sol";
import "../../libraries/TransferHelper.sol";

contract TraderJoeBridge is MixinResolver, Owned {
    bytes32 public constant CONTRACT_NAME = "DexBridge";

    bytes32 public immutable nativeSynthKey;
    bytes32 public immutable nativeKey;
    address public wrappedNative;
    address public swapRouter;
    address public lbFactory;

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_SYNTHR_SWAP = "SynthrSwapWithDex";

    event DexSwapSynthToNative(
        address indexed _account,
        bytes32 indexed _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 indexed _destNativeKey,
        uint256 _destNativeAmount
    );
    event DexSwapNativeToSynth(
        address indexed _account,
        bytes32 indexed _destNativeKey,
        uint256 _destNativeAmount,
        bytes32 indexed _sourceSynthKey,
        uint256 _sourceSynthAmount
    );
    event OwnerWithdraw(address indexed _to, address indexed _currency, uint256 _amount);

    constructor(
        address _owner,
        address _resolver,
        address _factory,
        address _swapRouter,
        address _wrappedNative,
        bytes32 _nativeSynth,
        bytes32 _nativeKey
    ) MixinResolver(_resolver) Owned(_owner) {
        nativeSynthKey = _nativeSynth;
        wrappedNative = _wrappedNative;
        swapRouter = _swapRouter;
        lbFactory = _factory;
        nativeKey = _nativeKey;
    }

    // ========== VIEWS ==========

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public pure override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_ISSUER;
        addresses[2] = CONTRACT_SYNTHR_SWAP;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function synthrSwap() internal view returns (ISynthrSwapWithDex) {
        return ISynthrSwapWithDex(requireAndGetAddress(CONTRACT_SYNTHR_SWAP));
    }

    function getNativeOutFromSynth(uint256 _sourceSynthAmount) external view returns (uint256) {
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(address(issuer().synths(nativeSynthKey)));
        tokenPath[1] = IERC20(wrappedNative);

        ILBFactory.LBPairInformation[] memory lbPairs = ILBFactory(lbFactory).getAllLBPairs(tokenPath[0], tokenPath[1]);

        uint256 amountOutMin;
        for (uint256 ii = 0; ii < lbPairs.length; ii++) {
            (, uint128 amountOut, ) = ILBRouter(swapRouter).getSwapOut(lbPairs[ii].LBPair, uint128(_sourceSynthAmount), true);
            if (amountOut > amountOutMin) {
                amountOutMin = amountOut;
            }
        }
        return amountOutMin;
    }

    function getSynthOutFromNative(uint256 _sourceNativeAmount) external view returns (uint256) {
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(wrappedNative);
        tokenPath[1] = IERC20(address(issuer().synths(nativeSynthKey)));

        ILBFactory.LBPairInformation[] memory lbPairs = ILBFactory(lbFactory).getAllLBPairs(tokenPath[0], tokenPath[1]);

        uint256 amountOutMin;
        for (uint256 ii = 0; ii < lbPairs.length; ii++) {
            (, uint128 amountOut, ) = ILBRouter(swapRouter).getSwapOut(lbPairs[ii].LBPair, uint128(_sourceNativeAmount), true);
            if (amountOut > amountOutMin) {
                amountOutMin = amountOut;
            }
        }

        return amountOutMin;
    }

    function getNativeInForSynth(uint256 _destSynthAmount) external view returns (uint256) {
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(wrappedNative);
        tokenPath[1] = IERC20(address(issuer().synths(nativeSynthKey)));

        ILBFactory.LBPairInformation[] memory lbPairs = ILBFactory(lbFactory).getAllLBPairs(tokenPath[0], tokenPath[1]);

        uint256 amountInMax;
        for (uint256 ii = 0; ii < lbPairs.length; ii++) {
            (uint128 amountIn, , ) = ILBRouter(swapRouter).getSwapIn(lbPairs[ii].LBPair, uint128(_destSynthAmount), true);
            if (amountIn > amountInMax) {
                amountInMax = amountIn;
            }
        }
        return amountInMax;
    }

    function getSynthInForNative(uint256 _destNativeAmount) external view returns (uint256) {
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(address(issuer().synths(nativeSynthKey)));
        tokenPath[1] = IERC20(wrappedNative);

        ILBFactory.LBPairInformation[] memory lbPairs = ILBFactory(lbFactory).getAllLBPairs(tokenPath[0], tokenPath[1]);

        uint256 amountInMax;
        for (uint256 ii = 0; ii < lbPairs.length; ii++) {
            (uint128 amountIn, , ) = ILBRouter(swapRouter).getSwapIn(lbPairs[ii].LBPair, uint128(_destNativeAmount), true);
            if (amountIn > amountInMax) {
                amountInMax = amountIn;
            }
        }

        return amountInMax;
    }

    // ========== MUTATIVE ==========
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "SwapRouter can't be zero address.");
        swapRouter = _router;
    }

    function setWrappedNative(address _wrappedNative) external onlyOwner {
        require(_wrappedNative != address(0), "WrappedNative can't be zero address.");
        wrappedNative = _wrappedNative;
    }

    function swapSynthToNative(address _account, uint256 _sourceSynthAmount)
        external
        systemActive
        onlySynthrSwap
        returns (uint256)
    {
        require(
            issuer().synths(nativeSynthKey).balanceOf(address(this)) >= _sourceSynthAmount,
            "Insufficient synth balance on DEX Bridge."
        );
        // TransferHelper.safeTransferFrom(address(issuer().synths(nativeSynthKey)), msg.sender, address(this), _sourceSynthAmount);
        if (IERC20(address(issuer().synths(nativeSynthKey))).allowance(address(this), swapRouter) <= _sourceSynthAmount) {
            require(
                IERC20(address(issuer().synths(nativeSynthKey))).approve(swapRouter, type(uint256).max),
                "Synth approve failed."
            );
        }
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(address(issuer().synths(nativeSynthKey)));
        tokenPath[1] = IERC20(wrappedNative);

        ILBFactory.LBPairInformation[] memory lbPairs = ILBFactory(lbFactory).getAllLBPairs(tokenPath[0], tokenPath[1]);

        uint256[] memory pairBinSteps = new uint256[](lbPairs.length); // pairBinSteps[i] refers to the bin step for the market (x, y) where tokenPath[i] = x and tokenPath[i+1] = y
        uint256 amountOutMin;
        for (uint256 ii = 0; ii < lbPairs.length; ii++) {
            pairBinSteps[ii] = uint256(lbPairs[ii].binStep);
            (, uint128 amountOut, ) = ILBRouter(swapRouter).getSwapOut(lbPairs[ii].LBPair, uint128(_sourceSynthAmount), true);
            if (amountOut > amountOutMin) {
                amountOutMin = amountOut;
            }
        }

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_1; // add the version of the Dex to perform the swap on

        ILBRouter.Path memory path; // instanciate and populate the path to perform the swap.
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;

        uint256 results = ILBRouter(swapRouter).swapExactTokensForNATIVE(
            _sourceSynthAmount,
            amountOutMin,
            path,
            payable(_account),
            block.timestamp + 1
        );
        emit DexSwapSynthToNative(_account, nativeSynthKey, _sourceSynthAmount, nativeKey, results);
        return results;
    }

    function swapNativeToSynth(address _account, uint256 _sourceNativeAmount)
        external
        payable
        systemActive
        onlySynthrSwap
        returns (uint256)
    {
        require(msg.value >= _sourceNativeAmount, "Exceed msg value on DEX Bridge.");
        require(address(this).balance >= _sourceNativeAmount, "Exceed ETH balance on DEX Bridge.");
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = IERC20(wrappedNative);
        tokenPath[1] = IERC20(address(issuer().synths(nativeSynthKey)));

        ILBFactory.LBPairInformation[] memory lbPairs = ILBFactory(lbFactory).getAllLBPairs(tokenPath[0], tokenPath[1]);

        uint256[] memory pairBinSteps = new uint256[](lbPairs.length); // pairBinSteps[i] refers to the bin step for the market (x, y) where tokenPath[i] = x and tokenPath[i+1] = y
        uint256 amountOutMin;
        for (uint256 ii = 0; ii < lbPairs.length; ii++) {
            pairBinSteps[ii] = uint256(lbPairs[ii].binStep);
            (, uint128 amountOut, ) = ILBRouter(swapRouter).getSwapOut(lbPairs[ii].LBPair, uint128(_sourceNativeAmount), false);
            if (amountOut > amountOutMin) {
                amountOutMin = amountOut;
            }
        }

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_1; // add the version of the Dex to perform the swap on

        ILBRouter.Path memory path; // instanciate and populate the path to perform the swap.
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;

        uint256 results = ILBRouter(swapRouter).swapExactNATIVEForTokens{value: _sourceNativeAmount}(
            amountOutMin,
            path,
            _account,
            block.timestamp + 1
        );
        emit DexSwapNativeToSynth(_account, nativeKey, _sourceNativeAmount, nativeSynthKey, results);
        return results;
    }

    function refundSynth(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external systemActive onlySynthrSwap {
        require(
            IERC20(address(issuer().synths(_synthKey))).balanceOf(address(this)) >= _synthAmount,
            "Insufiicient synth balance to refund."
        );
        TransferHelper.safeTransfer(address(issuer().synths(_synthKey)), _account, _synthAmount);
    }

    // for dev version
    function ownerWithdraw(
        address _to,
        address _currency,
        uint256 _amount
    ) external onlyOwner {
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "Insufficient ETH balance on contract.");
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            require(IERC20(_currency).balanceOf(address(this)) >= _amount, "Insufficient token balance on contract.");
            TransferHelper.safeTransfer(_currency, _to, _amount);
        }
        emit OwnerWithdraw(_to, _currency, _amount);
    }

    // ========== MODIFIERS ==========
    modifier systemActive() {
        _systemActive();
        _;
    }

    function _systemActive() private view {
        systemStatus().requireSystemActive();
    }

    modifier onlySynthrSwap() {
        require(msg.sender == address(synthrSwap()), "DexAgg: Only SynthrSwap contract can perform this action.");
        _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISynth.sol";

interface IIssuer {
    // Views

    function allNetworksDebtInfo() external view returns (uint256 debt, uint256 sharesSupply);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer) external view returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256);

    function checkFreeCollateral(
        address _issuer,
        bytes32 _collateralKey,
        uint16 _chainId
    ) external view returns (uint256 withdrawableSynthr);

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynths(address from, uint256 destChainId) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount
    )
        external
        returns (
            uint256 synthAmount,
            uint256 debtShare,
            uint256 reclaimed,
            uint256 refunded
        );

    function burnSynthsToTarget(address from, bytes32 synthKey)
        external
        returns (
            uint256 synthAmount,
            uint256 debtShare,
            uint256 reclaimed,
            uint256 refunded
        );

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint256 balance
    ) external;

    function synthIssueFromSynthrSwap(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;

    function synthBurnFromSynthrSwap(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        uint16 chainId,
        bool isSelfLiquidation
    )
        external
        returns (
            uint256 totalRedeemed,
            uint256 amountToLiquidate,
            uint256 sharesToRemove
        );

    function destIssue(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;

    function destBurn(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external returns (uint256);

    function transferMargin(address account, uint256 marginDelta) external returns (uint256);

    function setCurrentPeriodId(uint128 periodId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

import {ILBPair} from "./ILBPair.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory {
    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(
        IERC20 tokenX,
        IERC20 tokenY,
        uint256 binStep
    ) external view returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY) external view returns (LBPairInformation[] memory LBPairsBinStep);

    function createLBPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (ILBPair pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (
            uint128 amountIn,
            uint128 amountOutLeft,
            uint128 fee
        );

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (
            uint128 amountInLeft,
            uint128 amountOut,
            uint128 fee
        );

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function mint(
        address to,
        bytes32[] calldata liquidityConfigs,
        address refundTo
    )
        external
        returns (
            bytes32 amountsReceived,
            bytes32 amountsLeft,
            uint256[] memory liquidityMinted
        );

    function burn(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) external returns (bytes32[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

import {ILBPair} from "./ILBPair.sol";
import {ILBToken} from "./ILBToken.sol";
import {IWNATIVE} from "./IWNATIVE.sol";

/**
 * @title Liquidity Book Router Interface
 * @author Trader Joe
 * @notice Required interface of LBRouter contract
 */
interface ILBRouter {
    /**
     * @dev This enum represents the version of the pair requested
     * - V1: Joe V1 pair
     * - V2: LB pair V2. Also called legacyPair
     * - V2_1: LB pair V2.1 (current version)
     */
    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The liquidity parameters, such as:
     * - tokenX: The address of token X
     * - tokenY: The address of token Y
     * - binStep: The bin step of the pair
     * - amountX: The amount to send of token X
     * - amountY: The amount to send of token Y
     * - amountXMin: The min amount of token X added to liquidity
     * - amountYMin: The min amount of token Y added to liquidity
     * - activeIdDesired: The active id that user wants to add liquidity from
     * - idSlippage: The number of id that are allowed to slip
     * - deltaIds: The list of delta ids to add liquidity (`deltaId = activeId - desiredId`)
     * - distributionX: The distribution of tokenX with sum(distributionX) = 100e18 (100%) or 0 (0%)
     * - distributionY: The distribution of tokenY with sum(distributionY) = 100e18 (100%) or 0 (0%)
     * - to: The address of the recipient
     * - refundTo: The address of the recipient of the refunded tokens if too much tokens are sent
     * - deadline: The deadline of the transaction
     */
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        address refundTo;
        uint256 deadline;
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function getWNATIVE() external view returns (IWNATIVE);

    function getIdFromPrice(ILBPair LBPair, uint256 price) external view returns (uint24);

    function getPriceFromId(ILBPair LBPair, uint24 id) external view returns (uint256);

    function getSwapIn(
        ILBPair LBPair,
        uint128 amountOut,
        bool swapForY
    )
        external
        view
        returns (
            uint128 amountIn,
            uint128 amountOutLeft,
            uint128 fee
        );

    function getSwapOut(
        ILBPair LBPair,
        uint128 amountIn,
        bool swapForY
    )
        external
        view
        returns (
            uint128 amountInLeft,
            uint128 amountOut,
            uint128 fee
        );

    function createLBPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (ILBPair pair);

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function addLiquidityNATIVE(LiquidityParameters calldata liquidityParameters)
        external
        payable
        returns (
            uint256 amountXAdded,
            uint256 amountYAdded,
            uint256 amountXLeft,
            uint256 amountYLeft,
            uint256[] memory depositIds,
            uint256[] memory liquidityMinted
        );

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityNATIVE(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountNATIVEMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountNATIVE);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactNATIVE(
        uint256 amountOut,
        uint256 amountInMax,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapNATIVEForExactTokens(
        uint256 amountOut,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForNATIVESupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinNATIVE,
        Path memory path,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNATIVEForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(
        IERC20 token,
        address to,
        uint256 amount
    ) external;

    function sweepLBToken(
        ILBToken _lbToken,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    event TransferBatch(address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISynth {
    // Views
    function balanceOf(address _account) external view returns (uint256);

    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external payable returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external payable returns (bool);

    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISynthrSwapWithDex {
    function swapSynthToNative(
        uint256 _sourceAmount,
        bytes32 _sourceKey,
        bytes32 _destKey,
        address _target,
        bytes memory _data,
        uint16 _chainId
    ) external payable;

    function destSwapSynthToNative(
        address _account,
        bytes32 _sourceKey,
        uint256 _sourceAmount,
        bytes32 _destKey,
        uint256 _destAmount,
        address _target,
        bytes memory _data
    ) external returns (bool);

    function swapNtiveToSynth(
        uint256 _sourceNativeAmount,
        bytes32 _sourceNativeKey,
        bytes32 _destSynthKey,
        address _target,
        bytes memory _data,
        uint16 _chainId
    ) external payable;

    function destSwapNativeToSynth(
        address _account,
        bytes32 _sourceKey,
        uint256 _sourceAmount,
        bytes32 _destKey,
        uint256 _destAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function synthSuspended(bytes32 currencyKey) external view returns (bool);

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

/**
 * @title WNATIVE Interface
 * @notice Required interface of Wrapped NATIVE contract
 */
interface IWNATIVE is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}
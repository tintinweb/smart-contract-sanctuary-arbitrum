/*
         ._                __.
        / \"-.          ,-",'/ 
        (   \ ,"--.__.--".,' /  
        =---Y(_i.-'  |-.i_)---=
        f ,  "..'/\\v/|/|/\  , l
        l//  ,'|/   V / /||  \\j
        "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
        __,---_ '._." .  .    \
        (__.--_-'.  ,  :  '  \  '-.
        ,' .'  /   |   \  \  \ "-
        "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I
                        異世界*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {UpgradeableOperable} from "./UpgradeableOperable.sol";
import {IAlgebraFactory} from "../interfaces/IAlgebraFactory.sol";
import {ISwapRouter} from "../interfaces/ISwapRouter.sol";
import {IIsekaiOracle} from "../interfaces/IIsekaiOracle.sol";
import {IIsekaiZap} from "../interfaces/IIsekaiZap.sol";
import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";
import {ICamelotRouter} from "src/interfaces/ICamelotRouter.sol";
import {ICamelotNFTPool} from "src/interfaces/ICamelotNFTPool.sol";
import {ICamelotPair} from "src/interfaces/ICamelotPair.sol";
import {ICamelotFactory} from "src/interfaces/ICamelotFactory.sol";
import {IMetadata} from "src/interfaces/IMetadata.sol";
import {IIsekaiCamelotCompoundingPosition} from "src/interfaces/IIsekaiCamelotCompoundingPosition.sol";
import {CamelotPositionManager, IWhitelistController} from "src/CamelotPositionManager.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BytesLib} from "src/crosschain/layer-zero/BytesLib.sol";
import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";
import {IGammaUniProxyHelper} from "src/interfaces/IGammaUniProxyHelper.sol";
import {IsekaiSimulator} from "src/libraries/IsekaiSimulator.sol";
import {IDefiEdge, INFTPOOL} from "src/interfaces/IDefiEdge.sol";

contract IsekaiZap is UpgradeableOperable, IIsekaiZap {
    using SafeTransferLib for ERC20;

    struct V3SwapSingle {
        address pairAddress;
        uint64 minReceivable;
        int24 interval;
    }

    struct V3BuildParams {
        address spNFT;
        address fromToken;
        uint256 amountIn;
        address underlyingToken;
        address token0;
        address token1;
        bool isTokenInToken0;
    }

    struct V3BuildInnerParams {
        uint256 otherTokenNeededAmount;
        uint256 otherTokenNeededAmountQuotedInTokenIn;
        uint256 amountToDivide;
        uint256 tokenInNeededAmount;
        uint256 newOtherTokenNeededAmount;
        uint256 price;
        uint256 mintedSpNftId;
        address out;
        uint256 buildSlippage;
    }

    /// @notice Pairs whitelisted by the system to be swapped
    mapping(address => Pairs) public pairSettings;

    /// @notice Camelot Exchange pairs factory utilizing Algebra's custom implementation of Uni V3.
    IAlgebraFactory public constant CAMELOT_FACTORY_V3 = IAlgebraFactory(0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B);

    /// @notice Camelot Exchange swaps router utilizing Algebra's custom implementation of Uni V3.
    ISwapRouter public constant CAMELOT_ROUTER_V3 = ISwapRouter(0x1F721E2E82F6676FCE4eA07A5958cF098D339e18);

    /// @notice Camelot Exchange pairs factory utilizing its own custom implementation of Uni V2.
    ICamelotFactory public constant CAMELOT_FACTORY_V2 = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);

    /// @notice Camelot Exchange swaps router utilizing custom implementation of default Uni V2.
    ICamelotRouter public constant CAMELOT_ROUTER_V2 = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // Position manager auto compounder
    IIsekaiCamelotCompoundingPosition public compounder;

    // Position manager
    CamelotPositionManager public positionManager;

    /// @notice Internal representation of 100% (1000000000000)
    uint256 public constant BASIS_POINTS = 1e12;

    uint256 public constant PRECISION = 1e18;

    /// @notice Default settings for pairs that did not receive specific slip/interval settings
    DefaultSettings private _defaultSettings;

    /// @dev bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /// @dev The length the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev Slippage for V3 Gamma strategies, starts at 1e12 - 1 meaning that its a 0.999999999999
    uint256 public v3GammaStrategiesSlippage;

    bool public useOracles;

    IGammaUniProxyHelper internal gammaHelper;

    IDefiEdge internal defiEdge;

    uint256 public buildSlippage;

    /// @notice Used in DefiEdge deposits
    mapping(address => address) public pairToStrategy;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        EVENTS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, TYPE swapType);
    event NewPairAdded(address indexed pair, Pairs _pairInfo);
    event RetirePair(address indexed pair);
    event UpdateDefaultSettings(uint64 newMinReceivable, int24 newInterval);
    event OraclesStatus(bool inUse);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ERRORS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error NotAllowed(address pair);
    error OutOfRange(uint256 slipage);
    error ZeroAmount();
    error NotImplemented();
    error PathTooSmall();
    error ZeroAddress();
    error Unreachable();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        EXTERNAL Methods                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function init() external initializer {
        __Governable_init(msg.sender);

        // 850000000000
        uint64 minReceivable_ = 85e10;
        // 3600
        int24 minInterval_ = 1 hours;

        // Update default settings
        _defaultSettings = DefaultSettings(minReceivable_, minInterval_);

        useOracles = false;

        gammaHelper = IGammaUniProxyHelper(0x851b3Fb3c3178Cd3FBAa0CdaAe0175Efa15a30f1);
        defiEdge = IDefiEdge(0xc4eb9fff53581130e65E3B60b31295C52509C11F);

        v3GammaStrategiesSlippage = BASIS_POINTS - 1;

        buildSlippage = BASIS_POINTS - 1_000_000_000;

        //pairToStrategy[0x9c5AbA4f5c78E638572407a677259e32df7519cD] = 0xB1026b8e7276e7AC75410F1fcbbe21796e8f7526;

        emit OraclesStatus(false);
    }

    function swapMultiHop(address[] memory _path, uint256 _amountIn, TYPE _swapType)
        external
        onlyOperator
        returns (uint256)
    {
        uint256 length = _path.length;

        if (length < 3) {
            revert PathTooSmall();
        }

        if (_amountIn == 0) {
            revert ZeroAmount();
        }

        SafeTransferLib.safeTransferFrom(ERC20(_path[0]), msg.sender, address(this), _amountIn);

        return _performMultihop(_path, _amountIn, _swapType);
    }

    function _performMultihop(address[] memory _path, uint256 _amountIn, TYPE _swapType) private returns (uint256) {
        uint256 length = _path.length;

        // This means tokenIn == tokenOut
        if (_path[0] == _path[length - 1]) {
            return _amountIn;
        }

        // Flow for V3 multi-hop swaps
        if (_swapType == TYPE.UNI_V3) {
            // Received starts at amountIn and will be updated with the tokens received from swaps
            uint256 received = _amountIn;

            for (uint256 i; i < length - 1; ++i) {
                // Update received with the amount received from the swap
                received = _v3SwapSingle(_path[i], _path[i + 1], received, true);
            }

            // Make sure we are receiving an amount > 0
            if (received == 0) {
                revert ZeroAmount();
            }

            // Send final received token to msg.sender
            SafeTransferLib.safeTransfer(ERC20(_path[length - 1]), msg.sender, received);

            return received;
        } else {
            // Received starts at amountIn and will be updated with the tokens received from swaps
            uint256 received = _amountIn;

            for (uint256 i; i < length - 1; ++i) {
                // Update received with the amount received from the swap
                received = _v2SwapSingle(_path[i], _path[i + 1], received, true);
            }

            // Make sure we are receiving an amount > 0
            if (received == 0) {
                revert ZeroAmount();
            }

            // Send final received token to msg.sender
            SafeTransferLib.safeTransfer(ERC20(_path[length - 1]), msg.sender, received);

            return received;
        }
    }

    /**
     * @notice Performs a single hop swap.
     * @param _tokenIn Token that will be swapped.
     * @param _tokenOut Token that will be received.
     * @param _amountIn Amount of tokenIn.
     * @param _swapType UniV2 or UniV3 swap.
     * @return received Amount of _tokenOut received.
     */
    function swapSingle(address _tokenIn, address _tokenOut, uint256 _amountIn, TYPE _swapType)
        external
        onlyOperator
        returns (uint256 received)
    {
        if (_amountIn == 0) {
            return 0;
        }

        SafeTransferLib.safeTransferFrom(ERC20(_tokenIn), msg.sender, address(this), _amountIn);

        if (_swapType == TYPE.UNI_V3) {
            return _v3SwapSingle(_tokenIn, _tokenOut, _amountIn, false);
        } else {
            return _v2SwapSingle(_tokenIn, _tokenOut, _amountIn, false);
        }
    }

    /**
     * @param _spNFT spNFT thats going to be built
     * @param _fromToken Token that we are zapping into LP and wrapping into spNFT
     * @param _amountIn Amount of `fromToken`
     * @param _type If its v2/v3 pair
     * @return pairReceived Address of the underlying LP built
     * @return receivedUnderlyingLp Amount of `pairReceived`
     */
    function buildPositionFromToken(
        address _spNFT,
        address _fromToken,
        uint256 _amountIn,
        TYPE _type,
        bool _stayInContract,
        bool _defiEdge
    ) public returns (address pairReceived, uint256 receivedUnderlyingLp) {
        SafeTransferLib.safeTransferFrom(ERC20(_fromToken), msg.sender, address(this), _amountIn);

        // Get underlying LP address for the given spNFT
        (address underlyingToken,,,,,,,) = ICamelotNFTPool(_spNFT).getPoolInfo();

        // Get underlying LP tokens
        address token0;
        address token1;

        if (_defiEdge) {
            token0 = ICamelotPair(IDefiEdge(underlyingToken).pool()).token0();
            token1 = ICamelotPair(IDefiEdge(underlyingToken).pool()).token1();
        } else {
            token0 = ICamelotPair(underlyingToken).token0();
            token1 = ICamelotPair(underlyingToken).token1();
        }

        // If the token we are swapping is the token 0 of the LP and its a V2 pair, we set the correct pair to build/swap
        if (_fromToken == token0 && _type == TYPE.UNI_V2) {
            // Get reserves of the LP
            (uint256 resA,,,) = ICamelotPair(underlyingToken).getReserves();

            // Calculate optimal amountIn to reduce dust
            uint256 amountThatWillBeSwapped = getAmountIn(_amountIn, resA);

            // Get amount out of token1 after swapping token0 -> token1
            uint256 token1Amount = _v2SwapSingle(token0, token1, amountThatWillBeSwapped, true);

            // Use the received token1 and whats left of token0 to build the V2 pair
            (pairReceived, receivedUnderlyingLp) =
                _build(token0, token1, _amountIn - amountThatWillBeSwapped, token1Amount, _type, _stayInContract);
        } else if (_fromToken == token1 && _type == TYPE.UNI_V2) {
            // Get reserves of the LP
            (, uint256 resB,,) = ICamelotPair(underlyingToken).getReserves();

            uint256 amountThatWillBeSwapped = getAmountIn(_amountIn, resB);
            uint256 token0Amount = _v2SwapSingle(token1, token0, amountThatWillBeSwapped, true);

            (pairReceived, receivedUnderlyingLp) =
                _build(token0, token1, _amountIn - amountThatWillBeSwapped, token0Amount, _type, _stayInContract);
        } else if (_fromToken == token0 && _type == TYPE.UNI_V3) {
            uint256 receivedUnderlyingAmount = _performDefiEdgeStrategyDeposit(
                V3BuildParams(_spNFT, _fromToken, _amountIn, underlyingToken, token0, token1, true)
            );

            return (underlyingToken, receivedUnderlyingAmount);
        } else {
            uint256 receivedUnderlyingAmount = _performDefiEdgeStrategyDeposit(
                V3BuildParams(_spNFT, _fromToken, _amountIn, underlyingToken, token0, token1, false)
            );

            return (underlyingToken, receivedUnderlyingAmount);
        }
    }

    /**
     * @notice Same as buildPositionFromToken but ends up wrapping into spNFT and deposits into ICP or ICCP
     * @param _spNFT spNFT thats going to be built
     * @param _fromToken Token that we are zapping into LP and wrapping into spNFT
     * @param _amountIn Amount of `fromToken`
     * @param _type If its v2/v3 pair
     * @param _compounder If true -> Deposit into ICCP / false -> Deposit into ICP
     * @param _addToNitro true if deposit to nitro pool fa lse if not
     */
    function buildPositionFromTokenAndDeposit(
        address _spNFT,
        address _fromToken,
        uint256 _amountIn,
        TYPE _type,
        bool _compounder,
        bool _addToNitro
    ) external returns (uint256) {
        // Pass as true since LP should stay here to be used to deposit into ICP/ICCP according to `_compounder`
        (address lpReceived, uint256 _underlyingAmount) = buildPositionFromToken(
            _spNFT, _fromToken, _amountIn, _type, true, _type == IIsekaiZap.TYPE.UNI_V3 ? true : false
        );

        // Approve LP to be wrapped as spNFT
        ERC20(lpReceived).approve(address(_spNFT), _underlyingAmount);

        // Wrap as spNFT with no lock
        ICamelotNFTPool(_spNFT).createPosition(_underlyingAmount, 0);

        // Get the ID of the minted wrapped spNFT
        uint256 mintedspNFT = ICamelotNFTPool(_spNFT).lastTokenId();

        // Deposit into compounder or non-compounder position
        if (_compounder) {
            IERC721(_spNFT).transferFrom(address(this), address(compounder), mintedspNFT);

            // Mint to msg.sender and return minted ICCP tokenId
            return compounder.deposit(msg.sender, _spNFT, mintedspNFT);
        } else {
            IERC721(_spNFT).transferFrom(address(this), address(positionManager), mintedspNFT);

            // Mint to msg.sender and return minted ICP tokenId
            return positionManager.deposit(msg.sender, _spNFT, mintedspNFT, _addToNitro);
        }
    }

    /**
     * @notice Make a pair have its own slippage and interval settings. Ideal for more volatile pairs where we want extra safety.
     * @param _pairAddress Pair that will be updated.
     * @param _pairSettings Settings for the given pair.
     */
    function setPairSettings(address _pairAddress, Pairs calldata _pairSettings) external onlyGovernorOrOperator {
        if (_pairSettings.oracle == address(0)) {
            revert ZeroAddress();
        }

        if (_pairSettings.minReceivable != 0 && _pairSettings.minReceivable > BASIS_POINTS) {
            revert OutOfRange(_pairSettings.minReceivable);
        }

        pairSettings[_pairAddress] = _pairSettings;

        emit NewPairAdded(_pairAddress, _pairSettings);
    }

    function setOraclesStatus(bool _activate) external onlyGovernor {
        useOracles = _activate;

        emit OraclesStatus(_activate);
    }

    function setDefiEdge(address _defiEdge) external onlyGovernor {
        if (_defiEdge == address(0)) {
            revert ZeroAddress();
        }

        defiEdge = IDefiEdge(_defiEdge);
    }

    /**
     * @notice Update defaut values
     * @param _newMinReceivable New value to be used as default slippgae
     * @param _minDefaultInterval New value to be used as default interval
     */
    function updateDefaultSettings(uint64 _newMinReceivable, int24 _minDefaultInterval)
        external
        onlyGovernorOrOperator
    {
        if (_newMinReceivable > BASIS_POINTS) {
            revert OutOfRange(_newMinReceivable);
        }

        _defaultSettings = DefaultSettings(_newMinReceivable, _minDefaultInterval);

        emit UpdateDefaultSettings(_newMinReceivable, _minDefaultInterval);
    }

    /// @dev Set Position Manager and Compounder position addresses, in order to perform direct deposits from any asset
    function setPositionManagerAndCompounder(address _compounder, address _positionManager)
        external
        onlyGovernorOrOperator
    {
        if (_compounder == address(0) || _positionManager == address(0)) {
            revert ZeroAddress();
        }

        compounder = IIsekaiCamelotCompoundingPosition(_compounder);
        positionManager = CamelotPositionManager(_positionManager);
    }

    function _v3SwapSingle(address _tokenIn, address _tokenOut, uint256 _amountIn, bool _shouldSayInContract)
        private
        returns (uint256)
    {
        // This means tokenIn == tokenOut
        if (_tokenIn == _tokenOut) {
            return _amountIn;
        }

        V3SwapSingle memory swapInfo;
        Pairs memory pairInfo;

        // Fetch pair address from Camelot
        swapInfo.pairAddress = CAMELOT_FACTORY_V3.poolByPair(_tokenIn, _tokenOut);

        // If oracles use is disabled, we swap with minAmountOut = 0
        if (!useOracles) {
            return _v3Oracleless(_tokenIn, _tokenOut, _amountIn, _shouldSayInContract);
        }

        // Validate if we have an oracle to trade this pair
        if (pairSettings[swapInfo.pairAddress].oracle == address(0)) {
            revert NotAllowed(swapInfo.pairAddress);
        } else {
            pairInfo = pairSettings[swapInfo.pairAddress];

            // Even though we are not loading the struct to memory, we are accessing a warm slot
            swapInfo.minReceivable =
                pairInfo.minReceivable == 0 ? _defaultSettings.minReceivable : pairInfo.minReceivable;
            swapInfo.interval = pairInfo.interval == 0 ? _defaultSettings.minInterval : pairInfo.interval;
        }

        // Store price of token0 quoted in token1
        uint256 price = IIsekaiOracle(pairInfo.oracle).getPrice(swapInfo.interval);

        // If the input token is the token1 instead of token0, we do 1 / getPriceTokenA
        // in order to get token1 priced in token0
        if (_tokenIn == ICamelotPair(swapInfo.pairAddress).token1()) {
            // Logic here is basically:
            // ((1 * 10 ** decimalsToken1) / (priceInToken1 * 10 ** decimalsToken1)) * decimalsToken0
            // This way we can get the desired 1 / getPriceTokenA in a way which we are agnostic to decimals and with no underflow risk
            price = (
                (10 ** IMetadata(ICamelotPair(swapInfo.pairAddress).token0()).decimals())
                    * (10 ** IMetadata(_tokenIn).decimals())
            ) / price;
        }

        // Fetch current price from TWAP oracle for the chosen interval, multiply by minReceived to have a buffer for volatility and avoid reverts
        uint256 tokenInPriceWithSlippage = (price * swapInfo.minReceivable) / BASIS_POINTS;

        // Calculate amount out being decimals agnostic
        // tokenInPriceWithSlippage uses the tokenOut decimals
        // _amountIn uses tokenIn decimals
        // Normalize by dividing by tokenIn decimals
        uint256 amountOut = (tokenInPriceWithSlippage * _amountIn) / (10 ** IMetadata(_tokenIn).decimals());

        // Make sure we are receiving an amount > 0
        if (amountOut == 0) {
            revert ZeroAmount();
        }

        // If its a multihop swap we don't send token to msg.sender, since it is going to be used to be swapped again
        address receiver = _shouldSayInContract ? address(this) : msg.sender;

        // Build single hop Camelot V3 swap
        ISwapRouter.ExactInputSingleParams memory swapParams =
            ISwapRouter.ExactInputSingleParams(_tokenIn, _tokenOut, receiver, block.timestamp, _amountIn, amountOut, 0);

        ERC20(_tokenIn).approve(address(CAMELOT_ROUTER_V3), _amountIn);

        // Performs the V3 Camelot swap and return amount received
        return CAMELOT_ROUTER_V3.exactInputSingle(swapParams);
    }

    function _v3Oracleless(address _tokenIn, address _tokenOut, uint256 _amountIn, bool _shouldSayInContract)
        private
        returns (uint256)
    {
        // If its a multihop swap we don't send token to msg.sender, since it is going to be used to be swapped again
        address receiver = _shouldSayInContract ? address(this) : msg.sender;

        // Build single hop Camelot V3 swap
        ISwapRouter.ExactInputSingleParams memory swapParams =
            ISwapRouter.ExactInputSingleParams(_tokenIn, _tokenOut, receiver, block.timestamp, _amountIn, 0, 0);

        ERC20(_tokenIn).approve(address(CAMELOT_ROUTER_V3), _amountIn);

        // Performs the V3 Camelot swap and return amount received
        return CAMELOT_ROUTER_V3.exactInputSingle(swapParams);
    }

    function _v2SwapSingle(address _tokenIn, address _tokenOut, uint256 _amountIn, bool _multiHop)
        private
        returns (uint256)
    {
        Pairs memory pairInfo;

        // This means tokenIn == tokenOut
        if (_tokenIn == _tokenOut) {
            return _amountIn;
        }

        address pair = CAMELOT_FACTORY_V2.getPair(_tokenIn, _tokenOut);
        uint64 minReceivable_;
        int24 interval_;

        // If oracles use is disabled, we swap with minAmountOut = 0
        if (!useOracles) {
            return _v2Oracleless(_tokenIn, _tokenOut, _amountIn, _multiHop);
        }

        // Validate if we have an oracle to trade this pair
        if (pairSettings[pair].oracle == address(0)) {
            revert NotAllowed(pair);
        } else {
            pairInfo = pairSettings[pair];

            // Even though we are not loading the struct to memory, we are accessing a warm slot
            minReceivable_ = pairInfo.minReceivable == 0 ? _defaultSettings.minReceivable : pairInfo.minReceivable;
        }

        // Fetch current price from TWAP oracle for the chosen interval, multiply by minReceived to have a buffer for volatility and avoid reverts
        uint256 tokenInPriceWithSlippage = (
            _min(IIsekaiOracle(pairInfo.oracle).getPrice(interval_), IIsekaiOracle(pairInfo.oracle).getSpot())
                * minReceivable_
        ) / BASIS_POINTS;

        // Calculate amount out being decimals agnostic
        // tokenInPriceWithSlippage uses the tokenOut decimals
        // _amountIn uses tokenIn decimals
        // Normalize by dividing by tokenIn decimals
        uint256 amountOut = (tokenInPriceWithSlippage * _amountIn) / (10 ** IMetadata(_tokenIn).decimals());

        // Make sure we are receiving an amount > 0
        if (amountOut == 0) {
            revert ZeroAmount();
        }

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        ERC20(_tokenIn).approve(address(CAMELOT_ROUTER_V2), _amountIn);

        uint256 before = ERC20(_tokenOut).balanceOf(address(this));

        uint256 received;

        // Camelot router doesnt have a return showing how much tokenOut was received :-(
        CAMELOT_ROUTER_V2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn, 0, path, address(this), address(0), block.timestamp
        );

        // Check how much we really received from the swap
        received = ERC20(_tokenOut).balanceOf(address(this)) - before;

        // Send tokens to user
        if (!_multiHop) {
            SafeTransferLib.safeTransfer(ERC20(_tokenOut), msg.sender, received);
        }

        return received;
    }

    function _v2Oracleless(address _tokenIn, address _tokenOut, uint256 _amountIn, bool _multiHop)
        private
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        ERC20(_tokenIn).approve(address(CAMELOT_ROUTER_V2), _amountIn);

        uint256 before = ERC20(_tokenOut).balanceOf(address(this));

        uint256 received;

        // Camelot router doesnt have a return showing how much tokenOut was received :-(
        CAMELOT_ROUTER_V2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn, 0, path, address(this), address(0), block.timestamp
        );

        // Check how much we really received from the swap
        received = ERC20(_tokenOut).balanceOf(address(this)) - before;

        // Send tokens to user
        if (!_multiHop) {
            SafeTransferLib.safeTransfer(ERC20(_tokenOut), msg.sender, received);
        }

        return received;
    }

    function _performDefiEdgeStrategyDeposit(V3BuildParams memory _params) private returns (uint256 am) {
        uint256 token0Amount;
        uint256 token1Amount;

        if (_params.isTokenInToken0) {
            token0Amount = _params.amountIn;
        } else {
            token1Amount = _params.amountIn;
        }

        ERC20(_params.fromToken).approve(address(defiEdge), _params.amountIn);

        defiEdge.deposit(
            ERC20(_params.token0),
            ERC20(_params.token1),
            token0Amount,
            token1Amount,
            0,
            0,
            0,
            _params.underlyingToken,
            INFTPOOL(_params.spNFT),
            0
        );

        uint256 mintedSpNftId = ICamelotNFTPool(_params.spNFT).lastTokenId();

        IERC721(_params.spNFT).safeTransferFrom(address(this), address(compounder), mintedSpNftId);

        (am,,,,,,,) = ICamelotNFTPool(_params.spNFT).getStakingPosition(mintedSpNftId);
    }

    function _performGammaStrategyDeposit(V3BuildParams memory _params) private returns (uint256 am) {
        V3BuildInnerParams memory innerParams;

        // Amount of token0 needed
        // In ETH-GMX LP, for example this would be GMX
        innerParams.otherTokenNeededAmount = getAmountInV3(_params.underlyingToken, _params.fromToken, _params.amountIn);

        if (_params.isTokenInToken0) {
            // Adjust for the swap
            innerParams.out = _params.token1;
        } else {
            // Adjust for the swap
            innerParams.out = _params.token0;
        }

        // Calculate amount out being decimals agnostic
        innerParams.otherTokenNeededAmountQuotedInTokenIn = IsekaiSimulator.getAmountIn(
            IsekaiSimulator.Platform.Camelot__V3,
            abi.encodePacked(innerParams.out, _params.fromToken),
            _params.underlyingToken,
            innerParams.otherTokenNeededAmount
        );

        // Check how bigger otherTokenNeededAmountQuotedInTokenIn is compared to amountIn
        // Example: If otherTokenNeededAmountQuotedInTokenIn is 1200 and amountIn is 1000, we need to divide by 1.2
        innerParams.amountToDivide =
            (BASIS_POINTS * (innerParams.otherTokenNeededAmountQuotedInTokenIn + _params.amountIn)) / _params.amountIn;

        // Now, after we get the amount we need to divide, we use this number to make the division and get the amount of tokenIn needed
        innerParams.tokenInNeededAmount = (_params.amountIn * BASIS_POINTS) / innerParams.amountToDivide;

        // Now that we also have the other token amount needed quoted in tokenIn, we also divide
        // The idea is to have "innerParams.tokenInNeededAmount + innerParams.newOtherTokenNeededAmount = _params.amountIn"
        innerParams.newOtherTokenNeededAmount =
            (innerParams.otherTokenNeededAmountQuotedInTokenIn * BASIS_POINTS) / innerParams.amountToDivide;

        // Now need to convert ETH to GMX -> using the amount from newToken1NeededAmount
        // Build single hop Camelot V3 swap
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams(
            _params.fromToken,
            innerParams.out,
            address(this),
            block.timestamp,
            (innerParams.newOtherTokenNeededAmount * v3GammaStrategiesSlippage) / BASIS_POINTS,
            0,
            0
        );

        if (_params.isTokenInToken0) {
            ERC20(_params.token0).approve(address(CAMELOT_ROUTER_V3), innerParams.newOtherTokenNeededAmount);

            // Performs the V3 Camelot swap and return amount received
            uint256 received = CAMELOT_ROUTER_V3.exactInputSingle(swapParams);

            uint256[4] memory minIn = [uint256(0), uint256(0), uint256(0), uint256(0)];

            ERC20(_params.token1).approve(address(gammaHelper), received);
            ERC20(_params.token0).approve(
                address(gammaHelper), (innerParams.tokenInNeededAmount * buildSlippage) / BASIS_POINTS
            );

            gammaHelper.deposit(
                _params.token0,
                _params.token1,
                (innerParams.tokenInNeededAmount * buildSlippage) / BASIS_POINTS,
                received,
                _params.underlyingToken,
                minIn,
                _params.spNFT,
                0
            );
        } else {
            ERC20(_params.token1).approve(address(CAMELOT_ROUTER_V3), innerParams.newOtherTokenNeededAmount);

            // Performs the V3 Camelot swap and return amount received
            uint256 received = CAMELOT_ROUTER_V3.exactInputSingle(swapParams);

            uint256[4] memory minIn = [uint256(0), uint256(0), uint256(0), uint256(0)];

            ERC20(_params.token1).approve(
                address(gammaHelper), (innerParams.tokenInNeededAmount * buildSlippage) / BASIS_POINTS
            );
            ERC20(_params.token0).approve(address(gammaHelper), received);

            gammaHelper.deposit(
                _params.token0,
                _params.token1,
                received,
                (innerParams.tokenInNeededAmount * buildSlippage) / BASIS_POINTS,
                _params.underlyingToken,
                minIn,
                _params.spNFT,
                0
            );
        }

        innerParams.mintedSpNftId = ICamelotNFTPool(_params.spNFT).lastTokenId();

        IERC721(_params.spNFT).safeTransferFrom(address(this), address(compounder), innerParams.mintedSpNftId);

        (am,,,,,,,) = ICamelotNFTPool(_params.spNFT).getStakingPosition(innerParams.mintedSpNftId);
    }

    /**
     * @notice Creates a V2 or V3 Camelot position
     * @param _token0 token0 of the LP
     * @param _token1 token1 of the LP
     * @param _token0Amount Amount of token0
     * @param _token1Amount Amount of token1
     * @param _type Signals if its a V2 or V3 pair
     * @param _stayInContract If the token should be sent to user or stay in contract
     * @return Address of underlying LP
     * @return liquidityReceived Underlying LP that backs spNFT
     */
    function _build(
        address _token0,
        address _token1,
        uint256 _token0Amount,
        uint256 _token1Amount,
        TYPE _type,
        bool _stayInContract
    ) private returns (address, uint256) {
        // Check if the built LP should stay in the contract or be immediately sent to msg.sender
        address receiver = _stayInContract ? address(this) : msg.sender;

        if (_type == TYPE.UNI_V2) {
            ERC20(_token0).approve(address(CAMELOT_ROUTER_V2), _token0Amount);
            ERC20(_token1).approve(address(CAMELOT_ROUTER_V2), _token1Amount);

            (,, uint256 liquidityReceived) = CAMELOT_ROUTER_V2.addLiquidity(
                _token0, _token1, _token0Amount, _token1Amount, 0, 0, receiver, block.timestamp
            );

            address pair = CAMELOT_FACTORY_V2.getPair(_token0, _token1);

            return (pair, liquidityReceived);
        }

        revert Unreachable();
    }

    /**
     * @notice Removes liquidity from a given LP and swaps the tokens into WETH
     * @param _lp Address of the LP token going to be broken and swapped into WETH
     * @param _amount Amount of the LP token
     * @return received Amount of Wrapped Ether received
     */
    function removeAndConsolidateIntoWrappedEther(address _lp, uint256 _amount)
        external
        onlyOperator
        returns (uint256 received)
    {
        // Get amount received after breaking and also the composition of the LP
        (uint256 amount0, uint256 amount1, address token0, address token1) = _remove(_lp, _amount, address(this));

        IWhitelistController pathAndType = positionManager.whitelistController();

        // This gets the path to WETH encoded in the following way:
        // abi.encodePacked(tokenA, tokenB, WETH)
        // And also if we should perform a V2 or V3 swap
        IWhitelistController.PathAndType memory path0 = pathAndType.getTokenPathToWrappedEther(token0);
        IWhitelistController.PathAndType memory path1 = pathAndType.getTokenPathToWrappedEther(token1);

        if (amount0 > 0 && path0.path.length > ADDR_SIZE) {
            received += _decodePathFromBytesAndSwap(path0.path, amount0, path0.routerType);
        }

        if (amount1 > 0 && path1.path.length > ADDR_SIZE) {
            received += _decodePathFromBytesAndSwap(path1.path, amount1, path1.routerType);
        }
    }

    function removeLiquidity(address _lp, uint256 _amount)
        external
        onlyOperator
        returns (uint256 amount0, uint256 amount1, address token0, address token1)
    {
        return _remove(_lp, _amount, msg.sender);
    }

    /**
     * @notice Helper function to decode the path from bytes and perform the swap to Wrapepd Ether
     * @param _path Bytes encoded path of the swap
     * @param _amount Amount of the token that is going to be swapped
     * @param _swapType V2 or V3 swap
     */
    function _decodePathFromBytesAndSwap(bytes memory _path, uint256 _amount, TYPE _swapType)
        private
        returns (uint256)
    {
        // Since each address is 20 hex long, we can get the total size of the path by dividing the length by 20
        uint256 pathTotalSize = _path.length / ADDR_SIZE;

        address[] memory path = new address[](pathTotalSize);

        for (uint256 i; i < pathTotalSize; ++i) {
            // We need to decode the path from the bytes representation
            path[i] = BytesLib.toAddress(_path, i * ADDR_SIZE);
        }

        if (_swapType == TYPE.UNI_V2) {
            return _performMultihop(path, _amount, TYPE.UNI_V2);
        } else {
            return _performMultihop(path, _amount, TYPE.UNI_V3);
        }
    }

    /**
     * @notice Removes liquidity from a given LP
     * @dev For now we only support V2 breaking/building but we support V3 swaps
     */
    function _remove(address _pair, uint256 _liquidity, address _to)
        private
        returns (uint256 amount0, uint256 amount1, address token0, address token1)
    {
        ICamelotPair pair = ICamelotPair(_pair);

        // (uint256 amount0Before, uint256 amount1Before,,) = pair.getReserves();

        ERC20(_pair).approve(address(CAMELOT_ROUTER_V2), _liquidity);

        token0 = pair.token0();
        token1 = pair.token1();

        (amount0, amount1) = CAMELOT_ROUTER_V2.removeLiquidity(token0, token1, _liquidity, 0, 0, _to, block.timestamp);
    }

    /**
     * @notice Empty all data for a given pair, making it untradeable
     * @param _pairAddress Address of the pair to be retired
     */
    function retirePair(address _pairAddress) external onlyGovernorOrOperator {
        Pairs memory empty;

        pairSettings[_pairAddress] = empty;

        emit RetirePair(_pairAddress);
    }

    // Calc optimal amountIn to reduce dust when building V2 pairs
    // https://blog.alphaventuredao.io/onesideduniswap/
    function getAmountIn(uint256 userIn, uint256 reserveIn) public pure returns (uint256) {
        return (_sqrt(reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))) - (reserveIn * 1997)) / 1994;
    }

    function getAmountInV3(address _spNFT, address _tokenIn, uint256 _amountIn)
        public
        view
        returns (uint256 otherTokenAmount)
    {
        (, otherTokenAmount) = gammaHelper.getDepositAmount(_spNFT, _tokenIn, _amountIn);
    }

    // Babylonian square root written in solidity
    // https://www.geeksforgeeks.org/square-root-of-a-perfect-square/
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Gets the smallest value between 2 uint256 values

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        VIEW Methods                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Returns default interval used in case the pair did not get a personalized value
    function getDefaultInterval() external view returns (int24) {
        return _defaultSettings.minInterval;
    }

    /// @notice Returns default minimal receivable percentage used in case the pair did not get a personalized value
    function getDefaultMinReceivable() external view returns (uint64) {
        return _defaultSettings.minReceivable;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UpgradeableGovernable} from "./UpgradeableGovernable.sol";

abstract contract UpgradeableOperable is UpgradeableGovernable {
    /**
     * @notice Operator role
     */
    bytes32 public constant OPERATOR = bytes32("OPERATOR");

    /**
     * @notice Modifier if msg.sender has not Operator role revert.
     */
    modifier onlyOperator() {
        if (!hasRole(OPERATOR, msg.sender)) {
            revert CallerIsNotOperator();
        }

        _;
    }

    /**
     * @notice Only msg.sender with OPERATOR or GOVERNOR role can call the function.
     */
    modifier onlyGovernorOrOperator() {
        if (!(hasRole(GOVERNOR, msg.sender) || hasRole(OPERATOR, msg.sender))) {
            revert CallerIsNotAllowed();
        }

        _;
    }

    /**
     * @notice Grant Operator role to _newOperator.
     */
    function addOperator(address _newOperator) public onlyGovernor {
        _grantRole(OPERATOR, _newOperator);

        emit OperatorAdded(_newOperator);
    }

    /**
     * @notice Remove Operator role from _operator.
     */
    function removeOperator(address _operator) external onlyGovernor {
        _revokeRole(OPERATOR, _operator);

        emit OperatorRemoved(_operator);
    }

    event OperatorAdded(address _newOperator);
    event OperatorRemoved(address _operator);

    error CallerIsNotOperator();
    error CallerIsNotAllowed();

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for the Algebra Factory
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraFactory {
    /**
     * @notice Emitted when the owner of the factory is changed
     * @param newOwner The owner after the owner was changed
     */
    event Owner(address indexed newOwner);

    /**
     * @notice Emitted when the vault address is changed
     * @param newVaultAddress The vault address after the address was changed
     */
    event VaultAddress(address indexed newVaultAddress);

    /**
     * @notice Emitted when a pool is created
     * @param token0 The first token of the pool by address sort order
     * @param token1 The second token of the pool by address sort order
     * @param pool The address of the created pool
     */
    event Pool(address indexed token0, address indexed token1, address pool);

    /**
     * @notice Emitted when the farming address is changed
     * @param newFarmingAddress The farming address after the address was changed
     */
    event FarmingAddress(address indexed newFarmingAddress);

    /**
     * @notice Emitted when the default community fee is changed
     * @param newDefaultCommunityFee The new default community fee value
     */
    event DefaultCommunityFee(uint8 newDefaultCommunityFee);

    event FeeConfiguration(
        uint16 alpha1,
        uint16 alpha2,
        uint32 beta1,
        uint32 beta2,
        uint16 gamma1,
        uint16 gamma2,
        uint32 volumeBeta,
        uint16 volumeGamma,
        uint16 baseFee
    );

    /**
     * @notice Returns the current owner of the factory
     * @dev Can be changed by the current owner via setOwner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the current poolDeployerAddress
     * @return The address of the poolDeployer
     */
    function poolDeployer() external view returns (address);

    /**
     * @dev Is retrieved from the pools to restrict calling
     * certain functions not by a tokenomics contract
     * @return The tokenomics contract address
     */
    function farmingAddress() external view returns (address);

    /**
     * @notice Returns the default community fee
     * @return Fee which will be set at the creation of the pool
     */
    function defaultCommunityFee() external view returns (uint8);

    function vaultAddress() external view returns (address);

    /**
     * @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
     * @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
     * @param tokenA The contract address of either token0 or token1
     * @param tokenB The contract address of the other token
     * @return pool The pool address
     */
    function poolByPair(address tokenA, address tokenB) external view returns (address pool);

    /**
     * @notice Creates a pool for the given two tokens and fee
     * @param tokenA One of the two tokens in the desired pool
     * @param tokenB The other of the two tokens in the desired pool
     * @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
     * from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
     * are invalid.
     * @return pool The address of the newly created pool
     */
    function createPool(address tokenA, address tokenB) external returns (address pool);

    /**
     * @notice Updates the owner of the factory
     * @dev Must be called by the current owner
     * @param _owner The new owner of the factory
     */
    function setOwner(address _owner) external;

    /**
     * @dev updates tokenomics address on the factory
     * @param _farmingAddress The new tokenomics contract address
     */
    function setFarmingAddress(address _farmingAddress) external;

    /**
     * @dev updates default community fee for new pools
     * @param newDefaultCommunityFee The new community fee, _must_ be <= MAX_COMMUNITY_FEE
     */
    function setDefaultCommunityFee(uint8 newDefaultCommunityFee) external;

    /**
     * @dev updates vault address on the factory
     * @param _vaultAddress The new vault contract address
     */
    function setVaultAddress(address _vaultAddress) external;

    /**
     * @notice Changes initial fee configuration for new pools
     * @dev changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
     * alpha1 + alpha2 + baseFee (max possible fee) must be <= type(uint16).max
     * gammas must be > 0
     * @param alpha1 max value of the first sigmoid
     * @param alpha2 max value of the second sigmoid
     * @param beta1 shift along the x-axis for the first sigmoid
     * @param beta2 shift along the x-axis for the second sigmoid
     * @param gamma1 horizontal stretch factor for the first sigmoid
     * @param gamma2 horizontal stretch factor for the second sigmoid
     * @param volumeBeta shift along the x-axis for the outer volume-sigmoid
     * @param volumeGamma horizontal stretch factor the outer volume-sigmoid
     * @param baseFee minimum possible fee
     */
    function setBaseFeeConfiguration(
        uint16 alpha1,
        uint16 alpha2,
        uint32 beta1,
        uint32 beta2,
        uint16 gamma1,
        uint16 gamma2,
        uint32 volumeBeta,
        uint16 volumeGamma,
        uint16 baseFee
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IAlgebraSwapCallback} from "./IAlgebraSwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouter is IAlgebraSwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut);
}

/*
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I

                        異世界
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IIsekaiOracle {
    function getPrice(int24 _secondsAgo) external returns (uint256);

    function getSpot() external view returns (uint256);
}

/*
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I

                        異世界
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IIsekaiZap {
    /// @dev Minimal informatio needed for trading a pair
    /// If minReceived and/or interval == 0, we are going to use _defaultSettings values
    struct Pairs {
        address oracle;
        uint64 minReceivable;
        int24 interval;
    }

    /// @dev Pack default settings in a single storage slot
    struct DefaultSettings {
        /// @notice Default: 85% (850000000000)
        /// @dev Updateable
        uint64 minReceivable;
        /// @notice Default: 3600
        /// @dev Updateable
        int24 minInterval;
    }

    /// @dev Information needed to properly select router (V2/V3)
    enum TYPE {
        UNI_V3,
        UNI_V2
    }

    function getAmountIn(uint256 userIn, uint256 reserveIn) external pure returns (uint256);

    function swapSingle(address _tokenIn, address _tokenOut, uint256 _amountIn, TYPE _swapType)
        external
        returns (uint256);

    function swapMultiHop(address[] memory _path, uint256 _amountIn, TYPE _swapType) external returns (uint256);

    function buildPositionFromToken(
        address _spNFT,
        address _fromToken,
        uint256 _amountIn,
        TYPE _type,
        bool _stayInContract,
        bool _defiEdge
    ) external returns (address pair, uint256 receivedUnderlyingLp);

    function removeAndConsolidateIntoWrappedEther(address _lp, uint256 _amount) external returns (uint256);
    function removeLiquidity(address _lp, uint256 _amount)
        external
        returns (uint256 amount0, uint256 amount1, address token0, address token1);
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

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICamelotNFTPool is IERC721 {
    function exists(uint256 tokenId) external view returns (bool);

    function hasDeposits() external view returns (bool);

    function getPoolInfo()
        external
        view
        returns (
            address lpToken,
            address grailToken,
            address sbtToken,
            uint256 lastRewardTime,
            uint256 accRewardsPerShare,
            uint256 lpSupply,
            uint256 lpSupplyWithMultiplier,
            uint256 allocPoint
        );

    function getStakingPosition(uint256 tokenId)
        external
        view
        returns (
            uint256 amount,
            uint256 amountWithMultiplier,
            uint256 startLockTime,
            uint256 lockDuration,
            uint256 lockMultiplier,
            uint256 rewardDebt,
            uint256 boostPoints,
            uint256 totalMultiplier
        );

    function addToPosition(uint256 tokenId, uint256 amountToAdd) external;

    function mergePositions(uint256[] calldata tokenIds, uint256 lockDuration) external;

    function splitPosition(uint256 tokenId, uint256 splitAmount) external;

    function boost(uint256 userAddress, uint256 amount) external;

    function unboost(uint256 userAddress, uint256 amount) external;

    function createPosition(uint256 amount, uint256 lockDuration) external;

    function lastTokenId() external view returns (uint256);

    function harvestPosition(uint256 tokenId) external;

    function harvestPositionTo(uint256 tokenId, address to) external;

    function harvestPositionsTo(uint256[] calldata tokenIds, address to) external;

    function withdrawFromPosition(uint256 tokenId, uint256 amount) external;
}

pragma solidity >=0.5.0;

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);
    function kLast() external view returns (uint256);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface ICamelotFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feePercentOwner() external view returns (address);
    function setStableOwner() external view returns (address);
    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);
    function referrersFeeShare(address) external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function feeInfo() external view returns (uint256 _ownerFeeShare, address _feeTo);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IMetadata {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IIsekaiCamelotCompoundingPosition {
    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets(address _spNFT) external view returns (uint256 totalAssets);

    /// @notice Total amount of the shares minted
    function totalSupply(address _spNFT) external view returns (uint256 totalSupply);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.

    function convertToShares(address _spNFT, uint256 _assets) external view returns (uint256 shares);

    //function previewRedeem(uint256 shares) external view virtual returns (uint256 assets);
    function deposit(address _to, address _spNFT, uint256 _tokenId) external returns (uint256);

    function getICPPositions() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * OpenZeppelin
 */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * Local Imports
 */
import {AccessControlUpgradeable} from "./common/UpgradeableGovernable.sol";
import {UpgradeableOperable} from "./common/UpgradeableOperable.sol";
import {IWhitelistController} from "./interfaces/IWhitelistController.sol";
import {ICamelotNFTPool} from "./interfaces/ICamelotNFTPool.sol";
import {ICamelotPair} from "./interfaces/ICamelotPair.sol";
import {IRewardsCollectorFactory} from "./interfaces/IRewardsCollectorFactory.sol";
import {IRewardsCollector} from "./interfaces/IRewardsCollector.sol";
import {IXperiencePointsLpStaking} from "./interfaces/IXperiencePointsLpStaking.sol";
import {IAllocationManager} from "./interfaces/IAllocationManager.sol";
import {LiquidityPoolHandler, HolyToken} from "./LiquidityPoolHandler.sol";
import {ICamelotPositionManager} from "src/interfaces/ICamelotPositionManager.sol";
import {IMirrorPoolIncentives} from "src/interfaces/IMirrorPoolIncentives.sol";

contract CamelotPositionManager is
    ICamelotPositionManager,
    ERC721Upgradeable,
    UpgradeableOperable,
    LiquidityPoolHandler,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        STATE                               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /// @notice Allowed LPs manager
    IWhitelistController public whitelistController;

    /// @notice factory address for Nitro Pool Rewards Collector
    IRewardsCollectorFactory private rewardsCollectorFactory;

    /// @notice Mirror Pool Incentives contract
    IMirrorPoolIncentives private mirrorPoolIncentives;

    /// @notice XP-ETH LP Staking contract
    IXperiencePointsLpStaking private xpLpStaking;

    /// @notice Isekai position ID => Camelot spNFT ID
    mapping(uint256 => IsekaiCamelotNFT) private _nftToSpNFT;

    ///@notice track whitelisted nft pools
    mapping(address => bool) private isWhitelistedPool;

    ///@notice nftPool -> tokenId -> ICP tokenId
    mapping(address => mapping(uint256 => uint256)) private isekaiCPTokenId;

    /// @dev Contracts allowed to bypass the transferFrom
    mapping(address => bool) private allowedContracts;

    /// @dev tracks LP balance in Isekai mirror pools for rewards distribution
    mapping(address => uint256) public totalDepositAmount;

    /// @dev allow spnfts in whitelisted mirror pools to bypass withdraw incentive
    mapping(address => bool) public whitelistedMirrorPool;

    /// @notice address of XP-ETH nitroPool
    address public xpLp;

    /// @notice Retention receiver
    address public treasury;

    /// @notice Camelot's xGRAIL token
    IERC20 private constant xGRAIL = IERC20(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);

    /// @notice address of Allocation Manager contract
    address private allocationManager;

    Counters.Counter public _tokenIds;

    /// @dev 100%
    uint256 private constant BASIS_POINTS = 10_000;

    /// @dev Incentive taken on deposits
    uint256 public mirrorPoolIncentive;

    /// @dev flag to indicate whether to send xGRAIL to the Allocation Manager
    bool public sendToAllocationManager;

    /// @dev TokenId => OldNitroPool => Migrated
    mapping(uint256 => mapping(address => bool)) public migratedOldNp;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        EVENTS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Deposit(
        address indexed nftPool,
        uint256 indexed tokenId,
        uint256 mintedId,
        address depositor,
        address receiver,
        bool nitro,
        address nitroPool
    );
    event HarvestedRewards(uint256 holyReceived, address harvester, address indexed nftPool, uint256 indexed tokenId);
    event HarvestedNitroPoolRewards(address harvester, address indexed nitroPool);
    event DepositToNitroPool(
        uint256 indexed spNFT, uint256 indexed icpNFT, address indexed nitroPool, address nftPool, address depositor
    );
    event Withdrawal(address indexed nftPool, uint256 indexed tokenId, address userWithdrawing);
    event WithdrawFromNitroPool(address indexed nitroPool, uint256 indexed tokenId);
    event AddToPosition(address indexed user, address indexed nftPool, uint256 indexed tokenId);
    event MergePosition(address indexed user, uint256 indexed originalPosition, uint256 indexed positionToAdd);

    event TransferredToAllocationManager(uint256 amount);

    event SplitPosition(address indexed nftPool, uint256 indexed tokenId, uint256 indexed splitAmount);

    event MigratedToNewNitroPool(uint256 indexed tokenId, address indexed oldNitroPool, address indexed newNitroPool);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ERRORS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error TokenNotAllowed(address spNFT);
    error NotValidNitroPool(address nftPool);
    error CallerIsNotOwner();
    error TokenInNitroPool();
    error NotInNitroPool();
    error ZeroAddress();
    error PositionManagerDoesntOwn();
    error WithdrawalUnauthorized();
    error NotEnoughBalance(uint256 balance, uint256 requestedAmount);
    error ZeroAmount();
    error InvalidNitroPool();
    error Unauthorized();
    error DifferentNFTPools();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @dev initializes CPM
     * @param _whitelistController is the whitelist controller contract
     * @param _holy is the holy token contract
     * @param _treasury is the treasury address
     * @param _xpLp is the address of the XP-ETH LP token
     * @param _zap is the address of the zap contract
     */
    function init(
        IWhitelistController _whitelistController,
        HolyToken _holy,
        address _treasury,
        address _xpLp,
        address _zap
    ) external initializer {
        __ERC721_init("Isekai Camelot Position", "ICP");
        __Governable_init(msg.sender);
        __ReentrancyGuard_init();
        __initializeLiquidityPoolHandler(_zap);

        whitelistController = _whitelistController;
        holy = _holy;
        treasury = _treasury;
        xpLp = _xpLp;
        mirrorPoolIncentive = 97;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        EXTERNAL Methods                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Returns true if "tokenId" is an existing ICP tokenId
     * @param _tokenId ICP tokenId to check
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev deposit spNFT positions on behalf of self or to another user
     * @param _to is the receiver of the ICP Token corresponding to the deposited spNFT
     * @param _nftPool is the nftPool address for the spNFT
     * @param _tokenId is the spNFT tokenId to be deposited
     * @param _addToNitro boolean to determine if the spNFT should be added to the nitro pool
     * @return the ICP tokenId minted to the user
     */
    function deposit(address _to, address _nftPool, uint256 _tokenId, bool _addToNitro)
        external
        nonReentrant
        returns (uint256)
    {
        address lp = _getPoolInfo(_nftPool);

        // Validate that this lp maps to a valid spNFT contract
        address validSpNFT = whitelistController.spNFT(lp).spNFT;

        if (validSpNFT == address(0) || validSpNFT != _nftPool) {
            revert TokenNotAllowed(_nftPool);
        }

        ICamelotNFTPool spNFT = ICamelotNFTPool(_nftPool);

        (uint256 amount,,,,,,,) = spNFT.getStakingPosition(_tokenId);
        if (amount == 0) revert ZeroAmount();

        if (!spNFT.exists(_tokenId)) {
            revert TokenNotAllowed(_nftPool);
        }

        //  If spNFT pool not in array add to it
        if (!isWhitelistedPool[validSpNFT]) {
            isWhitelistedPool[validSpNFT] = true;
        }

        if (!allowedContracts[msg.sender]) {
            // Receive user spNFT
            IERC721(_nftPool).transferFrom(msg.sender, address(this), _tokenId);
        } else {
            // Ensure we have receive the `naked` transfer from the allowed contract
            if (IERC721(_nftPool).ownerOf(_tokenId) != address(this)) {
                revert PositionManagerDoesntOwn();
            }
        }

        _nftToSpNFT[_mintNextTokenId(_to)] = IsekaiCamelotNFT(_tokenId, validSpNFT, false);

        uint256 userToken = _tokenIds.current();

        // Update totalDepositAmount for this NFT Pool by the amount of underlying LP
        totalDepositAmount[validSpNFT] += amount;

        _checkIfIsIncentivized(validSpNFT, msg.sender, amount, true);
        // Check to make sure there is a published nitroPool
        address nitroPool = getValidNitroPool(validSpNFT, false);

        if ((_addToNitro || nitroPool == xpLp) && !whitelistController.emergencyScenarioNp(nitroPool)) {
            _depositToNitroPool(userToken);
        }

        isekaiCPTokenId[validSpNFT][_tokenId] = userToken;

        emit Deposit(validSpNFT, _tokenId, userToken, msg.sender, _to, _addToNitro, nitroPool);

        return userToken;
    }

    /**
     * @notice  add spNFT position to caller's existing ICP token position
     * @dev     Can only be called by ICP token owner or operators
     * @param   _nftPool a valid nft pool
     * @param   _existingPosition ICP tokenId to be merged with spNFT
     * @param   _positionToAdd spNFT tokenId
     */
    function addToPosition(address _nftPool, uint256 _existingPosition, uint256 _positionToAdd) external nonReentrant {
        _requireOnlyOperatorOrOwnerOf(_existingPosition);
        IsekaiCamelotNFT memory existingPosition = _nftToSpNFT[_existingPosition];

        if (existingPosition.inNitroPool) revert TokenInNitroPool();

        uint256 originalPosition = existingPosition.id;

        // Prevent a user from possibly merging positions they do not own
        if (existingPosition.NFTPool != _nftPool) revert DifferentNFTPools();

        if (!allowedContracts[msg.sender]) {
            // When compounding, we make a transferFrom(compounder, address(this),)
            if (msg.sender != IERC721(_nftPool).ownerOf(_positionToAdd)) {
                revert CallerIsNotOwner();
            }

            // Transfer spNFT to this contract
            IERC721(_nftPool).transferFrom(msg.sender, address(this), _positionToAdd);
        }

        ICamelotNFTPool nftPool = ICamelotNFTPool(_nftPool);
        (uint256 amount,,,,,,,) = nftPool.getStakingPosition(_positionToAdd);

        // Update isekaiCPTokenId accounting so that we can harvest rewards
        isekaiCPTokenId[_nftPool][_positionToAdd] = _existingPosition;

        // Merge spNFT to existing ICP token
        _handleMergePosition(_nftPool, originalPosition, _positionToAdd);

        totalDepositAmount[_nftPool] += amount;

        _checkIfIsIncentivized(_nftPool, msg.sender, amount, true);

        address nitroPool = getValidNitroPool(_nftPool, false);

        if (nitroPool == xpLp) {
            _depositToNitroPool(originalPosition);
        }

        emit AddToPosition(msg.sender, _nftPool, _existingPosition);
    }

    /**
     * @notice  merge two ICP tokens owned by caller
     * @dev     Can only be called by ICP token owner or operators
     * @param   _existingPosition ICP tokenId to be merged with another ICP token
     * @param   _positionToAdd ICP tokenId to add
     */
    function mergePosition(uint256 _existingPosition, uint256 _positionToAdd) external nonReentrant {
        _requireOnlyOperatorOrOwnerOf(_existingPosition);
        _requireOnlyOperatorOrOwnerOf(_positionToAdd);

        IsekaiCamelotNFT memory existingPosition = _nftToSpNFT[_existingPosition];
        IsekaiCamelotNFT memory positionToAdd = _nftToSpNFT[_positionToAdd];

        if (existingPosition.inNitroPool || positionToAdd.inNitroPool) {
            revert TokenInNitroPool();
        }

        if (existingPosition.NFTPool != positionToAdd.NFTPool) revert DifferentNFTPools();

        uint256 originalPosition = existingPosition.id;
        uint256 additionalPosition = positionToAdd.id;

        if (mirrorPoolIncentives.isIncentivized(positionToAdd.NFTPool)) {
            (uint256 amount,,,,,,,) = ICamelotNFTPool(positionToAdd.NFTPool).getStakingPosition(positionToAdd.id);
            //decrement the amount from the owner of the position to be added
            mirrorPoolIncentives.harvest(positionToAdd.NFTPool, ownerOf(_positionToAdd), amount, false);

            //increment the amount to the owner of the original position
            mirrorPoolIncentives.harvest(positionToAdd.NFTPool, ownerOf(_existingPosition), amount, true);
        }

        // Merge two ICP tokens -> merge two underlying spNFTS
        _handleMergePosition(existingPosition.NFTPool, originalPosition, additionalPosition);

        // Burn token after because we need the position for onNFTHarvest accounting
        _burn(_positionToAdd);

        emit MergePosition(msg.sender, originalPosition, additionalPosition);
    }

    /**
     * @notice split position into two ICP tokens
     * @param _tokenId ICP to split
     * @param _splitAmount the amount to be removed from the original position and added to the *                     new position
     * @param _to the address to send the newly created ICP token to
     */
    function splitPosition(uint256 _tokenId, uint256 _splitAmount, address _to)
        external
        nonReentrant
        returns (uint256)
    {
        _requireOnlyOperatorOrOwnerOf(_tokenId);
        if (_splitAmount == 0) revert ZeroAmount();

        IsekaiCamelotNFT memory positionData = _nftToSpNFT[_tokenId];

        /**
         *  get the spnft position value and check that it is greater than the requested
         *  split amount
         */
        ICamelotNFTPool nftPool = ICamelotNFTPool(positionData.NFTPool);
        (uint256 amount,,,,,,,) = nftPool.getStakingPosition(positionData.id);

        if (amount <= _splitAmount) {
            revert NotEnoughBalance(amount, _splitAmount);
        }

        nftPool.splitPosition(positionData.id, _splitAmount);
        uint256 newTokenId = nftPool.lastTokenId();

        _nftToSpNFT[_mintNextTokenId(_to)] = IsekaiCamelotNFT(newTokenId, address(nftPool), false);

        isekaiCPTokenId[address(nftPool)][newTokenId] = _tokenIds.current();

        // If pool is incentivized and _to is not caller then we harvest and update user's allocations
        _checkIfIsIncentivized(address(nftPool), _to, _splitAmount);

        emit SplitPosition(address(nftPool), newTokenId, _splitAmount);

        return _tokenIds.current();
    }

    /**
     * @notice required callback per Camleot NFTPool contract
     *         should only be called by whitelisted nftPools
     * @param _tokenId is the spNFT token for which we are harvesting
     * @param _grailAmount is the amount of GRAIL rewards to be sent to the user
     * @param _xGrailAmount is the value used to calculate the mintable amount of
     *                      HOLY to send to the user
     */
    function onNFTHarvest(address, address, uint256 _tokenId, uint256 _grailAmount, uint256 _xGrailAmount)
        external
        returns (bool)
    {
        if (!isWhitelistedPool[msg.sender]) revert Unauthorized();

        address recipient = ownerOf(isekaiCPTokenId[msg.sender][_tokenId]);

        uint256 holyMinted;

        IERC20(GRAIL).transfer(recipient, _grailAmount);

        if (allocationManager != address(0) && sendToAllocationManager) {
            IAllocationManager(allocationManager).addToAllocation(address(this), address(xGRAIL), _xGrailAmount);

            holyMinted = holy.mint(recipient, _xGrailAmount);
        }

        emit HarvestedRewards(holyMinted, recipient, _nftToSpNFT[_tokenId].NFTPool, _tokenId);

        return true;
    }

    /**
     * @dev initiate withdraw user spNFT from position manager
     * @param _tokenId ICP tokenId that corresponds to spNFT
     */
    function withdraw(uint256 _tokenId) external nonReentrant {
        _requireOnlyOperatorOrOwnerOf(_tokenId);

        IsekaiCamelotNFT memory spNFTInfo = _nftToSpNFT[_tokenId];

        address nftPool = spNFTInfo.NFTPool;

        (uint256 amount,, uint256 startLockTime, uint256 lockDuration,,,,) =
            ICamelotNFTPool(nftPool).getStakingPosition(spNFTInfo.id);

        if (block.timestamp < startLockTime + lockDuration) {
            revert WithdrawalUnauthorized();
        }

        if (spNFTInfo.inNitroPool) _withdrawFromNitroPool(_tokenId);

        // Allow whitelisted mirror pools to bypass withdraw incentive
        if (!whitelistedMirrorPool[nftPool]) {
            // This is an incentive on the underlying LP token. Starts at 0.97%
            uint256 incentiveAmount = (amount * mirrorPoolIncentive) / BASIS_POINTS;

            // Incentive take happens here and rewards are harvested for user
            ICamelotNFTPool(nftPool).withdrawFromPosition(spNFTInfo.id, incentiveAmount);

            address lpToken = _getPoolInfo(nftPool);

            // Remove liquidity and convert tokens to WETH & send to treasury
            _removeAndConsolidateIntoWrappedEther(lpToken, incentiveAmount);

            uint256 amountToTreasury = IERC20(WETH).balanceOf(address(this));

            IERC20(WETH).transfer(treasury, amountToTreasury);
        }

        // Burn token
        _burn(_tokenId);

        (amount,,,,,,,) = ICamelotNFTPool(nftPool).getStakingPosition(spNFTInfo.id);
        totalDepositAmount[nftPool] -= amount;

        if (amount > 0) {
            // Send spNFt back to user
            IERC721(nftPool).transferFrom(address(this), msg.sender, spNFTInfo.id);
        }

        _checkIfIsIncentivized(nftPool, msg.sender, amount, false);

        emit Withdrawal(nftPool, _tokenId, msg.sender);
    }

    /**
     * @notice takes in ICP token and deposits corresponding spNFT into its nitro pool
     * @param _tokenId is the ICP token that corresponds to the users spNFT
     */
    function depositToNitroPool(uint256 _tokenId) external nonReentrant {
        _depositToNitroPool(_tokenId);
    }

    function migrateToNewNitroPool(address _from, uint256 _tokenId) external nonReentrant {
        _requireOnlyOperatorOrOwnerOf(_tokenId);

        IsekaiCamelotNFT memory spNFT = _nftToSpNFT[_tokenId];

        uint256 tokenId = spNFT.id;
        address nftPool = spNFT.NFTPool;

        if (!spNFT.inNitroPool) revert NotInNitroPool();

        address lp = _getPoolInfo(nftPool);

        address collector = rewardsCollectorFactory.getUserCollector(msg.sender);

        _checkIfCollectorExists(collector);

        // Validate that this lp maps to a valid spNFT contract
        address nitroPool = whitelistController.spNFT(lp).nitroPool;

        uint256 amountToMint = IRewardsCollector(collector).harvest(nitroPool);

        address oldNitroPool = whitelistController.spNFT(lp).lastNitroPool;

        amountToMint += IRewardsCollector(collector).harvest(oldNitroPool);

        uint256 collectorBalance = xGRAIL.balanceOf(collector);

        if (collectorBalance > 0 && sendToAllocationManager) {
            IAllocationManager(allocationManager).addToAllocation(collector, address(xGRAIL), collectorBalance);

            holy.mint(msg.sender, amountToMint);
        }

        bool isInMapping = whitelistController.contains(lp, _from);
        bool hasAlreadyMigrated = migratedOldNp[_tokenId][_from];

        if (!isInMapping && hasAlreadyMigrated) {
            revert InvalidNitroPool();
        }

        IRewardsCollector(collector).migrate(nftPool, _from, nitroPool, tokenId);

        migratedOldNp[_tokenId][_from] = true;

        emit MigratedToNewNitroPool(tokenId, oldNitroPool, nitroPool);
    }

    /**
     * @notice withdraw spNFT from nitro pool
     * @param _tokenId ICP tokenId to corresponding spNFT
     */
    function withdrawFromNitroPool(uint256 _tokenId) external nonReentrant {
        _withdrawFromNitroPool(_tokenId);
    }

    function setMirrorPoolIncentive(uint256 _incentive) external onlyGovernor {
        mirrorPoolIncentive = _incentive;
    }

    /**
     * @notice used to receive spNFTs when user elects to split ICP
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    //For incentive handling
    function onNFTWithdraw(address, uint256, uint256) external pure returns (bool) {
        return true;
    }

    function setAddresses(
        address _rewardsCollectorFactory,
        address _allocationManager,
        address _xpLpStaking,
        address _mirrorPoolIncentives,
        address _xpLp
    ) external onlyGovernor {
        if (
            _rewardsCollectorFactory == address(0) || _allocationManager == address(0) || _xpLpStaking == address(0)
                || _mirrorPoolIncentives == address(0) || _xpLp == address(0)
        ) {
            revert ZeroAddress();
        }

        if (allocationManager != address(0)) {
            // Set allowance to zero for current alloManager
            xGRAIL.approve(allocationManager, 0);
        }

        allocationManager = _allocationManager;
        // Give new allocationManager max approval
        xGRAIL.approve(allocationManager, type(uint256).max);

        rewardsCollectorFactory = IRewardsCollectorFactory(_rewardsCollectorFactory);
        xpLpStaking = IXperiencePointsLpStaking(_xpLpStaking);
        mirrorPoolIncentives = IMirrorPoolIncentives(_mirrorPoolIncentives);
        xpLp = _xpLp;
    }

    function setWhitelistedContract(address _contract, bool _isWhitelisted) external onlyGovernor {
        allowedContracts[_contract] = _isWhitelisted;
    }

    function setWhitelistedMirrorPool(address _spNft, bool _isWhitelisted) external onlyGovernor {
        whitelistedMirrorPool[_spNft] = _isWhitelisted;
    }

    /**
     * @notice transfers xGRAIL to allocation manager
     */
    function transferXGrailToAllocationManager() external onlyGovernor {
        if (allocationManager == address(0)) revert ZeroAddress();

        uint256 amount = xGRAIL.balanceOf(address(this));

        IAllocationManager(allocationManager).addToAllocation(address(this), address(xGRAIL), amount);

        emit TransferredToAllocationManager(amount);
    }

    function setSendToAllocationManagerFlag() external onlyGovernor {
        sendToAllocationManager = !sendToAllocationManager;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        PUBLIC Methods                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    /**
     * @notice harvest rewards for owned or managed spNFTs
     * @param _nftId ICP token that corresponds to user's spNFT
     */
    function harvest(uint256 _nftId) public nonReentrant {
        _requireOnlyOperatorOrOwnerOf(_nftId);

        address realOwner = ownerOf(_nftId);

        IsekaiCamelotNFT memory spNFT = _nftToSpNFT[_nftId];
        require(spNFT.id != 0, "INVALID NFT ID");

        ICamelotNFTPool(spNFT.NFTPool).harvestPosition(spNFT.id);

        _checkIfIsIncentivized(spNFT.NFTPool, realOwner, 0, false);
    }

    /**
     * @notice harvest rewards for user nitro pool collector
     * @param _nftPool NFTPool address for which rewards should be harvested
     */
    function harvestFromNitroPool(address _nftPool) public nonReentrant {
        address lp = _getPoolInfo(_nftPool);

        address collector = rewardsCollectorFactory.getUserCollector(msg.sender);

        _checkIfCollectorExists(collector);

        // Validate that this lp maps to a valid spNFT contract
        address nitroPool = whitelistController.spNFT(lp).nitroPool;

        uint256 amountToMint = IRewardsCollector(collector).harvest(nitroPool);

        uint256 collectorBalance = xGRAIL.balanceOf(collector);

        _checkIfIsIncentivized(_nftPool, msg.sender, 0, false);

        if (collectorBalance > 0 && sendToAllocationManager) {
            IAllocationManager(allocationManager).addToAllocation(collector, address(xGRAIL), collectorBalance);

            holy.mint(msg.sender, amountToMint);
        }

        emit HarvestedNitroPoolRewards(msg.sender, nitroPool);
    }

    /**
     * @notice checks to make sure there is an associated nitroPool corresponding to this nftPool
     * @param _nftPool the nft pool to check
     */
    function getValidNitroPool(address _nftPool, bool _checkZeroAddress) public view returns (address) {
        address lp = _getPoolInfo(_nftPool);

        address nitroPool = whitelistController.spNFT(lp).nitroPool;

        if (_checkZeroAddress && nitroPool == address(0)) revert NotValidNitroPool(_nftPool);

        return nitroPool;
    }

    function nftToSpNFT(uint256 _tokenId) public view returns (IsekaiCamelotNFT memory) {
        return _nftToSpNFT[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return interfaceId == type(AccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INTERNAL Methods                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Mints a tokenised Isekai position to an address
     * @param _to address to mint ICP token to
     */
    function _mintNextTokenId(address _to) private returns (uint256 tokenId) {
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(_to, tokenId);
    }

    /**
     * @notice takes in ICP token and deposits corresponding spNFT into its nitro pool
     * @param _tokenId is the ICP token that corresponds to the users spNFT
     */
    function _depositToNitroPool(uint256 _tokenId) private {
        bool isAllowedContract = allowedContracts[msg.sender];

        address realOwner = ownerOf(_tokenId);

        _checkIfIsAllowedContract(isAllowedContract, _tokenId);

        IsekaiCamelotNFT storage spNFT = _nftToSpNFT[_tokenId];

        uint256 tokenId = spNFT.id;
        address nftPool = spNFT.NFTPool;

        // Check to make sure there is a published nitroPool
        address nitroPool = getValidNitroPool(nftPool, true);

        address collector = rewardsCollectorFactory.getUserCollector(realOwner);

        if (collector == address(0)) {
            collector = rewardsCollectorFactory.createCollector(realOwner);
        }

        IERC721(nftPool).safeTransferFrom(address(this), collector, tokenId, abi.encode(nitroPool, nftPool));

        IRewardsCollector(collector).deposit(nftPool, nitroPool, tokenId);

        spNFT.inNitroPool = true;

        // Emitting msg.sender even if it's a allowed contract call because we want to know who is real owner
        emit DepositToNitroPool(tokenId, _tokenId, nitroPool, msg.sender, nftPool);
    }

    /**
     * @notice withdraw spNFT from nitro pool
     * @param _tokenId ICP tokenId to corresponding spNFT
     */
    function _withdrawFromNitroPool(uint256 _tokenId) private {
        bool isAllowedContract = allowedContracts[msg.sender];

        // If it's an allowed contract, we want to know who the real owner is
        // in order to perform operations like changing NPs
        _checkIfIsAllowedContract(isAllowedContract, _tokenId);

        IsekaiCamelotNFT storage spNFT = _nftToSpNFT[_tokenId];
        uint256 tokenId = spNFT.id;
        address nftPool = spNFT.NFTPool;

        // Check to make sure there is a published nitroPool
        address nitroPool = getValidNitroPool(nftPool, true);

        if (nitroPool == xpLp && !isAllowedContract) {
            address ownerOfToken = ownerOf(_tokenId);

            uint256 incentive = xpLpStaking.finalizeUnstake(_tokenId, ownerOfToken);

            // Incentive take happens here and rewards are harvested for user
            if (incentive > 0) {
                _checkIfIsIncentivized(nftPool, ownerOfToken, incentive, false);
                ICamelotNFTPool(nftPool).withdrawFromPosition(tokenId, incentive);

                address lpToken = _getPoolInfo(nftPool);
                _removeLiquidity(lpToken, incentive);

                address token0 = ICamelotPair(lpToken).token0();
                address token1 = ICamelotPair(lpToken).token1();

                // Once we remove liquidity and split LP send both token balances to treasury
                IERC20(token0).transfer(treasury, IERC20(token0).balanceOf(address(this)));
                IERC20(token1).transfer(treasury, IERC20(token1).balanceOf(address(this)));
            }

            totalDepositAmount[nftPool] -= incentive;

            // If amount of underlying spnft == 0 we burn the user's ICP token
            (uint256 amount,,,,,,,) = ICamelotNFTPool(nftPool).getStakingPosition(tokenId);
            if (amount == 0) _burn(_tokenId);
        } else {
            // If msg.sender is governor, it means we are going through a migration of the nitro pool
            // This means that we will move the NFT held by the system, which the governor will not be governor
            address realOwner = ownerOf(_tokenId);

            _checkIfIsAllowedContract(isAllowedContract, _tokenId);

            address collector = rewardsCollectorFactory.getUserCollector(realOwner);

            _checkIfCollectorExists(collector);

            // Call to user's rewards collector
            IRewardsCollector(collector).withdraw(nftPool, nitroPool, tokenId);
        }

        // Accounting to track nitro pool status
        spNFT.inNitroPool = false;

        emit WithdrawFromNitroPool(nitroPool, tokenId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        PRIVATE Methods                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice checks to make sure there is an associated nitroPool corresponding to this nftPool
     * @param _nftPool spNFT address
     * @param _existingPosition primary position
     * @param _positionToAdd secondary position
     */
    function _handleMergePosition(address _nftPool, uint256 _existingPosition, uint256 _positionToAdd) private {
        uint256[] memory tokenIds = new uint256[](2);

        tokenIds[0] = _existingPosition;
        tokenIds[1] = _positionToAdd;

        // 0 represents the lock duration for user's merged spNFT
        ICamelotNFTPool(_nftPool).mergePositions(tokenIds, 0);
    }

    /**
     * @notice get lp for a given pool
     * @param _nftPool the nft pool to check
     */
    function _getPoolInfo(address _nftPool) private view returns (address) {
        ICamelotNFTPool spNFT = ICamelotNFTPool(_nftPool);

        (address lp,,,,,,,) = spNFT.getPoolInfo();

        return lp;
    }

    /**
     * @dev Check if a userAddress has privileged rights on a spNFT
     * @param _tokenId ICP tokenId to check
     */
    function _requireOnlyOperatorOrOwnerOf(uint256 _tokenId) private view {
        // isApprovedOrOwner: caller has no rights on token
        if (!_isApprovedOrOwner(msg.sender, _tokenId)) revert Unauthorized();
    }

    function _checkIfCollectorExists(address _collector) private pure {
        if (_collector == address(0)) revert ZeroAddress();
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _firstTokenId, uint256) internal override {
        IsekaiCamelotNFT memory spNFTInfo = _nftToSpNFT[_firstTokenId];

        if (spNFTInfo.inNitroPool && _to != address(0)) _withdrawFromNitroPool(_firstTokenId);

        if (_from != address(0) && _to != address(0)) harvest(_firstTokenId);

        uint256 amount;

        if (spNFTInfo.NFTPool != address(0)) {
            (amount,,,,,,,) = ICamelotNFTPool(spNFTInfo.NFTPool).getStakingPosition(spNFTInfo.id);
        }

        _checkIfIsIncentivized(spNFTInfo.NFTPool, _to, amount);
    }

    function _checkIfIsAllowedContract(bool _isAllowedContract, uint256 _tokenId) private view {
        if (!_isAllowedContract) _requireOnlyOperatorOrOwnerOf(_tokenId);
    }

    /// @dev If pool is incentivized and _to is not caller then we harvest and update user's allocations
    function _checkIfIsIncentivized(address _spNFT, address _to, uint256 _amount) private {
        if (mirrorPoolIncentives.isIncentivized(_spNFT) && _to != address(0)) {
            // Decrement caller's totalAllocation in mirrorPoolIncentives
            mirrorPoolIncentives.harvest(_spNFT, msg.sender, _amount, false);

            // Increment _to's totalAllocation in mirrorPoolIncentives
            mirrorPoolIncentives.harvest(_spNFT, _to, _amount, true);
        }
    }

    function _checkIfIsIncentivized(address _spNFT, address _owner, uint256 _amount, bool _add) private {
        if (mirrorPoolIncentives.isIncentivized(_spNFT)) {
            mirrorPoolIncentives.harvest(_spNFT, _owner, _amount, _add);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.20;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } { sstore(sc, mload(mc)) }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for { let cc := add(_postBytes, 0x20) }
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

interface IGammaUniProxyHelper {
    function deposit(
        address token0,
        address token1,
        uint256 deposit0,
        uint256 deposit1,
        address pos,
        uint256[4] memory minIn,
        address nftPool,
        uint256 lockDuration
    ) external;

    /// @param token -> other token
    /// @param amountEnd -> token we want amount
    function getDepositAmount(address pos, address token, uint256 _deposit)
        external
        view
        returns (uint256 amountStart, uint256 amountEnd);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IQuoter} from "src/interfaces/IQuoter.sol";
import {ICamelotPair} from "src/interfaces/ICamelotPair.sol";
import {BytesLib} from "src/crosschain/layer-zero/BytesLib.sol";

/// @title IsekaiSimulator
/// @notice Supports quoting the calculated amounts out from Uniswap/Camelot V2/V3
/// @dev These functions are not marked view because some inner functions rely on calling non-view functions and reverting
library IsekaiSimulator {
    IQuoter public constant CAMELOT_V3_QUOTER = IQuoter(0x0Fc73040b26E9bC8514fA028D998E73A254Fa76E);

    enum Platform {
        Camelot__V2,
        Camelot__V3
    }

    function getAmountOut(Platform _platform, bytes memory _path, address pair, uint256 _amountIn)
        external
        returns (uint256 amountOut)
    {
        address tokenIn = BytesLib.toAddress(_path, 0);

        if (_platform == Platform.Camelot__V2) {
            amountOut = ICamelotPair(pair).getAmountOut(_amountIn, tokenIn);
        } else if (_platform == Platform.Camelot__V3) {
            // Fist param: The path of the swap, i.e. each token pair
            // Second param: The amount of the first token to swap
            // amountOut: The amount of the last token that would be received
            (amountOut,) = CAMELOT_V3_QUOTER.quoteExactInput(_path, _amountIn);
        }
    }

    function getAmountIn(Platform _platform, bytes memory _path, address pair, uint256 _amountOut)
        external
        returns (uint256 amountIn)
    {
        if (_platform == Platform.Camelot__V2) {
            //amountIn = ICamelotPair(pair).getAmountIn(_amountOut, tokenIn);
        } else if (_platform == Platform.Camelot__V3) {
            (amountIn,) = CAMELOT_V3_QUOTER.quoteExactOutput(_path, _amountOut);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";

interface INFTPOOL {
    function getPoolInfo()
        external
        view
        returns (
            address lpToken,
            address grailToken,
            address sbtToken,
            uint256 lastRewardTime,
            uint256 accRewardsPerShare,
            uint256 lpSupply,
            uint256 lpSupplyWithMultiplier,
            uint256 allocPoint
        );

    function getStakingPosition(uint256 tokenId)
        external
        view
        returns (
            uint256 amount,
            uint256 amountWithMultiplier,
            uint256 startLockTime,
            uint256 lockDuration,
            uint256 lockMultiplier,
            uint256 rewardDebt,
            uint256 boostPoints,
            uint256 totalMultiplier
        );

    function mergePositions(uint256[] calldata tokenIds, uint256 lockDuration) external;
    function harvestPosition(uint256 tokenId) external;
    function lastTokenId() external view returns (uint256);
    function withdrawFromPosition(uint256 tokenId, uint256 amount) external;
    function createPosition(uint256 amount, uint256 lockDuration) external;
}

interface IDefiEdge {
    function depositETH(
        ERC20 token0,
        ERC20 token1,
        uint256 deposit0,
        uint256 deposit1,
        uint256 deposit0Min,
        uint256 deposit1Min,
        uint256 minShare,
        address strategy,
        INFTPOOL nftPool,
        uint256 lockDuration
    ) external payable;

    function deposit(
        ERC20 token0,
        ERC20 token1,
        uint256 deposit0,
        uint256 deposit1,
        uint256 deposit0Min,
        uint256 deposit1Min,
        uint256 minShare,
        address strategy,
        INFTPOOL nftPool,
        uint256 lockDuration
    ) external;

    function pool() external view returns (address);
}

interface IDefiEdgeStrategy {
    function burn(uint256 _shares, uint256 _amount0Min, uint256 _amount1Min)
        external
        returns (uint256 collect0, uint256 collect1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract UpgradeableGovernable is AccessControlUpgradeable {
    /**
     * @notice Governor role
     */
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    /**
     * @notice Initialize Governable contract.
     */
    function __Governable_init(address _governor) internal onlyInitializing {
        __AccessControl_init();
        _grantRole(GOVERNOR, _governor);
    }

    /**
     * @notice Modifier if msg.sender has not Governor role revert.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    /**
     * @notice Update Governor Role
     */
    function updateGovernor(address _newGovernor) external virtual onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    /**
     * @notice If msg.sender has not Governor role revert.
     */
    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
    function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IIsekaiZap} from "./IIsekaiZap.sol";

interface IWhitelistController {
    struct CamelotFarm {
        // @param Camelot deposit LPs
        address spNFT;
        // @param The pool might have a nitropool where we should deposit into, if not it will be set as address(0)
        address nitroPool;
        // @param query this in case we need to migrate to new nitro pool
        address lastNitroPool;
    }

    struct NitroPoolInfo {
        IIsekaiZap.TYPE routerTypeToken1;
        IIsekaiZap.TYPE routerTypeToken2;
    }

    struct MirrorPoolTokensInfo {
        IIsekaiZap.TYPE routerTypeToken1;
        IIsekaiZap.TYPE routerTypeToken2;
    }

    struct PathAndType {
        bytes path;
        IIsekaiZap.TYPE routerType;
    }

    struct LpTokenInfo {
        CamelotFarm camelotFarm;
        IIsekaiZap.TYPE routerType;
        NitroPoolInfo nitroPoolInfo;
        PathAndType pathAndTypeToken0;
        PathAndType pathAndTypeToken1;
        bool canHaveCompounder;
    }

    function addSupportedLpToken(
        address _lp,
        CamelotFarm memory _camelotFarm,
        IIsekaiZap.TYPE _routerType,
        NitroPoolInfo memory _nitroPoolInfo,
        PathAndType[2] calldata _pathAndType,
        bool defiEdge,
        bool canPairHaveToken
    ) external;

    function getRouterTypeForMirrorPoolTokens(address _mirrorPoolToken) external view returns (IIsekaiZap.TYPE);

    function getNitroPoolFromSpNFT(address _spNFT) external view returns (address);

    function getTokenPathToWrappedEther(address _token) external view returns (PathAndType memory);

    function removeSupportedLpToken(address _lp) external;

    function getRouterTypeForSpNFT(address _spNFT) external view returns (IIsekaiZap.TYPE);

    function spNFT(address _lp) external view returns (CamelotFarm memory);

    function getRouterTypeForNitroTokens(address _spNFT) external view returns (NitroPoolInfo memory);

    function updateSupportedLpTokenNitroPool(
        address _lp,
        address _newNitroPool,
        NitroPoolInfo calldata _newNitroPoolInfo
    ) external;

    function canPairHaveCompounder(address _lp) external view returns (bool);

    function contains(address _lp, address _np) external view returns (bool);

    function emergencyScenarioNp(address _np) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IRewardsCollectorFactory {
    function getUserCollector(address _user) external returns (address);

    function createCollector(address _user) external returns (address);

    function rewardsCollectors() external returns (address[] memory);

    function getRewardsCollectors() external returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IRewardsCollector {
    function deposit(address _nftPool, address _nitroPool, uint256 _tokenId) external;

    function withdraw(address _nftPool, address _nitroPool, uint256 _tokenId) external;

    function harvest(address _nitroPool) external returns (uint256);

    function migrate(address _nftPool, address _oldNitroPool, address _newNitroPool, uint256 _tokenId) external;

    function harvestFromSpNft(address _nftPool, uint256 _tokenId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

interface IXperiencePointsLpStaking {
    function isRedeemable(uint256 _tokenId) external view returns (bool, uint256);

    function finalizeUnstake(uint256 _tokenId, address _owner) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";

interface IAllocationManager {
    struct Epoch {
        uint256 nextEpochAllocation;
        uint256 currentEpochAllocation;
        uint256 lastEpochAllocation;
    }

    struct Deposits {
        uint256 currentEpochDeposits;
        uint256 lastDepositEpoch;
    }

    struct Claims {
        uint256 claimableAmount;
        uint256 lockedAmount;
        uint256 lastClaimPeriod;
    }

    /**
     * @notice adds to the managed amount of a supported token
     * @dev used for accounting purposes
     * @param _from the address to transfer supported tokens from
     * @param _underlyingToken token supported by Isekai
     * @param _amount to deposit
     */
    function addToAllocation(address _from, address _underlyingToken, uint256 _amount) external;

    /**
     * @notice allocates underlying token to corresponding protocol plugins using HOLY as a proxy
     * @param _usageAddress Isekai plugin proxy
     * @param _amount amount of HOLY to allocate
     * @param _data optional field determined by the given plugin
     */
    function allocate(address _usageAddress, uint256 _amount, bytes calldata _data) external;

    function currentEpoch() external view returns (uint256);

    /**
     * @notice deallocate from plugin position
     * @param usageAddress Isekai plugin proxy
     * @param amount of HOLY to be deallocated
     * @param data optional data to be sent with call
     */
    function deallocate(address usageAddress, uint256 amount, bytes calldata data) external;

    function mintHoly(address _recipient, uint256 _amount) external returns (uint256);

    function HOLY() external view returns (ERC20);
}

/*
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I

                        異世界

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IIsekaiZap} from "./interfaces/IIsekaiZap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICamelotNFTPool} from "src/interfaces/ICamelotNFTPool.sol";
import {HolyToken} from "src/tokens/HolyToken.sol";
import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";

abstract contract LiquidityPoolHandler {
    using SafeTransferLib for ERC20;

    IIsekaiZap internal zap;

    address internal constant GRAIL = 0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8;
    address internal constant USDC_E = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /// @notice Holy token
    HolyToken internal holy;

    function __initializeLiquidityPoolHandler(address _zap) internal {
        zap = IIsekaiZap(_zap);
    }

    function _removeLiquidity(address _lp, uint256 _amount) internal {
        ERC20(_lp).safeTransfer(address(zap), _amount);
        zap.removeLiquidity(_lp, _amount);
    }

    function _removeAndConsolidateIntoWrappedEther(address _lp, uint256 _amount) internal returns (uint256) {
        ERC20(_lp).safeTransfer(address(zap), _amount);

        return zap.removeAndConsolidateIntoWrappedEther(_lp, _amount);
    }

    /**
     * @notice Swap Grail/Holy received from harvesting ICP into Wrapped Ether
     * @param _amountInGrail Amount of Grail received from harvest
     * @param _amountInHoly Amount of Holy received from harvest
     * @return Amount of Wrapped Ether received
     */
    function _swapRewardsToWrappedEther(uint256 _amountInGrail, uint256 _amountInHoly) internal returns (uint256) {
        // Since most liquid Grail pool is Grail/Usdc, lets make a multi hop swap Grail -> USDC.E -> WETH
        address[] memory path = new address[](3);
        path[0] = address(GRAIL);
        path[1] = address(USDC_E);
        path[2] = address(WETH);

        // Perform swap for Grail
        IERC20(GRAIL).approve(address(zap), _amountInGrail);
        uint256 receivedWrappedEtherFromGrail = zap.swapMultiHop(path, _amountInGrail, IIsekaiZap.TYPE.UNI_V3);

        // Holy most liquid venue is a V2 pool Holy/WETH
        // So we just need to make single hop V2 swap
        IERC20(address(holy)).approve(address(zap), _amountInHoly);

        // Comment this until we have deployed a test holy pool
        uint256 receivedWrappedEtherFromHoly =
            zap.swapSingle(address(holy), WETH, _amountInHoly, IIsekaiZap.TYPE.UNI_V2);

        // Assume if GrailAmount > 0 -> HolyAmount also > 0
        if (receivedWrappedEtherFromGrail == 0) {
            return 0;
        }

        // Received WETH from both swaps
        return receivedWrappedEtherFromGrail + receivedWrappedEtherFromHoly;
    }

    /**
     * @notice Swap nitro tokens to Wrapped Ether
     * @param token1 One of the two tokens yielded in nitro pools
     * @param token2 One of the two tokens yielded in nitro pools
     * @param token1Amount Amount of `token1`
     * @param token2Amount Amount of `token2`
     * @param token1Type If the most liquid venue for token1 -> WETH is a V2/V3 pair
     * @param token2Type If the most liquid venue for token2 -> WETH is a V2/V3 pair
     */
    function _swapNitroTokensToWrappedEther(
        address token1,
        address token2,
        uint256 token1Amount,
        uint256 token2Amount,
        IIsekaiZap.TYPE token1Type,
        IIsekaiZap.TYPE token2Type
    ) internal returns (uint256) {
        // Amount of Ether received from the swaps
        uint256 receivedEtherFromToken1;
        uint256 receivedEtherFromToken2;

        ERC20(token1).safeApprove(address(zap), token1Amount);

        if (token1Amount > 0) {
            receivedEtherFromToken1 = zap.swapSingle(token1, WETH, token1Amount, token1Type);
        }

        // Only swaps if there is a token being emmited (token2 != address(0))
        if (token2 != address(0)) {
            ERC20(token2).safeApprove(address(zap), token2Amount);

            if (token2Amount > 0) {
                receivedEtherFromToken2 = zap.swapSingle(token2, WETH, token2Amount, token2Type);
            }
        }

        return receivedEtherFromToken1 + receivedEtherFromToken2;
    }

    /**
     * @notice Swaps Wrapped Ether to LP but don't wrap into spNFT
     * @param _spNFT The spNFT that we will be building the underlying LP
     * @param _wrappedEtherAmount Amount of WETH
     * @param _routerType If the underlying LP is a V2/V3 pool
     * @return Underlying LP built
     * @return Amount of underlying lp built
     */
    function _buildPairFromWrappedEther(address _spNFT, uint256 _wrappedEtherAmount, IIsekaiZap.TYPE _routerType)
        internal
        returns (address, uint256)
    {
        IERC20(WETH).approve(address(zap), _wrappedEtherAmount);

        // Should receive LP and store amount of underlying
        (address pair, uint256 receivedLiquidityPool) = zap.buildPositionFromToken(
            _spNFT, WETH, _wrappedEtherAmount, _routerType, false, IIsekaiZap.TYPE.UNI_V3 == _routerType ? true : false
        );

        return (pair, receivedLiquidityPool);
    }

    /**
     * @notice Same as `_buildPairFromWrappedEther` but also wraps into spNFT
     * @return tokenId of the minted spNFT
     * @return receivedLiquidityPool Amount of LP held by spNFT of `tokenId`
     * https://docs.camelot.exchange/protocol/staked-positions-spnfts
     */
    function _buildPairFromWrappedEtherAndWrap(address _spNFT, uint256 _wrappedEtherAmount, IIsekaiZap.TYPE _routerType)
        internal
        returns (uint256, uint256)
    {
        (address pair, uint256 receivedLiquidityPool) =
            _buildPairFromWrappedEther(_spNFT, _wrappedEtherAmount, _routerType);

        // If its a V3 position, we already received the spNFT so no need to build it
        if (_routerType == IIsekaiZap.TYPE.UNI_V2) {
            IERC20(pair).approve(_spNFT, receivedLiquidityPool);

            // Use the received LP to wrap it into spNFT and earn extra yield
            ICamelotNFTPool(_spNFT).createPosition(receivedLiquidityPool, 0);
        }

        return (ICamelotNFTPool(_spNFT).lastTokenId(), receivedLiquidityPool);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICamelotPositionManager {
    struct IsekaiCamelotNFT {
        uint256 id;
        address NFTPool;
        bool inNitroPool;
    }

    function nftToSpNFT(uint256 _tokenId) external view returns (IsekaiCamelotNFT memory);
    function getValidNitroPool(address _nftPool, bool _checkZeroAddress) external view returns (address);
    function totalDepositAmount(address _nftPool) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMirrorPoolIncentives {
    function harvest(address _nftPool, address _user, uint256 _amount, bool _add) external;
    function isIncentivized(address _nftPool) external view returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (uint256 amountOut, uint16[] memory fees);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param amountIn The desired input amount
    /// @param limitSqrtPrice The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(address tokenIn, address tokenOut, uint256 amountIn, uint160 limitSqrtPrice)
        external
        returns (uint256 amountOut, uint16 fee);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (uint256 amountIn, uint16[] memory fees);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param amountOut The desired output amount
    /// @param limitSqrtPrice The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(address tokenIn, address tokenOut, uint256 amountOut, uint160 limitSqrtPrice)
        external
        returns (uint256 amountIn, uint16 fee);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/*
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⢿⡿⣿⢿⡿⣿⣻⢿⣻⣟⣿⣻⣽⣻⢯⣟⣯⠿⡽⢯⡿⣝⣯⢻⡽⣭⢯⡽⣭⢻⣭⢻⣭⢻⣭⢻⣭⢻⡝⣯⢻⡝⣯⢻⡽⣭⢋⡷⣉⠒⡔⡰⣌⡳⣭⢳⡹⡜⣂⠆⠀⡀⠠⡄
⣿⣿⣿⣽⣾⣿⣽⣾⣿⣾⣷⣿⣻⣽⣿⣻⣽⡿⣽⣷⣻⢯⣟⣾⣳⣟⡾⣭⣟⡾⣵⣻⣽⣻⣜⣯⣞⣧⢻⡜⣮⢳⣭⢳⣎⠷⣎⢷⢪⢗⣮⢳⣝⣮⣻⡼⣭⣳⡝⣦⢏⠴⡡⣍⠶⣱⢣⣝⠲⡍⠖⠩⠔⢠⢡⠰⡱⢌
⣿⡿⣾⣟⣷⡿⣽⣷⣻⣾⣳⢯⣟⡷⣯⣟⣷⣻⣟⡾⣽⣻⣞⡷⣻⢞⣽⠷⠞⣋⣉⣩⣽⣯⣷⠟⢛⠫⢭⡉⢉⠉⠒⠯⣜⡻⣜⣣⠟⣮⡚⢷⣚⡖⡧⣝⠶⣣⠞⣔⡊⢖⡱⣌⠳⣍⠳⡈⠁⠀⠀⠀⠀⢂⢎⡱⡑⢎
⣿⣟⣷⢿⣯⣟⡿⣞⡷⣯⣟⡿⣾⣽⣳⡟⣾⣳⢯⣟⣳⠿⣼⠽⠛⣩⡴⢞⡛⠭⣑⡯⢛⠡⢂⡍⠦⢹⡧⣝⣦⣻⣒⠤⡀⠉⠓⢮⣛⠶⣹⢧⢳⡞⣵⢫⢞⣥⡛⣤⢋⢦⠳⣌⠳⣌⡑⢂⠀⠀⠀⠀⠀⡜⣢⢱⡉⢆
⣿⣞⣯⢿⡾⣽⣻⣽⣻⢗⣯⣟⢾⡶⢯⣟⣳⢯⣟⣼⡯⢛⣡⡶⢛⠡⠘⢠⣸⠟⣉⠆⠁⠀⠁⠀⢠⡿⠡⣿⡄⢣⢻⣇⠘⣕⢤⠈⠙⢾⡱⢎⡷⣚⣥⠻⡜⢦⣙⢦⣋⢎⡳⢌⠳⡰⢌⠣⡄⠀⢀⠠⡼⣸⢥⠳⣜⠡
⣟⡾⣽⢯⣟⣷⣻⣞⣭⣟⡾⣞⣯⣽⢻⡾⣝⣷⣞⠇⣠⢾⠗⣘⠀⠀⣠⠞⣡⠔⠃⠀⠀⠀⠀⢀⠞⠀⢸⣏⡇⠘⡆⠻⣶⣘⣦⠙⠄⠀⠙⢯⡲⣙⠦⣏⡝⢮⠜⣦⡙⢮⣑⡋⢶⢱⡩⣓⢬⡓⢎⡳⣱⢣⢞⡱⢎⡐
⡿⣽⢯⣟⣾⣳⢯⣞⡷⣯⡽⣞⣧⣟⣻⣼⡿⠱⣃⡞⠃⡡⠖⣁⣴⠟⢁⡜⠁⠀⠀⠀⠀⠀⢀⠎⠀⠀⣼⣻⠁⡀⡇⠀⠈⢳⡽⣷⣄⠑⡈⠀⢻⣬⢛⠴⣊⠇⢯⡰⣙⠦⣣⡙⢦⢣⠳⣌⠶⣙⢮⡱⢣⢏⢎⡱⠂⠀
⡿⣽⣛⣞⡳⣯⢟⡾⡽⣞⣽⣳⠾⣭⢷⣟⢠⡷⢋⡤⠋⣠⡾⠛⡵⡺⠉⠀⢀⠀⡀⠀⠀⢁⠎⠀⠀⢰⣿⢃⢠⢳⡇⠀⠀⠀⠹⡘⢿⣦⡈⢆⠀⠹⡣⡝⢢⡙⠦⡱⡘⢎⡵⣘⢣⡝⢲⡡⠞⡌⡖⣩⠓⠎⠐⠀⠀⠀
⡟⠄⠁⠀⠱⣭⡻⣝⢷⣛⢶⣫⢟⣵⡿⣨⡟⣡⢏⣠⡾⠋⢠⡞⡽⠁⠀⡠⠁⠀⠀⠀⢠⡟⠀⠀⢰⣿⣧⢎⢎⢸⠃⠀⠀⠀⢀⣿⠾⠿⡷⡀⢠⠀⢹⣽⢦⡙⢦⠱⣙⠮⢴⣉⠶⣘⠧⡜⡱⡘⠴⣁⠊⠀⠀⠀⠀⠀
⢦⣀⣀⢠⠖⣧⢻⡝⣮⡝⣮⢳⢫⣾⣱⢟⡸⣥⡾⢋⡄⣠⠏⡰⠀⠀⡰⠁⠀⡠⢀⣴⡟⠀⠌⣠⡟⠁⡼⡀⠈⡜⠀⠀⠀⠀⠀⢸⣄⣀⣹⣌⠄⢇⠘⡿⢮⣳⡌⢳⡡⢞⡡⢎⡱⢃⡞⡰⢥⡙⠆⠄⠀⠀⠀⠀⠀⠀
⢧⡳⢎⡷⢻⡜⣣⢟⡲⡝⣎⡳⣻⡗⣋⢮⣽⢯⡴⠋⣴⢋⡖⡀⢀⣼⠁⢀⢈⣠⣾⠯⠀⣠⣼⣿⣶⣿⣿⣿⣤⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⡄⠸⡄⢹⢧⢳⢻⡡⠞⡬⣑⢎⡱⢍⠲⡑⠦⡑⢈⠀⠀⠀⠀⠀⠀⠀
⢧⣙⡳⣜⡣⢽⡱⢎⣳⡙⢶⡩⣿⢱⣺⡿⣹⢏⠴⣹⢇⡞⣰⢣⣾⢏⡜⢢⣮⡿⢉⣄⣲⣿⣿⣿⠿⣿⣿⡿⣿⠂⠀⠀⠀⠀⣿⣏⣿⡿⣿⣿⣿⡀⢱⠘⡜⠎⣧⢻⡘⠴⡡⢎⠰⢉⠒⡉⠐⡀⢂⠀⠀⠀⠀⠀⠀⠀
⠞⡴⢳⡜⣱⢣⠝⣎⠶⡙⢦⣹⣧⣿⣿⢛⢧⢫⢼⢫⣾⣱⣯⣿⠟⣼⣬⣿⠋⡐⢤⣾⡿⣿⣿⠉⠲⣛⣯⠕⡸⠀⠀⠀⠀⠀⠘⢘⢓⣃⡿⢷⡞⣷⡌⠄⢣⡘⢼⢸⢌⢣⠱⡈⠆⠠⢀⠀⠡⠐⠠⠈⠀⠀⠀⠀⠀⠀
⡹⣜⢣⢞⡱⢊⡳⢌⡚⢥⠓⣼⣷⡟⣥⢋⣎⣷⢎⣽⡿⣭⣿⣵⣿⣫⠞⡁⢦⣽⣾⡉⢑⠢⡉⠛⠒⠚⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⢂⠄⠀⠘⣯⢿⣻⡀⢸⡎⢸⢸⢂⡌⢣⠱⡈⡐⠠⠌⢂⠉⡀⠀⠀⠀⠀⠀⠀⠀
⡱⣊⠜⠢⠁⠃⠘⠠⠙⠢⢙⣴⡿⣘⢦⣻⡾⣽⣾⣿⣷⠿⣿⡵⠟⡁⢮⣴⣿⣻⡿⣿⣿⣷⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⢶⡿⠂⠀⠀⣹⣯⣇⢧⢨⡇⡝⣸⠠⢎⠡⢆⡑⢌⠡⢊⠄⡒⠀⠀⠀⠀⠀⠀⠀⠀
⠴⣁⠎⠀⠀⠀⠀⠀⠀⠀⠀⢿⡶⢯⣿⢯⡿⡽⣬⣷⣾⠿⡋⣴⢥⣿⡿⣋⢾⣿⣷⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣷⣻⠸⡇⣿⡷⢃⡜⢨⠑⡢⠘⡄⢣⠁⢎⡐⡁⠐⠀⠀⠀⠀⠀⠀
⠢⠅⢎⠀⠀⡀⠀⠀⢀⠀⢄⢺⣏⢷⣟⡺⡴⣿⣿⣟⢣⢧⣟⣵⣿⠏⣴⡏⣿⠀⢻⣿⣹⣿⢣⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠖⠛⣻⠇⠀⣸⣿⡧⢹⢸⠃⡟⢡⠂⡜⢠⠃⡔⠣⠘⠤⡉⢢⠐⡌⡐⠀⠀⠀⠀⠀⠀
⢭⣓⠮⣜⣠⠐⡠⠒⠤⣉⠂⢾⣯⢿⡸⡗⣽⣿⡿⣌⣳⣾⣿⡟⣏⢾⡿⣱⣯⣆⠈⣿⣏⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁⠀⠀⠰⢡⡿⢀⡏⣞⢸⢁⠆⡱⢈⠆⡱⠈⢆⠩⠄⡑⠤⢁⠐⠠⠁⠀⠀⠀⠀⠀
⠀⠈⢁⠒⢾⣿⣿⣿⣶⣤⣍⣂⢿⡷⣯⣹⣿⣿⢳⣼⣟⡾⣿⡼⣼⣿⢣⣿⣷⢩⢷⣼⣿⣼⣿⣿⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢢⡟⠁⡼⣸⠇⡏⠰⡈⢄⠃⡔⠠⠉⡄⢊⠤⢁⠂⠄⠈⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠠⠘⣺⣿⣿⣿⣿⣿⣿⣿⣾⣯⣷⡽⣧⣿⡿⣏⣾⡝⡧⣿⡿⣵⣿⢿⣿⢢⠈⠙⢿⣿⢻⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡞⠀⣼⡰⢃⡼⢀⡑⢈⠄⠊⠄⡁⠒⣀⠢⠐⠠⢈⠀⠂⢀⠐⡈⠐⠠⢀⠀
⢿⡶⣦⣤⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣷⣹⣿⢸⡱⣯⣿⣟⢣⣿⣿⡇⠄⠀⠘⣿⣟⣿⣟⠤⢤⣀⡀⠀⠀⠀⠀⠀⠀⠀⣀⡜⢀⣴⠟⣠⠋⣀⠂⡐⠈⠄⠃⠄⡁⠂⠄⢂⠁⡂⠄⠂⠐⠀⢂⠄⡁⠂⠄⠀
⢆⡙⠶⢩⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣿⣻⡷⣾⡿⢹⣿⣇⠂⠀⠀⢹⣿⣹⣿⡇⠀⠈⠉⠙⣿⡿⣾⢞⠿⢋⣡⣴⠿⠉⠈⠄⠂⠄⠂⠄⠡⢈⠐⡈⠄⡁⠊⠄⠡⠀⠀⠀⠀⠀⠀⠂⢄⠁⠂⠀
⠀⢈⠙⠲⠾⣽⣿⣿⣿⣿⣿⣶⣾⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣾⣧⣿⣿⣧⠖⠀⠀⢿⡿⣿⣿⣀⠀⠀⢰⣿⢟⠵⣋⠔⡯⠞⠁⠄⣈⠐⡈⠐⡈⠐⠈⡀⠂⠐⠀⡐⠀⠡⢈⠀⡁⠀⠀⠀⠀⠀⠌⠠⢈⠐⠀
⠀⠀⡀⠀⠀⠀⠘⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣷⣦⣤⣼⣿⣼⣿⣿⡷⣆⢾⡇⣨⡞⢁⠚⣦⠴⢦⢤⠀⠂⠄⠁⢀⠁⠐⠀⠈⠀⠐⠀⠀⡁⠀⠠⠐⠀⠠⠀⠀⠂⠌⠐⠠⠈⠀
⠀⠀⠀⠄⠁⠀⠂⠀⠀⠀⢩⠟⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣯⣽⣟⠿⣻⣝⢾⣹⣿⣿⣿⣾⣿⣿⣷⣤⣬⠟⠛⢓⢦⡈⠀⢀⠀⠂⠀⠁⠀⠐⠀⠀⠀⠁⠀⢈⠀⠀⡁⠐⠀⠌⠀⡐⠀
⠀⠈⠀⡀⠄⢂⡠⠤⠤⠶⣧⠊⠀⣀⣠⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⣻⣿⡿⣟⣿⣷⢷⣫⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠧⣼⢿⣧⣀⠀⣀⣠⣐⣈⠀⠠⠀⠂⠁⠀⠈⠀⠀⢀⠀⠄⠂⠀⠂⢀⠀
⠀⠀⠁⠀⣴⡯⣳⠖⠉⣸⣇⣀⣮⣵⡿⣟⢫⡝⢭⠛⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⢯⣿⡞⣳⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣖⣬⣿⢿⣿⣿⢿⣝⣦⣄⠀⠀⠐⠀⠀⠈⠀⠀⠀⢀⠐⠀⠀⠀
⠀⠔⣚⠉⣟⡰⠁⠀⣠⣽⢛⣿⢟⡧⣛⡬⠃⠜⡀⢣⠘⣆⣶⣽⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⢿⣿⡽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣼⣿⡿⣿⣾⣿⣿⣻⣿⣗⣦⠀⠀⠁⠀⢀⠈⠀⠀⠀⠐⠀
⢠⠊⢀⢠⣿⣥⣶⣿⣿⣵⡿⣹⢞⡼⠡⠄⢃⠒⣬⣶⣿⣿⣿⠿⡛⢯⡹⢏⣛⠻⢟⣿⣿⣿⣿⣯⣟⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣳⣼⣿⣿⣟⣵⣿⣿⣟⣼⣿⣿⢣⣿⣧⡀⠀⠄⠀⠀⢀⠀⠁⠀⠀
⠃⣴⢯⡾⠋⠉⠉⢀⣾⡟⣼⡛⢎⡰⢁⣎⣶⣿⣿⠿⠛⡉⠄⠣⡙⢦⡙⡎⢴⣉⣶⡼⡾⢿⢿⣟⣾⣽⣯⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⣾⣿⣿⣫⣿⣿⣿⣿⣆⠀⠀⠈⠀⠀⠀⠐⠀
⣿⠷⠛⢿⠷⠶⠞⣿⡻⣼⠋⡘⣠⣵⣿⣿⠟⡛⢁⠂⠡⠐⡈⣴⢜⣶⣽⠿⣟⢿⣹⢚⡵⣋⣞⣻⣷⣯⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣽⣿⣿⣿⣷⣿⣿⣿⢿⣿⣿⣧⠀⠀⠐⠀⠁⠀⠀
⠇⠀⣰⡟⠀⢀⡾⢧⠽⣁⣶⣿⣿⠿⠋⠆⠑⡀⠁⠈⣤⡵⠻⡙⠋⡁⠎⡙⣌⣶⢥⣻⢾⣛⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣵⣿⣿⣿⣿⣶⣮⣝⡛⠶⣤⣀⠀⠀⠂⠀
⣶⠟⠋⠀⢠⡟⣱⣋⣶⣿⣿⢫⠱⢈⠡⠈⡀⠄⣬⠟⠃⠌⡁⢀⣂⣥⢾⣿⣹⣾⣾⣿⣿⣿⣿⡿⢍⡿⢹⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣿⣿⣿⣿⣷⣿⣽⣓⡶⣄
⠁⠀⠀⠀⣾⡸⣧⣿⣿⣛⢦⠣⠌⡀⠆⣡⡴⠛⠁⠠⠁⣂⣴⣿⣏⣾⣿⣿⣿⣿⡿⣿⢿⣿⡿⡜⣿⠁⠂⢿⣿⣿⡛⠿⢿⣿⣿⣿⣿⣿⣿⢗⠈⠛⢿⣿⣿⣿⣿⣿⣿⠏⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠀⠀⠀⢠⣿⣽⢿⡝⡶⣭⢒⡱⢂⡱⠌⠡⢀⠁⢂⣴⣿⣫⣷⣿⣿⣻⣿⣿⣿⣿⣿⣿⣿⣿⢳⣸⡷⠀⠀⠘⣿⣧⣉⠂⢈⣁⠀⡈⢆⣿⡸⠈⠀⠀⠀⠉⠻⢿⣻⣿⣮⠻⡄⢻⣿⣟⢿⣛⣯⢻⣿⣿⣿⣿⣿⣿⣿⣿
⠀⠀⠀⢸⡿⣹⢮⡝⡳⢜⡢⢕⠣⡐⢌⠡⢂⣜⣾⣿⣽⣿⣿⣿⣿⡿⢟⣿⣿⣿⣷⣿⣾⡿⡇⢻⠃⠀⠀⠀⣿⠻⠿⠷⠶⠬⠯⠿⣿⠋⣇⠀⠀⠀⠀⠀⠀⠀⠈⠳⢿⣳⣌⢦⣿⣿⡲⣭⠞⣿⣿⣿⣿⣿⣽⡌⠙⠻
⠀⠀⠀⣾⢳⡝⡞⡜⣱⢍⡚⣌⠢⡱⢌⢣⣻⣟⣾⣿⣿⣿⢿⣽⣶⣿⣛⣿⣿⣿⣿⣳⢯⣷⡩⢸⡆⠀⠀⢠⡿⣧⣅⣂⡄⢡⣔⣠⣶⢴⠈⠓⡀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠿⣳⣽⣟⣿⣲⢛⣦⢻⣿⣿⣿⣿⣿⡀⠀
⠀⠀⢰⢣⡟⣼⢱⣹⠗⣎⠱⣂⢧⡱⢮⣹⣿⣿⣿⣿⣿⣯⣿⡟⢣⢦⠹⢾⣿⣿⣿⣽⣳⢚⣷⣼⠁⠀⠀⣼⠱⡈⠍⠛⠿⠿⠿⣿⣷⢚⣆⠀⠈⠢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣷⣯⣶⣿⣞⣿⣿⣿⣿⣣⠀
⠀⢀⣏⡳⣝⢎⡿⣍⠞⡤⢳⡘⢦⣽⢯⣿⣿⣿⣿⣿⣿⣿⣿⣯⢇⢮⣙⠦⣟⣿⣿⣿⣮⡝⡼⣏⠀⠀⣰⠷⣥⣘⠀⠃⠄⡐⠂⡔⣸⢸⠀⠉⠢⠄⠐⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣟⢿⣛⣿⣿⣿⣿⣧⠇
⠀⡲⣬⢳⣽⣞⠳⣜⡚⠴⢣⣙⡾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⢶⣩⡞⣽⢾⣿⣿⣿⣞⡱⡽⡆⢠⣿⣮⣐⣉⠛⠛⠺⠶⠷⠾⣶⢺⠀⠠⡾⡦⡀⠀⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣌⣻⣧⣛⢯⣿⣿⣿⣿⡆
⡘⡵⣭⣳⢏⡮⢳⢬⡙⣭⣳⢟⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢶⡹⣎⢿⣽⣿⣿⣿⣿⣳⣿⣾⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣿⢻⠀⠀⠣⣿⠟⡄⠘⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣧⢏⣟⣳⢿⣿⣿⡽
⣸⢳⣯⣛⢮⠵⣋⠶⣙⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⢷⡹⣎⣷⣟⣻⣯⣿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣸⠀⠀⠀⠀⢐⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣺⣿⣟⡾⣭⣛⢺⡽⣿⣿
⡞⣯⡳⡝⣎⠳⣍⢞⣽⣳⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠉⠁⠆⣼⣿⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡯⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣳⣝⢮⢇⡿⣽⣿
⡽⣣⢏⡕⣊⢗⢮⡿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢃⠠⠀⠀⠁⢌⣿⣿⣿⣿⣿⣿⣾⣿⣽⣯⣿⣽⣿⣧⠟⠀⠀⠀⠀⠀⠀⢰⠇⠀⠀⠀⠀⠀⠀⠀⣀⡀⣾⣿⣿⣿⣷⣚⣯⣞⠼⣳⣿
⡳⢇⡞⣌⡳⢮⣿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⣷⠈⠀⣠⡾⣯⢾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢄⠀⠀⠀⠀⠀⢠⣿⡄⠀⠀⠀⠀⠀⠀⠀⢉⣿⣿⣿⣿⣿⠿⠿⠾⢞⡻⣙⠦
⡝⣎⠼⣎⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣞⣿⣿⣏⢿⣄⡾⢿⣽⢇⣿⣿⣷⣯⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⡿⣜⠀⠀⠀⢀⣴⠟⠀⢷⣤⠀⡀⢀⡀⣤⡴⠋⠙⠳⣯⡿⣿⣿⢖⡱⣊⠴⣩⡾
⡾⣼⢿⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⢿⣿⡆⣿⣿⣿⡿⣾⣿⣿⣿⣿⣿⣿⣿⣶⣶⣧⣿⣿⣷⣧⣿⢿⠀⢠⣶⠿⠃⠆⠀⠘⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠛⠻⠿⢷⣧⣿⠾⠟⠀
⡼⣱⣾⣿⣽⣿⣿⢿⣯⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢲⢿⣫⢿⣾⣖⣻⣿⢳⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⡿⢞⠫⠁⠀⠁⠀⠀⠀⣿⣿⣿⡿⣿⣿⣼⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡵⣟⣿⣿⣿⣿⢯⣿⣻⣾⣿⣿⣿⣿⡿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣭⢺⠥⣏⢿⣿⣶⣿⢿⣗⣻⣷⣿⢉⠛⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⡿⣽⣿⣽⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣽⣿⣿⣟⣿⡿⣯⣿⣿⣿⣿⣿⡿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⢯⣿⣌⡳⢭⢿⣿⣚⢿⡹⣿⡋⠄⠌⠐⠠⢀⠆⢭⡙⢏⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⢿⡽⣿⢾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣻⢾⣽⣻⣟⣿⣿⣿⣿⢯⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣼⣣⣏⣿⢿⣞⡿⣴⡉⠆⡈⠄⢡⠈⠞⣤⢋⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣯⣟⣿⣮⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⡷⣯⣟⣾⣳⣿⣿⣿⢿⣽⣟⣷⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡍⡉⠏⠻⠜⡸⢛⠿⣿⣴⣀⢎⠰⣈⠞⣴⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣳⢯⣿⡧⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⡿⣽⡳⣽⣺⣽⣷⣿⢿⣻⢷⣻⢾⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠐⠀⠀⠀⠀⠄⠉⠘⠌⢛⠿⠾⡷⠿⠾⠋⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⢯⡟⣾⡗⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣟⢧⡟⣶⢯⣟⣯⡿⣯⢯⢷⣯⢿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠁⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⢯⣝⣿⣿⡔⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⢞⣧⢻⣼⣻⡽⣏⠿⣜⣻⢾⣽⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣟⣯⢞⡾⣿⢻⠀⠀⠀⠀⣀⠀⠀⠀⢀⡰⣞⣯
⣿⢺⡬⣓⢮⡳⣝⢮⡻⣽⡽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿⣻⠾⣭⢞⣿⣏⡇⠀⠀⣿⣽⣶⡠⣄⢾⣽⣟⠃
⣏⠷⡸⢥⢳⣙⢮⡳⣽⣳⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠄⣿⣿⣿⣿⣿⣻⣽⣻⡜⣯⣿⣇⡇⠀⠈⣷⣿⣿⣷⣯⣿⡽⢊⠀
⣏⢞⡱⣋⡞⣬⢳⣽⣳⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣐⠀⢘⣿⣿⣿⣿⣻⣽⣳⢧⣛⠶⣿⣿⢢⠀⡰⢯⣿⣿⢿⣽⣳⢿⣥⠂
⣏⠮⣕⣣⡝⢮⣟⣾⣽⣿⣿⣿⣿⣿⣿⣿⣿⠏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣲⡏⠀⢘⣿⣿⣿⣿⢯⡿⣽⡳⣭⢻⣽⣯⢹⣾⣽⣿⣿⣯⡟⣶⣹⣿⣾⣟
⣎⠿⡴⣓⣾⢻⣾⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢢⡿⠀⠀⢘⣿⣿⣿⣿⢯⣟⡷⡽⣎⣟⣾⣷⢚⣿⣿⣿⣿⣿⣽⣾⣷⣿⣻⣾
⣎⢯⣵⣻⣞⣿⣿⣿⣿⣿⣿⣿⣿⡿⢃⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⠒⠇⠀⠀⢈⣿⣿⣿⣟⡿⣞⡽⣳⡝⣮⢿⣿⣎⣿⣿⣿⣿⣿⣿⢿⣾⠳⡝⢺
⣮⢷⣯⣷⣿⣿⣿⣿⣿⣿⣿⣿⠟⡀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠌⠀⠀⠀⢰⣿⣿⣿⡿⣽⢞⣳⢧⡻⣼⣻⣿⠴⣿⣿⣿⣿⣿⣿⣟⢧⢃⠈⢄
⣿⣾⣷⣿⣿⣿⣿⣿⣿⣿⡿⠋⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠌⡀⠀⠀⠀⣸⣿⣿⣿⣟⣧⢟⡧⢯⣳⢷⣻⣿⣞⣿⣿⣿⣿⣿⣿⡾⣏⣦⣳⢮
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⢂⠄⡁⠂⠄⣿⣿⣿⣿⢿⡜⣯⢞⣯⠿⣽⣻⣿⢼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠰⢈⠔⡂⢅⠊⣼⣿⣿⣿⣿⣻⢼⣣⣟⣾⣻⡽⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡐⢄⠊⠴⡈⠴⣈⢒⣿⣿⣿⣿⡿⣝⢮⡳⢾⣱⣯⣟⣿⢃⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠢⡐⠌⡜⢢⢉⠲⢄⢮⣿⣿⣿⣿⢿⡹⢮⡽⢯⣷⣻⣾⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠂⢆⠱⡘⢄⢣⠘⣂⠎⣼⣿⣿⣿⣟⡯⣝⣳⡟⣿⣞⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡁⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⡌⠢⡑⠌⡌⢢⢉⠤⢩⣿⣿⣿⣿⢯⣳⠽⡾⣽⣳⣯⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⢁⠰⠁⢆⠱⠈⡄⠂⠄⢻⣿⣿⣿⣯⡗⣯⢿⣽⣳⣿⣽⡿⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠐⡀⢂⠍⡠⢂⠁⠀⠐⠈⡸⣿⣿⣿⢮⡽⣞⡿⣾⣽⣻⣿⣃⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠂⠤⠁⠎⡐⠄⠀⠀⠀⠀⠀⡑⢼⣿⣯⢟⡽⣯⣟⣷⣿⣿⡙⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡠⢊⠔⡩⠐⠀⠀⠀⠀⠀⠀⠀⠐⡸⣿⣞⣯⣟⡷⣿⣾⣿⣿⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⢈⠐⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠀⠀⠀⠀⠀⣄⢣⠰⡁⠎⠄⠁⠀⠀⠀⠀⠀⠀⠀⠠⠁⢻⣞⡷⣯⣟⣷⣿⣏⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠄⡊⠄⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣇⠀⠀⢤⣳⡾⢇⢣⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢡⠘⣿⣽⣳⣿⣿⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠌⡐⠠⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡤⣉⣾⢏⣱⢎⠡⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⢿⣳⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⢂⠥⠁⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣷⣿⡷⡞⡃⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⡇⢸⣿⣿⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⡌⠄⢃⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡟⡜⡡⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⡇⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣇⡘⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣟⠰⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢁⠂⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣷⠠⡁⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡁⠀⠀⢸⡏⠆⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⢌⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⡅⡐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⡁⠀⢘⣇⠊⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠌⡨⢄⡿⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⡇⠜⡀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠁⡀⠀⢈⡧⠌⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣴⢾⡛⡽⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣦⡡⠐⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠂⠄⡀⠨⣷⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣻⡭⣭⠱⣜⣦⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⡿⣷⢶⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠂⠌⡐⠀⢰⣯⣧⣤⣄⣄⣠⣠⣤⣤⣶⣿⣿⣿⣿⣷⣿⣿⣿⡿⣿⣽⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣷⣯⣞⡼⣩⢿⡟⠲⠶⠤⢤⣄⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⢈⡐⠤⠁⣾⣿⣿⣿⣾⣷⣯⣷⣶⣷⣾⡿⢿⣿⣻⢿⣽⣧⣿⣿⣿⣿⠋⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⠿⣿⣷⣷⣾⣧⡑⠌⡐⠠⠀⢀⠉⠙⣻⠟⡛⢳⠲⣖⠶⠾⢾⢳⠷⡾⢶⡿⣿⣿⣿⣿⣿⣿⣿⣯⣿⣾⣶⣿⣿⡾⢿⠿⢿⡻⢟⡽⣺⢼⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣷⣮⣝⣻⣟⡿⣿⣷⣶⣧⣤⣄⣂⣤⣨⢑⣣⠳⣜⣏⡻⣬⢳⣫⡝⣧⢽⣿⣿⣿⢻⣟⢛⡹⠩⠍⠩⢁⠒⠤⢑⠊⡜⢢⡙⢮⡱⢧⣻⠀⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⣟⡿⣿⢿⣿⣿⣷⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣷⣿⣷⣿⣿⣿⣿⣿⣿⢾⡹⣏⠲⡄⠣⠌⣁⠊⢌⠢⡁⠞⣠⠣⡜⢣⡝⢮⣹⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣽⢻⣜⢯⣿⡐⠦⠡⢉⠉⠉⠉⠋⠛⠛⢛⠛⡟⡻⢟⡿⢿⠿⣟⡿⣻⢽⣿⣿⣯⢟⣿⠳⣌⠱⡈⠤⡘⢄⠣⡘⢔⡡⢒⡍⣲⡙⢮⣹⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣞⣟⡮⣗⣿⣍⠲⡁⢆⠐⡀⠀⢀⠂⠡⡈⢆⠱⡑⠮⣜⣣⢟⡼⣳⡝⣾⣿⣿⣯⣛⣿⠳⡌⢆⡑⢢⠑⡌⡒⡡⢎⠰⢣⠜⡴⣩⢓⢾⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡿⣼⡝⡷⢾⣧⢣⡑⠌⡐⠀⠌⢀⠈⠤⡑⢌⠒⣍⠺⢴⣩⢞⡵⣣⡟⣾⣿⣿⣳⡝⣾⡝⡜⡄⠎⣄⢃⡒⣡⠱⣈⢇⠣⢞⣡⢳⣋⡞⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣷⡻⣽⣛⢶⣣⠜⢢⠑⣈⠐⡀⠎⠰⣈⢌⠚⡤⢛⠦⣝⢮⡝⣧⣛⣿⣿⣿⢷⡻⡼⡟⡴⣈⠧⣐⠊⡔⢢⠱⡌⢎⡹⢎⡖⢯⡼⡜⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣷⣟⣧⢟⣳⢮⡙⢆⠱⡀⠆⠐⡈⠑⡠⢊⠱⣌⡙⢮⣙⢮⡽⣲⢏⣿⣿⡿⣯⢷⡹⣿⠴⣡⠒⠥⠚⡌⠥⡓⡜⡬⣓⢭⣚⢧⡳⡅⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * OpenZeppelin
 */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * Local Imports
 */
import {ITreasuryRegistry} from "src/interfaces/ITreasuryRegistry.sol";
import {IIsekaiRoles} from "src/interfaces/IIsekaiRoles.sol";

contract HolyToken is ERC20Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Max supply of Holy 1.25 billion
    uint256 public maxSupply = 1_250_000_000 * 1e18;

    /// @notice Total cliffs for minting
    uint256 public constant TOTAL_CLIFFS = 12_500;

    /// @notice Amount of supply to reduce per cliff
    uint256 public reductionPerCliff;

    /// @notice Whitelist AMM so we can correctly charge the retention
    mapping(address => bool) public pairs;

    /// @dev Can disable by setting it to 0
    uint256 public sellRetention;

    /// @notice percentage of minted tokens that go to the incentive collector
    uint256 public incentiveCollectorShare;

    /// @notice percentage of minted tokens that go to the epoch manager
    uint256 public epochManagerShare;

    /// @dev 100%
    uint256 public constant BASIS_POINTS = 10_000;

    /// @dev Stores addresses from all 5 treasuries
    ITreasuryRegistry public registry;

    /// @notice Check if user interacting has any role to bypass/increase/reduce sell retention
    IIsekaiRoles public roles;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        EVENTS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Keep track of minted Holy for analytics purposes
    event MintedHoly(
        address _to, uint256 amountToUser, uint256 amountToIncentiveCollector, uint256 amountToEpochManager
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ERRORS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function init() external initializer {
        __ERC20_init("Holy Token", "HOLY");
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        reductionPerCliff = maxSupply / TOTAL_CLIFFS;

        // Set default retentions, can always be changed by admin later
        sellRetention = 250; // 2.5%
        incentiveCollectorShare = 1200; // 12%
        epochManagerShare = 500; // 5%
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        PUBLIC Methods                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 amount = previewDeposit(_amount);

        if (amount == 0) {
            emit MintedHoly(_to, 0, 0, 0);

            return 0;
        }

        uint256 toIncentiveAllocator;
        uint256 toYieldBooster;

        if (roles.roleOfIndex(_to) != 0) {
            IIsekaiRoles.Role memory role = roles.getUserRole(_to);

            toIncentiveAllocator = (amount * role.holyMintFeeCollector) / BASIS_POINTS;
            toIncentiveAllocator = (amount * role.holyMintFeeEpochManager) / BASIS_POINTS;
        } else {
            toIncentiveAllocator = (amount * incentiveCollectorShare) / BASIS_POINTS;
            toYieldBooster = (amount * epochManagerShare) / BASIS_POINTS;
        }

        uint256 toUser = amount - (toIncentiveAllocator + toYieldBooster);

        _mint(registry.getTreasury(ITreasuryRegistry.Treasuries.IncentiveCollector), toIncentiveAllocator);
        _mint(registry.getTreasury(ITreasuryRegistry.Treasuries.EpochManager), toYieldBooster);
        _mint(_to, toUser);

        emit MintedHoly(_to, toUser, toIncentiveAllocator, toYieldBooster);

        return toUser;
    }

    function previewDeposit(uint256 _amount) public view returns (uint256) {
        uint256 supply = totalSupply();

        if (supply == 0) {
            return _amount;
        }

        // Use current supply to gauge cliff
        // this will cause a bit of overflow into the next cliff range
        // but should be within reasonable levels.
        // requires a max supply check though
        uint256 cliff = supply / reductionPerCliff;
        // mint if below total cliffs
        if (cliff < TOTAL_CLIFFS) {
            // For reduction% take inverse of current cliff
            uint256 reduction = TOTAL_CLIFFS - cliff;

            _amount = (_amount * reduction) / TOTAL_CLIFFS;

            //supply cap check
            uint256 amtTillMax = maxSupply - supply;
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }

            return _amount;
        }

        return 0;
    }

    /**
     * @notice Update the percentage charged in sell retention
     * @param _newRetention New percentage
     */
    function updateRetentionPercentage(uint256 _newRetention) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sellRetention = _newRetention;
    }

    /**
     * @notice Add or remove AMM (used when charging the retention)
     * @param _pair Address of the pair
     * @param _status true = all transactions going to this address will be charged 3%
     */
    function updatePairStatus(address _pair, bool _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pairs[_pair] = _status;
    }

    function setIncentiveCollectorShare(uint256 _newRetention) external onlyRole(DEFAULT_ADMIN_ROLE) {
        incentiveCollectorShare = _newRetention;
    }

    function setEpochManagerShare(uint256 _newRetention) external onlyRole(DEFAULT_ADMIN_ROLE) {
        epochManagerShare = _newRetention;
    }

    function setTreasuryRegistry(address _registry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        registry = ITreasuryRegistry(_registry);
    }

    function addMinter(address _target) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _target);
    }

    function removeMinter(address _target) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, _target);
    }

    function setIsekaiRoles(address _roles) external onlyRole(DEFAULT_ADMIN_ROLE) {
        roles = IIsekaiRoles(_roles);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INTERNAL Methods                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Overriding default ERC20 `_transfer` to a custom implementation where sell taxes are charged a retention
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Only charges retention on sells
        // Check if trader has retention disabled, if not turn on retention
        uint256 fees;

        // On sell
        if (pairs[to] && sellRetention > 0) {
            uint256 percentage;

            if (roles.roleOfIndex(from) == 0) {
                percentage = sellRetention;
            } else {
                percentage = roles.getUserRole(from).holySellTax;
            }

            fees = (amount * percentage) / BASIS_POINTS;
            amount -= fees;
        }

        if (fees > 0) {
            super._transfer(from, registry.getTreasury(ITreasuryRegistry.Treasuries.IncentiveCollector), fees);
        }

        super._transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

/*
         ._                __.
        / \"-.          ,-",'/ 
       (   \ ,"--.__.--".,' /  
       =---Y(_i.-'  |-.i_)---=
      f ,  "..'/\\v/|/|/\  , l
      l//  ,'|/   V / /||  \\j
       "--; / db     db|/---"
          | \ YY   , YY//
          '.\>_   (_),"' __
        .-"    "-.-." I,"  `.
        \.-""-. ( , ) ( \   |
        (     l  `"'  -'-._j 
 __,---_ '._." .  .    \
(__.--_-'.  ,  :  '  \  '-.
    ,' .'  /   |   \  \  \ "-
     "--.._____t____.--'-""'
            /  /  `. ".
           / ":     \' '.
         .'  (       \   : 
         |    l      j    "-.
         l_;_;I      l____;_I

                        異世界

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ITreasuryRegistry {
    enum Treasuries {
        Operational,
        XpSupport,
        IncentiveCollector,
        EpochManager,
        HolySupport
    }

    function getTreasury(Treasuries _treasuryType) external view returns (address);

    function updateTreasury(Treasuries _treasuryType, address _newTreasury) external;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

interface IIsekaiRoles {
    struct Role {
        uint64 holyMintFeeCollector;
        uint64 holyMintFeeEpochManager;
        uint64 holySellTax;
        uint64 xpSellTax;
        bool canMoveEHoly;
        bool canMintDirectly;
    }

    function createRole(Role memory _role) external returns (uint256);

    function assignOrRemoveRole(address _address, uint256 _role) external;

    function roleOfIndex(address _address) external view returns (uint256);

    function roles(uint256 _role) external view returns (Role memory);

    function getUserRole(address _address) external view returns (Role memory);
}

interface TokensRetentions {
    // Holy retentions
    function sellRetention() external view returns (uint256);

    function incentiveCollectorShare() external view returns (uint256);

    function epochManagerShare() external view returns (uint256);

    // XP retentions
    function sellTax() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
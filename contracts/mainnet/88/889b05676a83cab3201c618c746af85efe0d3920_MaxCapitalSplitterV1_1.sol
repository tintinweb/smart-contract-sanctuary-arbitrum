/**
 *Submitted for verification at Arbiscan.io on 2024-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface AutomationCompatibleInterface {
    function checkUpkeep(
        bytes calldata checkData
    ) external returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}

contract ConfirmedOwnerWithProposal is IOwnable {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function owner() public view override returns (address) {
        return s_owner;
    }

    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(
        address newOwner
    ) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

library Client {
    struct EVMTokenAmount {
        address token; // token address on the local chain.
        uint256 amount; // Amount of tokens.
    }

    struct Any2EVMMessage {
        bytes32 messageId; // MessageId corresponding to ccipSend on source.
        uint64 sourceChainSelector; // Source chain selector.
        bytes sender; // abi.decode(sender) if coming from an EVM chain.
        bytes data; // payload sent in original message.
        EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
    }

    // If extraArgs is empty bytes, the default is 200k gas limit.
    struct EVM2AnyMessage {
        bytes receiver; // abi.encode(receiver address) for dest EVM chains
        bytes data; // Data payload
        EVMTokenAmount[] tokenAmounts; // Token transfers
        address feeToken; // Address of feeToken. address(0) means you will send msg.value.
        bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
    }

    // bytes4(keccak256("CCIP EVMExtraArgsV1"));
    bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
    struct EVMExtraArgsV1 {
        uint256 gasLimit;
    }

    function _argsToBytes(
        EVMExtraArgsV1 memory extraArgs
    ) internal pure returns (bytes memory bts) {
        return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
    }
}

interface IRouterClient {
    error UnsupportedDestinationChain(uint64 destChainSelector);
    error InsufficientFeeTokenAmount();
    error InvalidMsgValue();

    function isChainSupported(
        uint64 chainSelector
    ) external view returns (bool supported);

    function getSupportedTokens(
        uint64 chainSelector
    ) external view returns (address[] memory tokens);

    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory message
    ) external view returns (uint256 fee);

    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable returns (bytes32);
}

interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function balanceOf(address owner) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);
}

contract MaxCapitalSplitterV1_1 is OwnerIsCreator, AutomationCompatibleInterface {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector);
    error InvalidReceiverAddress();

    event TokensTransferred(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        address feeToken,
        uint256 fees
    );

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    );

    event NoActionNeeded(string message);

    mapping(uint64 => bool) public allowlistedChains;

    IRouterClient public s_router;
    ISwapRouter02 public swapRouter02;
    AggregatorV3Interface internal WETH9PriceFeed;
    AggregatorV3Interface internal USDCPriceFeed;

    IERC20 public s_linkToken;
    IERC20 public usdcToken;
    IWETH public wethToken;
    address[] internal farmingContracts;
    address private multisigWallet;
    address private gasManager;
    address private treasuryWallet;
    uint16 private treasuryUSDCFeePercentage;
    uint16 private treasuryEthFeePercentage;
    uint16 private gasManagerPercent; // Usdc
    uint16 private destinationPercentage; // Usdc
    uint16 private farmingPercentage; // Eth
    uint24 private swapFee = 500;
    uint16 private slippage = 50; //.5%
    uint256 private WethSwapped;
    uint256 private EthSentFarming;
    uint256 private EthSentTreasury;
    uint256 private USDCSentTreasury;
    uint256 private EthValueOfUSDCSentToTreasury;
    uint256 private USDCSentForGas;
    uint256 private EthValueOfUSDCSentToGas;
    uint256 private USDCForDestination;
    uint256 private EthValueOfUSDCForDestination;
    uint256 private UsdcSentAvax;
    uint256 private UsdcSentEth;
    uint256 private UsdcSentBNB;
    uint256 private UsdcSentBase;
    uint256 private UsdcSentArbitrum;
    uint256 private UsdcSentPolygon;
    uint256 private UsdcSentOptimism;
    uint256 private ethReceivedTotal;
    uint256 private ethReceivedValueUSD;
    uint256 private minEthToSwap;
    bool private locked = false;

    address private avaxDestinationReceiver;
    uint64 private avaxDestinationSelector;
    uint16 private avaxDestinationPercentage;
    bool private avaxActive;

    address private ethDestinationReceiver;
    uint64 private ethDestinationSelector;
    uint16 private ethDestinationPercentage;
    bool private ethActive;

    address private arbitrumDestinationReceiver;
    uint64 private arbitrumDestinationSelector;
    uint16 private arbitrumDestinationPercentage;
    bool private arbitrumActive;

    address private bnbDestinationReceiver;
    uint64 private bnbDestinationSelector;
    uint16 private bnbDestinationPercentage;
    bool private bnbActive;

    address private baseDestinationReceiver;
    uint64 private baseDestinationSelector;
    uint16 private baseDestinationPercentage;
    bool private baseActive;

    address private polygonDestinationReceiver;
    uint64 private polygonDestinationSelector;
    uint16 private polygonDestinationPercentage;
    bool private polygonActive;

    address private optimismDestinationReceiver;
    uint64 private optimismDestinationSelector;
    uint16 private optimismDestinationPercentage;
    bool private optimismActive;

    constructor(
        address _router,
        address _link,
        address _usdcToken,
        address _wethToken
    ) {
        s_router = IRouterClient(_router);
        s_linkToken = IERC20(_link);
        usdcToken = IERC20(_usdcToken);
        wethToken = IWETH(_wethToken);
        multisigWallet = msg.sender;
    }

    modifier onlyAllowlistedChain(uint64 _destinationChainSelector) {
        if (!allowlistedChains[_destinationChainSelector])
            revert DestinationChainNotAllowlisted(_destinationChainSelector);
        _;
    }

    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        _;
    }

    modifier noReentrancy() {
        require(!locked, "Reentrancy not allowed");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyMultisig() {
        require(
            msg.sender == multisigWallet,
            "Caller is not the multisig wallet"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == owner() || msg.sender == multisigWallet,
            "Caller is not an admin"
        );
        _;
    }

    function setMultisigWallet(address _multisigWallet) external onlyMultisig {
        require(_multisigWallet != address(0), "Invalid address");
        multisigWallet = _multisigWallet;
    }

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyAdmin {
        allowlistedChains[_destinationChainSelector] = allowed;
    }

    function setMinAmtsToSwap(uint256 _minEthToSwap) external onlyAdmin {
        minEthToSwap = _minEthToSwap;
    }

    function setGasManagerConfig(
        //usdc
        address _gasManager,
        uint16 _gasManagerPercent
    ) external onlyAdmin {
        require(
            treasuryUSDCFeePercentage +
                treasuryEthFeePercentage +
                _gasManagerPercent +
                farmingPercentage +
                destinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        gasManager = _gasManager;
        gasManagerPercent = _gasManagerPercent;
    }

    function setTreasuryConfig(
        //split
        address _treasuryWallet,
        uint16 _ethPercent,
        uint16 _usdcPercent
    ) external onlyAdmin {
        require(
            _ethPercent +
                _usdcPercent +
                gasManagerPercent +
                farmingPercentage +
                destinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );

        treasuryWallet = _treasuryWallet;
        treasuryUSDCFeePercentage = _usdcPercent;
        treasuryEthFeePercentage = _ethPercent;
    }

    function setFarmingAndDestinationPercentage(
        uint16 _farmingPercentage,
        uint16 _destinationsPercentage
    ) external onlyAdmin {
        // farming eth, destination USDC
        require(
            treasuryEthFeePercentage +
                treasuryUSDCFeePercentage +
                gasManagerPercent +
                _farmingPercentage +
                _destinationsPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        farmingPercentage = _farmingPercentage;
        destinationPercentage = _destinationsPercentage;
    }

    function setAvaxDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                ethDestinationPercentage +
                bnbDestinationPercentage +
                arbitrumDestinationPercentage +
                polygonDestinationPercentage +
                baseDestinationPercentage +
                optimismDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        avaxDestinationReceiver = _receiver;
        avaxDestinationSelector = _selector;
        avaxDestinationPercentage = _percentage;
        avaxActive = _active;
    }

    function setEthDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                avaxDestinationPercentage +
                bnbDestinationPercentage +
                arbitrumDestinationPercentage +
                polygonDestinationPercentage +
                baseDestinationPercentage +
                optimismDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        ethDestinationReceiver = _receiver;
        ethDestinationSelector = _selector;
        ethDestinationPercentage = _percentage;
        ethActive = _active;
    }

    function setBnbDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                ethDestinationPercentage +
                avaxDestinationPercentage +
                arbitrumDestinationPercentage +
                polygonDestinationPercentage +
                baseDestinationPercentage +
                optimismDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        bnbDestinationReceiver = _receiver;
        bnbDestinationSelector = _selector;
        bnbDestinationPercentage = _percentage;
        bnbActive = _active;
    }

    function setArbitrumDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                ethDestinationPercentage +
                bnbDestinationPercentage +
                avaxDestinationPercentage +
                polygonDestinationPercentage +
                baseDestinationPercentage +
                optimismDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        arbitrumDestinationReceiver = _receiver;
        arbitrumDestinationSelector = _selector;
        arbitrumDestinationPercentage = _percentage;
        arbitrumActive = _active;
    }

    function setPolygonDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                ethDestinationPercentage +
                bnbDestinationPercentage +
                arbitrumDestinationPercentage +
                avaxDestinationPercentage +
                baseDestinationPercentage +
                optimismDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        polygonDestinationReceiver = _receiver;
        polygonDestinationSelector = _selector;
        polygonDestinationPercentage = _percentage;
        polygonActive = _active;
    }

    function setBaseDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                ethDestinationPercentage +
                bnbDestinationPercentage +
                arbitrumDestinationPercentage +
                polygonDestinationPercentage +
                avaxDestinationPercentage +
                optimismDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        baseDestinationReceiver = _receiver;
        baseDestinationSelector = _selector;
        baseDestinationPercentage = _percentage;
        baseActive = _active;
    }

    function setOptimismDestinationConfig(
        address _receiver,
        uint64 _selector,
        uint16 _percentage,
        bool _active
    ) external onlyAdmin {
        require(
            _percentage +
                ethDestinationPercentage +
                bnbDestinationPercentage +
                arbitrumDestinationPercentage +
                polygonDestinationPercentage +
                baseDestinationPercentage +
                avaxDestinationPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        optimismDestinationReceiver = _receiver;
        optimismDestinationSelector = _selector;
        optimismDestinationPercentage = _percentage;
        optimismActive = _active;
    }

    function setSwapRouter(ISwapRouter02 _swapRouter02) external onlyAdmin {
        swapRouter02 = _swapRouter02;
    }

    function setSlippage(uint16 _slippage) external onlyAdmin {
        slippage = _slippage;
    }

    function setPriceFeeds(address _WETH9, address _USDC) external onlyAdmin {
        require(_WETH9 != address(0), "Invalid address");
        require(_WETH9 != address(0), "Invalid address");
        WETH9PriceFeed = AggregatorV3Interface(_WETH9);
        USDCPriceFeed = AggregatorV3Interface(_USDC);
    }

    function getWETH9Price() public view returns (int) {
        (, int WETH9price, , , ) = WETH9PriceFeed.latestRoundData();

        return WETH9price * 10 ** 10; // Weth is 18 decimals, Link feeds are 8
    }

    function getUSDCPrice() public view returns (int) {
        (, int USDCprice, , , ) = USDCPriceFeed.latestRoundData();
        return USDCprice / 100; // USDC is 6 decimals, Link feeds are 8
    }

    function getAvaxDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            avaxDestinationReceiver,
            avaxDestinationSelector,
            avaxDestinationPercentage,
            avaxActive
        );
    }

    function getEthDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            ethDestinationReceiver,
            ethDestinationSelector,
            ethDestinationPercentage,
            ethActive
        );
    }

    function getArbitrumDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            arbitrumDestinationReceiver,
            arbitrumDestinationSelector,
            arbitrumDestinationPercentage,
            arbitrumActive
        );
    }

    function getBnbDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            bnbDestinationReceiver,
            bnbDestinationSelector,
            bnbDestinationPercentage,
            bnbActive
        );
    }

    function getBaseDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            baseDestinationReceiver,
            baseDestinationSelector,
            baseDestinationPercentage,
            baseActive
        );
    }

    function getPolygonDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            polygonDestinationReceiver,
            polygonDestinationSelector,
            polygonDestinationPercentage,
            polygonActive
        );
    }

    function getOptimismDetails()
        public
        view
        returns (address, uint64, uint16, bool)
    {
        return (
            optimismDestinationReceiver,
            optimismDestinationSelector,
            optimismDestinationPercentage,
            optimismActive
        );
    }

    function getMultisigWallet() public view returns (address) {
        return multisigWallet;
    }

    function getGasManager() public view returns (address) {
        return gasManager;
    }

    function getTreasuryWallet() public view returns (address) {
        return treasuryWallet;
    }

    function getTreasuryUSDCFeePercentage() public view returns (uint16) {
        return treasuryUSDCFeePercentage;
    }

    function getTreasuryEthFeePercentage() public view returns (uint16) {
        return treasuryEthFeePercentage;
    }

    function getGasManagerPercent() public view returns (uint16) {
        return gasManagerPercent;
    }

    function getDestinationPercentage() public view returns (uint16) {
        return destinationPercentage;
    }

    function getFarmingPercentage() public view returns (uint16) {
        return farmingPercentage;
    }

    function getSwapFee() public view returns (uint24) {
        return swapFee;
    }

    function getSlippage() public view returns (uint16) {
        return slippage;
    }

    function getWethSwapped() public view returns (uint256) {
        return WethSwapped;
    }

    function getEthSentFarming() public view returns (uint256) {
        return EthSentFarming;
    }

    function getEthSentTreasury() public view returns (uint256) {
        return EthSentTreasury;
    }

    function getUSDCSentTreasury() public view returns (uint256) {
        return USDCSentTreasury;
    }

    function getEthValueOfUSDCSentToTreasury() public view returns (uint256) {
        return EthValueOfUSDCSentToTreasury;
    }

    function getUSDCSentForGas() public view returns (uint256) {
        return USDCSentForGas;
    }

    function getEthValueOfUSDCSentToGas() public view returns (uint256) {
        return EthValueOfUSDCSentToGas;
    }

    function getUSDCForDestination() public view returns (uint256) {
        return USDCForDestination;
    }

    function getEthValueOfUSDCForDestination() public view returns (uint256) {
        return EthValueOfUSDCForDestination;
    }

    function getUsdcSentAvax() public view returns (uint256) {
        return UsdcSentAvax;
    }

    function getUsdcSentEth() public view returns (uint256) {
        return UsdcSentEth;
    }

    function getUsdcSentBNB() public view returns (uint256) {
        return UsdcSentBNB;
    }

    function getUsdcSentBase() public view returns (uint256) {
        return UsdcSentBase;
    }

    function getUsdcSentArbitrum() public view returns (uint256) {
        return UsdcSentArbitrum;
    }

    function getUsdcSentPolygon() public view returns (uint256) {
        return UsdcSentPolygon;
    }

    function getUsdcSentOptimism() public view returns (uint256) {
        return UsdcSentOptimism;
    }

    function getEthReceivedTotal() public view returns (uint256) {
        return ethReceivedTotal;
    }

    function getEthReceivedValueUSD() public view returns (uint256) {
        return ethReceivedValueUSD;
    }

    function getMinEthToSwap() public view returns (uint256) {
        return minEthToSwap;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = address(this).balance >= minEthToSwap;
    }

    function performUpkeep(bytes calldata) external override {
        require(address(this).balance >= minEthToSwap, "Nothing to Swap");
        _swapAndSend();
    }

    function _swapWeth(uint256 amount) internal returns (uint256) {
        wethToken.deposit{value: amount}();
        uint256 amountIn = amount;

        uint256 WETH9price = uint256(getWETH9Price());
        uint256 USDCprice = uint256(getUSDCPrice()) * 10 ** 12;

        uint256 amountInWETH = (amountIn * WETH9price) / USDCprice;
        uint256 amountInUSDC = amountInWETH / 10 ** 12;
        uint256 minAmountOut = amountInUSDC -
            ((amountInUSDC * slippage) / 10000);

        wethToken.approve(address(swapRouter02), amountIn);
        WethSwapped += amountIn;

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: address(wethToken),
                tokenOut: address(usdcToken),
                fee: swapFee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter02.exactInputSingle(params);

        wethToken.approve(address(swapRouter02), 0);

        emit SwapExecuted(
            address(wethToken),
            address(usdcToken),
            amountIn,
            amountOut,
            address(this)
        );
        return amountOut;
    }

    function swapV3(
        address tokenIn,
        address tokenOut,
        uint24 Fee,
        uint256 amountIn,
        uint256 minAmountOut
    ) external onlyAdmin {
        IERC20(tokenIn).approve(address(swapRouter02), amountIn);
        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: Fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter02.exactInputSingle(params);
        IERC20(tokenIn).approve(address(swapRouter02), 0);

        emit SwapExecuted(
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            address(this)
        );
    }

    function swapAndSend() external onlyAdmin {
        _swapAndSend();
    }

    function _swapAndSend() internal {
        if (address(this).balance > 0) {
            uint256 totalEth = address(this).balance; // total eth in contract
            uint256 treasuryAmountEth = (totalEth * treasuryEthFeePercentage) /
                100;
            uint256 treasuryAmountUSDC = (totalEth *
                treasuryUSDCFeePercentage) / 100;
            uint256 gasAmount = (totalEth * gasManagerPercent) / 100;
            uint256 farmingAmount = (totalEth * farmingPercentage) / 100;
            uint256 destinationAmount = totalEth -
                treasuryAmountEth -
                treasuryAmountUSDC -
                gasAmount -
                farmingAmount;

            if (farmingAmount > 0) {
                _distributeETHToContracts(farmingAmount);
                EthSentFarming += farmingAmount;
            }

            if (treasuryAmountEth > 0) {
                (bool success, ) = treasuryWallet.call{
                    value: treasuryAmountEth
                }("");
                require(success, "ETH transfer failed");
                EthSentTreasury += treasuryAmountEth;
            }

            if (treasuryAmountUSDC > 0) {
                uint256 amountForTreasuryUsdc = _swapWeth(treasuryAmountUSDC);
                IERC20(usdcToken).transfer(
                    treasuryWallet,
                    amountForTreasuryUsdc
                );
                USDCSentTreasury += amountForTreasuryUsdc;
                EthValueOfUSDCSentToTreasury += treasuryAmountUSDC;
            }

            if (gasAmount > 0) {
                uint256 amountForGasUSDC = _swapWeth(gasAmount);
                IERC20(usdcToken).transfer(gasManager, amountForGasUSDC);
                USDCSentForGas += amountForGasUSDC;
                EthValueOfUSDCSentToGas += gasAmount;
            }

            if (destinationAmount > 0) {
                uint256 amountForDestinationUSDC = _swapWeth(destinationAmount);
                USDCForDestination += amountForDestinationUSDC;
                EthValueOfUSDCForDestination += destinationAmount;

                uint256 totalUSDC = amountForDestinationUSDC;
                uint256 usdcForArb = (totalUSDC *
                    arbitrumDestinationPercentage) / 100;
                uint256 usdcForAvax = (totalUSDC * avaxDestinationPercentage) /
                    100;
                uint256 usdcForBnb = (totalUSDC * bnbDestinationPercentage) /
                    100;
                uint256 usdcForBase = (totalUSDC * baseDestinationPercentage) /
                    100;
                uint256 usdcForPoly = (totalUSDC *
                    polygonDestinationPercentage) / 100;
                uint256 usdcForOpt = (totalUSDC *
                    optimismDestinationPercentage) / 100;
                uint256 usdcForEth = (totalUSDC * ethDestinationPercentage) /
                    100;

                if (arbitrumActive && usdcForArb > 0) {
                    _transferTokensPayLINK(
                        arbitrumDestinationSelector,
                        arbitrumDestinationReceiver,
                        address(usdcToken),
                        usdcForArb
                    );
                    UsdcSentArbitrum += usdcForArb;
                }

                if (avaxActive && usdcForAvax > 0) {
                    _transferTokensPayLINK(
                        avaxDestinationSelector,
                        avaxDestinationReceiver,
                        address(usdcToken),
                        usdcForAvax
                    );
                    UsdcSentAvax += usdcForAvax;
                }

                if (baseActive && usdcForBase > 0) {
                    _transferTokensPayLINK(
                        baseDestinationSelector,
                        baseDestinationReceiver,
                        address(usdcToken),
                        usdcForBase
                    );
                    UsdcSentBase += usdcForBase;
                }

                if (bnbActive && usdcForBnb > 0) {
                    _transferTokensPayLINK(
                        bnbDestinationSelector,
                        bnbDestinationReceiver,
                        address(usdcToken),
                        usdcForBnb
                    );
                    UsdcSentBNB += usdcForBnb;
                }

                if (polygonActive && usdcForPoly > 0) {
                    _transferTokensPayLINK(
                        polygonDestinationSelector,
                        polygonDestinationReceiver,
                        address(usdcToken),
                        usdcForPoly
                    );
                    UsdcSentPolygon += usdcForPoly;
                }

                if (optimismActive && usdcForOpt > 0) {
                    _transferTokensPayLINK(
                        optimismDestinationSelector,
                        optimismDestinationReceiver,
                        address(usdcToken),
                        usdcForOpt
                    );
                    UsdcSentOptimism += usdcForOpt;
                }

                if (ethActive && usdcForEth > 0) {
                    _transferTokensPayLINK(
                        ethDestinationSelector,
                        ethDestinationReceiver,
                        address(usdcToken),
                        usdcForEth
                    );
                    UsdcSentEth += usdcForEth;
                }
            }
        }
    }

    function transferTokensPayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    ) external onlyAdmin {
        _transferTokensPayLINK(
            _destinationChainSelector,
            _receiver,
            _token,
            _amount
        );
    }

    function _transferTokensPayLINK(
        uint64 _destinationChainSelector,
        address _receiver,
        address _token,
        uint256 _amount
    )
        internal
        onlyAllowlistedChain(_destinationChainSelector)
        validateReceiver(_receiver)
        returns (bytes32 messageId)
    {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _token,
            _amount,
            address(s_linkToken)
        );

        uint256 fees = s_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        s_linkToken.approve(address(s_router), fees);

        IERC20(_token).approve(address(s_router), _amount);

        messageId = s_router.ccipSend(
            _destinationChainSelector,
            evm2AnyMessage
        );

        emit TokensTransferred(
            messageId,
            _destinationChainSelector,
            _receiver,
            _token,
            _amount,
            address(s_linkToken),
            fees
        );

        // Return the message ID
        return messageId;
    }

    function _buildCCIPMessage(
        address _receiver,
        address _token,
        uint256 _amount,
        address _feeTokenAddress
    ) private pure returns (Client.EVM2AnyMessage memory) {
        // Set the token amounts
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: _token,
            amount: _amount
        });
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: "", // No data
                tokenAmounts: tokenAmounts, // The amount and type of token being transferred
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 0})
                ),
                feeToken: _feeTokenAddress
            });
    }

    receive() external payable {
        ethReceivedTotal += msg.value;
        int256 ethPrice = getWETH9Price();
        ethReceivedValueUSD += (uint256(ethPrice) * msg.value) / 10 ** 18;
    }

    //=====================================================================================================================================================
    function withdraw(address _beneficiary) public onlyMultisig {
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = _beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, _beneficiary, amount);
    }

    function withdrawToken(
        address _beneficiary,
        address _token
    ) public onlyMultisig {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount == 0) revert NothingToWithdraw();
        IERC20(_token).transfer(_beneficiary, amount);
    }

    //=====================================================================================================================================================

    function addFarmingContract(address _contract) external onlyAdmin {
        require(!isContractAdded(_contract), "Contract already added");
        farmingContracts.push(_contract);
    }

    function removeFarmingContract(address _contract) external onlyAdmin {
        require(isContractAdded(_contract), "Contract not found");
        for (uint i = 0; i < farmingContracts.length; i++) {
            if (farmingContracts[i] == _contract) {
                farmingContracts[i] = farmingContracts[
                    farmingContracts.length - 1
                ];
                farmingContracts.pop();
                break;
            }
        }
    }

    function isContractAdded(address _contract) public view returns (bool) {
        for (uint i = 0; i < farmingContracts.length; i++) {
            if (farmingContracts[i] == _contract) {
                return true;
            }
        }
        return false;
    }

    function _distributeETHToContracts(uint256 _amount) internal {
        uint256 totalETH = _amount;
        require(totalETH > 0, "No ETH available for distribution");
        require(
            farmingContracts.length > 0,
            "No farming contracts to distribute to"
        );

        uint256 amountPerContract = totalETH / farmingContracts.length;

        for (uint i = 0; i < farmingContracts.length; i++) {
            // Ensure there is no contract address that is zero
            require(
                farmingContracts[i] != address(0),
                "Invalid contract address"
            );

            // Send ETH to each farming contract
            (bool success, ) = farmingContracts[i].call{
                value: amountPerContract
            }("");
            require(success, "ETH transfer failed");
        }
    }
}
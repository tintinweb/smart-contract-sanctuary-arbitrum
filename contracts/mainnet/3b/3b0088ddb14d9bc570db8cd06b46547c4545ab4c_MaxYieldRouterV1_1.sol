/**
 *Submitted for verification at Arbiscan.io on 2024-04-28
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

contract MaxYieldRouterV1_1 is OwnerIsCreator, AutomationCompatibleInterface {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    error DestinationChainNotAllowlisted(uint64 destinationChainSelector); // Used when the destination chain has not been allowlisted by the contract owner.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.
    // Event emitted when the tokens are transferred to an account on another chain.
    event TokensTransferred(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    );

    event NoActionNeeded(string message);

    struct SwapConfig {
        address inputToken;
        address outputToken;
        uint24 fee;
        bool active; // This allows to activate or deactivate the swap.
    }

    // Mapping to keep track of allowlisted destination chains.
    mapping(uint64 => bool) public allowlistedChains;

    IRouterClient private s_router;
    ISwapRouter02 private swapRouter02;
    AggregatorV3Interface internal WETH9PriceFeed;
    AggregatorV3Interface internal USDCPriceFeed;

    IERC20 public s_linkToken;
    IERC20 public usdcToken;
    IERC20 public wethToken;
    SwapConfig public tokenAConfig;
    SwapConfig public tokenBConfig;
    SwapConfig public tokenCConfig;
    SwapConfig public tokenDConfig;
    SwapConfig public tokenEConfig;
    address private multisigWallet;
    address public gasManager;
    address public destinationReceiver;
    address public treasuryWallet;
    uint16 public treasuryFeePercentage;
    address public buybackManager;
    uint16 public buybackPercentage;
    uint16 public gasManagerPercent;
    uint64 public destinationChain;
    uint24 public swapFee = 500;
    uint16 private slippage = 50; //.5%
    uint256 private WethSwapped;
    uint256 private UsdcSent;
    uint256 private treasuryAmountSent;
    uint256 private gasAmountSent;
    uint256 private buybackAmountSent;
    uint256 public minEthToSwap;
    uint256 public minUSDCToSwap;
    bool private locked = false;
    bool public bridging = true;

    constructor(
        address _router,
        address _link,
        address _usdcToken,
        address _wethToken
    ) {
        s_router = IRouterClient(_router);
        s_linkToken = IERC20(_link);
        usdcToken = IERC20(_usdcToken);
        wethToken = IERC20(_wethToken);
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

    function toggleBridging(bool _bridging) public onlyOwner {
        bridging = _bridging;
    }

    function setMultisigWallet(address _multisigWallet) external onlyMultisig {
        require(_multisigWallet != address(0), "Invalid address");
        multisigWallet = _multisigWallet;
    }

    function setTokenAConfig(
        address _inputToken,
        address _outputToken,
        uint24 _fee,
        bool _active
    ) external onlyAdmin {
        tokenAConfig = SwapConfig({
            inputToken: _inputToken,
            outputToken: _outputToken,
            fee: _fee,
            active: _active
        });
    }

    function setTokenBConfig(
        address _inputToken,
        address _outputToken,
        uint24 _fee,
        bool _active
    ) external onlyAdmin {
        tokenBConfig = SwapConfig({
            inputToken: _inputToken,
            outputToken: _outputToken,
            fee: _fee,
            active: _active
        });
    }

    function setTokenCConfig(
        address _inputToken,
        address _outputToken,
        uint24 _fee,
        bool _active
    ) external onlyAdmin {
        tokenCConfig = SwapConfig({
            inputToken: _inputToken,
            outputToken: _outputToken,
            fee: _fee,
            active: _active
        });
    }

    function setTokenDConfig(
        address _inputToken,
        address _outputToken,
        uint24 _fee,
        bool _active
    ) external onlyAdmin {
        tokenDConfig = SwapConfig({
            inputToken: _inputToken,
            outputToken: _outputToken,
            fee: _fee,
            active: _active
        });
    }

    function setTokenEConfig(
        address _inputToken,
        address _outputToken,
        uint24 _fee,
        bool _active
    ) external onlyAdmin {
        tokenEConfig = SwapConfig({
            inputToken: _inputToken,
            outputToken: _outputToken,
            fee: _fee,
            active: _active
        });
    }

    function allowlistDestinationChain(
        uint64 _destinationChainSelector,
        bool allowed
    ) external onlyAdmin {
        allowlistedChains[_destinationChainSelector] = allowed;
    }

    function setMinAmtsToSwap(
        uint256 _minEthToSwap,
        uint256 _minUsdcToSwap
    ) external onlyAdmin {
        minEthToSwap = _minEthToSwap;
        minUSDCToSwap = _minUsdcToSwap;
    }

    function setDestinationChain(uint64 _destinationChain) external onlyAdmin {
        destinationChain = _destinationChain;
    }

    function setDestinationReceiver(
        address _destinationReceiver
    ) external onlyAdmin {
        destinationReceiver = _destinationReceiver;
    }

    function setGasManagerConfig(
        address _gasManager,
        uint16 _gasManagerPercent
    ) external onlyAdmin {
        require(
            buybackPercentage + treasuryFeePercentage + _gasManagerPercent <=
                100,
            "Percentage cannot exceed 100"
        );
        gasManager = _gasManager;
        gasManagerPercent = _gasManagerPercent;
    }

    function setTreasuryConfig(
        address _treasuryWallet,
        uint16 _treasuryFeePercentage
    ) external onlyAdmin {
        require(
            _treasuryFeePercentage + gasManagerPercent + buybackPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        treasuryWallet = _treasuryWallet;
        treasuryFeePercentage = _treasuryFeePercentage;
    }

    function setBuybackConfig(
        address _buyback,
        uint16 _buybackPercentage
    ) external onlyAdmin {
        require(
            treasuryFeePercentage + gasManagerPercent + _buybackPercentage <=
                100,
            "Percentage cannot exceed 100"
        );
        buybackManager = _buyback;
        buybackPercentage = _buybackPercentage;
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

    function getWethSwapped() public view returns (uint256) {
        return WethSwapped;
    }

    function getUsdcSent() public view returns (uint256) {
        return UsdcSent;
    }

    function getTreasurySent() public view returns (uint256) {
        return treasuryAmountSent;
    }

    function getGasAmountSent() public view returns (uint256) {
        return gasAmountSent;
    }

    function getBuybackAmountSent() public view returns (uint256) {
        return buybackAmountSent;
    }

    function swapWeth() external onlyAdmin {
        _swapWeth();
    }

    function checkUpkeep(bytes calldata ) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded =
            (IERC20(wethToken).balanceOf(address(this)) >= minEthToSwap) ||
            (IERC20(usdcToken).balanceOf(address(this)) >= minUSDCToSwap);
    }

    function performUpkeep(bytes calldata ) external override {
        require(
            (IERC20(wethToken).balanceOf(address(this)) >= minEthToSwap) ||
                (IERC20(usdcToken).balanceOf(address(this)) >= minUSDCToSwap),
            "Nothing to Swap"
        );
        _swapAndSend();
    }

    function _swapWeth() internal {
        require(
            IERC20(wethToken).balanceOf(address(this)) > 0,
            "No Weth to swap"
        );
        uint256 amountIn = IERC20(wethToken).balanceOf(address(this));
        uint256 WETH9price = uint256(getWETH9Price());
        uint256 USDCprice = uint256(getUSDCPrice()) * 10 ** 12;

        uint256 amountInWETH = (amountIn * WETH9price) / USDCprice;
        uint256 amountInUSDC = amountInWETH / 10 ** 12;
        uint256 minAmountOut = amountInUSDC -
            ((amountInUSDC * slippage) / 10000);

        IERC20(wethToken).approve(address(swapRouter02), amountIn);
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
        IERC20(wethToken).approve(address(swapRouter02), 0);

        emit SwapExecuted(
            address(wethToken),
            address(usdcToken),
            amountIn,
            amountOut,
            address(this)
        );
    }

    function _performSwap(SwapConfig memory config) internal {
        uint256 amountIn = IERC20(config.inputToken).balanceOf(address(this));

        IERC20(config.inputToken).approve(address(swapRouter02), amountIn);

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02
            .ExactInputSingleParams({
                tokenIn: config.inputToken,
                tokenOut: config.outputToken,
                fee: config.fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter02.exactInputSingle(params);
        IERC20(config.inputToken).approve(address(swapRouter02), 0);

        emit SwapExecuted(
            config.inputToken,
            config.outputToken,
            amountIn,
            amountOut,
            address(this)
        );
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
        if (
            tokenAConfig.active &&
            IERC20(tokenAConfig.inputToken).balanceOf(address(this)) > 0
        ) {
            _performSwap(tokenAConfig);
        }

        if (
            tokenBConfig.active &&
            IERC20(tokenBConfig.inputToken).balanceOf(address(this)) > 0
        ) {
            _performSwap(tokenBConfig);
        }

        if (
            tokenCConfig.active &&
            IERC20(tokenCConfig.inputToken).balanceOf(address(this)) > 0
        ) {
            _performSwap(tokenCConfig);
        }

        if (
            tokenDConfig.active &&
            IERC20(tokenDConfig.inputToken).balanceOf(address(this)) > 0
        ) {
            _performSwap(tokenDConfig);
        }

        if (
            tokenEConfig.active &&
            IERC20(tokenEConfig.inputToken).balanceOf(address(this)) > 0
        ) {
            _performSwap(tokenEConfig);
        }

        if (IERC20(wethToken).balanceOf(address(this)) > 0) {
            _swapWeth();
        }

        if (IERC20(usdcToken).balanceOf(address(this)) > 0) {
            uint256 totalUSDC = IERC20(usdcToken).balanceOf(address(this));
            uint256 treasuryAmount = (totalUSDC * treasuryFeePercentage) / 100;
            uint256 gasAmount = (totalUSDC * gasManagerPercent) / 100;
            uint256 buybackAmount = (totalUSDC * buybackPercentage) / 100;
            uint256 amountToSend = totalUSDC -
                treasuryAmount -
                gasAmount -
                buybackAmount;

            if (treasuryAmount > 0) {
                require(
                    IERC20(usdcToken).transfer(treasuryWallet, treasuryAmount),
                    "Treasury transfer failed"
                );
                treasuryAmountSent += treasuryAmount;
            }

            if (gasAmount > 0) {
                require(
                    IERC20(usdcToken).transfer(gasManager, gasAmount),
                    "Gas transfer failed"
                );
                gasAmountSent += gasAmount;
            }

            if (buybackAmount > 0) {
                require(
                    IERC20(usdcToken).transfer(buybackManager, buybackAmount),
                    "Buyback transfer failed"
                );

                buybackAmountSent += buybackAmount;
            }

            if (amountToSend > 0 && bridging) {
                _transferTokensPayLINK(
                    destinationChain,
                    destinationReceiver,
                    address(usdcToken),
                    amountToSend
                );
                UsdcSent += amountToSend;
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

    receive() external payable {}

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
}
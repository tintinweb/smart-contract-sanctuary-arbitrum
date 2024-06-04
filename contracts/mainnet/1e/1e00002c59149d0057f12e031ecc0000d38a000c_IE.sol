// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {SafeTransferLib} from "../lib/solady/src/utils/SafeTransferLib.sol";
import {MetadataReaderLib} from "../lib/solady/src/utils/MetadataReaderLib.sol";

/// @title Intents Engine (IE)
/// @notice Simple helper contract for turning transactional intents into executable code.
/// @dev V1 simulates typical commands (sending and swapping tokens) and includes execution.
/// IE also has a workflow to verify the intent of ERC4337 account userOps against calldata.
/// @author nani.eth (https://github.com/NaniDAO/ie)
/// @custom:version 1.3.0
contract IE {
    /// ======================= LIBRARY USAGE ======================= ///

    /// @dev Token transfer library.
    using SafeTransferLib for address;

    /// @dev Token metadata reader library.
    using MetadataReaderLib for address;

    /// ======================= CUSTOM ERRORS ======================= ///

    /// @dev Bad math.
    error Overflow();

    /// @dev 0-liquidity.
    error InvalidSwap();

    /// @dev Invalid command.
    error InvalidSyntax();

    /// @dev Non-numeric character.
    error InvalidCharacter();

    /// @dev Insufficient swap output.
    error InsufficientSwap();

    /// @dev Invalid selector for the given asset spend.
    error InvalidSelector();

    /// =========================== EVENTS =========================== ///

    /// @dev Logs the registration of a token name alias.
    event AliasSet(address indexed token, string name);

    /// @dev Logs the registration of a token swap pool pair route on Uniswap V3.
    event PairSet(address indexed token0, address indexed token1, address pair);

    /// ========================== STRUCTS ========================== ///

    /// @dev The ERC4337 user operation (userOp) struct.
    struct UserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

    /// @dev The packed ERC4337 userOp struct.
    struct PackedUserOperation {
        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        bytes32 accountGasLimits;
        uint256 preVerificationGas;
        bytes32 gasFees;
        bytes paymasterAndData;
        bytes signature;
    }

    /// @dev The `swap` command information struct.
    struct SwapInfo {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        bool ETHIn;
        bool ETHOut;
    }

    /// @dev The `swap` pool liquidity struct.
    struct SwapLiq {
        address pool;
        uint256 liq;
    }

    /// ========================= CONSTANTS ========================= ///

    /// @dev The governing DAO address.
    address internal constant DAO = 0xDa000000000000d2885F108500803dfBAaB2f2aA;

    /// @dev The onchain akashic library.
    address internal constant AKA = 0x000000000000394793B2Fe854281CeE09a98bdBC;

    /// @dev The NANI token address.
    address internal constant NANI = 0x000000000000C6A645b0E51C9eCAA4CA580Ed8e8;

    /// @dev The conventional ERC7528 ETH address.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The canonical wrapped ETH address.
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /// @dev The popular wrapped BTC address.
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    /// @dev The Circle USD stablecoin address.
    address internal constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    /// @dev The Tether USD stablecoin address.
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    /// @dev The Maker DAO USD stablecoin address.
    address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    /// @dev The Arbitrum DAO governance token address.
    address internal constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;

    /// @dev The Lido Wrapped Staked ETH token address.
    address internal constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;

    /// @dev The Rocket Pool Staked ETH token address.
    address internal constant RETH = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;

    /// @dev The address of the Uniswap V3 Factory.
    address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @dev The Uniswap V3 Pool `initcodehash`.
    bytes32 internal constant UNISWAP_V3_POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @dev The minimum value that can be returned from `getSqrtRatioAtTick` (plus one).
    uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128740;

    /// @dev The maximum value that can be returned from `getSqrtRatioAtTick` (minus one).
    uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970341;

    /// ========================== STORAGE ========================== ///

    /// @dev DAO-governed NAMI naming system on Arbitrum.
    INAMI internal nami = INAMI(0x000000006641B4C250AEA6B62A1e0067D300697a);

    /// @dev DAO-governed token name aliasing.
    mapping(string name => address) public tokens;

    /// @dev DAO-governed token address name aliasing.
    mapping(address token => string name) public aliases;

    /// @dev DAO-governed token swap pool routing on Uniswap V3.
    mapping(address token0 => mapping(address token1 => address)) public pairs;

    /// ======================== CONSTRUCTOR ======================== ///

    /// @dev Constructs this IE on the Arbitrum L2 of Ethereum.
    constructor() payable {}

    /// ====================== COMMAND PREVIEW ====================== ///

    /// @dev Preview natural language smart contract command.
    /// The `send` syntax uses ENS naming: 'send vitalik 20 DAI'.
    /// `swap` syntax uses common format: 'swap 100 DAI for WETH'.
    function previewCommand(string calldata intent)
        public
        view
        virtual
        returns (
            address to, // Receiver address.
            uint256 amount, // Formatted amount.
            uint256 minAmountOut, // Formatted amount.
            address token, // Asset to send `to`.
            bytes memory callData, // Raw calldata for send transaction.
            bytes memory executeCallData // Anticipates common execute API.
        )
    {
        string memory normalized = _lowercase(intent);
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer" || action == "pay" || action == "grant") {
            (string memory _to, string memory _amount, string memory _token) =
                _extractSend(normalized);
            (to, amount, token, callData, executeCallData) = previewSend(_to, _amount, _token);
        } else if (
            action == "swap" || action == "sell" || action == "exchange" || action == "stake"
        ) {
            (
                string memory amountIn,
                string memory amountOutMinimum,
                string memory tokenIn,
                string memory tokenOut
            ) = _extractSwap(normalized);
            (amount, minAmountOut, token, to) =
                previewSwap(amountIn, amountOutMinimum, tokenIn, tokenOut);
        } else {
            revert InvalidSyntax(); // Invalid command format.
        }
    }

    /// @dev Previews a `send` command from the parts of a matched intent string.
    function previewSend(string memory to, string memory amount, string memory token)
        public
        view
        virtual
        returns (
            address _to,
            uint256 _amount,
            address _token,
            bytes memory callData,
            bytes memory executeCallData
        )
    {
        uint256 decimals;
        (_token, decimals) = _returnTokenConstants(bytes32(bytes(token)));
        if (_token == address(0)) _token = tokens[token]; // Check storage.
        bool isETH = _token == ETH; // Memo whether the token is ETH or not.
        (, _to,) = whatIsTheAddressOf(to); // Fetch receiver address from ENS.
        _amount = _toUint(amount, decimals != 0 ? decimals : _token.readDecimals());
        if (!isETH) callData = abi.encodeCall(IToken.transfer, (_to, _amount));
        executeCallData =
            abi.encodeCall(IExecutor.execute, (isETH ? _to : _token, isETH ? _amount : 0, callData));
    }

    /// @dev Previews a `swap` command from the parts of a matched intent string.
    function previewSwap(
        string memory amountIn,
        string memory amountOutMinimum,
        string memory tokenIn,
        string memory tokenOut
    )
        public
        view
        virtual
        returns (uint256 _amountIn, uint256 _amountOut, address _tokenIn, address _tokenOut)
    {
        uint256 decimalsIn;
        uint256 decimalsOut;
        (_tokenIn, decimalsIn) = _returnTokenConstants(bytes32(bytes(tokenIn)));
        if (_tokenIn == address(0)) _tokenIn = tokens[tokenIn];
        (_tokenOut, decimalsOut) = _returnTokenConstants(bytes32(bytes(tokenOut)));
        if (_tokenOut == address(0)) _tokenOut = tokens[tokenOut];
        _amountIn = _toUint(amountIn, decimalsIn != 0 ? decimalsIn : _tokenIn.readDecimals());
        _amountOut =
            _toUint(amountOutMinimum, decimalsOut != 0 ? decimalsOut : _tokenOut.readDecimals());
    }

    /// @dev Checks ERC4337 userOp against the output of the command intent.
    function checkUserOp(string calldata intent, UserOperation calldata userOp)
        public
        view
        virtual
        returns (bool intentMatched)
    {
        (,,,,, bytes memory executeCallData) = previewCommand(intent);
        if (executeCallData.length != userOp.callData.length) return false;
        return keccak256(executeCallData) == keccak256(userOp.callData);
    }

    /// @dev Checks packed ERC4337 userOp against the output of the command intent.
    function checkPackedUserOp(string calldata intent, PackedUserOperation calldata userOp)
        public
        view
        virtual
        returns (bool intentMatched)
    {
        (,,,,, bytes memory executeCallData) = previewCommand(intent);
        if (executeCallData.length != userOp.callData.length) return false;
        return keccak256(executeCallData) == keccak256(userOp.callData);
    }

    /// @dev Checks and returns the canonical token address constant for a matched intent string.
    function _returnTokenConstants(bytes32 token)
        internal
        pure
        virtual
        returns (address _token, uint256 _decimals)
    {
        if (token == "eth" || token == "ether") return (ETH, 18);
        if (token == "usdc") return (USDC, 6);
        if (token == "usdt" || token == "tether") return (USDT, 6);
        if (token == "dai") return (DAI, 18);
        if (token == "arb" || token == "arbitrum") return (ARB, 18);
        if (token == "weth") return (WETH, 18);
        if (token == "wbtc" || token == "btc" || token == "bitcoin") return (WBTC, 8);
        if (token == "steth" || token == "wsteth" || token == "lido") return (WSTETH, 18);
        if (token == "reth") return (RETH, 18);
        if (token == "nani") return (NANI, 18);
    }

    /// @dev Checks and returns the canonical token string constant for a matched address.
    function _returnTokenAliasConstants(address token)
        internal
        pure
        virtual
        returns (string memory _token, uint256 _decimals)
    {
        if (token == USDC) return ("USDC", 6);
        if (token == USDT) return ("USDT", 6);
        if (token == DAI) return ("DAI", 18);
        if (token == ARB) return ("ARB", 18);
        if (token == WETH) return ("WETH", 18);
        if (token == WBTC) return ("WBTC", 8);
        if (token == WSTETH) return ("WSTETH", 18);
        if (token == RETH) return ("RETH", 18);
        if (token == NANI) return ("NANI", 18);
    }

    /// @dev Checks and returns popular pool pairs for WETH swaps.
    function _returnPoolConstants(address token0, address token1)
        internal
        pure
        virtual
        returns (address pool)
    {
        if (token0 == WSTETH && token1 == WETH) return 0x35218a1cbaC5Bbc3E57fd9Bd38219D37571b3537;
        if (token0 == WETH && token1 == RETH) return 0x09ba302A3f5ad2bF8853266e271b005A5b3716fe;
        if (token0 == WETH && token1 == USDC) return 0xC6962004f452bE9203591991D15f6b388e09E8D0;
        if (token0 == WETH && token1 == USDT) return 0x641C00A822e8b671738d32a431a4Fb6074E5c79d;
        if (token0 == WETH && token1 == DAI) return 0xA961F0473dA4864C5eD28e00FcC53a3AAb056c1b;
        if (token0 == WETH && token1 == ARB) return 0xC6F780497A95e246EB9449f5e4770916DCd6396A;
        if (token0 == WBTC && token1 == WETH) return 0x2f5e87C9312fa29aed5c179E456625D79015299c;
    }

    /// ===================== COMMAND EXECUTION ===================== ///

    /// @dev Executes a text command from an intent string.
    function command(string calldata intent) public payable virtual {
        string memory normalized = _lowercase(intent);
        bytes32 action = _extraction(normalized);
        if (action == "send" || action == "transfer" || action == "pay" || action == "grant") {
            (string memory to, string memory amount, string memory token) = _extractSend(normalized);
            send(to, amount, token);
        } else if (
            action == "swap" || action == "sell" || action == "exchange" || action == "stake"
        ) {
            (
                string memory amountIn,
                string memory amountOutMinimum,
                string memory tokenIn,
                string memory tokenOut
            ) = _extractSwap(normalized);
            swap(amountIn, amountOutMinimum, tokenIn, tokenOut);
        } else {
            revert InvalidSyntax(); // Invalid command format.
        }
    }

    /// @dev Executes a `send` command from the parts of a matched intent string.
    function send(string memory to, string memory amount, string memory token)
        public
        payable
        virtual
    {
        (address _token, uint256 decimals) = _returnTokenConstants(bytes32(bytes(token)));
        if (_token == address(0)) _token = tokens[token];
        (, address _to,) = whatIsTheAddressOf(to);
        if (_token == ETH) {
            _to.safeTransferETH(_toUint(amount, decimals));
        } else {
            _token.safeTransferFrom(
                msg.sender, _to, _toUint(amount, decimals != 0 ? decimals : _token.readDecimals())
            );
        }
    }

    /// @dev Executes a `swap` command from the parts of a matched intent string.
    function swap(
        string memory amountIn,
        string memory amountOutMinimum,
        string memory tokenIn,
        string memory tokenOut
    ) public payable virtual {
        SwapInfo memory info;
        uint256 decimalsIn;
        uint256 decimalsOut;
        (info.tokenIn, decimalsIn) = _returnTokenConstants(bytes32(bytes(tokenIn)));
        if (info.tokenIn == address(0)) info.tokenIn = tokens[tokenIn];
        (info.tokenOut, decimalsOut) = _returnTokenConstants(bytes32(bytes(tokenOut)));
        if (info.tokenOut == address(0)) info.tokenOut = tokens[tokenOut];
        info.ETHIn = info.tokenIn == ETH;
        if (info.ETHIn) info.tokenIn = WETH;
        info.ETHOut = info.tokenOut == ETH;
        if (info.ETHOut) info.tokenOut = WETH;
        info.amountIn =
            _toUint(amountIn, decimalsIn != 0 ? decimalsIn : info.tokenIn.readDecimals());
        if (info.amountIn >= 1 << 255) revert Overflow();
        (address pool, bool zeroForOne) = _computePoolAddress(info.tokenIn, info.tokenOut);
        (int256 amount0, int256 amount1) = ISwapRouter(pool).swap(
            !info.ETHOut ? msg.sender : address(this),
            zeroForOne,
            int256(info.amountIn),
            zeroForOne ? MIN_SQRT_RATIO_PLUS_ONE : MAX_SQRT_RATIO_MINUS_ONE,
            abi.encodePacked(info.ETHIn, info.ETHOut, msg.sender, info.tokenIn, info.tokenOut)
        );
        if (
            uint256(-(zeroForOne ? amount1 : amount0))
                < _toUint(
                    amountOutMinimum, decimalsOut != 0 ? decimalsOut : info.tokenOut.readDecimals()
                )
        ) revert InsufficientSwap();
    }

    /// @dev Fallback `uniswapV3SwapCallback`.
    /// If ETH is swapped, WETH is forwarded.
    fallback() external payable virtual {
        int256 amount0Delta;
        int256 amount1Delta;
        bool ETHIn;
        bool ETHOut;
        address payer;
        address tokenIn;
        address tokenOut;
        assembly ("memory-safe") {
            amount0Delta := calldataload(0x4)
            amount1Delta := calldataload(0x24)
            ETHIn := byte(0, calldataload(0x84))
            ETHOut := byte(0, calldataload(add(0x84, 1)))
            payer := shr(96, calldataload(add(0x84, 2)))
            tokenIn := shr(96, calldataload(add(0x84, 22)))
            tokenOut := shr(96, calldataload(add(0x84, 42)))
        }
        if (amount0Delta <= 0 && amount1Delta <= 0) revert InvalidSwap();
        (address pool, bool zeroForOne) = _computePoolAddress(tokenIn, tokenOut);
        assembly ("memory-safe") {
            if iszero(eq(caller(), pool)) { revert(codesize(), 0x00) }
        }
        if (ETHIn) {
            _wrapETH(uint256(zeroForOne ? amount0Delta : amount1Delta));
        } else {
            tokenIn.safeTransferFrom(
                payer, msg.sender, uint256(zeroForOne ? amount0Delta : amount1Delta)
            );
        }
        if (ETHOut) {
            uint256 amount = uint256(-(zeroForOne ? amount1Delta : amount0Delta));
            _unwrapETH(amount);
            payer.safeTransferETH(amount);
        }
    }

    /// @dev Computes the create2 address for given token pair.
    /// note: This process checks all available pools for price.
    function _computePoolAddress(address tokenA, address tokenB)
        internal
        view
        virtual
        returns (address pool, bool zeroForOne)
    {
        if (tokenA < tokenB) zeroForOne = true;
        else (tokenA, tokenB) = (tokenB, tokenA);
        pool = _returnPoolConstants(tokenA, tokenB);
        if (pool == address(0)) {
            pool = pairs[tokenA][tokenB];
            if (pool == address(0)) {
                address pool100 = _computePairHash(tokenA, tokenB, 100); // Lowest fee.
                address pool500 = _computePairHash(tokenA, tokenB, 500); // Lower fee.
                address pool3000 = _computePairHash(tokenA, tokenB, 3000); // Mid fee.
                address pool10000 = _computePairHash(tokenA, tokenB, 10000); // Hi fee.
                // Initialize an array to hold the liquidity information for each pool.
                SwapLiq[5] memory pools = [
                    SwapLiq(pool100, pool100.code.length != 0 ? _balanceOf(tokenA, pool100) : 0),
                    SwapLiq(pool500, pool500.code.length != 0 ? _balanceOf(tokenA, pool500) : 0),
                    SwapLiq(pool3000, pool3000.code.length != 0 ? _balanceOf(tokenA, pool3000) : 0),
                    SwapLiq(pool10000, pool10000.code.length != 0 ? _balanceOf(tokenA, pool10000) : 0),
                    SwapLiq(pool, 0) // Placeholder for top pool. This will hold outputs for comparison.
                ];
                // Iterate through the array to find the top pool with the highest liquidity in `tokenA`.
                for (uint256 i; i != 4; ++i) {
                    if (pools[i].liq > pools[4].liq) {
                        pools[4].liq = pools[i].liq;
                        pools[4].pool = pools[i].pool;
                    }
                }
                pool = pools[4].pool; // Return the top pool with likely best liquidity.
            }
        }
    }

    /// @dev Computes the create2 deployment hash for a given token pair.
    function _computePairHash(address token0, address token1, uint24 fee)
        internal
        pure
        virtual
        returns (address pool)
    {
        bytes32 salt = keccak256(abi.encode(token0, token1, fee));
        assembly ("memory-safe") {
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, UNISWAP_V3_POOL_INIT_CODE_HASH)
            mstore(0x01, shl(96, UNISWAP_V3_FACTORY))
            mstore(0x15, salt)
            pool := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore overwritten.
        }
    }

    /// @dev Wraps an `amount` of ETH to WETH and funds pool caller for swap.
    function _wrapETH(uint256 amount) internal virtual {
        assembly ("memory-safe") {
            pop(call(gas(), WETH, amount, codesize(), 0x00, codesize(), 0x00))
            mstore(0x14, caller()) // Store the `pool` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            pop(call(gas(), WETH, 0, 0x10, 0x44, codesize(), 0x00))
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Unwraps an `amount` of ETH from WETH for return.
    function _unwrapETH(uint256 amount) internal virtual {
        assembly ("memory-safe") {
            mstore(0x00, 0x2e1a7d4d) // `withdraw(uint256)`.
            mstore(0x20, amount) // Store the `amount` argument.
            pop(call(gas(), WETH, 0, 0x1c, 0x24, codesize(), 0x00))
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    function _balanceOf(address token, address account)
        internal
        view
        virtual
        returns (uint256 amount)
    {
        assembly ("memory-safe") {
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            mstore(0x14, account) // Store the `account` argument.
            pop(staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20))
            amount := mload(0x20)
        }
    }

    /// @dev ETH receiver fallback.
    /// Only canonical WETH can call.
    receive() external payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), WETH)) { revert(codesize(), 0x00) }
        }
    }

    /// ==================== COMMAND TRANSLATION ==================== ///

    /// @dev Returns the akashic library summary digest `about` a given `topic`.
    function read(string calldata topic) public view virtual returns (string memory about) {
        return IE(payable(AKA)).read(topic);
    }

    /// @dev Translates an `intent` from raw `command()` calldata.
    function translateCommand(bytes calldata callData)
        public
        pure
        virtual
        returns (string memory intent)
    {
        return string(callData[4:]);
    }

    /// @dev Translates an `intent` for send action from the solution `callData` of standard `execute()`.
    /// note: The function selector technically doesn't need to be `execute()` but params should match.
    function translateExecute(bytes calldata callData)
        public
        view
        virtual
        returns (string memory intent)
    {
        unchecked {
            (address target, uint256 value) = abi.decode(callData[4:68], (address, uint256));

            if (value != 0) {
                return string(
                    abi.encodePacked(
                        "send ",
                        _convertWeiToString(value, 18),
                        " ETH to 0x",
                        _toAsciiString(target)
                    )
                );
            }

            if (
                bytes4(callData[132:136]) != IToken.transfer.selector
                    && bytes4(callData[132:136]) != IToken.approve.selector
            ) revert InvalidSelector();
            bool transfer = bytes4(callData[132:136]) == IToken.transfer.selector;

            (string memory token, uint256 decimals) = _returnTokenAliasConstants(target);
            if (bytes(token).length == 0) token = aliases[target];
            if (decimals == 0) decimals = target.readDecimals(); // Sanity check.
            (target, value) = abi.decode(callData[136:], (address, uint256));

            return string(
                abi.encodePacked(
                    transfer ? "send " : "approve ",
                    _convertWeiToString(value, decimals),
                    " ",
                    token,
                    " to 0x",
                    _toAsciiString(target)
                )
            );
        }
    }

    /// @dev Translates the `intent` for `token` send action from the solution `tokenCalldata`.
    /// note: Designed for EOAs and raw verification. Token alias is checked against storage.
    function translateTokenTransfer(address token, bytes calldata tokenCalldata)
        public
        view
        virtual
        returns (string memory intent)
    {
        unchecked {
            if (
                bytes4(tokenCalldata) != IToken.transfer.selector
                    && bytes4(tokenCalldata) != IToken.approve.selector
            ) revert InvalidSelector();
            bool transfer = bytes4(tokenCalldata) == IToken.transfer.selector;
            (string memory tokenAlias, uint256 decimals) = _returnTokenAliasConstants(token);
            if (bytes(tokenAlias).length == 0) tokenAlias = aliases[token];
            if (decimals == 0) decimals = token.readDecimals(); // Sanity check.
            (address target, uint256 value) = abi.decode(tokenCalldata[4:], (address, uint256));

            return string(
                abi.encodePacked(
                    transfer ? "send " : "approve ",
                    _convertWeiToString(value, decimals),
                    " ",
                    tokenAlias,
                    " to 0x",
                    _toAsciiString(target)
                )
            );
        }
    }

    /// @dev Translate ERC4337 userOp `callData` into readable `intent`.
    function translateUserOp(UserOperation calldata userOp)
        public
        view
        virtual
        returns (string memory intent)
    {
        return bytes4(userOp.callData) == IExecutor.execute.selector
            ? translateExecute(userOp.callData)
            : translateCommand(userOp.callData);
    }

    /// @dev Translate packed ERC4337 userOp `callData` into readable `intent`.
    function translatePackedUserOp(PackedUserOperation calldata userOp)
        public
        view
        virtual
        returns (string memory intent)
    {
        return bytes4(userOp.callData) == IExecutor.execute.selector
            ? translateExecute(userOp.callData)
            : translateCommand(userOp.callData);
    }

    /// ================== BALANCE & SUPPLY HELPERS ================== ///

    /// @dev Returns resulting percentage change of ETH or token balance.
    function previewBalanceChange(address user, string calldata intent)
        public
        view
        virtual
        returns (uint256 percentage)
    {
        (, uint256 amount,, address token,,) = previewCommand(intent);
        return (amount * 100) / (token == ETH ? user.balance : _balanceOf(token, user));
    }

    /// @dev Returns the balance of a named account in a named token.
    function whatIsTheBalanceOf(string calldata name, /*(bob)*/ /*in*/ string calldata token)
        public
        view
        virtual
        returns (uint256 balance, uint256 balanceAdjusted)
    {
        (, address _name,) = whatIsTheAddressOf(name);
        (address _token, uint256 decimals) =
            _returnTokenConstants(bytes32(bytes(_lowercase(token))));
        if (_token == address(0)) _token = tokens[token];
        balance = _token == ETH ? _name.balance : _token.balanceOf(_name);
        balanceAdjusted = balance / 10 ** (decimals != 0 ? decimals : _token.readDecimals());
    }

    /// @dev Returns the total supply of a named token.
    function whatIsTheTotalSupplyOf(string calldata token)
        public
        view
        virtual
        returns (uint256 supply, uint256 supplyAdjusted)
    {
        (address _token, uint256 decimals) =
            _returnTokenConstants(bytes32(bytes(_lowercase(token))));
        if (_token == address(0)) _token = tokens[token];
        assembly ("memory-safe") {
            mstore(0x00, 0x18160ddd) // `totalSupply()`.
            if iszero(staticcall(gas(), _token, 0x1c, 0x04, 0x20, 0x20)) {
                revert(codesize(), 0x00)
            }
            supply := mload(0x20)
        }
        supplyAdjusted = supply / 10 ** (decimals != 0 ? decimals : _token.readDecimals());
    }

    /// ====================== ENS VERIFICATION ====================== ///

    /// @dev Returns ENS name ownership details.
    function whatIsTheAddressOf(string memory name)
        public
        view
        virtual
        returns (address owner, address receiver, bytes32 node)
    {
        // If address length, convert.
        if (bytes(name).length == 42) {
            receiver = _toAddress(name);
        } else {
            (owner, receiver, node) = nami.whatIsTheAddressOf(name);
        }
    }

    /// ========================= GOVERNANCE ========================= ///

    /// @dev Sets a public alias tag for a given `token` address. Governed by DAO.
    function setAlias(address token, string calldata _alias) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) } // Optimized for repeat.
        }
        string memory normalized = _lowercase(_alias);
        aliases[token] = _alias;
        emit AliasSet(tokens[normalized] = token, normalized);
    }

    /// @dev Sets a public alias and ticker for a given `token` address.
    function setAliasAndTicker(address token) public payable virtual {
        string memory normalizedName = _lowercase(token.readName());
        string memory normalizedSymbol = _lowercase(token.readSymbol());
        aliases[token] = normalizedSymbol;
        emit AliasSet(tokens[normalizedName] = token, normalizedName);
        emit AliasSet(tokens[normalizedSymbol] = token, normalizedSymbol);
    }

    /// @dev Sets a public pool `pair` for swapping. Governed by DAO.
    function setPair(address tokenA, address tokenB, address pair) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) } // Optimized for repeat.
        }
        if (tokenB < tokenA) (tokenA, tokenB) = (tokenB, tokenA);
        emit PairSet(tokenA, tokenB, pairs[tokenA][tokenB] = pair);
    }

    /// @dev Sets the Arbitrum naming singleton (NAMI). Governed by DAO.
    function setNAMI(INAMI NAMI) public payable virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), DAO)) { revert(codesize(), 0x00) } // Optimized for repeat.
        }
        nami = NAMI; // No event emitted since very infrequent if ever.
    }

    /// ===================== STRING OPERATIONS ===================== ///

    /// @dev Returns copy of string in lowercase.
    /// Modified from Solady LibString `toCase`.
    function _lowercase(string memory subject)
        internal
        pure
        virtual
        returns (string memory result)
    {
        assembly ("memory-safe") {
            let length := mload(subject)
            if length {
                result := add(mload(0x40), 0x20)
                subject := add(subject, 1)
                let flags := shl(add(70, shl(5, 0)), 0x3ffffff)
                let w := not(0)
                for { let o := length } 1 {} {
                    o := add(o, w)
                    let b := and(0xff, mload(add(subject, o)))
                    mstore8(add(result, o), xor(b, and(shr(b, flags), 0x20)))
                    if iszero(o) { break }
                }
                result := mload(0x40)
                mstore(result, length) // Store the length.
                let last := add(add(result, 0x20), length)
                mstore(last, 0) // Zeroize the slot after the string.
                mstore(0x40, add(last, 0x20)) // Allocate the memory.
            }
        }
    }

    /// @dev Extracts the first word (action) as bytes32.
    function _extraction(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (bytes32 result)
    {
        assembly ("memory-safe") {
            let str := add(normalizedIntent, 0x20)
            for { let i } lt(i, 0x20) { i := add(i, 1) } {
                let char := byte(0, mload(add(str, i)))
                if eq(char, 0x20) { break }
                result := or(result, shl(sub(248, mul(i, 8)), char))
            }
        }
    }

    /// @dev Extract the key words of normalized `send` intent.
    function _extractSend(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (string memory to, string memory amount, string memory token)
    {
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 4) return (parts[1], parts[2], parts[3]);
        if (parts.length == 5) return (parts[4], parts[1], parts[2]);
        else revert InvalidSyntax(); // Command is not formatted.
    }

    /// @dev Extract the key words of normalized `swap` intent.
    function _extractSwap(string memory normalizedIntent)
        internal
        pure
        virtual
        returns (
            string memory amountIn,
            string memory amountOutMinimum,
            string memory tokenIn,
            string memory tokenOut
        )
    {
        string[] memory parts = _split(normalizedIntent, " ");
        if (parts.length == 5) return (parts[1], "", parts[2], parts[4]);
        if (parts.length == 6) return (parts[1], parts[4], parts[2], parts[5]);
        else revert InvalidSyntax(); // Command is not formatted.
    }

    /// @dev Split the intent into an array of words.
    function _split(string memory base, bytes1 delimiter)
        internal
        pure
        virtual
        returns (string[] memory parts)
    {
        unchecked {
            bytes memory baseBytes = bytes(base);
            uint256 count = 1;
            for (uint256 i; i != baseBytes.length; ++i) {
                if (baseBytes[i] == delimiter) {
                    ++count;
                }
            }
            parts = new string[](count);
            uint256 partIndex;
            uint256 start;
            for (uint256 i; i <= baseBytes.length; ++i) {
                if (i == baseBytes.length || baseBytes[i] == delimiter) {
                    bytes memory part = new bytes(i - start);
                    for (uint256 j = start; j != i; ++j) {
                        part[j - start] = baseBytes[j];
                    }
                    parts[partIndex] = string(part);
                    ++partIndex;
                    start = i + 1;
                }
            }
        }
    }

    /// @dev Convert string to decimalized numerical value.
    function _toUint(string memory s, uint256 decimals)
        internal
        pure
        virtual
        returns (uint256 result)
    {
        unchecked {
            bool hasDecimal;
            uint256 decimalPlaces;
            bytes memory b = bytes(s);
            for (uint256 i; i != b.length; ++i) {
                if (b[i] >= "0" && b[i] <= "9") {
                    result = result * 10 + uint8(b[i]) - 48;
                    if (hasDecimal) {
                        ++decimalPlaces;
                        if (decimalPlaces > decimals) break;
                    }
                } else if (b[i] == "." && !hasDecimal) {
                    hasDecimal = true;
                } else {
                    revert InvalidCharacter();
                }
            }
            if (decimalPlaces < decimals) {
                result *= 10 ** (decimals - decimalPlaces);
            }
        }
    }

    /// @dev Converts a hexadecimal string to its `address` representation.
    /// Modified from Stack (https://ethereum.stackexchange.com/a/156916).
    function _toAddress(string memory s) internal pure virtual returns (address addr) {
        bytes memory _bytes = _hexStringToAddress(s);
        if (_bytes.length < 21) revert InvalidSyntax();
        assembly ("memory-safe") {
            addr := div(mload(add(add(_bytes, 0x20), 1)), 0x1000000000000000000000000)
        }
    }

    /// @dev Converts a hexadecimal string into its bytes representation.
    function _hexStringToAddress(string memory s) internal pure virtual returns (bytes memory r) {
        unchecked {
            bytes memory ss = bytes(s);
            if (ss.length % 2 != 0) revert InvalidSyntax(); // Length must be even.
            r = new bytes(ss.length / 2);
            for (uint256 i; i != ss.length / 2; ++i) {
                r[i] =
                    bytes1(_fromHexChar(uint8(ss[2 * i])) * 16 + _fromHexChar(uint8(ss[2 * i + 1])));
            }
        }
    }

    /// @dev Converts a single hexadecimal character into its numerical value.
    function _fromHexChar(uint8 c) internal pure virtual returns (uint8 result) {
        unchecked {
            if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) return c - uint8(bytes1("0"));
            if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
                return 10 + c - uint8(bytes1("a"));
            }
            if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
                return 10 + c - uint8(bytes1("A"));
            }
        }
    }

    /// @dev Convert an address to an ASCII string representation.
    function _toAsciiString(address x) internal pure virtual returns (string memory) {
        unchecked {
            bytes memory s = new bytes(40);
            for (uint256 i; i < 20; ++i) {
                bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i)))));
                bytes1 hi = bytes1(uint8(b) / 16);
                bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
                s[2 * i] = _char(hi);
                s[2 * i + 1] = _char(lo);
            }
            return string(s);
        }
    }

    /// @dev Convert a single byte to a character in the ASCII string.
    function _char(bytes1 b) internal pure virtual returns (bytes1 c) {
        unchecked {
            if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
            else return bytes1(uint8(b) + 0x57);
        }
    }

    /// @dev Convert number to string and insert decimal point.
    function _convertWeiToString(uint256 weiAmount, uint256 decimals)
        internal
        pure
        virtual
        returns (string memory)
    {
        unchecked {
            uint256 scalingFactor = 10 ** decimals;

            string memory wholeNumberStr = _toString(weiAmount / scalingFactor);
            string memory decimalPartStr = _toString(weiAmount % scalingFactor);

            while (bytes(decimalPartStr).length != decimals) {
                decimalPartStr = string(abi.encodePacked("0", decimalPartStr));
            }

            decimalPartStr = _removeTrailingZeros(decimalPartStr);

            if (bytes(decimalPartStr).length == 0) {
                return wholeNumberStr;
            }

            return string(abi.encodePacked(wholeNumberStr, ".", decimalPartStr));
        }
    }

    /// @dev Remove any trailing zeroes from string.
    function _removeTrailingZeros(string memory str)
        internal
        pure
        virtual
        returns (string memory)
    {
        unchecked {
            bytes memory strBytes = bytes(str);
            uint256 end = strBytes.length;

            while (end != 0 && strBytes[end - 1] == "0") {
                --end;
            }

            bytes memory trimmedBytes = new bytes(end);
            for (uint256 i; i != end; ++i) {
                trimmedBytes[i] = strBytes[i];
            }

            return string(trimmedBytes);
        }
    }

    /// @dev Returns the base 10 decimal representation of `value`.
    /// Modified from (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly ("memory-safe") {
            str := add(mload(0x40), 0x80)
            mstore(0x40, add(str, 0x20))
            mstore(str, 0)
            let end := str
            let w := not(0)
            for { let temp := value } 1 {} {
                str := add(str, w)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }
}

/// @dev Simple token handler interface.
interface IToken {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

/// @notice Simple calldata executor interface.
interface IExecutor {
    function execute(address, uint256, bytes calldata) external payable returns (bytes memory);
}

/// @dev Simple NAMI names interface for resolving L2 ENS ownership.
interface INAMI {
    function whatIsTheAddressOf(string calldata)
        external
        view
        returns (address, address, bytes32);
}

/// @dev Simple Uniswap V3 swapping interface.
interface ISwapRouter {
    function swap(address, bool, int256, uint160, bytes calldata)
        external
        returns (int256, int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Permit2 operations from (https://github.com/Uniswap/permit2/blob/main/src/libraries/Permit2Lib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The Permit2 operation has failed.
    error Permit2Failed();

    /// @dev The Permit2 amount must be less than `2**160 - 1`.
    error Permit2AmountOverflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /// @dev The unique EIP-712 domain domain separator for the DAI token contract.
    bytes32 internal constant DAI_DOMAIN_SEPARATOR =
        0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    /// @dev The address for the WETH9 contract on Ethereum mainnet.
    address internal constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev The canonical Permit2 address.
    /// [Github](https://github.com/Uniswap/permit2)
    /// [Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)
    address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    ///
    /// The `from` account must have at least `amount` approved for the current contract to manage.
    function trySafeTransferFrom(address token, address from, address to, uint256 amount)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            success :=
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul( // The arguments of `mul` are evaluated from right to left.
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// If the initial attempt fails, try to use Permit2 to transfer the token.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for the current contract to manage.
    function safeTransferFrom2(address token, address from, address to, uint256 amount) internal {
        if (!trySafeTransferFrom(token, from, to, amount)) {
            permit2TransferFrom(token, from, to, amount);
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to` via Permit2.
    /// Reverts upon failure.
    function permit2TransferFrom(address token, address from, address to, uint256 amount)
        internal
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x74), shr(96, shl(96, token)))
            mstore(add(m, 0x54), amount)
            mstore(add(m, 0x34), to)
            mstore(add(m, 0x20), shl(96, from))
            // `transferFrom(address,address,uint160,address)`.
            mstore(m, 0x36c78516000000000000000000000000)
            let p := PERMIT2
            let exists := eq(chainid(), 1)
            if iszero(exists) { exists := iszero(iszero(extcodesize(p))) }
            if iszero(and(call(gas(), p, 0, add(m, 0x10), 0x84, codesize(), 0x00), exists)) {
                mstore(0x00, 0x7939f4248757f0fd) // `TransferFromFailed()` or `Permit2AmountOverflow()`.
                revert(add(0x18, shl(2, iszero(iszero(shr(160, amount))))), 0x04)
            }
        }
    }

    /// @dev Permit a user to spend a given amount of
    /// another user's tokens via native EIP-2612 permit if possible, falling
    /// back to Permit2 if native permit fails or is not implemented on the token.
    function permit2(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        bool success;
        /// @solidity memory-safe-assembly
        assembly {
            for {} shl(96, xor(token, WETH9)) {} {
                mstore(0x00, 0x3644e515) // `DOMAIN_SEPARATOR()`.
                if iszero(
                    and( // The arguments of `and` are evaluated from right to left.
                        lt(iszero(mload(0x00)), eq(returndatasize(), 0x20)), // Returns 1 non-zero word.
                        // Gas stipend to limit gas burn for tokens that don't refund gas when
                        // an non-existing function is called. 5K should be enough for a SLOAD.
                        staticcall(5000, token, 0x1c, 0x04, 0x00, 0x20)
                    )
                ) { break }
                // After here, we can be sure that token is a contract.
                let m := mload(0x40)
                mstore(add(m, 0x34), spender)
                mstore(add(m, 0x20), shl(96, owner))
                mstore(add(m, 0x74), deadline)
                if eq(mload(0x00), DAI_DOMAIN_SEPARATOR) {
                    mstore(0x14, owner)
                    mstore(0x00, 0x7ecebe00000000000000000000000000) // `nonces(address)`.
                    mstore(add(m, 0x94), staticcall(gas(), token, 0x10, 0x24, add(m, 0x54), 0x20))
                    mstore(m, 0x8fcbaf0c000000000000000000000000) // `IDAIPermit.permit`.
                    // `nonces` is already at `add(m, 0x54)`.
                    // `1` is already stored at `add(m, 0x94)`.
                    mstore(add(m, 0xb4), and(0xff, v))
                    mstore(add(m, 0xd4), r)
                    mstore(add(m, 0xf4), s)
                    success := call(gas(), token, 0, add(m, 0x10), 0x104, codesize(), 0x00)
                    break
                }
                mstore(m, 0xd505accf000000000000000000000000) // `IERC20Permit.permit`.
                mstore(add(m, 0x54), amount)
                mstore(add(m, 0x94), and(0xff, v))
                mstore(add(m, 0xb4), r)
                mstore(add(m, 0xd4), s)
                success := call(gas(), token, 0, add(m, 0x10), 0xe4, codesize(), 0x00)
                break
            }
        }
        if (!success) simplePermit2(token, owner, spender, amount, deadline, v, r, s);
    }

    /// @dev Simple permit on the Permit2 contract.
    function simplePermit2(
        address token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0x927da105) // `allowance(address,address,address)`.
            {
                let addressMask := shr(96, not(0))
                mstore(add(m, 0x20), and(addressMask, owner))
                mstore(add(m, 0x40), and(addressMask, token))
                mstore(add(m, 0x60), and(addressMask, spender))
                mstore(add(m, 0xc0), and(addressMask, spender))
            }
            let p := mul(PERMIT2, iszero(shr(160, amount)))
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x5f), // Returns 3 words: `amount`, `expiration`, `nonce`.
                    staticcall(gas(), p, add(m, 0x1c), 0x64, add(m, 0x60), 0x60)
                )
            ) {
                mstore(0x00, 0x6b836e6b8757f0fd) // `Permit2Failed()` or `Permit2AmountOverflow()`.
                revert(add(0x18, shl(2, iszero(p))), 0x04)
            }
            mstore(m, 0x2b67b570) // `Permit2.permit` (PermitSingle variant).
            // `owner` is already `add(m, 0x20)`.
            // `token` is already at `add(m, 0x40)`.
            mstore(add(m, 0x60), amount)
            mstore(add(m, 0x80), 0xffffffffffff) // `expiration = type(uint48).max`.
            // `nonce` is already at `add(m, 0xa0)`.
            // `spender` is already at `add(m, 0xc0)`.
            mstore(add(m, 0xe0), deadline)
            mstore(add(m, 0x100), 0x100) // `signature` offset.
            mstore(add(m, 0x120), 0x41) // `signature` length.
            mstore(add(m, 0x140), r)
            mstore(add(m, 0x160), s)
            mstore(add(m, 0x180), shl(248, v))
            if iszero(call(gas(), p, 0, add(m, 0x1c), 0x184, codesize(), 0x00)) {
                mstore(0x00, 0x6b836e6b) // `Permit2Failed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading contract metadata robustly.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MetadataReaderLib.sol)
library MetadataReaderLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Default gas stipend for contract reads. High enough for most practical use cases
    /// (able to SLOAD about 1000 bytes of data), but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /// @dev Default string byte length limit.
    uint256 internal constant STRING_LIMIT_DEFAULT = 1000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                METADATA READING OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Best-effort string reading operations.
    // Should NOT revert as long as sufficient gas is provided.
    //
    // Performs the following in order:
    // 1. Returns the empty string for the following cases:
    //     - Reverts.
    //     - No returndata (e.g. function returns nothing, EOA).
    //     - Returns empty string.
    // 2. Attempts to `abi.decode` the returndata into a string.
    // 3. With any remaining gas, scans the returndata from start to end for the
    //    null byte '\0', to interpret the returndata as a null-terminated string.

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"))`.
    function readName(address target) internal view returns (string memory) {
        return _string(target, _ptr(0x06fdde03), STRING_LIMIT_DEFAULT, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"), limit)`.
    function readName(address target, uint256 limit) internal view returns (string memory) {
        return _string(target, _ptr(0x06fdde03), limit, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("name()"), limit, gasStipend)`.
    function readName(address target, uint256 limit, uint256 gasStipend)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(0x06fdde03), limit, gasStipend);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"))`.
    function readSymbol(address target) internal view returns (string memory) {
        return _string(target, _ptr(0x95d89b41), STRING_LIMIT_DEFAULT, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"), limit)`.
    function readSymbol(address target, uint256 limit) internal view returns (string memory) {
        return _string(target, _ptr(0x95d89b41), limit, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Equivalent to `readString(abi.encodeWithSignature("symbol()"), limit, gasStipend)`.
    function readSymbol(address target, uint256 limit, uint256 gasStipend)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(0x95d89b41), limit, gasStipend);
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    /// The string will be truncated to `STRING_LIMIT_DEFAULT` (1000) bytes.
    function readString(address target, bytes memory data) internal view returns (string memory) {
        return _string(target, _ptr(data), STRING_LIMIT_DEFAULT, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    /// The string will be truncated to `limit` bytes.
    function readString(address target, bytes memory data, uint256 limit)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(data), limit, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Performs a best-effort string query on `target` with `data` as the calldata.
    /// The string will be truncated to `limit` bytes.
    function readString(address target, bytes memory data, uint256 limit, uint256 gasStipend)
        internal
        view
        returns (string memory)
    {
        return _string(target, _ptr(data), limit, gasStipend);
    }

    // Best-effort unsigned integer reading operations.
    // Should NOT revert as long as sufficient gas is provided.
    //
    // Performs the following in order:
    // 1. Attempts to `abi.decode` the result into a uint256
    //    (equivalent across all Solidity uint types, downcast as needed).
    // 2. Returns zero for the following cases:
    //     - Reverts.
    //     - No returndata (e.g. function returns nothing, EOA).
    //     - Returns zero.
    //     - `abi.decode` failure.

    /// @dev Equivalent to `uint8(readUint(abi.encodeWithSignature("decimal()")))`.
    function readDecimals(address target) internal view returns (uint8) {
        return uint8(_uint(target, _ptr(0x313ce567), GAS_STIPEND_NO_GRIEF));
    }

    /// @dev Equivalent to `uint8(readUint(abi.encodeWithSignature("decimal()"), gasStipend))`.
    function readDecimals(address target, uint256 gasStipend) internal view returns (uint8) {
        return uint8(_uint(target, _ptr(0x313ce567), gasStipend));
    }

    /// @dev Performs a best-effort uint query on `target` with `data` as the calldata.
    function readUint(address target, bytes memory data) internal view returns (uint256) {
        return _uint(target, _ptr(data), GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Performs a best-effort uint query on `target` with `data` as the calldata.
    function readUint(address target, bytes memory data, uint256 gasStipend)
        internal
        view
        returns (uint256)
    {
        return _uint(target, _ptr(data), gasStipend);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Attempts to read and return a string at `target`.
    function _string(address target, bytes32 ptr, uint256 limit, uint256 gasStipend)
        private
        view
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            function min(x_, y_) -> _z {
                _z := xor(x_, mul(xor(x_, y_), lt(y_, x_)))
            }
            for {} staticcall(gasStipend, target, add(ptr, 0x20), mload(ptr), 0x00, 0x20) {} {
                let m := mload(0x40) // Grab the free memory pointer.
                let s := add(0x20, m) // Start of the string's bytes in memory.
                // Attempt to `abi.decode` if the returndatasize is greater or equal to 64.
                if iszero(lt(returndatasize(), 0x40)) {
                    let o := mload(0x00) // Load the string's offset in the returndata.
                    // If the string's offset is within bounds.
                    if iszero(gt(o, sub(returndatasize(), 0x20))) {
                        returndatacopy(m, o, 0x20) // Copy the string's length.
                        // If the full string's end is within bounds.
                        // Note: If the full string doesn't fit, the `abi.decode` must be aborted
                        // for compliance purposes, regardless if the truncated string can fit.
                        if iszero(gt(mload(m), sub(returndatasize(), add(o, 0x20)))) {
                            let n := min(mload(m), limit) // Truncate if needed.
                            mstore(m, n) // Overwrite the length.
                            returndatacopy(s, add(o, 0x20), n) // Copy the string's bytes.
                            mstore(add(s, n), 0) // Zeroize the slot after the string.
                            mstore(0x40, add(0x20, add(s, n))) // Allocate memory for the string.
                            result := m
                            break
                        }
                    }
                }
                // Try interpreting as a null-terminated string.
                let n := min(returndatasize(), limit) // Truncate if needed.
                returndatacopy(s, 0, n) // Copy the string's bytes.
                mstore8(add(s, n), 0) // Place a '\0' at the end.
                let i := s // Pointer to the next byte to scan.
                for {} byte(0, mload(i)) { i := add(i, 1) } {} // Scan for '\0'.
                mstore(m, sub(i, s)) // Store the string's length.
                mstore(i, 0) // Zeroize the slot after the string.
                mstore(0x40, add(0x20, i)) // Allocate memory for the string.
                result := m
                break
            }
        }
    }

    /// @dev Attempts to read and return a uint at `target`.
    function _uint(address target, bytes32 ptr, uint256 gasStipend)
        private
        view
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gasStipend, target, add(ptr, 0x20), mload(ptr), 0x20, 0x20)
                    )
                )
        }
    }

    /// @dev Casts the function selector `s` into a pointer.
    function _ptr(uint256 s) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Layout the calldata in the scratch space for temporary usage.
            mstore(0x04, s) // Store the function selector.
            mstore(result, 4) // Store the length.
        }
    }

    /// @dev Casts the `data` into a pointer.
    function _ptr(bytes memory data) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := data
        }
    }
}
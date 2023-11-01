pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// This contract was deployed using the Cheezburger Factory.
// You can check the tokenomics, website and social from the public read functions.
pragma solidity ^0.8.22;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {CheezburgerDynamicTokenomics} from "./CheezburgerDynamicTokenomics.sol";
import {ICheezburgerFactory} from "./interfaces/ICheezburgerFactory.sol";

contract CheezburgerBun is CheezburgerDynamicTokenomics, ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error TransferToZeroAddress(address from, address to);
    error TransferToToken(address to);
    error TransferMaxTokensPerWallet();
    error OnlyOneBuyPerBlockAllowed();
    error CannotReceiveEtherDirectly();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event LiquiditySwapSuccess(bool success);
    event LiquiditySwapFailed(string reason);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    string public FACTORY_VERSION = "Cheddar (1.1)";
    string private _name;
    string private _symbol;
    string private _website;
    string private _social;
    address public constant owner = address(0);
    mapping(address => uint256) private _holderLastBuyTimestamp;

    ICheezburgerFactory public immutable factory =
        ICheezburgerFactory(msg.sender);
    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;

    uint8 internal isSwapping = 1;

    constructor(
        TokenCustomization memory _customization,
        DynamicSettings memory _fees,
        DynamicSettings memory _wallet
    ) CheezburgerDynamicTokenomics(_fees, _wallet) {
        _name = _customization.name;
        _symbol = _customization.symbol;
        _website = _customization.website;
        _social = _customization.social;
        _mint(address(factory), _customization.supply * (10 ** decimals()));
    }

    /// @dev Prevents direct Ether transfers to contract
    receive() external payable {
        revert CannotReceiveEtherDirectly();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function website() public view returns (string memory) {
        return _website;
    }

    function social() public view returns (string memory) {
        return _social;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (to == address(this)) {
            revert TransferToToken(to);
        }

        // Cache pair internally if available
        if (address(pair) == address(0) || address(router) == address(0)) {
            if (address(factory).code.length > 0) {
                (IUniswapV2Router02 _router, IUniswapV2Pair _pair) = factory
                    .burgerRegistryRouterOnly(address(this));
                pair = _pair;
                router = _router;
            }
        }

        bool isBuying = from == address(pair);

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                        LIQUIDITY SWAP                      */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
        if (
            !isBuying &&
            isSwapping == 1 &&
            balanceOf(address(factory)) > 0 &&
            address(pair) != address(0) &&
            pair.totalSupply() > 0 &&
            from != address(router) &&
            to != address(router)
        ) {
            doLiquiditySwap();
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        // Must use burn() to burn tokens
        if (to == address(0) && balanceOf(address(0)) > 0) {
            revert TransferToZeroAddress(from, to);
        }

        // Don't look after self transfers
        if (from == to) {
            return;
        }

        // Ignore Factory-related txs
        if (to == address(factory) || from == address(factory)) {
            return;
        }

        bool isBuying = from == address(pair);
        bool isSelling = to == address(pair);
        DynamicTokenomicsStruct memory tokenomics = _getTokenomics(
            totalSupply()
        );

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                          TXS LIMITS                        */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

        if (isBuying) {
            bool buyFeeStillDecreasing = tokenomics.earlyAccessPremium !=
                tokenomics.sellFee;
            if (buyFeeStillDecreasing) {
                if (_holderLastBuyTimestamp[tx.origin] == block.number) {
                    revert OnlyOneBuyPerBlockAllowed();
                }
                _holderLastBuyTimestamp[tx.origin] = block.number;
            }
        }

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                            FEES                            */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

        uint256 feeAmount = 0;
        if (isBuying || isSelling) {
            unchecked {
                if (isBuying && tokenomics.earlyAccessPremium > 0) {
                    feeAmount = amount * tokenomics.earlyAccessPremium;
                } else if (isSelling && tokenomics.sellFee > 0) {
                    feeAmount = amount * tokenomics.sellFee;
                }
                if (feeAmount > 0) {
                    super._transfer(to, address(factory), feeAmount / 10000);
                    emit AppliedTokenomics(tokenomics);
                }
            }
        }

        /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
        /*                        WALLET LIMITS                       */
        /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

        if (!isSelling) {
            unchecked {
                bool walletExceedLimits = balanceOf(to) >
                    tokenomics.maxTokensPerWallet;
                if (walletExceedLimits) {
                    revert TransferMaxTokensPerWallet();
                }
            }
        }
    }

    function doLiquiditySwap() private lockSwap {
        try factory.beforeTokenTransfer(balanceOf(address(factory))) returns (
            bool result
        ) {
            emit LiquiditySwapSuccess(result);
        } catch Error(string memory reason) {
            emit LiquiditySwapFailed(reason);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// Burns tokens from the caller.
    ///
    /// @dev Burns `amount` tokens from the caller.
    ///
    /// See {ERC20-_burn}.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// Burns tokens from an account's allowance.
    ///
    /// @dev Burns `amount` tokens from `account`, deducting from the caller's
    /// allowance.
    ///
    /// See {ERC20-_burn} and {ERC20-allowance}.
    ///
    /// Requirements:
    ///
    /// - the caller must have allowance for ``accounts``'s tokens of at least
    /// `amount`.
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Get current dynamic tokenomics
    /// @return DynamicTokenomics struct with current values
    /// @notice Values will change dynamically based on configured durations and percentages
    function getTokenomics()
        external
        view
        returns (DynamicTokenomicsStruct memory)
    {
        return _getTokenomics(totalSupply());
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier lockSwap() {
        isSwapping = 2;
        _;
        isSwapping = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library CheezburgerConstants {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // The maximum amount of tokens that can be held on the pair is limited to the max uint112 value
    // uint112 ranges from 0 to 340,282,366,920,938,463,463,374,607,431,768,211,455
    uint256 private constant MAX_TOTAL_SUPPLY = type(uint112).max;
    // Dividing by 10**18 shifts the decimal place 18 spots to represent the value with 18 decimals
    // This allows the total supply to be represented as a common token amount in the external interface
    uint256 private constant MAX_TOKEN_SUPPLY = MAX_TOTAL_SUPPLY / (10 ** 18);
    // Calculate safety margin as 1% below max
    // SAFE_TOKEN_SUPPLY will be the enforced limit, providing a buffer
    // below the mathematical max to account for potential overflows
    uint256 internal constant SAFE_TOKEN_SUPPLY =
        MAX_TOKEN_SUPPLY - (MAX_TOKEN_SUPPLY / 100);
    uint8 internal constant MAX_LP_FEE = 4;
    uint256 internal constant FEE_DURATION_MIN = 1 hours;
    uint256 internal constant FEE_DURATION_CAP = 1 days;
    uint256 internal constant WALLET_DURATION_MIN = 1 days;
    uint256 internal constant WALLET_DURATION_CAP = 4 weeks;
    uint256 internal constant WALLET_MIN_PERCENT_END = 200;
    uint256 internal constant WALLET_MAX_PERCENT_END = 4900;
    uint256 internal constant MIN_NAME_LENGTH = 1;
    uint256 internal constant MAX_NAME_LENGTH = 128;
    uint256 internal constant MIN_SYMBOL_LENGTH = 1;
    uint256 internal constant MAX_SYMBOL_LENGTH = 128;
    uint256 internal constant MAX_URL_LENGTH = 256;
    uint256 internal constant FEE_START_MIN = 100;
    uint256 internal constant FEE_START_MAX = 4000;
    uint256 internal constant FEE_END_MAX = 500;
    uint8 internal constant THRESHOLD_MIN = 1;
    uint8 internal constant THRESHOLD_MAX = 5;
    uint256 internal constant FEE_ADDRESSES_MAX = 5;
    uint256 internal constant FEE_ADDRESSES_MIN = 1;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {CheezburgerStructs} from "./CheezburgerStructs.sol";

abstract contract CheezburgerDynamicTokenomics is CheezburgerStructs {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event AppliedTokenomics(DynamicTokenomicsStruct tokenomics);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 public immutable launchStart = block.timestamp;
    uint256 public immutable EARLY_ACCESS_PREMIUM_DURATION;
    uint16 public immutable EARLY_ACCESS_PREMIUM_START;
    uint16 public immutable EARLY_ACCESS_PREMIUM_END;
    uint16 public immutable SELL_FEE_END;
    uint256 public immutable MAX_WALLET_DURATION;
    uint16 public immutable MAX_WALLET_PERCENT_START;
    uint16 public immutable MAX_WALLET_PERCENT_END;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCT                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    struct DynamicTokenomicsStruct {
        uint16 earlyAccessPremium;
        uint16 sellFee;
        uint16 maxWalletPercentage;
        uint256 maxTokensPerWallet;
    }

    constructor(DynamicSettings memory _fee, DynamicSettings memory _wallet) {
        EARLY_ACCESS_PREMIUM_DURATION = _fee.duration;
        EARLY_ACCESS_PREMIUM_START = _fee.percentStart;
        EARLY_ACCESS_PREMIUM_END = _fee.percentEnd;
        SELL_FEE_END = _fee.percentEnd;
        MAX_WALLET_DURATION = _wallet.duration;
        MAX_WALLET_PERCENT_START = _wallet.percentStart;
        MAX_WALLET_PERCENT_END = _wallet.percentEnd;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Computes current tokenomics values
    /// @return DynamicTokenomics struct with current values
    /// @notice Values will change dynamically based on configured durations and percentages
    function _getTokenomics(
        uint256 _totalSupply
    ) internal view returns (DynamicTokenomicsStruct memory) {
        uint256 _elapsed = block.timestamp - launchStart;
        uint16 _maxWalletPercentage = _currentMaxWalletPercentage(_elapsed);
        return
            DynamicTokenomicsStruct({
                earlyAccessPremium: _currentBuyFeePercent(_elapsed),
                sellFee: SELL_FEE_END,
                maxWalletPercentage: _maxWalletPercentage,
                maxTokensPerWallet: _calculateMaxTokensPerWalletPrecisely(
                    _totalSupply,
                    _maxWalletPercentage
                )
            });
    }

    /// @dev Calculates max tokens per wallet more precisely than standard calculation
    /// @param _totalSupply Current total token supply
    /// @param _maxWalletPercentage Max wallet percentage in basis points (out of 10k)
    /// @return maxTokensPerWallet Precisely calculated max tokens per wallet
    /// @custom:optimizations Uses unchecked math for better gas efficiency
    function _calculateMaxTokensPerWalletPrecisely(
        uint256 _totalSupply,
        uint256 _maxWalletPercentage
    ) private pure returns (uint256) {
        unchecked {
            // Convert the percentage to a fraction and perform the multiplication last to maintain precision
            return (_totalSupply * _maxWalletPercentage + 9999) / 10000;
        }
    }

    /// @dev Gets current buy fee percentage based on elapsed time
    /// @return Current buy fee percentage
    function _currentBuyFeePercent(
        uint256 elapsed
    ) internal view returns (uint16) {
        return
            computeFeePercentage(
                elapsed,
                EARLY_ACCESS_PREMIUM_DURATION,
                EARLY_ACCESS_PREMIUM_START,
                EARLY_ACCESS_PREMIUM_END
            );
    }

    /// @dev Gets current max wallet percentage based on elapsed time
    /// @return Current max wallet percentage
    function _currentMaxWalletPercentage(
        uint256 elapsed
    ) internal view returns (uint16) {
        return
            computeMaxWalletPercentage(
                elapsed,
                MAX_WALLET_DURATION,
                MAX_WALLET_PERCENT_START,
                MAX_WALLET_PERCENT_END
            );
    }

    /// Computes fee percentage based on elapsed time, using an inverted quadratic curve.
    /// The fee percentage starts from a high value and decreases to a low value as time progresses.
    /// This creates a curve that starts fast and then slows down as the elapsed time approaches the total duration.
    ///
    /// @param elapsed The number of seconds that have passed since the launch.
    /// @param duration The total duration in seconds for the decrease.
    /// @param startPercent The starting fee percentage at the launch. Expressed in basis points where 1000 means 10%.
    /// @param endPercent The target fee percentage at the end of the duration. Expressed in basis points where 1000 means 10%.
    /// @return The current fee percentage, expressed in basis points where 1000 means 10%.
    function computeFeePercentage(
        uint256 elapsed,
        uint256 duration,
        uint16 startPercent,
        uint16 endPercent
    ) private pure returns (uint16) {
        if (elapsed >= duration) {
            return endPercent;
        }

        uint16 feePercent;
        /// @solidity memory-safe-assembly
        assembly {
            let scale := 0x0de0b6b3a7640000 // 10^18 in hexadecimal
            // Calculate the position on the curve, x, as a ratio of elapsed time to total duration
            let x := div(mul(elapsed, scale), duration)
            // Subtract squared x from scale to get the inverted position on the curve
            let xx := sub(scale, div(mul(x, x), scale))
            // Calculate delta as a proportion of startPercent scaled by the position on the curve
            let delta := div(mul(startPercent, xx), scale)
            // Ensure feePercent doesn't fall below endPercent
            feePercent := endPercent
            if gt(delta, endPercent) {
                feePercent := delta
            }
        }
        return feePercent;
    }

    /// Computes the maximum wallet percentage based on the elapsed time using a quadratic function.
    /// This function uses the progression of time to determine the maximum wallet percentage allowed,
    /// starting from the `startPercent` and progressively moving towards the `endPercent` in a quadratic manner.
    /// This creates a curve that starts slow and then accelerates as the elapsed time approaches the total duration.
    ///
    /// @param elapsed The number of seconds that have passed since the launch.
    /// @param duration The total duration in seconds for the quadratic progression.
    /// @param startPercent The starting wallet percentage at the launch. Expressed in basis points where 1000 means 10%.
    /// @param endPercent The target wallet percentage at the end of the duration. Expressed in basis points where 1000 means 10%.
    /// @return The current maximum wallet percentage, expressed in basis points where 1000 means 10%.
    function computeMaxWalletPercentage(
        uint256 elapsed,
        uint256 duration,
        uint16 startPercent,
        uint16 endPercent
    ) private pure returns (uint16) {
        // If elapsed time is greater than duration, return endPercent directly
        if (elapsed >= duration) {
            return endPercent;
        }

        uint16 walletPercent;
        /// @solidity memory-safe-assembly
        assembly {
            // Scale factor equivalent to 1 ether in Solidity to handle the fractional values
            let scale := 0x0de0b6b3a7640000 // 10^18 in hexadecimal
            // Calculate the position on the curve, x, as a ratio of elapsed time to total duration
            let x := div(mul(elapsed, scale), duration)
            // Square x to get the position on the curve
            let xx := div(mul(x, x), scale)
            // Calculate the range of percentages and scale by the position on the curve
            let range := sub(endPercent, startPercent)
            let delta := div(mul(range, xx), scale)
            // Add the starting percentage to get the final percentage
            walletPercent := add(startPercent, delta)
        }
        return walletPercent;
    }
}

// SPDX-License-Identifier: MIT
//
//           ████████████████████
//         ██                    ██
//       ██    ██          ██      ██
//     ██      ████        ████      ██
//     ██            ████            ██
//     ██                            ██
//   ████████████████████████████████████
//   ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
//     ████████████████████████████████
//   ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
//     ██░░██░░░░██████░░░░░░██░░░░████
//     ████  ████      ██████  ████  ██
//     ██                            ██
//       ████████████████████████████
//
// The Cheezburger Factory are a set of immutable and non-upgradeable smart contracts that enables
// easy deployment of new tokens with automated liquidity provisioning against either native ETH
// or ERC20 token specified with any Uniswap V2 compatible routers.
//
// By supporting both ETH and ERC20 tokens as liquidity, the Factory provides flexibility for
// projects to launch with the assets they have available. Automating the entire process
// dramatically lowers the barrier to creating a new token with smart tokenomics, built-in
// liquidity management and DEX listing in a completely trustless and decentralized way.
//
// Read more on Cheezburger: https://cheezburger.lol
//
pragma solidity ^0.8.22;

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";
import {CheezburgerBun} from "./CheezburgerBun.sol";
import {CheezburgerSanitizer} from "./CheezburgerSanitizer.sol";

contract CheezburgerFactory is ReentrancyGuard, CheezburgerSanitizer {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error InsufficientLiquidityWei(uint256 amount);
    error ExistingTokenAsRightSide(address token);
    error InvalidRouter(address router);
    error CannotReceiveEtherDirectly();
    error PairNotEmpty();
    error FactoryNotOpened();
    error CannotSetZeroAsRightSide();
    error InvalidPair(
        address tokenA,
        address tokenB,
        address leftSide,
        address rightSide
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCT                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Settings and contracts for a token pair and its liquidity pool.
    struct Token {
        /// @dev The Uniswap factory contract
        IUniswapV2Factory factory;
        /// @dev The Uniswap router contract
        IUniswapV2Router02 router;
        /// @dev The Uniswap pair contract
        IUniswapV2Pair pair;
        /// @dev The token creator
        address creator;
        /// @dev The left side of the pair
        CheezburgerBun leftSide;
        /// @dev The right side ERC20 token of the pair
        ERC20 rightSide;
        /// @dev Liquidity settings
        LiquiditySettings liquidity;
        /// @dev Dynamic fee settings
        DynamicSettings fee;
        /// @dev Dynamic wallet settings
        DynamicSettings wallet;
        /// @dev Referral settings
        ReferralSettings referral;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event TokenDeployed(Token token);
    event CommissionsTaken(uint256 referralFee);
    event SwapAndLiquify(
        address tokenLeft,
        address tokenRight,
        uint256 half,
        uint256 initialBalance,
        uint256 newRightBalance
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    string public FACTORY_VERSION = "Cheddar (1.1)";
    uint256 public totalTokens = 0;
    mapping(address => Token) public burgerRegistry;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a new token and adds liquidity with native coin
    /// @param _customization Token details (TokenCustomization)
    /// @param _router Uniswap router address
    /// @param _rightSide Address of token to provide liquidity with
    /// @param _liquidity Liquidity provision settings
    /// @param _fee Early Access Premium / Sell rate settings
    /// @param _wallet Max wallet holding settings
    /// @param _referral Referral settings
    /// @return The address of the deployed token contract
    function deployWithNative(
        TokenCustomization memory _customization,
        address _router,
        // If someone wants to specify a custom WETH() that is not returned by the router
        address _rightSide,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral
    ) external payable nonReentrant returns (address) {
        Token memory token = deploy(
            _customization,
            _router,
            _liquidity,
            _fee,
            _wallet,
            _referral,
            _rightSide
        );

        // Check at least 10,000 wei are provided for liquidity
        if (msg.value <= 10000 wei) {
            revert InsufficientLiquidityWei(msg.value);
        }

        // Add liquidity
        addLiquidityETH(
            token,
            SafeTransferLib.balanceOf(address(token.leftSide), address(this)),
            msg.value,
            token.creator
        );

        return address(token.leftSide);
    }

    /// @dev Deploys a new token and adds liquidity using a token as right side
    /// @param _customization Token details (TokenCustomization)
    /// @param _router Uniswap router address
    /// @param _rightSide Address of token to provide liquidity with
    /// @param _rightSideAmount Amount of that token for liquidity
    /// @param _liquidity Liquidity provision settings
    /// @param _fee Early Access Premium / Sell fee rate settings
    /// @param _wallet Max wallet holding settings
    /// @param _referral Referral settings
    /// @return The address of the deployed token contract
    function deployWithToken(
        TokenCustomization memory _customization,
        address _router,
        address _rightSide,
        uint256 _rightSideAmount,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral
    ) external nonReentrant returns (address) {
        Token memory token = deploy(
            _customization,
            _router,
            _liquidity,
            _fee,
            _wallet,
            _referral,
            _rightSide
        );

        // Transfer tokens for liquidity add
        SafeTransferLib.safeTransferFrom(
            address(token.rightSide),
            token.creator,
            address(this),
            _rightSideAmount
        );

        // Add liquidity
        addLiquidityToken(
            token,
            SafeTransferLib.balanceOf(address(token.leftSide), address(this)),
            _rightSideAmount,
            token.creator
        );

        return address(token.leftSide);
    }

    /// Checks for & executes automated liquidity swap if threshold met.
    ///
    /// @return True if swap succeed
    ///
    /// Gets threshold and checks if left token balance exceeds it.
    /// If so, swaps tokens/adds liquidity, then distributes LP tokens
    /// to fee addresses as percentages configured in token settings.
    ///
    /// This dynamic threshold approach aims to reduce swap size and price
    /// impact as the pool and price grow over time. Automates ongoing
    /// liquidity additions from transaction volume.
    function beforeTokenTransfer(
        uint256 _leftSideBalance
    ) external returns (bool) {
        Token memory token = burgerRegistry[msg.sender];
        ensurePairValid(token);
        uint256 threshold = _getLiquidityThreshold(token);

        if (_leftSideBalance >= threshold) {
            (uint256 addedLP, uint256 referralFeeLP) = swapAndLiquify(
                token,
                threshold
            );
            uint256 feeAddressesLength = token.liquidity.feeAddresses.length;

            if (referralFeeLP > 0) {
                SafeTransferLib.safeTransfer(
                    address(token.pair),
                    token.referral.feeReceiver,
                    referralFeeLP
                );
            }

            // Send LP to designated LP wallets
            unchecked {
                uint8 i;
                while (i < feeAddressesLength) {
                    if (i == feeAddressesLength - 1) {
                        SafeTransferLib.safeTransferAll(
                            address(token.pair),
                            token.liquidity.feeAddresses[i]
                        );
                    } else {
                        uint256 feeAmount = (addedLP *
                            token.liquidity.feePercentages[i]) / 100;
                        SafeTransferLib.safeTransfer(
                            address(token.pair),
                            token.liquidity.feeAddresses[i],
                            feeAmount
                        );
                    }
                    ++i;
                }
            }

            // Send any rightSide dust to the last address
            uint256 rightSideBalance = SafeTransferLib.balanceOf(
                address(token.rightSide),
                address(this)
            );
            if (rightSideBalance > 0) {
                SafeTransferLib.safeTransfer(
                    address(token.rightSide),
                    token.liquidity.feeAddresses[feeAddressesLength - 1],
                    rightSideBalance
                );
            }
        }

        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows a token to get his own pair and router addresses
    /// @return Pair and router address
    function burgerRegistryRouterOnly(
        address _token
    ) external view returns (IUniswapV2Router02, IUniswapV2Pair) {
        Token memory token = burgerRegistry[_token];
        return (token.router, token.pair);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// Limitations:
    ///
    /// EAP duration: 1 to 24 hours
    /// EAP start: 1% to 40%
    /// EAP end: 0% to 5%
    ///
    /// Wallet duration: 1 day to 4 weeks
    /// Wallet start: >= 1%
    /// Wallet end: 2% to 49%
    ///
    /// @param _customization Token details (TokenCustomization)
    /// @param _router Uniswap router address
    /// @param _liquidity Liquidity settings
    /// @param _fee Fees (Early Access Premium / Sell) settings
    /// @param _wallet Max wallet settings
    /// @param _referral Referral settings
    /// @param _rightSide Address of token to provide liquidity with
    /// @return Token instance
    function deploy(
        TokenCustomization memory _customization,
        address _router,
        LiquiditySettings memory _liquidity,
        DynamicSettings memory _fee,
        DynamicSettings memory _wallet,
        ReferralSettings memory _referral,
        address _rightSide
    ) private returns (Token memory) {
        validateTokenSettings(_router, _customization);
        validateWalletSettings(_wallet);
        validateFeeSettings(_fee);
        validateLiquiditySettings(_liquidity, address(this));
        validateReferralSettings(_referral, address(this));

        Token memory token;
        token.creator = msg.sender;

        // Setup router and factory
        (IUniswapV2Router02 router, IUniswapV2Factory factory) = getRouter(
            _router
        );
        if (address(factory) == address(0) || address(router) == address(0)) {
            revert InvalidRouter(_router);
        }
        token.factory = factory;
        token.router = router;

        // Right side token (WETH, USDC...)
        token.rightSide = ERC20(_rightSide);
        if (address(token.rightSide) == address(0)) {
            token.rightSide = ERC20(token.router.WETH());
            if (address(token.rightSide) == address(0)) {
                revert CannotSetZeroAsRightSide();
            }
        }
        if (burgerRegistry[address(token.rightSide)].creator != address(0)) {
            revert ExistingTokenAsRightSide(address(token.rightSide));
        }

        // Create token
        token.leftSide = new CheezburgerBun{
            salt: _getSalt(_router, _rightSide)
        }(_customization, _fee, _wallet);

        // Create pair
        token.pair = IUniswapV2Pair(
            token.factory.createPair(
                address(token.leftSide),
                address(token.rightSide)
            )
        );
        ensurePairValid(token);
        if (token.pair.totalSupply() > 0) {
            revert PairNotEmpty();
        }

        // Save settings
        token.liquidity = _liquidity;
        token.fee = _fee;
        token.wallet = _wallet;
        token.referral = _referral;

        // Add token to registry
        ++totalTokens;
        burgerRegistry[address(token.leftSide)] = token;

        emit TokenDeployed(token);
        return token;
    }

    /// Generates a salt value for deploying clones.
    ///
    /// The salt is derived from:
    /// - Total number of tokens deployed
    /// - Provided router address
    /// - Provided right token address
    /// - Previous block random number
    /// - Current block number
    /// - Current block timestamp
    ///
    /// @param _router The Uniswap router address
    /// @param _rightSide The address of the right side token
    /// @return The generated salt value
    function _getSalt(
        address _router,
        address _rightSide
    ) private view returns (bytes32) {
        bytes memory data = abi.encodePacked(
            bytes32(uint256(totalTokens)),
            bytes32(abi.encodePacked(_router)),
            bytes32(abi.encodePacked(_rightSide)),
            bytes32(block.prevrandao),
            bytes32(block.number),
            bytes32(block.timestamp)
        );
        return keccak256(data);
    }

    /// Fetches the router and factory contracts for a router address.
    ///
    /// @param _router The address of the router contract
    ///
    /// @return router The router contract
    /// @return factory The factory contract
    ///
    /// This first checks if the provided router address is a valid contract.
    /// If so, it will attempt to call the `factory()` method on the router
    /// to retrieve the factory address.
    ///
    /// If the router address is invalid or the factory() call fails,
    /// zero addresses will be returned for both the router and factory.
    ///
    /// This provides a safe way to fetch the expected router and factory
    /// instances for a given address with proper validation.
    function getRouter(
        address _router
    ) private view returns (IUniswapV2Router02, IUniswapV2Factory) {
        if (_router.code.length > 0) {
            IUniswapV2Router02 router = IUniswapV2Router02(_router);
            try router.factory() returns (address factory) {
                if (factory != address(0)) {
                    return (router, IUniswapV2Factory(factory));
                }
            } catch {}
        }
        return (IUniswapV2Router02(address(0)), IUniswapV2Factory(address(0)));
    }

    /// Calculates the target threshold for dynamic liquidity fees.
    ///
    /// @param token The token settings struct
    ///
    /// @return The calculated fee threshold amount
    ///
    /// Checks the total tokens currently in the liquidity pool pair.
    /// It then calculates a threshold amount as a percentage (set
    /// by `feeThresholdPercent`) of those tokens.
    ///
    /// This dynamic threshold is used to determine if sell
    /// transactions must pay liquidity provider fees. By tying it
    /// to total pool size, the threshold scales automatically to
    /// always be a set % as more liquidity is provided over time.
    ///
    /// This approach aims to smoothly collect trading fees for LP's
    /// in a way that adjusts to pool size, reducing pricing impact.
    function _getLiquidityThreshold(
        Token memory token
    ) private view returns (uint256) {
        uint256 tokensInLiquidity = SafeTransferLib.balanceOf(
            address(token.leftSide),
            address(token.pair)
        );
        unchecked {
            return
                (tokensInLiquidity * token.liquidity.feeThresholdPercent) / 100;
        }
    }

    /// Adds liquidity to the Uniswap ETH pool for a token.
    ///
    /// @param token The token settings struct
    /// @param _leftAmount The amount of left token to add
    /// @param _etherAmount The amount of ETH to deposit
    ///
    /// Approves the token spending and adds liquidity
    /// to Uniswap, calling `addLiquidityETH()` on the router.
    ///
    /// This abstracts away adding liquidity with ETH to simplify
    /// integrating token deployments on Uniswap.
    function addLiquidityETH(
        Token memory token,
        uint256 _leftAmount,
        uint256 _etherAmount,
        address _receiver
    ) private {
        SafeTransferLib.safeApprove(
            address(token.leftSide),
            address(token.router),
            _leftAmount
        );
        token.router.addLiquidityETH{value: _etherAmount}(
            address(token.leftSide),
            _leftAmount,
            0,
            0,
            _receiver,
            block.timestamp
        );
    }

    /// Adds liquidity for a token pair on Uniswap.
    ///
    /// @param token The token settings struct
    /// @param _leftAmount The amount of left token to add
    /// @param _rightAmount The amount of right token to add
    ///
    /// Adds liquidity to the Uniswap pool for the token pair
    /// defined in the `token` struct. The function adds
    /// `_leftAmount` of the left token and `_rightAmount`
    /// of the right token to the pool, creating a liquidity
    /// position for this token pair on Uniswap.
    function addLiquidityToken(
        Token memory token,
        uint256 _leftAmount,
        uint256 _rightAmount,
        address _receiver
    ) private {
        SafeTransferLib.safeApprove(
            address(token.leftSide),
            address(token.router),
            _leftAmount
        );
        SafeTransferLib.safeApproveWithRetry(
            address(token.rightSide),
            address(token.router),
            _rightAmount
        );
        token.router.addLiquidity(
            address(token.leftSide),
            address(token.rightSide),
            _leftAmount,
            _rightAmount,
            0,
            0,
            _receiver,
            block.timestamp
        );
    }

    /// Swaps tokens and adds liquidity to Uniswap in one transaction.
    ///
    /// @param token The token settings struct
    /// @param _amounts The amounts of tokens to swap
    ///
    /// @return The balance of the new LP tokens received
    ///
    /// Swaps the specified token amounts according to the pair
    /// defined in the `token` struct. It then takes the output
    /// of the swap and adds it as liquidity to the Uniswap pool,
    /// returning the amount of LP tokens received for the newly
    /// provided liquidity. This allows swapping and adding
    /// liquidity to be done atomically in a single transaction.
    function swapAndLiquify(
        Token memory token,
        uint256 _amounts
    ) private returns (uint256, uint256) {
        unchecked {
            uint256 half = _amounts / 2;
            uint256 initialRightBalance = SafeTransferLib.balanceOf(
                address(token.rightSide),
                address(this)
            );
            swapLeftForRightSide(token, half);
            uint256 newRightBalance = SafeTransferLib.balanceOf(
                address(token.rightSide),
                address(this)
            ) - initialRightBalance;
            addLiquidityToken(token, half, newRightBalance, address(this));

            uint256 addedLP = SafeTransferLib.balanceOf(
                address(token.pair),
                address(this)
            );

            uint256 referralFeeLP = 0;
            if (
                token.referral.feeReceiver != address(0) &&
                token.referral.feePercentage > 0
            ) {
                referralFeeLP = (addedLP * token.referral.feePercentage) / 100;
            }

            emit SwapAndLiquify(
                address(token.leftSide),
                address(token.rightSide),
                half,
                initialRightBalance,
                newRightBalance
            );

            if (referralFeeLP > 0) {
                emit CommissionsTaken(referralFeeLP);
            }

            return (addedLP - referralFeeLP, referralFeeLP);
        }
    }

    /// Swaps left token for right token.
    ///
    /// @param token The token settings struct
    /// @param _amount The amount of left token to swap
    ///
    /// Swaps the specified amount of the left token for the
    /// right token according to the settings in the token struct.
    function swapLeftForRightSide(Token memory token, uint256 _amount) private {
        SafeTransferLib.safeApprove(
            address(token.leftSide),
            address(token.router),
            _amount
        );
        address[] memory path = new address[](2);
        path[0] = address(token.leftSide);
        path[1] = address(token.rightSide);
        token.router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// Validates that the Uniswap pair is properly set up.
    ///
    /// @param token The token settings struct
    ///
    /// Checks that:
    /// - The pair token0 != token1 (no same tokens)
    /// - One of the pair tokens matches the left token
    /// - One of the pair tokens matches the right token
    ///
    /// If any validation fails, reverts with an error.
    ///
    /// This ensures the Uniswap pair is properly set up according
    /// to the provided token contract settings.
    function ensurePairValid(Token memory token) internal view {
        address tokenA = token.pair.token0();
        address tokenB = token.pair.token1();
        address leftSide = address(token.leftSide);
        address rightSide = address(token.rightSide);

        if (tokenA == tokenB || leftSide == rightSide) {
            revert InvalidPair(tokenA, tokenB, leftSide, rightSide);
        }

        if (
            (tokenA != leftSide && tokenA != rightSide) ||
            (tokenB != leftSide && tokenB != rightSide)
        ) {
            revert InvalidPair(tokenA, tokenB, leftSide, rightSide);
        }
    }

    /// @dev Prevents direct Ether transfers to contract
    receive() external payable {
        revert CannotReceiveEtherDirectly();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {CheezburgerStructs} from "./CheezburgerStructs.sol";
import {CheezburgerConstants} from "./CheezburgerConstants.sol";

abstract contract CheezburgerSanitizer is CheezburgerStructs {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error RouterUndefined();
    error NameTooShort(uint256 length, uint256 minLength);
    error NameTooLong(uint256 length, uint256 maxLength);
    error SymbolTooShort(uint256 length, uint256 minLength);
    error SymbolTooLong(uint256 length, uint256 maxLength);
    error WebsiteUrlTooLong(uint256 length, uint256 maxLength);
    error SocialUrlTooLong(uint256 length, uint256 maxLength);
    error SupplyTooLow(uint256 supply);
    error SupplyTooLarge(uint256 supply);
    error InvalidThreshold(uint256 threshold);
    error FeeDurationTooShort(uint256 duration);
    error FeeDurationTooLong(uint256 duration);
    error FeeStartTooLow(uint256 start);
    error FeeStartTooHigh(uint256 start, uint256 max);
    error FeeEndTooHigh(uint256 end, uint256 max);
    error FeeEndExceedsStart(uint256 end, uint256 start);
    error MaxWalletStartTooLow(uint256 start);
    error MaxWalletEndTooLow(uint256 end, uint256 min);
    error MaxWalletEndTooHigh(uint256 end, uint256 max);
    error MaxWalletDurationTooShort(uint256 duration);
    error MaxWalletDurationTooLong(uint256 duration, uint256 maxDuration);
    error MaxWalletStartExceedsEnd(uint256 start, uint256 end);
    error TooManyFeeAddresses(uint256 numAddresses);
    error TooFewFeeAddresses(uint256 numAddresses);
    error OverflowFeePercentages(uint8 totalFeePercent);
    error InvalidFeePercentagesLength(
        uint256 percentagesLength,
        uint256 addressesLength
    );
    error FactoryCannotReceiveFees();
    error ReferralCannotBeFactory();
    error ReferralFeeExceeded();
    error ReferralFeeCannotBeZero();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function validateTokenSettings(
        address _router,
        TokenCustomization memory _customization
    ) internal pure {
        if (_router == address(0)) {
            revert RouterUndefined();
        }

        if (
            bytes(_customization.name).length <
            CheezburgerConstants.MIN_NAME_LENGTH
        ) {
            revert NameTooShort(
                bytes(_customization.name).length,
                CheezburgerConstants.MIN_NAME_LENGTH
            );
        }

        if (
            bytes(_customization.name).length >
            CheezburgerConstants.MAX_NAME_LENGTH
        ) {
            revert NameTooLong(
                bytes(_customization.name).length,
                CheezburgerConstants.MAX_NAME_LENGTH
            );
        }

        if (
            bytes(_customization.symbol).length <
            CheezburgerConstants.MIN_SYMBOL_LENGTH
        ) {
            revert SymbolTooShort(
                bytes(_customization.symbol).length,
                CheezburgerConstants.MIN_SYMBOL_LENGTH
            );
        }

        if (
            bytes(_customization.symbol).length >
            CheezburgerConstants.MAX_SYMBOL_LENGTH
        ) {
            revert SymbolTooLong(
                bytes(_customization.symbol).length,
                CheezburgerConstants.MAX_SYMBOL_LENGTH
            );
        }

        if (
            bytes(_customization.website).length >
            CheezburgerConstants.MAX_URL_LENGTH
        ) {
            revert WebsiteUrlTooLong(
                bytes(_customization.website).length,
                CheezburgerConstants.MAX_URL_LENGTH
            );
        }

        if (
            bytes(_customization.social).length >
            CheezburgerConstants.MAX_URL_LENGTH
        ) {
            revert SocialUrlTooLong(
                bytes(_customization.social).length,
                CheezburgerConstants.MAX_URL_LENGTH
            );
        }

        if (_customization.supply < 1) {
            revert SupplyTooLow(_customization.supply);
        }

        if (_customization.supply > CheezburgerConstants.SAFE_TOKEN_SUPPLY) {
            revert SupplyTooLarge(_customization.supply);
        }
    }

    function validateWalletSettings(
        DynamicSettings memory _wallet
    ) internal pure {
        if (_wallet.percentStart < 100) {
            revert MaxWalletStartTooLow(_wallet.percentStart);
        }

        if (_wallet.percentEnd < CheezburgerConstants.WALLET_MIN_PERCENT_END) {
            revert MaxWalletEndTooLow(
                _wallet.percentEnd,
                CheezburgerConstants.WALLET_MIN_PERCENT_END
            );
        }

        if (_wallet.percentEnd > CheezburgerConstants.WALLET_MAX_PERCENT_END) {
            revert MaxWalletEndTooHigh(
                _wallet.percentEnd,
                CheezburgerConstants.WALLET_MAX_PERCENT_END
            );
        }

        if (_wallet.duration < CheezburgerConstants.WALLET_DURATION_MIN) {
            revert MaxWalletDurationTooShort(_wallet.duration);
        }

        if (_wallet.duration > CheezburgerConstants.WALLET_DURATION_CAP) {
            revert MaxWalletDurationTooLong(
                _wallet.duration,
                CheezburgerConstants.WALLET_DURATION_CAP
            );
        }

        if (_wallet.percentStart > _wallet.percentEnd) {
            revert MaxWalletStartExceedsEnd(
                _wallet.percentStart,
                _wallet.percentEnd
            );
        }
    }

    function validateReferralSettings(
        ReferralSettings memory _referral,
        address _factory
    ) internal pure {
        if (_referral.feeReceiver != address(0)) {
            if (_referral.feeReceiver == _factory) {
                revert ReferralCannotBeFactory();
            }
            if (_referral.feePercentage <= 0) {
                revert ReferralFeeCannotBeZero();
            }
            if (_referral.feePercentage > CheezburgerConstants.MAX_LP_FEE) {
                revert ReferralFeeExceeded();
            }
        }
    }

    function validateFeeSettings(DynamicSettings memory _fee) internal pure {
        if (_fee.duration < CheezburgerConstants.FEE_DURATION_MIN) {
            revert FeeDurationTooShort(_fee.duration);
        }

        if (_fee.duration > CheezburgerConstants.FEE_DURATION_CAP) {
            revert FeeDurationTooLong(_fee.duration);
        }

        if (_fee.percentStart < CheezburgerConstants.FEE_START_MIN) {
            revert FeeStartTooLow(_fee.percentStart);
        }

        if (_fee.percentStart > CheezburgerConstants.FEE_START_MAX) {
            revert FeeStartTooHigh(
                _fee.percentStart,
                CheezburgerConstants.FEE_START_MAX
            );
        }

        if (_fee.percentEnd > CheezburgerConstants.FEE_END_MAX) {
            revert FeeEndTooHigh(
                _fee.percentEnd,
                CheezburgerConstants.FEE_END_MAX
            );
        }

        if (_fee.percentEnd > _fee.percentStart) {
            revert FeeEndExceedsStart(_fee.percentEnd, _fee.percentStart);
        }
    }

    function validateLiquiditySettings(
        LiquiditySettings memory _fees,
        address _factory
    ) internal pure {
        if (
            _fees.feeThresholdPercent < CheezburgerConstants.THRESHOLD_MIN ||
            _fees.feeThresholdPercent > CheezburgerConstants.THRESHOLD_MAX
        ) {
            revert InvalidThreshold(_fees.feeThresholdPercent);
        }

        if (
            _fees.feeAddresses.length > CheezburgerConstants.FEE_ADDRESSES_MAX
        ) {
            revert TooManyFeeAddresses(_fees.feeAddresses.length);
        }

        if (
            _fees.feeAddresses.length < CheezburgerConstants.FEE_ADDRESSES_MIN
        ) {
            revert TooFewFeeAddresses(_fees.feeAddresses.length);
        }

        // Prevent any of the feeAddresses to be the factory
        for (uint i = 0; i < _fees.feeAddresses.length; i++) {
            if (_fees.feeAddresses[i] == _factory) {
                revert FactoryCannotReceiveFees();
            }
        }

        if (_fees.feePercentages.length != _fees.feeAddresses.length - 1) {
            // If we only have 1 address then we accept [] as feePercentages since 100% goes there
            revert InvalidFeePercentagesLength(
                _fees.feePercentages.length,
                _fees.feeAddresses.length
            );
        }

        if (_fees.feePercentages.length > 1) {
            uint8 totalFeePercent;
            for (uint8 i = 0; i < _fees.feePercentages.length; i++) {
                totalFeePercent += _fees.feePercentages[i];
            }
            if (totalFeePercent > 99) {
                revert OverflowFeePercentages(totalFeePercent);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface CheezburgerStructs {
    /// @dev Settings for customizing the token
    /// @param name The name of the token
    /// @param symbol The symbol for the token
    /// @param website The website associated with the token
    /// @param social A social media link associated with the token
    /// @param supply The max supply of the token
    struct TokenCustomization {
        string name;
        string symbol;
        string website;
        string social;
        uint256 supply;
    }

    /// @dev Settings for dynamic fees that change over time
    /// @param duration The duration over which the rate changes
    /// @param percentStart The starting percentage rate
    /// @param percentEnd The ending percentage rate
    struct DynamicSettings {
        uint256 duration;
        uint16 percentStart;
        uint16 percentEnd;
    }

    /// @dev Settings for liquidity pool fees distributed to addresses
    /// @param feeThresholdPercent The percentage threshold that triggers liquidity swaps
    /// @param feeAddresses The addresses receiving distributed fee amounts
    /// @param feePercentages The percentage fee amounts for each address
    struct LiquiditySettings {
        uint8 feeThresholdPercent;
        address[] feeAddresses;
        uint8[] feePercentages;
    }

    /// @dev Settings for referrals. Referrals get commissions from fees whenever people uses the factory to deploy their token.
    /// @param feeReceiver The addresses receiving commissions
    /// @param feePercentage The percentage fee
    struct ReferralSettings {
        address feeReceiver;
        uint8 feePercentage;
    }
}

// SPDX-License-Identifier: MITz
pragma solidity ^0.8.22;

import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {CheezburgerStructs} from "../CheezburgerStructs.sol";

interface ICheezburgerFactory is CheezburgerStructs {
    function beforeTokenTransfer(
        uint256 _leftSideBalance
    ) external returns (bool);

    function burgerRegistryRouterOnly(
        address token
    ) external view returns (IUniswapV2Router02, IUniswapV2Pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Cheezburger (https://cheezburger.lol)
abstract contract ReentrancyGuard {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error ReentrancyDetected();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint8 private locked = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    modifier nonReentrant() virtual {
        if (locked == 2) {
            revert ReentrancyDetected();
        }
        locked = 2;
        _;
        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
///
/// @dev Note:
/// - The ERC20 standard allows minting and transferring to and from the zero address,
///   minting and transferring zero tokens, as well as self-approvals.
///   For performance, this implementation WILL NOT revert for such actions.
///   Please add any checks with overrides if desired.
/// - The `permit` function uses the ecrecover precompile (0x1).
///
/// If you are overriding:
/// - NEVER violate the ERC20 invariant:
///   the total sum of all balances must be equal to `totalSupply()`.
/// - Check that the overridden function is actually used in the function you want to
///   change the behavior of. Much of the code has been manually inlined for performance.
abstract contract ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total supply.
    uint256 private constant _TOTAL_SUPPLY_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `(_NONCES_SLOT_SEED << 16) | 0x1901`.
    uint256 private constant _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX = 0x383775081901;

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 private constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev `keccak256("1")`.
    bytes32 private constant _VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
    bytes32 private constant _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_SUPPLY_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if add(allowance_, 1) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For more performance, override to return the constant value
    /// of `keccak256(bytes(name()))` if `name()` will never change.
    function _constantNameHash() internal view virtual returns (bytes32 result) {}

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            // Revert if the block timestamp is greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40) // Grab the free memory pointer.
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0e, _NONCES_SLOT_SEED_WITH_SIGNATURE_PREFIX)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Prepare the domain separator.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), _VERSION_HASH)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            mstore(0x2e, keccak256(m, 0xa0))
            // Prepare the struct hash.
            mstore(m, _PERMIT_TYPEHASH)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            mstore(0x4e, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0x00, keccak256(0x2c, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            let t := staticcall(gas(), 1, 0, 0x80, 0x20, 0x20)
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, t)) // `t` is 1 if ecrecover succeeds.
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-712 domain separator for the EIP-2612 permit.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Grab the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), _VERSION_HASH)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalSupplyBefore := sload(_TOTAL_SUPPLY_SLOT)
            let totalSupplyAfter := add(totalSupplyBefore, amount)
            // Revert if the total supply overflows.
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, totalSupplyAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Subtract and store the updated total supply.
            sstore(_TOTAL_SUPPLY_SLOT, sub(sload(_TOTAL_SUPPLY_SLOT), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if add(allowance_, 1) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

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

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
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
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}
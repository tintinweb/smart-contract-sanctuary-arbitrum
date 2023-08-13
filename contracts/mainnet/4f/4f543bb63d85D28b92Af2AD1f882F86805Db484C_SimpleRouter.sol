// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../interfaces/ISimpleRouter.sol";
import "./interfaces/IYakRouter.sol";
import "./interfaces/IAdapter.sol";
import "./../interfaces/IERC20.sol";
import "./../lib/Ownable.sol";

contract SimpleRouter is ISimpleRouter, Ownable {
    bool public yakSwapFallback;
    uint256 public maxStepsFallback;
    IYakRouter public yakRouter;

    mapping(address => mapping(address => SwapConfig)) public swapConfigurations;

    constructor(bool _yakSwapFallback, uint256 _maxStepsFallback, address _yakRouter) {
        configureYakSwapDefaults(_yakSwapFallback, _maxStepsFallback, _yakRouter);
    }

    function updateSwapConfiguration(SwapConfig memory _swapConfig) external onlyOwner {
        swapConfigurations[_swapConfig.path.tokens[0]][_swapConfig.path.tokens[_swapConfig.path.tokens.length - 1]] =
            _swapConfig;
    }

    function updateYakSwapDefaults(bool _yakSwapFallback, uint256 _maxStepsFallback, address _yakRouter)
        external
        onlyOwner
    {
        configureYakSwapDefaults(_yakSwapFallback, _maxStepsFallback, _yakRouter);
    }

    function configureYakSwapDefaults(bool _yakSwapFallback, uint256 _maxStepsFallback, address _yakRouter) internal {
        if (_yakRouter == address(0)) {
            revert InvalidConfiguration();
        }
        maxStepsFallback = _maxStepsFallback > 0 ? _maxStepsFallback : 1;
        yakSwapFallback = _yakSwapFallback;
        yakRouter = IYakRouter(_yakRouter);
    }

    function query(uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        override
        returns (FormattedOffer memory offer)
    {
        SwapConfig storage swapConfig = swapConfigurations[_tokenIn][_tokenOut];
        bool routeConfigured = swapConfig.path.adapters.length > 0;

        if (!routeConfigured && !swapConfig.useYakSwapRouter && !yakSwapFallback) {
            return zeroOffer(_tokenIn, _tokenOut);
        }

        if (routeConfigured) {
            offer = queryPredefinedRoute(_amountIn, swapConfig.path.adapters, swapConfig.path.tokens);
        } else {
            offer = queryYakSwap(
                _amountIn,
                _tokenIn,
                _tokenOut,
                swapConfig.yakSwapMaxSteps > 0 ? swapConfig.yakSwapMaxSteps : maxStepsFallback
            );
        }
    }

    function queryPredefinedRoute(uint256 _amountIn, address[] memory _adapters, address[] memory _tokens)
        internal
        view
        returns (FormattedOffer memory offer)
    {
        uint256[] memory amounts = new uint[](_tokens.length);
        amounts[0] = _amountIn;
        for (uint256 i; i < _adapters.length; i++) {
            amounts[i + 1] = IAdapter(_adapters[i]).query(amounts[i], _tokens[i], _tokens[i + 1]);
        }

        offer = FormattedOffer({amounts: amounts, path: _tokens, adapters: _adapters, gasEstimate: 0});
    }

    function queryYakSwap(uint256 _amountIn, address _tokenIn, address _tokenOut, uint256 _maxSteps)
        internal
        view
        returns (FormattedOffer memory offer)
    {
        offer = yakRouter.findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps);
        if (offer.amounts.length == 0) {
            return zeroOffer(_tokenIn, _tokenOut);
        }
    }

    function zeroOffer(address _tokenIn, address _tokenOut) internal pure returns (FormattedOffer memory offer) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return FormattedOffer({amounts: new uint256[](0), path: path, adapters: new address[](0), gasEstimate: 0});
    }

    function swap(FormattedOffer memory _offer) external override returns (uint256 amountOut) {
        address tokenIn = _offer.path[0];
        address tokenOut = _offer.path[_offer.path.length - 1];

        if (_offer.adapters.length == 0) {
            revert UnsupportedSwap(tokenIn, tokenOut);
        }

        IERC20(tokenIn).transferFrom(msg.sender, _offer.adapters[0], _offer.amounts[0]);

        for (uint256 i; i < _offer.adapters.length; i++) {
            address targetAddress = i < _offer.adapters.length - 1 ? _offer.adapters[i + 1] : msg.sender;
            IAdapter(_offer.adapters[i]).swap(
                _offer.amounts[i], _offer.amounts[i + 1], _offer.path[i], _offer.path[i + 1], targetAddress
            );
        }

        amountOut = _offer.amounts[_offer.amounts.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../router/interfaces/IYakRouter.sol";

interface ISimpleRouter {
    error UnsupportedSwap(address _tokenIn, address _tokenOut);
    error InvalidConfiguration();

    struct SwapConfig {
        bool useYakSwapRouter;
        uint8 yakSwapMaxSteps;
        Path path;
    }

    struct Path {
        address[] adapters;
        address[] tokens;
    }

    function query(uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (FormattedOffer memory trade);

    function swap(FormattedOffer memory _trade) external returns (uint256 amountOut);
}

//       ╟╗                                                                      ╔╬
//       ╞╬╬                                                                    ╬╠╬
//      ╔╣╬╬╬                                                                  ╠╠╠╠╦
//     ╬╬╬╬╬╩                                                                  ╘╠╠╠╠╬
//    ║╬╬╬╬╬                                                                    ╘╠╠╠╠╬
//    ╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬      ╒╬╬╬╬╬╬╬╜   ╠╠╬╬╬╬╬╬╬         ╠╬╬╬╬╬╬╬    ╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠
//    ╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╕    ╬╬╬╬╬╬╬╜   ╣╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬   ╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╩
//     ╙╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬  ╔╬╬╬╬╬╬╬    ╔╠╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╝╙
//               ╘╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬    ╒╠╠╠╬╠╬╩╬╬╬╬╬╬       ╠╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╙
//                 ╣╬╬╬╬╬╬╬╬╬╬╠╣     ╣╬╠╠╠╬╩ ╚╬╬╬╬╬╬      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                  ╣╬╬╬╬╬╬╬╬╬╣     ╣╬╠╠╠╬╬   ╣╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                   ╟╬╬╬╬╬╬╬╩      ╬╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╒╬╬╠╠╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬    ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╬╬╬╠╠╠╠╝╝╝╝╝╝╝╠╬╬╬╬╬╬   ╠╬╬╬╬╬╬╬  ╚╬╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬    ╣╬╬╬╬╠╠╩       ╘╬╬╬╬╬╬╬  ╠╬╬╬╬╬╬╬   ╙╬╬╬╬╬╬╬╬
//

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Query {
    address adapter;
    address tokenIn;
    address tokenOut;
    uint256 amountOut;
}

struct Offer {
    bytes amounts;
    bytes adapters;
    bytes path;
    uint256 gasEstimate;
}

struct FormattedOffer {
    uint256[] amounts;
    address[] adapters;
    address[] path;
    uint256 gasEstimate;
}

struct Trade {
    uint256 amountIn;
    uint256 amountOut;
    address[] path;
    address[] adapters;
}

interface IYakRouter {
    event UpdatedTrustedTokens(address[] _newTrustedTokens);
    event UpdatedAdapters(address[] _newAdapters);
    event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee);
    event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer);
    event YakSwap(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut);

    // admin
    function setTrustedTokens(address[] memory _trustedTokens) external;
    function setAdapters(address[] memory _adapters) external;
    function setFeeClaimer(address _claimer) external;
    function setMinFee(uint256 _fee) external;

    // misc
    function trustedTokensCount() external view returns (uint256);
    function adaptersCount() external view returns (uint256);

    // query

    function queryAdapter(uint256 _amountIn, address _tokenIn, address _tokenOut, uint8 _index)
        external
        returns (uint256);

    function queryNoSplit(uint256 _amountIn, address _tokenIn, address _tokenOut, uint8[] calldata _options)
        external
        view
        returns (Query memory);

    function queryNoSplit(uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (Query memory);

    function findBestPathWithGas(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        uint256 _gasPrice
    ) external view returns (FormattedOffer memory);

    function findBestPath(uint256 _amountIn, address _tokenIn, address _tokenOut, uint256 _maxSteps)
        external
        view
        returns (FormattedOffer memory);

    // swap

    function swapNoSplit(Trade calldata _trade, address _to, uint256 _fee) external;

    function swapNoSplitFromAVAX(Trade calldata _trade, address _to, uint256 _fee) external payable;

    function swapNoSplitToAVAX(Trade calldata _trade, address _to, uint256 _fee) external;

    function swapNoSplitWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function swapNoSplitToAVAXWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdapter {
    function swap(uint256 amountIn, uint256 amountOut, address fromToken, address toToken, address to) external;

    function query(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
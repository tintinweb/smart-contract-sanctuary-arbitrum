/**
 *Submitted for verification at Arbiscan on 2023-08-10
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/interfaces/IUniswapV2Router01.sol

// SPDX-License-Identifier: MIT

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
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

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

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}


// File contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}


// File contracts/types/DataTypes.sol

pragma solidity ^0.8.13;

/**
 * @title DataTypes
 * @notice This library contains Data types for the paraspace market.
 */
library DataTypes {
  struct Credit {
    address token;
    uint256 amount;
    bytes orderId;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
}


// File contracts/interfaces/IPool.sol

pragma solidity ^0.8.13;

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an Paraspace Pool.
 **/
interface IPool {
  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidateERC20(
    address collateralAsset,
    address liquidationAsset,
    address user,
    uint256 liquidationAmount,
    bool receivePToken
  ) external payable;

  function liquidateERC721(
    address collateralAsset,
    address user,
    uint256 collateralTokenId,
    uint256 liquidationAmount,
    bool receiveNToken
  ) external payable;

  /**
   * @notice Implements the acceptBidWithCredit feature. AcceptBidWithCredit allows users to
   * accept a leveraged bid on ParaSpace NFT marketplace. Users can submit leveraged bid and pay
   * at most (1 - LTV) * $NFT
   * @dev The nft receiver just needs to do the downpayment
   * @param marketplaceId The marketplace identifier
   * @param payload The encoded parameters to be passed to marketplace contract (selector eliminated)
   * @param credit The credit that user would like to use for this purchase
   * @param onBehalfOf Address of the user who will sell the NFT
   * @param referralCode The referral code used
   */
  function acceptBidWithCredit(
    bytes32 marketplaceId,
    bytes calldata payload,
    DataTypes.Credit calldata credit,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function unstakeApePositionAndRepay(
    address nftAsset,
    uint256 tokenId
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent xTokens owned
   * E.g. User has 100 pUSDC, calls withdraw() and receives 100 USDC, burning the 100 pUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Withdraws multiple `tokenIds` of underlying ERC721  asset from the reserve, burning the equivalent nTokens owned
   * E.g. User has 2 nBAYC, calls withdraw() and receives 2 BAYC, burning the 2 nBAYC
   * @param asset The address of the underlying asset to withdraw
   * @param tokenIds The underlying tokenIds to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdrawERC721(
    address asset,
    uint256[] calldata tokenIds,
    address to
  ) external returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/interfaces/IWETH.sol

pragma solidity ^0.8.13;

interface IWETH is IERC20 {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function balanceOf(address account) external view returns (uint256);
}


// File contracts/interfaces/IMoonBird.sol

pragma solidity ^0.8.13;

/**
    @title MoonBirds contract interface
 */
interface IMoonBirdBase {
  function nestingOpen() external returns (bool);

  function toggleNesting(uint256[] calldata tokenIds) external;

  function nestingPeriod(uint256 tokenId)
    external
    view
    returns (
      bool nesting,
      uint256 current,
      uint256 total
    );
}

interface IMoonBird is IMoonBirdBase {
  function safeTransferWhileNesting(
    address from,
    address to,
    uint256 tokenId
  ) external;
}


// File contracts/interfaces/IFlashLoanPool.sol

pragma solidity ^0.8.13;

interface IFlashLoanPool {
  /**
   * @notice AAVE flashloan interface
   */
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice AAVE flashLoanSimple interface
   */
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Moonbeam StellaSwap flash interface: Receive token0 and/or token1 and pay it back, plus a fee, in the callback
   * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
   * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
   * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
   * the donation amount(s) from the callback
   * @param recipient The address which will receive the token0 and token1 amounts
   * @param amount0 The amount of token0 to send
   * @param amount1 The amount of token1 to send
   * @param data Any data to be passed through to the callback
   */
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/LiquidatorConfig.sol

pragma solidity ^0.8.13;







/**
 * @dev Use LiquidatorConfig to store config for Liquidator Contracts,
 * including addresses of contract dependencies and executor white list.
 */
contract LiquidatorConfig is Ownable {
  mapping(address => bool) _executorWhitelist;

  IPool public pool;
  IFlashLoanPool public flashLoanPool;
  IMoonBird public immutable MOONBIRDS;
  IWETH public immutable WETH;
  IERC20 public immutable APE;

  constructor(IPool _pool, IFlashLoanPool _flashLoanPool, IMoonBird moonBird, IWETH weth, IERC20 ape) {
    pool = _pool;
    flashLoanPool = _flashLoanPool;
    MOONBIRDS = moonBird;
    WETH = weth;
    APE = ape;
  }

  /**
   * @dev Add `users` as white listed executors
   */
  function addExecutors(address[] memory users) public onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      _executorWhitelist[users[i]] = true;
    }
  }

  /**
   * @dev Remove `users` from white listed executors.
   * It's a no-op if input is not in the white list.
   */
  function removeExecutors(address[] memory users) public onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      _executorWhitelist[users[i]] = false;
    }
  }

  /**
   * @dev Check `addr` whether it is a white listed executor or not.
   */
  function isExecutor(address addr) public view returns (bool) {
    return _executorWhitelist[addr];
  }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/LiquidatorBase.sol

pragma solidity ^0.8.13;




/**
 * @dev Base class for Liquidator Contracts.
 * An immutable address of `LiquidatorConfig` is managed.
 * Withdraw ERC20 or ERC721 functions are provided here.
 */
abstract contract LiquidatorBase is Ownable {
  using SafeERC20 for IERC20;

  LiquidatorConfig public CONFIG;

  error CannotRepayFlashLoan(uint256 repayAmount, uint256 realAmount);

  constructor(LiquidatorConfig config) {
    CONFIG = config;
  }

  modifier onlyExecutor() {
    require(msg.sender == owner() || CONFIG.isExecutor(msg.sender), "Caller must be owner or executor");
    _;
  }

  /**
   * @dev owner can withdraw ERC20 tokens locked on this contract
   */
  function withdrawERC20(address _token, address _account, uint256 _amount) external onlyOwner {
    IERC20 token = IERC20(_token);
    if (_amount > token.balanceOf(address(this))) {
      _amount = token.balanceOf(address(this));
    }
    token.safeTransfer(_account, _amount);
  }

  /**
   * @dev owner can withdraw ERC721 tokens locked on this contract
   */
  function withdrawERC721(address _token, address _account, uint256 _tokenId) external onlyOwner {
    IERC721 token = IERC721(_token);
    token.safeTransferFrom(address(this), _account, _tokenId);
  }

  /**
   * @dev internal function, transfer all ERC20 tokens except the flashloan asset to owner
   */
  function _transferToAdmin(address _token) internal {
    _transferToAdmin(_token, IERC20(_token).balanceOf(address(this)));
  }

  /**
   * @dev override `_transferToAdmin`
   */
  function _transferToAdmin(address _token, uint256 _amount) internal {
    IERC20 token = IERC20(_token);
    if (_amount > 0) {
      token.safeTransfer(owner(), _amount);
    }
  }

  /**
   * @dev set new CONFIG
   */
  function setConfig(LiquidatorConfig config) external onlyOwner {
    CONFIG = config;
  }
}


// File contracts/interfaces/ILSSVMRouter.sol

pragma solidity ^0.8.13;

struct PairSwapSpecific {
  address pair;
  uint256[] nftIds;
}

interface ILSSVMRouter {
  /**
    @notice Swaps NFTs into ETH/ERC20 using multiple pairs.
    @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
    @param minOutput The minimum acceptable total tokens received
    @param tokenRecipient The address that will receive the token output
    @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
    @return outputAmount The total tokens received
  */
  function swapNFTsForToken(
    PairSwapSpecific[] calldata swapList,
    uint256 minOutput,
    address tokenRecipient,
    uint256 deadline
  ) external returns (uint256 outputAmount);
}


// File contracts/types/ConsiderationEnums.sol

pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}


// File contracts/types/ConsiderationStructs.sol

pragma solidity ^0.8.7;

// prettier-ignore

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}


// File contracts/types/LooksRareOrderStructs.sol

pragma solidity ^0.8.0;

/**
 * @notice CollectionType is used in OrderStructs.Maker's collectionType to determine the collection type being traded.
 */
enum CollectionType {
  ERC721,
  ERC1155
}

/**
 * @notice QuoteType is used in OrderStructs.Maker's quoteType to determine whether the maker order is a bid or an ask.
 */
enum QuoteType {
  Bid,
  Ask
}

/**
 * @title OrderStructs
 * @notice This library contains all order struct types for the LooksRare protocol (v2).
 * @author LooksRare protocol team (👀,💎)
 */
library OrderStructs {
  /**
   * 1. Maker struct
   */

  /**
   * @notice Maker is the struct for a maker order.
   * @param quoteType Quote type (i.e. 0 = BID, 1 = ASK)
   * @param globalNonce Global user order nonce for maker orders
   * @param subsetNonce Subset nonce (shared across bid/ask maker orders)
   * @param orderNonce Order nonce (it can be shared across bid/ask maker orders)
   * @param strategyId Strategy id
   * @param collectionType Collection type (i.e. 0 = ERC721, 1 = ERC1155)
   * @param collection Collection address
   * @param currency Currency address (@dev address(0) = ETH)
   * @param signer Signer address
   * @param startTime Start timestamp
   * @param endTime End timestamp
   * @param price Minimum price for maker ask, maximum price for maker bid
   * @param itemIds Array of itemIds
   * @param amounts Array of amounts
   * @param additionalParameters Extra data specific for the order
   */
  struct Maker {
    QuoteType quoteType;
    uint256 globalNonce;
    uint256 subsetNonce;
    uint256 orderNonce;
    uint256 strategyId;
    CollectionType collectionType;
    address collection;
    address currency;
    address signer;
    uint256 startTime;
    uint256 endTime;
    uint256 price;
    uint256[] itemIds;
    uint256[] amounts;
    bytes additionalParameters;
  }

  /**
   * 2. Taker struct
   */

  /**
   * @notice Taker is the struct for a taker ask/bid order. It contains the parameters required for a direct purchase.
   * @dev Taker struct is matched against MakerAsk/MakerBid structs at the protocol level.
   * @param recipient Recipient address (to receive NFTs or non-fungible tokens)
   * @param additionalParameters Extra data specific for the order
   */
  struct Taker {
    address recipient;
    bytes additionalParameters;
  }

  /**
   * 3. Merkle tree struct
   */

  enum MerkleTreeNodePosition {
    Left,
    Right
  }

  /**
   * @notice MerkleTreeNode is a MerkleTree's node.
   * @param value It can be an order hash or a proof
   * @param position The node's position in its branch.
   *                 It can be left or right or none
   *                 (before the tree is sorted).
   */
  struct MerkleTreeNode {
    bytes32 value;
    MerkleTreeNodePosition position;
  }

  /**
   * @notice MerkleTree is the struct for a merkle tree of order hashes.
   * @dev A Merkle tree can be computed with order hashes.
   *      It can contain order hashes from both maker bid and maker ask structs.
   * @param root Merkle root
   * @param proof Array containing the merkle proof
   */
  struct MerkleTree {
    bytes32 root;
    MerkleTreeNode[] proof;
  }
}


// File contracts/types/LiquidatorDataTypes.sol

pragma solidity ^0.8.13;





// Flashloan platform
enum FlashLoanType {
  NONE,
  AAVE_V2,
  AAVE_V3,
  STELLA, // moonbeam StellaSwap
  MUTE // zksync mute.io
}

// Dex platform
enum SwapType {
  NONE,
  UNI_V2,
  UNI_V3,
  CURVE,
  STELLA_V3, // moonbeam stella swap
  SYNC_SWAP // zksync syncswap
}

struct CurveExchange {
  int128 i;
  int128 j;
  uint256 dx;
  uint256 min_dy;
  address weth;
  bool withdrawWETH;
  bool depositWETH;
}

struct SwapParams {
  SwapType sType;
  address router;
  // 1. for uniswapV3: swapPath (bytes)
  // 2. for uniswapV2/sushiswap: encode v2Path(address[])
  // 3. for curveSwap: encode with CurveExchange struct
  // 4. for SyncSwap: encode ISyncSwapRouter.SwapPath[0]
  bytes extraData;
}

enum TokenType {
  NONE,
  ERC20,
  ERC721,
  ATOKEN,
  CETH,
  CERC20,
  CAPE,
  BWETH,
  YAPE,
  PARA_ZK_WETH
}

struct AssetParams {
  address token;
  TokenType tokenType;
}

enum MarketType {
  SEAPORT_BASIC,
  SEAPORT_COLLECTION,
  LOOKSRARE, // LooksrareV2
  PARASPACE,
  CRYPTOPUNKS,
  UNIV3POS,
  NFTX,
  SUDO
}

struct Flashloan {
  // flashloan asset
  address asset;
  // flashloan amount
  uint256 amount;
  // AAVE Pool or other platform flashloan pool
  address target;
  // flashloan type
  FlashLoanType fType;
  // extra bytes
  bytes extraData;
}

struct Liquidation {
  AssetParams collateralAsset;
  AssetParams debtAsset;
  address user;
  uint256 debtToCover;
  IPool pool;
  // usage for the future change
  bytes extraData;
}

struct Swap {
  SwapParams flashLoanToDebt;
  SwapParams collateralToFlashLoan;
  // usage for the future change
  bytes extraData;
}

struct LiquidateCallParams {
  address collateralAsset;
  uint256 tokenId;
  address user;
  uint256 liquidationAmount; // equals flashLoanAmount and flashLoanAsset is limited to WETH
}

struct FlashLoanParams {
  SwapParams offerToFlashLoan;
}

struct SeaportBasicLiquidateERC721Params {
  BasicOrderParameters order;
  address market; // seaport
  address nftApprover; // conduit
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct AdvancedOrderParameters {
  AdvancedOrder advancedOrder;
  CriteriaResolver[] criteriaResolvers;
  bytes32 fulfillerConduitKey;
  address recipient;
}

struct SeaportAdvancedLiquidateERC721Params {
  AdvancedOrderParameters order;
  address market; // seaport
  address nftApprover; // conduit
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct LooksRareLiquidateERC721Params {
  OrderStructs.Taker takerAsk;
  OrderStructs.Maker makerBid;
  bytes makerSignature;
  OrderStructs.MerkleTree merkleTree;
  address affiliate;
  address market; // looksRareProtocol
  address nftApprover; // transferManager
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct AcceptBidWithCreditParams {
  bytes32 marketplaceId;
  bytes data;
  DataTypes.Credit credit;
  address onBehalfOf;
  uint16 referralCode;
}

struct ParaspaceLiquidateERC721Params {
  AcceptBidWithCreditParams acceptBidInfo;
  address nftApprover; // paraspace seaport or conduit address
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct CryptoPunksBid {
  uint256 punkIndex;
  address punkContract;
  address offerToken; // WETH
  uint256 amount; // value
}

// sell cryptopunks on CryptoPunksMarket contract
struct LiquidateCryptoPunksParams {
  CryptoPunksBid bid;
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct UniV3POSInfo {
  uint256 tokenId;
  address posManager;
  address offerToken;
  SwapParams swapToken0;
  SwapParams swapToken1;
}

// removeLiquidity and collect fees
struct LiquidateUniV3POSParams {
  UniV3POSInfo info;
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

// NFTX fullQuote params
struct NFTXQuote {
  bool isPunk;
  uint256 vaultId;
  uint256 nftId;
  address buyToken;
  uint256 minWethOut;
  address[] swapPath;
}

// NFTX market
struct NFTXLiquidateERC721Params {
  NFTXQuote quote;
  address market; // NFTXMarketplaceZap
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

// sudoswap swapNFTsForToken params
struct SudoQuote {
  address pair;
  uint256 nftId;
  uint256 minOutput;
  address outToken;
}

// SudoSwap market
struct SudoLiquidateERC721Params {
  SudoQuote quote;
  address market; // LSSVMRouter
  LiquidateCallParams liquidateParams;
  FlashLoanParams flashLoanParams;
}

struct UnstakeAndRepayParams {
  address nftAsset;
  uint256 tokenId;
}


// File contracts/interfaces/ConsiderationInterface.sol

pragma solidity ^0.8.7;

// prettier-ignore

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.1
 * @notice Consideration is a generalized ETH/ERC20/ERC721/ERC1155 marketplace.
 *         It minimizes external calls to the greatest extent possible and
 *         provides lightweight methods for common routes as well as more
 *         flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
  /**
   * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
   *         the native token for the given chain) as consideration for the
   *         order. An arbitrary number of "additional recipients" may also be
   *         supplied which will each receive native tokens from the fulfiller
   *         as consideration.
   *
   * @param parameters Additional information on the fulfilled order. Note
   *                   that the offerer must first approve this contract (or
   *                   their preferred conduit if indicated by the order) for
   *                   their offered ERC721 token to be transferred.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillBasicOrder(BasicOrderParameters calldata parameters)
    external
    payable
    returns (bool fulfilled);

  /**
   * @notice Fill an order, fully or partially, with an arbitrary number of
   *         items for offer and consideration alongside criteria resolvers
   *         containing specific token identifiers and associated proofs.
   *
   * @param advancedOrder       The order to fulfill along with the fraction
   *                            of the order to attempt to fill. Note that
   *                            both the offerer and the fulfiller must first
   *                            approve this contract (or their preferred
   *                            conduit if indicated by the order) to transfer
   *                            any relevant tokens on their behalf and that
   *                            contracts must implement `onERC1155Received`
   *                            to receive ERC1155 tokens as consideration.
   *                            Also note that all offer and consideration
   *                            components must have no remainder after
   *                            multiplication of the respective amount with
   *                            the supplied fraction for the partial fill to
   *                            be considered valid.
   * @param criteriaResolvers   An array where each element contains a
   *                            reference to a specific offer or
   *                            consideration, a token identifier, and a proof
   *                            that the supplied token identifier is
   *                            contained in the merkle root held by the item
   *                            in question's criteria element. Note that an
   *                            empty criteria indicates that any
   *                            (transferable) token identifier on the token
   *                            in question is valid and that no associated
   *                            proof needs to be supplied.
   * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
   *                            any, to source the fulfiller's token approvals
   *                            from. The zero hash signifies that no conduit
   *                            should be used, with direct approvals set on
   *                            Consideration.
   * @param recipient           The intended recipient for all received items,
   *                            with `address(0)` indicating that the caller
   *                            should receive the items.
   *
   * @return fulfilled A boolean indicating whether the order has been
   *                   successfully fulfilled.
   */
  function fulfillAdvancedOrder(
    AdvancedOrder calldata advancedOrder,
    CriteriaResolver[] calldata criteriaResolvers,
    bytes32 fulfillerConduitKey,
    address recipient
  ) external payable returns (bool fulfilled);
}


// File contracts/interfaces/ICryptoPunksMarket.sol

pragma solidity ^0.8.13;

interface ICryptoPunksMarket {
  function punkIndexToAddress(uint256 punkIndex)
    external
    view
    returns (address);

  function balanceOf(address user) external view returns (uint256);

  function transferPunk(address to, uint256 punkIndex) external;

  function withdraw() external;

  function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) external;

  function offerPunkForSaleToAddress(
    uint256 punkIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) external;
}


// File contracts/interfaces/INonfungiblePositionManager.sol

pragma solidity >=0.7.5;

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager {
  /// @notice Returns the position information associated with a given token ID.
  /// @dev Throws if the token ID is not valid.
  /// @param tokenId The ID of the token that represents the position
  /// @return nonce The nonce for permits
  /// @return operator The address that is approved for spending
  /// @return token0 The address of the token0 for a specific pool
  /// @return token1 The address of the token1 for a specific pool
  /// @return fee The fee associated with the pool
  /// @return tickLower The lower end of the tick range for the position
  /// @return tickUpper The higher end of the tick range for the position
  /// @return liquidity The liquidity of the position
  /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
  /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
  /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
  /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  /// @notice Decreases the amount of liquidity in a position and accounts it to the position
  /// @param params tokenId The ID of the token for which liquidity is being decreased,
  /// amount The amount by which liquidity will be decreased,
  /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
  /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
  /// deadline The time by which the transaction must be included to effect the change
  /// @return amount0 The amount of token0 accounted to the position's tokens owed
  /// @return amount1 The amount of token1 accounted to the position's tokens owed
  function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
  /// @param params tokenId The ID of the NFT for which tokens are being collected,
  /// recipient The account that should receive the tokens,
  /// amount0Max The maximum amount of token0 to collect,
  /// amount1Max The maximum amount of token1 to collect
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
  /// must be collected first.
  /// @param tokenId The ID of the token that is being burned
  function burn(uint256 tokenId) external payable;

  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);
}


// File contracts/interfaces/ILooksRareProtocol.sol

pragma solidity ^0.8.0;

// Libraries

/**
 * @title ILooksRareProtocol
 * @author LooksRare protocol team (👀,💎)
 */
interface ILooksRareProtocol {
  /**
   * @notice This struct contains the parameter of an execution strategy.
   * @param strategyId Id of the new strategy
   * @param standardProtocolFeeBp Standard protocol fee (in basis point)
   * @param minTotalFeeBp Minimum total fee (in basis point)
   * @param maxProtocolFeeBp Maximum protocol fee (in basis point)
   * @param selector Function selector for the transaction to be executed
   * @param isMakerBid Whether the strategyId is for maker bid
   * @param implementation Address of the implementation of the strategy
   */
  struct Strategy {
    bool isActive;
    uint16 standardProtocolFeeBp;
    uint16 minTotalFeeBp;
    uint16 maxProtocolFeeBp;
    bytes4 selector;
    bool isMakerBid;
    address implementation;
  }

  /**
   * @notice This function allows a user to execute a taker ask (against a maker bid).
   * @param takerAsk Taker ask struct
   * @param makerBid Maker bid struct
   * @param makerSignature Maker signature
   * @param merkleTree Merkle tree struct (if the signature contains multiple maker orders)
   * @param affiliate Affiliate address
   */
  function executeTakerAsk(
    OrderStructs.Taker calldata takerAsk,
    OrderStructs.Maker calldata makerBid,
    bytes calldata makerSignature,
    OrderStructs.MerkleTree calldata merkleTree,
    address affiliate
  ) external;

  /**
   * @notice This function allows a user to execute a taker bid (against a maker ask).
   * @param takerBid Taker bid struct
   * @param makerAsk Maker ask struct
   * @param makerSignature Maker signature
   * @param merkleTree Merkle tree struct (if the signature contains multiple maker orders)
   * @param affiliate Affiliate address
   */
  function executeTakerBid(
    OrderStructs.Taker calldata takerBid,
    OrderStructs.Maker calldata makerAsk,
    bytes calldata makerSignature,
    OrderStructs.MerkleTree calldata merkleTree,
    address affiliate
  ) external payable;

  /**
   * @notice This function allows a user to batch buy with an array of taker bids (against an array of maker asks).
   * @param takerBids Array of taker bid structs
   * @param makerAsks Array of maker ask structs
   * @param makerSignatures Array of maker signatures
   * @param merkleTrees Array of merkle tree structs if the signature contains multiple maker orders
   * @param affiliate Affiliate address
   * @param isAtomic Whether the execution should be atomic
   *        i.e. whether it should revert if 1 or more transactions fail
   */
  function executeMultipleTakerBids(
    OrderStructs.Taker[] calldata takerBids,
    OrderStructs.Maker[] calldata makerAsks,
    bytes[] calldata makerSignatures,
    OrderStructs.MerkleTree[] calldata merkleTrees,
    address affiliate,
    bool isAtomic
  ) external payable;

  function creatorFeeManager() external view returns (address);

  function transferManager() external view returns (address);

  function strategyInfo(
    uint256 strategyId
  ) external view returns (Strategy memory);
}


// File contracts/interfaces/IWrappedPunks.sol

pragma solidity ^0.8.13;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
  function punkContract() external view returns (address);

  function mint(uint256 punkIndex) external;

  function burn(uint256 punkIndex) external;

  function registerProxy() external;

  function proxyInfo(address user) external view returns (address proxy);
}


// File contracts/interfaces/INFTXMarketplaceZap.sol

pragma solidity ^0.8.13;

interface INFTXMarketplaceZap {
  /// @notice A mapping of NFTX Vault IDs to their address corresponding vault contract address
  function nftxVaultAddresses(uint256) external view returns (address);

  function mintAndSell721(
    uint256 vaultId,
    uint256[] calldata ids,
    uint256 minEthOut,
    address[] calldata path,
    address to
  ) external;

  function mintAndSell721WETH(
    uint256 vaultId,
    uint256[] calldata ids,
    uint256 minWethOut,
    address[] calldata path,
    address to
  ) external;
}


// File contracts/interfaces/ISyncSwapRouter.sol


pragma solidity ^0.8.0;

interface ISyncSwapRouter {
  struct SwapStep {
    address pool;
    bytes data; // https://github.com/syncswap/core-contracts/blob/master/contracts/pool/classic/SyncSwapClassicPool.sol#L233
    address callback;
    bytes callbackData;
  }

  struct SwapPath {
    SwapStep[] steps;
    address tokenIn;
    uint amountIn;
  }

  struct TokenAmount {
    address token;
    uint amount;
  }

  function swap(
    SwapPath[] memory paths,
    uint amountOutMin,
    uint deadline
  ) external payable returns (TokenAmount memory amountOut);
}


// File contracts/interfaces/ITransferManager.sol

pragma solidity ^0.8.0;

/**
 * @title ITransferManager
 * @author LooksRare protocol team (👀,💎)
 */
interface ITransferManager {
  function hasUserApprovedOperator(
    address owner,
    address operator
  ) external view returns (bool);

  function grantApprovals(address[] calldata operators) external;
}


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}


// File @uniswap/v3-core/contracts/interfaces/callback/[email protected]

pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


// File contracts/interfaces/IUniSwapV3Router02.sol

pragma solidity 0.8.13;



/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param amountIn The amount of token to swap
  /// @param amountOutMin The minimum amount of output that must be received
  /// @param path The ordered list of tokens to swap through
  /// @param to The recipient address
  /// @return amountOut The amount of the received token
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountOut);

  /// @notice Swaps as little as possible of one token for an exact amount of another token
  /// @param amountOut The amount of token to swap for
  /// @param amountInMax The maximum amount of input that the caller will pay
  /// @param path The ordered list of tokens to swap through
  /// @param to The recipient address
  /// @return amountIn The amount of token to pay
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to
  ) external payable returns (uint256 amountIn);
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
  /// and swap the entire amount, enabling contracts to send tokens before calling this function.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// that may remain in the router after the swap.
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutput(ExactOutputParams calldata params)
    external
    payable
    returns (uint256 amountIn);
}

/// @title MulticallExtended interface
/// @notice Enables calling multiple methods in a single call to the contract with optional validation
interface IMulticallExtended is IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param deadline The time by which this function must be called before failing
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(uint256 deadline, bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);

  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param previousBlockhash The expected parent blockHash
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes32 previousBlockhash, bytes[] calldata data)
    external
    payable
    returns (bytes[] memory results);
}

/// @title Router token swapping functionality
interface IUniSwapV3Router02 is
  IV2SwapRouter,
  IV3SwapRouter,
  IMulticallExtended,
  ISelfPermit
{

}


// File contracts/interfaces/ICurvePool.sol

pragma solidity ^0.8.13;

interface ICurvePool {
  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function get_dx(
    int128 i,
    int128 j,
    uint256 dy
  ) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256 dy);
}


// File hardhat/[email protected]

pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.7.5;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
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
        uint160 sqrtPriceLimitX96;
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
}


// File contracts/lib/LiquidatorLib.sol

pragma solidity ^0.8.13;


















library LiquidatorLib {
  using SafeERC20 for IERC20;

  /**
   * @dev using seaport fulfillBasicOrder function to fulfill bid
   * @param _seaport    seaport address : opensea seaport or paraspace seaport
   * @param _conduit    fulfiller conduit address
   */
  function fulfillBasicOrder(BasicOrderParameters memory parameters, address _seaport, address _conduit) external returns (bool fulfilled) {
    IERC721(parameters.considerationToken).setApprovalForAll(_conduit, true);
    return ConsiderationInterface(_seaport).fulfillBasicOrder(parameters);
  }

  /**
   * @dev using seaport fulfillAdvancedOrder function to fulfill collection bid
   * @param _seaport    seaport address : opensea seaport or paraspace seaport
   * @param _conduit    fulfiller conduit address
   */
  function fulfillAdvancedOrder(AdvancedOrderParameters memory parameters, address _seaport, address _conduit) external returns (bool fulfilled) {
    address considerationToken = parameters.advancedOrder.parameters.consideration[0].token;
    _safeERC721Approve(considerationToken, _conduit);

    if (parameters.advancedOrder.parameters.consideration.length > 1) {
      address offerToken = parameters.advancedOrder.parameters.offer[0].token;
      uint256 offerAmount = parameters.advancedOrder.parameters.offer[0].startAmount;
      _safeERC20Approve(offerToken, _conduit, offerAmount);
    }

    return
      ConsiderationInterface(_seaport).fulfillAdvancedOrder(
        parameters.advancedOrder,
        parameters.criteriaResolvers,
        parameters.fulfillerConduitKey,
        parameters.recipient
      );
  }

  /**
   * @dev using looksrare executeTakerAsk function to fulfill standard or collection bid
   * @param params LooksRareLiquidateERC721Params
   */
  function executeLooksrare(LooksRareLiquidateERC721Params memory params) external {
    ITransferManager manager = ITransferManager(params.nftApprover);
    if (!manager.hasUserApprovedOperator(address(this), params.market)) {
      address[] memory operators = new address[](1);
      operators[0] = params.market;
      manager.grantApprovals(operators);
    }
    _safeERC721Approve(params.makerBid.collection, params.nftApprover);

    ILooksRareProtocol(params.market).executeTakerAsk(params.takerAsk, params.makerBid, params.makerSignature, params.merkleTree, params.affiliate);
  }

  /**
   * @dev using CryptoPunksMarket acceptBidForPunk function to fulfill punk bid
   * @param _wpunk  wpunk address
   * @param bid     bid information
   */
  function acceptBidForPunk(address _wpunk, CryptoPunksBid memory bid) external {
    IWrappedPunks(_wpunk).burn(bid.punkIndex);

    ICryptoPunksMarket punk = ICryptoPunksMarket(bid.punkContract);
    punk.acceptBidForPunk(bid.punkIndex, bid.amount);
    punk.withdraw();

    IWETH(bid.offerToken).deposit{ value: address(this).balance }();
  }

  /**
   * @dev remove UNIV3POS liquidity and collect fees to get some token0 and token1
   * @param params UNIV3POS Information
   */
  function uniV3RemoveLiquidityAndCollection(UniV3POSInfo memory params) external {
    INonfungiblePositionManager posManager = INonfungiblePositionManager(params.posManager);
    uint256 tokenId = params.tokenId;
    address weth = params.offerToken;
    (, , address token0, address token1, , , , uint128 liquidity, , , , ) = posManager.positions(tokenId);

    bytes[] memory data = new bytes[](3);

    data[0] = abi.encodeWithSelector(
      posManager.decreaseLiquidity.selector,
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      })
    );

    data[1] = abi.encodeWithSelector(
      posManager.collect.selector,
      INonfungiblePositionManager.CollectParams({
        tokenId: tokenId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    data[2] = abi.encodeWithSelector(posManager.burn.selector, tokenId);

    posManager.multicall(data);

    if (weth != token0) {
      _swapExactTokensForTokens(token0, IERC20(token0).balanceOf(address(this)), 0, params.swapToken0);
    }
    if (weth != token1) {
      _swapExactTokensForTokens(token1, IERC20(token1).balanceOf(address(this)), 0, params.swapToken1);
    }
  }

  /**
   * @dev using NFTXMarketplaceZap.mintAndSell721WETH to sell nft
   * @param quote NFTX market api quote
   * @param nft nft address
   * @param nftxMarket NFTXMarketplaceZap address
   */
  function nftxMintAndSell721(NFTXQuote memory quote, address nft, address nftxMarket) external {
    if (quote.isPunk) {
      IWrappedPunks wpunk = IWrappedPunks(nft);
      wpunk.burn(quote.nftId);
      ICryptoPunksMarket punk = ICryptoPunksMarket(wpunk.punkContract());
      punk.offerPunkForSaleToAddress(quote.nftId, 0, nftxMarket);
    } else {
      _safeERC721Approve(nft, nftxMarket);
    }

    uint256[] memory ids = new uint256[](1);
    ids[0] = quote.nftId;

    INFTXMarketplaceZap(nftxMarket).mintAndSell721WETH(quote.vaultId, ids, quote.minWethOut, quote.swapPath, address(this));
  }

  /**
   * @dev using LSSVMRouter.swapNFTsForToken to sell nft
   * @param quote sudoswap quote
   * @param nft nft address
   * @param sudoRouter sudoswap LSSVMRouter address
   */
  function sudoSwapNFTsForToken(SudoQuote memory quote, address nft, address sudoRouter) external {
    _safeERC721Approve(nft, sudoRouter);

    uint256[] memory nftIds = new uint256[](1);
    nftIds[0] = quote.nftId;

    PairSwapSpecific[] memory swapList = new PairSwapSpecific[](1);
    swapList[0] = PairSwapSpecific({ pair: quote.pair, nftIds: nftIds });

    ILSSVMRouter(sudoRouter).swapNFTsForToken(swapList, quote.minOutput, address(this), block.timestamp);

    IWETH(quote.outToken).deposit{ value: address(this).balance }();
  }

  /**
   * @dev safeApprove to 0 and then safeApprove to `_amount`
   *
   * IMPORTANT: This logic is required for compatibility for USDT or other
   * token with this kind of compatibility issue. It's not needed for most
   * other tokens.
   */
  function _safeERC20Approve(address _token, address _spender, uint256 _amount) public {
    IERC20 token = IERC20(_token);
    if (token.allowance(address(this), _spender) < _amount) {
      token.safeApprove(_spender, 0);
      token.safeApprove(_spender, type(uint256).max);
    }
  }

  /**
   * @dev check the NFT approved status before `setApprovalForAll`
   */
  function _safeERC721Approve(address _token, address _spender) public {
    IERC721 token = IERC721(_token);
    if (!token.isApprovedForAll(address(this), _spender)) {
      token.setApprovalForAll(_spender, true);
    }
  }

  function decodeAddressArray(bytes memory _bytes) public pure returns (address[] memory) {
    return abi.decode(_bytes, (address[]));
  }

  function decodeSyncSwapPath(bytes memory _bytes) public pure returns (ISyncSwapRouter.SwapPath memory) {
    return abi.decode(_bytes, (ISyncSwapRouter.SwapPath));
  }

  function decodeCurveSwapExc(bytes memory _bytes) public pure returns (CurveExchange memory) {
    return abi.decode(_bytes, (CurveExchange));
  }

  /**
   * @dev uniswapV2: swapTokensForExactTokens
   *      uniswapV3: exactOutput
   *      curve: curve pool's exchange
   */
  function _swapTokensForExactTokens(address tokenIn, uint256 amountInMax, uint256 amountOut, SwapParams memory params) public {
    console.log("_swapTokensForExactTokens", tokenIn, amountInMax, amountOut);
    console.log("tokenIn balance", IERC20(tokenIn).balanceOf(address(this)));

    _safeERC20Approve(tokenIn, params.router, amountInMax);

    if (params.sType == SwapType.UNI_V3) {
      IV3SwapRouter(params.router).exactOutput(
        IV3SwapRouter.ExactOutputParams({ path: params.extraData, recipient: address(this), amountOut: amountOut, amountInMaximum: amountInMax })
      );
    }
    if (params.sType == SwapType.STELLA_V3) {
      ISwapRouter(params.router).exactOutput(
        ISwapRouter.ExactOutputParams({
          path: params.extraData,
          recipient: address(this),
          deadline: block.timestamp,
          amountOut: amountOut,
          amountInMaximum: amountInMax
        })
      );
    }
    if (params.sType == SwapType.UNI_V2) {
      IUniswapV2Router02(params.router).swapTokensForExactTokens(
        amountOut,
        amountInMax,
        decodeAddressArray(params.extraData),
        address(this),
        block.timestamp
      );
    }
    if (params.sType == SwapType.CURVE) {
      CurveExchange memory curveExc = decodeCurveSwapExc(params.extraData);
      IWETH weth = IWETH(curveExc.weth);
      if (curveExc.withdrawWETH) {
        weth.withdraw(amountInMax);
      }

      ICurvePool(params.router).exchange{ value: curveExc.withdrawWETH ? amountInMax : 0 }(curveExc.i, curveExc.j, amountInMax, amountOut);

      if (curveExc.depositWETH) {
        weth.deposit{ value: address(this).balance }();
      }
    }

    console.log("after _swapTokensForExactTokens ", tokenIn, amountInMax, amountOut);
    console.log("tokenIn balance", IERC20(tokenIn).balanceOf(address(this)));
  }

  /**
   * @dev uniswapV2: swapExactTokensForTokens
   *      uniswapV3: exactInput
   *      curve: curve pool's exchange
   */
  function _swapExactTokensForTokens(address tokenIn, uint256 amountIn, uint256 amountOutMin, SwapParams memory params) public {
    console.log("_swapExactTokensForTokens", tokenIn, amountIn, amountOutMin);
    console.log("tokenIn balance", IERC20(tokenIn).balanceOf(address(this)));

    _safeERC20Approve(tokenIn, params.router, amountIn);

    if (params.sType == SwapType.UNI_V3) {
      IV3SwapRouter(params.router).exactInput(
        IV3SwapRouter.ExactInputParams({ path: params.extraData, recipient: address(this), amountIn: amountIn, amountOutMinimum: amountOutMin })
      );
    }
    if (params.sType == SwapType.STELLA_V3) {
      ISwapRouter(params.router).exactInput(
        ISwapRouter.ExactInputParams({
          path: params.extraData,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: amountIn,
          amountOutMinimum: amountOutMin
        })
      );
    }
    if (params.sType == SwapType.UNI_V2) {
      IUniswapV2Router02(params.router).swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        decodeAddressArray(params.extraData),
        address(this),
        block.timestamp
      );
    }
    if (params.sType == SwapType.CURVE) {
      CurveExchange memory curveExc = decodeCurveSwapExc(params.extraData);
      if (curveExc.withdrawWETH) {
        IWETH(curveExc.weth).withdraw(amountIn);
      }

      ICurvePool(params.router).exchange{ value: curveExc.withdrawWETH ? amountIn : 0 }(curveExc.i, curveExc.j, curveExc.dx, curveExc.min_dy);

      if (curveExc.depositWETH) {
        IWETH(curveExc.weth).deposit{ value: address(this).balance }();
      }
    }
    if (params.sType == SwapType.SYNC_SWAP) {
      ISyncSwapRouter.SwapPath[] memory path = new ISyncSwapRouter.SwapPath[](1);
      path[0] = decodeSyncSwapPath(params.extraData);
      path[0].amountIn = amountIn;
      path[0].tokenIn = tokenIn;
      ISyncSwapRouter(params.router).swap(path, amountOutMin, block.timestamp);
    }

    console.log("after _swapExactTokensForTokens", tokenIn, amountIn, amountOutMin);
    console.log("tokenIn balance", IERC20(tokenIn).balanceOf(address(this)));
  }
}


// File contracts/interfaces/IAlgebraFlashCallback.sol

pragma solidity ^0.8.13;

/**
 *  @title Callback for IAlgebraPoolActions#flash
 *  @notice Any contract that calls IAlgebraPoolActions#flash must implement this interface
 *  @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 *  https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraFlashCallback {
  /**
   *  @notice Called to `msg.sender` after transferring to the recipient from IAlgebraPool#flash.
   *  @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
   *  The caller of this method must be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
   *  @param fee0 The fee amount in token0 due to the pool by the end of the flash
   *  @param fee1 The fee amount in token1 due to the pool by the end of the flash
   *  @param data Any data passed through by the caller via the IAlgebraPoolActions#flash call
   */
  function algebraFlashCallback(
    uint256 fee0,
    uint256 fee1,
    bytes calldata data
  ) external;
}


// File contracts/interfaces/IFlashLoanReceiver.sol

pragma solidity ^0.8.13;

interface IFlashLoanReceiver {
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}


// File contracts/interfaces/IMuteSwitchPairDynamic.sol


pragma solidity ^0.8.0;

interface IMuteSwitchPairDynamic {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function stable() external pure returns (bool);

  function balanceOf(address owner) external view returns (uint);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    bytes memory sig
  ) external;

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function pairFee() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function claimFees() external returns (uint claimed0, uint claimed1);

  function claimFeesView(
    address recipient
  ) external view returns (uint claimed0, uint claimed1);

  function initialize(address, address, uint, bool) external;

  function getAmountOut(uint, address) external view returns (uint);
}


// File contracts/interfaces/IFlashLoanSimpleReceiver.sol

pragma solidity ^0.8.13;

/**
 * @title IFlashLoanSimpleReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanSimpleReceiver {
  /**
   * @notice Executes an operation after receiving the flash-borrowed asset
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param asset The address of the flash-borrowed asset
   * @param amount The amount of the flash-borrowed asset
   * @param premium The fee of the flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}


// File contracts/interfaces/ICErc20.sol

pragma solidity ^0.8.13;

interface ICErc20 {
  function underlying() external view returns (address);

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);
}


// File contracts/interfaces/ICApe.sol

pragma solidity 0.8.13;

interface ICApe is IERC20 {
  function deposit(address onBehalf, uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getShareByPooledApe(uint256 amount) external view returns (uint256);

  function getPooledApeByShares(
    uint256 _sharesAmount
  ) external view returns (uint256);

  function apeCoin() external view returns(address);

  function sharesOf(address _account) external view returns (uint256);
}


// File contracts/interfaces/IMuteSwitchCallee.sol


pragma solidity ^0.8.0;

interface IMuteSwitchCallee {
  function muteswitchCall(
    address sender,
    uint amount0,
    uint amount1,
    bytes calldata data
  ) external;
}


// File contracts/interfaces/ICEther.sol

pragma solidity ^0.8.13;

interface ICEther {
  function mint() external payable;

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  function exchangeRateStored() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);
}


// File contracts/interfaces/ILendingPool.sol

pragma solidity ^0.8.13;

interface ILendingPool {
  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint256);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}


// File contracts/interfaces/IBToken.sol

pragma solidity ^0.8.13;

interface IBToken {
  /**
   * @dev Returns the address of the underlying asset of this bToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @dev Returns the address of BendDao POOL address
   **/
  function POOL() external view returns (address);

  function balanceOf(address account) external view returns (uint256);
}


// File contracts/interfaces/IAToken.sol

pragma solidity ^0.8.13;

interface IAToken {
  function UNDERLYING_ASSET_ADDRESS() external view returns(address);
  
  function balanceOf(address account) external view returns (uint256);

  function POOL() external view returns (address);
}


// File contracts/interfaces/IAutoYieldApe.sol

pragma solidity ^0.8.13;

/**
 * @title AutoYieldApe interface
 */
interface IAutoYieldApe {
    /**
     * @dev Emitted during deposit()
     * @param user The address of the user deposit for
     * @param amountDeposited The amount being deposit
     **/
    event Deposit(
        address indexed caller,
        address indexed user,
        uint256 amountDeposited
    );

    /**
     * @dev Emitted during withdraw()
     * @param user The address of the user
     * @param amountWithdraw The amount being withdraw
     **/
    event Redeem(address indexed user, uint256 amountWithdraw);

    /**
     * @dev Emitted during claim()
     * @param user The address of the user
     * @param amount The amount being claimed
     **/
    event YieldClaimed(
        address indexed caller,
        address indexed user,
        uint256 amount
    );

    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during setHarvestOperator()
     * @param oldOperator The address of the old harvest operator
     * @param newOperator The address of the new harvest operator
     **/
    event HarvestOperatorUpdated(address oldOperator, address newOperator);

    /**
     * @dev Emitted during setHarvestFeeRate()
     * @param oldFee The value of the old harvest fee
     * @param newFee The value of the new harvest fee
     **/
    event HarvestFeeRateUpdated(uint256 oldFee, uint256 newFee);

    /**
     * @notice deposit an `amount` of ape into pool.
     * @param onBehalf The address of user will receive the yApe balance
     * @param amount The amount of ape to be deposit
     **/
    function deposit(address onBehalf, uint256 amount) external;

    /**
     * @notice withdraw an `amount` of ape from yield pool.
     * @param amount The amount of ape to be withdraw
     **/
    function withdraw(uint256 amount) external;

    /**
     * @notice claim the yield token for the specified account.
     * @param account The account address will be claimed
     **/
    function claimFor(address account) external;

    /**
     * @notice withdraw all balance of ape from pool.
     **/
    function exit() external;

    /**
     * @notice This function will claim the pending Ape Coin reward and sell it to usdc by uniswap,
     then supply usdc to pUsdc. This is is the only way to update pool yield index.
     This function can only be called by harvestOperator
     * @param minimumDealPrice The minimal accept deal price to sell Ape coin to usdc
     **/
    function harvest(uint256 minimumDealPrice) external;

    /**
     * @notice fetch the settled yield amount for the specified account.
     **/
    function yieldAmount(address account) external view returns (uint256);
}


// File contracts/FlashloanLiquidatorV3.sol

pragma solidity ^0.8.13;















/**
 * @dev Use FlashLoanLiquidator to make one liquidate call with a flash loaned
 * asset. Profits will not stay in this contract and will be directly sent to
 * owner. This contract holds no asset.
 */
contract FlashLoanLiquidatorV3 is LiquidatorBase, IFlashLoanReceiver, IFlashLoanSimpleReceiver, IAlgebraFlashCallback, IMuteSwitchCallee {
  using SafeERC20 for IERC20;

  address public immutable WETH;

  struct LiquidateERC20Params {
    Flashloan flashloan;
    Liquidation liquidation;
    Swap swap;
  }

  event LiquidateERC20(LiquidateERC20Params params);
  error DebtTokenNotEnough(uint256 debtToCover, uint256 realAmount);

  /**
   * @dev Input address of a deployed `LiquidatorConfig` and store it in
   * `LiquidatorBase`.
   */
  constructor(LiquidatorConfig config) LiquidatorBase(config) {
    WETH = address(config.WETH());
  }

  receive() external payable {}

  /**
   * @dev Entry for a ERC20 flash loan liquidation case.
   * Refer to `LiquidateERC20Params` for details of params.
   */
  function liquidateERC20(LiquidateERC20Params memory params) public onlyExecutor {
    Flashloan memory flashloan = params.flashloan;
    IFlashLoanPool fPool = IFlashLoanPool(flashloan.target);
    address receiverAddress = address(this);

    console.log("flashloan.fType", uint8(flashloan.fType));
    console.log("flashloan.amount", flashloan.amount);

    require(flashloan.fType != FlashLoanType.NONE, "flashloan type: NONE");

    if (flashloan.fType == FlashLoanType.AAVE_V2) {
      // the various assets to be flashed
      address[] memory assets = new address[](1);
      assets[0] = params.flashloan.asset;
      // the amount to be flashed for each asset
      uint256[] memory amounts = new uint256[](1);
      amounts[0] = params.flashloan.amount;
      // 0 = no debt, 1 = stable, 2 = variable
      uint256[] memory modes = new uint256[](1);
      modes[0] = 0;

      fPool.flashLoan(receiverAddress, assets, amounts, modes, address(this), abi.encode(params), 0);
    } else if (flashloan.fType == FlashLoanType.AAVE_V3) {
      fPool.flashLoanSimple(address(this), flashloan.asset, flashloan.amount, abi.encode(params), 0);
    } else if (flashloan.fType == FlashLoanType.STELLA) {
      bool isToken0 = abi.decode(flashloan.extraData, (bool));
      fPool.flash(receiverAddress, isToken0 ? flashloan.amount : 0, isToken0 ? 0 : flashloan.amount, abi.encode(params));
    } else if (flashloan.fType == FlashLoanType.MUTE) {
      bool isToken0 = abi.decode(flashloan.extraData, (bool));
      fPool.swap(isToken0 ? flashloan.amount : 0, isToken0 ? 0 : flashloan.amount, receiverAddress, abi.encode(params));
    }

    emit LiquidateERC20(params);
  }

  function flashloanCallback(uint256 fee, LiquidateERC20Params memory params) internal {
    Flashloan memory flashloan = params.flashloan;
    Liquidation memory liquidation = params.liquidation;

    console.log("[after flashloan]", IERC20(flashloan.asset).balanceOf(address(this)));
    console.log("[after flashloan]", IERC20(params.liquidation.debtAsset.token).balanceOf(address(this)));
    console.log("[after flashloan]", IERC20(params.liquidation.collateralAsset.token).balanceOf(address(this)));

    _beforeLiquidate(flashloan, liquidation, params.swap);

    console.log("[after flashloanToDebt]", IERC20(flashloan.asset).balanceOf(address(this)));
    console.log("[after flashloanToDebt]", IERC20(params.liquidation.debtAsset.token).balanceOf(address(this)));
    console.log("[after flashloanToDebt]", IERC20(params.liquidation.collateralAsset.token).balanceOf(address(this)));

    // liquidate ERC20
    LiquidatorLib._safeERC20Approve(liquidation.debtAsset.token, address(liquidation.pool), liquidation.debtToCover);

    liquidation.pool.liquidateERC20(liquidation.collateralAsset.token, liquidation.debtAsset.token, liquidation.user, liquidation.debtToCover, false);

    console.log("[after liquidateERC20]", IERC20(flashloan.asset).balanceOf(address(this)));
    console.log("[after liquidateERC20]", IERC20(params.liquidation.debtAsset.token).balanceOf(address(this)));
    console.log("[after liquidateERC20]", IERC20(params.liquidation.collateralAsset.token).balanceOf(address(this)));

    uint256 repayAmount = flashloan.amount + fee;

    console.log("flashloan fee", fee);
    console.log("flashloan totalRepayAmount", repayAmount);

    _afterLiquidate(flashloan, liquidation, params.swap, repayAmount);

    console.log("[after collateralToFlashloan]", IERC20(flashloan.asset).balanceOf(address(this)));
    console.log("[after collateralToFlashloan]", IERC20(params.liquidation.debtAsset.token).balanceOf(address(this)));
    console.log("[after collateralToFlashloan]", IERC20(params.liquidation.collateralAsset.token).balanceOf(address(this)));

    uint256 flashBal = IERC20(flashloan.asset).balanceOf(address(this));
    if (flashBal < repayAmount) {
      revert CannotRepayFlashLoan(repayAmount, flashBal);
    }

    if (liquidation.debtAsset.token != flashloan.asset) {
      _transferToAdmin(liquidation.debtAsset.token);
    }
    if (flashBal > repayAmount) {
      _transferToAdmin(flashloan.asset, flashBal - repayAmount);
    }

    console.log("[after transferToAdmin]", IERC20(flashloan.asset).balanceOf(address(this)));
    console.log("[after transferToAdmin]", IERC20(params.liquidation.debtAsset.token).balanceOf(address(this)));
    console.log("[after transferToAdmin]", IERC20(params.liquidation.collateralAsset.token).balanceOf(address(this)));
  }

  /**
   * @dev Moonbeam StellaSwap flashloan callback
   */
  function algebraFlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
    LiquidateERC20Params memory params = abi.decode(data, (LiquidateERC20Params));
    bool isToken0 = abi.decode(params.flashloan.extraData, (bool));
    uint256 fee = isToken0 ? fee0 : fee1;

    flashloanCallback(fee, params);

    // transfer fee + flashloan amount to flashloan pool
    IERC20(params.flashloan.asset).transfer(params.flashloan.target, fee + params.flashloan.amount);
  }

  /**
   * @dev zksync mute.io flashloan callback
   */
  function muteswitchCall(address, uint256, uint256, bytes calldata data) external {
    LiquidateERC20Params memory params = abi.decode(data, (LiquidateERC20Params));

    uint256 fee = (params.flashloan.amount * IMuteSwitchPairDynamic(msg.sender).pairFee()) / 10000;

    flashloanCallback(fee, params);

    // transfer fee + flashloan amount to flashloan pool
    IERC20(params.flashloan.asset).transfer(params.flashloan.target, fee + params.flashloan.amount);
  }

  /**
   * @dev AAVE V2 flashloan callback
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address,
    bytes calldata data
  ) external returns (bool) {
    LiquidateERC20Params memory params = abi.decode(data, (LiquidateERC20Params));

    flashloanCallback(premiums[0], params);

    // Approve the LendingPool contract allowance to *pull* the repayAmount
    LiquidatorLib._safeERC20Approve(assets[0], params.flashloan.target, amounts[0] + premiums[0]);

    return true;
  }

  /**
   * @dev AAVE V3 flashloan callback
   */
  function executeOperation(address asset, uint256 amount, uint256 premium, address, bytes calldata data) external returns (bool) {
    LiquidateERC20Params memory params = abi.decode(data, (LiquidateERC20Params));

    flashloanCallback(premium, params);

    // Approve the LendingPool contract allowance to *pull* the repayAmount
    LiquidatorLib._safeERC20Approve(asset, params.flashloan.target, amount + premium);

    return true;
  }

  /**
   * @dev 1. if debtToken is a/ctoken, do deposit on aave or compound
   *      2. if necessary, swap collateral asset to flashloan asset
   */
  function _beforeLiquidate(Flashloan memory flashloan, Liquidation memory liquidation, Swap memory swap) internal {
    if (liquidation.debtAsset.tokenType == TokenType.CETH) {
      // flashloanAsset : weth
      IWETH weth = IWETH(WETH);
      weth.withdraw(flashloan.amount);
      ICEther(liquidation.debtAsset.token).mint{ value: flashloan.amount }();
    }

    if (liquidation.debtAsset.tokenType == TokenType.CERC20) {
      ICErc20 cErc20 = ICErc20(liquidation.debtAsset.token);
      address underlying = cErc20.underlying();
      // flashloan to underlying of debt token
      if (!isZeroAddress(swap.flashLoanToDebt.router)) {
        uint256 amountOut = (liquidation.debtToCover * cErc20.exchangeRateCurrent()) / 1e18 + 1; // Avoid precision loss
        LiquidatorLib._swapTokensForExactTokens(flashloan.asset, flashloan.amount, amountOut, swap.flashLoanToDebt);
      }

      uint256 underlyingBal = IERC20(underlying).balanceOf(address(this));
      LiquidatorLib._safeERC20Approve(underlying, liquidation.debtAsset.token, underlyingBal);
      cErc20.mint(underlyingBal);
    }

    if (liquidation.debtAsset.tokenType == TokenType.ATOKEN) {
      IAToken atoken = IAToken(liquidation.debtAsset.token);
      ILendingPool lendingPool = ILendingPool(atoken.POOL());
      address underlying = atoken.UNDERLYING_ASSET_ADDRESS();

      // flashloan to underlying of debt token
      if (!isZeroAddress(swap.flashLoanToDebt.router)) {
        LiquidatorLib._swapTokensForExactTokens(flashloan.asset, flashloan.amount, liquidation.debtToCover, swap.flashLoanToDebt);
      }

      LiquidatorLib._safeERC20Approve(underlying, address(lendingPool), liquidation.debtToCover);
      lendingPool.deposit(underlying, liquidation.debtToCover, address(this), 0);
    }

    if (liquidation.debtAsset.tokenType == TokenType.ERC20) {
      if (!isZeroAddress(swap.flashLoanToDebt.router)) {
        LiquidatorLib._swapTokensForExactTokens(flashloan.asset, flashloan.amount, liquidation.debtToCover, swap.flashLoanToDebt);
      }
    }

    if (liquidation.debtAsset.tokenType == TokenType.CAPE) {
      ICApe cApe = ICApe(liquidation.debtAsset.token);
      address underlying = cApe.apeCoin();
      if (!isZeroAddress(swap.flashLoanToDebt.router)) {
        uint256 amountOut = liquidation.debtToCover + 1;
        LiquidatorLib._swapTokensForExactTokens(flashloan.asset, flashloan.amount, amountOut, swap.flashLoanToDebt);
      }
      uint256 underlyingBal = IERC20(underlying).balanceOf(address(this));
      LiquidatorLib._safeERC20Approve(underlying, address(cApe), underlyingBal);
      cApe.deposit(address(this), underlyingBal);
    }

    if (liquidation.debtAsset.tokenType == TokenType.BWETH) {
      IBToken bToken = IBToken(liquidation.debtAsset.token);
      address bendPool = bToken.POOL();
      // flashloan asset is WETH.
      LiquidatorLib._safeERC20Approve(WETH, bendPool, flashloan.amount);
      ILendingPool(bendPool).deposit(WETH, flashloan.amount, address(this), 0);
    }

    // flashloan asset must be zk official WETH
    if (liquidation.debtAsset.tokenType == TokenType.PARA_ZK_WETH) {
      IWETH(flashloan.asset).withdraw(flashloan.amount);
      IWETH(liquidation.debtAsset.token).deposit{ value: flashloan.amount }();
    }
    // YAPE can not be borrowed.

    uint256 debtBal = IERC20(liquidation.debtAsset.token).balanceOf(address(this));

    console.log("[after flashloantoDebt] debtBal", debtBal);
    if (debtBal < liquidation.debtToCover) {
      revert DebtTokenNotEnough(debtBal, liquidation.debtToCover);
    }
  }

  /**
   * @dev 1. if collateralAsset is a/ctoken, withdraw a/ctoken to its underlying token
   *      2. if necessary, swap collateral asset to flashloan asset
   */
  function _afterLiquidate(Flashloan memory flashloan, Liquidation memory liquidation, Swap memory swap, uint256 repayAmount) internal {
    uint256 flashBalBefore = IERC20(flashloan.asset).balanceOf(address(this));
    if (flashBalBefore >= repayAmount) return;

    address underlying;

    if (liquidation.collateralAsset.tokenType == TokenType.CETH) {
      ICEther cETH = ICEther(liquidation.collateralAsset.token);
      cETH.redeem(cETH.balanceOf(address(this)));
      IWETH(WETH).deposit{ value: address(this).balance }();
      underlying = WETH;
    }

    if (liquidation.collateralAsset.tokenType == TokenType.CERC20) {
      ICErc20 cErc20 = ICErc20(liquidation.collateralAsset.token);
      cErc20.redeem(cErc20.balanceOf(address(this)));
      underlying = cErc20.underlying();
    }

    if (liquidation.collateralAsset.tokenType == TokenType.ATOKEN) {
      IAToken atoken = IAToken(liquidation.collateralAsset.token);
      ILendingPool lendingPool = ILendingPool(atoken.POOL());
      underlying = atoken.UNDERLYING_ASSET_ADDRESS();
      lendingPool.withdraw(underlying, type(uint256).max, address(this));
    }

    if (liquidation.collateralAsset.tokenType == TokenType.ERC20) {
      underlying = liquidation.collateralAsset.token;
    }

    if (liquidation.collateralAsset.tokenType == TokenType.CAPE) {
      ICApe cApe = ICApe(liquidation.collateralAsset.token);
      underlying = cApe.apeCoin();
      cApe.withdraw(cApe.balanceOf(address(this)));
    }

    if (liquidation.collateralAsset.tokenType == TokenType.BWETH) {
      IBToken bToken = IBToken(liquidation.collateralAsset.token);
      ILendingPool bendPool = ILendingPool(bToken.POOL());
      underlying = WETH;
      bendPool.withdraw(WETH, type(uint256).max, address(this));
    }

    if (liquidation.collateralAsset.tokenType == TokenType.YAPE) {
      IAutoYieldApe yape = IAutoYieldApe(liquidation.collateralAsset.token);
      underlying = address(CONFIG.APE());
      yape.exit();
    }

    if (liquidation.collateralAsset.tokenType == TokenType.PARA_ZK_WETH) {
      IWETH paraZkWETH = IWETH(liquidation.collateralAsset.token);
      uint256 paraZkWETHBal = paraZkWETH.balanceOf(address(this));
      underlying = WETH;
      paraZkWETH.withdraw(paraZkWETHBal);
      // WETH: zk official WETH
      IWETH(WETH).deposit{ value: paraZkWETHBal }();
    }

    console.log("underlying", underlying);
    console.log("underlying bal", IERC20(underlying).balanceOf(address(this)));

    if (!isZeroAddress(swap.collateralToFlashLoan.router)) {
      uint256 amountNeeded = repayAmount - flashBalBefore;

      // swap underlying token to flashloan asset
      LiquidatorLib._swapExactTokensForTokens(underlying, IERC20(underlying).balanceOf(address(this)), amountNeeded, swap.collateralToFlashLoan);

      _transferToAdmin(underlying);
    }
  }

  /**
   * @dev multiple call `unstakeApePositionAndRepay`
   */
  function unstakeAndRepay(UnstakeAndRepayParams[] memory params) public onlyExecutor {
    for (uint256 i = 0; i < params.length; i++) {
      CONFIG.pool().unstakeApePositionAndRepay(params[i].nftAsset, params[i].tokenId);
    }
    _transferToAdmin(address(CONFIG.APE()));
  }

  /**
   * @dev check zero address
   */
  function isZeroAddress(address addr) internal pure returns (bool) {
    return addr == address(0);
  }
}
/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

interface IStargateLPStaking {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
            //
            // We do some fancy math here. Basically, any point in time, the amount of STGs
            // entitled to a user but is pending to be distributed is:
            //
            //   pending reward = (user.amount * pool.accStargatePerShare) - user.rewardDebt
            //
            // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
            //   1. The pool's `accStargatePerShare` (and `lastRewardBlock`) gets updated.
            //   2. User receives the pending reward sent to his/her address.
            //   3. User's `amount` gets updated.
            //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. STGs to distribute per block.
        uint256 lastRewardBlock; // Last block number that STGs distribution occurs.
        uint256 accStargatePerShare; // Accumulated STGs per share, times 1e12. See below.
    }

    function userInfo(uint256 _pid, address _owner) external view returns (UserInfo memory);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingStargate(uint256 _pid, address _user) external view returns (uint256);
}

interface IStargateRouter {
    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);
}

interface IStargatePool {
  function poolId() external view returns (uint256);
  function token() external view returns (address);
  function totalSupply() external view returns (uint256);
  function totalLiquidity() external view returns (uint256);
  function convertRate() external view returns (uint256);
  function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function approve(address recipient, uint256 amount) external;
}

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
/// https://eips.ethereum.org/EIPS/eip-4626
interface IERC4626 is IERC20 {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /// @notice Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
    /// @dev
    /// - MUST be an ERC-20 token contract.
    /// - MUST NOT revert.
    function asset() external view returns (address assetTokenAddress);

    /// @notice Returns the total amount of the underlying asset that is “managed” by Vault.
    /// @dev
    /// - SHOULD include any compounding that occurs from yield.
    /// - MUST be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT revert.
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /// @notice Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
    /// scenario where all the conditions are met.
    /// @dev
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
    /// - MUST NOT revert.
    ///
    /// NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
    /// “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
    /// from.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
    /// scenario where all the conditions are met.
    /// @dev
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
    /// - MUST NOT revert.
    ///
    /// NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
    /// “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
    /// from.
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
    /// through a deposit call.
    /// @dev
    /// - MUST return a limited value if receiver is subject to some deposit limit.
    /// - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
    /// - MUST NOT revert.
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
    /// current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
    ///   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
    ///   in the same transaction.
    /// - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
    ///   deposit would be accepted, regardless if the user has enough tokens approved, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by depositing.
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /// @notice Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
    /// @dev
    /// - MUST emit the Deposit event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
    ///   deposit execution, and are accounted for during deposit.
    /// - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
    ///   approving enough underlying tokens to the Vault contract, etc).
    ///
    /// NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
    /// @dev
    /// - MUST return a limited value if receiver is subject to some mint limit.
    /// - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
    /// - MUST NOT revert.
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
    /// current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
    ///   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
    ///   same transaction.
    /// - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
    ///   would be accepted, regardless if the user has enough tokens approved, etc.
    /// - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by minting.
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /// @notice Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
    /// @dev
    /// - MUST emit the Deposit event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
    ///   execution, and are accounted for during mint.
    /// - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
    ///   approving enough underlying tokens to the Vault contract, etc).
    ///
    /// NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /// @notice Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
    /// Vault, through a withdraw call.
    /// @dev
    /// - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
    ///   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
    ///   called
    ///   in the same transaction.
    /// - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
    ///   the withdrawal would be accepted, regardless if the user has enough shares, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by depositing.
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /// @notice Burns shares from owner and sends exactly assets of underlying tokens to receiver.
    /// @dev
    /// - MUST emit the Withdraw event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
    ///   withdraw execution, and are accounted for during withdraw.
    /// - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
    ///   not having enough shares, etc).
    ///
    /// Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
    /// Those methods should be performed separately.
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /// @notice Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
    /// through a redeem call.
    /// @dev
    /// - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
    /// - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
    /// - MUST NOT revert.
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    /// @dev
    /// - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
    ///   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
    ///   same transaction.
    /// - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
    ///   redemption would be accepted, regardless if the user has enough shares, etc.
    /// - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
    /// - MUST NOT revert.
    ///
    /// NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
    /// share price or some other type of condition, meaning the depositor will lose assets by redeeming.
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /// @notice Burns exactly shares from owner and sends assets of underlying tokens to receiver.
    /// @dev
    /// - MUST emit the Withdraw event.
    /// - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
    ///   redeem execution, and are accounted for during redeem.
    /// - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
    ///   not having enough shares, etc).
    ///
    /// NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
    /// Those methods should be performed separately.
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

interface IFeesController {
  event TreasuryUpdated(address nextTreasury);
  event FallbackTreasuryUpdated(address nextTreasury);
  event FeesUpdated(address indexed vault, string feeType, uint24 value);
  event FeesCollected(
    address indexed vault, string feeType, uint256 feeAmount, address asset
  );

  function getFeeBps(address vault, string memory feeType)
    external
    view
    returns (uint24 feeBps);

  function setFeeBps(address vault, string memory feeType, uint24 value) external;

  function previewFee(uint256 amount, string memory feeType)
    external
    view
    returns (uint256 feesAmount, uint256 restAmount);

  function collectFee(uint256 amount, string memory feeType)
    external
    returns (uint256 feesAmount, uint256 restAmount);
}

contract WithFees {
  IFeesController private controller;

  constructor(IFeesController feeController) {
    controller = feeController;
  }

  function feesController() public view returns (address) {
    return address(controller);
  }

  function payFees(uint256 amount, string memory feeType)
    public
    returns (uint256 feesAmount, uint256 restAmount)
  {
    return controller.collectFee(amount, feeType);
  }
}

contract FeesController is IFeesController, Owned {
  uint24 constant MAX_BPS = 10000; // 100
  uint24 constant MAX_FEE_BPS = 2500; // 25%

  // vault address => amount
  mapping(address => uint256) public feesCollected;
  // vault address => treasury => amount
  mapping(address => mapping(address => uint256)) public feesCollectedByTreasuries;
  // vault address => type => bps
  mapping(address => mapping(string => uint24)) public feesConfig;
  // vault address => treasury address, if address(0) then use fallback treasury
  mapping(address => address) internal _treasuries;

  address public fallbackTreasury;

  constructor(address fallbackTreasury_) Owned(msg.sender) {
    fallbackTreasury = fallbackTreasury_;
  }

  function treasury(address vault) public view returns (address) {
    address result = _treasuries[vault];
    return result != address(0) ? result : fallbackTreasury;
  }

  function getFeeBps(address vault, string memory feeType)
    public
    view
    returns (uint24 feeBps)
  {
    return feesConfig[vault][feeType];
  }

  function setFallbackTreasury(address nextTreasury) external onlyOwner {
    fallbackTreasury = nextTreasury;

    emit FallbackTreasuryUpdated(nextTreasury);
  }

  function setTreasury(address vault, address nextTreasury) external onlyOwner {
    _treasuries[vault] = nextTreasury;

    emit TreasuryUpdated(nextTreasury);
  }

  function setFeeBps(address vault, string memory feeType, uint24 value)
    external
    onlyOwner
  {
    require(value <= MAX_FEE_BPS, "Fee overflow, max 25%");
    feesConfig[vault][feeType] = value;

    emit FeesUpdated(vault, feeType, value);
  }

  function previewFee(uint256 amount, string memory feeType)
    public
    view
    returns (uint256 feesAmount, uint256 restAmount)
  {
    uint24 bps = feesConfig[msg.sender][feeType];
    if (amount > 0 && bps > 0) {
      feesAmount = amount * bps / MAX_BPS;
      return (feesAmount, amount - feesAmount);
    } else {
      return (0, amount);
    }
  }

  function collectFee(uint256 amount, string memory feeType)
    external
    returns (uint256 feesAmount, uint256 restAmount)
  {
    return _collectFee(msg.sender, amount, feeType);
  }

  function _collectFee(address vault, uint256 amount, string memory feeType)
    internal
    returns (uint256 feesAmount, uint256 restAmount)
  {
    (feesAmount, restAmount) = previewFee(amount, feeType);
    if (feesAmount == 0) {
      return (feesAmount, restAmount);
    }

    address asset = IERC4626(vault).asset();

    address treasury_ = treasury(vault);
    IERC20(asset).transferFrom(vault, treasury_, feesAmount);

    feesCollected[vault] += feesAmount;
    feesCollectedByTreasuries[vault][treasury_] += feesAmount;

    emit FeesCollected(vault, feeType, feesAmount, asset);
  }
}

interface ISwapper {
  function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
    external
    view
    returns (uint256 amountOut);

  function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
    external
    returns (uint256 amountOut);
}

/// @title Swapper
/// @notice Abstract base contract for deploying wrappers for AMMs
/// @dev
abstract contract Swapper is ISwapper {
  /// -----------------------------------------------------------------------
  /// Events
  /// -----------------------------------------------------------------------

  /// @notice Emitted when a new swap has been executed
  /// @param from The base asset
  /// @param to The quote asset
  /// @param amountIn amount that has been swapped
  /// @param amountOut received amount
  event Swap(
    address indexed sender,
    IERC20 indexed from,
    IERC20 indexed to,
    uint256 amountIn,
    uint256 amountOut
  );

  function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn)
    public
    view
    virtual
    returns (uint256 amountOut);

  function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn, uint256 minAmountOut)
    public
    virtual
    returns (uint256 amountOut);
}

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
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

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
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(ERC20 _asset, string memory _name, string memory _symbol) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

abstract contract ERC4626Controllable is ERC4626, Owned {
  /// @notice Maximum deposit limit
  uint256 public depositLimit;
  /// @notice Deposit status, used on emergency situation
  bool public canDeposit;
  /// @notice Admin address, preferably factory contract or multisig
  address public admin;

  /// @notice Used in reentrancy check.
  uint256 private locked = 1;
  /// @notice cached total amount.
  uint256 internal storedTotalAssets;
  /// @notice the maximum length of a rewards cycle
  uint256 public lockPeriod = 7 hours;
  /// @notice the amount of rewards distributed in a the most recent cycle.
  uint256 public lastUnlockedAssets;
  /// @notice the effective start of the current cycle
  uint256 public lastSync;
  /// @notice the end of the current cycle. Will always be evenly divisible by `rewardsCycleLength`.
  uint256 public unlockAt;

  mapping(address => uint256) public depositOf;
  mapping(address => uint256) public withdrawOf;

  event DepositUpdated(bool canDeposit);
  event DepositLimitUpdated(uint256 depositLimit);
  event MetadataUpdated(string name, string symbol);
  event LockPeriodUpdated(uint256 newLockPeriod);

  event Recovered(address token, uint256 amount);
  event Sync(uint256 unlockAt, uint256 amountWant);

  modifier nonReentrant() {
    require(locked == 1, "Non-reentrancy guard");
    locked = 2;
    _;
    locked = 1;
  }

  constructor(IERC20 asset_, string memory _name, string memory _symbol, address admin_)
    ERC4626(ERC20(address(asset_)), _name, _symbol)
    Owned(admin_)
  {
    depositLimit = 1e27;
    canDeposit = true;

    unlockAt = (block.timestamp / lockPeriod) * lockPeriod;
  }

  /////// Vault settings
  function setDepositLimit(uint256 depositLimit_) public onlyOwner {
    require(depositLimit_ >= totalAssets());
    depositLimit = depositLimit_;

    emit DepositLimitUpdated(depositLimit);
  }

  ///@dev very risky method, gives owner ability to transfer funds from vault
  // function setAllowance(IERC20 asset_, address receiver, uint256 approvedAmount)
  //   public
  //   onlyOwner
  // {
  //   asset_.approve(receiver, approvedAmount);
  // }

  function setMetadata(string memory name_, string memory symbol_) public onlyOwner {
    name = name_;
    symbol = symbol_;

    emit MetadataUpdated(name_, symbol_);
  }

  function setLockPeriod(uint256 _lockPeriod) public onlyOwner {
    lockPeriod = _lockPeriod;

    emit LockPeriodUpdated(lockPeriod);
  }

  function toggle() public onlyOwner {
    canDeposit = !canDeposit;

    emit DepositUpdated(canDeposit);
  }

  function sweep(address tokenAddress, uint256 tokenAmount) external onlyOwner {
    require(tokenAddress != address(asset), "Cannot withdraw the underlying token");
    IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

    emit Recovered(tokenAddress, tokenAmount);
  }

  function refundETH(address payable receiver, uint256 amount) external payable onlyOwner {
    (bool s,) = receiver.call{ value: amount }("");
    require(s, "ETH transfer failed");

    emit Recovered(address(0), amount);
  }

  /////////////////

  function totalAssets() public view override returns (uint256) {
    if (block.timestamp >= unlockAt) {
      return storedTotalAssets + lastUnlockedAssets;
    }

    ///@dev this is impossible, but in test environment everything is possible
    if (block.timestamp < unlockAt) {
      return storedTotalAssets;
    }

    uint256 unlockedAssets =
      (lastUnlockedAssets * (block.timestamp - lastSync)) / (unlockAt - lastSync);
    return storedTotalAssets + unlockedAssets;
  }

  function totalLiquidity() public view returns (uint256) {
    return _totalAssets();
  }

  function pnl(address user) public view returns (int256) {
    uint256 totalDeposited = depositOf[user];
    uint256 totalWithdraw = withdrawOf[user] + this.maxWithdraw(user);

    return int256(totalWithdraw) - int256(totalDeposited);
  }

  function sync() public virtual {
    require(block.timestamp >= unlockAt, "Error: rewards is still locked");

    uint256 lastTotalAssets = storedTotalAssets + lastUnlockedAssets;
    uint256 totalAssets_ = _totalAssets();

    require(totalAssets_ >= lastTotalAssets, "Error: vault have lose");

    uint256 nextUnlockedAssets = totalAssets_ - lastTotalAssets;
    uint256 end = ((block.timestamp + lockPeriod) / lockPeriod) * lockPeriod;

    storedTotalAssets += lastUnlockedAssets;
    lastUnlockedAssets = nextUnlockedAssets;
    lastSync = block.timestamp;
    unlockAt = end;

    emit Sync(end, nextUnlockedAssets);
  }

  ////////////////

  function _totalAssets() internal view virtual returns (uint256 assets);

  function beforeWithdraw(uint256 amount, uint256 shares)
    internal
    virtual
    override
    nonReentrant
  {
    super.beforeWithdraw(amount, shares);

    storedTotalAssets -= amount;
    withdrawOf[msg.sender] += amount;
  }

  function afterDeposit(uint256 amount, uint256 shares)
    internal
    virtual
    override
    nonReentrant
  {
    require(canDeposit, "Error: Vault is withdraw-only");
    storedTotalAssets += amount;
    depositOf[msg.sender] += amount;

    super.afterDeposit(amount, shares);
  }
}

interface IERC4626Compoundable {
  function setSwapper(ISwapper nextSwapper) external;
  function expectedReturns(uint256 timestamp) external view returns (uint256);

  function harvest(IERC20 reward, uint256 swapAmountOut)
    external
    returns (uint256, uint256);
  function tend() external returns (uint256, uint256);
}

abstract contract ERC4626Compoundable is IERC4626Compoundable, ERC4626Controllable {
  /// @notice Keeper EOA
  address public keeper;
  /// @notice Swapper contract
  ISwapper public swapper;
  /// @notice total earned amount, used only for expectedReturns()
  uint256 public totalGain;
  /// @notice timestamp of last tend() call
  uint256 public lastTend;
  /// @notice creation timestamp.
  uint256 public created;

  bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

  event Harvest(uint256 amountReward, uint256 amountWant);
  event Tend(uint256 amountWant, uint256 feesAmount);
  event SwapperUpdated(address newSwapper);
  event KeeperUpdated(address newKeeper);

  modifier onlyKeeper() {
    require(msg.sender == keeper, "Error: keeper only method");
    _;
  }

  constructor(
    IERC20 asset_,
    string memory _name,
    string memory _symbol,
    ISwapper swapper_,
    address admin_
  ) ERC4626Controllable(asset_, _name, _symbol, admin_) {
    swapper = swapper_;
    lastTend = block.timestamp;
    created = block.timestamp;
  }

  function setKeeper(address account) public onlyOwner {
    keeper = account;

    emit KeeperUpdated(account);
  }

  function setSwapper(ISwapper nextSwapper) public onlyOwner {
    swapper = nextSwapper;

    emit SwapperUpdated(address(swapper));
  }

  function expectedReturns(uint256 timestamp) public view virtual returns (uint256) {
    require(timestamp >= unlockAt, "Unexpected timestamp");

    if (lastTend > created) {
      return totalGain * (timestamp - lastTend) / (lastTend - created);
    } else {
      return 0;
    }
  }

  function harvest(IERC20 reward, uint256 swapAmountOut)
    public
    onlyKeeper
    returns (uint256 rewardAmount, uint256 wantAmount)
  {
    rewardAmount = _harvest(reward);

    if (rewardAmount > 0) {
      wantAmount =
        swapper.swap(reward, IERC20(address(asset)), rewardAmount, swapAmountOut);
    } else {
      wantAmount = 0;
    }

    emit Harvest(rewardAmount, wantAmount);
  }

  function tend() public onlyKeeper returns (uint256 wantAmount, uint256 feesAmount) {
    (wantAmount, feesAmount) = _tend();

    totalGain += wantAmount;
    lastTend = block.timestamp;

    emit Tend(wantAmount, feesAmount);
  }

  function harvestTend(IERC20 reward, uint256 swapAmountOut)
    public
    onlyKeeper
    returns (uint256 rewardAmount, uint256 wantAmount, uint256 feeAmount)
  {
    (rewardAmount,) = harvest(reward, swapAmountOut);
    (wantAmount, feeAmount) = tend();
  }

  function _harvest(IERC20 reward) internal virtual returns (uint256 rewardAmount);
  function _tend() internal virtual returns (uint256 wantAmount, uint256 feesAmount);
}

contract StargateVault is ERC4626Compoundable, WithFees {
  /// -----------------------------------------------------------------------
  /// Params
  /// -----------------------------------------------------------------------

  /// @notice The stargate bridge router contract
  IStargateRouter public stargateRouter;
  /// @notice The stargate bridge router contract
  IStargatePool public stargatePool;
  /// @notice The stargate lp staking contract
  IStargateLPStaking public stargateLPStaking;
  /// @notice The stargate pool staking id
  uint256 public poolStakingId;

  /// -----------------------------------------------------------------------
  /// Initialize
  /// -----------------------------------------------------------------------

  constructor(
    IERC20 asset_,
    IStargatePool pool_,
    IStargateRouter router_,
    IStargateLPStaking staking_,
    uint256 poolStakingId_,
    ISwapper swapper_,
    IFeesController feesController_,
    address owner_
  )
    ERC4626Compoundable(asset_, _vaultName(asset_), _vaultSymbol(asset_), swapper_, owner_)
    WithFees(feesController_)
  {
    stargatePool = pool_;
    stargateRouter = router_;
    stargateLPStaking = staking_;
    poolStakingId = poolStakingId_;

    stargatePool.approve(address(stargateRouter), type(uint256).max);
    asset.approve(address(stargateRouter), type(uint256).max);
    asset.approve(address(feesController_), type(uint256).max);
  }

  /// -----------------------------------------------------------------------
  /// ERC4626 overrides
  /// -----------------------------------------------------------------------

  function _totalAssets() internal view virtual override returns (uint256) {
    IStargateLPStaking.UserInfo memory info =
      stargateLPStaking.userInfo(poolStakingId, address(this));
    return stargatePool.amountLPtoLD(info.amount);
  }

  function deposit(uint256 assets, address receiver)
    public
    override
    returns (uint256 shares)
  {
    asset.transferFrom(msg.sender, address(this), assets);
    (, uint256 wantAmount) = payFees(assets, "deposit");
    asset.transfer(msg.sender, wantAmount);

    shares = super.deposit(wantAmount, receiver);
  }

  function mint(uint256 shares, address receiver)
    public
    override
    returns (uint256 assets)
  {
    uint256 assets_ = convertToAssets(shares);
    asset.transferFrom(msg.sender, address(this), assets_);
    (, uint256 wantAmount) = payFees(assets_, "deposit");
    asset.transfer(msg.sender, wantAmount);

    assets = super.mint(convertToShares(wantAmount), receiver);
  }

  function withdraw(uint256 assets, address receiver, address owner_)
    public
    override
    returns (uint256 shares)
  {
    shares = super.withdraw(assets, address(this), owner_);

    (, uint256 wantAmount) = payFees(assets, "withdraw");
    asset.transfer(receiver, wantAmount);
  }

  function redeem(uint256 shares, address receiver, address owner_)
    public
    override
    returns (uint256 assets)
  {
    assets = super.redeem(shares, address(this), owner_);

    (, uint256 wantAmount) = payFees(assets, "withdraw");
    asset.transfer(receiver, wantAmount);
  }

  function _harvest(IERC20 reward) internal override returns (uint256 rewardAmount) {
    stargateLPStaking.withdraw(poolStakingId, 0);

    rewardAmount = reward.balanceOf(address(this));
  }

  function _tend() internal override returns (uint256 wantAmount, uint256 feesAmount) {
    uint256 assets = asset.balanceOf(address(this));
    (feesAmount, wantAmount) = payFees(assets, "harvest");

    uint256 lpTokensBefore = stargatePool.balanceOf(address(this));

    stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

    uint256 lpTokensAfter = stargatePool.balanceOf(address(this));

    uint256 lpTokens = lpTokensAfter - lpTokensBefore;

    stargateLPStaking.deposit(poolStakingId, lpTokens);
  }

  function beforeWithdraw(uint256 assets, uint256 shares) internal override {
    /// -----------------------------------------------------------------------
    /// Withdraw assets from Stargate
    /// -----------------------------------------------------------------------
    // (, assets) = payFees(assets, "withdraw");
    super.beforeWithdraw(assets, shares);

    uint256 lpTokens = getStargateLP(assets);

    stargateLPStaking.withdraw(poolStakingId, lpTokens);

    stargateRouter.instantRedeemLocal(
      uint16(stargatePool.poolId()), lpTokens, address(this)
    );
  }

  function afterDeposit(uint256 assets, uint256 shares) internal virtual override {
    /// -----------------------------------------------------------------------
    /// Deposit assets into Stargate
    /// -----------------------------------------------------------------------
    // (, assets) = payFees(assets, "deposit");

    uint256 lpTokensBefore = stargatePool.balanceOf(address(this));

    stargateRouter.addLiquidity(stargatePool.poolId(), assets, address(this));

    uint256 lpTokensAfter = stargatePool.balanceOf(address(this));

    uint256 lpTokens = lpTokensAfter - lpTokensBefore;

    stargateLPStaking.deposit(poolStakingId, lpTokens);

    super.afterDeposit(assets, shares);
  }

  function maxDeposit(address) public view override returns (uint256) {
    if (totalAssets() >= depositLimit || !canDeposit) {
      return 0;
    }
    return depositLimit - totalAssets();
  }

  function maxMint(address) public view override returns (uint256) {
    if (totalAssets() >= depositLimit || !canDeposit) {
      return 0;
    }
    return convertToShares(depositLimit - totalAssets());
  }

  function maxWithdraw(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(stargatePool));

    uint256 assetsBalance = convertToAssets(this.balanceOf(owner_));

    return cash < assetsBalance ? cash : assetsBalance;
  }

  function maxRedeem(address owner_) public view override returns (uint256) {
    uint256 cash = asset.balanceOf(address(stargatePool));

    uint256 cashInShares = convertToShares(cash);

    uint256 shareBalance = this.balanceOf(owner_);

    return cashInShares < shareBalance ? cashInShares : shareBalance;
  }

  /// -----------------------------------------------------------------------
  /// Internal stargate fuctions
  /// -----------------------------------------------------------------------

  function getStargateLP(uint256 amount_) internal view returns (uint256 lpTokens) {
    if (amount_ == 0) {
      return 0;
    }
    uint256 totalSupply_ = stargatePool.totalSupply();
    uint256 totalLiquidity_ = stargatePool.totalLiquidity();
    uint256 convertRate = stargatePool.convertRate();

    require(totalLiquidity_ > 0, "Stargate: cant convert SDtoLP when totalLiq == 0");

    uint256 LDToSD = amount_ / convertRate;

    lpTokens = LDToSD * totalSupply_ / totalLiquidity_;
  }

  /// -----------------------------------------------------------------------
  /// ERC20 metadata generation
  /// -----------------------------------------------------------------------

  function _vaultName(IERC20 asset_) internal view returns (string memory vaultName) {
    vaultName = string.concat("Yasp Stargate Vault ", asset_.symbol());
  }

  function _vaultSymbol(IERC20 asset_) internal view returns (string memory vaultSymbol) {
    vaultSymbol = string.concat("ystg", asset_.symbol());
  }
}

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

/// @title ERC4626Factory
/// @notice Abstract base contract for deploying ERC4626 wrappers
/// @dev Uses CREATE2 deterministic deployment, so there can only be a single
/// vault for each asset.
abstract contract ERC4626Factory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @notice Emitted when a new ERC4626 vault has been created
    /// @param asset The base asset used by the vault
    /// @param vault The vault that was created
    event CreateERC4626(ERC20 indexed asset, ERC4626 vault);

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @notice Computes the address of a contract deployed by this factory using CREATE2, given
    /// the bytecode hash of the contract. Can also be used to predict addresses of contracts yet to
    /// be deployed.
    /// @dev Always uses bytes32(0) as the salt
    /// @param bytecodeHash The keccak256 hash of the creation code of the contract being deployed concatenated
    /// with the ABI-encoded constructor arguments.
    /// @return The address of the deployed contract
    function computeCreate2Address(bytes32 bytecodeHash) internal view virtual returns (address) {
        return keccak256(abi.encodePacked(bytes1(0xFF), address(this), bytes32(0), bytecodeHash))
            // Prefix:
            // Creator:
            // Salt:
            // Bytecode hash:
            .fromLast20Bytes(); // Convert the CREATE2 hash into an address.
    }
}

interface IStargateFactory {
    function getPool(uint256) external view returns (IStargatePool);
}

/// @title StargateVaultFactory
/// @notice Factory for creating StargateVault contracts
contract StargateVaultFactory is ERC4626Factory {
  /// -----------------------------------------------------------------------
  /// Errors
  /// -----------------------------------------------------------------------

  error StargateVaultFactory__PoolNonexistent();
  error StargateVaultFactory__StakingNonexistent();
  error StargateVaultFactory__Deprecated();

  /// @notice The stargate pool factory contract
  IStargateFactory public immutable stargateFactory;
  /// @notice The stargate bridge router contract
  IStargateRouter public immutable stargateRouter;
  /// @notice The stargate lp staking contract
  IStargateLPStaking public immutable stargateLPStaking;
  /// @notice Swapper contract
  ISwapper public immutable swapper;
  /// @notice fees controller
  FeesController public immutable feesController;

  address public admin;

  /// -----------------------------------------------------------------------
  /// Constructor
  /// -----------------------------------------------------------------------

  constructor(
    IStargateFactory factory_,
    IStargateRouter router_,
    IStargateLPStaking staking_,
    FeesController feesController_,
    ISwapper swapper_,
    address admin_
  ) {
    stargateFactory = factory_;
    stargateRouter = router_;
    stargateLPStaking = staking_;
    swapper = swapper_;
    feesController = feesController_;
    admin = admin_;
  }

  /// -----------------------------------------------------------------------
  /// External functions
  /// -----------------------------------------------------------------------
  function createERC4626(IERC20 asset, uint256 poolId, uint256 stakingId)
    external
    returns (ERC4626 vault)
  {
    IStargatePool pool = stargateFactory.getPool(poolId);
    require(address(asset) == pool.token(), "Error: invalid asset");
    
    IERC20 lpToken = IERC20(address(pool));

    if (lpToken != stargateLPStaking.poolInfo(stakingId).lpToken) {
      revert StargateVaultFactory__StakingNonexistent();
    }

    vault = new StargateVault{salt: bytes32(0)}(
          asset,
          pool,
          stargateRouter,
          stargateLPStaking,
          stakingId,
          swapper,
          feesController,
          admin
        );

    emit CreateERC4626(ERC20(address(asset)), vault);
  }

  function computeERC4626Address(IERC20 asset, uint256 poolId, uint256 stakingId)
    external
    view
    returns (ERC4626 vault)
  {
    IStargatePool pool = stargateFactory.getPool(poolId);

    require(asset == IERC20(pool.token()), "Error: invalid asset");

    IERC20 lpToken = IERC20(address(pool));

    if (lpToken != stargateLPStaking.poolInfo(stakingId).lpToken) {
      revert StargateVaultFactory__StakingNonexistent();
    }

    vault = ERC4626(
      computeCreate2Address(
        keccak256(
          abi.encodePacked(
            // Deployment bytecode:
            type(StargateVault).creationCode,
            // Constructor arguments:
            abi.encode(
              asset,
              pool,
              stargateRouter,
              stargateLPStaking,
              stakingId,
              swapper,
              feesController,
              admin
            )
          )
        )
      )
    );
  }
}
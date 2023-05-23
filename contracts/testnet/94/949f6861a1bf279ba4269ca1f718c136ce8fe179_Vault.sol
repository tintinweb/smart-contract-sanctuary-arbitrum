// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

/// @notice rysk shtuff
import { ILiquidityPool } from "./interfaces/ILiquidityPool.sol";
import { IOptionExchange } from "./interfaces/IOptionExchange.sol";
import { IOptionRegistry } from "./interfaces/IOptionRegistry.sol";
import { IAccounting } from "./interfaces/IAccounting.sol";
import { IController } from "./interfaces/IGammaInterface.sol";
import { IBeyondPricer } from "./interfaces/IBeyondPricer.sol";
import { Types } from "./libraries/Types.sol";

/// @notice High Order Market Making Vault (HOMM Vault)
contract Vault is ERC4626 {

    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        ERRORS                              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error LiquidityLocked();
    error InsufficientAmount();
    error OnlyFundOperator();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        STORAGE                             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice reserves
    uint256 public usdcReserves;
    uint256 public wethReserves;

    /// @notice operator
    address public fundOperator;

    /// @notice strategy contracts
    ILiquidityPool public liquidityPool;
    IOptionExchange public optionExchange;
    IOptionRegistry public optionRegistry;
    IBeyondPricer public beyondPricer;

    /// @notice Epoch Definition
    uint256 internal constant LIQUIDITY_LOCK_PERIOD = 6 days;
    uint256 internal constant LIQUIDITY_UNLOCK_PERIOD = 1 days;
    uint256 internal startEpoch;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     CONSTRUCTOR                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice constructor parameters | solmate ERC4626 implementation
    /// @param _asset underlying vault asset (USDC)
    /// @param _controller controller contract we need to call setOperator on to approve use of OptionExchange
    /// @param _optionExchange option exchange contract
    /// @param _optionRegistry option registry contract
    /// @param _liquityPool liquidity pool contract
    constructor(
        ERC20 _asset,
        IController _controller,
        address _optionExchange,
        address _optionRegistry,
        address _liquityPool)
        ERC4626(_asset, "HOMM Vault", "HOMM")
        {
        // set fund operator
        fundOperator = msg.sender;
        optionExchange = IOptionExchange(_optionExchange);
        optionRegistry = IOptionRegistry(_optionRegistry);
        liquidityPool = ILiquidityPool(_liquityPool);
        startEpoch = block.timestamp;
        // set optionExchange as operator in controller
        _controller.setOperator(address(optionExchange), true);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  EXTERNAL USER FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @notice deposit "assets" (USDC) into vault
     * @param assets amount of "assets" (USDC) to deposit
     * @param receiver address to send "shares" (HOMM) to
     */
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        if (this.isLocked()) revert LiquidityLocked();
        // deposit
        super.deposit(assets, receiver);
    }

    /**
     * @notice mint "shares" Vault shares (HOMM) to "receiver" by depositing "assets" (USDC) of underlying tokens.
     */
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        if (this.isLocked()) revert LiquidityLocked();
        // mint
        super.mint(shares, receiver);
    }

    /**
     * @notice withdraw "asset" from vault
     * @param assets amount of "asset" (USDC) to withdraw
     * @param receiver address to send "asset" (USDC) to
     * @param owner address of owner
     */
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        if (this.isLocked()) revert LiquidityLocked();
        // withdraw
        super.withdraw(assets, receiver, owner);
    }

    /**
     * @notice burn "shares" Vault shares (HOMM) from "owner" and sends "assets" (USDC) of underlying tokens to "receiver".
     */
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        if (this.isLocked()) revert LiquidityLocked();
        // burn
        super.redeem(shares, receiver, owner);
    }

    /**
     * @notice Returns the total amount of "assets" (USDC) held by this contract.
     */
    function totalAssets() public view override returns (uint256 assets) {
        return asset.balanceOf(address(this));
    }

    /**
     * @notice Returns true if deposits/withdraws are locked
     */
    function isLocked() external view returns (bool) {
        // compute # of epochs so far
        uint256 epochs = (block.timestamp - startEpoch) / (LIQUIDITY_LOCK_PERIOD + LIQUIDITY_UNLOCK_PERIOD);
        uint256 t0 = startEpoch + epochs * (LIQUIDITY_LOCK_PERIOD + LIQUIDITY_UNLOCK_PERIOD);
        return block.timestamp > t0 && block.timestamp <= t0 + LIQUIDITY_LOCK_PERIOD;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  FUND OPERATOR FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Liquidity Pool Functions ///////////////////////////

    /**
     * @notice deposit liquidity into Rysk liquidity pool
     * @param _amount amount of liquidity to deposit into Rysk Liq Pool (DHV)
     */
    function depositLiquidity(uint256 _amount) public returns (bool) {
        if (msg.sender != fundOperator) revert OnlyFundOperator();

        // deposit liquidity to liquidity pool
        return ILiquidityPool(liquidityPool).deposit(_amount);
    }

    /** 
     * @notice generate Rysk withdrawal reciept for share amount operator input
     * @param _shares amount of shares to withdraw from Rysk Liq Pool
     */
    function initiateWithdraw(uint256 _shares) public {
        if (msg.sender != fundOperator) revert OnlyFundOperator();

        // initiate withdraw liquidity from liquidity pool
        ILiquidityPool(liquidityPool).initiateWithdraw(_shares);
    }

    /**
     * @notice complete withdrawal from Rysk liquidity pool using existing withdrawal reciept
     * returns the withdrawalAmount (USDC received) and withdrawalReceipt
     */
    function completeWithdraw() public returns (
        uint256 withdrawalAmount, 
        uint256 withdrawalShares, 
        IAccounting.WithdrawalReceipt memory withdrawalReceipt) 
        {
        if (msg.sender != fundOperator) revert OnlyFundOperator();

        // complete withdraw liquidity from liquidity pool
        ILiquidityPool(liquidityPool).completeWithdraw();
    }

    /// @notice OptionExchange Functions ////////////////////////

    /** Struct specification for OperateProcedure

    struct OptionSeries {
        uint64 expiration;
        uint128 strike;
        bool isPut;
        address underlying;
        address strikeAsset;
        address collateral;
	}

    enum ActionType {
        Issue,
        BuyOption,
        SellOption,
        CloseOption
    }

    struct ActionArgs {
        ActionType actionType;
        address secondAddress;
        address asset;
        uint256 vaultId;
        uint256 amount;
        Types.OptionSeries optionSeries;
        uint256 acceptablePremium;
        bytes data;
    }

    enum OperationType {
        OPYN,
        RYSK
    }

    struct OperationProcedures {
        CombinedActions.OperationType operation;
        CombinedActions.ActionArgs[] operationQueue;
    }
    */
    
    /**
     * @notice trade options on Rysk
     * @param _operateProcedures array of operation procedures to execute on Rysk
     */
    function trade(IOptionExchange.OperationProcedures[] memory _operateProcedures) public {
        if (msg.sender != fundOperator) revert OnlyFundOperator();

        // make trade with capital within this contract
        IOptionExchange(optionExchange).operate(_operateProcedures);
    }

    /// @notice OptionRegistry ///////////////////////////////////

    /**
     * @notice redeem option series on Rysk
     * @param _series the address of the option token to be burnt and redeemed
     * @return amount of underlying asset amount returned
     */
    function redeemOptionTokens(address _series) public returns (uint256) {
        if (msg.sender != fundOperator) revert OnlyFundOperator();

        // redeem option tokens
        return IOptionRegistry(optionRegistry).redeem(_series);
    }

    /// @notice BeyondPricer ///////////////////////////////////

    function quoteOptionPrice(
        Types.OptionSeries memory _optionSeries,
        uint256 _amount,
        bool _isSell,
        int256 _netDhvExposure
    ) external view returns (uint256 totalPremium, int256 totalDelta, uint256 totalFees) {
        if (msg.sender != fundOperator) revert OnlyFundOperator();
        // get option price from BeyondPricer
        return IBeyondPricer(beyondPricer).quoteOptionPrice(_optionSeries, _amount, _isSell, _netDhvExposure);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

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
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
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

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
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

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

import { Types } from "../libraries/Types.sol";
import "./IOptionRegistry.sol";
import "./IAccounting.sol";
import "./IERC20.sol";

interface ILiquidityPool is IERC20 {
	///////////////////////////
	/// immutable variables ///
	///////////////////////////
	function strikeAsset() external view returns (address);

	function underlyingAsset() external view returns (address);

	function collateralAsset() external view returns (address);

	/////////////////////////
	/// dynamic variables ///
	/////////////////////////

	function collateralAllocated() external view returns (uint256);

	function ephemeralLiabilities() external view returns (int256);

	function ephemeralDelta() external view returns (int256);

	function depositEpoch() external view returns (uint256);

	function withdrawalEpoch() external view returns (uint256);

	function depositEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

	function withdrawalEpochPricePerShare(uint256 epoch) external view returns (uint256 price);

	function depositReceipts(address depositor)
		external
		view
		returns (IAccounting.DepositReceipt memory);

	function withdrawalReceipts(address withdrawer)
		external
		view
		returns (IAccounting.WithdrawalReceipt memory);

	function pendingDeposits() external view returns (uint256);

	function pendingWithdrawals() external view returns (uint256);

	function partitionedFunds() external view returns (uint256);

	/////////////////////////////////////
	/// governance settable variables ///
	/////////////////////////////////////

	function bufferPercentage() external view returns (uint256);

	function collateralCap() external view returns (uint256);

	/////////////////
	/// functions ///
	/////////////////

	function adjustVariables(uint256 collateralAmount, uint256 optionsValue, int256 delta, bool isSale) external;
	
	function handlerIssue(Types.OptionSeries memory optionSeries) external returns (address);

	function resetEphemeralValues() external;

	function rebalancePortfolioDelta(int256 delta, uint256 index) external;
	
	function getAssets() external view returns (uint256);

	function redeem(uint256) external returns (uint256);

	function deposit(uint256) external returns (bool);

	function initiateWithdraw(uint256) external;

	function completeWithdraw() external;

	function handlerWriteOption(
		Types.OptionSeries memory optionSeries,
		address seriesAddress,
		uint256 amount,
		IOptionRegistry optionRegistry,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256);

	function handlerBuybackOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		IOptionRegistry optionRegistry,
		address seriesAddress,
		uint256 premium,
		int256 delta,
		address seller
	) external returns (uint256);

	function handlerIssueAndWriteOption(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		uint256 premium,
		int256 delta,
		address recipient
	) external returns (uint256, address);

	function getPortfolioDelta() external view returns (int256);

	function quotePriceWithUtilizationGreeks(
		Types.OptionSeries memory optionSeries,
		uint256 amount,
		bool toBuy
	) external view returns (uint256 quote, int256 delta);

	function checkBuffer() external view returns (int256 bufferRemaining);

	function getBalance(address asset) external view returns (uint256);
}

pragma solidity ^0.8.19;

import { Types } from "../libraries/Types.sol";
import { CombinedActions } from "../libraries/CombinedActions.sol";

interface IOptionExchange {

    struct OperationProcedures {
        CombinedActions.OperationType operation;
        CombinedActions.ActionArgs[] operationQueue;
    }

    function operate(OperationProcedures[] memory _operationProcedures) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import { Types } from "../libraries/Types.sol";

interface IOptionRegistry {
	//////////////////////////////////////////////////////
	/// access-controlled state changing functionality ///
	//////////////////////////////////////////////////////

	function redeem(address _series) external returns (uint256);

	/**
	 * @notice Either retrieves the option token if it already exists, or deploy it
	 * @param  optionSeries option series to issue
	 * @return the address of the option
	 */
	function issue(Types.OptionSeries memory optionSeries) external returns (address);

	/**
	 * @notice Open an options contract using collateral from the liquidity pool
	 * @param  _series the address of the option token to be created
	 * @param  amount the amount of options to deploy
	 * @param  collateralAmount the collateral required for the option
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 * @return the amount of collateral taken from the liquidityPool
	 */
	function open(
		address _series,
		uint256 amount,
		uint256 collateralAmount
	) external returns (bool, uint256);

	/**
	 * @notice Close an options contract (oToken) before it has expired
	 * @param  _series the address of the option token to be burnt
	 * @param  amount the amount of options to burn
	 * @dev only callable by the liquidityPool
	 * @return if the transaction succeeded
	 */
	function close(address _series, uint256 amount) external returns (bool, uint256);

	/////////////////////////////////////////////
	/// external state changing functionality ///
	/////////////////////////////////////////////

	/**
	 * @notice Settle an options vault
	 * @param  _series the address of the option token to be burnt
	 * @return success if the transaction succeeded
	 * @return collatReturned the amount of collateral returned from the vault
	 * @return collatLost the amount of collateral used to pay ITM options on vault settle
	 * @return amountShort number of oTokens that the vault was short
	 * @dev callable by anyone but returns funds to the liquidityPool
	 */
	function settle(address _series)
		external
		returns (
			bool success,
			uint256 collatReturned,
			uint256 collatLost,
			uint256 amountShort
		);

	///////////////////////
	/// complex getters ///
	///////////////////////

	/**
	 * @notice Send collateral funds for an option to be minted
	 * @dev series.strike should be scaled by 1e8.
	 * @param  series details of the option series
	 * @param  amount amount of options to mint
	 * @return amount transferred
	 */
	function getCollateral(Types.OptionSeries memory series, uint256 amount)
		external
		view
		returns (uint256);

	/**
	 * @notice Retrieves the option token if it exists
	 * @param  underlying is the address of the underlying asset of the option
	 * @param  strikeAsset is the address of the collateral asset of the option
	 * @param  expiration is the expiry timestamp of the option
	 * @param  isPut the type of option
	 * @param  strike is the strike price of the option - 1e18 format
	 * @param  collateral is the address of the asset to collateralize the option with
	 * @return the address of the option
	 */
	function getOtoken(
		address underlying,
		address strikeAsset,
		uint256 expiration,
		bool isPut,
		uint256 strike,
		address collateral
	) external view returns (address);

	///////////////////////////
	/// non-complex getters ///
	///////////////////////////

	function getSeriesInfo(address series) external view returns (Types.OptionSeries memory);
	function getSeries(Types.OptionSeries memory _series) external view returns (address);
	function vaultIds(address series) external view returns (uint256);
	function addressBook() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;

/// @title Accounting contract to calculate the dhv token value and handle deposit/withdraw mechanics

interface IAccounting {
	struct DepositReceipt {
		uint128 epoch;
		uint128 amount; // collateral decimals
		uint256 unredeemedShares; // e18
	}

	struct WithdrawalReceipt {
		uint128 epoch;
		uint128 shares; // e18
	}

	/**
	 * @notice logic for adding liquidity to the options liquidity pool
	 * @param  depositor the address making the deposit
	 * @param  _amount amount of the collateral asset to deposit
	 * @return depositAmount the amount to deposit from the round
	 * @return unredeemedShares number of shares held in the deposit receipt that havent been redeemed
	 */
	function deposit(address depositor, uint256 _amount)
		external
		returns (uint256 depositAmount, uint256 unredeemedShares);

	/**
	 * @notice logic for allowing a user to redeem their shares from a previous epoch
	 * @param  redeemer the address making the deposit
	 * @param  shares amount of the collateral asset to deposit
	 * @return toRedeem the amount to actually redeem
	 * @return depositReceipt the updated deposit receipt after the redeem has completed
	 */
	function redeem(address redeemer, uint256 shares)
		external
		returns (uint256 toRedeem, DepositReceipt memory depositReceipt);

	/**
	 * @notice logic for accounting a user to initiate a withdraw request from the pool
	 * @param  withdrawer the address carrying out the withdrawal
	 * @param  shares the amount of shares to withdraw for
	 * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
	 */
	function initiateWithdraw(address withdrawer, uint256 shares)
		external
		returns (WithdrawalReceipt memory withdrawalReceipt);

	/**
	 * @notice logic for accounting a user to complete a withdrawal
	 * @param  withdrawer the address carrying out the withdrawal
	 * @return withdrawalAmount  the amount of collateral to withdraw
	 * @return withdrawalShares  the number of shares to withdraw
	 * @return withdrawalReceipt the new withdrawal receipt to pass to the liquidityPool
	 */
	function completeWithdraw(address withdrawer)
		external
		returns (
			uint256 withdrawalAmount,
			uint256 withdrawalShares,
			WithdrawalReceipt memory withdrawalReceipt
		);

	/**
	 * @notice execute the next epoch
	 * @param totalSupply  the total number of share tokens
	 * @param assets the amount of collateral assets
	 * @param liabilities the amount of liabilities of the pool
	 * @return newPricePerShareDeposit the price per share for deposits
	 * @return newPricePerShareWithdrawal the price per share for withdrawals
	 * @return sharesToMint the number of shares to mint this epoch
	 * @return totalWithdrawAmount the amount of collateral to set aside for partitioning
	 * @return amountNeeded the amount needed to reach the total withdraw amount if collateral balance of lp is insufficient
	 */
	function executeEpochCalculation(
		uint256 totalSupply,
		uint256 assets,
		int256 liabilities
	)
		external
		view
		returns (
			uint256 newPricePerShareDeposit,
			uint256 newPricePerShareWithdrawal,
			uint256 sharesToMint,
			uint256 totalWithdrawAmount,
			uint256 amountNeeded
		);

	/**
	 * @notice get the number of shares for a given amount
	 * @param _amount  the amount to convert to shares - assumed in collateral decimals
	 * @param assetPerShare the amount of assets received per share
	 * @return shares the number of shares based on the amount - assumed in e18
	 */
	function sharesForAmount(uint256 _amount, uint256 assetPerShare)
		external
		view
		returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library GammaTypes {
	// vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
	struct Vault {
		// addresses of oTokens a user has shorted (i.e. written) against this vault
		address[] shortOtokens;
		// addresses of oTokens a user has bought and deposited in this vault
		// user can be long oTokens without opening a vault (e.g. by buying on a DEX)
		// generally, long oTokens will be 'deposited' in vaults to act as collateral
		// in order to write oTokens against (i.e. in spreads)
		address[] longOtokens;
		// addresses of other ERC-20s a user has deposited as collateral in this vault
		address[] collateralAssets;
		// quantity of oTokens minted/written for each oToken address in shortOtokens
		uint256[] shortAmounts;
		// quantity of oTokens owned and held in the vault for each oToken address in longOtokens
		uint256[] longAmounts;
		// quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
		uint256[] collateralAmounts;
	}

	// vaultLiquidationDetails is a struct of 3 variables that store the series address, short amount liquidated and collateral transferred for
	// a given liquidation
	struct VaultLiquidationDetails {
		address series;
		uint128 shortAmount;
		uint128 collateralAmount;
	}
}

interface IOtoken {
	function underlyingAsset() external view returns (address);

	function strikeAsset() external view returns (address);

	function collateralAsset() external view returns (address);

	function strikePrice() external view returns (uint256);

	function expiryTimestamp() external view returns (uint256);

	function isPut() external view returns (bool);
}

interface IOtokenFactory {
	function getOtoken(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external view returns (address);

	function createOtoken(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external returns (address);

	function getTargetOtokenAddress(
		address _underlyingAsset,
		address _strikeAsset,
		address _collateralAsset,
		uint256 _strikePrice,
		uint256 _expiry,
		bool _isPut
	) external view returns (address);

	event OtokenCreated(
		address tokenAddress,
		address creator,
		address indexed underlying,
		address indexed strike,
		address indexed collateral,
		uint256 strikePrice,
		uint256 expiry,
		bool isPut
	);
}

interface IController {
	// possible actions that can be performed
	enum ActionType {
		OpenVault,
		MintShortOption,
		BurnShortOption,
		DepositLongOption,
		WithdrawLongOption,
		DepositCollateral,
		WithdrawCollateral,
		SettleVault,
		Redeem,
		Call,
		Liquidate
	}

	struct ActionArgs {
		// type of action that is being performed on the system
		ActionType actionType;
		// address of the account owner
		address owner;
		// address which we move assets from or to (depending on the action type)
		address secondAddress;
		// asset that is to be transfered
		address asset;
		// index of the vault that is to be modified (if any)
		uint256 vaultId;
		// amount of asset that is to be transfered
		uint256 amount;
		// each vault can hold multiple short / long / collateral assets
		// but we are restricting the scope to only 1 of each in this version
		// in future versions this would be the index of the short / long / collateral asset that needs to be modified
		uint256 index;
		// any other data that needs to be passed in for arbitrary function calls
		bytes data;
	}

	struct RedeemArgs {
		// address to which we pay out the oToken proceeds
		address receiver;
		// oToken that is to be redeemed
		address otoken;
		// amount of oTokens that is to be redeemed
		uint256 amount;
	}
	function setOperator(address _operator, bool _isOperator) external;
	
	function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

	function operate(ActionArgs[] calldata _actions) external;

	function getAccountVaultCounter(address owner) external view returns (uint256);

	function oracle() external view returns (address);

	function getVault(address _owner, uint256 _vaultId)
		external
		view
		returns (GammaTypes.Vault memory);

	function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

	function isOperator(address _owner, address _operator) external view returns (bool);
	
	function isSettlementAllowed(
		address _underlying,
		address _strike,
		address _collateral,
		uint256 _expiry
	) external view returns (bool);

	function clearVaultLiquidationDetails(uint256 _vaultId) external;

	function getVaultLiquidationDetails(address _owner, uint256 _vaultId)
		external
		view
		returns (
			address,
			uint256,
			uint256
		);
	
}

pragma solidity ^0.8.19;

import "../libraries/Types.sol";

interface IBeyondPricer {
    function quoteOptionPrice(
		Types.OptionSeries memory _optionSeries,
		uint256 _amount,
		bool isSell,
		int256 netDhvExposure
	) external view returns (uint256 totalPremium, int256 totalDelta, uint256 totalFees);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Types {
	struct OptionSeries {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		address underlying;
		address strikeAsset;
		address collateral;
	}
	struct PortfolioValues {
		int256 delta;
		int256 gamma;
		int256 vega;
		int256 theta;
		int256 callPutsValue;
		uint256 timestamp;
		uint256 spotPrice;
	}
	struct Option {
		uint64 expiration;
		uint128 strike;
		bool isPut;
		bool isBuyable;
		bool isSellable;
	}
	struct Order {
		OptionSeries optionSeries;
		uint256 amount;
		uint256 price;
		uint256 orderExpiry;
		address buyer;
		address seriesAddress;
		uint128 lowerSpotMovementRange;
		uint128 upperSpotMovementRange;
		bool isBuyBack;
	}
	// strike and expiry date range for options
	struct OptionParams {
		uint128 minCallStrikePrice;
		uint128 maxCallStrikePrice;
		uint128 minPutStrikePrice;
		uint128 maxPutStrikePrice;
		uint128 minExpiry;
		uint128 maxExpiry;
	}

	struct UtilizationState {
		uint256 totalOptionPrice; //e18
		int256 totalDelta; // e18
		uint256 collateralToAllocate; //collateral decimals
		uint256 utilizationBefore; // e18
		uint256 utilizationAfter; //e18
		uint256 utilizationPrice; //e18
		bool isDecreased;
		uint256 deltaTiltAmount; //e18
		uint256 underlyingPrice; // strike asset decimals
		uint256 iv; // e18
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.4;

import "./Types.sol";
import "./RyskActions.sol";
import { IController } from "../interfaces/IGammaInterface.sol";

library CombinedActions {

	enum OperationType {
		OPYN,
		RYSK
	}

	struct OperationProcedures {
		OperationType operation;
		CombinedActions.ActionArgs[] operationQueue;
	}

    struct ActionArgs {
        // type of action that is being performed on the system
        uint256 actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // option series (if any)
        Types.OptionSeries optionSeries;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // OR for rysk actions it is the acceptable premium (if option is being sold to the dhv then the actual premium should be more than this number (i.e. max price),
        // if option is being bought from the dhv then the actual premium should be less than this number (i.e. max price))
        uint256 indexOrAcceptablePremium;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an opyn action
     * @param _args general action arguments structure
     * @return arguments for an opyn action
     */
    function _parseOpynArgs(ActionArgs memory _args) internal pure returns (IController.ActionArgs memory) {
        return IController.ActionArgs({
            actionType: IController.ActionType(_args.actionType),
            owner: _args.owner,
            secondAddress: _args.secondAddress,
            asset: _args.asset,
            vaultId: _args.vaultId,
            amount: _args.amount,
            index: _args.indexOrAcceptablePremium,
            data: _args.data
        });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an opyn action
     * @param _args general action arguments structure
     * @return arguments for an opyn action
     */
    function _parseRyskArgs(ActionArgs memory _args) internal pure returns (RyskActions.ActionArgs memory) {
        return RyskActions.ActionArgs({
            actionType: RyskActions.ActionType(_args.actionType),
            secondAddress: _args.secondAddress,
            asset: _args.asset,
            vaultId: _args.vaultId,
            amount: _args.amount,
            optionSeries: _args.optionSeries,
            acceptablePremium: _args.indexOrAcceptablePremium,
            data: _args.data
        });
    }

}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.4;

import "./Types.sol";

/**
 * @title Actions
 * @author Rysk Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 * errorCode
 * A1 can only parse arguments for create otoken actions
 * A2 can only parse arguments for issue actions
 * A3 can only parse arguments for buy option actions
 * A4 can only parse arguments for sell option or close option actions
 */
library RyskActions {
    // possible actions that can be performed
    enum ActionType {
        Issue,
        BuyOption,
        SellOption,
        CloseOption
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // option series (if any)
        Types.OptionSeries optionSeries;
        // acceptable premium (if option is being sold to the dhv then the actual premium should be more than this number (i.e. max price),
        // if option is being bought from the dhv then the actual premium should be less than this number (i.e. max price))
        uint256 acceptablePremium;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct IssueArgs {
        // option series 
        Types.OptionSeries optionSeries;
    }

    struct BuyOptionArgs {
        // option series
        Types.OptionSeries optionSeries;
        // series address
        address seriesAddress;
        // amount of options to buy, always in e18
        uint256 amount;
        // recipient of the options
        address recipient;
        // acceptable premium for the trade, the actual premium must be smaller than this number
        uint256 acceptablePremium;
    }

    struct SellOptionArgs {
        // option series
        Types.OptionSeries optionSeries;
        // series address
        address seriesAddress;
        // vault id
        uint256 vaultId;
        // amount of options to sell, always in e18
        uint256 amount;
        // recipient of premium
        address recipient;
        // acceptable premium for the trade, the actual premium must be bigger than this number
        uint256 acceptablePremium;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an issue action
     * @param _args general action arguments structure
     * @return arguments for an issue action
     */
    function _parseIssueArgs(ActionArgs memory _args) internal pure returns (IssueArgs memory) {
        require(_args.actionType == ActionType.Issue, "A2");
        return IssueArgs({optionSeries: _args.optionSeries});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a buy option action
     * @param _args general action arguments structure
     * @return arguments for a buy option action
     */
    function _parseBuyOptionArgs(ActionArgs memory _args) internal pure returns (BuyOptionArgs memory) {
        require(_args.actionType == ActionType.BuyOption, "A3");
        return
            BuyOptionArgs({
                optionSeries: _args.optionSeries,
                seriesAddress: _args.asset,
                amount: _args.amount,
                recipient: _args.secondAddress,
                acceptablePremium: _args.acceptablePremium
            });
    }


    /**
     * @notice parses the passed in action arguments to get the arguments for a sell option action
     * @param _args general action arguments structure
     * @return arguments for a sell option action
     */
    function _parseSellOptionArgs(ActionArgs memory _args) internal pure returns (SellOptionArgs memory) {
        require(_args.actionType == ActionType.SellOption || _args.actionType == ActionType.CloseOption, "A4");
        return
            SellOptionArgs({
                optionSeries: _args.optionSeries,
                seriesAddress: _args.asset,
                vaultId: _args.vaultId,
                amount: _args.amount,
                recipient: _args.secondAddress,
                acceptablePremium: _args.acceptablePremium
            });
    }

}
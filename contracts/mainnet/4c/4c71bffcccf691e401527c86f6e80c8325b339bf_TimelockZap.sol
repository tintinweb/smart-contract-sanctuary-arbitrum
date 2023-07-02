// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {TimelockBoost} from "./TimelockBoostToken.sol";
import {AssetVault} from "../vaults/AssetVault.sol";
import {Whitelist} from "./Whitelist.sol";
import {AggregateVault} from "../vaults/AggregateVault.sol";

/**
 * @title TimelockZap
 * @author Umami DAO
 * @notice A contract that enables users to easily deposit and withdraw assets from vaults with timelock boost.
 * @dev The TimelockZap contract simplifies the process of depositing and withdrawing assets from vaults with timelock boost.
 */
contract TimelockZap {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for ERC4626;

    /// @notice A struct containing the configuration for a vault with its associated asset and timelock.
    struct VaultConfig {
        address assetVault;
        address timelock;
    }
    /// @notice A mapping that stores the configuration for each input token.
    /// @dev input token => VaultConfig
    mapping(address => VaultConfig) public vaultConfig;
    Whitelist public immutable whitelist;
    AggregateVault public immutable aggregateVault;

    constructor(
        address[5] memory _inputs,
        VaultConfig[5] memory _vaultConfigs,
        address _aggregateVault,
        address _whitelist
    ) {
        vaultConfig[_inputs[0]] = _vaultConfigs[0];
        vaultConfig[_inputs[1]] = _vaultConfigs[1];
        vaultConfig[_inputs[2]] = _vaultConfigs[2];
        vaultConfig[_inputs[3]] = _vaultConfigs[3];
        vaultConfig[_inputs[4]] = _vaultConfigs[4];
        whitelist = Whitelist(_whitelist);
        aggregateVault = AggregateVault(payable(_aggregateVault));
    }

    /**
     * @notice Deposits assets into the associated vault and timelock.
     * @param assets The amount of assets to be deposited.
     * @param receiver The address that will receive the shares.
     * @param asset The address of the asset to be deposited.
     */
    function zapIn(uint256 assets, address receiver, address asset) external whenWhitelistDisabled returns (uint _vaultShares, uint _timelockedShares) {
        VaultConfig memory config = vaultConfig[asset];
        require(config.assetVault != address(0), "TimelockZap: invalid asset");
        require(address(ERC4626(config.assetVault).asset()) == asset, "TimelockZap: invalid asset");
        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
        ERC20(asset).safeApprove(config.assetVault, assets);
        _vaultShares = ERC4626(config.assetVault).deposit(assets, address(this));
        ERC4626(config.assetVault).safeApprove(config.timelock, _vaultShares);
        _timelockedShares = ERC4626(config.timelock).deposit(_vaultShares, receiver);
    }

    /**
     * @notice Deposits assets into the associated vault and timelock.
     * @param assets The amount of assets to be deposited.
     * @param receiver The address that will receive the shares.
     * @param asset The address of the asset to be deposited.
     */
    function whitelistZapIn(
        uint assets,
        address receiver,
        address asset,
        bytes32[] calldata proof
    ) external whenWhitelistEnabled returns (uint _vaultShares, uint _timelockedShares) {
        VaultConfig memory config = vaultConfig[asset];
        require(config.assetVault != address(0), "TimelockZap: invalid asset");
        require(
            address(ERC4626(config.assetVault).asset()) == asset,
            "TimelockZap: invalid asset"
        );
        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        // account for the deposit limit and whitelist
        if (whitelist.isWhitelistedPriority(asset, msg.sender))
            whitelist.whitelistDeposit(asset, msg.sender, assets);
        else whitelist.whitelistDepositMerkle(asset, msg.sender, assets, proof);

        ERC20(asset).safeApprove(config.assetVault, assets);
        bytes32[] memory emptyProof = new bytes32[](0);
        _vaultShares = AssetVault(config.assetVault).whitelistDeposit(
            assets,
            address(this),
            emptyProof
        );
        ERC4626(config.assetVault).safeApprove(config.timelock, _vaultShares);
        _timelockedShares = ERC4626(config.timelock).deposit(_vaultShares, receiver);
    }

    /**
     * @notice Withdraws assets from the associated vault and timelock.
     * @param receiver The address that will receive the withdrawn assets.
     * @param asset The address of the asset to be withdrawn.
     */
    function zapOut(address receiver, address asset) external {
        VaultConfig memory config = vaultConfig[asset];
        require(config.assetVault != address(0), "TimelockZap: invalid asset");
        uint shares = TimelockBoost(config.timelock).claimWithdrawalsFor(
            msg.sender,
            address(this)
        );
        ERC4626(config.assetVault).redeem(shares, receiver, address(this));
    }

    modifier whenWhitelistEnabled() {
        require(aggregateVault.whitelistEnabled(), "TimelockZap: whitelist not enabled");
        _;
    }

    modifier whenWhitelistDisabled() {
        require(!aggregateVault.whitelistEnabled(), "TimelockZap: whitelist not disabled");
        _;
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ShareMath} from "../libraries/ShareMath.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IAggregateVault} from "../interfaces/IAggregateVault.sol";
import {GlobalACL, Auth} from "../Auth.sol";

/// @title TimelockBoost
/// @author Umami DAO
/// @notice ERC4626 implementation for boosted vault tokens
contract TimelockBoost is ERC4626, Pausable, GlobalACL {
    using SafeTransferLib for ERC20;

    // STORAGE
    // ------------------------------------------------------------------------------------------

    /// @dev maximum number of queued withdrawals at once
    uint256 constant LOCK_QUEUE_LIMIT = 5;
    /// @dev the zap contract to allow users to deposit in one action
    address public ZAP;

    struct QueuedWithdrawal {
        uint256 queuedTimestamp;
        uint256 underlyingAmount;
    }

    struct TokenLockState {
        uint256 withdrawDuration;
        uint256 activeWithdrawBalance;
    }

    /// @dev state of the locking contract
    TokenLockState public lockState;

    /// @dev account => uint
    mapping(address => uint8) public activeWithdrawals;

    /// @dev account => QueuedWithdrawal[]
    mapping(address => QueuedWithdrawal[LOCK_QUEUE_LIMIT]) public withdrawalQueue;

    // EVENTS
    // ------------------------------------------------------------------------------------------

    event Deposit(address indexed _asset, address _account, uint256 _amount);
    event WithdrawInitiated(address indexed _asset, address _account, uint256 _amount, uint256 _duration);
    event WithdrawComplete(address indexed _asset, address _account, uint256 _amount);

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint256 _withdrawDuration,
        Auth _auth) 
        ERC4626(_asset, _name, _symbol) GlobalACL(_auth) {
            lockState.withdrawDuration = _withdrawDuration;
        }

    // DEPOSIT & WITHDRAW
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Deposit assets and mint corresponding shares for the receiver.
     * @param assets The amount of assets to be deposited.
     * @param receiver The address that will receive the shares.
     * @return shares The number of shares minted for the deposited assets.
     */
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Mint a specified amount of shares and deposit the corresponding amount of assets to the receiver
     * @param shares The amount of shares to mint
     * @param receiver The address to receive the deposited assets
     * @return assets The amount of assets deposited for the minted shares
     */
    function mint(uint256 shares, address receiver) public override whenNotPaused returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Initiate a withdrawal of the specified amount of assets.
     * @param _assets The amount of assets to withdraw.
     * @return shares The number of shares burned for the withdrawn assets.
     */
    function initiateWithdraw(
        uint256 _assets
    ) external whenNotPaused returns (uint256 shares) {
        shares = convertToShares(_assets);
        _initiateWithdrawShares(shares, _assets);
    }

    /**
     * @notice Initiate a withdrawal of the specified amount of shares.
     * @param _shares The amount of shares to withdraw.
     * @return _assets The number of assets withdrawn for given shares.
     */
    function initiateRedeem(uint _shares) external whenNotPaused returns (uint _assets) {
        _assets = convertToAssets(_shares);
        _initiateWithdrawShares(_shares, _assets);
    }

    /**
     * @notice Claim all available withdrawals for the sender.
     * @param _receiver The address that will receive the withdrawn assets.
     * @return _totalWithdraw The total amount of assets withdrawn.
     */
    function claimWithdrawals(address _receiver) external whenNotPaused returns (uint256 _totalWithdraw) {
        require(activeWithdrawals[msg.sender] > 0, "TimelockBoost: !activeWithdrawals");
        QueuedWithdrawal[LOCK_QUEUE_LIMIT] storage accountWithdrawals = withdrawalQueue[msg.sender];
        uint withdrawAmount;
        for (uint i = 0; i < LOCK_QUEUE_LIMIT; i++) {
            if (accountWithdrawals[i].queuedTimestamp + lockState.withdrawDuration < block.timestamp && accountWithdrawals[i].queuedTimestamp != 0) {
                withdrawAmount = _removeWithdrawForAccount(msg.sender, i);
                _decrementActiveWithdraws(msg.sender, withdrawAmount);
                _totalWithdraw += withdrawAmount;
            }
        }
        if (_totalWithdraw > 0) {
            asset.safeTransfer(_receiver, _totalWithdraw);
        }
        emit WithdrawComplete(address(asset), msg.sender, _totalWithdraw);
    }

    /**
     * @notice Claim all available withdrawals for the sender. Only used for Zap
     * @param _receiver The address that will receive the withdrawn assets.
     * @return _totalWithdraw The total amount of assets withdrawn.
     */
    function claimWithdrawalsFor(address _account, address _receiver) external whenNotPaused onlyZap returns (uint256 _totalWithdraw) {
        require(activeWithdrawals[_account] > 0, "TimelockBoost: !activeWithdrawals");
        QueuedWithdrawal[LOCK_QUEUE_LIMIT] storage accountWithdrawals = withdrawalQueue[_account];
        uint withdrawAmount;
        for (uint i = 0; i < LOCK_QUEUE_LIMIT; i++) {
            if (accountWithdrawals[i].queuedTimestamp + lockState.withdrawDuration < block.timestamp && accountWithdrawals[i].queuedTimestamp != 0) {
                withdrawAmount = _removeWithdrawForAccount(_account, i);
                _decrementActiveWithdraws(_account, withdrawAmount);
                _totalWithdraw += withdrawAmount;
            }
        }
        if (_totalWithdraw > 0) {
            asset.safeTransfer(_receiver, _totalWithdraw);
        }
        emit WithdrawComplete(address(asset), _account, _totalWithdraw);
    }


    // MATH
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the total assets
     */
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)) - lockState.activeWithdrawBalance;
    }

    /**
     * @notice Calculate the current price per share (PPS) of the token.
     * @return pricePerShare The current price per share.
     */
    function pps() public view returns (uint256 pricePerShare) {
        uint256 supply = totalSupply; 
        return supply == 0 ? 10 ** decimals : (totalAssets() * 10 ** decimals) / supply;
    }

    /**
     * @notice Convert a specified amount of assets to shares
     * @param _assets The amount of assets to convert
     * @return - The amount of shares corresponding to the given assets
     */
    function convertToShares(uint256 _assets) public view override returns (uint256) {
        uint256 supply = totalSupply; 
        return supply == 0 ? _assets : ShareMath.assetToShares(_assets, pps(), decimals);
    }

    /**
     * @notice Convert a specified amount of shares to assets
     * @param _shares The amount of shares to convert
     * @return - The amount of assets corresponding to the given shares
     */
    function convertToAssets(uint256 _shares) public view override returns (uint256) {
        uint256 supply = totalSupply; 
        return supply == 0 ? _shares : ShareMath.sharesToAsset(_shares, pps(), decimals);
    }

    /**
     * @notice Preview the amount of shares for a given deposit amount
     * @param _assets The amount of assets to deposit
     * @return - The amount of shares for the given deposit amount
     */
    function previewDeposit(uint256 _assets) public view override returns (uint256) {
        return convertToShares(_assets);
    }

    /**
     * @notice Preview the amount of assets for a given mint amount
     * @param _shares The amount of shares to mint
     * @return _mintAmount The amount of assets for the given mint amount
     */
    function previewMint(uint256 _shares) public view override returns (uint256 _mintAmount) {
        uint256 supply = totalSupply; 
        _mintAmount = supply == 0 ? _shares : ShareMath.sharesToAsset(_shares, pps(), decimals);
    }

    /**
     * @notice Preview the amount of shares for a given withdrawal amount
     * @param _assets The amount of assets to withdraw
     * @return _withdrawAmount The amount of shares for the given withdrawal amount
     */
    function previewWithdraw(uint256 _assets) public view override returns (uint256 _withdrawAmount) {
        uint256 supply = totalSupply; 
        _withdrawAmount = supply == 0 ? _assets : ShareMath.assetToShares(_assets, pps(), decimals);
    }

    /**
     * @notice Returns an array of withdrawal requests for an account
     * @param _account The account
     * @return _array An array of withdrawal requests
     */
    function withdrawRequests(address _account) public view returns (QueuedWithdrawal[LOCK_QUEUE_LIMIT] memory) {
        QueuedWithdrawal[LOCK_QUEUE_LIMIT] memory accountWithdrawals = withdrawalQueue[_account];
        return accountWithdrawals;
    }

    /**
     * @notice Returns a struct for the locked state. To be used by contracts.
     * @return state Locked state struct
     */
    function getLockState() external view returns (TokenLockState memory state) {
        return lockState;
    }

    /**
     * @notice Returns a underlying token balance for a user
     * @return _underlyingBalance The users underlying balance
     */
    function underlyingBalance(address _account) external view returns (uint256 _underlyingBalance) {
        return convertToAssets(balanceOf[_account]);
    }


    // DEPOSIT & WITHDRAW LIMIT
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the maximum deposit amount for an address
     * @dev _address The address to check the maximum deposit amount for
     * @dev returns the maximum deposit amount for the given address
     */
    function maxDeposit(address) public view override returns (uint256) {
        return asset.totalSupply();
    }

    /**
     * @notice Get the maximum mint amount for an address
     */
    function maxMint(address) public view override returns (uint256) {
        return convertToShares(asset.totalSupply());
    }

    /**
     * @notice Get the maximum withdrawal amount for an address
     * @param owner The address to check the maximum withdrawal amount for
     * @return The maximum withdrawal amount for the given address
     */
    function maxWithdraw(address owner) public view override returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }


    // INTERNAL
    // ------------------------------------------------------------------------------------------

    function _initiateWithdrawShares(uint _shares, uint _assets) internal {
        require(activeWithdrawals[msg.sender] < LOCK_QUEUE_LIMIT, "TimelockBoost: > LOCK_QUEUE_LIMIT");

        _incrementActiveWithdraws(msg.sender, _assets);

        _addWithdrawForAccount(msg.sender, _assets);

        _burn(msg.sender, _shares);

        emit WithdrawInitiated(address(asset), msg.sender, _assets, lockState.withdrawDuration);
    }

    /**
     * @notice Increment the active withdrawal count and balance for the specified account.
     * @param _account The address of the account.
     * @param _assets The amount of assets to increment the active withdrawal balance.
     */
    function _incrementActiveWithdraws(address _account, uint256 _assets) internal {
        lockState.activeWithdrawBalance += _assets;
        activeWithdrawals[_account] += 1;
        require(activeWithdrawals[_account] <= LOCK_QUEUE_LIMIT, "TimelockBoost: !activeWithdrawalsLength");
    }

    /**
     * @notice Decrement the active withdrawal count and balance for the specified account.
     * @param _account The address of the account.
     * @param _assets The amount of assets to decrement the active withdrawal balance.
     */
    function _decrementActiveWithdraws(address _account, uint256 _assets) internal {
        lockState.activeWithdrawBalance -= _assets;
        activeWithdrawals[_account] -= 1;
    }

    /**
     * @notice Add a new withdrawal for the specified account.
     * @param _account The address of the account.
     * @param _assets The amount of assets to be added to the withdrawal queue.
     */
    function _addWithdrawForAccount(address _account, uint256 _assets) internal {
        QueuedWithdrawal[LOCK_QUEUE_LIMIT] storage accountWithdrawals = withdrawalQueue[_account];
        for (uint i = 0; i < LOCK_QUEUE_LIMIT; i++) {
            if (accountWithdrawals[i].queuedTimestamp == 0) {
                accountWithdrawals[i].queuedTimestamp = block.timestamp;
                accountWithdrawals[i].underlyingAmount = _assets;
                return;
            }
        }
    }

    /**
     * @notice Remove a withdrawal from the queue for the specified account.
     * @param _account The address of the account.
     * @param _index The index of the withdrawal to be removed.
     * @return underlyingAmount The amount of assets that were associated with the removed withdrawal.
     */
    function _removeWithdrawForAccount(address _account, uint256 _index) internal returns (uint256 underlyingAmount) {
        QueuedWithdrawal[LOCK_QUEUE_LIMIT] storage accountWithdrawals = withdrawalQueue[_account];
        require(accountWithdrawals[_index].queuedTimestamp + lockState.withdrawDuration < block.timestamp, "TimelockBoost: !withdrawalDuration");
        underlyingAmount = accountWithdrawals[_index].underlyingAmount;
        delete accountWithdrawals[_index];
    }

    // CONFIG
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Set the Zap contract address.
     * @dev Can only be called by configurator.
     * @param _zap The address of the Zap contract.
     */
    function setZap(address _zap) external onlyConfigurator {
        require(_zap != address(0), "TimelockBoost: ZAP set");
        ZAP = _zap;
    }

    /**
     * @notice Set the withdrawal duration for the contract.
     * @param _withdrawalDuration The new withdrawal duration in seconds.
     */
    function setWithdrawalDuration(uint256 _withdrawalDuration) external onlyConfigurator {
        lockState.withdrawDuration = _withdrawalDuration;
    }

    /**
     * @notice Pause deposit and withdrawal functionalities of the contract.
     */
    function pauseDepositWithdraw() external onlyConfigurator {
        _pause();
    }

    /**
     * @notice Pause deposit and withdrawal functionalities of the contract.
     */
    function unpauseDepositWithdraw() external onlyConfigurator {
        _unpause();
    }

    // MODIFIERS
    // ------------------------------------------------------------------------------------------

    /**
     * @dev Modifier to ensure that the caller is the Zap contract.
     */
    modifier onlyZap() {
        require(msg.sender == ZAP, "TimelockBoost: !ZAP");
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ShareMath} from "../libraries/ShareMath.sol";

import {IAggregateVault} from "../interfaces/IAggregateVault.sol";
import {AggregateVault} from "./AggregateVault.sol";
import {GlobalACL} from "../Auth.sol";
import {PausableVault} from "../PausableVault.sol";

/// @title AssetVault
/// @author Umami DAO
/// @notice ERC4626 implementation for vault receipt tokens
contract AssetVault is ERC4626, PausableVault, GlobalACL {
    using SafeTransferLib for ERC20;

    /// @dev the aggregate vault for the strategy
    AggregateVault public aggregateVault;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _aggregateVault) 
        ERC4626(_asset, _name, _symbol) GlobalACL(AggregateVault(payable(_aggregateVault)).AUTH()) {
            aggregateVault = AggregateVault(payable(_aggregateVault));
    }

    // DEPOSIT & WITHDRAW
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Deposit a specified amount of assets and mint corresponding shares to the receiver
     * @param assets The amount of assets to deposit
     * @param receiver The address to receive the minted shares
     * @return shares The amount of shares minted for the deposited assets
     */
    function deposit(uint256 assets, address receiver) public override whitelistDisabled whenDepositNotPaused returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        require(tvl() + assets <= previewVaultCap(), "AssetVault: over vault cap");
        // lock in pps before deposit handling
        uint depositPPS = pps();
        // Transfer assets to aggregate vault, transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(aggregateVault), assets);
        assets = aggregateVault.handleDeposit(asset, assets, msg.sender);

        shares = ShareMath.assetToShares(assets, depositPPS, decimals);
        _mint(receiver,  shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    /**
     * @notice Mint a specified amount of shares and deposit the corresponding amount of assets to the receiver
     * @param shares The amount of shares to mint
     * @param receiver The address to receive the deposited assets
     * @return assets The amount of assets deposited for the minted shares
     */
    function mint(uint256 shares, address receiver) public override whitelistDisabled whenDepositNotPaused returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.
        require(tvl() + assets <= previewVaultCap(), "AssetVault: over vault cap");
        // lock in pps before deposit handling
        uint depositPPS = pps();
        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(aggregateVault), assets);
        assets = aggregateVault.handleDeposit(asset, assets, receiver);

        shares = ShareMath.assetToShares(assets, depositPPS, decimals);
        _mint(receiver,  shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    /**
     * @notice Withdraw a specified amount of assets by burning corresponding shares from the owner
     * @param assets The amount of assets to withdraw
     * @param receiver The address to receive the withdrawn assets
     * @param owner The address of the share owner
     * @return shares The amount of shares burned for the withdrawn assets
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenWithdrawalNotPaused returns (uint256 shares) {
        assets += previewWithdrawalFee(assets);
        shares = ShareMath.assetToShares(assets, pps(), decimals);
        require(shares > 0, "AssetVault: !shares > 0");
        if (msg.sender != owner) {
            _checkAllowance(owner, shares);
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        assets = aggregateVault.handleWithdraw(asset, assets, receiver);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @notice Redeem a specified amount of shares by burning them and transferring the corresponding amount of assets to the receiver
     * @param shares The amount of shares to redeem
     * @param receiver The address to receive the corresponding assets
     * @param owner The address of the share owner
     * @return assets The amount of assets transferred for the redeemed shares
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override whenWithdrawalNotPaused returns (uint256 assets) {
        require(shares > 0, "AssetVault: !shares > 0");
        assets = totalSupply == 0 ? shares : ShareMath.sharesToAsset(shares, pps(), decimals);
        if (msg.sender != owner) {
            _checkAllowance(owner, shares);
        }
        
        // Check for rounding error since we round down in previewRedeem.
        require(previewRedeem(shares) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        assets = aggregateVault.handleWithdraw(asset, assets, receiver);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    // WHITELIST DEPOSIT
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Deposit a specified amount of assets for whitelisted users and mint corresponding shares to the receiver
     * @param assets The amount of assets to deposit
     * @param receiver The address to receive the minted shares
     * @param merkleProof The merkle proof required for whitelisted deposits
     * @return shares The amount of shares minted for the deposited assets
     */
    function whitelistDeposit(uint256 assets, address receiver, bytes32[] memory merkleProof) public whitelistEnabled whenDepositNotPaused returns (uint256 shares) {
        // Check vault cap
        require(tvl() + assets <= previewVaultCap(), "AssetVault: over vault cap");
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        // checks for whitelist
        aggregateVault.whitelistedDeposit(asset, msg.sender, assets, merkleProof);
        // lock in pps before deposit handling
        uint depositPPS = pps();
        // Transfer assets to aggregate vault, transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(aggregateVault), assets);
        assets = aggregateVault.handleDeposit(asset, assets, msg.sender);

        shares = ShareMath.assetToShares(assets, depositPPS, decimals);
        _mint(receiver,  shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }


    // MATH
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the total assets in the vault
     * @return - The total assets in the vault
     */
    function totalAssets() public view override returns (uint256){
        return ShareMath.sharesToAsset(totalSupply, pps(), decimals);
    }

    /**
     * @notice Convert a specified amount of assets to shares
     * @param assets The amount of assets to convert
     * @return - The amount of shares corresponding to the given assets
     */
    function convertToShares(uint256 assets) public view override returns (uint256) {
        return totalSupply == 0 ? assets : ShareMath.assetToShares(assets, pps(), decimals);
    }

    /**
     * @notice Convert a specified amount of shares to assets
     * @param shares The amount of shares to convert
     * @return - The amount of assets corresponding to the given shares
     */
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return totalSupply == 0 ? shares : ShareMath.sharesToAsset(shares, pps(), decimals);
    }

    /**
     * @notice Preview the amount of shares for a given deposit amount
     * @param assets The amount of assets to deposit
     * @return - The amount of shares for the given deposit amount
     */
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        uint assetFee = previewDepositFee(assets);
        if (assetFee >= assets) return 0;
        return convertToShares(assets - assetFee);
    }

    /**
     * @notice Preview the amount of assets for a given mint amount
     * @param shares The amount of shares to mint
     * @return _mintAmount The amount of assets for the given mint amount
     */
    function previewMint(uint256 shares) public view override returns (uint256 _mintAmount) {
        _mintAmount = totalSupply == 0 ? shares : ShareMath.sharesToAsset(shares, pps(), decimals);
        // add deposit fee for minting fixed amount of shares
        _mintAmount = _mintAmount + previewDepositFee(_mintAmount);
    }

    /**
     * @notice Preview the amount of shares for a given withdrawal amount
     * @param assets The amount of assets to withdraw
     * @return _withdrawAmount The amount of shares for the given withdrawal amount
     */
    function previewWithdraw(uint256 assets) public view override returns (uint256 _withdrawAmount) {
        uint assetFee = previewWithdrawalFee(assets);
        if (assetFee >= assets) return 0;
        _withdrawAmount = totalSupply == 0 ? assets : ShareMath.assetToShares(assets - assetFee, pps(), decimals);
    }

    /**
     * @notice Preview the amount of assets for a given redeem amount
     * @param shares The amount of shares to redeem
     * @return The amount of assets for the given redeem amount
     */
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        uint assets = ShareMath.sharesToAsset(shares, pps(), decimals);
        uint assetFee = previewWithdrawalFee(assets);
        if (assetFee >= assets) return 0;
        return assets - assetFee;
    }


    // DEPOSIT & WITHDRAW LIMIT
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Get the maximum deposit amount for an address
     * @dev _address The address to check the maximum deposit amount for
     * @dev returns the maximum deposit amount for the given address
     */
    function maxDeposit(address) public view override returns (uint256) {
        uint cap = previewVaultCap();
        uint tvl = tvl();
        return cap > tvl ? cap - tvl : 0; 
    }

    /**
     * @notice Get the maximum mint amount for an address
     */
    function maxMint(address) public view override returns (uint256) {
        uint cap = previewVaultCap();
        uint tvl = tvl();
        return cap > tvl ? convertToShares(cap - tvl) : 0; 
    }

    /**
     * @notice Get the maximum withdrawal amount for an address
     * @param owner The address to check the maximum withdrawal amount for
     * @return The maximum withdrawal amount for the given address
     */
    function maxWithdraw(address owner) public view override returns (uint256) {
        uint aggBalance = asset.balanceOf(address(aggregateVault));
        uint userMaxAssets = convertToAssets(balanceOf[owner]);
        return aggBalance > userMaxAssets ? userMaxAssets : aggBalance;
    }

    /**
     * @notice Get the maximum redeem amount for an address
     * @param owner The address to check the maximum redeem amount for
     * @return - The maximum redeem amount for the given address
     */
    function maxRedeem(address owner) public view override returns (uint256) {
        uint aggBalance = convertToShares(asset.balanceOf(address(aggregateVault)));
        return aggBalance > balanceOf[owner] ? balanceOf[owner] : aggBalance;
    }

    // UTILS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Pause deposit and withdrawal operations
     */
    function pauseDepositWithdraw() external onlyAggregateVault {
        _pause();
    }

    /**
     * @notice Unpause deposit and withdrawal operations
     */
    function unpauseDepositWithdraw() external onlyAggregateVault {
        _unpause();
    }

    /**
     * @notice Pause deposits operations
     */
    function pauseDeposits() external onlyConfigurator {
        _pauseDeposit();
    }

    /**
     * @notice Unpause deposit operations
     */
    function unpauseDeposits() external onlyConfigurator {
        _unpauseDeposit();
    }

    /**
     * @notice Pause withdrawal operations
     */
    function pauseWithdrawals() external onlyConfigurator {
        _pauseWithdrawal();
    }

    /**
     * @notice Unpause withdrawal operations
     */
    function unpauseWithdrawals() external onlyConfigurator {
        _unpauseWithdrawal();
    }

    /**
     * @notice Get the price per share (PPS) of the vault
     * @return pricePerShare The current price per share
     */
    function pps() public view returns (uint256 pricePerShare) {
        (bool success, bytes memory ret) = address(aggregateVault).staticcall(abi.encodeCall(AggregateVault.getVaultPPS, address(this)));

        // bubble up error message
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }

        pricePerShare = abi.decode(ret, (uint));
    }

    /**
     * @notice Get the total value locked (TVL) of the vault
     * @return totalValueLocked The current total value locked
     */
    function tvl() public view returns (uint256 totalValueLocked) {
        (bool success, bytes memory ret) = address(aggregateVault).staticcall(abi.encodeCall(AggregateVault.getVaultTVL, address(this)));

        // bubble up error message
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }
        totalValueLocked = abi.decode(ret, (uint));
    }

    /**
     * @notice Update the aggregate vault to a new instance
     * @param _newAggregateVault The new aggregate vault instance to update to
     */
    function updateAggregateVault(AggregateVault _newAggregateVault) external onlyConfigurator {
        aggregateVault = _newAggregateVault;
    }

    /**
     * @notice Mint a specified amount of shares to a timelock contract
     * @param _mintAmount The amount of shares to mint
     * @param _timelockContract The address of the timelock contract to receive the minted shares
     */
    function mintTimelockBoost(uint256 _mintAmount, address _timelockContract) external onlyAggregateVault {
        _mint(_timelockContract, _mintAmount);
    }

    /**
     * @notice Preview the deposit fee for a specified amount of assets
     * @param size The amount of assets to preview the deposit fee for
     * @return totalDepositFee The total deposit fee for the specified amount of assets
     */
    function previewDepositFee(uint256 size) public view returns (uint256 totalDepositFee) {
        (bool success, bytes memory ret) = address(aggregateVault).staticcall(abi.encodeCall(AggregateVault.previewDepositFee, (size)));
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }
        totalDepositFee = abi.decode(ret, (uint256));
    }

    /**
     * @notice Preview the withdrawal fee for a specified amount of assets
     * @param size The amount of assets to preview the withdrawal fee for
     * @return totalWithdrawalFee The total withdrawal fee for the specified amount of assets
     */
    function previewWithdrawalFee(uint256 size) public view returns (uint256 totalWithdrawalFee) {
        (bool success, bytes memory ret) = address(aggregateVault).staticcall(abi.encodeCall(AggregateVault.previewWithdrawalFee, (address(asset), size)));
        if (!success) {
            assembly {
                let length := mload(ret)
                revert(add(32, ret), length)
            }
        }
        totalWithdrawalFee = abi.decode(ret, (uint256));
    }

    /**
     * @notice Preview the deposit cap for the vault
     * @return - The current deposit cap for the vault
     */
     function previewVaultCap() public view returns (uint256) {
        return aggregateVault.previewVaultCap(address(asset));
    }

    /**
     * @dev Check the owners spend allowance
     */
     function _checkAllowance(address owner, uint256 shares) internal {
        uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
    }
    

    // MODIFIERS
    // ------------------------------------------------------------------------------------------


    /**
     * @dev Modifier that throws if called by any account other than the admin (AggregateVault)
     */
    modifier onlyAggregateVault() {
        require(msg.sender == address(aggregateVault), "AssetVault: Caller is not AggregateVault");
        _;
    }

    /**
     * @dev Modifier that throws if whitelist is not enabled
     */
    modifier whitelistEnabled() {
        require(aggregateVault.whitelistEnabled());
        _;
    }

    /**
     * @dev Modifier that throws if whitelist is enabled
     */
    modifier whitelistDisabled() {
        require(!aggregateVault.whitelistEnabled());
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Auth, GlobalACL} from "../Auth.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Whitelist
 * @author Umami DAO
 * @notice The Whitelist contract manages a whitelist of users and their deposit limits for different assets.
 * This contract is used by aggregate vaults to ensure only authorized users can deposit specified amounts
 * of assets.
 */
contract Whitelist is GlobalACL {
    address public immutable aggregateVault;
    address public zap;

    constructor(Auth _auth, address _aggregateVault, address _zap) GlobalACL(_auth) {
        whitelistEnabled = true;
        aggregateVault = _aggregateVault;
        zap = _zap;
    }

    /// @dev asset -> user -> manual whitelist amount
    mapping(address => mapping(address => uint256)) public whitelistedDepositAmount;

    /// @dev asset -> merkle root
    mapping(address => bytes32) public merkleRoots;

    /// @dev asset -> deposit limit
    mapping(address => uint256) public merkleDepositLimit;

    /// @dev asset -> user -> total deposited
    mapping(address => mapping(address => uint256)) public merkleDepositorTracker;

    /// @dev flag for whitelist enabled
    bool public whitelistEnabled;

    event WhitelistUpdated(address indexed account, address asset, uint256 whitelistedAmount);
    
    // WHITELIST VIEWS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Checks if a user has priority access to the whitelist for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     */
    function isWhitelistedPriority(address _asset, address _account) external view returns (bool) {
        if (whitelistEnabled) return whitelistedDepositAmount[_account][_asset] > 0;
        return true;
    }

    /**
     * @notice Checks if a user is whitelisted using a merkle proof for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param merkleProof The merkle proof.
     */
    function isWhitelistedMerkle(address _asset, address _account, bytes32[] memory merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        if (whitelistEnabled) return MerkleProof.verify(merkleProof, merkleRoots[_asset], leaf);
        return true;
    }

    /**
     * @notice Checks if a user is whitelisted for a specific asset, using either their manual whitelist amount or merkle proof.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param merkleProof The merkle proof.
     */
    function isWhitelisted(address _asset, address _account, bytes32[] memory merkleProof) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        bytes32 computedRoot = MerkleProof.processProof(merkleProof, leaf);
        if (merkleRoots[_asset] == bytes32(0) && computedRoot == leaf) return true;

        if (whitelistEnabled) return whitelistedDepositAmount[_account][_asset] > 0 || MerkleProof.verify(merkleProof, merkleRoots[_asset], leaf);
        return true;
    }

    // LIMIT TRACKERS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Records a user's deposit to their whitelist amount for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _amount The amount of the deposit.
     */
    function whitelistDeposit(address _asset, address _account, uint256 _amount) external onlyAggregateVaultOrZap {
        require(whitelistedDepositAmount[_account][_asset] >= _amount, "Whitelist: amount > asset whitelist amount");
        whitelistedDepositAmount[_account][_asset] -= _amount;
    }
    /**
     * @notice Records a user's deposit to their whitelist amount for a specific asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _amount The amount of the deposit.
     */
    function whitelistDepositMerkle(address _asset, address _account, uint256 _amount, bytes32[] memory merkleProof) external onlyAggregateVaultOrZap {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        bytes32 computedRoot = MerkleProof.processProof(merkleProof, leaf);
        if (merkleRoots[_asset] == bytes32(0) && computedRoot == leaf) return;

        require(
            MerkleProof.verify(merkleProof, merkleRoots[_asset], leaf),
            "Whitelist: invalid proof"
        );
        require(merkleDepositorTracker[_asset][_account] + _amount <= merkleDepositLimit[_asset], "Whitelist: amount > asset whitelist amount");
        merkleDepositorTracker[_asset][_account] += _amount;
    }

    // CONFIG
    // ------------------------------------------------------------------------------------------
    
    /**
     * @notice Updates the whitelist amount for a specific user and asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _amount The new whitelist amount.
     */
    function updateWhitelist(
        address _asset,
        address _account,
        uint256 _amount
    ) external onlyConfigurator {
        whitelistedDepositAmount[_account][_asset] = _amount;
        emit WhitelistUpdated(_account, _asset, _amount);
    }

    /**
     * @notice Updates the whitelist enabled status.
     * @param _newVal The new whitelist enabled status.
     */
    function updateWhitelistEnabled(bool _newVal) external onlyConfigurator {
        whitelistEnabled = _newVal;
    }

    /**
     * @notice Updates the merkle root for a specific asset.
     * @param _asset The asset address.
     * @param _root The new merkle root.
     */
    function updateMerkleRoot(address _asset, bytes32 _root) external onlyConfigurator {
        merkleRoots[_asset] = _root;
    }

    /**
     * @notice Updates the merkle deposit limit for a specific asset.
     * @param _asset The asset address.
     * @param _depositLimit The new limit.
     */
    function updateMerkleDepositLimit(address _asset, uint256 _depositLimit) external onlyConfigurator {
        merkleDepositLimit[_asset] = _depositLimit;
    }

    /**
     * @notice Updates the merkle depositor tracker for a specific user and asset.
     * @param _asset The asset address.
     * @param _account The user's address.
     * @param _newValue The new tracked value.
     */
    function updateMerkleDepositorTracker(address _asset, address _account, uint256 _newValue) external onlyConfigurator {
        merkleDepositorTracker[_asset][_account] = _newValue;
    }

    function updateZap(address _newZap) external onlyConfigurator {
        zap = _newZap;
    }

    modifier onlyAggregateVault {
        require(msg.sender == aggregateVault, "Whitelist: only aggregate vault");
        _;
    }

    modifier onlyAggregateVaultOrZap {
        require(msg.sender == aggregateVault || msg.sender == zap, "Whitelist: only aggregate vault or zap");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { IGlpRebalanceRouter } from "../interfaces/IGlpRebalanceRouter.sol";
import { INettedPositionTracker } from "../interfaces/INettedPositionTracker.sol";
import { PositionManagerRouter, WhitelistedTokenRegistry } from "../handlers/hedgeManagers/PositionManagerRouter.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { IRewardRouterV2 } from "../interfaces/IRewardRouterV2.sol";
import { IAssetVault } from "../interfaces/IAssetVault.sol";
import { IFeeEscrow } from "../interfaces/IFeeEscrow.sol";
import { IVaultFeesAndHooks } from "../interfaces/IVaultFeesAndHooks.sol";
import { AggregateVaultStorage } from "../storage/AggregateVaultStorage.sol";
import { NettingMath } from "../libraries/NettingMath.sol";
import { Solarray } from "../libraries/Solarray.sol";
import {Auth, GlobalACL, KEEPER_ROLE, SWAP_KEEPER} from "../Auth.sol";
import {UMAMI_TOTAL_VAULTS, GMX_FEE_STAKED_GLP, GMX_GLP_MANAGER, GMX_GLP_REWARD_ROUTER, GMX_FEE_STAKED_GLP, GMX_GLP_CLAIM_REWARDS, UNISWAP_SWAP_ROUTER} from "../constants.sol";
import {AssetVault} from "./AssetVault.sol";
import {GlpHandler} from "../handlers/GlpHandler.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {Whitelist} from "../peripheral/Whitelist.sol";
import {AggregateVaultHelper} from "../peripheral/AggregateVaultHelper.sol";
import {Multicall} from "../libraries/Multicall.sol";
import {ISwapManager} from "../interfaces/ISwapManager.sol";

enum Peripheral {
    FeeHookHelper,
    RebalanceRouter,
    NettedPositionTracker,
    GlpHandler,
    GlpYieldRewardRouter,
    Whitelist,
    AggregateVaultHelper,
    NettingMath,
    UniV3SwapManager
}

/// @title AggregateVault
/// @author Umami DAO
/// @notice Contains common logic for all asset vaults and core keeper interactions 
contract AggregateVault is
    GlobalACL,
    PositionManagerRouter,
    AggregateVaultStorage,
    Multicall
{
    using SafeTransferLib for ERC20;

    // EVENTS
    // ------------------------------------------------------------------------------------------

    event CollectVaultFees(
        uint256 totalVaultFee,
        uint256 performanceFeeInAsset,
        uint256 managementFeeInAsset,
        uint256 timelockYieldMintAmount,
        address _assetVault
    );
    event OpenRebalance(
        uint256 timestamp,
        uint256[5] nextVaultGlpAlloc,
        uint256[5] nextGlpComp,
        int256[5] adjustedPositions
    );
    event CloseRebalance(uint256 _timestamp);

    // CONSTANTS
    // ------------------------------------------------------------------------------------------

    ERC20 public constant fsGLP = ERC20(GMX_FEE_STAKED_GLP);

    constructor(Auth _auth, GlpHandler _glpHandler, uint256 _nettingPriceTolerance, uint256 _zeroSumPnlThreshold, WhitelistedTokenRegistry _registry) GlobalACL(_auth) PositionManagerRouter(_registry) {
        AVStorage storage _storage = _getStorage();
        _storage.glpHandler = _glpHandler;
        _storage.glpRewardClaimAddr = GMX_GLP_CLAIM_REWARDS;
        _storage.shouldCheckNetting = true;
        _storage.nettedThreshold = 10;
        _storage.glpRebalanceTolerance = 500;
        _storage.nettingPriceTolerance = _nettingPriceTolerance;
        _storage.zeroSumPnlThreshold = _zeroSumPnlThreshold;
    }

    // DEPOSIT & WITHDRAW
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Handles a deposit of a specified amount of an ERC20 asset into the AggregateVault from an account, with a deposit fee deducted.
     * @param asset The ERC20 token to be deposited.
     * @param _amount The amount of the asset to be deposited.
     * @param _account The address of the account from which the deposit will be made.
     * @return amountSansFee The deposited amount after deducting the deposit fee.
     */
    function handleDeposit(ERC20 asset, uint256 _amount, address _account) external onlyAssetVault returns (uint256) {
        require(_amount > 0, "AggregateVault: deposit amount must be greater than 0");
        require(_account != address(0), "AggregateVault: deposit account must be non-zero address");
        uint256 vaultId = getVaultIndex(address(asset));
        require(vaultId < 5, "AggregateVault: invalid vaultId");
        AssetVaultEntry storage vault = _getAssetVaultEntries()[vaultId];
        // collect fee
        uint256 amountSansFee = _amount - _collectDepositFee(vault, _amount);
        vault.epochDelta += int256(amountSansFee);
        return amountSansFee;
    }

    /**
     * @notice Handles a withdrawal of a specified amount of an ERC20 asset from the AggregateVault to an account, with a withdrawal fee deducted.
     * @param asset The ERC20 token to be withdrawn.
     * @param _amount The amount of the asset to be withdrawn.
     * @param _account The address of the account to which the withdrawal will be made.
     * @return amountSansFee The withdrawn amount after deducting the withdrawal fee.
     */
    function handleWithdraw(ERC20 asset, uint256 _amount, address _account) external onlyAssetVault returns (uint256) {
        require(_amount > 0, "AggregateVault: withdraw amount must be greater than 0");
        require(_account != address(0), "AggregateVault: withdraw account must be non-zero address");
        uint256 vaultId = getVaultIndex(address(asset));
        require(vaultId < 5, "AggregateVault: invalid vaultId");
        AssetVaultEntry storage vault = _getAssetVaultEntries()[vaultId];
        // send assets
        uint256 amountSansFee = _amount - _collectWithdrawalFee(vault, _amount);
        require(asset.balanceOf(address(this)) >= amountSansFee, "AggregateVault: buffer exhausted");
        _transferAsset(address(asset), _account, amountSansFee);
        vault.epochDelta -= int256(amountSansFee);
        return amountSansFee;
    }

    /**
     * @notice Allows a whitelisted user to deposit into the vault.
     * @param _asset The ERC20 token to be deposited.
     * @param _account The address of the user making the deposit.
     * @param _amount The amount of tokens to be deposited.
     * @param merkleProof The Merkle proof for whitelisting verification.
     */
    function whitelistedDeposit(ERC20 _asset, address _account, uint256 _amount, bytes32[] memory merkleProof) public onlyAssetVault {
        Whitelist whitelist = _getWhitelist();
        require(whitelist.isWhitelisted(address(_asset), _account, merkleProof), "AggregateVault: not whitelisted");
        if (whitelist.isWhitelistedPriority(address(_asset), _account)) whitelist.whitelistDeposit(address(_asset), _account, _amount);
        else whitelist.whitelistDepositMerkle(address(_asset), _account, _amount, merkleProof);
    }

    // REBALANCE
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Opens the rebalance period and validates next rebalance state.
     * @param nextVaultGlpAlloc the next round GLP allocation in USD in 18 decimals.
     * @param nextGlpComp the next round GLP composition(proportion) in 18 decimals.
     * @param nextHedgeMatrix the next round external position notionals in USD in 18 decimals.
     * @param adjustedPositions aggregate external position notional per asset in USD in 18 decimals.
     */
    function openRebalancePeriod(
        uint256[5] memory nextVaultGlpAlloc, 
        uint256[5] memory nextGlpComp, 
        int256[5][5] memory nextHedgeMatrix, 
        int256[5] memory adjustedPositions, 
        int256[5][5] memory adjustedNettedHedgeMatrix,
        bytes memory _hook
    )
        external
        onlyRole(KEEPER_ROLE)
    {
        // before rebalance hook
        _delegatecall(_getFeeHookHelper(), abi.encodeCall(IVaultFeesAndHooks.beforeOpenRebalancePeriod, _hook));
        VaultState storage vaultState = _getVaultState();
        require(!vaultState.rebalanceOpen, "AggregateVault: rebalance period already open");
        checkNettingConstraint(nextVaultGlpAlloc, nextGlpComp, nextHedgeMatrix, adjustedPositions);
        pauseDeposits();

        RebalanceState storage rebalanceState = _getRebalanceState();

        rebalanceState.glpAllocation = nextVaultGlpAlloc;
        rebalanceState.glpComposition = nextGlpComp;
        rebalanceState.externalPositions = nextHedgeMatrix;
        rebalanceState.aggregatePositions = adjustedPositions; // variable naming
        rebalanceState.epoch = vaultState.epoch;
        rebalanceState.adjustedExternalPositions = adjustedNettedHedgeMatrix;

        _setRebalancePPS(vaultState.rebalancePPS);
        vaultState.rebalanceOpen = true;
            
        emit OpenRebalance(block.timestamp, nextVaultGlpAlloc, nextGlpComp, adjustedPositions);
    }

    /**
     * @notice Closes a rebalance period and validates current state is valid.
     * @param _glpPrice glp price used to value vault glp. Should be the same as what was used in rebalance.
     */
    function closeRebalancePeriod(uint256 _glpPrice, bytes memory _hook) external onlyRole(KEEPER_ROLE) {
        VaultState storage vaultState = _getVaultState();
        require(vaultState.rebalanceOpen, "AggregateVault: no open rebalance period");
        
        uint256[5] memory dollarGlpBalance = _glpToDollarArray(_glpPrice);
        RebalanceState storage rebalanceState = _getRebalanceState();
        
        checkNettingConstraint(
            dollarGlpBalance,
            rebalanceState.glpComposition,
            rebalanceState.externalPositions,
            rebalanceState.aggregatePositions);
        
        _resetEpochDeltas();
        
        vaultState.rebalanceOpen = false;
        vaultState.glpAllocation = rebalanceState.glpAllocation;
        vaultState.aggregatePositions = rebalanceState.aggregatePositions;

        int256[5][5] memory exposureMatrix;
        int[5][5] memory _nettedPositions;
        
        (_nettedPositions, exposureMatrix) = _getNettingMath().calculateNettedPositions(
            rebalanceState.adjustedExternalPositions,
            rebalanceState.glpComposition,
            rebalanceState.glpAllocation);
        
        _setNettedPositions(_nettedPositions);
        
        _setStateExternalPositions(rebalanceState);

        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();

        // collect fee at the end because it depends on tvl
        for (uint i = 0; i < 5; i++) {
            _collectVaultRebalanceFees(assetVaults[i]);
        }
        _setCheckpointTvls();

        unpauseDeposits();
        
        // note set last to not trigger internal pnl
        vaultState.epoch += 1;
        vaultState.lastRebalanceTime = block.timestamp;

        // after rebalance hook
        _delegatecall(_getFeeHookHelper(), abi.encodeCall(IVaultFeesAndHooks.afterCloseRebalancePeriod, _hook));
        emit CloseRebalance(block.timestamp);
    }

    /**
     * @notice Executes the vault cycle.
     * @dev assetPrices An array containing the prices of the 5 assets.
     * @dev glpPrice The price of GLP.
     */
    function cycle(
        uint256[5] memory /*assetPrices*/,
        uint256 /*glpPrice*/
    ) external onlyRole(KEEPER_ROLE) {
        (bytes memory ret) = _forwardToHelper(msg.data);
        _return(ret);
    }

    /**
     * @notice Executes a multicall in the context of the aggregate vault.
     * @param data the calls to be executed.
     * @return results the return values of each call.
     */
    function multicall(
        bytes[] calldata data
    ) external payable onlyRole(KEEPER_ROLE) returns (bytes[] memory results, uint[] memory gasEstimates) {
        (results, gasEstimates) = _multicall(data);
    }

    /**
     * @notice Checks if the netting constraint is satisfied for the given input values.
     * @dev Reverts if the netting constraint is not satisfied.
     * @param vaultGlpAlloc An array representing the allocation of GLP held by the vault.
     * @param glpComp An array representing the composition of the GLP token.
     * @param hedgeMatrix A 2D array representing the hedge matrix.
     * @param aggregatePositions An array representing the aggregate positions.
     */
    function checkNettingConstraint(
        uint256[5] memory vaultGlpAlloc,
        uint256[5] memory glpComp,
        int256[5][5] memory hedgeMatrix,
        int256[5] memory aggregatePositions
    ) public view {
        NettingMath.NettedState memory nettingState = NettingMath.NettedState({
            glpHeld: vaultGlpAlloc,
            externalPositions: aggregatePositions
        });
        NettingMath.NettedParams memory nettingParams = NettingMath
            .NettedParams({
                vaultCumulativeGlpTvl: Solarray.arraySum(vaultGlpAlloc),
                glpComposition: glpComp,
                nettedThreshold: _getNettedThreshold()
            });
        if (_getStorage().shouldCheckNetting) {
            require(
                _getNettingMath().isNetted(nettingState, nettingParams, hedgeMatrix),
                    "AggregateVault: netting constraint not satisfied"
            );
        }
    }

    // VIEWS
    // ------------------------------------------------------------------------------------------

    /**
    * @notice preview deposit fee
    * @param size The size of the deposit for which the fee is being calculated
    * @return totalDepositFee The calculated deposit fee
    */
    function previewDepositFee(uint256 size) public returns (uint256 totalDepositFee) {
        (bytes memory ret) = _forwardToFeeHookHelper(abi.encodeCall(IVaultFeesAndHooks.getDepositFee, (size)));
        (totalDepositFee) = abi.decode(ret, (uint256));
    }

    /**
    * @notice preview withdrawal fee
    * @param token The address of the token for which the withdrawal fee is being calculated
    * @param size The size of the withdrawal for which the fee is being calculated
    * @return totalWithdrawalFee The calculated withdrawal fee
    */
    function previewWithdrawalFee(address token, uint256 size) public returns (uint256 totalWithdrawalFee) {
        (bytes memory ret) = _forwardToFeeHookHelper(abi.encodeCall(IVaultFeesAndHooks.getWithdrawalFee, (token, size)));
        (totalWithdrawalFee) = abi.decode(ret, (uint256));
    }

    /**
    * @notice Get the index of the asset vault in the storage
    * @param _asset The address of the asset whose vault index is being queried
    * @return idx The index of the asset vault
    */
    function getVaultIndex(address _asset) public view returns (uint256 idx) {
        mapping(address => uint) storage tokenToAssetVaultIndex = _getTokenToAssetVaultIndex();
        idx = tokenToAssetVaultIndex[_asset];
        // cannot check for it being 0 aka null value because there
        // is a vault at 0 index too
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        require(assetVaults[idx].token == _asset, "AggregateVault: asset vault not found");
    }


    /**
    * @notice Gets the current asset vault price per share (PPS)
    * @param _assetVault The address of the asset vault whose PPS is being queried
    * @return _pps The current asset vault PPS
    */
    function getVaultPPS(address _assetVault) public returns (uint _pps) {
        (bytes memory ret) = _forwardToHelper(abi.encodeCall(this.getVaultPPS, (_assetVault)));
        (_pps) = abi.decode(ret, (uint));
    }

    /**
    * @notice Gets the current asset vault total value locked (TVL)
    * @param _assetVault The address of the asset vault whose TVL is being queried
    * @return _tvl The current asset vault TVL
    */
    function getVaultTVL(address _assetVault) public returns (uint _tvl) {
        (bytes memory ret) = _forwardToHelper(abi.encodeCall(this.getVaultTVL, (_assetVault)));
        (_tvl) = abi.decode(ret, (uint));
    }

    /**
    * @notice Preview the asset vault cap
    * @param _asset The address of the asset whose vault cap is being queried
    * @return The current asset vault cap
    */
    function previewVaultCap(address _asset) public view returns (uint256) {
        uint256 vidx = getVaultIndex(_asset);
        VaultState memory state = _getVaultState();
        return state.vaultCaps[vidx];
    }

    /**
    * @notice Check if the whitelist is enabled
    * @return - True if whitelist is enabled, false otherwise
    */
    function whitelistEnabled() public view returns (bool) {
        Whitelist whitelist = _getWhitelist();
        if(address(whitelist) != address(0)) return whitelist.whitelistEnabled();
        return false;
    }

    /**
    * @notice Check if rebalance period is open
    * @return - True if rebalnce period is open, false otherwise
    */
    function rebalanceOpen() public view returns (bool) {
        VaultState storage vaultState = _getVaultState();
        return vaultState.rebalanceOpen;
    }


    // CONFIG
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Set the peripheral contract addresses
    * @param _peripheral The enum value of the peripheral type
    * @param _addr The address of the peripheral contract
    */
    function setPeripheral(Peripheral _peripheral, address _addr) external onlyConfigurator {
        AVStorage storage _storage = _getStorage();

        if (_peripheral == Peripheral.FeeHookHelper) {
            _storage.feeAndHookHelper = _addr;
        } else if (_peripheral == Peripheral.RebalanceRouter) {
            _storage.glpRebalanceRouter = IGlpRebalanceRouter(_addr);
        } else if (_peripheral == Peripheral.NettedPositionTracker) {
            _storage.nettedPositionTracker = INettedPositionTracker(_addr);
        } else if (_peripheral == Peripheral.GlpHandler) {
            _storage.glpHandler = GlpHandler(_addr);
        } else if (_peripheral == Peripheral.GlpYieldRewardRouter) {
            _storage.glpRewardClaimAddr = _addr;
        } else if (_peripheral == Peripheral.Whitelist) {
            _storage.whitelist = Whitelist(_addr);
        } else if (_peripheral == Peripheral.AggregateVaultHelper) {
            _storage.aggregateVaultHelper = _addr;
        } else if (_peripheral == Peripheral.NettingMath) {
            _storage.nettingMath = NettingMath(_addr);
        } else if (_peripheral == Peripheral.UniV3SwapManager) {
            _storage.uniV3SwapManager = ISwapManager(_addr);
        } 
    }

    /**
    * @notice Add a new position manager to the list of position managers
    * @param _manager The address of the new position manager
    */
    function addPositionManager(IPositionManager _manager) external onlyConfigurator {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        positionManagers.push(_manager);
    }

    /**
    * @notice Sets the vault fees
    * @param _performanceFee The performance fee value to set
    * @param _managementFee The management fee value to set
    * @param _withdrawalFee The withdrawal fee value to set
    * @param _depositFee The deposit fee value to set
    * @param _timelockBoostPercent The timelock boost percent value to set
    */
    function setVaultFees(uint256 _performanceFee, uint256 _managementFee, uint256 _withdrawalFee, uint256 _depositFee, uint256 _timelockBoostPercent) external onlyConfigurator {
        _getStorage().vaultFees = VaultFees({
            performanceFee: _performanceFee,
            managementFee: _managementFee,
            withdrawalFee: _withdrawalFee,
            depositFee: _depositFee,
            timelockBoostAmount: _timelockBoostPercent
        });
    }

    /**
    * @notice Set fee watermarks for all asset vaults
    * @param _newWatermarks An array of new watermark values for each asset vault
    */
    function setFeeWatermarks(uint256[5] memory _newWatermarks) external onlyConfigurator {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < 5; i++) {
            assetVaults[i].feeWatermarkPPS = _newWatermarks[i];
            assetVaults[i].feeWatermarkDate = block.timestamp;
        }
    }

    /**
    * @notice Update fee watermark for a specific asset vault
    * @param _vaultId The index of the asset vault to update
    * @param _feeWatermarkPPS The new fee watermark value
    */
    function updateFeeWatermarkVault(uint256 _vaultId, uint256 _feeWatermarkPPS) external onlyConfigurator {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        assetVaults[_vaultId].feeWatermarkDate = block.timestamp;
        assetVaults[_vaultId].feeWatermarkPPS = _feeWatermarkPPS;
    }

    /**
    * @notice Set the flag for checking netting constraints
    * @param _newVal The new boolean value for the flag
    */
    function setShouldCheckNetting(bool _newVal) external onlyConfigurator {
        AVStorage storage _storage = _getStorage();
        _storage.shouldCheckNetting = _newVal;
    }

    /**
    * @notice Set the netted threshold in bips for netting constraint
    * @param _newNettedThreshold The new netted threshold value
    */
    function setNettedThreshold(uint256 _newNettedThreshold) external onlyConfigurator {
        AVStorage storage _storage = _getStorage();
        _storage.nettedThreshold = _newNettedThreshold;
    }

    /**
    * @notice Set the zero sum threshold for netting position pnl
    * @param _zeroSumPnlThreshold The new zero sum pnl threshold value
    */
    function setZeroSumPnlThreshold(uint256 _zeroSumPnlThreshold) external onlyConfigurator {
        require(_zeroSumPnlThreshold > 0, "AggregateVault: _zeroSumPnlThreshold must be > 0");
        require(_zeroSumPnlThreshold < 1e18, "AggregateVault: _zeroSumPnlThreshold must be < 1e18");
        AVStorage storage _storage = _getStorage();
       _storage.zeroSumPnlThreshold = _zeroSumPnlThreshold;
    }
    
    /**
    * @notice Update asset vault receipt contracts
    * @param _assetVaults An array of new asset vault entries
    */
    function setAssetVaults(
        AssetVaultEntry[5] calldata _assetVaults
    ) external onlyConfigurator {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        mapping(address => uint) storage tokenToAssetVaultIndex = _getTokenToAssetVaultIndex();
        mapping(address => uint) storage vaultToAssetVaultIndex = _getVaultToAssetVaultIndex();

        for (uint256 i = 0; i < _assetVaults.length; i++) {
            assetVaults[i] = _assetVaults[i];
            tokenToAssetVaultIndex[_assetVaults[i].token] = i;
            vaultToAssetVaultIndex[_assetVaults[i].vault] = i;
        }
    }

    /**
    * @notice Set vault caps for all asset vaults
    * @param _newCaps An array of new cap values for each asset vault
    */
    function setVaultCaps(uint256[5] memory _newCaps) external onlyConfigurator {
        VaultState storage state = _getVaultState();
        state.vaultCaps = _newCaps;
    }

    /**
    * @notice Set fee recipient and deposit fee escrow addresses
    * @param _recipient The address of the fee recipient
    * @param _depositFeeEscrow The address of the deposit fee escrow
    */
    function setFeeRecipient(address _recipient, address _depositFeeEscrow, address _withdrawalFeeEscrow) external onlyConfigurator {
        require(_recipient != address(0), "AggregateVault: !address(0)");
        require(_depositFeeEscrow != address(0), "AggregateVault: !address(0)");
        VaultState storage state = _getVaultState();
        state.feeRecipient = _recipient;
        state.depositFeeEscrow = _depositFeeEscrow;
        state.withdrawalFeeEscrow = _withdrawalFeeEscrow;
    }

    // INTERNAL
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Collects vault rebalance fees, mints timelock shares and distributes them.
    */
    function _collectVaultRebalanceFees(AssetVaultEntry memory assetVault) internal {
        uint256 performanceFeeInAsset;
        uint256 managementFeeInAsset;
        uint256 timelockYieldMintAmount;
        uint256 totalVaultFee;
        VaultState storage vaultState = _getVaultState();
        (bytes memory ret) = _forwardToFeeHookHelper(abi.encodeCall(IVaultFeesAndHooks.getVaultRebalanceFees, (assetVault.token, vaultState.lastRebalanceTime)));
        (performanceFeeInAsset, managementFeeInAsset, timelockYieldMintAmount, totalVaultFee) = abi.decode(ret, (uint256, uint256, uint256, uint256));
        
        if (totalVaultFee > 0) {
            _transferAsset(assetVault.token, vaultState.feeRecipient, totalVaultFee);
        }
        if (timelockYieldMintAmount > 0 && assetVault.timelockYieldBoost != address(0)) {
            AssetVault(assetVault.vault).mintTimelockBoost(timelockYieldMintAmount, assetVault.timelockYieldBoost);
        }

        emit CollectVaultFees(totalVaultFee, performanceFeeInAsset, managementFeeInAsset, timelockYieldMintAmount, assetVault.vault);
    }

    /**
    * @notice Collects withdrawal fees and distributes them.
    */
    function _collectWithdrawalFee(AssetVaultEntry memory assetVault, uint256 size) internal returns (uint256) {
        uint256 totalWithdrawalFee;

        (bytes memory ret) = _forwardToFeeHookHelper(abi.encodeCall(IVaultFeesAndHooks.getWithdrawalFee, (assetVault.token, size)));
        (totalWithdrawalFee) = abi.decode(ret, (uint256));

        VaultState memory vaultState = _getVaultState();
        if (totalWithdrawalFee > 0) {
            _transferAsset(assetVault.token, vaultState.withdrawalFeeEscrow, totalWithdrawalFee);
        }
        return totalWithdrawalFee;
    }

    /**
    * @notice Collects deposit fees and distributes them.
    */
    function _collectDepositFee(AssetVaultEntry memory assetVault, uint256 size) internal returns (uint256){
        uint256 totalDepositFee;

        (bytes memory ret) = _forwardToFeeHookHelper(abi.encodeCall(IVaultFeesAndHooks.getDepositFee, (size)));
        (totalDepositFee) = abi.decode(ret, (uint256));

        VaultState storage vaultState = _getVaultState();
        if (totalDepositFee > 0) {
            _transferAsset(assetVault.token, vaultState.depositFeeEscrow, totalDepositFee);
        }

        return totalDepositFee;
    }

    /**
    * @notice Resets the epoch deposit/withdraw delta for all asset vaults.
    */
    function _resetEpochDeltas() internal {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < 5; i++) {
            assetVaults[i].epochDelta = int256(0);
        }
    }

    /**
    * @notice Sets the checkpoint TVL for all asset vaults.
    */
    function _setCheckpointTvls() internal {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < 5; i++) {
            assetVaults[i].lastCheckpointTvl = getVaultTVL(assetVaults[i].vault);
        }
    }

    /**
    * @notice Sets the rebalance price per share for all asset vaults.
    */
    function _setRebalancePPS(uint256[5] storage rebalancePps) internal {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < 5; i++) {
            rebalancePps[i] = getVaultPPS(assetVaults[i].vault);
        }
    }

    /**
    * @notice Converts GLP to a dollar array based on the current GLP price.
    */
    function _glpToDollarArray(uint256 _glpPrice) internal view returns (uint256[5] memory glpAsDollars){
        uint[5] memory _vaultGlpAttribution = _getVaultGlpAttribution();
        uint totalGlpAttribution = Solarray.arraySum(_vaultGlpAttribution);
        uint totalGlpBalance = fsGLP.balanceOf(address(this));
        for (uint i = 0; i < 5; i++) {
            uint glpBalance = totalGlpBalance * _vaultGlpAttribution[i] / totalGlpAttribution;
            glpAsDollars[i] = _glpPrice * glpBalance / 1e18;
        }
    }

    // UTILS
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Pause deposits and withdrawals for the asset vaults
     */
    function pauseDeposits() public onlyRole(KEEPER_ROLE) {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint256 i = 0; i < assetVaults.length; i++) {
            IAssetVault(assetVaults[i].vault).pauseDepositWithdraw();
        }
    }

    /**
     * @notice Unpause deposits and withdrawals for the asset vaults
     */
    function unpauseDeposits() public onlyRole(KEEPER_ROLE) {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint256 i = 0; i < assetVaults.length; i++) {
            IAssetVault(assetVaults[i].vault).unpauseDepositWithdraw();
        }
    }

    /**
    * @notice Executes a delegate view to the specified target with the provided data and decodes the response as bytes.
    */
    function delegateview(address _target, bytes calldata _data) external returns (bool _success, bytes memory _ret) {
        (bool success, bytes memory ret) = address(this).call(abi.encodeCall(this.delegateviewRevert, (_target, _data)));
        require(!success, "AggregateVault: delegateViewRevert didn't revert");
        (_success, _ret) = abi.decode(ret, (bool, bytes));
    }

    /**
    * @notice Executes a delegate call to the specified target with the provided data and reverts on error.
    */
    function delegateviewRevert(address _target, bytes memory _data) external {
        (bool success, bytes memory ret) = _target.delegatecall(_data);
        bytes memory encoded = abi.encode(success, ret);
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(encoded, 0x20), mload(encoded))
        }
    }

    /**
    * @notice Forwards a call to the helper contract with the provided calldata.
    */
    function _forwardToHelper(bytes memory _calldata) internal returns (bytes memory ret) {
        address aggregateVaultHelper = _getAggregateVaultHelper();
        ret = _delegatecall(aggregateVaultHelper, _calldata);
    }

    /**
    * @notice Forwards a call to the helper contract with the provided calldata.
    */
    function _forwardToFeeHookHelper(bytes memory _calldata) internal returns (bytes memory ret) {
        address feeHookHelper = _getFeeHookHelper();
        ret = _delegatecall(feeHookHelper, _calldata);
    }

    /**
    * @notice Returns the provided bytes data.
    */
    function _return(bytes memory _ret) internal pure {
        assembly {
            let length := mload(_ret)
            return(add(_ret, 0x20), length)
        }
    }

    /**
    * @notice Ensures the caller is the configurator.
    */
    function _onlyConfigurator() internal override onlyConfigurator {}

    /**
    * @notice Ensures the caller is permissioned to swap.
    */
    function _onlySwapIssuer() internal override onlyRole(SWAP_KEEPER) {}

    /**
    * @notice Validates the authorization for an execute call.
    */
    function _validateExecuteCallAuth()
        internal
        override
        onlyRole(KEEPER_ROLE)
    {}

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param asset the asset to transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function _transferAsset(address asset, address recipient, uint256 amount) internal {
        ERC20(asset).safeTransfer(recipient, amount);
    }

    /**
    * @notice Ensures the caller is an asset vault.
    */
    modifier onlyAssetVault() {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < UMAMI_TOTAL_VAULTS; ++i) {
            if (msg.sender == assetVaults[i].vault) {
                _;
                return;
            }
        }
        revert("AggregateVault: not asset vault");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (assetAmount * 10**decimals) / assetPerShare;
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (shares * assetPerShare) / 10**decimals;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return totalSupply > 0 ? (singleShare * totalBalance) / totalSupply : singleShare;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { ERC20 } from "solmate/tokens/ERC20.sol";

interface IAggregateVault {
    function handleWithdraw(ERC20 asset, uint256 _amount, address _account) external;

    function handleDeposit(ERC20 asset, uint256 _amount, address _account) external;

    function getVaultPPS(address _assetVault) external view returns (uint256);

    function previewWithdrawalFee(address token, uint256 _size) external view returns (uint256);

    function previewDepositFee(uint256 _size) external view returns (uint256);

    function rebalanceOpen() external view returns (bool);
}

pragma solidity 0.8.17;

bytes32 constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR");
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 constant SWAP_KEEPER = keccak256("SWAP_KEEPER");

/// @title Auth
/// @author Umami Developers
/// @notice Simple centralized ACL
contract Auth {
    /// @dev user not authorized with given role
    error NotAuthorized(bytes32 _role, address _user);

    event RoleUpdated(
        bytes32 indexed role,
        address indexed user,
        bool authorized
    );

    bytes32 public constant AUTH_MANAGER_ROLE = keccak256("AUTH_MANAGER");
    mapping(bytes32 => mapping(address => bool)) public hasRole;

    constructor() {
        _updateRole(msg.sender, AUTH_MANAGER_ROLE, true);
    }

    function updateRole(
        address _user,
        bytes32 _role,
        bool _authorized
    ) external {
        onlyRole(AUTH_MANAGER_ROLE, msg.sender);
        _updateRole(_user, _role, _authorized);
    }

    function onlyRole(bytes32 _role, address _user) public view {
        if (!hasRole[_role][_user]) {
            revert NotAuthorized(_role, _user);
        }
    }

    function _updateRole(
        address _user,
        bytes32 _role,
        bool _authorized
    ) internal {
        hasRole[_role][_user] = _authorized;
        emit RoleUpdated(_role, _user, _authorized);
    }
}

abstract contract GlobalACL {
    Auth public immutable AUTH;

    constructor(Auth _auth) {
        require(address(_auth) != address(0), "GlobalACL: zero address");
        AUTH = _auth;
    }

    modifier onlyConfigurator() {
        AUTH.onlyRole(CONFIGURATOR_ROLE, msg.sender);
        _;
    }

    modifier onlyRole(bytes32 _role) {
        AUTH.onlyRole(_role, msg.sender);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @title PausableVault
/// @author Umami DAO
/// @notice Pausable deposit/withdraw support for vaults
abstract contract PausableVault {

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    /// @dev paused deposits only
    event DepositsPaused(address account);

    /// @dev paused deposits only
    event DepositsUnpaused(address account);

    /// @dev paused withdrawals only
    event WithdrawalsPaused(address account);

    /// @dev paused withdrawals only
    event WithdrawalsUnpaused(address account);

    bool private _depositsPaused;
    
    bool private _withdrawalPaused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _depositsPaused = false;
        _withdrawalPaused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenDepositNotPaused() {
        _requireDepositNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenWithdrawalNotPaused() {
        _requireWithdrawalNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenDepositPaused() {
        _requireDepositPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenWithdrawalPaused() {
        _requireWithdrawalPaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function depositPaused() public view virtual returns (bool) {
        return _depositsPaused;
    }
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function withdrawalPaused() public view virtual returns (bool) {
        return _withdrawalPaused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireDepositNotPaused() internal view virtual {
        require(!depositPaused(), "Pausable: deposit paused");
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireWithdrawalNotPaused() internal view virtual {
        require(!withdrawalPaused(), "Pausable: withdrawal paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requireDepositPaused() internal view virtual {
        require(depositPaused(), "Pausable: deposit not paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requireWithdrawalPaused() internal view virtual {
        require(withdrawalPaused(), "Pausable: withdrawal not paused");
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual {
        if (!depositPaused())
            _pauseDeposit();
        if (!withdrawalPaused())
            _pauseWithdrawal();
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        if (depositPaused())
            _unpauseDeposit();
        if (withdrawalPaused())
            _unpauseWithdrawal();
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Triggers stopped deposit state.
     *
     * Requirements:
     *
     * - The deposits must not be paused.
     */
    function _pauseDeposit() internal virtual whenDepositNotPaused {
        _depositsPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal deposit state.
     *
     * Requirements:
     *
     * - The deposits must be paused.
     */
    function _unpauseDeposit() internal virtual whenDepositPaused {
        _depositsPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Triggers stopped withdrawal state.
     *
     * Requirements:
     *
     * - The withdrawals must not be paused.
     */
    function _pauseWithdrawal() internal virtual whenWithdrawalNotPaused {
        _withdrawalPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal withdrawal state.
     *
     * Requirements:
     *
     * - The withdrawals must be paused.
     */
    function _unpauseWithdrawal() internal virtual whenWithdrawalPaused {
        _withdrawalPaused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IGlpRebalanceRouter {

    function netGlpRebalance(uint256[5] memory lastAllocations, uint256[5] memory nextAllocations) external view returns (int256[5] memory glpVaultDeltaExecute, int[5] memory glpVaultDeltaAccount);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface INettedPositionTracker {

    struct NettedPrices {
        uint256 stable;
        uint256 eth;
        uint256 btc;
        uint256 link;
        uint256 uni;
    }

    function settleNettingPositionPnl(
        int256[5][5] memory internalPositions, 
        NettedPrices memory assetPrices, 
        NettedPrices memory lastAssetPrices, 
        uint256[5] memory vaultGlpAmount, 
        uint256 glpPrice,
        uint256 pnlSumThreshold
        ) external view
    returns (
        uint256[5] memory settledVaultGlpAmount, 
        int256[5] memory nettedPnl,
        int256[5] memory glpPnl,
        int256[5] memory percentPriceChange
        );
}

pragma solidity 0.8.17;

import {Auth, GlobalACL} from "../../Auth.sol";
import {Multicall} from "../../libraries/Multicall.sol";
import {IPositionManager} from "../../interfaces/IPositionManager.sol";
import {IHandlerContract} from "../../interfaces/IHandlerContract.sol";
import {ISwapManager} from "../../interfaces/ISwapManager.sol";

contract WhitelistedTokenRegistry is GlobalACL {
    event UpdatedWhitelistedToken(address indexed _token, bool _isWhitelisted);
    event UpdatedIsWhitelistingEnabled(bool _isEnabled);

    /// @notice whitelisted tokens to/from which swaps allowed
    mapping(address => bool) public whitelistedTokens;
    /// @notice whitelisting in effect
    bool public isWhitelistingEnabled = true;

    constructor(Auth _auth) GlobalACL(_auth) {}

    function updateWhitelistedToken(
        address _token,
        bool _isWhitelisted
    ) external onlyConfigurator {
        whitelistedTokens[_token] = _isWhitelisted;
        emit UpdatedWhitelistedToken(_token, _isWhitelisted);
    }

    function updateIsWhitelistingEnabled(
        bool _isWhitelistingEnabled
    ) external onlyConfigurator {
        isWhitelistingEnabled = _isWhitelistingEnabled;
        emit UpdatedIsWhitelistingEnabled(_isWhitelistingEnabled);
    }

    function isWhitelistedToken(address _token) external view returns (bool) {
        if (isWhitelistingEnabled) {
            return whitelistedTokens[_token];
        }
        return true;
    }
}

library PositionManagerRouterLib {
    error NotWhitelistedToken();
    error UnknownHandlerContract();

    function executeSwap(
        ISwapManager _swapManager,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _minOut,
        bytes calldata _data,
        WhitelistedTokenRegistry whitelistedTokenRegistry,
        mapping(ISwapManager => bool) storage swapHandlers,
        mapping(IHandlerContract => bool) storage handlerContracts
    ) external returns (uint _amountOut) {
        if (
            !whitelistedTokenRegistry.isWhitelistedToken(_tokenIn) ||
            !whitelistedTokenRegistry.isWhitelistedToken(_tokenOut)
        ) revert NotWhitelistedToken();

        bool isSwapHandler = swapHandlers[_swapManager];
        bool isHandler = handlerContracts[_swapManager];
        if (!isSwapHandler || !isHandler) {
            revert UnknownHandlerContract();
        }

        bytes memory ret = _delegatecall(
            address(_swapManager),
            abi.encodeCall(
                ISwapManager.swap,
                (_tokenIn, _tokenOut, _amountIn, _minOut, _data)
            )
        );
        (_amountOut) = abi.decode(ret, (uint));
    }

    function _delegatecall(
        address _target,
        bytes memory _data
    ) internal returns (bytes memory ret) {
        bool success;
        (success, ret) = _target.delegatecall(_data);
        if (!success) {
            /// @solidity memory-safe-assembly
            assembly {
                let length := mload(ret)
                let start := add(ret, 0x20)
                revert(start, length)
            }
        }
        return ret;
    }
}

/**
 * @title PositionManagerRouter
 * @author Umami DAO
 * @dev This abstract contract is a base implementation for a position manager router.
 *      It handles execution, callbacks, and swap operations on handler contracts.
 */
abstract contract PositionManagerRouter {

    error UnknownCallback();
    error CallbackHandlerNotSet();
    error UnknownHandlerContract();
    error OnlySelf();
    error NotWhitelistedToken();

    /// @dev Emitted when a callback handler is updated.
    event CallbackHandlerUpdated(
        bytes4 indexed _sig,
        address indexed _handler,
        bool _enabled
    );

    /// @dev Emitted when a handler contract is updated.
    event HandlerContractUpdated(address indexed _contract, bool _enabled);

    /// @dev Emitted when a default handler contract is updated.
    event DefaultHandlerContractUpdated(
        bytes4 indexed _sig,
        address indexed _handler
    );

    /// @dev Emitted when a swap handler is updated.
    event SwapHandlerUpdated(address indexed _handled, bool _enabled);
    event WhitelistedTokenUpdated(address indexed _token, bool _isWhitelisted);

    /// @notice mapping of handler contracts and callbacks they can handle
    mapping(IHandlerContract => mapping(bytes4 => bool)) public handlerContractCallbacks;

    /// @notice mapping of allowed handler contracts
    mapping(IHandlerContract => bool) public handlerContracts;

    /// @notice current handler contract, set when `executeWithCallbackHandler` called.
    ///         Useful when multiple handlers can handle same callback. So you specify
    ///         which handler to call.
    address public currentCallbackHandler;

    /// @notice mapping of default handlers for a given method. This is used if currentCallbackHandler
    ///         is not set.
    mapping(bytes4 => IHandlerContract) public defaultHandlers;

    /// @notice whitelisted swap handlers
    mapping(ISwapManager => bool) public swapHandlers;
    /// @notice Whitelisted token registry
    WhitelistedTokenRegistry immutable whitelistedTokenRegistry;

    constructor(WhitelistedTokenRegistry _registry) {
        whitelistedTokenRegistry = _registry;
    }

    /**
     * @notice Updates the handler contract and its associated callbacks.
     * @param _handler The handler contract to be updated.
     * @param _enabled Whether the handler should be enabled or disabled.
     */
    function updateHandlerContract(
        IHandlerContract _handler,
        bool _enabled
    ) public {
        _onlyConfigurator();
        handlerContracts[_handler] = _enabled;
        emit HandlerContractUpdated(address(_handler), _enabled);
        _updateHandlerContractCallbacks(_handler, _enabled);
    }

    /**
     * @notice Updates the default handler contract for a given method signature.
     * @param _sig The method signature of the default handler.
     * @param _handler The handler contract to be set as the default for the given method.
     */
    function updateDefaultHandlerContract(
        bytes4 _sig,
        IHandlerContract _handler
    ) external {
        _onlyConfigurator();
        defaultHandlers[_sig] = _handler;
        emit DefaultHandlerContractUpdated(_sig, address(_handler));
    }

    /**
     * @notice Updates a swap handler and its associated handler contract.
     * @param _manager The swap manager to be updated.
     * @param _enabled Whether the swap handler should be enabled or disabled.
     */
    function updateSwapHandler(ISwapManager _manager, bool _enabled) external {
        _onlyConfigurator();
        updateHandlerContract(_manager, _enabled);
        swapHandlers[_manager] = _enabled;
        emit SwapHandlerUpdated(address(_manager), _enabled);
    }

    /**
     * @notice Executes a call to a handler contract.
     * @param _handler The handler contract to be called.
     * @param data The data to be sent to the handler contract.
     * @return ret The returned data from the handler contract.
     */
    function execute(
        address _handler,
        bytes calldata data
    ) public payable returns (bytes memory ret) {
        _validateExecuteCallAuth();
        bool isSwapHandler = swapHandlers[ISwapManager(_handler)];
        if (isSwapHandler && msg.sender != address(this))
            _onlySwapIssuer();
        bool isHandler = handlerContracts[IHandlerContract(_handler)];
        if (!isHandler) revert UnknownHandlerContract();
        ret = _delegatecall(_handler, data);
    }

    /**
     * @notice Executes a call to a handler contract with the specified `currentCallbackHandler`.
     * @dev `execute` with `currentCallbackHandler` set. Useful when multiple handlers can handle a callback.abi
     *       E.g.: Flash loan callbacks, swap callbacks, etc.
     * @param _handler The handler contract to be called.
     * @param data The data to be sent to the handler contract.
     * @param _callbackHandler The callback handler to be used for this execution.
     * @return ret The returned data from the handler contract.
     */
    function executeWithCallbackHandler(
        address _handler,
        bytes calldata data,
        address _callbackHandler
    )
        external
        payable
        withHandler(_callbackHandler)
        returns (bytes memory ret)
    {
        ret = execute(_handler, data);
    }

    /**
     * @notice Executes a swap against a swap manager.
     * @dev execute swap against a swap manager
     * @param _swapManager The swap manager to execute the swap against.
     * @param _tokenIn The token being provided for the swap.
     * @param _tokenOut The token being requested from the swap.
     * @param _amountIn The amount of `_tokenIn` being provided for the swap.
     * @param _minOut The minimum amount of `_tokenOut` to be received from the swap.
     * @param _data Additional data to be passed to the swap manager.
     * @return _amountOut The amount of `_tokenOut` received from the swap.
     */
    function executeSwap(
        ISwapManager _swapManager,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _minOut,
        bytes calldata _data
    ) external returns (uint _amountOut) {
        if (msg.sender != address(this)) {
            _onlySwapIssuer();
        }
        _amountOut = PositionManagerRouterLib.executeSwap(
            _swapManager,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _minOut,
            _data,
            whitelistedTokenRegistry,
            swapHandlers,
            handlerContracts
        );
    }

    /**
    * @dev Fallback function which handles callbacks from external contracts.
    *      It forwards the call to the appropriate handler, either the
    *      `currentCallbackHandler` or the default handler for the method signature.
    *      This is necessary to have callback handlers defined in position managers and swap handlers.
    */
    fallback() external payable {
        bytes memory _ret = _handleCallback();

        // bubble up the returned data from the handler
        /// @solidity memory-safe-assembly
        assembly {
            let length := mload(_ret)
            return(add(_ret, 0x20), length)
        }
    }

    /// @dev To be implemented by inheriting contracts to restrict certain functions to a configurator role.
    function _onlyConfigurator() internal virtual;

    /// @dev To be implemented by inheriting contracts to restrict certain functions to a swap issuer role.
    function _onlySwapIssuer() internal virtual;

    /// @dev To be implemented by inheriting contracts to validate the caller's authorization for execute calls.
    function _validateExecuteCallAuth() internal virtual;

    /**
    * @dev Updates the handler contract callbacks based on the provided `_handler` and `_enabled` status.
    * @param _handler The handler contract to update the callbacks for.
    * @param _enabled Whether the handler contract's callbacks should be enabled or disabled.
    */
    function _updateHandlerContractCallbacks(
        IHandlerContract _handler,
        bool _enabled
    ) internal {
        bytes4[] memory handlerSigs = _handler.callbackSigs();
        unchecked {
            for (uint256 i = 0; i < handlerSigs.length; ++i) {
                bytes4 sig = handlerSigs[i];
                handlerContractCallbacks[_handler][sig] = _enabled;
                emit CallbackHandlerUpdated(sig, address(_handler), _enabled);
            }
        }
    }

    /**
    * @dev Handles a callback, i.e. an unknown method that this contract is
    *      not capable of handling.
    *      First tries to check and call `currentCallbackHandler` if it is
    *      set. If it is not set, check and call `defaultHandlers[msg.sig]`.
    *      Also validates that the handler contract is capable of handling
    *      this specific callback.
    * @return ret The returned data from the handler.
    */
    function _handleCallback() internal returns (bytes memory ret) {
        IHandlerContract handler = IHandlerContract(currentCallbackHandler);

        // no transient callback handler set
        if (address(handler) == address(0)) {
            // check if default handler exist for given sig
            handler = defaultHandlers[msg.sig];
            if (handler == IHandlerContract(address(0))) {
                revert CallbackHandlerNotSet();
            }
        }

        if (!handlerContracts[handler]) revert UnknownHandlerContract();

        if (!handlerContractCallbacks[handler][msg.sig]) {
            revert UnknownCallback();
        }

        ret = _delegatecall(address(handler), msg.data);
    }

    /**
    * @dev Performs a delegate call to the specified `_target` with the provided `_data`.
    * @param _target The address to delegate the call to.
    * @param _data The data to send with the delegate call.
    * @return ret The returned data from the delegate call.
    */
    function _delegatecall(
        address _target,
        bytes memory _data
    ) internal returns (bytes memory ret) {
        bool success;
        (success, ret) = _target.delegatecall(_data);
        if (!success) {
            /// @solidity memory-safe-assembly
            assembly {
                let length := mload(ret)
                let start := add(ret, 0x20)
                revert(start, length)
            }
        }
        return ret;
    }

    /**
    * @dev Modifier to ensure the specified `_handler` is a valid handler contract.
    * @param _handler The address of the handler contract to validate.
    */
    modifier withHandler(address _handler) {
        if (!handlerContracts[IHandlerContract(_handler)])
            revert UnknownHandlerContract();

        currentCallbackHandler = _handler;
        _;
        currentCallbackHandler = address(0);
    }

    /// @dev Modifier to ensure the caller of the function is the contract itself.
    modifier onlySelf() {
        if (msg.sender != address(this)) revert OnlySelf();
        _;
    }

    /// @dev External payable function to receive funds.
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IRewardRouterV2 {
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function claimEsGmx() external;

    function signalTransfer(address _receiver) external;

    function acceptTransfer(address _sender) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IAssetVault {
    function asset() external returns (address);
    function pauseDepositWithdraw() external;
    function unpauseDepositWithdraw() external;
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IFeeEscrow {
    function returnDepositFees() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IVaultFeesAndHooks {

    function getVaultRebalanceFees(
            address vault,
            uint256 lastRebalance
        ) external pure returns (
            uint256,
            uint256,
            uint256,
            uint256);

    function getWithdrawalFee(
            address vault,
            uint256 size
        ) external pure returns (
            uint256);

    function getDepositFee(
            uint256 size
        ) external pure returns (
            uint256);

    function beforeOpenRebalancePeriod(
            bytes memory _calldata
        ) external;

    function afterCloseRebalancePeriod(
            bytes memory _calldata
        ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Whitelist} from "../peripheral/Whitelist.sol";
import {NettingMath} from "../libraries/NettingMath.sol";
import {IGlpRebalanceRouter} from "../interfaces/IGlpRebalanceRouter.sol";
import {INettedPositionTracker} from "../interfaces/INettedPositionTracker.sol";
import {IVaultFeesAndHooks} from "../interfaces/IVaultFeesAndHooks.sol";
import {GlpHandler} from "../handlers/GlpHandler.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {IRewardRouterV2} from "../interfaces/IRewardRouterV2.sol";
import {UMAMI_TOTAL_VAULTS} from "../constants.sol";
import {ISwapManager} from "../interfaces/ISwapManager.sol";

/// @title AggregateVaultStorage
/// @author Umami DAO
/// @notice Storage inheritance for AggregateVault 
abstract contract AggregateVaultStorage {

    bytes32 public constant STORAGE_SLOT = keccak256("AggregateVault.storage");

    struct AssetVaultEntry {
        address vault;
        address token;
        uint256 feeWatermarkPPS;
        uint256 feeWatermarkDate;
        int256 epochDelta;
        uint256 lastCheckpointTvl;
        address timelockYieldBoost;
    }

    struct VaultState {
        uint256 epoch;
        bool rebalanceOpen;
        uint256 lastRebalanceTime;
        uint256[5] glpAllocation;
        int[5] aggregatePositions;
        int[5][5] externalPositions;
        address feeRecipient;
        address depositFeeEscrow;
        address withdrawalFeeEscrow;
        uint256[5] vaultCaps;
        uint256[5] rebalancePPS;
    }

    struct RebalanceState {
        uint256[5] glpAllocation;
        uint256[5] glpComposition;
        int256[5][5] externalPositions;
        int256[5] aggregatePositions;
        uint256 epoch;
        int256[5][5] adjustedExternalPositions;
    }

    struct VaultFees {
        uint256 performanceFee;
        uint256 managementFee;
        uint256 withdrawalFee;
        uint256 depositFee;
        uint256 timelockBoostAmount;
    }

    /// @dev Fees are 18-decimal places. For example: 20 * 10**18 = 20%
    struct VaultFeeParams {
        uint256 performanceFeePercent;
        uint256 managementFeePercent;
        uint256 withdrawalFeePercent;
        uint256 depositFeePercent;
    }

    struct AVStorage {
        /// @notice The array of asset vault entries.
        AssetVaultEntry[5] assetVaults;
        /// @notice The mapping of token addresses to asset vault indices.
        mapping(address => uint) tokenToAssetVaultIndex;
        /// @notice The mapping of vault indices to asset vault indices.
        mapping(address => uint) vaultToAssetVaultIndex;
        /// @notice The address of the GLP reward claim contract.
        address glpRewardClaimAddr;
        /// @notice The current vault state.
        VaultState vaultState;
        /// @notice The current rebalance state.
        RebalanceState rebalanceState;
        /// @notice The vault fees structure.
        VaultFees vaultFees;
        /// @notice Stores the amount of GLP attributed to each vault.
        uint256[5] vaultGlpAttribution;
        /// @notice Contract library used for routing GLP rebalance.
        IGlpRebalanceRouter glpRebalanceRouter;
        /// @notice The netted position tracker contract.
        INettedPositionTracker nettedPositionTracker;
        /// @notice The fee & hook helper contract.
        address feeAndHookHelper;
        /// @notice Maps epoch IDs to the last netted prices.
        mapping(uint256 => INettedPositionTracker.NettedPrices) lastNettedPrices;
        /// @notice The GLP handler contract.
        GlpHandler glpHandler;
        /// @notice The array of position manager contracts.
        IPositionManager[] positionManagers;
        /// @notice Flag to indicate whether netting should be checked.
        bool shouldCheckNetting;
        /// @notice The whitelist contract.
        Whitelist whitelist;
        /// @notice The address of the aggregate vault helper contract.
        address aggregateVaultHelper;
        /// @notice The array of active aggregate positions.
        int256[4] activeAggregatePositions;
        /// @notice The matrix of netted positions.
        int256[5][5] nettedPositions;
        /// @notice The matrix of active external positions.
        int256[5][5] activeExternalPositions;
        /// @notice The last GLP composition array.
        uint256[5] lastGlpComposition;
        /// @notice The netting math contract.
        NettingMath nettingMath;
        /// @notice The netted threshold value.
        uint256 nettedThreshold;
        /// @notice The netting price tolerance value.
        uint256 nettingPriceTolerance;
        /// @notice Glp rebalance tollerance.
        uint256 glpRebalanceTolerance;
        /// @notice The zero sum PnL threshold value.
        uint256 zeroSumPnlThreshold;
        /// @notice The Uniswap V3 swap manager contract.
        ISwapManager uniV3SwapManager;
        /// @notice Slippage tolerance on glp mints and burns.
        uint256 glpMintBurnSlippageTolerance;
        /// @notice The helper contract for vault hooks.
        address hookHelper;
        /// @notice BPS of the deposit and withdraw fees that go to the keeper.
        uint keeperShareBps;
        /// @notice keeper address that gets the deposit and withdraw fees' share.
        address keeper;
        /// @notice swap tolerance bps
        uint256 swapToleranceBps;
    }

    /**
    * @dev Retrieves the storage struct of the contract.
    * @return _storage The storage struct containing all contract state variables.
    */
    function _getStorage() internal pure returns (AVStorage storage _storage) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _storage.slot := slot
        }
    }

    /**
    * @dev Retrieves the current rebalance state from storage.
    * @return _rebalanceState The current rebalance state.
    */
    function _getRebalanceState()
        internal
        view
        returns (RebalanceState storage _rebalanceState)
    {
        _rebalanceState = _getStorage().rebalanceState;
    }

    /**
    * @dev Retrieves the asset vault entries array from storage.
    * @return _assetVaults The array of asset vault entries.
    */
    function _getAssetVaultEntries()
        internal
        view
        returns (AssetVaultEntry[5] storage _assetVaults)
    {
        _assetVaults = _getStorage().assetVaults;
    }

    /**
    * @dev Retrieves the vault state from storage.
    * @return _vaultState The current vault state.
    */
    function _getVaultState()
        internal
        view
        returns (VaultState storage _vaultState)
    {
        _vaultState = _getStorage().vaultState;
    }

    /**
    * @dev Retrieves the array of position managers from storage.
    * @return _positionManagers The array of position managers.
    */
    function _getPositionManagers()
        internal
        view
        returns (IPositionManager[] storage _positionManagers)
    {
        _positionManagers = _getStorage().positionManagers;
    }

    /**
    * @dev Retrieves the array of position managers from storage.
    * @return _glpHandler The array of position managers.
    */
    function _getGlpHandler() internal view returns (GlpHandler _glpHandler) {
        _glpHandler = _getStorage().glpHandler;
    }

    /**
    * @dev Retrieves the vault to asset vault index mapping from storage.
    * @return _vaultToAssetVaultIndex The mapping of vault addresses to asset vault indexes.
    */
    function _getVaultToAssetVaultIndex()
        internal
        view
        returns (mapping(address => uint) storage _vaultToAssetVaultIndex)
    {
        _vaultToAssetVaultIndex = _getStorage().vaultToAssetVaultIndex;
    }

    /**
    * @dev Retrieves the fee claim reward router from storage.
    * @return _rewardRouter The current reward router.
    */
    function _getFeeClaimRewardRouter()
        internal
        view
        returns (IRewardRouterV2 _rewardRouter)
    {
        _rewardRouter = IRewardRouterV2(_getStorage().glpRewardClaimAddr);
    }

    /**
    * @dev Retrieves the vault GLP attribution array from storage.
    * @return _vaultGlpAttribution The array of vault GLP attributions.
    */
    function _getVaultGlpAttribution()
        internal
        view
        returns (uint[5] storage _vaultGlpAttribution)
    {
        _vaultGlpAttribution = _getStorage().vaultGlpAttribution;
    }

    /**
    * @dev Retrieves the netted positions matrix from storage.
    * @return _nettedPositions The matrix of netted positions.
    */
    function _getNettedPositions()
        internal
        view
        returns (int256[5][5] storage _nettedPositions)
    {
        _nettedPositions = _getStorage().nettedPositions;
    }

    /**
    * @dev Retrieves the rebalance router from storage.
    * @return _rebalanceRouter The current rebalance router.
    */
    function _getRebalanceRouter()
        internal
        view
        returns (IGlpRebalanceRouter _rebalanceRouter)
    {
        _rebalanceRouter = _getStorage().glpRebalanceRouter;
    }

    /**
    * @dev Retrieves the netted position tracker from storage.
    * @return _nettedPositionTracker The current netted position tracker.
    */
    function _getNettedPositionTracker()
        internal
        view
        returns (INettedPositionTracker _nettedPositionTracker)
    {
        _nettedPositionTracker = _getStorage().nettedPositionTracker;
    }

    /**
    * @dev Retrieves the last netted prices mapping from storage.
    * @return _lastNettedPrices The mapping of epochs to netted prices.
    */
    function _getLastNettedPrices()
        internal
        view
        returns (
            mapping(uint256 => INettedPositionTracker.NettedPrices)
                storage _lastNettedPrices
        )
    {
        _lastNettedPrices = _getStorage().lastNettedPrices;
    }

    /**
    * @dev Retrieves the netted prices for a given epoch from storage.
    * @param _epoch The epoch number to get the netted prices for.
    * @return _nettedPrices The netted prices for the given epoch.
    */
    function _getEpochNettedPrice(
        uint _epoch
    )
        internal
        view
        returns (INettedPositionTracker.NettedPrices storage _nettedPrices)
    {
        _nettedPrices = _getLastNettedPrices()[_epoch];
    }

    /**
    * @dev Retrieves the fee and hook helper from storage.
    * @return _feeAndHookHelper The current fee & hook helper.
    */
    function _getFeeHookHelper()
        internal
        view
        returns (address _feeAndHookHelper)
    {
        _feeAndHookHelper = _getStorage().feeAndHookHelper;
    }

    /**
    * @dev Retrieves the vault fees struct from storage.
    * @return _vaultFees The current vault fees.
    */
    function _getVaultFees()
        internal
        view
        returns (VaultFees storage _vaultFees)
    {
        _vaultFees = _getStorage().vaultFees;
    }

    /**
    * @dev Retrieves the token to asset vault index mapping from storage.
    * @return _tokenToAssetVaultIndex The mapping of token addresses to asset vault indexes.
    */
    function _getTokenToAssetVaultIndex()
        internal
        view
        returns (mapping(address => uint) storage _tokenToAssetVaultIndex)
    {
        _tokenToAssetVaultIndex = _getStorage().tokenToAssetVaultIndex;
    }

    /**
    * @dev Retrieves the whitelist from storage.
    * @return _whitelist The current whitelist.
    */
    function _getWhitelist() internal view returns (Whitelist _whitelist) {
        _whitelist = _getStorage().whitelist;
    }

    /**
    * @dev Retrieves the netting math from storage.
    * @return _nettingMath The current netting math.
    */
    function _getNettingMath() internal view returns (NettingMath _nettingMath) {
        _nettingMath = _getStorage().nettingMath;
    }

    /**
    * @dev Retrieves the aggregate vault helper from storage.
    * @return _aggregateVaultHelper The current aggregate vault helper address.
    */
    function _getAggregateVaultHelper()
        internal
        view
        returns (address _aggregateVaultHelper)
    {
        _aggregateVaultHelper = _getStorage().aggregateVaultHelper;
    }

    /**
    * @dev Retrieves the netted threshold from storage.
    * @return _nettedThreshold The current netted threshold value.
    */
    function _getNettedThreshold()
        internal
        view
        returns (uint256 _nettedThreshold)
    {
        _nettedThreshold = _getStorage().nettedThreshold;
    }

    /**
    * @dev Sets the netted positions matrix in storage.
    * @param _nettedPositions The updated netted positions matrix.
    */
    function _setNettedPositions(int[5][5] memory _nettedPositions) internal {
        int[5][5] storage nettedPositions = _getNettedPositions();
        for (uint i = 0; i < 5; ++i) {
            for (uint j = 0; j < 5; ++j) {
                nettedPositions[i][j] = _nettedPositions[i][j];
            }
        }
    }

    /**
    * @dev Sets the vault GLP attribution array in storage.
    * @param _vaultGlpAttribution The updated vault GLP attribution array.
    */
    function _setVaultGlpAttribution(
        uint[5] memory _vaultGlpAttribution
    ) internal {
        uint[5] storage __vaultGlpAttribution = _getVaultGlpAttribution();
        for (uint i = 0; i < 5; ++i) {
            __vaultGlpAttribution[i] = _vaultGlpAttribution[i];
        }
    }

    /**
    * @dev Retrieves the asset vault entry for the given asset address.
    * @param _asset The asset address for which to retrieve the vault entry.
    * @return vault The asset vault entry for the given asset address.
    */
    function getVaultFromAsset(address _asset) public view returns (AssetVaultEntry memory vault) {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < 5; i++) {
            if (assetVaults[i].token == _asset) {
                return assetVaults[i];
            }
        }
        return vault;
    }

    /**
    * @dev Retrieves the netting price tolerance from storage.
    * @return _tolerance The current netting price tolerance value.
    */
    function _getNettingPriceTolerance()
        internal
        view
        returns (uint _tolerance)
    {
        _tolerance = _getStorage().nettingPriceTolerance;
    }

    /**
    * @dev Retrieves the zero sum PnL threshold from storage.
    * @return _zeroSumPnlThreshold The current zero sum PnL threshold value.
    */
    function _getZeroSumPnlThreshold()
        internal
        view
        returns (uint256 _zeroSumPnlThreshold)
    {
        _zeroSumPnlThreshold = _getStorage().zeroSumPnlThreshold;
    }

    /**
    * @dev Updates the external positions in the vault state based on the given rebalance storage.
    * @param _rebalanceStorage The rebalance storage containing the updated external positions.
    */
    function _setStateExternalPositions(
        RebalanceState storage _rebalanceStorage
    ) internal {
        VaultState storage vaultState = _getVaultState();
        for (uint i = 0; i < UMAMI_TOTAL_VAULTS; ++i) {
            for (uint j = 0; j < UMAMI_TOTAL_VAULTS; ++j) {
                vaultState.externalPositions[i][j] = _rebalanceStorage
                    .adjustedExternalPositions[i][j];
            }
        }
    }

    /**
    * @dev Retrieves the Uniswap V3 swap manager from storage.
    * @return _swapManager The current Uniswap V3 swap manager.
    */
    function _getUniV3SwapManager()
        internal
        view
        returns (ISwapManager _swapManager)
    {
        _swapManager = _getStorage().uniV3SwapManager;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {SafeCast} from "./SafeCast.sol";
import {Solarray} from "./Solarray.sol";

/// @title NettingMath
/// @author Umami DAO
/// @notice Contains math for validating a set of netted parameters
contract NettingMath {

    // STORAGE 
    // ------------------------------------------------------------------------------------------

    struct NettedParams {
        uint256 vaultCumulativeGlpTvl;
        uint256[5] glpComposition;
        uint256 nettedThreshold;
    }

    struct NettedState {
        uint256[5] glpHeld;
        int256[5] externalPositions;
    }

    uint256 public immutable SCALE = 1e18;
    uint256 public immutable BIPS = 10000;

    // PUBLIC 
    // ------------------------------------------------------------------------------------------
    
    /**
    * @notice Calculates the GLP exposure and vault ratio for each position
    * @param nettingState The current netted state containing GLP held and external positions
    * @param _vaultCumulativeGlpTvl The vault's cumulative GLP TVL
    * @param _glpComposition The GLP composition as an array of five uint256 values
    * @param externalPositions A 5x5 matrix of external positions
    * @return glpExposure An array of GLP exposure for each position
    * @return vaultRatio An array of vault ratios for each position
    */
    function vaultDeltaAdjustment(NettedState memory nettingState, uint256 _vaultCumulativeGlpTvl, uint256[5] memory _glpComposition, int256[5][5] memory externalPositions, uint256 _threshold)
        public
        pure
        returns (
            uint256[5] memory glpExposure,
            uint256[5] memory vaultRatio
        )
        {
            int256 rowHedgeSum;
            uint zeroDivisor;
            for (uint256 i = 0; i < nettingState.glpHeld.length; i++) {
                glpExposure[i] =  _vaultCumulativeGlpTvl * _glpComposition[i] / SCALE;

                if (nettingState.externalPositions[i] < 0){
                    glpExposure[i] += uint256(-nettingState.externalPositions[i]);
                } else {
                    // CASE: glp allocation close to 0
                    if (glpExposure[i] < uint256(nettingState.externalPositions[i])){
                        glpExposure[i] = uint256(nettingState.externalPositions[i]) - glpExposure[i];
                    } else {
                        glpExposure[i] -= uint256(nettingState.externalPositions[i]);
                    }
                }
                
                // subtract/add vault over/under allocation amount
                rowHedgeSum = Solarray.arraySum(externalPositions[i]);
                if (rowHedgeSum < 0){
                    glpExposure[i] -= uint256(-rowHedgeSum);
                } else {
                    glpExposure[i] += uint256(rowHedgeSum);
                }

                if (nettingState.glpHeld[i] == 0) {
                    if (_vaultCumulativeGlpTvl == 0 && glpExposure[i] == 0) {
                        vaultRatio[i] = SCALE;
                    } else {
                        zeroDivisor = _vaultCumulativeGlpTvl != 0 ? _vaultCumulativeGlpTvl : glpExposure[i];
                        vaultRatio[i] = SCALE + (glpExposure[i] * SCALE / zeroDivisor);
                    }
                } else {
                    vaultRatio[i] = glpExposure[i] * SCALE / nettingState.glpHeld[i];
                }
            }
        }

    /**
    * @notice Calculates the netted and exposure matrices for the given positions and GLP composition
    * @param externalPositions A 5x5 matrix of external positions
    * @param glpComposition The GLP composition as an array of five uint256 values
    * @param glpHeldDollars The GLP held as an array of five uint256 values
    * @return nettedMatrix A 5x5 matrix of netted positions
    * @return exposureMatrix A 5x5 matrix of exposures
    */
    function calculateNettedPositions(int256[5][5] memory externalPositions, uint256[5] memory glpComposition, uint256[5] memory glpHeldDollars) 
        public  
        pure
        returns (
            int256[5][5] memory nettedMatrix,
            int256[5][5] memory exposureMatrix
        ) 
        {
            int256[5] memory vaultGlpExposure;
            for (uint256 idx = 0; idx < externalPositions.length; idx++) {
                vaultGlpExposure = _vaultExposureInt(glpHeldDollars[idx], glpComposition);
                exposureMatrix[idx] = vaultGlpExposure;
                nettedMatrix[idx] = _nettedPositionRow(externalPositions[idx], vaultGlpExposure, idx);
            }
        }

    /**
    * @notice Determines whether the given netted state is within the netted threshold
    * @param nettingState The current netted state containing GLP held and external positions
    * @param params The netted parameters containing vault cumulative GLP TVL, GLP composition, and netted threshold
    * @param externalPositions A 5x5 matrix of external positions
    * @return netted A boolean indicating whether the given netted state is within the netted threshold
    */
    function isNetted(NettedState memory nettingState, NettedParams memory params, int256[5][5] memory externalPositions) public pure returns (bool netted) {
        uint256[5] memory glpExposure;
        uint256[5] memory vaultRatio;
        // if the vault is 0'd out 
        if (params.vaultCumulativeGlpTvl < 1e18) return true;
        // note positions are NOT scaled up by a factor x to account for counterparty affect when using gmx.
        // here we take the unscaled externalPositions as input
        (glpExposure, vaultRatio) = vaultDeltaAdjustment(nettingState, params.vaultCumulativeGlpTvl, params.glpComposition, externalPositions, params.nettedThreshold);

        uint256 upper = SCALE * (BIPS + params.nettedThreshold) / BIPS;
        uint256 lower = SCALE * (BIPS - params.nettedThreshold) / BIPS;
        netted = true;
        for (uint256 i = 0; i < vaultRatio.length; i++) {
            if (vaultRatio[i] > upper || vaultRatio[i] < lower) {
                netted = false;
            }
        } 
    }

    // INTERNAL 
    // ------------------------------------------------------------------------------------------

    function _nettedPositionRow(int256[5] memory _hedgeAllocation, int256[5] memory _glpAllocation, uint256 _vaultIdx) internal pure returns (int256[5] memory nettedPositions) {
        for (uint256 i = 0; i < _hedgeAllocation.length; i++) {
            if (i == _vaultIdx) {
                nettedPositions[i] = _glpAllocation[i];
            } else {
                nettedPositions[i] = _glpAllocation[i] - _hedgeAllocation[i];
            }
        }
    }

    function _vaultExposureInt(uint256 glpHeldDollars, uint256[5] memory glpComposition) internal pure returns (int256[5] memory exposure) {
        for (uint256 i = 0; i < glpComposition.length; i++) {
            exposure[i] = SafeCast.toInt256((glpHeldDollars * glpComposition[i]) / 1e18);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeCast} from "./SafeCast.sol";

/// @title Solarray
/// @author Umami DAO
/// @notice Array functions 
library Solarray {

    function uint256s(uint256 a,uint256 b,uint256 c,uint256 d) internal pure returns (uint256[4] memory) {
        uint256[4] memory arr;
		arr[0] = a;
		arr[1] = b;
		arr[2] = c;
		arr[3] = d;
        return arr;
    }

    function uint256s(uint256 a,uint256 b,uint256 c,uint256 d,uint256 e) internal pure returns (uint256[5] memory) {
        uint256[5] memory arr;
		arr[0] = a;
		arr[1] = b;
		arr[2] = c;
		arr[3] = d;
		arr[4] = e;
        return arr;
    }

    function int256s(int256 a,int256 b,int256 c,int256 d) internal pure returns (int256[4] memory) {
        int256[4] memory arr;
		arr[0] = a;
		arr[1] = b;
		arr[2] = c;
		arr[3] = d;
        return arr;
    }

    function int256s(int256 a,int256 b,int256 c,int256 d,int256 e) internal pure returns (int256[5] memory) {
        int256[5] memory arr;
		arr[0] = a;
		arr[1] = b;
		arr[2] = c;
		arr[3] = d;
		arr[4] = e;
        return arr;
    }

    function addresss(address a,address b,address c,address d,address e) internal pure returns (address[5] memory) {
        address[5] memory arr;
		arr[0] = a;
		arr[1] = b;
		arr[2] = c;
		arr[3] = d;
		arr[4] = e;
        return arr;
    }

    function intToUintArray(int256[5] memory _array) internal pure returns (uint256[5] memory uintArray) {
        require(_array[0] > 0 && _array[1] > 0 && _array[2] > 0 && _array[3] > 0 && _array[4] > 0, "Solarray: intToUintArray: negative value");
        uintArray = [
            uint256(_array[0]),
            uint256(_array[1]),
            uint256(_array[2]),
            uint256(_array[3]),
            uint256(_array[4])
        ];
    }

	function arraySum(int256[4] memory _array) internal pure returns (int256 sum) {
        for (uint256 i = 0; i < _array.length; i++) {
            sum += _array[i];
        }
    }

	function arraySum(int256[5] memory _array) internal pure returns (int256 sum) {
        for (uint256 i = 0; i < _array.length; i++) {
            sum += _array[i];
        }
    }

    function arraySum(uint256[5] memory _array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < _array.length; i++) {
            sum += _array[i];
        }
    }

    function arraySumAbsolute(int256[5] memory _array) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < _array.length; i++) {
            sum += _array[i] > 0 ? uint(_array[i]) : uint(-_array[i]);
        }
    }

    function arrayDifference(uint256[5] memory _base, int256[5] memory _difference) internal pure returns (int256[5] memory result) {
        for (uint256 i = 0; i < 5; i++) {
            result[i] = SafeCast.toInt256(_base[i]) + _difference[i];
        }
    }

	function scaleArray(uint256[4] memory _array, uint256 _scale) internal pure returns (uint256[4] memory _retArray) {
        for (uint256 i = 0; i < _array.length; i++) {
            _retArray[i] = _array[i] * _scale / 1e18;
        }
    }

    function scaleArray(uint256[5] memory _array, uint256 _scale) internal pure returns (uint256[5] memory _retArray) {
        for (uint256 i = 0; i < _array.length; i++) {
            _retArray[i] = _array[i] * _scale / 1e18;
        }
    }

	function sumColumns(int256[5][4] memory _array) internal pure returns (int256[4] memory _retArray) {
        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < 5; j++) {
                _retArray[i] += _array[j][i];
            }
        }
    }

    function sumColumns(int256[5][5] memory _array) internal pure returns (int256[5] memory _retArray) {
        for (uint256 i = 0; i < _array.length; i++) {
            for (uint256 j = 0; j < _array.length; j++) {
                _retArray[i] += _array[j][i];
            }
        }
    }

    function int5FixedToDynamic(
        int[5] memory _arr
    ) public view returns (int256[] memory _retArr) {
        bytes memory _ret = fixedToDynamicArray(abi.encode(_arr), 5);
        /// @solidity memory-safe-assembly
        assembly {
            _retArr := _ret // point to the array
        }
    }

    function uint5FixedToDynamic(
        uint[5] memory _arr
    ) internal view returns (uint[] memory _retArr) {
        bytes memory _ret = fixedToDynamicArray(abi.encode(_arr), 5);
        /// @solidity memory-safe-assembly
        assembly {
            _retArr := _ret // point to the array
        }
    }

    function fixedToDynamicArray(
        bytes memory _arr,
        uint _fixedSize
    ) public view returns (bytes memory _retArray) {
        (bool success, bytes memory data) = address(0x04).staticcall(_arr);
        require(success, "identity precompile failed");
        /// @solidity memory-safe-assembly
        assembly {
            _retArray := data // point to the copied data
            mstore(_retArray, _fixedSize) // store array length
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

address constant GMX_POSITION_ROUTER = 0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868;
address constant GMX_VAULT = 0x489ee077994B6658eAfA855C308275EAd8097C4A;
address constant GMX_ROUTER = 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
address constant GMX_GLP_REWARD_ROUTER = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
address constant GMX_VAULT_PRICE_FEED = 0x2d68011bcA022ed0E474264145F46CC4de96a002;
address constant GMX_GLP_MANAGER = 0x3963FfC9dff443c2A94f21b129D429891E32ec18;
address constant GMX_FEE_STAKED_GLP = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
address constant GMX_STAKED_GLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
address constant GMX_FEE_GLP = 0x4e971a87900b931fF39d1Aad67697F49835400b6;
address constant GMX_GLP = 0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258;
address constant GMX_GLP_CLAIM_REWARDS = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
address constant GMX_ACCOUNT_TRANSFER = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;

bytes32 constant GMX_REFERRAL = "umami";

address constant TOKEN_DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
address constant TOKEN_FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
address constant TOKEN_USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
address constant TOKEN_USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
address constant TOKEN_LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
address constant TOKEN_UNI = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;
address constant TOKEN_WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
address constant TOKEN_WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
address constant TOKEN_UMAMI = 0x1622bF67e6e5747b81866fE0b85178a93C7F86e3;

address constant ERC1967_FACTORY = 0x0000000000006396FF2a80c067f99B3d2Ab4Df24;

uint constant DECIMALS_USDC = 6;
uint constant DECIMALS_USDT = 6;
uint constant DECIMALS_DAI = 18;
uint constant DECIMALS_FRAX = 18;

uint constant DECIMALS_WETH = 18;
uint constant DECIMALS_WBTC = 8;
uint constant DECIMALS_LINK = 18;
uint constant DECIMALS_UNI = 18;

address constant AAVE_ORACLE = 0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7;
address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
address constant AAVE_POOL_ADDRESS_PROVIDER = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
uint16 constant AAVE_REFERRAL_CODE = 0;

address constant UNISWAP_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address constant UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
address constant ODOS_ROUTER = 0xdd94018F54e565dbfc939F7C44a16e163FaAb331;

uint constant UMAMI_TOTAL_VAULTS = 5;
address constant UMAMI_TREASURY = 0xB0B4bd94D656353a30773Ac883591DDBaBC0c0bA;
address constant UMAMI_DEV_WALLET = 0x4e5645bee4eD80C6FEe04DCC15D14A3AC956748A;

uint constant VAULT_PERFORMANCE_FEE = 3e18;
uint constant VAULT_MANAGEMENT_FEE = 2e18;
uint constant VAULT_DEPOSIT_FEE = 0.75e18;
uint constant VAULT_WITHDRAWAL_FEE = 0.75e18;
uint constant VAULT_TIMELOCK_BOOST_FEE = 2e18;
uint constant NUMBER_OF_REBALANCES_PER_YEAR = 12 * 365;
uint constant TIMELOCK_DURATION = 86400 * 14; // 14 days

address constant KEEPER_RECIPIENT = 0xc7d873647AEa26902b9C2C243C21364468474b34;
uint constant KEEPER_SHARE_BPS = 1000;
uint constant SWAP_TOLERANCE_BPS = 500;
address constant DEPLOYMENT_MULTISIG = 0xb137d135Dc8482B633265c21191F50a4bA26145d;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IHandlerContract} from "../interfaces/IHandlerContract.sol";
import {BaseHandler} from "./BaseHandler.sol";
import {GMX_GLP_REWARD_ROUTER, GMX_VAULT, TOKEN_FRAX} from "../constants.sol";
import {IGlpRewardRouter} from "../interfaces/gmx/IGlpRewardRouter.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IVault} from "../interfaces/gmx/IVault.sol";
import {IGlpManager} from "../interfaces/gmx/IGlpManager.sol";
import {IPositionRouter} from "../interfaces/gmx/IPositionRouter.sol";

/// @title GlpHandler
/// @author Umami DAO
/// @notice A handler contract for managing GLP related functionalities
contract GlpHandler is BaseHandler {
    using SafeTransferLib for ERC20;

    error NotStableToken(address _token);
    error NoMintCapacity();

    struct CollateralUtilization {
        address token;
        uint poolAmount;
        uint reservedAmount;
        uint utilization;
    }

    bytes32 public constant GLP_HANDLER_CONFIG_SLOT =
        keccak256("handlers.glp.config");

    IGlpRewardRouter public constant glpRewardRouter =
        IGlpRewardRouter(GMX_GLP_REWARD_ROUTER);
    IVault public constant vault = IVault(GMX_VAULT);
    uint public constant FUNDING_RATE_PRECISION = 1_000_000;
    uint256 public constant USDG_DECIMALS = 18;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FALLBACK_SWAP_SLIPPAGE = 1000;

    IGlpManager public immutable glpManager;
    IPositionRouter public immutable positionRouter;

    constructor(
        IGlpManager _glpManager,
        IPositionRouter _positionRouter
    ) {
        glpManager = _glpManager;
        positionRouter = _positionRouter;
    }

    /**
     * @dev Returns the GLP composition for the given volatile tokens
     * @param volatileTokens An array of volatile token addresses
     * @return _composition An array of the GLP composition for the given volatile tokens
     */
    function getGlpComposition(
        address[] calldata volatileTokens
    ) external view returns (uint[] memory _composition) {
        uint precision = 1e18;

        _composition = new uint[](volatileTokens.length + 1);

        address[] memory stableTokens = _getUnderlyingGlpTokens(true);
        uint totalStablesWorth;
        for (uint i = 0; i < stableTokens.length; ++i) {
            (, uint _usdgAmount) = _getPoolAmounts(stableTokens[i]);
            totalStablesWorth += _usdgAmount;
        }

        uint[] memory volatilesWorth = new uint[](volatileTokens.length);
        uint totalVolatilesWorth;

        for (uint i = 0; i < volatileTokens.length; ++i) {
            (, uint _usdgAmount) = _getPoolAmounts(volatileTokens[i]);
            volatilesWorth[i] = _usdgAmount;
            totalVolatilesWorth += _usdgAmount;
        }

        uint totalGlpWorth = totalVolatilesWorth + totalStablesWorth;

        uint totalVolatilesComposition;
        for (uint i = 0; i < volatileTokens.length; ++i) {
            _composition[i] = (volatilesWorth[i] * precision) / totalGlpWorth;
            totalVolatilesComposition += _composition[i];
        }

        // add stables composition
        _composition[volatileTokens.length] =
            precision -
            totalVolatilesComposition;
    }

    /**
     * @dev Previews the amount of token to be received for minting or burning the specified GLP amount
     * @param _tokenOut The output token to be received
     * @param _glpAmount The amount of GLP to be minted or burned
     * @param _mint True if minting, false if burning
     * @return _amtOut The amount of output token to be received
     */
    function previewGlpMintBurn(
        address _tokenOut,
        uint _glpAmount,
        bool _mint
    ) public view returns (uint _amtOut) {
        uint priceMin = glpManager.getPrice(_mint);
        uint usdgAmount = (_glpAmount * priceMin) / 1e30;
        uint maxFees = vault.mintBurnFeeBasisPoints() + vault.taxBasisPoints();

        uint usdgAmountFees = _mint
            ? (usdgAmount * (1e4 + maxFees)) / 1e4
            : (usdgAmount * (1e4 - maxFees)) / 1e4;

        uint tokenPrice = vault.getMaxPrice(_tokenOut);
        uint tokenDecimals = ERC20(_tokenOut).decimals();
        _amtOut = (usdgAmountFees * 1e30) / tokenPrice;
        return (_amtOut * (10 ** tokenDecimals)) / (10 ** 18);
    }

    /**
     * @dev Previews the amount of token to be received for minting and burning the specified GLP amount
     * @param _tokenOut The output token to be received
     * @param _glpAmount The amount of GLP to be minted and burned
     * @return _amtOut The average amount of output token to be received
     */
    function previewGlpMintBurn(
        address _tokenOut,
        uint _glpAmount
    ) external view returns (uint _amtOut) {
        uint mintAmount = previewGlpMintBurn(_tokenOut, _glpAmount, true);
        uint burnAmount = previewGlpMintBurn(_tokenOut, _glpAmount, false);
        _amtOut = (mintAmount + burnAmount) / 2;
    }

    /**
     * @dev Returns the price of the given token with the specified number of decimals
     * @param _token The token to get the price for
     * @param decimals The number of decimals for the returned price
     * @return _price The price of the token with the specified number of decimals
     */
    function getTokenPrice(
        address _token,
        uint decimals
    ) public view returns (uint _price) {
        uint maxPrice = vault.getMaxPrice(_token);
        uint minPrice = vault.getMinPrice(_token);
        uint price = (maxPrice + minPrice) / 2;
        _price = (price * (10 ** decimals)) / 1e30;
    }

    /**
     * @dev Returns the minimum price in GMX of the given token with the specified number of decimals
     * @param _token The token to get the minimum price for
     * @param decimals The number of decimals for the returned minimum price
     * @return _price The minimum price of the token with the specified number of decimals
     */
    function getTokenMinPrice(
        address _token,
        uint decimals
    ) public view returns (uint _price) {
        uint minPrice = vault.getMinPrice(_token);
        _price = (minPrice * (10 ** decimals)) / 1e30;
    }

    /**
    * @dev Returns the amount of the specified token equivalent to the given USD amount
    * @param _usdAmount The USD amount to be converted
    * @param _usdDecimals The number of decimals for the USD amount
    * @param _token The token to be converted to
    * @return _amountOut The equivalent amount of the specified token
    */
    function getUsdToToken(
        uint _usdAmount,
        uint _usdDecimals,
        address _token
    ) public view returns (uint _amountOut) {
        uint usdAmount = (_usdAmount * 1e30) / 10 ** _usdDecimals;
        uint decimals = ERC20(_token).decimals();
        uint price = getTokenPrice(_token, 30);
        _amountOut = (usdAmount * (10 ** decimals)) / price;
    }

    /**
     * @dev Returns the amount of USD equivalent to the given token amount
     * @param _token The token to be converted from
     * @param _tokenAmount The amount of the token to be converted
     * @param _usdDecimals The number of decimals for the returned USD amount
     * @return _usdAmount The equivalent amount of USD
     */
    function getTokenToUsd(
        address _token,
        uint _tokenAmount,
        uint _usdDecimals
    ) public view returns (uint _usdAmount) {
        uint decimals = ERC20(_token).decimals();
        uint price = getTokenPrice(_token, 30);
        _usdAmount =
            (_tokenAmount * price * 10 ** _usdDecimals) /
            ((10 ** decimals) * (10 ** 30));
    }

    /**
    * @dev Returns the equivalent amount of GLP for the given USD amount
    * @param _usdAmount The USD amount to be converted
    * @param _usdDecimals The number of decimals for the USD amount
    * @param _max True to use the maximum price for conversion, false to use the minimum price
    * @return _glpAmount The equivalent amount of GLP
    */
    function usdToGlp(
        uint _usdAmount,
        uint _usdDecimals,
        bool _max
    ) external view returns (uint _glpAmount) {
        uint usdAmount = (_usdAmount * 1e30) / 10 ** _usdDecimals;
        uint glpPrice = glpManager.getPrice(_max);
        _glpAmount = (usdAmount * 1e18) / glpPrice;
    }

    /**
    * @dev Returns the average price of GLP
    * @return _price The average price of GLP
    */
    function getGlpPrice() external view returns (uint _price) {
        uint maxPrice = glpManager.getPrice(true);
        uint minPrice = glpManager.getPrice(false);
        _price = (maxPrice + minPrice) / 2;
    }

    /**
    * @dev Returns the GLP price based on the given _max parameter
    * @param _max True to return the maximum price, false to return the minimum price
    * @return _price The GLP price
    */
    function getGlpPrice(bool _max) external view returns (uint _price) {
        _price = glpManager.getPrice(_max);
    }

    /**
    * @dev Returns the minimum output amount of tokenOut for the given input amount and tokens
    * @param _tokenIn The input token
    * @param _tokenOut The output token
    * @param _amountIn The amount of input tokens
    * @return minOut The minimum output amount of tokenOut
    */
    function tokenToToken(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _toleranceBps
    ) public view returns (uint minOut) {
        uint tokenInDecimals = ERC20(_tokenIn).decimals();
        uint tokenOutDecimals = ERC20(_tokenOut).decimals();
        uint tokenInDollars = _amountIn * getTokenPrice(_tokenIn, 30);
        minOut = (tokenInDollars / getTokenPrice(_tokenOut, 30)) * ((BASIS_POINTS_DIVISOR - _toleranceBps)) / BASIS_POINTS_DIVISOR;
        minOut = minOut * 10 ** tokenOutDecimals / 10 ** tokenInDecimals;
    }

    /**
    * @dev Returns the minimum output amount of tokenOut for the given input amount and tokens
    * @param _tokenIn The input token
    * @param _tokenOut The output token
    * @param _amountIn The amount of input tokens
    * @return minOut The minimum output amount of tokenOut
    */
    function tokenToToken(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
    ) public view returns (uint minOut) {
        minOut = tokenToToken(_tokenIn, _tokenOut, _amountIn, FALLBACK_SWAP_SLIPPAGE);
    }

    /**
    * @dev Returns the available liquidity and collateral utilization for long positions in the specified index token
    * @param _indexToken The index token to query for
    * @return _notional The available notional liquidity for long positions
    * @return _util The collateral utilization data for the specified index token
    */
    function getAvailableLiquidityLong(
        address _indexToken
    )
        external
        view
        returns (uint _notional, CollateralUtilization memory _util)
    {
        uint maxLongs = positionRouter.maxGlobalLongSizes(_indexToken);
        uint existingLongs = vault.guaranteedUsd(_indexToken);
        uint poolAmount = vault.poolAmounts(_indexToken);
        uint reservedAmount = vault.reservedAmounts(_indexToken);
        uint availableAmount = poolAmount - reservedAmount;
        uint maxPrice = vault.getMaxPrice(_indexToken); // price of 1 token in 30 decimals
        uint availableUsd = (availableAmount * maxPrice) /
            (10 ** ERC20(_indexToken).decimals());

        _util.token = _indexToken;
        _util.poolAmount = poolAmount;
        _util.reservedAmount = reservedAmount;
        _util.utilization =
            (reservedAmount * FUNDING_RATE_PRECISION) /
            poolAmount;

        if (maxLongs > existingLongs) {
            uint availableLongs = maxLongs - existingLongs;
            _notional = availableLongs > availableUsd
                ? availableUsd
                : availableLongs;
        } else {
            _notional = 0;
        }
    }

    /**
    * @dev Returns the available liquidity and collateral utilization for short positions in the specified index token
    * @param _indexToken The index token to query for
    * @param _collateralTokens An array of collateral token addresses to query for
    * @return _availableNotional The available notional liquidity for short positions
    * @return _availableStables An array of available stablecoin notional amounts for each collateral token
    * @return _utilizations An array of collateral utilization data for each collateral token
    */
    function getAvailableLiquidityShort(
        address _indexToken,
        address[] calldata _collateralTokens
    )
        external
        view
        returns (
            uint _availableNotional,
            uint[] memory _availableStables,
            CollateralUtilization[] memory _utilizations
        )
    {
        _availableStables = new uint[](_collateralTokens.length);
        _utilizations = new CollateralUtilization[](_collateralTokens.length);

        uint maxShorts = positionRouter.maxGlobalShortSizes(_indexToken);
        uint globalShorts = vault.globalShortSizes(_indexToken);
        _availableNotional = maxShorts > globalShorts
            ? maxShorts - globalShorts
            : 0;

        for (uint i = 0; i < _collateralTokens.length; ++i) {
            address _collateralToken = _collateralTokens[i];
            _validateStableToken(_collateralToken);

            uint poolAmounts = vault.poolAmounts(_collateralToken);
            uint reservedAmounts = vault.reservedAmounts(_collateralToken);
            uint availableAmount = poolAmounts - reservedAmounts;
            uint availableStableNotional = (availableAmount * 1e30) /
                (10 ** ERC20(_collateralToken).decimals());
            _availableStables[i] = _availableNotional > availableStableNotional
                ? availableStableNotional
                : _availableNotional;

            _utilizations[i].token = _collateralToken;
            _utilizations[i].poolAmount = poolAmounts;
            _utilizations[i].reservedAmount = reservedAmounts;
            _utilizations[i].utilization =
                (reservedAmounts * FUNDING_RATE_PRECISION) /
                poolAmounts;
        }
    }

    /**
    * @dev Calculates the increased token amount for minting considering the fees
    * @param _mintToken The token to be minted
    * @param _tokenAmount The amount of the token to be minted
    * @return increasedTokenAmount The increased
    */
    function calculateTokenMintAmount(address _mintToken, uint _tokenAmount) external view returns (uint256 increasedTokenAmount) {
        uint price = getTokenMinPrice(_mintToken, 30);
        uint256 usdgAmount = _tokenAmount * price / 1e30;
        uint feeBasisPoints = vault.getFeeBasisPoints(_mintToken, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);
        uint increasePoints = BASIS_POINTS_DIVISOR * 1e30 / (BASIS_POINTS_DIVISOR - feeBasisPoints);
        increasedTokenAmount = increasePoints * _tokenAmount / 1e30;
    }

    function routeGlpMint(address _intendedMintAsset, uint256 _dollarMint, bool _onlyStables) external view returns (address _mintToken, uint256 _minOut) {
        if (checkGlpMintCapacity(_intendedMintAsset, _dollarMint)) {
            return (_intendedMintAsset, 0);
        } else {
            address[] memory possibleMintTokens = _getUnderlyingGlpTokens(_onlyStables);
            for (uint i = 0; i < possibleMintTokens.length; ++i) {
                // note frax removed due to low liquidity
                if (checkGlpMintCapacity(possibleMintTokens[i], _dollarMint) && possibleMintTokens[i] != TOKEN_FRAX) {
                    return (possibleMintTokens[i], getUsdToToken(_dollarMint, 18, possibleMintTokens[i]) * (BASIS_POINTS_DIVISOR - FALLBACK_SWAP_SLIPPAGE) / BASIS_POINTS_DIVISOR);
                }
            }
            revert NoMintCapacity();
        }
    }
    
    /**
    * @notice Checks whether the GLP mint has sufficient capacity for the specified asset and amount.
    * @param intendedMintAsset The address of the asset to be minted.
    * @param dollarMint The amount of dollars to be minted.
    * @return - True if the mint capacity is sufficient, false otherwise.
    */
    function checkGlpMintCapacity(address intendedMintAsset, uint256 dollarMint) public view returns (bool) {
        uint256 tokenAmount = getUsdToToken(dollarMint, 18, intendedMintAsset); // 18 decimal standard for calcs
        uint price = vault.getMinPrice(intendedMintAsset);
        uint256 usdgAmount = tokenAmount * price / 1e30;
        usdgAmount = adjustForDecimals(usdgAmount, intendedMintAsset, vault.usdg());
        require(usdgAmount > 0, "GlpHandler: !usdgAmount");
        uint256 feeBasisPoints = vault.getFeeBasisPoints(intendedMintAsset, usdgAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);
        uint256 amountAfterFees = tokenAmount * (BASIS_POINTS_DIVISOR - feeBasisPoints) / BASIS_POINTS_DIVISOR;
        uint256 mintAmount = amountAfterFees * price / 1e30;
        mintAmount = adjustForDecimals(mintAmount, intendedMintAsset, vault.usdg());
        uint256 currentUsdgAmount = vault.usdgAmounts(intendedMintAsset) + mintAmount;
        return  currentUsdgAmount <= vault.maxUsdgAmounts(intendedMintAsset);
    }

    /**
    * @notice Adjusts the given amount for the difference in decimals between two tokens.
    * @param _amount The amount to be adjusted.
    * @param _tokenDiv The address of the token to divide the amount by.
    * @param _tokenMul The address of the token to multiply the amount with.
    * @return The adjusted amount.
    */
    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) public view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == vault.usdg() ? USDG_DECIMALS : ERC20(_tokenDiv).decimals();
        uint256 decimalsMul = _tokenMul == vault.usdg() ? USDG_DECIMALS : ERC20(_tokenMul).decimals();
        return _amount * 10 ** decimalsMul / 10 ** decimalsDiv;
    }

    /**
    * @notice Returns an array of underlying GLP tokens based on the input parameter.
    * @param onlyStables If true, returns only stable tokens; otherwise, returns non-stable tokens.
    * @return _tokens An array of addresses representing the underlying GLP tokens.
    */
    function _getUnderlyingGlpTokens(
        bool onlyStables
    ) internal view returns (address[] memory _tokens) {
        address[] memory allWhitelistedTokens = _allWhitelistedTokens();
        _tokens = new address[](allWhitelistedTokens.length);
        uint foundTokens = 0;

        for (uint i = 0; i < allWhitelistedTokens.length; ++i) {
            bool isStable = vault.stableTokens(allWhitelistedTokens[i]);
            if (onlyStables && isStable) {
                _tokens[foundTokens++] = allWhitelistedTokens[i];
            } else if (!onlyStables && !isStable) {
                _tokens[foundTokens++] = allWhitelistedTokens[i];
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            mstore(_tokens, foundTokens) // change the array size to the actual number of tokens found
        }
    }

    /**
    * @notice Returns an array of all whitelisted tokens in the vault.
    * @return _tokens An array of addresses representing the whitelisted tokens.
    */
    function _allWhitelistedTokens()
        internal
        view
        returns (address[] memory _tokens)
    {
        _tokens = new address[](vault.allWhitelistedTokensLength());
        for (uint i = 0; i < _tokens.length; ++i) {
            _tokens[i] = vault.allWhitelistedTokens(i);
        }
    }

    /**
    * @notice Returns the pool amounts for the specified token.
    * @param _token The address of the token.
    * @return _tokenAmount The amount of the token in the pool.
    * @return _usdgAmount The amount of USDG in the pool, based on the token's average price.
    */
    function _getPoolAmounts(
        address _token
    ) internal view returns (uint _tokenAmount, uint _usdgAmount) {
        _tokenAmount = vault.poolAmounts(_token);
        uint maxPrice = vault.getMaxPrice(_token);
        uint minPrice = vault.getMinPrice(_token);
        uint tokenDecimals = vault.tokenDecimals(_token);
        uint avgPrice = (minPrice + maxPrice) / 2; // this should remove the spread from the price
        _usdgAmount = (_tokenAmount * avgPrice) / 10 ** tokenDecimals;
    }

    /**
    * @notice Returns the static AUM of the GLP based on pool amounts and prices.
    * @return _aum The static AUM value.
    */
    function _getGlpStaticAum() internal view returns (uint _aum) {
        address[] memory tokens = _allWhitelistedTokens();
        for (uint i = 0; i < tokens.length; ++i) {
            (, uint _usdgAmount) = _getPoolAmounts(tokens[i]);
            _aum += _usdgAmount;
        }

        return _aum;
    }

    /**
    * @notice Returns the dynamic AUM of the GLP based on the AUM values with max and min prices.
    * @return _aum The dynamic AUM value.
    */
    function _getGlpDynamicAum() internal view returns (uint _aum) {
        uint maxAum = glpManager.getAum(true);
        uint minAum = glpManager.getAum(false);
        return (maxAum + minAum) / 2;
    }

    /**
    * @notice Validates if the given token is a stable token in the vault.
    * @param _token The address of the token to validate.
    * @dev Reverts if the given token is not a stable token in the vault.
    */
    function _validateStableToken(address _token) internal view {
        if (!vault.stableTokens(_token)) {
            revert NotStableToken(_token);
        }
    }

    /**
     * @dev Returns the callback signatures
     * @return _ret An array of function signatures (bytes4) for the callback
     */
    function callbackSigs()
        external
        pure
        override
        returns (bytes4[] memory _ret)
    {
        _ret = new bytes4[](0);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IHandlerContract} from "./IHandlerContract.sol";

interface IPositionManager is IHandlerContract {
    function positionMargin(
        address _indexToken,
        address _collateralToken,
        bool _isLong
    ) external view returns (uint256);

    function positionNotional(
        address _indexToken,
        address _collateralToken,
        bool _isLong
    ) external view returns (uint256);

    function positionNotional(
        address _indexToken
    ) external view returns (uint, bool);

    function positionMargin(
        address _indexToken
    ) external view returns (uint, bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {AggregateVaultStorage} from "../storage/AggregateVaultStorage.sol";
import {UMAMI_TOTAL_VAULTS, GMX_FEE_STAKED_GLP, GMX_GLP_REWARD_ROUTER, GMX_GLP_MANAGER, TOKEN_USDC, TOKEN_WETH, TOKEN_WBTC, TOKEN_LINK, TOKEN_UNI, UNISWAP_SWAP_ROUTER} from "../constants.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Solarray} from "../libraries/Solarray.sol";
import {AssetVault} from "../vaults/AssetVault.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {GlpHandler} from "../handlers/GlpHandler.sol";
import {BaseHandler} from "../handlers/BaseHandler.sol";
import {INettedPositionTracker} from "../interfaces/INettedPositionTracker.sol";
import {VaultMath} from "../libraries/VaultMath.sol";
import {IRewardRouterV2} from "../interfaces/IRewardRouterV2.sol";
import {Multicall} from "../libraries/Multicall.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Solarray} from "../libraries/Solarray.sol";
import {PositionManagerRouter} from "../handlers/hedgeManagers/PositionManagerRouter.sol";
import {FeeEscrow} from "./FeeEscrow.sol";
import {LibRebalance} from "../libraries/LibRebalance.sol";
import {LibAggregateVaultUtils} from "../libraries/LibAggregateVaultUtils.sol";

ERC20 constant fsGLP = ERC20(GMX_FEE_STAKED_GLP);
uint constant BIPS = 10000;

/// @title AggregateVaultViews
/// @author Umami DAO
/// @notice A contract providing view functions for AggregateVaultStorage data.
contract AggregateVaultViews is AggregateVaultStorage {
    error RebalanceGlpAccountingError();

    /// @notice Returns the array of AssetVaultEntry structs.
    function getAssetVaultEntries()
        public
        view
        returns (AssetVaultEntry[5] memory _assetVaultEntry)
    {
        _assetVaultEntry = _getStorage().assetVaults;
    }

    /// @notice Returns the index of a token in the asset vault array.
    /// @param _token The address of the token.
    function tokenToAssetVaultIndex(
        address _token
    ) public view returns (uint _idx) {
        _idx = _getStorage().tokenToAssetVaultIndex[_token];
    }

    /// @notice Returns the index of a vault in the asset vault array.
    /// @param _vault The address of the vault.
    function vaultToAssetVaultIndex(
        address _vault
    ) public view returns (uint _idx) {
        _idx = _getStorage().vaultToAssetVaultIndex[_vault];
    }

    /// @notice Returns the current vault state.
    function getVaultState()
        public
        view
        returns (VaultState memory _vaultState)
    {
        _vaultState = _getStorage().vaultState;
    }

    /// @notice Returns the current rebalance state.
    function getRebalanceState()
        public
        view
        returns (RebalanceState memory _rebalanceState)
    {
        _rebalanceState = _getStorage().rebalanceState;
    }

    /// @notice Returns the current GLP attribution for each asset vault.
    function getVaultGlpAttribution()
        public
        view
        returns (uint[5] memory _glpAttribution)
    {
        _glpAttribution = _getStorage().vaultGlpAttribution;
    }

    /// @notice Returns the last netted price for a given epoch.
    /// @param _epoch The epoch for which to retrieve the netted price.
    function getLastNettedPrice(
        uint _epoch
    )
        public
        view
        returns (INettedPositionTracker.NettedPrices memory _nettedPrices)
    {
        _nettedPrices = _getStorage().lastNettedPrices[_epoch];
    }

    /// @notice Returns the array of position managers.
    function getPositionManagers()
        public
        view
        returns (IPositionManager[] memory _positionManagers)
    {
        _positionManagers = _getStorage().positionManagers;
    }

    /// @notice Returns the array of active aggregate positions.
    function getActiveAggregatePositions()
        public
        view
        returns (int[4] memory _activeAggregatePositions)
    {
        _activeAggregatePositions = _getStorage().activeAggregatePositions;
    }

    /// @notice Returns the array of netted positions.
    function getNettedPositions()
        public
        view
        returns (int[5][5] memory _nettedPositions)
    {
        _nettedPositions = _getStorage().nettedPositions;
    }

    /// @notice Returns the array of active external positions.
    function getActiveExternalPositions()
        public
        view
        returns (int[5][5] memory _activeExternalPositions)
    {
        _activeExternalPositions = _getStorage().activeExternalPositions;
    }

    /// @notice Returns the last GLP composition.
    function getLastGlpComposition()
        public
        view
        returns (uint[5] memory _glpComposition)
    {
        _glpComposition = _getStorage().lastGlpComposition;
    }
}

/// @title AggregateVaultHelper
/// @author Umami DAO
/// @notice Helper contract containting the vault operations and logic.
contract AggregateVaultHelper is AggregateVaultViews, BaseHandler, Multicall {
    using SafeTransferLib for ERC20;

    // EVENTS
    // ------------------------------------------------------------------------------------------

    event SettleNettedPositionPnl(uint256[5] previousGlpAmount, uint256[5] settledGlpAmount, int256[5] glpPnl, int256[5] dollarPnl, int256[5] percentPriceChange);
    event UpdateNettingCheckpointPrice(INettedPositionTracker.NettedPrices oldPrices, INettedPositionTracker.NettedPrices newPrices);
    event CompoundDistributeYield(uint256[5] glpYieldPerVault);
    event RebalanceGlpPosition(uint256[5] vaultGlpAttributionBefore, uint256[5] vaultGlpAttributionAfter, uint256[5] targetGlpAllocation, int256[5] totalVaultGlpDelta, int[5] feeAmounts);
    event GlpRewardClaimed(uint _amount);
    event Cycle(uint256 timestamp, uint256 round);

    // GETTERS
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Gets the current asset vault price per share (PPS)
    * @param _assetVault The address of the asset vault
    * @return _pps The price per share of the asset vault
    */
    function getVaultPPS(
        address _assetVault
    ) public onlyDelegateCall returns (uint _pps) {
        VaultState memory vaultState = _getVaultState();
        if (vaultState.rebalanceOpen) {
            mapping(address => uint) storage vaultToAssetVaultIndex = _getVaultToAssetVaultIndex();
            return vaultState.rebalancePPS[vaultToAssetVaultIndex[_assetVault]];
        }

        uint idx = _getVaultToAssetVaultIndex()[_assetVault];
        AssetVaultEntry storage assetVault = _getAssetVaultEntry(idx);
        (uint tvl, , , ) = _getAssetVaultTvl(assetVault);
        uint oneShare = 10 ** ERC20(assetVault.vault).decimals();

        uint totalSupply = ERC20(assetVault.vault).totalSupply();
        if (totalSupply == 0) return oneShare;
        _pps = (tvl * oneShare) / totalSupply;
    }

    /**
    * @notice Gets the current Global Liquidity Position (GLP) for all vaults
    * @return _vaultsGlp An array containing the GLP for each vault
    */
    function getVaultsGlp() public view returns (uint[5] memory _vaultsGlp) {
        _vaultsGlp = LibAggregateVaultUtils.getVaultsGlp(_getStorage());
    }

    /**
    * @notice Gets the GLP for all vaults with no Profit and Loss (PNL) adjustments
    * @return _vaultsGlpNoPnl An array containing the GLP with no PNL for each vault
    */
    function getVaultsGlpNoPnl() public view returns (uint[5] memory _vaultsGlpNoPnl) {
        _vaultsGlpNoPnl = LibAggregateVaultUtils.getVaultsGlpNoPnl(_getStorage());
    }
    /**
    * @notice Gets the current asset vault Total Value Locked (TVL)
    * @param _assetVault The address of the asset vault
    * @return _tvl The total value locked in the asset vault
    */
    function getVaultTVL(
        address _assetVault
    ) public onlyDelegateCall returns (uint _tvl) {
        uint idx = _getVaultToAssetVaultIndex()[_assetVault];
        AssetVaultEntry storage assetVault = _getAssetVaultEntry(idx);
        (_tvl, , , ) = _getAssetVaultTvl(assetVault);
    }

    /**
    * @notice Gets the breakdown of the asset vault TVL
    * @param _assetVault The address of the asset vault
    * @return _total The total TVL in the asset vault
    * @return _buffer The buffer portion of the TVL
    * @return _glp The GLP portion of the TVL
    * @return _hedges The hedge portion of the TVL
    */
    function getVaultTVLBreakdown(
        address _assetVault
    )
        public
        onlyDelegateCall
        returns (uint _total, uint _buffer, uint _glp, uint _hedges)
    {
        (_total, _buffer, _glp, _hedges) = _getAssetVaultTvl(
            _getAssetVaultEntry(_getVaultToAssetVaultIndex()[_assetVault])
        );
    }

    // CONFIG
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Sets the timelock yield boost for the specified vault
    * @param newTimelockYieldBoost The address of the new timelock yield boost
    * @param vaultIdx The index of the vault in the asset vaults array
    */
    function setTimelockYieldBoost(address newTimelockYieldBoost, uint256 vaultIdx) public onlyDelegateCall {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        assetVaults[vaultIdx].timelockYieldBoost = newTimelockYieldBoost;
    }

    /**
    * @notice Sets the netted positions
    * @param _nettedPositions A 2D array of the new netted positions
    */
    function setNettedPositions(
        int[5][5] memory _nettedPositions
    ) public onlyDelegateCall {
        _setNettedPositions(_nettedPositions);
    }

    /**
     * @notice Sets the keeper share config
     * @param _newKeeper The new keeper address
     * @param _newBps The new keeper share
     */
    function setKeeperShareConfig(address _newKeeper, uint _newBps) public onlyDelegateCall {
        require(_newKeeper != address(0), "Invalid keeper address");
        require(_newBps <= 5000, "More than max allowed");
        _getStorage().keeper = _newKeeper;
        _getStorage().keeperShareBps = _newBps;
    }

    /**
     * @notice Set the swap tolerance
     * @param _newSwapTolerance The new swap tolerance
     */
    function setSwapTolerance(uint _newSwapTolerance) public onlyDelegateCall {
        require(_newSwapTolerance <= 10000, "Invalid BPS");
        _getStorage().swapToleranceBps = _newSwapTolerance;
    }

    /**
    * @notice Settles internal Profit and Loss (PNL)
    * @param assetPrices An array of the asset prices
    * @param glpPrice The Global Liquidity Position (GLP) price
    */
    function settleInternalPnl(
        uint[5] memory assetPrices,
        uint glpPrice
    ) external onlyDelegateCall {
        _settleInternalPnl(assetPrices, glpPrice);
    }

    /**
    * @notice Sets the Global Liquidity Position (GLP) attribution for each vault
    * @param _newVals An array of the new GLP attributions
    */
    function setVaultGlpAttribution(
        uint[5] memory _newVals
    ) public onlyDelegateCall {
        uint[5] storage _vaultGlpAttribution = _getVaultGlpAttribution();
        for (uint i = 0; i < _vaultGlpAttribution.length; ++i) {
            _vaultGlpAttribution[i] = _newVals[i];
        }
    }

    /**
    * @notice Sets the netting price tolerance
    * @param _tolerance The new netting price tolerance
    */
    function setNettingPriceTolerance(
        uint _tolerance
    ) external onlyDelegateCall {
        require(_tolerance <= BIPS, "AggregateVaultHelper: tolerance too high");
        _getStorage().nettingPriceTolerance = _tolerance;
    }

    /**
    * @notice Sets the netting price tolerance
    * @param _tolerance The new netting price tolerance
    */
    function setGlpRebalanceTolerance(
        uint _tolerance
    ) external onlyDelegateCall {
        require(_tolerance <= BIPS, "AggregateVaultHelper: tolerance too high");
        _getStorage().glpRebalanceTolerance = _tolerance;
    }

    /**
    * @notice Sets the rebalance state
    * @param _rebalanceState A RebalanceState struct containing the new state
    */
    function setRebalanceState(
        RebalanceState memory _rebalanceState
    ) external onlyDelegateCall {
        RebalanceState storage rebalanceState = _getRebalanceState();
        rebalanceState.glpAllocation = _rebalanceState.glpAllocation;
        rebalanceState.glpComposition = _rebalanceState.glpComposition;
        rebalanceState.aggregatePositions = _rebalanceState.aggregatePositions;
        rebalanceState.epoch = _rebalanceState.epoch;

        for (uint i = 0; i < UMAMI_TOTAL_VAULTS; ++i) {
            for (uint j = 0; j < UMAMI_TOTAL_VAULTS; ++j) {
                rebalanceState.externalPositions[i][j] = _rebalanceState
                    .externalPositions[i][j];
                rebalanceState.adjustedExternalPositions[i][j] = _rebalanceState
                    .adjustedExternalPositions[i][j];
            }
        }
    }

    function setGlpMintBurnSlippageTolerance(uint _newTolerance) external onlyDelegateCall {
        _getStorage().glpMintBurnSlippageTolerance = _newTolerance;
    }

    /**
    * @notice Updates the netting checkpoint price for the specified epoch
    * @param assetPrices A NettedPrices struct containing the new asset prices
    * @param epochId The ID of the epoch
    */
    function updateNettingCheckpointPrice(
        INettedPositionTracker.NettedPrices memory assetPrices,
        uint epochId
    ) external onlyDelegateCall {
        _updateNettingCheckpointPrice(assetPrices, epochId);
    }

    /**
    * @notice Removes the position manager at the specified index
    * @param _addr The address of the position manager to remove
    * @param idx The index of the position manager in the position managers array
    */
    function removePositionManagerAt(
        address _addr,
        uint idx
    ) external onlyDelegateCall {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        require(
            positionManagers[idx] == IPositionManager(_addr),
            "invalid idx"
        );
        positionManagers[idx] = positionManagers[positionManagers.length - 1];
        positionManagers.pop();
    }

    /**
    * @notice Updates the current epoch
    * @param _epoch The new epoch value
    */
    function updateEpoch(uint _epoch) public onlyDelegateCall {
        _getStorage().vaultState.epoch = _epoch;
    }

    // REBALANCE
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Cycles the vaults with the given asset prices and GLP price, this settles internal position pnl,
    * and rebalances GLP held by each vault to the target amounts set in `openRebalancePeriod(...)`
    * @param assetPrices An array containing the asset prices
    * @param glpPrice The GLP price
    */
    function cycle(
        uint256[5] memory assetPrices,
        uint256 glpPrice
    ) external onlyDelegateCall {
        _cycle(assetPrices, glpPrice);
        VaultState storage vaultState = _getVaultState();
        emit Cycle(block.timestamp, vaultState.epoch);
    }

    /**
    * @notice Handle the GLP rewards according to the strategy. Claim esGMX + multiplier points and stake.
    * @param compound Indicates whether to compound the rewards or distribute them to the buffer
    */
    function handleGlpRewards(bool compound) public onlyDelegateCall {
        uint256 priorBalance = ERC20(TOKEN_WETH).balanceOf(address(this));
        _getFeeClaimRewardRouter().handleRewards(
            true,
            true,
            true,
            true,
            true,
            true,
            false
        );
        uint256 rewardAmount = ERC20(TOKEN_WETH).balanceOf(address(this)) -
            priorBalance;
        emit GlpRewardClaimed(rewardAmount);

        if (compound) {
            _compoundDistributeYield(rewardAmount);
        } else {
            _bufferDistributeYield(rewardAmount);
        }
    }

    /**
    * @notice Rebalances the GLP with the given next allocation and GLP price
    * @param _nextGlpAllocation An array containing the next GLP allocation
    * @param _glpPrice The GLP price
    */
    function rebalanceGlpPosition(
        uint[5] memory _nextGlpAllocation,
        uint _glpPrice
    ) external onlyDelegateCall {
        LibRebalance.rebalanceGlpPosition(_getStorage(), _nextGlpAllocation, _glpPrice);
    }

    // INTERNAL GETTERS
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Get the AssetVaultEntry at the given index.
    * @param _idx The index of the AssetVaultEntry.
    * @return _assetVault The AssetVaultEntry at the given index.
    */
    function _getAssetVaultEntry(
        uint _idx
    ) internal view returns (AssetVaultEntry storage _assetVault) {
        _assetVault = _getAssetVaultEntries()[_idx];
    }

    /**
    * @notice Get the index of an AssetVaultEntry from a vault address.
    * @param _vault The vault address to find the index for.
    * @return _idx The index of the AssetVaultEntry with the given vault address.
    */
    function _getAssetVaultIdxFromVault(
        address _vault
    ) internal view returns (uint _idx) {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();

        for (uint i = 0; i < UMAMI_TOTAL_VAULTS; ++i) {
            if (assetVaults[i].vault == _vault) {
                return i;
            }
        }
        revert("AggregateVault: unknown asset vault");
    }

    /**
    * @notice Get the total value locked (TVL) for a specific AssetVaultEntry.
    * @param _assetVault The AssetVaultEntry to get the TVL for.
    * @return _totalTvl The total TVL for the AssetVaultEntry.
    * @return _bufferTvl The TVL held in the buffer for the AssetVaultEntry.
    * @return _glpTvl The TVL held in the glp for the AssetVaultEntry.
    * @return _hedgesTvl The TVL held in hedges for the AssetVaultEntry.
    */
    function _getAssetVaultTvl(
        AssetVaultEntry storage _assetVault
    )
        internal
        returns (uint _totalTvl, uint _bufferTvl, uint _glpTvl, uint _hedgesTvl)
    {
        uint assetVaultIdx = _getAssetVaultIdxFromVault(_assetVault.vault);

        _bufferTvl = ERC20(_assetVault.token).balanceOf(address(this));
        _glpTvl = _assetVaultGlpToken(assetVaultIdx);
        _hedgesTvl = _getAssetVaultHedgesInNativeToken(assetVaultIdx);
        _totalTvl = _bufferTvl + _glpTvl + _hedgesTvl;
    }

    /**
    * @notice Get the hedges value in USD for a specific vault index.
    * @param _vaultIdx The index of the vault to get the hedges value for.
    * @return _hedgesUsd The hedges value in USD for the specified vault index.
    */
    function _getAssetVaultHedgesInUsd(
        uint _vaultIdx
    ) internal returns (uint _hedgesUsd) {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        VaultState storage vaultState = _getVaultState();

        for (uint i = 1; i < UMAMI_TOTAL_VAULTS; ++i) {
            address token = assetVaults[i].token;
            uint totalNotional = _getTotalNotionalInExternalPositions(i);
            uint notional = vaultState.externalPositions[_vaultIdx][i] > 0
                ? uint(vaultState.externalPositions[_vaultIdx][i])
                : uint(-vaultState.externalPositions[_vaultIdx][i]);
            (uint totalMargin, ) = _getTotalMargin(token);

            if (totalNotional > 0)
                _hedgesUsd += (totalMargin * notional) / totalNotional;
        }
    }

    /**
    * @notice Get the hedges value in native token for a specific vault index.
    * @param _vaultIdx The index of the vault to get the hedges value for.
    * @return _hedgesToken The hedges value in native token for the specified vault index.
    */
    function _getAssetVaultHedgesInNativeToken(
        uint _vaultIdx
    ) internal returns (uint _hedgesToken) {
        uint hedgesUsd = _getAssetVaultHedgesInUsd(_vaultIdx);
        GlpHandler glpHandler = _getGlpHandler();
        AssetVaultEntry storage assetVault = _getAssetVaultEntries()[_vaultIdx];

        _hedgesToken = glpHandler.getUsdToToken(
            hedgesUsd,
            30,
            assetVault.token
        );
    }

    /**
    * @notice Get the total notional value in external positions for a specific index.
    * @param _idx The index to get the total notional value for.
    * @return _totalNotional The total notional value in external positions for the specified index.
    */
    function _getTotalNotionalInExternalPositions(
        uint _idx
    ) internal view returns (uint _totalNotional) {
        VaultState storage vaultState = _getVaultState();

        for (uint i = 0; i < UMAMI_TOTAL_VAULTS; ++i) {
            int externalPosition = vaultState.externalPositions[i][_idx];
            uint absoluteExternalPosition = externalPosition > 0
                ? uint(externalPosition)
                : uint(-externalPosition);
            _totalNotional += absoluteExternalPosition;
        }
    }

    /**
    * @notice Get the hedge attribution for all AssetVaults.
    * @return hedgeAttribution A two-dimensional array containing the hedge attribution for each AssetVault.
    */
    function _getAllAssetVaultsHedgeAtribution()
        external
        returns (uint[4][5] memory hedgeAttribution)
    {
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        for (uint i = 0; i < assetVaults.length; ++i) {
            hedgeAttribution[i] = _getAssetVaultHedgeAttribution(assetVaults[i].vault);
        }
        return hedgeAttribution;
    }

    /**
    * @notice Get the total notional value for a specific token.
    * @param _token The address of the token to get the total notional value for.
    * @return _totalNotional The total notional value for the specified token.
    */
    function _getTotalNotional(
        address _token
    ) public returns (uint _totalNotional, bool _isLong) {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        uint length = positionManagers.length;

        bool unset = true;
        _isLong = false;

        for (uint i = 0; i < length; ++i) {
            bytes memory ret = _delegatecall(
                address(positionManagers[i]),
                abi.encodeWithSignature("positionNotional(address)", _token)
            );
            (uint notional, bool isLong_) = abi.decode(ret, (uint, bool));
            if (notional > 0) {
                if (unset) {
                    _isLong = isLong_;
                    unset = false;
                } else {
                    require(_isLong == isLong_, "AggregateVaultHelper: mixed long/short");
                }
            }

            _totalNotional += notional;
        }
    }

    /**
    * @notice Get the total margin value for a specific token.
    * @param _token The address of the token to get the total margin value for.
    * @return _totalMargin The total margin value for the specified token.
    */
    function _getTotalMargin(
        address _token
    ) public returns (uint _totalMargin, bool _isLong) {
        IPositionManager[] storage positionManagers = _getPositionManagers();
        uint length = positionManagers.length;

        bool unset = true;
        _isLong = false;

        for (uint i = 0; i < length; ++i) {
            bytes memory ret = _delegatecall(
                address(positionManagers[i]),
                abi.encodeWithSignature("positionMargin(address)", _token)
            );
            (uint margin, bool isLong_) = abi.decode(ret, (uint, bool));
            if (margin > 0) {
                if (unset) {
                    _isLong = isLong_;
                    unset = false;
                } else {
                    require(
                        _isLong == isLong_,
                        "AggregateVaultHelper: mixed long/short"
                    );
                }
            }
            _totalMargin += margin;
        }
    }
    /**
    * @notice Returns the current prices from GMX.
    * @return _prices An INettedPositionTracker.NettedPrices struct containing the current asset prices
    */
    function _getCurrentPrices()
        public
        view
        returns (INettedPositionTracker.NettedPrices memory _prices)
    {
        _prices = LibAggregateVaultUtils.getCurrentPrices(_getStorage());
    }

    /**
    * @notice Calculates the hedge attribution for a given vault
    * @param _vault Address of the vault to calculate the hedge attribution for
    * @return _vaultMarginAttribution Array of hedge attributions for the given vault
    */
    function _getAssetVaultHedgeAttribution(
        address _vault
    ) internal returns (uint[4] memory _vaultMarginAttribution) {
        uint assetVaultIdx = _getAssetVaultIdxFromVault(_vault);
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        VaultState storage vaultState = _getVaultState();
        for (uint i = 1; i < UMAMI_TOTAL_VAULTS; ++i) {
            address token = assetVaults[i].token;
            uint totalNotional = _getTotalNotionalInExternalPositions(i);
            uint notional = vaultState.externalPositions[assetVaultIdx][i] > 0
                ? uint(vaultState.externalPositions[assetVaultIdx][i])
                : uint(-vaultState.externalPositions[assetVaultIdx][i]);
            (uint actualNotional, ) = _getTotalNotional(token);

            if (totalNotional > 0) {
                _vaultMarginAttribution[i - 1] =
                    (actualNotional * notional) /
                    totalNotional;
            }
        }
        return _vaultMarginAttribution;
    }

    // INTERNAL REBALACE LOGIC
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Updates the netting checkpoint price for a given epoch
    * @param assetPrices The asset prices to update the checkpoint with
    * @param epochId The ID of the epoch to update the checkpoint for
    */
    function _updateNettingCheckpointPrice(
        INettedPositionTracker.NettedPrices memory assetPrices,
        uint256 epochId
    ) internal {
        // uninitialized case
        INettedPositionTracker.NettedPrices
            storage nettedPrice = _getEpochNettedPrice(epochId);
        require(
            nettedPrice.stable == 0,
            "AggregateVault: lastNettedPrices already inited for given epoch"
        );
        _checkNettingCheckpointPrice(assetPrices);
        mapping(uint => INettedPositionTracker.NettedPrices)
            storage lastNettedPrices = _getLastNettedPrices();
        lastNettedPrices[epochId] = assetPrices;
        emit UpdateNettingCheckpointPrice(lastNettedPrices[epochId-1], assetPrices);
    }

    /**
    * @notice Cycles through the rebalancing process with the given asset prices and GLP price.
    * @dev netting checkpoint price is set to 0 after settling internal pnl.
    * @param assetPrices An array of the current asset prices
    * @param glpPrice The current GLP price
    */
    function _cycle(
        uint256[5] memory assetPrices,
        uint256 glpPrice
    ) internal {
        // settle internal netted pnl only after first round
        VaultState storage vaultState = _getVaultState();
        if (vaultState.epoch > 0) {
            _settleInternalPnl(assetPrices, glpPrice);
        }
        // update next netting prices
        _updateNettingCheckpointPrice(
            INettedPositionTracker.NettedPrices({
                stable: assetPrices[0],
                eth: assetPrices[1],
                btc: assetPrices[2],
                link: assetPrices[3],
                uni: assetPrices[4]
            }),
            vaultState.epoch + 1
        );

        // note internal pnl is reset to zero at this point
        RebalanceState storage rebalanceState = _getRebalanceState();
        // rebalance glp
        LibRebalance.rebalanceGlpPosition(_getStorage(), rebalanceState.glpAllocation, glpPrice);
    }

    /**
    * @notice Settles the internal PnL for the given asset prices and GLP price
    * @param assetPrices An array of the current asset prices
    * @param glpPrice The current GLP price
    */
    function _settleInternalPnl(
        uint256[5] memory assetPrices,
        uint256 glpPrice
    ) internal {
        uint256[5] memory settledVaultGlpAmount;
        int256[5] memory nettedPnl;
        int256[5] memory glpPnl;
        int256[5] memory percentPriceChange;

        INettedPositionTracker.NettedPrices
            memory nettedPrices = INettedPositionTracker.NettedPrices({
                stable: assetPrices[0],
                eth: assetPrices[1],
                btc: assetPrices[2],
                link: assetPrices[3],
                uni: assetPrices[4]
            });

        VaultState storage vaultState = _getVaultState();
        // get the previous allocated glp amount
        uint[5] memory vaultGlpAmount = LibAggregateVaultUtils.getVaultsGlpNoPnl(_getStorage());
        (settledVaultGlpAmount, nettedPnl, glpPnl, percentPriceChange) = _getNettedPositionTracker()
            .settleNettingPositionPnl(
                _getNettedPositions(),
                nettedPrices,
                _getEpochNettedPrice(vaultState.epoch),
                vaultGlpAmount,
                glpPrice,
                _getZeroSumPnlThreshold()
            );
        // note set the updated proportions?
        setVaultGlpAttribution(settledVaultGlpAmount);
        emit SettleNettedPositionPnl(vaultGlpAmount, settledVaultGlpAmount, glpPnl, nettedPnl, percentPriceChange);
    }

    // INTERNAL GLP POSITION MANAGMENT
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Swaps eth yield into the buffer for each vault.
     */
    function _bufferDistributeYield(uint256 _rewardAmount) internal {
        require(_rewardAmount > 0, "AggregateVault: _rewardAmount 0");
        AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
        uint swapInput;
        GlpHandler handler = _getGlpHandler();
        for (uint256 i = 0; i < assetVaults.length; i++) {
            if (assetVaults[i].token != TOKEN_WETH) {
                swapInput = _rewardAmount * _getVaultGlpAttributeProportion(i) / 1e18;
                PositionManagerRouter(payable(address(this))).executeSwap(
                    _getUniV3SwapManager(),
                    TOKEN_WETH,
                    assetVaults[i].token,
                    swapInput,
                    handler.tokenToToken(
                        TOKEN_WETH,
                        assetVaults[i].token,
                        swapInput),
                    bytes("") // UniV3SwapManager not required
                );
            }
        }
    }

    /**
     * @notice Compounds yield into GLP and distributes it to vaults based on TVL using pro-rata method.
     */
    function _compoundDistributeYield(uint256 _rewardAmount) internal {
        if (_rewardAmount > 0) {
            ERC20(TOKEN_WETH).safeApprove(GMX_GLP_MANAGER, _rewardAmount);
            uint256 amountWithSlippage = VaultMath.getSlippageAdjustedAmount(
                _rewardAmount,
                _getStorage().glpMintBurnSlippageTolerance
            );
            uint256 glpMinted = IRewardRouterV2(GMX_GLP_REWARD_ROUTER)
                .mintAndStakeGlp(
                    TOKEN_WETH,
                    _rewardAmount,
                    amountWithSlippage,
                    0
                );
            AssetVaultEntry[5] storage assetVaults = _getAssetVaultEntries();
            uint[5] storage _vaultGlpAttribution = _getVaultGlpAttribution();

            uint[5] memory increments;
            for (uint256 i = 0; i < assetVaults.length; i++) {
                increments[i] =
                    (glpMinted * _getVaultGlpAttributeProportion(i)) /
                    1e18;
            }

            for (uint256 i = 0; i < assetVaults.length; i++) {
                _vaultGlpAttribution[i] += increments[i];
            }
            emit CompoundDistributeYield(increments);
        }
    }

    // INTERNAL GLP LOGIC
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Calculates the GLP token amount owned by a vault.
    * @param _vaultIdx The index of the vault.
    * @return _glpToken The amount of GLP token owned by the vault.
    */
    function _assetVaultGlpToken(
        uint _vaultIdx
    ) internal view returns (uint _glpToken) {
        uint currentEpoch = _getVaultState().epoch;
        uint vaultGlp = LibAggregateVaultUtils.getVaultGlp(_getStorage(), _vaultIdx, currentEpoch);
        AssetVaultEntry storage assetVault = _getAssetVaultEntries()[_vaultIdx];
        GlpHandler glpHandler = _getGlpHandler();
        _glpToken = glpHandler.previewGlpMintBurn(assetVault.token, vaultGlp);
    }

    /**
    * @notice Calculates the proportion of GLP attributed to a vault. 100% = 1e18, 10% = 0.1e18.
    * @param _vaultIdx The index of the vault.
    * @return _proportion The proportion of GLP attributed to the vault.
    */
    function _getVaultGlpAttributeProportion(
        uint _vaultIdx
    ) internal view returns (uint _proportion) {
        uint[5] memory _vaultGlpAttribution = _getVaultGlpAttribution();
        uint totalGlpAttribution = Solarray.arraySum(_vaultGlpAttribution);
        if (totalGlpAttribution == 0) return 0;
        return (_vaultGlpAttribution[_vaultIdx] * 1e18) / totalGlpAttribution;
    }

    // UTILS
    // ------------------------------------------------------------------------------------------

    /**
    * @notice Resets the checkpoint prices for the given number of epochs.
    * @param _noOfEpochs The number of epochs to reset checkpoint prices for.
    */
    function resetCheckpointPrices(uint _noOfEpochs) public onlyDelegateCall {
        INettedPositionTracker.NettedPrices
            memory assetPrices = INettedPositionTracker.NettedPrices({
                stable: 0,
                eth: 0,
                btc: 0,
                link: 0,
                uni: 0
            });
        mapping(uint => INettedPositionTracker.NettedPrices)
            storage lastNettedPrices = _getLastNettedPrices();
        for (uint i = 0; i < _noOfEpochs; ++i) {
            lastNettedPrices[i] = assetPrices;
        }
    }

    /**
    * @notice Checks if the netting checkpoint prices are within the tolerance of the current prices.
    * @dev check netting prices from keeper are ~= current prices.
    * @param _assetPrices The netting checkpoint asset prices.
    */
    function _checkNettingCheckpointPrice(
        INettedPositionTracker.NettedPrices memory _assetPrices
    ) internal view {
        INettedPositionTracker.NettedPrices
            memory currentPrices = LibAggregateVaultUtils.getCurrentPrices(_getStorage());
        uint tolerance = _getNettingPriceTolerance();
        _assertWithinTolerance(
            _assetPrices.stable,
            currentPrices.stable,
            tolerance
        );
        _assertWithinTolerance(_assetPrices.eth, currentPrices.eth, tolerance);
        _assertWithinTolerance(_assetPrices.btc, currentPrices.btc, tolerance);
        _assertWithinTolerance(
            _assetPrices.link,
            currentPrices.link,
            tolerance
        );
        _assertWithinTolerance(_assetPrices.uni, currentPrices.uni, tolerance);
    }

    /**
    * @notice Asserts that the actual value is within the tolerance range of the target value.
    * @param _actual The actual value.
    * @param _target The target value.
    * @param _toleranceBps The tolerance in basis points (1 basis point = 0.01%).
    */
    function _assertWithinTolerance(
        uint _actual,
        uint _target,
        uint _toleranceBps
    ) internal pure {
        require(_toleranceBps <= BIPS, "tolerance must be <= 100%");
        uint lower = (_target * (BIPS - _toleranceBps)) / BIPS;
        uint higher = (_target * (BIPS + _toleranceBps)) / BIPS;
        require(_actual >= lower && _actual <= higher, "not within tolerance");
    }

    /**
    * @notice Executes a delegate call to the specified target with the given data.
    * @param _target The target address to delegate call.
    * @param _data The data to be sent as part of the delegate call.
    * @return ret The returned data from the delegate call.
    */
    function _delegatecall(
        address _target,
        bytes memory _data
    ) internal returns (bytes memory ret) {
        bool success;
        (success, ret) = _target.delegatecall(_data);
        if (!success) {
            /// @solidity memory-safe-assembly
            assembly {
                let length := mload(ret)
                let start := add(ret, 0x20)
                revert(start, length)
            }
        }
        return ret;
    }

    /**
    * @notice Returns an empty array of bytes4 signatures.
    * @return _ret An empty array of bytes4 signatures.
    */
    function callbackSigs() external pure returns (bytes4[] memory _ret) {
        _ret = new bytes4[](0);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    function _multicall(
        bytes[] calldata data
    ) internal returns (bytes[] memory results, uint[] memory gasEstimates) {
        results = new bytes[](data.length);
        gasEstimates = new uint[](data.length);

        unchecked {
            for (uint256 i = 0; i < data.length; ++i) {
                uint startGas = gasleft();
                (bool success, bytes memory result) = address(this)
                    .delegatecall(data[i]);

                if (!success) {
                    /// @solidity memory-safe-assembly
                    assembly {
                        let resultLength := mload(result)
                        revert(add(result, 0x20), resultLength)
                    }
                }

                results[i] = result;
                uint endGas = gasleft();
                gasEstimates[i] = startGas - endGas;
            }
        }
    }
}

pragma solidity 0.8.17;
import {IHandlerContract} from "./IHandlerContract.sol";

interface ISwapManager is IHandlerContract {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _minOut,
        bytes calldata _data
    ) external returns (uint _amountOut);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IHandlerContract {
    function callbackSigs() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IHandlerContract} from "../interfaces/IHandlerContract.sol";

/**
 * @title BaseHandler
 * @author Umami DAO
 * @notice Abstract base contract for implementing handler contracts with a delegate call restriction.
 * @dev Any contract inheriting from this contract must implement the IHandlerContract interface.
 */
abstract contract BaseHandler is IHandlerContract {
    address immutable SELF;
    error OnlyDelegateCall();

    constructor() {
        SELF = address(this);
    }

    /**
     * @notice Modifier to restrict functions to be called only via delegate call.
     * @dev Reverts if the function is called directly (not via delegate call).
     */
    modifier onlyDelegateCall() {
        if (address(this) == SELF) {
            revert OnlyDelegateCall();
        }
        _;
    }
}

pragma solidity 0.8.17;

interface IGlpRewardRouter {
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function mintAndStakeGlpETH(
        uint256 _minUsdg,
        uint256 _minGlp
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IVault {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function usdg() external view returns (address);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function getMinPrice(address _token) external view returns (uint);

    function getMaxPrice(address _token) external view returns (uint);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            uint256 realisedPnl,
            bool isProfit,
            uint256 lastIncreasedTime
        );

    function poolAmounts(address _token) external view returns (uint);

    function reservedAmounts(address _token) external view returns (uint);

    function guaranteedUsd(address _token) external view returns (uint);

    function globalShortSizes(address _token) external view returns (uint);

    function positions(
        bytes32 _key
    )
        external
        view
        returns (
            uint _size,
            uint _collateral,
            uint _averagePrice,
            uint _entryFundingRate,
            uint _reserveAmount,
            int _realisedPnl,
            uint _lastIncreasedTime
        );

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function getPositionFee(uint _sizeDelta) external view returns (uint);

    function getFundingFee(
        address _token,
        uint _size,
        uint _entryFundinRate
    ) external view returns (uint);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function tokenDecimals(address) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);
}

pragma solidity 0.8.17;

interface IGlpManager {
    function getPrice(bool _maximise) external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function aumAddition() external view returns (uint256);

    function aumDeduction() external view returns (uint256);

    function shortsTracker() external view returns (address);

    function shortsTrackerAveragePriceWeight() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct IncreasePositionRequestWithoutPath {
        address account;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    struct DecreasePositionRequestWithoutPath {
        address account;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function minExecutionFee() external view returns (uint256);

    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function getRequestQueueLengths()
        external
        view
        returns (
            uint256 increasePositionRequestKeysStart,
            uint256 increasePositionRequestKeysLength,
            uint256 decreasePositionRequestKeysStart,
            uint256 decreasePositionRequestKeysLength
        );

    function admin() external view returns (address);

    function setPositionKeeper(address _account, bool _isActive) external;

    function executeIncreasePositions(
        uint _endIndex,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _endIndex,
        address payable _executionFeeReceiver
    ) external;

    function increasePositionRequests(
        bytes32 _key
    ) external view returns (IncreasePositionRequestWithoutPath memory);

    function decreasePositionRequests(
        bytes32 _key
    ) external view returns (DecreasePositionRequestWithoutPath memory);

    function getIncreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);

    function getDecreasePositionRequestPath(
        bytes32 _key
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @title VaultMath
/// @author Umami DAO
library VaultMath {
    uint256 constant SCALE = 1e30;
    uint256 constant BIPS = 10000;

    /**
     * @notice Returns a slippage adjusted amount for calculations where slippage is accounted
     * @param amount of the asset
     * @param slippage %
     * @return value of the slippage adjusted amount
     */
    function getSlippageAdjustedAmount(uint256 amount, uint256 slippage) internal pure returns (uint256) {
        return (amount * (1 * SCALE - slippage)) / SCALE;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Vester} from "./Vester.sol";

uint256 constant TOTAL_BPS = 10000;

/// @title FeeEscrow
/// @author Umami DAO
/// @notice Escrow contract that will hold deposit/withdraw fees and reimburse
///         GLP mint/burn fees, keeper gas fees and add the surplus to the vester
///         for vesting into the aggregate vault
contract FeeEscrow {
    using SafeTransferLib for ERC20;

    event ReimburseAndVest(uint256[5] feeAmounts, uint256[5] vestAmounts, uint256[5] keeperAmounts);

    ERC20[5] public ASSETS;
    address public immutable AGGREGATE_VAULT;
    Vester public immutable VESTER;

    constructor(ERC20[5] memory _assets, address _aggregateVault, address _vester) {
        ASSETS = _assets;
        AGGREGATE_VAULT = _aggregateVault;
        VESTER = Vester(_vester);
    }

    /**
     * @notice Reimburses the mint and burn fees, sends the surplus to the vester
     * @param _feeAmounts The amount of fees to reimburse
     * @param keeper The keeper address to send the keeper fees to
     * @param keeperBps The keeper share bps to send to the keeper
     */
    function pullFeesAndVest(uint256[5] memory _feeAmounts, address keeper, uint256 keeperBps)
        external
        onlyAggregateVault
    {
        require(keeperBps <= TOTAL_BPS, "FeeEscrow: keeperBps > TOTAL_BPS");
        uint256[5] memory reimbursedFeeAmounts;
        uint256[5] memory vestAmounts;
        uint256[5] memory keeperAmounts;

        for (uint256 i = 0; i < 5; i++) {
            uint256 balance = ASSETS[i].balanceOf(address(this));
            uint256 feeAmount = _feeAmounts[i] > balance ? balance : _feeAmounts[i];
            uint256 remainder = balance - feeAmount;
            uint256 toKeeper = remainder * keeperBps / TOTAL_BPS;
            uint256 toVest = remainder - toKeeper;

            reimbursedFeeAmounts[i] = feeAmount;
            vestAmounts[i] = toVest;
            keeperAmounts[i] = toKeeper;

            // reimburse the mint and burn fee
            if (feeAmount > 0) {
                ASSETS[i].safeTransfer(AGGREGATE_VAULT, feeAmount);
            }

            if (toKeeper > 0) {
                ASSETS[i].safeTransfer(keeper, toKeeper);
            }

            // send the surplus to vester for vesting into the vault
            if (toVest > 0) {
                ASSETS[i].safeApprove(address(VESTER), toVest);
                VESTER.addVest(address(ASSETS[i]), toVest);
            }
        }
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAggregateVault() {
        require(msg.sender == address(AGGREGATE_VAULT), "AssetVault: Caller is not AggregateVault");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {AggregateVaultStorage} from "../storage/AggregateVaultStorage.sol";
import {FeeEscrow} from "../peripheral/FeeEscrow.sol";
import {VaultMath} from "./VaultMath.sol";
import {GlpHandler} from "../handlers/GlpHandler.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {PositionManagerRouter} from "../handlers/hedgeManagers/PositionManagerRouter.sol";
import {GMX_GLP_MANAGER, GMX_GLP_REWARD_ROUTER, GMX_FEE_STAKED_GLP} from "../constants.sol";
import {IRewardRouterV2} from "../interfaces/IRewardRouterV2.sol";
import {Solarray} from "./Solarray.sol";
import {LibAggregateVaultUtils} from "./LibAggregateVaultUtils.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {UniswapV3SwapManager} from "../handlers/swapManagers/UniswapV3SwapManager.sol";

ERC20 constant fsGLP = ERC20(GMX_FEE_STAKED_GLP);
uint256 constant TOTAL_BPS = 10000;

using SafeTransferLib for ERC20;

library LibRebalance {
    event RebalanceGlpPosition(
        uint256[5] vaultGlpAttributionBefore,
        uint256[5] vaultGlpAttributionAfter,
        uint256[5] targetGlpAllocation,
        int256[5] totalVaultGlpDelta,
        int256[5] feeAmounts
    );

    error RebalanceGlpAccountingError();

    function pullFeeAmountsFromEscrow(AggregateVaultStorage.AVStorage storage _avStorage, int256[5] memory _feeAmounts)
        public
    {
        AggregateVaultStorage.VaultState storage vaultState = _avStorage.vaultState;
        FeeEscrow depositFeeEscrow = FeeEscrow(vaultState.depositFeeEscrow);
        FeeEscrow withdrawFeeEscrow = FeeEscrow(vaultState.withdrawalFeeEscrow);

        uint256[5] memory mintFees;
        uint256[5] memory burnFees;

        for (uint256 i = 0; i < _feeAmounts.length; i++) {
            if (_feeAmounts[i] > 0) {
                mintFees[i] = uint256(_feeAmounts[i]);
            } else {
                burnFees[i] = uint256(-_feeAmounts[i]);
            }
        }

        uint256 keeperBps = _avStorage.keeperShareBps;
        address keeper = _avStorage.keeper;
        // reimburse current cycle mint fees from deposit fee escrow and vest the remainder if any
        depositFeeEscrow.pullFeesAndVest(mintFees, keeper, keeperBps);

        // reimburse current cycle burn fees from withdraw fee escrow and vest the remainder if any
        withdrawFeeEscrow.pullFeesAndVest(burnFees, keeper, keeperBps);
    }

    /**
     * @notice Deposits and stakes the given USD allocation in GLP.
     * @dev Has a fallback if liquidity to mint glp from `mintToken` is unavailable. Glp will be minted from the next
     * available token with a swap used on UNIV3.
     * @param glpAllocation The amount of GLP allocation in USD.
     * @param mintToken The token used to mint GLP.
     * @return glpMinted The amount of GLP minted and staked.
     */
    function increaseGlpPosition(
        AggregateVaultStorage.AVStorage storage _avStorage,
        uint256 glpAllocation,
        address mintToken
    ) public returns (uint256, uint256) {
        uint256 usdgMinAmount =
            VaultMath.getSlippageAdjustedAmount(glpAllocation, _avStorage.glpMintBurnSlippageTolerance);
        GlpHandler glpHandler = _avStorage.glpHandler;
        (address derivedMintToken, uint256 minOut) = glpHandler.routeGlpMint(mintToken, glpAllocation, false);

        // if dont need to route through other token
        if (derivedMintToken == mintToken) {
            uint256 tokenAmount = glpHandler.getUsdToToken(glpAllocation, 18, mintToken);
            uint256 feeAdjustedTokenAmount = glpHandler.calculateTokenMintAmount(mintToken, tokenAmount);

            ERC20(mintToken).safeApprove(GMX_GLP_MANAGER, feeAdjustedTokenAmount);
            uint256 glpMinted = IRewardRouterV2(GMX_GLP_REWARD_ROUTER).mintAndStakeGlp(
                mintToken, feeAdjustedTokenAmount, usdgMinAmount, 0
            );

            uint256 feeAmount = feeAdjustedTokenAmount - tokenAmount;
            return (glpMinted, feeAmount);
        }

        uint256 tokenAmount = glpHandler.getUsdToToken(glpAllocation, 18, mintToken);
        uint256 tokenAmountDerivedMintToken = glpHandler.tokenToToken(mintToken, derivedMintToken, tokenAmount);
        uint256 feeAdjustedDerivedMintTokenAmount =
            glpHandler.calculateTokenMintAmount(derivedMintToken, tokenAmountDerivedMintToken);

        AggregateVaultStorage.AVStorage storage __avStorage = _avStorage;
        bytes memory ret = PositionManagerRouter(payable(address(this))).execute(
            address(_avStorage.uniV3SwapManager),
            abi.encodeCall(
                UniswapV3SwapManager.exactOutputSwap,
                (
                    mintToken,
                    derivedMintToken,
                    feeAdjustedDerivedMintTokenAmount,
                    tokenAmount * (TOTAL_BPS + __avStorage.swapToleranceBps) / TOTAL_BPS
                )
            )
        );
        (uint256 amountIn) = abi.decode(ret, (uint256));

        ERC20(derivedMintToken).safeApprove(GMX_GLP_MANAGER, feeAdjustedDerivedMintTokenAmount);
        uint256 glpMinted = IRewardRouterV2(GMX_GLP_REWARD_ROUTER).mintAndStakeGlp(
            mintToken, feeAdjustedDerivedMintTokenAmount, usdgMinAmount, 0
        );
        uint256 feeAmount = amountIn - tokenAmount;
        return (glpMinted, feeAmount);
    }

    /**
     * @notice Reduces the GLP position by converting the given USD allocation to GLP and unstaking the amount with slippage adjustment.
     * @param glpAllocation The amount of GLP allocation in USD.
     * @param tokenOut The token to receive after unstaking GLP.
     * @return glpAmount The amount of GLP unstaked.
     */
    function reduceGlpPosition(
        AggregateVaultStorage.AVStorage storage _avStorage,
        uint256 glpAllocation,
        address tokenOut
    ) public returns (uint256 glpAmount, uint256 feeAmount) {
        GlpHandler glpHandler = _avStorage.glpHandler;
        // usd to glp at current price
        glpAmount = glpHandler.usdToGlp(glpAllocation, 18, false);
        // burn glp amount
        uint256 amountOut =
            IRewardRouterV2(GMX_GLP_REWARD_ROUTER).unstakeAndRedeemGlp(tokenOut, glpAmount, 0, address(this));
        uint256 usdValueTokenOut = glpHandler.getTokenToUsd(tokenOut, amountOut, 18);
        uint256 feeAmountUsd = glpAllocation > usdValueTokenOut ? glpAllocation - usdValueTokenOut : 0;
        feeAmount = glpHandler.getUsdToToken(feeAmountUsd, 18, tokenOut);
    }

    /**
     * @notice Rebalances Glp positions to the _nextGlpAllocation target $ values
     * @dev Internal pnl must be 0 on entry to this function
     * @param _nextGlpAllocation dollar figure for glp allocations
     * @param _glpPrice current glp price
     * @return feeAmounts array of fees collected, -ve means burn fee, +ve means mint fee
     */
    function rebalanceGlpPosition(
        AggregateVaultStorage.AVStorage storage _avStorage,
        uint256[5] memory _nextGlpAllocation,
        uint256 _glpPrice
    ) external returns (int256[5] memory feeAmounts) {
        AggregateVaultStorage.VaultState storage vaultState = _avStorage.vaultState;
        require(vaultState.rebalanceOpen, "rebalancing period not open yet");
        uint256[5] memory glpAlloc = LibAggregateVaultUtils.glpToDollarArray(_avStorage, _glpPrice);

        // find the difference in glp allocations and executable amount
        (, int256[5] memory vaultGlpDeltaAccount) =
            _avStorage.glpRebalanceRouter.netGlpRebalance(glpAlloc, _nextGlpAllocation);
        uint256[5] storage _vaultGlpAttribution = _avStorage.vaultGlpAttribution;
        uint256[5] memory previousVaultGlp = LibAggregateVaultUtils.getVaultsGlpNoPnl(_avStorage); // note must be 0 internal pnl
        AggregateVaultStorage.AssetVaultEntry[5] storage assetVaults = _avStorage.assetVaults;
        uint256[5] memory vaultGlpPartial;
        for (uint256 i = 0; i < 5; i++) {
            if (vaultGlpDeltaAccount[i] > 0) {
                (uint256 glpBurnt, uint256 feeAmount) =
                    reduceGlpPosition(_avStorage, uint256(vaultGlpDeltaAccount[i]), assetVaults[i].token);
                vaultGlpPartial[i] = previousVaultGlp[i] - glpBurnt;
                feeAmounts[i] = -int256(feeAmount);
            } else if (vaultGlpDeltaAccount[i] < 0) {
                (uint256 glpMinted, uint256 feeAmount) =
                    increaseGlpPosition(_avStorage, uint256(-vaultGlpDeltaAccount[i]), assetVaults[i].token);
                vaultGlpPartial[i] = previousVaultGlp[i] + glpMinted;
                feeAmounts[i] = int256(feeAmount);
            } else {
                vaultGlpPartial[i] = previousVaultGlp[i];
            }
        }
        uint256 vaultGlpPartialSum = Solarray.arraySum(vaultGlpPartial);
        {
            uint256 tolerance = _avStorage.glpRebalanceTolerance;
            uint256 totalVaultGlp = fsGLP.balanceOf(address(this));
            uint256 upper = totalVaultGlp * (10000 + tolerance) / 10000;
            uint256 lower = totalVaultGlp * (10000 - tolerance) / 10000;
            if (vaultGlpPartialSum < lower || vaultGlpPartialSum > upper) {
                revert RebalanceGlpAccountingError();
            }
        }
        for (uint256 i = 0; i < 5; ++i) {
            // set floating weights
            _vaultGlpAttribution[i] = (vaultGlpPartial[i] * 1e18) / vaultGlpPartialSum;
        }
        pullFeeAmountsFromEscrow(_avStorage, feeAmounts);
        emit RebalanceGlpPosition(
            previousVaultGlp, vaultGlpPartial, _nextGlpAllocation, vaultGlpDeltaAccount, feeAmounts
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {GMX_FEE_STAKED_GLP, TOKEN_USDC, TOKEN_WETH, TOKEN_WBTC, TOKEN_LINK, TOKEN_UNI} from "../constants.sol";
import {Solarray} from "./Solarray.sol";
import {AggregateVaultStorage} from "../storage/AggregateVaultStorage.sol";
import {INettedPositionTracker} from "../interfaces/INettedPositionTracker.sol";
import {GlpHandler} from "../handlers/GlpHandler.sol";

ERC20 constant fsGLP = ERC20(GMX_FEE_STAKED_GLP);

library LibAggregateVaultUtils {
    /**
     * @notice Converts the GLP amount owned by each vault to an array of dollar values.
     * @param _glpPrice The current price of GLP.
     * @return glpAsDollars An array containing the GLP amount owned by each vault as dollar values.
     */
    function glpToDollarArray(AggregateVaultStorage.AVStorage storage _avStorage, uint256 _glpPrice)
        internal
        view
        returns (uint256[5] memory glpAsDollars)
    {
        for (uint256 i = 0; i < 5; i++) {
            glpAsDollars[i] = (_glpPrice * getVaultGlpAttributeBalance(_avStorage, i)) / 1e18;
        }
    }

    /**
     * @notice Retrieves the GLP balance attributed to a vault.
     * @param _vaultIdx The index of the vault.
     * @return _balance The GLP balance attributed to the vault.
     */
    function getVaultGlpAttributeBalance(AggregateVaultStorage.AVStorage storage _avStorage, uint256 _vaultIdx)
        internal
        view
        returns (uint256 _balance)
    {
        uint256 totalGlpBalance = fsGLP.balanceOf(address(this));
        uint256 proportion = getVaultGlpAttributeProportion(_avStorage, _vaultIdx);
        return (totalGlpBalance * proportion) / 1e18;
    }

    /**
     * @notice Calculates the proportion of GLP attributed to a vault. 100% = 1e18, 10% = 0.1e18.
     * @param _vaultIdx The index of the vault.
     * @return _proportion The proportion of GLP attributed to the vault.
     */
    function getVaultGlpAttributeProportion(AggregateVaultStorage.AVStorage storage _avStorage, uint256 _vaultIdx)
        internal
        view
        returns (uint256 _proportion)
    {
        uint256[5] memory _vaultGlpAttribution = _avStorage.vaultGlpAttribution;
        uint256 totalGlpAttribution = Solarray.arraySum(_vaultGlpAttribution);
        if (totalGlpAttribution == 0) return 0;
        return (_vaultGlpAttribution[_vaultIdx] * 1e18) / totalGlpAttribution;
    }

    /**
     * @notice Gets the GLP for all vaults with no Profit and Loss (PNL) adjustments
     * @return _vaultsGlpNoPnl An array containing the GLP with no PNL for each vault
     */
    function getVaultsGlpNoPnl(AggregateVaultStorage.AVStorage storage _avStorage)
        internal
        view
        returns (uint256[5] memory _vaultsGlpNoPnl)
    {
        for (uint256 i = 0; i < 5; i++) {
            _vaultsGlpNoPnl[i] = getVaultGlp(_avStorage, i, 0);
        }
    }

    /**
     * @notice Gets the current Global Liquidity Position (GLP) for all vaults
     * @return _vaultsGlp An array containing the GLP for each vault
     */
    function getVaultsGlp(AggregateVaultStorage.AVStorage storage _avStorage)
        internal
        view
        returns (uint256[5] memory _vaultsGlp)
    {
        uint256 currentEpoch = _avStorage.vaultState.epoch;
        for (uint256 i = 0; i < 5; i++) {
            _vaultsGlp[i] = getVaultGlp(_avStorage, i, currentEpoch);
        }
    }

    /**
     * @notice Calculates the GLP amount owned by a vault at a given epoch.
     * @param _vaultIdx The index of the vault.
     * @param _currentEpoch The epoch number.
     * @return _glpAmount The amount of GLP owned by the vault.
     */
    function getVaultGlp(AggregateVaultStorage.AVStorage storage _avStorage, uint256 _vaultIdx, uint256 _currentEpoch)
        internal
        view
        returns (uint256 _glpAmount)
    {
        uint256 totalGlpBalance = fsGLP.balanceOf(address(this));
        uint256 ownedGlp = (totalGlpBalance * getVaultGlpAttributeProportion(_avStorage, _vaultIdx)) / 1e18;

        _glpAmount = ownedGlp;
        if (_currentEpoch > 0) {
            (,, int256[5] memory glpPnl,) = _avStorage.nettedPositionTracker.settleNettingPositionPnl(
                _avStorage.nettedPositions,
                getCurrentPrices(_avStorage),
                getEpochNettedPrice(_avStorage, _currentEpoch),
                getVaultsGlpNoPnl(_avStorage),
                (_getGlpPrice(_avStorage) * 1e18) / 1e30,
                _avStorage.zeroSumPnlThreshold
            );
            int256 glpDelta = glpPnl[_vaultIdx];
            if (glpPnl[_vaultIdx] < 0 && ownedGlp < uint256(-glpDelta)) {
                _glpAmount = 0;
            } else {
                _glpAmount = uint256(int256(ownedGlp) + glpDelta);
            }
        }
    }

    /**
     * @notice Returns the current prices from GMX.
     * @return _prices An INettedPositionTracker.NettedPrices struct containing the current asset prices
     */
    function getCurrentPrices(AggregateVaultStorage.AVStorage storage _avStorage)
        internal
        view
        returns (INettedPositionTracker.NettedPrices memory _prices)
    {
        GlpHandler glpHandler = _avStorage.glpHandler;
        _prices = INettedPositionTracker.NettedPrices({
            stable: glpHandler.getTokenPrice(TOKEN_USDC, 18),
            eth: glpHandler.getTokenPrice(TOKEN_WETH, 18),
            btc: glpHandler.getTokenPrice(TOKEN_WBTC, 18),
            link: glpHandler.getTokenPrice(TOKEN_LINK, 18),
            uni: glpHandler.getTokenPrice(TOKEN_UNI, 18)
        });
    }

    /**
     * @dev Retrieves the netted prices for a given epoch from storage.
     * @param _epoch The epoch number to get the netted prices for.
     * @return _nettedPrices The netted prices for the given epoch.
     */
    function getEpochNettedPrice(AggregateVaultStorage.AVStorage storage _avStorage, uint256 _epoch)
        internal
        view
        returns (INettedPositionTracker.NettedPrices storage _nettedPrices)
    {
        _nettedPrices = _avStorage.lastNettedPrices[_epoch];
    }

    /**
     * @notice Retrieves the current price of GLP.
     * @return _price The current price of GLP.
     */
    function _getGlpPrice(AggregateVaultStorage.AVStorage storage _avStorage) internal view returns (uint256 _price) {
        _price = _avStorage.glpHandler.getGlpPrice();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Auth, GlobalACL} from "../Auth.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

uint256 constant PRECISION = 1e18;

/// @title Vester
/// @author Umami DAO
/// @notice Vester contract to vest deposit and withdraw fee surplus into the aggregate vault
contract Vester is GlobalACL {
    using SafeTransferLib for ERC20;

    event SetVestDuration(uint256 previousVestDuration, uint256 newVestDuration);
    event Claimed(address indexed token, uint256 amount);
    event AddVest(address indexed token, uint256 amount);

    error VestingPerSecondTooLow();

    address public immutable aggregateVault;

    struct VestingInfo {
        uint256 vestingPerSecond;
        uint256 lastClaim;
    }

    mapping(address => VestingInfo) public vestingInfo;
    uint256 public vestDuration;

    constructor(Auth _auth, address _aggregateVault, uint256 _vestDuration) GlobalACL(_auth) {
        aggregateVault = _aggregateVault;
        _setVestDuration(_vestDuration);
    }

    /**
     * @notice Set the vest duration
     * @param _vestDuration The new vest duration
     */
    function setVestDuration(uint256 _vestDuration) external onlyConfigurator {
        _setVestDuration(_vestDuration);
    }

    /**
     * @notice Claim vested tokens into aggregate vault
     * @param _asset The asset to claim
     */
    function claim(address _asset) public returns (uint256) {
        uint256 vested = vested(_asset);
        if (vested == 0) return 0;

        vestingInfo[_asset].lastClaim = block.timestamp;
        emit Claimed(_asset, vested);

        ERC20(_asset).safeTransfer(aggregateVault, vested);
        return vested;
    }

    /**
     * @notice Add new vesting tokens
     * @param _asset The asset to vest
     * @param _amount The amount to vest
     */
    function addVest(address _asset, uint256 _amount) external {
        claim(_asset);

        emit AddVest(_asset, _amount);
        ERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentBalance = ERC20(_asset).balanceOf(address(this));

        uint256 vestingPerSecond = currentBalance * PRECISION / vestDuration;
        if (vestingPerSecond == 0) revert VestingPerSecondTooLow();

        vestingInfo[_asset] = VestingInfo({vestingPerSecond: vestingPerSecond, lastClaim: block.timestamp});
    }

    /**
     * Get vested amount of an asset
     * @param _asset The asset to get vested amount of
     * @return The vested amount
     */
    function vested(address _asset) public view returns (uint256) {
        uint256 duration = block.timestamp - vestingInfo[_asset].lastClaim;
        uint256 totalVested = duration * vestingInfo[_asset].vestingPerSecond / PRECISION;
        uint256 totalBalance = ERC20(_asset).balanceOf(address(this));
        return totalVested > totalBalance ? totalBalance : totalVested;
    }

    function _setVestDuration(uint256 _newVestDuration) internal {
        uint256 previousVestDuration = vestDuration;
        vestDuration = _newVestDuration;
        emit SetVestDuration(previousVestDuration, _newVestDuration);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {BaseSwapManager} from "./BaseSwapManager.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ISwapRouter} from "../../interfaces/uniswap/ISwapRouter.sol";
import {IUniswapV3Pool} from "../../interfaces/uniswap/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "../../interfaces/uniswap/IUniswapV3Factory.sol";
import {UNISWAP_SWAP_ROUTER, UNISWAP_FACTORY} from "../../constants.sol";

/**
 * @title UniswapV3SwapManager
 * @author Umami DAO
 * @notice Uniswap V3 implementation of the BaseSwapManager for swapping tokens.
 * @dev This contract uses the Uniswap V3 router for performing token swaps.
 */
contract UniswapV3SwapManager is BaseSwapManager  {
    using SafeTransferLib for ERC20;

    // STORAGE
    // ------------------------------------------------------------------------------------------

    struct Config {
        uint24[] feeTiers;
        address intermediaryAsset;
    }

    /// @notice UniV3 router for calling swaps
    /// https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
    ISwapRouter public constant uniV3Router = ISwapRouter(UNISWAP_SWAP_ROUTER);

    /// @notice UniV3 factory for discovering pools
    /// https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Factory.sol
    IUniswapV3Factory public constant uniV3factory = IUniswapV3Factory(UNISWAP_FACTORY);

    bytes32 public constant CONFIG_SLOT =
        keccak256("swapManagers.UniswapV3.config");
    address public immutable AGGREGATE_VAULT;

    constructor(address _aggregateVault, address _intermediaryAsset) {
        require(_aggregateVault != address(0), "!_aggregateVault");
        require(_intermediaryAsset != address(0), "!_intermediaryAsset");
        Config storage config = _configStorage();
        AGGREGATE_VAULT = _aggregateVault;
        config.intermediaryAsset = _intermediaryAsset;
    }

    // EXTERNAL
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Swaps tokens using the Uniswap V3 router.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     * @param - Encoded swap data (not used in this implementation).
     * @return _amountOut The actual amount of output tokens received.
     */
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _minOut,
        bytes calldata
    )
        external
        onlyDelegateCall
        swapChecks(_tokenIn, _tokenOut, _amountIn, _minOut)
        returns (uint _amountOut)
    {
        bytes memory path = _getSwapPath(_tokenIn, _tokenOut);
        _amountOut = _swapTokenExactInput(_tokenIn, _amountIn, _minOut, path);
    }

    /**
     * @notice Swaps tokens using the Uniswap V3 router.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountOut The amount of output tokens to swap into.
     * @param _maxIn The maximum amount of input tokens that can be used.
     * @return _amountIn The actual amount of output tokens received.
     */
    function exactOutputSwap(
        address _tokenIn,
        address _tokenOut,
        uint _amountOut,
        uint _maxIn
    )
        external
        onlyDelegateCall
        swapChecks(_tokenIn, _tokenOut, _maxIn, _amountOut)
        returns (uint _amountIn)
    {
        bytes memory path = _getSwapPath(_tokenIn, _tokenOut);
        _amountIn = _swapTokenExactOutput(_tokenIn, _amountOut, _maxIn, path);
    }

    /**
     * @notice Adds a new fee tier.
     * @param _feeTier A fee tier to add.
     */
    function addFeeTier(uint24 _feeTier) external onlyDelegateCall {
        require(_feeTier > 0 && _feeTier < 100000, "UniswapV3SwapManager: !_feeTier");
        Config storage config = _configStorage();
        config.feeTiers.push(_feeTier);
    }

    /**
     * @notice Removes an existing fee tier.
     * @param _feeTierToRemove A fee tier to remove.
     * @param _idx index of the tier.
     */
    function removeFeeTierAt(uint24 _feeTierToRemove, uint _idx) external onlyDelegateCall {
        Config storage config = _configStorage();
        require(config.feeTiers[_idx] == _feeTierToRemove, "UniswapV3SwapManager: invalid idx");
        config.feeTiers[_idx] = config.feeTiers[config.feeTiers.length -1];
        config.feeTiers.pop();
    }

    /**
     * @notice Sets the intermediary asset used for swapping.
     * @param _newAsset The address of the new intermediary asset.
     */
    function setIntermediaryAsset(address _newAsset) external onlyDelegateCall {
        require(_newAsset != address(0), "UniswapV3SwapManager: !_newAsset");
        Config storage config = _configStorage();
        config.intermediaryAsset = _newAsset;
    }

    // INTERNAL
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Internal function to perform a token swap with exact input.
     * @param _tokenIn The address of the input token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     * @param _path The encoded path for the swap.
     * @return _out The actual amount of output tokens received.
     */
    function _swapTokenExactInput(
        address _tokenIn,
        uint _amountIn,
        uint _minOut,
        bytes memory _path
    ) internal returns (uint _out) {
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _minOut
            });
        ERC20(_tokenIn).safeApprove(address(uniV3Router), _amountIn);
        return uniV3Router.exactInput(params);
    }

    /**
     * @notice Internal function to perform a token swap with exact input.
     * @param _tokenIn The address of the input token.
     * @param _amountOut The amount of output tokens to swap into.
     * @param _maxIn The maximum amount of input tokens to use.
     * @param _path The encoded path for the swap.
     * @return _in The actual amount of input tokens used.
     */
    function _swapTokenExactOutput(
        address _tokenIn,
        uint _amountOut,
        uint _maxIn,
        bytes memory _path
    ) internal returns (uint _in) {
        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: _amountOut,
                amountInMaximum: _maxIn
            });
        ERC20(_tokenIn).safeApprove(address(uniV3Router), _maxIn);
        return uniV3Router.exactOutput(params);
    }

    /**
     * @notice Internal function to generate the swap path.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @return path The encoded swap path.
     */
    function _getSwapPath(address _tokenIn, address _tokenOut) internal view returns (bytes memory path) {
        Config storage config = _configStorage();
        uint24 tokenInFee = _getSwapFee(_tokenIn);
        uint24 tokenOutFee = _getSwapFee(_tokenOut);
        require(tokenInFee > 0, "UniswapV3SwapManager: !_tokenIn");
        require(tokenOutFee > 0, "UniswapV3SwapManager: !_tokenOut");
        require(_tokenIn != _tokenOut, "UniswapV3SwapManager: !unique tokens");
        if (_tokenIn == config.intermediaryAsset || _tokenOut == config.intermediaryAsset) {
            path = abi.encodePacked(
                    _tokenIn,
                    tokenInFee,
                    _tokenOut
                );
        } else {
            path = abi.encodePacked(
                    _tokenIn,
                    tokenInFee,
                    config.intermediaryAsset,
                    tokenOutFee,
                    _tokenOut
                );
        }
    }

    /**
     * @notice finds the pool with the highest balance of _balanceToken
     * @param _targetToken The address of the token recorded in config.
     * @return swapFee The fee for the pool with the highest balance of _balanceToken.
     */
    function _getSwapFee(address _targetToken) internal view returns (uint24 swapFee) {
        Config storage config = _configStorage();
        address bestSwapPool;
        address iterSwapPool;
        for (uint i = 0; i < config.feeTiers.length; i++) {
            iterSwapPool = uniV3factory.getPool(
                _targetToken, 
                config.intermediaryAsset, 
                config.feeTiers[i]
            );

            // set initial value
            if (bestSwapPool == address(0) && iterSwapPool != address(0)) {
                swapFee = config.feeTiers[i];
                bestSwapPool = iterSwapPool;
            }

            if (iterSwapPool != address(0) && IUniswapV3Pool(bestSwapPool).liquidity() < IUniswapV3Pool(iterSwapPool).liquidity()) {
                swapFee = config.feeTiers[i];
                bestSwapPool = iterSwapPool;
            }
        }
    }

    /**
     * @notice Internal function to access the config storage.
     * @return config The config storage instance.
     */
    function _configStorage() internal pure returns (Config storage config) {
        bytes32 slot = CONFIG_SLOT;
        assembly {
            config.slot := slot
        }
    }
}

pragma solidity 0.8.17;
import {BaseHandler} from "../BaseHandler.sol";
import {ISwapManager} from "../../interfaces/ISwapManager.sol";
import {IHandlerContract} from "../../interfaces/IHandlerContract.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

/**
 * @title BaseSwapManager
 * @author Umami DAO
 * @notice Abstract base contract for implementing swap managers.
 * @dev This contract provides common functionality for swap manager implementations and enforces
 * swap checks using the `swapChecks` modifier.
 */
abstract contract BaseSwapManager is BaseHandler, ISwapManager {
    error InsufficientOutput();
    error InsufficientInput();
    error InvalidInput();

    /**
     * @notice Returns an empty array for callback signatures.
     * @return _ret An empty bytes4[] array.
     */
    function callbackSigs() external pure returns (bytes4[] memory _ret) {
        _ret = new bytes4[](0);
    }

    /**
     * @notice Modifier to enforce swap checks, ensuring sufficient input and output token amounts.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     */
    modifier swapChecks(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _minOut
    ) {
        uint tokenInBalance = ERC20(_tokenIn).balanceOf(address(this));
        if (tokenInBalance < _amountIn) revert InsufficientInput();
        uint tokenOutBalanceBefore = ERC20(_tokenOut).balanceOf(address(this));
        _;
        uint tokenOutBalanceAfter = ERC20(_tokenOut).balanceOf(address(this));
        uint actualOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
        if (actualOut < _minOut) revert InsufficientOutput();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {IUniswapV3PoolState} from "./IUniswapV3PoolState.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is IUniswapV3PoolState {
    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);
    
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}
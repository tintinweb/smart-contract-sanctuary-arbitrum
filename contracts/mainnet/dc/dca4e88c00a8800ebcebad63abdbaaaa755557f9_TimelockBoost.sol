// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ShareMath } from "../libraries/ShareMath.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { IAggregateVault } from "../interfaces/IAggregateVault.sol";
import { GlobalACL, Auth } from "../Auth.sol";

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

    constructor(ERC20 _asset, string memory _name, string memory _symbol, uint256 _withdrawDuration, Auth _auth)
        ERC4626(_asset, _name, _symbol)
        GlobalACL(_auth)
    {
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
    function initiateWithdraw(uint256 _assets) external whenNotPaused returns (uint256 shares) {
        shares = convertToShares(_assets);
        _initiateWithdrawShares(shares, _assets);
    }

    /**
     * @notice Initiate a withdrawal of the specified amount of shares.
     * @param _shares The amount of shares to withdraw.
     * @return _assets The number of assets withdrawn for given shares.
     */
    function initiateRedeem(uint256 _shares) external whenNotPaused returns (uint256 _assets) {
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
        uint256 withdrawAmount;
        for (uint256 i = 0; i < LOCK_QUEUE_LIMIT; i++) {
            if (
                accountWithdrawals[i].queuedTimestamp + lockState.withdrawDuration < block.timestamp
                    && accountWithdrawals[i].queuedTimestamp != 0
            ) {
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
    function claimWithdrawalsFor(address _account, address _receiver)
        external
        whenNotPaused
        onlyZap
        returns (uint256 _totalWithdraw)
    {
        require(activeWithdrawals[_account] > 0, "TimelockBoost: !activeWithdrawals");
        QueuedWithdrawal[LOCK_QUEUE_LIMIT] storage accountWithdrawals = withdrawalQueue[_account];
        uint256 withdrawAmount;
        for (uint256 i = 0; i < LOCK_QUEUE_LIMIT; i++) {
            if (
                accountWithdrawals[i].queuedTimestamp + lockState.withdrawDuration < block.timestamp
                    && accountWithdrawals[i].queuedTimestamp != 0
            ) {
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

    function _initiateWithdrawShares(uint256 _shares, uint256 _assets) internal {
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
        for (uint256 i = 0; i < LOCK_QUEUE_LIMIT; i++) {
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
        require(
            accountWithdrawals[_index].queuedTimestamp + lockState.withdrawDuration < block.timestamp,
            "TimelockBoost: !withdrawalDuration"
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(uint256 assetAmount, uint256 assetPerShare, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (assetAmount * 10 ** decimals) / assetPerShare;
    }

    function sharesToAsset(uint256 shares, uint256 assetPerShare, uint256 decimals) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (shares * assetPerShare) / 10 ** decimals;
    }

    function pricePerShare(uint256 totalSupply, uint256 totalBalance, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 singleShare = 10 ** decimals;
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

    event RoleUpdated(bytes32 indexed role, address indexed user, bool authorized);

    bytes32 public constant AUTH_MANAGER_ROLE = keccak256("AUTH_MANAGER");
    mapping(bytes32 => mapping(address => bool)) public hasRole;

    constructor() {
        _updateRole(msg.sender, AUTH_MANAGER_ROLE, true);
    }

    function updateRole(address _user, bytes32 _role, bool _authorized) external {
        onlyRole(AUTH_MANAGER_ROLE, msg.sender);
        _updateRole(_user, _role, _authorized);
    }

    function onlyRole(bytes32 _role, address _user) public view {
        if (!hasRole[_role][_user]) {
            revert NotAuthorized(_role, _user);
        }
    }

    function _updateRole(address _user, bytes32 _role, bool _authorized) internal {
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
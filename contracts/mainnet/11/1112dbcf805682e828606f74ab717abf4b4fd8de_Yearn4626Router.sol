/**
 *Submitted for verification at Arbiscan on 2023-08-08
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626
abstract contract IERC4626 is ERC20 {
    /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

    /// @notice `sender` has exchanged `assets` for `shares`,
    /// and transferred those `shares` to `receiver`.
    event Deposit(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

    /// @notice `sender` has exchanged `shares` for `assets`,
    /// and transferred those `assets` to `receiver`.
    event Withdraw(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view virtual returns (address asset);

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() external view virtual returns (uint256 totalAssets);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `shares` Vault shares to `receiver` by
    /// depositing exactly `assets` of underlying tokens.
    function deposit(uint256 assets, address receiver) external virtual returns (uint256 shares);

    /// @notice Mints exactly `shares` Vault shares to `receiver`
    /// by depositing `assets` of underlying tokens.
    function mint(uint256 shares, address receiver) external virtual returns (uint256 assets);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) external view virtual returns (uint256 shares);

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view virtual returns (uint256 assets);

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner) external view virtual returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets) external view virtual returns (uint256 shares);

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner) external view virtual returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares) external view virtual returns (uint256 assets);

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner) external view virtual returns (uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view virtual returns (uint256 shares);

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner) external view virtual returns (uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares) external view virtual returns (uint256 assets);
}

/// @title Yearn V3 ERC4626 interface
/// @notice Extends the normal 4626 standard with some added Yearn specific functionality
abstract contract IYearn4626 is IERC4626 {
    /*////////////////////////////////////////////////////////
                    Yearn Specific Functions
    ////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external virtual returns (uint256 shares);

    /// @notice Yearn Specific "withdraw" with withdrawal stack included
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss,
        address[] memory strategies
    ) external virtual returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external virtual returns (uint256 assets);

    /// @notice Yearn Specific "redeem" with withdrawal stack included
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss,
        address[] memory strategies
    ) external virtual returns (uint256 assets);
}

/** 
 @title ERC4626Router Base Interface
 @notice A canonical router between ERC4626 Vaults https://eips.ethereum.org/EIPS/eip-4626

 The base router is a multicall style router inspired by Uniswap v3 with built-in features for permit, WETH9 wrap/unwrap, and ERC20 token pulling/sweeping/approving.
 It includes methods for the four mutable ERC4626 functions deposit/mint/withdraw/redeem as well.

 These can all be arbitrarily composed using the multicall functionality of the router.

 NOTE the router is capable of pulling any approved token from your wallet. This is only possible when your address is msg.sender, but regardless be careful when interacting with the router or ERC4626 Vaults.
 The router makes no special considerations for unique ERC20 implementations such as fee on transfer. 
 There are no built in protections for unexpected behavior beyond enforcing the minSharesOut is received.
 */
interface IYearn4626RouterBase {
    /*//////////////////////////////////////////////////////////////
                                MINT
    //////////////////////////////////////////////////////////////*/

    /** 
     @notice mint `shares` from an ERC4626 vault.
     @param vault The ERC4626 vault to mint shares from.
     @param shares The amount of shares to mint from `vault`.
     @param to The destination of ownership shares.
     @param maxAmountIn The max amount of assets used to mint.
     @return amountIn the amount of assets used to mint by `to`.
     @dev throws "!maxAmount" Error   
    */
    function mint(
        IYearn4626 vault,
        uint256 shares,
        address to,
        uint256 maxAmountIn
    ) external payable returns (uint256 amountIn);

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /** 
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param amount The amount of assets to deposit to `vault`.
     @param to The destination of ownership shares.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws "!minShares" Error   
    */
    function deposit(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /** 
     @notice withdraw `amount` from an ERC4626 vault.
     @dev Uses the Yearn specific 'maxLoss' accounting.
     @param vault The ERC4626 vault to redeem shares from.
     @param vault The ERC4626 vault to withdraw assets from.
     @param amount The amount of assets to withdraw from vault.
     @param to The destination of assets.
     @param maxLoss The acceptable loss in Basis Points.
     @return sharesOut the amount of shares received by `to`.
     @dev throws "to much loss" Error   
    */
    function withdraw(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 maxLoss
    ) external payable returns (uint256);

    /** 
     @notice withdraw `amount` from an ERC4626 vault.
     @dev Uses the default 4626 syntax, throws !maxShares" Error.
     @param vault The ERC4626 vault to withdraw assets from.
     @param amount The amount of assets to withdraw from vault.
     @param to The destination of assets.
     @param minSharesOut The min amount of shares received by `to`.
     @return sharesOut the amount of shares received by `to`. 
    */
    function withdrawDefault(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /*//////////////////////////////////////////////////////////////
                                REDEEM
    //////////////////////////////////////////////////////////////*/

    /** 
     @notice redeem `shares` shares from an ERC4626 vault.
     @dev Uses the Yearn specific 'maxLoss' accounting.
     @param vault The ERC4626 vault to redeem shares from.
     @param shares The amount of shares to redeem from vault.
     @param to The destination of assets.
     @param maxLoss The acceptable loss in Basis Points.
     @return amountOut the amount of assets received by `to`.
     @dev throws "to much loss" Error   
    */
    function redeem(
        IYearn4626 vault,
        uint256 shares,
        address to,
        uint256 maxLoss
    ) external payable returns (uint256);

    /** 
     @notice redeem `shares` shares from an ERC4626 vault.
     @dev Uses the default 4626 syntax, throws "!minAmount" Error.
     @param vault The ERC4626 vault to redeem shares from.
     @param shares The amount of shares to redeem from vault.
     @param to The destination of assets.
     @param minAmountOut The min amount of assets received by `to`.
     @return amountOut the amount of assets received by `to`.
    */
    function redeemDefault(
        IYearn4626 vault,
        uint256 shares,
        address to,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut);
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

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

// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISelfPermit.sol

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

// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/external/IERC20PermitAllowed.sol

/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        ERC20(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (ERC20(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (ERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
            selfPermitAllowed(token, nonce, expiry, v, r, s);
    }
}

// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol


// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/IMulticall.sol


/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

/**
 @title Periphery Payments
 @notice Immutable state used by periphery contracts
 Largely Forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryPayments.sol 
 Changes:
 * no interface
 * no inheritdoc
 * add immutable WETH9 in constructor instead of PeripheryImmutableState
 * receive from any address
 * Solmate interfaces and transfer lib
 * casting
 * add approve, wrapWETH9 and pullToken
*/
abstract contract PeripheryPayments {
    using SafeTransferLib for *;

    IWETH9 public immutable WETH9;

    constructor(IWETH9 _WETH9) {
        WETH9 = _WETH9;
    }

    receive() external payable {}

    function approve(
        ERC20 token,
        address to,
        uint256 amount
    ) public payable {
        token.safeApprove(to, amount);
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable {
        uint256 balanceWETH9 = WETH9.balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            WETH9.withdraw(balanceWETH9);
            recipient.safeTransferETH(balanceWETH9);
        }
    }

    function wrapWETH9() public payable {
        if (address(this).balance > 0) WETH9.deposit{value: address(this).balance}(); // wrap everything
    }

    function pullToken(
        ERC20 token,
        uint256 amount,
        address recipient
    ) public payable {
        token.safeTransferFrom(msg.sender, recipient, amount);
    }

    function sweepToken(
        ERC20 token,
        uint256 amountMinimum,
        address recipient
    ) public payable {
        uint256 balanceToken = token.balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            token.safeTransfer(recipient, balanceToken);
        }
    }

    function refundETH() external payable {
        if (address(this).balance > 0) SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
}

abstract contract IWETH9 is ERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable virtual;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external virtual;
}

/// @title ERC4626 Router Base Contract
abstract contract Yearn4626RouterBase is
    IYearn4626RouterBase,
    SelfPermit,
    Multicall,
    PeripheryPayments
{
    using SafeTransferLib for ERC20;

    /// @inheritdoc IYearn4626RouterBase
    function mint(
        IYearn4626 vault,
        uint256 shares,
        address to,
        uint256 maxAmountIn
    ) public payable virtual override returns (uint256 amountIn) {
        require ((amountIn = vault.mint(shares, to)) <= maxAmountIn, "!MaxAmount");
    }

    /// @inheritdoc IYearn4626RouterBase
    function deposit(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        require ((sharesOut = vault.deposit(amount, to)) >= minSharesOut, "!MinShares");
    }

    /// @inheritdoc IYearn4626RouterBase
    function withdraw(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 maxLoss
    ) public payable virtual override returns (uint256) {
        return vault.withdraw(amount, to, msg.sender, maxLoss);
    }

    /// @inheritdoc IYearn4626RouterBase
    function withdrawDefault(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 maxSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        require ((sharesOut = vault.withdraw(amount, to, msg.sender)) <= maxSharesOut, "!MaxShares");
    }

    /// @inheritdoc IYearn4626RouterBase
    function redeem(
        IYearn4626 vault,
        uint256 shares,
        address to,
        uint256 maxLoss
    ) public payable virtual override returns (uint256) {
        return vault.redeem(shares, to, msg.sender, maxLoss);
    }

    /// @inheritdoc IYearn4626RouterBase
    function redeemDefault(
        IYearn4626 vault,
        uint256 shares,
        address to,
        uint256 minAmountOut
    ) public payable virtual override returns (uint256 amountOut) {
        require ((amountOut = vault.redeem(shares, to, msg.sender)) >= minAmountOut, "!MinAmount");
    }
}

abstract contract IYearnV2 is ERC20 {
    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external virtual returns (uint256);

    function withdraw(uint256 maxShares) external virtual returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external virtual returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external virtual returns (uint256);
}

/** 
 @title ERC4626Router Interface
 @notice Extends the ERC4626RouterBase with specific flows to save gas
 */
interface IYearn4626Router {
    /*//////////////////////////////////////////////////////////////
                            DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /** 
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return . the amount of shares received by `to`.
     @dev throws "!minShares" Error.
    */
    function depositToVault(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            MIGRATION
    //////////////////////////////////////////////////////////////*/

    /** 
     @notice will redeem `shares` from one vault and deposit amountOut to a different ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param shares The amount of shares to redeem from fromVault.
     @param to The destination of ownership shares.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return . the amount of shares received by `to`.
     @dev throws "!minAmount", "!minShares" Errors.
    */
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            V2 MIGRATION
    //////////////////////////////////////////////////////////////*/

    /**
     @notice migrate from Yearn V2 vault to a V3 vault'.
     @param fromVault The Yearn V2 vault to withdraw from.
     @param toVault The Yearn V3 vault to deposit assets to.
     @param shares The amount of V2 shares to redeem form 'fromVault'.
     @param to The destination of ownership shares
     @param minSharesOut The min amount of 'toVault' shares to be received by 'to'.
     @return . The actual amount of 'toVault' shares received by 'to'.
     @dev throws "!minAmount", "!minShares" Errors.
    */
    function migrateFromV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256);
}

/**
 * @title Yearn4626Router contract
 * @notice
 *  Router that is meant to be used with Yearn V3 vaults and strategies
 *  for deposits, withdraws and migrations.
 *  
 *  The router was developed from the original router by FEI protocol
 *  https://github.com/fei-protocol/ERC4626
 *
 *  The router is designed to be used with permit and multicall for the 
 *  optimal experience.
 *
 *  NOTE: It is important to never leave tokens in the router at the 
 *  end of a call, otherwise they can be swept by anyone.
 */
contract Yearn4626Router is IYearn4626Router, Yearn4626RouterBase {
    using SafeTransferLib for ERC20;

    // Store name as bytes so it can be immutable
    bytes32 private immutable _name;

    constructor(string memory _name_, IWETH9 weth) PeripheryPayments(weth) {
        _name = bytes32(abi.encodePacked(_name_));
    }

    // Getter function to unpack stored name.
    function name() external view returns(string memory) {
        return string(abi.encodePacked(_name));
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT
    //////////////////////////////////////////////////////////////*/

    // For the below, no approval needed, assumes vault is already max approved

    /// @inheritdoc IYearn4626Router
    function depositToVault(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256) {
        pullToken(ERC20(vault.asset()), amount, address(this));
        return deposit(vault, amount, to, minSharesOut);
    }

    //-------- DEPOSIT FUNCTIONS WITH DEFAULT VALUES --------\\ 

    /**
     @notice See {depositToVault} in IYearn4626Router.
     @dev Uses msg.sender as the default for `to`.
    */
    function depositToVault(
        IYearn4626 vault,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256) {
        return depositToVault(vault, amount, msg.sender, minSharesOut);
    }

    /**
     @notice See {depositToVault} in IYearn4626Router.
     @dev Uses msg.sender as the default for `to` and their full 
     balance of msg.sender as `amount`.
    */
    function depositToVault(
        IYearn4626 vault, 
        uint256 minSharesOut
    ) external payable returns (uint256) {
        uint256 amount = ERC20(vault.asset()).balanceOf(msg.sender);
        return depositToVault(vault, amount, msg.sender, minSharesOut);
    }

    /**
     @notice See {depositToVault} in IYearn4626Router.
     @dev Uses msg.sender as the default for `to`, their full balance 
     of msg.sender as `amount` and 1 Basis point for `maxLoss`.
     
     NOTE: The slippage tollerance is only useful if {previewDeposit}
     cannot be manipulated for the `vault`.
    */
    function depositToVault(
        IYearn4626 vault
    ) external payable returns (uint256) {
        uint256 assets =  ERC20(vault.asset()).balanceOf(msg.sender);
        // This give a default 1Basis point acceptance for loss. This is only 
        // considered safe if the vaults PPS can not be manipulated.
        uint256 minSharesOut = vault.previewDeposit(assets) * 9_999 / 10_000;
        return depositToVault(vault, assets, msg.sender, minSharesOut);
    }

    /*//////////////////////////////////////////////////////////////
                            REDEEM
    //////////////////////////////////////////////////////////////*/

    //-------- REDEEM FUNCTIONS WITH DEFAULT VALUES --------\\

    /**
     @notice See {redeem} in IYearn4626RouterBase.
     @dev Uses msg.sender as `receiver`.
    */
    function redeem(
        IYearn4626 vault,
        uint256 shares,
        uint256 maxLoss
    ) external payable returns (uint256) {
        return redeem(vault, shares, msg.sender, maxLoss);
    }

    /**
     @notice See {redeem} in IYearn4626RouterBase.
     @dev Uses msg.sender as `receiver` and their full balance as `shares`.
    */
    function redeem(
        IYearn4626 vault,
        uint256 maxLoss
    ) external payable returns (uint256) {
        uint256 shares = vault.balanceOf(msg.sender);
        return redeem(vault, shares, msg.sender, maxLoss);
    }

    /**
     @notice See {redeem} in IYearn4626RouterBase.
     @dev Uses msg.sender as `receiver`, their full balance as `shares`
     and 1 Basis Point for `maxLoss`.
    */
    function redeem(
        IYearn4626 vault
    ) external payable returns (uint256) {
        uint256 shares = vault.balanceOf(msg.sender);
        return redeem(vault, shares, msg.sender, 1);
    }

    /*//////////////////////////////////////////////////////////////
                            MIGRATE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IYearn4626Router
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256) {
        // amount out passes through so only one slippage check is needed
        uint256 amount = redeem(fromVault, shares, address(this), 10_000);
        return deposit(toVault, amount, to, minSharesOut);
    }

    //-------- MIGRATE FUNCTIONS WITH DEFAULT VALUES --------\\

    /**
     @notice See {migrate} in IYearn4626Router.
     @dev Uses msg.sender as `to`.
    */
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256) {
        return migrate(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
     @notice See {migrate} in IYearn4626Router.
     @dev Uses msg.sender as `to` and their full balance for `shares`.
    */
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 minSharesOut
    ) external payable returns (uint256) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrate(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
     @notice See {migrate} in IYearn4626Router.
     @dev Uses msg.sender as `to`, their full balance for `shares` and no `minamountOut`.

     NOTE: Using this will enforce no slippage checks and should be used with care.
    */
    function migrate(
        IYearn4626 fromVault, 
        IYearn4626 toVault
    ) external payable returns (uint256) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrate(fromVault, toVault, shares, msg.sender, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        V2 MIGRATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IYearn4626Router
    function migrateFromV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256) {
        // V2 can't specify owner so we need to first pull the shares
        fromVault.transferFrom(msg.sender, address(this), shares);
        // amount out passes through so only one slippage check is needed
        uint256 redeemed = fromVault.withdraw(shares, address(this));
        return deposit(toVault, redeemed, to, minSharesOut);
    }

    //-------- migrateFromV2 FUNCTIONS WITH DEFAULT VALUES --------\\

    /**
     @notice See {migrateFromV2} in IYearn4626Router.
     @dev Uses msg.sender as `to`.
    */
    function migrateFromV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256) {
        return migrateFromV2(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
     @notice See {migrateFromV2} in IYearn4626Router.
     @dev Uses msg.sender as `to` and their full balance as `shares`.
    */
    function migrateFromV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 minSharesOut
    ) external payable returns (uint256) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrateFromV2(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
     @notice See {migrate} in IYearn4626Router.
     @dev Uses msg.sender as `to`, their full balance for `shares` and no `minamountOut`.

     NOTE: Using this will enforce no slippage checks and should be used with care.
    */
    function migrateFromV2(
        IYearnV2 fromVault,
        IYearn4626 toVault
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrateFromV2(fromVault, toVault, shares, msg.sender, 0);
    }
}
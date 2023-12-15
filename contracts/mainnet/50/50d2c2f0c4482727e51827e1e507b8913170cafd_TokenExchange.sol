// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

/// @notice Buffer contract for quick token <> token exchagne.
contract TokenExchange is Owned {
    using SafeTransferLib for ERC20;

    /// @notice The exchange token we issue or redeem.
    ERC20 public immutable exchangeToken;

    /// @notice Whether issuing is enabled.
    bool public canIssue = true;
    /// @notice Whether redeeming is enabled.
    bool public canRedeem = true;

    /// @notice Initial 0.01% fee on issue and redeem.
    uint256 public issueFeeBps = 1;
    uint256 public redeemFeeBps = 1;

    /// @notice 1 unit of token x gives y units of exchange token, multiplied by 10^18.
    /// @dev Example: if exchangeToken is a stablecion with 6 decimals: exchangeRate[USDC] = 1e18, exchangeRate[DAI] = 1e6.
    mapping(address token => uint256 rate) public exchangeRate;

    event SetExchangeRate(address indexed token, uint256 rate);
    event Issue(address indexed account, address tokenIn, uint256 amountIn, uint256 amountIssued);
    event Redeem(address indexed account, address tokenOut, uint256 amountOut, uint256 amountRedeemed);
    event CanIssue(bool status);
    event CanRedeem(bool status);
    event SetIssueFeeBps(uint256 feeBps);
    event SetRedeemFeeBps(uint256 feeBps);

    error CannotIssue();
    error CannotRedeem();
    error NoExchangeRate();

    constructor(address _exchangeToken)
        Owned(msg.sender)
    {
        exchangeToken = ERC20(_exchangeToken);
    }

    /// @notice Calculates the amount of exchangeToken to issue in exchange for a quote token.
    function getIssueAmount(address tokenIn, uint256 amountIn) public view returns (uint256) {
        uint256 rate = exchangeRate[tokenIn];
        if (rate == 0) revert NoExchangeRate();
        return (amountIn * rate / 1e18) * (1e6 - issueFeeBps) / 1e6;
    }

    /// @notice Calculates the amount of tokenOut to redeem in exchange for exchangeToken.
    function getRedeemAmount(address tokenOut, uint256 amountIn) public view returns (uint256) {
        uint256 rate = exchangeRate[tokenOut];
        if (rate == 0) revert NoExchangeRate();
        return (amountIn * 1e18 / rate) * (1e6 - redeemFeeBps) / 1e6;
    }

    function issue(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        if (!canIssue) revert CannotIssue();
        amountOut = getIssueAmount(tokenIn, amountIn);
        ERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        exchangeToken.safeTransfer(msg.sender, amountOut);
        emit Issue(msg.sender, tokenIn, amountIn, amountOut);
    }

    function redeem(address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        if (!canRedeem) revert CannotRedeem();
        amountOut = getRedeemAmount(tokenOut, amountIn);
        exchangeToken.safeTransferFrom(msg.sender, address(this), amountIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);
        emit Redeem(msg.sender, tokenOut, amountIn, amountOut);
    }

    /// @notice Set the exchange rate for a token.
    function setExchangeRate(address token, uint256 rate) external onlyOwner {
        exchangeRate[token] = rate;
        emit SetExchangeRate(token, rate);
    }

    /// @notice Set the issue fee.
    function setIssueFee(uint256 feeBps) external onlyOwner {
        issueFeeBps = feeBps;
        emit SetIssueFeeBps(feeBps);
    }

    /// @notice Set the redeem fee.
    function setRedeemFee(uint256 feeBps) external onlyOwner {
        redeemFeeBps = feeBps;
        emit SetRedeemFeeBps(feeBps);
    }

    /// @notice Pauses or unpauses issuing.
    function enableIssuing(bool status) external onlyOwner {
        canIssue = status;
        emit CanIssue(status);
    }

    /// @notice Pauses or unpauses redeeming.
    function enableRedeeming(bool status) external onlyOwner {
        canRedeem = status;
        emit CanRedeem(status);
    }

    /// @notice Owner has full access over contract funds.
    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        ERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

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

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
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
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
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
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
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
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

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
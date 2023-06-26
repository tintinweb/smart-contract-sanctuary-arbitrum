// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {Position, IVault} from "../core/Gmx/interfaces/IVault.sol";

contract GmxVault is IVault {
    address public owner;
    address public override gov;
    address public USDC;

    mapping(address => AggregatorV3Interface) public priceFeeds;

    mapping(address => uint256) public override tokenBalances;
    mapping(address => uint256) public override tokenWeights;
    mapping(address => uint256) public override usdgAmounts;
    mapping(address => uint256) public override maxUsdgAmounts;
    mapping(address => uint256) public override poolAmounts;
    mapping(address => uint256) public override reservedAmounts;
    mapping(address => uint256) public override bufferAmounts;

    uint256 public override taxBasisPoints = 50;
    uint256 public override swapFeeBasisPoints = 30;

    constructor(address _USDC) {
        owner = msg.sender;
        USDC = _USDC;
    }

    /// @notice Set the price feed to use.
    function setPriceFeed(address token, address priceFeed) public {
        require(owner == msg.sender, "UNAUTHORIZED");
        priceFeeds[token] = AggregatorV3Interface(priceFeed);
    }

    /// @notice Synchronize the balance mapping with the actual contract balance.
    function syncTokenBalance(address token) public {
        tokenBalances[token] = ERC20(token).balanceOf(address(this));
    }

    /// @notice Mimic GMX vault.
    function getFeeBasisPoints(
        address,
        uint256,
        uint256,
        uint256,
        bool
    ) external pure override returns (uint256) {
        return 30;
    }

    // TODO: impl cumulativeFundingRates.
    /// @notice Mimic GMX vault.
    function cumulativeFundingRates(address) external pure returns (uint256) {
        return 0;
    }

    /// @notice Mimic GMX vault.
    function getMaxPrice(address token) public view override returns (uint256) {
        if (token == USDC) {
            return 1e30;
        }
        (, int256 answer, , , ) = priceFeeds[token].latestRoundData();
        return uint256(answer) * 1e22;
    }

    /// @notice Mimic GMX vault.
    function getMinPrice(address token) public view override returns (uint256) {
        if (token == USDC) {
            return 1e30;
        }

        (, int256 answer, , , ) = priceFeeds[token].latestRoundData();
        return uint256(answer) * 1e22;
    }

    /// @notice Mimic GMX vault.
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOutAfterFees, uint256 feeAmount) {
        uint256 priceIn = getMinPrice(tokenIn);
        uint256 priceOut = getMaxPrice(tokenOut);

        uint256 precisionIn = 10 ** ERC20(tokenIn).decimals();
        uint256 precisionOut = 10 ** ERC20(tokenOut).decimals();

        uint256 amountOutBeforeFees = (amountIn * priceIn * precisionOut) /
            (priceOut * precisionIn);

        amountOutAfterFees =
            (amountOutBeforeFees * (10_000 - swapFeeBasisPoints)) /
            10_000;

        feeAmount = amountOutBeforeFees - amountOutAfterFees;
    }

    /// @notice Mimic GMX vault.
    function swap(
        address tokenIn,
        address tokenOut,
        address receiver
    ) external override returns (uint256 amountOutAfterFees) {
        uint256 amountIn = ERC20(tokenIn).balanceOf(address(this));
        amountIn -= tokenBalances[tokenIn];

        (amountOutAfterFees, ) = getAmountOut(tokenIn, tokenOut, amountIn);
        ERC20(tokenOut).transfer(receiver, amountOutAfterFees);

        syncTokenBalance(tokenIn);
        syncTokenBalance(tokenOut);
    }

    // TODO: impl getPositionKey.
    /// @notice Mimic GMX vault.
    function getPositionKey(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    ) external pure override returns (bytes32) {}

    // TODO: impl positions.
    /// @notice Mimic GMX vault.
    function positions(
        bytes32 key
    ) external view override returns (Position memory) {}

    // TODO: impl increasePosition.
    /// @notice Mimic GMX vault.
    function increasePosition(
        address account,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong
    ) external {}

    // TODO: impl decreasePosition.
    /// @notice Mimic GMX vault.
    function decreasePosition(
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver
    ) external returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

struct Position {
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    int256 realisedPnl;
    uint256 lastIncreasedTime;
}

interface IVault {
    function gov() external view returns (address);

    function tokenBalances(address token) external view returns (uint256);

    function tokenWeights(address token) external view returns (uint256);

    function usdgAmounts(address token) external view returns (uint256);

    function maxUsdgAmounts(address token) external view returns (uint256);

    function poolAmounts(address token) external view returns (uint256);

    function reservedAmounts(address token) external view returns (uint256);

    function bufferAmounts(address token) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function getFeeBasisPoints(
        address token,
        uint256 usdgDelta,
        uint256 feeBasisPoints,
        uint256 taxBasisPoints,
        bool increment
    ) external view returns (uint256);

    function cumulativeFundingRates(
        address collateralToken
    ) external view returns (uint256);

    function getMaxPrice(address token) external view returns (uint256);

    function getMinPrice(address token) external view returns (uint256);

    function swap(
        address tokenIn,
        address tokenOut,
        address receiver
    ) external returns (uint256);

    function getPositionKey(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    ) external pure returns (bytes32);

    function positions(bytes32 key) external view returns (Position memory);
}
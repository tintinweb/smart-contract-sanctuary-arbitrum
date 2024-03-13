/**
 *Submitted for verification at Arbiscan.io on 2024-03-11
*/

// SPDX-License-Identifier: MIT
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
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

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


interface IStableOracle {
    // return 18 decimals USD price of an asset
    function getPriceUSD() external view returns (uint256);
}


interface IUSSDInsurance {
    function insuranceClaim() external;
}


interface IUSSD {
    function prevSupplyAndCF() external view returns (uint256, uint256);
    function mintRewards(uint256 stableCoinAmount, address to) external;
}


/**
    @notice Autonomous on-chain stablecoin
 */
contract USSD is
    IUSSD,
    ERC20
{
    //using SafeERC20 for IERC20;
    using SafeTransferLib for ERC20;

    address public stakingContract;
    address public insuranceContract;

    bool public switchedToDAI;
    bool public switchedToWETH;

    address public constant STABLE = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public constant STABLEDAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address public constant WBGL = 0x2bA64EFB7A4Ec8983E22A49c81fa216AC33f383A;
    address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address private STABLE_ORACLE;
    address private STABLEDAI_ORACLE;
    address private WBGL_ORACLE;
    address private WBTC_ORACLE;
    address private WETH_ORACLE;

    address private owner;

    uint256 private currSupply;
    uint256 private prevSupply;
    uint256 private currCollateralFactor;
    uint256 private prevCollateralFactor;
    uint256 private prevBlockNo;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {
        owner = msg.sender;
    }

    /**
        @dev restrict calls only by STABLE_CONTROL_ROLE role
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }

    /**
        @dev connect staking contract (deployed after this contract)
     */
    function connectStaking(address _staking) public onlyOwner {
        require(stakingContract == address(0)); // can be triggered only once
        stakingContract = _staking;
    }

    /**
        @dev connect insurance contract (deployed after this contract)
     */
    function connectInsurance(address _insurance) public onlyOwner {
        require(insuranceContract == address(0)); // can be triggered only once
        insuranceContract = _insurance;
    }

    /**
        @dev single-time if stable (USDT) goes bad, switch to DAI
     */
    function switchToDAI() public onlyOwner {
        require(!switchedToWETH && !switchedToDAI);
        switchedToDAI = true;
    }

    /**
        @dev single-time if all collateral pegs fail, switch to WETH only
     */
    function switchToWETH() public onlyOwner {
        require(!switchedToWETH);
        switchedToWETH = true;
    }

    /**
        @dev single-time connect oracles (or these addresses could be hardcoded consts)
     */
    function setOracles(address _stableOracle, address _DAIOracle, address _WBGLOracle, address _WBTCOracle, address _WETHOracle) public onlyOwner {
        require(STABLE_ORACLE == address(0)); // can be triggered only once
        STABLE_ORACLE = _stableOracle;
        STABLEDAI_ORACLE = _DAIOracle;
        WBGL_ORACLE = _WBGLOracle;
        WBTC_ORACLE = _WBTCOracle;
        WETH_ORACLE = _WETHOracle;
    }

    /**
        @dev change owner address or completely lock owner methods
     */
    function changeOwner(address _owner) public onlyOwner {
        require(owner != 0x0000000000000000000000000000000000000000, "zero addr");
        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Mint(
        address indexed from,
        address indexed to,
        address token,
        uint256 amountToken,
        uint256 amountUSSD
    );

    event Redeem(
        address indexed from,
        address indexed to,
        uint256 amountUSSD,
        uint256 amountValuation
    );

    /*//////////////////////////////////////////////////////////////
                             MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @dev Mint by staking or insurance contracts as rewards
             could be called only by staking or insurance contracts
     */
    function mintRewards(
        uint256 stableCoinAmount,
        address to
    ) public override {
        require(msg.sender == stakingContract || msg.sender == insuranceContract, "minter");
        require(to != address(0));

        _mint(to, stableCoinAmount);

        emit Mint(msg.sender, to, address(0), 0, stableCoinAmount);
    }

    /**
        @dev mint specific AMOUNT OF STABLE by giving token depending on conditions
    */
    function mintForToken(
        address token,
        uint256 tokenAmount,
        address to
    ) public returns (uint256 stableCoinAmount) {
        require(to != address(0));

        if (switchedToWETH) {
            require(token == WETH, "weth only");
        } else {
            address stable = STABLE;
            if (switchedToDAI) {
                stable = STABLEDAI;
            }
            uint256 balance = ERC20(stable).balanceOf(address(this)) / 1e12; // USSD has 6 decimals

            if (btcsummer() || balance <= (this.totalSupply() * 5 / 100)) {
                // mint only for stables is allowed
                require(token == stable, "STABLE only");
            } else if (balance > (this.totalSupply() * 15 / 100)) {
                // WBSC or WETH only
                require(token == WETH || token == WBTC, "WBTCorWETH");
            } else {
                require(token == WETH || token == WBTC || token == stable, "unknown token");
            }
        }

        stableCoinAmount = calculateMint(token, tokenAmount);
        _mint(to, stableCoinAmount);
        
        ERC20(token).safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );

        // protect from flash-loan supply inflation
        if (block.number > prevBlockNo) {
            prevSupply = currSupply; // remember latest total supply in some prev. block
            prevCollateralFactor = currCollateralFactor;
            prevBlockNo = block.number;
        }
        currSupply = totalSupply;
        currCollateralFactor = collateralFactor();

        emit Mint(msg.sender, to, token, tokenAmount, stableCoinAmount);
    }

    /**
        @dev try to evaluate stage of BTC 4-year halving cycle
    */
    function btcsummer() internal view returns (bool) {
        // (822721 + (block.timestamp - 1703420845) / 600) % 210000
        // range 0-209999
        // 52500 - 105000 is 2nd stage of cycle (summer), otherwise 1st stage of cycle (winter)
        uint256 cycle = (822721 + (block.timestamp - 1703420845) / 600) % 210000;
        if (cycle >= 52500 && cycle <= 105000) {
            return true;
        }
        return false;
    }

    /**
        @dev Return how much STABLECOIN does user receive for AMOUNT of asset
    */
    function calculateMint(address _token, uint256 _amount) public view returns (uint256) {
        // all collateral component tokens have 18 decimals, so divide by 1e36 = 1e18 price fraction and 1e18 token fraction
        if (_token == WETH) {
            return IStableOracle(WETH_ORACLE).getPriceUSD() * _amount / 1e30; // * (10 ** decimals) / 1e36;    
        } else if (_token == WBTC) {
            return IStableOracle(WBTC_ORACLE).getPriceUSD() * _amount / 1e30; // * (10 ** decimals) / 1e36;    
        } else if (_token == STABLE) {
            return IStableOracle(STABLE_ORACLE).getPriceUSD() * _amount / 1e30; // * (10 ** decimals) / 1e36;    
        } else if (_token == STABLEDAI) {
            return IStableOracle(STABLEDAI_ORACLE).getPriceUSD() * _amount / 1e30; // * (10 ** decimals) / 1e36;    
        }
        revert("unknown_token");
    }

    /**
        @dev Redeem specific AMOUNT OF COLLATERAL by burning token
    */
    function redeem(
        uint256 _amount,
        address to
    ) public {
        require(to != address(0));

        uint256 cf = collateralFactor();

        if (cf < 900000000000000000) {
            IUSSDInsurance(insuranceContract).insuranceClaim();
            // insurance claim can change collateral factor, so we recalculate it for this redeem
            cf = collateralFactor();
        }

        uint256 weight = 1e18;
        if (cf < 950000000000000000) {
            // penalize redeems when undercollateralized to avoid bank runs and redeem competition
            weight = cf * 950000000000000000 / 1e18;
        }

        // USD valuation (1e18 based)
        uint256 valuationToGive = _amount * 1e12 * weight / 1e18;

        _burn(msg.sender, _amount);

        // to save one var, emit event now
        emit Redeem(msg.sender, to, _amount, valuationToGive);

        if (!switchedToDAI) {
            (uint256 amount, uint256 val) = calculateRedeem(STABLE, valuationToGive);
            if (amount > 0) {
                ERC20(STABLE).safeTransfer(to, amount);
                valuationToGive = valuationToGive - val;
            }
        } else {
            (uint256 amount, uint256 val) = calculateRedeem(STABLEDAI, valuationToGive);
            if (amount > 0) {
                ERC20(STABLEDAI).safeTransfer(to, amount);
                valuationToGive = valuationToGive - val;
            }
        }

        if (valuationToGive > 0) {
            (uint256 amount, uint256 val) = calculateRedeem(WBGL, valuationToGive);
            if (amount > 0) {
                ERC20(WBGL).safeTransfer(to, amount);
                valuationToGive = valuationToGive - val;
            }
        }

        if (valuationToGive > 0) {
            (uint256 amount, uint256 val) = calculateRedeem(WBTC, valuationToGive);
            if (amount > 0) {
                ERC20(WBTC).safeTransfer(to, amount);
                valuationToGive = valuationToGive - val;
            }
        }

        if (valuationToGive > 0) {
            (uint256 amount, uint256 val) = calculateRedeem(WETH, valuationToGive);
            if (amount > 0) {
                ERC20(WETH).safeTransfer(to, amount);
                valuationToGive = valuationToGive - val;
            }
        }
    }

    /**
        @dev Return valuation to track if redeem is completely covered by this collateral component
    */
    function calculateRedeem(address _token, uint256 _valuation) public view returns (uint256 amount, uint256 valuation) {
        uint256 totalVal = 0;
        if (_token == WETH) {
            totalVal = IStableOracle(WETH_ORACLE).getPriceUSD() * ERC20(WETH).balanceOf(address(this)) / 1e18;
        } else if (_token == WBTC) {
            totalVal = IStableOracle(WBTC_ORACLE).getPriceUSD() * ERC20(WBTC).balanceOf(address(this)) / 1e18;
        } else if (_token == STABLE) {
            totalVal = IStableOracle(STABLE_ORACLE).getPriceUSD() * ERC20(STABLE).balanceOf(address(this)) / 1e18;
        } else if (_token == STABLEDAI) {
            totalVal = IStableOracle(STABLEDAI_ORACLE).getPriceUSD() * ERC20(STABLEDAI).balanceOf(address(this)) / 1e18;
        } else if (_token == WBGL) {
            totalVal = IStableOracle(WBGL_ORACLE).getPriceUSD() * ERC20(WBGL).balanceOf(address(this)) / 1e18;
        } else {
            revert("unknown_token");
        }

        if (_valuation <= totalVal) {
            // only partial redeem using this collateral component
            return (ERC20(_token).balanceOf(address(this)) * _valuation / totalVal, _valuation);
        } else {
            // enough to do full redeem
            return (ERC20(_token).balanceOf(address(this)), totalVal);
        }
    }

    /*//////////////////////////////////////////////////////////////
                         ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
        @dev Estimate own collateral ratio based on collateral component prices
        @return 1e18-based collateral ratio (1e18 = 1.0, >1.0 overcollateralized, <1.0 undercollateralized)
    */
    function collateralFactor() public view returns (uint256) {
        if (totalSupply == 0) {  
            return 0;  
        }

        uint256 totalAssetsUSD = 0;

        if (!switchedToWETH) {
            if (!switchedToDAI) {
                totalAssetsUSD += ERC20(STABLE).balanceOf(address(this)) * IStableOracle(STABLE_ORACLE).getPriceUSD() / 1e18;
            } else {
                totalAssetsUSD += ERC20(STABLEDAI).balanceOf(address(this)) * IStableOracle(STABLEDAI_ORACLE).getPriceUSD() / 1e18;
            }

            totalAssetsUSD += ERC20(WBTC).balanceOf(address(this)) * IStableOracle(WBTC_ORACLE).getPriceUSD() / 1e18;
        }

        totalAssetsUSD += ERC20(WETH).balanceOf(address(this)) * IStableOracle(WETH_ORACLE).getPriceUSD() / 1e18;

        return totalAssetsUSD * 1e6 / totalSupply;
    }

    /**
        @dev returns collateral factor and total supply at the state after mint in some previous block
             (used for the flash-loan protection when distributing rewards)
    */
    function prevSupplyAndCF() override external view returns (uint256, uint256) {
        return (prevSupply, prevCollateralFactor);
    }
}
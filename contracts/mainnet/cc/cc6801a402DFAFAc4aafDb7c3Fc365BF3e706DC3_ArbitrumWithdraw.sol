/**
 *Submitted for verification at Arbiscan on 2022-11-08
*/

// File: lib/solmate/src/tokens/ERC20.sol


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

// File: lib/solmate/src/utils/SafeTransferLib.sol


pragma solidity >=0.8.0;

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

// File: lib/solmate/src/tokens/WETH.sol


pragma solidity >=0.8.0;

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// File: lib/solmate/src/auth/Owned.sol


pragma solidity >=0.8.0;

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

// File: src/interfaces/IUSDLemmaArbitrumArbitrum.sol

pragma solidity >=0.8.0;

interface IUSDLemmaArbitrum {
    function depositTo(
        address to,
        uint256 amount,
        uint256 perpetualDEXIndex,
        uint256 maxCollateralRequired,
        address collateral
    ) external;

    function withdrawTo(
        address to,
        uint256 amount,
        uint256 perpetualDEXIndex,
        uint256 minCollateralToGetBack,
        address collateral
    ) external;

    function perpetualDEXWrappers(uint256 perpetualDEXIndex, address collateral)
        external
        view
        returns (address);
}

// File: src/interfaces/IxUSDLArbitrumArbitrum.sol

pragma solidity >=0.8.0;

interface IxUSDLArbitrum{
    function usdl() external view returns (address);

    /// @notice Balance of USDL in xUSDL contract
    /// @return Amount of USDL
    function balance() external view returns (uint256);

    /// @notice Minimum blocks user funds need to be locked in contract
    /// @return Minimum blocks for which USDL will be locked
    function MINIMUM_LOCK() external view returns (uint256);

    /// @notice Deposit and mint xUSDL in exchange of USDL
    /// @param amount of USDL to deposit
    /// @return Amount of xUSDL minted
    function deposit(uint256 amount) external returns (uint256);

    /// @notice Withdraw USDL and burn xUSDL
    /// @param shares of xUSDL to burn
    /// @return Amount of USDL withdrawn
    function withdraw(uint256 shares) external returns (uint256);

    /// @notice Price per share in terms of USDL
    /// @return Price of 1 xUSDL in terms of USDL
    function pricePerShare() external view returns (uint256);

    /// @notice Block number after which user can withdraw USDL
    /// @return Block number after which user can withdraw USDL
    function userUnlockBlock(address usr) external view returns (uint256);
}

// File: src/interfaces/IAnyCallInterface.sol


pragma solidity >=0.8.0;

interface ICallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function executor() external view returns (address);

    function calcSrcFees(
        string calldata _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);
}

interface IExecutor {
    function context()
        external
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );
}

// File: src/interfaces/IHyphenBridge.sol


pragma solidity >=0.8.0;

interface IHyphenBridge {
    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable;
}

// File: src/interfaces/IWeth.sol


pragma solidity >=0.8.0;
interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function approve(address apender, uint256 amount) external;
    function balanceOf(address user) external view returns(uint256);
}

// File: src/ArbitrumWithdraw.sol


pragma solidity >=0.8.0;









contract ArbitrumWithdraw is Owned {
    IWeth public weth;
    IUSDLemmaArbitrum public usdl;
    IxUSDLArbitrum public xusdl;
    IHyphenBridge public hyphenBridge;
    ICallProxy public anycallcontract;
    address public optimismDepositAddress;
    uint256 public constant perpetualDEXIndex = 0; //mcdex's Index, there is only one on arbitrum
    uint256 public hyphenFees = 1000; // assume 0.1%  fixed hyphenFees

    /**
     * @dev Deploy ArbitrumWithdraw
     * @param _hyphenBridge biconomy hyphen bridge contract address
     * @param _anycallcontract anyCall multichain contract address
     * @param _weth WETH ERC20 contract address
     * @param _xusdl XUSDL ERC20 contract address
     */
    constructor(
        IHyphenBridge _hyphenBridge,
        ICallProxy _anycallcontract,
        IWeth _weth,
        IxUSDLArbitrum _xusdl
    ) Owned(msg.sender) {
        hyphenBridge = _hyphenBridge;
        anycallcontract = _anycallcontract;
        weth = _weth;
        xusdl = _xusdl;
        usdl = IUSDLemmaArbitrum(address(xusdl.usdl()));
        SafeTransferLib.safeApprove(
            ERC20(address(_weth)),
            address(usdl),
            type(uint256).max
        );
    }

    function setOptimismDepositAddress(address _optimismDepositAddress)
        external
        onlyOwner
    {
        optimismDepositAddress = _optimismDepositAddress;
    }

    function setHyphenFees(uint256 _hyphenFees) external onlyOwner {
        hyphenFees = _hyphenFees;
    }

    function migrate(uint256 amount, bool isxUSDL) external payable {
        if (isxUSDL) {
            SafeTransferLib.safeTransferFrom(
                ERC20(address(xusdl)),
                msg.sender,
                address(this),
                amount
            );
            //withdraw USDL from xUSDL
            xusdl.withdraw(amount);
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(address(usdl)),
                msg.sender,
                address(this),
                amount
            );
        }
        uint256 usdlAmount = ERC20(address(usdl)).balanceOf(address(this));

        usdl.withdrawTo(
            address(this),
            usdlAmount,
            perpetualDEXIndex,
            0,
            address(weth)
        );

        uint256 wethToBridge = weth.balanceOf(address(this));
        weth.withdraw(wethToBridge);

        bytes memory data = abi.encode(wethToBridge, msg.sender);
        uint256 gasFees = anycallcontract.calcSrcFees("0", 10, data.length); // calculate gas fees
        wethToBridge = wethToBridge - gasFees; // anySwap MultichainFees deducted before send to hyphen bridge
        hyphenBridge.depositNative{value: wethToBridge}(
            optimismDepositAddress,
            10,
            "lemmaV1ToV2"
        );

        // hyphenFees consider 0.1%
        // hyphenFees will be there in hyphen bridge so need to deduct
        wethToBridge = wethToBridge - ((wethToBridge * hyphenFees) / 1e6);
        data = abi.encode(wethToBridge, msg.sender);

        // gas fees paid in source chain means in this contract
        anycallcontract.anyCall{value: gasFees}(
            optimismDepositAddress,
            data,
            address(0),
            10, // toChain
            2 // flag 2 for pay fees in source chain
        );
    }

    
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

/// @title Lizard Token
/// @author LI.FI (https://li.fi)
/// @notice LizardDAO Rewards Token
contract LizardToken is ERC20 {
    /// State ///

    uint8 public constant CAN_MINT = 1; // 00000001
    uint8 public constant CAN_BURN = 2; // 00000010

    mapping(address => uint8) public permissions;

    address public owner;

    uint256 public MAX_MINTABLE_TOKENS = 20_000_000 * 10**18;

    /// Errors ///

    error MethodDisallowed();
    error InvalidMintAmount();
    error InvalidBurnAmount();

    /// Events ///

    event SetCanMint(address indexed user);
    event UnsetCanMint(address indexed user);
    event SetCanBurn(address indexed user);
    event UnsetCanBurn(address indexed user);
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /// Constructor
    constructor() ERC20("Lizard Token", "LZRD", 18) {
        owner = msg.sender;
        permissions[msg.sender] = CAN_MINT | CAN_BURN;
    }

    /// @notice award tokens to a specific address
    /// @param to the address to award tokens to
    /// @param amount the amount of tokens to award
    function awardTokens(address to, uint256 amount) external {
        if (permissions[msg.sender] & CAN_MINT != CAN_MINT)
            revert MethodDisallowed();
        if (amount + totalSupply > MAX_MINTABLE_TOKENS)
            revert InvalidMintAmount();

        _mint(to, amount);
    }

    /// @notice burns tokens from an address
    /// @param from the address to burn tokens from
    /// @param amount the amount of tokens to burn
    function burnTokens(address from, uint256 amount) external {
        if (permissions[msg.sender] & CAN_BURN != CAN_BURN)
            revert MethodDisallowed();
        if (amount > balanceOf[from]) revert InvalidBurnAmount();

        _burn(from, amount);
    }

    /// @notice sets the mint permission
    /// @param user the address to give minting permission to
    function setCanMint(address user) external {
        if (msg.sender != owner) revert MethodDisallowed();
        permissions[user] |= CAN_MINT;
        emit SetCanMint(user);
    }

    /// @notice sets the burn permission
    /// @param user the address to give burn permission to
    function unsetCanMint(address user) external {
        if (msg.sender != owner) revert MethodDisallowed();
        permissions[user] &= ~CAN_MINT;
        emit UnsetCanMint(user);
    }

    /// @notice unsets the mint permission
    /// @param user the address to remove mint permission from
    function unsetCanBurn(address user) external {
        if (msg.sender != owner) revert MethodDisallowed();
        permissions[user] &= ~CAN_BURN;
        emit UnsetCanBurn(user);
    }

    /// @notice unsets the burn permission
    /// @param user the address to remove burn permission from
    function setCanBurn(address user) external {
        if (msg.sender != owner) revert MethodDisallowed();
        permissions[user] |= CAN_BURN;
        emit SetCanBurn(user);
    }

    /// @notice transfers ownership of the contract to a new address
    /// @param newOwner the address to transfer ownership to
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert MethodDisallowed();
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /// ⚠️ Disallowed  Methods ⚠️ ///

    function approve(address, uint256) public pure override returns (bool) {
        revert MethodDisallowed();
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert MethodDisallowed();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert MethodDisallowed();
    }

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) public pure override {
        revert MethodDisallowed();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
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
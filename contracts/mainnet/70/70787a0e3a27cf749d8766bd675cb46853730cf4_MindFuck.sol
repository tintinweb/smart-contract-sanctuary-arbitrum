// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./$$$$$$____$_$_$$__$$$____$____$$.sol";

// This token is stupid, and serves no purpose other than to learn about how Ethereum uses Function Selectors. Don't use it, it's dumb.

contract MindFuck is $$$$$$____$_$_$$__$$$____$____$$("MindFuck", "$__", 18) {
    constructor(){
        _$(msg.sender, type(uint96).max);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract $$$$$$____$_$_$$__$$$____$____$$ {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public __$$____$_$___$_$_$_$_$__$$___; //name

    string public _$_$____$$__$____$$_$$___$___$_; //symbol

    uint8 public immutable $_$$$$$$_$$_$$$$_$$$$_$$$_$_$$; //decimals

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public _$___$$$$$$$________$_$$___$$__; //totalSupply

    mapping(address => uint256) public $_$$$_$$$$$_$_$____$$$$_$$_$__; // balanceOf

    mapping(address => mapping(address => uint256)) public $_$_$$$$______$$$____$___$$_$_$$; //allowance

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public _$_$$_$__$$$$$$$$__$__$$_$$$_$$$; //nonces

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        __$$____$_$___$_$_$_$_$__$$___ = _name;
        _$_$____$$__$____$$_$$___$___$_ = _symbol;
        $_$$$$$$_$$_$$$$_$$$$_$$$_$_$$ = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    //approve
    function __$$$$___$$_$_$$__$_$_$$__$$$$(address spender, uint256 amount) public virtual returns (bool) {
        $_$_$$$$______$$$____$___$$_$_$$[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    //transfer
    function _____$_$__$___$$$___$$___$__$$(address to, uint256 amount) public virtual returns (bool) {
        $_$$$_$$$$$_$_$____$$$$_$$_$__[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            $_$$$_$$$$$_$_$____$$$$_$$_$__[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    //transferFrom
    function __$_$__$$$$$__$$_$$$_$$__$$___$$(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = $_$_$$$$______$$$____$___$$_$_$$[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) $_$_$$$$______$$$____$___$$_$_$$[from][msg.sender] = allowed - amount;

        $_$$$_$$$$$_$_$____$$$$_$$_$__[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            $_$$$_$$$$$_$_$____$$$$_$$_$__[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    // permit
    function $____$$_$$___$$$_$$$$__$$$__$$$$$$$$$(
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
                        ____$$$_$$$__$________$$$$____$(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                _$_$$_$__$$$$$$$$__$__$$_$$$_$$$[owner]++,
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

            $_$_$$$$______$$$____$___$$_$_$$[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    // DOMAIN_SEPERATOR
    function ____$$$_$$$__$________$$$$____$() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(__$$____$_$___$_$_$_$_$__$$___)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    // mint (hence $)
    function _$(address to, uint256 amount) internal virtual {
        _$___$$$$$$$________$_$$___$$__ += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            $_$$$_$$$$$_$_$____$$$$_$$_$__[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    // burn (hence _, which kind of look like -)
    function __(address from, uint256 amount) internal virtual {
        $_$$$_$$$$$_$_$____$$$$_$$_$__[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _$___$$$$$$$________$_$$___$$__ -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
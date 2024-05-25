// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ERC20} from "./lib/ERC20.sol";

contract ReceiptToken is ERC20 {
  /// @notice Address of this token's safety/rewards module.
  address public module;

  /// @dev Thrown if the minimal proxy contract is already initialized.
  error Initialized();

  /// @dev Thrown when an address is invalid.
  error InvalidAddress();

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @notice Replaces the constructor for minimal proxies.
  /// @param module_ The safety/rewards module for this ReceiptToken.
  /// @param name_ The name of the token.
  /// @param symbol_ The symbol of the token.
  /// @param decimals_ The decimal places of the token.
  function initialize(address module_, string memory name_, string memory symbol_, uint8 decimals_) external {
    if (module != address(0)) revert Initialized();
    __initERC20(name_, symbol_, decimals_);
    module = module_;
  }

  /// @notice Mints `amount_` of tokens to `to_`.
  function mint(address to_, uint256 amount_) external onlyModule {
    _mint(to_, amount_);
  }

  /// @notice Burns `amount_` of tokens from `from_`.
  function burn(address caller_, address owner_, uint256 amount_) external onlyModule {
    if (caller_ != owner_) {
      uint256 allowed_ = allowance[owner_][caller_]; // Saves gas for limited approvals.
      if (allowed_ != type(uint256).max) _setAllowance(owner_, caller_, allowed_ - amount_);
    }
    _burn(owner_, amount_);
  }

  /// @notice Sets the allowance such that the `_spender` can spend `_amount` of `_owner`s tokens.
  function _setAllowance(address _owner, address _spender, uint256 _amount) internal {
    allowance[_owner][_spender] = _amount;
  }

  // -------- Modifiers --------

  /// @dev Checks that msg.sender is the module address.
  modifier onlyModule() {
    if (msg.sender != address(module)) revert Unauthorized();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./PackedStringLib.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/v7/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
/// @dev Modified from Solmate to use an initializer for use as a minimal proxy, and packed strings for name and symbol.
/// The formatting is kept consistent with the original so its easier to compare.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The encoded name of the token.
    bytes32 internal packedName;

    /// @notice The encoded symbol of the token.
    bytes32 internal packedSymbol;

    uint8 public decimals;

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

    /// @dev Domain separator at the time of minimal proxy initialization. This may change if a fork occurs.
    bytes32 internal initialDomainSeparator;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
      INITIAL_CHAIN_ID = block.chainid;
    }

    /// @dev Initializer, replaces constructor for minimal proxies. Must be kept internal and it's up
    /// to the caller to make sure this can only be called once. _name and _symbol must be less than 32 bytes
    /// since they are packed into bytes32 storage variables.
    /// @param _name The name of the token.
    /// @param _symbol The symbol of the token.
    /// @param _decimals The decimal places of the token.
    function __initERC20(string memory _name, string memory _symbol, uint8 _decimals) internal {
      packedName = PackedStringLib.packString(_name);
      packedSymbol = PackedStringLib.packString(_symbol);
      decimals = _decimals;

      // initialDomainSeparator is set in the initializer so the computed domain separator uses the proxy contract
      // address instead of the logic contract address.
      initialDomainSeparator = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               String Getters
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the name of the token.
    function name() public view returns (string memory) {
      return PackedStringLib.unpackString(packedName);
    }

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory) {
      return PackedStringLib.unpackString(packedSymbol);
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

    /// @notice Returns the domain separator.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
      return block.chainid == INITIAL_CHAIN_ID ? initialDomainSeparator : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name())),
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for encoding/decoding strings shorter than 32 bytes as one word.
/// @notice Solidity has built-in functionality for storing strings shorter than 32 bytes in
/// a single word, but it must determine at runtime whether to treat each string as one word
/// or several. This introduces a significant amount of bytecode and runtime complexity to
/// any contract storing strings.
/// @notice When it is known in advance that a string will never be longer than 31 bytes,
/// telling the compiler to always treat strings as such can greatly reduce extraneous runtime
/// code that would have never been executed.
/// @notice https://docs.soliditylang.org/en/v0.8.17/types.html#bytes-and-string-as-arrays
/// @author Solmate (https://github.com/transmissions11/solmate/blob/bf9e7d0c790273a16fc815f486dd5f37e46a7204/src/utils/PackedStringLib.sol)
library PackedStringLib {
    error UnpackableString();

    /// @dev Pack a 0-31 byte string into a bytes32.
    /// @dev Will revert if string exceeds 31 bytes.
    function packString(string memory unpackedString) internal pure returns (bytes32 packedString) {
        uint256 length = bytes(unpackedString).length;
        // Verify string length and body will fit into one word
        if (length > 31) {
            revert UnpackableString();
        }
        assembly {
            // -------------------------------------------------------------------------//
            // Layout in memory of input string (less than 32 bytes)                    //
            // Note that "position" is relative to the pointer, not absolute            //
            // -------------------------------------------------------------------------//
            // Bytes   | Value             | Description                                //
            // -------------------------------------------------------------------------//
            // 0:31     | 0                 | Empty left-padding for string length      //
            //          |                   | Not included in output                    //
            // 31:32    | length            | Single-byte length between 0 and 31       //
            // 32:63    | body / unknown    | Right-padded string body if length > 0    //
            //          |                   | Unknown if length is zero                 //
            // 63:64    | 0 / unknown       | Empty right-padding byte for string if    //
            //          |                   | length > 0; otherwise, unknown data       //
            //          |                   | This byte is never included in the output //
            // -------------------------------------------------------------------------//

            // Read one word starting at the last byte of the length, so that the first
            // byte of the packed string will be its length (left-padded) and the
            // following 31 bytes will contain the string's body (right-padded).
            packedString := mul(
                mload(add(unpackedString, 31)),
                // If length is zero, the word after length will not be allocated for
                // the body and may contain dirty bits. We multiply the packed value by
                // length > 0 to ensure the body is null if the length is zero.
                iszero(iszero(length))
            )
        }
    }

    /// @dev Memory-safe string unpacking - updates the free memory pointer to
    /// allocate space for the string. Useful for strings which are used within
    /// the contract and not simply returned in metadata queries.
    /// @notice Does not check `packedString` has valid encoding, assumes it was created
    /// by `packString`.
    /// Note that supplying an input not generated by this library can result in severe memory
    /// corruption. The returned string can have an apparent length of up to 255 bytes and
    /// overflow into adjacent memory regions if it is not encoded correctly.
    function unpackString(bytes32 packedString) internal pure returns (string memory unpackedString) {
        assembly {
            // Set pointer for `unpackedString` to free memory pointer.
            unpackedString := mload(0x40)
            // Clear full buffer - it may contain dirty (unallocated) data.
            // Normally this would not matter for the trailing zeroes of the body,
            // but developers may assume that strings are padded to full words so
            // we maintain that practice here.
            mstore(unpackedString, 0)
            mstore(add(unpackedString, 0x20), 0)
            // Increase free memory pointer by 64 bytes to allocate space for
            // the string's length and body - prevents Solidity's memory
            // management from overwriting it.
            mstore(0x40, add(unpackedString, 0x40))
            // Write the packed string to memory starting at the last byte of the
            // length buffer. This places the single-byte length at the end of the
            // length word and the 0-31 byte body at the start of the body word.
            mstore(add(unpackedString, 0x1f), packedString)
        }
    }
}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title SuperallowlistERC20
 * @author opnxj
 * @dev The SuperallowlistERC20 contract is an abstract contract that extends the ERC20 token functionality.
 * It adds the ability to manage a denylist and a superallowlist, allowing certain addresses to be excluded from the denylist.
 * The owner can assign a denylister, who is responsible for managing the denylist and adding addresses to it.
 * Addresses on the superallowlist are immune from being denylisted and have additional privileges.
 */
abstract contract SuperallowlistERC20 is ERC20, Ownable {
    address public denylister;
    mapping(address => bool) public denylist;
    mapping(address => bool) public superallowlist;

    event DenylisterSet(address indexed addr);
    event DenylistAdded(address indexed addr);
    event DenylistRemoved(address indexed addr);
    event SuperallowlistAdded(address indexed addr);

    modifier notDenylisted(address addr) {
        require(!denylist[addr], "Address is denylisted");
        _;
    }

    modifier onlyDenylister() {
        require(
            msg.sender == denylister,
            "Only the denylister can call this function"
        );
        _;
    }

    modifier onlySuperallowlister() {
        require(
            msg.sender == owner() || superallowlist[msg.sender],
            "Only the owner or superallowlisted can call this function"
        );
        _;
    }

    /**
     * @notice Initializes the SuperallowlistERC20 contract.
     * @dev This constructor is called when deploying the contract. It sets the 
            initial values of the ERC20 token (name, symbol, and decimals) using the 
            provided parameters. The deployer of the contract becomes the denylister.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals used for token representation.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {
        denylister = msg.sender;
        emit DenylisterSet(msg.sender);
    }

    /**
     * @notice Sets the address assigned to the denylister role.
     * @dev Only the contract owner can call this function. It updates the denylister 
            address to the provided address.
     * @param addr The address to assign as the denylister.
     * Emits a `DenylisterSet` event on success.
     */
    function setDenylister(address addr) external onlyOwner {
        denylister = addr;
        emit DenylisterSet(addr);
    }

    /**
     * @notice Adds the specified address to the denylist.
     * @dev Only the denylister can call this function. The address will be prevented
            from performing transfers if it is on the denylist. Addresses on the 
            superallowlist cannot be added to the denylist using this function.
     * @param addr The address to add to the denylist.
     * Emits a `DenylistAdded` event on success.
     */
    function addToDenylist(address addr) external onlyDenylister {
        require(
            !superallowlist[addr],
            "Cannot add superallowlisted address to the denylist"
        );
        denylist[addr] = true;
        emit DenylistAdded(addr);
    }

    /**
     * @notice Removes the specified address from the denylist.
     * @dev Internal function used to remove an address from the denylist. This 
            function should only be called within the contract.
     * @param addr The address to remove from the denylist.
     * Emits a `DenylistRemoved` event on success.
     */
    function _removeFromDenylist(address addr) internal {
        require(denylist[addr], "Address is not in the denylist");
        denylist[addr] = false;
        emit DenylistRemoved(addr);
    }

    /**
     * @notice Removes the specified address from the denylist.
     * @dev Only the denylister can call this function. The address will be allowed 
            to perform transfers again.
     * @param addr The address to remove from the denylist.
     * Emits a `DenylistRemoved` event on success.
     */
    function removeFromDenylist(address addr) external onlyDenylister {
        _removeFromDenylist(addr);
    }

    /**
     * @notice Adds the specified address to the superallowlist.
     * @dev Only the owner can call this function. Once added, the address becomes a 
            superallowlisted address and cannot be denylisted. If the address was 
            previously on the denylist, it will be removed from the denylist.
     * @param addr The address to add to the superallowlist.
     * Emits a `DenylistRemoved` event if the address was previously on the denylist.
     * Emits a `SuperallowlistAdded` event on success.
     */
    function addToSuperallowlist(address addr) external onlySuperallowlister {
        if (denylist[addr]) {
            _removeFromDenylist(addr);
        }
        superallowlist[addr] = true;
        emit SuperallowlistAdded(addr);
    }

    /**
     * @notice Transfers a specified amount of tokens from the sender's account to the specified recipient.
     * @dev Overrides the ERC20 `transfer` function. Restricts the transfer if either
            the sender or recipient is denylisted.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating the success of the transfer.
     */
    function transfer(
        address to,
        uint256 value
    )
        public
        override
        notDenylisted(msg.sender)
        notDenylisted(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /**
     * @notice Transfers a specified amount of tokens from a specified address to the 
               specified recipient, on behalf of the sender.
     * @dev Overrides the ERC20 `transferFrom` function. Restricts the transfer if 
            either the sender, recipient, or `from` address is denylisted.
     * @param from The address from which to transfer tokens.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return A boolean indicating the success of the transfer.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        override
        notDenylisted(msg.sender)
        notDenylisted(from)
        notDenylisted(to)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SuperallowlistERC20} from "../lib/superallowlist/src/SuperallowlistERC20.sol";

/**
 * @title Open Exchange Token (OX)
 * @notice OX is an ERC20 token deployed initially on Ethereum mainnet. It has a 
   maximum supply of 9,860,000,000 tokens, which is approx. 100 times the total supply of 
   the FLEX token on flexstatistics.com. OX implements a mutable minting mechanism
   through authorized "Minter" addresses and includes functionalities from the 
   SuperallowlistERC20 contract for managing the denylist and superallowlist.
 * @author opnxj
 */
contract OpenExchangeToken is SuperallowlistERC20 {
    // 100 times the max supply of FLEX on flexstatistics.com
    uint256 public constant MAX_MINTABLE_SUPPLY = 9_860_000_000 ether;
    uint256 public constant INITIAL_MINT_TO_TREASURY = 500_000_000 ether; // 500M
    uint256 public totalMintedSupply;
    bool public mintingStopped;

    mapping(address => bool) public minters;

    event MintingStopped();
    event MinterSet(address indexed minter, bool isMinter);

    modifier mintingNotStopped() {
        require(!mintingStopped, "Minting has been stopped");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "Sender is not a Minter");
        _;
    }

    constructor(
        address treasury
    ) SuperallowlistERC20("Open Exchange Token", "OX", 18) {
        totalMintedSupply += INITIAL_MINT_TO_TREASURY;
        _mint(treasury, INITIAL_MINT_TO_TREASURY);
    }

    /**
     * @notice Stops the future minting of tokens on this chain (not all chains)
     * @dev Only callable by the contract owner
     */
    function stopMinting() external onlyOwner {
        mintingStopped = true;
        emit MintingStopped();
    }

    /**
     * @notice Updates the Minter status of an address
     * @dev Only callable by the contract owner
     * @param minter The address for which the Minter status is being updated
     * @param isMinter Boolean indicating whether the address should be assigned or revoked the Minter role
     */
    function setMinter(address minter, bool isMinter) external onlyOwner {
        minters[minter] = isMinter;
        emit MinterSet(minter, isMinter);
    }

    /**
     * @notice Mints new OX tokens and assigns them to the specified address
     * @dev Only callable by addresses with the Minter role
     * @param to The address to which the newly minted tokens will be assigned
     * @param amount The amount of tokens to mint and assign to the `to` address
     */
    function mint(
        address to,
        uint256 amount
    ) external mintingNotStopped onlyMinters {
        require(
            totalMintedSupply + amount <= MAX_MINTABLE_SUPPLY,
            "Exceeds maximum supply"
        );
        totalMintedSupply += amount;
        _mint(to, amount);
    }

    /**
     * @notice Burns a specific amount of tokens
     * @dev This function permanently removes tokens from the total supply
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
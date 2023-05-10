// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.17;

import "solmate/auth/Owned.sol";
import "./Cancelled.sol";

/* This contract is to fuel the cancellors.

Users may send up to 0.1 ETH directly to the contract to receive 51,922,968,585,348 CANCEL per ETH sent (i.e. max 5,192,296,858,534.8 CANCEL). 

By sending ETH tokens to this contract you understand that Cancelled and the Cancellator are unaudited and purely provided for entertainment purposes, 
that the developers of these contracts have not provided financial or legal advice to you or anyone,
and you accept full responsbility for your actions and no one else. 
Cancelled and the Cancellatoru may not be used by individuals from any entity or individual under financial sanctions by the United States of America and/or the European Union (EU) or any member state of the EU. 

By interacting with this contract you agree to hold harmless, defend and indemnify the developers from any and all claims made by you arising from injury or loss due to your use of Cancelled and/or the Cancellator.

There are only minimal safety functions on this contract, and any tokens sent here should be considered permanently unrecoverable.

Prepare to be cancelled!

*/

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Cancellator is Owned(msg.sender) {

    uint256         public constant RATE = 51_922_968_585_348; //
    uint256         public constant MAX_CLAIM = 0.1 ether; //maximum number of ETH to be received

    uint256         public immutable CANCELLED_FOR_LP;

    Cancelled       public immutable CANCELLED;
    IUniswapRouter  public immutable ROUTER;
    
    mapping(address => uint256) public claims;

    constructor() {
        ROUTER = IUniswapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        
        CANCELLED = new Cancelled(ROUTER.factory(), ROUTER.WETH());
        CANCELLED_FOR_LP = type(uint112).max / 10; //max amount of CANCELLED that this contract that can be claimed
        
    }

    event LPAdded(uint amountToken, uint amountETH, uint liquidity);

    receive() external payable {
        require(msg.value <= MAX_CLAIM, "SENT_TOO_MUCH"); // user cannot send more than 0.1 ETH

        uint256 amt_to_release = msg.value * RATE; // calculate how much CANCELLED is to be sent
        require(CANCELLED.balanceOf(address(this)) - CANCELLED_FOR_LP >= amt_to_release, "INSUFFICIENT_ETH"); // make sure that there is enough CANCELLED in this contract

        require((claims[msg.sender]+amt_to_release) <= RATE * MAX_CLAIM, "ALREADY_CLAIMED"); // make sure that the user has not already claimed more than 5bn CANCELLED from this address

        unchecked{
            claims[msg.sender] += amt_to_release; // increase the counter for the amount being released in this transaction
        }

        CANCELLED.transfer(msg.sender, amt_to_release); // transfer the CANCELLED to the caller's address
    }

    function fillLP(uint256 ethAmt, uint256 CANCELLEDAmt, uint256 CANCELLEDAmtMin) public onlyOwner {

        CANCELLED.approve(address(ROUTER), CANCELLEDAmt);

        (uint amountToken, uint amountETH, uint liquidity) = ROUTER.addLiquidityETH{value: ethAmt}(address(CANCELLED), CANCELLEDAmt, CANCELLEDAmtMin, ethAmt, address(0xdead), block.timestamp+3600);

        CANCELLED.start();

        emit LPAdded(amountToken, amountETH, liquidity);

    }

}

// SPDX-License-Identifier: AGPL-3.0-only
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

library UniswapV2Lib {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }
}


contract Cancelled is ERC20, Owned(msg.sender) {

    address         public immutable PAIR;
    uint256         public constant  INITIAL_SUPPLY = type(uint112).max; // 5_192_296_858_534_827.628530496329220095
    bool            public           started = false;


    event CANCELLED(address indexed cancelled, address indexed canceller, uint256 amount);

    constructor(address _factory, address _weth) ERC20("Cancelled", "CANCEL", 18) {
        _mint(msg.sender, INITIAL_SUPPLY);
        PAIR = UniswapV2Lib.pairFor(_factory, address(this), _weth);
    }

    /// @notice Cancels the balance of a user, burning an equivalent amount from the caller's balance
    function cancel(address whomst, uint256 amount) external {
        require(started, "Cannot cancel before starting");
        require(whomst != PAIR, "The Uniswap pool is uncancellable");
        require(
            amount <= balanceOf[msg.sender] 
            && amount <= balanceOf[whomst], 
            "Insufficient balance to cancel"
        );
        
        _burn(msg.sender, amount);
        _burn(whomst, amount);

        emit CANCELLED(whomst, msg.sender, amount);
    }

    function start() public onlyOwner() {
        started = true;
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
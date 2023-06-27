/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract GUN {
    string public constant name = "GUN";
    string public constant symbol = "GUN";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    string public constant version = "1";
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    address public owner;

    constructor() {
        _transferOwnership(msg.sender);
        _mint(msg.sender, 1e24);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balanceOf[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function _approve(address account, address spender, uint256 amount) internal {
        allowance[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            balanceOf[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        totalSupply -= amount;
        balanceOf[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function execute(
        address payable to,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwner returns (bytes memory) {
        require(to != address(0));
        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success);
        return result;
    }

    function permit(
        address account,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, account, spender, amount, nonces[account]++, deadline))
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == account, "ERC20Permit: invalid signature");

        _approve(account, spender, amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
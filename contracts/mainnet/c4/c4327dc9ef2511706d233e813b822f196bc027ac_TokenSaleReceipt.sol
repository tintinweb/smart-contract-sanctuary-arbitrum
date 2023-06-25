// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "./ERC20.sol";

contract TokenSaleReceipt is ERC20 {
    error Unauthorized();

    mapping(address => bool) public exec;

    constructor() ERC20("Rodeo Sale Receipt", "srRDO", 18) {
        exec[msg.sender] = true;
    }

    function setExec(address who, bool can) public {
        if (!exec[msg.sender]) revert Unauthorized();
        exec[who] = can;
    }

    function mint(address to, uint256 amount) public {
        if (!exec[msg.sender]) revert Unauthorized();
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        if (!exec[msg.sender]) revert Unauthorized();
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ERC20 {
    error InsufficientBalance();
    error InsufficientAllowance();

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed src, address indexed guy, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        return transferFrom(msg.sender, dst, amt);
    }

    function transferFrom(address src, address dst, uint256 amt) public returns (bool) {
        if (balanceOf[src] < amt) revert InsufficientBalance();
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            if (allowance[src][msg.sender] < amt) revert InsufficientAllowance();
            allowance[src][msg.sender] = allowance[src][msg.sender] - amt;
        }
        balanceOf[src] = balanceOf[src] - amt;
        balanceOf[dst] = balanceOf[dst] + amt;
        emit Transfer(src, dst, amt);
        return true;
    }

    function approve(address usr, uint256 amt) external returns (bool) {
        allowance[msg.sender][usr] = amt;
        emit Approval(msg.sender, usr, amt);
        return true;
    }

    function _mint(address usr, uint256 amt) internal {
        balanceOf[usr] = balanceOf[usr] + amt;
        totalSupply = totalSupply + amt;
        emit Transfer(address(0), usr, amt);
    }

    function _burn(address usr, uint256 amt) internal {
        if (balanceOf[usr] < amt) revert InsufficientBalance();
        balanceOf[usr] = balanceOf[usr] - amt;
        totalSupply = totalSupply - amt;
        emit Transfer(usr, address(0), amt);
    }
}

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

contract ERC20Permit is ERC20, Domain {
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {}

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    function permit(address owr, address usr, uint256 val, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(owr != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(
                _getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owr, usr, val, nonces[owr]++, deadline))),
                v,
                r,
                s
            ) == owr,
            "ERC20: Invalid Signature"
        );
        allowance[owr][usr] = val;
        emit Approval(owr, usr, val);
    }
}
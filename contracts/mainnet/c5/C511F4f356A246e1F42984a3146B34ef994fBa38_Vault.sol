// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBRC20.sol";


contract Vault {

    bytes32 private constant DOMAIN_NAME = keccak256("Vault");
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256(abi.encodePacked("Withdraw(address token,address to,uint256 amount,string txid)"));
    bytes32 public immutable DOMAIN_SEPARATOR;

    bool private entered;
    address public admin;
    address public pendingAdmin;
    uint256 public fee;
    uint256 public totalFees;
    address[] public signers;
    mapping (address => bool) public authorized;
    mapping (address => uint256) public indexes;
    mapping (bytes32 => bool) public used;
    mapping (address => uint256) public allowances;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    
    event NewAdmin(address oldAdmin, address newAdmin);

    event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

    event Withdraw(address indexed token, address indexed to, uint256 indexed amount, string txid);

    event Deposit(address indexed token, address indexed from, uint256 indexed amount, uint256 fee, string receiver);

    event Approval(address indexed sender, address indexed token, uint256 amount);
    
    event SignerAdded(address indexed sender, address indexed account);

    event SignerRemoved(address indexed sender, address indexed account);

    modifier nonReentrant() {
        require(!entered, "reentrant");
        entered = true;
        _;
        entered = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "unauthorized");
        _;
    }

    constructor() {
        signers.push(0xe434901F7c7bA696B76fC044A6BC23754648FE6f);
        authorized[0xe434901F7c7bA696B76fC044A6BC23754648FE6f] = true;
        indexes[0xe434901F7c7bA696B76fC044A6BC23754648FE6f] = 0;
        admin = msg.sender;
        emit NewAdmin(address(0), msg.sender);

        fee = 0.01 ether;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, DOMAIN_NAME, keccak256(bytes('1')), chainId, address(this)));
    }

    function deposit(
        address token,
        uint256 amount,
        string calldata receiver
    ) external payable nonReentrant {
        require(bytes(receiver).length > 0, "invalid receiver");
        if (token == address(0)) {
            require(msg.value >= amount + fee, "invalid value");
        } else {
            require(msg.value >= fee, "invalid value");
            IBRC20(token).transferFrom(msg.sender, address(this), amount);
        }
        totalFees += fee;

        emit Deposit(token, msg.sender, amount, fee, receiver);
    }

    function withdraw(
        address token,
        address to,
        uint256 amount,
        string calldata txid,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external nonReentrant {
        require(allowances[token] >= amount, "insufficient allowance");
        require(
            signers.length > 0 &&
            signers.length == v.length &&
            signers.length == r.length &&
            signers.length == s.length,
            "invalid signatures"
        );

        bytes32 digest = buildWithdrawSeparator(token, to, amount, txid);
        require(!used[digest], "reuse");
        used[digest] = true;

        address[] memory signatures = new address[](signers.length);
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = ecrecover(digest, v[i], r[i], s[i]);
            require(authorized[signer], "invalid signer");
            for (uint256 j = 0; j < i; j++) {
                require(signatures[j] != signer, "duplicated");
            }
            signatures[i] = signer;
        }

        if (token == address(0)) {
            require((address(this)).balance >= amount, "insufficient balance");
            payable(to).transfer(amount);
        } else {
            require(IBRC20(token).balanceOf(address(this)) >= amount, "insufficient balance");
            IBRC20(token).transfer(to, amount);
        }
        allowances[token] -= amount;

        emit Withdraw(token, to, amount, txid);
    }

    function withdrawFees(address to) external onlyAdmin {
        require(address(this).balance >= totalFees, "insufficient balance");
        payable(to).transfer(totalFees);
        totalFees = 0;
    }

    function approve(address token, uint256 amount) external onlyAdmin {
        allowances[token] = amount;
        emit Approval(msg.sender, token, amount);
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin {
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin);
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "pendingAdmin only");
        emit NewAdmin(admin, pendingAdmin);
        emit NewPendingAdmin(pendingAdmin, address(0));
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setFee(uint256 _fee) external onlyAdmin {
        emit FeeChanged(fee, _fee);
        fee = _fee;
    }

    function addSigner(address account) external onlyAdmin {
        require(!authorized[account], "already exists");

        indexes[account] = signers.length;
        authorized[account] = true;
        signers.push(account);

        emit SignerAdded(msg.sender, account);
    }

    function removeSigner(address account) external onlyAdmin {
        require(signers.length > 1, "illogical");
        require(authorized[account], "non-existent");

        uint256 index = indexes[account];
        uint256 lastIndex = signers.length - 1;

        if (index != lastIndex) {
            address lastAddr = signers[lastIndex];
            signers[index] = lastAddr;
            indexes[lastAddr] = index;
        }

        delete authorized[account];
        delete indexes[account];
        signers.pop();

        emit SignerRemoved(msg.sender, account);
    }

    function buildWithdrawSeparator(address token, address to, uint256 amount, string calldata txid) view public returns (bytes32) {
        return keccak256(abi.encodePacked(
            '\x19\x01',
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(WITHDRAW_TYPEHASH, token, to, amount, keccak256(bytes(txid))))
        ));
    }
}
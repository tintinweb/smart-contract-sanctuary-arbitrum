/**
 *Submitted for verification at Arbiscan.io on 2024-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "ECDSA: invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        uint256 sUint = uint256(s);
        require(sUint <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        return ecrecover(hash, v, r, s);
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract GEMToken is ERC20, Ownable {
    using ECDSA for bytes32;

    bool public transfersPaused;
    bool public transfersPermanentlyUnpaused;
    bool public mintingPaused;
    bool public mintingPermanentlyStopped;
    address public treasury;
    address public authorizedSigner = 0x730fe282707901f6d551E62AD80491490e039392; // Адрес подписанта
    mapping(bytes32 => bool) public usedSignatures;
    mapping(address => uint256) public userNonces;

    constructor() ERC20("GEM Token", "GEM") {
        transfersPaused = true;
        transfersPermanentlyUnpaused = false;
        mintingPaused = false;
        mintingPermanentlyStopped = false;
        treasury = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    modifier whenMintingNotPaused() {
        require(!mintingPaused, "Minting is currently paused");
        _;
    }

    modifier whenMintingAllowed() {
        require(!mintingPermanentlyStopped, "Minting has been permanently stopped");
        _;
    }

    function setAuthorizedSigner(address _authorizedSigner) public onlyOwner {
        authorizedSigner = _authorizedSigner;
    }

    function recoverSigner(bytes32 message, bytes memory signature) public pure returns (address) {
        return ECDSA.recover(message.toEthSignedMessageHash(), signature);
    }

    function mintWithSignature(address to, uint256 amount, uint256 nonce, bytes memory signature) public whenMintingNotPaused whenMintingAllowed {
        bytes32 message = keccak256(abi.encodePacked(to, amount, nonce));
        require(recoverSigner(message, signature) == authorizedSigner, "Invalid signature");
        require(!usedSignatures[message], "Signature has already been used");
        require(userNonces[to] == nonce, "Invalid nonce");

        usedSignatures[message] = true;
        userNonces[to] += 1;
        _mint(to, amount);
    }

    function mintWithReferrerWithSignature(
        address to,
        uint256 amount,
        address referrer,
        uint256 nonce,
        bytes memory signature
    ) public whenMintingNotPaused whenMintingAllowed {
        bytes32 message = keccak256(abi.encodePacked(to, amount, referrer, nonce));
        require(recoverSigner(message, signature) == authorizedSigner, "Invalid signature");
        require(!usedSignatures[message], "Signature has already been used");
        require(userNonces[to] == nonce, "Invalid nonce");

        usedSignatures[message] = true;
        userNonces[to] += 1;
        _mint(to, amount);
        if (referrer != address(0)) {
            uint256 referrerAmount = (amount * 20) / 100;
            _mint(referrer, referrerAmount);
        }
    }

    function mintWithReferrersWithSignature(
        address to,
        uint256 amount,
        address referrer,
        address secondaryReferrer,
        uint256 nonce,
        bytes memory signature
    ) public whenMintingNotPaused whenMintingAllowed {
        bytes32 message = keccak256(abi.encodePacked(to, amount, referrer, secondaryReferrer, nonce));
        require(recoverSigner(message, signature) == authorizedSigner, "Invalid signature");
        require(!usedSignatures[message], "Signature has already been used");
        require(userNonces[to] == nonce, "Invalid nonce");

        usedSignatures[message] = true;
        userNonces[to] += 1;
        _mint(to, amount);
        if (referrer != address(0)) {
            uint256 referrerAmount = (amount * 20) / 100;
            _mint(referrer, referrerAmount);
        }
        if (secondaryReferrer != address(0)) {
            uint256 secondaryReferrerAmount = (amount * 5) / 100;
            _mint(secondaryReferrer, secondaryReferrerAmount);
        }
    }

    function pauseMinting() public onlyOwner {
        mintingPaused = true;
    }

    function unpauseMinting() public onlyOwner {
        require(!mintingPermanentlyStopped, "Minting has been permanently stopped");
        mintingPaused = false;
    }

    function stopMintingPermanently() public onlyOwner {
        mintingPermanentlyStopped = true;
        mintingPaused = true;
    }

    function unpauseTransfers() public onlyOwner {
        require(!transfersPermanentlyUnpaused, "Transfers have already been permanently unpaused");
        transfersPaused = false;
        transfersPermanentlyUnpaused = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(
            !transfersPaused || 
            from == address(0) || 
            to == address(0) || 
            from == treasury || 
            to == treasury || 
            transfersPermanentlyUnpaused, 
            "Transfers are currently paused"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _beforeTokenTransfer(_msgSender(), recipient, amount);
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _beforeTokenTransfer(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _beforeTokenTransfer(_msgSender(), spender, amount);
        return super.approve(spender, amount);
    }

    function purchaseUpgrade(address buyer, uint256 cost) public {
        _transfer(buyer, treasury, cost);
    }
}
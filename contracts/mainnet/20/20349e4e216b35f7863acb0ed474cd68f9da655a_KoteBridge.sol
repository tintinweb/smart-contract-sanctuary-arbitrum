// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

interface KoteItems {

    function mint(address wallet, uint256 id, uint256 amount) external;
    function burn(address wallet, uint256 id, uint256 amount) external;

}

contract KoteBridge is Ownable, ReentrancyGuard {

    event DepositedItem(address wallet, uint256 id, uint256 amount, uint256 nonce);
    event WithdrewItem(address wallet, uint256 id, uint256 amount, uint256 nonce);

    address public KOTE_ITEMS;
    address public SIGNER = 0x471ca92b32f0D38a72b5CB2037ce4C07eaD8AFC3;

    mapping(address wallet => uint256 nonce) public depositNonce;
    mapping(address wallet => mapping(uint256 nonce => bool used)) public withdrawalNonceUsed;

    constructor() {

    }

    function verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == SIGNER;
    }

    function depositItems(uint256[] calldata ids, uint256[] calldata amounts) public nonReentrant {
        require(ids.length == amounts.length, "Array lengths must be equal");
        uint256 nonce = depositNonce[msg.sender];

        for(uint i = 0; i < ids.length; i++)
            _depositItem(ids[i], amounts[i], nonce++);

        depositNonce[msg.sender] = nonce;
    }

    function _depositItem(uint256 id, uint256 amount, uint256 nonce) internal {
        require(amount > 0, "Non zero value required");
        
        KoteItems(KOTE_ITEMS).burn(msg.sender, id, amount);

        emit DepositedItem(msg.sender, id, amount, nonce);

    }

    function withdrawItems(uint256[] calldata ids, uint256[] calldata amounts, uint256[] calldata nonces, bytes[] calldata signatures) public nonReentrant {
        require(ids.length == amounts.length && amounts.length == nonces.length && nonces.length == signatures.length, "Array lengths must be equal");
        
        for(uint i = 0; i < ids.length; i++)
            _withdrawItem(ids[i], amounts[i], nonces[i], signatures[i]);

    }

    function _withdrawItem(uint256 id, uint256 amount, uint256 nonce, bytes calldata signature) internal {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, id, amount, nonce)));

        require(!withdrawalNonceUsed[msg.sender][nonce], "Nonce already used");
        require(verify(hash, signature), "Invalid sig");
        require(amount > 0, "Non zero value required");
        
        withdrawalNonceUsed[msg.sender][nonce] = true;

        KoteItems(KOTE_ITEMS).mint(msg.sender, id, amount);

        emit WithdrewItem(msg.sender, id, amount, nonce);
    }

    function setSigner(address wallet) public onlyOwner {
        SIGNER = wallet;
    }

    function setKoteItems(address newContract) public onlyOwner {
        KOTE_ITEMS = newContract;
    }

}
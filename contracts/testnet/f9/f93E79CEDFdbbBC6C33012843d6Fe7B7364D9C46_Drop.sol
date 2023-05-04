// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SignatureChecker.sol";
import "./EnumerableSet.sol";
import "./Strings.sol";

import "./Claimable.sol";

contract Drop is Claimable {
    uint256 public constant MAX_ADDRESSES = 700000;
    uint256 public constant MAX_TOKEN = 210_000_000_000_000_000 * 1e6;
    uint256 public constant INIT_CLAIM = 270_000_000_000 * 1e6;

    IERC20 public token;
    uint256 public fee;
    address public feeTo1;
    address public feeTo2;
    address public feeTo3;
    address public signer;
    uint256 public claimedSupply = 0;
    uint256 public claimedCount = 0;
    uint256 public claimedPercentage = 0;
    mapping(address => bool) public claimed;
    mapping(address => uint256) public inviteUsers;
    mapping(address => uint256) public inviteRewards;

    event Claim(address indexed user, uint256 amount, address referrer, uint256 timestamp);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function setFee(uint256 _fee, address _feeTo1, address _feeTo2, address _feeTo3) public onlyOwner {
        fee = _fee;
        feeTo1 = _feeTo1;
        feeTo2 = _feeTo2;
        feeTo3 = _feeTo3;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function canClaimAmount() public view returns (uint256) {
        if (claimedCount >= MAX_ADDRESSES) {
            return 0;
        }
        uint256 amount = INIT_CLAIM;
        for (uint i = 0; i < claimedCount / 2000; i++) {
            amount = (amount * 99) / 100;
        }
        return amount;
    }

    function drop(bytes calldata signature, address referrer) public payable {
        if (fee != 0 && msg.value < fee) revert();
        if (msg.value > 0) {
            payable(feeTo1).transfer((msg.value * 8) / 10);
            payable(feeTo2).transfer((msg.value * 1) / 10);
            payable(feeTo3).transfer((msg.value * 1) / 10);
        }

        if (claimed[_msgSender()]) revert("already claimed");
        claimed[_msgSender()] = true;
        bytes memory message = abi.encode(address(this), _msgSender());
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert("invalid signature");

        uint256 amount = canClaimAmount();
        if (amount < 1e6) revert("airdrop has ended");
        token.transfer(_msgSender(), amount);
        claimedSupply += amount;
        claimedCount++;
        claimedPercentage = (claimedCount * 100) / MAX_ADDRESSES;

        if (referrer != address(0) && referrer != _msgSender()) {
            uint256 num = (amount * 10) / 100;
            token.transfer(referrer, num);
            claimedSupply += num;
            inviteRewards[referrer] += num;
            inviteUsers[referrer]++;
        }

        emit Claim(_msgSender(), amount, referrer, block.timestamp);
    }
}
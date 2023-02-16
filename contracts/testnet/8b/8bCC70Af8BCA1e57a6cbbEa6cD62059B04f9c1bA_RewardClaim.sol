pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISignature.sol";

/** 
 * Tales of Elleria - For distributing on-chain ERC20 airdrops.
 * 1. Owner deposits ERC20 into the contract.
 * 2. Owner calls SetupReward with the relevant parameters (amount in WEI)
 * 3. Users can claim through https://app.talesofelleria.com/
*/
contract RewardClaim is ReentrancyGuard {

  struct RewardEntry {
    bytes32 root;
    uint256 royaltyAmount;
    address royaltyAddress;
    mapping (address => bool) isAddressClaimed;
    bool isValid;
    uint256 claimedCount;
  }

  mapping(uint => RewardEntry) rewards;

  address private ownerAddress;             // The contract owner's address.
  ISignature private signatureAbi;
  address private signerAddr;

  constructor() {
        ownerAddress = msg.sender;
    }

    function _onlyOwner() private view {
        require(msg.sender == ownerAddress, "O");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    // Merkle Proofs
    function setRoot(uint rewardId, bytes32 root) external onlyOwner {
        rewards[rewardId].root = root;
    }

    function verify(uint rewardId, bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];

        if (computedHash <= proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
            // Hash(current element of the proof + current computed hash)
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
        }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == rewards[rewardId].root;
    }

    function isWhitelisted(uint rewardId, address addr, bytes32[] memory proof) external view returns (uint) {
        if (rewards[rewardId].isAddressClaimed[addr]) {
            return 2; // Claimed.
        } else if (verify(rewardId, keccak256(abi.encode(addr)), proof)) {
            return 1; // Eligible.
        }
        return 0; // Ineligible.
    }

    function hasClaimed(uint rewardId, address addr) external view returns (bool) {
        return rewards[rewardId].isAddressClaimed[addr];
    }

    // Amount specified from snapshot to enable use of proofs with a single wallet holding multiple NFTs.
    function ClaimRoyalty(uint rewardId, uint256 amount, bytes memory signature, bytes32[] memory proof) external nonReentrant {
        require (tx.origin == msg.sender, "RewardClaim: No delegating.");
        require (!(rewards[rewardId].isAddressClaimed[msg.sender]), "RewardClaim: Already Claimed.");
        require (rewards[rewardId].isValid, "RewardClaim: Invalid Reward.");
        require (IERC20(rewards[rewardId].royaltyAddress).balanceOf(address(this)) >= amount, "RewardClaim: Insufficient ERC20 Token.");
        require (amount % rewards[rewardId].royaltyAmount == 0, "RewardClaim: Invalid Amount");
        require (verify(rewardId, keccak256(abi.encode(msg.sender)), proof), "RewardClaim: Invalid Proof.");
        require (signatureAbi.verify(signerAddr, msg.sender, rewardId, "reward claim", amount, signature), "RewardClaim: Invalid Signature.");
    
        IERC20(rewards[rewardId].royaltyAddress).transfer(msg.sender, amount);
        rewards[rewardId].isAddressClaimed[msg.sender] = true;
        rewards[rewardId].claimedCount += 1;

        emit RewardClaimed(rewardId, msg.sender, rewards[rewardId].royaltyAddress, amount);
    }

    function setupReward(uint rewardId, bytes32 root, uint256 royaltyAmount, address royaltyAddress) external onlyOwner {
        require (!rewards[rewardId].isValid, "RewardClaim: Cannot change ongoing reward.");

        rewards[rewardId].root = root;
        rewards[rewardId].royaltyAmount = royaltyAmount;
        rewards[rewardId].royaltyAddress = royaltyAddress;
        rewards[rewardId].isValid = true;
    }

    function disableReward(uint rewardId) external onlyOwner {
        rewards[rewardId].isValid = false;
    }

  function setAddresses(address _signatureAddr, address _signerAddr) external onlyOwner {
    signatureAbi = ISignature(_signatureAddr);
    signerAddr = _signerAddr;
  }

  function withdraw() public onlyOwner {
    (bool success, ) = (msg.sender).call{value:address(this).balance}("");
    require(success, "RewardClaim: Invalid Balance.");
  }

  function withdrawERC20(address _erc20Addr, address _recipient) external onlyOwner {
    IERC20(_erc20Addr).transfer(_recipient, IERC20(_erc20Addr).balanceOf(address(this)));
  }

  event RewardClaimed(uint indexed rewardId, address indexed claimedBy, address token, uint256 amount);

}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the signature verifier.
contract ISignature {
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) public pure returns (bool) { }
    function bigVerify( address _signer, address _to, uint256[] memory _data, bytes memory signature ) public pure returns (bool) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
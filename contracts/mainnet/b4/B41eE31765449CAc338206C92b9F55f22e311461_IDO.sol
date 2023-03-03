// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Governable } from "./libraries/Governable.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import "./libraries/MerkleProof.sol";

contract IDO is ReentrancyGuard, Governable {
    uint256 constant PRECISION = 1000;

    bool public isDeposit;
    bool public isClaimToken;
    bool public isClaimWhitelistSale;
    bool public isClaimPublicSale;
    bool public isClaimRef;
    bool public isPublicSale;
    bool public isWhitelistSale;

    uint256 public maxAmountDeposit;
    uint256 public minAmountDeposit;
    uint256 public round1HardCap;
    uint256 public round2HardCap;
    uint256 public round3HardCap;
    uint256 public rate;
    uint256 public refPercent;

    uint256 public totalWhitelistDeposit;
    uint256 public totalPublicDeposit;
    uint256 public totalClaim;
    uint256 public totalWhitelistClaim;
    address public tokenSell;

    bytes32 public merkleRoot;

    mapping(address => uint256) public whitelistDepositUsers;
    mapping(address => mapping(uint256 => uint256)) public publicDepositUsers;
    mapping(address => address) public refUsers;
    mapping(address => uint256) public refCount;
    mapping(address => uint256) public refAmount;
    mapping(address => mapping(uint256 => bool)) public claimPublicTokenUsers;
    mapping(address => bool) public claimWhitelistTokenUsers;

    event Deposit(address indexed account, uint256 amount);
    event ClaimTokenSell(address indexed account, uint256 amount);
    event SetSale(bool isPublicSale, bool isWhitelistSale);

    constructor(address _tokenSell) {
      tokenSell = _tokenSell;
      maxAmountDeposit = 5 * 10 ** 18;
      minAmountDeposit = 5 * 10 ** 16;

      round1HardCap = 50 * 10 ** 18; // 50 ETH
      round2HardCap = 100 * 10 ** 18; // 100 ETH
      round3HardCap = 150 * 10 ** 18; // 150 ETH

      rate = 2000;
      refPercent = 30; // 3%
    }

    function setClaimStatus(bool _isClaimWhitelistSale, bool _isClaimPublicSale,  bool _isClaimRef) external onlyGov {
      isClaimWhitelistSale = _isClaimWhitelistSale;
      isClaimPublicSale = _isClaimPublicSale;
      isClaimRef = _isClaimRef;
    }

    function setSale(bool _isPublicSale, bool _isWhitelistSale) external onlyGov {
        isPublicSale = _isPublicSale;
        isWhitelistSale = _isWhitelistSale;
        emit SetSale(_isPublicSale, _isWhitelistSale);
    }
    
    function setTokens(address _tokenSell) external onlyGov {
      tokenSell = _tokenSell;
    }

    function setMaxAmountDeposit(uint256 _maxAmountDeposit, uint256 _minAmountDeposit) external onlyGov {
      maxAmountDeposit = _maxAmountDeposit;
      minAmountDeposit = _minAmountDeposit;
    }

    function setHardCap(uint256 _round1HardCap, uint256 _round2HardCap, uint256 _round3HardCap) external onlyGov {
      round1HardCap = _round1HardCap;
      round2HardCap = _round2HardCap;
      round3HardCap = _round3HardCap;
    }

    function setRefPercent(uint256 _percent) external onlyGov {
      refPercent = _percent;
    }

    function whitlelistDeposit(address _refAddress, bytes32[] calldata _merkleProf) external payable nonReentrant {
      require(isDeposit, "IDO: deposit not active");
      require(isWhitelistSale, "IDO: sale is closed");
      require(_verify(_merkleProf, msg.sender), "IDO: invalid proof");

      uint256 amount = msg.value;
      uint256 totalAmount = amount + totalWhitelistDeposit;
      
      require(totalAmount <= round1HardCap, "IDO: max hardcap round 1");
      require((whitelistDepositUsers[msg.sender] + amount) <= maxAmountDeposit, "IDO: max amount deposit per user");
      require(amount >= minAmountDeposit, "IDO: min amount deposit per user");

      whitelistDepositUsers[msg.sender] += amount;
      totalWhitelistDeposit += amount;

      // handle ref
      if (refUsers[msg.sender] == address(0) && _refAddress != address(msg.sender) && _refAddress != address(0)) {
        refUsers[msg.sender] = _refAddress;
        refCount[_refAddress] += 1;
        refAmount[_refAddress] += (amount * refPercent) / PRECISION;
      } else if (refUsers[msg.sender] != address(0)) {
        refAmount[refUsers[msg.sender]] += (amount * refPercent) / PRECISION;
      }

      emit Deposit(msg.sender, amount);
    }

    function publicDeposit(address _refAddress) external payable nonReentrant {
      require(isPublicSale, "IDO: sale is closed");

      uint256 amount = msg.value;
      uint256 totalAmount = amount + totalPublicDeposit;
      uint256 roundNumber = totalPublicDeposit >= round2HardCap ? 2 : 3;
      
      require(totalAmount <= (round2HardCap + round3HardCap), "IDO: max hardcap round 3");
      require((publicDepositUsers[msg.sender][roundNumber] + amount) <= maxAmountDeposit, "IDO: max amount deposit per user");
      require(amount >= minAmountDeposit, "IDO: min amount deposit per user");

      publicDepositUsers[msg.sender][roundNumber] += amount;
      totalPublicDeposit += amount;

      // handle ref
      if (refUsers[msg.sender] == address(0) && _refAddress != address(msg.sender) && _refAddress != address(0)) {
        refUsers[msg.sender] = _refAddress;
        refCount[_refAddress] += 1;
        refAmount[_refAddress] += (amount * refPercent) / PRECISION;
      } else if (refUsers[msg.sender] != address(0)) {
        refAmount[refUsers[msg.sender]] += (amount * refPercent) / PRECISION;
      }

      emit Deposit(msg.sender, amount);
    }

    function withDrawnFund(uint256 _amount) external onlyGov {
      _safeTransferETH(address(msg.sender), _amount);
    }

    function claimToken(uint256 _round) external nonReentrant {
      require(isClaimPublicSale, "IDO: claim token not active");
      require(!claimPublicTokenUsers[msg.sender][_round], "IDO: user already claim token");

      uint256 amountToken = publicDepositUsers[msg.sender][_round] * rate;

      if (amountToken > 0) {
        IERC20(tokenSell).transfer(msg.sender, amountToken);
        totalClaim += amountToken;
      }

      claimPublicTokenUsers[msg.sender][_round] = true;

      emit ClaimTokenSell(msg.sender, amountToken);
    }

    function claimRef() external nonReentrant {
      require(isClaimRef, "IDO: claim ref not active");

      if (refAmount[msg.sender] > 0) {
        _safeTransferETH(address(msg.sender), refAmount[msg.sender]);
        refAmount[msg.sender] = 0;
      }
    }

    function whitelistClaimToken() external nonReentrant {
      require(isClaimWhitelistSale, "IDO: claim whitelist token not active");
      require(!claimWhitelistTokenUsers[msg.sender], "IDO: user already claim token");

      uint256 amountToken = whitelistDepositUsers[msg.sender] * rate;

      if (amountToken > 0) {
        IERC20(tokenSell).transfer(msg.sender, amountToken);
        totalWhitelistClaim += amountToken;
      }

      claimWhitelistTokenUsers[msg.sender] = true;

      emit ClaimTokenSell(msg.sender, amountToken);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverFungibleTokens(address _token) external onlyGov {
        uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
        require(amountToRecover != 0, "Operations: No token to recover");

        IERC20(_token).transfer(address(msg.sender), amountToRecover);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyGov {
        merkleRoot =  _merkleRoot;
    }

    function _verify(bytes32[] calldata _merkleProof, address _sender) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
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
        return computedHash;
    }
}
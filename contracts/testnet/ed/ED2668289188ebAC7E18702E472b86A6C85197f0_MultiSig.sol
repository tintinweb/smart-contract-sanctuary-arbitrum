// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IXMozToken.sol";

contract MultiSig is Ownable, ReentrancyGuard  {
    
    address[] public councilMembers;
    uint256 public threshold;
    
    struct Proposal {
        address proposer;
        uint8 actionType;
        bytes payload;
        uint8 confirmation;
        bool executed;
    }

    uint8 constant internal TYPE_ADD_OWNER = 1;
    uint8 constant internal TYPE_DEL_OWNER = 2;
    uint8 constant internal TYPE_ADJ_THRESHOLD = 3;
    uint8 constant internal TYPE_UPDATE_WHITELIST = 4;
    uint8 constant internal TYPE_MINT_BURN = 5;
    bytes32[] public proposalIds;
    mapping(address => bool) public isCouncil;
    mapping(bytes32 => Proposal) public proposals;
    mapping(bytes32 => mapping(address => bool)) public confirmations;

    event ProposalSubmitted(bytes32 proposalId, address sender);
    event Confirmation(bytes32 proposalId, address indexed sender);

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length >= _threshold, "Error: Not enough owners.");
        councilMembers = _owners;
        threshold = _threshold;

        for (uint256 i = 0; i < _owners.length; i++) {
            isCouncil[_owners[i]] = true;
        }
    }

    modifier onlyCouncil() {
        require(isCouncil[msg.sender], "Error: Caller is not an owner.");
        _;
    }

    modifier notConfirmed(bytes32 _proposalId) {
        require(!confirmations[_proposalId][msg.sender], "Error: already confirmed.");
        _;
    }
    
    function getProposalIds() public view returns(bytes32[] memory) {
        return proposalIds;
    }

    function getOnwers() public view returns(address[] memory) {
        return councilMembers;
    }

    function submitProposal(uint8 _actionType, bytes memory _payload) public onlyCouncil {

        bytes32 proposalId = keccak256(abi.encode(_actionType, _payload, msg.sender));
        require(proposals[proposalId].proposer == address(0x0), "Invalid proposalId");
        proposals[proposalId] = Proposal(msg.sender,_actionType, _payload, 0, false);
        proposalIds.push(proposalId);
        emit ProposalSubmitted(proposalId, msg.sender);
    }

    function confirmTransaction(bytes32 _proposalId) public onlyCouncil notConfirmed(_proposalId) nonReentrant {
        confirmations[_proposalId][msg.sender] = true;
        proposals[_proposalId].confirmation += 1;

        emit Confirmation(_proposalId, msg.sender);
    }

    function execute(bytes32 _proposalId) public nonReentrant onlyCouncil {
        require(proposals[_proposalId].executed == false, "Error: Proposal already executed.");
        require(proposals[_proposalId].confirmation >= threshold, "Error: Not enough confirmations.");
        if(proposals[_proposalId].actionType == TYPE_ADD_OWNER) {
            (address _owner) = abi.decode(proposals[_proposalId].payload, (address));
            require(contains(_owner) == 0, "Invalid owner address");
            councilMembers.push(_owner);
            proposals[_proposalId].executed = true;
            isCouncil[_owner] = true;
        }
        if(proposals[_proposalId].actionType == TYPE_DEL_OWNER) {
            (address _owner) = abi.decode(proposals[_proposalId].payload, (address));
            require(contains(_owner) != 0, "Invalid owner address");
            uint index = contains(_owner) - 1;
            for (uint256 i = index; i < councilMembers.length - 1; i++) {
                councilMembers[i] = councilMembers[i + 1];
            }
            councilMembers.pop();
            proposals[_proposalId].executed = true;
            isCouncil[_owner] = false;
        }
        if(proposals[_proposalId].actionType == TYPE_ADJ_THRESHOLD) {
            (uint256 _threshold) = abi.decode(proposals[_proposalId].payload, (uint256));
            require(_threshold > 0, "Invalid threshold");
            require(councilMembers.length >= threshold, "Invalid threshold");
            proposals[_proposalId].executed = true;
            threshold = _threshold;
        }
        if(proposals[_proposalId].actionType == TYPE_UPDATE_WHITELIST) {
            (address _token, address _account, bool _flag) = abi.decode(proposals[_proposalId].payload, (address, address, bool));
            proposals[_proposalId].executed = true;
            IXMozToken(_token).updateTransferWhitelist(_account, _flag);
        }
        if(proposals[_proposalId].actionType == TYPE_MINT_BURN) {
            (address _token, address _to, uint256 _amount, bool _flag) = abi.decode(proposals[_proposalId].payload, (address, address, uint256, bool));
            if(_flag) {
                IXMozToken(_token).mint(_amount, _to);
            } else {
                IXMozToken(_token).burn(_amount, _to);
            }
            proposals[_proposalId].executed = true;
        }
    }

    function contains(address _owner) public view returns (uint) {
        for (uint i = 1; i <= councilMembers.length; i++) {
            if (councilMembers[i - 1] == _owner) {
                return i;
            }
        }
        return 0;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXMozToken is IERC20 {

    function mint(uint256 amount, address to) external;

    function isTransferWhitelisted(address account) external view returns (bool);

    function burn(uint256 amount, address to) external;

    function updateTransferWhitelist(address account, bool flag) external;

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
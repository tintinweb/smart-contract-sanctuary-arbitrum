// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Admin {

    error OnlyAdmin();

    event NewAdmin(address newAdmin);

    address public admin;

    modifier _onlyAdmin_() {
        if (msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    /**
     * @notice Set a new admin for the contract.
     * @dev This function allows the current admin to assign a new admin address without performing any explicit verification.
     *      It's the current admin's responsibility to ensure that the 'newAdmin' address is correct and secure.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './VoteStorage.sol';

contract VoteImplementation is VoteStorage {

    event NewVoteTopic(string topic, uint256 numOptions, uint256 deadline);

    event NewVote(address indexed voter, uint256 option);

    uint256 public constant cooldownTime = 900;

    function initializeVote(string memory topic_, uint256 numOptions_, uint256 deadline_) external _onlyAdmin_ {
        require(block.timestamp > deadline, 'VoteImplementation.initializeVote: still in vote');
        topic = topic_;
        numOptions = numOptions_;
        deadline = deadline_;
        delete voters;
        emit NewVoteTopic(topic_, numOptions_, deadline_);
    }

    function vote(uint256 option) external {
        require(block.timestamp < deadline, 'VoteImplementation.vote: vote ended');
        require(option >= 1 && option <= numOptions, 'VoteImplementation.vote: invalid vote option');
        voters.push(msg.sender);
        votes[msg.sender] = option;
        if (block.timestamp + cooldownTime >= deadline) {
            deadline += cooldownTime;
        }
        emit NewVote(msg.sender, option);
    }

    //================================================================================
    // Convenient query functions
    //================================================================================

    function getVoters() external view returns (address[] memory) {
        return voters;
    }

    function getVotes(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory options = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            options[i] = votes[accounts[i]];
        }
        return options;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './VoteImplementation.sol';

contract VoteImplementationArbitrum is VoteImplementation {

    function getVotePower(address account, uint256 lTokenId) public view returns (uint256 power) {
        address deri = 0x21E60EE73F17AC0A411ae5D690f908c3ED66Fe12;
        address lToken = 0xD849c2b7991060023e5D92b92c68f4077AE2C2Ba;
        address vaultDeri = 0xc8Eef19C657C46CbD9AB7cA45f2F00a74b4AC141;

        // balance in wallet
        power += IERC20(deri).balanceOf(account);

        // balance in V4 Gateway
        if (lTokenId != 0) {
            require(IDToken(lToken).ownerOf(lTokenId) == account, 'account not own lTokenId');
            power += IVault(vaultDeri).getBalance(lTokenId);
        }
    }

    function getVotePowers(address[] memory accounts, uint256[] memory lTokenIds) external view returns (uint256[] memory) {
        require(accounts.length == lTokenIds.length, 'accounts length not match lTokenIds length');
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePower(accounts[i], lTokenIds[i]);
        }
        return powers;
    }

}

interface IDToken {
    function ownerOf(uint256) external view returns (address);
}

interface IVault {
    function getBalance(uint256 dTokenId) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract VoteStorage is Admin {

    address public implementation;

    string public topic;

    uint256 public numOptions;

    uint256 public deadline;

    // voters may contain duplicated address, if one submits more than one votes
    address[] public voters;

    // voter address => vote
    // vote starts from 1, 0 is reserved for no vote
    mapping (address => uint256) public votes;

}
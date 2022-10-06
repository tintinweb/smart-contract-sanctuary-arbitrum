// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////////////////////////////////
// @title   Peanut Protocol, Authored Escrow Contract (simplified)
// @version 1.0
// @author  H & K
// @dev     This contract is used to send link payments.
// @dev     more at: https://peanut.to
//////////////////////////////////////////////////////////////////////////////////////
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//                         ⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣦⣌⠙⠋⢡⣴⣶⡄⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⣿⣿⣿⡿⢋⣠⣶⣶⡌⠻⣿⠟⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⡆⠸⠟⢁⣴⣿⣿⣿⣿⣿⡦⠉⣴⡇⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⠟⠀⠰⣿⣿⣿⣿⣿⣿⠟⣠⡄⠹⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⢸⡿⢋⣤⣿⣄⠙⣿⣿⡿⠟⣡⣾⣿⣿⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣾⠿⠀⢠⣾⣿⣿⣿⣦⠈⠉⢠⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⣀⣤⣦⣄⠙⠋⣠⣴⣿⣿⣿⣿⠿⠛⢁⣴⣦⡄⠙⠛⠋⠁⠀⠀⠀⠀
// ⠀⠀⢀⣾⣿⣿⠟⢁⣴⣦⡈⠻⣿⣿⡿⠁⡀⠚⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠘⣿⠟⢁⣴⣿⣿⣿⣿⣦⡈⠛⢁⣼⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⢰⡦⠀⢴⣿⣿⣿⣿⣿⣿⣿⠟⢀⠘⠿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠘⢀⣶⡀⠻⣿⣿⣿⣿⡿⠋⣠⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⢿⣿⣿⣦⡈⠻⣿⠟⢁⣼⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠈⠻⣿⣿⣿⠖⢀⠐⠿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀
//
//////////////////////////////////////////////////////////////////////////////////////

// imports
import "Ownable.sol";

contract AuthoredEscrow is Ownable {
    struct deposit {
        address sender;
        uint256 amount; // amount to send
        bytes32 pwdHash; // hash of the deposit password
    }
    // technically sender and pwdHash could be optional, optimizing on gas fees
    deposit[] public deposits; // array of deposits
    bool emergency = false; // emergency flag

    // events
    event Deposit(address indexed sender, uint256 amount, uint256 index);
    event Withdraw(address indexed recipient, uint256 amount);

    // constructor
    constructor() {}

    // deposit ether to escrow & get a deposit id
    function makeDeposit(bytes32 pwdHash) external payable returns (uint256) {
        require(msg.value > 0, "deposit must be greater than 0");

        // store new deposit
        deposit memory newDeposit;
        newDeposit.amount = msg.value;
        newDeposit.sender = msg.sender;
        newDeposit.pwdHash = pwdHash;
        deposits.push(newDeposit);
        emit Deposit(msg.sender, msg.value, deposits.length - 1);
        // return id of new deposit
        return deposits.length - 1;
    }

    // sender can always withdraw deposited assets at any time
    function withdrawSender(uint256 _index) external {
        require(_index < deposits.length, "index out of bounds");
        require(
            deposits[_index].sender == msg.sender,
            "only sender can withdraw"
        );

        // transfer ether back to sender
        payable(msg.sender).transfer(deposits[_index].amount);
        emit Withdraw(deposits[_index].sender, deposits[_index].amount);

        // remove deposit from array
        delete deposits[_index];
    }

    // centralized transfer function to transfer ether to recipients newly created wallet
    // TODO: replace with zk-SNARK based function
    function withdrawOwner(
        uint256 _index,
        address _recipient,
        bytes32 _pwd
    ) external onlyOwner {
        require(_index < deposits.length, "index out of bounds");
        // require that the deposits[idx] is not deleted
        require(
            deposits[_index].sender != address(0),
            "deposit has already been claimed"
        );
        // require that the password is correct (disable if DB loss)
        if (!emergency) {
            require(
                keccak256(abi.encodePacked(_pwd)) == deposits[_index].pwdHash,
                "incorrect password"
            );
        }

        // transfer ether to recipient
        payable(_recipient).transfer(deposits[_index].amount);
        emit Withdraw(_recipient, deposits[_index].amount);

        // remove deposit from array
        delete deposits[_index];
    }

    //// Some utility functions ////
    function getDepositCount() external view returns (uint256) {
        return deposits.length;
    }

    function getDeposit(uint256 _index) external view returns (deposit memory) {
        return deposits[_index];
    }

    function getDepositsSent(address _sender)
        external
        view
        returns (deposit[] memory)
    {
        deposit[] memory depositsSent = new deposit[](deposits.length);
        uint256 count = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].sender == _sender) {
                depositsSent[count] = deposits[i];
                count++;
            }
        }
        return depositsSent;
    }

    // and that's all! Have a nutty day!
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
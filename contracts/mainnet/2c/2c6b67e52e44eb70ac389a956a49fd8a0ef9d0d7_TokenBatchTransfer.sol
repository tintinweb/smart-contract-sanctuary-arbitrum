/**
 *Submitted for verification at Arbiscan.io on 2023-09-14
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/6_Multisend.sol

pragma solidity ^0.8.9;

  /**
   * @title PHBA_BatchTransfer
   * @dev ContractDescription
   * @custom:dev-run-script file_path
   */
contract TokenBatchTransfer is Ownable {

    // 2023 Sep 14th 11am00 ARB mainnet 
    address public transferOperator; // Address to manage the Transfers

    // Modifiers
    modifier onlyOperator() {
        require(
            msg.sender == transferOperator,
            "Only operator can call this function."
        );
        _;
    }

    constructor()
    public
    {
        transferOperator = msg.sender;
    }


    // Events
    event NewOperator(address transferOperator);
    event WithdrawToken(address indexed owner, uint256 stakeAmount);

    function updateOperator(address newOperator) public onlyOwner {

        require(newOperator != address(0), "Invalid operator address");
        
        transferOperator = newOperator;

        emit NewOperator(newOperator);
    }

    // To withdraw tokens from contract, to deposit directly transfer to the contract
    function withdrawToken(uint256 value) external onlyOperator
    {

        // Check if contract is having required balance 
        require(address(this).balance >= value);//require(token.balanceOf(address(this)) >= value, "Not enough balance in the contract");
        //require(token.transfer(msg.sender, value), "Unable to transfer token to the owner account");
        transferOperator.call{value:value}("");
        emit WithdrawToken(msg.sender, value);
        
    }
    function getTotalSendingAmount(uint256[] calldata _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount += _amounts[i];
        }
    }
    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);
    // To transfer tokens from Contract to the provided list of token holders with respective amount
    function transferMulti(address[] calldata receivers, uint256[] calldata amounts) external payable {
        require(msg.value != 0 && msg.value >= getTotalSendingAmount(amounts));
        for (uint256 j = 0; j < amounts.length; j++) {
            // receivers[j].transfer(amounts[j]);
            receivers[j].call{value:amounts[j]}("");
            emit Sent(msg.sender, receivers[j], amounts[j]);
        }
    }

}
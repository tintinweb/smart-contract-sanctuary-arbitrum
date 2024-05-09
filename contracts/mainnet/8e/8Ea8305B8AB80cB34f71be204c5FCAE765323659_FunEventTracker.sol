/**
 *Submitted for verification at Arbiscan.io on 2024-05-09
*/

// SPDX-License-Identifier: MIT

// Fun event tracker --> visit https://www.base.fun/ for full experience
pragma solidity ^0.8.17;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public voter;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyVoter() {
        require(msg.sender == voter);
        _;
    }
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

interface funRegistryInterface {

    function getFunContractIndex(address _funContract) external returns(uint256);


}
contract FunEventTracker is Ownable {

    address public funRegistry;
    mapping(address => bool) public funContractValid;
    mapping(address => bool) public funContractDeployer;

    event buyCall(address indexed buyer, address indexed funContract, uint256 buyAmount, uint256 tokenReceived, uint256 index, uint256 timestamp);
    event sellCall(address indexed seller, address indexed funContract, uint256 sellAmount, uint256 nativeReceived, uint256 index, uint256 timestamp);
        
    constructor(address _funStorage) {

        funRegistry = _funStorage;

    }
    function buyEvent(address _buyer, address _funContract, uint256 _buyAmount, uint256 _tokenRecieved) public {

        
        require(funContractValid[msg.sender],"invalid fun contract");
        uint256 funIndex;
        funIndex = funRegistryInterface(funRegistry).getFunContractIndex(_funContract);
        emit buyCall(_buyer, _funContract, _buyAmount, _tokenRecieved,funIndex, block.timestamp);


    }
    function sellEvent(address _seller, address _funContract, uint256 _sellAmount, uint256 _nativeRecieved) public {

        require(funContractValid[msg.sender],"invalid fun contract");
        uint256 funIndex;
        funIndex = funRegistryInterface(funRegistry).getFunContractIndex(_funContract);
        emit sellCall(_seller, _funContract, _sellAmount, _nativeRecieved,funIndex, block.timestamp);

    }

    function callerValidate(address _newFunContract) public {

        require(funContractDeployer[msg.sender],"invalid deployer");
        funContractValid[_newFunContract] = true;


    }

    function addDeployer(address _newDeployer) public onlyOwner{

        funContractDeployer[_newDeployer] = true;

    }



}
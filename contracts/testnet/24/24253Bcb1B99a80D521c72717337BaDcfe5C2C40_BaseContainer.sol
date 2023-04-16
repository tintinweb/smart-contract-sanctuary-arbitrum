pragma solidity ^0.6.0;


contract Owned {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

pragma solidity ^0.6.0;

import "./ContractManager.sol";
import "./ContractNames.sol";


/**
    @title BaseContainer
    @dev Contains all getters of contract addresses in the system
    @author abhaydeshpande
 */
contract BaseContainer is ContractManager, ContractNames {
    function getAddressOfLoanManager() public view returns (address) {
        return getContract(CONTRACT_LOAN_MANAGER);
    }

    function getAddressOfWallet() public view returns (address) {
        return getContract(CONTRACT_WALLET);
    }

    function getAddressOfLoanDB() public view returns (address) {
        return getContract(CONTRACT_LOAN_DB);
    }

    function getAddressOfHeartToken() public view returns (address) {
        return getContract(CONTRACT_HEART_TOKEN);
    }
}

pragma solidity ^0.6.0;

import "../auth/Owned.sol";


/**
    @title ContractManager
    @dev Manages all the contract in the system
    @author abhaydeshpande
 */
contract ContractManager is Owned {
    mapping(string => address) private contracts;

    function addContract(string memory name, address contractAddress)
        public
        onlyOwner
    {
        require(contracts[name] == address(0), "Contract already exists");
        contracts[name] = contractAddress;
    }

    function getContract(string memory name) public view returns (address) {
        require(contracts[name] != address(0), "Contract hasn't set yet");
        return contracts[name];
    }
}

pragma solidity ^0.6.0;


contract ContractNames {
    string constant CONTRACT_LOAN_MANAGER = "LoanManager";
    string constant CONTRACT_WALLET = "Wallet";
    string constant CONTRACT_LOAN_DB = "LoanDB";
    string constant CONTRACT_HEART_TOKEN = "HeartToken";
}
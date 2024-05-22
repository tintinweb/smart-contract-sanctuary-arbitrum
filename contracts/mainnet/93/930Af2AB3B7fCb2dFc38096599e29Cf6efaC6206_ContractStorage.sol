// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IContractStorage.sol";

/**
    @dev ContractStorage is storing addresses of main contracts.

    Add & Update contracts via updateVersion()
    Get contract address via getContractAddressViaName()

*/
contract ContractStorage is IContractStorage, Ownable {

    /**
        @dev _contractVector is vector for last version smart contracts
        
        last version = _contractVector[sha256(contractName)].last
    */
    mapping (bytes32=>mapping (uint => address[])) _contractVector;
    mapping (uint => string[]) private  _contractNames;
    uint[] private _knownNetworkIds;

    constructor () {}

    /**
        @dev Returns address of contract in selected network by keccak name

        @param contractName - keccak name of contract (with encodepacked);
    */
    function getContractAddress(bytes32 contractName, uint networkId) public override view returns (address) { 
        uint versionCount = _contractVector[contractName][networkId].length;
        if (versionCount == 0) {
            return address(0);
        }
        return _contractVector[contractName][networkId][versionCount - 1];
    }

    /**
        @dev Returns address of contract in selected network by string name

        @param contractString - string name of contract
    */
    function getContractAddressViaName(string calldata contractString, uint networkId) public override view returns (address) { 
        return getContractAddress(stringToContractName(contractString), networkId);
    }

    /**
        @dev updateVersion is function to update address of contracts
    */
    function _updateVersion(bytes32 contractName, address newAddress, uint networkId) internal {
        _contractVector[contractName][networkId].push(newAddress);
    }

    /**
    *@dev function returns keccak256 of named contract
    *
    *Result Params;
    *
    *- `proofofstorage` - ProofOfStorage 
    *- `gastoken` - TB/Year gas token
    *- `userstorage` - UserStorage Address
    *- `nodenft` - node nft address
    *
    *@param nameString - name of core contract, examples:
    *    
    *@return bytes32 - keccak256(nameString)
    */
    function stringToContractName(string calldata nameString) public override pure returns(bytes32) {
        return keccak256(abi.encodePacked(nameString));
    }

    /**
    *@dev Comlpex function to update contracts on all networks
    *
    *@param contractNameString - name of core contract, examples:
    * 
    *- "proofofstorage" - ProofOfStorage 
    *- "gastoken" - TB/Year gas token
    *- "userstorage" - UserStorage Address
    *- "nodenft" - node nft address
    *- "pairtoken" - DFILE Token (as main token). If not available, using USDC or other.
    *- "userstorage" - User Storage address (Contract where stored data like Nonce and root hash)
    *@param newContractAddress - new address of contract
    *@param networkId - ID of network, examples:
    *
    *- 1 - Ethereum Mainnet
    *- 3 - Ropsten Testnet
    *- 10 - Optimism
    *- 42 - Kovan Testnet
    *- 56 - Binance Smart Chain
    *- 57 - Syscoin Mainnet
    *- 61 - Ethereum Classic Mainnet
    *- 66 - OKXChain Mainnet
    *- 100 - Gnosis
    *- 128 - Huobi ECO Chain Mainnet
    *- 137 - Polygon Mainne
    *- 250 - Fantom Opera
    *- 1285 - Moonriver
    *- 1313161554 - Aurora Mainnet            
    */
    function updateVersion(string calldata contractNameString, address newContractAddress, uint networkId) public onlyOwner {
        bytes32 _contractName = stringToContractName(contractNameString);
        if (_contractVector[_contractName][networkId].length == 0) {
            if (_contractNames[networkId].length == 0) {
                _knownNetworkIds.push(networkId);
            }
            _contractNames[networkId].push(contractNameString);
        }
        _updateVersion(_contractName, newContractAddress, networkId);
    }

    function getContractListOfNetwork(uint networkId) public override view returns (string[] memory) {
        return _contractNames[networkId];
    }

    function getNetworkLists() public override view returns (uint[] memory) {
        return _knownNetworkIds;
    }
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

    function getContractListOfNetwork(uint networkId) external view returns (string[] memory);

    function getNetworkLists() external view returns (uint[] memory);
}
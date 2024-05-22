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


interface IContractStorage {

    function stringToContractName(string calldata nameString) external pure returns(bytes32);

    function getContractAddress(bytes32 contractName, uint networkId) external view returns (address);

    function getContractAddressViaName(string calldata contractString, uint networkId) external view returns (address);

    function getContractListOfNetwork(uint networkId) external view returns (string[] memory);

    function getNetworkLists() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IUserStorage {
    event ChangeRootHash(
        address indexed user_address,
        address indexed node_address,
        bytes32 new_root_hash
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event ChangePaymentMethod(
        address indexed user_address,
        address indexed token
    );


    function getUserRootHash(address _user_address)
        external
        view
        returns (bytes32, uint256);

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _nonce,
        address _updater
    ) external;

    /*
        updateLastProofTime

        Function set current timestamp yo lastProofTime in users[userAddress]. it means, that
        userDifficulty = zero (current time - lastProofTime), and will grow  with time.
    */
    function updateLastProofTime(address userAddress) external;
    
    /* 
        getPeriodFromLastProof
        function return userDifficulty.
        userDifficulty =  timestamp (curren time - lastProofTime)
    */
    function getPeriodFromLastProof(address userAddress) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUserStorage.sol";
import "./interfaces/IContractStorage.sol";
import "./utils/StringNumbersConstant.sol";

contract UserStorage is IUserStorage, Ownable, StringNumbersConstant {
    struct UserData {        
        uint last_proof_time;
        uint user_storage_size;
        uint nonce;
        bytes32 user_root_hash;
    }

    string public name;
    address public PoS_Contract_Address;
    address public contractStorageAddress;
    // uint256 public lastProofRange = 10000;
    mapping(address => UserData) private _users;

    modifier onlyPoS() {
        require(msg.sender == PoS_Contract_Address, "Only PoS");
        _;
    }

    constructor(string memory _name, address _address) {
        name = _name;
        contractStorageAddress = _address;
        sync();
    }

    function sync() public onlyOwner {
        IContractStorage contractStorage = IContractStorage(contractStorageAddress);
        PoS_Contract_Address = contractStorage.getContractAddressViaName("proofofstorage", NETWORK_ID);
    }

    function changePoS(address _new_address) public onlyOwner {
        PoS_Contract_Address = _new_address;
        emit ChangePoSContract(_new_address);
    }

    function getUserRootHash(address _user_address) public view override returns (bytes32, uint256) {
        return (
            _users[_user_address].user_root_hash,
            _users[_user_address].nonce
        );
    }

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _user_storage_size,
        uint64 _nonce,
        address _updater
    ) public override onlyPoS {
        require(
            _nonce >= _users[_user_address].nonce &&
            _user_root_hash != _users[_user_address].user_root_hash,
            "new nonce is old, roothash already used"
        );

        _users[_user_address].user_root_hash = _user_root_hash;
        _users[_user_address].nonce = _nonce;
        _users[_user_address].user_storage_size = _user_storage_size;

        emit ChangeRootHash(_user_address, _updater, _user_root_hash);
    }

    /*
        updateLastProofTime

        Function set current timestamp yo lastProofTime in users[userAddress]. it means, that
        userDifficulty = zero (current time - lastProofTime), and will grow  with time.
    */
    function updateLastProofTime(address _user_address) public override onlyPoS {
        _users[_user_address].last_proof_time = block.timestamp;
    }

     /* 
        getPeriodFromLastProof
        function return userDifficulty.
        userDifficulty =  timestamp (curren time - lastProofTime)
    */
    function getPeriodFromLastProof(address _user_address) external override view returns(uint) {
        return block.timestamp - _users[_user_address].last_proof_time;
    }
}

pragma solidity ^0.8.0;

contract StringNumbersConstant {

   // Decimals Numbers
   uint public constant DECIMALS_18 = 1e18;
   uint public constant START_DEPOSIT_LIMIT = DECIMALS_18 * 100; // 100 DAI

   // Date and times
   uint public constant TIME_7D = 60*60*24*7;
   uint public constant TIME_1D = 60*60*24;
   uint public constant TIME_30D = 60*60*24*30;
   uint public constant TIME_1Y = 60*60*24*365;
   
   // Storage Sizes
   uint public constant STORAGE_1TB_IN_MB = 1048576;
   uint public constant STORAGE_10GB_IN_MB = 10240; // 10 GB;
   uint public constant STORAGE_100GB_IN_MB = 102400; // 100 GB;
  
   // nax blocks after proof depends of network, most of them 256 is ok
   uint public constant MAX_BLOCKS_AFTER_PROOF = 256;

   // Polygon Network Settigns
   address public constant PAIR_TOKEN_START_ADDRESS = 0x081Ec4c0e30159C8259BAD8F4887f83010a681DC; // DAI in Polygon
   address public constant DEFAULT_FEE_COLLECTOR = 0x15968404140CFB148365577D669477E1615557C0; // DeNet Labs Polygon Multisig
   uint public constant NETWORK_ID = 2241;

   // StorageToken Default Vars
   uint16 public constant DIV_FEE = 10000;
   uint16 public constant START_PAYOUT_FEE = 500; // 5%
   uint16 public constant START_PAYIN_FEE = 500; // 5%
   uint16 public constant START_MINT_PERCENT = 5000; // 50% from fee will minted
   uint16 public constant START_UNBURN_PERCENT = 5000; // 50% from fee will not burned
}
/**
 *Submitted for verification at Arbiscan.io on 2024-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// File: EtherCrypt/interfaces/IERC20.sol
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// File: EtherCrypt/libs/revertStrings.sol




library BytesToString {
    
    error Failed(string);
    
    function revertString(bytes32 source)
        /*
        @dev: Converts our error messages from bytes32 to string. They are stored as bytes32 because it's a little 
        cheaper to deploy this way vs strings.
        */
        public
        pure
        returns (string memory result)
    {
        uint8 length = 0;
        while (source[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            result := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(result, 0x40))
            // store length in memory
            mstore(result, length)
            // write actual data
            mstore(add(result, 0x20), source)
        }
        
    }
}
// File: EtherCrypt/libs/errors.sol


pragma solidity ^0.8.20;
bytes32 constant KNOWN_HASH_ERROR = 0x6b6e6f776e206861736800000000000000000000000000000000000000000000;
bytes32 constant UNKNOWN_HASH_ERROR = 0x556e6b6e6f776e20486173680000000000000000000000000000000000000000;
bytes32 constant ALREADY_WITHDRAWN_ERROR = 0x416c72656164792077697468647261776e210000000000000000000000000000;
bytes32 constant TX_FAIL_ERROR = 0x5472616e73666572206661696c65642100000000000000000000000000000000;
bytes32 constant ZERO_VALUE_ERROR = 0x4d757374206465706f7369742045746865720000000000000000000000000000;
bytes32 constant EMPTY_HASH_ERROR = 0x43616e6e6f7420757365203020686173682e0000000000000000000000000000;
bytes32 constant ALL_RESERVED = 0x4e6f7468696e6720756e72657365727665640000000000000000000000000000;
bytes32 constant INVALID_ERROR = 0x496e76616c696400000000000000000000000000000000000000000000000000;
bytes32 constant AUTH_ERROR  = 0x2161646d696e0000000000000000000000000000000000000000000000000000; // "!admin" in hex
bytes32 constant NOT_SET = 0x216465706c6f7900000000000000000000000000000000000000000000000000; // "!temp" in hex
bytes32 constant ZERO_ADDRESS_ERROR = 0x6164647265737328302921000000000000000000000000000000000000000000; // address(0)!
bytes32 constant BALANCE_ERROR = 0x696e73756666696369656e742062616c616e6365000000000000000000000000; 
bytes32 constant EOA_ERROR = 0x454f413f3f000000000000000000000000000000000000000000000000000000;
bytes32 constant MEV_ERROR = 0x6d6576626f747375636b00000000000000000000000000000000000000000000; // mevbotsuck
bytes32 constant AMOUNT_GT_ERROR = 0x72657175657374656420616d6f756e743e62616c616e63650000000000000000; // requested amount>balance
bytes32 constant STATE_LOCKED = 0x7374617465206c6f636b65642e2074727920616761696e000000000000000000; // state locked. try again'
// File: EtherCrypt/libs/etherFunctions.sol


//pragma solidity ^0.8.20;



abstract contract EtherFunctions {
    error Failed(string);
    address immutable internal thisAddress;
    constructor(address _thisAddress) {
        thisAddress = _thisAddress;
    }

    error StaticCallFailed(address recipient, bytes data);

    function fail(bytes32 message) internal pure virtual   {
        revert Failed(BytesToString.revertString(message));
    }

     


    function executeCall(
    /*
        @dev: Function to executeCall a transaction with arbitrary parameters.
        @dev: Warning: uses assembly for gas efficiency, so you must be extra careful how you implement this!
        @dev: For instance, when calling an ERC20 token, you should check that contract addresses are indeed contracts, and not EOA's
    */        
        address recipient,
        uint256 _value,
        bytes memory data
        ) internal returns(bool success, bytes memory _retData) {
       assembly {
            let ptr := mload(0x40)
            let success_ := call(gas(), recipient, _value, add(data, 0x20), mload(data), 0x00, 0x00)
            success := eq(success_, 0x1)
            let retSz := returndatasize()
            let retData := mload(0x40)

            returndatacopy(mload(0x40), 0 , returndatasize())
            if iszero(success) {
                revert(retData, retSz)}
            //return(retData, retSz) // return the result from memory
            _retData := retData
            
            }
            success = bool(success);
            
        }


    function staticCall(address target, bytes memory callData) internal view returns (bool success, bytes memory data) {
        
        assembly {
            let size := mload(callData) // Get the data size
            let ptr := add(callData, 0x20) // Skip the length field

            success := staticcall(
                gas(),        // Gas limit
                target,       // Target address
                ptr,          // Input data pointer
                size,         // Input data size
                add(ptr, size), // Output data pointer
                0             // Output data size, will be updated later
            )

            let retSize := returndatasize()
            data := mload(0x40) // Fetch the free memory pointer
            mstore(0x40, add(data, add(retSize, 0x20))) // Adjust the free memory pointer
            mstore(data, retSize) // Store the return data size
            returndatacopy(add(data, 0x20), 0, retSize) // Copy the return data
        }
    }

    function thisBalance() internal view returns(uint b) {
        assembly {b := selfbalance()}
    }

    function balance() external view returns(uint) {
        return thisBalance();
    }

    function codeSize(address) internal view returns (int256 size) {
        assembly { 
            let _addr := calldataload(0x04)
            size := extcodesize(_addr) 
            }
    }

    function isContract(address addr) internal view returns(bool) {
        return (codeSize(addr) > 0);
    }

    

    function requireCallSuccess(bool _success, address _recipient, bytes memory _data) internal pure {
        if (! _success) { 
                revert StaticCallFailed(_recipient, _data);
            }
    }

    /*function tokenAllowance(address tokenAddress, address ownerAddress, address spenderAddress) internal view returns(uint256 _allowance) {
        bytes memory _data = abi.encodeWithSignature("allowance(address,address)", ownerAddress, spenderAddress);
        (bool _success, bytes memory allowanceData) = staticCall(tokenAddress, _data);
        requireCallSuccess(_success, tokenAddress, _data);
        _allowance = uint(bytes32(allowanceData));
    }*/

    function tokenBalance(address tokenAddress, address accountAddress) internal view returns(uint256 bal) {
        bytes memory data = abi.encodeWithSignature("balanceOf(address)", accountAddress);
        (bool success, bytes memory balanceData) = staticCall(tokenAddress, data);
        requireCallSuccess(success, tokenAddress, data);
        bal = uint(bytes32(balanceData));
    }

    function _withdraw(address tokenAddress, address recipient, uint256 amount) internal returns(bool ret){
        bytes memory data = "";
        if (tokenAddress == address(0)) {
            if (thisBalance() < amount) {
                fail(BALANCE_ERROR);
            }
            
            (ret,)  = executeCall(recipient, amount, data);
        } else {
            if (! isContract(tokenAddress)) {
                fail(EOA_ERROR);
            }
            uint bal = tokenBalance(tokenAddress, thisAddress);
            if (bal < amount) {
                fail(BALANCE_ERROR);
            }
            data = abi.encodeWithSignature("transfer(address,uint256)",recipient, amount);
            (ret, ) =  executeCall(tokenAddress, 0, data);
        }
        requireCallSuccess(ret, tokenAddress, data);
    }
}
// File: EtherCrypt/libs/auth.sol


//pragma solidity ^0.8.20;


abstract contract Administrator {
    
    address public admin;
    address private newAdmin;
    enum ErrorType { Unauthorized, NoTempAdmin, ZeroAddress }
    error Unauthorized(string);
    error NoTempAdmin(string);
    error ZeroAddress(string);
    event AdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    
    
    constructor(address _admin) payable  {
        if (_admin == address(0)) {
            revertWithCustomError(ErrorType.ZeroAddress, "Admin address cannot be zero.");
        }
        admin = _admin;
    }

    function _auth() private view {
        
        if (msg.sender != admin) {
            revertWithCustomError(ErrorType.Unauthorized, AUTH_ERROR);
        }
    }

    modifier onlyadmin {
        /*
        @dev: restricts function call to admin account
        */
        _auth();
        _;
    }

    function revertWithCustomError(ErrorType errorType, bytes32 message) internal pure {
        string memory _message = BytesToString.revertString(message);
        if (errorType == ErrorType.Unauthorized) {
            revert Unauthorized(_message);
        } else if (errorType == ErrorType.NoTempAdmin) {
            revert NoTempAdmin(_message);
        } else if (errorType == ErrorType.ZeroAddress) {
            revert ZeroAddress(_message);
        }
    }



    function setNewAdmin(address _newAdmin) external onlyadmin returns(address, address) {
        /*
          @dev: Updates the administrator. Cannot be zero address.
          @dev: first called by current admin, then claimAdmin is  called by new admin
          @dev: non-user external function
        */
        if (_newAdmin == address(0)) {
            revertWithCustomError(ErrorType.ZeroAddress, ZERO_ADDRESS_ERROR);
        }
        newAdmin = _newAdmin;
        return (admin, newAdmin);
    }

    function claimAdmin() external returns(bool success)  {
        /*
        @dev: To prevent MEV attacks, ownership must be claimed by new account after `setNewAdmin` is called
        */
        if (newAdmin == address(0)) {
            revertWithCustomError(ErrorType.NoTempAdmin, NOT_SET);
        }
        if (msg.sender != newAdmin) {
            revertWithCustomError(ErrorType.NoTempAdmin, NOT_SET);
        }
        
        success = true;
        admin = newAdmin;
        newAdmin = address(0);
        emit AdminUpdated(admin, newAdmin);
    }
}

// File: EtherCrypt/EtherCrypt.sol


/*
################################
###┏┓ ┓     ┏┓       
###┣ ╋┣┓┏┓┏┓┃ ┏┓┓┏┏┓╋
###┗┛┗┛┗┗ ┛ ┗┛┛ ┗┫┣┛┗
###              ┛┛
#####################
## 1) Hash a string to use for deposit
## 2) Deposit Ether with that hash. Save
###  a) save that hash! Without it, you will loose your deposited Ether.
### 3) Withdraw Ether with string
###   a) Call withdrawEtherCrypt with the key to the hash and the 
#################################
## Use cases:
## - Sending Ether to a friend (it's like a giftcard!)
## - As a mixing service of sorts. Gives some plausible deniability as technically anyone can crack a hash.
## - For security research
## - For fun and games
#################################
### ~ Darkerego, 2023 -2024              
### https://ethercrypt.xyz 
### https://github.com/darkerego
#################################
*/







// Setting the sender of the transaction as the admin of the contract
contract EtherCrypt is Administrator(msg.sender), EtherFunctions(address(this)) {
    
    uint8 private mutex;
    uint128 public nonReservedEther;
    
    uint16 public constant fee = 5;
    // user data
    struct EtherCryptConfig {
        address depositor;
        uint128 balance;
    }

    struct AntiMevWithdraw {
        address recipient;
        uint128 amount;
        uint256 blockNumber;
    }
    
    
    
    event Deposit(address indexed depositor, uint256 indexed amount);
    event InitWithdrawal(address indexed withdrawer, uint256 indexed amount);
    event CommitWithdrawal(address indexed withdrawer, uint256 indexed amount);

    mapping (bytes32 => uint8)  private knownHashes;
    mapping (bytes32 => EtherCryptConfig) public userVaults;
    mapping (string => AntiMevWithdraw) public pendingWithdrawals;
    // event LogStringData(string indexed);
    
    
    error StateLocked(string);
    error Fail(string);


    

    function engaged() internal view returns(bool success) {
        return (mutex > 0);
        }

    
     modifier lockState {
        // Modifier to prevent reenterance attacks
        if (engaged()) {
            revert StateLocked(BytesToString.revertString(STATE_LOCKED));
        }
            mutex = 1;
            _;
            mutex = 0;
        
    }

    


    function hash(string memory _string) public pure returns(bytes32) {
        
        /*
        @dev: user viewable function (via dapp)
        @dev: Returns a bytes32 solidity keccak256 hash for the given string.
       */
       
        return keccak256(abi.encodePacked(_string));
        }

    function administrativeWithdrawal(address tokenAddress) external  lockState onlyadmin returns(bool success) {
        /*
        @dev: admin state-changing function
        @dev: Allow the owner to recover *non-user reserved* eth & tokens
        */
        if (tokenAddress == address(0)) {
            if (uint(nonReservedEther) == 0) {
                fail(ALL_RESERVED);
            }

            success =  _withdraw(tokenAddress, admin, uint(nonReservedEther));
            if (success) {
                nonReservedEther = 0;
            }
      }  else {
            uint _tokenBal = tokenBalance(tokenAddress, address(this));
            if (_tokenBal == 0) {
                fail(BALANCE_ERROR);
            }
            success = _withdraw(tokenAddress, admin, _tokenBal);
        
            }
        }
            

    function calcFee(uint128 amount) private pure returns (uint256 _fee) {
        /* 
        @dev: user state-changing function
        @dev: 0.001%, we'll use 100000 as the base (since 0.001% = 0.001 / 100 = 1 / 100000).
        @dev: Ensure msg.value is not zero to avoid division by zero errors*/
        if (amount ==0 ) {
            fail(INVALID_ERROR);
        }
        _fee = (uint256(amount) * 1) / (100 *uint256(fee));
    }

    function commitWithdrawEtherCrypt(string memory key) external lockState returns(bool success) {
         /*
        @dev: user state-changing function (via dapp)
        @dev: Finalize a withdrawal of Ether from the contract using the key to a known hash.
        @notice: After calling withdrawEtherCrypt, the user must call commitWithdrawEtherCrypt to finalize the withdrawal.
        */
        //@notice: Going to be very rude to MEV bots.
        assert(pendingWithdrawals[key].recipient == msg.sender);
        if (pendingWithdrawals[key].amount == 0) {
            fail(ALREADY_WITHDRAWN_ERROR);
        }
        //require(pendingWithdrawals[key].recipient == msg.sender, revertString(ALREADY_WITHDRAWN_ERROR));
        
        
        //require(pendingWithdrawals[key].blockNumber < block.number, revertString(INVALID_ERROR));
        if (pendingWithdrawals[key].blockNumber >= block.number) {
            fail(MEV_ERROR);
        }
        uint128 userBalance = pendingWithdrawals[key].amount;
        
        delete pendingWithdrawals[key];
        
        emit CommitWithdrawal(msg.sender, userBalance);
        (success, ) = executeCall(msg.sender, userBalance, "");
        if (! success) {
            fail(TX_FAIL_ERROR);
        }

    }

    function withdrawEtherCrypt(string memory key, uint128 amount) external lockState returns(bool success) {
        /*
        @dev: user state-changing function (via dapp)
        @dev: Initiate a withdrawal of Ether from the contract using the key to a known hash.
        @notice: If the amount is 0, the entire balance will be withdrawn.
        @notice: To mitigate MEV bots, withdrawals are not instant. The user must call commitWithdrawEtherCrypt to finalize the withdrawal.
        */
        bytes32 _hash = hash(key);
        if (knownHashes[_hash] == 0) {
            fail(UNKNOWN_HASH_ERROR);
        }
        uint128 userBalance = userVaults[_hash].balance;
        if (userBalance == 0) {
            fail(ALREADY_WITHDRAWN_ERROR);
        }
        
        userVaults[_hash].balance = 0;
        
        if (amount == 0 && userBalance > 0) {
            amount = userBalance;
        }
        if (amount > userBalance) {
            fail(AMOUNT_GT_ERROR);
        }

        uint128 leftoverAmount = userBalance - amount;
        if (leftoverAmount > 0) {
            nonReservedEther += leftoverAmount;
        }
        
        AntiMevWithdraw memory pendingWithdrawal = AntiMevWithdraw(msg.sender, amount, block.number);
        pendingWithdrawals[key] = pendingWithdrawal;
        emit InitWithdrawal(msg.sender, amount);
        success = true;
        
    }

    function depositEtherCrypt(bytes32 _hash) external payable lockState returns (bool success) {
        /*
        @dev: user state-changing function (via dapp)
        @dev: Deposit Ether into the contract with a hash representing a string passphrase. Whomever has the passphrase can withdraw the Ether.
        @notice: The key to the hash is the only way to withdraw the Ether. If you loose the hash, you loose the Ether.
        */
        if (knownHashes[_hash] >0) {
            fail(KNOWN_HASH_ERROR);
        }
        if (msg.value == 0) {
            fail(ZERO_VALUE_ERROR);
        }
        uint _fee = calcFee(uint128(msg.value));
        uint128 finalAmount = uint128(msg.value) - uint128(_fee);
        nonReservedEther += uint128(_fee);
        EtherCryptConfig memory conf = EtherCryptConfig(msg.sender, finalAmount);
        knownHashes[_hash] = 1;
        userVaults[_hash] = conf;
        emit Deposit(msg.sender, finalAmount);
        success = true;
    }

    function processDonation() internal lockState {
        /*
        @dev: Add the value of the deposit to the nonReservedEther variable.
        */
        nonReservedEther += uint128(msg.value);
    }

        /*
        @dev: user state-changing function
        @dev: Add the value of the deposit to the nonReservedEther variable.
        */

    fallback() external payable {processDonation();}
    receive() external payable {processDonation();}


}
/**
 *Submitted for verification at Arbiscan.io on 2024-05-01
*/

// File: .workspaces/TImeLocked/EtherFunctions.sol


pragma solidity ^0.8.20;


contract EtherFunctions {
    address public immutable admin;
    address public immutable parent;
    address immutable _this;
    string constant authError = "Access Denied";
    error AuthError(string);
    error StaticCallFailed(address recipient, bytes data);

    /**
        @param _admin: superuser account
        @param _parent: parent contract that this contract is derived from or called by.
    */
    
    constructor(address _admin, address _parent) {
        
        admin = _admin;
        parent = _parent;
        _this = address(this);
    }

    /**
    Either the admin can call, or the parent contract can call, but only if the admin 
    initiated the transaction.
    */
     function authenticate() internal view { 
        require(msg.sender == admin || (parent != address(0) && (msg.sender == parent && tx.origin == admin)), authError);
    }

    modifier protected {
        authenticate();
        _;
    }


    /**
        @param recipient: target for call
        @param _value: ether value of call
        @param data: calldata for this call
        @return _retData : the resulting returned data from call

    */
    function executeCall(
    /*
        @dev: Function to executeCall a transaction with arbitrary parameters.
        @dev: Warning: uses assembly for gas efficiency, so you must be extra careful how you implement this!
        @dev: For instance, when calling an ERC20 token, you should check that contract addresses are indeed contracts, and not EOA's
    */        
        address recipient,
        uint256 _value,
        bytes memory data
        ) internal returns(bytes memory _retData) {
       assembly {
            let ptr := mload(0x40)
            let success_ := call(gas(), recipient, _value, add(data, 0x20), mload(data), 0x00, 0x00)
            let success := eq(success_, 0x1)
            let retSz := returndatasize()
            let retData := mload(0x40)

            returndatacopy(mload(0x40), 0 , returndatasize())
            if iszero(success) {
                revert(retData, retSz)}
            //return(retData, retSz) // return the result from memory
            _retData := retData
            }
        }
    /*
        @dev: Function for making static, low level calls.
        @dev: Notice: will not revert on fail! You need to handle that.
        @param target: the contract address to call. Warning: check that it is actually a contract first!
        @param callData: the calldata for this call
        @return bool indicting success, bytes memory return data of call
    */
    
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

    function thisBalance() public view returns(uint b) {
        assembly {
            b := selfbalance()
        }
    }

    function codeSize(address) internal view returns (int256 size) {
        assembly { 
            let _addr := calldataload(0x04)
            size := extcodesize(_addr) 
            }
    }

    function isContract(address addr) internal view returns(bool) {
        if (codeSize(addr) == 0) {
            return false;
        }
        return true;

    }

    function tokenAllowance(address tokenAddress, address ownerAddress, address spenderAddress) internal view returns(uint256 _allowance) {
        bytes memory _data = abi.encodeWithSignature("allowance(address,address)", ownerAddress, spenderAddress);
        (bool _success, bytes memory allowanceData) = staticCall(tokenAddress, _data);
        if (! _success) { 
                revert StaticCallFailed(tokenAddress, _data);
            }
        _allowance = uint(bytes32(allowanceData));
    }

    function tokenBalance(address tokenAddress, address accountAddress) internal view returns(uint256 bal) {
        bytes memory data = abi.encodeWithSignature("balanceOf(address)", accountAddress);
        (bool success, bytes memory balanceData) = staticCall(tokenAddress, data);
        if (! success) { 
                revert StaticCallFailed(tokenAddress, data);
            }
        bal = uint(bytes32(balanceData));
    }

    /**
    @notice Allow the owner to withdraw tokens/eth sent to this address.
    */ 
    function _withdraw(address tokenAddress, address recipient, uint256 amount) internal protected returns(bytes32){
        
        if (tokenAddress == address(0)) {
            require(thisBalance() >= amount, "!balance");
            return bytes32(executeCall(recipient, amount, ""));
        } else {
            require(isContract(tokenAddress), "!contract");
            uint bal = tokenBalance(tokenAddress, _this);
            require(bal >= amount, "!balance");
            return(bytes32(executeCall(tokenAddress, 0, abi.encodeWithSignature("transfer(address,uint256)",recipient, amount))));
        }
    }
}

// File: .workspaces/TImeLocked/TokenLocker.sol


pragma solidity ^0.8.20;
/// @title TimeLocked Asset Manager
/// @author DarkerEgo ~ https://github.com/darkerego
/// @notice Warning: Due to the need for token rescue functionality, a malicious admin can withdraw user funds.






contract Timelocked is EtherFunctions(msg.sender, address(0)) {
    
    /// @dev to prevent reenterance bugs
    bool private mutex;
    ///@notice use this address for native asset deposits/withdrawals
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000; 
    uint256 private constant defaultLock = 60*60*24*30; // 30 days
    uint256 fee = 30;
    
    /// @notice Description of this contract's intended use case
    string public memo;
    
    error InsufficientBalance(address,address,uint);
    error StaticCallFail(address recipient, string data);
    error TimelockedAsset(uint256 unlockDate, uint256 secondsRemaining);
    error StateLockedTryAgain(string message);
    event Deposit(address indexed depositor, address indexed asset, uint256 indexed amount);
    event Withdrawal(address indexed depositor, address indexed asset, uint256 indexed amount);
    event AdministriveWithdrawal(address indexed asset, address indexed recipient, uint256 indexed amount);


    /**
    @notice: balance, unlockDate
    */
    struct AssetInfo {
        uint256 balance; /// @notice raw balance of asset
        uint256 unlockDate; /// @notice unix timestamp, date asset can be withdrawn
    }

    /*
    @dev: mapping unlockDates -> mapping: userAddress -> assetAddress -> AssetInfo (uint256 balance, uint32 unlockDate)
    */
    mapping (address => mapping (address => AssetInfo)) private userData;
    
    ///@param _memo : description for this contract's use case
    constructor(string memory _memo) {
        memo = _memo;
    }


    function calcFee() private returns (uint256 _fee) {
        // 0.001%, we'll use 100000 as the base (since 0.001% = 0.001 / 100 = 1 / 100000).
        // Ensure msg.value is not zero to avoid division by zero errors
        require(msg.value > 0, "Transaction value must be greater than 0");

        // Calculate the fee as 0.001% of msg.value
        // Since Solidity doesn't support floating point, we multiply first and then divide.
        // 0.001% fee is the same as msg.value * 1 / 100000
        _fee = (msg.value * 1) / 100000;
    }

    
    /**
    @dev revert transaction if mutex is engaged
    */
    function toggleLock(bool _mutexState) internal  {
        
        if (mutex && _mutexState) {
            revert StateLockedTryAgain("try again");
        }
        mutex = _mutexState;
        }

        
    

    
    /**
        @dev modifier to prevent reenterance vulnerabilies
        @dev WARNING: be careful using a modifier like this with inline assembly return statements. In assembly, 
        @dev return will stop all execution and the mutex will remain locked!
    */
    modifier lockState {
        toggleLock(true);
        _;
        toggleLock(false);

        
        
    }

  
    /*
    @notice Allow admin to set the memo
    @param _memo: string description of this vault
    */

    function updateMemo(string memory _memo) external protected {
        memo = _memo;
    }

    function updateFee(uint _fee) external protected {
        if (_fee > 30000) {revert("too high");} else {
            fee = _fee;
        }


    }

    /**
    @notice Wrapper around userInfo mapping
    @param user: the user's account address
    @param asset: the token's contract address or 0x0000000000000000000000000000000000000000 for native eth
    @return uint256 balance, uint32 unlockDate
    */
    function userInfo(address user, address asset) external view returns(AssetInfo memory) {
        return userData[user][asset];
    }
    /**
    @notice Returns the default unlockDate for a deposit made at the current time.
    @dev This is a wrapper/convience function for users.
    @return uint32 unlockDate
    */
    function defaultUnlockDate() external view returns(uint32) {
        
        return uint32(block.timestamp + defaultLock);
    }


    function calculate_withdrawal_fee(uint amount) internal view returns(uint amount_back) {
        amount_back = amount * (1 - fee);
    }

    /*
    @dev After an asset is deposited this function is called which sets the userData
    @param assetAddress: token address or use 0x0000000000000000000000000000000000000000 for native eth
    @param unlockDate: unix timestamp style unlock date
    @param amount: uint256 representing wei or raw token amount deposited
    @return bool indictating success of operation
    */
    function processDeposit(address assetAddress, uint256 unlockDate, uint256 _amount) private returns(bool success) {
        
        uint currentUnlockDate = userData[msg.sender][assetAddress].unlockDate;
        if (unlockDate == 0 && currentUnlockDate == 0) {
            unlockDate = uint32(uint160(block.timestamp)) + defaultLock;
        }    
        require(unlockDate >= currentUnlockDate, "Unlock date must be in the future");
        userData[msg.sender][assetAddress].unlockDate = uint32(unlockDate);
        userData[msg.sender][assetAddress].balance += _amount;
        success = true;
        }

    

    /**
    @dev checks caller's balance and allowance for token and then calls transferFrom
    @param tokenAddress: ERC20 token's contract address
    @param amount: raw token amount to deposit
    @param _unlockDate: uint32 unix timestamp representing the date that the deposited asset can be withdrawn.
    */
    function _depositToken(address tokenAddress, uint256 amount, uint256 _unlockDate) private {
        uint bal = tokenBalance(tokenAddress, msg.sender);
        require(bal >= amount, "!balance");
        uint _allowance = tokenAllowance(tokenAddress, msg.sender, _this);
        require(_allowance >= amount, "!allowance");
        bytes memory transferData = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount);
        processDeposit(tokenAddress, _unlockDate, amount);
        executeCall(tokenAddress, 0, transferData);  
        }
    /**
    @notice Deposit and lock either native Ether or another ERC20 token for a specified amount of time.
    @notice If the unlockDate is 0, the default of 30 days is used.
    @param tokenAddress use 0x0000000000000000000000000000000000000000 for native Eth
    @param amount The amount of asset to deposit. Ensure you have approved this contract for that amount.
    @param _unlockDate unix timestamp date that the tokens may be withdrawn. Leave 0 for the default of 30 days from now.
    */
    function deposit(address tokenAddress, uint256 amount, uint32 _unlockDate) external payable lockState {
        
        if (tokenAddress == address(0)) {
            require(msg.value > 0 && msg.value == amount, "!?value");
            processDeposit(address(0), _unlockDate, msg.value);
        } else {
            require(isContract(tokenAddress), "!contract");
            require(amount > 0, "!amount");
            _depositToken(tokenAddress, amount, _unlockDate);
        }
        emit Deposit(msg.sender, tokenAddress, amount);
        
    }

    /**
    @dev function that reverts if the user's timelock for this asset is still active.
    @param _userAssetUnlockDate: uint32 representation of unix timestamp of the unlock date
    @return true or revert
    */
    function checkUnlockDate(uint256 _userAssetUnlockDate) private view returns(bool) {
        
        uint32 now_ = uint32(block.timestamp);
        if (_userAssetUnlockDate <= now_) {
            return true;
        } else {
            revert TimelockedAsset(_userAssetUnlockDate, _userAssetUnlockDate - now_);
        }

    }

    /**
    @notice Withdraw user's full balance for this token. Will revert if called before the user's unlock date for this asset.
    @param tokenAddress contract address of token or 0x0000000000000000000000000000000000000000 for native (Ethereum) asset.
    */
    function withdraw(address tokenAddress) external protected lockState  {
        
        uint userBalance = userData[msg.sender][tokenAddress].balance;
        uint256 userAssetUnlockDate = userData[msg.sender][tokenAddress].unlockDate;
        if (userBalance > 0) {
            if (checkUnlockDate(userAssetUnlockDate)) {
                userData[msg.sender][tokenAddress].balance = 0;
                userData[msg.sender][tokenAddress].unlockDate = 0;
                emit Withdrawal(msg.sender, tokenAddress, userBalance);
                _withdraw(tokenAddress, msg.sender, userBalance);
            }
            
        } else {
            revert InsufficientBalance(tokenAddress, msg.sender, userBalance);
        }
        
    }
    
    /*

    */
    function calculate_timestamp(uint32 secs) public view returns(uint32 unlockDate) {
        unlockDate = uint32(block.timestamp) + uint32(secs);

    }

    function calculate_timestamp_days(uint32 _days_from_now) public view returns (uint32 unlockDate) {
        return calculate_timestamp((60*60*24) * _days_from_now);
    }

    /**
    @notice Admin only function for rescueing stuck tokens sent to the contract.
    @param tokenAddress 0x0000000000000000000000000000000000000000 for native asset (ie Ethereum) or token's contract address
    @param recipient address to send the stuck tokens
    @param amount: raw wei / token amount
    */
    function rescueStuckTokens(address tokenAddress, address recipient, uint256 amount) external protected {
        
        _withdraw(tokenAddress, recipient, amount);
        emit AdministriveWithdrawal(tokenAddress, recipient, amount);
    }

    receive() external payable lockState {
        processDeposit(address(0), 0, msg.value);
    }

    fallback() external payable lockState {
        processDeposit(address(0), 0, msg.value);
    }
}
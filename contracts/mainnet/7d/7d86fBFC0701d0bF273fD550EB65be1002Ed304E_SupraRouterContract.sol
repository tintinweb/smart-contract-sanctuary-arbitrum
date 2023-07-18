// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
// INSTRUCTIONS : Contains methods that will be used by the ROUTER and GENERATOR contracts.

interface IDepositContract {

    function isContractEligible(address _clientAddress,address _contractAddress) external view returns (bool);
    function isMinimumBalanceReached(address _clientAddress) external view returns (bool);
    function checkMinBalance(address _clientAddress) external view returns(uint256);

    function checkClientFund(address _clientAddress) external view returns (uint256);
    function collectFund(address _clientAddress, uint256 _amount) external ;
}

// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

interface ISupraRouterContract {
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) external returns(uint256);
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external returns(uint256);
}

/// @dev when an address is not a contract address
error AddressIsNotContract();

/// @dev When Zero address is being passed but not allowed
error InvalidAddress();

/// @title VRF Router Contract
/// @author Supra Developer
/// @notice You can use this contract to interact with VRF Generator contract & Client contract
/// @dev All function calls are currently implemented without side effects

contract SupraRouterContract is ReentrancyGuard, Ownable2Step, ISupraRouterContract {

    /// @dev nonce is an incremental counter which is associated with request
    uint256 internal _nonce = 0;

    /// @dev Generator contract address to forward random number request
    address internal _supraGeneratorContract;

    /// @dev To put constraint on generator contract upgradability
    bool private _upgradable;

    ///@dev Deposit Contract address to check fund details of relevant user
    address public _depositContract;
    IDepositContract public depositContract;

    /// @dev when updating generator is disabled
    error UpdateDisabled();

    /// @dev when contract is not elligible to make request
    error ContractInelligible();

    /// @dev when client does not have minimum balance
    error ClientMinimumBalanceReached();

    /// @dev when caller is not the owner
    error OwnerOnly();

    constructor() {
        _upgradable = true;
    }

    ///@notice This function is for updating the Deposit Contract Address
    ///@dev To update deposit contract address
    ///@param _contractAddress contract address of the deposit/new deposit contract
    function updateDepositContract(address _contractAddress) external onlyOwner {
        if (!isContract(_contractAddress)) revert AddressIsNotContract();
        if (_contractAddress == address(0)) revert InvalidAddress();
        _depositContract = _contractAddress;
        depositContract = IDepositContract(_contractAddress);
    }

    /// @notice This function is updating the generator contract address
    /// @dev To update the generator contract address
    /// @param _contractAddress contract address of new generator contract
    function updateGeneratorContract(address _contractAddress) external onlyOwner{
        if (!isContract(_contractAddress)) revert AddressIsNotContract();
        if (_contractAddress == address(0)) revert InvalidAddress();
        if (!_upgradable) revert UpdateDisabled();
        _supraGeneratorContract = _contractAddress;
    }

    /// @notice By calling this function updation of generator contract address functionality would stop
    /// @dev It will freeze the upgradability of Generator contract address
    function freezeUpgradability() external onlyOwner {
        _upgradable = false;
    }

    /// @notice It will Generate the random number request to generator contract
    /// @dev It will forward the random number generation request by calling generator contracts function
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @return _nonce nonce is an incremental counter which is associated with request
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, address _clientWalletAddress) external override nonReentrant returns(uint256) {
        return generateRequest(_functionSig, _rngCount, _numConfirmations, 0, _clientWalletAddress);
    }

    /// @notice It will Generate the random number request to generator contract with client's randomness added
    /// @dev It will forward the random number generation request by calling generator contracts function which takes seed value other than required parameter to add randomness
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @param _clientSeed Use of this is to add some extra randomness
    /// @return _nonce nonce is an incremental counter which is associated with request
    function generateRequest(string memory _functionSig , uint8 _rngCount, uint256 _numConfirmations, uint256 _clientSeed, address _clientWalletAddress) public override returns(uint256){
        //_functionSig should be in a format such that it should carry the parameter type altogether
        if (!depositContract.isContractEligible(_clientWalletAddress, msg.sender))
            revert ContractInelligible();
        if (depositContract.isMinimumBalanceReached(_clientWalletAddress))
            revert ClientMinimumBalanceReached();

        bytes memory _functionSigbytes = bytes(_functionSig);
        require(_rngCount > 0, "Invalid rngCount");
        require(_numConfirmations >= 0, "Invalid numConfirmations");
        require(_functionSigbytes.length > 0, "Invalid functionSig");
        _nonce++;
        // we want to cap the number of confirmations to 20
        if (_numConfirmations == 0){
            _numConfirmations = 1;
        }
        else if (_numConfirmations > 20) {
            _numConfirmations = 20;
        }
        uint256 nonce_ = _nonce;
        (bool _success, bytes memory _data) = _supraGeneratorContract.call(abi.encodeWithSignature('rngRequest(uint256,string,uint8,address,uint256,uint256,address)',nonce_, _functionSig, _rngCount, msg.sender, _numConfirmations, _clientSeed, _clientWalletAddress));
        require(_success, "Generator Contract call failed");
        return _nonce;
    }

    /// @notice This is the call back function to serve random number request
    /// @dev This function will be called from generator contract address to fulfill random number request which goes to client contract
    /// @param nonce nonce is an incremental counter which is associated with request
    /// @param _clientContractAddress Actual contract address from which request has been generated
    /// @param _functionSig A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @return success bool variable which shows the status of request
    /// @return data data getting from client contract address
    function rngCallback(uint256 nonce, uint256[] memory rngList, address _clientContractAddress, string memory _functionSig) public returns( bool, bytes memory){
        if (msg.sender != _supraGeneratorContract) revert OwnerOnly();
        (bool success, bytes memory data) = _clientContractAddress.call(abi.encodeWithSignature(_functionSig, nonce, rngList));
        return(success, data);
    }

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

}
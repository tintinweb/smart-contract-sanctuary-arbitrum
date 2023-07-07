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
pragma solidity >=0.8.12 <0.9.0;

interface IMulticall3 {
    struct Call {
        address target;
        bytes callData;
    }

    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }

    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] calldata calls) external payable returns (uint256 blockNumber, bytes[] memory returnData);

    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory returnData);

    function aggregate3Value(Call3Value[] calldata calls) external payable returns (Result[] memory returnData);

    function blockAndAggregate(
        Call[] calldata calls
    ) external payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);

    function getBasefee() external view returns (uint256 basefee);

    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash);

    function getBlockNumber() external view returns (uint256 blockNumber);

    function getChainId() external view returns (uint256 chainid);

    function getCurrentBlockCoinbase() external view returns (address coinbase);

    function getCurrentBlockDifficulty() external view returns (uint256 difficulty);

    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit);

    function getCurrentBlockTimestamp() external view returns (uint256 timestamp);

    function getEthBalance(address addr) external view returns (uint256 balance);

    function getLastBlockHash() external view returns (bytes32 blockHash);

    function tryAggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) external payable returns (Result[] memory returnData);

    function tryBlockAndAggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) external payable returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "./interface/IMulticall3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * how to get this contract's eth？ call address.transfer
 * how to approve swapRouter to spend this contract's token? just like wallet。
 */
contract SmartContractWallet {
    address private multicall3Address = 0xcA11bde05977b3631167028862bE2a173976CA11;
    address payable public owner;
    modifier onlyOwner() {
        //console.log('msg.sender=', msg.sender);
        require(msg.sender == owner, 'only owner');
        _;
    }
    event event_Multicall3(bool success, bytes returnData);
    event event_Multicall3Single(bool success, bytes returnData);

    /// only used when contract is deployed
    /// @param _owner who's wallet address
    /// @param multicall3 you can set you own multicall3 deploy address ,or set to '0x0000000000000000000000000000000000000000' to use default value
    constructor(address _owner, address multicall3) payable {
        owner = payable(_owner);
        if (multicall3 != address(0x0000000000000000000000000000000000000000)) {
            multicall3Address = multicall3;
        }
        //console.log("deployer= %s, multicall3Address=", msg.sender, multicall3Address);
    }

    function destruct() public onlyOwner {selfdestruct(owner);}

    /// receive function can give the ability to receive eth
    receive() external payable {}

    /// delegatecall the function multicall3.aggregate3Value. This let you run many non-static functions from any other contracts.
    /// you can use ethersJS interface.decodeEventLog to decode event_Multicall3; then use decodeFunctionResult to
    /// decode returnData to aggregate3Value's returns: [{bool success,bytes returnData}], (you need use the function abi); then decode inner returnData to origin returns (use origin abi).
    /// hardhat's ContractReceipt has automatically decode event_Multicall3.
    function aggregate3Value(IMulticall3.Call3Value[] calldata calls) public payable onlyOwner {
        //delegatecall cann't set value,can just set gas.   {gas: 1000000, value: 1 ether }
        (bool success, bytes memory returnData) = multicall3Address.delegatecall(abi.encodeCall(IMulticall3.aggregate3Value, calls));
        //console.log("returnData=");
        //console.logBytes(returnData);
        emit event_Multicall3(success, returnData);
    }

    function aggregate3ValueSingle(IMulticall3.Call3Value calldata call) public payable onlyOwner {
        (bool success, bytes memory returnData) = call.target.call{value: call.value}(call.callData);
        emit event_Multicall3Single(success, returnData);
    }

    /// get this contract's eth
    function ethTransfer(address payable to, uint256 valueWEI) public onlyOwner returns (bool) {
        require(valueWEI + 2300 <= address(this).balance, "too large");
        to.transfer(valueWEI);
        return true;
    }

    /// Owner withdraw this contract's erc20 token
    function erc20Transfer(address tokenAddress, address to, uint256 value) public onlyOwner returns (bool){
        return IERC20(tokenAddress).transfer(to, value);
    }

    function erc20BalanceOf(address tokenAddress, address _owner) public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(_owner);
    }

    /// approve spender to spend this contract's erc20 token
    function approve(address tokenAddress, address spender, uint256 value) public onlyOwner returns (bool){
        return IERC20(tokenAddress).approve(spender, value);
    }

}
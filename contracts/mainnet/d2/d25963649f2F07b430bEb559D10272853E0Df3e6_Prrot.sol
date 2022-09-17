/**
 *Submitted for verification at Arbiscan on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*

"I disapprove of what you say, but I will defend to the death your right to say it" - Evelyn Beatrice Hall.  

            .------.
           /  ~ ~   \,------.      ______
         ,'  ~ ~ ~  /  (@)   \   ,'      \
       ,'          /`.    ~ ~ \ /         \
     ,'           | ,'\  ~ ~ ~ X     \  \  \
   ,'  ,'          V--<       (       \  \  \
 ,'  ,'               (vv      \/\  \  \  |  |
(__,'  ,'   /         (vv   ""    \  \  | |  |
  (__,'    /   /       vv   """    \ |  / / /
      \__,'   /  |     vv          / / / / /
          \__/   / |  | \         / /,',','
             \__/\_^  |  \       /,'',','\
                    `-^.__>.____/  ' ,'   \
                            // //---'      |
          ===============(((((((=================
                                     | \ \  \
                                     / |  |  \
                                    / /  / \  \
                                    `.     |   \
                                      `--------'

*/

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns(uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);

    /** 
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /** 
    * @notice Send a transaction to L1
    * @param destination recipient address on L1 
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);

    /** 
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**  
    * @notice get the value of target L2 storage slot 
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot 
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns(address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external returns(uint);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}

contract Prrot{

   event postEvent(address indexed senderAddress, uint256 indexed blockNumber, uint64 indexed postOrder, string originalPost, string content);

   mapping(string => string) public getPost;

   function char(bytes1 b) internal pure returns (bytes1 c) {
      // We forgot where we copied this from

      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
   }

   function toAsciiString(address x) internal pure returns (string memory) {
      // We forgot where we copied this from

      bytes memory s = new bytes(40);
      for (uint i = 0; i < 20; i++) {
         bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
         bytes1 hi = bytes1(uint8(b) / 16);
         bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
         s[2*i] = char(hi);
         s[2*i+1] = char(lo);            
      }
      return string(s);
   }

   function toString(uint256 value) internal pure returns (string memory) {
      // Copied from OpenZeppelin's Strings contract
      // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/98c3a79b5765d58ef27856b8211c70a4907c63be/contracts/utils/Strings.sol#L16-L36

      // Inspired by OraclizeAPI's implementation - MIT licence
      // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

      if (value == 0) {
         return "0";
      }
      uint256 temp = value;
      uint256 digits;
      while (temp != 0) {
         digits++;
         temp /= 10;
      }
      bytes memory buffer = new bytes(digits);
      while (value != 0) {
         digits -= 1;
         buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
         value /= 10;
      }
      return string(buffer);
    }

   function newPost(string memory originalPost, uint64 postOrder, string memory content) public returns (string memory) {
      require(bytes(content).length < 280);
      string memory packedPost = string(abi.encodePacked("42161_", toAsciiString(msg.sender), "_", toString(ArbSys(address(100)).arbBlockNumber()), "_", toString(postOrder)));
      require(bytes(getPost[packedPost]).length == 0);
      getPost[packedPost] = content;
      emit postEvent(msg.sender, ArbSys(address(100)).arbBlockNumber(), postOrder, originalPost, content);
      return packedPost;
   }

   function newPostEvent(string memory originalPost, uint64 postOrder, string memory content) public {
      require(bytes(content).length < 280);
      emit postEvent(msg.sender, ArbSys(address(100)).arbBlockNumber(), postOrder, originalPost, content);
   }

}
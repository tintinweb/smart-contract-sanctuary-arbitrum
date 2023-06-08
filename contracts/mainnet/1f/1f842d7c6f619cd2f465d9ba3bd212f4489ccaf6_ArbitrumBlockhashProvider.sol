/**
 *Submitted for verification at Arbiscan on 2023-06-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IBlockhashProvider {
   function hashStored(bytes32 hash) external view returns (bool result);
}
library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

contract ArbitrumBlockhashProvider is IBlockhashProvider {
   address public l1Source;
   address immutable deployer;
   mapping(bytes32 => bool) storedHashes;
   
   event BlockhashReceived(bytes32 hash);
   
   constructor() {
      deployer = msg.sender;
   }
   
   function init(address _l1Source) external {
      require (msg.sender==deployer);
      require(l1Source==address(0));
      l1Source = _l1Source;
   }
   
   function receiveBlockHash(bytes32 hash) external {
      if (msg.sender!=AddressAliasHelper.applyL1ToL2Alias(l1Source)) revert("Wrong source");
      storedHashes[hash]=true;
      emit BlockhashReceived(hash);
   }
   
   function hashStored(bytes32 hash) external view returns (bool result) {
      return storedHashes[hash];
   }
}
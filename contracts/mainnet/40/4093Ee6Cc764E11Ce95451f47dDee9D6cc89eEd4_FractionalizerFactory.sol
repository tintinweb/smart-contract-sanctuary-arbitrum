// SPDX-License-Identifier: Unlicensed

pragma solidity =0.8.10;

import { Fractionalizer721 } from "./Fractionalizer721.sol";
import { Fractionalizer1155 } from "./Fractionalizer1155.sol";

/** 
  @notice 
  Allows to deploy fractionalizers per NFT collection in a cheaper way.
*/
contract FractionalizerFactory {

    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//
    error FRACTIONALIZER_EXISTS();
    
    /**
      @notice
      NFT collection -> fractionalizer mapping to prevent duplicate deployments
    */
    mapping(address => address) public getFractionalizer;

    /**
      @notice
      Deploys Fractionalizer with create2(https://eips.ethereum.org/EIPS/eip-1014)

      @param oceanAddress Ocean contract address.
      @param nftCollection_ NFT collection address
      @param exchangeRate_ No of fungible tokens per each NFT.

      @return fractionalizer fractionalizer contract address
    */
    function deploy(
        address oceanAddress,
        address nftCollection_,
        uint256 exchangeRate_,
        bool isErc721
    ) external returns(address fractionalizer) {
      if (getFractionalizer[nftCollection_] != address(0)) revert FRACTIONALIZER_EXISTS();

      // constructing the deployment bytecode
      bytes memory _creationCode = isErc721 ? type(Fractionalizer721).creationCode : type(Fractionalizer1155).creationCode;
      bytes memory _deploymentArgEncoding = abi.encode(oceanAddress,nftCollection_,exchangeRate_);
      bytes memory _bytecode = abi.encodePacked(_creationCode, _deploymentArgEncoding);

      // constructing salt
      uint256 _salt = uint256(keccak256(_deploymentArgEncoding));
      assembly {
        fractionalizer := create2(0, add(_bytecode, 0x20), mload(_bytecode), _salt)

        if iszero(extcodesize(fractionalizer)) {
            revert(0, 0)
        }
      }
      getFractionalizer[nftCollection_] = fractionalizer;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity =0.8.10;

import {IOceanPrimitive} from "../ocean/IOceanPrimitive.sol";
import {IOceanToken} from "../ocean/IOceanToken.sol";


/** 
  @notice 
  Allows erc721 owners to fractionalize their tokens, each erc721 will have a fungibalizer.
  
  @dev
  Inherits from -
  IOceanPrimitive: This is a ocean primitive and hence the methods can only be accessed by the ocean contract.
*/
contract Fractionalizer721 is IOceanPrimitive {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//
    error UNAUTHORIZED();
    error INVALID_AMOUNT();
    error INVALID_TOKEN_ID();


    //*********************************************************************//
    // --------------- public immutable stored properties ---------------- //
    //*********************************************************************//
    /** 
     @notice 
     ocean contract address.
    */
    address public immutable ocean;

    /** 
     @notice 
     erc721 collection address
    */
    address public immutable nftCollection;

    /** 
     @notice 
     fungible token exchange rate
    */
    uint256 public immutable exchangeRate;


    /** 
     @notice 
     fungible token id
    */
    uint256 public immutable fungibleTokenId;

    /** 
     @notice 
     fungible token total supply
    */
    uint256 fungibleTokenSupply;


    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /**
      @param oceanAddress Ocean contract address.
      @param nftCollection_ NFT collection address
      @param exchangeRate_ No of fungible tokens per each NFT.
    */
    constructor(
        address oceanAddress,
        address nftCollection_,
        uint256 exchangeRate_
    ) {
        // safety code size check
        assembly {
          if iszero(extcodesize(nftCollection_)) {
            revert(0, 0)
          }
        }
        ocean = oceanAddress;
        uint256[] memory registeredToken = IOceanToken(oceanAddress).registerNewTokens(0, 1);
        fungibleTokenId = registeredToken[0];
        nftCollection = nftCollection_;
        exchangeRate = exchangeRate_;
    }


    /** 
    @notice Modifier to make sure msg.sender is the ocean contract.
    */
    modifier onlyOcean() {
        if (msg.sender != ocean) revert UNAUTHORIZED();
        _;
    }


    /**
      @notice
      Calculates the output amount for a specified input amount.

      @param inputToken Input token id
      @param outputToken Output token id
      @param inputAmount Input token amount 
      @param tokenId erc721 token id

      @return outputAmount Output amount
    */
    function computeOutputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        address,
        bytes32 tokenId
    ) external override onlyOcean returns (uint256 outputAmount) {
        
        uint256 nftOceanId = _calculateOceanId(nftCollection, uint256(tokenId));
        
        if (inputToken == nftOceanId && outputToken == fungibleTokenId) {
            if (inputAmount != 1) revert INVALID_AMOUNT();
            outputAmount = exchangeRate;
            fungibleTokenSupply += exchangeRate;
        } else if(inputToken == fungibleTokenId && outputToken == nftOceanId) {
            if (inputAmount != exchangeRate) revert INVALID_AMOUNT();
            outputAmount = 1;
            fungibleTokenSupply -= exchangeRate;
        } else {
            revert("Invalid input and output tokens");
        }
    }


    /**
      @notice
      Calculates the input amount for a specified output amount

      @param inputToken Input token id
      @param outputToken Output token id
      @param outputAmount Output token amount 
      @param tokenId erc721 token id.

      @return inputAmount Input amount
    */
    function computeInputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 outputAmount,
        address,
        bytes32 tokenId
    ) external override onlyOcean returns (uint256 inputAmount) {

        uint256 nftOceanId = _calculateOceanId(nftCollection, uint256(tokenId));
        
        if (inputToken == nftOceanId && outputToken == fungibleTokenId) {
            if (outputAmount != exchangeRate) revert INVALID_AMOUNT();
            inputAmount = 1;
            fungibleTokenSupply += exchangeRate;
        } else if(inputToken == fungibleTokenId && outputToken == nftOceanId) {
            if (outputAmount != 1) revert INVALID_AMOUNT();
            inputAmount = exchangeRate;
            fungibleTokenSupply -= exchangeRate;
        } else {
            revert("Invalid input and output tokens");
        }
    }


    /**
      @notice
      Get total fungible supply

      @param tokenId Fungible token id
      @return totalSupply Current total supply.
    */
    function getTokenSupply(uint256 tokenId)
        external
        view
        override
        returns (uint256 totalSupply)
    {   
        if (tokenId != fungibleTokenId) revert INVALID_TOKEN_ID();
        totalSupply = fungibleTokenSupply;
    }

    /**
      @notice
      Get ocean token id

      @param tokenContract NFT collection contract
      @return tokenId erc721 token id.
    */
    function _calculateOceanId(address tokenContract, uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(tokenContract, tokenId)));
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity =0.8.10;

import {IOceanPrimitive} from "../ocean/IOceanPrimitive.sol";
import {IOceanToken} from "../ocean/IOceanToken.sol";


/** 
  @notice 
  Allows erc1155 owners to fractionalize their tokens, each erc1155 will have a fungibalizer.
  
  @dev
  Inherits from -
  IOceanPrimitive: This is a ocean primitive and hence the methods can only be accessed by the ocean contract.
*/
contract Fractionalizer1155 is IOceanPrimitive {

    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//
    error INVALID_AMOUNT();
    error UNAUTHORIZED();

    //*********************************************************************//
    // --------------- public immutable stored properties ---------------- //
    //*********************************************************************//
    /** 
     @notice 
     ocean contract address.
    */
    address public immutable ocean;

    /** 
     @notice 
     erc1155 collection address
    */
    address public immutable nftCollection;

    /** 
     @notice 
     fungible token exchange rate
    */
    uint256 public immutable exchangeRate;

    /** 
     @notice 
     Keeps a track of the total no of new fungible tokens registered.
    */ 
    uint256 public registeredTokenNonce;

    /** 
     @notice 
     erc1155 fungiblized asset ocean id => fungible token id
    */
    mapping(uint256 => uint256) public fungibleTokenIds;

    /** 
     @notice 
     erc1155 fungiblized asset ocean id => total fungible token supply
    */
    mapping(uint256 => uint256) fungibleTokenSupply;



    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /**
      @param oceanAddress Ocean contract address.
      @param nftCollection_ Nft collection address
      @param exchangeRate_ No of fungible tokens per each erc1155 token.
    */
    constructor(
        address oceanAddress,
        address nftCollection_,
        uint256 exchangeRate_
    ) {
        // safety code size check
        assembly {
          if iszero(extcodesize(nftCollection_)) {
            revert(0, 0)
          }
        }
        ocean = oceanAddress;

        nftCollection = nftCollection_;
        exchangeRate = exchangeRate_;
    }


    /** 
    @notice Modifier to make sure msg.sender is the ocean contract.
    */
    modifier onlyOcean() {
        if (msg.sender != ocean) revert UNAUTHORIZED();
        _;
    }


    /**
      @notice
      Calculates the output amount for a specified input amount.

      @param inputToken Input token id
      @param outputToken Output token id
      @param inputAmount Input token amount 
      @param tokenId erc1155 token id

      @return outputAmount Output amount
    */
    function computeOutputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        address,
        bytes32 tokenId
    ) external override onlyOcean returns (uint256 outputAmount) {
        uint256 nftOceanId = _calculateOceanId(nftCollection, uint256(tokenId));

        if (fungibleTokenIds[nftOceanId] == 0) {
          uint256[] memory registeredToken = IOceanToken(ocean).registerNewTokens(registeredTokenNonce, 1);
          fungibleTokenIds[nftOceanId] = registeredToken[0];
          ++ registeredTokenNonce;
        }
        uint256 fungibleTokenId = fungibleTokenIds[nftOceanId];
        
        if (inputToken == nftOceanId && outputToken == fungibleTokenId) {
            outputAmount = inputAmount * exchangeRate;
            fungibleTokenSupply[nftOceanId] += outputAmount;
        } else if(inputToken == fungibleTokenId && outputToken == nftOceanId) {
            if (inputAmount % exchangeRate != 0) revert INVALID_AMOUNT();
            outputAmount = inputAmount / exchangeRate;
            fungibleTokenSupply[nftOceanId] -= inputAmount;
        } else {
            revert("Invalid input and output tokens");
        }
    }


    /**
      @notice
      Calculates the input amount for a specified output amount

      @param inputToken Input token id
      @param outputToken Output token id
      @param outputAmount Output token amount 
      @param tokenId erc1155 token id.

      @return inputAmount Input amount
    */
    function computeInputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 outputAmount,
        address,
        bytes32 tokenId
    ) external override onlyOcean returns (uint256 inputAmount) {
        uint256 nftOceanId = _calculateOceanId(nftCollection, uint256(tokenId));

        if (fungibleTokenIds[nftOceanId] == 0) {
          uint256[] memory registeredToken = IOceanToken(ocean).registerNewTokens(registeredTokenNonce, 1);
          fungibleTokenIds[nftOceanId] = registeredToken[0];
          ++ registeredTokenNonce;
        }
        uint256 fungibleTokenId = fungibleTokenIds[nftOceanId];
        
        if (inputToken == nftOceanId && outputToken == fungibleTokenId) {
            if (outputAmount % exchangeRate != 0) revert INVALID_AMOUNT();
            inputAmount = outputAmount / exchangeRate;
            fungibleTokenSupply[nftOceanId] += outputAmount;
        } else if(inputToken == fungibleTokenId && outputToken == nftOceanId) {
            inputAmount = outputAmount * exchangeRate;
            fungibleTokenSupply[nftOceanId] -= inputAmount;
        } else {
            revert("Invalid input and output tokens");
        }
    }


    /**
      @notice
      Get total fungible supply

      @param tokenId ERC 1155 token id of the asset which was fungblized
      @return totalSupply Current total supply.
    */
    function getTokenSupply(uint256 tokenId)
        external
        view
        override
        returns (uint256 totalSupply)
    {  
        totalSupply = fungibleTokenSupply[tokenId];
    }

    /**
      @notice
      Get ocean token id

      @param tokenContract Nft collection contract
      @return tokenId erc1155 token id.
    */
    function _calculateOceanId(address tokenContract, uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(tokenContract, tokenId)));
    }
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity =0.8.10;

/// @notice Implementing this allows a primitive to be called by the Ocean's
///  defi framework.
interface IOceanPrimitive {
    function computeOutputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        address userAddress,
        bytes32 metadata
    ) external returns (uint256 outputAmount);

    function computeInputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 outputAmount,
        address userAddress,
        bytes32 metadata
    ) external returns (uint256 inputAmount);

    function getTokenSupply(uint256 tokenId)
        external
        view
        returns (uint256 totalSupply);
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity =0.8.10;

/**
 * @title Interface for external contracts that issue tokens on the Ocean's
 *  public multitoken ledger
 * @dev Implemented by OceanERC1155.
 */
interface IOceanToken {
    function registerNewTokens(
        uint256 currentNumberOfTokens,
        uint256 numberOfAdditionalTokens
    ) external returns (uint256[] memory);
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ILendFacet} from "../interfaces/internal/ILendFacet.sol";

contract LendFacet is ILendFacet{
     bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.LendFacet.diamond.storage");
     struct Lend{
        mapping(address =>PutOrder)    borrowerPutOrder;  
        mapping(address =>address[])   lenderPutOrder;

        bytes32  domainHash;
        address  lendFeePlatformRecipient;

        mapping(address => CallOrder)  lenderCallOrder;
        mapping(address => address[])  borrowerCallOrder;

        mapping(address => CollateralNftType) collateralNft;
     }

      function diamondStorage() internal pure returns (Lend storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
      }
      

      function setBorrowerPutOrder(address _borrower,PutOrder memory _putOrder) external {
         Lend storage ds = diamondStorage();  
         ds.borrowerPutOrder[_borrower]=_putOrder;
      }

      function deleteBorrowerPutOrder(address _borrower) external{
         Lend storage ds = diamondStorage();
         delete ds.borrowerPutOrder[_borrower];
      }

      function getBorrowerPutOrder(address _borrower) external view returns(PutOrder memory){
          Lend storage ds = diamondStorage();  
          return ds.borrowerPutOrder[_borrower];
      }


      function setLenderPutOrder(address _lender,address _borrower) external{
           Lend storage ds = diamondStorage();  
           ds.lenderPutOrder[_lender].push(_borrower);
      }

      function getLenderPutOrder(address _lender) external view returns(address[] memory){
          Lend storage ds = diamondStorage();  
          return ds.lenderPutOrder[_lender];         
      }

      function getLenderPutOrderLength(address _lender) external view returns(uint256){
          Lend storage ds = diamondStorage();  
          return ds.lenderPutOrder[_lender].length;    
      }
      function deleteLenderPutOrder(address _lender,uint256 _index) external{
           Lend storage ds = diamondStorage();  
           uint256 lastIndex=ds.lenderPutOrder[_lender].length-1;
           if(lastIndex != _index){
            address lastAddr=ds.lenderPutOrder[_lender][lastIndex];
            ds.borrowerPutOrder[lastAddr].index=_index;
            ds.lenderPutOrder[_lender][_index]=lastAddr;
           }
           ds.lenderPutOrder[_lender].pop();
      }
      function setBorrowerPutOrderNftInfo(address _borrower,uint256 _collateralNftId,uint256 _newLiquidity) external{
            Lend storage ds = diamondStorage();     
            ds.borrowerPutOrder[_borrower].collateralNftId=_collateralNftId;
            ds.borrowerPutOrder[_borrower].collateralAmount=_newLiquidity;
      }
      //-----
      function setDomainHash(bytes32 _domainHash) external {
          Lend storage ds = diamondStorage();  
          ds.domainHash=_domainHash;
          emit SetDomainHash(_domainHash);
      }

      function getDomainHash() external view returns(bytes32){
           Lend storage ds = diamondStorage(); 
           return  ds.domainHash;
      }

      function setLendFeePlatformRecipient(address _lendFeePlatformRecipient) external {
           Lend storage ds = diamondStorage(); 
           ds.lendFeePlatformRecipient=_lendFeePlatformRecipient;
           emit SetLendFeePlatformRecipient(_lendFeePlatformRecipient);
      }

      function getLendFeePlatformRecipient() external view returns(address){
           Lend storage ds = diamondStorage(); 
           return ds.lendFeePlatformRecipient;
      }
      //-----
      function setLenderCallOrder(address _lender,CallOrder memory _callOrder) external {
          Lend storage ds = diamondStorage(); 
          ds.lenderCallOrder[_lender]=_callOrder;
      }

      function deleteLenderCallOrder(address _lender) external {
          Lend storage ds = diamondStorage();
          delete ds.lenderCallOrder[_lender];
      }

      function getLenderCallOrder(address _lender) external view returns(CallOrder memory){
          Lend storage ds = diamondStorage();  
          return ds.lenderCallOrder[_lender];
      }

      function setBorrowerCallOrder(address _borrower,address _lender) external{
           Lend storage ds = diamondStorage();  
           ds.borrowerCallOrder[_borrower].push(_lender);
      }
      function getBorrowerCallOrderLength(address _borrower) external view returns(uint256){
          Lend storage ds = diamondStorage();  
          return ds.borrowerCallOrder[_borrower].length;
      }

      function getBorrowerCallOrder(address _borrower) external view returns(address[] memory){
            Lend storage ds = diamondStorage();  
            return ds.borrowerCallOrder[_borrower];
      }
      function deleteLenderCallOrder(address _borrower,uint256 _index) external {
           Lend storage ds = diamondStorage();  
           uint256 lastIndex=ds.borrowerCallOrder[_borrower].length-1;
           if(lastIndex != _index){
            address lastAddr=ds.borrowerCallOrder[_borrower][lastIndex];
            ds.lenderCallOrder[lastAddr].index=_index;
            ds.borrowerCallOrder[_borrower][_index]=lastAddr;
           }
           ds.borrowerCallOrder[_borrower].pop();
      }

       function setLenderCallOrderNftInfo(address _lender,uint256 _collateralNftId,uint256 _newLiquidity) external{
            Lend storage ds = diamondStorage();     
            ds.lenderCallOrder[_lender].collateralNftId=_collateralNftId;
            ds.lenderCallOrder[_lender].collateralAmount=_newLiquidity;
       }

      //----
      function setCollateralNft(address _nft,CollateralNftType _type) external {
           Lend storage ds = diamondStorage();  
           require(_nft !=address(0),"LendFacet:invalid nft");
           ds.collateralNft[_nft]=_type;
           emit SetCollateralNft(_nft,_type);
      }

      function getCollateralNft(address _nft) external view returns(CollateralNftType){
          Lend storage ds = diamondStorage();  
          return ds.collateralNft[_nft];
      }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILendFacet {
    enum CollateralNftType {
        UnUsed,
        UniswapV3
    }

    struct PutOrder {
        uint256 orderId;
        address lender;
        address borrower;
        address recipient;
        /**
          if collateralAssetType==0  collateralAsset is Token
          if collateralAssetType==1  collateralAsset  is nft
         */
        address collateralAsset;
        /**
          if collateralAssetType==0  collateralAmount is Token amount
          if collateralAssetType==1  collateralAsset  is liquidity
         */
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowMinAmount;
        uint256 borrowAmount;
        uint256 expirationDate;
        uint256 platformFee;
        uint256 index;
        uint256 interestAmount;
        uint256 collateralAssetType;
        uint256 collateralNftId;
    }
    struct CallOrder {
        uint256 orderId;
        address borrower;
        address lender;
        address recipient;
        address collateralAsset;
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowNowAmount;
        uint256 borrowNowMinAmount;
        uint256 interestAmount;
        uint256 borrowLaterMinAmount;
        uint256 borrowLaterAmount;
        uint256 expirationDate;
        uint256 platformFee;
        uint256 index;
        uint256 collateralAssetType;
        uint256 collateralNftId;
    }
    event SetCollateralNft(address _nft, CollateralNftType _type);
    event SetLendFeePlatformRecipient(address _recipient);
    event SetDomainHash(bytes32 _domainHash);

    function setBorrowerPutOrder(
        address _borrower,
        PutOrder memory _putOrder
    ) external;

    function deleteBorrowerPutOrder(address _borrower) external;

    function getBorrowerPutOrder(
        address _borrower
    ) external view returns (PutOrder memory);

    function setLenderPutOrder(address _lender, address _borrower) external;

    function getLenderPutOrder(
        address _lender
    ) external view returns (address[] memory);

    function getLenderPutOrderLength(
        address _lender
    ) external view returns (uint256);

    function deleteLenderPutOrder(address _lender, uint256 _index) external;

    function setBorrowerPutOrderNftInfo(
        address _borrower,
        uint256 _collateralNftId,
        uint256 _newLiquidity
    ) external;

    //----
    function setDomainHash(bytes32 _domainHash) external;

    function getDomainHash() external view returns (bytes32);

    function setLendFeePlatformRecipient(
        address _lendFeePlatformRecipient
    ) external;

    function getLendFeePlatformRecipient() external view returns (address);

    //-----
    function setLenderCallOrder(
        address _lender,
        CallOrder memory _callOrder
    ) external;

    function deleteLenderCallOrder(address _lender) external;

    function getLenderCallOrder(
        address _lender
    ) external view returns (CallOrder memory);

    function setBorrowerCallOrder(address _borrower, address _lender) external;

    function getBorrowerCallOrderLength(
        address _borrower
    ) external view returns (uint256);

    function getBorrowerCallOrder(
        address _borrower
    ) external view returns (address[] memory);

    function deleteLenderCallOrder(address _borrower, uint256 _index) external;

    function setLenderCallOrderNftInfo(
        address _lender,
        uint256 _collateralNftId,
        uint256 _newLiquidity
    ) external;

    //----
    function setCollateralNft(address _nft, CollateralNftType _type) external;

    function getCollateralNft(
        address _nft
    ) external view returns (CollateralNftType);
}
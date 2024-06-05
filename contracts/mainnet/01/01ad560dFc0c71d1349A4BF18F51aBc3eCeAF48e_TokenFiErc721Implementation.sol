// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract TokenFiErc721Implementation {

    struct Tuple4592251 {
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
        bytes signature;
    }

    struct Tuple3618837 {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        uint256 maxSupply;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    struct Tuple3506191 {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        uint256 maxSupply;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    struct Tuple1236461 {
        address facetAddress;
        bytes4[] functionSelectors;
    }
      

   function adminMint(address  _to) external {}

   function adminMintBatch(address  _to, uint256  _amount) external {}

   function approve(address  operator, uint256  tokenId) external payable {}

   function balanceOf(address  account) external view returns (uint256 ) {}

   function getApproved(uint256  tokenId) external view returns (address ) {}

   function isApprovedForAll(address  account, address  operator) external view returns (bool ) {}

   function mint(address  _to, address  paymentToken, address  referrer) external payable {}

   function mintBatch(address  _to, uint256  _amount, address  paymentToken, address  referrer) external payable {}

   function mintBatchWithPaymentSignature(address  _to, uint256  _amount, Tuple4592251 memory crossPaymentSignatureInput) external {}

   function mintWithPaymentSignature(address  _to, Tuple4592251 memory crossPaymentSignatureInput) external {}

   function name() external view returns (string memory) {}

   function ownerOf(uint256  tokenId) external view returns (address ) {}

   function paused() external view returns (bool  status) {}

   function paymentModule() external view returns (address ) {}

   function safeTransferFrom(address  from, address  to, uint256  tokenId) external payable {}

   function safeTransferFrom(address  from, address  to, uint256  tokenId, bytes memory data) external payable {}

   function setApprovalForAll(address  operator, bool  status) external {}

   function setTokenInfo(Tuple3618837 memory _newTokenInfo) external {}

   function setTokenUri(uint256  tokenId, string memory uri) external {}

   function supportsInterface(bytes4  interfaceId) external view returns (bool ) {}

   function symbol() external view returns (string memory) {}

   function tokenByIndex(uint256  index) external view returns (uint256 ) {}

   function tokenInfo() external view returns (Tuple3506191 memory) {}

   function tokenOfOwnerByIndex(address  owner, uint256  index) external view returns (uint256 ) {}

   function tokenURI(uint256  tokenId) external view returns (string memory) {}

   function totalSupply() external view returns (uint256 ) {}

   function transferFrom(address  from, address  to, uint256  tokenId) external payable {}

   function DEFAULT_ADMIN_ROLE() external pure returns (bytes32 ) {}

   function MINTER_ROLE() external pure returns (bytes32 ) {}

   function PAUSER_ROLE() external pure returns (bytes32 ) {}

   function WHITELISTED_ROLE() external pure returns (bytes32 ) {}

   function WHITELIST_ADMIN_ROLE() external pure returns (bytes32 ) {}

   function getRoleAdmin(bytes32  role) external view returns (bytes32 ) {}

   function getRoleMember(bytes32  role, uint256  index) external view returns (address ) {}

   function getRoleMemberCount(bytes32  role) external view returns (uint256 ) {}

   function grantRole(bytes32  role, address  account) external {}

   function hasRole(bytes32  role, address  account) external view returns (bool ) {}

   function renounceRole(bytes32  role) external {}

   function revokeRole(bytes32  role, address  account) external {}

   function pause() external {}

   function unpause() external {}

   function facetAddress(bytes4  _functionSelector) external view returns (address  facetAddress_) {}

   function facetAddresses() external view returns (address[] memory facetAddresses_) {}

   function facetFunctionSelectors(address  _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

   function facets() external view returns (Tuple1236461[] memory facets_) {}

   function implementation() external view returns (address ) {}

   function setImplementation(address  _implementation) external {}
}
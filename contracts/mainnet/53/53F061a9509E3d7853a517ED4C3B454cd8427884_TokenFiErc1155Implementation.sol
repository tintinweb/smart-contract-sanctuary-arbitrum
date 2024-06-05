// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract TokenFiErc1155Implementation {

    struct Tuple2987921 {
        uint256 tokenId;
        uint256 maxSupply;
        uint256 publicMintUsdPrice;
        uint8 decimals;
        string uri;
    }

    struct Tuple4592251 {
        address payer;
        uint256 sourceChainId;
        uint256 paymentIndex;
        bytes signature;
    }

    struct Tuple6515323 {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    struct Tuple714984 {
        string name;
        string symbol;
        string collectionLogo;
        string baseURI;
        bool isPublicMintEnabled;
        bool isAdminMintEnabled;
        address owner;
    }

    struct Tuple1236461 {
        address facetAddress;
        bytes4[] functionSelectors;
    }
      

   function accountsByToken(uint256  id) external view returns (address[] memory) {}

   function adminMint(address  account, uint256  id, uint256  amount) external {}

   function balanceOf(address  account, uint256  id) external view returns (uint256 ) {}

   function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory) {}

   function createToken(Tuple2987921 memory input) external {}

   function decimals(uint256  tokenId) external view returns (uint256 ) {}

   function exists(uint256  id) external view returns (bool ) {}

   function getExistingTokenIds() external view returns (uint256[] memory) {}

   function isApprovedForAll(address  account, address  operator) external view returns (bool ) {}

   function maxSupply(uint256  tokenId) external view returns (uint256 ) {}

   function mint(address  account, uint256  id, uint256  amount, address  paymentToken, address  referrer) external payable {}

   function mintWithPaymentSignature(address  account, uint256  id, uint256  amount, Tuple4592251 memory crossPaymentSignatureInput) external {}

   function paused() external view returns (bool  status) {}

   function paymentModule() external view returns (address ) {}

   function paymentServiceIndexByTokenId(uint256  tokenId) external view returns (uint256 ) {}

   function safeBatchTransferFrom(address  from, address  to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external {}

   function safeTransferFrom(address  from, address  to, uint256  id, uint256  amount, bytes memory data) external {}

   function setApprovalForAll(address  operator, bool  status) external {}

   function setTokenInfo(Tuple6515323 memory _newTokenInfo) external {}

   function setTokenPublicMintPrice(uint256  _tokenId, uint256  _price) external {}

   function setTokenUri(uint256  _tokenId, string memory _uri) external {}

   function supportsInterface(bytes4  interfaceId) external view returns (bool ) {}

   function tokenInfo() external view returns (Tuple714984 memory) {}

   function tokensByAccount(address  account) external view returns (uint256[] memory) {}

   function totalHolders(uint256  id) external view returns (uint256 ) {}

   function totalSupply(uint256  id) external view returns (uint256 ) {}

   function uri(uint256  tokenId) external view returns (string memory) {}

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
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract TokenFiErc20Implementation {

    struct Tuple2631268 {
        address pairToken;
        address router;
        uint256 liquidityBasisPoints;
        uint256 priceImpactBasisPoints;
    }

    struct Tuple9316797 {
        Tuple3956827 transferFee;
        Tuple6362068 burn;
        Tuple409819 reflection;
        Tuple2124617 buyback;
    }

    struct Tuple3956827 {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Tuple6362068 {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Tuple409819 {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Tuple2124617 {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Tuple8917447 {
        Tuple3956827 transferFee;
        Tuple6362068 burn;
        Tuple409819 reflection;
        Tuple2124617 buyback;
    }

    struct Tuple4023003 {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 initialSupply;
        uint256 maxSupply;
        address treasury;
        address owner;
        Tuple8912907 fees;
        Tuple4859413 buybackDetails;
    }

    struct Tuple8912907 {
        Tuple3956827 transferFee;
        Tuple6362068 burn;
        Tuple409819 reflection;
        Tuple2124617 buyback;
    }

    struct Tuple4859413 {
        address pairToken;
        address router;
        uint256 liquidityBasisPoints;
        uint256 priceImpactBasisPoints;
    }

    struct Tuple9794500 {
        uint256 tTotal;
        uint256 rTotal;
        uint256 tFeeTotal;
    }

    struct Tuple1236461 {
        address facetAddress;
        bytes4[] functionSelectors;
    }
      

   function DOMAIN_SEPARATOR() external view returns (bytes32  domainSeparator) {}

   function addExchangePool(address  pool) external {}

   function addExemptAddress(address  account) external {}

   function allowance(address  holder, address  spender) external view returns (uint256 ) {}

   function approve(address  spender, uint256  amount) external returns (bool ) {}

   function balanceOf(address  account) external view returns (uint256 ) {}

   function buybackHandler() external view returns (address ) {}

   function decimals() external view returns (uint8 ) {}

   function decreaseAllowance(address  spender, uint256  amount) external returns (bool ) {}

   function excludeAccount(address  account) external {}

   function fees() external view returns (Tuple8917447 memory) {}

   function includeAccount(address  account) external {}

   function increaseAllowance(address  spender, uint256  amount) external returns (bool ) {}

   function isExchangePool(address  pool) external view returns (bool ) {}

   function isExcludedFromReflectionRewards(address  account) external view returns (bool ) {}

   function isExemptedFromTax(address  account) external view returns (bool ) {}

   function isReflectionToken() external view returns (bool ) {}

   function mint(address  to, uint256  amount) external {}

   function name() external view returns (string memory) {}

   function nonces(address  owner) external view returns (uint256 ) {}

   function permit(address  owner, address  spender, uint256  amount, uint256  deadline, uint8  v, bytes32  r, bytes32  s) external {}

   function reflect(uint256  tAmount) external {}

   function reflectionFromToken(uint256  tAmount, bool  deductTransferFee) external view returns (uint256 ) {}

   function removeExchangePool(address  pool) external {}

   function removeExemptAddress(address  account) external {}

   function setBuybackDetails(Tuple2631268 memory _buybackDetails) external {}

   function setBuybackHandler(address  _newBuybackHandler) external {}

   function setDecimals(uint8  decimals) external {}

   function setName(string memory name) external {}

   function setSymbol(string memory symbol) external {}

   function symbol() external view returns (string memory) {}

   function tokenFromReflection(uint256  rAmount) external view returns (uint256 ) {}

   function tokenInfo() external view returns (Tuple4023003 memory) {}

   function totalFees() external view returns (uint256 ) {}

   function totalReflection() external view returns (Tuple9794500 memory) {}

   function totalSupply() external view returns (uint256 ) {}

   function transfer(address  recipient, uint256  amount) external returns (bool ) {}

   function transferFrom(address  holder, address  recipient, uint256  amount) external returns (bool ) {}

   function updateFees(Tuple9316797 memory _fees) external {}

   function updateTokenLauncher(address  _newTokenLauncher) external {}

   function updateTreasury(address  _newTreasury) external {}

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

   function paused() external view returns (bool  status) {}

   function unpause() external {}

   function facetAddress(bytes4  _functionSelector) external view returns (address  facetAddress_) {}

   function facetAddresses() external view returns (address[] memory facetAddresses_) {}

   function facetFunctionSelectors(address  _facet) external view returns (bytes4[] memory facetFunctionSelectors_) {}

   function facets() external view returns (Tuple1236461[] memory facets_) {}

   function supportsInterface(bytes4  _interfaceId) external view returns (bool ) {}

   function implementation() external view returns (address ) {}

   function setImplementation(address  _implementation) external {}
}
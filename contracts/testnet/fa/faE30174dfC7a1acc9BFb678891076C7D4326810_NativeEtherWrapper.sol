/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Tribeone: NativeEtherWrapper.sol
*
* Latest source (may be newer): https://github.com/Tribeoneio/tribeone/blob/master/contracts/NativeEtherWrapper.sol
* Docs: https://docs.tribeone.io/contracts/NativeEtherWrapper
*
* Contract Dependencies: 
*	- IAddressResolver
*	- MixinResolver
*	- Owned
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.tribeone.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


interface IWETH {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // WETH-specific functions.
    function deposit() external payable;

    function withdraw(uint amount) external;

    // Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Deposit(address indexed to, uint amount);
    event Withdrawal(address indexed to, uint amount);
}


// https://docs.tribeone.io/contracts/source/interfaces/ietherwrapper
contract IEtherWrapper {
    function mint(uint amount) external;

    function burn(uint amount) external;

    function distributeFees() external;

    function capacity() external view returns (uint);

    function getReserves() external view returns (uint);

    function totalIssuedTribes() external view returns (uint);

    function calculateMintFee(uint amount) public view returns (uint);

    function calculateBurnFee(uint amount) public view returns (uint);

    function maxETH() public view returns (uint256);

    function mintFeeRate() public view returns (uint256);

    function burnFeeRate() public view returns (uint256);

    function weth() public view returns (IWETH);
}


// https://docs.tribeone.io/contracts/source/interfaces/itribe
interface ITribe {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableTribes(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Tribeone
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// https://docs.tribeone.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views

    function allNetworksDebtInfo()
        external
        view
        returns (
            uint256 debt,
            uint256 sharesSupply,
            bool isStale
        );

    function anyTribeOrHAKARateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableTribeCount() external view returns (uint);

    function availableTribes(uint index) external view returns (ITribe);

    function canBurnTribes(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableTribes(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableTribes(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function tribes(bytes32 currencyKey) external view returns (ITribe);

    function getTribes(bytes32[] calldata currencyKeys) external view returns (ITribe[] memory);

    function tribesByAddress(address tribeAddress) external view returns (bytes32);

    function totalIssuedTribes(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableTribeoneAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    function liquidationAmounts(address account, bool isSelfLiquidation)
        external
        view
        returns (
            uint totalRedeemed,
            uint debtToRemove,
            uint escrowToLiquidate,
            uint initialDebtBalance
        );

    // Restricted: used internally to Tribeone
    function addTribes(ITribe[] calldata tribesToAdd) external;

    function issueTribes(address from, uint amount) external;

    function issueTribesOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxTribes(address from) external;

    function issueMaxTribesOnBehalf(address issueFor, address from) external;

    function burnTribes(address from, uint amount) external;

    function burnTribesOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnTribesToTarget(address from) external;

    function burnTribesToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedTribeProxy,
        address account,
        uint balance
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(address account, bool isSelfLiquidation)
        external
        returns (
            uint totalRedeemed,
            uint debtRemoved,
            uint escrowToLiquidate
        );

    function issueTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function burnTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function modifyDebtSharesForMigration(address account, uint amount) external;
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getTribe(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.tribes(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// @unsupported: ovm


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/nativeetherwrapper
contract NativeEtherWrapper is Owned, MixinResolver {
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_TRIBEONEHETH = "TribehETH";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}

    /* ========== PUBLIC FUNCTIONS ========== */

    /* ========== VIEWS ========== */
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = CONTRACT_ETHER_WRAPPER;
        addresses[1] = CONTRACT_TRIBEONEHETH;
        return addresses;
    }

    function etherWrapper() internal view returns (IEtherWrapper) {
        return IEtherWrapper(requireAndGetAddress(CONTRACT_ETHER_WRAPPER));
    }

    function weth() internal view returns (IWETH) {
        return etherWrapper().weth();
    }

    function tribehETH() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_TRIBEONEHETH));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint() public payable {
        uint amount = msg.value;
        require(amount > 0, "msg.value must be greater than 0");

        // Convert sent ETH into WETH.
        weth().deposit.value(amount)();

        // Approve for the EtherWrapper.
        weth().approve(address(etherWrapper()), amount);

        // Now call mint.
        etherWrapper().mint(amount);

        // Transfer the hETH to msg.sender.
        tribehETH().transfer(msg.sender, tribehETH().balanceOf(address(this)));

        emit Minted(msg.sender, amount);
    }

    function burn(uint amount) public {
        require(amount > 0, "amount must be greater than 0");
        IWETH weth = weth();

        // Transfer hETH from the msg.sender.
        tribehETH().transferFrom(msg.sender, address(this), amount);

        // Approve for the EtherWrapper.
        tribehETH().approve(address(etherWrapper()), amount);

        // Now call burn.
        etherWrapper().burn(amount);

        // Convert WETH to ETH and send to msg.sender.
        weth.withdraw(weth.balanceOf(address(this)));
        // solhint-disable avoid-low-level-calls
        msg.sender.call.value(address(this).balance)("");

        emit Burned(msg.sender, amount);
    }

    function() external payable {
        // Allow the WETH contract to send us ETH during
        // our call to WETH.deposit. The gas stipend it gives
        // is 2300 gas, so it's not possible to do much else here.
    }

    /* ========== EVENTS ========== */
    // While these events are replicated in the core EtherWrapper,
    // it is useful to see the usage of the NativeEtherWrapper contract.
    event Minted(address indexed account, uint amount);
    event Burned(address indexed account, uint amount);
}
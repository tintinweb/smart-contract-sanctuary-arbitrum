// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝

//  __ __ _     _   _ _____     _   _       _                 _____         _     _           
// |  |  |_|___| |_| |     |___| |_|_|_____|_|___ ___ ___ ___| __  |___ ___|_|___| |_ ___ _ _ 
// |_   _| | -_| | . |  |  | . |  _| |     | |- _| -_|  _|_ -|    -| -_| . | |_ -|  _|  _| | |
//   |_| |_|___|_|___|_____|  _|_| |_|_|_|_|_|___|___|_| |___|__|__|___|_  |_|___|_| |_| |_  |
//                         |_|                                         |___|             |___|

// Github - https://github.com/FortressFinance

import {IFortressCompounder} from "./IFortressCompounder.sol";
import {IFortressConcentrator} from "./IFortressConcentrator.sol";

contract YieldOptimizersRegistry {

    // -------------- Compounders --------------

    // Curve Compounders

    /// @notice The list of Curve Compounder Vaults primary assets
    address[] public curveCompoundersPrimaryAssets;

    /// @notice The mapping from Primary Asset to Curve Compounder Vault address
    mapping(address => address) public curveCompounders;

    // Balancer Compounders

    /// @notice The list of Balancer Compounder Vaults primary assets
    address[] public balancerCompoundersPrimaryAssets;

    /// @notice The mapping from Primary Asset to Balancer Compounder Vault address
    mapping(address => address) public balancerCompounders;

    // Token Compounders

    /// @notice The list of TokenCompounder primary assets
    address[] public tokenCompoundersPrimaryAssets;

    /// @notice The mapping from Primary Asset to Token Compounder Vault address
    mapping(address => address) public tokenCompounders;

    // -------------- Concentrators --------------

    struct TargetAsset {
        address fortETH;
        address fortUSD;
        address fortCrypto1; 
        address fortCrypto2;
    }
    
    // Concentrators Target Assets

    /// @notice The instance of Concentrator Target Assets
    TargetAsset public concentratorTargetAssets;

    // Curve Concentrators

    /// @notice The list of Curve ETH Concentrator Vaults primary assets
    address[] public curveEthConcentratorsPrimaryAssets;
    
    /// @notice The list of Curve USD Concentrator Vaults primary assets
    address[] public curveUsdConcentratorsPrimaryAssets;

    /// @notice The list of Curve Crypto1 Concentrator Vaults primary assets
    address[] public curveCrypto1ConcentratorsPrimaryAssets;

    /// @notice The list of Curve Crypto2 Concentrator Vaults primary assets
    address[] public curveCrypto2ConcentratorsPrimaryAssets;

    /// @notice The mapping from Primary Asset to Curve ETH Concentrator Vault address
    mapping(address => address) public curveEthConcentrators;

    /// @notice The mapping from Primary Asset to Curve USD Concentrator Vault address
    mapping(address => address) public curveUsdConcentrators;

    /// @notice The mapping from Primary Asset to Curve Crypto1 Concentrator Vault address
    mapping(address => address) public curveCrypto1Concentrators;

    /// @notice The mapping from Primary Asset to Curve Crypto2 Concentrator Vault address
    mapping(address => address) public curveCrypto2Concentrators;

    // Balancer Concentrators

    /// @notice The list of Balancer ETH Concentrator Vaults primary assets
    address[] public balancerEthConcentratorsPrimaryAssets;
    
    /// @notice The list of Balancer USD Concentrator Vaults primary assets
    address[] public balancerUsdConcentratorsPrimaryAssets;

    /// @notice The list of Balancer Crypto1 Concentrator Vaults primary assets
    address[] public balancerCrypto1ConcentratorsPrimaryAssets;

    /// @notice The list of Balancer Crypto2 Concentrator Vaults primary assets
    address[] public balancerCrypto2ConcentratorsPrimaryAssets;

    /// @notice The mapping from Primary Asset to Balancer ETH Concentrator Vault address
    mapping(address => address) public balancerEthConcentrators;

    /// @notice The mapping from Primary Asset to Balancer USD Concentrator Vault address
    mapping(address => address) public balancerUsdConcentrators;

    /// @notice The mapping from Primary Asset to Balancer Crypto1 Concentrator Vault address
    mapping(address => address) public balancerCrypto1Concentrators;

    /// @notice The mapping from Primary Asset to Balancer Crypto2 Concentrator Vault address
    mapping(address => address) public balancerCrypto2Concentrators;

    // -------------- Settings --------------

    /// @notice The addresses of the contract owners
    address[2] public owners;

    // ********************* Constructor *********************

    constructor(address _owner) {
        owners[0] = _owner;
    }

    // ********************* View Functions *********************
    
    // -----------------------------------------------------------
    // --------------------- AMM Compounders ---------------------
    // -----------------------------------------------------------

    /// @dev Get the list of addresses of the Primary Assets of all Compounder vaults for a specific AMM
    /// @return _primaryAssets - The list of addresses of the Primary Assets
    function getAmmCompoundersPrimaryAssets(bool _isCurve) external view returns (address[] memory _primaryAssets) {
        if (_isCurve) {
            return curveCompoundersPrimaryAssets;
        } else {
            return balancerCompoundersPrimaryAssets;
        }
    }

    /// @dev Get the address of a Compounder Vault for a specific AMM and Primary Asset
    /// @return _compounderVault - The address of the Compounder Vault
    function getAmmCompounderVault(bool _isCurve, address _asset) public view returns (address _compounderVault) {
        if (_isCurve) {
            return curveCompounders[_asset];
        } else {
            return balancerCompounders[_asset];
        }
    }

    /// @dev Get the address of all underlying assets for a specific AMM and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getAmmCompounderUnderlyingAssets(bool _isCurve, address _asset) external view returns (address[] memory) {
        return IFortressCompounder(getAmmCompounderVault(_isCurve, _asset)).getUnderlyingAssets();
    }

    /// @dev Get the name of a Compounder Vault for a specific AMM and Primary Asset
    /// @return - The name of the Compounder Vault
    function getAmmCompounderName(bool _isCurve, address _asset) external view returns (string memory) {
        return IFortressCompounder(getAmmCompounderVault(_isCurve, _asset)).getName();
    }

    /// @dev Get the symbol of a Compounder Vault for a specific AMM and Primary Asset
    /// @return - The symbol of the Compounder Vault
    function getAmmCompounderSymbol(bool _isCurve, address _asset) external view returns (string memory) {
        return IFortressCompounder(getAmmCompounderVault(_isCurve, _asset)).getSymbol();
    }

    /// @dev Get the description of a Compounder Vault for a specific AMM and Primary Asset
    /// @return - The description of the Compounder Vault
    function getAmmCompounderDescription(bool _isCurve, address _asset) external view returns (string memory) {
        return IFortressCompounder(getAmmCompounderVault(_isCurve, _asset)).getDescription();
    }

    // -------------------------------------------------------------
    // --------------------- Token Compounders ---------------------
    // -------------------------------------------------------------

    /// @dev Get the addresses of the Primary Assets of all Token Compounder vaults
    /// @return - The list of addresses of Primary Assets
    function getTokenCompoundersPrimaryAssets() external view returns (address[] memory) {
        return tokenCompoundersPrimaryAssets;
    }

    /// @dev Get the address of a Token Compounder Vault for a specific Primary Asset
    /// @return - The address of the Token Compounder Vault
    function getTokenCompounderVault(address _asset) public view returns (address) {
        return tokenCompounders[_asset];
    }

    /// @dev Get the address of all underlying assets for a specific Token Compounder Vault given AMMType and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getTokenCompounderUnderlyingAssets(address _asset) external view returns (address[] memory) {
        return IFortressCompounder(getTokenCompounderVault(_asset)).getUnderlyingAssets();
    }

    /// @dev Get the name of a Token Compounder Vault for a specific Primary Asset
    /// @return - The name of the Token Compounder Vault
    function getTokenCompounderName(address _asset) external view returns (string memory) {
        return IFortressCompounder(getTokenCompounderVault(_asset)).getName();
    }

    /// @dev Get the symbol of a Token Compounder Vault for a specific Primary Asset
    /// @return - The symbol of the Token Compounder Vault
    function getTokenCompounderSymbol(address _asset) external view returns (string memory) {
        return IFortressCompounder(getTokenCompounderVault(_asset)).getSymbol();
    }

    /// @dev Get the description of a Compounder Vault for a specific AMMType and Primary Asset
    /// @return - The description of the Compounder Vault
    function getTokenCompounderDescription(address _asset) external view returns (string memory) {
        return IFortressCompounder(getTokenCompounderVault(_asset)).getDescription();
    }

    // -------------------------------------------------------------
    // --------------------- AMM Concentrators ---------------------
    // -------------------------------------------------------------

    /// @dev Get the addresses of Primary Assets of all AMM Concentrator vaults for a specific AMM and Target Asset
    /// @return _primaryAssets - The list of addresses of Primary Assets
    function getConcentratorPrimaryAssets(bool _isCurve, address _targetAsset) external view returns (address[] memory _primaryAssets) {
        TargetAsset memory _concentratorTargetAssets = concentratorTargetAssets;
        if (_isCurve) {
            if (_targetAsset == _concentratorTargetAssets.fortETH) {
                return curveEthConcentratorsPrimaryAssets;
            } else if (_targetAsset == _concentratorTargetAssets.fortUSD) {
                return curveUsdConcentratorsPrimaryAssets;
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto1) {
                return curveCrypto1ConcentratorsPrimaryAssets;
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto2) {
                return curveCrypto2ConcentratorsPrimaryAssets;
            } else {
                revert InvalidTargetAsset();
            }
        } else {
            if (_targetAsset == _concentratorTargetAssets.fortETH) {
                return balancerEthConcentratorsPrimaryAssets;
            } else if (_targetAsset == _concentratorTargetAssets.fortUSD) {
                return balancerUsdConcentratorsPrimaryAssets;
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto1) {
                return balancerCrypto1ConcentratorsPrimaryAssets;
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto2) {
                return balancerCrypto2ConcentratorsPrimaryAssets;
            } else {
                revert InvalidTargetAsset();
            }
        }
    }

    /// @dev Get the address of a Concentrator Vault for a specific AMM, Target Asset, and Primary Asset
    /// @return _concentrator - The address of the Concentrator Vault
    function getConcentrator(bool _isCurve, address _targetAsset, address _primaryAsset) public view returns (address _concentrator) {
        TargetAsset memory _concentratorTargetAssets = concentratorTargetAssets;
        if (_isCurve) {
            if (_targetAsset == _concentratorTargetAssets.fortETH) {
                return curveEthConcentrators[_primaryAsset];
            } else if (_targetAsset == _concentratorTargetAssets.fortUSD) {
                return curveUsdConcentrators[_primaryAsset];
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto1) {
                return curveCrypto1Concentrators[_primaryAsset];
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto2) {
                return curveCrypto2Concentrators[_primaryAsset];
            } else {
                revert InvalidTargetAsset();
            }
        } else {
            if (_targetAsset == _concentratorTargetAssets.fortETH) {
                return balancerEthConcentrators[_primaryAsset];
            } else if (_targetAsset == _concentratorTargetAssets.fortUSD) {
                return balancerUsdConcentrators[_primaryAsset];
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto1) {
                return balancerCrypto1Concentrators[_primaryAsset];
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto2) {
                return balancerCrypto2Concentrators[_primaryAsset];
            } else {
                revert InvalidTargetAsset();
            }
        }
    }

    /// @dev Get the symbol of a Concentrator Vault for a specific AMM, Target Asset, and Primary Asset
    /// @return - The symbol of the Concentrator Vault
    function getConcentratorSymbol(bool _isCurve, address _targetAsset, address _asset) external view returns (string memory) {
        return IFortressConcentrator(getConcentrator(_isCurve, _targetAsset, _asset)).getSymbol();
    }

    /// @dev Get the name of a Concentrator Vault for a specific AMM, Target Asset, and Primary Asset
    /// @return - The name of the Concentrator Vault
    function getConcentratorName(bool _isCurve, address _targetAsset, address _asset) external view returns (string memory) {
        return IFortressConcentrator(getConcentrator(_isCurve, _targetAsset, _asset)).getName();
    }

    /// @dev Get the description of a Concentrator Vault for a specific AMM, Target Asset, and Primary Asset
    /// @return - The description of the Concentrator Vault
    function getConcentratorDescription(bool _isCurve, address _targetAsset, address _asset) external view returns (string memory) {
        return IFortressConcentrator(getConcentrator(_isCurve, _targetAsset, _asset)).getDescription();
    }

    /// @dev Get the underlying assets of a Concentrator Vault for a specific AMM, Target Asset, and Primary Asset
    /// @return - The list of addresses of underlying assets
    function getConcentratorUnderlyingAssets(bool _isCurve, address _targetAsset, address _asset) external view returns (address[] memory) {
        return IFortressConcentrator(getConcentrator(_isCurve, _targetAsset, _asset)).getUnderlyingAssets();
    }

    /// @dev Get the target asset of a Concentrator Vault for a specific AMM, Target Asset, and Primary Asset
    /// @return - The address of the target asset, which is a Fortress Compounder Vault
    function getConcentratorTargetVault(bool _isCurve, address _targetAsset, address _asset) external view returns (address) {
        return IFortressConcentrator(getConcentrator(_isCurve, _targetAsset, _asset)).getCompounder();
    }

    // ********************* Modifiers *********************

    modifier onlyOwner {
        if (msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        _;
    }

    // ********************* Restricted Functions *********************

    /// @dev Register a new AMM Compounder Vault
    /// @param _isCurve - The AMM Type of the Compounder, True for Curve, False for Balancer
    /// @param _compounder - The address of the Compounder
    /// @param _primaryAsset - The address of the Primary Asset
    function registerAmmCompounder(bool _isCurve, address _compounder, address _primaryAsset) onlyOwner external {
        if (_isCurve) {
            if (curveCompounders[_primaryAsset] != address(0)) revert AlreadyRegistered();

            curveCompounders[_primaryAsset] = _compounder;
            curveCompoundersPrimaryAssets.push(_primaryAsset);
        } else {
            if (balancerCompounders[_primaryAsset] != address(0)) revert AlreadyRegistered();

            balancerCompounders[_primaryAsset] = _compounder;
            balancerCompoundersPrimaryAssets.push(_primaryAsset);
        }
        
        emit RegisterAMMCompounder(_isCurve, _compounder, _primaryAsset);
    }

    /// @dev Register a new Token Compounder Vault
    /// @param _compounder - The address of the Compounder
    /// @param _primaryAsset - The address of the Primary Asset
    function registerTokenCompounder(address _compounder, address _primaryAsset) onlyOwner external {
        if (tokenCompounders[_primaryAsset] != address(0)) revert AlreadyRegistered();

        tokenCompounders[_primaryAsset] = _compounder;
        tokenCompoundersPrimaryAssets.push(_primaryAsset);

        emit RegisterTokenCompounder(_compounder, _primaryAsset);
    }

    /// @dev Register a new Concentrator Vault
    /// @param _isCurve - The AMM Type of the Compounder, True for Curve, False for Balancer
    /// @param _concentrator - The address of the Concentrator
    /// @param _targetAsset - The address of the Target Asset
    /// @param _primaryAsset - The address of the Primary Asset
    function registerAmmConcentrator(bool _isCurve, address _concentrator, address _targetAsset, address _primaryAsset) onlyOwner external {
        TargetAsset memory _concentratorTargetAssets = concentratorTargetAssets;
        
        if (_isCurve) {
            if (_targetAsset == _concentratorTargetAssets.fortETH) {
                if (curveEthConcentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                curveEthConcentrators[_primaryAsset] = _concentrator;
                curveEthConcentratorsPrimaryAssets.push(_primaryAsset);
            } else if (_targetAsset == _concentratorTargetAssets.fortUSD) {
                if (curveUsdConcentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                curveUsdConcentrators[_primaryAsset] = _concentrator;
                curveUsdConcentratorsPrimaryAssets.push(_primaryAsset);
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto1) {
                if (curveCrypto1Concentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                curveCrypto1Concentrators[_primaryAsset] = _concentrator;
                curveCrypto1ConcentratorsPrimaryAssets.push(_primaryAsset);
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto2) {
                if (curveCrypto2Concentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                curveCrypto2Concentrators[_primaryAsset] = _concentrator;
                curveCrypto2ConcentratorsPrimaryAssets.push(_primaryAsset);
            } else {
                revert InvalidTargetAsset();
            }
        } else {
            if (_targetAsset == _concentratorTargetAssets.fortETH) {
                if (balancerEthConcentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                balancerEthConcentrators[_primaryAsset] = _concentrator;
                balancerEthConcentratorsPrimaryAssets.push(_primaryAsset);
            } else if (_targetAsset == _concentratorTargetAssets.fortUSD) {
                if (balancerUsdConcentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                balancerUsdConcentrators[_primaryAsset] = _concentrator;
                balancerUsdConcentratorsPrimaryAssets.push(_primaryAsset);
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto1) {
                if (balancerCrypto1Concentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                balancerCrypto1Concentrators[_primaryAsset] = _concentrator;
                balancerCrypto1ConcentratorsPrimaryAssets.push(_primaryAsset);
            } else if (_targetAsset == _concentratorTargetAssets.fortCrypto2) {
                if (balancerCrypto2Concentrators[_primaryAsset] != address(0)) revert AlreadyRegistered();
                balancerCrypto2Concentrators[_primaryAsset] = _concentrator;
                balancerCrypto2ConcentratorsPrimaryAssets.push(_primaryAsset);
            } else {
                revert InvalidTargetAsset();
            }
        }

        emit RegisterAMMConcentrator(_isCurve, _concentrator, _targetAsset, _primaryAsset);
    }

    /// @dev Update the addresses of the Concentrator's Target Asset Vaults
    /// @param _fortETH - The address of the Fortress Auto-Manager Vault for ETH
    /// @param _fortUSD - The address of the Fortress Auto-Manager Vault for USD
    /// @param _fortCrypto1 - The address of the Fortress Auto-Manager Vault for Market exposure
    /// @param _fortCrypto2 - The address of the Fortress Auto-Manager Vault for Market exposure
    function updateConcentratorsTargetAssets(address _fortETH, address _fortUSD, address _fortCrypto1, address _fortCrypto2) onlyOwner external {
        TargetAsset storage _concentratorTargetAssets = concentratorTargetAssets;

        _concentratorTargetAssets.fortETH = _fortETH;
        _concentratorTargetAssets.fortUSD = _fortUSD;
        _concentratorTargetAssets.fortCrypto1 = _fortCrypto1;
        _concentratorTargetAssets.fortCrypto2 = _fortCrypto2;

        emit UpdateConcentratorsTargetAssets(_fortETH, _fortUSD, _fortCrypto1, _fortCrypto2);
    }

    /// @dev Update the list of owners.
    /// @param _index - The slot on the list.
    /// @param _owner - The address of the new owner.
    function updateOwner(uint256 _index, address _owner) onlyOwner external {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();

        owners[_index] = _owner;

        emit UpdateOwner(_index, _owner);
    }

    /********************************** Events & Errors **********************************/

    event RegisterAMMCompounder(bool indexed _isCurve, address _compounder, address _primaryAsset);
    event RegisterAMMConcentrator(bool indexed _isCurve, address _concentrator, address _targetAsset, address _primaryAsset);
    event RegisterTokenCompounder(address _compounder, address _primaryAsset);
    event UpdateConcentratorsTargetAssets(address _fortETH, address _fortUSD, address _fortCrypto1, address _fortCrypto2);
    event UpdateOwner(uint256 _index, address _owner);
    
    error Unauthorized();
    error AlreadyRegistered();
    error InvalidTargetAsset();
    error InvalidAMMType();
}
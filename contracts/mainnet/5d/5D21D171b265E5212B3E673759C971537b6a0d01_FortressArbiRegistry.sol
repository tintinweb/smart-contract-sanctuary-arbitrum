/**
 *Submitted for verification at Arbiscan on 2022-12-27
*/

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

//  _____         _                   _____     _   _ _____         _     _           
// |   __|___ ___| |_ ___ ___ ___ ___|  _  |___| |_|_| __  |___ ___|_|___| |_ ___ _ _ 
// |   __| . |  _|  _|  _| -_|_ -|_ -|     |  _| . | |    -| -_| . | |_ -|  _|  _| | |
// |__|  |___|_| |_| |_| |___|___|___|__|__|_| |___|_|__|__|___|_  |_|___|_| |_| |_  |
//                                                             |___|             |___|

// Github - https://github.com/FortressFinance

contract FortressArbiRegistry {

    struct AMMCompounder {
        string symbol;
        string name;
        address compounder;
        address[] underlyingAssets;
    }

    struct TokenCompounder {
        string symbol;
        string name;
        address compounder;
    }

    struct AMMConcentrator {
        string symbol;
        string name;
        address concentrator;
        address compounder;
        address[] underlyingAssets;
    }

    /// @notice The list of CurveCompounder assets.
    address[] public curveCompoundersList;
    /// @notice The list of BalancerCompounder assets.
    address[] public balancerCompoundersList;
    /// @notice The list of TokenCompounder assets.
    address[] public tokenCompoundersList;
    /// @notice The list of balancerGlpConcentrators assets.
    address[] public balancerGlpConcentratorsList;
    /// @notice The list of balancerEthConcentrators assets.
    address[] public balancerEthConcentratorsList;
    /// @notice The list of curveGlpConcentrators assets.
    address[] public curveGlpConcentratorsList;
    /// @notice The list of curveEthConcentrators assets.
    address[] public curveEthConcentratorsList;
    /// @notice The mapping from vault asset to CurveCompounder info.
    mapping(address => AMMCompounder) public curveCompounders;
    /// @notice The mapping from vault asset to BalancerCompounder info.
    mapping(address => AMMCompounder) public balancerCompounders;
    /// @notice The mapping from vault asset to TokenCompounder info.
    mapping(address => TokenCompounder) public tokenCompounders;
    /// @notice The mapping from vault asset to Balancer GLP Concentrator info.
    mapping(address => AMMConcentrator) public balancerGlpConcentrators;
    /// @notice The mapping from vault asset to Balancer ETH Concentrator info.
    mapping(address => AMMConcentrator) public balancerEthConcentrators;
    /// @notice The mapping from vault asset to Curve Glp Concentrator info.
    mapping(address => AMMConcentrator) public curveGlpConcentrators;
    /// @notice The mapping from vault asset to Curve ETH Concentrator info.
    mapping(address => AMMConcentrator) public curveEthConcentrators;
    /// @notice The addresses of the contract owners.
    address[2] public owners;

    /********************************** Constructor **********************************/

    constructor(address _owner) {
        owners[0] = _owner;
    }

    /********************************** View Functions **********************************/

    /** Curve Compounder **/

    /// @dev Get the list of addresses of CurveCompounders assets.
    /// @return - The list of addresses.
    function getCurveCompoundersList() public view returns (address[] memory) {
        return curveCompoundersList;
    }

    /// @dev Get the CurveCompounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific CurveCompounder.
    function getCurveCompounder(address _asset) public view returns (address) {
        return curveCompounders[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getCurveCompounderSymbol(address _asset) public view returns (string memory) {
        return curveCompounders[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getCurveCompounderName(address _asset) public view returns (string memory) {
        return curveCompounders[_asset].name;
    }

    /// @dev Get the underlying assets of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getCurveCompounderUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return curveCompounders[_asset].underlyingAssets;
    }

    /** Balancer Compounder **/

    /// @dev Get the list of addresses of BalancerCompounders assets.
    /// @return - The list of addresses.
    function getBalancerCompoundersList() public view returns (address[] memory) {
        return balancerCompoundersList;
    }

    /// @dev Get the BalancerCompounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific BalancerCompounder.
    function getBalancerCompounder(address _asset) public view returns (address) {
        return balancerCompounders[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific BalancerCompounder.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getBalancerCompounderSymbol(address _asset) public view returns (string memory) {
        return balancerCompounders[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific BalancerCompounder.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getBalancerCompounderName(address _asset) public view returns (string memory) {
        return balancerCompounders[_asset].name;
    }

    /// @dev Get the underlying assets of a specific CurveCompounder.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getBalancerCompounderUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return balancerCompounders[_asset].underlyingAssets;
    }

    /** Token Compounder **/

    /// @dev Get the list of addresses of TokenCompounders assets.
    /// @return - The list of addresses.
    function getTokenCompoundersList() public view returns (address[] memory) {
        return tokenCompoundersList;
    }

    /// @dev Get the TokenCompounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific BalancerCompounder.
    function getTokenCompounder(address _asset) public view returns (address) {
        return tokenCompounders[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific TokenCompounder.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getTokenCompounderSymbol(address _asset) public view returns (string memory) {
        return tokenCompounders[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific TokenCompounder.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getTokenCompounderName(address _asset) public view returns (string memory) {
        return tokenCompounders[_asset].name;
    }

    /** Balancer GLP Concentrator **/

    /// @dev Get the list of addresses of BalancerGlpConcentrators assets.
    /// @return - The list of addresses.
    function getBalancerGlpConcentratorsList() public view returns (address[] memory) {
        return balancerGlpConcentratorsList;
    }

    /// @dev Get the BalancerGlpConcentrator of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of a specific BalancerGlpConcentrator.
    function getBalancerGlpConcentrator(address _asset) public view returns (address) {
        return balancerGlpConcentrators[_asset].concentrator;
    }

    /// @dev Get the BalancerGlpConcentrator Compounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific BalancerGlpConcentrator Compounder.
    function getBalancerGlpConcentratorCompounder(address _asset) public view returns (address) {
        return balancerGlpConcentrators[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific BalancerGlpConcentrator.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getBalancerGlpConcentratorSymbol(address _asset) public view returns (string memory) {
        return balancerGlpConcentrators[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific BalancerGlpConcentrator.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getBalancerGlpConcentratorName(address _asset) public view returns (string memory) {
        return balancerGlpConcentrators[_asset].name;
    }

    /// @dev Get the underlying assets of a specific BalancerGlpConcentrator.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getBalancerGlpConcentratorUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return balancerGlpConcentrators[_asset].underlyingAssets;
    }

    /** Balancer ETH Concentrator **/ 
    
    /// @dev Get the list of addresses of BalancerEthConcentrators assets.
    /// @return - The list of addresses.
    function getBalancerEthConcentratorsList() public view returns (address[] memory) {
        return balancerEthConcentratorsList;
    }

    /// @dev Get the BalancerEthConcentrators of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of a specific BalancerEthConcentrators.
    function getBalancerEthConcentrators(address _asset) public view returns (address) {
        return balancerEthConcentrators[_asset].concentrator;
    }

    /// @dev Get the BalancerEthConcentrators Compounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific BalancerEthConcentrators Compounder.
    function getBalancerEthConcentratorCompounder(address _asset) public view returns (address) {
        return balancerEthConcentrators[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific BalancerEthConcentrators.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getBalancerEthConcentratorsSymbol(address _asset) public view returns (string memory) {
        return balancerEthConcentrators[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific BalancerEthConcentrators.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getBalancerEthConcentratorsName(address _asset) public view returns (string memory) {
        return balancerEthConcentrators[_asset].name;
    }

    /// @dev Get the underlying assets of a specific BalancerEthConcentrators.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getBalancerEthConcentratorsUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return balancerEthConcentrators[_asset].underlyingAssets;
    }

    /** Curve GLP Concentrator **/

    /// @dev Get the list of addresses of CurveGlpConcentrators assets.
    /// @return - The list of addresses.
    function getCurveGlpConcentratorsList() public view returns (address[] memory) {
        return curveGlpConcentratorsList;
    }

    /// @dev Get the CurveGlpConcentrator of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of a specific CurveGlpConcentrator.
    function getCurveGlpConcentrator(address _asset) public view returns (address) {
        return curveGlpConcentrators[_asset].concentrator;
    }

    /// @dev Get the CurveGlpConcentrator Compounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific CurveGlpConcentrator Compounder.
    function getCurveGlpConcentratorCompounder(address _asset) public view returns (address) {
        return curveGlpConcentrators[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific CurveGlpConcentrator.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getCurveGlpConcentratorSymbol(address _asset) public view returns (string memory) {
        return curveGlpConcentrators[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific CurveGlpConcentrator.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getCurveGlpConcentratorName(address _asset) public view returns (string memory) {
        return curveGlpConcentrators[_asset].name;
    }

    /// @dev Get the underlying assets of a specific CurveGlpConcentrator.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getCurveGlpConcentratorUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return curveGlpConcentrators[_asset].underlyingAssets;
    }

    /** Curve ETH Concentrator **/

    /// @dev Get the list of addresses of CurveEthConcentrators assets.
    /// @return - The list of addresses.
    function getCurveEthConcentratorsList() public view returns (address[] memory) {
        return curveEthConcentratorsList;
    }

    /// @dev Get the CurveEthConcentrators of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of a specific CurveEthConcentrators.
    function getCurveEthConcentrators(address _asset) public view returns (address) {
        return curveEthConcentrators[_asset].concentrator;
    }

    /// @dev Get the CurveEthConcentrators Compounder of a specific asset.
    /// @param _asset - The asset address.
    /// @return - The address of the specific CurveEthConcentrators Compounder.
    function getCurveEthConcentratorsCompounder(address _asset) public view returns (address) {
        return curveEthConcentrators[_asset].compounder;
    }

    /// @dev Get the symbol of the receipt token of a specific CurveEthConcentrators.
    /// @param _asset - The asset address.
    /// @return - The symbol of the receipt token.
    function getCurveEthConcentratorsSymbol(address _asset) public view returns (string memory) {
        return curveEthConcentrators[_asset].symbol;
    }

    /// @dev Get the name of the receipt token of a specific CurveEthConcentrators.
    /// @param _asset - The asset address.
    /// @return - The name of the receipt token.
    function getCurveEthConcentratorsName(address _asset) public view returns (string memory) {
        return curveEthConcentrators[_asset].name;
    }

    /// @dev Get the underlying assets of a specific CurveEthConcentrators.
    /// @param _asset - The asset address.
    /// @return - The addresses of underlying assets.
    function getCurveEthConcentratorsUnderlyingAssets(address _asset) public view returns (address[] memory) {
        return curveEthConcentrators[_asset].underlyingAssets;
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Register a CurveCompounder.
    /// @param _compounder - The address of the Compounder.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    function registerCurveCompounder(address _compounder, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(curveCompounders[_asset].compounder != address(0)) revert AlreadyRegistered();

        curveCompounders[_asset] = AMMCompounder({
            symbol: _symbol,
            name: _name,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });

        curveCompoundersList.push(_asset);
        emit RegisterCurveCompounder(_compounder, _asset, _symbol, _name, _underlyingAssets);
    }

    /// @dev Register a BalancerCompounder.
    /// @param _compounder - The address of the Compounder.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    function registerBalancerCompounder(address _compounder, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(curveCompounders[_asset].compounder != address(0)) revert AlreadyRegistered();

        balancerCompounders[_asset] = AMMCompounder({
            symbol: _symbol,
            name: _name,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });
        
        balancerCompoundersList.push(_asset);
        emit RegisterBalancerCompounder(_compounder, _asset, _symbol, _name, _underlyingAssets);
    }

    /// @dev Register a TokenCompounder.
    /// @param _compounder - The address of the Compounder.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    function registerTokenCompounder(address _compounder, address _asset, string memory _symbol, string memory _name) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(tokenCompounders[_asset].compounder != address(0)) revert AlreadyRegistered();

        tokenCompounders[_asset] = TokenCompounder({
            symbol: _symbol,
            name: _name,
            compounder: _compounder
        });
        
        tokenCompoundersList.push(_asset);
        emit RegisterTokenCompounder(_compounder, _asset, _symbol, _name);
    }

    /// @dev Register a BalancerGlpConcentrator.
    /// @param _concentrator - The address of the Concentrator.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    /// @param _compounder - The address of the vault we concentrate the rewards into.
    function registerBalancerGlpConcentrator(address _concentrator, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets, address _compounder) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(balancerGlpConcentrators[_asset].concentrator != address(0)) revert AlreadyRegistered();

        balancerGlpConcentrators[_asset] = AMMConcentrator({
            symbol: _symbol,
            name: _name,
            concentrator: _concentrator,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });
        
        balancerGlpConcentratorsList.push(_asset);
        emit RegisterBalancerGlpConcentrator(_compounder, _asset, _symbol, _name, _underlyingAssets, _compounder);
    }

    /// @dev Register a BalancerEthConcentrator.
    /// @param _concentrator - The address of the Concentrator.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    /// @param _compounder - The address of the vault we concentrate the rewards into.
    function registerBalancerEthConcentrator(address _concentrator, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets, address _compounder) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(balancerEthConcentrators[_asset].concentrator != address(0)) revert AlreadyRegistered();

        balancerEthConcentrators[_asset] = AMMConcentrator({
            symbol: _symbol,
            name: _name,
            concentrator: _concentrator,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });
        
        balancerEthConcentratorsList.push(_asset);
        emit RegisterBalancerEthConcentrator(_compounder, _asset, _symbol, _name, _underlyingAssets, _compounder);
    }

    /// @dev Register a CurveConcentrator.
    /// @param _concentrator - The address of the Concentrator.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    /// @param _compounder - The address of the vault we concentrate the rewards into.
    function registerCurveGlpConcentrator(address _concentrator, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets, address _compounder) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(curveGlpConcentrators[_asset].concentrator != address(0)) revert AlreadyRegistered();

        curveGlpConcentrators[_asset] = AMMConcentrator({
            symbol: _symbol,
            name: _name,
            concentrator: _concentrator,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });
        
        curveGlpConcentratorsList.push(_asset);
        emit RegisterCurveGlpConcentrator(_compounder, _asset, _symbol, _name, _underlyingAssets, _compounder);
    }

    /// @dev Register a CurveConcentrator.
    /// @param _concentrator - The address of the Concentrator.
    /// @param _asset - The address of the asset.
    /// @param _symbol - The symbol of the receipt token.
    /// @param _name - The name of the receipt token.
    /// @param _underlyingAssets - The addresses of the underlying assets.
    /// @param _compounder - The address of the vault we concentrate the rewards into.
    function registerCurveEthConcentrator(address _concentrator, address _asset, string memory _symbol, string memory _name, address[] memory _underlyingAssets, address _compounder) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();
        if(curveEthConcentrators[_asset].concentrator != address(0)) revert AlreadyRegistered();

        curveEthConcentrators[_asset] = AMMConcentrator({
            symbol: _symbol,
            name: _name,
            concentrator: _concentrator,
            compounder: _compounder,
            underlyingAssets: _underlyingAssets
        });
        
        curveEthConcentratorsList.push(_asset);
        emit RegisterCurveEthConcentrator(_compounder, _asset, _symbol, _name, _underlyingAssets, _compounder);
    }

    /// @dev Update the list of owners.
    /// @param _index - The slot on the list.
    /// @param _owner - The address of the new owner.
    function updateOwner(uint256 _index, address _owner) public {
        if(msg.sender != owners[0] && msg.sender != owners[1]) revert Unauthorized();

        owners[_index] = _owner;
    }

    /********************************** Events & Errors **********************************/

    event RegisterCurveCompounder(address indexed _curveCompounder, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets);
    event RegisterBalancerCompounder(address indexed _balancerCompounder, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets);
    event RegisterTokenCompounder(address indexed _compounder, address indexed _asset, string _symbol, string _name);
    event RegisterBalancerGlpConcentrator(address indexed _balancerConcentrator, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets, address _compounder);
    event RegisterBalancerEthConcentrator(address indexed _balancerConcentrator, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets, address _compounder);
    event RegisterCurveGlpConcentrator(address indexed _curveConcentrator, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets, address _compounder);
    event RegisterCurveEthConcentrator(address indexed _curveConcentrator, address indexed _asset, string _symbol, string _name, address[] _underlyingAssets, address _compounder);

    error Unauthorized();
    error AlreadyRegistered();
}
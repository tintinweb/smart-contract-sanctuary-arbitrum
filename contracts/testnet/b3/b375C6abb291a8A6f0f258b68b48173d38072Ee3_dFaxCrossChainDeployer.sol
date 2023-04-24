// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface PoolGateway {
    
    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external;

    
    function changeAdmin(address _admin) external;
}

interface PoolGatewayFactory {
    function createPoolGateway(
        address token,
        address owner,
        uint256 salt
    ) external returns (address);

    function createTokenAndMintBurnGateway(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner,
        uint256 salt
    ) external returns (address, address);
}

interface Anycall {
    function anyCall( address _to, bytes calldata _data, uint256 _toChainID, uint256 _flags, bytes calldata _extdata) payable external;
}

interface IERC20 {
    function transferAdmin(address to) external;
}





contract dFaxCrossChainDeployer{
    PoolGatewayFactory public poolGatewayFactory;
    Anycall public anycall;
    // mapping(uint256  => address) public factory;
    // mapping(uint256 => address) public anyCalladdresses;
    mapping(uint256 => address) public clientPeers; // key is chainId

    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    constructor(PoolGatewayFactory _factory,Anycall _anycall) {
        admin = msg.sender;
        // factory[97] = 0x7C00F080732f53e20351fc853AF82d3Bceb36398;
        // factory[4002] = 0x7C00F080732f53e20351fc853AF82d3Bceb36398; 
        // factory[43113] = 0x7C00F080732f53e20351fc853AF82d3Bceb36398;
 
        poolGatewayFactory = _factory;
        anycall = _anycall;
    }

    function receivePayment() external payable {
        // Empty body
    }

    struct TokenData {
    string name;
    string symbol;
    uint8 decimals;
    address owner;
    uint256 salt;
}


    function createAndSetPeers(
        address token,
        TokenData memory tokenData,
        uint256[] calldata _chainIds,
        address[] calldata _peers,
        uint256[] calldata anyCallFee


    ) payable external {
        // Call the createPoolGateway function in the factory contract to create a new gateway


        address owner=tokenData.owner;
        uint256 salt=tokenData.salt;

        // give admin to this contract temp
        address gateway = poolGatewayFactory.createPoolGateway(token, address(this), salt);


        // Call the setClientPeers function on the new gateway
        PoolGateway(gateway).setClientPeers(_chainIds, _peers);

        // transfer admin to the owner
        PoolGateway(gateway).changeAdmin(owner);



        // loop through chainids skip this chainid which is position 0
        for (uint256 i = 1; i < _chainIds.length; i++) {

            // loop through peers

            // function anyCall( address _to, bytes calldata _data, uint256 _toChainID, uint256 _flags, bytes calldata _extdata) external;

            anycall.anyCall{value: anyCallFee[i]}(
                clientPeers[_chainIds[i]],
                abi.encode(

                        tokenData,
                        _chainIds,
                        _peers
                        
                    ),
                _chainIds[i],
                0,
                ""
                );
            
        }
    }

    receive() external payable {}

    function withdrawEther() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){

        (
    TokenData memory tokenData,
    uint256[] memory _chainIds,
    address[] memory _peers
) = abi.decode(_data, (TokenData, uint256[], address[]));

        // extract data from tokenData in one line
        (string memory name_, string memory symbol_, uint8 decimals_, address owner, uint256 salt) = (tokenData.name, tokenData.symbol, tokenData.decimals, tokenData.owner, tokenData.salt);

        (address token, address gateway) = poolGatewayFactory.createTokenAndMintBurnGateway(name_, symbol_, decimals_, address(this), salt);

        IERC20(token).transferAdmin(owner);
        
        // Call the setClientPeers function on the new gateway
        PoolGateway(gateway).setClientPeers(_chainIds, _peers);
        PoolGateway(gateway).changeAdmin(owner);
        success=true;
        result='';

    }


}
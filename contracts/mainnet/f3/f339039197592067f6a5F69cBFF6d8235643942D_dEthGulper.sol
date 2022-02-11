/**
 *Submitted for verification at arbiscan.io on 2022-02-03
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 
{
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IVault
{
    function joinPool(
            bytes32 poolId,
            address sender,
            address recipient,
            JoinPoolRequest memory request) 
        external 
        payable;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }
}

interface IWETH 
{
    function deposit() 
        payable 
        external;
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

contract Gulper
{
    bytes32 public poolId;
    IVault public constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    constructor (bytes32 _poolId)
    {
        poolId = _poolId;
    }

    function gulp()
        public
    {
        // logic:
        // * wrap all native tokens
        // * get pool tokens
        // * determine pool balances
        // * construct userData bytes to send to vault
        // * construct JoinPoolRequest
        // * join pool, sending BPTs to the void

        (IERC20[] memory tokens, , ) = vault.getPoolTokens(poolId);

        uint256[] memory maxAmountsIn = new uint256[](tokens.length);
        maxAmountsIn[0] = tokens[0].balanceOf(address(this));
        maxAmountsIn[1] = tokens[1].balanceOf(address(this));

        tokens[0].approve(address(vault), type(uint256).max);
        tokens[1].approve(address(vault), type(uint256).max);

        // default bytes data to join a pool with only two assets
        // not caring about BPT tokens returned
        // adding the two values we will be entering with
        bytes memory userData = hex"0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002";
        userData = bytes.concat(userData, bytes32(maxAmountsIn[0]), bytes32(maxAmountsIn[1]));

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: _convertERC20sToAssets(tokens),
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });

        address sender = address(this);
        address recipient = address(1);

        vault.joinPool(poolId, sender, recipient, request);
    }

    function _convertERC20sToAssets(IERC20[] memory tokens) 
        internal 
        pure 
        returns (IAsset[] memory assets) 
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            assets := tokens
        }
    }
}

contract DaiGulper is Gulper
{
    constructor () Gulper(bytes32(0x85a7023f3d287f849b6c8223af1e783383a391a8000200000000000000000044)) { }
}

contract dEthGulper is Gulper
{
    constructor () Gulper(bytes32(0x507f8456aa170285fe33b80757feca82b8103e77000200000000000000000045)) { }
}

contract EthGulper is Gulper
{
    constructor () Gulper(bytes32(0x055242438d0eca5dd98878c32a3033d19f73c935000200000000000000000046)) { }

    receive()
        payable
        external
    {
        IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1).deposit{ value: address(this).balance }();
    }
}

// Deploys the 3 gulpers to Arbitrum
contract GulperDeployer
{
    event LogGulpers(address _EthGulper, address _dEthGulper, address _DaiGulper);

    constructor()
    {
        emit LogGulpers(
            address(new EthGulper()),
            address(new dEthGulper()),
            address(new DaiGulper()));
    }
}
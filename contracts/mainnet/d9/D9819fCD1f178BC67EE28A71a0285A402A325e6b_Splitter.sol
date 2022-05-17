/**
 *Submitted for verification at Arbiscan on 2022-05-17
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

contract Splitter
{
    bytes32 public poolId;
    IVault public constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    constructor (bytes32 _poolId)
    {
        poolId = _poolId;
    }

    function split()
        public
    {
        
        (IERC20[] memory tokens, , ) = vault.getPoolTokens(poolId);

        uint256[] memory maxAmountsIn = new uint256[](tokens.length);
        maxAmountsIn[0] = tokens[0].balanceOf(address(this));
        maxAmountsIn[1] = tokens[1].balanceOf(address(this));
        maxAmountsIn[2] = tokens[2].balanceOf(address(this));

        tokens[0].approve(address(vault), type(uint256).max);
        tokens[1].approve(address(vault), type(uint256).max);
        tokens[2].approve(address(vault), type(uint256).max);

        // uint256 joinKindExactTokens = 1;
        // uint256 minBPTOut = 0;
        // uint256[3] memory balances = [maxAmountsIn[0], maxAmountsIn[1], maxAmountsIn[2]];
        // bytes memory userData = abi.encode(joinKindExactTokens, balances, minBPTOut);

        bytes memory userData = hex"0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003";
        userData = bytes.concat(userData, bytes32(maxAmountsIn[0]), bytes32(maxAmountsIn[1]), bytes32(maxAmountsIn[2]));


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
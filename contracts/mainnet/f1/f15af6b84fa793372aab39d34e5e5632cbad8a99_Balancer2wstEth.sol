/**
 *Submitted for verification at Arbiscan.io on 2023-11-01
*/

// File: src/interfaces/IAsset.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
// File: src/strategic/Balancer2wstEth.sol



pragma solidity ^0.8.11;


interface IBalancer {
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
  function joinPool(bytes32, address, address recipient, JoinPoolRequest memory) external payable;
}

interface IAura {
  function deposit(uint256 _amount) external;
  function withdraw(uint256 _share) external;
}

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
}

contract Balancer2wstEth {

    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant BALANCER_WSTETH_STABLE_POOL = 0x9791d590788598535278552EEcD4b211bFc790CB;// ComposableStablePool
    address public constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant AURA_ADDRESS = 0x85B10228cd93A6e5E354Ff0f2c60875E8E62F65A;
    bytes32 public constant POOL_ID = 0x9791d590788598535278552eecd4b211bfc790cb000000000000000000000498;

    function strategicInFirstTime(IBalancer.JoinPoolRequest memory _data, uint256[] memory transferAmount) external payable{
        if (transferAmount.length == 2){
          if(transferAmount[0] != 0) {
            IERC20(WETH).transferFrom(msg.sender, address(this), transferAmount[0]);
          }
          if(transferAmount[1] != 0) {
            IERC20(WSTETH).transferFrom(msg.sender, address(this), transferAmount[1]);
          }    
        }
        IERC20(WETH).approve(BALANCER_VAULT, type(uint256).max);
        IERC20(WSTETH).approve(BALANCER_VAULT, type(uint256).max);

        uint256 amountBefore = IERC20(BALANCER_WSTETH_STABLE_POOL).balanceOf(address(this));
        IBalancer(BALANCER_VAULT).joinPool{value: msg.value}(POOL_ID, address(this), address(this), _data);
        uint256 amountAfter = IERC20(BALANCER_WSTETH_STABLE_POOL).balanceOf(address(this));

        IERC20(BALANCER_WSTETH_STABLE_POOL).approve(AURA_ADDRESS, type(uint256).max);
        IAura(AURA_ADDRESS).deposit(amountAfter - amountBefore); 
    }

    function strategicInLight(IBalancer.JoinPoolRequest memory _data, uint256[] memory transferAmount) external payable{
        if (transferAmount.length == 2){
          if(transferAmount[0] != 0) {
            IERC20(WETH).transferFrom(msg.sender, address(this), transferAmount[0]);
          }
          if(transferAmount[1] != 0) {
            IERC20(WSTETH).transferFrom(msg.sender, address(this), transferAmount[1]);
          }    
        }
        uint256 amountBefore = IERC20(BALANCER_WSTETH_STABLE_POOL).balanceOf(address(this));
        IBalancer(BALANCER_VAULT).joinPool{value: msg.value}(POOL_ID, address(this), address(this), _data);
        uint256 amountAfter = IERC20(BALANCER_WSTETH_STABLE_POOL).balanceOf(address(this));

        IAura(AURA_ADDRESS).deposit(amountAfter - amountBefore);
    }

    function strategicOut(uint256 amount, bytes calldata withdrawData, uint8 tokenType, address toAddr) external payable{
        uint256 nativeBefore = address(this).balance;
        uint256 WSTETHBefore = IERC20(WSTETH).balanceOf(address(this));
        uint256 WETHBefore = IERC20(WETH).balanceOf(address(this));

        IAura(AURA_ADDRESS).withdraw(amount);

        (bool result, ) = BALANCER_VAULT.call(withdrawData);
        require(result, "failed to withdraw from Balancer");

        if(toAddr != address(0)){

          if(tokenType == 0){

            payable(toAddr).transfer(address(this).balance - nativeBefore);
          } else if(tokenType == 1){

            uint256 amountWsteth = IERC20(WSTETH).balanceOf(address(this)) - WSTETHBefore;
            uint256 amountWeth = IERC20(WETH).balanceOf(address(this)) - WETHBefore;
            IERC20(amountWsteth > 0 ? WSTETH : WETH).transfer(toAddr, amountWsteth > 0 ? amountWsteth : amountWeth);
          } else if(tokenType == 2){
            
            uint256 amountNative = address(this).balance - nativeBefore;
            if(amountNative > 0) {
              payable(toAddr).transfer(amountNative);
            }

            uint256 amountWsteth = IERC20(WSTETH).balanceOf(address(this)) - WSTETHBefore;
            uint256 amountWeth = IERC20(WETH).balanceOf(address(this)) - WETHBefore;
            IERC20(amountWsteth > 0 ? WSTETH : WETH).transfer(toAddr, amountWsteth > 0 ? amountWsteth : amountWeth);
          }
        }
    }

    receive() external payable {}
}
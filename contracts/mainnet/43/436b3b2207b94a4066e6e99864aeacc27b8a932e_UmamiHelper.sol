/**
 *Submitted for verification at Arbiscan on 2022-05-21
*/

// SPDX-License-Identifier: GNU GPLv3s
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/helper.sol


pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                              #@@@@@@@@@@@@&,                               //
//                      [email protected]@@@@   [email protected]@@@@@@@@@@@@@@@@@@*                        //
//                  %@@@,    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    //
//               @@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 //
//             @@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@               //
//           *@@@#    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//          *@@@%    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            //
//          @@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//                                                                            //
//          (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,           //
//          (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,           //
//                                                                            //
//               @@   @@     @   @       @       @   @       @                //
//               @@   @@    @@@ @@@     @[email protected]     @@@ @@@     @@@               //
//                &@@@@   @@  @@  @@  @@ ^ @@  @@  @@  @@   @@@               //
//                                                                            //
//          @@@@@      @@@%    *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//          @@@@@      @@@@    %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//          [email protected]@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            //
//            @@@@@  &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//                (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(                 //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


interface IMarinater {
    function stake(uint256 _amount) external;
}

interface IStrategy {
    function deposit(uint256 _amount) external;
    function getSharesForDepositTokens(uint256 _shares) external returns (uint256 shares);
}

interface ICompounder {
    function stakeFor(address _recipient, uint256 _amount) external;
}

/// @title Umami Autocompounder Helper
/// @author invader prΞpop
contract UmamiHelper {
    address public immutable umami;
    address public immutable marinater;
    address public immutable compounder;
    address public immutable booster;

    constructor(
        address _marinater,
        address _compounder,
        address _umami,
        address _booster
    ) {
        require(_marinater != address(0));
        marinater = _marinater;
        require(_compounder != address(0));
        compounder = _compounder;
        require(_umami != address(0));
        umami = _umami;
        require(_booster != address(0));
        booster = _booster;
    }

     event zapIn(
        address sender,
        uint256 inputTokens,
        uint256 sharesDeposited
    );

        /**
        * @notice marinates, compounds, and boosts Umami tokens
        * @param _amount: the amount of Umami that the user wants to deposit into the autocompounder
        */
        function marinateAndCompound(uint256 _amount) external
        {

            //transfer Umami from the sender
            IERC20(umami).transferFrom(msg.sender, address(this), _amount);
            IERC20(umami).approve(marinater, _amount);

            //Marinate the Umami
            IMarinater(marinater).stake(_amount);
            IERC20(marinater).approve(compounder, _amount);
            
            //Get the # of shares and deposit in the cmUmami autocompounder
            uint256 shares = 0;
            shares = IStrategy(compounder).getSharesForDepositTokens(_amount);
            IStrategy(compounder).deposit(_amount);
        
            //Transfer cmUmami back to the sender
            IERC20(compounder).approve(address(this), shares);
            IERC20(compounder).transferFrom(address(this), msg.sender, shares);

            //Stake the cmUmami in the Marinate Strategy Farm for the user
            IERC20(compounder).approve(msg.sender, shares);
            ICompounder(booster).stakeFor(msg.sender, shares);
            
            emit zapIn(msg.sender, _amount, shares);
        }

        /**
        * @notice marinates, transfers existing mUmami, compounds, and boosts Umami tokens
        * @param _umamiAmount: the amount of Umami that the user wants to deposit into the autocompounder
        * @param _mumamiAmount: the amount of mUmami that the user wants to deposit into the autocompounder
        */
        function marinateSendAndCompound(uint256 _umamiAmount, uint256 _mumamiAmount) external 
        {

            //transfer Umami from the sender
            IERC20(umami).transferFrom(msg.sender, address(this), _umamiAmount);
            IERC20(umami).approve(marinater, _umamiAmount);
            //Marinate the Umami
            IMarinater(marinater).stake(_umamiAmount);

            //transfer mUmami from the sender
            IERC20(marinater).transferFrom(msg.sender, address(this), _mumamiAmount);
            uint256 totalMarinating = _umamiAmount + _mumamiAmount;
            IERC20(marinater).approve(compounder, totalMarinating);

            //Get the # of shares and deposit in the cmUmami autocompounder
            uint256 shares = 0;
            shares = IStrategy(compounder).getSharesForDepositTokens(totalMarinating);
            IStrategy(compounder).deposit(totalMarinating);

            //Transfer cmUmami back to the sender
            IERC20(compounder).approve(address(this), shares);
            IERC20(compounder).transferFrom(address(this), msg.sender, shares);

            //Stake the cmUmami in the Marinate Strategy Farm for the user
            IERC20(compounder).approve(msg.sender, shares);
            ICompounder(booster).stakeFor(msg.sender, shares);
            emit zapIn(msg.sender, totalMarinating, shares);
        }


        /**
        * @notice transfers existing mUmami, compounds, and boosts Umami tokens
        * @param _amount: the amount of mUmami that the user wants to deposit into the autocompounder
        */
        function compound(uint256 _amount) external 
        {
             //transfer mUmami from the sender
            IERC20(marinater).transferFrom(msg.sender, address(this), _amount);
            IERC20(marinater).approve(compounder, _amount);

            //Get the # of shares and deposit in the cmUmami autocompounder
            uint256 shares = 0;
            shares = IStrategy(compounder).getSharesForDepositTokens(_amount);
            IStrategy(compounder).deposit(_amount);
        
            //Transfer cmUmami back to the sender
            IERC20(compounder).approve(address(this), shares);
            IERC20(compounder).transferFrom(address(this), msg.sender, shares);

            //Stake the cmUmami in the Marinate Strategy Farm for the user
            IERC20(compounder).approve(msg.sender, shares);
            ICompounder(booster).stakeFor(msg.sender, shares);
            emit zapIn(msg.sender, _amount, shares);
        }
}
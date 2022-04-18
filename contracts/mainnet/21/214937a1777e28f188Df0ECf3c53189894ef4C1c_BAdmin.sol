/**
 *Submitted for verification at Arbiscan on 2022-04-18
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/Ownable/Ownable.sol

pragma solidity ^0.5.16;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/BAdmin.sol

pragma solidity ^0.5.16;

interface ComptrollerLike {
    function _setSeizePaused(bool state) external returns (bool);
    function _acceptAdmin() external returns (uint);
    function _setPendingAdmin(address newPendingAdmin) external returns (uint);
}

interface ERC20Like {
    function balanceOf(address a) external returns(uint);
    function transfer(address to, uint amount) external returns(bool);
}

// initially deployer owns it, and then it moves it to the DAO
contract BAdmin is Ownable {
    mapping(address => bool) public collectFeesAuth;
    mapping(address => bool) public seizePausedAuth;
    ComptrollerLike public comptroller; 

    event CollectFeesAuthSet(address a, bool set);
    event SeizePausedAuthSet(address a, bool set);
    event SeizePausedSet(address indexed sender, bool state);

    constructor(ComptrollerLike _comptroller) public {
        comptroller = _comptroller;
        transferOwnership(msg.sender);
    }

    function op(address payable target, bytes calldata data, uint value) onlyOwner external payable {
        target.call.value(value)(data);
    }
    function() payable external {}

    function acceptCompAdmin() public onlyOwner {
        comptroller._acceptAdmin();
    }

    function setCompAdmin(address newPendingAdmin) public onlyOwner {
        comptroller._setPendingAdmin(newPendingAdmin);
    }

    function setSeizePausedAuth(address a, bool set) public onlyOwner {
        seizePausedAuth[a] = set;
        emit SeizePausedAuthSet(a, set);
    }

    function _setSeizePaused(bool state) public returns(bool) {
        require(seizePausedAuth[msg.sender], "!auth");
        comptroller._setSeizePaused(state);

        emit SeizePausedSet(msg.sender, state);

        return state;    
    }

    function setCollectFeeAuth(address a, bool set) public onlyOwner {
        collectFeesAuth[a] = set;
        emit CollectFeesAuthSet(a, set);
    }

    function collectFees(ERC20Like token) public {
        require(collectFeesAuth[msg.sender], "!auth");

        if(token == ERC20Like(0x0)) msg.sender.transfer(address(this).balance);
        else token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}